module BugContestQuest
  ALL_BUGS = [
    :CATERPIE, :METAPOD, :BUTTERFREE,
    :WEEDLE, :KAKUNA, :BEEDRILL,
    :PARAS, :PARASECT,
    :VENONAT, :VENOMOTH,
    :SCYTHER, :SCIZOR, :PINSIR,
    :LEDYBA, :LEDIAN,
    :SPINARAK, :ARIADOS,
    :YANMA, :PINECO, :FORRETRESS,
    :SHUCKLE, :HERACROSS, :SNEASEL, :TANGELA
  ]

 def self.remaining_species
  val = $game_variables[38]
  if !val.is_a?(Array)
    val = ALL_BUGS.clone
    $game_variables[38] = val
  end
  return val
end

  def self.give_species(species)
    return unless remaining_species.include?(species)
    $game_variables[38].delete(species)
  end

  def self.completed?
    remaining_species.empty?
  end

  def self.reset
    $game_variables[38] = ALL_BUGS.clone
  end
end

def pbBugQuestNPCInteraction
  last = pbBugContestState.lastPokemon
  if !last
    pbMessage("You haven't caught any Pokémon in the contest yet!")
    return
  end

  if !BugContestQuest.remaining_species.include?(last.species)
    pbMessage("That Pokémon isn't one I'm looking for right now.")
    return
  end

  BugContestQuest.give_species(last.species)
  pbMessage("Thank you for the #{last.speciesName}!")

  if BugContestQuest.completed?
    pbMessage("You've shown me every Bug-type from Kanto and Johto!")
    if $game_switches[74] == false
      $game_switches[74] = true
    else
      items_to_get = [:MASTERBALL, :ABILITYPATCH, :EXPSHARE, :HELIXFOSSIL, :DOMEFOSSIL,
                :OLDAMBER, :ROOTFOSSIL, :CLAWFOSSIL, :ARMORFOSSIL, :SKULLFOSSIL]
      item = items_to_get.sample
      $bag.add(item, 1)
      pbMEPlay("Item get")
      pbMessage(_INTL("You received {1}!", GameData::Item.get(item).name))
 
      # Award a ribbon to the first Pokémon in the player's party
      first_pkmn = $player.party[0]
      if first_pkmn && !first_pkmn.shadowPokemon?
        ribbon_id = :BUGCOLLECTION   # Replace this with your desired ribbon symbol ID
        if !first_pkmn.hasRibbon?(ribbon_id)
          first_pkmn.giveRibbon(ribbon_id)
          pbMessage(_INTL("{1} was awarded the {2} Ribbon!", first_pkmn.name, GameData::Ribbon.get(ribbon_id).name))
        end
      end
    end
  else
    pbMessage("Still more Bug-types out there. Keep looking!")
  end
end

class Window_MissingBugSpecies < Window_DrawableCommand
  def initialize(species_list, x, y, width, height)
    @commands = species_list
    super(x, y, width, height)
    self.windowskin = nil
    self.baseColor   = Color.new(88, 88, 80)
    self.shadowColor = Color.new(168, 184, 184)
    self.windowskin  = nil
  end

 def drawItem(index, _count, rect)
    species_id = @commands[index]
    species_name = GameData::Species.get(species_id).name
    textpos = [
      [species_name, rect.x + 4, rect.y, false, self.baseColor, self.shadowColor]
    ]
    pbDrawTextPositions(self.contents, textpos)
  end

  def itemCount
    return @commands.length
  end

  def itemRect(index)
    rect = Rect.new(0, 0, self.width - 32, 32)
    rect.y = index * 32
    return rect
  end
end

def pbShowRemainingBugQuestSpeciesList
  missing = BugContestQuest.remaining_species
  if missing.empty?
    pbMessage(_INTL("You've already shown me every Bug-type from Kanto and Johto!"))
    return
  end

  species_names = missing.map { |sym| GameData::Species.get(sym).name }
  commands = species_names.sort
  commands << _INTL("Close")

  pbMessage(_INTL("\\ts[]Missing Bug-type Pokémon:\n"), commands, commands.length - 1)
end



#===============================================================================
# Bug Contest Storage
#===============================================================================
# This module handles the storage and retrieval of the last caught Pokémon in the Bug Contest.
# It allows the player to store the last caught Pokémon and retrieve it later.
# The stored Pokémon can be reclaimed or replaced, and the storage state is tracked with a switch.

module BugContestStorage
  def self.store_last_pokemon
    return false if !$PokemonGlobal.bugContestState&.lastPokemon
    return false if $game_switches[44]  # Already stored

    # Store the Pokémon
    $PokemonGlobal.instance_variable_set(:@bugContestStored, $PokemonGlobal.bugContestState.lastPokemon)
    pkmn = $PokemonGlobal.bugContestState.lastPokemon
    $PokemonGlobal.bugContestState.lastPokemon = nil
    $game_switches[44] = true

    # Store the name/species to a visible variable
    $game_variables[45] = "#{pkmn.name} Lv.#{pkmn.level}"

    return true
  end

  def self.reclaim_last_pokemon(overwrite = true)
    stored = $PokemonGlobal.instance_variable_get(:@bugContestStored)
    return false if stored.nil?

    if overwrite || !$PokemonGlobal.bugContestState.lastPokemon
      $PokemonGlobal.bugContestState.lastPokemon = stored
      $PokemonGlobal.instance_variable_set(:@bugContestStored, nil)
      $game_switches[44] = false
      return true
    end
    return false
  end

  def self.has_stored?
    return !$PokemonGlobal.instance_variable_get(:@bugContestStored).nil?
  end
end
