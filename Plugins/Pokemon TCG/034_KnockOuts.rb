#==============================================================================
# Pokemon TCG - knock outs, status condition queue and between-turn events.
# Port of src/engine/duel/core.asm L6827-L7580:
#   HandleBetweenTurnsEvents, DiscardAttachedPlusPowers/Defenders,
#   HandleSleepCheck, HandlePoisonDamage, ConvertSpecialTrainerCardToPokemon,
#   ApplyStatusConditionQueue, HandleBetweenTurnKnockOuts,
#   MoveAllTurnHolderKnockedOutPokemonToDiscardPile, ReplaceKnockedOutPokemon,
#   CountKnockedOutPokemon, CheckIfTurnDuelistPlayAreaPokemonAreAllKnockedOut
#==============================================================================
module TCG
  class Duel
    # HandleBetweenTurnKnockOuts .Data_6ed2, indexed by wDuelFinishParam
    # bit3 = turn holder took last prize, bit2 = opponent took last prize,
    # bit1 = opponent can't replace, bit0 = turn holder can't replace
    DUEL_FINISH_TABLE = [
      DUEL_NOT_FINISHED, TURN_PLAYER_LOST, TURN_PLAYER_WON,  TURN_PLAYER_TIED,
      TURN_PLAYER_LOST,  TURN_PLAYER_LOST, TURN_PLAYER_TIED, TURN_PLAYER_LOST,
      TURN_PLAYER_WON,   TURN_PLAYER_TIED, TURN_PLAYER_WON,  TURN_PLAYER_WON,
      TURN_PLAYER_TIED,  TURN_PLAYER_LOST, TURN_PLAYER_WON,  TURN_PLAYER_TIED
    ]

    #--------------------------------------------------------------------------
    # status condition queue (wStatusConditionQueue)
    #--------------------------------------------------------------------------
    # queue a status for side (0 player / 1 opp): status = (status & keep_mask) | new
    def queue_status_condition(side, keep_mask, new_status)
      @atk.status_queue << [side, keep_mask, new_status]
    end

    # returns true if any status was applied (and defender wasn't protected)
    def apply_status_condition_queue
      @duelists.each { |d| d.last_turn_status = 0 }
      return false if @atk.nil? || @atk.status_queue.empty?
      if check_no_damage_or_effect
        # only the turn holder's own conditions apply
        @atk.status_queue.each do |side, mask, st|
          apply_status_condition_to_arena_pokemon(side, mask, st) if side == @turn
        end
        return false
      end
      @atk.status_queue.each { |side, mask, st| apply_status_condition_to_arena_pokemon(side, mask, st) }
      true
    end

    def apply_status_condition_to_arena_pokemon(side, mask, st)
      d = @duelists[side]
      d.status           = (d.status & mask) | st
      d.last_turn_status = (d.last_turn_status & mask) | st
    end

    #--------------------------------------------------------------------------
    # HandleBetweenTurnsEvents
    #--------------------------------------------------------------------------
    def handle_between_turns_events
      d  = turn_duelist
      nd = non_turn_duelist
      something = arena_asleep_or_poisoned?(d) || (d.status & CNF_SLP_PRZ) == PARALYZED ||
                  arena_asleep_or_poisoned?(nd)
      unless something
        discard_attached_pluspowers(d)
        discard_attached_defenders(nd)
        return
      end
      @ui.event(:between_turns)
      # turn holder: poison, sleep, then paralysis wears off
      if d.status != 0
        unless handle_poison_damage(d)
          handle_sleep_check(d)
          if (d.status & CNF_SLP_PRZ) == PARALYZED
            d.status &= DOUBLE_POISONED
            @ui.refresh(self)
            @ui.event(:status_anim, d.name, :cured_paralysis)   # IsCuredOfParalysisText + HEAL
          end
        end
      end
      discard_attached_pluspowers(d)
      # non-turn holder: poison, sleep (no paralysis recovery)
      if nd.status != 0
        handle_sleep_check(nd) unless handle_poison_damage(nd)
      end
      discard_attached_defenders(nd)
      handle_between_turn_knock_outs
    end

    # IsArenaPokemonAsleepOrPoisoned
    def arena_asleep_or_poisoned?(d)
      return false if d.status == 0
      return true if (d.status & DOUBLE_POISONED) != 0
      (d.status & CNF_SLP_PRZ) == ASLEEP
    end

    def discard_attached_pluspowers(d)
      d.slot_pluspower.map! { 0 }
      move_card_to_discard_pile_if_in_play_area(d, :PLUSPOWER)
    end

    def discard_attached_defenders(d)
      d.slot_defender.map! { 0 }
      move_card_to_discard_pile_if_in_play_area(d, :DEFENDER)
    end

    def move_card_to_discard_pile_if_in_play_area(d, id)
      (0...DECK_SIZE).each do |i|
        next if (d.card_locations[i] & CARD_LOCATION_PLAY_AREA) == 0
        d.put_card_in_discard_pile(i) if d.card_id(i) == id
      end
    end

    # HandleSleepCheck: heads cures sleep
    def handle_sleep_check(d)
      return unless (d.status & CNF_SLP_PRZ) == ASLEEP
      coin_check(_INTL("{1} is still asleep. Sleep check! If Heads, it wakes up.", d.card(d.arena).name),
                 "#{d.card(d.arena).name}'s Sleep check.")
      if toss_coin(d.name) == HEADS
        d.status &= DOUBLE_POISONED
        if @ui.shows_card_screens?
          @ui.event(:status_anim, d.name, :cured_sleep)       # IsCuredOfSleepText + HEAL
        else
          @ui.message(_INTL("{1} woke up.", d.card(d.arena).name))
        end
      elsif @ui.shows_card_screens?
        @ui.event(:status_anim, d.name, :still_asleep)        # IsStillAsleepText + SLEEP
      end
      @ui.refresh(self)
    end

    # HandlePoisonDamage: returns true if the Pokemon was knocked out
    def handle_poison_damage(d)
      return false if (d.status & POISONED) == 0
      dmg = (d.status & 0x40) != 0 ? DBLPSN_DAMAGE : PSN_DAMAGE
      if @ui.shows_card_screens?
        # text, DUEL_ANIM_POISON, SubtractHP, DUEL_ANIM_DAMAGE_HUD, PrintKnockedOutIfHLZero
        hp_before = d.slot_hp[PLAY_AREA_ARENA]
        subtract_hp(d, PLAY_AREA_ARENA, dmg)
        @ui.event(:status_anim, d.name, :poison, dmg, hp_before)
        return d.slot_hp[PLAY_AREA_ARENA] == 0
      end
      @ui.event(:poison, d.name)
      @ui.message(_INTL("{1} received {2} damage due to Poison.", d.card(d.arena).name, dmg))
      subtract_hp(d, PLAY_AREA_ARENA, dmg)
      @ui.refresh(self)
      if d.slot_hp[PLAY_AREA_ARENA] == 0
        @ui.message(_INTL("{1} was Knocked Out!", d.card(d.arena).name))
        return true
      end
      false
    end

    #--------------------------------------------------------------------------
    # Clefairy Doll / Mysterious Fossil in play behave as 10 HP Colorless
    # Pokemon that can't retreat and have the "Discard" power.
    #--------------------------------------------------------------------------
    def convert_special_trainer_card_to_pokemon(d, e)
      id = d.card_id(d.play_area[e])
      return unless id == :MYSTERIOUS_FOSSIL || id == :CLEFAIRY_DOLL
      d.slot_hp[e] = 10
      d.slot_stage[e] = BASIC
    end

    #--------------------------------------------------------------------------
    # HandleDestinyBondAndBetweenTurnKnockOuts / HandleBetweenTurnKnockOuts
    #--------------------------------------------------------------------------
    def handle_destiny_bond_and_between_turn_knock_outs
      handle_destiny_bond_substatus
      handle_between_turn_knock_outs
    end

    # returns true (carry) if the duel finished
    def handle_between_turn_knock_outs
      @duelists.each { |x| clear_damage_reduction_substatus2(x) if x.arena && x.slot_hp[PLAY_AREA_ARENA] == 0 }
      param = 0
      # turn holder takes prizes for the opponent's knocked out Pokemon
      param = (param << 1) | (as_non_turn { take_prizes_for_knock_outs } ? 1 : 0)
      result = nil
      if param != 0 && !all_play_area_pokemon_knocked_out?(turn_duelist)
        c = count_knocked_out_pokemon(turn_duelist)
        opp_prizes = non_turn_duelist.count_prizes
        if opp_prizes - 1 >= c
          take_a_prizes(non_turn_duelist, c)
          result = TURN_PLAYER_WON
        end
      end
      if result.nil?
        # opponent takes prizes for the turn holder's knocked out Pokemon
        param = (param << 1) | (take_prizes_for_knock_outs ? 1 : 0)
        if param == 1 && !as_non_turn { all_play_area_pokemon_knocked_out?(turn_duelist) }
          result = TURN_PLAYER_LOST
        end
      end
      if result.nil?
        param = (param << 1) | (as_non_turn { replace_knocked_out_pokemon } ? 1 : 0)
        param = (param << 1) | (replace_knocked_out_pokemon ? 1 : 0)
        result = DUEL_FINISH_TABLE[param] if param != 0
      end
      @duel_finished = result if result
      move_all_knocked_out_pokemon_to_discard_pile(turn_duelist)
      move_all_knocked_out_pokemon_to_discard_pile(non_turn_duelist)
      @duelists.each(&:shift_pokemon_to_first_play_area_slots)
      @ui.refresh(self)
      !result.nil?
    end

    # Func_6fa5 (turn = the side whose Pokemon were knocked out): the OTHER side
    # takes prizes. returns true if that side has no prizes left.
    def take_prizes_for_knock_outs
      n = count_knocked_out_pokemon(turn_duelist)
      return false if n == 0
      as_non_turn do
        d = turn_duelist
        if @ui.shows_card_screens?
          left = d.count_prizes
          @ui.event(:will_draw_prizes, d.name, n)            # WillDrawNPrizesText
          r = turn_duelist_take_prizes(n)
          @ui.event(:drew_prizes, d.name, [n, left].min) unless d.player?   # DrewNPrizesText
          r
        else
          @ui.message(_INTL("{1} draws {2} Prize card(s).", d.name, n))
          turn_duelist_take_prizes(n)
        end
      end
    end

    # CountKnockedOutPokemon (Clefairy Doll / Mysterious Fossil don't count)
    def count_knocked_out_pokemon(d)
      (0...MAX_PLAY_AREA_POKEMON).count do |e|
        idx = d.play_area[e]
        idx && d.slot_hp[e] == 0 && !d.card(idx).trainer?
      end
    end

    def all_play_area_pokemon_knocked_out?(d)
      (0...MAX_PLAY_AREA_POKEMON).none? { |e| d.play_area[e] && d.slot_hp[e] > 0 }
    end

    def move_all_knocked_out_pokemon_to_discard_pile(d)
      (0...MAX_PLAY_AREA_POKEMON).each do |e|
        next if d.play_area[e].nil? || d.slot_hp[e] > 0
        d.move_play_area_card_to_discard_pile(e)
      end
    end

    def has_alive_pokemon_in_bench?(d)
      (1...MAX_PLAY_AREA_POKEMON).any? { |e| d.play_area[e] && d.slot_hp[e] > 0 }
    end

    # ReplaceKnockedOutPokemon (turn holder). returns true (carry) if the arena
    # was knocked out and there is nothing to replace it with.
    def replace_knocked_out_pokemon
      d = turn_duelist
      return false if d.arena.nil? || d.slot_hp[PLAY_AREA_ARENA] > 0
      d.clear_all_status_conditions
      return true unless has_alive_pokemon_in_bench?(d)
      choices = (1...MAX_PLAY_AREA_POKEMON).select { |e| d.play_area[e] && d.slot_hp[e] > 0 }
      e = turn_controller.choose_ko_replacement(self, choices)
      e = choices.first unless choices.include?(e)
      d.swap_play_area_pokemon(e, PLAY_AREA_ARENA)
      @ui.event(:ko_replace, d.name, d.arena)
      false
    end
  end
end
