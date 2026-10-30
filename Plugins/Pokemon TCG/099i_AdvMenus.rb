#==============================================================================
# Pokemon TCG - duel menu texts for the Gen 3 cards (061f_AdvEffects.rb).
#==============================================================================
module TCG
  PlayerController::REASON_TEXT.merge!(
    :neo_no_more_trainers => "You can't play more Trainer cards this turn (PokéGear)."
  )

  PlayerController::YES_NO_PROMPTS.merge!(
    :AdvHealingShower    => "Healing Shower: remove all damage counters from every Pokémon?",
    :AdvDiscardForStatus => "Discard a Grass Energy card for the extra effect?",
    :AdvDiscardDarknessForStatus => "Discard a Darkness Energy card for the extra effect?",
    :AdvSuperConnectivityMetal   => "Attach a Metal Energy card? (No: a Psychic Energy card)"
  )
end
