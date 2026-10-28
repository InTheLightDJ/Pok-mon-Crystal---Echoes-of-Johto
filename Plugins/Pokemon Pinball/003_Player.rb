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
# From an event: Script command `pbPokemonPinball`.
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

  class Player
    KEYS = [[:LEFT, BTN_LEFT], [:RIGHT, BTN_RIGHT], [:UP, BTN_UP], [:DOWN, BTN_DOWN],
            [:USE, BTN_A], [:BACK, BTN_B], [:ACTION, BTN_START], [:SPECIAL, BTN_SELECT]]

    def play
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
      @machine = Machine.new(PinballGBC.rom)
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
        break if on_title_menu? && Input.trigger?(Input::BACK)
        @machine.buttons = read_buttons
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
        entry += PinballGBC.board_name(name).bytes + [0, 0, 0, 0]
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

  # 3 letters of a player name the game's font has
  def board_name(name)
    name.to_s.upcase.gsub(/[^A-Z0-9-]/, "")[0, 3].ljust(3)
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
  PinballGBC::Player.new.play
end
