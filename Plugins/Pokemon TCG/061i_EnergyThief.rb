#==============================================================================
# Pokemon TCG - Energy Thief (Shadow Lugia, 001f_DarkShadowLugia.rb): once a
# turn, every Darkness Energy card on the opponent's Pokémon moves to the
# user's Pokémon (the player picks a Pokémon for each one; the AI puts them
# all on its Active Pokémon, 099j_EnergyThiefAI.rb).
# A card moving to the other side becomes a new card of the taker's deck
# (Duelist#take_card), so it is discarded to the taker's discard pile later.
# On the opponent's side it leaves the duel (CARD_LOCATION_TAKEN).
#==============================================================================
module TCG
  CARD_LOCATION_TAKEN = 0x80

  EFFECT_TABLE["EnergyThiefEffectCommands"] = [[EFFECT_INITIAL_EFFECT_1, :EnergyThief_CheckUse],
                                               [EFFECT_BEFORE_DAMAGE, :EnergyThief_TakeEffect]]

  class Duelist
    # card idx of duelist `from` becomes this duelist's, attached to slot e
    def take_card(from, idx, e)
      i = deck_size
      @deck_ids << from.card_id(idx)
      @holo << nil
      @card_locations << (CARD_LOCATION_PLAY_AREA | e)
      @deck_cards.insert(@not_in_deck, i)   # out of the deck: before the deck part
      @not_in_deck += 1
      from.card_locations[idx] = CARD_LOCATION_TAKEN
      i
    end
  end

  class Duel
    # the opponent's Darkness Energy cards in play
    def energy_thief_cards
      nd = non_turn_duelist
      dark = TYPE_NAMES["TYPE_ENERGY_DARKNESS"]
      (0...nd.deck_size).select { |i| (nd.card_locations[i] & CARD_LOCATION_PLAY_AREA) != 0 && nd.card(i).type == dark }
    end
  end

  effect(:EnergyThief_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    next true if du.incapable_of_using_pkmn_power?(d, slot)
    du.energy_thief_cards.empty? ? _INTL("The opponent has no Darkness Energy in play.") : false
  end

  effect(:EnergyThief_TakeEffect) do |du|
    d, nd = du.turn_duelist, du.non_turn_duelist
    d.slot_flags[du.temp(:a0)] |= USED_PKMN_POWER_THIS_TURN
    du.energy_thief_cards.each do |i|
      e = du.effect_choice(:play_area, :EnergyThiefTo, (0...d.num_in_play_area).to_a, false) || PLAY_AREA_ARENA
      d.take_card(nd, i, e)
      du.ui.message(_INTL("Took a Darkness Energy for {1}!", d.card(d.play_area[e]).name))
      du.ui.refresh(du)
    end
    false
  end
end
