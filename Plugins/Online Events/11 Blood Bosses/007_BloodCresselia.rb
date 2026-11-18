#===============================================================================
# Blood Cresselia (server: handlers/blood_cresselia.js)
#
# Only an admin brings her (chat: CRES.Username, or CRES.rand for anyone with
# 8+ badges; the chat shows "GO CRESSELIA"). After she's caught the one she was
# sent after, she hunts players with 8+ badges at random. She flies through
# walls, over the routes and towns and through doors into houses and caves.
# Everyone sees her. On her target's map she gets in line with them, stops,
# turns to them and throws a Poké Ball (as in Lazor Ball): step out of its line.
#
# A ball that hits her target catches them: they vanish, can't move, and their
# camera follows her as she flies them to Blackthorn City (where Lazor Ball
# sends players back). There the Teleport animation plays and they wake up in
# the New Dimension (map 508, the blood gods' world), free again.
#
# She never leaves on her own. Fly into her for a battle: nothing hurts her,
# and only a Blood Ball can hold her. The first catch ends her for everyone.
#===============================================================================
BLOOD_CRESSELIA_SPECIES   = :BLOODCRESSELIA
BLOOD_CRESSELIA_MOVES     = [:MOONBLAST, :PSYCHIC, :ICEBEAM, :SHADOWBALL]
BLOOD_CRESSELIA_CHARSET   = "Followers/BLOODCRESSELIA"
BLOOD_CRESSELIA_BALL_GRAPHIC = "Graphics/Items/POKEBALL"   # as Lazor Ball
BLOOD_CRESSELIA_DELIVER_MS   = 2500                        # must match DELIVER_MS (server)

module BloodCresselia
  @state  = nil     # { map_id:, path:, ms_per_tile:, exit_dir:, mode:, face:, target:, carrying:, started: }
  @char   = nil
  @sprite = nil
  @balls  = {}      # id => { from:, dir:, d:, t0:, tile_time:, range:, sprite: }
  @battle_triggered = false
  @watch  = nil     # being carried: { menu_disabled:, follower: }
  @caught = false   # her ball got me: start watching when the game's free
  @drop   = nil     # [map, x, y, dimension]: she let go of me
  @dropped_to = nil
  @played_anim = nil

  class << self
    attr_reader :state

    def name
      GameData::Species.exists?(BLOOD_CRESSELIA_SPECIES) ? GameData::Species.get(BLOOD_CRESSELIA_SPECIES).name : "Blood Cresselia"
    end

    def online?; defined?(NetworkAuth) && NetworkAuth.logged_in?; end
    def active?; !@state.nil?; end
    def me?(name); online? && name.to_s.downcase == NetworkAuth.username.to_s.downcase; end
    def watching?; !@watch.nil?; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      @state = { map_id: d["map_id"].to_i, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 mode: d["mode"].to_s, face: d["face"].to_i, target: d["target"], carrying: d["carrying"],
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id]
    end

    def clear
      @state = nil
      destroy_sprite
      @balls.keys.each { |k| end_ball(k) }
    end

    def elapsed_ms; ((System.unscaled_uptime - @state[:started]) * 1000).to_i; end

    def position(ahead = false)
      ms = elapsed_ms
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, @state[:exit_dir])
    end

    def host_map
      id = @state[:map_id]
      return $game_map if $game_map&.map_id == id
      return $map_factory.getMapNoAdd(id) if $map_factory&.hasMap?(id)
      nil
    end

    def entered_map
      destroy_sprite
      @balls.keys.each { |k| end_ball(k) }
    end

    def destroy_sprite
      @sprite&.dispose
      @sprite = nil
      @char = nil
    end

    def free?
      $scene.is_a?(Scene_Map) && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
        !$game_temp.message_window_showing && !$game_temp.player_transferring && !$game_temp.in_battle
    end

    #---------------------------------------------------------------------------
    # Every frame
    #---------------------------------------------------------------------------
    # the server picks random-hunt targets by badges (8 or more): it hears the count
    # on login and whenever it changes
    def hello
      @badges_sent = $player ? $player.badge_count : 0
      NetworkClient.send_msg({ action: "blood_cresselia_hello", badges: @badges_sent })
    end

    def tick
      hello if online? && $player && Graphics.frame_count % 120 == 0 && $player.badge_count != @badges_sent
      start_watch if @caught && free?
      do_drop if @drop && $scene.is_a?(Scene_Map) && !$game_temp.player_transferring && !$game_temp.in_battle
      after_drop if @dropped_to
      watch_tick
      unless active? && online? && $scene.is_a?(Scene_Map)
        destroy_sprite
        return
      end
      update_balls
      map = host_map
      if @char && @char.map != map && @char.moving? && !@sprite.disposed?
        @char.update
        @sprite.update
        follow_camera
        return
      end
      return destroy_sprite unless map
      if !@char || @char.map != map || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_CRESSELIA_CHARSET}") ? BLOOD_CRESSELIA_CHARSET : "Followers/000"
        @char = ShadowLugiaCharacter.new(map, BLOOD_CRESSELIA_SPECIES, charset)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.move_speed = BLOOD_BOSS_SPEEDS[@state[:ms_per_tile]] || 3
      unless @char.moving?
        @char.fly_to(*position(true))
        @char.instance_variable_set(:@direction, @state[:face]) if @state[:face] > 0 && !@char.moving?
      end
      play_deliver_anim
      @char.update
      @sprite.update
      follow_camera
      check_trigger
    end

    # at Blackthorn: the Teleport animation on her
    def play_deliver_anim
      return unless @state[:mode] == "deliver" && !@played_anim.equal?(@state) && @char.map == $game_map
      @played_anim = @state
      @char.animation_id = (GhostTrainer.teleport_anim_id rescue 16)
      pbSEPlay("Teleport") if FileTest.audio_exist?("Audio/SE/Teleport")
    end

    #---------------------------------------------------------------------------
    # Flying into her: the battle (not while she's carrying you)
    #---------------------------------------------------------------------------
    def check_trigger
      return if watching? || @caught || !@char || @char.map != $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        battle = pbBloodBossBattle("blood_cresselia", BLOOD_CRESSELIA_SPECIES, BLOOD_CRESSELIA_MOVES,
                                   Battle::BloodCresseliaEncounter, name)
        clear if battle && battle.boss_caught
      end
    end

    #---------------------------------------------------------------------------
    # Her Poké Balls (drawn here; the server says what they hit)
    #---------------------------------------------------------------------------
    def add_ball(d)
      return unless $game_map && d["map_id"].to_i == $game_map.map_id
      dir = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }[d["dir"].to_i]
      return unless dir
      end_ball(d["id"])
      b = { from: d["from"].map(&:to_i), dir: dir, t0: System.unscaled_uptime,
            tile_time: [d["ms_per_tile"].to_i / 1000.0, 0.01].max, range: d["range"].to_i }
      vp = Spriteset_Map.viewport
      path = pbResolveBitmap(BLOOD_CRESSELIA_BALL_GRAPHIC)
      if vp && path
        b[:sprite] = Sprite.new(vp)
        b[:sprite].bitmap = Bitmap.new(path)
        b[:sprite].ox = b[:sprite].bitmap.width / 2
        b[:sprite].oy = b[:sprite].bitmap.height / 2
        b[:sprite].zoom_x = b[:sprite].zoom_y = 0.5
        b[:sprite].z = 999_999
      end
      @balls[d["id"]] = b
      pbSEPlay("Battle throw") if FileTest.audio_exist?("Audio/SE/Battle throw")
    end

    def end_ball(id)
      b = @balls.delete(id)
      return unless b
      b[:sprite]&.bitmap&.dispose
      b[:sprite]&.dispose
    end

    def update_balls
      @balls.keys.each do |id|
        b = @balls[id]
        f = (System.unscaled_uptime - b[:t0]) / b[:tile_time]
        next end_ball(id) if f > b[:range] + 0.5
        s = b[:sprite]
        next unless s
        fx = b[:from][0] + (b[:dir][0] * f)
        fy = b[:from][1] + (b[:dir][1] * f)
        s.x = ((fx * Game_Map::REAL_RES_X - $game_map.display_x) / Game_Map::X_SUBPIXELS).round + (Game_Map::TILE_WIDTH / 2)
        s.y = ((fy * Game_Map::REAL_RES_Y - $game_map.display_y) / Game_Map::Y_SUBPIXELS).round + (Game_Map::TILE_HEIGHT / 2) - 8
        s.angle = (f * 120) % 360
      end
    end

    #---------------------------------------------------------------------------
    # Caught: hidden, can't move, the camera follows her to Blackthorn
    #---------------------------------------------------------------------------
    def captured(d)
      end_ball(d["ball"])
      return unless me?(d["username"])
      @caught = true
      $game_screen.start_flash(Color.new(255, 40, 40, 200), 12) if $game_screen
      pbSEPlay("Battle recall") if FileTest.audio_exist?("Audio/SE/Battle recall")
    end

    def start_watch
      @caught = false
      return if watching?
      follower = defined?(FollowingPkmn) && $PokemonGlobal.follower_toggled
      @watch = { menu_disabled: $game_system.menu_disabled, follower: follower }
      FollowingPkmn.toggle_off(false) if follower
      $game_player.transparent = true
      $game_system.menu_disabled = true
      pbMessage(_INTL("{1}'s Poké Ball caught you!\nShe's carrying you away...", name))
    end

    def transfer(map_id, x, y, dir = 2)
      $game_temp.player_new_map_id    = map_id
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = dir
      $game_temp.player_transferring  = true
    end

    # she's flown onto another map: there too
    def watch_tick
      return unless watching?
      return if $game_temp.player_transferring || !$scene.is_a?(Scene_Map)
      unless @state && me?(@state[:carrying])
        # she isn't carrying me any more and no drop came (the connection dropped
        # on the way, or she's gone) for 3 seconds: off to the New Dimension anyway
        @watch[:lost] ||= System.unscaled_uptime
        @drop ||= [508, 14, 4, true] if System.unscaled_uptime - @watch[:lost] > 3
        return
      end
      @watch[:lost] = nil
      if $game_map.map_id != @state[:map_id] && !(@char && @char.moving? && @char.map == $game_map)
        transfer(@state[:map_id], *position[0, 2])
      end
    end

    def follow_camera
      return unless watching? && @char && @char.map == $game_map
      $game_map.display_x = @char.real_x - Game_Player::SCREEN_CENTER_X
      $game_map.display_y = @char.real_y - Game_Player::SCREEN_CENTER_Y
    end

    def drop(d); @drop = [d["map_id"].to_i, d["x"].to_i, d["y"].to_i, d["dimension"] == true]; end

    # let go: visible and free again, where the server says
    def do_drop
      map_id, x, y, dimension = @drop
      @drop = nil
      @caught = false
      w = @watch
      @watch = nil
      $game_player.transparent = false
      if w
        $game_system.menu_disabled = w[:menu_disabled]
        FollowingPkmn.toggle_on(false) if w[:follower]
      end
      transfer(map_id, x, y)
      @dropped_to = [map_id, dimension]
    end

    def after_drop
      map_id, dimension = @dropped_to
      return unless $game_map&.map_id == map_id && free?
      @dropped_to = nil
      if dimension
        pbMessage(_INTL("{1} dropped you into another dimension...", name))
      else
        pbMessage(_INTL("{1} was caught! You're free!", name))
      end
    end
  end
end

#===============================================================================
# The battle: nothing hurts her, Blood Balls only (the first catch ends her)
#===============================================================================
class Battle::BloodCresseliaEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_cresselia"; end
  def weaknesses; []; end
  def wounds_text(boss); _INTL("{1} is untouchable! Only a Blood Ball can stop her!", boss.pbThis); end
  def elsewhere_text; ""; end
end

#===============================================================================
# While she's carrying you, you don't walk or talk to anything
#===============================================================================
module BloodCresseliaCarriedPlayer
  def update_command_new
    return if BloodCresselia.watching?
    super
  end

  def update_event_triggering
    if BloodCresselia.watching?
      $game_temp.interact_calling = false
      return
    end
    super
  end
end
Game_Player.prepend(BloodCresseliaCarriedPlayer)

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_cresselia_state") { |d| BloodCresselia.set_state(d) }
NetworkClient.on("blood_cresselia_cleared") { |_d| BloodCresselia.clear }
NetworkClient.on("blood_cresselia_ball") { |d| BloodCresselia.add_ball(d) }
NetworkClient.on("blood_cresselia_captured") { |d| BloodCresselia.captured(d) }
NetworkClient.on("blood_cresselia_drop") { |d| BloodCresselia.drop(d) }
NetworkClient.on("login_ok") { |_d| BloodCresselia.hello }

EventHandlers.add(:on_enter_map, :blood_cresselia, proc { |_old_map_id| BloodCresselia.entered_map })
EventHandlers.add(:on_frame_update, :blood_cresselia, proc { BloodCresselia.tick })
