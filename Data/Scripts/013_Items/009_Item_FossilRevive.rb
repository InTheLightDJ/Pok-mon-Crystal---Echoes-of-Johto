#==============================================================================
# Fossil Revival NPC helper
# Call pbFossilRevive from a Script event command in the reviver NPC's event.
#==============================================================================
FOSSIL_TABLE = {
  # Gen 1
  :HELIXFOSSIL => :OMANYTE,
  :DOMEFOSSIL  => :KABUTO,
  :OLDAMBER    => :AERODACTYL,
  # Gen 3
  :ROOTFOSSIL  => :LILEEP,
  :CLAWFOSSIL  => :ANORITH,
  # Gen 4
  :SKULLFOSSIL => :CRANIDOS,
  :ARMORFOSSIL => :SHIELDON,
  # Gen 5
  :COVERFOSSIL => :TIRTOUGA,
  :PLUMEFOSSIL => :ARCHEN,
  # Gen 6
  :JAWFOSSIL   => :TYRUNT,
  :SAILFOSSIL  => :AMAURA
  # Gen 8 Galar fossils (FOSSILIZEDBIRD/FISH/DRAKE/DINO) require two items
  # combined to make DRACOZOLT/ARCTOVISH/DRACOVISH/ARCTOZOLT — not supported here.
}.freeze

FOSSIL_REVIVE_LEVEL = 5

def pbFossilRevive
  available = FOSSIL_TABLE.keys.select { |id| $bag.has?(id) }
  if available.empty?
    pbMessage(_INTL("Sorry, you don't have any fossils I can revive."))
    return
  end
  choices = available.map { |id| GameData::Item.get(id).name }
  choices.push(_INTL("Never mind"))
  choice = pbMessage(_INTL("Which fossil shall I revive?"), choices, choices.length)
  return if choice == choices.length - 1
  item_id      = available[choice]
  species      = FOSSIL_TABLE[item_id]
  species_name = GameData::Species.get(species).name
  item_name    = GameData::Item.get(item_id).name
  $bag.remove(item_id)
  pbAddPokemon(species, FOSSIL_REVIVE_LEVEL)
  pbMessage(_INTL("Your {1} has been restored to a {2}!", item_name, species_name))
end
