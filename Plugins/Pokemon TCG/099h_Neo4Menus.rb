#==============================================================================
# Pokemon TCG - duel menu texts for the fourth batch of custom cards
# (061e_NeoEffects4.rb).
#==============================================================================
module TCG
  PlayerController::REASON_TEXT.merge!(
    :neo_elm => "You can't play more Trainer cards this turn (Professor Elm)."
  )

  PlayerController::YES_NO_PROMPTS.merge!(
    :NeoSweetKiss        => "Sweet Kiss: do you draw a card?",
    :NeoEvilDeedsDraw    => "Team Rocket's Evil Deeds: draw 2 cards?",
    :NeoEvolutionSong    => "Evolve 1 of your Pokémon from your deck?",
    :NeoEvolutionSongOpp => "Evolution Song: evolve 1 of your Pokémon from your deck?"
  )
end
