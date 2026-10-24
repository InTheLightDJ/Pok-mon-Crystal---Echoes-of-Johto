#==============================================================================
# Pokemon TCG - substatus handling. Full port of src/home/substatus.asm.
# Turn conventions follow the original: functions documented as acting on the
# "defending card (turn holder)" are called with the turn swapped.
# Original bugs are kept on purpose (marked ORIGINAL BUG).
#==============================================================================
module TCG
  class Duel
    # wTempPlayAreaLocation_cceb (target slot for bench damage routines)
    attr_accessor :temp_play_area_location

    # HandleDoubleDamageSubstatus (turn holder = attacker)
    def handle_double_damage_substatus(dmg)
      d = turn_duelist
      dmg *= 2 if (d.substatus3 & SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE) != 0
      dmg
    end

    # HandleDamageReduction (turn holder = defender, non-turn = attacker)
    def handle_damage_reduction(dmg)
      dmg = handle_damage_reduction_except_substatus2(dmg)
      case non_turn_duelist.substatus2
      when SUBSTATUS2_REDUCE_BY_20 then dmg -= 20
      when SUBSTATUS2_POUNCE, SUBSTATUS2_GROWL then dmg -= 10
      end
      dmg
    end

    def handle_damage_reduction_except_substatus2(dmg)
      return 0 if @atk.no_damage_or_effect != 0
      d = turn_duelist
      case d.substatus1
      when SUBSTATUS1_NO_DAMAGE_STIFFEN, SUBSTATUS1_NO_DAMAGE_WITHDRAW,
           SUBSTATUS1_NO_DAMAGE_HIDE_IN_SHELL, SUBSTATUS1_NO_DAMAGE_SCRUNCH
        return 0
      when SUBSTATUS1_REDUCE_BY_10 then return dmg - 10
      when SUBSTATUS1_REDUCE_BY_20 then return dmg - 20
      when SUBSTATUS1_PREVENT_LESS_THAN_40 then return dmg < 40 ? 0 : dmg
      when SUBSTATUS1_HALVE_DAMAGE then return halve_damage(dmg)
      end
      return dmg if incapable_of_using_pkmn_power?(d, PLAY_AREA_ARENA)
      damage_reduction_from_pkmn_power(dmg)
    end

    # .pkmn_power: Invisible Wall / Kabuto Armor of the defending card
    def damage_reduction_from_pkmn_power(dmg)
      return dmg if @atk.pokemon_power?
      case @atk.temp_non_turn_card_id
      when :MR_MIME then dmg >= 30 ? 0 : dmg   # Invisible Wall
      when :KABUTO  then halve_damage(dmg)     # Kabuto Armor
      else dmg
      end
    end

    # ORIGINAL BUG: uses "sla d" instead of "sra d" (only matters for >=256),
    # then rounds an odd result down by 5.
    def halve_damage(dmg)
      d = (dmg >> 8) & 0xff
      e = dmg & 0xff
      carry = (d >> 7) & 1          # sla d
      d = (d << 1) & 0xff
      e = (e >> 1) | (carry << 7)   # rr e
      res = (d << 8) | e
      res -= 5 if e.odd?
      res
    end

    # HandleDamageReductionOrNoDamageFromPkmnPowerEffects
    def handle_damage_reduction_or_no_damage_from_pkmn_power_effects(e, dmg)
      return dmg if @atk.pokemon_power?
      return dmg if toxic_gas_active?
      dmg = damage_reduction_from_pkmn_power(dmg) if e != PLAY_AREA_ARENA
      return 0 if no_damage_or_effect_pkmn_power || handle_transparency(e)
      dmg
    end

    # HandleStrikesBack_AgainstDamagingAttack (turn holder = damaged side)
    def handle_strikes_back_against_damaging_attack(e, dmg)
      return if dmg == 0 || @atk.is_damage_to_self
      return unless @atk.temp_non_turn_card_id == :MACHAMP
      return if toxic_gas_active? || @atk.pokemon_power?
      return if e == PLAY_AREA_ARENA && incapable_of_using_pkmn_power?(turn_duelist, PLAY_AREA_ARENA)
      as_non_turn do
        d = turn_duelist
        subtract_hp(d, PLAY_AREA_ARENA, 10)
        @ui.message(_INTL("{1} received 10 damage due to Strikes Back.", d.card(d.arena).name))
        if d.slot_hp[PLAY_AREA_ARENA] == 0
          @ui.message(_INTL("{1} was Knocked Out!", d.card(d.arena).name))
        end
      end
    end

    # HandleCantAttackSubstatus: reason symbol or nil
    def handle_cant_attack_substatus(d)
      case d.substatus2
      when SUBSTATUS2_TAIL_WAG    then :tail_wag
      when SUBSTATUS2_LEER        then :leer
      when SUBSTATUS2_BONE_ATTACK then :bone_attack
      end
    end

    def handle_amnesia_substatus(d, attack_index)
      d.substatus2 == SUBSTATUS2_AMNESIA && d.disabled_attack_index == attack_index
    end

    # CheckSandAttackOrSmokescreenSubstatus: affected and no heads yet
    def check_sand_attack_or_smokescreen_substatus
      s = turn_duelist.substatus2
      return false unless s == SUBSTATUS2_SAND_ATTACK || s == SUBSTATUS2_SMOKESCREEN
      !@got_heads_sand_attack_check
    end

    # returns true if the attack failed
    def handle_sand_attack_or_smokescreen_substatus
      return false unless check_sand_attack_or_smokescreen_substatus
      txt = turn_duelist.substatus2 == SUBSTATUS2_SAND_ATTACK ?
        _INTL("Sand-Attack check! If Tails, the attack is unsuccessful.") :
        _INTL("Smokescreen check! If Tails, the attack is unsuccessful.")
      coin_check(txt, turn_duelist.substatus2 == SUBSTATUS2_SAND_ATTACK ?
        "Sand-attack check!\nIf Tails, Attack is unsuccessful." :
        "Smokescreen check!\nIf Tails, Attack is unsuccessful.")
      @got_heads_sand_attack_check = (toss_coin == HEADS)
      return false if @got_heads_sand_attack_check
      @ui.message(_INTL("The attack was unsuccessful."))
      true
    end

    # HandleNoDamageOrEffectSubstatus (turn holder = defender).
    # returns true (carry) if no damage/effect
    def handle_no_damage_or_effect_substatus
      @atk.no_damage_or_effect = 0
      return false if @atk.pokemon_power?
      case turn_duelist.substatus1
      when SUBSTATUS1_FLY     then return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_FLY)
      when SUBSTATUS1_BARRIER then return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_BARRIER)
      when SUBSTATUS1_AGILITY then return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_AGILITY)
      end
      return false if incapable_of_using_pkmn_power?(turn_duelist, PLAY_AREA_ARENA)
      no_damage_or_effect_pkmn_power
    end

    # .pkmn_power: Neutralizing Shield (Mew Lv8) vs evolved attackers
    def no_damage_or_effect_pkmn_power
      return false unless @atk.temp_non_turn_card_id == :MEW_LV8
      return false if @atk.is_damage_to_self
      return false if TCG.card(@atk.temp_turn_card_id).stage == BASIC
      set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_NSHIELD)
    end

    def set_no_damage_or_effect(v)
      @atk.no_damage_or_effect = v
      true
    end

    # HandleTransparency (turn holder = defender): true if damage prevented
    def handle_transparency(e = PLAY_AREA_ARENA)
      return false unless @atk.temp_non_turn_card_id == :HAUNTER_LV17
      return false if @atk.pokemon_power?
      return false if incapable_of_using_pkmn_power?(turn_duelist, e)
      coin_check(_INTL("Transparency check! If Heads, do not receive damage or effects."),
                 "Transparency check! If Heads,\ndo not receive opponent's Attack!")
      return false if toss_coin == TAILS
      set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_TRANSPARENCY)
    end

    # ApplyTransparencyIfApplicable (from home/duel.asm; turn = attacker)
    def apply_transparency_if_applicable(dmg)
      return dmg if @atk.residual? || @atk.no_damage_or_effect != 0
      if dmg == 0 && non_turn_duelist.substatus2 == 0 && @atk.status_queue.empty?
        return dmg
      end
      @temp_play_area_location = PLAY_AREA_ARENA
      prevented = as_non_turn { handle_transparency }
      return dmg unless prevented
      non_turn_duelist.substatus2 = 0
      0
    end

    # CheckNoDamageOrEffect: text for the current no-damage cause (once)
    NO_DAMAGE_OR_EFFECT_TEXT = {
      NO_DAMAGE_OR_EFFECT_AGILITY      => "No damage or effect due to Agility.",
      NO_DAMAGE_OR_EFFECT_BARRIER      => "No damage or effect due to Barrier.",
      NO_DAMAGE_OR_EFFECT_FLY          => "No damage or effect due to Fly.",
      NO_DAMAGE_OR_EFFECT_TRANSPARENCY => "No damage or effect due to Transparency.",
      NO_DAMAGE_OR_EFFECT_NSHIELD      => "No damage or effect due to Neutralizing Shield."
    }
    # returns true if there's no damage/effect (prints the reason once)
    def check_no_damage_or_effect
      v = @atk.no_damage_or_effect
      return false if v == 0
      if (v & 0x80) == 0
        @atk.no_damage_or_effect |= 0x80
        @ui.message(_INTL(NO_DAMAGE_OR_EFFECT_TEXT[v]))
      end
      true
    end

    # ClearDamageReductionSubstatus2 (turn holder)
    def clear_damage_reduction_substatus2(d = turn_duelist)
      case d.substatus2
      when SUBSTATUS2_REDUCE_BY_20, SUBSTATUS2_POUNCE, SUBSTATUS2_GROWL,
           SUBSTATUS2_TAIL_WAG, SUBSTATUS2_LEER
        d.substatus2 = 0
      end
    end

    def update_substatus_conditions_start_of_turn
      d = turn_duelist
      s1 = d.substatus1
      d.substatus1 = 0
      d.substatus3 |= SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE if s1 == SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
    end

    def update_substatus_conditions_end_of_turn
      d = turn_duelist
      d.substatus3 &= ~SUBSTATUS3_HEADACHE
      d.substatus2 = 0
      return if d.substatus1 == SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE
      d.substatus3 &= ~SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE
    end

    # HandleDestinyBondSubstatus (turn = attacker)
    def handle_destiny_bond_substatus
      nd = non_turn_duelist
      return unless nd.substatus1 == SUBSTATUS1_DESTINY_BOND
      return if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] > 0
      d = turn_duelist
      return if d.slot_hp[PLAY_AREA_ARENA] == 0
      d.slot_hp[PLAY_AREA_ARENA] = 0
      @ui.refresh(self)
      @ui.message(_INTL("{1} was Knocked Out due to Destiny Bond.", d.card(d.arena).name))
    end

    # ORIGINAL BUG/quirk: despite the name, this skips RESIDUAL attacks and
    # only bounces back regular (non-residual) attacks that dealt damage.
    def handle_strikes_back_against_residual_attack
      return unless @atk.temp_non_turn_card_id == :MACHAMP
      return if @atk.residual?
      return if @atk.dealt_damage == 0
      return if as_non_turn { incapable_of_using_pkmn_power?(turn_duelist, PLAY_AREA_ARENA) }
      apply_strikes_back_against_residual_attack(10)
    end

    def apply_strikes_back_against_residual_attack(amount)
      d = turn_duelist
      subtract_hp(d, PLAY_AREA_ARENA, amount)
      @ui.message(_INTL("{1} received {2} damage due to Strikes Back.", TCG.card(@atk.temp_turn_card_id).name, amount))
      if d.slot_hp[PLAY_AREA_ARENA] == 0
        @ui.message(_INTL("{1} was Knocked Out!", d.card(d.arena).name))
      end
    end

    # ClearChangedTypesIfMuk
    def clear_changed_types_if_muk(d, idx)
      return unless d.card_id(idx) == :MUK
      @duelists.each { |x| x.slot_changed_type.map! { 0 } }
    end
  end
end
