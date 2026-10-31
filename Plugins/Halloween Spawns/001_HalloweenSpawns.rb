#==============================================================================
# Halloween Spawns
#
# On October 31st (the player's clock), any wild encounter anywhere (the
# overworld Pokémon that wander the map and step-on battles alike) has a
# 1 in SPAWN_CHANCE chance to be a Halloween Pokémon instead: one of SPECIES,
# at the level the encounter rolled. Roaming Pokémon are never replaced.
#
# A Halloween Pokémon keeps a flag (Pokemon#halloween) for good, so it shows
# its costume sprite everywhere a Pokémon's picture is drawn (battle,
# summary, storage...):
#   Graphics/Pokemon/<SPECIES>_HALLOWEEN.png   front
#   Graphics/Pokemon/<SPECIES>b_HALLOWEEN.png  back
# (no shiny versions: a shiny Halloween Pokémon shows the costume too). A
# species without these files shows its normal sprite. The overworld
# sprite and party icon are the normal ones unless
#   Graphics/Characters/Followers/<SPECIES>_HALLOWEEN.png
#   Graphics/Pokemon/Icons/<SPECIES>_HALLOWEEN.png
# exist.
#==============================================================================
module HalloweenSpawns
  SPECIES      = [:ABRA, :ABSOL]
  SPAWN_CHANCE = 200       # 1 in this many encounters
  SUFFIX       = "_HALLOWEEN"

  @pending = nil           # species of the encounter just turned into a Halloween one

  class << self
    attr_accessor :pending
  end

  module_function

  def today?
    t = Time.now
    t.month == 10 && t.day == 31
  end

  # the costume graphic for pkmn under path ("b" = back), or nil
  def graphic(path, pkmn, back = "")
    return nil unless pkmn.respond_to?(:halloween) && pkmn.halloween && !pkmn.egg?
    pbResolveBitmap("#{path}#{GameData::Species.get(pkmn.species).species}#{back}#{SUFFIX}")
  end
end

class Pokemon
  attr_accessor :halloween   # true for a Halloween spawn (costume sprite)
end

# a wild encounter about to be made: sometimes a Halloween one
EventHandlers.add(:on_wild_species_chosen, :halloween_spawns,
  proc { |encounter|
    HalloweenSpawns.pending = nil   # a blocked encounter (Repel...) doesn't carry over
    next if !encounter || !HalloweenSpawns.today?
    next if $PokemonGlobal.roamEncounter   # a roaming Pokémon stays itself
    next if rand(HalloweenSpawns::SPAWN_CHANCE) != 0
    encounter[0] = HalloweenSpawns::SPECIES.sample
    HalloweenSpawns.pending = encounter[0]
  }
)

# the Pokémon made for it (overworld spawn or battle) gets the costume
EventHandlers.add(:on_wild_pokemon_created, :halloween_spawns,
  proc { |pkmn|
    next unless HalloweenSpawns.pending && pkmn.species == HalloweenSpawns.pending
    pkmn.halloween = true
    HalloweenSpawns.pending = nil
  }
)

module GameData
  class Species
    class << self
      alias halloween_sprite_bitmap_from_pokemon sprite_bitmap_from_pokemon
      def sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
        file = !species && HalloweenSpawns.graphic("Graphics/Pokemon/", pkmn, back ? "b" : "")
        return AnimatedBitmap.new(file) if file
        halloween_sprite_bitmap_from_pokemon(pkmn, back, species)
      end

      alias halloween_icon_filename_from_pokemon icon_filename_from_pokemon
      def icon_filename_from_pokemon(pkmn)
        HalloweenSpawns.graphic("Graphics/Pokemon/Icons/", pkmn) || halloween_icon_filename_from_pokemon(pkmn)
      end
    end
  end
end

# the overworld Pokémon: a Followers costume sprite if there is one
# (prepended, like Shiny Spawns' hook: an alias here would loop with it)
module HalloweenSpawnsOWEvent
  def spawnPokeEvent(x, y, pokemon)
    file = pokemon.is_a?(Pokemon) && HalloweenSpawns.graphic("Graphics/Characters/Followers/", pokemon)
    $halloween_ow_sprite = file || nil
    super
  ensure
    $halloween_ow_sprite = nil
  end
end
Game_Map.prepend(HalloweenSpawnsOWEvent)

alias halloween_ow_sprite_filename ow_sprite_filename
def ow_sprite_filename(*args)
  $halloween_ow_sprite ? $halloween_ow_sprite.dup : halloween_ow_sprite_filename(*args)
end
