#==============================================================================
# Pokemon TCG - AI damage estimation (port of engine/duel/ai/damage_calculation.asm)
# and the expected-damage helpers used by EFFECTCMDTYPE_AI effect functions
# (effect_functions.asm SetExpectedAIDamage / UpdateExpectedAIDamage*).
#==============================================================================
module TCG
  class AttackContext
    attr_accessor :ai_min, :ai_max
  end

  class Duel
    # SetExpectedAIDamage(a, d, e)
    def set_expected_ai_damage(avg, min, max)
      @atk.damage = avg
      @atk.ai_min = min
      @atk.ai_max = max
    end

    # UpdateExpectedAIDamage(a, d, e)
    def update_expected_ai_damage(add, dmin, dmax)
      base = @atk.damage
      @atk.ai_min = base + dmin
      @atk.ai_max = base + dmax
      @atk.damage = base + add
    end

    # UpdateExpectedAIDamage_AccountForPoison: no extra if already poisoned
    def update_expected_ai_damage_account_for_poison(add, dmin, dmax)
      if (non_turn_duelist.status & DOUBLE_POISONED) != 0
        @atk.ai_min = @atk.ai_max = @atk.damage
      else
        update_expected_ai_damage(add, dmin, dmax)
      end
    end

    # run the EFFECTCMDTYPE_AI function of the loaded attack (if any)
    def run_ai_effect_phase
      cmds = EFFECT_TABLE[@atk.effect_name] or return
      entry = cmds.find { |p, _| p == EFFECT_AI } or return
      fn = EffectFunctions[entry[1]] or return
      fn.call(self)
    end

    # EstimateDamage_VersusDefendingCard: damage the turn holder's Pokemon in
    # slot e would deal with attack ai to the non-turn arena Pokemon.
    # returns [damage, min, max]
    def ai_estimate_damage_versus_defending(e, ai)
      d = turn_duelist
      return [0, 0, 0] if d.play_area[e].nil? || d.card(d.play_area[e]).attacks[ai].nil?
      saved = @atk
      copy_attack_data_and_damage(d.play_area[e], ai)
      @atk.temp[:power_slot] = e
      if @atk.pokemon_power?
        @atk = saved
        return [0, 0, 0]
      end
      @atk.ai_min = @atk.ai_max = @atk.damage
      run_ai_effect_phase
      if @atk.ai_min.to_i == 0 && @atk.ai_max.to_i == 0
        @atk.ai_min = @atk.ai_max = @atk.damage
      end
      res = with_bench_substatus_reset(d, e) { ai_calc_damage_versus_defending(e) }
      @atk = saved
      res
    end

    # the original temporarily clears substatus1/2 + changed resistance when
    # the attacker isn't the arena Pokemon (it would be after switching)
    def with_bench_substatus_reset(d, e)
      return yield if e == PLAY_AREA_ARENA
      s1, s2, cr = d.substatus1, d.substatus2, d.changed_resistance
      d.substatus1 = d.substatus2 = d.changed_resistance = 0
      begin
        yield
      ensure
        d.substatus1, d.substatus2, d.changed_resistance = s1, s2, cr
      end
    end

    def ai_calc_damage_versus_defending(e)
      [@atk.damage, @atk.ai_min, @atk.ai_max].map { |v| ai_calc_one_versus_defending(e, v) }
    end

    def ai_calc_one_versus_defending(e, v)
      d  = turn_duelist
      nd = non_turn_duelist
      @atk.temp_turn_card_id     = d.card_id(d.play_area[e])
      @atk.temp_non_turn_card_id = nd.card_id(nd.arena)
      blocked = as_non_turn { handle_no_damage_or_effect_substatus }
      return 0 if blocked
      dmg = v
      dmg = handle_double_damage_substatus(dmg) if e == PLAY_AREA_ARENA
      unless @atk.unaffected_by_wr
        wr = COLOR_TO_WR[play_area_card_color(d, e)]
        dmg *= 2 if (arena_card_weakness(nd) & wr) != 0
        dmg -= resistance_amount(nd) if (arena_card_resistance(nd) & wr) != 0
      end
      dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA + e)
      dmg -= 20 * attached_count(nd, :DEFENDER, CARD_LOCATION_ARENA)
      dmg = as_non_turn { handle_damage_reduction(dmg) }
      dmg = 0 if dmg < 0
      if (nd.status & DOUBLE_POISONED) != 0
        dmg += (nd.status & 0x40) != 0 ? 20 : 10
      end
      [dmg, 255].min
    end

    # EstimateDamage_FromDefendingPokemon: damage the non-turn arena Pokemon's
    # attack ai would deal to the turn holder's Pokemon in slot e (2 turns of
    # poison included). returns [damage, min, max]
    def ai_estimate_damage_from_defending(e, ai)
      nd = non_turn_duelist
      return [0, 0, 0] if nd.arena.nil? || nd.card(nd.arena).attacks[ai].nil?
      saved = @atk
      as_non_turn { copy_attack_data_and_damage(nd.arena, ai) }
      if @atk.pokemon_power?
        @atk = saved
        return [0, 0, 0]
      end
      @atk.ai_min = @atk.ai_max = @atk.damage
      as_non_turn do
        @atk.temp[:power_slot] = PLAY_AREA_ARENA
        run_ai_effect_phase
      end
      if @atk.ai_min.to_i == 0 && @atk.ai_max.to_i == 0
        @atk.ai_min = @atk.ai_max = @atk.damage
      end
      d = turn_duelist
      res = with_bench_substatus_reset(d, e) do
        [@atk.damage, @atk.ai_min, @atk.ai_max].map { |v| ai_calc_one_from_defending(e, v) }
      end
      @atk = saved
      res
    end

    def ai_calc_one_from_defending(e, v)
      d  = turn_duelist
      nd = non_turn_duelist
      @atk.temp_turn_card_id     = nd.card_id(nd.arena)
      @atk.temp_non_turn_card_id = d.card_id(d.play_area[e])
      dmg = as_non_turn { handle_double_damage_substatus(v) }
      unless @atk.unaffected_by_wr
        wr = COLOR_TO_WR[as_non_turn { play_area_card_color(turn_duelist, PLAY_AREA_ARENA) }]
        weak = (e == 0 && d.changed_weakness != 0) ? d.changed_weakness : d.card(d.play_area[e]).weakness
        res  = (e == 0 && d.changed_resistance != 0) ? d.changed_resistance : d.card(d.play_area[e]).resistance
        dmg *= 2 if (weak & wr) != 0
        dmg -= resistance_amount(d, e) if (res & wr) != 0
      end
      dmg += 10 * attached_count(nd, :PLUSPOWER, CARD_LOCATION_ARENA)
      dmg -= 20 * attached_count(d, :DEFENDER, CARD_LOCATION_ARENA + e)
      dmg = handle_damage_reduction(dmg) if e == PLAY_AREA_ARENA
      dmg = 0 if dmg < 0
      if e == PLAY_AREA_ARENA && (d.status & DOUBLE_POISONED) != 0
        dmg += (d.status & 0x40) != 0 ? 40 : 20
      end
      [dmg, 255].min
    end
  end
end
