#===============================================================================
# NetworkRoamSpawn — client-side handler for the server's hourly roaming
# Gen 3 Pokémon event.
#
# Flow:
#   Server picks a Gen 3 Pokémon + route every hour and broadcasts roam_spawn.
#   Each time a normal overworld Pokémon spawns on the target map (after at least
#   MINIMUM_SPAWNS have appeared), there is a 1-in-SPAWN_ODDS chance a visible
#   network event is also spawned nearby via the Visible Overworld Encounters
#   plugin (spawnPokeEvent).
#   The server is notified (roam_found) immediately when the event appears.
#   Other players' spawns are cleared right away. The local event stays so this
#   player can still battle it.
#===============================================================================

module NetworkRoamSpawn
  MIN_LEVEL           = 25
  MAX_LEVEL           = 45
  CHAIN_RESET_SPECIES = :RATTATA
  SPAWN_ODDS          = 50   # 1-in-N overworld spawns triggers the network event
  MINIMUM_SPAWNS      = 3    # require this many normal overworld spawns first

  @active                 = false
  @species_id             = nil
  @map_id                 = nil
  @spawned_event_id       = nil
  @claimed_species        = nil   # saved species after notifying server; survives roam_cleared
  @spawns_seen            = 0     # normal overworld spawns counted since activation
  @battle_was_server_spawn = false

  class << self
    attr_reader :species_id, :map_id, :claimed_species

    def activate(species_id, map_id, species_name = nil, route_name = nil)
      deactivate
      @active      = true
      @species_id  = species_id.to_sym
      @map_id      = map_id.to_i
      @spawns_seen = 0
    end

    def deactivate
      _remove_spawned_event
      @active                  = false
      @species_id              = nil
      @map_id                  = nil
      @spawned_event_id        = nil
      @claimed_species         = nil
      @spawns_seen             = 0
      @battle_was_server_spawn = false
    end

    def active?;  @active; end
    def spawned?; !@spawned_event_id.nil?; end

    def increment_spawns
      @spawns_seen += 1
    end

    def spawn_count
      @spawns_seen
    end

    def set_spawned_event_id(id)
      @spawned_event_id = id
    end

    # Called immediately after spawnPokeEvent — notifies server and stops checks.
    def on_spawn_placed(species_id)
      @claimed_species = species_id
      @active          = false  # stop spawn checks; battle hook uses @claimed_species
      NetworkClient.send_msg({ action: 'roam_found', species_id: species_id.to_s })
    end

    # Called when server broadcasts roam_cleared.
    def on_roam_cleared
      if @claimed_species
        # We placed the event and already notified the server.
        # Don't remove our local event — let the player still battle it.
        @active      = false
        @species_id  = nil
        @map_id      = nil
        @spawns_seen = 0
        # Keep @spawned_event_id and @claimed_species until the battle
      else
        # Someone else found it — fully deactivate.
        deactivate
      end
    end

    # Called from on_calling_wild_battle when the player enters battle with our event.
    def on_battle_started
      @battle_was_server_spawn = true
      @spawned_event_id = nil
      @claimed_species  = nil
    end

    # Called from on_wild_battle_end after the chaining system has already updated
    # rescue_chain and catch_combo. Resets both to RATTATA so the server-spawn
    # species doesn't get treated as the active chain target.
    # outcome: Battle::Outcome integer (1=WIN, 2=LOSE, 3=FLEE, 4=CATCH, 5=DRAW)
    def on_battle_ended(outcome)
      return unless @battle_was_server_spawn
      @battle_was_server_spawn = false
      if defined?($game_temp) && $game_temp
        $game_temp.rescue_chain = [0, CHAIN_RESET_SPECIES]
        $game_temp.catch_combo  = [0, CHAIN_RESET_SPECIES]
      end
      return unless NetworkClient.connected?
      decision = case outcome
                 when 1 then 'won'
                 when 4 then 'caught'
                 else        'fled'
                 end
      NetworkClient.send_msg({ action: 'roam_result', decision: decision })
    end

    private

    def _remove_spawned_event
      return unless @spawned_event_id
      return unless $game_map
      $game_map.removeThisEventfromMap(@spawned_event_id) rescue nil
      @spawned_event_id = nil
    end
  end
end

#-------------------------------------------------------------------------------
# Server callbacks
#-------------------------------------------------------------------------------
NetworkClient.on('roam_spawn') do |data|
  NetworkRoamSpawn.activate(
    data['species_id'], data['map_id'], data['species_name'], data['route_name']
  )
end

NetworkClient.on('roam_cleared') do |_data|
  NetworkRoamSpawn.on_roam_cleared
end

#-------------------------------------------------------------------------------
# Overworld spawn hook — fires each time a normal overworld Pokémon appears.
# After MINIMUM_SPAWNS have been seen, 1-in-SPAWN_ODDS chance to also place the
# network event. Server is notified the moment it appears on the map.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_wild_pokemon_created_for_spawning, :network_roam_spawn_check,
  proc { |_pokemon|
    next unless NetworkRoamSpawn.active?
    next unless NetworkClient.connected?
    next unless $game_map&.map_id == NetworkRoamSpawn.map_id
    next if NetworkRoamSpawn.spawned?
    next unless $scene.is_a?(Scene_Map)

    NetworkRoamSpawn.increment_spawns
    next if NetworkRoamSpawn.spawn_count < NetworkRoamSpawn::MINIMUM_SPAWNS
    next unless rand(NetworkRoamSpawn::SPAWN_ODDS) == 0

    level   = NetworkRoamSpawn::MIN_LEVEL + rand(NetworkRoamSpawn::MAX_LEVEL - NetworkRoamSpawn::MIN_LEVEL + 1)
    pokemon = pbGenerateWildPokemon(NetworkRoamSpawn.species_id, level)
    next unless pokemon

    px, py    = $game_player.x, $game_player.y
    spawn_pos = nil
    (-4..4).to_a.product((-4..4).to_a).shuffle.each do |dx, dy|
      next if dx == 0 && dy == 0
      nx, ny = px + dx, py + dy
      if (pbTileIsPossible(nx, ny) rescue false)
        spawn_pos = [nx, ny]
        break
      end
    end
    next unless spawn_pos

    # encounter_type is already set by the normal spawn that triggered this hook,
    # but we set it explicitly here as a safeguard for pbCheckBattleAllowed.
    $game_temp.encounter_type = :Land
    $game_map.spawnPokeEvent(spawn_pos[0], spawn_pos[1], pokemon)
    NetworkRoamSpawn.set_spawned_event_id($game_map.events.keys.max)
    NetworkRoamSpawn.on_spawn_placed(NetworkRoamSpawn.species_id)
  }
)

#-------------------------------------------------------------------------------
# Battle hook — fires when the player enters battle with our overworld event.
# Server was already notified at spawn time; this sets the chain-reset flag.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_calling_wild_battle, :network_roam_found,
  proc { |pkmn, handled|
    next unless NetworkRoamSpawn.spawned?
    next unless $PokemonGlobal.battlingSpawnedPokemon
    species = pkmn.is_a?(Pokemon) ? pkmn.species : pkmn
    next unless species == NetworkRoamSpawn.claimed_species
    NetworkRoamSpawn.on_battle_started
  }
)

#-------------------------------------------------------------------------------
# Post-battle hook — fires after on_wild_battle_end in 002_Chaining has already
# updated rescue_chain / catch_combo. Overrides both to RATTATA so the server-
# spawn species doesn't become the active chain target.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_wild_battle_end, :network_roam_chain_reset,
  proc { |_species, _level, outcome|
    NetworkRoamSpawn.on_battle_ended(outcome)
  }
)
