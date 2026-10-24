#==============================================================================
# Pokemon TCG - effect functions, batch 5 (effect_functions.asm).
# Play area selections for trainers, Full Heal, Leek Slap once-per-duel,
# Item Finder check, Mystery Attack recover, Doll/Fossil "Discard" power check.
#==============================================================================
module TCG
  class Duel
    # CreateTrainerCardListFromDiscardPile (newest first)
    def trainer_card_list_from_discard_pile(d = turn_duelist)
      d.discard_pile.reverse.select { |i| d.card(i).trainer? }
    end

    # OpenPlayAreaScreenForSelection on the turn holder's play area
    def select_play_area_slot(purpose, bench_only, prompt)
      d = turn_duelist
      @ui.message(prompt) if player_turn? && prompt
      slots = (bench_only ? 1 : 0).upto(d.num_in_play_area - 1).to_a
      sel = effect_choice(:play_area, purpose, slots, false)
      sel = slots.first unless slots.include?(sel)
      sel
    end
  end

  effect(:TrainerCardAsPokemon_BenchCheck) do |du|
    du.set_temp(:a0, du.atk.temp[:power_slot] || PLAY_AREA_ARENA)
    du.turn_duelist.num_in_play_area < 2 ? _INTL(NO_BENCH_TEXT) : false
  end

  effect(:ItemFinder_HandDiscardPileCheck) do |du|
    next _INTL("Not enough cards in your hand.") if du.turn_duelist.hand.size < 3
    du.trainer_card_list_from_discard_pile.empty? ? _INTL("There are no Trainer cards in the Discard Pile.") : false
  end

  effect(:Defender_PlayerSelection) do |du|
    du.set_temp(:a0, du.select_play_area_slot(:Defender, false, _INTL("Choose a Pokémon to attach Defender to."))); false
  end
  effect(:MrFuji_PlayerSelection) do |du|
    du.set_temp(:a0, du.select_play_area_slot(:MrFuji, true, _INTL("Choose a Pokémon to return to the Deck."))); false
  end
  effect(:Switch_PlayerSelection) do |du|
    du.set_temp(:a0, du.select_play_area_slot(:Switch, true, _INTL("Select a Pokémon on the Bench to switch with the Active Pokémon."))); false
  end

  effect(:FullHeal_StatusCheck) do |du|
    du.turn_duelist.status != 0 ? false : _INTL("Not affected by Poison, Sleep, Paralysis or Confusion.")
  end
  effect(:FullHeal_ClearStatusEffect) do |du|
    du.ui.event(:trainer_anim, :ATK_ANIM_FULL_HEAL)
    du.turn_duelist.status = NO_STATUS
    du.ui.refresh(du); false
  end

  effect(:LeekSlap_OncePerDuelCheck) do |du|
    (du.turn_duelist.slot_flags[PLAY_AREA_ARENA] & USED_LEEK_SLAP_THIS_DUEL) != 0 ?
      _INTL("This attack cannot be used twice.") : false
  end

  # Mystery Attack: hTemp_ffa0 == 4 -> recover 10
  effect(:MysteryAttack_RecoverEffect) do |du|
    du.apply_and_animate_hp_recovery(10) if du.temp(:a0) == 4; false
  end
end
