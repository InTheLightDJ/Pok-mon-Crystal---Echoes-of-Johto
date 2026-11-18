#==============================================================================
# Shiny Spawns (server: handlers/shiny_spawns.js)
#
# The server rolls the shiny (1 in 50) when a World Boss, Mythical, roaming
# Gen 3 spawn or Mini-Boss spawns, and sends "shiny" with the spawn. This
# makes that Pokémon shiny in every player's game, instead of each game
# rolling its own normal shiny odds:
#   World Boss / Mini-Boss  the boss in the battle
#   Mythical                the wild Pokémon when you step on its tile
#   roaming spawn           its overworld event (and so the battle)
# Without "shiny" from the server (an older server) nothing changes.
#==============================================================================
module ShinySpawns
  @boss       = false   # current World Boss
  @mythical   = nil     # species id string of a shiny Mythical spawn
  @roam       = false   # current roaming spawn
  @boss_fight = false   # the boss battle starting now is a shiny one
  @wild_shiny = nil     # species to make shiny in the next wild battle

  class << self
    attr_accessor :boss, :mythical, :roam, :boss_fight, :wild_shiny
  end
end

NetworkClient.on('boss_spawn')     { |d| ShinySpawns.boss = d['shiny'] == true }
NetworkClient.on('boss_status')    { |d| ShinySpawns.boss = d['active'] == true && d['shiny'] == true }
NetworkClient.on('boss_cleared')   { |_d| ShinySpawns.boss = false }
NetworkClient.on('mythical_spawn') { |d| ShinySpawns.mythical = d['shiny'] == true ? d['species'].to_s : nil }
NetworkClient.on('roam_spawn')     { |d| ShinySpawns.roam = d['shiny'] == true }

#------------------------------------------------------------------------------
# World Boss and Mini-Boss: the boss Pokémon handed to the battle
#------------------------------------------------------------------------------
class << NetworkBoss
  alias shiny_spawns_start_boss_battle _start_boss_battle
  def _start_boss_battle(*args)
    ShinySpawns.boss_fight = ShinySpawns.boss
    shiny_spawns_start_boss_battle(*args)
  ensure
    ShinySpawns.boss_fight = false
  end
end

class << NetworkMiniBoss
  alias shiny_spawns_start_boss_battle _start_boss_battle
  def _start_boss_battle(b, *args)
    ShinySpawns.boss_fight = b.is_a?(Hash) && b[:shiny] == true
    shiny_spawns_start_boss_battle(b, *args)
  ensure
    ShinySpawns.boss_fight = false
  end
end

module ShinySpawnsBossBattle
  # (scene, player_party, boss_party, ...)
  def initialize(*args)
    Array(args[2]).each { |pkmn| pkmn.shiny = true if pkmn } if ShinySpawns.boss_fight
    super
  end
end
Battle::BossEncounter.prepend(ShinySpawnsBossBattle)
Battle::MiniBossEncounter.prepend(ShinySpawnsBossBattle)

#------------------------------------------------------------------------------
# Mythical: the wild battle started by stepping on its tile
#------------------------------------------------------------------------------
class << NetworkMythical
  alias shiny_spawns_trigger_encounter _trigger_encounter
  def _trigger_encounter(*args)
    species = @species.to_s
    ShinySpawns.wild_shiny = species.to_sym if ShinySpawns.mythical && ShinySpawns.mythical == species
    shiny_spawns_trigger_encounter(*args)
  ensure
    ShinySpawns.wild_shiny = nil
    ShinySpawns.mythical = nil
  end
end

EventHandlers.add(:on_wild_pokemon_created, :shiny_spawns_mythical,
  proc { |pkmn|
    next unless ShinySpawns.wild_shiny && pkmn.species == ShinySpawns.wild_shiny
    pkmn.shiny = true
  }
)

#------------------------------------------------------------------------------
# roaming spawn: its overworld event is placed with the Pokémon it battles
#------------------------------------------------------------------------------
module ShinySpawnsRoamEvent
  def spawnPokeEvent(x, y, pokemon)
    if ShinySpawns.roam && pokemon.is_a?(Pokemon) && NetworkRoamSpawn.active? &&
       !NetworkRoamSpawn.spawned? && pokemon.species == NetworkRoamSpawn.species_id
      pokemon.shiny = true
      ShinySpawns.roam = false
    end
    super
  end
end
Game_Map.prepend(ShinySpawnsRoamEvent)
