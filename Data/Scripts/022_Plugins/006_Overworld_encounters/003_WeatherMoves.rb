#===============================================================================
# Overworld Weather Moves
# Registers weather moves as usable from the Pokémon party menu on the map,
# changing the overworld weather. Works like HM field moves (no badge required).
#===============================================================================

OVERWORLD_WEATHER_MOVE_MAP = {
  :THUNDER    => { weather: :Storm,    max: 9, msg: "Lightning split the sky!\nA raging storm rolled in!" },
  :BLIZZARD   => { weather: :Blizzard, max: 6, msg: "An icy blizzard swept through the area!" },
  :POWDERSNOW => { weather: :Snow,     max: 4, msg: "Light snowflakes began to drift down..." },
  :HAZE       => { weather: :Rain,     max: 4, msg: "A fine mist settled over the area..." },
  :RAINDANCE  => { weather: :HeavyRain,max: 9, msg: "Dark clouds gathered and heavy rain began to fall!" },
  :SUNNYDAY   => { weather: :Sun,      max: 9, msg: "The sunlight turned harsh and intense!" },
  :SANDSTORM  => { weather: :Sandstorm,max: 9, msg: "A harsh sandstorm blew up from nowhere!" },
  # Fog: add a move here when you have one:
  # :YOURMOVE => { weather: :Fog, max: 6, msg: "A thick fog rolled in..." },
}

OVERWORLD_WEATHER_MOVE_MAP.each do |move_id, data|
  HiddenMoveHandlers::CanUseMove.add(move_id, proc { |move, pkmn, showmsg|
    next true
  })

  HiddenMoveHandlers::UseMove.add(move_id, proc { |move, pokemon|
    pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
    pbMessage(_INTL(data[:msg]))
    $game_screen.weather(data[:weather], data[:max], 40) if $game_screen
    next true
  })
end
