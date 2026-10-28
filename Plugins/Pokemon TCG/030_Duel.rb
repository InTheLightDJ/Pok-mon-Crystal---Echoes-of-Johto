#==============================================================================
# Pokemon TCG - duel controller. Ports StartDuel / HandleDuelSetup /
# MainDuelLoop / HandleTurn from src/engine/duel/core.asm.
#
# Decisions are delegated to a controller per duelist (TCG::PlayerController
# drives the scene, TCG::AIController ports engine/duel/ai). Everything that
# the original printed/animated goes through @ui (TCG::DuelUI interface), so
# the engine can run headless with TCG::LogUI.
#==============================================================================
module TCG
  # Base UI sink. The scene overrides these; headless runs use LogUI.
  class DuelUI
    def message(text); end                         # DrawWideTextBox_WaitForInput
    def coin_toss(name, result); end              # TossCoin animation
    def refresh(duel); end                         # DrawDuelMainScene
    def event(type, *args); end                    # misc animations / sfx
    # true when the UI shows the original card screens for played cards
    # (then the engine/AI skip their plain text announcements)
    def shows_card_screens?; false; end
  end

  class LogUI < DuelUI
    attr_reader :log
    def initialize(echo = false); @log = []; @echo = echo; end
    def message(text); @log << text; puts(text) if @echo; end
    def coin_toss(name, result); message("#{name} coin: #{result == HEADS ? 'Heads' : 'Tails'}"); end
    def event(type, *args); message("[#{type}] #{args.join(' ')}") if @echo; end
  end

  class Duel
    attr_reader   :duelists, :controllers, :ui
    attr_accessor :turn, :duel_turns, :duel_finished, :duel_result,
                  :initial_prizes, :already_played_energy,
                  :confusion_retreat_check_unsuccessful,
                  :got_heads_sand_attack_check, :is_practice

    PLAYER   = 0
    OPPONENT = 1

    # player_deck / opp_deck: arrays of 60 card id symbols
    def initialize(player_name, player_deck, player_ctrl,
                   opp_name, opp_deck, opp_ctrl, prizes: 6, ui: DuelUI.new)
      @duelists = [Duelist.new(player_name, player_deck, DUELIST_TYPE_PLAYER),
                   Duelist.new(opp_name, opp_deck, DUELIST_TYPE_AI_OPP)]
      @controllers = [player_ctrl, opp_ctrl]
      @initial_prizes = prizes.to_i.clamp(1, MAX_PRIZES)
      @ui = ui
      @turn = PLAYER
    end

    #--------------------------------------------------------------------------
    # hWhoseTurn helpers
    #--------------------------------------------------------------------------
    def turn_duelist;     @duelists[@turn];     end
    def non_turn_duelist; @duelists[1 - @turn]; end
    def turn_controller;  @controllers[@turn];  end
    def swap_turn;        @turn = 1 - @turn;    end
    # run a block with the turn temporarily swapped (SwapTurn ... SwapTurn)
    def as_non_turn
      swap_turn
      yield
    ensure
      swap_turn
    end

    #--------------------------------------------------------------------------
    # StartDuel / MainDuelLoop
    #--------------------------------------------------------------------------
    # returns DUEL_WIN or DUEL_LOSS (from the player's perspective)
    def start
      init_variables_to_begin_duel
      handle_duel_setup
      main_duel_loop
      @duel_result
    end

    def init_variables_to_begin_duel
      @duel_finished = DUEL_NOT_FINISHED
      @duel_turns    = 0
    end

    def main_duel_loop
      loop do
        update_substatus_conditions_start_of_turn
        @ui.event(:turn_start, turn_duelist.name)
        handle_turn
        if @duel_finished == DUEL_NOT_FINISHED
          update_substatus_conditions_end_of_turn
          handle_between_turns_events
        end
        if @duel_finished != DUEL_NOT_FINISHED
          break unless handle_duel_finished
          next   # sudden death restarts the loop
        end
        @duel_turns += 1
        swap_turn
      end
    end

    # .duel_finished: returns true if a sudden death match starts
    def handle_duel_finished
      screens = @ui.shows_card_screens?
      screens ? @ui.event(:decision) : @ui.message(_INTL("Decision..."))
      case @duel_finished
      when TURN_PLAYER_WON
        @duel_result = (@turn == PLAYER) ? DUEL_WIN : DUEL_LOSS
      when TURN_PLAYER_LOST
        @duel_result = (@turn == PLAYER) ? DUEL_LOSS : DUEL_WIN
      else
        if screens
          @ui.event(:duel_result, :draw)
        else
          @ui.message(_INTL("The duel was a draw!"))
          @ui.message(_INTL("Start Sudden Death Match!"))
        end
        @initial_prizes = 1
        init_variables_to_begin_duel
        @turn = PLAYER
        handle_duel_setup
        return true
      end
      if screens
        @ui.event(:duel_result, @duel_result == DUEL_WIN ? :win : :loss)
      else
        @ui.message(@duel_result == DUEL_WIN ? _INTL("You won the duel!") : _INTL("You lost the duel..."))
      end
      false
    end

    #--------------------------------------------------------------------------
    # HandleDuelSetup
    #--------------------------------------------------------------------------
    def handle_duel_setup
      loop do
        @duelists.each(&:reset)
        p_ok = shuffle_deck_and_draw_seven_cards(@duelists[PLAYER])
        o_ok = shuffle_deck_and_draw_seven_cards(@duelists[OPPONENT])
        @ui.event(:shuffle_draw, nil)             # PlayShuffleAndDrawCardsAnimation_BothDuelists
        unless p_ok || o_ok                       # .neither_drew_basic_pkmn
          @ui.event(:no_basic, nil)
          next
        end
        [[p_ok, PLAYER], [o_ok, OPPONENT]].each do |ok, who|
          next if ok
          d = @duelists[who]
          loop do
            if @ui.shows_card_screens?
              @ui.event(:no_basic, d.name)        # DisplayNoBasicPokemonInHandScreenAndText
            else
              @ui.message(_INTL("{1} has no Basic Pokémon. Return cards to Deck and draw again.", d.name))
            end
            d.reset
            ok = shuffle_deck_and_draw_seven_cards(d)
            @ui.event(:shuffle_draw, d.name)      # PlayShuffleAndDrawCardsAnimation_TurnDuelist
            break if ok
          end
        end
        break
      end
      saved = @turn
      @turn = PLAYER
      choose_initial_arena_and_bench_pokemon
      swap_turn
      choose_initial_arena_and_bench_pokemon
      swap_turn
      @turn = saved
      @duelists.each { |d| init_duelist_prizes(d) }
      @ui.event(:place_prizes, @initial_prizes)
      # coin toss: the turn holder flips; heads = goes first
      flipper = turn_duelist
      if @ui.shows_card_screens?
        @ui.event(:coin_toss_intro)               # BOXMSG_COIN_TOSS + CoinTossToDecide...
        @coin_text = _INTL("If heads,\n{1} plays first.", flipper.name)
      else
        @ui.message(_INTL("{1} will toss a coin to decide who goes first.", flipper.name))
      end
      res = toss_coin(flipper.name)
      swap_turn if res == TAILS
      @ui.event(:play_order, turn_duelist.player?)
      @ui.refresh(self)
    end

    # ShuffleDeckAndDrawSevenCards: returns true if a basic Pokemon was drawn
    # (Mysterious Fossil / Clefairy Doll do NOT count here)
    def shuffle_deck_and_draw_seven_cards(d)
      unless @is_practice
        d.shuffle_deck
        d.shuffle_deck
      end
      STARTING_HAND_SIZE.times { d.add_card_to_hand(d.draw_card_from_deck) }
      d.hand.any? { |i| d.card(i).basic? }
    end

    # IsLoadedCard1BasicPokemon (fossil/doll count)
    def playable_as_basic?(d, idx)
      id = d.card_id(idx)
      return true if id == :MYSTERIOUS_FOSSIL || id == :CLEFAIRY_DOLL
      d.card(idx).basic?
    end

    def choose_initial_arena_and_bench_pokemon
      d = turn_duelist
      ctrl = turn_controller
      arena = ctrl.choose_initial_arena(self)
      put_basic_pokemon_in_play_area(arena)
      loop do
        break if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        idx = ctrl.choose_initial_bench(self)
        break if idx.nil?
        put_basic_pokemon_in_play_area(idx)
      end
    end

    # PutHandPokemonCardInPlayArea, converting Fossil/Doll like the original
    # (ConvertSpecialTrainerCardToPokemon is applied when they are played)
    def put_basic_pokemon_in_play_area(idx)
      d = turn_duelist
      e = d.put_hand_pokemon_card_in_play_area(idx)
      convert_special_trainer_card_to_pokemon(d, e) if e
      e
    end

    def init_duelist_prizes(d)
      @initial_prizes.times do |i|
        idx = d.draw_card_from_deck
        d.prize_cards[i] = idx
        d.card_locations[idx] = CARD_LOCATION_PRIZE
      end
      d.prizes = (1 << @initial_prizes) - 1
    end

    #--------------------------------------------------------------------------
    # HandleTurn
    #--------------------------------------------------------------------------
    def handle_turn
      d = turn_duelist
      set_all_play_area_pokemon_can_evolve(d) if @duel_turns >= 2
      init_variables_to_begin_turn
      display_draw_n_cards(d, 1)
      idx = d.draw_card_from_deck
      if idx.nil?
        @ui.message(_INTL("{1} has no cards left in the Deck and cannot draw.", d.name)) unless @ui.shows_card_screens?
        @duel_finished = TURN_PLAYER_LOST
        return
      end
      d.add_card_to_hand(idx)
      @ui.event(:draw, d.name, idx, :turn)
      turn_controller.take_turn(self)
    end

    # DisplayDrawNCardsScreen, shown before the cards are drawn; `text` is the
    # plain message for UIs without the card screens
    def display_draw_n_cards(d, n, text = nil)
      if @ui.shows_card_screens?
        @ui.event(:draw_n, d.name, n)
      elsif text
        @ui.message(text)
      end
    end

    def init_variables_to_begin_turn
      @already_played_energy = false
      @confusion_retreat_check_unsuccessful = false
      @got_heads_sand_attack_check = false
    end

    def set_all_play_area_pokemon_can_evolve(d)
      d.num_in_play_area.times do |e|
        d.slot_flags[e] &= ~USED_PKMN_POWER_THIS_TURN
        d.slot_flags[e] |= CAN_EVOLVE_THIS_TURN
      end
    end

    # TakeAPrizes: update prize bitmask after drawing n prizes
    def take_a_prizes(d, n)
      return if n == 0
      left = [d.count_prizes - n, 0].max
      d.prizes = (1 << left) - 1
    end

    #--------------------------------------------------------------------------
    # coin tosses (home/coin_toss.asm)
    #--------------------------------------------------------------------------
    def toss_coin(name = turn_duelist.name)
      res = TCG.rng.rand(2)
      @ui.coin_toss(name, res)
      res
    end

    # returns number of heads
    def toss_coins(n, name = turn_duelist.name)
      (0...n).count { toss_coin(name) == HEADS }
    end

    # filled in by later scripts
    def update_substatus_conditions_start_of_turn; end
    def update_substatus_conditions_end_of_turn; end
    def handle_between_turns_events; end
    def convert_special_trainer_card_to_pokemon(d, e); end
  end
end
