#==============================================================================
# Pokemon TCG - AI retreating. Port of engine/duel/ai/retreat.asm
# (AIDecideWhetherToRetreat, AIDecideBenchPokemonToSwitchTo, AITryToRetreat,
# SetAIRetreatFlags) + core.asm helpers (LoadDefendingPokemonColorWRAndPrizeCards,
# LookForEnergyNeededForAttackInHand, CheckIfArenaCardIsFullyPowered,
# FindHighestBenchScore, CheckIfEnergyIsUseful).
#==============================================================================
module TCG
  class AIController
    # LoadDefendingPokemonColorWRAndPrizeCards
    def load_defending_info(duel)
      nd = duel.non_turn_duelist
      @ai_player_color      = COLOR_TO_WR[duel.as_non_turn { duel.play_area_card_color(nd, 0) }]
      @ai_player_weakness   = duel.arena_card_weakness(nd)
      @ai_player_resistance = duel.arena_card_resistance(nd)
      @ai_player_prizes     = nd.count_prizes
      @ai_opponent_prizes   = duel.turn_duelist.count_prizes
    end

    # LookForEnergyNeededForAttackInHand (slot e, attack ai)
    def energy_needed_for_attack_in_hand?(duel, e, ai)
      d = duel.turn_duelist
      ok, b, c, id = energy_needed_for_attack(duel, e, ai)
      return false if ok
      if b + c == 1
        b == 0 ? d.hand.any? { |i| d.card(i).energy? } : d.hand.any? { |i| d.card_id(i) == id }
      elsif b + c == 2 && c == 2
        d.hand.any? { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY }
      else
        false
      end
    end

    # CheckIfArenaCardIsFullyPowered
    def arena_fully_powered?(duel)
      d = duel.turn_duelist
      c = d.card(d.arena)
      return false if (c.hp >> 1) >= d.slot_hp[0]
      return false if c.ai_info&.include?("HAS_EVOLUTION") && card_evolution_in_hand_or_deck(d, d.arena)
      !attack_unusable?(duel, PLAY_AREA_ARENA, 1)
    end

    # slot e's attack ai can KO and is usable (or the energy is in hand)
    def slot_can_ko?(duel, e, need_energy_check = true)
      ai = any_attack_knocks_out?(duel, e) or return false
      return true unless attack_unusable?(duel, e, ai)
      need_energy_check && energy_needed_for_attack_in_hand?(duel, e, ai)
    end

    #--------------------------------------------------------------------------
    # AIDecideWhetherToRetreat
    #--------------------------------------------------------------------------
    def decide_whether_to_retreat(duel)
      return false if duel.confusion_retreat_check_unsuccessful
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      return false if d.arena.nil? || nd.arena.nil?
      saved = @score
      @play_energy_for_retreat = false
      load_defending_info(duel)
      @score = 0x80
      rs = @retreat_score.to_i
      ai_encourage((rs >> 2) << 1) if rs != 0     # (asm comment says *8; code is /4*2)
      if d.status != 0
        ai_encourage(2) if (d.status & DOUBLE_POISONED) != 0
        ai_encourage(1) if (d.status & CNF_SLP_PRZ) == CONFUSED
      end
      if slot_can_ko?(duel, PLAY_AREA_ARENA)
        ai_discourage(5)
        ai_discourage(35) if @ai_opponent_prizes < 2
      end
      if defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)[0]
        ai_encourage(2)
        if apply_boss_energy_scoring?
          if @ai_player_prizes < 2
            @play_energy_for_retreat = true
            ai_encourage(2)
          end
          ai_discourage(2) if @ai_opponent_prizes < 2
        end
      elsif apply_boss_energy_scoring?
        ai_encourage(2) if @ai_player_prizes < 2
        ai_discourage(2) if @ai_opponent_prizes < 2
      end
      bench = (1...d.num_in_play_area).to_a
      my_wr = COLOR_TO_WR[duel.play_area_card_color(d, 0)]
      if (@ai_player_resistance & my_wr) != 0
        ai_encourage(1)
        ai_discourage(2) unless bench.any? { |e| (COLOR_TO_WR[d.card(d.play_area[e]).color.to_i] & @ai_player_resistance) == 0 }
      end
      if (duel.arena_card_weakness(d) & @ai_player_color) != 0
        ai_encourage(2)
        ai_discourage(3) unless bench.any? { |e| (d.card(d.play_area[e]).weakness.to_i & @ai_player_color) == 0 }
      end
      ai_discourage(3) if (duel.arena_card_resistance(d) & @ai_player_color) != 0
      # bench Pokemon of the defending Pokemon's weakness
      weak_found = bench.find { |e| (COLOR_TO_WR[d.card(d.play_area[e]).color.to_i] & @ai_player_weakness) != 0 }
      if weak_found
        ai_encourage(2)
        if d.card_id(d.arena) == :PORYGON && can_damage_defending?(duel, weak_found)
          ai_encourage(10)
        elsif (my_wr & @ai_player_weakness) != 0
          ai_discourage(3)
        end
      end
      ai_encourage(1) if bench.any? { |e| (d.card(d.play_area[e]).resistance.to_i & @ai_player_color) != 0 }
      # bench Pokemon that can KO
      if bench.any? { |e| slot_can_ko?(duel, e) }
        ai_encourage(2)
        if @ai_opponent_prizes < 2 && apply_boss_energy_scoring? && !slot_can_ko?(duel, PLAY_AREA_ARENA, false)
          ai_encourage(40)
          @play_energy_for_retreat = true
        end
      end
      if [:MR_MIME, :HITMONLEE].include?(nd.card_id(nd.arena)) && !can_damage_defending?(duel, PLAY_AREA_ARENA)
        if bench.any? { |e| can_damage_defending?(duel, e) }
          ai_encourage(5)
          @play_energy_for_retreat = true
        end
      end
      cost = duel.retreat_cost(d)
      ai_discourage(1) if cost == 2
      ai_discourage(2) if cost >= 3
      unless arena_fully_powered?(duel)
        n = count_set_up_bench_pokemon(duel)
        ai_encourage(n) if n >= 2
      end
      safe = bench.any? do |e|
        id = d.card_id(d.play_area[e])
        next false if id == :MYSTERIOUS_FOSSIL || id == :CLEFAIRY_DOLL
        !defending_pokemon_can_knock_out(duel, e)[0]
      end
      ai_discourage(20) unless safe
      result =
        if [:MYSTERIOUS_FOSSIL, :CLEFAIRY_DOLL].include?(d.card_id(d.arena))
          bench.any? { |e| !defending_pokemon_can_knock_out(duel, e)[0] && can_damage_defending?(duel, e) }
        else
          @score >= 131
        end
      @score = saved
      result
    end

    #--------------------------------------------------------------------------
    # AIDecideBenchPokemonToSwitchTo — slot or nil
    #--------------------------------------------------------------------------
    def decide_bench_pokemon_to_switch_to(duel)
      d = duel.turn_duelist
      return nil if d.num_in_play_area < 2
      saved = @score
      # SetAIRetreatFlags
      flags = (duel.whose_turn == duel.turn && @tried_attack) ? 0 : 0x80
      if duel.whose_turn != duel.turn
        flags = (duel.atk && duel.atk.pokemon_power?) ? 0 : 0x80
      end
      load_defending_info(duel)
      nd = duel.non_turn_duelist
      scores = { 0 => 50 }
      (1...d.num_in_play_area).each do |e|
        @score = 50
        f = flags
        if (ai = any_attack_knocks_out?(duel, e)) && !attack_unusable?(duel, e, ai)
          ai_encourage(10)
          f |= 0x01
          ai_encourage(10) if d.count_prizes < 2
        end
        if (f & 0x01) == 0 || d.count_prizes >= 2
          last_ai = 0
          [0, 1].each do |a|
            last_ai = a
            next if attack_unusable?(duel, e, a)
            dmg, = duel.ai_estimate_damage_versus_defending(e, a)
            ai_encourage(dmg_counters(dmg) + 1)
          end
          if energy_needed_in_hand_for_slot?(duel, e)
            dmg, = duel.ai_estimate_damage_versus_defending(e, last_ai)
            ai_encourage(dmg_counters(dmg) >> 1)
          end
          ai_discourage(1) if d.attached_energies(e)[1] == 0
          if nd.card_id(nd.arena) == :MR_MIME
            if duel.ai_estimate_damage_versus_defending(e, 0)[0] != 0 || duel.ai_estimate_damage_versus_defending(e, 1)[0] != 0
              ai_encourage(5)
            end
          end
        end
        c = d.card(d.play_area[e])
        wr = COLOR_TO_WR[c.color.to_i]
        ai_encourage(3) if (wr & @ai_player_weakness) != 0
        ai_discourage(2) if (wr & @ai_player_resistance) != 0
        ai_encourage(2) if (c.resistance.to_i & @ai_player_color) != 0
        ai_discourage(3) if (c.weakness.to_i & @ai_player_color) != 0
        rc = duel.retreat_cost(d, e)
        if rc < 2 then ai_encourage(1)
        elsif rc > 2 then ai_discourage(1)
        end
        if f != 0x81 && defending_pokemon_can_knock_out(duel, e)[0]
          ai_discourage(@ai_player_prizes == 1 ? 10 : 3)
        end
        if d.slot_hp[e] == 0
          scores[e] = 0
          next
        end
        ai_encourage(dmg_counters(d.slot_hp[e] / 4))
        id = d.card_id(d.play_area[e])
        if id == :MR_MIME || (id == :MEW_LV8 && nd.slot_stage[0] != BASIC)
          ai_encourage(5)
        end
        ai_discourage(2) if c.ai_info == ["AI_INFO_BENCH_UTILITY"]   # ORIGINAL BUG: unmasked
        ai_discourage(10) if id == :MYSTERIOUS_FOSSIL || id == :CLEFAIRY_DOLL
        if (bonus = retreat_bonus_list[id])
          bonus >= 0x80 ? ai_encourage(bonus - 0x80) : ai_discourage(0x80 - bonus)
        end
        scores[e] = @score
      end
      @retreat_score = 0
      @score = saved
      # FindHighestBenchScore (ties -> later slot)
      best = 0; slot = 0
      (1...d.num_in_play_area).each { |e| (best = scores[e]; slot = e) if scores[e] >= best }
      slot == 0 ? nil : slot
    end

    def energy_needed_in_hand_for_slot?(duel, e)
      [0, 1].any? { |ai| energy_needed_for_attack_in_hand?(duel, e, ai) }
    end

    # per-deck wAICardListRetreatBonus { card_id => score } — TODO step G
    def retreat_bonus_list; {}; end

    #--------------------------------------------------------------------------
    # AITryToRetreat
    #--------------------------------------------------------------------------
    def try_to_retreat(duel, e)
      d = duel.turn_duelist
      st = d.status & CNF_SLP_PRZ
      if @play_energy_for_retreat && st != ASLEEP && st != PARALYZED && !duel.already_played_energy
        need = duel.retreat_cost(d) - d.energy_cards_in_slot(0).size
        if need == 1 && (en = d.hand.find { |i| d.card(i).energy? })
          play_energy(duel, d, en, 0)
        end
      end
      if [:MYSTERIOUS_FOSSIL, :CLEFAIRY_DOLL].include?(d.card_id(d.arena))
        return false if d.num_in_play_area < 2
        duel.atk = nil
        @fossil_switch_to = e
        return duel.use_pkmn_power(0) == :ok
      end
      return false if st == ASLEEP || st == PARALYZED
      cost = duel.retreat_cost(d)
      energies = d.energy_cards_in_slot(0)
      discard =
        if cost == 0 then []
        elsif d.attached_energies(0)[1] == cost then energies
        else choose_retreat_energy(duel, d, energies, cost)
        end
      return false if discard.nil?
      r = duel.attempt_retreat(discard, e)
      announce(duel, _INTL("{1} retreated.", d.name)) if r == :ok
      r == :ok
    end

    def choose_retreat_energy(duel, d, energies, cost)
      list = energies.dup
      out = []
      c = cost
      my_type = d.card(d.arena).type | TYPE_ENERGY
      # 1) double colorless first if cost >= 2
      while c >= 2 && (dce = list.find { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY })
        out << dce; list.delete(dce); c -= 2
      end
      return out if c <= 0
      # 2) energy that isn't useful for this Pokemon
      list.shuffle.each do |i|
        break if c <= 0
        next if energy_useful?(d, i, my_type)
        out << i; list.delete(i); c -= 1
      end
      return out if c <= 0
      # 3) anything
      list.each do |i|
        out << i
        c -= d.card_id(i) == :DOUBLE_COLORLESS_ENERGY ? 2 : 1
        return out if c <= 0
      end
      nil
    end

    # CheckIfEnergyIsUseful
    def energy_useful?(d, idx, my_type)
      id = d.card_id(idx)
      return true if id == :DOUBLE_COLORLESS_ENERGY || my_type == TYPE_ENERGY_DOUBLE_COLORLESS
      cur = d.card_id(d.arena)
      special = case cur
                when :EXEGGCUTE, :EXEGGUTOR, :PSYDUCK, :GOLDUCK then :PSYCHIC_ENERGY
                when :SURFING_PIKACHU_LV13, :SURFING_PIKACHU_ALT_LV13 then :WATER_ENERGY
                end
      return true if special && id == special
      return true if cur == :EEVEE && [:WATER_ENERGY, :FIRE_ENERGY, :LIGHTNING_ENERGY].include?(id)
      d.card(idx).type == my_type
    end

    # Clefairy Doll / Mysterious Fossil "Discard" power: pick the new active
    def effect_choice(duel, kind, purpose, options, cancellable)
      if purpose == :TrainerCardAsPokemon && @fossil_switch_to && options.include?(@fossil_switch_to)
        return @fossil_switch_to
      end
      super
    end
  end
end
