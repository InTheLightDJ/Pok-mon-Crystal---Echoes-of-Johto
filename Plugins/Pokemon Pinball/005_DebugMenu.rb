# Debug menu: start Pokémon Pinball (GBC) for testing
MenuHandlers.add(:debug_menu, :pinball_gbc, {
  "name"        => _INTL("Pokémon Pinball"),
  "parent"      => :main,
  "description" => _INTL("Play Pokémon Pinball (GBC). Left / Right arrows: flippers. Hold Back 2 s to quit."),
  "always_show" => true,
  "effect"      => proc { pbPokemonPinball }
})
