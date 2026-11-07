#===============================================================================
# The Ghost Guy (server: handlers/ghost_trainer.js)
#
# A trainer (POKEMONTRAINER_305) who always walks around the world, through
# everything, the way the Scavenger Hunt's boss flies (002_ShadowLugia.rb):
# the server sends his walk over his current map (ghost_trainer_state) and
# every game plays it from the same clock. Every hour he may teleport to the
# other region: he stands still, the Teleport animation plays and he fades
# away (teleport_out), then fades in on a map in the other region (arrive).
#
# Walking into him (or him into you) starts a battle against a level 100 team
# of Ghost and Dark types picked each battle, with a glitch Pokémon as his
# ace. The server checks the battle and gives the prizes for a win (once an
# hour per player; until then he passes through you).
#===============================================================================
GHOST_TRAINER_TYPE       = :POKEMONTRAINER_305
GHOST_TRAINER_NAME       = "???"
GHOST_TRAINER_CHARSET    = "trainer_POKEMONTRAINER_305"
GHOST_TRAINER_MOVE_SPEED = 3        # 0.25 s a tile: must match MS_PER_TILE (250) on the server
GHOST_TRAINER_OPACITY    = 210      # a little see-through
GHOST_TRAINER_LEVEL      = 100
GHOST_TRAINER_TEAM_SIZE  = 5        # plus the ace
GHOST_TRAINER_ACES       = [:BURRIEDALIVE, :DARKMEW, :FOSSEL, :FOSSIL, :MISSIGNO, :GHOST, :GHOSTLY]
GHOST_TRAINER_TELEPORT_OUT_MS = 2500   # must match TELEPORT_OUT_MS on the server
GHOST_TRAINER_ARRIVE_MS       = 2000   # must match ARRIVE_MS on the server

module GhostTrainer
  # { map_id:, path:, ms_per_tile:, exit_dir:, teleport_out:, arrive:, started: }
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @quiet_until = 0          # System.uptime: he passes through until then
  @played_anim = nil        # the plan whose Teleport animation was played

  class << self
    attr_reader :state

    def active?; !@state.nil?; end

    def name
      tt = GameData::TrainerType.try_get(GHOST_TRAINER_TYPE)
      tt ? "#{tt.name} #{GHOST_TRAINER_NAME}" : GHOST_TRAINER_NAME
    end

    def set_state(d)
      return clear if !d["active"]
      @state = { map_id: d["map_id"].to_i, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 teleport_out: d["teleport_out"] == true, arrive: d["arrive"] == true,
                 started: System.uptime - (d["elapsed_ms"].to_i / 1000.0) }
      # a new walk: drawn afresh, unless he's still stepping across onto this map
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id] && !@state[:arrive]
    end

    def clear
      @state = nil
      destroy_sprite
    end

    def elapsed_ms
      ((System.uptime - @state[:started]) * 1000).to_i
    end

    def duration_ms
      s = @state
      ms = s[:exit_dir] > 0 ? s[:ms_per_tile] : 0
      s[:path].each_with_index do |(x, y, wait), i|
        ms += wait
        q = s[:path][i + 1]
        ms += ((q[0] - x).abs + (q[1] - y).abs) * s[:ms_per_tile] if q
      end
      ms
    end

    # where he is (as the Shadow Lugia's flight); ahead = a tile's time from now
    def position(ahead = false)
      s = @state
      ms = elapsed_ms
      ms += s[:ms_per_tile] if ahead
      ShadowLugia.position_at(s[:path], s[:ms_per_tile], ms, s[:exit_dir])
    end

    # how see-through he is now: fading out at the end of a teleport_out walk,
    # fading in at the start of an arrive one
    def opacity
      ms = elapsed_ms
      if @state[:teleport_out]
        gone_at = duration_ms - GHOST_TRAINER_TELEPORT_OUT_MS + 700
        return (GHOST_TRAINER_OPACITY * (1 - ((ms - gone_at) / 1000.0).clamp(0, 1))).round
      elsif @state[:arrive]
        return (GHOST_TRAINER_OPACITY * ((ms - 400) / 1000.0).clamp(0, 1)).round
      end
      GHOST_TRAINER_OPACITY
    end

    # the map animation called "Teleport" (16 in this game)
    def teleport_anim_id
      @teleport_anim_id ||= begin
        anims = load_data("Data/Animations.rxdata")
        anims.index { |a| a && a.name == "Teleport" } || 16
      rescue StandardError
        16
      end
    end

    # the Teleport animation, once, as he starts to vanish or appears
    def play_teleport_anim
      return if @played_anim.equal?(@state)
      ms = elapsed_ms
      at = if @state[:teleport_out]
             duration_ms - GHOST_TRAINER_TELEPORT_OUT_MS
           elsif @state[:arrive]
             0
           end
      return unless at && ms >= at && ms < at + 1500
      @played_anim = @state
      @char.animation_id = teleport_anim_id
    end

    #---------------------------------------------------------------------------
    # Him on the map
    #---------------------------------------------------------------------------
    def host_map
      id = @state[:map_id]
      return $game_map if $game_map&.map_id == id
      return $map_factory.getMapNoAdd(id) if $map_factory&.hasMap?(id)
      nil
    end

    def destroy_sprite
      @sprite&.dispose
      @sprite = nil
      @char = nil
    end

    def tick
      return destroy_sprite unless @state && $scene.is_a?(Scene_Map) && NetworkAuth.logged_in?
      map = host_map
      # still stepping across onto his new map: finish that step first
      if @char && @char.map != map && @char.moving? && !@sprite.disposed?
        @char.update
        @sprite.update
        return
      end
      return destroy_sprite unless map
      if !@char || @char.map != map || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        @char = GhostTrainerCharacter.new(map)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.fly_to(*position(true)) unless @char.moving?
      @char.opacity = opacity
      play_teleport_anim
      @char.update
      @sprite.update
      check_trigger
      follow_camera
    end

    #---------------------------------------------------------------------------
    # Watching him (admin "GhostWatch" chat command): the camera follows him
    # from map to map, the player is hidden and can't move; Back stops it and
    # puts the player back where they were
    #---------------------------------------------------------------------------
    def watching?; !@watch.nil?; end

    def toggle_watch
      watching? ? stop_watch : start_watch
    end

    def start_watch
      return if watching? || !@state || !$scene.is_a?(Scene_Map)
      follower = defined?(FollowingPkmn) && $PokemonGlobal.follower_toggled
      @watch = { map_id: $game_map.map_id, x: $game_player.x, y: $game_player.y,
                 dir: $game_player.direction, follower: follower,
                 menu_disabled: $game_system.menu_disabled }
      FollowingPkmn.toggle_off(false) if follower
      $game_player.transparent = true
      $game_system.menu_disabled = true
    end

    def stop_watch
      w = @watch or return
      @watch = nil
      $game_player.transparent = false
      $game_system.menu_disabled = w[:menu_disabled]
      transfer_player(w[:map_id], w[:x], w[:y], w[:dir])
      FollowingPkmn.toggle_on(false) if w[:follower]
    end

    def transfer_player(map_id, x, y, dir = 2)
      $game_temp.player_new_map_id    = map_id
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = dir
      $game_temp.player_transferring  = true
    end

    def watch_tick
      return unless watching?
      return stop_watch if !@state || Input.trigger?(Input::BACK)
      return if $game_temp.player_transferring || !$scene.is_a?(Scene_Map)
      # he's on another map (walked across, or teleported): go there too
      if $game_map.map_id != @state[:map_id] && !(@char && @char.moving? && @char.map == $game_map)
        transfer_player(@state[:map_id], *position[0, 2])
      end
    end

    def follow_camera
      return unless watching? && @char && @char.map == $game_map
      $game_map.display_x = @char.real_x - Game_Player::SCREEN_CENTER_X
      $game_map.display_y = @char.real_y - Game_Player::SCREEN_CENTER_Y
    end

    # standing on the same tile as him starts the battle (once per meeting)
    def check_trigger
      return if watching?
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y && @char.opacity >= GHOST_TRAINER_OPACITY / 2
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        start_battle if System.uptime >= @quiet_until
      end
    end

    #---------------------------------------------------------------------------
    # The battle
    #---------------------------------------------------------------------------
    # Ghost and Dark types that don't evolve further (no legendaries), with a
    # battle sprite
    def team_pool
      @team_pool ||= begin
        pool = []
        GameData::Species.each_species do |sp|
          next unless sp.types.include?(:GHOST) || sp.types.include?(:DARK)
          next if GHOST_TRAINER_ACES.include?(sp.species) || sp.species == :SHADOWLUGIA
          next if sp.has_flag?("Legendary") || sp.has_flag?("Mythical") || sp.has_flag?("UltraBeast")
          next unless sp.get_evolutions(true).empty?
          next unless pbResolveBitmap(sprintf("Graphics/Pokemon/%s", sp.species))
          pool << sp.species
        end
        pool
      end
    end

    def make_trainer
      trainer = NPCTrainer.new(GHOST_TRAINER_NAME, GHOST_TRAINER_TYPE)
      aces = GHOST_TRAINER_ACES.select { |s| GameData::Species.exists?(s) }
      team = team_pool.sample(GHOST_TRAINER_TEAM_SIZE)
      team << aces.sample unless aces.empty?
      trainer.party = team.map { |s| Pokemon.new(s, GHOST_TRAINER_LEVEL, trainer) }
      trainer.lose_text = "..."
      trainer
    end

    def start_battle
      unless $player.party.compact.any? { |p| p.hp > 0 && !p.egg? }
        pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
        return
      end
      result = nil
      cb = NetworkClient.on("ghost_trainer_engage") { |d| result = d }
      NetworkClient.send_msg({ action: "ghost_trainer_found", map_id: $game_map.map_id })
      300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
      NetworkClient.remove("ghost_trainer_engage", cb)
      unless result
        pbMessage(_INTL("Couldn't reach the server. Try again in a moment."))
        return
      end
      unless result["ok"]
        if (mins = result["wait_min"].to_i) > 0
          @quiet_until = System.uptime + mins * 60
          pbMessage(_INTL("{1} drifts right through you...\nCome back for a battle in {2} min.", name, mins))
        end
        return
      end
      return unless GameData::TrainerType.exists?(GHOST_TRAINER_TYPE)
      setBattleRule("single")
      outcome = TrainerBattle.start_core(make_trainer)
      claim_reward if outcome == Battle::Outcome::WIN
    end

    # the server puts the prizes in the prize queue: claim them right away
    # (with no answer they stay there, for the prize claim NPC)
    def claim_reward
      result = nil
      cb = NetworkClient.on("ghost_trainer_reward") { |d| result = d }
      NetworkClient.send_msg({ action: "ghost_trainer_won" })
      300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
      NetworkClient.remove("ghost_trainer_reward", cb)
      return unless result && result["ok"]
      @quiet_until = System.uptime + 60 * 60
      NetworkAuction.request_claim
      data = NetworkAuction.wait_claim(600)
      NetworkAuction._deliver_prizes(data["prizes"]) if data && data["success"]
    end
  end
end

#===============================================================================
# Him on the map: walks through everything (as the hunt's boss flies)
#===============================================================================
class GhostTrainerCharacter < ShadowLugiaCharacter
  def name; "Ghost Guy (airborne)"; end

  def initialize(map)
    super(map, :GHOSTGUY, GHOST_TRAINER_CHARSET)
    self.move_speed = GHOST_TRAINER_MOVE_SPEED
    @step_anime = false
    @opacity    = GHOST_TRAINER_OPACITY
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("ghost_trainer_state") { |d| GhostTrainer.set_state(d) }
NetworkClient.on("ghost_watch") { |_d| GhostTrainer.toggle_watch }

EventHandlers.add(:on_enter_map, :ghost_trainer, proc { |_old_map_id| GhostTrainer.destroy_sprite })

EventHandlers.add(:on_frame_update, :ghost_trainer, proc { GhostTrainer.watch_tick; GhostTrainer.tick })

# while watching him the player doesn't walk or talk to anything
module GhostTrainerWatchPlayer
  def update_command_new
    return if GhostTrainer.watching?
    super
  end

  def update_event_triggering
    if GhostTrainer.watching?
      $game_temp.interact_calling = false
      return
    end
    super
  end
end
Game_Player.prepend(GhostTrainerWatchPlayer)
