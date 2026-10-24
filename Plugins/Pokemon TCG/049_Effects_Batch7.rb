#==============================================================================
# Pokemon TCG - effect functions, batch 7 (effect_functions.asm).
# x30/x40 multipliers, Tantrum/Rampage self-confusion, Thunderbolt, Spark,
# Peal of Thunder, Horn Hazard, Clamp, Venom Powder, bench/deck/discard
# selections (Lure, Stretch Kick, Scavenge, Computer Search, Energy Retrieval),
# Energy Absorption attach, Devolution Beam check.
#==============================================================================
module TCG
  class Duel
    # CheckIfTurnDuelistHasEvolvedCards
    def has_evolved_cards?(d = turn_duelist)
      (0...d.num_in_play_area).any? { |e| d.slot_stage[e] != BASIC }
    end

    # choose an opponent bench slot, not cancellable (".loop_input / jr c")
    def select_opponent_bench_slot(purpose, prompt)
      @ui.message(prompt) if player_turn? && prompt
      as_non_turn { select_play_area_slot(purpose, true, nil) }
    end

    # confuse the turn holder's own active Pokemon (SwapTurn; ConfusionEffect)
    def confuse_self
      as_non_turn { queue_status(PSN_DBLPSN, CONFUSED) }
    end
  end

  # 2 coins x30
  effects(:Twineedle_MultiplierEffect, :NidorinaDoubleKick_MultiplierEffect,
          :NidorinoDoubleKick_MultiplierEffect, :OmastarSpikeCannon_MultiplierEffect,
          :PoliwhirlDoubleslap_MultiplierEffect, :CloysterSpikeCannon_MultiplierEffect) do |du|
    du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 30))
    du.set_definite_damage(30 * du.toss_coins(2)); false
  end
  # 2 coins x40
  effect(:DragoniteLv45Slam_MultiplierEffect) do |du|
    du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 40))
    du.set_definite_damage(40 * du.toss_coins(2)); false
  end

  effect(:TantrumEffect) do |du|
    du.ui.message(_INTL("If Tails, your Pokémon becomes Confused."))
    if du.toss_coin == TAILS
      du.atk.temp[:anim] = :ATK_ANIM_MULTIPLE_SLASH
      du.confuse_self
    end
    false
  end
  effect(:Rampage_Confusion50PercentEffect) do |du|
    du.atk.damage += du.arena_damage
    du.ui.message(_INTL("If Tails, your Pokémon becomes Confused."))
    du.confuse_self if du.toss_coin == TAILS
    false
  end

  # Thunderbolt: discard all energy cards attached to the arena
  effect(:ThunderboltEffect) do |du|
    d = du.turn_duelist
    d.energy_cards_in_slot(PLAY_AREA_ARENA).each { |i| d.put_card_in_discard_pile(i) }; false
  end

  effect(:Spark_BenchDamageEffect) do |du|
    e = du.temp(:a0)
    du.as_non_turn { du.deal_damage_to_play_area_pokemon(e, 10) } if e; false
  end

  effect(:PealOfThunder_RandomlyDamageEffect) do |du|
    du.randomly_damage_play_area_pokemon(30)
    du.handle_destiny_bond_and_between_turn_knock_outs; false
  end

  effect(:HornHazard_NoDamage50PercentEffect) do |du|
    du.ui.message(_INTL("Damage check! If Tails, no damage."))
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_HIT
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end

  effect(:ClampEffect) do |du|
    du.ui.message(_INTL("Success check! If Heads, the attack is successful."))
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_HIT_EFFECT
      du.queue_status(PSN_DBLPSN, PARALYZED)
    else
      du.atk.temp[:anim] = :NONE
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end

  effect(:VenomPowder_PoisonConfusion50PercentEffect) do |du|
    du.ui.message(_INTL("Venom Powder check! If Heads, the Defending Pokémon is Poisoned and Confused."))
    next false if du.toss_coin == TAILS
    du.queue_status(CNF_SLP_PRZ, POISONED)
    du.atk.temp[:no_effect_from_which_status] = CONFUSED | POISONED unless du.queue_status(PSN_DBLPSN, CONFUSED)
    false
  end

  # selections
  effect(:NinetalesLure_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_opponent_bench_slot(:Lure, _INTL("Select a Pokémon on the Bench to switch with the Active Pokémon."))); false
  end
  effect(:StretchKick_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.select_opponent_bench_slot(:StretchKick, _INTL("Choose a Pokémon on the Bench to give damage to."))); false
  end
  effect(:Scavenge_PlayerSelectTrainerEffect) do |du|
    list = du.trainer_card_list_from_discard_pile
    du.set_temp(:a1, du.effect_choice(:card, :Scavenge, list, false) || list.first); false
  end
  effect(:Scavenge_AddToHandEffect) do |du|
    d = du.turn_duelist
    i = du.temp(:a1)
    d.move_discard_pile_card_to_hand(i)
    d.add_card_to_hand(i)
    du.ui.message(_INTL("{1} was placed in the hand.", d.card(i).name)) unless du.player_turn?
    false
  end
  effect(:EnergyRetrieval_PlayerHandSelection) do |du|
    du.ui.message(_INTL("Choose a card to discard from your hand.")) if du.player_turn?
    list = du.turn_duelist.hand - [du.atk.card_index]
    sel = du.effect_choice(:card, :EnergyRetrievalDiscard, list, true)
    next true if sel.nil?
    du.set_temp(:list, [sel]); false
  end
  effect(:ComputerSearch_PlayerDeckSelection) do |du|
    list = du.turn_duelist.deck_list
    sel = du.effect_choice(:card, :ComputerSearchDeck, list, false) || list.first
    l = du.temp(:list) || []
    l[2] = sel
    du.set_temp(:list, l); false
  end

  # Energy Absorption (alt): discard pile energy goes straight onto the arena
  effect(:MewtwoAltEnergyAbsorption_AddToHandEffect) do |du|
    d = du.turn_duelist
    (du.temp(:list) || []).each do |i|
      d.move_discard_pile_card_to_hand(i)
      d.card_locations[i] = CARD_LOCATION_ARENA
    end
    false
  end

  effect(:KadabraRecover_CheckEnergyHP) do |du|
    next _INTL("Not enough Psychic Energy.") if du.turn_duelist.attached_energies(PLAY_AREA_ARENA)[0][PSYCHIC] < 1
    du.arena_damage < 10 ? _INTL("There are no damage counters.") : false
  end

  effect(:DevolutionBeam_CheckPlayArea) do |du|
    next false if du.has_evolved_cards?
    du.as_non_turn { du.has_evolved_cards? } ? false : _INTL("There are no Stage 1 Pokémon.")
  end

  effect(:DamageSwap_CheckDamage) do |du|
    slot = du.atk.temp[:power_slot] || PLAY_AREA_ARENA
    du.set_temp(:a0, slot)
    next _INTL("There are no Pokémon with damage counters.") unless du.play_area_has_any_damage?
    du.incapable_of_using_pkmn_power?(du.turn_duelist, slot) ? true : false
  end
end
