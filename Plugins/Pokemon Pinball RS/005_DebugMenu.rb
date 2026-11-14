# Debug menu: start Pokémon Pinball: Ruby & Sapphire (GBA) for testing
MenuHandlers.add(:debug_menu, :pinball_rs, {
  "name"        => _INTL("Pokémon Pinball R&S"),
  "parent"      => :main,
  "description" => _INTL("Play Pokémon Pinball: Ruby & Sapphire. Left / Right arrows: flippers. Hold Back 2 s to quit."),
  "always_show" => true,
  "effect"      => proc { pbPokemonPinballRS }
})
