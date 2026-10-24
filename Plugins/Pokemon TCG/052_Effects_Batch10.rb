#==============================================================================
# Pokemon TCG - effect functions, batch 10 (effect_functions.asm).
# Power checks (Heal, Step In, Cowardice, Strange Behavior), Shift color,
# Solar Power, selections (Flames of Rage, Potion, Scoop Up, Whirlpool, Dark
# Mind, Spark, Recycle, Terror Strike) and trainer apply steps (Bill,
# Maintenance, Item Finder, Energy Retrieval, Poke Ball, Pokedex, Flute).
#==============================================================================
module TCG
  class Duel
    def power_slot; @atk.temp[:power_slot] || PLAY_AREA_ARENA; end

    # opponent bench selection that is skipped (a0 = nil) when there's no bench
    def select_opponent_bench_or_none(purpose, prompt)
      return nil if non_turn_duelist.num_in_play_area < 2
      select_opponent_bench_slot(purpose, prompt)
    end
  end

  #----------------------------------------------------------------------------
  # Pokemon Power checks / effects
  #----------------------------------------------------------------------------
  effect(:Heal_OncePerTurnCheck) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    next _INTL("There are no Pokémon with damage counters.") unless du.play_area_has_any_damage?
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end

  effect(:StepIn_BenchCheck) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    next _INTL("Can only be used on the Bench.") if slot == 0
    next _INTL("Only once per turn.") if (du.turn_duelist.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    du.incapable_of_using_pkmn_power?(du.turn_duelist, slot) ? true : false
  end

  effect(:Cowardice_CheckUseAndBench) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next true if du.incapable_of_using_pkmn_power?(d, slot)
    next _INTL(NO_BENCH_TEXT) if d.num_in_play_area < 2
    (d.slot_flags[slot] & CAN_EVOLVE_THIS_TURN) == 0 ? _INTL("Cannot be used in the turn in which it was played.") : false
  end

  effect(:StrangeBehavior_CheckDamage) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    next _INTL("There are no Pokémon with damage counters.") unless du.play_area_has_any_damage?
    next _INTL("Cannot use because it will be Knocked Out.") if du.turn_duelist.slot_hp[slot] < 20
    du.incapable_of_using_pkmn_power?(du.turn_duelist, slot) ? true : false
  end

  effect(:Shift_ChangeColorEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    d.slot_flags[e] |= USED_PKMN_POWER_THIS_TURN
    color = du.atk.temp[:power_param]
    d.slot_changed_type[e] = color | HAS_CHANGED_COLOR
    du.ui.message(_INTL("Changed the color of {1} to {2}.", d.card(d.play_area[e]).name, COLOR_NAMES.key(color).to_s.capitalize))
    false
  end

  effect(:SolarPower_RemoveStatusEffect) do |du|
    du.ui.event(:anim, :ATK_ANIM_HEAL_BOTH_SIDES)
    du.turn_duelist.slot_flags[du.temp(:a0)] |= USED_PKMN_POWER_THIS_TURN
    du.turn_duelist.status = NO_STATUS
    du.non_turn_duelist.status = NO_STATUS
    du.ui.refresh(du); false
  end

  effect(:VenusaurMegaDrainEffect) { |du| du.heal_half_dealt_damage; false }

  effect(:Conversion1_ChangeWeaknessEffect) do |du|
    next false if du.handle_no_damage_or_effect
    nd = du.non_turn_duelist
    wr = COLOR_TO_WR[du.temp(:a0)]
    nd.changed_weakness = wr
    nd.last_turn_change_weak = wr
    du.ui.message(_INTL("Changed the Weakness of {1} to {2}.", nd.card(nd.arena).name, COLOR_NAMES.key(du.temp(:a0)).to_s.capitalize))
    du.apply_substatus2_to_defending_card(SUBSTATUS2_CONVERSION2); false
  end

  # Stone Barrage: flip until tails, 10 per heads
  effect(:StoneBarrage_MultiplierEffect) do |du|
    du.ui.message(_INTL("Flip until Tails appears. 10 damage for each Heads."))
    heads = 0
    heads += 1 while du.toss_coin == HEADS
    du.atk.damage = 10 * heads; false
  end

  #----------------------------------------------------------------------------
  # selections
  #----------------------------------------------------------------------------
  effect(:FlamesOfRage_PlayerSelectEffect) do |du|
    du.ui.message(_INTL("Choose and discard 2 Fire Energy cards.")) if du.player_turn?
    list = du.list_of_fire_energy_attached_to_arena
    picked = []
    2.times do
      sel = du.effect_choice(:card, :FlamesOfRage, list, true)
      break if sel.nil?
      picked << sel
      list.delete(sel)
    end
    next true if picked.size < 2
    du.set_temp(:list, picked); false
  end

  effect(:Potion_PlayerSelection) do |du|
    d = du.turn_duelist
    slots = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
    e = du.effect_choice(:play_area, :Potion, slots, true)
    next true if e.nil?
    du.set_temp(:a0, e)
    du.set_temp(:a1, [du.card_damage_and_max_hp(d, e)[0], 20].min); false
  end

  effect(:ScoopUp_PlayerSelection) do |du|
    du.ui.message(_INTL("Choose a Pokémon to Scoop Up.")) if du.player_turn?
    d = du.turn_duelist
    e = du.effect_choice(:play_area, :ScoopUp, (0...d.num_in_play_area).to_a, true)
    next true if e.nil?
    du.set_temp(:a0, e)
    du.set_temp(:a1, du.select_play_area_slot(:ScoopUpReplace, true,
      _INTL("Select a Pokémon to place in the Active spot."))) if e == 0
    false
  end

  effect(:Whirlpool_PlayerSelectEffect) do |du|
    list = du.as_non_turn { du.turn_duelist.energy_cards_in_slot(PLAY_AREA_ARENA) }
    if list.empty?
      du.set_temp(:a0, nil)
    else
      du.ui.message(_INTL("Choose the Energy card attached to the opponent's Active Pokémon to discard.")) if du.player_turn?
      du.set_temp(:a0, du.effect_choice(:card, :Whirlpool, list, false) || list.first)
    end
    false
  end

  effects(:GengarDarkMind_PlayerSelectEffect, :HypnoDarkMind_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_opponent_bench_or_none(:DarkMind, _INTL("Choose a Pokémon on the Bench to give damage to."))); false
  end
  effect(:Spark_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_opponent_bench_or_none(:Spark, _INTL("Choose a Pokémon on the Bench to give damage to."))); false
  end

  effect(:TerrorStrike_50PercentSelectSwitchPokemon) do |du|
    du.set_temp(:a0, 0)
    next false if du.non_turn_duelist.num_in_play_area < 2
    du.ui.message(_INTL("If Heads, change the opponent's Active Pokémon."))
    r = du.toss_coin
    du.set_temp(:a0, r)
    du.set_temp(:a1, du.duelist_select_forced_switch) if r == HEADS
    false
  end

  effect(:Recycle_PlayerSelection) do |du|
    du.ui.message(_INTL("Trainer card success check! If Heads, the card is effective."))
    if du.toss_coin == HEADS
      list = du.turn_duelist.discard_pile.reverse
      du.set_temp(:list, [du.effect_choice(:card, :Recycle, list, false) || list.first])
    else
      du.set_temp(:list, [nil])
    end
    false
  end

  #----------------------------------------------------------------------------
  # trainer apply steps
  #----------------------------------------------------------------------------
  effect(:BillEffect) do |du|
    d = du.turn_duelist
    du.display_draw_n_cards(d, 2, _INTL("Draw 2 cards."))
    2.times do
      i = d.draw_card_from_deck or break
      d.add_card_to_hand(i)
      du.ui.event(:draw, d.name, i)
    end
    false
  end

  effect(:Maintenance_ReturnToDeckAndDrawEffect) do |du|
    d = du.turn_duelist
    du.temp(:list).first(2).each { |i| d.remove_card_from_hand(i); d.return_card_to_deck(i) }
    du.shuffle_cards_in_deck
    du.display_draw_n_cards(d, 1)
    i = d.draw_card_from_deck
    if i
      d.add_card_to_hand(i)
      du.ui.event(:draw, d.name, i)
    end
    false
  end

  effect(:ItemFinder_DiscardAddToHandEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list)
    l[0, 2].each { |i| d.remove_card_from_hand(i); d.put_card_in_discard_pile(i) }
    d.move_discard_pile_card_to_hand(l[2])
    d.add_card_to_hand(l[2])
    du.ui.message(_INTL("{1} was placed in the hand.", d.card(l[2]).name)) unless du.player_turn?
    false
  end

  effect(:EnergyRetrieval_DiscardAndAddToHandEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list)
    d.remove_card_from_hand(l[0])
    d.put_card_in_discard_pile(l[0])
    l[1..].compact.each { |i| d.move_discard_pile_card_to_hand(i); d.add_card_to_hand(i) }
    false
  end

  effect(:PokeBall_AddToHandEffect) do |du|
    l = du.temp(:list) || []
    next false if l[0] == TAILS
    d = du.turn_duelist
    if (i = l[1])
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      du.ui.message(_INTL("{1} was placed in the hand.", d.card(i).name)) unless du.player_turn?
    end
    du.shuffle_cards_in_deck; false
  end

  # Pokedex: temp :list = chosen order, top first
  effect(:Pokedex_OrderDeckCardsEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list).compact
    l.each { |i| d.search_card_in_deck_and_add_to_hand(i) }
    l.reverse_each { |i| d.return_card_to_deck(i) }
    false
  end

  effect(:PokemonFlute_PlaceInPlayAreaText) do |du|
    i = du.temp(:a0)
    du.as_non_turn do
      d = du.turn_duelist
      d.move_discard_pile_card_to_hand(i)
      d.add_card_to_hand(i)
      du.put_basic_pokemon_in_play_area(i)
    end
    du.ui.message(_INTL("{1} was chosen.", du.non_turn_duelist.card(i).name)) unless du.player_turn?
    false
  end
end
