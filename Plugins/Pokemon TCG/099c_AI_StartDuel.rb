#==============================================================================
# Pokemon TCG - AI action-table entries other than the turn itself:
# .start_duel (InitAIDuelVars, boss_deck_set_up.asm SetUpBossStartingHandAndDeck,
# core.asm TrySetUpBossStartingPlayArea / AIPlayInitialBasicCards),
# .forced_switch / .ko_switch (AIDecideBenchPokemonToSwitchTo) and
# .take_prize (AIPickPrizeCards).
#==============================================================================
module TCG
  class Duel
    # the AI's .start_duel replaces the generic initial placement
    alias_method :tcg_ai_choose_initial_arena_and_bench, :choose_initial_arena_and_bench_pokemon
    def choose_initial_arena_and_bench_pokemon
      ctrl = turn_controller
      return ctrl.start_duel(self) if ctrl.respond_to?(:start_duel)
      tcg_ai_choose_initial_arena_and_bench
    end
  end

  class AIController
    def basic_pokemon_card?(c); c.type < TYPE_ENERGY && c.stage == BASIC; end

    #--------------------------------------------------------------------------
    # .start_duel
    #--------------------------------------------------------------------------
    def start_duel(duel)
      init_ai_duel_vars
      calls = ai_table[:start_duel] || [:InitAIDuelVars, :AIPlayInitialBasicCards]
      boss_set_up_starting_hand_and_deck(duel) if calls.include?(:SetUpBossStartingHandAndDeck)
      if calls.include?(:TrySetUpBossStartingPlayArea)
        return if try_set_up_boss_starting_play_area(duel)
      end
      # (Sam's practice deck's SetSamsStartingPlayArea is tutorial-scripted;
      # it falls back to the general placement here)
      ai_play_initial_basic_cards(duel)
    end

    # AIPlayInitialBasicCards: every Basic Pokemon in hand, in hand order
    # (the first one becomes the Active Pokemon). Doll/Fossil never.
    def ai_play_initial_basic_cards(duel)
      d = duel.turn_duelist
      d.hand.dup.each do |i|
        next unless basic_pokemon_card?(d.card(i))
        break if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        duel.put_basic_pokemon_in_play_area(i)
      end
    end

    # TrySetUpBossStartingPlayArea: Active from the arena list, then bench from
    # the bench list until 3 Pokemon are in play. true (no carry) on success.
    # (ORIGINAL: the "null list" check tests the list ADDRESS, so it never fails.)
    def try_set_up_boss_starting_play_area(duel)
      d = duel.turn_duelist
      list = d.hand.dup
      play_in_order = lambda do |ids|
        ids.each do |id|
          j = list.index { |i| d.card_id(i) == id } or next
          duel.put_basic_pokemon_in_play_area(list.delete_at(j))
          return d.num_in_play_area
        end
        nil
      end
      return false unless play_in_order.call(arena_priority_list)
      loop do
        n = play_in_order.call(bench_priority_list)
        break if n.nil? || n >= 3
      end
      true
    end

    # SetUpBossStartingHandAndDeck: reshuffle until the 7-card hand has >= 2
    # Basic Pokemon and >= 2 energy, and those plus the 6 cards after the
    # prizes reach >= 4 each. ORIGINAL BUG: the avoid-prize check
    # ("cp a" instead of "or a") never matches, so prizes are unconstrained.
    def boss_set_up_starting_hand_and_deck(duel)
      d = duel.turn_duelist
      STARTING_HAND_SIZE.times do
        i = d.hand.first
        d.remove_card_from_hand(i)
        d.return_card_to_deck(i)
      end
      first = true
      loop do
        d.shuffle_deck unless first
        first = false
        deck = d.deck_list
        b = e = 0
        tally = lambda do |cards|
          cards.each do |i|
            c = d.card(i)
            if c.type < TYPE_ENERGY then b += 1 if c.stage == BASIC
            elsif c.type != TYPE_TRAINER then e += 1
            end
          end
        end
        tally.call(deck[0, STARTING_HAND_SIZE])
        next if b < 2 || e < 2
        tally.call(deck[STARTING_HAND_SIZE + 6, 6])
        next if b < 4 || e < 4
        break
      end
      d.deck_list.first(STARTING_HAND_SIZE).each do |i|
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
      end
    end

    #--------------------------------------------------------------------------
    # .take_prize: AIPickPrizeCards (random untaken prize)
    #--------------------------------------------------------------------------
    def choose_prize(duel, avail); avail.sample; end

    #--------------------------------------------------------------------------
    # .ko_switch / .forced_switch: AIDecideBenchPokemonToSwitchTo
    #--------------------------------------------------------------------------
    def choose_ko_replacement(duel, choices)
      e = decide_bench_pokemon_to_switch_to(duel)
      choices.include?(e) ? e : choices.first
    end

    alias_method :tcg_ai_start_effect_choice, :effect_choice
    def effect_choice(duel, kind, purpose, options, cancellable)
      if purpose == :ForcedSwitch
        # DuelistSelectForcedSwitch swaps the turn before asking the AI
        e = duel.as_non_turn { decide_bench_pokemon_to_switch_to(duel) }
        return e if options.include?(e)
      end
      tcg_ai_start_effect_choice(duel, kind, purpose, options, cancellable)
    end
  end
end
