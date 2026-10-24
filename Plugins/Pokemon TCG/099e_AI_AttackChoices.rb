#==============================================================================
# Pokemon TCG - AI choices inside its own attacks. Port of core.asm
# AITryUseAttack: AISelectSpecialAttackParameters (Mew Lv23, Mewtwo Lv60s,
# Exeggutor, Electrode Lv35) or else the attack's EFFECTCMDTYPE_AI_SELECTION
# function. The original writes hTemp* variables the effects read; here the
# same answers are preset as @ai_choices for the engine's selection prompts.
#==============================================================================
module TCG
  class AIController
    # replaces the plain duel.use_attack in AIProcessAndTryToUseAttack
    def ai_use_attack(duel, ai)
      d = duel.turn_duelist
      @ai_choices = attack_ai_choices(duel, d.arena, ai)
      duel.use_attack(d.arena, ai)
    ensure
      @ai_choices = nil
    end

    def attack_ai_choices(duel, idx, ai)
      d = duel.turn_duelist
      special = ai_special_attack_parameters(duel, d, idx, ai)
      return special if special
      atk = d.card(idx).attacks[ai] or return {}
      cmds = EFFECT_TABLE[atk.effect] || []
      fn = cmds.find { |p, _| p == EFFECT_AI_SELECTION }&.last
      fn ? (ai_selection_choices(duel, d, fn) || {}) : {}
    end

    #--------------------------------------------------------------------------
    # AISelectSpecialAttackParameters (carry = handled, AI_SELECTION skipped)
    #--------------------------------------------------------------------------
    def ai_special_attack_parameters(duel, d, idx, ai)
      case d.card_id(idx)
      when :MEW_LV23        # Devolution Beam on the player's side
        return nil if ai == 0
        { :DevolutionBeamSide => 1, :DevolutionBeam => (ko_on_devolution_slot(duel) || 0) }
      when :MEWTWO_ALT_LV60, :MEWTWO_LV60   # Energy Absorption
        return nil if ai != 0
        psy = card_id_in_location(d, :PSYCHIC_ENERGY, CARD_LOCATION_DISCARD_PILE)
        other = duel.energy_card_list_from_discard_pile(false).find { |i| i != psy }
        { :EnergyAbsorption => [psy, other].compact }
      when :EXEGGUTOR       # Teleport
        return nil if ai != 0
        e = decide_bench_pokemon_to_switch_to(duel) or return nil
        { :Teleport => e }
      when :ELECTRODE_LV35  # Energy Spike
        return nil if ai == 0
        en = card_id_in_location(d, :LIGHTNING_ENERGY, CARD_LOCATION_DECK) or return nil
        t = process_and_try_to_play_energy(duel, AI_ENERGY_FLAG_DONT_PLAY | AI_ENERGY_FLAG_SKIP_EVOLUTION) or return nil
        { :EnergySpike => en, :EnergySpikeTarget => t }
      end
    end

    # LookForCardThatIsKnockedOutOnDevolution (player's play area)
    def ko_on_devolution_slot(duel)
      duel.as_non_turn do
        d = duel.turn_duelist
        (0...d.num_in_play_area).find do |e|
          below = duel.card_one_stage_below(d, e) or next false
          d.card(below[0]).hp <= duel.card_damage_and_max_hp(d, e)[0]
        end
      end
    end

    #--------------------------------------------------------------------------
    # EFFECTCMDTYPE_AI_SELECTION functions
    #--------------------------------------------------------------------------
    FIRE_DISCARD_AI = %i[ArcanineFlamethrower CharmeleonFlamethrower FlareonFlamethrower
                         MagmarFlamethrower Ember FireBlast]

    def ai_selection_choices(duel, d, fn)
      name = fn.to_s.sub(/_AISelect(ion|Effect)\z/, "")
      if FIRE_DISCARD_AI.include?(name.to_sym)
        return { :"#{name}_PlayerSelectEffect" => duel.list_of_fire_energy_attached_to_arena.first }
      end
      case fn
      when :FlamesOfRage_AISelectEffect
        { :FlamesOfRage => duel.list_of_fire_energy_attached_to_arena.first(2) }
      when :FireSpin_AISelectEffect
        { :FireSpin => d.energy_cards_in_slot(PLAY_AREA_ARENA).first(2) }
      when :Wildfire_AISelectEffect
        { :Wildfire => [] }                       # discards no Fire Energy
      when :Barrier_AISelectEffect, :KadabraRecover_AISelectEffect, :DestinyBond_AISelectEffect
        { :DiscardPsychic => psychic_on_arena(duel) }
      when :Scavenge_AISelectEffect
        { :DiscardPsychic => psychic_on_arena(duel), :Scavenge => duel.trainer_card_list_from_discard_pile.first }
      when :StarmieRecover_AISelectEffect
        { :DiscardWater => duel.list_of_energy_attached_to_arena(TYPE_NAMES["TYPE_ENERGY_WATER"]).first }
      when :DragonairHyperBeam_AISelectEffect, :GolduckHyperBeam_AISelectEffect
        { :HyperBeam => energy_to_discard_from_defending(duel) }
      when :Whirlpool_AISelectEffect
        { :Whirlpool => energy_to_discard_from_defending(duel) }
      when :PidgeottoMirrorMove_AISelection, :SpearowMirrorMove_AISelection
        d.last_turn_effect == LAST_TURN_EFFECT_DISCARD_ENERGY ? { :MirrorMove => energy_to_discard_from_defending(duel) } : {}
      when :PoliwhirlAmnesia_AISelectEffect, :SlowpokeAmnesia_AISelectEffect
        { :Amnesia => [attack_for_amnesia(duel)] }   # one [card, attack] answer
      when :NinetalesLure_AISelectEffect, :VictreebelLure_GetBenchPokemonWithLowestHP
        { :Lure => lowest_hp_player_bench(duel) }
      when :StretchKick_AISelectEffect
        { :StretchKick => lowest_hp_player_bench(duel) }
      when :GengarDarkMind_AISelectEffect, :HypnoDarkMind_AISelectEffect
        { :DarkMind => lowest_hp_player_bench(duel) }
      when :Spark_AISelectEffect
        { :Spark => lowest_hp_player_bench(duel) }
      when :Teleport_AISelectEffect
        # ORIGINAL: Random(play area size) may pick 0 (the Active itself)
        { :Teleport => rand(d.num_in_play_area) }
      when :Sprout_AISelectEffect
        { :Sprout => d.deck_list.find { |i| d.card_id(i) == :ODDISH } || :none }
      when :BellsproutCallForFamily_AISelectEffect
        { :CallForFamily => d.deck_list.find { |i| d.card_id(i) == :BELLSPROUT } || :none }
      when :KrabbyCallForFamily_AISelectEffect
        { :CallForFamily => d.deck_list.find { |i| d.card_id(i) == :KRABBY } || :none }
      when :NidoranFCallForFamily_AISelectEffect
        { :CallForFamily => d.deck_list.find { |i| [:NIDORANF, :NIDORANM].include?(d.card_id(i)) } || :none }
      when :MarowakCallForFamily_AISelectEffect
        { :CallForFamily => d.deck_list.find { |i| d.card(i).type == FIGHTING && d.card(i).stage == BASIC } || :none }
      when :EnergyConversion_AISelectEffect
        { :EnergyConversion => duel.energy_card_list_from_discard_pile(false).first(2) }
      when :MewtwoEnergyAbsorption_AISelectEffect, :MewtwoAltEnergyAbsorption_AISelectEffect
        { :EnergyAbsorption => duel.energy_card_list_from_discard_pile(false).first(2) }
      when :Conversion1_AISelectEffect
        { :Conversion1 => conversion_color(duel) }
      when :Conversion2_AISelectEffect
        nd = duel.non_turn_duelist
        t = nd.card(nd.arena).type
        { :Conversion2 => (t == COLORLESS ? duel.as_non_turn { conversion_color(duel) } : t & 0x07) }
      when :DevolutionBeam_AISelectEffect
        side = 1
        slot = duel.as_non_turn { first_non_basic_slot(duel.turn_duelist) }
        if slot.nil?
          side = 0
          slot = first_non_basic_slot(d)
        end
        { :DevolutionBeamSide => side, :DevolutionBeam => slot }
      when :Gigashock_AISelectEffect
        { :Gigashock => gigashock_targets(duel) }
      when :EnergySpike_AISelectEffect
        { :EnergySpike => :none }                 # $ff: takes nothing
      when :Prophecy_AISelectEffect
        { :ProphecyDeck => 0 }                    # $ff: leaves its deck as is
      end
    end

    def psychic_on_arena(duel)
      duel.list_of_energy_attached_to_arena(TYPE_NAMES["TYPE_ENERGY_PSYCHIC"]).first
    end

    # AIFindTargetForBenchAttack: lowest-HP player bench card (ties -> later)
    def lowest_hp_player_bench(duel)
      nd = duel.non_turn_duelist
      best = 255; slot = nil
      (1...nd.num_in_play_area).each { |e| (best = nd.slot_hp[e]; slot = e) if nd.slot_hp[e] <= best }
      slot
    end

    # FindFirstNonBasicCardInPlayArea
    def first_non_basic_slot(x)
      (0...x.num_in_play_area).find { |e| x.slot_stage[e] != BASIC }
    end

    # AIPickEnergyCardToDiscardFromDefendingPokemon
    def energy_to_discard_from_defending(duel)
      duel.as_non_turn do
        x = duel.turn_duelist
        list = x.energy_cards_in_slot(PLAY_AREA_ARENA)
        next nil if list.empty?
        en, = x.attached_energies(PLAY_AREA_ARENA)
        want = nil
        if en[COLORLESS] != 0
          want = COLORLESS
        else
          t = x.card(x.arena).type
          want = t if t < COLORLESS && en[t] != 0
        end
        pick = want && list.find { |i| (x.card(i).type & 0x07) == want }
        pick || list.sample
      end
    end

    # AIPickAttackForAmnesia: the player's 2nd attack if it has the energy for
    # it, else the 1st (2nd if the 1st is a Pokemon Power) -> [card, attack]
    def attack_for_amnesia(duel)
      nd = duel.non_turn_duelist
      c = nd.card(nd.arena)
      ai = if duel.as_non_turn { duel.enough_energies_for_attack?(nd, nd.arena, 1) } then 1
           elsif c.attacks[0]&.pokemon_power? then 1
           else 0
           end
      [nd.arena, ai]
    end

    # AISelectConversionColor (turn holder's play area)
    def conversion_color(duel)
      x = duel.turn_duelist
      (0...x.num_in_play_area).each do |e|
        c = x.card(x.play_area[e])
        next if c.type == COLORLESS
        if [0, 1].any? { |ai| c.attacks[ai] && duel.enough_energies_for_attack?(x, x.play_area[e], ai) }
          return c.type & 0x07
        end
      end
      (0...x.num_in_play_area).each do |e|
        c = x.card(x.play_area[e])
        next if x.attached_energies(e)[1] == 0
        return c.type & 0x07 if c.type != COLORLESS
      end
      rand(NUM_COLORED_TYPES)
    end

    # Gigashock: every bench card if <= 3 benched, else the 3 with most HP
    def gigashock_targets(duel)
      nd = duel.non_turn_duelist
      bench = (1...nd.num_in_play_area).to_a
      return bench if nd.num_in_play_area < MAX_PLAY_AREA_POKEMON - 1
      list = bench.dup
      list.each_index do |o|
        ((o + 1)...list.size).each do |i|
          next if nd.slot_hp[list[i]] < nd.slot_hp[list[o]]
          list[o], list[i] = list[i], list[o]
        end
      end
      list.first(3)
    end
  end
end
