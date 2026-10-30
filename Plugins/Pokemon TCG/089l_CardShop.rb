#==============================================================================
# Pokemon TCG - Card Shop (not in the original; server: handlers/tcg_shop.js)
#
# Buy (online): 10 cards a day, one of them a holo, one more holo that's
# already graded (PSA 3-10, appraised; priced by its grade like a sold one)
# and a booster pack. Every player sees the same stock; each can buy each item
# once a day. Cards cost game money (3x their selling price), the pack costs
# Server Tokens.
# Sell (also offline): any card you have to spare (cards in saved decks
# can't be sold) for its HP x its holo level x its stage boost: a normal card
# is level 1, Blue 2, Yellow 3 ... Black & Red 12. Trainer and Energy cards:
# 5 x the level.
# Card prices both ways go with the server's price multiplier (x1.0-x5.0,
# changes every hour; mult); offline the last one seen counts.
# The day's card types (hidden, never shown): one Pokémon type's cards
# buy and sell for x1.1-2.5 more, another type's for /1.1-2.5 (type_factor;
# the server's types, kept until the shop's next restock).
# Each spare holo copy is its own entry; an appraised one sells for its
# grade (x0.05 at PSA 1 up to x10 at PSA 10, 089o_CardGrades.rb).
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
class PokemonGlobalMetadata
  attr_writer :tcg_shop_mult, :tcg_shop_types
  def tcg_shop_mult; @tcg_shop_mult || 1.0; end
  def tcg_shop_types; @tcg_shop_types; end   # { boost:, cut:, until: (Time) }
end

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

    # Pokémon by stage: a Basic that evolves x1, a Basic with no evolution
    # card (Pinsir, Sneasel) x1.5, Stage 1 x2, Stage 2 x3; legendaries and
    # special cards (087b) x5
    STAGE_BOOST = { "BASIC" => 1, "STAGE1" => 2, "STAGE2" => 3 }
    LONE_BASIC_BOOST = 1.5
    LEGENDARY_BOOST = 5

    # names that something evolves from
    def evolves?(name)
      @preevos ||= CARDS.each_value.map { |h| h[:preevo] }.compact.uniq
      @preevos.include?(name)
    end

    def stage_boost(id)
      h = CARDS[TCG.base_id(id)]
      return 1 unless h && h[:type].to_s.start_with?("TYPE_PKMN")
      return LEGENDARY_BOOST if TCG.reserved_card?(id)
      return LONE_BASIC_BOOST if h[:stage] == "BASIC" && !evolves?(h[:name])
      STAGE_BOOST[h[:stage]] || 1
    end

    # the server's hourly price multiplier (x1.0-x5.0), the last one seen
    # (selling also works offline)
    def mult; TCG.global ? TCG.global.tcg_shop_mult : (@test_mult ||= 1.0); end

    def mult=(v)
      v = v.to_f.clamp(1.0, 5.0)
      TCG.global ? TCG.global.tcg_shop_mult = v : @test_mult = v
    end

    def mult_text; format("x%.1f", mult); end

    # HP (Trainer / Energy: NO_HP_PRICE) x holo level x stage boost
    def base_price(id)
      card = TCG.card(id.to_sym)
      (card.pokemon? ? CARDS[id.to_sym][:hp].to_i : NO_HP_PRICE) * holo_level(id) * stage_boost(id)
    end

    # the day's boosted / cut card types from the server (hidden):
    # { :boost => ["FIRE", 1.7], :cut => ["WATER", 1.4], :until => Time }
    def types; TCG.global ? TCG.global.tcg_shop_types : @test_types; end

    def types=(v); TCG.global ? TCG.global.tcg_shop_types = v : @test_types = v; end

    def import_types(d, restock_in)
      return unless d.is_a?(Hash) && d["boost"].is_a?(Array) && d["cut"].is_a?(Array)
      pair = ->(x) { [x[0].to_s, x[1].to_f.clamp(1.0, 2.5)] }
      self.types = { :boost => pair.(d["boost"]), :cut => pair.(d["cut"]),
                     :until => Time.now + restock_in.to_i }
    end

    # x the boost for the boosted type's Pokémon, / the cut for the cut one's,
    # else 1 (and 1 once the day is over)
    def type_factor(id)
      t = types
      return 1.0 unless t && Time.now < t[:until]
      type = CARDS[TCG.base_id(id)] && CARDS[TCG.base_id(id)][:type].to_s
      return 1.0 unless type && type.start_with?("TYPE_PKMN_")
      type = type.sub("TYPE_PKMN_", "")
      return t[:boost][1] if t[:boost][0] == type
      return 1.0 / t[:cut][1] if t[:cut][0] == type
      1.0
    end

    # copy: which holo copy (an appraised one sells for its grade, 089o;
    # an unappraised one for the normal price)
    def sell_price(id, copy = nil)
      [(base_price(id) * Grades.price_factor(id, copy) * type_factor(id) * mult).round, 1].max
    end

    # grade: a graded card in the stock
    def buy_price(id, grade = nil)
      factor = grade ? Grades::PRICE[grade.to_i] || 1.0 : 1.0
      [(base_price(id) * BUY_MULTIPLIER * factor * type_factor(id) * mult).round, 1].max
    end

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
      graded = d["graded"].is_a?(Hash) ? d["graded"] : {}
      items = Array(d["cards"]).each_with_index.map do |id, i|
        grade = graded["slot"].to_i == i && graded["grade"].to_i.between?(1, 10) ? graded["grade"].to_i : nil
        { :kind => :card, :id => id.to_s, :slot => i, :sold => bought.include?(i), :grade => grade }
      end
      self.mult = d["mult"] if d["mult"]
      import_types(d["types"], d["restock_in"])
      if d["pack"]
        n = items.size
        items << { :kind => :pack, :pack => d["pack"].to_s, :slot => n, :cost => d["pack_cost"].to_i,
                   :sold => bought.include?(n) }
      end
      NetworkTokens.set(d["tokens"]) if defined?(NetworkTokens) && d["tokens"]
      { :date => d["date"].to_s, :items => items, :restock_at => System.uptime + d["restock_in"].to_i,
        :mult_at => d["mult_in"] ? System.uptime + d["mult_in"].to_i : nil }
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
      @map.text(1, 9, _INTL("Card prices: {1}", CardShop.mult_text))
      if stock
        if stock[:mult_at]
          m = ((stock[:mult_at] - System.uptime) / 60.0).ceil.clamp(0, 60)
          @map.text(1, 10, _INTL("Prices change in {1}m", m))
        end
        mins = ((stock[:restock_at] - System.uptime) / 60.0).ceil.clamp(0, 99_999)
        @map.text(1, 11, _INTL("New stock in {1}h {2}m", mins / 60, mins % 60))
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
        @map.text(10, 4, _INTL("Price: {1}", CardShop.buy_price(id, it[:grade])))
        if it[:grade]
          @map.text(10, 5, _INTL("PSA {1} {2}", it[:grade], Grades.name(it[:grade]))[0, 18])
        else
          @map.text(10, 5, _INTL("You have {1}", TCG.card_count(id)))
        end
      end
      @map.text(10, 6, _INTL("SOLD OUT")) if it[:sold]
      @map.box(0, 7, 20, 11)
      items.each_with_index do |x, i|
        cx = CardShop::GRID_X[i % 4]
        cy = CardShop::GRID_Y[i / 4] or next
        if x[:kind] == :pack
          shop_pic(cx, cy, :pack => x[:pack], :sold => x[:sold], :sel => i == cur)
        else
          shop_pic(cx, cy, :gfx => TCG.card(x[:id].to_sym).gfx, :sold => x[:sold], :sel => i == cur,
                   :label => x[:grade] ? _INTL("PSA {1}", x[:grade]) : nil)
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
        price = CardShop.buy_price(id, it[:grade])
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
        pts = TCG.pack_pulled(cards)   # rare holo: World Rankings points (089g)
        shop_say(_INTL("A rare pull! +{1} World Rankings points!", pts)) if pts > 0
      else
        id = it[:id].to_sym
        CardShop.money -= price
        TCG.add_card(id)
        # the graded one comes appraised; an ungraded holo's hidden grade is
        # 4-10 (from a pack: 6-10, 089o)
        if it[:grade]
          Grades.import_record(id, [it[:grade], 0, true])
        elsif TCG.holo?(id)
          Grades.import_record(id, [Grades.new_grade(rand(Grades::SHOP_GRADES)), 0, false])
        end
        CardShop.changed!
        if it[:grade]
          shop_say(_INTL("You bought {1}, graded PSA {2}!", TCG.card(id).name, it[:grade]))
        else
          shop_say(_INTL("You bought {1}!", TCG.card(id).name))
        end
      end
    end

    #--------------------------------------------------------------------------
    # Sell: the picked card large on top, your spare cards in pages of 12
    #--------------------------------------------------------------------------
    # one entry per spare holo copy ([id, copy], 089o), [id, nil] for the rest
    def shop_sell_screen
      cur = 0
      loop do
        entries = Grades.spare_entries(CardShop.sellable)
        if entries.empty?
          shop_say(_INTL("You have no cards to sell. Cards in your decks can't be sold."))
          return
        end
        cur = cur.clamp(0, entries.size - 1)
        shop_draw_sell(entries, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          id, copy = entries[cur]
          price = CardShop.sell_price(id, copy)
          next unless shop_yes_no(_INTL("Sell 1 {1} for {2}?", TCG.card(id).name, price))
          copy ? Grades.remove_copy(id, copy) : TCG.remove_card(id)
          CardShop.money += price
          CardShop.changed!
        else
          n = shop_move(cur, key, entries.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def shop_draw_sell(entries, cur)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (entries.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Sell {1}/{2}", page + 1, pages))
      shop_money_header
      id, copy = entries[cur]
      shop_draw_big_card(id)
      @map.text(10, 4, _INTL("Sell for {1}", CardShop.sell_price(id, copy)))
      spare = TCG.available_for_deck(id)
      if copy
        @map.text(10, 5, Grades.label(id, copy) || _INTL("Not appraised"))
      else
        @map.text(10, 5, _INTL("Spare: {1}", spare))
      end
      in_decks = TCG.card_count(id) - spare
      @map.text(10, 6, _INTL("In decks: {1}", in_decks)) if in_decks > 0
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      entries[first, CardShop::GRID_CELLS].each_with_index do |(x, c), i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :count => c ? 0 : TCG.available_for_deck(x),
                 :label => c ? Grades.label(x, c) : nil)
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
