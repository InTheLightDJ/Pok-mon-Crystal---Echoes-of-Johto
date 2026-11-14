#==============================================================================
# Pokémon Pinball: Ruby & Sapphire (GBA) - playing it: pbPokemonPinballRS
#
# Loads the translated game (Data/Pinball_RS_Code.rxdata) and its ROM data
# (Data/Pinball_RS_Rom.rxdata) the first time, made by
# Pinball-mod/tools/rs/package_rs.py. Runs one game frame per screen frame.
#
# Keys (GBA -> Essentials input), like Pokémon Pinball (GBC):
#   D-pad  arrows        A  Use (C)        B  Back (X)
#   Start  Action (Z)    Select  Special
#   L  JumpUp / Aux1 (tilt left)    R  JumpDown / Aux2 (tilt right)
#   On a table, Right is the right flipper (A) instead of D-pad right, so
#   Left / Right arrows work the two flippers. Menus keep the plain D-pad.
#   On the title menu Back closes the minigame (it opens on the menu: the
#   "Press Start" screen is skipped). Anywhere else: hold Back for 2 seconds
#   to quit.
#
# From an event: Script command `pbPokemonPinballRS`.
# The table is the one in front of the player: facing left, the Ruby Field;
# facing right, the Sapphire Field. Game Start then skips the Field Select
# screen and starts that table (with the saved ball speed); any other way the
# screen shows both, as in the game. The intro
# (copyright, Torchic and Pikachu scenes) is skipped: it starts at the title.
# The game's own save (high scores, Pokédex, options, a suspended game) is
# kept in the save folder as PokemonPinballRS.sav. At game over (Ruby or
# Sapphire field) the score earns Server Tokens (1 per 1,000,000,000
# points, server: handlers/pinball.js, game 'rs').
# Online, the High Scores screen shows the server's boards instead (the top
# 5 players of each field this season; the season's top 5 win tokens). The
# saved file keeps the offline scores.
#==============================================================================
module PinballRS
  CODE_FILE = "Data/Pinball_RS_Code.rxdata"
  ROM_FILE  = "Data/Pinball_RS_Rom.rxdata"
  SAVE_NAME = "PokemonPinballRS.sav"
  QUIT_HOLD_FRAMES = 120

  BTN_A = 0x1; BTN_B = 0x2; BTN_SELECT = 0x4; BTN_START = 0x8
  BTN_RIGHT = 0x10; BTN_LEFT = 0x20; BTN_UP = 0x40; BTN_DOWN = 0x80
  BTN_R = 0x100; BTN_L = 0x200

  # gMain (struct Main) fields
  MAIN_STATE   = 0x02
  SUB_STATE    = 0x03
  FIELD        = 0x04
  EXIT_STATE   = 0x0E
  FINAL_LO     = 0x58
  FINAL_HI     = 0x5C
  SAVE_DATA    = 0x74
  # struct SaveData: highScores[2][8] of { u32 name[4]; u32 scoreHi, scoreLo } at
  SD_SCORES    = 0xE4
  SD_CHECKSUM  = 0x26E
  SD_SIZE      = 0x274
  SCORE_SIZE   = 24
  NUM_SCORES   = 8
  # the two copies of SaveData in SRAM
  SRAM_COPIES  = [0x4, 0x2A4]

  STATE_TITLE      = 1
  STATE_GAME_MAIN  = 2
  STATE_SCORES_MAIN = 8
  STATE_SCORES_IDLE = 9
  TITLE_PRESS_START = 1
  TITLE_MENU_INPUT  = [4, 5]   # SUBSTATE_MENU_INPUT_NO_SAVED_GAME / _SAVED_GAME
  FIELDS = ["ruby", "sapphire"]

  module_function

  def loaded?; defined?(Machine::FUNCS); end

  def load_game
    return if loaded?
    code = Zlib::Inflate.inflate(load_data(CODE_FILE))
    code.force_encoding(Encoding::UTF_8)
    code = tall_code(code)
    eval(code, TOPLEVEL_BINDING, "pinball_rs_code.rb")
    Machine.define_native_stubs
    @rom = Zlib::Inflate.inflate(load_data(ROM_FILE)).force_encoding(Encoding::BINARY)
  end

  def rom; @rom; end

  # The tall view (002_Screen.rb): lines added above and below the GBA's 160
  # so that, at the window's width, it fills the window's height (28 at
  # 320x288). The main tables' camera then stops that much sooner at both
  # ends (gFieldBoardConfigs: start / max / min camera y), so the view never
  # shows more of a table than the game ever did.
  BOARD_CONFIGS_SIZE = 0x54
  BOARD_START_Y = 0x2; BOARD_MAX_Y = 0x4; BOARD_MIN_Y = 0x6
  MAIN_FIELD_COUNT = 2

  # the camera tests of TallSprites, made to read the machine's tall_ext
  TALL_CAMERA_FUNCS = %w[f_UpdateFrameProcess0_DefaultSpriteState_RubyBoard
                         f_UpdateFrameProcess0_DefaultSpriteState_SapphireBoard
                         f_UpdateRubyBoardEntityRendering f_UpdateSapphireBoardEntityRendering]
  CAMERA_READ = "rs16((r32(0x20314e0) + 104))"   # gCurrentPinballGame->cameraYViewport

  def tall_code(code)
    cam = Regexp.escape(CAMERA_READ)
    TALL_CAMERA_FUNCS.each do |f|
      from = code.index("def #{f}()") or next
      to = code.index("\n    def ", from + 1) || code.size
      body = code[from...to]
      body = body.gsub(/#{cam} < (\d+)/) { "#{CAMERA_READ} < (#{$1} + @tall_ext.to_i)" }
      body = body.gsub(/#{cam} > (\d+)/) { "#{CAMERA_READ} > (#{$1} - @tall_ext.to_i)" }
      body = body.gsub(/(\d+) < #{cam}/) { "(#{$1} - @tall_ext.to_i) < #{CAMERA_READ}" }
      code = code[0...from] + body + code[to..]
    end
    code
  end

  def tall_ext
    ((240.0 * Graphics.height / Graphics.width - 160) / 2).floor.clamp(0, 48)
  end

  # sprite groups whose base y is one of these are parked out of sight by
  # the game (just past the GBA's 160 lines): in the tall view they'd show
  PARKED_Y = [180, 200, -30, -40, -50, -60]
  PAUSE_GROUPS = 3                 # SG_PAUSE_PANEL, _TOP_BORDER, _BOTTOM_BORDER
  SPRITE_GROUP_SIZE_TALL = 184
  MAIN_SPRITE_GROUPS_TALL = 0x2F8
  CAMERA_Y_VIEWPORT = 0x68         # gCurrentPinballGame->cameraYViewport

  def tall_rom(rom, ext)
    return rom if ext <= 0
    rom = rom.dup
    base = Machine::SYMS.fetch("gFieldBoardConfigs") & 0x1FFFFFF
    MAIN_FIELD_COUNT.times do |f|
      a = base + (f * BOARD_CONFIGS_SIZE)
      { BOARD_START_Y => -ext, BOARD_MAX_Y => -ext, BOARD_MIN_Y => ext }.each do |o, d|
        v = rom.byteslice(a + o, 2).unpack1("s<") + d
        # the camera's top is 80 above its target: not above the table's top
        v = [v, 80 + ext].max if o == BOARD_MIN_Y
        rom[a + o, 2] = [v].pack("s<")
      end
    end
    rom
  end

  def save_path
    dir = (RTP.getSaveFolder rescue nil) || "."
    File.join(dir, SAVE_NAME)
  end

  def online?
    defined?(NetworkAuth) && NetworkAuth.logged_in?
  end

  # up to 4 letters of a player name in the high score letters
  # (A-Z 0-25, 0-9 26-35, blank 41)
  def board_name(name)
    chars = name.to_s.upcase.gsub(/[^A-Z0-9]/, "")[0, 4].chars.map { |c| c =~ /\d/ ? 26 + c.to_i : c.ord - 65 }
    chars + [41] * (4 - chars.size)
  end

  # the board and Server Tokens (1 per 1,000,000,000 points; the server
  # decides; offline nothing)
  def report_score(score, field)
    return if score <= 0 || !online?
    NetworkClient.send_msg({ action: "pinball_result", game: "rs", field: field, score: score })
  rescue StandardError
    nil
  end

  #--- the last name entered (PinballNames.dat in the save folder, shared
  # with Pokémon Pinball under its own key) ---
  NAMES_FILE = "PinballNames.dat"

  def names_path = File.join((RTP.getSaveFolder rescue nil) || ".", NAMES_FILE)

  def saved_names
    names = File.open(names_path, "rb") { |f| Marshal.load(f) }
    names.is_a?(Hash) ? names : {}
  rescue StandardError
    {}
  end

  # 4 letters as the name entry has them (0-41); the first time, the player's name
  def last_name
    n = saved_names["rs"]
    return n if n.is_a?(Array) && n.size == 4 && n.all? { |c| c.is_a?(Integer) && c.between?(0, 41) }
    board_name(($player&.name rescue nil).to_s)
  end

  def save_last_name(letters)
    names = saved_names
    return if names["rs"] == letters
    names["rs"] = letters
    File.open(names_path, "wb") { |f| Marshal.dump(names, f) }
  rescue StandardError
    nil
  end

  def checksum(data)
    sum = 0
    (data.bytesize / 2).times { |i| sum += data.getbyte(i * 2) | (data.getbyte(i * 2 + 1) << 8) }
    sum = (sum & 0xFFFF) + (sum >> 16)
    ~((sum >> 16) + sum) & 0xFFFF
  end

  class Player
    KEYS = [[:LEFT, BTN_LEFT], [:RIGHT, BTN_RIGHT], [:UP, BTN_UP], [:DOWN, BTN_DOWN],
            [:USE, BTN_A], [:BACK, BTN_B], [:ACTION, BTN_START], [:SPECIAL, BTN_SELECT],
            [:JUMPUP, BTN_L], [:AUX1, BTN_L], [:JUMPDOWN, BTN_R], [:AUX2, BTN_R]]

    # field: 0 Ruby / 1 Sapphire (only that table on the Field Select screen), or nil
    def play(field: nil)
      @field = field
      unless PinballRS.loaded?
        msg = Window_AdvancedTextPokemon.new(_INTL("Loading Pokémon Pinball..."))
        msg.z = 99_999
        pbBottomLeftLines(msg, 2)
        Graphics.update
        begin
          PinballRS.load_game
        ensure
          msg.dispose
        end
      end
      @ext = PinballRS.tall_ext
      @machine = new_machine
      @main = @machine.sym("gMain")
      load_sram
      @machine.hooks[:game_over] = method(:on_game_over)
      start_server_board
      Sound.install(@machine)
      @screen = Screen.new(@ext)
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 200_000   # over every menu it may be opened from (the debug menu is 99_999)
      @back = Sprite.new(@viewport)
      @back.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @back.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = @screen.bitmap
      sh = @screen.bitmap.height
      zoom = [Graphics.width / 240.0, Graphics.height / sh.to_f].min
      @sprite.zoom_x = @sprite.zoom_y = zoom
      @sprite.x = (Graphics.width - 240 * zoom) / 2
      @sprite.y = (Graphics.height - sh * zoom) / 2
      @sprite.z = 1
      $game_system.bgm_memorize rescue nil
      pbBGMStop rescue nil
      @machine.start
      run
    ensure
      save_sram
      NetworkClient.remove("pinball_board", @board_cb) if @board_cb
      @sprite&.dispose
      @back&.bitmap&.dispose
      @back&.dispose
      @screen&.dispose
      @viewport&.dispose
      Sound.stop
      $game_system.bgm_restore rescue nil
    end

    def run
      hold = 0
      loop do
        Graphics.update
        Input.update
        break if back_quits? && Input.trigger?(Input::BACK)
        @machine.buttons = read_buttons
        begin
          @machine.step_frame
        rescue Machine::SoftReset
          @machine = restart_machine
          next
        end
        update_server_board
        @screen.tall = on_main_table?
        @screen.oam_hints = @screen.tall ? @machine.oam_hints : nil
        @screen.draw(@machine)
        save_sram if @machine.sram_dirty && @machine.frames % 300 == 0
        hold = Input.press?(Input::BACK) ? hold + 1 : 0
        if hold >= QUIT_HOLD_FRAMES
          hold = 0
          break if confirm_quit
        end
      end
    end

    # A+B+Start+Select: the game resets itself
    def restart_machine
      save_sram
      m = new_machine
      m.hooks[:game_over] = method(:on_game_over)
      @machine = m
      load_sram
      Sound.install(m)
      m.start
      m
    end

    def new_machine
      m = Machine.new(PinballRS.tall_rom(@field ? PinballRS.one_field_rom(@field) : PinballRS.rom, @ext))
      m.one_field = @field
      m.tall_ext = @ext
      m
    end

    def main_state = @machine.r8(@main + MAIN_STATE)
    # playing on Ruby / Sapphire (not a bonus table): the tall view
    def on_main_table? = main_state == STATE_GAME_MAIN && @machine.r8(@main + MAIN_IS_BONUS_FIELD) == 0
    def sub_state = @machine.r8(@main + SUB_STATE)

    # the title's menu (or its "Press Start", if it ever shows): Back quits
    def back_quits?
      main_state == STATE_TITLE && (sub_state == TITLE_PRESS_START || TITLE_MENU_INPUT.include?(sub_state))
    end

    def read_buttons
      btn = KEYS.sum { |key, bit| Input.const_defined?(key) && Input.press?(Input.const_get(key)) ? bit : 0 }
      btn |= BTN_L if btn & BTN_L != 0
      btn = (btn & 0x3FF)
      if main_state == STATE_GAME_MAIN && btn & BTN_RIGHT != 0
        btn = (btn & ~BTN_RIGHT) | BTN_A     # Right arrow = right flipper
      end
      # Back closes the minigame on the title: the game doesn't see it there
      btn &= ~BTN_B if back_quits?
      btn
    end

    def confirm_quit
      @viewport.visible = false
      pbConfirmMessage(_INTL("Quit Pokémon Pinball?"))
    ensure
      @viewport.visible = true
    end

    # PinballGame_State3_4B20C: a game on a main field has ended
    def on_game_over(m)
      return unless m.r8(@main + EXIT_STATE) == 0
      field = FIELDS[m.r8(@main + FIELD)]
      return unless field
      score = m.r32(@main + FINAL_HI) * 100_000_000 + m.r32(@main + FINAL_LO)
      drop_own_entry(field, score)
      PinballRS.report_score(score, field)
    end

    #--- the server's boards (online only) ---
    def start_server_board
      return unless PinballRS.online?
      @board_cb = NetworkClient.on("pinball_board") do |d|
        next unless d["game"] == "rs"
        @board = FIELDS.to_h { |f| [f, Array(d.dig("fields", f)).map { |u, sc| [u.to_s, sc.to_i] }] }
        @board_dirty = true
      end
      NetworkClient.send_msg({ action: "pinball_board", game: "rs" })
    rescue StandardError
      @board_cb = nil
    end

    # writes the boards into the game's high score tables, except while the
    # High Scores screen runs (it shows and may change the tables)
    def update_server_board
      return unless @board_cb
      NetworkClient.update
      st = main_state
      in_scores = [STATE_SCORES_MAIN, STATE_SCORES_IDLE].include?(st)
      @board_dirty = true if @last_in_scores && !in_scores
      @last_in_scores = in_scores
      return unless @board && @board_dirty && !in_scores && st >= STATE_TITLE
      @board.each { |field, rows| write_board(field, rows) }
      @board_dirty = false
      @board_used = true
    end

    def score_addr(field, i)
      @main + SAVE_DATA + SD_SCORES + (FIELDS.index(field) * NUM_SCORES + i) * SCORE_SIZE
    end

    def write_board(field, rows)
      NUM_SCORES.times do |i|
        name, score = rows[i] || ["", 0]
        a = score_addr(field, i)
        letters = rows[i] ? PinballRS.board_name(name) : [40] * 4
        letters.each_with_index { |c, j| @machine.w32(a + j * 4, c) }
        @machine.w32(a + 16, score / 100_000_000)
        @machine.w32(a + 20, score % 100_000_000)
      end
    end

    # the server keeps one score per player: a new best replaces the old one,
    # so it leaves the table the game is about to put the new score into
    def drop_own_entry(field, score)
      return unless @board_used && @board
      me = (NetworkAuth.username rescue nil).to_s
      rows = @board[field]
      own = rows.index { |u, _| u.casecmp?(me) }
      return unless own && rows[own][1] < score
      write_board(field, rows.reject.with_index { |_, i| i == own })
    end

    #--- the save file ---
    def load_sram
      data = File.binread(PinballRS.save_path) rescue nil
      @machine.sram[0, data.bytesize] = data.b if data && data.bytesize <= @machine.sram.bytesize
      @local_scores = @machine.sram.byteslice(SRAM_COPIES[0] + SD_SCORES, NUM_SCORES * 2 * SCORE_SIZE)
    end

    # the saved high scores stay the offline ones
    def save_sram
      return unless @machine
      save_name
      sram = @machine.sram
      if @board_used
        sram = sram.dup
        SRAM_COPIES.each do |base|
          block = sram.byteslice(base, SD_SIZE)
          next unless block.getbyte(SD_CHECKSUM) || nil
          block[SD_SCORES, @local_scores.bytesize] = @local_scores
          block.setbyte(SD_CHECKSUM, 0)
          block.setbyte(SD_CHECKSUM + 1, 0)
          sum = PinballRS.checksum(block)
          block.setbyte(SD_CHECKSUM, sum & 0xFF)
          block.setbyte(SD_CHECKSUM + 1, sum >> 8)
          sram[base, SD_SIZE] = block
        end
      end
      File.binwrite(PinballRS.save_path, sram)
      @machine.sram_dirty = false
    rescue StandardError
      nil
    end

    # the name the game keeps for the next entry (set when one is done)
    def save_name
      a = @machine.sym("gHighScoreNameEntry")
      letters = (0...4).map { |i| @machine.r32(a + (i * 4)) }
      PinballRS.save_last_name(letters) if letters.all? { |c| c.between?(0, 41) } && letters != PinballRS.last_name
    rescue StandardError
      nil
    end
  end

  # The name entry starts on the last name entered: the game keeps it in
  # gHighScoreNameEntry, which it clears (to AAAA) at boot.
  module RememberName
    def f_ClearHighScoreNameEntry
      a = sym("gHighScoreNameEntry")
      PinballRS.last_name.each_with_index { |c, i| w32(a + (i * 4), c) }
    end
  end
  Machine.prepend(RememberName)

  # the game-over hook (PinballGame_State3_4B20C ends a game)
  module GameOverHook
    def f_PinballGame_State3_4B20C
      super
      @hooks[:game_over]&.call(self)
    end
  end
  Machine.prepend(GameOverHook)

  # No Options on the title menu (the controls are Essentials' own, F1):
  # HI-SCORE moves up into its row, the last row is left empty and the
  # cursor doesn't go there.
  module TitleMenuWithoutOptions
    MENU_TEXT = 0x06010000 + 15 * 32                   # OBJ_VRAM_ADDR_MENU_BUTTON_TEXT_TILE_BASE
    BLANK     = 0x06010000 + (512 + 8 * 32 + 15) * 32  # OBJ_VRAM_ADDR_BLANK_MENU_BUTTON_TILE_BASE
    ROW       = 0x800                                  # VRAM_MENU_BUTTON_TEXT_TILE_OFFSET
    TS_CURSOR = 0x0
    TS_HAS_SAVED_GAME = 0x7

    # [Options row, rows] (gTitlescreen.hasSavedGame: set by LoadTitlescreenGraphics)
    def title_menu_rows = r8(sym("gTitlescreen") + TS_HAS_SAVED_GAME) == 1 ? [3, 5] : [2, 4]

    def f_LoadTitlescreenGraphics
      super
      opt, rows = title_menu_rows
      opt.upto(rows - 2) { |i| f_CopyBgTilesRect(MENU_TEXT + (i + 1) * ROW, MENU_TEXT + i * ROW, 8, 2) }
      f_CopyBgTilesRect(BLANK, MENU_TEXT + (rows - 1) * ROW, 8, 2)
      # the menu actions move up the same way
      %w[gTitleNoSaveMenuActions gTitleSavedMenuActions].zip([2, 3], [4, 5]).each do |table, o, n|
        a = sym(table) & 0x1FFFFFF
        o.upto(n - 2) { |i| @rom[a + i * 2, 2] = @rom.byteslice(a + (i + 1) * 2, 2) }
      end
    end

    def f_TitleScreen4_MenuInputNoSavedGame = skip_last_row { super }
    def f_TitleScreen5_MenuInputSavedGame = skip_last_row { super }

    def skip_last_row
      cur = sym("gTitlescreen") + TS_CURSOR
      before = rs8(cur)
      yield
      _, rows = title_menu_rows
      w8(cur, before == 0 ? rows - 2 : 0) if rs8(cur) == rows - 1
    end
  end
  Machine.prepend(TitleMenuWithoutOptions)

  # No intro: whenever it would start (at boot, after the title's demo), the
  # title starts instead (the game has its own splash screens).
  module NoIntro
    def f_IntroMain = f_SetMainGameState(STATE_TITLE)
  end
  Machine.prepend(NoIntro)

  # No "Press Start": the title always opens on its menu (the game's own way
  # back from the other screens, gAutoDisplayTitlescreenMenu).
  module NoPressStart
    def f_LoadTitlescreenGraphics
      w8(sym("gAutoDisplayTitlescreenMenu"), 1)
      super
    end
  end
  Machine.prepend(NoPressStart)

  # The tall view sees ext more of the table above and below. The game turns
  # a main table's sprites on, and draws them, by where its camera is
  # ("camera < y" for things near the top, "camera > y" near the bottom, in
  # TALL_CAMERA_FUNCS): those tests are moved ext further when the code is
  # loaded (tall_code), so what the taller view shows is drawn.
  module TallSprites
    attr_accessor :tall_ext

    # For the screen (Screen#oam_hints), from the active sprite groups: their
    # sprites parked out of sight (:hide), and for each sprite y of 160-255
    # (8 bits: past the bottom, or above the top) the one nearer the group's
    # own place (its base y, 16 bits): :below / :above
    def oam_hints
      table = sym("gFieldSpriteSets") + (r8(sym("gMain") + MAIN_SELECTED_FIELD) * 8)
      sets = r32(table)
      groups = sym("gMain") + MAIN_SPRITE_GROUPS_TALL
      hints = {}
      r16(table + 4).times do |i|
        g = groups + (i * SPRITE_GROUP_SIZE_TALL)
        next if r16(g) == 0
        by = rs16(g + 4)
        parked = PARKED_Y.include?(by)
        r16(r32(sets + (i * 4))).times do |j|
          id = r16(g + 8 + (j * 8))
          next if id >= 128
          if parked
            hints[id] = :hide
            next
          end
          y = @oam.getbyte(id * 8)
          next if y < 160
          # the pause panel and its borders rest just off the GBA's screen
          if i < PAUSE_GROUPS
            hints[id] = :hide
            next
          end
          hints[id] = (y - by).abs <= (y - 256 - by).abs ? :below : :above
        end
      end
      hints
    end
  end
  Machine.prepend(TallSprites)

  # One table on the Field Select screen (0 Ruby, 1 Sapphire). Each table is
  # the same 11 tile columns on the screen's 3 BG tilemaps (ROM data it
  # loads: frame, shadow, window): the chosen one's move to the middle and
  # the rest become background; its sprites (name, highlight) move with it
  # and the other's are hidden; the ball speed picker is at the middle for
  # both; Left / Right don't change the choice.
  FIELD_SELECT_MAPS  = %w[gFieldSelectBG0Tilemap gFieldSelectFrameShadowTilemap gFieldSelectWindowTilemap]
  FIELD_COLUMNS      = [3, 16]       # first tile column of each table (11 wide)
  FIELD_ROWS         = 3..18
  BACKGROUND_COLUMN  = 14            # between the tables: background on every row
  CENTER_COLUMN      = 9
  FIELD_SHIFT        = FIELD_COLUMNS.map { |c| (CENTER_COLUMN - c) * 8 }
  BALL_SPEED_X       = 84            # gFieldSelectBallSpeedPositions x for the middle (36 + 48)
  # gFieldSelectData fields
  FS_RUBY_GROUP = 0x0; FS_SAPPHIRE_GROUP = 0x2; FS_RUBY_HL = 0x4; FS_SAPPHIRE_HL = 0x6
  FS_SELECTED = 0x8; FS_STATE = 0xA
  FS_BALL_SPEED_STATE = 2
  SG_NAME = [0, 1]                   # SG_FIELD_SELECT_*_BOARD_NAME_HIGHLIGHT
  SG_SAPPHIRE_CHOSEN = [7, 11]       # RUBY_FULL_SHADOW, SAPPHIRE_FULL_HIGHLIGHT
  SPRITE_GROUP_SIZE = 184
  MAIN_SPRITE_GROUPS = 0x2F8         # gMain.spriteGroups
  MAIN_NEW_KEYS = 0x18
  MAIN_SELECTED_FIELD = 0x04
  MAIN_TEMP_FIELD = 0x05
  MAIN_IS_BONUS_FIELD = 0x06
  OAM_BUFFER_NAME = "gOamBuffer"

  def one_field_rom(field)
    rom = @rom.dup
    FIELD_SELECT_MAPS.each do |name|
      base = Machine::SYMS.fetch(name) & 0x1FFFFFF
      FIELD_ROWS.each do |y|
        row = base + (y * 32 * 2)
        table = rom.byteslice(row + (FIELD_COLUMNS[field] * 2), 11 * 2)
        background = rom.byteslice(row + (BACKGROUND_COLUMN * 2), 2)
        rom[row + (FIELD_COLUMNS[0] * 2), 24 * 2] = background * 24
        rom[row + (CENTER_COLUMN * 2), 11 * 2] = table
      end
    end
    pos = Machine::SYMS.fetch("gFieldSelectBallSpeedPositions") & 0x1FFFFFF
    2.times { |i| rom[pos + (i * 4), 2] = [BALL_SPEED_X].pack("v") }
    rom
  end

  module OneField
    attr_accessor :one_field

    def fs = sym("gFieldSelectData")

    # With one table there's nothing to choose: the Field Select screen
    # starts its game at once (the title has already faded out and stopped
    # the music; the ball speed is the saved one, gMain_saveData.ballSpeed).
    def f_LoadFieldSelectGraphics
      return super unless @one_field
      main = sym("gMain")
      w8(main + MAIN_SELECTED_FIELD, @one_field)
      w8(main + MAIN_TEMP_FIELD, @one_field)
      w8(main + MAIN_IS_BONUS_FIELD, 0)
      w8(sym("gAutoDisplayTitlescreenMenu"), 1)
      f_SetMainGameState(STATE_GAME_MAIN)
    end

    # the chosen table starts selected (as if Right had been pressed for Sapphire)
    def f_InitFieldSelectData
      super
      return unless @one_field == 1
      w16(fs + FS_SELECTED, 1)
      w16(fs + FS_RUBY_HL, 1)
      w16(fs + FS_SAPPHIRE_HL, 0)
      w16(fs + FS_RUBY_GROUP, SG_SAPPHIRE_CHOSEN[0])
      w16(fs + FS_SAPPHIRE_GROUP, SG_SAPPHIRE_CHOSEN[1])
      w8(sym("gMain") + MAIN_SELECTED_FIELD, 1)
    end

    # Left / Right only change the ball speed
    def f_FieldSelect_State1_8C7C
      if @one_field && r16(fs + FS_STATE) != FS_BALL_SPEED_STATE
        keys = sym("gMain") + MAIN_NEW_KEYS
        w16(keys, r16(keys) & ~(BTN_LEFT | BTN_RIGHT))
      end
      super
    end

    def f_RenderFieldSelectSprites
      super
      return unless @one_field
      shift = FIELD_SHIFT[@one_field]
      field_groups(@one_field).each { |g| move_group(g) { |x, y| [x + shift, y] } }
      field_groups(1 - @one_field).each { |g| move_group(g) { |x, _| [x, 160] } }   # below the screen
    end

    # a table's sprite groups: its name and its highlight / shadow
    def field_groups(field)
      [SG_NAME[field], r16(fs + (field == 0 ? FS_RUBY_GROUP : FS_SAPPHIRE_GROUP))]
    end

    # the OAM entries of a sprite group (its sprite set's count)
    def move_group(group)
      grp = sym("gMain") + MAIN_SPRITE_GROUPS + (group * SPRITE_GROUP_SIZE)
      count = r16(r32(sym("gFieldSelectSpriteSets") + (group * 4)))
      oam = sym(OAM_BUFFER_NAME)
      count.times do |i|
        a = oam + (r16(grp + 8 + (i * 8)) * 8)
        word = r32(a)
        x, y = yield((word >> 16) & 0x1FF, word & 0xFF)
        w32(a, (word & 0xFE00FF00) | ((x & 0x1FF) << 16) | (y & 0xFF))
      end
    end
  end
  Machine.prepend(OneField)
end

def pbPokemonPinballRS
  # the machine the player faces: left Ruby, right Sapphire
  field = { 4 => 0, 6 => 1 }[$game_player&.direction]
  PinballRS::Player.new.play(field: field)
end
