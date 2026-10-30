#==============================================================================
# Pokemon TCG - Game Boy Color screen emulation for the duel interface.
#
# The original draws every duel screen as a 20x18 map of 8x8 tiles
# (BGMap0) plus a CGB palette number per tile. TileMap reproduces that
# map 1:1 so screens can be ported from engine/duel/core.asm and
# engine/menus/duel.asm coordinate for coordinate; Renderer draws it to a
# 160x144 bitmap shown at 2x (the game runs at 320x288).
#
# Tile sources (Graphics/Plugins/Pokemon TCG/UI/):
#   symbols.png       SymbolsFont, the TX_SYMBOL tiles (SYM_* ids below)
#   font_half.png     HalfWidthFont: English text, 2 characters per tile
#   cgb_symbols.png   DuelCgbSymbolGraphics (card icons, face-down cards)
#   duel_other.png    DuelOtherGraphics (prize field, coin results)
#   font_full.png     full-width font 3 (rarity marks, ' and ” of lengths)
#   card_headers.png  TRAINER / ENERGY / PoKeMoN card page headers
#   Cards/*.png       card pictures, 8x6 tiles, with their own palette
#==============================================================================
module TCG
  module GB
    COLS = 20
    ROWS = 18

    # CGBDefaultPalettes (SetDefaultConsolePalettes), BGP0-BGP4, 5-bit rgb
    PALETTES = [
      [[28, 28, 24], [21, 21, 16], [10, 10, 8], [0, 0, 0]],
      [[28, 28, 24], [30, 29, 0],  [30, 3, 0],  [0, 0, 0]],
      [[28, 28, 24], [0, 18, 0],   [12, 11, 20], [0, 0, 0]],
      [[28, 28, 24], [22, 0, 22],  [27, 7, 3],  [0, 0, 0]],
      [[28, 28, 24], [26, 10, 0],  [28, 0, 0],  [0, 0, 0]],
      [[28, 28, 24], [30, 26, 8],  [28, 21, 2], [25, 17, 0]],   # PAL_HOLO_NAME (089j)
      [[28, 28, 24], [16, 12, 20], [8, 5, 12],  [0, 0, 0]],     # Darkness icons
      [[28, 28, 24], [20, 22, 25], [10, 12, 16], [0, 0, 0]]     # Metal icons
    ]
    PAL_TEXTBOX = 4   # wTextBoxFrameType in duels (Duel_Init)
    PAL_DARKNESS = 6
    PAL_METAL    = 7

    # TX_SYMBOL tile ids (constants/charmaps.asm)
    SYM_SPACE = 0x00; SYM_FIRE = 0x01; SYM_GRASS = 0x02; SYM_LIGHTNING = 0x03
    SYM_WATER = 0x04; SYM_FIGHTING = 0x05; SYM_PSYCHIC = 0x06; SYM_COLORLESS = 0x07
    SYM_POISONED = 0x08; SYM_ASLEEP = 0x09; SYM_CONFUSED = 0x0a; SYM_PARALYZED = 0x0b
    SYM_CURSOR_U = 0x0c; SYM_POKEMON = 0x0d; SYM_ATK_DESCR = 0x0e; SYM_CURSOR_R = 0x0f
    SYM_HP = 0x10; SYM_LV = 0x11; SYM_E = 0x12; SYM_NO = 0x13
    SYM_PLUSPOWER = 0x14; SYM_DEFENDER = 0x15; SYM_HP_OK = 0x16; SYM_HP_NOK = 0x17
    SYM_BOX_TOP_L = 0x18; SYM_BOX_TOP_R = 0x19; SYM_BOX_BTM_L = 0x1a; SYM_BOX_BTM_R = 0x1b
    SYM_BOX_TOP = 0x1c; SYM_BOX_BOTTOM = 0x1d; SYM_BOX_LEFT = 0x1e; SYM_BOX_RIGHT = 0x1f
    SYM_0 = 0x20; SYM_DOT = 0x2a; SYM_PLUS = 0x2b; SYM_MINUS = 0x2c; SYM_CROSS = 0x2d
    SYM_SLASH = 0x2e; SYM_CURSOR_D = 0x2f; SYM_PRIZE = 0x30
    SYM_DARKNESS = 0x38; SYM_METAL = 0x39   # added below the original tiles
    # energy symbol of each color (FIRE..COLORLESS, DARKNESS, METAL)
    COLOR_SYMBOLS = [SYM_FIRE, SYM_GRASS, SYM_LIGHTNING, SYM_WATER, SYM_FIGHTING,
                     SYM_PSYCHIC, SYM_COLORLESS, SYM_DARKNESS, SYM_METAL]

    TOKEN_SYMBOLS = {
      "FIRE" => SYM_FIRE, "GRASS" => SYM_GRASS, "LIGHTNING" => SYM_LIGHTNING,
      "WATER" => SYM_WATER, "FIGHTING" => SYM_FIGHTING, "PSYCHIC" => SYM_PSYCHIC,
      "COLORLESS" => SYM_COLORLESS, "DARKNESS" => SYM_DARKNESS, "METAL" => SYM_METAL
    }

    # half-width charmap: ascii $20-$7f plus a few specials
    HALF_SPECIAL = { "é" => 0x60, "É" => 0x40, "”" => 0x22, "\"" => 0x22, "“" => 0x22,
                     "♂" => 0x24, "♀" => 0x25, "’" => 0x27, "~" => 0x2d, "`" => 0x27,
                     " " => 0x20 }   # French no-break space before ! ? : ;

    # accented letters for the translations, added below the original glyphs
    # as codes 0x80+ by PokeTCG-mod/tools/extend_tcg_font.py (same order)
    HALF_EXTRA = "áíóúñüàèìòùâêîôûäëïöÿãõÁÍÓÚÑÜÀÈÂÊÎÔÛÄÖÃÕçÇ¿¡ßœ"
    HALF_EXTRA.each_char.with_index { |c, i| HALF_SPECIAL[c] = 0x80 + i }
    # anything else outside ASCII: the nearest plain text
    HALF_FALLBACK = { "Œ" => "OE", "«" => "\"", "»" => "\"", "–" => "-", "—" => "-", "…" => "...",
                      "Ï" => "I", "Ë" => "E", "Ÿ" => "Y", "Ì" => "I", "Ò" => "O", "Ù" => "U" }

    def self.half_code(ch)
      return HALF_SPECIAL[ch] if HALF_SPECIAL[ch]
      o = ch.ord
      (0x20..0x7f).cover?(o) ? o : 0x3f
    end

    # splits text into [:char, c] / [:sym, id] / [:nl] items
    def self.tokens(str)
      out = []
      s = str.to_s.gsub(/[^\x00-\x7f]/) { |c| HALF_SPECIAL[c] ? c : (HALF_FALLBACK[c] || c) }
      i = 0
      while i < s.size
        if s[i] == "<" && (j = s.index(">", i))
          name = s[i + 1...j]
          out << [:sym, TOKEN_SYMBOLS[name]] if TOKEN_SYMBOLS[name]
          i = j + 1
          next
        end
        out << (s[i] == "\n" ? [:nl] : [:char, s[i]])
        i += 1
      end
      out
    end

    # width in half-tiles (a symbol takes a full tile, rounded to a tile boundary)
    def self.half_width(items)
      w = 0
      items.each do |t|
        if t[0] == :sym then w += w.odd? ? 3 : 2
        else w += 1
        end
      end
      w
    end

    # word wrap to lines of `width` half tiles (36 = one 18-tile text box line);
    # existing line breaks are kept
    def self.wrap(str, width = 36)
      lines = []
      str.to_s.split("\n", -1).each do |para|
        cur = []
        # split on single spaces so aligned text ("Yours   Opponent's") keeps its runs
        para.split(/ /, -1).each_with_index do |w, i|
          wt = tokens(w)
          if i == 0
            cur = wt
            next
          end
          cand = cur + [[:char, " "]] + wt
          if !cur.empty? && half_width(cand) > width
            lines << cur
            cur = wt
          else
            cur = cand
          end
        end
        lines << cur
      end
      lines
    end

    #--------------------------------------------------------------------------
    # BGMap0 + attribute map
    #--------------------------------------------------------------------------
    class TileMap
      # cells[y][x]: Integer (symbol tile), [:half, c1, c2], [:cgb, tile] or
      # [:other, tile]; pals[y][x]: CGB palette; pictures: [x, y, gfx];
      # sprites: OAM cursors [x, y, flipped] in pixels (LoadCursorTile);
      # objs: animation OBJ tiles [x, y, tile, xflip, yflip, sheet] of
      # UI/<sheet>.png (default "coin"), made by tools/make_obj_sheets.py;
      # px_tiles: cgb_symbols tiles off the tile grid [x, y, tile, pal, tag]
      # in pixels (not from the original: the 7-9 Prize layouts), skipped
      # while their tag is hidden_tag (a blinking selection)
      attr_reader :cells, :pals, :pictures, :sprites, :objs, :px_tiles
      # BG scroll (hSCX / hSCY, screen shakes) and the white flash (DUEL_ANIM_FLASH)
      attr_accessor :scroll_x, :scroll_y, :flash, :hidden_tag

      def initialize; clear; end

      def clear
        @cells    = Array.new(ROWS) { Array.new(COLS, SYM_SPACE) }
        @pals     = Array.new(ROWS) { Array.new(COLS, 0) }
        @pictures = []
        @sprites  = []
        @objs     = []
        @px_tiles = []
        @hidden_tag = nil
        @scroll_x = @scroll_y = 0
        @flash    = false
      end

      def inside?(x, y); x >= 0 && y >= 0 && x < COLS && y < ROWS; end

      def put(x, y, cell); @cells[y][x] = cell if inside?(x, y); end
      def sym(x, y, id);   put(x, y, id); end
      def cgb(x, y, tile); put(x, y, [:cgb, tile]); end
      def full(x, y, tile); put(x, y, [:full, tile]); end   # full-width font 3
      def header(x, y, tile); put(x, y, [:hdr, tile]); end  # DuelCardHeaderGraphics
      def at(x, y);        inside?(x, y) ? @cells[y][x] : nil; end

      def fill(x, y, w, h, id = SYM_SPACE)
        h.times { |j| w.times { |i| put(x + i, y + j, id) } }
      end

      def palette(x, y, w, h, pal)
        h.times { |j| w.times { |i| @pals[y + j][x + i] = pal if inside?(x + i, y + j) } }
      end

      # card picture (LoadPlayAreaCardGfx + FillRectangle): 8x6 tiles;
      # duelist portraits are 6x6
      def picture(x, y, gfx, w = 8, h = 6)
        @pictures.reject! { |px, py, _| px == x && py == y }
        @pictures << [x, y, gfx.to_s]
        fill(x, y, w, h, [:pic])
      end

      # ProcessText: half-width characters two per tile; a TX_SYMBOL ends the
      # current half tile and takes a whole tile. "\n" goes 1 line down
      # (callers pass line_step 2 inside text boxes). Returns the next free x.
      def text(x, y, str, line_step: 1)
        x0 = x
        pending = nil
        flush = lambda do
          if pending
            put(x, y, [:half, pending, 0x20])
            x += 1
            pending = nil
          end
        end
        items = str.is_a?(Array) ? str : GB.tokens(str)
        items.each do |t|
          case t[0]
          when :nl
            flush.call
            x = x0
            y += line_step
          when :sym
            flush.call
            put(x, y, t[1])
            x += 1
          else
            c = GB.half_code(t[1])
            if pending
              put(x, y, [:half, pending, c])
              x += 1
              pending = nil
            else
              pending = c
            end
          end
        end
        flush.call
        x
      end

      # WriteOneByteNumberInTxSymbol_PadSpace: 3 symbol digits, leading spaces
      def number(x, y, n, digits = 3)
        s = n.to_s.rjust(digits)[-digits, digits]
        s.each_char.with_index do |ch, i|
          put(x + i, y, ch == " " ? SYM_SPACE : SYM_0 + ch.to_i)
        end
      end

      # DrawRegularTextBox (CGB): border + blank body, palette wTextBoxFrameType
      def box(x, y, w, h, pal = PAL_TEXTBOX)
        h.times do |j|
          w.times do |i|
            id = if j == 0
                   i == 0 ? SYM_BOX_TOP_L : (i == w - 1 ? SYM_BOX_TOP_R : SYM_BOX_TOP)
                 elsif j == h - 1
                   i == 0 ? SYM_BOX_BTM_L : (i == w - 1 ? SYM_BOX_BTM_R : SYM_BOX_BOTTOM)
                 else
                   i == 0 ? SYM_BOX_LEFT : (i == w - 1 ? SYM_BOX_RIGHT : SYM_SPACE)
                 end
            put(x + i, y + j, id)
          end
        end
        palette(x, y, w, h, pal)
        @pictures.reject! { |px, py, _| px + 8 > x && px < x + w && py + 6 > y && py < y + h }
      end

      def wide_text_box; box(0, 12, 20, 6); end

      # for the headless preview tool
      # a 2x2 cgb_symbols block at pixel x, y (like cgb + palette on the grid)
      def px_cgb_rect(x, y, tile, pal, tag = nil)
        @px_tiles << [x, y, tile, pal, tag] << [x + 8, y, tile + 1, pal, tag] <<
          [x, y + 8, tile + 2, pal, tag] << [x + 8, y + 8, tile + 3, pal, tag]
      end

      def to_h
        { "cells" => @cells, "pals" => @pals, "pictures" => @pictures, "sprites" => @sprites, "objs" => @objs,
          "px" => @px_tiles.reject { |t| !t[4].nil? && t[4] == @hidden_tag } }
      end
    end

    #--------------------------------------------------------------------------
    # draws a TileMap with the original graphics (mkxp only)
    #--------------------------------------------------------------------------
    class Renderer
      attr_reader :sprite

      def initialize(viewport)
        @bitmap = Bitmap.new(COLS * 8, ROWS * 8)
        @sprite = Sprite.new(viewport)
        @sprite.bitmap = @bitmap
        @sprite.zoom_x = @sprite.zoom_y = Graphics.width / (COLS * 8.0)
        @sheets = {}
        @pics = {}
      end

      def dispose
        @sheets.each_value(&:dispose)
        @pics.each_value { |b| b&.dispose }
        @bitmap.dispose
        @sprite.dispose
      end

      def colors(pal)
        PALETTES[pal].map { |r, g, b| Color.new(r * 255 / 31, g * 255 / 31, b * 255 / 31) }
      end

      # grayscale sheet -> colors of palette `pal` (white = shade 0 ... black = 3)
      def sheet(name, pal)
        @sheets[[name, pal]] ||= begin
          src = RPG::Cache.load_bitmap(GFX + "UI/", name)
          cols = colors(pal)
          b = Bitmap.new(src.width, src.height)
          src.height.times do |y|
            src.width.times do |x|
              v = src.get_pixel(x, y)
              shade = 3 - ((v.red + v.green + v.blue) / 3 + 42) / 85
              b.set_pixel(x, y, cols[shade.clamp(0, 3)])
            end
          end
          b
        end
      end

      def pic(gfx)
        return @pics[gfx] if @pics.key?(gfx)
        dir, name = gfx.include?("/") ? [GFX + File.dirname(gfx) + "/", File.basename(gfx)] : [GFX + "Cards/", gfx]
        @pics[gfx] = (RPG::Cache.load_bitmap(dir, name).clone rescue nil)
      end

      def tile_from(dst_x, dst_y, sheet, tile, w = 8)
        cols = sheet.width / 8
        @bitmap.blt(dst_x, dst_y, sheet, Rect.new((tile % cols) * 8, (tile / cols) * 8, w, 8))
      end

      # OBJ sheet: UI/<name>.png (4 flip columns, see tools/make_obj_sheets.py)
      def obj_sheet(sheet)
        RPG::Cache.load_bitmap(GFX + "UI/", sheet || "coin")
      end

      def draw(map)
        @bitmap.clear
        white = colors(0)[0]
        @bitmap.fill_rect(0, 0, COLS * 8, ROWS * 8, map.flash ? Color.new(255, 255, 255) : white)
        sx = map.scroll_x.to_i
        sy = map.scroll_y.to_i
        ROWS.times do |y|
          COLS.times do |x|
            break if map.flash
            c = map.cells[y][x]
            pal = map.pals[y][x]
            px = x * 8 - sx
            py = y * 8 - sy
            case c
            when Integer
              tile_from(px, py, sheet("symbols", pal), c)
            when Array
              case c[0]
              when :half
                f = sheet("font_half", pal)
                [c[1], c[2]].each_with_index do |ch, k|
                  i = ch - 0x20
                  @bitmap.blt(px + k * 4, py, f, Rect.new((i % 8) * 8, (i / 8) * 8, 4, 8))
                end
              when :cgb   then tile_from(px, py, sheet("cgb_symbols", pal), c[1])
              when :other then tile_from(px, py, sheet("duel_other", pal), c[1])
              when :full  then tile_from(px, py, sheet("font_full", pal), c[1])
              when :hdr   then tile_from(px, py, sheet("card_headers", pal), c[1])
              when :hand  then tile_from(px, py, sheet("hand_cards", pal), c[1])   # HandCardsGfx
              end
            end
          end
        end
        # left to right: a tile's white margin may overlap its right neighbour's
        # slot, so the neighbour has to be drawn after it
        map.px_tiles.sort_by { |t| t[0] }.each do |x, y, tile, pal, tag|
          break if map.flash
          next if !tag.nil? && tag == map.hidden_tag
          tile_from(x - sx, y - sy, sheet("cgb_symbols", pal), tile)
        end
        map.pictures.each do |x, y, gfx|
          break if map.flash
          b = pic(gfx)
          @bitmap.blt(x * 8 - sx, y * 8 - sy, b, Rect.new(0, 0, b.width, b.height)) if b
        end
        cur = RPG::Cache.load_bitmap(GFX + "UI/", "cursor")
        map.objs.each do |x, y, t, xf, yf, sheet|
          src = obj_sheet(sheet)
          @bitmap.blt(x, y, src, Rect.new(((xf ? 1 : 0) + (yf ? 2 : 0)) * 8, t * 8, 8, 8))
        end
        map.sprites.each do |x, y, flip|
          @bitmap.blt(x, y, cur, Rect.new(flip ? 8 : 0, 0, 8, 8))
        end
      end
    end
  end
end
