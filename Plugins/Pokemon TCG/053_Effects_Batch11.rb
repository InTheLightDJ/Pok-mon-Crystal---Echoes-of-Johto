#==============================================================================
# Pokemon TCG - effect functions, batch 11 + ProcessPlayedPokemonCard
# (home/duel.asm L1339: Pokemon Power triggers when a Pokemon is played).
#==============================================================================
module TCG
  class Duel
    # ProcessPlayedPokemonCard (overrides the stub from 031)
    def process_played_pokemon_card(idx, e)
      d = turn_duelist
      clear_changed_types_if_muk(d, idx)
      return if d.card(idx).attacks.empty?
      copy_attack_data_and_damage(idx, 0)
      update_arena_card_ids_and_clear_two_turn_duel_vars
      @atk.temp_turn_card_id = d.card_id(idx)
      @atk.temp[:power_slot] = e
      return unless @atk.pokemon_power?
      unless d.card_id(idx) == :MUK
        return if toxic_gas_active?   # CheckIsIncapableOfUsingPkmnPower(bench)
      end
      return unless has_effect_command?(EFFECT_PKMN_POWER_TRIGGER)
      @ui.message(_INTL("{1}'s Pokémon Power: {2}", d.card(idx).name, @atk.attack.name))
      try_execute_effect_command(EFFECT_PKMN_POWER_TRIGGER)
    end

    # PickRandomBasicCardFromDeck
    def pick_random_basic_card_from_deck(d = turn_duelist)
      d.deck_list.shuffle(random: TCG.rng).find { |i| d.card(i).basic? }
    end
  end

  # Professor Oak: discard hand (sorted by card ID), draw 7
  effect(:ProfessorOakEffect) do |du|
    d = du.turn_duelist
    d.hand.sort_by { |i| TCG.card_order_index(d.card_id(i)) || 0 }.each do |i|
      d.remove_card_from_hand(i)
      d.put_card_in_discard_pile(i)
    end
    du.display_draw_n_cards(d, 7, _INTL("Draw 7 cards."))
    7.times do
      i = d.draw_card_from_deck or break
      d.add_card_to_hand(i)
    end
    du.ui.refresh(du); false
  end

  effect(:EnergyConversion_AddToHandEffect) do |du|
    du.deal_recoil_damage_to_self(10)
    d = du.turn_duelist
    (du.temp(:list) || []).each { |i| d.move_discard_pile_card_to_hand(i); d.add_card_to_hand(i) }
    false
  end

  effect(:PokemonTrader_TradeCardsEffect) do |du|
    d = du.turn_duelist
    d.remove_card_from_hand(du.temp(:a0))
    d.return_card_to_deck(du.temp(:a0))
    d.search_card_in_deck_and_add_to_hand(du.temp(:a1))
    d.add_card_to_hand(du.temp(:a1))
    du.shuffle_cards_in_deck; false
  end

  # +20 for each Nidoking in the turn holder's play area
  effect(:BoyfriendsEffect) do |du|
    d = du.turn_duelist
    du.atk.damage += 20 * d.play_area.compact.count { |i| d.card_id(i) == :NIDOKING }; false
  end

  # Quickfreeze (power trigger on play): 50% paralysis, applied immediately
  effect(:Quickfreeze_Paralysis50PercentEffect) do |du|
    if du.toss_coin == HEADS
      du.queue_status(PSN_DBLPSN, PARALYZED)
      du.ui.event(:anim, :QUICKFREEZE)
      du.apply_status_condition_queue
    else
      du.set_was_unsuccessful
    end
    false
  end

  # Revive: place at half HP rounded up to 10
  effect(:Revive_PlaceInPlayAreaEffect) do |du|
    d = du.turn_duelist
    i = du.temp(:a0)
    d.move_discard_pile_card_to_hand(i)
    d.add_card_to_hand(i)
    e = du.put_basic_pokemon_in_play_area(i)
    hp = d.slot_hp[e] >> 1
    hp += 5 if hp.odd?
    d.slot_hp[e] = hp
    du.ui.message(_INTL("{1} was placed on the Bench.", d.card(i).name)) unless du.player_turn?
    false
  end

  effect(:FriendshipSong_AddToBench50PercentEffect) do |du|
    du.ui.message(_INTL("If Heads, put a Basic Pokémon from your Deck onto your Bench."))
    next false if du.toss_coin == TAILS
    d = du.turn_duelist
    i = du.pick_random_basic_card_from_deck
    if i
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      du.put_basic_pokemon_in_play_area(i)
      du.ui.message(_INTL("{1} came to the Bench.", d.card(i).name))
    else
      du.ui.message(_INTL("None came..."))
    end
    du.shuffle_cards_in_deck; false
  end

  effect(:EnergyTrans_CheckPlayArea) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next true if du.incapable_of_using_pkmn_power?(d, slot)
    grass = TYPE_NAMES["TYPE_ENERGY_GRASS"]
    (0...DECK_SIZE).any? { |i| (d.card_locations[i] & CARD_LOCATION_PLAY_AREA) != 0 && d.card(i).type == grass } ? false : true
  end

  effect(:SolarPower_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    next true if du.incapable_of_using_pkmn_power?(d, slot)
    d.status != 0 || du.non_turn_duelist.status != 0 ? false : _INTL("Not affected by Poison, Sleep, Paralysis or Confusion.")
  end

  # Cowardice: Tentacool's slot is discarded, only Tentacool returns to hand
  effect(:Cowardice_ReturnToHandEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    idx = d.play_area[e]
    d.move_play_area_card_to_discard_pile(e)
    d.swap_arena_with_bench_pokemon(du.atk.temp[:power_param]) if e == 0
    d.move_discard_pile_card_to_hand(idx)
    d.add_card_to_hand(idx)
    du.duelists.each(&:shift_pokemon_to_first_play_area_slots)
    du.ui.refresh(du); false
  end
end
