#==============================================================================
# Pokemon TCG - AI special attack handling. Port of
# engine/duel/ai/special_attacks.asm HandleSpecialAIAttacks (+ helpers from
# core.asm: LookForCardThatIsKnockedOutOnDevolution,
# CountNumberOfSetUpBenchPokemon, CheckForEvolutionInList).
# Returns $80 + bonus (encourage) / below $80 (discourage); 0 dismisses.
#==============================================================================
module TCG
  class AIController
    def bench_slots_free(d, max)
      d.num_in_play_area >= max ? nil : max - d.num_in_play_area
    end

    def deck_has_card_id?(d, *ids)
      (0...d.deck_size).any? { |i| d.card_locations[i] == CARD_LOCATION_DECK && ids.include?(d.card_id(i)) }
    end

    def handle_special_ai_attacks(duel, ai)
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      case d.card_id(d.arena)
      when :ODDISH, :BELLSPROUT, :KRABBY
        id = d.card_id(d.arena)
        return 0 unless deck_has_card_id?(d, id)
        (s = bench_slots_free(d, MAX_BENCH_POKEMON)) ? 0x80 + s : 0
      when :NIDORANF
        return 0 unless deck_has_card_id?(d, :NIDORANM, :NIDORANF)
        (s = bench_slots_free(d, MAX_PLAY_AREA_POKEMON)) ? 0x80 + s : 0
      when :MAROWAK_LV26
        return 0 unless deck_has_card_id?(d, :GEODUDE, :ONIX, :CUBONE, :RHYHORN)
        (s = bench_slots_free(d, MAX_BENCH_POKEMON)) ? 0x80 + s : 0
      when :JIGGLYPUFF_LV13
        return 0 unless d.deck_list.any? { |i| d.card(i).basic? }
        (s = bench_slots_free(d, MAX_PLAY_AREA_POKEMON)) ? 0x80 + s : 0
      when :EXEGGUTOR
        decide_whether_to_retreat(duel) ? 0x8a : 0
      when :SCYTHER, :VAPOREON_LV29
        return 0x85 if @cannot_damage || attack_unusable?(duel, PLAY_AREA_ARENA, 1)
        dmg, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, 1)
        dmg == 0 ? 0x85 : 0
      when :ELECTRODE_LV42
        col = duel.as_non_turn { duel.play_area_card_color(duel.turn_duelist, PLAY_AREA_ARENA) }
        d.bench.any? { |i| d.card(i).type == col } ? 0 : 0x82
      when :MEW_LV23
        knocked_out_on_devolution(duel) ? 0x85 : 0
      when :PORYGON
        return 0 if (d.status & CNF_SLP_PRZ) == CONFUSED
        n = count_set_up_bench_pokemon(duel)
        if ai == 0
          n < 2 ? 0x81 : 0x82
        else
          n >= 2 ? 0x81 : 0x82
        end
      when :MEWTWO_ALT_LV60, :MEWTWO_LV60
        (0...d.deck_size).any? { |i| d.card_locations[i] == CARD_LOCATION_DISCARD_PILE && d.card_id(i) == :PSYCHIC_ENERGY } ? 0x82 : 0
      when :NINETALES_LV35 then mix_up_score(duel, nd)
      when :ZAPDOS_LV68 then 0x83
      when :KANGASKHAN then d.not_in_deck >= 41 ? 0 : 0x80
      when :DUGTRIO
        # ORIGINAL BUGS (hl clobbered + own prizes counted): the loop runs on
        # through unrelated duel variables, so with any benched Pokemon the
        # count always exceeds the prizes -> only used with an empty bench.
        d.bench.empty? ? 0x80 : 0
      when :ELECTRODE_LV35
        return 0 unless deck_has_card_id?(d, :LIGHTNING_ENERGY)
        energy_would_be_useful_somewhere?(duel) ? 0x83 : 0
      when :GOLDUCK, :DRAGONAIR
        nd.energy_cards_in_slot(PLAY_AREA_ARENA).empty? ? 0x80 : 0x83
      else
        0
      end
    end

    # LookForCardThatIsKnockedOutOnDevolution (opponent's play area)
    def knocked_out_on_devolution(duel)
      duel.as_non_turn do
        d = duel.turn_duelist
        (0...d.num_in_play_area).any? do |e|
          below = duel.card_one_stage_below(d, e)
          next false unless below
          d.card(below[0]).hp <= duel.card_damage_and_max_hp(d, e)[0]
        end
      end
    end

    # CountNumberOfSetUpBenchPokemon
    def count_set_up_bench_pokemon(duel)
      d = duel.turn_duelist
      (1...d.num_in_play_area).count do |e|
        c = d.card(d.play_area[e])
        next false if (c.hp >> 1) >= d.slot_hp[e]
        if c.ai_info&.include?("HAS_EVOLUTION")
          next false if evolution_in_hand_or_deck?(d, c)
        end
        !attack_unusable?(duel, e, 1)
      end
    end

    def evolution_in_hand_or_deck?(d, c)
      (0...d.deck_size).any? do |i|
        loc = d.card_locations[i]
        (loc == CARD_LOCATION_DECK || loc == CARD_LOCATION_HAND) && d.card(i).preevo == c.name
      end
    end

    # Mix Up: 1/3 encourage, 1/3 neutral... (see asm)
    def mix_up_score(duel, nd)
      return 0 if nd.hand.empty?
      r = rand(3)
      return 0x83 if r == 0
      return 0 if r == 1
      if nd.num_in_play_area < 3
        return 0x83 if nd.hand.count { |i| nd.card(i).basic? } >= 2
      end
      evo = (0...nd.num_in_play_area).any? do |e|
        nd.hand.any? { |i| nd.check_if_can_evolve_into(i, e) == :ok }
      end
      evo ? 0x83 : 0
    end

    # energy.asm AIProcessButDontPlayEnergy_SkipEvolution — TODO: real port
    def energy_would_be_useful_somewhere?(duel)
      d = duel.turn_duelist
      (0...d.num_in_play_area).any? { |e| needs_energy?(duel, d, e) }
    end
  end
end
