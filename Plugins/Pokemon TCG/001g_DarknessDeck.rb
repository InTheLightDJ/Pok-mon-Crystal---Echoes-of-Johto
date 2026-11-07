#==============================================================================
# Pokemon TCG - a premade Darkness deck for NPCs (not in the original; the
# user's card picks, 2026-11-06):  pbTCGDuel("Name", :SHADOW_DARKNESS_DECK)
# Tyranitar with Larvitar and Pupitar, Umbreon with Eevee, Mightyena with
# Poochyena, the Darkness Shadow Lugia, Sneasel, Absol and Sableye, Trainers
# the AI knows how to play, Darkness Energy and 2 Double Colorless Energy.
# Shining Tyranitar, Murkrow, Nuzleaf and Carvanha were left out: Shining
# Tyranitar and Carvanha need Fighting / Water Energy, Murkrow and Nuzleaf
# (needs Seedot) are weaker than the rest.
#==============================================================================
module TCG
  DECKS[:SHADOW_DARKNESS_DECK] = { :label => "ShadowDarknessDeck", :cards => {
    # Pokémon (22)
    :SHADOW_LUGIA_DARK => 2,
    :LARVITAR => 3, :PUPITAR => 2, :TYRANITAR => 2,
    :EEVEE_NEO => 2, :UMBREON => 2,
    :POOCHYENA => 2, :MIGHTYENA => 1,
    :SNEASEL => 3, :ABSOL => 2, :SABLEYE => 1,
    # Trainers (12)
    :BILL => 3, :PROFESSOR_OAK => 1, :POKEMON_BREEDER => 2, :PLUSPOWER => 2,
    :GUST_OF_WIND => 1, :SWITCH => 1, :SUPER_POTION => 1, :ENERGY_RETRIEVAL => 1,
    # Energy (26)
    :DARKNESS_ENERGY => 24, :DOUBLE_COLORLESS_ENERGY => 2
  } }
end
