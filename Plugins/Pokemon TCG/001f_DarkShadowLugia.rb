#==============================================================================
# Pokemon TCG - a second Shadow Lugia (not in the original): Darkness type,
# 100 HP, Pokémon Power Energy Thief and a 200-damage Shadow Storm for 4
# Darkness Energy (the user's, 2026-11-06), with its own art (the user's).
# Energy Thief's effect is in 061i_EnergyThief.rb.
# Like the other Shadow Lugia it's reserved (087b): only from the Card Slots'
# final spin, trades and events:  pbTCGGiveCard(:SHADOW_LUGIA_DARK)
#==============================================================================
module TCG
  CARDS[:SHADOW_LUGIA_DARK] = CARDS[:SHADOW_LUGIA].merge(
    :label => "ShadowLugiaDarkCard", :gfx => "shadow_lugia_dark", :type => "TYPE_PKMN_DARKNESS", :hp => 100,
    :weakness => ["FIGHTING"], :resistance => ["PSYCHIC"],
    :attacks => [
      { :cost => {}, :name => "Energy Thief",
        :desc => "Once during your turn (before your\nattack), you may move all <DARKNESS>\nEnergy cards attached to your\n" \
                 "opponent's Pokémon to your Pokémon\nin any way you like. This power\ncan't be used if Shadow Lugia is\n" \
                 "Asleep, Confused, or Paralyzed.",
        :damage => 0, :category => ["POKEMON_POWER"], :effect => "EnergyThiefEffectCommands",
        :flags1 => [], :flags2 => [], :flags3 => [], :param => 0, :anim => "ATK_ANIM_PKMN_POWER_1" },
      CARDS[:SHADOW_LUGIA][:attacks][0].merge(:cost => { "DARKNESS" => 4 }, :damage => 200, :anim => "ATK_ANIM_DARK_MIND")
    ])
  CARD_ORDER.insert(CARD_ORDER.index(:SHADOW_LUGIA) + 1, :SHADOW_LUGIA_DARK) unless CARD_ORDER.include?(:SHADOW_LUGIA_DARK)
end
