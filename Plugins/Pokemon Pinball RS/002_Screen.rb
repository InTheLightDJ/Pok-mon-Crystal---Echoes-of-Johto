#==============================================================================
# Pokémon Pinball RS - the GBA screen (mode 0): 4 text BGs and 128 sprites,
# drawn into a 240x160 Bitmap.
#   Each BG is a Bitmap of its whole map (256/512 square), kept up to date
#   cell by cell (8x8) from cached tile rows (RGBA strings, Bitmap#raw_data=)
#   whenever its map, tiles or palettes change.
#   A frame is composed band by band (Machine#bands: the display registers
#   between VCount interrupts): from priority 3 to 0, BGs (higher number
#   first) then that priority's sprites (higher OAM index first). Alpha
#   blending -> blt opacity, brightness -> a white / black layer on top.
#   Affine sprites are transformed in Ruby (they are few and small).
#   A semi-transparent sprite hides the sprites behind it (find_obj_masks).
# The tall view: the Bitmap is ext lines taller above and below (to fill the
# window's height at its width). Off a main table those are black (the GBA
# screen in the middle); on one (tall = true) the table is drawn there too:
# the first band from -ext, the score bar's band (the last, from line 128 on)
# moved down ext to the new bottom. The table's streamed tiles (a ring of 22
# tile rows the game refills as it scrolls, BG char block 2) are drawn from
# the game's unpacked board (gBoardBGTileBuffer / ...Alt: map row r is ring
# slot (r - 12) % 22, from buffer row r), so rows past the ring are right.
#==============================================================================
module PinballRS
  class Screen
    W = 240
    H = 160
    OBJ_SIZES = [[[8, 8], [16, 16], [32, 32], [64, 64]],
                 [[16, 8], [32, 8], [32, 16], [64, 32]],
                 [[8, 16], [8, 32], [16, 32], [32, 64]]]
    CLEAR = "\0\0\0\0".b

    RING_BASE  = 0x8000              # BG char block 2
    RING_SLOTS = 22
    RING_SHIFT = 12                  # map row r is in slot (r - 12) % 22
    RING_ROWS  = 56                  # board rows: 32 in the buffer, 24 in Alt
    HUD_FROM   = 128                 # a last band starting this low is the score bar

    attr_reader :bitmap, :ext
    attr_accessor :tall
    # OAM entry => :hide (parked out of sight), :above / :below (where a y of
    # 160-255 really is: past the bottom, or above the top; set by the player
    # from the sprite groups' own positions)
    attr_accessor :oam_hints

    def initialize(ext = 0)
      @ext = ext
      @tall = false
      th = H + (2 * ext)
      @bitmap = Bitmap.new(W, th)
      @white = Bitmap.new(W, th)
      @white.fill_rect(0, 0, W, th, Color.new(255, 255, 255))
      @black = Bitmap.new(W, th)
      @black.fill_rect(0, 0, W, th, Color.new(0, 0, 0))
      @ring = nil                       # [buffer offset in EWRAM, Alt offset, version] on a main table
      @ring_ver = 0
      @ring_sig = nil
      @ring_rows = {}
      @pal_raw = nil
      @bg_pal = Array.new(16) { Array.new(16, CLEAR) }    # [bank][index] RGBA
      @obj_pal = Array.new(16) { Array.new(16, CLEAR) }
      @bg_pal256 = Array.new(256, CLEAR)
      @obj_pal256 = Array.new(256, CLEAR)
      @pal_ver = Array.new(34, 0)       # BG banks 0-15, OBJ banks 16-31, 32 BG 8bpp, 33 OBJ 8bpp
      @tile_ver = Array.new(0x18000 >> 5, 0)
      @block_ver = Array.new(6, 0)      # per 16 KB char block
      @rows = {}                        # tile block => { variant => [8 RGBA rows] }
      @bgs = Array.new(4) { BgLayer.new }
      @objs = {}                        # sprite key => [Bitmap, versions, unused frames, RGBA]
      @masked = []                      # this frame's sprite bitmaps with holes (find_obj_masks)
      @backdrop = Color.new(0, 0, 0)
      @rect = Rect.new(0, 0, 0, 0)
    end

    def dispose
      @masked.each(&:dispose)
      @bgs.each(&:dispose)
      @objs.each_value { |b, _| b.dispose }
      @bitmap.dispose
      @white.dispose
      @black.dispose
    end

    #--------------------------------------------------------------------------
    def draw(m)
      sync_palettes(m) if m.pal_dirty
      sync_tiles(m)
      bands = m.bands
      return if bands.empty?
      @masked.each(&:dispose)
      @masked.clear
      used = {}
      sync_ring(m)
      plan = bands.each_with_index.map { |(y0, regs), i| [y0, i + 1 < bands.size ? bands[i + 1][0] : H, regs, 0] }
      if @tall && @ext > 0
        hud = plan.size > 1 && plan.last[0] >= HUD_FROM ? plan.pop : nil
        plan.first[0] = -@ext
        if hud
          plan.last[1] = hud[0] + @ext
          plan << [hud[0] + @ext, H + @ext, hud[2], @ext]
        else
          plan.last[1] = H + @ext
        end
      elsif @ext > 0
        @bitmap.fill_rect(0, 0, W, @ext, Color.new(0, 0, 0))
        @bitmap.fill_rect(0, H + @ext, W, @ext, Color.new(0, 0, 0))
      end
      plan.each do |y0, y1, regs, hud_shift|
        next unless y1 > y0
        # (the score bar's band last, over the blanked lines)
        blank_past_table(bands[0][1]) if hud_shift > 0
        draw_band(m, regs, y0, y1, used, hud_shift)
      end
      blank_past_table(bands[0][1]) if @tall && @ext > 0 && plan.last[3] == 0
      # sprite bitmaps not used for a while go
      @objs.delete_if do |k, v|
        next false if used[k]
        v[2] = (v[2] || 0) + 1
        next false if v[2] < 120
        v[0].dispose
        true
      end
    end

    def reg(regs, o) = regs.getbyte(o) | (regs.getbyte(o + 1) << 8)

    # the added lines that would show past the table's ends (a cutscene's
    # camera can go there; the map wraps): black
    def blank_past_table(regs)
      vofs = reg(regs, 0x12 + (3 * 4)) & 0x1FF     # BG3: the table
      ((-@ext...0).to_a + (H...(H + @ext)).to_a).each do |y|
        next if (vofs + y) % 512 < RING_ROWS * 8
        @bitmap.fill_rect(0, y + @ext, W, 1, Color.new(0, 0, 0))
      end
    end

    # lines y0...y1 (GBA lines; the Bitmap's are ext lower); hud_shift: BG0
    # (the score bar) drawn that much lower
    def draw_band(m, regs, y0, y1, used, hud_shift = 0)
      dispcnt = reg(regs, 0)
      if dispcnt & 0x80 != 0      # forced blank: white
        @bitmap.fill_rect(0, y0 + @ext, W, y1 - y0, Color.new(255, 255, 255))
        return
      end
      @bitmap.fill_rect(0, y0 + @ext, W, y1 - y0, @backdrop)
      bld = reg(regs, 0x50)
      alpha = reg(regs, 0x52)
      effect = (bld >> 6) & 3
      eva = [alpha & 31, 16].min
      sprites = dispcnt & 0x1000 != 0 ? visible_sprites(m, dispcnt, y0, y1) : []
      find_obj_masks(sprites)
      3.downto(0) do |prio|
        3.downto(0) do |n|
          next if dispcnt & (0x100 << n) == 0
          cnt = reg(regs, 8 + n * 2)
          next if cnt & 3 != prio
          bg = @bgs[n]
          bg.update(self, m, cnt)
          op = effect == 1 && bld & (1 << n) != 0 ? eva * 255 / 16 : 255
          vofs = reg(regs, 0x12 + n * 4) - (n == 0 ? hud_shift : 0)
          by0 = y0
          by1 = y1
          if n == 0 && hud_shift == 0
            # BG0 (banners, text) is laid out for the GBA's 160 lines only
            by0 = [y0, 0].max
            by1 = [y1, H].min
          end
          blit_bg(bg, reg(regs, 0x10 + n * 4) & 0x1FF, vofs & 0x1FF, by0, by1, op) if by1 > by0
        end
        sprites.each do |s|
          next unless s[:prio] == prio
          op = 255
          op = eva * 255 / 16 if s[:mode] == 1 || (effect == 1 && bld & 0x10 != 0)
          blit_sprite(m, s, y0, y1, op, used)
        end
      end
      if effect >= 2
        evy = [reg(regs, 0x54) & 31, 16].min
        if evy > 0
          @rect.set(0, y0 + @ext, W, y1 - y0)
          @bitmap.blt(0, y0 + @ext, effect == 2 ? @white : @black, @rect, evy * 255 / 16)
        end
      end
    end

    # the map bitmap scrolled by (hofs, vofs), wrapping, into lines y0...y1
    def blit_bg(bg, hofs, vofs, y0, y1, opacity)
      mw = bg.w
      mh = bg.h
      y = y0
      while y < y1
        sy = (vofs + y) % mh
        h = [mh - sy, y1 - y].min
        x = 0
        while x < W
          sx = (hofs + x) % mw
          w = [mw - sx, W - x].min
          @rect.set(sx, sy, w, h)
          @bitmap.blt(x, y + @ext, bg.bitmap, @rect, opacity)
          x += w
        end
        y += h
      end
    end

    #--------------------------------------------------------------------------
    # palettes and tiles
    #--------------------------------------------------------------------------
    def rgba(v)
      r = v & 31
      g = (v >> 5) & 31
      b = (v >> 10) & 31
      [(r << 3) | (r >> 2), (g << 3) | (g >> 2), (b << 3) | (b >> 2), 255].pack("C4")
    end

    def sync_palettes(m)
      pal = m.pal
      32.times do |bank|
        raw = pal.byteslice(bank * 32, 32)
        next if @pal_raw && @pal_raw.byteslice(bank * 32, 32) == raw
        cols = Array.new(16) { |i| rgba(raw.getbyte(i * 2) | (raw.getbyte(i * 2 + 1) << 8)) }
        if bank < 16
          @bg_pal[bank] = cols.dup.tap { |c| c[0] = CLEAR }
          16.times { |i| @bg_pal256[bank * 16 + i] = cols[i] }
          @bg_pal256[0] = CLEAR
          @pal_ver[32] += 1
          if bank == 0
            v = raw.getbyte(0) | (raw.getbyte(1) << 8)
            @backdrop = Color.new((v & 31) * 255 / 31, ((v >> 5) & 31) * 255 / 31, ((v >> 10) & 31) * 255 / 31)
          end
        else
          @obj_pal[bank - 16] = cols.dup.tap { |c| c[0] = CLEAR }
          16.times { |i| @obj_pal256[(bank - 16) * 16 + i] = cols[i] }
          @obj_pal256[0] = CLEAR
          @pal_ver[33] += 1
        end
        @pal_ver[bank] += 1
      end
      @pal_raw = pal.dup
      m.pal_dirty = false
    end

    def sync_tiles(m)
      d = m.vram_dirty
      i = 0
      n = d.size
      while i < n
        if d[i]
          d[i] = false
          @tile_ver[i] += 1
          @block_ver[i >> 9] += 1
          @rows.delete(i)
          @rows.delete(i - 1)    # an 8bpp tile spans 2 blocks
        end
        i += 1
      end
    end

    attr_reader :tile_ver, :pal_ver, :block_ver

    # 8 RGBA rows (32 bytes for 8 pixels) of the tile at VRAM offset a
    # variant: palette bank (0-15) + 16 for OBJ palettes; 8bpp: bank -1 / -2
    def tile_rows(vram, a, variant, hflip)
      return EMPTY_ROWS if a + 32 > 0x18000
      h = (@rows[a >> 5] ||= {})
      key = hflip ? variant + 64 : variant
      # the rows are only good for the palette version they were made with
      pver = @pal_ver[variant < 0 ? 31 - variant : variant]
      e = h[key]
      return e[1] if e && e[0] == pver
      rows = make_rows(vram, a, variant, hflip)
      h[key] = [pver, rows]
      rows
    end

    def make_rows(vram, a, variant, hflip)
      if variant < 0
        pal = variant == -1 ? @bg_pal256 : @obj_pal256
        Array.new(8) do |r|
          s = String.new(capacity: 32, encoding: Encoding::BINARY)
          o = a + r * 8
          if hflip
            7.downto(0) { |k| s << pal[vram.getbyte(o + k) || 0] }
          else
            8.times { |k| s << pal[vram.getbyte(o + k) || 0] }
          end
          s
        end
      else
        pal = variant < 16 ? @bg_pal[variant] : @obj_pal[variant - 16]
        Array.new(8) do |r|
          s = String.new(capacity: 32, encoding: Encoding::BINARY)
          o = a + r * 4
          if hflip
            3.downto(0) { |k| b = vram.getbyte(o + k); s << pal[b >> 4] << pal[b & 15] }
          else
            4.times { |k| b = vram.getbyte(o + k); s << pal[b & 15] << pal[b >> 4] }
          end
          s
        end
      end
    end

    EMPTY_ROWS = Array.new(8) { ("\0" * 32).b }

    # on a main table: where the unpacked board is (unpacked again, e.g.
    # after a bonus table, it's seen by its checksum)
    PREV_SCROLL_TILE_IX = 0x64       # gCurrentPinballGame->prevScrollYTileIx: the ring's first row

    def sync_ring(m)
      unless @tall
        @ring = nil
        return
      end
      @ring_window = m.rs16(m.r32(m.sym("gCurrentPinballGame")) + PREV_SCROLL_TILE_IX)
      buf = m.sym("gBoardBGTileBuffer") & 0x3FFFF
      alt = m.sym("gBoardBGTileBufferAlt") & 0x3FFFF
      sig = Zlib.crc32(m.ew.byteslice(buf, 32 * 0x400) + m.ew.byteslice(alt, (RING_ROWS - 32) * 0x400))
      return if sig == @ring_sig && @ring
      @ring_rows.clear
      @ring_ver += 1
      @ring_sig = sig
      @ring = [buf, alt, @ring_ver]
    end

    def ring? = !@ring.nil?
    def ring_version = @ring ? [@ring[2], @ring_window] : 0

    # the ring tile for map row ty, tile number tile (block 2, 4bpp), or nil:
    # [its version, its 8 RGBA rows]. Only for rows the ring doesn't hold
    # now: the ones it does are drawn from VRAM (the game changes them there:
    # the holes opening, lights)
    def ring_tile(m, ty, tile, bank, hflip)
      return nil unless @ring && tile < RING_SLOTS * 32
      return nil unless ty < RING_ROWS && tile >> 5 == (ty - RING_SHIFT) % RING_SLOTS
      # (a row's margin each end, in case a row is loaded a frame late)
      return nil if ty > @ring_window && ty < @ring_window + RING_SLOTS - 1
      buf, alt, ver = @ring
      a = (ty < 32 ? buf + (ty * 0x400) : alt + ((ty - 32) * 0x400)) + ((tile & 31) * 32)
      key = (a << 6) | (bank << 1) | (hflip ? 1 : 0)
      pver = @pal_ver[bank]
      tver = -ver - (pver * 4096)
      e = @ring_rows[key]
      return [tver, e[1]] if e && e[0] == pver
      rows = make_rows(m.ew, a, bank, hflip)
      @ring_rows[key] = [pver, rows]
      [tver, rows]
    end

    #--------------------------------------------------------------------------
    # a BG layer: its whole map as one Bitmap
    #--------------------------------------------------------------------------
    class BgLayer
      attr_reader :bitmap, :w, :h

      def initialize
        @cnt = nil
      end

      def dispose
        @bitmap&.dispose
      end

      def update(screen, m, cnt)
        size = (cnt >> 14) & 3
        w = size & 1 == 1 ? 512 : 256
        h = size & 2 == 2 ? 512 : 256
        if cnt != @cnt || @bitmap.nil? || @bitmap.disposed?
          if @w != w || @h != h || @bitmap.nil?
            @bitmap&.dispose
            @bitmap = Bitmap.new(w, h)
          end
          @w = w
          @h = h
          @cnt = cnt
          @buf = ("\0" * (w * h * 4)).b
          @cells = Array.new((w >> 3) * (h >> 3))    # [entry, tile version, palette version]
          @map_raw = nil
        end
        cbase = ((cnt >> 2) & 3) * 0x4000
        sbase = ((cnt >> 8) & 31) * 0x800
        eight = cnt & 0x80 != 0
        vram = m.vram
        blocks = (w >> 8) * (h >> 8)
        raw = vram.byteslice(sbase, 0x800 * blocks)
        tv = screen.tile_ver
        pv = screen.pal_ver
        bv = screen.block_ver
        cb = cbase >> 14
        # 1024 tiles reach 32 KB (4bpp) / 64 KB (8bpp) past the char base; BG tiles end at 64 KB
        # a main table's streamed tiles come from its unpacked board (ring_tile)
        ring_ok = cbase == RING_BASE && !eight && h == 512 && screen.ring?
        stamp = [bv[cb..[cb + (eight ? 3 : 1), 3].min].sum, eight ? pv[32] : pv[0, 16].sum, ring_ok ? screen.ring_version : 0]
        full = stamp != @stamp || @map_raw.nil?
        return if !full && raw == @map_raw
        # the map rows (32 entries) that changed; all of them after a tile / palette change
        rows = []
        (blocks * 32).times do |r|
          rows << r if full || raw.byteslice(r * 64, 64) != @map_raw.byteslice(r * 64, 64)
        end
        @map_raw = raw
        @stamp = stamp
        changed = false
        cols = w >> 3
        tile_bytes = eight ? 64 : 32
        rows.each do |r|
          blk = r >> 5
          ty = (r & 31) + (w == 512 ? (blk >> 1) * 32 : blk * 32)
          tx0 = w == 512 ? (blk & 1) * 32 : 0
          base_e = r * 64
          32.times do |k|
            tx = tx0 + k
            e = raw.getbyte(base_e + k * 2) | (raw.getbyte(base_e + k * 2 + 1) << 8)
            tile = e & 0x3FF
            a = cbase + tile * tile_bytes
            ring = ring_ok ? screen.ring_tile(m, ty, tile, e >> 12, e & 0x400 != 0) : nil
            tver = if ring then ring[0]
                   else a < 0x10000 ? tv[a >> 5] + (eight ? tv[(a >> 5) + 1] : 0) : 0
                   end
            pver = eight ? pv[32] : pv[e >> 12]
            ci = ty * cols + tx
            c = @cells[ci]
            next if c && c[0] == e && c[1] == tver && c[2] == pver
            @cells[ci] = [e, tver, pver]
            rws = if ring then ring[1]
                  else a < 0x10000 ? screen.tile_rows(vram, a, eight ? -1 : e >> 12, e & 0x400 != 0) : EMPTY_ROWS
                  end
            vflip = e & 0x800 != 0
            base = (ty * 8 * w + tx * 8) * 4
            8.times do |y|
              @buf[base + y * w * 4, 32] = rws[vflip ? 7 - y : y]
            end
            changed = true
          end
        end
        @bitmap.raw_data = @buf if changed
      end
    end

    #--------------------------------------------------------------------------
    # sprites
    #--------------------------------------------------------------------------
    def visible_sprites(m, dispcnt, y0, y1)
      oam = m.oam
      list = []
      127.downto(0) do |i|
        a0 = oam.getbyte(i * 8) | (oam.getbyte(i * 8 + 1) << 8)
        affine = a0 & 0x100 != 0
        dbl = a0 & 0x200 != 0
        next if !affine && dbl
        hint = @oam_hints && @oam_hints[i]
        next if hint == :hide
        mode = (a0 >> 10) & 3
        next if mode >= 2
        shape = a0 >> 14
        next if shape == 3
        a1 = oam.getbyte(i * 8 + 2) | (oam.getbyte(i * 8 + 3) << 8)
        a2 = oam.getbyte(i * 8 + 4) | (oam.getbyte(i * 8 + 5) << 8)
        w, h = OBJ_SIZES[shape][a1 >> 14]
        bw = affine && dbl ? w * 2 : w
        bh = affine && dbl ? h * 2 : h
        y = a0 & 0xFF
        if hint == :above then y -= 256 if y >= H
        elsif hint != :below then y -= 256 if y + bh > 256
        end
        x = a1 & 0x1FF
        x -= 512 if x >= 256
        next if y >= y1 || y + bh <= y0 || x >= W || x + bw <= 0
        s = { i: i, x: x, y: y, w: w, h: h, bw: bw, bh: bh, tile: a2 & 0x3FF, prio: (a2 >> 10) & 3,
              pal: a2 >> 12, eight: a0 & 0x2000 != 0, mode: mode, oned: dispcnt & 0x40 != 0 }
        if affine
          g = (a1 >> 9) & 31
          s[:matrix] = Array.new(4) { |k| v = oam.getbyte(g * 32 + 6 + k * 8) | (oam.getbyte(g * 32 + 7 + k * 8) << 8); (v ^ 0x8000) - 0x8000 }
        else
          s[:hflip] = a1 & 0x1000 != 0
          s[:vflip] = a1 & 0x2000 != 0
        end
        list << s
      end
      list
    end

    # [Bitmap, versions, unused frames, RGBA] of a sprite's picture
    def sprite_entry(m, s, used)
      key = [s[:tile], s[:w], s[:h], s[:eight], s[:eight] ? 0 : s[:pal], s[:oned], s[:hflip], s[:vflip], s[:matrix], s[:bw]]
      tiles = sprite_tiles(s)
      ver = tiles.sum { |a| a < 0x18000 ? @tile_ver[a >> 5] : 0 } + (s[:eight] ? @pal_ver[33] : @pal_ver[16 + s[:pal]])
      e = @objs[key]
      used[key] = true
      if e && e[1] == ver
        e[2] = 0
        return e
      end
      e[0].dispose if e
      buf = s[:matrix] ? affine_rgba(m, s, tiles) : plain_rgba(m, s, tiles)
      bmp = Bitmap.new(s[:bw], s[:bh])
      bmp.raw_data = buf
      @objs[key] = [bmp, ver, 0, buf]
    end

    # On the GBA the sprites make one layer before it is blended: where a
    # semi-transparent sprite is in front of another, that one isn't seen
    # (the roulette's reel is cut off this way, by sprites with alpha 0).
    # s[:masks]: the semi-transparent sprites in front of s that overlap it.
    def find_obj_masks(sprites)
      semi = sprites.select { |s| s[:mode] == 1 }
      return if semi.empty?
      sprites.each do |t|
        ms = semi.select do |s|
          !s.equal?(t) && (t[:prio] > s[:prio] || (t[:prio] == s[:prio] && t[:i] > s[:i])) &&
            s[:x] < t[:x] + t[:bw] && t[:x] < s[:x] + s[:bw] && s[:y] < t[:y] + t[:bh] && t[:y] < s[:y] + s[:bh]
        end
        t[:masks] = ms unless ms.empty?
      end
    end

    # the sprite's picture without the pixels its masks cover (for this frame)
    def masked_bitmap(m, t, used)
      buf = sprite_entry(m, t, used)[3].dup
      w = t[:bw]
      t[:masks].each do |s|
        sbuf = sprite_entry(m, s, used)[3]
        sw = s[:bw]
        dx = s[:x] - t[:x]
        dy = s[:y] - t[:y]
        ([dy, 0].max...[dy + s[:bh], t[:bh]].min).each do |y|
          ([dx, 0].max...[dx + sw, w].min).each do |x|
            buf[(y * w + x) * 4, 4] = CLEAR if sbuf.getbyte(((y - dy) * sw + x - dx) * 4 + 3) != 0
          end
        end
      end
      bmp = Bitmap.new(w, t[:bh])
      bmp.raw_data = buf
      @masked << bmp
      bmp
    end

    # VRAM offsets of the sprite's tiles, row by row
    def sprite_tiles(s)
      tw = s[:w] >> 3
      th = s[:h] >> 3
      step = s[:eight] ? 2 : 1
      row = s[:oned] ? tw * step : 32
      out = []
      th.times do |ty|
        tw.times do |tx|
          t = (s[:tile] + ty * row + tx * step) & 0x3FF
          out << 0x10000 + t * 32
        end
      end
      out
    end

    def plain_rgba(m, s, tiles)
      w = s[:w]
      h = s[:h]
      tw = w >> 3
      buf = ("\0" * (w * h * 4)).b
      variant = s[:eight] ? -2 : 16 + s[:pal]
      tiles.each_with_index do |a, k|
        tx = k % tw
        ty = k / tw
        rows = tile_rows(m.vram, a, variant, s[:hflip])
        dx = s[:hflip] ? tw - 1 - tx : tx
        8.times do |r|
          dy = ty * 8 + r
          dy = h - 1 - dy if s[:vflip]
          buf[(dy * w + dx * 8) * 4, 32] = rows[r]
        end
      end
      buf
    end

    def affine_rgba(m, s, tiles)
      w = s[:w]
      h = s[:h]
      bw = s[:bw]
      bh = s[:bh]
      tw = w >> 3
      variant = s[:eight] ? -2 : 16 + s[:pal]
      # the plain picture, line by line
      lines = Array.new(h) { String.new(capacity: w * 4, encoding: Encoding::BINARY) }
      tiles.each_with_index do |a, k|
        rows = tile_rows(m.vram, a, variant, false)
        8.times { |r| lines[(k / tw) * 8 + r] << rows[r] }
      end
      pa, pb, pc, pd = s[:matrix]
      out = String.new(capacity: bw * bh * 4, encoding: Encoding::BINARY)
      hw = bw >> 1
      hh = bh >> 1
      cw = w >> 1
      ch = h >> 1
      bh.times do |y|
        cy = y - hh
        bw.times do |x|
          cx = x - hw
          tx = ((pa * cx + pb * cy) >> 8) + cw
          ty = ((pc * cx + pd * cy) >> 8) + ch
          if tx >= 0 && ty >= 0 && tx < w && ty < h
            out << lines[ty].byteslice(tx * 4, 4)
          else
            out << CLEAR
          end
        end
      end
      out
    end

    def blit_sprite(m, s, y0, y1, opacity, used)
      bmp = s[:masks] ? masked_bitmap(m, s, used) : sprite_entry(m, s, used)[0]
      sy = [y0 - s[:y], 0].max
      ey = [y1 - s[:y], s[:bh]].min
      return if ey <= sy
      @rect.set(0, sy, s[:bw], ey - sy)
      @bitmap.blt(s[:x], s[:y] + sy + @ext, bmp, @rect, opacity)
    end
  end
end
