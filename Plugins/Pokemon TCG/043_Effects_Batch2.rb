#==============================================================================
# Pokemon TCG - effect functions, batch 2 (effect_functions.asm).
# Substatus setters, recoil, Supersonic family, Sonicboom, Energy Burn,
# discard-pile energy selection, 2-card hand selection.
#==============================================================================
module TCG
  class Duel
    # HandleEnergyBurn (home/card_color.asm): Charizard's arena energy all
    # counts as Fire
    def attached_energies_with_energy_burn(d, e)
      en, total = d.attached_energies(e)
      return [en, total] unless e == PLAY_AREA_ARENA && d.card_id(d.arena) == :CHARIZARD
      return [en, total] if incapable_of_using_pkmn_power?(d, PLAY_AREA_ARENA)
      en = Array.new(7, 0)
      en[COLORLESS] = 0
      en[FIRE] = total
      [en, total]
    end

    # CreateEnergyCardListFromDiscardPile (newest first); only_basic excludes DCE
    def energy_card_list_from_discard_pile(only_basic, d = turn_duelist)
      d.discard_pile.reverse.select do |i|
        c = d.card(i)
        c.energy? && (!only_basic || c.basic_energy?)
      end
    end

    # HandleEnergyCardsInDiscardPileSelection: pick up to 2 -> temp :list
    def handle_energy_cards_in_discard_pile_selection(purpose, prompt)
      list = energy_card_list_from_discard_pile(false)
      picked = []
      unless list.empty?
        @ui.message(prompt) if player_turn?
        while picked.size < 2 && !list.empty?
          sel = effect_choice(:card, purpose, list, true)   # nil = quit selecting
          break if sel.nil?
          picked << sel
          list.delete(sel)
        end
      end
      set_temp(:list, picked)
      false
    end

    # HandlePlayerSelection2HandCards: 2 hand cards (excluding the trainer in
    # use) -> temp :list. returns true (carry) if cancelled.
    def handle_selection_2_hand_cards(purpose, prompt)
      list = turn_duelist.hand - [@atk.card_index]
      @ui.message(prompt) if player_turn?
      picked = []
      while picked.size < 2
        sel = effect_choice(:card, purpose, list, true)
        return true if sel.nil?
        picked << sel
        list.delete(sel)
      end
      set_temp(:list, picked)
      false
    end
  end

  # substatus 1 on the attacking card
  { :GrimerMinimizeEffect => SUBSTATUS1_REDUCE_BY_20, :ClefableMinimizeEffect => SUBSTATUS1_REDUCE_BY_20,
    :Barrier_BarrierEffect => SUBSTATUS1_BARRIER, :OnixHardenEffect => SUBSTATUS1_PREVENT_LESS_THAN_40,
    :GravelerHardenEffect => SUBSTATUS1_PREVENT_LESS_THAN_40,
    :LightScreenEffect => SUBSTATUS1_HALVE_DAMAGE }.each do |name, v|
    effect(name) { |du| du.apply_substatus1_to_attacking_card(v); false }
  end

  # substatus 2 on the defending card
  { :HorseaSmokescreenEffect => SUBSTATUS2_SMOKESCREEN, :MagmarSmokescreenEffect => SUBSTATUS2_SMOKESCREEN,
    :SnivelEffect => SUBSTATUS2_REDUCE_BY_20, :SandAttackEffect => SUBSTATUS2_SAND_ATTACK,
    :PikachuLv16GrowlEffect => SUBSTATUS2_GROWL,
    :PikachuAltLv16GrowlEffect => SUBSTATUS2_GROWL }.each do |name, v|
    effect(name) { |du| du.apply_substatus2_to_defending_card(v); false }
  end

  # recoil
  { :TakeDownEffect => 30, :SubmissionEffect => 20, :JigglypuffDoubleEdgeEffect => 20 }.each do |name, n|
    effect(name) { |du| du.deal_recoil_damage_to_self(n); false }
  end

  # Supersonic / Sleeping Gas: 50% status, tails -> "no effect"
  effects(:ZubatSupersonicEffect, :NidorinaSupersonicEffect, :ShellderSupersonicEffect,
          :TentacruelSupersonicEffect) do |du|
    ok = du.toss_coin == HEADS && du.queue_status(PSN_DBLPSN, CONFUSED)
    du.set_no_effect_from_status unless ok
    false
  end
  effect(:SleepingGasEffect) do |du|
    ok = du.toss_coin == HEADS && du.queue_status(PSN_DBLPSN, ASLEEP)
    du.set_no_effect_from_status unless ok
    false
  end

  # Sonicboom: unaffected by weakness/resistance
  effects(:MagnetonSonicboom_UnaffectedByColorEffect, :ElectrodeSonicboom_UnaffectedByColorEffect) do |du|
    du.atk.unaffected_by_wr = true
    false
  end

  effect(:EnergyBurnEffect)        { |du| true }   # passive power
  effect(:PrehistoricPowerEffect)  { |du| true }   # passive power
  effect(:IceBreath_ZeroDamage)    { |du| du.set_definite_damage(0); false }
  effect(:DevolutionBeam_LoadAnimation) { |du| du.ui.event(:anim, :NONE); false }
  effect(:FirstAid_HealEffect)     { |du| du.apply_and_animate_hp_recovery(10); false }

  # whirlwind: switch the defending Pokemon with the selected bench slot
  effects(:ButterfreeWhirlwind_SwitchEffect, :PidgeottoWhirlwind_SwitchEffect) do |du|
    du.handle_switch_defending_pokemon(du.temp(:a0)); false
  end

  # discard the energy chosen earlier (hTemp_ffa0)
  effects(:StarmieRecover_DiscardEffect, :Barrier_DiscardEffect, :Scavenge_DiscardEffect,
          :KadabraRecover_DiscardEffect) do |du|
    du.turn_duelist.put_card_in_discard_pile(du.temp(:a0)); false
  end
  # Destiny Bond discards the first card of hTempList
  effect(:DestinyBond_DiscardEffect) do |du|
    du.turn_duelist.put_card_in_discard_pile(du.temp(:list).first); false
  end

  # energy in discard pile checks / 2-card selection
  effects(:EnergyConversion_CheckEnergy, :MewtwoAltEnergyAbsorption_CheckDiscardPile,
          :MewtwoEnergyAbsorption_CheckDiscardPile) do |du|
    du.energy_card_list_from_discard_pile(false).empty? ? _INTL("There are no Energy cards in the Discard Pile.") : false
  end
  effect(:EnergyConversion_PlayerSelectEffect) do |du|
    du.handle_energy_cards_in_discard_pile_selection(:EnergyConversion,
      _INTL("Choose 2 Energy cards from the Discard Pile to take into your hand."))
  end
  effects(:MewtwoAltEnergyAbsorption_PlayerSelectEffect, :MewtwoEnergyAbsorption_PlayerSelectEffect) do |du|
    du.handle_energy_cards_in_discard_pile_selection(:EnergyAbsorption,
      _INTL("Choose 2 Energy cards from the Discard Pile to attach to the Active Pokémon."))
  end

  effects(:ComputerSearch_PlayerDiscardHandSelection, :SuperEnergyRetrieval_PlayerHandSelection) do |du|
    du.handle_selection_2_hand_cards(:DiscardHand, _INTL("Choose 2 cards from your hand to discard."))
  end

  effects(:ClefableMetronome_CheckAttacks, :ClefairyMetronome_CheckAttacks) do |du|
    du.defending_pokemon_has_any_attack? ? false : _INTL("No attack may be chosen.")
  end
end
