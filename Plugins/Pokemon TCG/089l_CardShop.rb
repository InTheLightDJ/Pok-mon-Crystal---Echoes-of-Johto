#==============================================================================
# Pokemon TCG - Card Shop (not in the original; server: handlers/tcg_shop.js)
#
# Buy (online): 10 cards a day, one of them a holo, and a booster pack. Every
# player sees the same stock; each can buy each item once a day. Cards cost
# game money (3x their selling price), the pack costs Server Tokens.
# Sell (also offline): any card you have to spare (cards in saved decks
# can't be sold) for its HP x its holo level: a normal card is level 1, Blue
# 2, Yellow 3 ... Black & Red 12. Trainer and Energy cards: 5 x the level.
# Market (online): players sell holo cards to each other for Server Tokens
# (089m_PlayerMarket.rb).
#
# The card menu's "Card Shop" (or pbTCGCardShop) opens it.
#   Arrow keys  pick a card
#   A           buy / sell it
#   B           back
# The screens: the picked card large at the top (picture, name, price), the
# cards as small pictures in a grid below (holo sparkles, sold out ones
# dimmed); 089k_CardTrader.rb draws the small pictures.
#==============================================================================
module TCG
  module CardShop
    BUY_MULTIPLIER  = 3
    NO_HP_PRICE     = 5     # Trainer and Energy cards
    GRID_X          = [2, 6, 10, 14]   # tile x of the grid's columns
    GRID_Y          = [8, 11, 14]      # tile y of its rows
    GRID_CELLS      = GRID_X.size * GRID_Y.size

    module_function

    # no holo 1, then 1 more for each tier (Blue 2 ... Black & Red 12)
    def holo_level(id)
      t = TCG.holo_tier(id)
      t ? CardTrader.tier_index(t) + 2 : 1
    end

    def sell_price(id)
      card = TCG.card(id.to_sym)
      base = card.pokemon? ? CARDS[id.to_sym][:hp].to_i : NO_HP_PRICE
      base * holo_level(id)
    end

    def buy_price(id); sell_price(id) * BUY_MULTIPLIER; end

    def money; $player ? $player.money : (@test_money ||= 0); end

    def money=(v)
      v = v.clamp(0, Settings::MAX_MONEY) if defined?(Settings::MAX_MONEY)
      $player ? $player.money = v : @test_money = v
    end

    def tokens; defined?(NetworkTokens) ? NetworkTokens.balance : 0; end

    # cards with a copy to spare, in card list order
    def sellable; TCG.listing_order.select { |id| TCG.available_for_deck(id) > 0 }; end

    # "LABORATORY_PSYCHIC" -> "Laboratory Psychic"
    def pack_name(pack)
      pack.to_s.split("_").map(&:capitalize).join(" ")
    end

    def pack_art(pack)
      set = BOOSTER_PACKS[pack.to_sym] && BOOSTER_PACKS[pack.to_sym][:set]
      "Boosters/#{(set || :COLOSSEUM).to_s.downcase}"
    end

    # the server's shop for today
    def import(d)
      return nil unless d
      bought = Array(d["bought"]).map(&:to_i)
      items = Array(d["cards"]).each_with_index.map do |id, i|
        { :kind => :card, :id => id.to_s, :slot => i, :sold => bought.include?(i) }
      end
      if d["pack"]
        n = items.size
        items << { :kind => :pack, :pack => d["pack"].to_s, :slot => n, :cost => d["pack_cost"].to_i,
                   :sold => bought.include?(n) }
      end
      NetworkTokens.set(d["tokens"]) if defined?(NetworkTokens) && d["tokens"]
      { :date => d["date"].to_s, :items => items, :restock_at => System.uptime + d["restock_in"].to_i }
    end

    def open
      stock = nil
      if NetPvP.online?
        stock = import(CardTrader.request({ action: "tcg_shop_list" }, "tcg_shop_list"))
      end
      pbFadeOutIn do
        scene = DuelScene.new
        begin
          scene.card_shop_screen(stock)
        ensure
          scene.dispose
        end
      end
    end

    def changed!; TCG.force_save; end
  end

  class DuelScene
    #--------------------------------------------------------------------------
    # the shop's front: today's pack, money and tokens; Buy / Sell / Leave
    #--------------------------------------------------------------------------
    def card_shop_screen(stock)
      with_shop_layer(stock) { card_shop_front }
    end

    # the small-pictures layer the shop's screens draw on (also the Brag
    # screen, 089n); @shop holds the stock and this screen's pictures
    def with_shop_layer(stock = nil)
      @shop = { :stock => stock, :pics => [] }
      @shop_spr = Sprite.new(@viewport)
      @shop_spr.z = 5
      @shop_spr.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @shop_dim = Bitmap.new(1, 1)
      @shop_dim.fill_rect(0, 0, 1, 1, Color.new(0, 0, 0))
      @small_pics_redraw = method(:shop_draw_pics)
      yield
    ensure
      @small_pics_redraw = nil
      @shop_dim&.dispose
      @shop_spr&.bitmap&.dispose
      @shop_spr&.dispose
      @shop_spr = nil
      @shop = nil
    end

    def card_shop_front
      list_cb = NetworkClient.on("tcg_shop_list") { |d| @shop[:stock] = CardShop.import(d) } if defined?(NetworkClient)
      pos = 0
      loop do
        shop_draw_front
        @map.wide_text_box
        [[2, 14, _INTL("Buy")], [12, 14, _INTL("Sell")], [2, 16, _INTL("Market")], [12, 16, _INTL("Leave")]].each { |x, y, t| @map.text(x, y, t) }
        pos = check_menu_cursor(pos, [0, 1, 2, 3])
        case pos
        when 0
          if @shop[:stock]
            shop_buy_screen
          else
            shop_say(_INTL("Connect to the server to buy cards. You can still sell."))
          end
        when 1 then shop_sell_screen
        when 2
          if NetPvP.online?
            market_screen
          else
            shop_say(_INTL("Connect to the server to use the Player Market."))
          end
        else break
        end
      end
    ensure
      NetworkClient.remove("tcg_shop_list", list_cb) if list_cb
    end

    def shop_draw_front
      @map.clear
      @shop[:pics] = []
      @map.text(6, 0, _INTL("CARD SHOP"))
      stock = @shop[:stock]
      pack = stock && stock[:items].find { |it| it[:kind] == :pack }
      if pack
        shop_pic(2, 2, :pack => pack[:pack], :big => true, :sold => pack[:sold])
        @map.text(8, 2, _INTL("Today's pack:"))
        GB.wrap(CardShop.pack_name(pack[:pack]), 22).first(2).each_with_index { |l, n| @map.text(8, 3 + n, l) }
      end
      @map.text(8, 6, _INTL("Money: {1}", CardShop.money))
      @map.text(8, 7, _INTL("Tokens: {1}", CardShop.tokens)) if stock
      if stock
        mins = ((stock[:restock_at] - System.uptime) / 60.0).ceil.clamp(0, 99_999)
        @map.text(1, 10, _INTL("New stock in {1}h {2}m", mins / 60, mins % 60))
      else
        @map.text(1, 10, _INTL("Offline: you can only sell."))
      end
      render
      shop_draw_pics
    end

    #--------------------------------------------------------------------------
    # Buy: the picked item large on top, today's stock in the grid
    #--------------------------------------------------------------------------
    def shop_buy_screen
      cur = 0
      loop do
        items = @shop[:stock][:items]
        cur = cur.clamp(0, items.size - 1)
        shop_draw_buy(items, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          shop_buy(items[cur])
        else
          n = shop_move(cur, key, items.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def shop_draw_buy(items, cur)
      @map.clear
      @shop[:pics] = []
      @map.text(1, 0, _INTL("Buy"))
      shop_money_header
      it = items[cur]
      if it[:kind] == :pack
        shop_pic(3, 1, :pack => it[:pack], :big => true, :sold => it[:sold])
        GB.wrap(CardShop.pack_name(it[:pack]), 18).first(2).each_with_index { |l, n| @map.text(10, 1 + n, l) }
        @map.text(10, 3, _INTL("Booster Pack"))
        @map.text(10, 4, _INTL("Price: {1} Tokens", it[:cost]))
        @map.text(10, 5, _INTL("Tokens: {1}", CardShop.tokens))
      else
        id = it[:id].to_sym
        shop_draw_big_card(id)
        @map.text(10, 4, _INTL("Price: {1}", CardShop.buy_price(id)))
        @map.text(10, 5, _INTL("You have {1}", TCG.card_count(id)))
      end
      @map.text(10, 6, _INTL("SOLD OUT")) if it[:sold]
      @map.box(0, 7, 20, 11)
      items.each_with_index do |x, i|
        cx = CardShop::GRID_X[i % 4]
        cy = CardShop::GRID_Y[i / 4] or next
        if x[:kind] == :pack
          shop_pic(cx, cy, :pack => x[:pack], :sold => x[:sold], :sel => i == cur)
        else
          shop_pic(cx, cy, :gfx => TCG.card(x[:id].to_sym).gfx, :sold => x[:sold], :sel => i == cur)
        end
      end
      render
      shop_draw_pics
    end

    def shop_buy(it)
      if it[:sold]
        shop_say(_INTL("Sold out. It's back tomorrow."))
        return
      end
      if it[:kind] == :pack
        if CardShop.tokens < it[:cost]
          shop_say(_INTL("You need {1} Server Tokens for this pack. You have {2}.", it[:cost], CardShop.tokens))
          return
        end
        return unless shop_yes_no(_INTL("Buy the {1} pack for {2} Server Tokens?", CardShop.pack_name(it[:pack]), it[:cost]))
      else
        id = it[:id].to_sym
        price = CardShop.buy_price(id)
        if CardShop.money < price
          shop_say(_INTL("You don't have enough money. It costs {1}.", price))
          return
        end
        return unless shop_yes_no(_INTL("Buy {1} for {2}?", TCG.card(id).name, price))
      end
      d = CardTrader.request({ action: "tcg_shop_buy", date: @shop[:stock][:date], slot: it[:slot] }, "tcg_shop_result")
      unless d
        shop_say(_INTL("No response from server."))
        return
      end
      NetworkTokens.set(d["tokens"]) if defined?(NetworkTokens) && d["tokens"]
      unless d["ok"]
        shop_say(d["message"].to_s.empty? ? _INTL("You couldn't buy that.") : d["message"].to_s)
        return
      end
      it[:sold] = true
      if it[:kind] == :pack
        pack = it[:pack].to_sym
        cards = TCG.generate_booster(pack)
        TCG.add_cards(cards)
        CardShop.changed!
        @shop_spr.visible = false
        booster_pack_screen(pack, cards, false)
        @shop_spr.visible = true
      else
        id = it[:id].to_sym
        CardShop.money -= CardShop.buy_price(id)
        TCG.add_card(id)
        CardShop.changed!
        shop_say(_INTL("You bought {1}!", TCG.card(id).name))
      end
    end

    #--------------------------------------------------------------------------
    # Sell: the picked card large on top, your spare cards in pages of 12
    #--------------------------------------------------------------------------
    def shop_sell_screen
      cur = 0
      loop do
        ids = CardShop.sellable
        if ids.empty?
          shop_say(_INTL("You have no cards to sell. Cards in your decks can't be sold."))
          return
        end
        cur = cur.clamp(0, ids.size - 1)
        shop_draw_sell(ids, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          id = ids[cur]
          price = CardShop.sell_price(id)
          next unless shop_yes_no(_INTL("Sell 1 {1} for {2}?", TCG.card(id).name, price))
          TCG.remove_card(id)
          CardShop.money += price
          CardShop.changed!
        else
          n = shop_move(cur, key, ids.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def shop_draw_sell(ids, cur)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (ids.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Sell {1}/{2}", page + 1, pages))
      shop_money_header
      id = ids[cur]
      shop_draw_big_card(id)
      @map.text(10, 4, _INTL("Sell for {1}", CardShop.sell_price(id)))
      spare = TCG.available_for_deck(id)
      @map.text(10, 5, _INTL("Spare: {1}", spare))
      in_decks = TCG.card_count(id) - spare
      @map.text(10, 6, _INTL("In decks: {1}", in_decks)) if in_decks > 0
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      ids[first, CardShop::GRID_CELLS].each_with_index do |x, i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :count => TCG.available_for_deck(x))
      end
      render
      shop_draw_pics
    end

    #--------------------------------------------------------------------------
    # shared pieces
    #--------------------------------------------------------------------------
    # picture at 1,1; name (gold for a holo) and holo tier on the right
    def shop_draw_big_card(id)
      card = TCG.card(id)
      @map.picture(1, 1, card.gfx)
      GB.wrap(Screens.name_and_level(card), 18).first(2).each_with_index do |l, n|
        nx = @map.text(10, 1 + n, l)
        @map.palette(10, 1 + n, nx - 10, 1, PAL_HOLO_NAME) if card.holo?
      end
      @map.text(10, 3, _INTL("{1} Holo", TCG.holo_name(card.holo_tier))) if card.holo?
    end

    def shop_money_header
      t = _INTL("Money: {1}", CardShop.money)
      @map.text(19 - Screens.text_tiles(t), 0, t)
    end

    # grid movement: LEFT/RIGHT one card, UP/DOWN a row (4 cards)
    def shop_move(cur, key, n)
      step = { Input::LEFT => -1, Input::RIGHT => 1, Input::UP => -4, Input::DOWN => 4 }[key] or return cur
      nxt = cur + step
      nxt.between?(0, n - 1) ? nxt : cur
    end

    def shop_wait_key
      loop do
        frame
        [Input::USE, Input::BACK].each { |k| return k if Input.trigger?(k) }
        [Input::LEFT, Input::RIGHT, Input::UP, Input::DOWN].each { |k| return k if Input.repeat?(k) }
      end
    end

    # a message / Yes-No box over the screen (the small pictures hide behind it)
    def shop_say(text)
      @shop_spr.visible = false
      message(text, keep: true)
    ensure
      @shop_spr.visible = true
    end

    def shop_yes_no(text)
      @shop_spr.visible = false
      yes_no_menu(text, true, keep: true)
    ensure
      @shop_spr.visible = true
    end

    #--------------------------------------------------------------------------
    # the small pictures: tile x, y and :gfx (a card) or :pack (a booster's
    # art, :big = full size 4x6 tiles, else squeezed into the 4x3 cell),
    # :sold (dimmed, "SOLD"), :sel (red frame), :count (x2... corner),
    # :label (small text in the top corner)
    #--------------------------------------------------------------------------
    def shop_pic(x, y, opts)
      @shop[:pics] << opts.merge(:x => x, :y => y)
    end

    def shop_draw_pics
      return unless @shop && @shop_spr
      bmp = @shop_spr.bitmap
      bmp.clear
      z = Graphics.width / (COLS * 8.0)
      tick = TCG.holo_tick
      @shop[:pics].each do |p|
        cell = Rect.new((p[:x] * 8 * z).round, (p[:y] * 8 * z).round, (32 * z).round, (24 * z).round)
        if p[:pack]
          src = (RPG::Cache.load_bitmap(GFX, CardShop.pack_art(p[:pack])) rescue nil)
          if src
            h = p[:big] ? (48 * z).round : cell.height
            w = (h * src.width / src.height.to_f).round
            dst = Rect.new(cell.x + (cell.width - w) / 2, cell.y, w, h)
            bmp.stretch_blt(dst, src, Rect.new(0, 0, src.width, src.height))
          end
          cell.height = (48 * z).round if p[:big]
        else
          small_card_blt(bmp, cell, p[:gfx], nil, tick)
        end
        if p[:sold]
          bmp.stretch_blt(cell, @shop_dim, Rect.new(0, 0, 1, 1), 150)
          pbSetSmallFont(bmp)
          pbDrawTextPositions(bmp, [[_INTL("SOLD"), cell.x + cell.width / 2, cell.y + cell.height / 2 - 10, :center,
                                     Color.new(248, 248, 248), Color.new(40, 40, 40)]])
        end
        if p[:label]
          pbSetSmallFont(bmp)
          pbDrawTextPositions(bmp, [[p[:label], cell.x + 3, cell.y, :left, Color.new(248, 232, 96), Color.new(40, 40, 40)]])
        end
        if p[:count].to_i > 1
          pbSetSmallFont(bmp)
          pbDrawTextPositions(bmp, [["x#{p[:count]}", cell.x + cell.width - 2, cell.y + cell.height - 18, :right,
                                     Color.new(248, 248, 248), Color.new(40, 40, 40)]])
        end
        next unless p[:sel]
        # black outside, white inside: shows on any card's colors
        shop_frame(bmp, cell, 0, Color.new(24, 24, 24))
        shop_frame(bmp, cell, 2, Color.new(248, 248, 248))
      end
    end

    # a 2-pixel frame `inset` pixels inside rect r
    def shop_frame(bmp, r, inset, color)
      x = r.x + inset
      y = r.y + inset
      w = r.width - inset * 2
      h = r.height - inset * 2
      bmp.fill_rect(x, y, w, 2, color)
      bmp.fill_rect(x, y + h - 2, w, 2, color)
      bmp.fill_rect(x, y, 2, h, color)
      bmp.fill_rect(x + w - 2, y, 2, h, color)
    end
  end
end

# only from the NPCs placed in the world (not in the card menu), so players
# have to find the shops
def pbTCGCardShop; TCG::CardShop.open; end
