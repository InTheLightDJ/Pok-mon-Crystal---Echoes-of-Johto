#==============================================================================
# Pokemon TCG - AI attack choice. Port of engine/duel/ai/attacks.asm
# (AIProcessAttacks / GetAIScoreOfAttack) + core.asm helpers
# (AIEncourage/AIDiscourage, CheckIfSelectedAttackIsUnusable,
# CheckIfDefendingPokemonCanKnockOut) + special_attacks.asm
# CheckWhetherToSwitchToFirstAttack.
#==============================================================================
module TCG
  AI_FLAG_USED_PLUSPOWER = 0x01

  class AIController
    attr_accessor :score, :retreat_score, :plus_power_attack

    def ai_encourage(n); @score = [@score + n, 255].min; end
    def ai_discourage(n)
      return if @score == 0
      @score = [@score - n, 0].max
    end
    def dmg_counters(hp); hp < 0 ? 0 : hp / 10; end

    # CheckIfSelectedAttackIsUnusable (turn holder, slot e)
    def attack_unusable?(duel, e, ai)
      d = duel.turn_duelist
      return true if d.play_area[e].nil? || d.card(d.play_area[e]).attacks[ai].nil?
      if e == PLAY_AREA_ARENA
        return true if duel.cant_attack_reason
        duel.copy_attack_data_and_damage(d.arena, ai)
        return true if duel.handle_amnesia_substatus(d, ai)
        return true if duel.silently { duel.try_execute_effect_command(EFFECT_INITIAL_EFFECT_1) }
      end
      idx = d.play_area[e]
      atk = d.card(idx).attacks[ai]
      return true if atk.nil? || atk.pokemon_power?
      return true unless duel.enough_energies_for_attack?(d, idx, ai, e)
      atk.flag?(:IGNORE_THIS_ATTACK)
    end

    # CheckIfDefendingPokemonCanKnockOut: [can_ko, best attack index]
    # (HP - damage: zero -> KO; underflow carry is returned too -> KO)
    def defending_pokemon_can_knock_out(duel, e)
      dmg = [0, 1].map do |ai|
        next 0 if duel.as_non_turn { attack_unusable?(duel, PLAY_AREA_ARENA, ai) }
        dm, = duel.ai_estimate_damage_from_defending(e, ai)
        (duel.turn_duelist.slot_hp[e] - dm) <= 0 ? dm : 0
      end
      return [false, nil] if dmg[0] == 0 && dmg[1] == 0
      [true, dmg[1] >= dmg[0] ? 1 : 0]
    end

    # GetAIScoreOfAttack
    def get_ai_score_of_attack(duel, ai)
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      @score = 0x50
      return @score = 0 if attack_unusable?(duel, PLAY_AREA_ARENA, ai)
      duel.atk ||= AttackContext.new
      duel.copy_attack_data_and_damage(d.arena, ai)
      duel.atk.temp_turn_card_id     = d.card_id(d.arena)
      duel.atk.temp_non_turn_card_id = nd.card_id(nd.arena)
      atk = d.card(d.arena).attacks[ai]
      cannot_damage = duel.as_non_turn { duel.handle_no_damage_or_effect_substatus }
      @cannot_damage = cannot_damage   # wAICannotDamage
      if cannot_damage
        return @score = 0 if atk.pokemon_power?
        return @score = 0 unless atk.residual? || atk.flag?(:DAMAGE_TO_OPPONENT_BENCH)
      end
      dmg, dmin, dmax = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, ai)
      ai_encourage(20) if nd.slot_hp[0] - dmg <= 0
      non_damaging = false
      if dmg != 0
        ai_encourage(dmg_counters(dmg))
      else
        non_damaging = true
        ai_discourage(0)
        if dmax != 0
          ai_encourage(2)
          non_damaging = false
        end
        ai_encourage(2) if atk.flag?(:DAMAGE_TO_OPPONENT_BENCH)
      end
      # recoil
      if (atk.flag?(:LOW_RECOIL) || atk.flag?(:HIGH_RECOIL)) && atk.param != 0
        duel.atk.damage = atk.param
        self_dmg = duel.apply_damage_modifiers_damage_to_self
        ai_discourage(dmg_counters(self_dmg))
        unless atk.flag?(:HIGH_RECOIL)
          ai_discourage(10) if d.slot_hp[0] <= self_dmg
          # fall through to the defending checks
        else
          r = high_recoil_score(duel, d, nd)
          return @score if r == :done
        end
      end
      # defending Pokemon can KO us
      can_ko, = defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)
      if can_ko
        ai_encourage(5)
        ai_discourage(5) if non_damaging
      end
      if atk.flag?(:DISCARD_ENERGY)
        ai_discourage(1)
        ai_discourage(atk.param)
      end
      ai_encourage(atk.param) if atk.flag?(:ENCOURAGE_THIS_ATTACK)
      ai_encourage(1) if atk.flag?(:NULLIFY_OR_WEAKEN_ATTACK)
      ai_encourage(1) if atk.flag?(:DRAW_CARD)
      if atk.flag?(:HEAL_USER)
        if atk.param == 1   # HEALING_EQUALS_10_HP
          a = 1
        else
          b = dmg_counters(dmg)
          if atk.param == 2   # half damage dealt, rounded up
            b = (b + 1) >> 1
          end
          a = [dmg_counters(d.slot_hp[0]), b].min
        end
        a = [dmg_counters(duel.card_damage_and_max_hp(d, 0)[0]), a].min
        ai_encourage(a)
      end
      unless nd.card_id(nd.arena) == :SNORLAX
        st = nd.status
        if atk.flag?(:INFLICT_POISON)
          if (st & DOUBLE_POISONED) == 0
            ai_encourage(2)
          elsif (st & 0x40) != 0 && atk.flag?(:ENCOURAGE_THIS_ATTACK)
            ai_discourage(2)
          end
        end
        ai_encourage(1) if atk.flag?(:INFLICT_SLEEP) && (st & CNF_SLP_PRZ) != ASLEEP
        if atk.flag?(:INFLICT_PARALYSIS)
          (st & CNF_SLP_PRZ) == ASLEEP ? ai_discourage(1) : ai_encourage(1)
        end
        if atk.flag?(:INFLICT_CONFUSION)
          if (st & CNF_SLP_PRZ) == ASLEEP then ai_discourage(1)
          elsif (st & CNF_SLP_PRZ) != CONFUSED then ai_encourage(1)
          end
        end
        ai_discourage(1) if (d.status & CNF_SLP_PRZ) == CONFUSED
      end
      if atk.flag?(:SPECIAL_AI_HANDLING)
        v = handle_special_ai_attacks(duel, ai)
        v >= 0x80 ? ai_encourage(v - 0x80) : ai_discourage(0x80 - v)
      end
      @score
    end

    # HIGH_RECOIL handling (Selfdestruct family). returns :done or nil
    def high_recoil_score(duel, d, nd)
      if d.num_in_play_area < 2
        @score = 0
        return :done
      end
      case @deck_id
      when :BOOM_BOOM_SELFDESTRUCT_DECK
        ai_encourage(20); return :done
      when :POWER_GENERATOR_DECK
        @score = 0; return :done
      when :ROCK_CRUSHER_DECK
        if d.count_prizes >= 4
          @score = 0; return :done
        end
        if duel.as_non_turn { kos_bench_enough?(duel, 0, 20) }
          ai_encourage(20); return :done
        end
      when :ZAPPING_SELFDESTRUCT_DECK
        dmg, max = duel.card_damage_and_max_hp(d, 0)
        if d.not_in_deck < 31 && (dmg * 2) >= max
          b = d.card_id(d.arena) == :MAGNEMITE_LV13 ? 10 : 20
          if kos_bench_enough?(duel, 1, b)
            @score = 0; return :done
          end
          ai_encourage(20); return :done
        end
      end
      id = d.card_id(d.arena)
      b = id == :CHANSEY ? 0 : ([:MAGNEMITE_LV13, :WEEZING].include?(id) ? 10 : 20)
      opp_kos = nil
      if duel.as_non_turn { opp_kos = bench_kos(duel, 0, b); kos_bench_enough?(duel, 0, b) }
        ai_encourage(20); return :done
      end
      own = bench_kos(duel, 1, b)
      if kos_bench_enough?(duel, 1, b)
        @score = 0; return :done
      end
      ai_discourage(own - 1) if own > 0
      ai_encourage(opp_kos)
      nil
    end

    # .check_if_kos_bench: KOs on the turn holder's bench (+ initial)
    def bench_kos(duel, initial, b)
      d = duel.turn_duelist
      initial + (1...d.num_in_play_area).count { |e| d.slot_hp[e] <= b }
    end

    # carry if those KOs >= the OTHER duelist's remaining prizes
    def kos_bench_enough?(duel, initial, b)
      bench_kos(duel, initial, b) >= duel.non_turn_duelist.count_prizes
    end

    # special_attacks.asm HandleSpecialAIAttacks — TODO (neutral $80 for now)
    def handle_special_ai_attacks(duel, ai); 0x80; end

    # CheckWhetherToSwitchToFirstAttack
    def check_whether_to_switch_to_first_attack(duel, first_score)
      return 1 if first_score < 0x50
      nd = duel.non_turn_duelist
      dmg, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, 0)
      return 1 if nd.slot_hp[0] - dmg > 0
      atk = duel.turn_duelist.card(duel.turn_duelist.arena).attacks[1]
      return 1 if atk && (atk.flag?(:HEAL_USER) || atk.flag?(:NULLIFY_OR_WEAKEN_ATTACK))
      0
    end

    # AIProcessAttacks / AIProcessAndTryToUseAttack: true if attacked
    def process_and_try_to_use_attack(duel)
      @scene&.refresh(duel)
      @retreat_score ||= 0
      d = duel.turn_duelist
      if (@previous_flags & AI_FLAG_USED_PLUSPOWER) != 0
        chosen = @plus_power_attack
      else
        if @barrier_flag_counter == AI_MEWTWO_MILL
          @retreat_score += 1
          return false
        end
        s0 = get_ai_score_of_attack(duel, 0)
        s1 = get_ai_score_of_attack(duel, 1)
        chosen, best = s1 >= s0 ? [1, s1] : [0, s0]
        if best < 0x50
          @retreat_score += 1
          return false
        end
        chosen = check_whether_to_switch_to_first_attack(duel, s0) if chosen == 1
      end
      @selected_attack = chosen
      process_hand_trainer_cards(duel, 14)
      dmg, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, chosen)
      atk = d.card(d.arena).attacks[chosen]
      if dmg != 0 || (atk && atk.flag?(:DAMAGE_TO_OPPONENT_BENCH))
        @retreat_score = 0
      else
        @retreat_score += 1
      end
      @tried_attack = true
      ai_use_attack(duel, chosen)
      true
    end
  end
end
