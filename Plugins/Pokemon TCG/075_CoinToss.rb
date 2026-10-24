#==============================================================================
# Pokemon TCG - coin toss screen (_TossCoin, engine/duel/core.asm)
#   labeled text box with the effect's check text (COIN_TEXT, or the engine
#   check set through Duel#coin_check), "n/total" for several coins, the
#   spinning coin (DUEL_ANIM_COIN_SPIN) until A (player) or 30 frames (AI),
#   the toss animation, then the result face and the O / X tally.
#==============================================================================
module TCG
  class Duel
    # text for the next coin toss box (cleared after the toss / series)
    attr_accessor :coin_text
    # [coins already tossed, total] while toss_coins runs
    attr_reader :coin_series
    # effect function currently running (its coin text is COIN_TEXT[fn])
    attr_reader :current_effect_fn

    # the engine's own checks: plain message for text UIs, the original
    # coin box text for the duel scene
    def coin_check(plain, original)
      if @ui.shows_card_screens?
        @coin_text = original
      else
        @ui.message(plain)
      end
    end

    alias_method :tcg_coin_try_execute_effect_command, :try_execute_effect_command
    def try_execute_effect_command(phase)
      old = @current_effect_fn
      cmds = @atk&.effect_name && EFFECT_TABLE[@atk.effect_name]
      entry = cmds && cmds.find { |p, _| p == phase }
      @current_effect_fn = entry && entry[1]
      tcg_coin_try_execute_effect_command(phase)
    ensure
      @current_effect_fn = old
    end

    alias_method :tcg_coin_toss_coin, :toss_coin
    def toss_coin(name = turn_duelist.name)
      r = tcg_coin_toss_coin(name)
      if @coin_series
        @coin_series = [@coin_series[0] + 1, @coin_series[1]]
      else
        @coin_text = nil
      end
      r
    end

    # TossCoinATimes: all coins on one screen
    def toss_coins(n, name = turn_duelist.name)
      return 0 if n <= 0
      @coin_series = [0, n]
      (0...n).count { toss_coin(name) == HEADS }
    ensure
      @coin_series = nil
      @coin_text = nil
    end
  end

  module Screens
    module_function

    # AnimFrameTable79: OAM entries [y, x, tile, xflip, yflip] per frame
    COIN_FRAMES = [
      [[-12, -12, 0], [-12, -4, 1], [-12, 4, 2], [-4, -12, 3], [-4, -4, 4], [-4, 4, 5],
       [4, -12, 6], [4, -4, 7], [4, 4, 8]],
      [[-8, -12, 17], [-8, -4, 18], [-8, 4, 17, true], [0, -12, 19], [0, -4, 20], [0, 4, 19, true]],
      [[-4, -12, 21], [-4, -4, 22], [-4, 4, 21, true]],
      [[-8, -12, 13], [-8, -4, 14], [-8, 4, 13, true], [0, -12, 15], [0, -4, 16], [0, 4, 15, true]],
      [[-12, -12, 9], [-12, -4, 10], [-12, 4, 9, true], [-4, -12, 11], [-4, -4, 12], [-4, 4, 11, true],
       [4, -12, 9, false, true], [4, -4, 10, false, true], [4, 4, 9, true, true]],
      [[0, -12, 13, false, true], [0, -4, 14, false, true], [0, 4, 13, true, true],
       [-8, -12, 15, false, true], [-8, -4, 16, false, true], [-8, 4, 15, true, true]],
      [[0, -12, 17, false, true], [0, -4, 18, false, true], [0, 4, 17, true, true],
       [-8, -12, 19, false, true], [-8, -4, 20, false, true], [-8, 4, 19, true, true]]
    ]
    # AnimData167 (spin, loops): [frame, duration]
    COIN_SPIN = [[0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [2, 4], [6, 4]]
    # AnimData168 / 169 (toss going heads / tails): [frame, y translation], 2 frames each
    TOSS_PATH = [[0, -7], [1, -7], [2, -6], [3, -6], [4, -5], [5, -5], [2, -4], [6, -4],
                 [0, -3], [1, -2], [2, -1], [3, 0], [4, 1], [5, 2], [2, 3], [6, 4],
                 [0, 4], [1, 5], [2, 5], [3, 6], [4, 6], [5, 7], [2, 7]]
    COIN_TOSS_HEADS = TOSS_PATH + [[6, -5], [0, -3], [1, -2], [2, -1], [3, 0], [4, 0],
                                   [5, 1], [2, 2], [6, 3], [0, 5]]
    COIN_TOSS_TAILS = TOSS_PATH + [[5, -5], [4, -3], [3, -2], [2, -1], [1, 0], [0, 0],
                                   [6, 1], [2, 2], [5, 3], [4, 5]]
    COIN_FACE_HEADS = 0   # AnimData170 (DUEL_ANIM_COIN_TAILS in the decomp's naming)
    COIN_FACE_TAILS = 4   # AnimData171
    # AnimationCoordinates[0] = OAM 88,88 -> screen pixels
    COIN_X = 88 - 8
    COIN_Y = 88 - 16

    def coin_frame(map, frame, dy = 0)
      map.objs.clear
      COIN_FRAMES[frame].each do |y, x, t, xf, yf|
        map.objs << [COIN_X + x, COIN_Y + dy + y, t, xf, yf]
      end
    end

    # _TossCoin: DrawLabeledTextBox 0,12 20x6 (no label), text at 1,14
    def coin_toss_screen(map, text)
      map.clear
      map.box(0, 12, 20, 6)
      map.text(1, 14, text.to_s, line_step: 2) if text
    end

    # "#coin/#total coins" at 15,11
    def coin_tally_count(map, n, total)
      two_digits(map, 15, 11, n)
      map.sym(17, 11, SYM_SLASH)
      two_digits(map, 18, 11, total)
    end

    # O ($30 = DuelOtherGraphics + $d) / X ($34) 2x2 at the top left, 10 a row
    def coin_tally_mark(map, k, heads)
      base = heads ? 0x0d : 0x11
      x = (k % 10) * 2
      y = (k / 10) * 2
      4.times { |i| map.put(x + i % 2, y + i / 2, [:other, base + i % 2 + 2 * (i / 2)]) }
    end
  end

  class DuelScene
    def coin_toss(name, result)
      k, total = @duel.coin_series || [0, 1]
      player = @duel.duelists[0].name == name
      if k == 0
        hide_banner
        text = @duel.coin_text || COIN_TEXT[@duel.current_effect_fn]
        Screens.coin_toss_screen(@map, text)
      end
      Screens.coin_tally_count(@map, k + 1, total) if total >= 2
      # DUEL_ANIM_COIN_SPIN until the player presses A / the AI waits 30 frames
      f = 0
      loop do
        step, = Screens::COIN_SPIN[(f / 4) % Screens::COIN_SPIN.size]
        if f % 4 == 0
          Screens.coin_frame(@map, step)
          render
        end
        frame
        f += 1
        break if player ? Input.trigger?(Input::USE) : f >= 30
      end
      # DUEL_ANIM_COIN_TOSS_GOING_HEADS / _TAILS (2 frames per step)
      dy = 0
      (result == HEADS ? Screens::COIN_TOSS_HEADS : Screens::COIN_TOSS_TAILS).each do |fr, ty|
        dy += ty
        Screens.coin_frame(@map, fr, dy)
        render
        2.times { frame }
      end
      Screens.coin_frame(@map, result == HEADS ? Screens::COIN_FACE_HEADS : Screens::COIN_FACE_TAILS)
      Screens.coin_tally_mark(@map, k, result == HEADS) if total >= 2
      render
      last = k + 1 >= total
      if player || last
        wait_text_box_input
      end
      30.times { frame } unless player
      @map.objs.clear if last
    end

    # Effects announce their coin flip with a plain message ("Damage check!
    # If Heads, ..."). The original prints that only inside the coin toss box,
    # so here it is dropped when COIN_TEXT has the effect's own text, or
    # becomes the box text when it doesn't.
    COIN_CHECK_TEXT = /(check|Heads|Tails)/

    alias_method :tcg_coin_message, :message
    def message(text, keep: false)
      if @duel && text.to_s =~ COIN_CHECK_TEXT && text.to_s !~ /was/
        @duel.coin_text ||= text.to_s unless COIN_TEXT[@duel.current_effect_fn]
        return
      end
      tcg_coin_message(text, keep: keep)
    end

    def event_coin_toss_intro
      @map.clear
      @map.wide_text_box
      render
      show_banner(:coin)
      message("A coin will be tossed\nto decide who plays first.", keep: true)
    end

    alias_method :tcg_coin_event, :event
    def event(type, *args)
      case type
      when :coin_toss_intro then event_coin_toss_intro
      when :play_order
        message(args[0] ? "You play first." : "You play second.", keep: true)
        @map.objs.clear
      else tcg_coin_event(type, *args)
      end
    end
  end
end
