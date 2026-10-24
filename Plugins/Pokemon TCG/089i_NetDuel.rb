#==============================================================================
# Pokemon TCG - online duels against another player (server: handlers/tcg.js)
#
# Lockstep: both games run the same duel. Each game drives its own player
# with the normal duel menu (NetLocalController) and replays the other
# player's moves as they arrive (NetRemoteController). What is relayed:
#   ["act", method, args]   a turn action (play a card, attack, retreat...)
#   ["dec", method, value]  an answer to a question the engine asked
#   ["end"]                 the turn is over
# Randomness: at the start of the duel and of every turn both games ask the
# server for that round's seed (the server makes it once and gives both the
# same one). Each duelist gets its own Random from it, so coin flips and
# shuffles come out the same in both games. Both games also send a checksum
# of the duel with each seed request; the server ends the duel if they differ.
#
# Starting a duel: pause menu SERVER > Card Duel, the Pokégear card menu's
# "Online Duel", or a player's name chip in the chat. Both players use their
# dueling deck (089d_PokegearMenu.rb).
#
# PROTOCOL (client -> server)            (server -> client)
#   tcg_request { target_username, deck }  tcg_pending   { duel_id }
#   tcg_accept  { duel_id, deck }          tcg_request   { from, duel_id }
#   tcg_decline { duel_id }                tcg_start     { duel_id, opp_name, my_deck, opp_deck, challenger }
#   tcg_seed    { duel_id, round, hash }   tcg_seed      { round, seed }
#   tcg_move    { duel_id, seq, data }     tcg_move_relay{ seq, data }
#   tcg_result  { duel_id, result }        tcg_declined  { from }
#                                          tcg_ended     { reason }
#                                          tcg_desync    { round }
#                                          tcg_error     { message }
#==============================================================================
module TCG
  # the RNG of the engine: plain Random offline, the turn holder's seeded
  # Random in an online duel
  def self.rng
    d = @net_duel
    (d && d.turn_duelist.rng) || Random
  end

  def self.net_duel=(duel); @net_duel = duel; end

  class NetAbort < StandardError; end

  # JSON-safe values (symbols become {"s" => name})
  module NetCodec
    module_function

    def enc(v)
      case v
      when Symbol then { "s" => v.to_s }
      when Array  then v.map { |x| enc(x) }
      when Hash   then { "h" => v.map { |k, x| [enc(k), enc(x)] } }
      else v
      end
    end

    def dec(v)
      case v
      when Array then v.map { |x| dec(x) }
      when Hash
        return v["s"].to_sym if v.key?("s")
        return v["h"].to_h { |k, x| [dec(k), dec(x)] } if v.key?("h")
        v
      else v
      end
    end
  end

  #----------------------------------------------------------------------------
  # one online duel's connection
  #----------------------------------------------------------------------------
  class NetSession
    attr_reader :duel_id, :opp_name

    def initialize(duel_id, opp_name)
      @duel_id  = duel_id
      @opp_name = opp_name
      @inbox    = []
      @seeds    = {}
      @ended    = nil
      @out_seq  = 0
      @in_seq   = 0
    end

    # server events (NetPvP routes them here)
    def receive(event, d)
      case event
      when "tcg_move_relay"
        @in_seq += 1
        @ended ||= "The duel went out of sync." if d["seq"].to_i != @in_seq
        @inbox << d["data"]
      when "tcg_seed"   then @seeds[d["round"].to_i] = d["seed"].to_i
      when "tcg_ended"  then @ended ||= d["reason"].to_s
      when "tcg_desync" then @ended ||= "The duel went out of sync."
      end
    end

    def send_event(ev)
      @out_seq += 1
      NetworkClient.send_msg({ action: "tcg_move", duel_id: @duel_id, seq: @out_seq, data: ev })
    end

    def seed(round, hash)
      NetworkClient.send_msg({ action: "tcg_seed", duel_id: @duel_id, round: round, hash: hash })
      wait { @seeds[round] }
    end

    # the opponent's next relayed event
    def pull
      wait { @inbox.shift }
    end

    # pumps the game until the block returns non-nil; shows "Waiting for..."
    # after a moment
    def wait
      frames = 0
      loop do
        v = yield
        return v unless v.nil?
        raise NetAbort, @ended if @ended
        raise NetAbort, _INTL("Connection lost.") unless NetworkClient.connected?
        Graphics.update
        Input.update
        NetworkClient.update
        frames += 1
        show_waiting if frames == 30
      end
    ensure
      hide_waiting
    end

    def show_waiting
      @wait_vp = Viewport.new(0, 0, Graphics.width, 24)
      @wait_vp.z = 100_002
      @wait_spr = Sprite.new(@wait_vp)
      @wait_spr.bitmap = Bitmap.new(Graphics.width, 24)
      @wait_spr.bitmap.fill_rect(0, 0, Graphics.width, 24, Color.new(0, 0, 0, 160))
      pbSetSmallFont(@wait_spr.bitmap)
      pbDrawTextPositions(@wait_spr.bitmap, [[_INTL("Waiting for {1}...", @opp_name), Graphics.width / 2, 2, :center,
                                              Color.new(248, 248, 248), Color.new(64, 64, 64)]])
    end

    def hide_waiting
      @wait_spr&.bitmap&.dispose
      @wait_spr&.dispose
      @wait_vp&.dispose
      @wait_spr = @wait_vp = nil
    end
  end

  #----------------------------------------------------------------------------
  # the duel: seeds every round and relays the local player's turn actions
  #----------------------------------------------------------------------------
  class NetDuel < Duel
    # the turn actions the duel menu calls (071_PlayerController.rb)
    ACTIONS = %i[play_energy_card play_trainer_card play_basic_pokemon evolve_pokemon
                 use_attack use_pkmn_power attempt_retreat]

    attr_accessor :recording

    # challenger: index of the challenger here (0 = this game's player)
    def initialize(session, challenger, *args, **kw)
      super(*args, **kw)
      @session    = session
      @challenger = challenger
      @round      = 0
      @act_depth  = 0
      @recording  = false
    end

    def reseed
      seed = @session.seed(@round, state_hash)
      @round += 1
      @duelists.each_with_index do |d, i|
        d.rng = Random.new(seed * 2 + (i == @challenger ? 0 : 1))
      end
    end

    # the challenger tosses the coin for who goes first (also in sudden death)
    def handle_duel_setup
      reseed
      @turn = @challenger
      super
    end

    def update_substatus_conditions_start_of_turn
      reseed
      super
    end

    ACTIONS.each do |m|
      define_method(m) do |*a|
        @session.send_event(["act", m.to_s, NetCodec.enc(a)]) if @recording && @act_depth == 0
        @act_depth += 1
        begin
          super(*a)
        ensure
          @act_depth -= 1
        end
      end
    end

    # same number in both games while they agree (challenger's side first)
    def state_hash
      order = @challenger == 0 ? @duelists : @duelists.reverse
      s = order.map do |d|
        [d.deck_cards, d.not_in_deck, d.card_locations, d.hand, d.prize_cards, d.prizes,
         d.play_area, d.slot_hp, d.status].inspect
      end.join("|") + @duel_turns.to_s
      h = 5381
      s.each_byte { |b| h = ((h * 33) ^ b) & 0xffffffff }
      h
    end
  end

  # engine questions the controllers answer
  NET_DECISIONS = %i[choose_initial_arena choose_initial_bench choose_prize
                     choose_ko_replacement effect_choice confirm_pkmn_power]

  # this game's player: the normal duel menu, with every answer and turn
  # action sent to the other game
  class NetLocalController < PlayerController
    def initialize(scene, session)
      super(scene)
      @session = session
    end

    NET_DECISIONS.each do |m|
      define_method(m) do |*a|
        r = super(*a)
        @session.send_event(["dec", m.to_s, NetCodec.enc(r)])
        r
      end
    end

    def take_turn(duel)
      duel.recording = true
      super
    ensure
      duel.recording = false
      @session.send_event(["end"])
    end
  end

  # the other player: replays what their game sent. A PlayerController so
  # the Neo effects that let a human pick (is_a?(PlayerController)) ask it
  # the same questions as in the other game.
  class NetRemoteController < PlayerController
    def initialize(scene, session)
      super(scene)
      @session = session
    end

    NET_DECISIONS.each do |m|
      define_method(m) do |*_a|
        ev = @session.pull
        raise NetAbort, _INTL("The duel went out of sync.") unless ev.is_a?(Array) && ev[0] == "dec" && ev[1] == m.to_s
        NetCodec.dec(ev[2])
      end
    end

    def take_turn(duel)
      @scene.refresh(duel)
      loop do
        ev = @session.pull
        case ev.is_a?(Array) && ev[0]
        when "end" then return
        when "act"
          raise NetAbort, _INTL("The duel went out of sync.") unless NetDuel::ACTIONS.include?(ev[1].to_sym)
          duel.send(ev[1].to_sym, *NetCodec.dec(ev[2]))
          @scene.refresh(duel)
        else
          raise NetAbort, _INTL("The duel went out of sync.")
        end
      end
    end
  end

  #----------------------------------------------------------------------------
  # challenges (like NetworkTriad)
  #----------------------------------------------------------------------------
  module NetPvP
    # challenging them starts a duel against the AI with their real deck
    # (server: AI_DUELISTS in handlers/tcg.js, which also sets the portrait)
    AI_DUELISTS    = ["InTheLight"]
    AI_DUEL_REWARD = :REVELATION

    @session  = nil
    @incoming = nil
    @busy     = false

    module_function

    def session; @session; end
    def busy?; @busy; end
    def queue_incoming(d); @incoming = d; end

    def route(event, d)
      @session&.receive(event, d)
    end

    def online?
      defined?(NetworkAuth) && NetworkAuth.logged_in?
    end

    # the dueling deck as 60 card id strings, or nil (with a message)
    def my_deck
      cards = TCG.active_deck_cards
      if cards.nil? || cards.size != DECK_SIZE
        pbMessage(_INTL("You need a 60-card dueling deck. Choose one in the card menu's Deck screen."))
        return nil
      end
      cards.map(&:to_s)
    end

    def valid_deck?(list)
      list.is_a?(Array) && list.size == DECK_SIZE && list.all? { |id| CARDS.key?(id.to_s.to_sym) }
    end

    # pumps the game until the block returns non-nil or `frames` pass
    def wait_for(frames)
      frames.times do
        Graphics.update
        Input.update
        NetworkClient.update
        v = yield
        return v unless v.nil?
      end
      nil
    end

    def fetch_online_players
      players = nil
      cb = NetworkClient.on("players_list") { |d| players = d["players"] }
      NetworkClient.send_msg({ action: "players_list" })
      wait_for(200) { players }
      NetworkClient.remove("players_list", cb)
      players || []
    end

    # challenger: pick an opponent (unless given), send the challenge, wait
    def request_duel(target = nil)
      unless online?
        pbMessage(_INTL("You need to be connected online to duel."))
        return
      end
      return if @busy
      @busy = true
      begin
        send_challenge(target)
      ensure
        @busy = false
      end
    end

    def send_challenge(target)
      deck = my_deck
      return unless deck
      unless target
        players = fetch_online_players
        if players.empty?
          pbMessage(_INTL("No other players are online right now."))
          return
        end
        cmds = players + [_INTL("Cancel")]
        c = pbMessage(_INTL("Who do you want to duel?"), cmds, cmds.size)
        return if c < 0 || c >= players.size
        target = players[c]
      end
      duel_id = nil
      error = nil
      ai = nil
      cbs = [["tcg_pending",  NetworkClient.on("tcg_pending")  { |d| duel_id = d["duel_id"] }],
             ["tcg_ai_start", NetworkClient.on("tcg_ai_start") { |d| ai = d }],
             ["tcg_error",    NetworkClient.on("tcg_error")    { |d| error = d["message"].to_s }]]
      NetworkClient.send_msg({ action: "tcg_request", target_username: target, deck: deck })
      wait_for(200) { duel_id || ai || error }
      cbs.each { |ev, cb| NetworkClient.remove(ev, cb) }
      return run_ai_duel(ai) if ai
      unless duel_id
        pbMessage(error || _INTL("No response from server."))
        return
      end
      start = nil
      reason = nil
      cbs = [["tcg_start",    NetworkClient.on("tcg_start")    { |d| start = d }],
             ["tcg_declined", NetworkClient.on("tcg_declined") { |d| reason = _INTL("{1} declined the duel.", d["from"]) }],
             ["tcg_ended",    NetworkClient.on("tcg_ended")    { |d| reason = d["reason"].to_s }]]
      msg_win = Window_AdvancedTextPokemon.new(_INTL("Waiting for {1}... (B: cancel)", target))
      msg_win.z = 99_999
      pbBottomLeftLines(msg_win, 2)
      waited = wait_for(3600) do
        if Input.trigger?(Input::BACK)
          NetworkClient.send_msg({ action: "tcg_decline", duel_id: duel_id })
          reason = _INTL("You cancelled the duel.")
        end
        start || reason
      end
      msg_win.dispose
      cbs.each { |ev, cb| NetworkClient.remove(ev, cb) }
      if start
        run_duel(start)
      else
        NetworkClient.send_msg({ action: "tcg_decline", duel_id: duel_id }) unless waited
        pbMessage(reason || _INTL("{1} did not respond.", target))
      end
    end

    # a challenge came in: shown on the map when nothing else is going on
    def process_incoming
      return unless @incoming && !@busy
      return unless $scene.is_a?(Scene_Map)
      return if $game_system.map_interpreter.running? || $game_temp.in_menu || TCG.dueling?
      req = @incoming
      @incoming = nil
      @busy = true
      begin
        answer_challenge(req)
      ensure
        @busy = false
      end
    end

    def answer_challenge(req)
      from    = req["from"].to_s
      duel_id = req["duel_id"].to_s
      c = pbMessage(_INTL("{1} wants to have a card duel! Accept?", from), [_INTL("Accept"), _INTL("Decline")], 2)
      deck = c == 0 ? my_deck : nil
      unless deck
        NetworkClient.send_msg({ action: "tcg_decline", duel_id: duel_id })
        return
      end
      start = nil
      reason = nil
      cbs = [["tcg_start", NetworkClient.on("tcg_start") { |d| start = d }],
             ["tcg_ended", NetworkClient.on("tcg_ended") { |d| reason = d["reason"].to_s }],
             ["tcg_error", NetworkClient.on("tcg_error") { |d| reason = d["message"].to_s }]]
      NetworkClient.send_msg({ action: "tcg_accept", duel_id: duel_id, deck: deck })
      wait_for(600) { start || reason }
      cbs.each { |ev, cb| NetworkClient.remove(ev, cb) }
      if start
        run_duel(start)
      else
        pbMessage(reason || _INTL("No response from server."))
      end
    end

    # a challenge to one of AI_DUELISTS: their real deck, played by the AI
    # in this game; beating them gives AI_DUEL_REWARD
    def run_ai_duel(data)
      name = data["opp_name"].to_s
      unless valid_deck?(data["deck"])
        pbMessage(_INTL("{1}'s deck can't be used right now.", name))
        return
      end
      portrait = data["portrait"].to_s
      portrait = nil if portrait.empty?
      pbTCGDuel(name, data["deck"].map(&:to_sym), prizes: 6, id: :"online_#{name.downcase}",
                portrait: portrait, reward: AI_DUEL_REWARD)
    end

    # an AI duelist's game keeps the server's copy of their dueling deck
    # up to date (checked every few seconds on the map)
    def upload_ai_deck
      return unless online?
      return unless AI_DUELISTS.any? { |n| n.downcase == NetworkAuth.username.to_s.downcase }
      @upload_timer = (@upload_timer || 0) + 1
      return if @upload_timer < 300
      @upload_timer = 0
      cards = TCG.active_deck_cards
      return if cards.nil? || cards.size != DECK_SIZE || cards == @uploaded_deck
      NetworkClient.send_msg({ action: "tcg_ai_deck", deck: cards.map(&:to_s) })
      @uploaded_deck = cards.dup
    end

    def run_duel(data)
      duel_id = data["duel_id"].to_s
      opp     = data["opp_name"].to_s
      unless valid_deck?(data["my_deck"]) && valid_deck?(data["opp_deck"])
        NetworkClient.send_msg({ action: "tcg_result", duel_id: duel_id, result: "abort" })
        pbMessage(_INTL("One of the decks can't be used. Duel cancelled."))
        return
      end
      my_cards  = data["my_deck"].map(&:to_sym)
      opp_cards = data["opp_deck"].map(&:to_sym)
      challenger = data["challenger"] ? Duel::PLAYER : Duel::OPPONENT
      player_name = $player ? $player.name : "Player"
      @session = NetSession.new(duel_id, opp)
      result = nil
      error  = nil
      TCG.with_duel_music do
        TCG.dueling = true
        TCG.with_battle_speed do
          pbFadeOutIn do
            scene = DuelScene.new
            begin
              duel = NetDuel.new(@session, challenger,
                                 player_name, my_cards, NetLocalController.new(scene, @session),
                                 opp, opp_cards, NetRemoteController.new(scene, @session),
                                 prizes: 6, ui: scene)
              scene.duel = duel
              TCG.net_duel = duel
              result = duel.start
            rescue NetAbort => e
              error = e.message
            ensure
              TCG.net_duel = nil
              scene.dispose
              TCG.dueling = false
            end
          end
        end
      end
      outcome = result == DUEL_WIN ? "win" : (result == DUEL_LOSS ? "loss" : "abort")
      NetworkClient.send_msg({ action: "tcg_result", duel_id: duel_id, result: outcome })
      @session = nil
      if error
        pbMessage(_INTL("{1} Duel ended.", error))
      elsif result == DUEL_WIN
        TCG.wins[:online] = TCG.wins[:online].to_i + 1
      end
      Game.save(safe: true) if defined?(Game) && Game.respond_to?(:save)
    ensure
      @session = nil
      TCG.net_duel = nil
    end
  end

  #----------------------------------------------------------------------------
  # chat name chips: "Trade / Battle / Triad / Card Duel" on a player's chip
  # tells the server, which sends chip_action to this game
  #----------------------------------------------------------------------------
  module ChipActions
    @pending = nil

    module_function

    def queue(d); @pending = d; end

    def process
      return unless @pending
      return unless $scene.is_a?(Scene_Map)
      return if $game_system.map_interpreter.running? || $game_temp.in_menu || TCG.dueling? || NetPvP.busy?
      d = @pending
      @pending = nil
      target = d["target"].to_s
      return if target.empty?
      case d["kind"].to_s
      when "trade"
        return unless pbConfirmMessage(_INTL("Ask {1} to trade?", target))
        NetworkTrade.request_trade(target)
      when "battle"
        c = pbMessage(_INTL("Battle {1}? Single or Double battle?", target),
                      [_INTL("Single"), _INTL("Double"), _INTL("Cancel")], 3)
        return unless c == 0 || c == 1
        NetworkBattle.request_battle(target, c == 1 ? "double" : "single")
      when "triad"
        return unless pbConfirmMessage(_INTL("Challenge {1} to Pokémon Triad?", target))
        NetworkTriad.instance_variable_set(:@chip_target, target)
        NetworkTriad.request_duel
        NetworkTriad.instance_variable_set(:@chip_target, nil)
      when "duel"
        return unless pbConfirmMessage(_INTL("Challenge {1} to a card duel?", target))
        NetPvP.request_duel(target)
      end
    end
  end
end

#------------------------------------------------------------------------------
# game hooks (not in the headless test harness)
#------------------------------------------------------------------------------
if defined?(NetworkClient)
  %w[tcg_move_relay tcg_seed tcg_ended tcg_desync].each do |ev|
    NetworkClient.on(ev) { |d| TCG::NetPvP.route(ev, d) }
  end
  NetworkClient.on("tcg_request") { |d| TCG::NetPvP.queue_incoming(d) }
  NetworkClient.on("chip_action") { |d| TCG::ChipActions.queue(d) }

  EventHandlers.add(:on_frame_update, :tcg_net_duel_pending,
    proc {
      next unless TCG::NetPvP.online?
      TCG::NetPvP.upload_ai_deck
      TCG::NetPvP.process_incoming
      TCG::ChipActions.process
    }
  )

  # a chip's Triad challenge skips the "Who do you want to duel?" list
  class << NetworkTriad
    alias tcg_chip__select_player _select_player
    def _select_player(players, prompt)
      t = @chip_target
      return t if t
      tcg_chip__select_player(players, prompt)
    end
  end
end

# "Online Duel" in the card game menu (Pokégear)
TCG::MENU_OPTIONS << :online unless TCG::MENU_OPTIONS.include?(:online)
TCG::MENU_LABELS[:online] = "Online Duel"

module TCG
  class << self
    alias net_open_menu_option open_menu_option
    def open_menu_option(opt)
      return NetPvP.request_duel if opt == :online
      net_open_menu_option(opt)
    end
  end
end

#------------------------------------------------------------------------------
# pause menu SERVER: the same entry as 023_Networking/004_NetworkMenu.rb with
# "Card Duel" added after Triad
#------------------------------------------------------------------------------
if defined?(NetworkClient)
  MenuHandlers.add(:pause_menu, :server, {
    "name"  => _INTL("SERVER"),
    "order" => 55,
    "desc"  => _INTL("Online features"),
    "effect" => proc { |menu|
      pbPlayDecisionSE

      unless NetworkAuth.logged_in?
        connected = NetworkAuth.auto_connect
        unless connected
          next false
        end
        pbMessage(_INTL("Connected to the server!"))
        File.delete(File.join(ENV['LOCALAPPDATA'] || '', 'EojChatData', 'Default', 'Preferences')) rescue nil
        system("start \"\" msedge --user-data-dir=\"%LOCALAPPDATA%\\EojChatData\" --app=\"#{NetworkClient::CHAT_URL}/?name=#{NetworkAuth.username}\" --window-size=420,580 --window-position=1170,80")
      end

      cmd = pbMessage(
        _INTL("What would you like to do?"),
        [_INTL("Trade"), _INTL("Battle"), _INTL("Triad"), _INTL("Card Duel"), _INTL("Chat"), _INTL("Cancel")], 6
      )

      if cmd == 0
        menu.pbHideMenu
        NetworkTrade.request_trade
        menu.pbEndScene
        next true
      elsif cmd == 1
        size_cmd = pbMessage(
          _INTL("Single or Double battle?"),
          [_INTL("Single"), _INTL("Double"), _INTL("Cancel")], 3
        )
        if size_cmd == 0 || size_cmd == 1
          menu.pbHideMenu
          NetworkBattle.request_battle(nil, size_cmd == 1 ? 'double' : 'single')
          menu.pbEndScene
        end
        next true
      elsif cmd == 2
        menu.pbHideMenu
        NetworkTriad.request_duel
        menu.pbEndScene
        next true
      elsif cmd == 3
        menu.pbHideMenu
        TCG::NetPvP.request_duel
        menu.pbEndScene
        next true
      elsif cmd == 4
        # Kill any existing EojChat Edge window, then open fresh.
        # This fixes zombie SSE connections where the window looks open but chat is dead.
        begin
          ps = "Get-CimInstance Win32_Process -Filter \"Name='msedge.exe'\" |" \
               " Where-Object { $_.CommandLine -like '*EojChatData*' } |" \
               " ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
          File.open('_kill_chat.ps1', 'w') { |f| f.write(ps) }
          system('powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File _kill_chat.ps1')
          File.delete('_kill_chat.ps1') rescue nil
        rescue => e
          puts "[Chat] Could not kill old window: #{e.message}"
        end
        File.delete(File.join(ENV['LOCALAPPDATA'] || '', 'EojChatData', 'Default', 'Preferences')) rescue nil
        system("start \"\" msedge --user-data-dir=\"%LOCALAPPDATA%\\EojChatData\" --app=\"#{NetworkClient::CHAT_URL}/?name=#{NetworkAuth.username}\" --window-size=420,580 --window-position=1170,80")
        next false
      end

      next false
    }
  })
end
