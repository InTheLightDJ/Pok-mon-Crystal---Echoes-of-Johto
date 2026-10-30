#==============================================================================
# Pokemon TCG - effects of the Gen 3 ("Advanced") cards (set ADV, data in
# 001c_AdvCards.rb). Attacks that work like an earlier one reuse its effect
# commands (Body Slam, Hypnosis, Rage, Flail, Water Gun, Fly, Withdraw,
# Amnesia, Scary Face, Fury Swipes...); the new ones are here. Effects that
# only differ by a number read it from the attack's :param.
#
# Gen 3 rules only: no Pokémon-ex, δ, ★ or later gimmicks, singles only, and
# no Stadium / Supporter cards here, so those parts of the real cards were
# dropped or adapted (PokeTCG-mod/tools/neo_cards/CARDS_TO_REVISIT.md).
#
# Pokémon Powers (Poké-Powers / Poké-Bodies work as Pokémon Powers here):
#   menu      Firestarter (Blaziken), Water Call (Swampert), Swing Dance
#             (Ludicolo), Fan Away (Shiftry), Psy Shadow (Gardevoir), Energy
#             Draw (Delcatty), Night Vision (Sableye), Terraforming (Aggron),
#             Solar Eclipse (Solrock), Dragon Wind (Salamence), Super
#             Connectivity (Metagross)
#   played    Healing Shower (Milotic)
#   passive   Natural Cure (Grovyle, Lombre), Green Essence (Sceptile),
#             Withering Dust (Beautifly), Hard Cocoon (Cascoon), Protective
#             Dust (Dustox), Lazy (Slaking), Empty Shell (Shedinja), Thick
#             Skin (Roselia), Carefree (Grumpig), Sand Guard (Flygon), Fluff
#             (Swablu), Sol Shade (Lunatone), Power Pinchers (Crawdaunt),
#             Super Suction Cups (Cradily), Energy Variation (Kecleon),
#             Exoskeleton (Clamperl), Aqua Lift (Relicanth), Energy Guard
#             (Shelgon), Levitate (Beldum), Clear Body (Metang, Regirock,
#             Regice, Registeel)
#==============================================================================
module TCG
  def self.adv_cmds(name, *pairs); EFFECT_TABLE["Adv#{name}EffectCommands"] = pairs; end
  # damage
  adv_cmds "CoinPlus",          [EFFECT_BEFORE_DAMAGE, :AdvCoinPlusEffect], [EFFECT_AI, :AdvCoinPlus_AIEffect]
  adv_cmds "HealSelf",          [EFFECT_AFTER_DAMAGE, :AdvHealSelfEffect]
  adv_cmds "NoResistance",      [EFFECT_BEFORE_DAMAGE, :AdvNoResistanceEffect]
  adv_cmds "LinkBlast",         [EFFECT_BEFORE_DAMAGE, :AdvLinkBlastEffect], [EFFECT_AI, :AdvLinkBlastEffect]
  adv_cmds "PickOpponent",      [EFFECT_BEFORE_DAMAGE, :AdvPickOpponentEffect], [EFFECT_AFTER_DAMAGE, :AdvPickOpponent_BenchEffect],
                                [EFFECT_AI, :AdvPickOpponent_AIEffect]
  adv_cmds "PickOpponentNoWR",  [EFFECT_AFTER_DAMAGE, :AdvPickOpponentNoWREffect], [EFFECT_AI, :AdvPickOpponent_AIEffect]
  adv_cmds "SpecialCircuit",    [EFFECT_BEFORE_DAMAGE, :AdvPickOpponentEffect], [EFFECT_AFTER_DAMAGE, :AdvPickOpponent_BenchEffect],
                                [EFFECT_AI, :AdvPickOpponent_AIEffect]
  adv_cmds "MidairCrush",       [EFFECT_BEFORE_DAMAGE, :AdvPickOpponentEffect], [EFFECT_AFTER_DAMAGE, :AdvMidairCrushEffect],
                                [EFFECT_AI, :AdvPickOpponent_AIEffect]
  adv_cmds "BenchN",            [EFFECT_AFTER_DAMAGE, :AdvBenchNEffect]
  adv_cmds "DragonSpark",       [EFFECT_BEFORE_DAMAGE, :AdvDragonSpark_CoinEffect], [EFFECT_AFTER_DAMAGE, :AdvDragonSpark_BenchEffect],
                                [EFFECT_AI, :AdvDragonSpark_AIEffect]
  adv_cmds "PowerBlow",         [EFFECT_BEFORE_DAMAGE, :AdvPowerBlowEffect], [EFFECT_AI, :AdvPowerBlowEffect]
  adv_cmds "DarkSplash",        [EFFECT_BEFORE_DAMAGE, :AdvDarkSplashEffect], [EFFECT_AI, :AdvDarkSplashEffect]
  adv_cmds "MaxEnergySource",   [EFFECT_BEFORE_DAMAGE, :AdvMaxEnergySourceEffect], [EFFECT_AI, :AdvMaxEnergySourceEffect]
  adv_cmds "EnergyBurst",       [EFFECT_BEFORE_DAMAGE, :AdvEnergyBurstEffect], [EFFECT_AI, :AdvEnergyBurstEffect]
  adv_cmds "CircularSteps",     [EFFECT_BEFORE_DAMAGE, :AdvCircularStepsEffect], [EFFECT_AI, :AdvCircularStepsEffect]
  adv_cmds "LightTouchThrow",   [EFFECT_BEFORE_DAMAGE, :AdvLightTouchThrowEffect], [EFFECT_AI, :AdvLightTouchThrowEffect]
  adv_cmds "MysticWater",       [EFFECT_BEFORE_DAMAGE, :AdvMysticWaterEffect], [EFFECT_AI, :AdvMysticWaterEffect]
  adv_cmds "Grudge",            [EFFECT_BEFORE_DAMAGE, :AdvGrudgeEffect], [EFFECT_AI, :AdvGrudgeEffect]
  adv_cmds "Pulverize",         [EFFECT_BEFORE_DAMAGE, :AdvPulverizeEffect], [EFFECT_AI, :AdvPulverizeEffect]
  adv_cmds "PowerHeal",         [EFFECT_BEFORE_DAMAGE, :FlareonRage_DamageBoostEffect], [EFFECT_AFTER_DAMAGE, :AdvPowerHeal_HealEffect],
                                [EFFECT_AI, :FlareonRage_AIEffect]
  adv_cmds "BenchManipulation", [EFFECT_BEFORE_DAMAGE, :AdvBenchManipulationEffect], [EFFECT_AI, :AdvBenchManipulation_AIEffect]
  adv_cmds "FocusEnergy",       [EFFECT_AFTER_DAMAGE, :AdvFocusEnergyEffect]
  adv_cmds "FocusSlash",        [EFFECT_BEFORE_DAMAGE, :AdvFocusSlashEffect], [EFFECT_AI, :AdvFocusSlashEffect]
  adv_cmds "ExtraCometPunch",   [EFFECT_BEFORE_DAMAGE, :AdvExtraCometPunchEffect], [EFFECT_AFTER_DAMAGE, :AdvExtraCometPunch_NextEffect],
                                [EFFECT_AI, :AdvExtraCometPunch_AIEffect]
  adv_cmds "Curse",             [EFFECT_AFTER_DAMAGE, :AdvCurseEffect]
  adv_cmds "PurePower",         [EFFECT_AFTER_DAMAGE, :AdvPurePowerEffect]
  adv_cmds "RockBlast",         [EFFECT_AFTER_DAMAGE, :AdvRockBlastEffect], [EFFECT_AI, :AdvRockBlast_AIEffect]
  # Energy
  adv_cmds "FireStream",        [EFFECT_INITIAL_EFFECT_1, :AdvFireStream_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvFireStreamEffect]
  adv_cmds "FireSpin",          [EFFECT_INITIAL_EFFECT_1, :AdvFireSpin_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvFireSpinEffect]
  adv_cmds "CriticalMove",      [EFFECT_INITIAL_EFFECT_1, :AdvCriticalMove_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvCriticalMoveEffect]
  adv_cmds "MistBall",          [EFFECT_INITIAL_EFFECT_1, :AdvMistBall_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvMistBallEffect]
  adv_cmds "LusterPurge",       [EFFECT_INITIAL_EFFECT_1, :AdvLusterPurge_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvLusterPurgeEffect]
  adv_cmds "AirSlash",          [EFFECT_AFTER_DAMAGE, :AdvAirSlashEffect]
  adv_cmds "ScorchingSmoke",    [EFFECT_BEFORE_DAMAGE, :AdvBurnEffect], [EFFECT_AFTER_DAMAGE, :NeoBurningTailEffect]
  adv_cmds "Thrust",            [EFFECT_BEFORE_DAMAGE, :AdvThrust_CoinEffect], [EFFECT_AFTER_DAMAGE, :AdvThrust_DiscardEffect],
                                [EFFECT_AI, :Neo3HalfDamage_AIEffect]
  adv_cmds "HyperBeamCoin",     [EFFECT_AFTER_DAMAGE, :AdvHyperBeamCoinEffect]
  adv_cmds "HydroReverse",      [EFFECT_BEFORE_DAMAGE, :AdvHydroReverseEffect], [EFFECT_AI, :AdvHydroReverse_AIEffect]
  adv_cmds "GrowthSpurt",       [EFFECT_INITIAL_EFFECT_1, :AdvGrowthSpurt_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvGrowthSpurtEffect]
  adv_cmds "SpeedGrowth",       [EFFECT_INITIAL_EFFECT_1, :AdvGrowthSpurt_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvSpeedGrowthEffect]
  adv_cmds "EnergyDrawAttack",  [EFFECT_AFTER_DAMAGE, :AdvEnergyDrawAttackEffect]
  adv_cmds "PowerGeneration",   [EFFECT_INITIAL_EFFECT_1, :AdvPowerGeneration_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvPowerGenerationEffect]
  adv_cmds "QuickCharge",       [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :AdvQuickChargeEffect]
  adv_cmds "ThirdEye",          [EFFECT_INITIAL_EFFECT_1, :AdvThirdEye_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvThirdEyeEffect]
  adv_cmds "Fruition",          [EFFECT_INITIAL_EFFECT_1, :AdvFruition_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvFruitionEffect]
  # status
  adv_cmds "Burn",              [EFFECT_BEFORE_DAMAGE, :AdvBurnEffect]
  adv_cmds "Hulala",            [EFFECT_BEFORE_DAMAGE, :AdvHulalaEffect]
  adv_cmds "DarkBind",          [EFFECT_BEFORE_DAMAGE, :AdvDarkBindEffect]
  adv_cmds "DeadlyPoison",      [EFFECT_BEFORE_DAMAGE, :AdvDeadlyPoisonEffect]
  adv_cmds "StrangeScale",      [EFFECT_BEFORE_DAMAGE, :AdvStrangeScaleEffect]
  adv_cmds "LurePoison",        [EFFECT_BEFORE_DAMAGE, :AdvLurePoisonEffect]
  adv_cmds "HealingSound",      [EFFECT_BEFORE_DAMAGE, :SleepEffect], [EFFECT_AFTER_DAMAGE, :AdvHealingSoundEffect]
  adv_cmds "AdvancedArmor",     [EFFECT_AFTER_DAMAGE, :AdvAdvancedArmorEffect]
  # healing
  adv_cmds "SweetScent",        [EFFECT_AFTER_DAMAGE, :AdvSweetScentEffect]
  adv_cmds "MiraculousLight",   [EFFECT_AFTER_DAMAGE, :AdvMiraculousLightEffect]
  adv_cmds "DistortedWave",     [EFFECT_BEFORE_DAMAGE, :AdvDistortedWaveEffect]
  # deck / hand / discard pile
  adv_cmds "CallForFamily",     [EFFECT_INITIAL_EFFECT_1, :AdvCallForFamily_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvCallForFamilyEffect]
  adv_cmds "Ascension",         [EFFECT_INITIAL_EFFECT_1, :AdvAscension_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvAscensionEffect]
  adv_cmds "SeekOut",           [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :AdvSeekOutEffect]
  adv_cmds "MoonGuidance",      [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :AdvMoonGuidanceEffect]
  adv_cmds "FastEvolution",     [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :AdvFastEvolutionEffect]
  adv_cmds "SignsOfEvolution",  [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :AdvSignsOfEvolutionEffect]
  adv_cmds "SniffOut",          [EFFECT_INITIAL_EFFECT_1, :AdvSniffOut_CheckEffect], [EFFECT_AFTER_DAMAGE, :AdvSniffOutEffect]
  adv_cmds "PullAway",          [EFFECT_AFTER_DAMAGE, :AdvPullAwayEffect]
  adv_cmds "KnockOff",          [EFFECT_AFTER_DAMAGE, :AdvKnockOffEffect]
  adv_cmds "Surprise",          [EFFECT_AFTER_DAMAGE, :AdvSurpriseEffect]
  adv_cmds "MixUp",             [EFFECT_AFTER_DAMAGE, :AdvMixUpEffect]
  adv_cmds "Plunder",           [EFFECT_BEFORE_DAMAGE, :AdvPlunderEffect]
  adv_cmds "Resonate",          [EFFECT_AFTER_DAMAGE, :AdvResonateEffect]
  # Pokémon Powers
  adv_cmds "Firestarter",       [EFFECT_INITIAL_EFFECT_1, :AdvFirestarter_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvFirestarterEffect]
  adv_cmds "WaterCall",         [EFFECT_INITIAL_EFFECT_1, :AdvWaterCall_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvWaterCallEffect]
  adv_cmds "SwingDance",        [EFFECT_INITIAL_EFFECT_1, :AdvSwingDance_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvSwingDanceEffect]
  adv_cmds "FanAway",           [EFFECT_INITIAL_EFFECT_1, :AdvFanAway_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvFanAwayEffect]
  adv_cmds "PsyShadow",         [EFFECT_INITIAL_EFFECT_1, :AdvPsyShadow_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvPsyShadowEffect]
  adv_cmds "EnergyDrawPower",   [EFFECT_INITIAL_EFFECT_1, :AdvEnergyDrawPower_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvEnergyDrawPowerEffect]
  adv_cmds "NightVision",       [EFFECT_INITIAL_EFFECT_1, :AdvNightVision_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvNightVisionEffect]
  adv_cmds "Terraforming",      [EFFECT_INITIAL_EFFECT_1, :AdvTerraforming_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvTerraformingEffect]
  adv_cmds "SolarEclipse",      [EFFECT_INITIAL_EFFECT_1, :AdvSolarEclipse_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvSolarEclipseEffect]
  adv_cmds "DragonWind",        [EFFECT_INITIAL_EFFECT_1, :AdvDragonWind_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvDragonWindEffect]
  adv_cmds "SuperConnectivity", [EFFECT_INITIAL_EFFECT_1, :AdvSuperConnectivity_CheckUse], [EFFECT_BEFORE_DAMAGE, :AdvSuperConnectivityEffect]
  adv_cmds "HealingShower",     [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :AdvHealingShowerEffect]

  { :AdvCoinPlusEffect           => "Damage check!\nIf Heads, + damage!!",
    :AdvDragonSpark_CoinEffect   => "If Heads, 20 damage to each\nof the opponent's Pokémon.",
    :AdvThrust_CoinEffect        => "If Heads, discard 1 Energy.\nIf Tails, no damage.",
    :AdvHulalaEffect             => "Heads: opponent Confused.\nTails: both Confused.",
    :AdvMidairCrushEffect        => "If Heads, discard 1 Energy\nfrom that Pokémon.",
    :AdvHyperBeamCoinEffect      => "If Heads, discard 1 Energy\nfrom the Defending Pokémon.",
    :AdvKnockOffEffect           => "If Heads, discard 1 card from\nthe opponent's hand.",
    :AdvFanAwayEffect            => "If Heads, 1 Energy goes back\nto the opponent's hand.",
    :AdvEnergyDrawAttackEffect   => "If Heads, attach a basic\nEnergy from the deck.",
    :AdvHardCocoon               => "Hard Cocoon check!\nIf Heads, -30 damage.",
    :AdvSandGuard                => "Sand Guard check!\nIf Heads, -20 damage.",
    :AdvFluff                    => "Fluff check! If Heads,\nno damage or effects." }.each { |fn, t| NEO_COIN_TEXT[fn] = t }

  # passive powers by card (001c_AdvCards.rb ids)
  ADV_NO_STATUS     = [:ROSELIA, :METANG, :REGIROCK, :REGICE, :REGISTEEL]   # Thick Skin / Clear Body
  ADV_NATURAL_CURE  = { :GROVYLE => :GRASS_ENERGY, :LOMBRE => :WATER_ENERGY }
  ADV_RETREAT_ZERO  = { :RELICANTH => :WATER_ENERGY, :BELDUM => :any }      # Aqua Lift / Levitate
  ADV_SIGNS         = [["Silcoon", "Beautifly"], ["Cascoon", "Dustox"]]

  class Duel
    #--------------------------------------------------------------------------
    # helpers
    #--------------------------------------------------------------------------
    def adv_param; @atk.attack.param.to_i; end

    # slots of duelist d holding card `id` whose power works
    def adv_power_slots(d, id)
      (0...d.num_in_play_area).select { |e| d.play_area[e] && d.card_id(d.play_area[e]) == id && neo_power_works?(d, e) }
    end

    def adv_active_power?(d, id)
      d.arena && d.slot_hp[PLAY_AREA_ARENA] > 0 && d.card_id(d.arena) == id && neo_power_works?(d, PLAY_AREA_ARENA)
    end

    # energy cards attached to slot e of d / to all of d's Pokemon
    def adv_energy_count(d, e); d.energy_cards_in_slot(e).size; end
    def adv_total_energy(d); (0...d.num_in_play_area).sum { |e| adv_energy_count(d, e) }; end

    # the attacker picks one of the opponent's Pokémon (Active included) for
    # an attack doing `dmg` to it; kept in the attack's temp
    def adv_pick_target(dmg)
      e = neo3_pick_opponent_pokemon(:AdvPickOpponent, dmg)
      @atk.temp[:adv_target] = e
      e
    end

    # the turn holder takes card i from the deck into the hand
    def adv_deck_to_hand(i)
      d = turn_duelist
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
    end

    # pick one card of `list` (from the deck) into the hand; AI takes ai_pick
    def adv_search_deck(list, purpose, ai_pick = nil)
      return nil if list.empty?
      i = neo_human_choice? ? effect_choice(:card, purpose, list, true) : (ai_pick || list.first)
      return nil unless list.include?(i)
      adv_deck_to_hand(i)
      @ui.message(_INTL("{1} was put into the hand.", turn_duelist.card(i).name))
      i
    end

    # discard 1 energy card attached to the opponent's slot e (the attacker picks)
    def adv_discard_opponent_energy(e, purpose)
      nd = non_turn_duelist
      return if nd.play_area[e].nil? || nd.slot_hp[e] == 0
      list = nd.energy_cards_in_slot(e)
      return if list.empty?
      i = neo_human_choice? ? as_non_turn { effect_choice(:card, purpose, list, false) } : nil
      i = list.first unless list.include?(i)
      nd.put_card_in_discard_pile(i)
      @ui.message(_INTL("{1} was discarded from {2}.", nd.card(i).name, nd.card(nd.play_area[e]).name))
      @ui.refresh(self)
    end

    # the turn holder's Active: discard energy cards matching `pick` (count n)
    def adv_discard_own(n, purpose, &pick)
      d = turn_duelist
      list = d.energy_cards_in_slot(PLAY_AREA_ARENA).select { |i| pick ? pick.call(d.card(i), d.card_id(i)) : true }
      picked = []
      while picked.size < n && !list.empty?
        sel = neo_human_choice? ? effect_choice(:card, purpose, list, false) : nil
        sel = list.first unless list.include?(sel)
        picked << list.delete(sel)
      end
      picked.each { |i| d.put_card_in_discard_pile(i) }
      @ui.message(_INTL("{1} Energy card(s) were discarded.", picked.size)) unless picked.empty?
      @ui.refresh(self)
      picked.size
    end

    # remove all Special Conditions of d's Active
    def adv_cure(d)
      d.status = NO_STATUS
      neo_cure_burn(d)
    end

    #--------------------------------------------------------------------------
    # Thick Skin / Clear Body / Carefree / Green Essence / Protective Dust:
    # Special Conditions from the opponent's attacks
    #--------------------------------------------------------------------------
    def adv_status_blocked?(status)
      nd = non_turn_duelist
      return false if nd.arena.nil?
      id = nd.card_id(nd.arena)
      as_non_turn do
        d = turn_duelist
        return true if ADV_NO_STATUS.include?(id) && neo_power_works?(d, PLAY_AREA_ARENA)
        return true if id == :DUSTOX && neo_power_works?(d, PLAY_AREA_ARENA)
        return true if id == :GRUMPIG && status == CONFUSED && neo_power_works?(d, PLAY_AREA_ARENA)
        if !adv_power_slots(d, :SCEPTILE).empty?
          return true if d.cards_in_slot(PLAY_AREA_ARENA).any? { |i| d.card_id(i) == :GRASS_ENERGY }
        end
      end
      false
    end

    alias_method :tcg_adv_queue_status, :queue_status
    def queue_status(keep_mask, status)
      if @turn == @whose_turn && @atk && !@atk.pokemon_power? && adv_status_blocked?(status)
        set_no_effect_from_status
        return false
      end
      tcg_adv_queue_status(keep_mask, status)
    end

    # Protective Dust: no effects other than damage (Acid, Smokescreen...)
    alias_method :tcg_adv_apply_substatus2_to_defending_card, :apply_substatus2_to_defending_card
    def apply_substatus2_to_defending_card(v)
      nd = non_turn_duelist
      return if nd.arena && nd.card_id(nd.arena) == :DUSTOX && as_non_turn { neo_power_works?(turn_duelist, PLAY_AREA_ARENA) }
      tcg_adv_apply_substatus2_to_defending_card(v)
    end

    #--------------------------------------------------------------------------
    # Natural Cure: a Grass (Grovyle) / Water (Lombre) Energy card from the
    # hand removes its Special Conditions
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_play_energy_card, :play_energy_card
    def play_energy_card(idx, e)
      r = tcg_adv_play_energy_card(idx, e)
      return r unless r == :ok
      d = turn_duelist
      target = d.play_area[e]
      want = target && ADV_NATURAL_CURE[d.card_id(target)]
      # (it works while Asleep / Confused / Paralyzed: that's what it cures)
      if want && d.card_id(idx) == want && e == PLAY_AREA_ARENA && !toxic_gas_active? &&
         !adv_active_power?(@duelists[1 - side_of(d)], :SLAKING) && (d.status != NO_STATUS || d.burned)
        adv_cure(d)
        @ui.message(_INTL("{1}'s Pokémon Power: Natural Cure", d.card(target).name))
        @ui.refresh(self)
      end
      r
    end

    #--------------------------------------------------------------------------
    # Withering Dust: no Resistance for the Active Pokémon; Sonic Wing /
    # Pebble Hurl / Mach Claw: no Resistance for that attack
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_arena_card_resistance, :arena_card_resistance
    def arena_card_resistance(d)
      return 0 if @atk && @atk.temp[:adv_no_resistance] && d.equal?(non_turn_duelist)
      return 0 if @duelists.any? { |x| !adv_power_slots(x, :BEAUTIFLY).empty? }
      tcg_adv_arena_card_resistance(d)
    end

    #--------------------------------------------------------------------------
    # damage taken: Hard Cocoon, Sand Guard, Exoskeleton, Energy Guard
    # (turn holder = the damaged side), Fluff and Advanced Armor (no damage
    # or effects)
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_damage_reduction_from_pkmn_power, :damage_reduction_from_pkmn_power
    def damage_reduction_from_pkmn_power(dmg)
      dmg = tcg_adv_damage_reduction_from_pkmn_power(dmg)
      return dmg if @atk.pokemon_power? || @atk.is_damage_to_self || dmg <= 0
      d = turn_duelist
      return dmg unless d.arena && neo_power_works?(d, PLAY_AREA_ARENA)
      name = d.card(d.arena).name
      case d.card_id(d.arena)
      when :CLAMPERL then dmg -= 10
      when :SHELGON  then dmg -= 10 if d.cards_in_slot(PLAY_AREA_ARENA).any? { |i| d.card(i).basic_energy? }
      when :CASCOON
        unless @neo3_ai_calc
          coin_check(_INTL("Hard Cocoon! If Heads, {1} takes 30 less damage.", name), NEO_COIN_TEXT[:AdvHardCocoon])
          dmg -= 30 if toss_coin(d.name) == HEADS
        end
      when :FLYGON
        unless @neo3_ai_calc
          coin_check(_INTL("Sand Guard! If Heads, {1} takes 20 less damage.", name), NEO_COIN_TEXT[:AdvSandGuard])
          dmg -= 20 if toss_coin(d.name) == HEADS
        end
      end
      [dmg, 0].max
    end

    alias_method :tcg_adv_handle_no_damage_or_effect_substatus, :handle_no_damage_or_effect_substatus
    def handle_no_damage_or_effect_substatus
      r = tcg_adv_handle_no_damage_or_effect_substatus
      return r if r || @atk.pokemon_power? || @atk.is_damage_to_self || @atk.temp[:swift]
      d = turn_duelist   # the defending side
      return false unless d.arena
      attacker = @atk.temp_turn_card_id && TCG.card(@atk.temp_turn_card_id)
      if attacker && attacker.pokemon? && !attacker.basic? && neo_fx_active?(:adv_armor, side_of(d), d.arena)
        @ui.message(_INTL("Advanced Armor! {1} isn't affected by Evolved Pokémon.", d.card(d.arena).name))
        return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_AGILITY)
      end
      if d.card_id(d.arena) == :SWABLU && card_damage_and_max_hp(d, PLAY_AREA_ARENA)[0] > 0 &&
         neo_power_works?(d, PLAY_AREA_ARENA) && !@neo3_ai_calc
        coin_check(_INTL("Fluff! If Heads, Swablu isn't affected by the attack."), NEO_COIN_TEXT[:AdvFluff])
        return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_AGILITY) if toss_coin(d.name) == HEADS
      end
      false
    end

    #--------------------------------------------------------------------------
    # Power Pinchers: the Active's attacks do 10 more (before Weakness /
    # Resistance) while Crawdaunt is the Active Pokémon
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_apply_damage_modifiers_damage_to_target, :apply_damage_modifiers_damage_to_target
    def apply_damage_modifiers_damage_to_target
      @atk.damage += 10 if @atk.damage > 0 && !@atk.pokemon_power? && adv_active_power?(turn_duelist, :CRAWDAUNT)
      tcg_adv_apply_damage_modifiers_damage_to_target
    end

    #--------------------------------------------------------------------------
    # Empty Shell: no Prize cards for Shedinja
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_count_knocked_out_pokemon, :count_knocked_out_pokemon
    def count_knocked_out_pokemon(d)
      n = tcg_adv_count_knocked_out_pokemon(d)
      shells = (0...MAX_PLAY_AREA_POKEMON).count do |e|
        idx = d.play_area[e]
        idx && d.slot_hp[e] == 0 && d.card_id(idx) == :SHEDINJA && !toxic_gas_active?
      end
      [n - shells, 0].max
    end

    #--------------------------------------------------------------------------
    # Lazy (the opponent's Active Slaking) / Sol Shade (Lunatone with a
    # Solrock: every Fire Pokémon): no Pokémon Powers
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_incapable_of_using_pkmn_power?, :incapable_of_using_pkmn_power?
    def incapable_of_using_pkmn_power?(d, e)
      return true if tcg_adv_incapable_of_using_pkmn_power?(d, e)
      return false if @adv_power_check || d.play_area[e].nil?
      @adv_power_check = true
      begin
        other = @duelists[1 - side_of(d)]
        return true if adv_active_power?(other, :SLAKING)
        if play_area_card_color(d, e) == FIRE
          return true if @duelists.any? { |x| !adv_power_slots(x, :LUNATONE).empty? && neo3_in_play?(x, :SOLROCK) }
        end
      ensure
        @adv_power_check = false
      end
      false
    end

    #--------------------------------------------------------------------------
    # retreating: Super Suction Cups (the opponent's Active Cradily), Aqua
    # Lift / Levitate (Retreat Cost 0)
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_unable_to_retreat_due_to_effect?, :unable_to_retreat_due_to_effect?
    def unable_to_retreat_due_to_effect?(d)
      return true if adv_active_power?(@duelists[1 - side_of(d)], :CRADILY)
      tcg_adv_unable_to_retreat_due_to_effect?(d)
    end

    alias_method :tcg_adv_retreat_cost, :retreat_cost
    def retreat_cost(d, e = PLAY_AREA_ARENA)
      idx = d.play_area[e]
      need = idx && ADV_RETREAT_ZERO[d.card_id(idx)]
      if need && neo_power_works?(d, e)
        energy = d.energy_cards_in_slot(e)
        return 0 if need == :any ? !energy.empty? : energy.any? { |i| d.card_id(i) == need }
      end
      tcg_adv_retreat_cost(d, e)
    end

    #--------------------------------------------------------------------------
    # Energy Variation: Kecleon is the type of its basic Energy (the first
    # one attached); Solar Eclipse: Solrock is Fire this turn
    #--------------------------------------------------------------------------
    alias_method :tcg_adv_play_area_card_color, :play_area_card_color
    def play_area_card_color(d, e)
      idx = d.play_area[e]
      if idx && d.card_id(idx) == :KECLEON && (d.slot_changed_type[e] & HAS_CHANGED_COLOR) == 0
        en = d.cards_in_slot(e).find { |i| d.card(i).basic_energy? }
        return d.card(en).color if en && !@adv_color_check && adv_kecleon_works?(d, e)
      end
      tcg_adv_play_area_card_color(d, e)
    end

    def adv_kecleon_works?(d, e)
      @adv_color_check = true
      neo_power_works?(d, e)
    ensure
      @adv_color_check = false
    end

    alias_method :tcg_adv_update_substatus_conditions_end_of_turn, :update_substatus_conditions_end_of_turn
    def update_substatus_conditions_end_of_turn
      if (fx = neo_fx[:adv_eclipse]) && fx[2] <= @duel_turns
        d = @duelists[fx[0]]
        e = d.play_area.index(fx[1])
        d.slot_changed_type[e] = 0 if e
      end
      tcg_adv_update_substatus_conditions_end_of_turn
    end
  end

  #----------------------------------------------------------------------------
  # damage
  #----------------------------------------------------------------------------
  # heads: + param damage
  effect(:AdvCoinPlusEffect) do |du|
    n = du.adv_param
    du.coin_check(_INTL("Damage check! If Heads, +{1} damage.", n), NEO_COIN_TEXT[:AdvCoinPlusEffect])
    du.atk.damage += n if du.toss_coin == HEADS
    false
  end
  effect(:AdvCoinPlus_AIEffect) { |du| b = du.atk.attack.damage; n = du.adv_param; du.set_expected_ai_damage(b + n / 2, b, b + n); false }

  effect(:AdvHealSelfEffect) do |du|
    du.ui.message(_INTL("There are no damage counters.")) if du.neo4_heal(PLAY_AREA_ARENA, du.adv_param) == 0
    du.ui.refresh(du); false
  end

  # Sonic Wing / Pebble Hurl / Mach Claw: Resistance doesn't apply
  effect(:AdvNoResistanceEffect) { |du| du.atk.temp[:adv_no_resistance] = true; false }

  # Link Blast: a different Energy count -> base damage param
  effect(:AdvLinkBlastEffect) do |du|
    d, nd = du.turn_duelist, du.non_turn_duelist
    du.set_definite_damage(du.adv_param) if nd.arena && du.adv_energy_count(d, PLAY_AREA_ARENA) != du.adv_energy_count(nd, PLAY_AREA_ARENA)
    false
  end

  # 1 of the opponent's Pokémon: the Active takes the attack's damage (with
  # Weakness / Resistance), a Benched one takes it without
  effect(:AdvPickOpponentEffect) do |du|
    n = du.adv_param
    e = du.adv_pick_target(n)
    if e && du.atk.attack.effect == "AdvSpecialCircuitEffectCommands"
      nd = du.non_turn_duelist
      n *= 2 if nd.card(nd.play_area[e]).has_pkmn_power?
    end
    du.atk.temp[:adv_amount] = n
    du.set_definite_damage(e == PLAY_AREA_ARENA ? n : 0)
    false
  end
  effect(:AdvPickOpponent_BenchEffect) do |du|
    e = du.atk.temp[:adv_target]
    du.neo_damage_opponent_slot(e, du.atk.temp[:adv_amount]) if e && e != PLAY_AREA_ARENA
    false
  end
  effect(:AdvPickOpponent_AIEffect) { |du| n = du.adv_param; du.set_expected_ai_damage(n, n, n); false }
  # Telekinesis: no Weakness / Resistance at all
  effect(:AdvPickOpponentNoWREffect) do |du|
    n = du.adv_param
    e = du.adv_pick_target(n)
    du.neo3_damage_opponent_any(e, n) if e
    false
  end
  # Mid-air Crush: heads, that Pokémon discards an Energy card
  effect(:AdvMidairCrushEffect) do |du|
    e = du.atk.temp[:adv_target]
    next false if e.nil?
    du.neo_damage_opponent_slot(e, du.atk.temp[:adv_amount]) if e != PLAY_AREA_ARENA
    du.coin_check(_INTL("If Heads, your opponent discards an Energy card from that Pokémon."), NEO_COIN_TEXT[:AdvMidairCrushEffect])
    du.adv_discard_opponent_energy(e, :AdvDiscardEnergy) if du.toss_coin == HEADS
    false
  end

  # param of the opponent's Benched Pokémon take 10 each (Gigashock, Rock
  # Slide, Lava Burn, Pebble Throw: 10; Dark Mind: 20 to 1)
  effect(:AdvBenchNEffect) do |du|
    nd = du.non_turn_duelist
    slots = du.neo_alive_bench(nd)
    n = [du.adv_param, slots.size].min
    dmg = du.atk.attack.name == "Dark Mind" ? 20 : 10
    picked = []
    n.times do
      left = slots - picked
      e = if du.neo_human_choice?
            du.ui.message(_INTL("Choose 1 of your opponent's Benched Pokémon."))
            du.as_non_turn { du.effect_choice(:play_area, :AdvBench, left, false) }
          end
      e = left.min_by { |s| nd.slot_hp[s] } unless left.include?(e)
      picked << e
    end
    picked.each { |e| du.neo_damage_opponent_slot(e, dmg) }
    false
  end

  # Dragon Spark: heads, param to each of the opponent's Pokémon
  effect(:AdvDragonSpark_CoinEffect) do |du|
    du.coin_check(_INTL("If Heads, 20 damage to each of your opponent's Pokémon."), NEO_COIN_TEXT[:AdvDragonSpark_CoinEffect])
    hit = du.toss_coin == HEADS
    du.atk.temp[:adv_spark] = hit
    du.set_definite_damage(hit ? du.adv_param : 0)
    du.set_was_unsuccessful unless hit
    false
  end
  effect(:AdvDragonSpark_BenchEffect) do |du|
    next false unless du.atk.temp[:adv_spark]
    du.neo_alive_bench(du.non_turn_duelist).each { |e| du.neo_damage_opponent_slot(e, du.adv_param) }
    false
  end
  effect(:AdvDragonSpark_AIEffect) { |du| n = du.adv_param; du.set_expected_ai_damage(n / 2, 0, n); false }

  # Power Blow: 10 + 10 for each Energy attached
  effect(:AdvPowerBlowEffect) do |du|
    du.set_definite_damage(du.atk.attack.damage + 10 * du.adv_energy_count(du.turn_duelist, PLAY_AREA_ARENA)); false
  end
  # Dark Splash (Huntail): +10 for each Darkness Pokémon in play (both sides)
  effect(:AdvDarkSplashEffect) do |du|
    n = [du.turn_duelist, du.non_turn_duelist].sum do |x|
      (0...x.num_in_play_area).count { |e| du.play_area_card_color(x, e) == DARKNESS }
    end
    du.set_definite_damage(du.atk.attack.damage + 10 * n); false
  end
  # Max Energy Source: 10 x the Energy on your Active Pokémon
  effect(:AdvMaxEnergySourceEffect) do |du|
    du.set_definite_damage(10 * du.adv_energy_count(du.turn_duelist, PLAY_AREA_ARENA)); false
  end
  # Energy Burst: 10 x the Energy on Gardevoir and the Defending Pokémon
  effect(:AdvEnergyBurstEffect) do |du|
    d, nd = du.turn_duelist, du.non_turn_duelist
    n = du.adv_energy_count(d, PLAY_AREA_ARENA) + (nd.arena ? du.adv_energy_count(nd, PLAY_AREA_ARENA) : 0)
    du.set_definite_damage(10 * n); false
  end
  # Circular Steps: 10 x the Pokémon in play, Ludicolo excluded
  effect(:AdvCircularStepsEffect) do |du|
    n = du.duelists.sum { |x| (0...x.num_in_play_area).count { |e| x.slot_hp[e] > 0 } } - 1
    du.set_definite_damage(10 * [n, 0].max); false
  end
  # Light Touch Throw: 80 - 10 for each Energy on the Defending Pokémon
  effect(:AdvLightTouchThrowEffect) do |du|
    nd = du.non_turn_duelist
    n = nd.arena ? du.adv_energy_count(nd, PLAY_AREA_ARENA) : 0
    du.set_definite_damage([du.atk.attack.damage - 10 * n, 0].max); false
  end
  # Mystic Water: 20 + 10 for each Psychic Energy in play
  effect(:AdvMysticWaterEffect) do |du|
    n = du.duelists.sum do |x|
      (0...x.num_in_play_area).sum { |e| x.cards_in_slot(e).count { |i| x.card_id(i) == :PSYCHIC_ENERGY } }
    end
    du.set_definite_damage(du.atk.attack.damage + 10 * n); false
  end
  # Grudge: 20 + 10 for each Prize card the opponent has taken
  effect(:AdvGrudgeEffect) do |du|
    nd = du.non_turn_duelist
    du.set_definite_damage(du.atk.attack.damage + 10 * [du.initial_prizes - nd.count_prizes, 0].max); false
  end
  # Pulverize: +20 if the Defending Pokémon has 2 or more damage counters
  effect(:AdvPulverizeEffect) do |du|
    nd = du.non_turn_duelist
    hurt = nd.arena && du.card_damage_and_max_hp(nd, PLAY_AREA_ARENA)[0] >= 20
    du.set_definite_damage(du.atk.attack.damage + (hurt ? 20 : 0)); false
  end
  # Power Heal: then remove 1 damage counter from Medicham
  effect(:AdvPowerHeal_HealEffect) { |du| du.neo4_heal(PLAY_AREA_ARENA, 10); du.ui.refresh(du); false }

  # Bench Manipulation: the opponent flips a coin for each Benched Pokémon,
  # 40 x tails, no Weakness / Resistance
  effect(:AdvBenchManipulationEffect) do |du|
    n = du.neo_alive_bench(du.non_turn_duelist).size
    du.coin_check(_INTL("Your opponent flips {1} coins: 40 damage for each Tails.", n), "Bench Manipulation!\n40 damage for each Tails!!")
    tails = n - du.as_non_turn { du.toss_coins(n) }
    du.set_definite_damage(0)
    du.neo3_damage_opponent_arena(40 * tails) if tails > 0
    false
  end
  effect(:AdvBenchManipulation_AIEffect) do |du|
    n = du.neo_alive_bench(du.non_turn_duelist).size
    du.set_expected_ai_damage(20 * n, 0, 40 * n); false
  end

  # Focus Energy: next turn, Vigoroth's Slash does param (90)
  effect(:AdvFocusEnergyEffect) do |du|
    d = du.turn_duelist
    du.neo_fx[:adv_focus] = [du.turn, d.arena, du.duel_turns + 2]
    du.ui.message(_INTL("{1}'s Slash will do 90 damage next turn.", d.card(d.arena).name)); false
  end
  effect(:AdvFocusSlashEffect) do |du|
    d = du.turn_duelist
    du.set_definite_damage(du.adv_param) if du.neo_fx_active?(:adv_focus, du.turn, d.arena); false
  end
  # Extra Comet Punch: +30 next turn (it adds up turn after turn)
  effect(:AdvExtraCometPunchEffect) do |du|
    d = du.turn_duelist
    fx = du.neo_fx[:adv_comet]
    du.atk.damage += 30 if fx && fx[0] == du.turn && fx[1] == d.arena && fx[2] >= du.duel_turns
    false
  end
  effect(:AdvExtraCometPunch_NextEffect) do |du|
    d = du.turn_duelist
    du.neo_fx[:adv_comet] = [du.turn, d.arena, du.duel_turns + 2]; false
  end
  effect(:AdvExtraCometPunch_AIEffect) do |du|
    d = du.turn_duelist
    fx = du.neo_fx[:adv_comet]
    n = du.atk.attack.damage + (fx && fx[0] == du.turn && fx[1] == d.arena ? 30 : 0)
    du.set_expected_ai_damage(n, n, n); false
  end

  # Extra Curse: param damage counters on the Defending Pokémon
  effect(:AdvCurseEffect) { |du| du.neo3_counters_on_opponent(PLAY_AREA_ARENA, du.adv_param.clamp(1, 9)); false }

  # Pure Power: 2 damage counters on the opponent's Pokémon in any way
  effect(:AdvPurePowerEffect) do |du|
    2.times do
      nd = du.non_turn_duelist
      slots = (0...nd.num_in_play_area).select { |e| nd.slot_hp[e] > 0 }
      break if slots.empty?
      e = if du.neo_human_choice?
            du.ui.message(_INTL("Choose 1 of your opponent's Pokémon for a damage counter."))
            du.as_non_turn { du.effect_choice(:play_area, :AdvPurePower, slots, false) }
          end
      e = slots.min_by { |s| nd.slot_hp[s] } unless slots.include?(e)
      du.neo3_counters_on_opponent(e, 1)
    end
    false
  end

  # Rock Blast: discard up to 5 Fighting Energy cards, 20 to a chosen
  # Pokémon for each (no Weakness / Resistance)
  effect(:AdvRockBlastEffect) do |du|
    d = du.turn_duelist
    list = d.energy_cards_in_slot(PLAY_AREA_ARENA).select { |i| d.card_id(i) == :FIGHTING_ENERGY }
    next false if list.empty?
    n = [list.size, 5].min
    if du.neo_human_choice?
      n = du.effect_choice(:number, :AdvRockBlast, (0..n).to_a.reverse, false).to_i.clamp(0, n)
    end
    next false if n == 0
    list.first(n).each { |i| d.put_card_in_discard_pile(i) }
    du.ui.message(_INTL("{1} Fighting Energy card(s) were discarded.", n))
    n.times do
      nd = du.non_turn_duelist
      e = du.adv_pick_target(20)
      break if e.nil?
      du.neo3_damage_opponent_any(e, 20)
    end
    du.ui.refresh(du); false
  end
  effect(:AdvRockBlast_AIEffect) do |du|
    d = du.turn_duelist
    n = [d.energy_cards_in_slot(PLAY_AREA_ARENA).count { |i| d.card_id(i) == :FIGHTING_ENERGY }, 5].min
    du.set_expected_ai_damage(20 * n, 20 * n, 20 * n); false
  end

  #----------------------------------------------------------------------------
  # Energy
  #----------------------------------------------------------------------------
  # Fire Stream: discard a Fire Energy card, 10 to each of the opponent's Benched Pokémon
  effect(:AdvFireStream_CheckEffect) do |du|
    du.neo_fire_attached(du.turn_duelist, PLAY_AREA_ARENA).empty? ? _INTL("Not enough Fire Energy attached.") : false
  end
  effect(:AdvFireStreamEffect) do |du|
    du.adv_discard_own(1, :AdvDiscardEnergy) { |_, id| id == :FIRE_ENERGY }
    du.neo_alive_bench(du.non_turn_duelist).each { |e| du.neo_damage_opponent_slot(e, 10) }
    false
  end
  # Fire Spin: discard 2 basic Energy cards
  effect(:AdvFireSpin_CheckEffect) do |du|
    d = du.turn_duelist
    d.energy_cards_in_slot(PLAY_AREA_ARENA).count { |i| d.card(i).basic_energy? } >= 2 ? false : _INTL("Needs 2 basic Energy cards attached.")
  end
  effect(:AdvFireSpinEffect) { |du| du.adv_discard_own(2, :AdvDiscardEnergy) { |c, _| c.basic_energy? }; false }
  # Critical Move: discard a basic Energy card; Slaking can't attack next turn
  effect(:AdvCriticalMove_CheckEffect) do |du|
    d = du.turn_duelist
    d.energy_cards_in_slot(PLAY_AREA_ARENA).any? { |i| d.card(i).basic_energy? } ? false : _INTL("Needs a basic Energy card attached.")
  end
  effect(:AdvCriticalMoveEffect) do |du|
    du.adv_discard_own(1, :AdvDiscardEnergy) { |c, _| c.basic_energy? }
    EffectFunctions[:Neo3NoAttackNextTurnEffect].call(du)
  end
  # Mist Ball: discard a Fire and a Water Energy
  effect(:AdvMistBall_CheckEffect) do |du|
    d = du.turn_duelist
    [:FIRE_ENERGY, :WATER_ENERGY].all? { |id| !du.neo3_attached(d, PLAY_AREA_ARENA, id).empty? } ? false :
      _INTL("Needs a Fire and a Water Energy card attached.")
  end
  effect(:AdvMistBallEffect) do |du|
    d = du.turn_duelist
    [:FIRE_ENERGY, :WATER_ENERGY].each { |id| (i = du.neo3_attached(d, PLAY_AREA_ARENA, id).first) && d.put_card_in_discard_pile(i) }
    du.ui.message(_INTL("A Fire and a Water Energy card were discarded."))
    du.ui.refresh(du); false
  end
  # Luster Purge: discard 3 Energy
  effect(:AdvLusterPurge_CheckEffect) do |du|
    du.adv_energy_count(du.turn_duelist, PLAY_AREA_ARENA) >= 3 ? false : _INTL("Needs 3 Energy cards attached.")
  end
  effect(:AdvLusterPurgeEffect) { |du| du.adv_discard_own(3, :AdvDiscardEnergy); false }
  # Air Slash: tails, discard an Energy card
  effect(:AdvAirSlashEffect) do |du|
    du.coin_check(_INTL("If Tails, discard an Energy card attached to {1}.", du.turn_duelist.card(du.turn_duelist.arena).name),
                  "If Tails, discard\n1 Energy card.")
    du.adv_discard_own(1, :AdvDiscardEnergy) if du.toss_coin == TAILS
    false
  end
  # Thrust: tails nothing; heads, discard an Energy from the Defending Pokémon
  effect(:AdvThrust_CoinEffect) do |du|
    du.coin_check(_INTL("If Tails, this attack does nothing. If Heads, discard an Energy card from the Defending Pokémon."),
                  NEO_COIN_TEXT[:AdvThrust_CoinEffect])
    if du.toss_coin == HEADS
      du.atk.temp[:adv_thrust] = true
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:AdvThrust_DiscardEffect) do |du|
    du.adv_discard_opponent_energy(PLAY_AREA_ARENA, :AdvDiscardEnergy) if du.atk.temp[:adv_thrust]; false
  end
  # Hyper Beam: heads, discard an Energy from the Defending Pokémon
  effect(:AdvHyperBeamCoinEffect) do |du|
    du.coin_check(_INTL("If Heads, discard an Energy card from the Defending Pokémon."), NEO_COIN_TEXT[:AdvHyperBeamCoinEffect])
    du.adv_discard_opponent_energy(PLAY_AREA_ARENA, :AdvDiscardEnergy) if du.toss_coin == HEADS
    false
  end
  # Hydro Reverse: basic Water Energy from your Pokémon to the hand, +10 each
  effect(:AdvHydroReverseEffect) do |du|
    d = du.turn_duelist
    list = (0...d.num_in_play_area).flat_map { |e| d.cards_in_slot(e).select { |i| d.card_id(i) == :WATER_ENERGY } }
    picked = []
    if du.neo_human_choice?
      until list.empty?
        sel = du.effect_choice(:card, :AdvHydroReverse, list, true)
        break unless list.include?(sel)
        picked << list.delete(sel)
      end
    else
      # the AI returns the Energy its Active doesn't need (on the Bench)
      picked = list.reject { |i| (d.card_locations[i] & 0x0f) == PLAY_AREA_ARENA }
    end
    picked.each { |i| d.card_locations[i] = CARD_LOCATION_HAND; d.hand.push(i) }
    du.ui.message(_INTL("{1} Water Energy card(s) went back to the hand.", picked.size)) unless picked.empty?
    du.atk.damage += 10 * picked.size
    du.ui.refresh(du); false
  end
  effect(:AdvHydroReverse_AIEffect) do |du|
    d = du.turn_duelist
    n = (1...d.num_in_play_area).sum { |e| d.cards_in_slot(e).count { |i| d.card_id(i) == :WATER_ENERGY } }
    b = du.atk.attack.damage + 10 * n
    du.set_expected_ai_damage(b, b, b); false
  end
  # Growth Spurt: a Grass Energy from the hand to Shroomish; Speed Growth: up
  # to 2 Grass Energy from the hand to your Pokémon
  effect(:AdvGrowthSpurt_CheckEffect) do |du|
    d = du.turn_duelist
    d.hand.any? { |i| d.card_id(i) == :GRASS_ENERGY } ? false : _INTL("There are no Grass Energy cards in your hand.")
  end
  effect(:AdvGrowthSpurtEffect) do |du|
    d = du.turn_duelist
    i = d.hand.find { |k| d.card_id(k) == :GRASS_ENERGY }
    if i && d.slot_hp[PLAY_AREA_ARENA] > 0
      d.put_hand_card_in_play_area(i, PLAY_AREA_ARENA)
      du.ui.message(_INTL("A Grass Energy card was attached to {1}.", d.card(d.arena).name))
    end
    du.ui.refresh(du); false
  end
  effect(:AdvSpeedGrowthEffect) do |du|
    d = du.turn_duelist
    2.times do
      list = d.hand.select { |k| d.card_id(k) == :GRASS_ENERGY }
      break if list.empty?
      slots = (0...d.num_in_play_area).select { |e| d.slot_hp[e] > 0 }
      if du.neo_human_choice?
        i = du.effect_choice(:card, :AdvAttachGrass, list, true)
        break unless list.include?(i)
        e = du.effect_choice(:play_area, :AdvAttachGrass, slots, false)
        e = PLAY_AREA_ARENA unless slots.include?(e)
      else
        i, e = list.first, PLAY_AREA_ARENA
      end
      d.put_hand_card_in_play_area(i, e)
      du.ui.message(_INTL("A Grass Energy card was attached to {1}.", d.card(d.play_area[e]).name))
    end
    du.ui.refresh(du); false
  end
  # Latios: heads, a basic Energy from the deck to Latios
  effect(:AdvEnergyDrawAttackEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("If Heads, attach a basic Energy card from your deck to {1}.", d.card(d.arena).name),
                  NEO_COIN_TEXT[:AdvEnergyDrawAttackEffect])
    next false unless du.toss_coin == HEADS
    list = d.deck_list.select { |i| d.card(i).basic_energy? }
    if list.empty?
      du.ui.message(_INTL("There are no basic Energy cards in the deck."))
    else
      i = du.neo_human_choice? ? du.effect_choice(:card, :NeoEnergySearch, list, false) : nil
      i = list.first unless list.include?(i)
      du.neo_attach_from_deck(i, PLAY_AREA_ARENA)
      du.ui.message(_INTL("{1} was attached to {2}.", d.card(i).name, d.card(d.arena).name))
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  # Power Generation: up to 2 basic Energy cards from the discard pile to the hand
  effect(:AdvPowerGeneration_CheckEffect) do |du|
    d = du.turn_duelist
    d.discard_pile.any? { |i| d.card(i).basic_energy? } ? false : _INTL("There are no basic Energy cards in your discard pile.")
  end
  effect(:AdvPowerGenerationEffect) do |du|
    d = du.turn_duelist
    got = 0
    2.times do
      list = d.discard_pile.select { |i| d.card(i).basic_energy? }
      break if list.empty?
      i = du.neo_human_choice? ? du.effect_choice(:card, :AdvFromDiscard, list, got > 0) : list.first
      break unless list.include?(i)
      d.move_discard_pile_card_to_hand(i)
      d.add_card_to_hand(i)
      got += 1
    end
    du.ui.message(_INTL("{1} basic Energy card(s) were put into the hand.", got)) if got > 0
    du.ui.refresh(du); false
  end
  # Quick Charge: up to 3 basic Energy cards of different types from the deck
  effect(:AdvQuickChargeEffect) do |du|
    d = du.turn_duelist
    got = []
    3.times do
      list = d.deck_list.select { |i| d.card(i).basic_energy? && !got.include?(d.card_id(i)) }
      break if list.empty?
      i = du.neo_human_choice? ? du.effect_choice(:card, :NeoEnergySearch, list, true) : list.first
      break unless list.include?(i)
      du.adv_deck_to_hand(i)
      got << d.card_id(i)
    end
    du.ui.message(_INTL("{1} basic Energy card(s) were put into the hand.", got.size)) unless got.empty?
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  # The Third Eye: discard an Energy card from Jirachi, draw 3
  effect(:AdvThirdEye_CheckEffect) do |du|
    du.adv_energy_count(du.turn_duelist, PLAY_AREA_ARENA) > 0 ? false : _INTL("No Energy cards attached.")
  end
  effect(:AdvThirdEyeEffect) do |du|
    du.adv_discard_own(1, :AdvDiscardEnergy)
    du.adv_draw(3); false
  end
  # Fruition: move an Energy card from Tropius to another of your Pokémon,
  # remove 4 damage counters from that Pokémon
  effect(:AdvFruition_CheckEffect) do |du|
    d = du.turn_duelist
    next _INTL("No Energy cards attached.") if du.adv_energy_count(d, PLAY_AREA_ARENA) == 0
    du.neo_alive_bench(d).empty? ? _INTL("There are no Benched Pokémon.") : false
  end
  effect(:AdvFruitionEffect) do |du|
    d = du.turn_duelist
    list = d.energy_cards_in_slot(PLAY_AREA_ARENA)
    slots = du.neo_alive_bench(d)
    next false if list.empty? || slots.empty? || d.slot_hp[PLAY_AREA_ARENA] == 0
    i = du.neo_human_choice? ? du.effect_choice(:card, :AdvMoveEnergy, list, false) : nil
    i = list.first unless list.include?(i)
    e = du.neo_human_choice? ? du.effect_choice(:play_area, :AdvMoveEnergy, slots, false) : nil
    e = slots.max_by { |s| du.card_damage_and_max_hp(d, s)[0] } unless slots.include?(e)
    d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e
    du.ui.message(_INTL("{1} was moved to {2}.", d.card(i).name, d.card(d.play_area[e]).name))
    du.neo4_heal(e, 40)
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Special Conditions
  #----------------------------------------------------------------------------
  effect(:AdvBurnEffect) { |du| du.queue_burn; false }
  # The Hula-la: heads, Confused; tails, both Confused
  effect(:AdvHulalaEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is now Confused. If Tails, both are now Confused."),
                  NEO_COIN_TEXT[:AdvHulalaEffect])
    tails = du.toss_coin == TAILS
    du.queue_status(PSN_DBLPSN, CONFUSED)
    du.confuse_self if tails
    false
  end
  # Dark Bind / Deadly Poison: may discard an Energy of the card's type to
  # Paralyze / Poison
  effect(:AdvDarkBindEffect) { |du| du.adv_discard_for_status(:DARKNESS_ENERGY, PARALYZED, :AdvDiscardDarknessForStatus); false }
  effect(:AdvDeadlyPoisonEffect) { |du| du.adv_discard_for_status(:GRASS_ENERGY, POISONED); false }
  # Strange Scale: an Evolved Defending Pokémon is now Confused
  effect(:AdvStrangeScaleEffect) do |du|
    nd = du.non_turn_duelist
    du.queue_status(PSN_DBLPSN, CONFUSED) if nd.arena && nd.slot_stage[PLAY_AREA_ARENA] != BASIC
    false
  end
  # Lure Poison: may switch the Defending Pokémon with a Benched one first, then Poison
  effect(:AdvLurePoisonEffect) do |du|
    nd = du.non_turn_duelist
    slots = du.neo_alive_bench(nd)
    unless slots.empty?
      if du.neo_human_choice?
        du.ui.message(_INTL("You may choose 1 of your opponent's Benched Pokémon to switch with the Defending Pokémon."))
        e = du.as_non_turn { du.effect_choice(:play_area, :AdvLure, slots, true) }
      else
        e = slots.min_by { |s| nd.slot_hp[s] }
      end
      if slots.include?(e)
        du.handle_switch_defending_pokemon(e)
        du.atk.temp_non_turn_card_id = nd.card_id(nd.arena)
      end
    end
    du.queue_status(CNF_SLP_PRZ, POISONED); false
  end
  # Healing Sound: remove 3 damage counters from your Active Pokémon (Asleep: SleepEffect)
  effect(:AdvHealingSoundEffect) { |du| du.neo4_heal(PLAY_AREA_ARENA, 30); du.ui.refresh(du); false }
  # Advanced Armor: no damage or effects from Evolved Pokémon next turn
  effect(:AdvAdvancedArmorEffect) do |du|
    d = du.turn_duelist
    du.neo_fx[:adv_armor] = [du.turn, d.arena, du.duel_turns + 1]
    du.ui.message(_INTL("{1} is protected from Evolved Pokémon during your opponent's next turn.", d.card(d.arena).name))
    false
  end

  #----------------------------------------------------------------------------
  # healing
  #----------------------------------------------------------------------------
  # Sweet Scent: remove param from 1 of your Pokémon
  effect(:AdvSweetScentEffect) do |du|
    d = du.turn_duelist
    slots = (0...d.num_in_play_area).select { |e| d.slot_hp[e] > 0 && du.card_damage_and_max_hp(d, e)[0] > 0 }
    if slots.empty?
      du.ui.message(_INTL("None of your Pokémon have damage counters."))
      next false
    end
    e = du.neo_human_choice? ? du.effect_choice(:play_area, :AdvHeal, slots, false) : nil
    e = slots.max_by { |s| du.card_damage_and_max_hp(d, s)[0] } unless slots.include?(e)
    du.neo4_heal(e, du.adv_param)
    du.ui.refresh(du); false
  end
  # Miraculous Light: remove 2 damage counters and all Special Conditions
  effect(:AdvMiraculousLightEffect) do |du|
    d = du.turn_duelist
    du.neo4_heal(PLAY_AREA_ARENA, 20)
    du.adv_cure(d)
    du.ui.refresh(du); false
  end
  # Distorted Wave: remove 3 damage counters from the Defending Pokémon first
  effect(:AdvDistortedWaveEffect) do |du|
    nd = du.non_turn_duelist
    du.neo4_heal(PLAY_AREA_ARENA, 30, nd) if nd.arena
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # deck / hand / discard pile
  #----------------------------------------------------------------------------
  # Call for Family / Call for Friend: a Basic Pokémon from the deck onto the Bench
  effect(:AdvCallForFamily_CheckEffect) { |du| du.deck_empty_text || du.no_bench_space_text }
  effect(:AdvCallForFamilyEffect) do |du|
    d = du.turn_duelist
    next false if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    list = d.deck_list.select { |i| d.card(i).basic? && !d.card(i).trainer? }
    if list.empty?
      du.ui.message(_INTL("There are no Basic Pokémon in the deck."))
    else
      i = du.neo_human_choice? ? du.effect_choice(:card, :CallForFamily, list, true) : list.max_by { |k| d.card(k).hp }
      if list.include?(i)
        du.adv_deck_to_hand(i)
        du.put_basic_pokemon_in_play_area(i)
        du.ui.message(_INTL("{1} was placed on the Bench.", d.card(i).name))
      end
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  # Ascension: the card that evolves from this one, from the deck, on it
  effect(:AdvAscension_CheckEffect) do |du|
    d = du.turn_duelist
    name = d.card(d.arena).name
    d.deck_list.any? { |i| d.card(i).pokemon? && d.card(i).preevo == name } ? false : _INTL("There is no card that evolves from it in the deck.")
  end
  effect(:AdvAscensionEffect) do |du|
    d = du.turn_duelist
    next false if d.slot_hp[PLAY_AREA_ARENA] == 0
    name = d.card(d.arena).name
    list = d.deck_list.select { |i| d.card(i).pokemon? && d.card(i).preevo == name }
    next false if list.empty?
    i = du.neo_human_choice? ? du.effect_choice(:card, :AdvAscension, list, false) : nil
    i = list.first unless list.include?(i)
    du.neo4_evolve_from_deck(i, PLAY_AREA_ARENA)
    du.shuffle_cards_in_deck; false
  end
  # Seek Out: any card from the deck
  effect(:AdvSeekOutEffect) do |du|
    d = du.turn_duelist
    du.adv_search_deck(d.deck_list, :AdvSearch, d.deck_list.max_by { |i| d.card(i).pokemon? ? d.card(i).hp.to_i : 0 })
    du.shuffle_cards_in_deck; du.ui.refresh(du); false
  end
  # Moon Guidance: a Trainer card from the deck
  effect(:AdvMoonGuidanceEffect) do |du|
    d = du.turn_duelist
    list = d.deck_list.select { |i| d.card(i).trainer? }
    du.ui.message(_INTL("There are no Trainer cards in the deck.")) if list.empty?
    du.adv_search_deck(list, :AdvSearch)
    du.shuffle_cards_in_deck; du.ui.refresh(du); false
  end
  # Fast Evolution: an Evolution card from the deck
  effect(:AdvFastEvolutionEffect) do |du|
    d = du.turn_duelist
    list = d.deck_list.select { |i| d.card(i).pokemon? && !d.card(i).basic? }
    du.ui.message(_INTL("There are no Evolution cards in the deck.")) if list.empty?
    du.adv_search_deck(list, :AdvSearch)
    du.shuffle_cards_in_deck; du.ui.refresh(du); false
  end
  # Signs of Evolution: Silcoon and Beautifly, or Cascoon and Dustox
  effect(:AdvSignsOfEvolutionEffect) do |du|
    d = du.turn_duelist
    pairs = ADV_SIGNS.map { |names| names.map { |n| d.deck_list.find { |i| d.card(i).name == n } } }
    usable = pairs.each_index.select { |k| pairs[k].any? }
    if usable.empty?
      du.ui.message(_INTL("There are no such cards in the deck."))
    else
      k = usable.first
      if du.neo_human_choice? && usable.size > 1
        first = pairs.flat_map(&:compact)
        sel = du.effect_choice(:card, :AdvSearch, first, true)
        k = pairs.index { |p| p.include?(sel) } || usable.first
      end
      pairs[k].compact.each do |i|
        du.adv_deck_to_hand(i)
        du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
      end
    end
    du.shuffle_cards_in_deck; du.ui.refresh(du); false
  end
  # Sniff Out: any card from the discard pile to the hand
  effect(:AdvSniffOut_CheckEffect) do |du|
    du.turn_duelist.discard_pile.empty? ? _INTL("There are no cards in your discard pile.") : false
  end
  effect(:AdvSniffOutEffect) do |du|
    d = du.turn_duelist
    list = d.discard_pile.dup
    next false if list.empty?
    i = du.neo_human_choice? ? du.effect_choice(:card, :AdvFromDiscard, list, false) : nil
    i = list.max_by { |k| d.card(k).pokemon? ? d.card(k).hp.to_i : (d.card(k).trainer? ? 50 : 0) } unless list.include?(i)
    d.move_discard_pile_card_to_hand(i)
    d.add_card_to_hand(i)
    du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
    du.ui.refresh(du); false
  end
  # Pull Away: 5 or more cards in the opponent's hand -> they discard down to 4
  effect(:AdvPullAwayEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.hand.size < 5
    ctrl = du.controllers[1 - du.turn]
    while nd.hand.size > 4
      i = ctrl.is_a?(PlayerController) ? du.as_non_turn { ctrl.effect_choice(du, :card, :AdvDiscardHand, nd.hand.dup, false) } : nil
      i = nd.hand.min_by { |k| nd.card(k).pokemon? ? 2 : nd.card(k).energy? ? 1 : 0 } unless nd.hand.include?(i)
      nd.remove_card_from_hand(i)
      nd.put_card_in_discard_pile(i)
    end
    du.ui.message(_INTL("Your opponent discarded down to 4 cards."))
    du.ui.refresh(du); false
  end
  # Knock Off: heads, a random card from the opponent's hand is discarded
  effect(:AdvKnockOffEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.hand.empty?
    du.coin_check(_INTL("If Heads, discard a random card from your opponent's hand."), NEO_COIN_TEXT[:AdvKnockOffEffect])
    next false unless du.toss_coin == HEADS
    i = nd.hand[TCG.rng.rand(nd.hand.size)]
    nd.remove_card_from_hand(i)
    nd.put_card_in_discard_pile(i)
    du.ui.message(_INTL("{1} was discarded from your opponent's hand.", nd.card(i).name))
    du.ui.refresh(du); false
  end
  # Surprise: a random card from the opponent's hand, looked at, shuffled in
  effect(:AdvSurpriseEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.hand.empty?
    i = nd.hand[TCG.rng.rand(nd.hand.size)]
    du.ui.message(_INTL("You chose {1}.", nd.card(i).name))
    du.neo4_shuffle_opponent_hand_card(i); false
  end
  # Mix-Up: the opponent discards the top card of the deck
  effect(:AdvMixUpEffect) do |du|
    nd = du.non_turn_duelist
    i = nd.draw_card_from_deck
    if i
      nd.put_card_in_discard_pile(i)
      du.ui.message(_INTL("{1} was discarded from the top of your opponent's deck.", nd.card(i).name))
    end
    du.ui.refresh(du); false
  end
  # Plunder: Trainer cards attached to the Defending Pokémon are discarded first
  effect(:AdvPlunderEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.arena.nil?
    list = nd.cards_in_slot(PLAY_AREA_ARENA).select { |i| nd.card(i).trainer? && i != nd.arena }
    list.each do |i|
      case nd.card_id(i)
      when :DEFENDER  then nd.slot_defender[0] = [nd.slot_defender[0] - 1, 0].max
      when :PLUSPOWER then nd.slot_pluspower[0] = [nd.slot_pluspower[0] - 1, 0].max
      end
      nd.put_card_in_discard_pile(i)
    end
    du.ui.message(_INTL("{1} Trainer card(s) were discarded from the Defending Pokémon.", list.size)) unless list.empty?
    du.ui.refresh(du); false
  end
  # Resonate: the opponent switches the Defending Pokémon
  effect(:AdvResonateEffect) { |du| du.neo_forced_switch; false }

  #----------------------------------------------------------------------------
  # Pokémon Powers (menu): once a turn, not with a Special Condition
  #----------------------------------------------------------------------------
  ADV_POWER = lambda do |du|
    r = NEO4_ONCE.call(du)
    next r if r
    d = du.turn_duelist
    du.temp(:a0) == PLAY_AREA_ARENA && (d.status != NO_STATUS || d.burned) ? _INTL("Not while affected by a Special Condition.") : false
  end

  # Firestarter: a Fire Energy from the discard pile to a Benched Pokémon
  effect(:AdvFirestarter_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    d = du.turn_duelist
    next _INTL("There are no Benched Pokémon.") if du.neo_alive_bench(d).empty?
    du.neo_fire_in_discard(d).empty? ? _INTL("There are no Fire Energy cards in your discard pile.") : false
  end
  effect(:AdvFirestarterEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    i = du.neo_fire_in_discard(d).first
    slots = du.neo_alive_bench(d)
    e = du.neo_human_choice? ? du.effect_choice(:play_area, :AdvAttach, slots, false) : nil
    e = slots.first unless slots.include?(e)
    du.neo_attach_from_discard(i, e)
    du.ui.message(_INTL("A Fire Energy card was attached to {1}.", d.card(d.play_area[e]).name))
    du.ui.refresh(du); false
  end
  # Water Call: a Water Energy card from the hand to the Active Pokémon
  effect(:AdvWaterCall_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    d = du.turn_duelist
    d.hand.any? { |i| d.card_id(i) == :WATER_ENERGY } ? false : _INTL("There are no Water Energy cards in your hand.")
  end
  effect(:AdvWaterCallEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    i = d.hand.find { |k| d.card_id(k) == :WATER_ENERGY }
    d.put_hand_card_in_play_area(i, PLAY_AREA_ARENA)
    du.ui.message(_INTL("A Water Energy card was attached to {1}.", d.card(d.arena).name))
    du.ui.refresh(du); false
  end
  # Swing Dance: draw a card
  effect(:AdvSwingDance_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    du.deck_empty_text
  end
  effect(:AdvSwingDanceEffect) { |du| TCG.neo4_power_used(du); du.adv_draw(1); false }
  # Fan Away: heads, an Energy card on the Defending Pokémon goes back to the opponent's hand
  effect(:AdvFanAway_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    nd = du.non_turn_duelist
    nd.arena && du.adv_energy_count(nd, PLAY_AREA_ARENA) > 0 ? false : _INTL("The Defending Pokémon has no Energy cards.")
  end
  effect(:AdvFanAwayEffect) do |du|
    TCG.neo4_power_used(du)
    du.coin_check(_INTL("If Heads, an Energy card on the Defending Pokémon goes back to your opponent's hand."),
                  NEO_COIN_TEXT[:AdvFanAwayEffect])
    next false unless du.toss_coin == HEADS
    nd = du.non_turn_duelist
    list = nd.energy_cards_in_slot(PLAY_AREA_ARENA)
    i = du.neo_human_choice? ? du.as_non_turn { du.effect_choice(:card, :AdvDiscardEnergy, list, false) } : nil
    i = list.first unless list.include?(i)
    nd.card_locations[i] = CARD_LOCATION_HAND
    nd.hand.push(i)
    du.ui.message(_INTL("{1} went back to your opponent's hand.", nd.card(i).name))
    du.ui.refresh(du); false
  end
  # Psy Shadow: a Psychic Energy from the deck to 1 of your Pokémon, 2 damage counters on it
  effect(:AdvPsyShadow_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    d = du.turn_duelist
    d.deck_list.any? { |i| d.card_id(i) == :PSYCHIC_ENERGY } ? false : _INTL("There are no Psychic Energy cards in the deck.")
  end
  effect(:AdvPsyShadowEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    i = d.deck_list.find { |k| d.card_id(k) == :PSYCHIC_ENERGY }
    slots = (0...d.num_in_play_area).select { |e| d.slot_hp[e] > 20 || (d.slot_hp[e] > 0 && du.neo_human_choice?) }
    slots = [PLAY_AREA_ARENA] if slots.empty?
    e = du.neo_human_choice? ? du.effect_choice(:play_area, :AdvAttach, slots, false) : nil
    e = slots.max_by { |s| d.slot_hp[s] } unless slots.include?(e)
    du.neo_attach_from_deck(i, e)
    name = d.card(d.play_area[e]).name
    du.ui.message(_INTL("A Psychic Energy card was attached to {1}.", name))
    du.neo3_damage_own(e, 20)
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  # Energy Draw: discard an Energy card from the hand, then draw up to 3
  effect(:AdvEnergyDrawPower_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    d = du.turn_duelist
    d.hand.any? { |i| d.card(i).energy? } ? false : _INTL("There are no Energy cards in your hand.")
  end
  effect(:AdvEnergyDrawPowerEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    list = d.hand.select { |i| d.card(i).energy? }
    i = du.neo_human_choice? ? du.effect_choice(:card, :AdvDiscardHand, list, false) : nil
    i = list.first unless list.include?(i)
    d.remove_card_from_hand(i)
    d.put_card_in_discard_pile(i)
    du.ui.message(_INTL("{1} was discarded.", d.card(i).name))
    du.adv_draw(3); false
  end
  # Night Vision: look at the opponent's hand (Active only)
  effect(:AdvNightVision_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    next _INTL("Only while it's your Active Pokémon.") unless du.temp(:a0) == PLAY_AREA_ARENA
    du.non_turn_duelist.hand.empty? ? _INTL("Your opponent has no cards in hand.") : false
  end
  effect(:AdvNightVisionEffect) { |du| TCG.neo4_power_used(du); du.neo4_look_at_opponent_hand(:NeoScout); false }
  # Terraforming: look at the top 5 cards of your deck and put them back in any order
  effect(:AdvTerraforming_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    du.deck_empty_text
  end
  effect(:AdvTerraformingEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    top = d.deck_list.first(5)
    order = []
    if du.neo_human_choice?
      du.ui.message(_INTL("Choose the cards in the order you want them on top of your deck."))
      left = top.dup
      while left.size > 1
        i = du.effect_choice(:card, :AdvOrder, left, false)
        i = left.first unless left.include?(i)
        order << left.delete(i)
      end
      order += left
    else
      # the AI keeps its Pokémon and Energy first
      order = top.sort_by { |i| d.card(i).pokemon? ? 0 : d.card(i).energy? ? 1 : 2 }
    end
    d.deck_cards[d.not_in_deck, order.size] = order
    du.ui.message(_INTL("The top {1} cards of the deck were put back in order.", order.size))
    du.ui.refresh(du); false
  end
  # Solar Eclipse: with Lunatone in play, Solrock is Fire this turn
  effect(:AdvSolarEclipse_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    du.duelists.any? { |x| du.neo3_in_play?(x, :LUNATONE) } ? false : _INTL("Lunatone isn't in play.")
  end
  effect(:AdvSolarEclipseEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    e = du.temp(:a0) || PLAY_AREA_ARENA
    d.slot_changed_type[e] = HAS_CHANGED_COLOR | FIRE
    du.neo_fx[:adv_eclipse] = [du.turn, d.play_area[e], du.duel_turns]
    du.ui.message(_INTL("Solrock is a Fire Pokémon this turn."))
    du.ui.refresh(du); false
  end
  # Dragon Wind: switch 1 of the opponent's Benched Pokémon with the Defending Pokémon
  effect(:AdvDragonWind_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    next _INTL("Only while it's your Active Pokémon.") unless du.temp(:a0) == PLAY_AREA_ARENA
    du.neo_alive_bench(du.non_turn_duelist).empty? ? _INTL("Your opponent has no Benched Pokémon.") : false
  end
  effect(:AdvDragonWindEffect) do |du|
    TCG.neo4_power_used(du)
    e = du.neo_pick_opponent_bench(:AdvLure)
    if e
      du.as_non_turn { du.turn_duelist.swap_arena_with_bench_pokemon(e) }
      nd = du.non_turn_duelist
      du.ui.message(_INTL("{1} is now the Defending Pokémon.", nd.card(nd.arena).name))
    end
    du.ui.refresh(du); false
  end
  # Super Connectivity: a Psychic or Metal Energy from the discard pile to the
  # Active (a player with both picks; the AI takes Psychic), 1 damage counter on it
  SUPER_CONNECTIVITY_ENERGY = [:PSYCHIC_ENERGY, :METAL_ENERGY]
  effect(:AdvSuperConnectivity_CheckUse) do |du|
    r = ADV_POWER.call(du)
    next r if r
    d = du.turn_duelist
    d.discard_pile.any? { |i| SUPER_CONNECTIVITY_ENERGY.include?(d.card_id(i)) } ? false : _INTL("There are no Psychic or Metal Energy cards in your discard pile.")
  end
  effect(:AdvSuperConnectivityEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    have = SUPER_CONNECTIVITY_ENERGY.select { |id| d.discard_pile.any? { |k| d.card_id(k) == id } }
    want = have.first
    if have.size > 1 && du.neo_human_choice?
      want = du.effect_choice(:yes_no, :AdvSuperConnectivityMetal, [true, false], false) ? :METAL_ENERGY : :PSYCHIC_ENERGY
    end
    i = d.discard_pile.find { |k| d.card_id(k) == want }
    du.neo_attach_from_discard(i, PLAY_AREA_ARENA)
    du.ui.message(_INTL("{1} was attached to {2}.", d.card(i).name, d.card(d.arena).name))
    du.neo3_damage_own(PLAY_AREA_ARENA, 10)
    du.ui.refresh(du); false
  end
  # Healing Shower (played to evolve): remove all damage counters from every Pokémon
  effect(:AdvHealingShowerEffect) do |du|
    d = du.turn_duelist
    ctrl = du.controllers[du.turn]
    use = if ctrl.is_a?(PlayerController)
            ctrl.effect_choice(du, :yes_no, :AdvHealingShower, [true, false], false)
          else
            own = (0...d.num_in_play_area).sum { |e| du.card_damage_and_max_hp(d, e)[0] }
            nd = du.non_turn_duelist
            opp = (0...nd.num_in_play_area).sum { |e| du.card_damage_and_max_hp(nd, e)[0] }
            own > opp
          end
    next false unless use
    du.duelists.each do |x|
      (0...x.num_in_play_area).each { |e| x.slot_hp[e] = du.card_damage_and_max_hp(x, e)[1] if x.slot_hp[e] > 0 }
    end
    du.ui.message(_INTL("All damage counters were removed from every Pokémon."))
    du.ui.refresh(du); false
  end

  class Duel
    # the turn holder draws n cards
    def adv_draw(n)
      d = turn_duelist
      display_draw_n_cards(d, n, _INTL("Draw {1} card(s).", n))
      got = 0
      n.times do
        i = d.draw_card_from_deck or break
        d.add_card_to_hand(i)
        got += 1
      end
      @ui.message(_INTL("There are no cards left in the Deck.")) if got < n
      @ui.refresh(self)
      got
    end

    # Dark Bind / Deadly Poison: the attacker may discard an Energy (`id`)
    # from its Active to give the Defending Pokémon `status`
    def adv_discard_for_status(id, status, prompt = :AdvDiscardForStatus)
      d = turn_duelist
      list = d.energy_cards_in_slot(PLAY_AREA_ARENA).select { |i| d.card_id(i) == id }
      return if list.empty? || non_turn_duelist.arena.nil? || non_turn_duelist.slot_hp[PLAY_AREA_ARENA] == 0
      use = neo_human_choice? ? effect_choice(:yes_no, prompt, [true, false], false) : list.size > 1
      return unless use
      d.put_card_in_discard_pile(list.first)
      @ui.message(_INTL("{1} was discarded.", d.card(list.first).name))
      queue_status(status == POISONED ? CNF_SLP_PRZ : PSN_DBLPSN, status)
      @ui.refresh(self)
    end
  end
end
