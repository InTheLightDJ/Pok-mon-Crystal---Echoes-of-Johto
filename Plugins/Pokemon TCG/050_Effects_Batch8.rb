#==============================================================================
# Pokemon TCG - effect functions, batch 8 (effect_functions.asm).
# Forced switch (defending duelist chooses), Selfdestruct, Super Fang, Fetch,
# PlusPower, Super Potion heal, Doll/Fossil Discard power, once-per-turn
# power checks, Conversion 1/2, Dive Bomb, more multipliers and selections.
#==============================================================================
module TCG
  class Duel
    # DuelistSelectForcedSwitch: the NON-turn duelist picks its new active
    def duelist_select_forced_switch
      nd = non_turn_duelist
      slots = (1...nd.num_in_play_area).to_a
      sel = @controllers[1 - @turn].effect_choice(self, :play_area, :ForcedSwitch, slots, false)
      slots.include?(sel) ? sel : slots.first
    end

    # whirlwind-style: nil (no bench) or the slot chosen by the defender
    def select_forced_switch_or_none
      non_turn_duelist.num_in_play_area < 2 ? nil : duelist_select_forced_switch
    end

    # Shift / Peek style: power slot -> temp a0, once per turn
    def once_per_turn_power_check
      slot = @atk.temp[:power_slot] || PLAY_AREA_ARENA
      set_temp(:a0, slot)
      d = turn_duelist
      return _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
      incapable_of_using_pkmn_power?(d, slot) ? true : false
    end
  end

  effects(:ButterfreeWhirlwind_CheckBench, :PidgeottoWhirlwind_SelectEffect,
          :PidgeyWhirlwind_SelectEffect, :Ram_SelectSwitchEffect) do |du|
    du.set_temp(:a0, du.select_forced_switch_or_none); false
  end

  { :WeezingSelfdestructEffect => [60, 10], :GolemSelfdestructEffect => [100, 20] }.each do |name, (self_dmg, bench)|
    effect(name) do |du|
      du.deal_recoil_damage_to_self(self_dmg)
      du.atk.is_damage_to_self = true
      du.deal_damage_to_all_benched_pokemon(bench)
      du.as_non_turn do
        du.atk.is_damage_to_self = false
        du.deal_damage_to_all_benched_pokemon(bench)
      end
      false
    end
  end

  # Super Fang: half the defender's remaining HP, rounded up to a multiple of 10
  effect(:SuperFang_HalfHPEffect) do |du|
    hp = du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] >> 1
    hp += 5 if hp.odd?
    du.set_definite_damage(hp); false
  end

  effects(:DragonairSlam_MultiplierEffect, :DragoniteLv41Slam_MultiplierEffect, :Bonemerang_MultiplierEffect) do |du|
    du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 30))
    du.set_definite_damage(30 * du.toss_coins(2)); false
  end

  effect(:MoltresLv35DiveBomb_Success50PercentEffect) do |du|
    du.ui.message(_INTL("Success check! If Heads, the attack is successful."))
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_DIVE_BOMB
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end

  effect(:MewtwoEnergyAbsorption_AddToHandEffect) do |du|
    d = du.turn_duelist
    (du.temp(:list) || []).each do |i|
      d.move_discard_pile_card_to_hand(i)
      d.card_locations[i] = CARD_LOCATION_ARENA
    end
    false
  end

  effect(:FetchEffect) do |du|
    d = du.turn_duelist
    du.display_draw_n_cards(d, 1, _INTL("Draw 1 card from the Deck."))
    i = d.draw_card_from_deck
    if i
      d.add_card_to_hand(i)
      du.ui.event(:draw, d.name, i)
    end
    false
  end

  effect(:PlusPowerEffect) do |du|
    d = du.turn_duelist
    d.put_hand_card_in_play_area(du.atk.card_index, PLAY_AREA_ARENA)
    d.slot_pluspower[PLAY_AREA_ARENA] += 1; false
  end

  effect(:SuperPotion_HealEffect) do |du|
    d = du.turn_duelist
    d.put_card_in_discard_pile(du.temp(:a0))
    du.heal_play_area_card_hp(du.temp(:a1), du.atk.temp[:play_area_effect_target]); false
  end

  effect(:ComputerSearch_HandDeckCheck) do |du|
    next _INTL("Not enough cards in your hand.") if du.turn_duelist.hand.size < 3
    du.deck_empty_text
  end

  effect(:PokemonFlute_BenchCheck) do |du|
    next _INTL("There is no space on the Bench.") if du.non_turn_duelist.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    du.as_non_turn { du.basic_pokemon_from_discard_pile.empty? } ? _INTL("There are no Pokémon in the Discard Pile.") : false
  end

  effects(:Shift_OncePerTurnCheck, :Peek_OncePerTurnCheck) { |du| du.once_per_turn_power_check }

  # Clefairy Doll / Mysterious Fossil "Discard" power
  effect(:TrainerCardAsPokemon_PlayerSelectSwitch) do |du|
    next false if du.temp(:a0) != 0
    du.set_temp(:a1, du.select_play_area_slot(:TrainerCardAsPokemon, true,
      _INTL("Select a Pokémon to place in the Active spot."))); false
  end
  effect(:TrainerCardAsPokemon_DiscardEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    d.move_play_area_card_to_discard_pile(e)
    d.swap_arena_with_bench_pokemon(du.temp(:a1)) if e == 0
    du.duelists.each(&:shift_pokemon_to_first_play_area_slots)
    false
  end

  effect(:Teleport_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_play_area_slot(:Teleport, true,
      _INTL("Select a Pokémon on the Bench to switch with the Active Pokémon."))); false
  end
  effect(:VictreebelLure_SelectSwitchPokemon) do |du|
    du.set_temp(:a0, du.select_opponent_bench_slot(:Lure, _INTL("Select a Pokémon on the Bench to switch with the Active Pokémon."))); false
  end

  # Porygon Conversion
  effect(:Conversion1_WeaknessCheck) do |du|
    nd = du.non_turn_duelist
    nd.card(nd.arena).weakness != 0 ? false : _INTL("No Weakness.")
  end
  effect(:Conversion2_ChangeResistanceEffect) do |du|
    d = du.turn_duelist
    d.changed_resistance = COLOR_TO_WR[du.temp(:a0)]
    du.ui.message(_INTL("Changed the Resistance of {1} to {2}.", d.card(d.arena).name,
      COLOR_NAMES.key(du.temp(:a0)).to_s.capitalize)); false
  end
end
