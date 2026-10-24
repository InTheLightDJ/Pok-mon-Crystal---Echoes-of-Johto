#==============================================================================
# Pokemon TCG - effect functions, batch 6 (effect_functions.asm).
# x20 multipliers, typed-energy discard selection, Lure/Gust switches,
# Dark Mind, Dream Eater, Psychic, trainer checks (Energy Retrieval, Breeder,
# Trader, Super Energy Removal/Retrieval, Revive).
#==============================================================================
module TCG
  class Duel
    # select one energy of a TYPE_ENERGY_* from the arena; cancellable => nil
    def select_arena_energy_of_type(purpose, type_name, cancellable)
      list = list_of_energy_attached_to_arena(TYPE_NAMES[type_name])
      sel = effect_choice(:card, purpose, list, cancellable)
      sel = list.first if sel.nil? && !cancellable
      sel
    end

    # CreatePlayableStage2PokemonCardListFromHand (Pokemon Breeder)
    def playable_stage2_cards_in_hand(d = turn_duelist)
      d.hand.select do |i|
        c = d.card(i)
        c.pokemon? && c.stage == STAGE2 &&
          (0...d.num_in_play_area).any? { |e| d.can_evolve_basic_to_stage2?(i, e) }
      end
    end

    def pokemon_cards_in_hand(d = turn_duelist)
      d.hand.select { |i| d.card(i).pokemon? }
    end

    # CreateBasicPokemonCardListFromDiscardPile (newest first)
    def basic_pokemon_from_discard_pile(d = turn_duelist)
      d.discard_pile.reverse.select { |i| c = d.card(i); c.pokemon? && c.stage == BASIC }
    end

    # HandleNShieldAndTransparency (turn holder = side owning slot e).
    # true = blocked
    def handle_nshield_and_transparency(e)
      d = turn_duelist
      case d.card_id(d.play_area[e])
      when :MEW_LV8
        return false if non_turn_duelist.slot_stage[PLAY_AREA_ARENA] == 0
        @atk.no_damage_or_effect = NO_DAMAGE_OR_EFFECT_NSHIELD
        @ui.message(_INTL("No damage or effect due to Neutralizing Shield."))
        true
      when :HAUNTER_LV17
        @ui.message(_INTL("Transparency check! If Heads, do not receive damage or effects."))
        return false if toss_coin == TAILS
        @atk.no_damage_or_effect = NO_DAMAGE_OR_EFFECT_TRANSPARENCY
        @ui.message(_INTL("No damage or effect due to Transparency."))
        true
      else
        false
      end
    end

    # Lure-style forced switch of the defending Pokemon with its bench slot a0
    def lure_switch_defending
      as_non_turn do
        e = temp(:a0)
        turn_duelist.swap_arena_with_bench_pokemon(e) unless handle_nshield_and_transparency(e)
      end
      @ui.refresh(self)
    end
  end

  # N coins, 20 x heads
  { :PrimeapeFurySwipes_MultiplierEffect => 3, :SandslashFurySwipes_MultiplierEffect => 3,
    :PinMissile_MultiplierEffect => 4, :JolteonDoubleKick_MultiplierEffect => 2,
    :CometPunch_MultiplierEffect => 4 }.each do |name, n|
    effect(name) do |du|
      du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 20))
      du.set_definite_damage(20 * du.toss_coins(n)); false
    end
  end
  effect(:BigEggsplosion_MultiplierEffect) do |du|
    n = du.turn_duelist.attached_energies(PLAY_AREA_ARENA)[1]
    du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 20))
    du.set_definite_damage(20 * du.toss_coins(n)); false
  end

  # typed energy discard selections (cancellable ones: "ret c")
  effects(:Barrier_PlayerSelectEffect, :KadabraRecover_PlayerSelectEffect, :Scavenge_PlayerSelectEnergyEffect) do |du|
    sel = du.select_arena_energy_of_type(:DiscardPsychic, "TYPE_ENERGY_PSYCHIC", true)
    next true if sel.nil?
    du.set_temp(:a0, sel); false
  end
  effect(:DestinyBond_PlayerSelectEffect) do |du|
    sel = du.select_arena_energy_of_type(:DiscardPsychic, "TYPE_ENERGY_PSYCHIC", true)
    next true if sel.nil?
    du.set_temp(:list, [sel]); false
  end
  effect(:StarmieRecover_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_arena_energy_of_type(:DiscardWater, "TYPE_ENERGY_WATER", false)); false
  end
  effect(:FireSpin_DiscardEffect) do |du|
    du.temp(:list).first(2).each { |i| du.turn_duelist.put_card_in_discard_pile(i) }; false
  end

  effect(:StarmieRecover_CheckEnergyHP) do |du|
    next _INTL("Not enough Water Energy.") if du.turn_duelist.attached_energies(PLAY_AREA_ARENA)[0][WATER] < 1
    du.arena_damage < 10 ? _INTL("There are no damage counters.") : false
  end
  effect(:Scavenge_CheckDiscardPile) do |du|
    next _INTL("Not enough Psychic Energy.") if du.turn_duelist.attached_energies(PLAY_AREA_ARENA)[0][PSYCHIC] < 1
    du.trainer_card_list_from_discard_pile.empty? ? _INTL("There are no Trainer cards in the Discard Pile.") : false
  end

  # Dark Mind: 10 to chosen opponent bench Pokemon (a0, nil = none)
  effects(:GengarDarkMind_DamageBenchEffect, :HypnoDarkMind_DamageBenchEffect) do |du|
    e = du.temp(:a0)
    du.as_non_turn { du.deal_damage_to_play_area_pokemon(e, 10) } if e; false
  end

  effect(:DreamEaterEffect) do |du|
    (du.non_turn_duelist.status & CNF_SLP_PRZ) == ASLEEP ? false : _INTL("The opponent is not Asleep.")
  end

  effect(:Psychic_DamageBoostEffect) { |du| du.atk.damage += du.energy_attached_multiplier_damage; false }

  effect(:Conversion2_ResistanceCheck) do |du|
    d = du.turn_duelist
    d.card(d.arena).resistance != 0 ? false : _INTL("No Resistance.")
  end

  effect(:CatPunchEffect) do |du|
    du.as_non_turn { du.deal_damage_to_play_area_pokemon(du.pick_random_play_area_card, 20, :ATK_ANIM_CAT_PUNCH_PLAY_AREA) }; false
  end

  effect(:SpitPoison_Poison50PercentEffect) do |du|
    du.ui.message(_INTL("Poison check! If Heads, the Defending Pokémon is Poisoned."))
    if du.toss_coin == HEADS
      du.queue_status(CNF_SLP_PRZ, POISONED)
    else
      du.atk.temp[:anim] = :ATK_ANIM_SPIT_POISON_SUCCESS
      du.set_no_effect_from_status
    end
    false
  end

  effects(:VictreebelLure_SwitchDefendingPokemon, :NinetalesLure_SwitchEffect) { |du| du.lure_switch_defending; false }

  effect(:GustOfWind_PlayerSelection) do |du|
    du.ui.message(_INTL("Choose a Pokémon to switch with the opponent's Active Pokémon.")) if du.player_turn?
    du.set_temp(:a0, du.as_non_turn { du.select_play_area_slot(:GustOfWind, true, nil) }); false
  end

  # Cowardice: choose a new active if Tentacool was in the arena (a0 == 0)
  effect(:Cowardice_PlayerSelectEffect) do |du|
    next false if du.temp(:a0) != 0
    du.atk.temp[:power_param] = du.select_play_area_slot(:Cowardice, true,
      _INTL("Select a Pokémon to place in the Active spot.")); false
  end

  #----------------------------------------------------------------------------
  # trainer checks
  #----------------------------------------------------------------------------
  effect(:EnergyRetrieval_HandEnergyCheck) do |du|
    next _INTL("Not enough cards in your hand.") if du.turn_duelist.hand.size < 2
    du.energy_card_list_from_discard_pile(true).empty? ? _INTL("There are no Basic Energy cards in the Discard Pile.") : false
  end
  effect(:SuperEnergyRetrieval_HandEnergyCheck) do |du|
    next _INTL("Not enough cards in your hand.") if du.turn_duelist.hand.size < 3
    du.energy_card_list_from_discard_pile(true).empty? ? _INTL("There are no Basic Energy cards in the Discard Pile.") : false
  end
  effect(:PokemonBreeder_HandPlayAreaCheck) do |du|
    next _INTL("Conditions for evolving to Stage 2 not fulfilled.") if du.playable_stage2_cards_in_hand.empty?
    du.prehistoric_power_active? ? true : false
  end
  effect(:PokemonTrader_HandDeckCheck) do |du|
    no = _INTL("There are no cards in hand that you can change.")
    next no if du.turn_duelist.hand.size < 2
    du.pokemon_cards_in_hand.empty? ? no : false
  end
  effect(:SuperEnergyRemoval_EnergyCheck) do |du|
    next _INTL("No Energy cards are attached to Pokémon in your Play Area.") unless du.any_energy_cards_attached?
    du.as_non_turn { du.any_energy_cards_attached? } ? false :
      _INTL("No Energy cards are attached to Pokémon in your opponent's Play Area.")
  end
  effect(:Revive_BenchCheck) do |du|
    next _INTL("There is no space on the Bench.") if du.turn_duelist.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    du.basic_pokemon_from_discard_pile.empty? ? _INTL("There are no Pokémon in the Discard Pile.") : false
  end
end
