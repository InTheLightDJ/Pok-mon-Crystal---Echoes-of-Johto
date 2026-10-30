#==============================================================================
# Pokemon TCG - attacks, Pokemon Powers, trainer cards and damage.
# Ports from src/home/duel.asm:
#   CopyAttackDataAndDamage, UpdateArenaCardIDsAndClearTwoTurnDuelVars,
#   UseAttackOrPokemonPower, PlayAttackAnimation_DealAttackDamage,
#   HandleAfterDamageEffects, HandleConfusionDamageToSelf, UsePokemonPower,
#   PlayTrainerCard, DealRecoilDamageToSelf, ApplyDamageModifiers_*,
#   ApplyAttachedPlusPower/Defender, SubtractHP, DealDamageToPlayAreaPokemon
# and core.asm DuelMenu_Attack / CheckIfEnoughEnergiesForGivenAttack.
#
# Effect commands: TCG::EffectCommands[name][phase] = proc { |duel| ... }
# A proc returning true means "carry" (failed / cancelled), like the original.
#==============================================================================
module TCG
  EFFECT_INITIAL_EFFECT_1         = 0x01
  EFFECT_INITIAL_EFFECT_2         = 0x02
  EFFECT_BEFORE_DAMAGE            = 0x03
  EFFECT_AFTER_DAMAGE             = 0x04
  EFFECT_REQUIRE_SELECTION        = 0x05
  EFFECT_DISCARD_ENERGY           = 0x06
  EFFECT_PKMN_POWER_TRIGGER       = 0x07
  EFFECT_AI_SELECTION             = 0x08
  EFFECT_AI                       = 0x09
  EFFECT_AI_SWITCH_DEFENDING_PKMN = 0x0a

  EffectCommands = {}   # filled by the effect scripts

  # the attack currently being executed (wLoadedAttack + temp vars)
  class AttackContext
    attr_accessor :card_index, :attack_index, :attack, :card_id, :damage,
                  :unaffected_by_wr, :dealt_damage, :no_damage_or_effect,
                  :damage_effectiveness, :effect_failed, :is_damage_to_self,
                  :defending_was_forced_to_switch, :status_queue,
                  :temp_turn_card_id, :temp_non_turn_card_id, :effect_name,
                  :temp, :confusion_attack_failed
    def initialize
      @status_queue = []
      @temp = {}          # hTemp_ffa0 / hTempPlayAreaLocation_ffa1 / etc.
      @dealt_damage = 0
      @no_damage_or_effect = 0
      @damage_effectiveness = 0
      @effect_failed = 0
    end
    def residual?;      @attack && @attack.residual?; end
    def pokemon_power?; @attack && @attack.pokemon_power?; end
  end

  class Duel
    attr_accessor :atk

    #--------------------------------------------------------------------------
    # TryExecuteEffectCommandFunction
    #--------------------------------------------------------------------------
    def try_execute_effect_command(phase)
      name = @atk&.effect_name
      return false unless name
      cmd = EffectCommands[name]
      return false unless cmd && cmd[phase]
      cmd[phase].call(self) ? true : false
    end

    #--------------------------------------------------------------------------
    # attack availability (DuelMenu_Attack)
    #--------------------------------------------------------------------------
    # nil if the arena Pokemon may open the attack menu, else the reason
    def cant_attack_reason
      d = turn_duelist
      r = handle_cant_attack_substatus(d)
      return r if r
      st = d.status & CNF_SLP_PRZ
      return :paralyzed if st == PARALYZED
      return :asleep if st == ASLEEP
      nil
    end

    # CheckIfEnoughEnergiesForGivenAttack (after HandleEnergyBurn)
    def enough_energies_for_attack?(d, deck_index, attack_index, e = PLAY_AREA_ARENA)
      atk = d.card(deck_index).attacks[attack_index]
      return false if atk.nil? || atk.pokemon_power?
      en, total = attached_energies_with_energy_burn(d, e)
      accum = 0
      COLORED_TYPES.each do |col|
        need = atk.cost[col]
        accum += need
        return false if need > en[col]
      end
      total - accum >= atk.cost[COLORLESS]
    end

    # HandleEnergyBurn hook (Charizard): overridden in the effects script
    def attached_energies_with_energy_burn(d, e)
      d.attached_energies(e)
    end

    # list of [deck_index, attack_index] the arena Pokemon can choose from
    # (PrintAndLoadAttacksToDuelTempList)
    def attack_list(d = turn_duelist)
      idx = d.arena
      d.card(idx).attacks.each_with_index.reject { |a, _| a.pokemon_power? }
                         .map { |_, i| [idx, i] }
    end

    #--------------------------------------------------------------------------
    # CopyAttackDataAndDamage_FromDeckIndex
    #--------------------------------------------------------------------------
    def copy_attack_data_and_damage(deck_index, attack_index, d = turn_duelist)
      @atk = AttackContext.new
      @atk.card_index   = deck_index
      @atk.attack_index = attack_index
      @atk.card_id      = d.card_id(deck_index)
      @atk.attack       = d.card(deck_index).attacks[attack_index]
      @atk.effect_name  = @atk.attack.effect
      @atk.damage       = @atk.attack.damage
      @atk
    end

    # UpdateArenaCardIDsAndClearTwoTurnDuelVars
    def update_arena_card_ids_and_clear_two_turn_duel_vars
      @atk.temp_turn_card_id     = turn_duelist.arena && turn_duelist.card_id(turn_duelist.arena)
      @atk.temp_non_turn_card_id = non_turn_duelist.arena && non_turn_duelist.card_id(non_turn_duelist.arena)
      @atk.status_queue = []
      @atk.effect_failed = 0
      @atk.is_damage_to_self = false
      @atk.defending_was_forced_to_switch = false
      clear_non_turn_temporary_duelvars
    end

    def clear_non_turn_temporary_duelvars
      nd = non_turn_duelist
      nd.disabled_attack_index = 0
      nd.last_turn_damage      = 0
      nd.last_turn_status      = 0
      nd.last_turn_substatus2  = 0
      nd.last_turn_change_weak = 0
      nd.last_turn_effect      = 0
    end

    #--------------------------------------------------------------------------
    # DuelMenu_Attack -> UseAttackOrPokemonPower
    # returns :ok (attack done; turn ends), or a failure reason (back to menu)
    #--------------------------------------------------------------------------
    def use_attack(deck_index, attack_index)
      return :duel_finished if @duel_finished != DUEL_NOT_FINISHED
      d = turn_duelist
      r = cant_attack_reason
      return r if r
      return :not_enough_energy unless enough_energies_for_attack?(d, deck_index, attack_index)
      copy_attack_data_and_damage(deck_index, attack_index)
      return :amnesia if handle_amnesia_substatus(d, attack_index)
      return :cancelled if use_attack_or_pokemon_power == :cancelled
      @attacked_this_turn = true
      :ok
    end

    def use_attack_or_pokemon_power
      return use_pokemon_power if @atk.pokemon_power?
      update_arena_card_ids_and_clear_two_turn_duel_vars
      return :cancelled if try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
      if check_sand_attack_or_smokescreen_substatus
        if handle_sand_attack_or_smokescreen_substatus   # attack failed (tails)
          clear_non_turn_temporary_duelvars
          return :ok
        end
      end
      return :cancelled if try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
      try_execute_effect_command(EFFECT_DISCARD_ENERGY)
      if check_self_confusion_damage
        handle_confusion_damage_to_self
        return :ok
      end
      text = _INTL("{1}'s\n{2}!", turn_duelist.card(turn_duelist.arena).name, @atk.attack.name)
      if @ui.shows_card_screens? && !turn_duelist.player?
        # OppAction_UseAttack -> DisplayOpponentUsedAttackScreen
        @ui.event(:opp_attack, turn_duelist.card_id(@atk.card_index), @atk.attack_index, text)
      else
        @ui.message(text)
      end
      try_execute_effect_command(EFFECT_REQUIRE_SELECTION)
      play_attack_animation_deal_attack_damage
      :ok
    end

    def play_attack_animation_deal_attack_damage
      unless @atk.residual?
        as_non_turn { handle_no_damage_or_effect_substatus }
      end
      try_execute_effect_command(EFFECT_BEFORE_DAMAGE)
      dmg = apply_damage_modifiers_damage_to_target
      dmg = apply_transparency_if_applicable(dmg)
      @atk.dealt_damage = dmg
      nd = non_turn_duelist
      @ui.event(:attack_animation, @atk.attack.anim, dmg, @atk.damage_effectiveness)
      subtract_hp(nd, PLAY_AREA_ARENA, dmg)
      @ui.refresh(self)
      handle_after_damage_effects
    end

    def handle_after_damage_effects
      saved = @atk.temp_non_turn_card_id
      try_execute_effect_command(EFFECT_AFTER_DAMAGE)
      @atk.temp_non_turn_card_id = saved
      handle_strikes_back_against_residual_attack
      apply_status_condition_queue
      print_knocked_out_if_needed
      update_arena_card_last_turn_damage
      handle_destiny_bond_and_between_turn_knock_outs
    end

    # Func_1bb4: show KO text for the defending arena Pokemon if HP is 0
    def print_knocked_out_if_needed
      nd = non_turn_duelist
      return if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] > 0
      @ui.message(_INTL("{1} was Knocked Out!", nd.card(nd.arena).name))
    end

    # UpdateArenaCardLastTurnDamage
    def update_arena_card_last_turn_damage
      non_turn_duelist.last_turn_damage =
        @atk.defending_was_forced_to_switch ? 0 : @atk.dealt_damage
    end

    #--------------------------------------------------------------------------
    # confusion / recoil
    #--------------------------------------------------------------------------
    def check_self_confusion_damage
      @atk.confusion_attack_failed = false
      return false unless (turn_duelist.status & CNF_SLP_PRZ) == CONFUSED
      coin_check(_INTL("Confusion check! If Tails, {1} attacks itself.", turn_duelist.card(turn_duelist.arena).name),
                 "Confusion check,\nIf Tails, damage to yourself!")
      return false if toss_coin == HEADS
      @atk.confusion_attack_failed = true
      true
    end

    def handle_confusion_damage_to_self
      @atk.is_damage_to_self = true
      @ui.message(_INTL("It attacked itself in its confusion!"))
      deal_damage_to_self(20, :ATK_ANIM_CONFUSION_HIT)
      print_knocked_out_self_if_needed
      handle_destiny_bond_and_between_turn_knock_outs
      clear_non_turn_temporary_duelvars
    end

    def deal_recoil_damage_to_self(amount)
      deal_damage_to_self(amount, :ATK_ANIM_RECOIL_HIT)
    end

    # DealConfusionDamageToSelf: uses the attacker's own W/R + PlusPower/Defender
    def deal_damage_to_self(amount, anim)
      @atk.damage = amount
      @atk.unaffected_by_wr = false
      saved_ndmg = @atk.no_damage_or_effect
      @atk.no_damage_or_effect = 0
      dmg = apply_damage_modifiers_damage_to_self
      @ui.event(:self_damage, anim, dmg)
      subtract_hp(turn_duelist, PLAY_AREA_ARENA, dmg)
      @atk.no_damage_or_effect = saved_ndmg
    end

    def print_knocked_out_self_if_needed
      d = turn_duelist
      return if d.slot_hp[PLAY_AREA_ARENA] > 0
      @ui.message(_INTL("{1} was Knocked Out!", d.card(d.arena).name))
    end

    #--------------------------------------------------------------------------
    # Pokemon Power / Trainer
    #--------------------------------------------------------------------------
    def use_pokemon_power
      if try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
        return :cancelled
      end
      return :cancelled if try_execute_effect_command(EFFECT_REQUIRE_SELECTION)
      unless @ui.shows_card_screens?   # the scene showed DisplayUsePokemonPowerScreen
        @ui.message(_INTL("{1} used the Pokémon Power\n{2}!", turn_duelist.card(@atk.card_index).name, @atk.attack.name))
      end
      try_execute_effect_command(EFFECT_BEFORE_DAMAGE)
      @ui.refresh(self)
      :ok
    end

    # DuelMenu_PkmnPower: Pokemon in play area slot e uses its power
    def use_pkmn_power(e)
      d = turn_duelist
      idx = d.play_area[e]
      ai = d.card(idx).attacks.index(&:pokemon_power?)
      return :no_power unless ai
      copy_attack_data_and_damage(idx, ai)
      @atk.temp[:power_slot] = e
      r = use_pokemon_power
      r
    end

    # PlayTrainerCard
    def play_trainer_card(idx)
      d = turn_duelist
      return :headache if cant_use_trainer_due_to_effect?(d)
      @atk = AttackContext.new
      @atk.card_index  = idx
      @atk.card_id     = d.card_id(idx)
      @atk.effect_name = d.card(idx).effect
      return :cant_use if try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
      return :cancelled if try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
      if @ui.shows_card_screens?
        @ui.event(:trainer_used, d.name, idx)
      else
        @ui.message(_INTL("{1} used\n{2}.", d.name, d.card(idx).name))
      end
      try_execute_effect_command(EFFECT_DISCARD_ENERGY)
      try_execute_effect_command(EFFECT_REQUIRE_SELECTION)
      try_execute_effect_command(EFFECT_BEFORE_DAMAGE)
      d.move_hand_card_to_discard_pile(idx)
      @ui.refresh(self)
      :ok
    end

    #--------------------------------------------------------------------------
    # damage modifiers
    #--------------------------------------------------------------------------
    def apply_damage_modifiers_damage_to_target
      @atk.damage_effectiveness = 0
      dmg = @atk.damage
      return 0 if dmg == 0
      d  = turn_duelist
      nd = non_turn_duelist
      unless @atk.unaffected_by_wr
        dmg = handle_double_damage_substatus(dmg)
        return 0 if dmg == 0
        wr = COLOR_TO_WR[play_area_card_color(d, PLAY_AREA_ARENA)]
        if (arena_card_weakness(nd) & wr) != 0
          dmg *= 2
          @atk.damage_effectiveness |= WEAKNESS
        end
        if (arena_card_resistance(nd) & wr) != 0
          dmg -= resistance_amount(nd)   # 30 for every original card
          @atk.damage_effectiveness |= RESISTANCE
        end
      else
        dmg = handle_double_damage_substatus(dmg)
      end
      dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA)
      dmg -= 20 * attached_count(nd, :DEFENDER, CARD_LOCATION_ARENA)
      dmg = as_non_turn { handle_damage_reduction(dmg) }
      dmg < 0 ? 0 : dmg
    end

    def apply_damage_modifiers_damage_to_self
      @atk.damage_effectiveness = 0
      dmg = @atk.damage
      return 0 if dmg == 0
      d = turn_duelist
      wr = COLOR_TO_WR[play_area_card_color(d, PLAY_AREA_ARENA)]
      if (arena_card_weakness(d) & wr) != 0
        dmg *= 2
        @atk.damage_effectiveness |= WEAKNESS
      end
      if (arena_card_resistance(d) & wr) != 0
        dmg -= resistance_amount(d)
        @atk.damage_effectiveness |= RESISTANCE
      end
      dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA)
      dmg -= 20 * attached_count(d, :DEFENDER, CARD_LOCATION_ARENA)
      dmg < 0 ? 0 : dmg
    end

    def attached_count(d, id, location)
      d.count_card_id_in_location(id, location)
    end

    # GetArenaCardWeakness/Resistance: changed values override the card's
    def arena_card_weakness(d)
      return d.changed_weakness if d.changed_weakness != 0
      d.card(d.arena).weakness
    end

    def arena_card_resistance(d)
      return d.changed_resistance if d.changed_resistance != 0
      d.card(d.arena).resistance
    end

    # SubtractHP: returns true if HP is still above 0
    def subtract_hp(d, e, dmg)
      d.slot_hp[e] = [d.slot_hp[e] - dmg, 0].max
      d.slot_hp[e] > 0
    end

    # DealDamageToPlayAreaPokemon: damage dmg to the TURN HOLDER's slot e
    # (callers swap turn first when hitting the opponent, like the original).
    def deal_damage_to_play_area_pokemon(e, dmg, anim = :ATK_ANIM_BENCH_HIT)
      d = turn_duelist
      if e == PLAY_AREA_ARENA
        return if @atk.no_damage_or_effect != 0
      end
      @atk.no_damage_or_effect = 0
      @atk.temp_non_turn_card_id = d.card_id(d.play_area[e])
      if e == PLAY_AREA_ARENA
        if @atk.is_damage_to_self
          dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA)
        else
          as_non_turn { dmg += 10 * attached_count(turn_duelist, :PLUSPOWER, CARD_LOCATION_ARENA) }
        end
      end
      unless @atk.pokemon_power?
        dmg -= 20 * attached_count(d, :DEFENDER, CARD_LOCATION_PLAY_AREA | e)
      end
      if e == PLAY_AREA_ARENA
        handle_no_damage_or_effect_substatus
        dmg = handle_damage_reduction(dmg)
      end
      dmg = 0 if dmg < 0
      dmg = handle_damage_reduction_or_no_damage_from_pkmn_power_effects(e, dmg)
      @atk.dealt_damage += dmg if e == PLAY_AREA_ARENA
      @ui.event(:damage, d.name, e, dmg, anim)
      subtract_hp(d, e, dmg)
      if d.slot_hp[e] == 0
        @ui.message(_INTL("{1} was Knocked Out!", d.card(d.play_area[e]).name))
      end
      handle_strikes_back_against_damaging_attack(e, dmg)
    end
  end
end
