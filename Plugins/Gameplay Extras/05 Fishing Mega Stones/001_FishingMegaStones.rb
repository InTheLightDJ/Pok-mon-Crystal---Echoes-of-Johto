#==============================================================================
# Lake of Rage Fishing Contest: treasures can be a Mega Stone
#
# A treasure on the hook (Data/Scripts/017_Minigames/LakeFishingMinigame.rb,
# LakeFishingMinigame._award_item) is swapped for a random Mega Stone:
#   COMMON_CHANCE of common treasures, RARE_CHANCE of rare ones (not skins)
# About 1 in 360 hooked bites on a normal day. The stone is delivered like
# the other catches (Auction House prize claim when the session ends; the
# server's handlers/lakefishing.js takes any item).
#==============================================================================
module FishingMegaStones
  COMMON_CHANCE = 0.02
  RARE_CHANCE   = 0.10

  module_function

  # every Mega Stone in the game (items with the MegaStone flag)
  def stones
    @stones ||= GameData::Item.keys.select { |k| GameData::Item.get(k).is_mega_stone? }
  end

  def roll(pick, rare)
    return pick if pick == :WARDROBE_SKIN || stones.empty?
    rand < (rare ? RARE_CHANCE : COMMON_CHANCE) ? stones.sample : pick
  end
end

module FishingMegaStonesAward
  def _award_item(pick, rare)
    stone = FishingMegaStones.roll(pick, rare)
    return super if stone == pick
    pbSEPlay("Mining reveal full") rescue nil
    super(stone, true)
  end
end
LakeFishingMinigame.singleton_class.prepend(FishingMegaStonesAward)
