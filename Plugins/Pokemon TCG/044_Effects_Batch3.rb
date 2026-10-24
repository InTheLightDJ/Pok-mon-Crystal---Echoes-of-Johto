#==============================================================================
# Pokemon TCG - effect functions, batch 3 (effect_functions.asm).
# Rage/Flail damage, Leech Life, checks (bench/damage/hand/discard), Earthquake,
# Big Thunder, Foul Odor, Acid, Headache, Switch, Potion heal, Fossil/Doll.
#==============================================================================
module TCG
  class Duel
    # RandomlyDamagePlayAreaPokemon (Big Thunder): 50/50 side, random slot
    def randomly_damage_play_area_pokemon(dmg)
      loop do
        @atk.no_damage_or_effect = 0
        if TCG.rng.rand(2) == 0
          @atk.is_damage_to_self = true
          e = TCG.rng.rand(turn_duelist.num_in_play_area)
          next if e == (@atk.temp[:power_slot] || PLAY_AREA_ARENA)   # re-roll
          deal_damage_to_play_area_pokemon(e, dmg, :ATK_ANIM_THUNDER_PLAY_AREA)
        else
          @atk.is_damage_to_self = false
          as_non_turn do
            e = TCG.rng.rand(turn_duelist.num_in_play_area)
            deal_damage_to_play_area_pokemon(e, dmg, :ATK_ANIM_THUNDER_PLAY_AREA)
          end
        end
        break
      end
    end

    # HealPlayAreaCardHP: no cap here (callers pass a valid amount)
    def heal_play_area_card_hp(e, n)
      d = turn_duelist
      @ui.event(:heal, d.name, e, n, :ATK_ANIM_HEALING_WIND_PLAY_AREA)
      unless @ui.shows_card_screens?   # the scene prints PokemonHealedDamageText
        @ui.message(_INTL("{1} healed {2} damage!", d.card(d.play_area[e]).name, n))
      end
      d.slot_hp[e] += n
    end

    # CheckIfThereAreAnyEnergyCardsAttached: ORIGINAL checks the whole play area
    def any_energy_cards_attached?(d = turn_duelist)
      (0...DECK_SIZE).any? do |i|
        (d.card_locations[i] & CARD_LOCATION_PLAY_AREA) != 0 && d.card(i).energy?
      end
    end

    # (0 with an emptied Active, e.g. AI scoring a replacement after Hurricane)
    def arena_damage; turn_duelist.arena ? card_damage_and_max_hp(turn_duelist, PLAY_AREA_ARENA)[0] : 0; end
  end

  NO_BENCH_TEXT = "There are no Pokémon on the Bench."

  # damage tweaks
  effect(:MagikarpFlail_HPCheck) { |du| du.set_definite_damage(du.arena_damage); false }
  effects(:FlamesOfRage_DamageBoostEffect, :FlareonRage_DamageBoostEffect,
          :CuboneRage_DamageBoostEffect, :DodrioRage_DamageBoostEffect) do |du|
    du.atk.damage += du.arena_damage; false
  end
  effect(:VaporeonWaterGunEffect) { |du| du.apply_extra_water_energy_damage_bonus(2, 1); false }
  effect(:Gale_LoadAnimation)     { |du| du.ui.event(:anim, :ATK_ANIM_GALE); false }
  effect(:ChanseyDoubleEdgeEffect){ |du| du.deal_recoil_damage_to_self(80); false }
  effect(:PounceEffect)           { |du| du.apply_substatus2_to_defending_card(SUBSTATUS2_POUNCE); false }
  effect(:ExpandEffect)           { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_REDUCE_BY_10); false }
  effect(:DestinyBond_DestinyBondEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_DESTINY_BOND); false }
  effect(:TransparencyEffect)     { |du| true }    # passive power
  effect(:HeadacheEffect)         { |du| du.non_turn_duelist.substatus3 |= SUBSTATUS3_HEADACHE; false }

  effects(:LickitungSupersonicEffect) do |du|
    ok = du.toss_coin == HEADS && du.queue_status(PSN_DBLPSN, CONFUSED)
    du.set_no_effect_from_status unless ok
    false
  end
  effect(:SingEffect) do |du|
    ok = du.toss_coin == HEADS && du.queue_status(PSN_DBLPSN, ASLEEP)
    du.set_no_effect_from_status unless ok
    false
  end

  # Leech Life: heal by damage dealt
  effects(:GolbatLeechLifeEffect, :ZubatLeechLifeEffect) do |du|
    du.apply_and_animate_hp_recovery(du.atk.dealt_damage); false
  end

  # Blizzard: store coin result (damage step done by another function)
  effect(:Blizzard_BenchDamage50PercentEffect) do |du|
    du.ui.message(_INTL("If Heads, 10 damage to each of the opponent's Benched Pokémon. If Tails, 10 damage to each of your own."))
    du.set_temp(:a0, du.toss_coin); false
  end

  effect(:BigThunderEffect) { |du| du.randomly_damage_play_area_pokemon(70); false }

  effect(:EarthquakeEffect) do |du|
    du.atk.is_damage_to_self = true
    du.deal_damage_to_all_benched_pokemon(10); false
  end

  effect(:LeekSlap_SetUsedThisDuelFlag) do |du|
    du.turn_duelist.slot_flags[PLAY_AREA_ARENA] |= USED_LEEK_SLAP_THIS_DUEL; false
  end

  # Foul Odor: confuse both active Pokemon
  effect(:FoulOdorEffect) do |du|
    du.queue_status(PSN_DBLPSN, CONFUSED)
    du.as_non_turn { du.queue_status(PSN_DBLPSN, CONFUSED) }
    false
  end

  effect(:AcidEffect) do |du|
    du.ui.message(_INTL("Acid check! If Heads, the opponent's Active Pokémon can't retreat."))
    du.apply_substatus2_to_defending_card(SUBSTATUS2_ACID) if du.toss_coin == HEADS
    false
  end

  # switch-defending effects using hTemp_ffa0 / hTempPlayAreaLocation_ffa1
  effect(:PidgeyWhirlwind_SwitchEffect) { |du| du.handle_switch_defending_pokemon(du.temp(:a0)); false }
  effect(:TerrorStrike_SwitchDefendingPokemon) do |du|
    du.handle_switch_defending_pokemon(du.temp(:a1)) if du.temp(:a0) && du.temp(:a0) != 0
    false
  end
  effect(:Ram_RecoilSwitchEffect) do |du|
    du.deal_recoil_damage_to_self(20)
    du.handle_switch_defending_pokemon(du.temp(:a0)); false
  end

  effect(:FlamesOfRage_DiscardEffect) do |du|
    du.temp(:list).first(2).each { |i| du.turn_duelist.put_card_in_discard_pile(i) }; false
  end

  #----------------------------------------------------------------------------
  # checks
  #----------------------------------------------------------------------------
  effects(:Teleport_CheckBench, :MrFuji_BenchCheck, :Switch_BenchCheck, :ScoopUp_BenchCheck) do |du|
    du.turn_duelist.num_in_play_area < 2 ? _INTL(NO_BENCH_TEXT) : false
  end
  effects(:NinetalesLure_CheckBench, :StretchKick_CheckBench, :GustOfWind_BenchCheck) do |du|
    du.non_turn_duelist.num_in_play_area < 2 ? _INTL(NO_BENCH_TEXT) : false
  end
  effects(:SpacingOut_CheckDamage, :FirstAid_DamageCheck) do |du|
    du.arena_damage < 10 ? _INTL("There are no damage counters.") : false
  end
  effects(:Potion_DamageCheck, :PokemonCenter_DamageCheck) do |du|
    du.play_area_has_any_damage? ? false : _INTL("There are no Pokémon with damage counters.")
  end
  effect(:EnergyRemoval_EnergyCheck) do |du|
    du.as_non_turn { du.any_energy_cards_attached? } ? false :
      _INTL("No Energy cards are attached to the opponent's Active Pokémon.")
  end
  effect(:Maintenance_HandCheck) do |du|
    du.turn_duelist.hand.size < 3 ? _INTL("Not enough cards in your hand.") : false
  end
  effect(:Recycle_DiscardPileCheck) do |du|
    du.turn_duelist.discard_count < 1 ? _INTL("There are no cards in the Discard Pile.") : false
  end

  #----------------------------------------------------------------------------
  # trainers
  #----------------------------------------------------------------------------
  effects(:MysteriousFossil_PlaceInPlayAreaEffect, :ClefairyDoll_PlaceInPlayAreaEffect) do |du|
    du.put_basic_pokemon_in_play_area(du.atk.card_index); false
  end
  effect(:Switch_SwitchEffect) do |du|
    du.turn_duelist.swap_arena_with_bench_pokemon(du.temp(:a0)); false
  end
  effect(:Potion_HealEffect) { |du| du.heal_play_area_card_hp(du.temp(:a0), du.temp(:a1)); false }
  effect(:Maintenance_PlayerSelection) do |du|
    du.handle_selection_2_hand_cards(:Maintenance, _INTL("Choose 2 cards from your hand to return to your Deck."))
  end
  effect(:EnergyTrans_PrintProcedure) do |du|
    du.ui.message(_INTL("Procedure for Energy Trans: choose a Grass Energy attached to one of your Pokémon, then the Pokémon to move it to.")) if du.player_turn?
    false
  end

  # Porygon Conversion 1/2: choose a color (hTemp_ffa0)
  effect(:Conversion1_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.effect_choice(:color, :Conversion1, (0...NUM_COLORED_TYPES).to_a, false)); false
  end
  effect(:Conversion2_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.effect_choice(:color, :Conversion2, (0...NUM_COLORED_TYPES).to_a, false)); false
  end
end
