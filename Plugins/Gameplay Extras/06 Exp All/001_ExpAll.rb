#===============================================================================
# Exp. All (Key Item): while EXPALL is in the Bag, every Pokémon in the party
# gets Exp. from battles (Data/Scripts/011_Battle/001_Battle/
# 003_Battle_ExpAndMoveLearning.rb: the ones that didn't fight get half, like
# the Gen 6 Exp. Share). Using it from the Bag swaps it with EXPALLOFF, which
# does nothing, and back ("Turn off" / "Turn on" come from 002_Item_Effects).
# Give it from an event: pbReceiveItem(:EXPALL)
#===============================================================================
ItemHandlers::UseFromBag.add(:EXPALL, proc { |item|
  $bag.replace_item(:EXPALL, :EXPALLOFF)
  pbMessage(_INTL("The Exp. All was turned off."))
  next 1
})

ItemHandlers::UseFromBag.add(:EXPALLOFF, proc { |item|
  $bag.replace_item(:EXPALLOFF, :EXPALL)
  pbMessage(_INTL("The Exp. All was turned on."))
  next 1
})
