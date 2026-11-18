#===============================================================================
# Lazor Ball - laser tag with Poké Balls (server: handlers/lazor_ball.js)
# By InTheLight
#
# Its own map (LAZOR_MAP, a copy of the New Dimension's maze). An NPC event
# with the script call   pbLazorBall   (put it last in the event): Play /
# Score Board (this month's top 5; the top 3 get 10 / 5 / 1 Server Tokens when
# the month ends) / Quit. Play starts a round if there's none and teleports
# you to a random free tile.
# You can come in during the first 5 minutes of a round. Everyone's in PvP:
# you hit, and get hit by, the other players and the NPCs. 20 minutes
# (the clock isn't shown): 10 NPC trainers hunt the players, and one more
# comes every minute. Everyone has 3 lives; a ball that hits takes one; no
# lives left and you're out: back to LAZOR_RETURN, and you can't come back
# in until the round's over (leaving the map counts as out too). At the end
# everyone still there sees the results and goes back to LAZOR_RETURN.
#
# Space throws a ball 5 tiles the way you face (every 1.5 seconds). An NPC
# stops and turns to you before it throws: step out of its line.
# Poké Balls on the floor: walk onto one for an extra life, double points or
# quick throws (30 seconds). Special Pokémon run around: hit one for 1000
# points, but if one runs into you it's a battle (and the clock keeps going).
#
# Points (doubled with double points): ball hits an NPC 100, knocks it out
# +300 / hits a player 150, knocks them out +500 / special Pokémon 1000 /
# still in at the end 1000 + 250 a life. Scores go to the Hall of Records.
#
# On this map the speed-up (Q) is off: everyone moves at the same speed.
#===============================================================================
LAZOR_MAP            = 509     # must match MAP_ID (server)
LAZOR_RETURN         = [149, 20, 17]   # map, x, y: where you go when you're out / the round's over
LAZOR_THROW_RANGE    = 5       # must match THROW_RANGE (server)
LAZOR_BALL_TILE_TIME = 0.06    # seconds a tile, your balls (server: PLAYER_BALL_MS)
LAZOR_THROW_TIME     = 1.5     # seconds between throws (server: THROW_MS)
LAZOR_RAPID_TIME     = 0.6     # with quick throws (server: RAPID_THROW_MS)
LAZOR_BALL_GRAPHIC   = "Graphics/Items/POKEBALL"
LAZOR_ITEM_GRAPHIC   = "Graphics/Items/POKEBALL"

# an NPC trainer or a special Pokémon on the map (moves where the server says)
class LazorCharacter < ShadowLugiaCharacter
  def initialize(map, charset, step_anime)
    super(map, :LAZOR, charset)
    @step_anime    = step_anime
    @always_on_top = false
  end

  def name; "Lazor Ball"; end
end

module LazorBall
  @phase    = nil     # "idle" "play" "over" (nil: nothing yet)
  @round    = nil
  @ends_at  = 0.0     # System.unscaled_uptime
  @players  = []      # [{ "name", "lives", "score", "out", "pvp", "mult_ms", "rapid_ms", "battling", "kos" }]
  @results  = nil
  @npcs     = {}      # id => { info:, started:, char:, sprite:, pips:, pips_key: }
  @specials = {}      # id => { info:, started:, char:, sprite: }
  @items    = {}      # id => { kind:, x:, y:, sprite:, asked: }
  @balls    = {}      # key => { from:, dir:, d:, tile:, steps:, t0:, tile_time:, range:, sprite: }
  @hello    = false
  @shown    = nil     # the round we showed the results of
  @going    = false   # on our way back to LAZOR_RETURN
  @busy     = false   # a message/battle of ours is up
  @battle   = nil     # a special Pokémon's species: a battle to start
  @thrown   = 0.0
  @cid      = 0
  @touched  = 0.0
  @feed     = []      # [[text, until]]
  @hud      = nil
  @board    = nil
  @hud_key  = nil
  @locked   = false   # the speed-up is held off
  @me_at    = 0.0     # my scores entry came in (its _ms count from then)

  class << self
    def here?; $game_map&.map_id == LAZOR_MAP && $scene.is_a?(Scene_Map); end
    def online?; defined?(NetworkAuth) && NetworkAuth.logged_in?; end
    def now; System.unscaled_uptime; end

    def free?
      $scene.is_a?(Scene_Map) && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
        !$game_temp.message_window_showing && !$game_temp.player_transferring && !$game_temp.in_battle
    end

    def me; @players.find { |p| p["name"] == NetworkAuth.username }; end
    def in?; (m = me) && !m["out"] && !m["battling"]; end

    #---------------------------------------------------------------------------
    # From the server
    #---------------------------------------------------------------------------
    def set_state(d)
      @phase   = d["phase"].to_s
      @round   = d["round"]
      @ends_at = now + (d["ends_in_ms"].to_i / 1000.0)
      @results = d["results"]
      set_scores(d) if d["players"]
      clear_things
      (d["npcs"] || []).each { |n| set_npc(n) }
      (d["specials"] || []).each { |s| set_special(s) }
      (d["items"] || []).each { |i| add_item(i) }
      @hud_key = nil
    end

    def set_scores(d)
      @players = d["players"] || []
      @me_at = now
      @hud_key = nil
    end

    def set_npc(d)
      e = (@npcs[d["id"]] ||= {})
      e[:info] = d
      e[:started] = now - (d["elapsed_ms"].to_i / 1000.0)
    end

    def set_special(d)
      e = (@specials[d["id"]] ||= {})
      e[:info] = d
      e[:started] = now - (d["elapsed_ms"].to_i / 1000.0)
    end

    def remove_special(id)
      e = @specials.delete(id)
      dispose_entry(e) if e
    end

    def add_item(d)
      @items[d["id"]] = { kind: d["kind"], x: d["x"].to_i, y: d["y"].to_i }
    end

    def remove_item(d)
      e = @items.delete(d["id"])
      e[:sprite]&.dispose if e
      return unless d["by"]
      text = { "life" => _INTL("an extra life"), "mult" => _INTL("double points"), "rapid" => _INTL("quick throws") }[d["kind"].to_s]
      if d["by"] == NetworkAuth.username
        pbSEPlay("Mining found all") if FileTest.audio_exist?("Audio/SE/Mining found all")
        feed(_INTL("You got {1}!", text))
      else
        feed(_INTL("{1} got {2}!", d["by"], text))
      end
    end

    # a ball someone else threw (or an NPC)
    def add_ball(d)
      dir = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }[d["dir"].to_i]
      return unless dir && here?
      from = d["from"].map(&:to_i)
      start_ball(d["id"], from, dir, d["dir"].to_i, d["ms_per_tile"].to_i / 1000.0, d["range"].to_i)
      if d["by_kind"] == "npc" && (e = @npcs[d["by"]])
        e[:char]&.instance_variable_set(:@direction, d["dir"].to_i)
      end
    end

    def on_hit(d)
      key = d["by"] == NetworkAuth.username && d["cid"] ? "c#{d['cid']}" : d["ball"]
      end_ball(key)
      mine = d["by"] == NetworkAuth.username
      by = d["by_kind"] == "npc" ? (@npcs.dig(d["by"], :info, "name") || "?") : d["by"]
      case d["kind"]
      when "npc"
        e = @npcs[d["target"]]
        e&.dig(:sprite)&.flash(Color.new(255, 255, 255, 220), 12)
        if e
          e[:info]["lives"] = d["lives"].to_i
          e[:pips_key] = nil
        end
        if d["out"]
          feed(mine ? _INTL("You knocked out {1}!", d["name"]) : _INTL("{1} knocked out {2}!", by, d["name"]))
          remove_npc(d["target"])
        end
        hit_sound if mine
      when "special"
        name = GameData::Species.exists?(d["species"].to_s) ? GameData::Species.get(d["species"].to_s).name : d["species"].to_s
        feed(mine ? _INTL("You hit {1}! Bonus points!", name) : _INTL("{1} hit {2}!", by, name))
        remove_special(d["target"])
        hit_sound if mine
      when "player"
        if d["target"] == NetworkAuth.username
          $game_screen.start_flash(Color.new(255, 40, 40, 160), 8)
          pbSEPlay("Battle damage weak") if FileTest.audio_exist?("Audio/SE/Battle damage weak")
          feed(d["out"] ? _INTL("{1} hit you! You're out!", by) : _INTL("{1} hit you!", by))
        else
          sprites = defined?(NetworkOverworld) && NetworkOverworld.instance_variable_get(:@char_sprites)
          sprites&.dig(d["target"])&.flash(Color.new(255, 255, 255, 220), 12) rescue nil
          if mine
            hit_sound
            feed(d["out"] ? _INTL("You knocked out {1}!", d["target"]) : _INTL("You hit {1}!", d["target"]))
          elsif d["out"]
            feed(_INTL("{1} knocked out {2}!", by, d["target"]))
          end
        end
      end
    end

    def hit_sound
      pbSEPlay("Battle damage normal") if FileTest.audio_exist?("Audio/SE/Battle damage normal")
    end

    def feed(text)
      @feed << [text, now + 3.5]
      @feed.shift while @feed.length > 3
      @hud_key = nil
    end

    #---------------------------------------------------------------------------
    # Every frame
    #---------------------------------------------------------------------------
    def tick
      stop_map_timer if here?
      return if @busy
      unless here? && online?
        leave if @locked || @phase
        return
      end
      return if @going
      lock_speed
      unless @hello
        @hello = true
        NetworkClient.send_msg({ action: "lazor_hello" })
      end
      return unless @phase
      update_things
      update_balls
      update_hud
      return unless free?
      return start_battle if @battle
      return show_results if @phase == "over" && @results && @shown != @round
      return go_home unless @phase == "play" && in_round?
      return unless in?
      check_items
      check_specials
      check_throw
    end

    # Q (the speed-up) is off on this map: everyone moves at the same speed
    def lock_speed
      @locked = true
      $GameSpeed = 0 if defined?($GameSpeed)
      $CanToggle = false if defined?($CanToggle)
    end

    # the map's own event (EV001, from the New Dimension copy) starts the game's
    # 10 minute timer (top right; at 0 it sends you to map 92): not for Lazor Ball.
    # With no timer that event's "timer <= 0" check is false, so it never fires.
    def stop_map_timer
      $game_system.timer_start = nil if $game_system&.timer_start
    end

    def leave
      stop_map_timer if @locked || @phase
      if @locked
        @locked = false
        $CanToggle = $PokemonSystem.only_speedup_battles == 0 if $PokemonSystem.respond_to?(:only_speedup_battles)
      end
      @phase = nil
      @hello = false
      @players = []
      @battle = nil
      clear_things
      dispose_hud
    end

    def entered_map
      @hello = false
      @going = false
      @phase = nil     # wait for the server's state for this visit
      leave unless here?
    end

    # still in this round (out = you've had your go)
    def in_round?
      m = me
      m && !m["out"]
    end

    #---------------------------------------------------------------------------
    # Coming in (pbLazorBall) and going back (LAZOR_RETURN)
    #---------------------------------------------------------------------------
    def transfer(map_id, x, y, dir = 2)
      $game_temp.player_new_map_id    = map_id
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = dir
      $game_temp.player_transferring  = true
    end

    # out, the round's over, or no round for us here: back to LAZOR_RETURN
    def go_home
      m = me
      @busy = true
      if m && m["out"] && @phase == "play"
        pbMessage(_INTL("You're out! You scored {1} points.", m["score"].to_i.to_s_formatted))
        pbMessage(_INTL("You can play again when this round is over."))
      end
    ensure
      @busy = false
      @going = true
      stop_map_timer
      transfer(*LAZOR_RETURN)
    end

    # the NPC's script call: Play / Score Board / Quit. True if you're on your way in
    def npc_menu
      unless online?
        pbMessage(_INTL("You need to be online to play Lazor Ball."))
        return false
      end
      loop do
        cmd = pbMessage(_INTL("Welcome to Lazor Ball!"),
                        [_INTL("Play"), _INTL("Score Board"), _INTL("Quit")], 3)
        case cmd
        when 0 then return enter
        when 1 then show_month_board
        else return false
        end
      end
    end

    # send a request, wait (up to 5 seconds) for one of the replies
    def ask_server(msg, *events)
      result = nil
      blocks = events.map { |ev| [ev, NetworkClient.on(ev) { |d| result = d }] }
      NetworkClient.send_msg(msg)
      300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
      result
    ensure
      blocks&.each { |ev, b| NetworkClient.remove(ev, b) }
    end

    # this month's top 5 (the top 3 win Server Tokens when the month ends)
    def show_month_board
      d = ask_server({ action: "lazor_board" }, "lazor_board")
      return pbMessage(_INTL("No answer from the server. Try again in a moment.")) unless d
      top = d["top"] || []
      prizes = d["prizes"] || [10, 5, 1]
      if top.empty?
        pbMessage(_INTL("Lazor Ball - {1}\nNo scores yet this month. Be the first!", d["month"]))
      else
        lines = top.each_with_index.map { |r, i| _INTL("{1}. {2} - {3}", i + 1, r["name"], r["score"].to_i.to_s_formatted) }
        pbMessage(_INTL("Lazor Ball - {1}", d["month"]) + "\n" + lines.first(3).join("\n"))
        pbMessage(lines[3..].join("\n")) if lines.length > 3
      end
      pbMessage(_INTL("At the end of the month, 1st place gets {1} Server Tokens, 2nd gets {2} and 3rd gets {3}!",
                      prizes[0], prizes[1], prizes[2]))
    end

    def enter
      result = ask_server({ action: "lazor_enter" }, "lazor_enter_ok", "lazor_enter_no")
      if !result
        pbMessage(_INTL("No answer from the server. Try again in a moment."))
        return false
      elsif result["event"] == "lazor_enter_no"
        pbMessage(case result["why"].to_s
                  when "late" then _INTL("This round of Lazor Ball started more than 5 minutes ago. Wait for the next one!")
                  when "out"  then _INTL("You've already played this round. Wait for it to end!")
                  when "over" then _INTL("A round just ended. Try again in a moment!")
                  else _INTL("Lazor Ball isn't open right now.")
                  end)
        return false
      end
      pbMessage(_INTL("You're in! Space throws a ball. Three hits and you're out!"))
      transfer(LAZOR_MAP, result["x"].to_i, result["y"].to_i)
      true
    end

    #---------------------------------------------------------------------------
    # Results / special battles (only when the player is free)
    #---------------------------------------------------------------------------

    def show_results
      @shown = @round
      ranking = (@results["ranking"] || [])
      return if ranking.empty?
      lines = ranking.first(5).each_with_index.map do |r, i|
        _INTL("{1}. {2} - {3}", i + 1, r["name"], r["score"].to_i.to_s_formatted)
      end
      @busy = true
      pbMessage(_INTL("Lazor Ball is over!") + "\n" + lines.join("\n"))
      mine = ranking.find { |r| r["name"] == NetworkAuth.username }
      pbMessage(_INTL("Your score: {1} points.", mine["score"].to_i.to_s_formatted)) if mine
    ensure
      @busy = false
    end

    def start_battle
      species = @battle
      @battle = nil
      @busy = true
      if GameData::Species.exists?(species)
        able = $player.able_party
        level = able.empty? ? 20 : able.map(&:level).max
        setBattleRule("canLose")
        WildBattle.start(species.to_sym, level.clamp(5, GameData::GrowthRate.max_level))
      end
    ensure
      @busy = false
      NetworkClient.send_msg({ action: "lazor_battle_end" }) if online?
    end

    #---------------------------------------------------------------------------
    # Your throws, pick-ups and running into special Pokémon
    #---------------------------------------------------------------------------
    def space_pressed?
      return Input.triggerex?(:SPACE) if Input.respond_to?(:triggerex?)
      Input.trigger?(Input::USE)
    end

    def throw_time
      m = me
      rapid = m && m["rapid_ms"].to_i / 1000.0 - (now - @me_at) > 0
      rapid ? LAZOR_RAPID_TIME : LAZOR_THROW_TIME
    end

    def check_throw
      return unless in? && space_pressed?
      return if now - @thrown < throw_time
      return if $game_player.pbFacingEvent
      d = $game_player.direction
      dir = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }[d]
      return unless dir
      @thrown = now
      @cid += 1
      from = [$game_player.x, $game_player.y]
      NetworkClient.send_msg({ action: "lazor_throw", x: from[0], y: from[1], dir: d, cid: @cid })
      start_ball("c#{@cid}", from, dir, d, LAZOR_BALL_TILE_TIME, LAZOR_THROW_RANGE)
      pbSEPlay("Battle throw") if FileTest.audio_exist?("Audio/SE/Battle throw")
    end

    def check_items
      return unless in?
      at = [$game_player.x, $game_player.y]
      @items.each do |id, e|
        next if e[:asked] || [e[:x], e[:y]] != at
        e[:asked] = true
        NetworkClient.send_msg({ action: "lazor_pickup", id: id })
      end
    end

    def check_specials
      return unless in? && now - @touched >= 1.0
      at = [$game_player.x, $game_player.y]
      @specials.each do |id, e|
        tiles = [position(e)[0, 2]]
        tiles << [e[:char].x, e[:char].y] if e[:char]
        next unless tiles.include?(at)
        @touched = now
        NetworkClient.send_msg({ action: "lazor_special_touch", id: id })
        break
      end
    end

    #---------------------------------------------------------------------------
    # Drawing: NPCs, special Pokémon, Poké Balls on the floor
    #---------------------------------------------------------------------------
    def position(e, ahead = false)
      i = e[:info]
      ms = ((now - e[:started]) * 1000).to_i
      ms += i["ms_per_tile"].to_i if ahead
      ShadowLugia.position_at(i["path"], [i["ms_per_tile"].to_i, 1].max, ms, 0)
    end

    def update_things
      vp = Spriteset_Map.viewport
      return unless vp
      @npcs.each_value { |e| update_mover(e, vp, e[:info]["look"].to_s, false, true) }
      @specials.each_value do |e|
        sp = e[:info]["species"].to_s
        charset = ["Followers/#{sp}", "Followers/000"].find { |c| pbResolveBitmap("Graphics/Characters/#{c}") } || "Followers/000"
        update_mover(e, vp, charset, true, false)
      end
      @items.each_value do |e|
        unless e[:sprite]
          e[:sprite] = Sprite.new(vp)
          path = pbResolveBitmap(LAZOR_ITEM_GRAPHIC)
          e[:sprite].bitmap = Bitmap.new(path) if path
          e[:sprite].ox = (e[:sprite].bitmap&.width || 0) / 2
          e[:sprite].oy = (e[:sprite].bitmap&.height || 0) / 2
          e[:sprite].zoom_x = e[:sprite].zoom_y = 0.5
          e[:sprite].z = 10
        end
        place(e[:sprite], e[:x], e[:y], (Math.sin(now * 4) * 2).round)
      end
    end

    def update_mover(e, vp, charset, step_anime, pips)
      if !e[:char] || e[:sprite].disposed?
        e[:char] = LazorCharacter.new($game_map, charset, step_anime)
        e[:char].moveto(*position(e)[0, 2])
        e[:sprite] = Sprite_Character.new(vp, e[:char])
      end
      ms = e[:info]["ms_per_tile"].to_i
      e[:char].move_speed = BLOOD_BOSS_SPEEDS[ms] || (ms <= 150 ? 4 : 3)
      unless e[:char].moving?
        e[:char].fly_to(*position(e, true))
        face = e[:info]["face"].to_i
        e[:char].instance_variable_set(:@direction, face) if face > 0 && !e[:char].moving?
      end
      e[:char].update
      e[:sprite].update
      update_pips(e, vp) if pips
    end

    # an NPC's lives, little dots over its head
    def update_pips(e, vp)
      lives = e[:info]["lives"].to_i
      unless e[:pips]
        e[:pips] = Sprite.new(vp)
        e[:pips].bitmap = Bitmap.new(20, 6)
        e[:pips].z = 999_998
      end
      if e[:pips_key] != lives
        e[:pips_key] = lives
        b = e[:pips].bitmap
        b.clear
        3.times do |i|
          b.fill_rect(i * 7, 0, 6, 6, Color.new(40, 0, 0))
          b.fill_rect((i * 7) + 1, 1, 4, 4, i < lives ? Color.new(240, 40, 40) : Color.new(90, 90, 90))
        end
      end
      e[:pips].x = e[:char].screen_x - 10
      e[:pips].y = e[:char].screen_y - 44
    end

    def place(sprite, fx, fy, dy = 0)
      sprite.x = ((fx * Game_Map::REAL_RES_X - $game_map.display_x) / Game_Map::X_SUBPIXELS).round + (Game_Map::TILE_WIDTH / 2)
      sprite.y = ((fy * Game_Map::REAL_RES_Y - $game_map.display_y) / Game_Map::Y_SUBPIXELS).round + (Game_Map::TILE_HEIGHT / 2) - 8 + dy
    end

    def remove_npc(id)
      e = @npcs.delete(id)
      dispose_entry(e) if e
    end

    def dispose_entry(e)
      e[:sprite]&.dispose
      e[:pips]&.bitmap&.dispose
      e[:pips]&.dispose
      e[:sprite] = e[:char] = e[:pips] = nil
    end

    def clear_things
      @npcs.each_value { |e| dispose_entry(e) }
      @specials.each_value { |e| dispose_entry(e) }
      @items.each_value { |e| e[:sprite]&.dispose }
      @balls.keys.each { |k| end_ball(k) }
      @npcs = {}
      @specials = {}
      @items = {}
    end

    #---------------------------------------------------------------------------
    # Balls in the air (just drawn: the server decides what they hit)
    #---------------------------------------------------------------------------
    def start_ball(key, from, dir, d, tile_time, range)
      b = { from: from, tile: from.dup, dir: dir, d: d, t0: now, steps: 0, tile_time: [tile_time, 0.01].max, range: range }
      vp = Spriteset_Map.viewport
      path = pbResolveBitmap(LAZOR_BALL_GRAPHIC)
      if vp && path
        b[:sprite] = Sprite.new(vp)
        b[:sprite].bitmap = Bitmap.new(path)
        b[:sprite].ox = b[:sprite].bitmap.width / 2
        b[:sprite].oy = b[:sprite].bitmap.height / 2
        b[:sprite].zoom_x = b[:sprite].zoom_y = 0.5
        b[:sprite].z = 999_999
      end
      end_ball(key)
      @balls[key] = b
    end

    def end_ball(key)
      b = @balls.delete(key)
      return unless b
      b[:sprite]&.bitmap&.dispose
      b[:sprite]&.dispose
    end

    def update_balls
      @balls.keys.each do |key|
        b = @balls[key]
        flown = (now - b[:t0]) / b[:tile_time]
        gone = false
        while b[:steps] < flown.floor
          x, y = b[:tile]
          nx, ny = x + b[:dir][0], y + b[:dir][1]
          if b[:steps] >= b[:range] || !$game_map.valid?(nx, ny) ||
             !$game_map.passable?(x, y, b[:d]) || !$game_map.passable?(nx, ny, 10 - b[:d])
            gone = true
            break
          end
          b[:tile] = [nx, ny]
          b[:steps] += 1
        end
        gone ||= flown > b[:range] + 0.5
        next end_ball(key) if gone
        s = b[:sprite]
        next unless s
        f = [flown, b[:steps] + 0.99].min
        place(s, b[:from][0] + (b[:dir][0] * f), b[:from][1] + (b[:dir][1] * f))
        s.angle = (f * 120) % 360
      end
    end

    #---------------------------------------------------------------------------
    # The HUD: the clock, your lives / points / power-ups (left), the top 3 (right)
    #---------------------------------------------------------------------------
    def dispose_hud
      [@hud, @board].each do |s|
        next unless s
        s.bitmap&.dispose
        s.dispose
      end
      @hud = @board = nil
      @hud_key = nil
    end

    def clock_text
      secs = [(@ends_at - now).ceil, 0].max
      format("%d:%02d", secs / 60, secs % 60)
    end

    def update_hud
      @feed.reject! { |_t, till| now > till }
      unless @hud
        @hud = Sprite.new
        @hud.bitmap = Bitmap.new(170, 74)
        @hud.x = 2
        @hud.y = 2
        @hud.z = 99_999
        @board = Sprite.new
        @board.bitmap = Bitmap.new(116, 56)
        @board.x = Graphics.width - 118
        @board.y = 2
        @board.z = 99_999
      end
      m = me
      left = now - @me_at
      mult  = m ? [(m["mult_ms"].to_i / 1000.0 - left).ceil, 0].max : 0
      rapid = m ? [(m["rapid_ms"].to_i / 1000.0 - left).ceil, 0].max : 0
      top = @players.first(3).map { |p| [p["name"], p["score"], p["out"]] }
      key = [@phase, m &&[m["lives"], m["score"], m["out"], m["battling"]], mult, rapid, top, @feed.map(&:first), @npcs.size]
      return if key == @hud_key
      @hud_key = key
      draw_hud(m, mult, rapid)
      draw_board
    end

    def draw_hud(m, mult, rapid)
      b = @hud.bitmap
      b.clear
      b.fill_rect(0, 0, b.width, 36, Color.new(0, 0, 0, 150))
      pbSetSmallFont(b)
      white = [Color.new(248, 248, 248), Color.new(40, 40, 40)]
      red   = [Color.new(255, 120, 120), Color.new(60, 0, 0)]
      gold  = [Color.new(255, 220, 90), Color.new(70, 50, 0)]
      title = case @phase    # no clock: nobody knows how long is left
              when "play" then _INTL("Lazor Ball NPCs: {1}", @npcs.size)
              when "over" then _INTL("Lazor Ball is over")
              else _INTL("Lazor Ball")
              end
      texts = [[title, 4, 0, :left, *white]]
      if m
        if m["out"]
          texts << [_INTL("Out! {1} pts", m["score"].to_i.to_s_formatted), 4, 16, :left, *red]
        else
          lives = m["lives"].to_i
          texts << [_INTL("{1} pts", m["score"].to_i.to_s_formatted), 4 + (lives * 12) + 4, 16, :left, *white]
          lives.times do |i|
            b.fill_rect(4 + (i * 12), 20, 10, 10, Color.new(60, 0, 0))
            b.fill_rect(5 + (i * 12), 21, 8, 8, Color.new(240, 40, 40))
            b.fill_rect(5 + (i * 12), 25, 8, 1, Color.new(60, 0, 0))
          end
        end
        power = []
        power << _INTL("x2 {1}s", mult) if mult > 0
        power << _INTL("Quick {1}s", rapid) if rapid > 0
        texts << [power.join("  "), b.width - 4, 16, :right, *gold] unless power.empty?
      elsif @phase == "play" || @phase == "over"
        texts << [_INTL("Watching"), 4, 16, :left, *white]
      end
      @feed.each_with_index { |(t, _), i| texts << [t, 4, 38 + (i * 12), :left, *gold] }
      pbDrawTextPositions(b, texts)
    end

    def draw_board
      b = @board.bitmap
      b.clear
      return if @players.empty?
      b.fill_rect(0, 0, b.width, 4 + (@players.first(3).size * 16), Color.new(0, 0, 0, 150))
      pbSetSmallFont(b)
      texts = []
      @players.first(3).each_with_index do |p, i|
        c = p["out"] ? [Color.new(150, 150, 150), Color.new(30, 30, 30)] : [Color.new(248, 248, 248), Color.new(40, 40, 40)]
        texts << ["#{i + 1}. #{p['name'].to_s[0, 9]}", 4, i * 16, :left, *c]
        texts << [p["score"].to_i.to_s_formatted, b.width - 4, i * 16, :right, *c]
      end
      pbDrawTextPositions(b, texts)
    end
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("lazor_state") { |d| LazorBall.set_state(d) }
NetworkClient.on("lazor_scores") { |d| LazorBall.set_scores(d) }
NetworkClient.on("lazor_npc") { |d| LazorBall.set_npc(d) }
NetworkClient.on("lazor_special") { |d| LazorBall.set_special(d) }
NetworkClient.on("lazor_special_gone") { |d| LazorBall.remove_special(d["id"]) }
NetworkClient.on("lazor_item") { |d| LazorBall.add_item(d) }
NetworkClient.on("lazor_item_gone") { |d| LazorBall.remove_item(d) }
NetworkClient.on("lazor_ball") { |d| LazorBall.add_ball(d) }
NetworkClient.on("lazor_hit") { |d| LazorBall.on_hit(d) }
NetworkClient.on("lazor_special_battle") { |d| LazorBall.instance_variable_set(:@battle, d["species"].to_s) }
NetworkClient.on("login_ok") { |_d| LazorBall.entered_map }

# Event script call (the NPC that lets you in; put it last in the event)
def pbLazorBall
  LazorBall.npc_menu
end

EventHandlers.add(:on_enter_map, :lazor_ball, proc { |_old_map_id| LazorBall.entered_map })
EventHandlers.add(:on_frame_update, :lazor_ball, proc { LazorBall.tick })
