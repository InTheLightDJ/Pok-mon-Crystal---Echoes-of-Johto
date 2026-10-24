#==============================================================================
# Pokemon TCG - effect function framework + shared helpers from the top of
# src/engine/duel/effect_functions.asm (L1-L1053).
#
# Effect functions are registered by their original names:
#   TCG.effect(:PoisonEffect) { |duel| ... }   # return true = carry
# and dispatched through TCG::EFFECT_TABLE (generated, 040_EffectTable.rb).
#
# Player/AI choices inside effects go through the turn controller:
#   controller.effect_choice(duel, kind, purpose, options, cancellable)
#     kind: :card (deck indices), :play_area (slots), :yes_no, :attack, :color
#     purpose: the effect function name (AI keys its logic on it)
#==============================================================================
module TCG
  EffectFunctions = {}

  def self.effect(name, &blk)
    EffectFunctions[name] = blk
  end

  class Duel
    # wWhoseTurn: the duelist whose turn it actually is (hWhoseTurn may be
    # temporarily swapped by effects)
    attr_accessor :whose_turn

    alias_method :tcg_init_variables_to_begin_turn, :init_variables_to_begin_turn
    def init_variables_to_begin_turn
      tcg_init_variables_to_begin_turn
      @whose_turn = @turn
    end

    # TryExecuteEffectCommandFunction via the generated table
    def try_execute_effect_command(phase)
      name = @atk&.effect_name
      return false unless name
      cmds = EFFECT_TABLE[name] or return false
      entry = cmds.find { |p, _| p == phase } or return false
      fn = EffectFunctions[entry[1]]
      unless fn
        @ui.event(:missing_effect, entry[1]) # not ported yet: no effect
        return false
      end
      fn.call(self) ? true : false
    end

    # does the current attack/trainer have a command for this phase?
    def has_effect_command?(phase)
      name = @atk&.effect_name
      cmds = name && EFFECT_TABLE[name]
      cmds ? cmds.any? { |p, _| p == phase } : false
    end

    # The duelist whose turn it actually is makes effect choices, even while
    # hWhoseTurn is temporarily swapped to look at the other side (SwapTurn).
    def effect_choice(kind, purpose, options, cancellable = false)
      ctrl = @controllers[@whose_turn || @turn]
      ctrl.effect_choice(self, kind, purpose, options, cancellable)
    end

    #--------------------------------------------------------------------------
    # QueueStatusCondition (target = non-turn holder of the current hWhoseTurn)
    # returns true (carry) if queued
    #--------------------------------------------------------------------------
    def queue_status(keep_mask, status)
      if @turn == @whose_turn
        tgt = @atk.temp_non_turn_card_id
        cant = tgt == :CLEFAIRY_DOLL || tgt == :MYSTERIOUS_FOSSIL
        if !cant && tgt == :SNORLAX
          cant = !as_non_turn { incapable_of_using_pkmn_power?(turn_duelist, PLAY_AREA_ARENA) }
        end
        if cant
          @atk.temp[:no_effect_from_which_status] = status
          set_no_effect_from_status
          return false
        end
      end
      queue_status_condition(1 - @turn, keep_mask, status)
      true
    end

    def set_no_effect_from_status; @atk.effect_failed = EFFECT_FAILED_NO_EFFECT; end
    def set_was_unsuccessful;     @atk.effect_failed = EFFECT_FAILED_UNSUCCESSFUL; end

    def player_turn?; turn_duelist.player?; end

    # SetDefiniteDamage
    def set_definite_damage(n); @atk.damage = n; end

    # ApplySubstatus1ToAttackingCard
    def apply_substatus1_to_attacking_card(v); turn_duelist.substatus1 = v; end

    # ApplySubstatus2ToDefendingCard
    def apply_substatus2_to_defending_card(v)
      return if check_no_damage_or_effect
      nd = non_turn_duelist
      nd.substatus2 = v
      nd.last_turn_substatus2 = v
    end

    # DealDamageToAllBenchedPokemon (turn holder's bench)
    def deal_damage_to_all_benched_pokemon(n)
      (1...turn_duelist.num_in_play_area).each { |e| deal_damage_to_play_area_pokemon(e, n) }
    end

    # CreateListOfEnergyAttachedToArena (by TYPE_ENERGY_* type byte)
    def list_of_energy_attached_to_arena(type)
      d = turn_duelist
      (0...DECK_SIZE).select { |i| d.card_locations[i] == CARD_LOCATION_ARENA && d.card(i).type == type }
    end

    def list_of_fire_energy_attached_to_arena
      list_of_energy_attached_to_arena(TYPE_NAMES["TYPE_ENERGY_FIRE"])
    end

    # HandleSwitchDefendingPokemonEffect(e): switch the defending Pokemon with
    # its bench slot e (nil = none selected)
    def handle_switch_defending_pokemon(e)
      return if e.nil?
      handle_destiny_bond_substatus if non_turn_duelist.slot_hp[PLAY_AREA_ARENA] == 0
      return if handle_no_damage_or_effect
      as_non_turn { turn_duelist.swap_arena_with_bench_pokemon(e) }
      @atk.defending_was_forced_to_switch = true
      @ui.refresh(self)
    end

    # HandleNoDamageOrEffect: true if no damage/effect (prints why)
    def handle_no_damage_or_effect; check_no_damage_or_effect; end

    # GetCardDamageAndMaxHP for turn holder's slot e -> [damage, max_hp]
    def card_damage_and_max_hp(d, e)
      max = d.card(d.play_area[e]).hp
      max = 10 if d.card(d.play_area[e]).trainer?   # fossil / doll
      [max - d.slot_hp[e], max]
    end

    # ApplyAndAnimateHPRecovery (turn holder's arena)
    def apply_and_animate_hp_recovery(n)
      d = turn_duelist
      dmg, max = card_damage_and_max_hp(d, PLAY_AREA_ARENA)
      return if dmg == 0
      @ui.event(:heal, d.name, PLAY_AREA_ARENA, n)
      d.slot_hp[PLAY_AREA_ARENA] = [d.slot_hp[PLAY_AREA_ARENA] + n, max].min
    end

    def play_area_has_any_damage?(d = turn_duelist)
      (0...d.num_in_play_area).any? { |e| card_damage_and_max_hp(d, e)[0] > 0 }
    end

    def shuffle_cards_in_deck(d = turn_duelist)
      @ui.event(:shuffle, d.name)
      d.shuffle_deck
    end

    # PickRandomPlayAreaCard
    def pick_random_play_area_card(d = turn_duelist); TCG.rng.rand(d.num_in_play_area); end
  end

  #----------------------------------------------------------------------------
  # status condition effects (effect_functions.asm L1-L40)
  #----------------------------------------------------------------------------
  effect(:PoisonEffect)            { |du| du.queue_status(CNF_SLP_PRZ, POISONED); false }
  effect(:DoublePoisonEffect)      { |du| du.queue_status(CNF_SLP_PRZ, DOUBLE_POISONED); false }
  effect(:ParalysisEffect)         { |du| du.queue_status(PSN_DBLPSN, PARALYZED); false }
  effect(:ConfusionEffect)         { |du| du.queue_status(PSN_DBLPSN, CONFUSED); false }
  effect(:SleepEffect)             { |du| du.queue_status(PSN_DBLPSN, ASLEEP); false }
  effect(:Poison50PercentEffect)   { |du| du.queue_status(CNF_SLP_PRZ, POISONED) if du.toss_coin == HEADS; false }
  effect(:Paralysis50PercentEffect){ |du| du.queue_status(PSN_DBLPSN, PARALYZED) if du.toss_coin == HEADS; false }
  effect(:Confusion50PercentEffect){ |du| du.queue_status(PSN_DBLPSN, CONFUSED) if du.toss_coin == HEADS; false }
  effect(:Sleep50PercentEffect)    { |du| du.queue_status(PSN_DBLPSN, ASLEEP) if du.toss_coin == HEADS; false }
end
