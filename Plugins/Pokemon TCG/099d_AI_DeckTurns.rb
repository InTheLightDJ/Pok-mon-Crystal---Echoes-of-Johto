#==============================================================================
# Pokemon TCG - per-deck .do_turn routines (engine/duel/ai/decks/*.asm
# AIDoTurn_*). Each is the original's exact call sequence written as a step
# list; decks using AIMainTurnLogic keep 090's take_turn.
#
# steps: :init, :anti_mewtwo (no carry -> straight to attack), [:ph, n],
#  :powers_pre / :powers_post (Pkmn Power blocks, may end the turn),
#  :play (AIDecidePlayPokemonCard, "ret c"), :play_nr (no ret c), :retreat,
#  :energy, [:energy_arena, ids..] (attach to an energyless Active first),
#  :etrans_attack, :moltres37, :oak (continue only if Prof. Oak was used),
#  :attack (end: try to attack; :attack_etrans also runs Energy Trans to bench)
#==============================================================================
module TCG
  class AIController
    AI_DECK_TURNS = {
      :AIDoTurn_GeneralNoRetreat => [
        :init, [:ph, 1], :anti_mewtwo, :powers_pre, [:ph, 2], [:ph, 3], [:ph, 4], :play,
        [:ph, 5], [:ph, 6], [:ph, 7], [:ph, 8], [:ph, 10], [:ph, 11], [:ph, 12], :energy, :play_nr,
        :powers_post, :etrans_attack, [:ph, 13], [:ph, 15], :oak,
        [:ph, 1], [:ph, 2], [:ph, 3], [:ph, 4], :play,
        [:ph, 5], [:ph, 6], [:ph, 7], [:ph, 8], [:ph, 10], [:ph, 11], [:ph, 12], :energy, :play_nr,
        :powers_post, [:ph, 13], :attack],
      :AIDoTurn_LegendaryMoltres => [
        :init, :anti_mewtwo, [:ph, 2], [:ph, 4], :moltres37, :play, [:ph, 5], :retreat,
        [:ph, 10], [:ph, 11], [:energy_arena, :MAGMAR_LV31], :play_nr, [:ph, 13], :attack],
      :AIDoTurn_LegendaryZapdos => [
        :init, :anti_mewtwo, [:ph, 1], [:ph, 4], :play, [:ph, 7], :retreat, [:ph, 10],
        :energy_zapdos, :play, [:ph, 13], :attack],
      :AIDoTurn_LegendaryArticuno => [
        :init, [:ph, 1], :anti_mewtwo, [:ph, 2], :play, :retreat, [:ph, 10], :energy, :play_nr,
        [:ph, 13], [:ph, 15], :oak,
        [:ph, 1], [:ph, 2], :play, :retreat, [:ph, 10], :energy, :play_nr, :attack],
      :AIDoTurn_LegendaryDragonite => [
        :init, [:ph, 1], :anti_mewtwo, [:ph, 2], :play, [:ph, 7], :retreat, [:ph, 10], [:ph, 11],
        [:energy_arena, :KANGASKHAN], :play_nr, [:ph, 15], :oak,
        [:ph, 1], [:ph, 2], :play, [:ph, 7], :retreat, [:ph, 10], [:ph, 11], :energy, :play_nr, :attack],
      # (no anti-Mewtwo check in this deck)
      :AIDoTurn_LegendaryRonald => [
        :init, [:ph, 1], [:ph, 2], [:ph, 4], :moltres37, :play, [:ph, 5], [:ph, 7], :retreat,
        [:ph, 10], :energy, :play, [:ph, 15], :oak,
        [:ph, 1], [:ph, 2], [:ph, 4], :moltres37, :play, [:ph, 5], [:ph, 7], :retreat,
        [:ph, 10], :energy, :play, :attack]
    }

    alias_method :tcg_ai_general_take_turn, :take_turn
    def take_turn(duel)
      steps = AI_DECK_TURNS[(ai_table[:do_turn] || []).first]
      return tcg_ai_general_take_turn(duel) unless steps
      run_deck_turn(duel, steps)
    end

    def run_deck_turn(duel, steps)
      steps.each do |s|
        return if turn_over?(duel) && s != :init
        name, arg = s.is_a?(Array) ? s : [s, nil]
        case name
        when :init        then init_ai_turn_vars(duel)
        when :ph          then process_hand_trainer_cards(duel, arg)
        when :anti_mewtwo then return try_attack_only(duel) unless anti_mewtwo_deck_strategy(duel)
        when :powers_pre
          handle_go_go_rain_dance_energy(duel)
          handle_damage_swap(duel)
          return if handle_pkmn_powers(duel)
          handle_cowardice(duel)
        when :powers_post
          handle_damage_swap(duel)
          return if handle_pkmn_powers(duel)
          handle_go_go_rain_dance_energy(duel)
        when :play        then return if decide_play_pokemon_card(duel)
        when :play_nr     then decide_play_pokemon_card(duel)
        when :retreat     then process_retreat(duel)
        when :energy      then process_and_try_to_play_energy(duel) unless duel.already_played_energy
        when :energy_arena then energy_to_bare_arena_first(duel, [arg])
        when :energy_zapdos then energy_zapdos(duel)
        when :etrans_attack then handle_energy_trans(duel, :attack)
        when :moltres37   then play_moltres_lv37(duel)
        when :oak         then return try_attack_only(duel) if (@previous_flags & AI_FLAG_USED_PROFESSOR_OAK) == 0
        when :attack      then return try_attack_only(duel)
        end
      end
    end

    def try_attack_only(duel)
      return if turn_over?(duel)
      process_and_try_to_use_attack(duel)
    end

    # "if <id> is the Active with no energy, try attaching to it from hand;
    # otherwise the normal energy routine"
    def energy_to_bare_arena_first(duel, ids)
      return if duel.already_played_energy
      d = duel.turn_duelist
      if ids.include?(d.card_id(d.arena))
        return if d.hand.none? { |i| d.card(i).energy? }
        if d.energy_cards_in_slot(PLAY_AREA_ARENA).empty?
          return if try_to_play_energy_card(duel, PLAY_AREA_ARENA)
        end
      end
      process_and_try_to_play_energy(duel)
    end

    # Legendary Zapdos: Voltorb (only with Electrode Lv35 in hand) or
    # Electabuzz Lv35 get the bare-Active treatment
    def energy_zapdos(duel)
      return if duel.already_played_energy
      d = duel.turn_duelist
      id = d.card_id(d.arena)
      special = id == :ELECTABUZZ_LV35 || (id == :VOLTORB && d.hand.any? { |i| d.card_id(i) == :ELECTRODE_LV35 })
      return process_and_try_to_play_energy(duel) unless special
      energy_to_bare_arena_first(duel, [id])
    end

    # play Moltres Lv37 straight from hand (bench room, deck > 9, no Muk)
    def play_moltres_lv37(duel)
      d = duel.turn_duelist
      return if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
      return if d.cards_in_deck <= 9
      return if duel.toxic_gas_active?
      i = d.hand.find { |c| d.card_id(c) == :MOLTRES_LV37 } or return
      say(duel, _INTL("{1} placed {2} on the Bench.", d.name, d.card(i).name)) if duel.play_basic_pokemon(i) == :ok
    end
  end
end
