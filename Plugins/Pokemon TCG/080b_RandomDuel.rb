#==============================================================================
# A random duelist: "Trainer" with the question-mark portrait, a random
# premade deck and, on a win, one random Colosseum / Evolution / Mystery pack.
#   Event Script: pbTCGRandomDuel
#==============================================================================
module TCG
  RANDOM_PACKS[:RANDOM_CLASSIC_BOOSTER] = [
    :COLOSSEUM_NEUTRAL, :COLOSSEUM_GRASS, :COLOSSEUM_FIRE, :COLOSSEUM_WATER,
    :COLOSSEUM_LIGHTNING, :COLOSSEUM_FIGHTING, :COLOSSEUM_TRAINER,
    :EVOLUTION_NEUTRAL, :EVOLUTION_GRASS, :EVOLUTION_NEUTRAL_FIRE_ENERGY,
    :EVOLUTION_WATER, :EVOLUTION_FIGHTING, :EVOLUTION_PSYCHIC, :EVOLUTION_TRAINER,
    :MYSTERY_NEUTRAL, :MYSTERY_GRASS_COLORLESS, :MYSTERY_WATER_COLORLESS,
    :MYSTERY_LIGHTNING_COLORLESS, :MYSTERY_FIGHTING_COLORLESS,
    :MYSTERY_TRAINER_COLORLESS
  ]

  # every full premade deck (not the unnamed ones or the 30-card starter extras)
  def self.random_duel_deck
    DECKS.keys.reject { |k| k.to_s.start_with?("UNNAMED") || k.to_s.end_with?("_EXTRA_DECK") }.sample
  end
end

def pbTCGRandomDuel(name = nil, **opts)
  pbTCGDuel(name || _INTL("Trainer"), TCG.random_duel_deck, reward: :RANDOM_CLASSIC_BOOSTER,
            portrait: "question", **opts)
end
