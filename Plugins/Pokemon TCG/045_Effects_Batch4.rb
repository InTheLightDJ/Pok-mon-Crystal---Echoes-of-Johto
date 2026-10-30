#==============================================================================
# Pokemon TCG - effect functions, batch 4 (effect_functions.asm).
# Coin-flip recoil/boosts, energy checks, Recover heals, Swords Dance/Focus
# Energy, Psywave, Meditate, Do the Wave, Pokemon+energy selection, deck checks.
#==============================================================================
module TCG
  class Duel
    # GetEnergyAttachedMultiplierDamage: 10 x energy CARDS on defending arena
    def energy_attached_multiplier_damage
      nd = non_turn_duelist
      10 * (0...nd.deck_size).count { |i| nd.card_locations[i] == CARD_LOCATION_ARENA && nd.card(i).energy? }
    end

    # HandlePokemonAndEnergySelectionScreen (turn holder's play area):
    # temp :a0 = slot, :a1 = energy card. returns true if cancelled.
    def handle_pokemon_and_energy_selection(purpose)
      d = turn_duelist
      slots = (0...d.num_in_play_area).select { |e| d.attached_energies(e)[1] > 0 }
      return true if slots.empty?
      e = effect_choice(:play_area, purpose, slots, true)
      return true if e.nil?
      cards = d.energy_cards_in_slot(e)
      c = effect_choice(:card, purpose, cards, false) || cards.first
      set_temp(:a0, e)
      set_temp(:a1, c)
      false
    end

    def deck_empty_text(d = turn_duelist)
      d.cards_in_deck <= 0 ? _INTL("There are no cards left in the Deck.") : false
    end

    def no_bench_space_text(d = turn_duelist)
      d.num_in_play_area >= MAX_PLAY_AREA_POKEMON ? _INTL("There is no space on the Bench.") : false
    end

    def energy_check_text(color, n, text)
      turn_duelist.attached_energies(PLAY_AREA_ARENA)[0][color] < n ? text : false
    end
  end

  effect(:FoulGas_PoisonOrConfusionEffect) do |du|
    du.ui.message(_INTL("If Heads, the Defending Pokémon is Poisoned. If Tails, it is Confused."))
    du.toss_coin == HEADS ? du.queue_status(CNF_SLP_PRZ, POISONED) : du.queue_status(PSN_DBLPSN, CONFUSED)
    false
  end

  effect(:Teleport_SwitchEffect) do |du|
    du.turn_duelist.swap_arena_with_bench_pokemon(du.temp(:a0)); du.ui.refresh(du); false
  end
  effect(:StepIn_SwitchEffect) do |du|
    d = du.turn_duelist
    d.swap_arena_with_bench_pokemon(du.temp(:a0))
    d.slot_flags[PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
    false
  end

  # coin: heads +10, tails 10 to yourself (Thrash / Thunderpunch)
  effects(:Thrash_ModifierEffect, :Thunderpunch_ModifierEffect) do |du|
    du.ui.message(_INTL("If Heads, +10 damage. If Tails, 10 damage to yourself."))
    r = du.toss_coin
    du.set_temp(:a0, r)
    du.atk.damage += 10 if r == HEADS
    false
  end
  effects(:Thrash_RecoilEffect, :Thunderpunch_RecoilEffect) do |du|
    du.deal_recoil_damage_to_self(10) if du.temp(:a0) == TAILS; false
  end

  # coin: if tails, recoil (Thunder / Thunder Jolt); the recoil step is separate
  { :ZapdosThunder_Recoil50PercentEffect => 30, :ThunderJolt_Recoil50PercentEffect => 10,
    :RaichuThunder_Recoil50PercentEffect => 30 }.each do |name, n|
    effect(name) do |du|
      du.ui.message(_INTL("If Tails, {1} damage to yourself too.", n))
      du.set_temp(:a0, du.toss_coin); false
    end
  end

  effect(:LeekSlap_NoDamage50PercentEffect) do |du|
    du.ui.message(_INTL("Damage check! If Tails, no damage."))
    du.set_definite_damage(0) if du.toss_coin == TAILS; false
  end

  effect(:KinglerFlail_HPCheck) { |du| du.set_definite_damage(du.arena_damage); false }
  effects(:StarmieRecover_HealEffect, :KadabraRecover_HealEffect) do |du|
    du.apply_and_animate_hp_recovery(du.arena_damage); false
  end
  effect(:VenonatLeechLifeEffect) { |du| du.apply_and_animate_hp_recovery(du.atk.dealt_damage); false }
  effect(:ExeggcuteLeechSeedEffect) do |du|
    du.apply_and_animate_hp_recovery(10) if (du.atk.dealt_damage & 0xff) != 0; false
  end

  effect(:FocusEnergyEffect) do |du|
    du.apply_substatus1_to_attacking_card(SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE) if du.atk.temp_turn_card_id == :VAPOREON_LV29
    false
  end
  effect(:SwordsDanceEffect) do |du|
    du.apply_substatus1_to_attacking_card(SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE) if du.atk.temp_turn_card_id == :SCYTHER
    false
  end

  # energy checks
  effect(:FlamesOfRage_CheckEnergy) { |du| du.energy_check_text(FIRE, 2, _INTL("Not enough Fire Energy.")) }
  effect(:Wildfire_CheckEnergy)     { |du| du.energy_check_text(FIRE, 1, _INTL("Not enough Fire Energy.")) }
  effects(:DestinyBond_CheckEnergy, :Barrier_CheckEnergy) do |du|
    du.energy_check_text(PSYCHIC, 1, _INTL("Not enough Psychic Energy."))
  end
  effect(:FireSpin_CheckEnergy) do |du|
    du.turn_duelist.energy_cards_in_slot(PLAY_AREA_ARENA).size < 2 ? _INTL("Not enough Energy cards.") : false
  end

  # bench / deck checks
  effects(:FriendshipSong_BenchCheck, :MysteriousFossil_BenchCheck, :ClefairyDoll_BenchCheck) do |du|
    du.no_bench_space_text
  end
  effects(:EnergySearch_DeckCheck, :Pokedex_DeckCheck, :PokeBall_DeckCheck) { |du| du.deck_empty_text }
  effect(:VictreebelLure_AssertPokemonInBench) do |du|
    du.non_turn_duelist.num_in_play_area < 2 ? _INTL(NO_BENCH_TEXT) : false
  end
  effect(:SuperPotion_DamageEnergyCheck) do |du|
    next _INTL("There are no Pokémon with damage counters.") unless du.play_area_has_any_damage?
    du.any_energy_cards_attached? ? false : _INTL("There is no Energy card attached.")
  end

  effect(:EnergyRemoval_PlayerSelection) do |du|
    du.ui.message(_INTL("Choose a Pokémon to remove Energy from.")) if du.player_turn?
    du.as_non_turn { du.handle_pokemon_and_energy_selection(:EnergyRemoval) }
  end

  effect(:IceBreath_RandomPokemonDamageEffect) do |du|
    du.as_non_turn { du.deal_damage_to_play_area_pokemon(du.pick_random_play_area_card, 40) }; false
  end
  effect(:StretchKick_BenchDamageEffect) do |du|
    du.as_non_turn { du.deal_damage_to_play_area_pokemon(du.temp(:a0), 20) }; false
  end

  effect(:PsywaveEffect) { |du| du.atk.damage = du.energy_attached_multiplier_damage; false }
  effect(:JynxMeditate_DamageBoostEffect) do |du|
    du.atk.damage += du.as_non_turn { du.arena_damage }; false
  end
  effect(:DoTheWaveEffect) { |du| du.atk.damage += 10 * (du.turn_duelist.num_in_play_area - 1); false }

  effect(:SpacingOut_Success50PercentEffect) do |du|
    du.ui.message(_INTL("Success check! If Heads, the attack is successful."))
    r = du.toss_coin
    du.set_temp(:a0, r)
    du.set_was_unsuccessful if r == TAILS
    false
  end
end
