#===============================================================================
# Booster Pack — gives random Triple Triad cards from the bag.
#
# BoosterPack.give(item, count, guaranteed_legendaries, shiny_odds)
#   item                  : item symbol (used for the opening message)
#   count                 : total number of cards to give
#   guaranteed_legendaries: how many are guaranteed legendary/mythical (placed last)
#   shiny_odds            : 1/N chance per card to be shiny
#
# Shiny constants:
#   SHINY_ODDS_NORMAL  1/2000  — used by regular BOOSTERPACK
#   SHINY_ODDS_LEGEND  1/1500  — used by LEGENDPACK
#===============================================================================
module BoosterPack
  SHINY_ODDS_NORMAL = 2000
  SHINY_ODDS_LEGEND = 1500

  def self.legendary_pool
    pool = []
    GameData::Species.each do |sp|
      next unless sp.form == 0
      next unless pbResolveBitmap(GameData::Species.icon_filename(sp.id, sp.form))
      pool << sp.id if sp.has_flag?("Legendary") || sp.has_flag?("Mythical")
    end
    pool
  end

  def self.regular_pool
    pool = []
    GameData::Species.each do |sp|
      next unless sp.form == 0
      next if sp.has_flag?("Legendary") || sp.has_flag?("Mythical")
      next unless pbResolveBitmap(GameData::Species.icon_filename(sp.id, sp.form))
      pool << sp.id
    end
    pool
  end

  def self.give(item, count = 3, guaranteed_legendaries = 0, shiny_odds = SHINY_ODDS_NORMAL)
    normal_count = [count - guaranteed_legendaries, 0].max
    reg_pool     = regular_pool
    leg_pool     = legendary_pool

    cards = []
    normal_count.times           { cards << reg_pool.sample if reg_pool.any? }
    guaranteed_legendaries.times do
      if leg_pool.any?
        cards << leg_pool.sample
      elsif reg_pool.any?
        cards << reg_pool.sample
      end
    end

    return if cards.empty?

    item_data = GameData::Item.get(item)
    pbMessage(_INTL("You opened the {1}!", item_data.name))

    cards.each do |species|
      sp_name = GameData::Species.get(species).name
      unless $PokemonGlobal.triads.can_add?(species)
        pbMessage(_INTL("You have no room for more cards."))
        next
      end
      $PokemonGlobal.triads.add(species)
      is_shiny = (rand(shiny_odds) == 0)
      if is_shiny && !$PokemonGlobal.triad_shiny_species.include?(species)
        $PokemonGlobal.triad_shiny_species << species
        pbMessage(_INTL("A shiny {1} card! ★", sp_name))
      else
        pbMessage(_INTL("You got a {1} card!", sp_name))
      end
    end
  end
end
