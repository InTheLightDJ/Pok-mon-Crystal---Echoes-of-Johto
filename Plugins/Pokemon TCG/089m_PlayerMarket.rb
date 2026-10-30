#==============================================================================
# Pokemon TCG - Player Market (in the Card Shop; server: handlers/tcg_market.js)
#
# Players sell holo cards to each other for Server Tokens. Only holo cards
# can be listed, and only spare copies (not ones in saved decks). A listing
# lasts 5 days; unsold, the card comes back. You can take a listing back
# any time. The seller is paid when the card sells, online or not.
#
# The listed card leaves your collection when the server takes the listing.
# Cards coming to you (bought, taken back, expired) are picked up whenever
# the market is opened; the game saves right after every change.
#
# Card Shop -> Market:
#   Browse        everyone's listings (yours marked); A buys / takes back
#   Sell a holo   your spare holo cards; A sets a price (Up/Down 1,
#                 Left/Right 10) and lists it
# Each holo copy's grade (089o_CardGrades.rb) goes with it: the server
# keeps it with the listing and hands it on to whoever gets the card, and
# listings show the grade of appraised copies.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_market_received
  # ids of the market deliveries this save has received (the newest ones)
  def tcg_market_received; @tcg_market_received ||= []; end
end

module TCG
  module PlayerMarket
    KEEP_RECEIVED = 500

    module_function

    def received
      TCG.global ? TCG.global.tcg_market_received : (@test_received ||= [])
    end

    # spare holo cards, in card list order
    def sellable; CardShop.sellable.select { |id| TCG.holo?(id) }; end

    def save_game; TCG.force_save; end

    # the server's market; adds the cards waiting for this player (once
    # each), tells the server, and returns the messages to show
    def import(d)
      return nil unless d
      NetworkTokens.set(d["tokens"]) if defined?(NetworkTokens) && d["tokens"]
      lines = []
      got = []
      Array(d["deliveries"]).each do |x|
        id = x["id"].to_i
        card = x["card"].to_s
        got << id
        next if received.include?(id) || !CardTrader.known?(card)
        TCG.add_card(card.to_sym)
        Grades.import_record(card.to_sym, x["grade"])   # the copy's grade comes with it (089o)
        received << id
        name = TCG.card(card.to_sym).name
        lines << case x["why"]
                 when "bought"  then _INTL("You got the {1} you bought!", name)
                 when "expired" then _INTL("Nobody bought your {1} in 5 days. It's back in your collection.", name)
                 else                _INTL("Your {1} is back in your collection.", name)
                 end
      end
      Array(d["notes"]).each do |n|
        card = n["card"].to_s
        name = CardTrader.known?(card) ? TCG.card(card.to_sym).name : card
        lines << _INTL("{1} bought your {2} for {3} Server Tokens!", n["buyer"].to_s, name, n["price"].to_i)
      end
      unless got.empty?
        received.shift(received.size - KEEP_RECEIVED) if received.size > KEEP_RECEIVED
        save_game
        NetworkClient.send_msg({ action: "tcg_market_ack", ids: got })
      end
      me = (NetworkAuth.username rescue nil).to_s.downcase
      listings = Array(d["listings"]).select { |l| CardTrader.known?(l["card"].to_s) }.map do |l|
        { :id => l["id"].to_i, :seller => l["seller"].to_s, :card => l["card"].to_s.to_sym, :price => l["price"].to_i,
          :ends_at => System.uptime + l["ends_in"].to_i, :mine => l["seller"].to_s.downcase == me,
          :psa => l["psa"] ? l["psa"].to_i : nil }
      end
      { :listings => listings, :lines => lines, :max_listings => d["max_listings"].to_i,
        :max_price => [d["max_price"].to_i, 1].max }
    end

    def fetch
      import(CardTrader.request({ action: "tcg_market_view" }, "tcg_market_view"))
    end

    # sends a post / buy / cancel; true when the server agreed (else shows why)
    def act(scene, msg)
      d = CardTrader.request(msg, "tcg_market_result")
      unless d
        scene.shop_say(_INTL("No response from server."))
        return false
      end
      NetworkTokens.set(d["tokens"]) if defined?(NetworkTokens) && d["tokens"]
      return true if d["ok"]
      scene.shop_say(d["message"].to_s.empty? ? _INTL("That didn't work.") : d["message"].to_s)
      false
    end

    # "4d 3h" / "5h 20m"
    def time_left(at)
      mins = ((at - System.uptime) / 60.0).ceil.clamp(0, 99_999_999)
      mins >= 24 * 60 ? _INTL("{1}d {2}h", mins / 1440, mins % 1440 / 60) : _INTL("{1}h {2}m", mins / 60, mins % 60)
    end
  end

  class DuelScene
    #--------------------------------------------------------------------------
    # the market's front: tokens, your listings; Browse / Sell a holo / Back
    #--------------------------------------------------------------------------
    def market_screen
      return unless market_refresh
      pos = 0
      loop do
        market_draw_front
        @map.wide_text_box
        [[2, 14, _INTL("Browse")], [12, 14, _INTL("Sell holo")], [2, 16, _INTL("Back")]].each { |x, y, t| @map.text(x, y, t) }
        pos = check_menu_cursor(pos, [0, 1, 2])
        case pos
        when 0 then market_browse
        when 1 then market_sell
        else return
        end
      end
    end

    # a fresh copy from the server (shows deliveries / sales); false if none
    def market_refresh
      m = PlayerMarket.fetch
      unless m
        shop_say(_INTL("No response from server."))
        return false
      end
      @market = m
      m[:lines].each { |l| shop_say(l) }
      true
    end

    def market_draw_front
      @map.clear
      @shop[:pics] = []
      @map.text(4, 0, _INTL("PLAYER MARKET"))
      @map.text(1, 2, _INTL("Sell holo cards to other"))
      @map.text(1, 3, _INTL("players for Server Tokens."))
      @map.text(1, 4, _INTL("Unsold cards come back"))
      @map.text(1, 5, _INTL("after 5 days."))
      mine = @market[:listings].count { |l| l[:mine] }
      @map.text(1, 7, _INTL("Tokens: {1}", CardShop.tokens))
      @map.text(1, 8, _INTL("For sale: {1}", @market[:listings].size))
      @map.text(1, 9, _INTL("Yours: {1}/{2}", mine, @market[:max_listings]))
      render
      shop_draw_pics
    end

    #--------------------------------------------------------------------------
    # Browse: the picked listing large on top, the listings in pages of 12
    #--------------------------------------------------------------------------
    def market_browse
      cur = 0
      loop do
        list = @market[:listings]
        if list.empty?
          shop_say(_INTL("Nobody is selling anything right now."))
          return
        end
        cur = cur.clamp(0, list.size - 1)
        market_draw_browse(list, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          market_pick(list[cur])
        else
          n = shop_move(cur, key, list.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def market_draw_browse(list, cur)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (list.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Market {1}/{2}", page + 1, pages))
      t = _INTL("Tokens: {1}", CardShop.tokens)
      @map.text(19 - Screens.text_tiles(t), 0, t)
      l = list[cur]
      shop_draw_big_card(l[:card])
      t = _INTL("{1} Tokens", l[:price])
      t += "  " + _INTL("PSA {1}", l[:psa]) if l[:psa]
      @map.text(10, 4, t)
      @map.text(10, 5, l[:mine] ? _INTL("Your card") : l[:seller][0, 16])
      @map.text(10, 6, _INTL("Ends {1}", PlayerMarket.time_left(l[:ends_at])))
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      list[first, CardShop::GRID_CELLS].each_with_index do |x, i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x[:card]).gfx,
                 :sel => first + i == cur,
                 :label => x[:mine] ? _INTL("YOURS") : (x[:psa] ? _INTL("PSA {1}", x[:psa]) : nil))
      end
      render
      shop_draw_pics
    end

    # buy someone's card / take your own back
    def market_pick(l)
      name = TCG.card(l[:card]).name
      if l[:mine]
        return unless shop_yes_no(_INTL("Take your {1} off the market?", name))
        return unless PlayerMarket.act(self, { action: "tcg_market_cancel", id: l[:id] })
      else
        if CardShop.tokens < l[:price]
          shop_say(_INTL("You need {1} Server Tokens for this card. You have {2}.", l[:price], CardShop.tokens))
          return
        end
        return unless shop_yes_no(_INTL("Buy {1} from {2} for {3} Server Tokens?", name, l[:seller], l[:price]))
        return unless PlayerMarket.act(self, { action: "tcg_market_buy", id: l[:id] })
      end
      market_refresh
    end

    #--------------------------------------------------------------------------
    # Sell a holo: your spare holo cards; A -> price -> list it
    #--------------------------------------------------------------------------
    # one entry per spare holo copy: [id, copy] (089o)
    def market_sell
      cur = 0
      loop do
        entries = Grades.spare_entries(PlayerMarket.sellable)
        if entries.empty?
          shop_say(_INTL("You have no spare holo cards. Only holo cards can be sold on the market."))
          return
        end
        cur = cur.clamp(0, entries.size - 1)
        market_draw_sell(entries, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          market_post(entries, cur)
        else
          n = shop_move(cur, key, entries.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    # price: the line under the card's tier while picking one
    def market_draw_sell(entries, cur, price = nil)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (entries.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Sell holo {1}/{2}", page + 1, pages))
      id, copy = entries[cur]
      shop_draw_big_card(id)
      if price
        @map.text(10, 4, _INTL("Price: {1}", price))
        @map.text(10, 5, _INTL("Up/Down: 1"))
        @map.text(10, 6, _INTL("L/R: 10"))
      else
        @map.text(10, 4, Grades.label(id, copy) || _INTL("Not appraised"))
        @map.text(10, 5, _INTL("A: set price"))
      end
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      entries[first, CardShop::GRID_CELLS].each_with_index do |(x, c), i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :label => Grades.label(x, c))
      end
      render
      shop_draw_pics
    end

    def market_post(entries, cur)
      id, copy = entries[cur]
      max = @market[:max_price]
      price = (@market_last_price || 10).clamp(1, max)
      loop do
        market_draw_sell(entries, cur, price)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE then break
        else
          step = { Input::UP => 1, Input::DOWN => -1, Input::RIGHT => 10, Input::LEFT => -10 }[key]
          n = (price + step.to_i).clamp(1, max)
          if n != price
            price = n
            pbPlayCursorSE
          end
        end
      end
      @market_last_price = price
      name = TCG.card(id).name
      return unless shop_yes_no(_INTL("List {1} for {2} Server Tokens for 5 days?", name, price))
      grade = Grades.record(id, copy)
      return unless PlayerMarket.act(self, { action: "tcg_market_post", card: id.to_s, price: price, grade: grade })
      Grades.remove_copy(id, copy)
      PlayerMarket.save_game
      shop_say(_INTL("{1} is on the market!", name))
      market_refresh
    end
  end
end
