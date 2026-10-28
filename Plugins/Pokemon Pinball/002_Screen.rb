#==============================================================================
# Pokémon Pinball (GBC) - the LCD: draws the machine's VRAM / OAM / palettes
# into a 160x144 Bitmap with blits (the per-scanline yardstick is
# Pinball-mod/tools/render_gbc.py).
#   Tiles are cached as 8x8 Bitmaps per (VRAM bank, tile, palette, flips,
#   opaque / transparent color 0) and rebuilt only when their tile data
#   (Machine#tile_dirty) or their palette changes.
#   Each band of lines with its own LCDC / scroll / window registers
#   (Machine#line_regs, the status bar split) is drawn separately.
#   Order: BG (opaque) -> sprites behind BG -> BG colors 1-3 over them ->
#   other sprites -> BG tiles with the priority attribute (colors 1-3).
#   Sprites are drawn band by band too: a band can switch them off (the
#   score / message box) or change their size.
#==============================================================================
module PinballGBC
  class Screen
    W = 160
    H = 144

    attr_reader :bitmap

    def initialize
      @bitmap = Bitmap.new(W, H)
      @cache = {}           # slot (bank * 384 + tile) => { variant => Bitmap }
      @pixels = {}          # slot => 64 color indices
      @bg_colors = Array.new(32) { Color.new(255, 255, 255) }
      @obj_colors = Array.new(32) { Color.new(255, 255, 255) }
      @white = Color.new(255, 255, 255)
      @tiles = []           # BG tiles drawn this frame: [slot, variant, dx, dy, sx, sy, w, h, priority, band]
    end

    def dispose
      @cache.each_value { |h| h.each_value(&:dispose) }
      @bitmap.dispose
    end

    def draw(m)
      sync_palettes(m) if m.pal_dirty
      sync_tiles(m)
      bands = m.line_regs
      @tiles.clear
      @bitmap.fill_rect(0, 0, W, H, @white)
      return if bands.none? { |b| b[1][7] == 1 }
      bands.each_with_index do |band, i|
        y1 = i + 1 < bands.size ? bands[i + 1][0] : H
        next unless y1 > band[0]
        @band = i
        draw_band(m, band, band[0], y1)
      end
      bands.each_with_index do |band, i|
        y1 = i + 1 < bands.size ? bands[i + 1][0] : H
        draw_sprites(m, band[1], band[0], y1, i) if y1 > band[0] && band[1][7] == 1
      end
    end

    #--------------------------------------------------------------------------
    # palettes / tiles
    #--------------------------------------------------------------------------
    def sync_palettes(m)
      changed = []
      8.times do |p|
        bg = m.bg_pal[p * 8, 8]
        obj = m.obj_pal[p * 8, 8]
        if @bg_raw.nil? || @bg_raw[p] != bg
          changed << p
          4.times { |c| @bg_colors[p * 4 + c] = color555(bg, c) }
        end
        if @obj_raw.nil? || @obj_raw[p] != obj
          changed << p + 8
          4.times { |c| @obj_colors[p * 4 + c] = color555(obj, c) }
        end
      end
      @bg_raw = Array.new(8) { |p| m.bg_pal[p * 8, 8] }
      @obj_raw = Array.new(8) { |p| m.obj_pal[p * 8, 8] }
      unless changed.empty?
        @cache.each_value do |h|
          h.delete_if do |variant, bmp|
            next false unless changed.include?(variant & 15)
            bmp.dispose
            true
          end
        end
      end
      m.pal_dirty = false
    end

    def color555(raw, c)
      v = raw[c * 2] | (raw[c * 2 + 1] << 8)
      Color.new((v & 31) * 255 / 31, ((v >> 5) & 31) * 255 / 31, ((v >> 10) & 31) * 255 / 31)
    end

    def sync_tiles(m)
      dirty = m.tile_dirty
      dirty.each_index do |slot|
        next unless dirty[slot]
        dirty[slot] = false
        @pixels.delete(slot)
        h = @cache.delete(slot)
        h&.each_value(&:dispose)
      end
    end

    def tile_pixels(m, slot)
      @pixels[slot] ||= begin
        vram = m.vram
        base = (slot >= 384 ? 0x2000 : 0) + (slot % 384) * 16
        px = Array.new(64)
        8.times do |y|
          lo = vram[base + y * 2]
          hi = vram[base + y * 2 + 1]
          8.times do |x|
            b = 7 - x
            px[y * 8 + x] = ((lo >> b) & 1) | (((hi >> b) & 1) << 1)
          end
        end
        px
      end
    end

    # variant: bits 0-3 palette (8+ = OBJ), 4 xflip, 5 yflip, 6 color 0 transparent
    def tile_bitmap(m, slot, variant)
      h = (@cache[slot] ||= {})
      h[variant] ||= begin
        px = tile_pixels(m, slot)
        pal = variant & 15
        colors = pal >= 8 ? @obj_colors : @bg_colors
        cbase = (pal & 7) * 4
        xf = variant[4] == 1
        yf = variant[5] == 1
        clear0 = variant[6] == 1
        bmp = Bitmap.new(8, 8)
        8.times do |y|
          row = (yf ? 7 - y : y) * 8
          x = 0
          while x < 8
            c = px[row + (xf ? 7 - x : x)]
            run = 1
            run += 1 while x + run < 8 && px[row + (xf ? 7 - (x + run) : x + run)] == c
            bmp.fill_rect(x, y, run, 1, colors[cbase + c]) unless clear0 && c == 0
            x += run
          end
        end
        bmp
      end
    end

    #--------------------------------------------------------------------------
    # BG / window for lines y0...y1
    #--------------------------------------------------------------------------
    def draw_band(m, band, y0, y1)
      _, lcdc, scx, scy, wx, wy = band
      return if lcdc[7] == 0
      unsigned = lcdc[4] == 1
      win_x = wx - 7
      win_on = lcdc[5] == 1 && wx <= 166 && wy < y1
      wy0 = win_on ? [y0, wy].max : y1
      bg_map = lcdc[3] == 1 ? 0x1c00 : 0x1800
      win_map = lcdc[6] == 1 ? 0x1c00 : 0x1800
      wl = [win_x, 0].max
      # BG: the whole band, except where the window covers it
      layer(m, bg_map, unsigned, scx, y0 + scy, 0, W, y0, wy0) if wy0 > y0
      if win_on
        layer(m, bg_map, unsigned, scx, wy0 + scy, 0, wl, wy0, y1) if wl > 0
        # the window's line counter: its row 0 is screen line wy
        layer(m, win_map, unsigned, wl - win_x, wy0 - wy, wl, W, wy0, y1) if wl < W
      end
    end

    # screen pixel (x, y), x0 <= x < x1 and y0 <= y < y1, shows map pixel
    # (x - x0 + src_x0, y - y0 + src_y0) (both wrap at 256)
    def layer(m, map, unsigned, src_x0, src_y0, x0, x1, y0, y1)
      vram = m.vram
      fy = src_y0 & 7
      ty = y0 - fy
      my = src_y0 - fy
      while ty < y1
        row = map + ((my & 255) >> 3) * 32
        fx = src_x0 & 7
        tx = x0 - fx
        mx = src_x0 - fx
        while tx < x1
          ti = row + ((mx & 255) >> 3)
          tile = vram[ti]
          attr = vram[0x2000 + ti]
          slot = (attr[3] == 1 ? 384 : 0) + (unsigned ? tile : 256 + ((tile ^ 0x80) - 0x80))
          variant = (attr & 7) | ((attr & 0x60) >> 1)
          sx = tx < x0 ? x0 - tx : 0
          sy = ty < y0 ? y0 - ty : 0
          w = (tx + 8 > x1 ? x1 - tx : 8) - sx
          h = (ty + 8 > y1 ? y1 - ty : 8) - sy
          if w > 0 && h > 0
            @bitmap.blt(tx + sx, ty + sy, tile_bitmap(m, slot, variant), Rect.new(sx, sy, w, h))
            @tiles << [slot, variant | 0x40, tx + sx, ty + sy, sx, sy, w, h, attr[7] == 1, @band]
          end
          tx += 8
          mx += 8
        end
        ty += 8
        my += 8
      end
    end

    #--------------------------------------------------------------------------
    # sprites
    #--------------------------------------------------------------------------
    # sprites on lines y0...y1 with this band's LCDC (lcdc bit 1: sprites on,
    # bit 2: 8x16, bit 0: BG priority)
    def draw_sprites(m, lcdc, y0, y1, band)
      if lcdc[1] == 1
        oam = m.oam
        tall = lcdc[2] == 1
        h = tall ? 16 : 8
        behind = []
        front = []
        # a lower OAM index is drawn on top, so draw from the end
        39.downto(0) do |i|
          y = oam[i * 4] - 16
          x = oam[i * 4 + 1] - 8
          next if y + h <= y0 || y >= y1 || x <= -8 || x >= W
          (oam[i * 4 + 3][7] == 1 ? behind : front) << i
        end
        behind.each { |i| draw_sprite(m, i, tall, y0, y1) }
        cover_sprites(m, behind, h, band) unless behind.empty?
        front.each { |i| draw_sprite(m, i, tall, y0, y1) }
      end
      # BG tiles with the priority attribute stay over every sprite
      return if lcdc[0] == 0
      @tiles.each do |slot, variant, dx, dy, sx, sy, w, hh, prio, b|
        @bitmap.blt(dx, dy, tile_bitmap(m, slot, variant), Rect.new(sx, sy, w, hh)) if prio && b == band
      end
    end

    def draw_sprite(m, i, tall, y0, y1)
      oam = m.oam
      y = oam[i * 4] - 16
      x = oam[i * 4 + 1] - 8
      tile = oam[i * 4 + 2]
      attr = oam[i * 4 + 3]
      bank = attr[3] == 1 ? 384 : 0
      variant = (8 + (attr & 7)) | ((attr & 0x60) >> 1) | 0x40
      if tall
        top = tile & 0xfe
        bottom = tile | 1
        top, bottom = bottom, top if attr[6] == 1
        blt_clipped(m, bank + top, variant, x, y, y0, y1)
        blt_clipped(m, bank + bottom, variant, x, y + 8, y0, y1)
      else
        blt_clipped(m, bank + tile, variant, x, y, y0, y1)
      end
    end

    # an 8x8 sprite tile at (x, y), only its rows inside y0...y1
    def blt_clipped(m, slot, variant, x, y, y0, y1)
      sy = y < y0 ? y0 - y : 0
      h = (y + 8 > y1 ? y1 - y : 8) - sy
      return if h <= 0
      @bitmap.blt(x, y + sy, tile_bitmap(m, slot, variant), Rect.new(0, sy, 8, h))
    end

    # sprites behind the BG: the BG's colors 1-3 are drawn again over them
    def cover_sprites(m, list, h, band)
      rects = list.map { |i| [m.oam[i * 4 + 1] - 8, m.oam[i * 4] - 16] }
      @tiles.each do |slot, variant, dx, dy, sx, sy, w, hh, _prio, b|
        next unless b == band
        next unless rects.any? { |x, y| dx < x + 8 && dx + w > x && dy < y + h && dy + hh > y }
        @bitmap.blt(dx, dy, tile_bitmap(m, slot, variant), Rect.new(sx, sy, w, hh))
      end
    end
  end
end
