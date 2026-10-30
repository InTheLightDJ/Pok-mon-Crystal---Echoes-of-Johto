#==============================================================================
# Pokemon TCG - basic Darkness and Metal Energy (not in the original game).
# Colors DARKNESS / METAL in 010_Constants.rb; their symbols and icons are
# the tiles added below the original ones in UI/symbols.png and
# UI/cgb_symbols.png. Neo packs give them (086b-086d); the original game's
# packs keep its 6 Energy types.
#==============================================================================
module TCG
  CARDS[:DARKNESS_ENERGY] = {:label => "DarknessEnergyCard", :type => "TYPE_ENERGY_DARKNESS", :gfx => "darknessenergy", :name => "Darkness Energy", :rarity => "CIRCLE", :sets => ["ENERGY"], :effect => "DarknessEnergyEffectCommands", :desc => "Provides 1 <DARKNESS> Energy."}
  CARDS[:METAL_ENERGY] = {:label => "MetalEnergyCard", :type => "TYPE_ENERGY_METAL", :gfx => "metalenergy", :name => "Metal Energy", :rarity => "CIRCLE", :sets => ["ENERGY"], :effect => "MetalEnergyEffectCommands", :desc => "Provides 1 <METAL> Energy."}
  CARD_ORDER.insert(CARD_ORDER.index(:DOUBLE_COLORLESS_ENERGY), :DARKNESS_ENERGY, :METAL_ENERGY) unless CARD_ORDER.include?(:DARKNESS_ENERGY)
end
