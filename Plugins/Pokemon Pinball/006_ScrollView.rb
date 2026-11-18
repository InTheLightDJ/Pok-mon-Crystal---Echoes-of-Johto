#==============================================================================
# Pokémon Pinball (GBC) - the scroll view of the Red and Blue Fields
#
# The game plays each Field as two screens (top and bottom halves): when the
# ball leaves one, the LCD goes off and the other half is loaded in its
# place. The scroll view keeps the game exactly as it is and only changes
# what is shown: both halves in one tall picture (the "world"), the half the
# ball is on drawn live every frame, the other half as it looked when the
# ball left it, and a camera that follows the ball up and down.
#   World coordinates: the top half's row r is world row YO + r, the bottom
#   half's row r is YO + DROP + r (the game moves the ball by DROP = $88
#   pixels when it changes halves, so the two line up). Columns: the BG map's
#   column c is world column XO + c (the game scrolls the 192-wide table
#   sideways itself, hSCX; the camera follows that).
#   Sprites are placed by their screen position plus the scroll registers.
#   The window (the message bar) stays at the bottom of the view.
# Options > Pinball View: Scroll (this) or Split (the game's own screens).
#==============================================================================
module PinballGBC
  CURRENT_STAGE_WRAM = 0x1000 + (0xd4ac - 0xd000)   # wCurrentStage
  BALL_Y_WRAM        = 0x1000 + (0xd4b6 - 0xd000)   # wBallYPos + 1
  SPRITE_BUFFER_WRAM = 0x1000 + (0xd000 - 0xd000)   # wSpriteBuffer (40 x 4 bytes)

  module_function

  # Options > Pinball View: 0 Scroll (default), 1 Split
  def scroll_view?
    ($PokemonSystem&.pinball_view || 0) == 0
  rescue StandardError
    true
  end

  # FieldVerticalTransition: the ball is leaving a half. It hides the ball,
  # rebuilds the sprite buffer and waits a frame before turning the LCD off,
  # so on that frame VRAM and wSpriteBuffer still hold the half being left,
  # without the ball (the Player takes its picture then).
  module StageLeave
    attr_accessor :leaving_stage
    attr_reader :changing_stage

    # while it runs, the stage is already the new half but the ball is still
    # where it was in the old one (its caller moves it by $88 after), so
    # the frames it shows aren't drawn
    def f_03_6674
      @leaving_stage = @wram[CURRENT_STAGE_WRAM]
      @changing_stage = true
      super
    ensure
      @changing_stage = false
    end
  end
  Machine.prepend(StageLeave)

  class Screen
    # Draws map rows r0...r1 of the BG (no window) at world rows base + r,
    # only world columns x0...x1, then the sprites of oam (screen positions
    # plus the scroll registers). false if the LCD shows nothing.
    def draw_world(m, world, base, r0, r1, x0, x1, oam, xo)
      sync_palettes(m) if m.pal_dirty
      sync_tiles(m)
      bands = m.line_regs
      return false if bands.empty? || bands[0][1][7] == 0
      scx = signed(bands[0][2])
      scy = signed(bands[0][3])
      saved = @bitmap
      @bitmap = world
      @tiles.clear
      @band = 0
      x0 = x0.clamp(0, world.width)
      x1 = x1.clamp(0, world.width)
      world.fill_rect(x0, base + r0, x1 - x0, r1 - r0, @white) if x1 > x0 && r1 > r0
      # each band's LCDC (the tile data area changes for the message bar)
      # from the map row its first line shows
      bands.each_with_index do |band, i|
        lcdc = band[1]
        s0 = i == 0 ? r0 : [band[0] + scy, r0].max
        s1 = i + 1 < bands.size ? [bands[i + 1][0] + scy, r1].min : r1
        next if s1 <= s0 || lcdc[7] == 0 || x1 <= x0
        layer(m, lcdc[3] == 1 ? 0x1c00 : 0x1800, lcdc[4] == 1, x0 - xo, s0, x0, x1, base + s0, base + s1)
      end
      world_sprites(m, bands[0][1], oam, xo + scx, base + scy) if bands[0][1][1] == 1
      true
    ensure
      @bitmap = saved if saved
    end

    # the message bar (the window) as the game shows it at the bottom of
    # the screen, into hud from its row 0. Returns its first screen line, or
    # nil when the window is off.
    def draw_hud(m, hud)
      bands = m.line_regs
      hud.clear
      return nil if bands.empty?
      band = bands.find { |b| b[1][5] == 1 && b[5] < H && b[4] <= 166 }
      return nil unless band
      wy = band[5]
      at = bands.select { |b| b[0] <= wy }.last || band
      lcdc = at[1]
      return nil if lcdc[7] == 0 || lcdc[5] == 0
      saved = @bitmap
      @bitmap = hud
      @tiles.clear
      win_x = at[4] - 7
      wl = [win_x, 0].max
      layer(m, lcdc[6] == 1 ? 0x1c00 : 0x1800, lcdc[4] == 1, wl - win_x, 0, wl, W, 0, H - wy) if wl < W
      wy
    ensure
      @bitmap = saved if saved
    end

    def signed(v) = v >= 128 ? v - 256 : v

    private

    # sprites at world (screen x + dx, screen y + dy); x wraps like the
    # 256-wide BG map (a sprite left of the screen can sit at x 232+)
    def world_sprites(m, lcdc, oam, dx, dy)
      tall = lcdc[2] == 1
      h = tall ? 16 : 8
      behind = []
      front = []
      39.downto(0) do |i|
        oy = oam[i * 4]
        next if oy == 0 || oy >= 0xe0   # parked ($f0) / off the table
        x = ((oam[i * 4 + 1] - 8 + dx + 64) % 256) - 64
        y = oy - 16 + dy
        (oam[i * 4 + 3][7] == 1 ? behind : front) << [i, x, y]
      end
      behind.each { |i, x, y| world_sprite(m, oam, i, x, y, tall) }
      unless behind.empty?
        @tiles.each do |slot, variant, tx, ty, sx, sy, w, hh, _prio, _b|
          next unless behind.any? { |_, x, y| tx < x + 8 && tx + w > x && ty < y + h && ty + hh > y }
          @bitmap.blt(tx, ty, tile_bitmap(m, slot, variant), Rect.new(sx, sy, w, hh))
        end
      end
      front.each { |i, x, y| world_sprite(m, oam, i, x, y, tall) }
      return if lcdc[0] == 0
      @tiles.each do |slot, variant, tx, ty, sx, sy, w, hh, prio, _b|
        @bitmap.blt(tx, ty, tile_bitmap(m, slot, variant), Rect.new(sx, sy, w, hh)) if prio
      end
    end

    def world_sprite(m, oam, i, x, y, tall)
      tile = oam[i * 4 + 2]
      attr = oam[i * 4 + 3]
      bank = attr[3] == 1 ? 384 : 0
      variant = (8 + (attr & 7)) | ((attr & 0x60) >> 1) | 0x40
      y1 = @bitmap.height
      if tall
        top = tile & 0xfe
        bottom = tile | 1
        top, bottom = bottom, top if attr[6] == 1
        blt_clipped(m, bank + top, variant, x, y, 0, y1)
        blt_clipped(m, bank + bottom, variant, x, y + 8, 0, y1)
      else
        blt_clipped(m, bank + tile, variant, x, y, 0, y1)
      end
    end
  end

  class ScrollView
    XO   = 16                    # world columns left of the BG map's column 0
    YO   = 16                    # world rows above the top half's row 0
    DROP = 0x88                  # the bottom half's row 0 in the top half's rows
    VW   = Screen::W
    VH   = Screen::H
    WW   = XO + 192 + XO         # the table is 192 wide (hSCX 0-32)
    WH   = YO + DROP + VH + YO
    FIELD_STAGES = [0, 1, 4, 5]  # Red top / bottom, Blue top / bottom
    CAMERA_STEP  = 10            # most pixels the camera moves in a frame
    MARGIN       = 8             # extra pixels drawn around the view

    attr_reader :world, :hud, :view_x, :view_y, :hud_y

    def initialize(screen)
      @screen = screen
      @world = Bitmap.new(WW, WH)
      @hud = Bitmap.new(VW, VH)
      @snaps = {}                # stage => its picture (the rows of region)
      @black = Color.new(0, 0, 0)
    end

    def dispose
      @snaps.each_value(&:dispose)
      @world.dispose
      @hud.dispose
    end

    def self.field?(m)
      m.wram[CURRENT_SCREEN_WRAM] == SCREEN_PINBALL_GAME && FIELD_STAGES.include?(m.wram[CURRENT_STAGE_WRAM])
    end

    def base(stage) = stage.even? ? YO : YO + DROP

    # map rows [r0, r1) of a half kept in the world (the bottom half's first
    # 8 rows are the top half's last 8, drawn by whichever half is live)
    def region(stage) = stage.even? ? [-YO, VH] : [0, VH + YO]

    # the ball is leaving this half: keep how it looks (sprites from the
    # sprite buffer, the ball already taken out)
    def snapshot(m, stage)
      return unless FIELD_STAGES.include?(stage)
      r0, r1 = region(stage)
      snap = (@snaps[stage] ||= Bitmap.new(WW, r1 - r0))
      # drawn straight into it: its row 0 is map row r0
      @snaps.delete(stage).dispose unless @screen.draw_world(m, snap, -r0, r0, r1, 0, WW, m.wram[SPRITE_BUFFER_WRAM, 160], XO)
    end

    # fresh: the first frame on a Field (the camera starts on the ball)
    def draw(m, fresh)
      stage = m.wram[CURRENT_STAGE_WRAM]
      other = stage ^ 1
      bands = m.line_regs
      scx = @screen.signed(bands[0][2])
      scy = @screen.signed(bands[0][3])
      follow(m, stage, fresh)
      vx = (XO + scx).clamp(0, WW - VW)
      vy = (@cam.round + scy).clamp(0, WH - VH)
      # the other half (black until the ball has been there)
      o0, o1 = region(other)
      if (snap = @snaps[other])
        @world.blt(0, base(other) + o0, snap, Rect.new(0, 0, WW, snap.height))
      else
        @world.fill_rect(0, base(other) + o0, WW, o1 - o0, @black)
      end
      # the live half: the rows and columns in view
      r0, r1 = region(stage)
      b = base(stage)
      l0 = [r0, vy - b - MARGIN].max
      l1 = [r1, vy + VH - b + MARGIN].min
      l0 = l1 = r0 if l1 < l0
      @screen.draw_world(m, @world, b, l0, l1, vx - MARGIN, vx + VW + MARGIN, m.oam, XO)
      @view_x = vx
      @view_y = vy
      @hud_y = @screen.draw_hud(m, @hud)
    end

    private

    # the camera keeps the ball in the middle, inside the halves it can show
    def follow(m, stage, fresh)
      ball = base(stage) + m.wram[BALL_Y_WRAM] - 8
      target = ball - VH / 2
      both = @snaps.key?(stage ^ 1)
      lo = stage.even? || both ? YO : YO + DROP
      hi = stage.odd? || both ? YO + DROP : YO
      target = target.clamp(lo, hi)
      if fresh || @cam.nil?
        @cam = target.to_f
      else
        @cam += ((target - @cam) * 0.3).clamp(-CAMERA_STEP, CAMERA_STEP)
        @cam = @cam.clamp(lo.to_f, hi.to_f)
      end
    end
  end
end

#==============================================================================
# Options > Pinball View
#==============================================================================
class PokemonSystem
  attr_writer :pinball_view

  def pinball_view
    @pinball_view ||= 0
  end
end

MenuHandlers.add(:options_menu, :pinball_view, {
  "name"        => _INTL("Pinball View"),
  "order"       => 125,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Scroll"), _INTL("Split")],
  "description" => _INTL("How Pokémon Pinball shows the Red and Blue Fields: one table that scrolls with the ball, or two screens."),
  "get_proc"    => proc { next $PokemonSystem.pinball_view },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.pinball_view = value }
})
