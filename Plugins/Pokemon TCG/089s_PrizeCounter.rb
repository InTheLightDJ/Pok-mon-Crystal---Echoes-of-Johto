#==============================================================================
# Pokemon TCG - PvP win streak and the Prize Counter (not in the original;
# server: handlers/tcg_prizes.js)
#
# Win streak: online card duels won in a row, kept by the server. A PvP win
# adds 1, any loss (or leaving a duel) resets it to 0. Online AI duels
# (InTheLight) count only while the streak is under 5. The last streak the
# server sent is saved, so the Trainer Card's Medals page (089f) can show it
# offline too; bragged cards show it in the chat (089n).
#
# Prize Counter (pbTCGPrizeCounter, from an NPC event; online only): one card
# per prize, the same for every player. A prize costs that many wins out of
# the streak; the server puts a new card in its place right away, and all of
# them change every day.
#    1  a Base set Basic Pokémon             25  a legendary
#    3  a Base/Neo Basic Pokémon holo        30  a legendary holo
#    5  a Base set holo (Imakuni too)        40  Shadow Lugia
#   10  a Base/Neo holo                      50  Shadow Lugia holo
#   20  any holo
# (no legendaries or Shadow Lugia below 25). A holo prize's hidden grade
# (089o) is 9 or 10, +1 with the PSA+1 ability (max 10).
#   Arrow keys  pick a prize
#   A           trade wins for it
#   B           back
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_streak, :tcg_streak_best
  def tcg_streak;      @tcg_streak || 0;      end
  def tcg_streak_best; @tcg_streak_best || 0; end
end

module TCG
  # the last pbTCGDuel's result (DUEL_WIN / DUEL_LOSS / nil)
  class << self
    attr_accessor :last_duel_result
  end

  module PrizeCounter
    CLERK        = "jennifer"   # her portrait (Graphics/.../Duelists)
    PRIZE_GRADES = (9..10)      # a holo prize's hidden grade

    module_function

    # this session's value from the server (it can come before the save is
    # loaded), else the last one saved
    def streak; sync; @live ? @live[0] : (TCG.global ? TCG.global.tcg_streak : 0); end
    def best;   sync; @live ? @live[1] : (TCG.global ? TCG.global.tcg_streak_best : 0); end

    def set_streak(s, b = nil)
      s = s.to_i
      old_best = @live ? @live[1] : (TCG.global ? TCG.global.tcg_streak_best : 0)
      @live = [s, [b ? b.to_i : old_best, s].max]
      sync
    end

    def sync
      return unless @live && TCG.global
      TCG.global.tcg_streak, TCG.global.tcg_streak_best = @live
    end

    # the server's prizes: [{ :slot, :cost, :id }] (cards this game doesn't
    # know, from a newer update, are left out)
    def import(d)
      return nil unless d
      set_streak(d["streak"], d["best"]) if d["streak"]
      prizes = Array(d["prizes"]).each_with_index.map do |p, i|
        id = p["card"].to_s.to_sym
        CARDS[id] ? { :slot => i, :cost => p["cost"].to_i, :id => id } : nil
      end
      { :prizes => prizes.compact, :restock_at => System.uptime + d["restock_in"].to_i }
    end

    def list; import(CardTrader.request({ action: "tcg_prize_list" }, "tcg_prize_list")); end

    # a prize won: into the collection, a holo with its hidden 9-10 grade
    def give(id)
      TCG.add_card(id)
      Grades.import_record(id, [Grades.new_grade(rand(PRIZE_GRADES)), 0, false]) if TCG.holo?(id)
      TCG.force_save
    end

    def card_name(id); TCG.holo?(id) ? Grades.full_name(id) : TCG.card(id).name; end

    def open
      unless NetPvP.online?
        pbMessage(_INTL("Welcome to the Prize Counter! Connect to the server to trade your win streak for prizes."))
        return
      end
      stock = list
      unless stock
        pbMessage(_INTL("No response from server."))
        return
      end
      pbFadeOutIn do
        scene = DuelScene.new
        begin
          scene.with_shop_layer(stock) { scene.prize_counter_front }
        ensure
          scene.dispose
        end
      end
    end
  end

  class DuelScene
    #--------------------------------------------------------------------------
    # the counter: the clerk, the player's streak; Prizes / Leave
    #--------------------------------------------------------------------------
    def prize_counter_front
      prize_draw_front
      shop_say(_INTL("Welcome to the Prize Counter! Win card duels in a row, then trade your streak for prizes!"))
      pos = 0
      loop do
        prize_draw_front
        @map.wide_text_box
        [[2, 14, _INTL("Prizes")], [12, 14, _INTL("Leave")]].each { |x, y, t| @map.text(x, y, t) }
        @map.text(2, 16, _INTL("Prizes cost wins in a row"))
        render
        shop_draw_pics
        pos = check_menu_cursor(pos, [0, 1])
        break if pos != 0
        prize_list_screen
      end
      shop_say(_INTL("Come back with a bigger streak!"))
    end

    def prize_draw_front
      @map.clear
      @shop[:pics] = []
      @map.text(4, 0, _INTL("PRIZE COUNTER"))
      @map.picture(1, 2, "Duelists/#{PrizeCounter::CLERK}", 6, 6)
      @map.text(8, 2, _INTL("PvP win streak"))
      @map.text(8, 4, _INTL("Now: {1}", PrizeCounter.streak))
      @map.text(8, 5, _INTL("Best: {1}", PrizeCounter.best))
      mins = ((@shop[:stock][:restock_at] - System.uptime) / 60.0).ceil.clamp(0, 99_999)
      @map.text(8, 7, _INTL("New prizes in"))
      @map.text(8, 8, _INTL("{1}h {2}m", mins / 60, mins % 60))
      @map.text(1, 10, _INTL("Holo prizes: PSA 9-10"))
      render
    end

    #--------------------------------------------------------------------------
    # the prizes: the picked one large on top, all of them in the grid
    #--------------------------------------------------------------------------
    def prize_list_screen
      cur = 0
      loop do
        prizes = @shop[:stock][:prizes]
        return shop_say(_INTL("There are no prizes right now. Come back later!")) if prizes.empty?
        cur = cur.clamp(0, prizes.size - 1)
        prize_draw_list(prizes, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          prize_claim(prizes[cur])
        else
          n = shop_move(cur, key, prizes.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def prize_draw_list(prizes, cur)
      @map.clear
      @shop[:pics] = []
      @map.text(1, 0, _INTL("Prizes"))
      t = _INTL("Streak: {1}", PrizeCounter.streak)
      @map.text(19 - Screens.text_tiles(t), 0, t)
      pr = prizes[cur]
      shop_draw_big_card(pr[:id])
      @map.text(10, 4, _INTL("Cost: {1} wins", pr[:cost]))
      @map.text(10, 5, TCG.holo?(pr[:id]) ? _INTL("PSA 9-10 hidden") : _INTL("You have {1}", TCG.card_count(pr[:id])))
      @map.text(10, 6, _INTL("Need {1} more", pr[:cost] - PrizeCounter.streak)) if PrizeCounter.streak < pr[:cost]
      @map.box(0, 7, 20, 11)
      prizes.each_with_index do |p, i|
        cy = CardShop::GRID_Y[i / 4] or next
        shop_pic(CardShop::GRID_X[i % 4], cy, :gfx => TCG.card(p[:id]).gfx, :sel => i == cur,
                 :label => p[:cost].to_s)
      end
      render
      shop_draw_pics
    end

    def prize_claim(pr)
      id = pr[:id]
      if PrizeCounter.streak < pr[:cost]
        shop_say(_INTL("This prize takes a streak of {1} wins. Yours is {2}.", pr[:cost], PrizeCounter.streak))
        return
      end
      name = PrizeCounter.card_name(id)
      return unless shop_yes_no(_INTL("Trade {1} wins from your streak for {2}?", pr[:cost], name))
      d = CardTrader.request({ action: "tcg_prize_claim", slot: pr[:slot], card: id.to_s }, "tcg_prize_result")
      unless d
        shop_say(_INTL("No response from server."))
        return
      end
      PrizeCounter.set_streak(d["streak"]) if d["streak"]
      if d["ok"]
        PrizeCounter.give(id)
        shop_say(_INTL("Congratulations! You won {1}!", name))
      else
        shop_say(d["message"].to_s.empty? ? _INTL("You couldn't get that prize.") : d["message"].to_s)
      end
      # the claimed prize (or one someone else took) has a new card now
      fresh = PrizeCounter.list
      @shop[:stock] = fresh if fresh
    end
  end
end

def pbTCGPrizeCounter; TCG::PrizeCounter.open; end
def pbTCGWinStreak;    TCG::PrizeCounter.streak; end

# the server sends the streak at login and whenever it changes
if defined?(NetworkClient)
  NetworkClient.on("tcg_streak") { |d| TCG::PrizeCounter.set_streak(d["streak"], d["best"]) }
end
