#==============================================================================
# Legendary Ride - Koraidon and Miraidon work as a Bicycle.
#
# In the party menu they get "Ride" (or "Get off" while riding) in the field
# move color, right after the field moves. Choosing it closes the menus like a
# field move does, then gets on / off the bike with the same rules as the
# Bicycle item (pbBikeCheck): not while surfing, not on must-walk tiles, only on
# maps where bikes are allowed, never off on always-bicycle maps.
#
#   RIDE_SPECIES  the Pokémon that can be ridden
#==============================================================================
module LegendaryRide
  RIDE_SPECIES = [:KORAIDON, :MIRAIDON]

  module_function

  def rider?(pkmn)
    pkmn && !pkmn.egg? && RIDE_SPECIES.any? { |s| pkmn.isSpecies?(s) }
  end

  # why the bike can't be used or put away here (nil if it can), the same
  # checks as pbBikeCheck but as text for the party screen
  def problem
    if $PokemonGlobal.surfing || $PokemonGlobal.diving ||
       (!$PokemonGlobal.bicycle &&
        ($game_player.pbTerrainTag.must_walk || $game_player.pbTerrainTag.must_walk_or_run))
      return _INTL("Can't ride here.")
    end
    return _INTL("You can't ride while someone is with you.") if !$game_player.can_ride_vehicle_with_follower?
    meta = $game_map.metadata
    if $PokemonGlobal.bicycle
      return _INTL("You can't get off here.") if meta&.always_bicycle
      return nil
    end
    return _INTL("Can't ride here.") if !meta || (!meta.can_bicycle && !meta.outdoor_map)
    nil
  end
end

# after the menus close (the pause menu calls pbUseHiddenMove with what the
# party screen returned)
HiddenMoveHandlers::UseMove.add(:LEGENDARY_RIDE, proc { |move, pkmn|
  if $PokemonGlobal.bicycle
    pbDismountBike
    pbMessage(_INTL("You got off {1}.", pkmn.name))
  else
    pbMessage(_INTL("You hopped on {1}!", pkmn.name))
    pbMountBike
  end
  next true
})

MenuHandlers.add(:party_menu, :legendary_ride, {
  "name"      => proc { [$PokemonGlobal.bicycle ? _INTL("Get off") : _INTL("Ride"), 1] },
  "order"     => 15,
  "condition" => proc { |screen, party, party_idx| next LegendaryRide.rider?(party[party_idx]) },
  "effect"    => proc { |screen, party, party_idx|
    msg = LegendaryRide.problem
    if msg
      screen.pbDisplay(msg)
      next
    end
    throw :legendary_ride, [party[party_idx], :LEGENDARY_RIDE]
  }
})

# lets the menu option above end the party screen the way a field move does
module LegendaryRidePartyScreen
  def pbPokemonScreen
    ride = catch(:legendary_ride) { return super }
    @scene.pbEndScene
    ride
  end
end
PokemonPartyScreen.prepend(LegendaryRidePartyScreen)
