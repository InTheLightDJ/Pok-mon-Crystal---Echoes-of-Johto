#==============================================================================
# Pokemon TCG - AI controller (port of src/engine/duel/ai).
# Step A: init.asm + decks/general.asm AIMainTurnLogic sequence.
# Sub-steps not ported yet fall back to SimpleAI behaviour (marked TODO).
#==============================================================================
module TCG
  AI_TRAINER_CARD_PHASES = (1..15).to_a
  AI_FLAG_USED_SWITCH        = 0x02
  AI_FLAG_USED_PROFESSOR_OAK = 0x04
  AI_MEWTWO_MILL             = 0x80

  class Duel
    # wPlayerAttackingCardIndex / wPlayerAttackingAttackIndex: last attack used
    attr_accessor :last_attacking_card_index, :last_attacking_attack_index

    alias_method :tcg_ai_use_attack_or_pokemon_power, :use_attack_or_pokemon_power
    def use_attack_or_pokemon_power
      unless @atk.pokemon_power?
        @last_attacking_card_index   = @atk.card_index
        @last_attacking_attack_index = @atk.attack_index
      end
      tcg_ai_use_attack_or_pokemon_power
    end
  end

  class AIController < SimpleAI
    attr_accessor :pokedex_counter, :peeked_prizes, :barrier_flag_counter,
                  :previous_flags, :tried_attack, :retreated_this_turn,
                  :play_area_card_to_switch, :deck_id

    def initialize(scene = nil, deck_id = nil)
      super(scene)
      @deck_id = deck_id
      init_ai_duel_vars
    end

    # InitAIDuelVars
    def init_ai_duel_vars
      @pokedex_counter = 5
      @peeked_prizes = 0xff
      @barrier_flag_counter = 0
      @previous_flags = 0
    end

    # InitAITurnVars
    def init_ai_turn_vars(duel)
      @pokedex_counter += 1
      @previous_flags = 0
      @tried_attack = false
      @retreated_this_turn = false
      ci, ai = duel.last_attacking_card_index, duel.last_attacking_attack_index
      if ci && ai && ai != 0 && duel.non_turn_duelist.card_id(ci) == :MEWTWO_LV53
        # the Player used Barrier last turn
        if (@barrier_flag_counter & AI_MEWTWO_MILL) != 0
          @barrier_flag_counter = AI_MEWTWO_MILL
        else
          @barrier_flag_counter += 1
          if @barrier_flag_counter >= 3
            nd = duel.non_turn_duelist
            if nd.card_id(nd.arena) == :MEWTWO_LV53 && !player_has_pokemon_other_than_mewtwo_lv53?(duel)
              @barrier_flag_counter = AI_MEWTWO_MILL
            else
              @barrier_flag_counter = 0
            end
          end
        end
      elsif (@barrier_flag_counter & AI_MEWTWO_MILL) != 0
        @barrier_flag_counter += 1
      else
        @barrier_flag_counter = 0
      end
    end

    # CheckIfPlayerHasPokemonOtherThanMewtwoLv53 (common.asm)
    def player_has_pokemon_other_than_mewtwo_lv53?(duel)
      nd = duel.non_turn_duelist
      (0...DECK_SIZE).any? do |i|
        loc = nd.card_locations[i]
        next false unless loc == CARD_LOCATION_DISCARD_PILE || (loc & CARD_LOCATION_PLAY_AREA) != 0
        c = nd.card(i)
        c.pokemon? && nd.card_id(i) != :MEWTWO_LV53
      end
    end

    def turn_over?(duel)
      duel.duel_finished != DUEL_NOT_FINISHED || duel.turn_duelist.arena.nil?
    end

    #--------------------------------------------------------------------------
    # AIMainTurnLogic (decks/general.asm)
    #--------------------------------------------------------------------------
    def take_turn(duel)
      init_ai_turn_vars(duel)
      process_hand_trainer_cards(duel, 1)
      unless anti_mewtwo_deck_strategy(duel)
        try_attack(duel)
        return
      end
      return if run_turn_body(duel, true)
      if (@previous_flags & AI_FLAG_USED_PROFESSOR_OAK) != 0
        process_hand_trainer_cards(duel, 1)
        return if run_turn_body(duel, false)
      end
      try_attack(duel)
    end

    # returns true if the turn ended
    def run_turn_body(duel, first_pass)
      if first_pass
        handle_go_go_rain_dance_energy(duel)
        handle_damage_swap(duel)
        return true if handle_pkmn_powers(duel)
        handle_cowardice(duel)
      end
      [2, 3, 4].each { |ph| process_hand_trainer_cards(duel, ph) } unless first_pass && false
      return true if decide_play_pokemon_card(duel)
      [5, 6, 7, 8].each { |ph| process_hand_trainer_cards(duel, ph) }
      process_retreat(duel)
      [10, 11, 12].each { |ph| process_hand_trainer_cards(duel, ph) }
      process_and_try_to_play_energy(duel) unless duel.already_played_energy
      decide_play_pokemon_card(duel)
      handle_damage_swap(duel)
      return true if handle_pkmn_powers(duel)
      handle_go_go_rain_dance_energy(duel)
      handle_energy_trans(duel, :attack)
      process_hand_trainer_cards(duel, 13)
      process_hand_trainer_cards(duel, 15) if first_pass
      turn_over?(duel)
    end

    def try_attack(duel)
      return if turn_over?(duel)
      handle_energy_trans(duel, :to_bench)
      process_and_try_to_use_attack(duel)
    end

    # AIProcessRetreat
    def process_retreat(duel)
      return if @retreated_this_turn || turn_over?(duel)
      return unless decide_whether_to_retreat(duel)
      e = decide_bench_pokemon_to_switch_to(duel)
      return if e.nil?
      @play_area_card_to_switch = e
      @retreated_this_turn = true
      process_hand_trainer_cards(duel, 9)
      if (@previous_flags & AI_FLAG_USED_SWITCH) != 0
        @previous_flags &= ~AI_FLAG_USED_SWITCH
        handle_energy_trans(duel, :retreat)
      else
        try_to_retreat(duel, e)
      end
    end

    #--------------------------------------------------------------------------
    # sub-steps — TODO: replace each with the port of its asm routine
    #--------------------------------------------------------------------------

    # trainer_cards.asm AIProcessHandTrainerCards(phase): see 099_AI_Trainers.rb

    # hand_pokemon.asm AIDecidePlayPokemonCard — returns true if turn ended
    def decide_play_pokemon_card(duel)
      d = duel.turn_duelist
      d.hand.select { |i| d.card(i).basic? }.each do |i|
        break if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        announce(duel, _INTL("{1} placed {2} on the Bench.", d.name, d.card(i).name)) if duel.play_basic_pokemon(i) == :ok
      end
      d.hand.select { |i| d.card(i).pokemon? && !d.card(i).basic? }.each do |i|
        t = duel.evolution_targets(i).first
        next unless t && !duel.cant_evolve_reason(i)
        announce(duel, _INTL("{1} evolved into {2}!", d.card(d.play_area[t]).name, d.card(i).name)) if duel.evolve_pokemon(i, t) == :ok
      end
      turn_over?(duel)
    end

    # energy.asm AIProcessAndTryToPlayEnergy
    def process_and_try_to_play_energy(duel)
      d = duel.turn_duelist
      en = d.hand.find { |i| d.card(i).energy? }
      return unless en
      target = (0...d.num_in_play_area).find { |e| needs_energy?(duel, d, e) } || 0
      if duel.play_energy_card(en, target) == :ok
        announce(duel, _INTL("{1} attached {2} to {3}.", d.name, d.card(en).name, d.card(d.play_area[target]).name))
      end
    end

    # retreat.asm
    def decide_whether_to_retreat(duel); false; end
    def decide_bench_pokemon_to_switch_to(duel)
      d = duel.turn_duelist
      (1...d.num_in_play_area).max_by { |e| d.slot_hp[e] }
    end
    def try_to_retreat(duel, e); end

    # attacks.asm AIProcessAndTryToUseAttack
    def process_and_try_to_use_attack(duel)
      d = duel.turn_duelist
      @scene&.refresh(duel)
      return if duel.cant_attack_reason
      opts = duel.attack_list.select { |ci, ai| duel.enough_energies_for_attack?(d, ci, ai) }
      best = opts.max_by { |ci, ai| d.card(ci).attacks[ai].damage }
      @tried_attack = true
      duel.use_attack(*best) if best
    end
  end
end
