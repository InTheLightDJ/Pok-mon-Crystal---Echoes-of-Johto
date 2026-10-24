#==============================================================================
# Pokemon TCG - end of the duel (MainDuelLoop.duel_finished)
#   "Decision..." box message, then the portraits with PrintDuelResultStats,
#   the blinking WIN / LOSE / DRAW sprites (DUEL_ANIM_DUEL_WIN/LOSS/DRAW) and
#   the result text; a draw goes on to "Start a Sudden-Death Match".
#==============================================================================
module TCG
  module Screens
    module_function

    # .PrintDuelistResultStats at d,e: player 8,8, opponent 1,1
    def duel_result_stats(map, duel)
      [[duel.duelists[0], 8, 8], [duel.duelists[1], 1, 1]].each do |du, x, y|
        map.text(x, y, "Prizes Left")
        map.text(x, y + 1, "Active Pokémon")
        map.text(x, y + 2, "Cards in Deck")
        two_digits(map, x + 7, y, du.count_prizes)
        map.text(x + 9, y, "Cards")
        map.text(x + 8, y + 1, du.num_in_play_area > 0 ? "Yes" : "None")
        two_digits(map, x + 7, y + 2, du.cards_in_deck)
        map.text(x + 9, y + 2, "Cards")
      end
    end

    # AnimFrameTable80 (result.png): frame 0 = player LOSE / opponent WIN,
    # 1 = player WIN / opponent LOSE, 2 = DRAW on both sides; [y, x, tile]
    RESULT_FRAMES = [
      [[-56, 32, 0], [-56, 40, 1], [-56, 48, 2], [-56, 56, 3], [-48, 64, 9], [-48, 56, 19],
       [-48, 48, 18], [-48, 40, 17], [-48, 32, 16], [-48, 24, 8], [-40, 24, 24], [-32, 32, 48],
       [-40, 32, 32], [-40, 40, 33], [-32, 40, 49], [-32, 48, 50], [-32, 56, 51], [-40, 64, 25],
       [-40, 48, 34], [-40, 56, 35], [-16, -40, 9], [-16, -80, 8], [-8, -80, 24], [-8, -40, 25],
       [-24, -72, 4], [-16, -72, 20], [-8, -72, 36], [-24, -64, 5], [-16, -64, 21], [-8, -64, 37],
       [0, -64, 53], [0, -72, 52], [0, -56, 40], [-8, -56, 38], [-16, -56, 22], [-24, -56, 6],
       [-24, -48, 7], [-16, -48, 23], [-8, -48, 39], [0, -48, 41]],
      [[-48, 64, 9], [-48, 24, 8], [-40, 24, 24], [-40, 64, 25], [-56, 32, 4], [-48, 32, 20],
       [-40, 32, 36], [-56, 40, 5], [-48, 40, 21], [-40, 40, 37], [-32, 40, 53], [-32, 32, 52],
       [-32, 48, 40], [-40, 48, 38], [-48, 48, 22], [-56, 48, 6], [-56, 56, 7], [-48, 56, 23],
       [-40, 56, 39], [-32, 56, 41], [-24, -72, 0], [-24, -64, 1], [-24, -56, 2], [-24, -48, 3],
       [-16, -40, 9], [-16, -48, 19], [-16, -56, 18], [-16, -64, 17], [-16, -72, 16], [-16, -80, 8],
       [-8, -80, 24], [0, -72, 48], [-8, -72, 32], [-8, -64, 33], [0, -64, 49], [0, -56, 50],
       [0, -48, 51], [-8, -40, 25], [-8, -56, 34], [-8, -48, 35]],
      [[-52, 24, 10], [-44, 24, 26], [-36, 24, 42], [-52, 32, 11], [-44, 32, 27], [-36, 32, 43],
       [-52, 40, 12], [-44, 40, 28], [-36, 40, 44], [-52, 48, 13], [-44, 56, 30], [-44, 48, 29],
       [-36, 48, 45], [-36, 56, 46], [-52, 56, 14], [-52, 64, 15], [-44, 64, 31], [-36, 64, 47],
       [-20, -80, 10], [-12, -80, 26], [-4, -80, 42], [-20, -72, 11], [-12, -72, 27], [-4, -72, 43],
       [-20, -64, 12], [-12, -64, 28], [-4, -64, 44], [-20, -56, 13], [-12, -48, 30], [-12, -56, 29],
       [-4, -56, 45], [-4, -48, 46], [-20, -48, 14], [-20, -40, 15], [-12, -40, 31], [-4, -40, 47]]
    ]
    RESULT_FRAME = { :win => 1, :loss => 0, :draw => 2 }   # AnimData172 / 173 / 174

    def result_frame(map, frame)
      map.objs.clear
      return unless frame
      RESULT_FRAMES[frame].each do |y, x, t|
        map.objs << [COIN_X + x, COIN_Y + y, t, false, false, "result"]
      end
    end
  end

  class DuelScene
    RESULT_BLINK = 30          # frame_data n, 30 / -1, 30
    RESULT_MIN_FRAMES = 120    # stands in for waiting on the result song

    def duel_result_screen(kind)
      opp = @duel.duelists[1].name
      Screens.duelist_portraits(@map, @duel, @portrait)
      Screens.duel_result_stats(@map, @duel)
      text = case kind
             when :win  then "You won the Duel with #{opp}!"
             when :loss then "You lost the Duel\nwith #{opp}..."
             else "The Duel with #{opp}\nwas a Draw!"
             end
      Screens.text_box_lines(@map, GB.wrap(text))
      TCG.play_bgm(kind == :win ? WIN_BGM : LOSS_BGM) unless kind == :draw
      f = 0
      loop do
        if f % RESULT_BLINK == 0
          Screens.result_frame(@map, (f / RESULT_BLINK).even? ? Screens::RESULT_FRAME[kind] : nil)
          @map.sym(18, 17, f >= RESULT_MIN_FRAMES && (f / 16).even? ? SYM_CURSOR_D : SYM_BOX_BOTTOM)
          render
        elsif f >= RESULT_MIN_FRAMES && f % 16 == 0
          @map.sym(18, 17, (f / 16).even? ? SYM_CURSOR_D : SYM_BOX_BOTTOM)
          render
        end
        frame
        f += 1
        break if f > RESULT_MIN_FRAMES && (Input.trigger?(Input::USE) || Input.trigger?(Input::BACK))
      end
      @map.objs.clear
      message("Start a Sudden-Death\nMatch for 1 Prize!", keep: true) if kind == :draw
    end

    alias_method :tcg_result_event, :event
    def event(type, *args)
      case type
      when :decision
        @map.clear
        @map.wide_text_box
        render
        show_banner(:decision)
        message("Decision...", keep: true)
        hide_banner
      when :duel_result then duel_result_screen(args[0])
      else tcg_result_event(type, *args)
      end
    end
  end
end
