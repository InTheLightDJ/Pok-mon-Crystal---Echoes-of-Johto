#===============================================================================
# Water Reflections - the player, events and following Pokémon are reflected
# in Water (terrain tag 7), like they already were in Still Water (6) and
# Puddles (16). The reflection ripples unless the map has StillReflections.
#===============================================================================
GameData::TerrainTag.get(:Water).instance_variable_set(:@shows_reflections, true)
