#==============================================================================
# Pokémon Pinball (GBC) - playing it: pbPokemonPinball
#
# Loads the recompiled game (Data/Pinball_GBC_Code.rxdata) and its ROM data
# (Data/Pinball_GBC_Rom.rxdata) the first time, made by
# Pinball-mod/tools/package_gbc.py. Runs one game frame per screen frame.
#
# Keys (Game Boy -> Essentials input):
#   D-pad  arrows        A  Use (C)        B  Back (X)
#   Start  Action (Z)    Select  Special
#   On a table, Right is the right flipper (A) instead of D-pad right, so
#   Left / Right arrows work the two flippers. Menus keep the plain D-pad.
#   On the title screen Back closes the minigame (the game's own B there,
#   the High Scores screen, moves to Select / Special).
#   Anywhere else: hold Back for 2 seconds to quit.
#
# From an event: Script command `pbPokemonPinball`. It asks Play / High
# Scores / Cancel first: the title screen has no room for a 4th menu line,
# so High Scores boots the game straight into its High Scores screen (the
# title's B) and closes the minigame when that screen is left.
# The table is the one in front of the player: facing left, the Red Field;
# facing right, the Blue Field. Game Start then skips the Field Select
# screen and starts that table (any other way, the screen shows both, as in
# the game). The copyright
# screen at boot is skipped (the game has its own splash screens).
# The game's own save (high scores, Pokédex) is kept in the save folder as
# PokemonPinball.sav. At game over the score earns Server Tokens
# (1 per 1,000,000,000 points, server: handlers/pinball.js).
# Online, the High Scores screen shows the server's boards instead (the top 5
# players of each field this season; the season's top 5 win tokens). The
# saved file keeps the offline scores.
#==============================================================================
module PinballGBC
  CODE_FILE = "Data/Pinball_GBC_Code.rxdata"
  ROM_FILE  = "Data/Pinball_GBC_Rom.rxdata"
  SAVE_NAME = "PokemonPinball.sav"
  QUIT_HOLD_FRAMES = 120
  # High Scores only: how long the title waits for the server's boards
  BOARD_WAIT_FRAMES = 180

  # game over: TransitionToHighScoresScreen; the score: wScore (6 BCD bytes,
  # lowest digits first) in WRAM bank 1
  GAME_OVER_KEY = (0x03 << 16) | 0x5b5d
  SCORE_WRAM    = 0x1000 + (0xd46a - 0xd000)
  # wCurrentScreen (WRAM bank 1): SCREEN_PINBALL_GAME while a table is played
  CURRENT_SCREEN_WRAM = 0x1000 + (0xd8f1 - 0xd000)
  SCREEN_STATE_WRAM   = 0x1000 + (0xd8f2 - 0xd000)
  SCREEN_PINBALL_GAME = 4
  SCREEN_TITLESCREEN  = 3
  TITLE_LOOP_STATE    = 1   # TitlescreenLoop (not a sub-menu or fade)
  SCREEN_HIGH_SCORES  = 7
  # wRedHighScores / wBlueHighScores: 5 entries of 13 bytes each (6 BCD
  # bytes of points lowest first, 3 letters, 4 bytes of IR id), best first.
  # wHighScoresStage: 0 Red, 1 Blue (the field a finished game was played on)
  HIGH_SCORES_WRAM = { "red" => 0x1000 + (0xd9fd - 0xd000), "blue" => 0x1000 + (0xda3e - 0xd000) }
  HIGH_SCORES_STAGE_WRAM = 0x1000 + (0xda83 - 0xd000)
  HIGH_SCORE_SIZE  = 13
  FIELDS           = ["red", "blue"]
  # sHighScores with its signature, checksum and backup copy
  SRAM_HIGH_SCORES = 0x10c

  module_function

  def loaded?; defined?(Code::FUNCS); end

  def load_game
    return if loaded?
    code = Zlib::Inflate.inflate(load_data(CODE_FILE))
    code.force_encoding(Encoding::UTF_8)
    eval(code, TOPLEVEL_BINDING, "pinball_gbc_code.rb")
    @rom = Zlib::Inflate.inflate(load_data(ROM_FILE))
  end

  def rom; @rom; end

  def save_path
    dir = (RTP.getSaveFolder rescue nil) || "."
    File.join(dir, SAVE_NAME)
  end

  def score_of(m)
    (0...6).sum do |i|
      v = m.wram[SCORE_WRAM + i]
      ((v >> 4) * 10 + (v & 15)) * (100**i)
    end
  end

  # The title menu without Option (the controls are the game's own, F1):
  # the menu's last line is blanked when the title is drawn, and the cursor
  # stops at Poké Dex. (The generated code calls these directly, so they're
  # replaced here rather than hooked.)
  module TitleMenu
    MAP          = 0x1800                   # vBGMap
    OPTION_TILES = [[16, 2..7], [17, 3..4]] # [row, columns] of "Option"
    OPTION_TOP   = [15, 3]                  # the tile holding its top pixel row
    BLANK_TILE   = 0x80

    def title_screen? = @wram[CURRENT_SCREEN_WRAM] == SCREEN_TITLESCREEN

    # HandleTitlescreenAnimations (runs once the title's tilemap is loaded)
    def f_03_40f7
      blank_option if title_screen?
      super
    end

    # Func_c1fc: moves a cursor, c = its last line
    def f_03_41fc
      @c = 1 if @c == 2 && title_screen?
      super
    end

    def blank_option
      return if @vram[MAP + 16 * 32 + 3] == BLANK_TILE
      OPTION_TILES.each { |r, cols| cols.each { |c| @vram[MAP + r * 32 + c] = BLANK_TILE } }
      # its top row of pixels: the last line of that tile (tiles $00-$7f are at $9000)
      row, col = OPTION_TOP
      tile = @vram[MAP + row * 32 + col]
      bank = @vram[0x2000 + MAP + row * 32 + col] & 8 != 0 ? 1 : 0
      addr = bank * 0x2000 + (tile < 0x80 ? 0x1000 : 0) + tile * 16 + 14
      @vram[addr] = @vram[addr + 1] = 0
      @tile_dirty[bank * 384 + ((addr & 0x1fff) >> 4)] = true
    end
  end
  Machine.prepend(TitleMenu)

  # Boot without the copyright screen: its fade-in only turns the screen on
  # (all white, so the fade-out after it has frames to run on) and its wait
  # moves straight on (the step after them, which loads the saved high
  # scores, still runs).
  WRAM_SCREEN_STATE = SCREEN_STATE_WRAM
  RETURN_MARK = 0xbeef
  module NoCopyright
    def f_02_4228   # FadeInCopyrightScreen
      call_routine(:f_00_0b66)   # SetAllPalettesWhite
      call_routine(:f_00_0916)   # ClearSpriteBuffer
      call_routine(:f_00_0588)   # EnableLCD
      @wram[WRAM_SCREEN_STATE] += 1
      pop16
    end

    # a call from here, as the game's code makes one
    def call_routine(name)
      push16(RETURN_MARK)
      r = tramp(send(name))
      raise MachineError, "#{name} returned to #{r}" unless r == RETURN_MARK
    end

    def f_02_4290   # DisplayCopyrightScreen
      @wram[WRAM_SCREEN_STATE] += 1
      pop16
    end
  end
  Machine.prepend(NoCopyright)

  # One table on the Field Select screen (0 Red, 1 Blue): its columns of the
  # screen's tilemap and colour map (ROM data the screen loads) move to the
  # middle, the other table's become background, the blinking border sprite
  # goes to the middle, and Left / Right don't move the choice.
  FIELD_SELECT_TILEMAP = (0x2c * 0x4000) + (0x7800 - 0x4000)   # FieldSelectTilemap, 32x18
  FIELD_SELECT_ATTRS   = (0x2c * 0x4000) + (0x7c00 - 0x4000)   # FieldSelectBGAttributes
  FIELD_SELECT_BORDER  = (0x03 * 0x4000) + (0x584f - 0x4000)   # FieldSelectBorderSpritePixelOffsetData: [y, x] x2
  FIELD_COLUMNS = [1, 10]          # first column of each table (9 wide)
  FIELD_ROWS    = 2..15
  CENTER_COLUMN = 5
  CENTER_BORDER_X = 74             # the border sprite's x for the middle (Red's 42 is 34 px into its table)
  SELECTED_FIELD_WRAM = 0x1000 + (0xd913 - 0xd000)   # wSelectedFieldIndex

  def one_field_rom(field)
    rom = @rom.dup
    [FIELD_SELECT_TILEMAP, FIELD_SELECT_ATTRS].each do |base|
      FIELD_ROWS.each do |y|
        row = base + (y * 32)
        table = rom.byteslice(row + FIELD_COLUMNS[field], 9)
        background = rom.getbyte(row)          # column 0 is background on every row
        (1..18).each { |x| rom.setbyte(row + x, background) }
        rom[row + CENTER_COLUMN, 9] = table
      end
    end
    rom.setbyte(FIELD_SELECT_BORDER + 1, CENTER_BORDER_X)
    rom.setbyte(FIELD_SELECT_BORDER + 3, CENTER_BORDER_X)
    rom
  end

  module OneField
    attr_accessor :one_field

    def f_03_57d3   # MoveFieldSelectCursor
      return super unless @one_field
      @wram[SELECTED_FIELD_WRAM] = @one_field
      pop16
    end
  end
  Machine.prepend(OneField)

  # With one table there's nothing to choose: the Field Select screen loads
  # as if A had just been pressed on it (the screen on, all white, as the
  # fade-in leaves it), so its last step fades out and starts the game.
  FIELD_PRESSED_BUTTON_WRAM = 0x1000 + (0xd8f6 - 0xd000)   # wFieldSelectPressedButton
  FIELD_BLINK_TIMER_WRAM    = 0x1000 + (0xd912 - 0xd000)   # wFieldSelectBlinkingBorderTimer
  FIELD_BLINK_FRAME_WRAM    = 0x1000 + (0xd914 - 0xd000)   # wFieldSelectBlinkingBorderFrame
  module SkipFieldSelect
    def f_03_56dd   # LoadFieldSelectScreen
      return super unless @one_field
      call_routine(:f_00_0b66)   # SetAllPalettesWhite
      call_routine(:f_00_0916)   # ClearSpriteBuffer
      call_routine(:f_00_0588)   # EnableLCD
      @wram[SELECTED_FIELD_WRAM] = @one_field
      @wram[FIELD_PRESSED_BUTTON_WRAM] = 1   # A
      @wram[FIELD_BLINK_TIMER_WRAM] = 1
      @wram[FIELD_BLINK_FRAME_WRAM] = 1
      @wram[WRAM_SCREEN_STATE] = 2           # ExitFieldSelectScreen
      pop16
    end
  end
  Machine.prepend(SkipFieldSelect)

  # The name entry starts on the last name entered (kept in PinballNames.dat
  # in the save folder; the first time, the player's name). The game copies
  # wPlayerName into a new high score (it's only ever set to blanks at boot),
  # so it's set when the High Scores screen starts, and read back from the
  # table when the name is done.
  PLAYER_NAME_WRAM    = 0x1000 + (0xd470 - 0xd000)   # wPlayerName
  ENTERING_NAME_WRAM  = 0x1000 + (0xda7f - 0xd000)   # wHighScoreIsEnteringName
  NAME_ROW_WRAM       = 0x1000 + (0xda81 - 0xd000)   # wHighScoreNameRow
  module RememberName
    def f_03_4a8f   # the High Scores screen's first step: puts a new score in
      PinballGBC.last_name.each_with_index { |c, i| @wram[PLAYER_NAME_WRAM + i] = c }
      super
    end

    def f_03_51d2   # Func_d1d2: A / B on the name entry
      entering = @wram[ENTERING_NAME_WRAM]
      r = super
      if entering != 0 && @wram[ENTERING_NAME_WRAM] == 0
        field = FIELDS[@wram[HIGH_SCORES_STAGE_WRAM]] || "red"
        at = HIGH_SCORES_WRAM[field] + (@wram[NAME_ROW_WRAM] * HIGH_SCORE_SIZE) + 6
        PinballGBC.save_last_name((0...3).map { |i| @wram[at + i] })
      end
      r
    end
  end
  Machine.prepend(RememberName)

  class Player
    KEYS = [[:LEFT, BTN_LEFT], [:RIGHT, BTN_RIGHT], [:UP, BTN_UP], [:DOWN, BTN_DOWN],
            [:USE, BTN_A], [:BACK, BTN_B], [:ACTION, BTN_START], [:SPECIAL, BTN_SELECT]]

    # high_scores: only show the High Scores screen
    # field: 0 Red / 1 Blue (only that table on the Field Select screen), or nil
    def play(high_scores = false, field: nil)
      @high_scores = high_scores
      unless PinballGBC.loaded?
        msg = Window_AdvancedTextPokemon.new(_INTL("Loading Pokémon Pinball..."))
        msg.z = 99_999
        pbBottomLeftLines(msg, 2)
        Graphics.update
        begin
          PinballGBC.load_game
        ensure
          msg.dispose
        end
      end
      @machine = Machine.new(field ? PinballGBC.one_field_rom(field) : PinballGBC.rom)
      @machine.one_field = field
      load_sram
      @machine.hooks[GAME_OVER_KEY] = method(:on_game_over)
      start_server_board
      Sound.install(@machine)
      @screen = Screen.new
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 200_000   # over every menu it may be opened from (the debug menu is 99_999)
      @back = Sprite.new(@viewport)
      @back.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @back.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
      @sprite = Sprite.new(@viewport)
      @sprite.bitmap = @screen.bitmap
      zoom = [Graphics.width / 160.0, Graphics.height / 144.0].min
      @sprite.zoom_x = @sprite.zoom_y = zoom
      @sprite.x = (Graphics.width - 160 * zoom) / 2
      @sprite.y = (Graphics.height - 144 * zoom) / 2
      @sprite.z = 1
      @sprite.visible = !@high_scores   # the boot and title stay black
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
      title_frames = 0
      loop do
        Graphics.update
        Input.update
        break if on_title_menu? && Input.trigger?(Input::BACK)
        btn = read_buttons
        if @high_scores
          if @machine.wram[CURRENT_SCREEN_WRAM] == SCREEN_HIGH_SCORES
            @sprite.visible = true
          elsif @sprite.visible
            break   # High Scores left: back to the overworld
          elsif on_title_menu?
            title_frames += 1
            # the title's B opens High Scores, once the server's boards are in
            btn = BTN_B if !@board_cb || @board_used || title_frames > BOARD_WAIT_FRAMES
          end
        end
        @machine.buttons = btn
        @machine.step_frame
        update_server_board
        # while the game has the LCD off (loading a table half, a new screen)
        # the last picture stays, like the blank LCD hides the loading
        @screen.draw(@machine) if @machine.lcd_on?
        save_sram if @machine.sram_dirty && @machine.frames % 300 == 0
        hold = Input.press?(Input::BACK) ? hold + 1 : 0
        if hold >= QUIT_HOLD_FRAMES
          hold = 0
          break if confirm_quit
        end
      end
    end

    # the screen is hidden while the message box is up (it sits under it)
    def on_title_menu?
      @machine.wram[CURRENT_SCREEN_WRAM] == SCREEN_TITLESCREEN &&
        @machine.wram[SCREEN_STATE_WRAM] == TITLE_LOOP_STATE
    end

    def read_buttons
      btn = KEYS.sum { |key, bit| Input.press?(Input.const_get(key)) ? bit : 0 }
      if @machine.wram[CURRENT_SCREEN_WRAM] == SCREEN_PINBALL_GAME && btn & BTN_RIGHT != 0
        btn = (btn & ~BTN_RIGHT) | BTN_A     # Right arrow = right flipper
      end
      if on_title_menu?
        # Back closes the minigame here; Select opens High Scores (the game's B)
        btn &= ~BTN_B
        btn = (btn & ~BTN_SELECT) | BTN_B if btn & BTN_SELECT != 0
      end
      btn
    end

    def confirm_quit
      @viewport.visible = false
      pbConfirmMessage(_INTL("Quit Pokémon Pinball?"))
    ensure
      @viewport.visible = true
    end

    # TransitionToHighScoresScreen: the game is over
    def on_game_over(m)
      score = PinballGBC.score_of(m)
      r = m.send(:f_03_5b5d)
      field = FIELDS[m.wram[HIGH_SCORES_STAGE_WRAM]] || "red"
      drop_own_entry(field, score)
      PinballGBC.report_score(score, field)
      r
    end

    #--- the server's boards (online only) ---
    def start_server_board
      return unless PinballGBC.online?
      @board_cb = NetworkClient.on("pinball_board") do |d|
        next unless d["game"] == "gbc"
        @board = FIELDS.to_h { |f| [f, Array(d.dig("fields", f)).map { |u, sc| [u.to_s, sc.to_i] }] }
        @board_dirty = true
      end
      NetworkClient.send_msg({ action: "pinball_board", game: "gbc" })
    rescue StandardError
      @board_cb = nil
    end

    # writes the boards into the game's high score tables, except while the
    # High Scores screen (or the boot, which loads the saved ones) is running
    def update_server_board
      return unless @board_cb
      NetworkClient.update
      screen = @machine.wram[CURRENT_SCREEN_WRAM]
      @board_dirty = true if @last_screen == SCREEN_HIGH_SCORES && screen != SCREEN_HIGH_SCORES
      @last_screen = screen
      return unless @board && @board_dirty && screen >= SCREEN_TITLESCREEN && screen != SCREEN_HIGH_SCORES
      @board.each { |field, rows| write_board(field, rows) }
      @board_dirty = false
      @board_used = true
    end

    def write_board(field, rows)
      base = HIGH_SCORES_WRAM[field]
      5.times do |i|
        name, score = rows[i] || ["---", 0]
        entry = (0...6).map { |j| v = (score / (100**j)) % 100; ((v / 10) << 4) | (v % 10) }
        entry += PinballGBC.board_name(name) + [0, 0, 0, 0]
        entry.each_with_index { |v, j| @machine.wram[base + i * HIGH_SCORE_SIZE + j] = v }
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

    def load_sram
      data = File.binread(PinballGBC.save_path) rescue nil
      data&.bytes&.each_with_index { |v, i| @machine.sram[i] = v if i < @machine.sram.size }
      @local_scores = @machine.sram[0, SRAM_HIGH_SCORES]
    end

    # the saved high scores stay the offline ones
    def save_sram
      return unless @machine
      sram = @machine.sram
      if @board_used
        sram = sram.dup
        sram[0, SRAM_HIGH_SCORES] = @local_scores
      end
      File.binwrite(PinballGBC.save_path, sram.pack("C*"))
      @machine.sram_dirty = false
    rescue StandardError
      nil
    end
  end

  def online?
    defined?(NetworkAuth) && NetworkAuth.logged_in?
  end

  # 3 letters of a player name in the game's own letters (the name entry's
  # $00-$09 digits, $0A-$23 A-Z, $37 space), as bytes
  def board_name(name)
    name.to_s.upcase.gsub(/[^A-Z0-9]/, "")[0, 3].ljust(3).chars.map do |c|
      c =~ /\d/ ? c.to_i : c == " " ? 0x37 : c.ord - 0x37
    end
  end

  #--- the last name entered (both pinball games keep theirs in one file) ---
  NAMES_FILE = "PinballNames.dat"

  def names_path = File.join((RTP.getSaveFolder rescue nil) || ".", NAMES_FILE)

  def saved_names
    names = File.open(names_path, "rb") { |f| Marshal.load(f) }
    names.is_a?(Hash) ? names : {}
  rescue StandardError
    {}
  end

  # 3 letters as the name entry has them ($0A-$37; it never shows digits)
  def last_name
    n = saved_names["gbc"]
    return n if n.is_a?(Array) && n.size == 3 && n.all? { |c| c.is_a?(Integer) && c.between?(0x0a, 0x37) }
    board_name(($player&.name rescue nil).to_s.gsub(/[^A-Za-z]/, ""))
  end

  def save_last_name(letters)
    names = saved_names
    return if names["gbc"] == letters
    names["gbc"] = letters
    File.open(names_path, "wb") { |f| Marshal.dump(names, f) }
  rescue StandardError
    nil
  end

  # the board and Server Tokens (1 per 1,000,000,000 points; the server
  # decides; offline nothing)
  def report_score(score, field)
    return if score <= 0 || !online?
    NetworkClient.send_msg({ action: "pinball_result", game: "gbc", field: field, score: score })
  rescue StandardError
    nil
  end
end

def pbPokemonPinball
  cmd = pbMessage(_INTL("Pokémon Pinball"), [_INTL("Play"), _INTL("High Scores"), _INTL("Cancel")], -1)
  # the machine the player faces: left Red, right Blue
  field = { 4 => 0, 6 => 1 }[$game_player&.direction]
  PinballGBC::Player.new.play(cmd == 1, field: field) if [0, 1].include?(cmd)
end
