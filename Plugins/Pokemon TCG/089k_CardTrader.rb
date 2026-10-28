#==============================================================================
# Pokemon TCG - Card Trader (not in the original; server: handlers/tcg_trader.js)
#
# The server keeps 3 offers that every player sees. Each is a holo card that
# wants 3 cards: specific normal cards and, for the rarer holos, "any holo of
# tier X or rarer". Taking an offer empties its spot for an hour, then the
# server puts a new one there.
#
# The card menu's "Card Trader" (or pbTCGCardTrader) opens it while online.
#   LEFT / RIGHT  other offers
#   A             Trade / See cards
#   B             leave
# Cards in saved decks are never traded away (TCG.available_for_deck). For an
# "any holo" want the trader takes the least rare holo that fits (most spare
# copies first); the confirm screen shows every card before anything changes.
#==============================================================================
module TCG
  module CardTrader
    REFRESH_FRAMES = 60 * 30   # asks the server for the board again every 30 s

    module_function

    def tier_index(t); HOLO_TIERS.index { |x, *_| x.to_s == t.to_s }; end
    def spare(id);     TCG.available_for_deck(id.to_sym); end
    def known?(id);    !id.nil? && !CARDS[id.to_s.to_sym].nil?; end

    # the server's slots with restock times as local deadlines
    def import(slots)
      now = System.uptime
      Array(slots).map do |s|
        next { :restock_at => now + s["restock_in"].to_i } unless s["offer_id"]
        { :offer_id => s["offer_id"].to_s, :card => s["card"].to_s, :tier => s["tier"].to_s,
          :wants => Array(s["wants"]).map { |w| w["card"] ? { :card => w["card"].to_s } : { :holo_tier => w["holo_tier"].to_s } } }
      end
    end

    # can this game show the offer? (cards from a newer update can't)
    def usable?(offer)
      known?(offer[:card]) && offer[:wants].all? { |w| w[:card] ? known?(w[:card]) : tier_index(w[:holo_tier]) }
    end

    # the cards the player would hand over for each want (nil where they
    # have none to spare)
    def choose_give(wants)
      used = Hash.new(0)
      wants.map do |w|
        id = if w[:card]
               c = w[:card].to_sym
               c if spare(c) - used[c] > 0
             else
               min = tier_index(w[:holo_tier])
               TCG.collection.keys.select do |c|
                 t = TCG.holo_tier(c)
                 t && tier_index(t) >= min && spare(c) - used[c] > 0
               end.min_by { |c| [tier_index(TCG.holo_tier(c)), -spare(c), TCG.card_order_index(c) || 0] }
             end
        used[id] += 1 if id
        id
      end
    end

    # sends a request and pumps the game until `reply` comes back (or nil)
    def request(msg, reply, frames = 300)
      got = nil
      cb = NetworkClient.on(reply) { |d| got = d }
      NetworkClient.send_msg(msg)
      frames.times do
        break if got
        Graphics.update
        Input.update
        NetworkClient.update
      end
      got
    ensure
      NetworkClient.remove(reply, cb) if cb
    end

    def open
      unless NetPvP.online?
        pbMessage(_INTL("You need to be connected online to use the Card Trader."))
        return
      end
      d = request({ action: "tcg_trader_list" }, "tcg_trader_list")
      unless d
        pbMessage(_INTL("No response from server."))
        return
      end
      pbFadeOutIn do
        scene = DuelScene.new
        begin
          scene.card_trader_screen(import(d["slots"]))
        ensure
          scene.dispose
        end
      end
    end

    def traded!; TCG.force_save; end
  end

  # Saves the game right after a card changes hands with the server (trader,
  # shop, market), even with Autosave off: the server already counted it, so
  # quitting or closing the game can't undo it on this side.
  def self.force_save
    return unless defined?(Game) && Game.respond_to?(:save)
    echoln("[TCG] the game couldn't be saved") unless Game.save(safe: true)
  end

  #----------------------------------------------------------------------------
  # the screen: GB tile map for the frame and text, a sprite over it for the
  # small pictures of the wanted cards (64x48 art at half its duel size)
  #----------------------------------------------------------------------------
  class DuelScene
    TRADER_COLS = [1, 7, 13]   # left tile of each wanted card's 6-tile column

    def card_trader_screen(slots)
      @trader = { :slots => slots, :page => 0, :pics => [], :timer => 0 }
      @trader_spr = Sprite.new(@viewport)
      @trader_spr.z = 5
      @trader_spr.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @small_pics_redraw = method(:trader_draw_pics)
      list_cb = NetworkClient.on("tcg_trader_list") do |d|
        @trader[:slots] = CardTrader.import(d["slots"])
        @trader[:dirty] = true
      end
      trader_draw_main
      message(_INTL("Welcome to the Card Trader! LEFT/RIGHT: other trades. A: trade. B: leave."), keep: true)
      trader_draw_main
      loop do
        frame
        NetworkClient.update
        if (@trader[:timer] += 1) >= CardTrader::REFRESH_FRAMES
          @trader[:timer] = 0
          NetworkClient.send_msg({ action: "tcg_trader_list" })
        end
        slot = @trader[:slots][@trader[:page]]
        # a restocking spot: the countdown, and a new offer once it's time
        if slot && slot[:restock_at] && @trader[:shown_min] != trader_minutes_left(slot)
          @trader[:timer] = CardTrader::REFRESH_FRAMES if trader_minutes_left(slot) == 0
          @trader[:dirty] = true
        end
        if @trader[:dirty]
          @trader[:dirty] = false
          trader_draw_main
        end
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          break
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
          n = @trader[:slots].size
          next if n < 2
          @trader[:page] = (@trader[:page] + (Input.trigger?(Input::LEFT) ? -1 : 1)) % n
          pbPlayCursorSE
          trader_draw_main
        elsif Input.trigger?(Input::USE) && slot && slot[:offer_id]
          pbPlayDecisionSE
          trader_offer_menu(@trader[:page], slot)
          trader_draw_main
        end
      end
    ensure
      NetworkClient.remove("tcg_trader_list", list_cb) if list_cb
      @trader_spr&.bitmap&.dispose
      @trader_spr&.dispose
      @trader_spr = nil
      @small_pics_redraw = nil
      @trader = nil
    end

    def trader_minutes_left(slot)
      ((slot[:restock_at] - System.uptime) / 60.0).ceil.clamp(0, 999)
    end

    # Trade / See cards
    def trader_offer_menu(page, offer)
      unless CardTrader.usable?(offer)
        trader_say(_INTL("This trade uses cards from a newer update of the game."))
        return
      end
      @trader_spr.visible = false
      @map.wide_text_box
      [_INTL("Trade"), _INTL("See cards")].each_with_index { |l, i| @map.text(2 + 10 * i, 14, l) }
      pos = check_menu_cursor(0, [0, 1])
      @trader_spr.visible = true
      case pos
      when 0 then trader_trade(page, offer)
      when 1
        @trader_spr.visible = false
        ids = [offer[:card].to_sym] + offer[:wants].map { |w| w[:card]&.to_sym }.compact
        browse_card_pages(ids, 0)
        @trader_spr.visible = true
      end
    end

    def trader_trade(page, offer)
      give = CardTrader.choose_give(offer[:wants])
      if give.include?(nil)
        trader_say(_INTL("You don't have all the cards the trader wants. Cards in your decks don't count."))
        return
      end
      trader_draw_confirm(offer, give)
      ok = yes_no_menu(_INTL("Trade these 3 cards for {1}?", TCG.card(offer[:card].to_sym).name), true, keep: true)
      return unless ok
      d = CardTrader.request({ action: "tcg_trader_trade", slot: page, offer_id: offer[:offer_id],
                               give: give.map(&:to_s) }, "tcg_trader_result")
      trader_draw_main
      unless d
        trader_say(_INTL("No response from server."))
        return
      end
      unless d["ok"]
        trader_say(d["message"].to_s.empty? ? _INTL("The trade didn't go through.") : d["message"].to_s)
        return
      end
      give.each { |id| TCG.remove_card(id) }
      TCG.add_card(offer[:card].to_sym)
      CardTrader.traded!
      @trader[:slots][page] = { :restock_at => System.uptime + 3600 }
      trader_draw_main
      trader_say(_INTL("You traded for {1}! A new card comes to this spot in an hour.", TCG.card(offer[:card].to_sym).name))
      trader_draw_main
    end

    # a message over the screen (the small pictures hide behind the box)
    def trader_say(text)
      @trader_spr.visible = false
      message(text, keep: true)
      @trader_spr.visible = true
    end

    #--------------------------------------------------------------------------
    # main layout: the offer's picture and name on top, the 3 wanted cards in
    # a box below (small picture, name, how many you have to spare)
    #--------------------------------------------------------------------------
    def trader_draw_main
      @map.clear
      slots = @trader[:slots]
      slot = slots[@trader[:page]]
      @map.text(1, 0, _INTL("Card Trader"))
      @map.text(15, 0, "#{@trader[:page] + 1}/#{slots.size}") if slots.size > 0
      @trader[:pics] = []
      if slot.nil?
        @map.text(1, 8, _INTL("The trader has no cards."))
      elsif slot[:restock_at]
        mins = trader_minutes_left(slot)
        @trader[:shown_min] = mins
        @map.box(1, 6, 18, 6)
        @map.text(3, 8, _INTL("Restocking..."))
        @map.text(3, 10, mins > 0 ? _INTL("New card in {1} min.", mins) : _INTL("New card soon!"))
      elsif !CardTrader.usable?(slot)
        @map.text(1, 8, _INTL("This trade uses cards from"))
        @map.text(1, 9, _INTL("a newer update of the game."))
      else
        trader_draw_offer(slot)
        @map.text(1, 8, _INTL("Wants these 3 cards:"))
        @map.box(0, 9, 20, 9)
        # what the trade would take (spare copies only, holo tiers checked)
        give = CardTrader.choose_give(slot[:wants])
        have = Hash.new(0)
        slot[:wants].each_with_index do |w, i|
          c = TRADER_COLS[i]
          if w[:card]
            id = w[:card].to_sym
            card = TCG.card(id)
            trader_pic(c + 1, 10, card.gfx, nil, !give[i].nil?)
            trader_label(c, 13, Screens.name_and_level(card), false)
            n = CardTrader.spare(id) - have[id]
            have[id] += 1
            @map.text(c, 16, n > 0 ? _INTL("Have {1}", n) : _INTL("Need 1"))
          else
            trader_pic(c + 1, 10, nil, w[:holo_tier], !give[i].nil?)
            @map.text(c, 13, _INTL("Any holo:"))
            trader_label(c, 14, "#{TCG.holo_name(w[:holo_tier].to_sym)}+", true)
            @map.text(c, 16, give[i] ? _INTL("Have") : _INTL("Need 1"))
          end
        end
      end
      render
      trader_draw_pics
    end

    def trader_draw_offer(slot)
      card = TCG.card(slot[:card].to_sym)
      @map.picture(1, 1, card.gfx)
      lines = GB.wrap(Screens.name_and_level(card), 18)
      lines.first(2).each_with_index do |l, n|
        nx = @map.text(10, 2 + n, l)
        @map.palette(10, 2 + n, nx - 10, 1, PAL_HOLO_NAME)
      end
      GB.wrap(_INTL("{1} Holo", TCG.holo_name(slot[:tier].to_sym)), 18).first(2).each_with_index do |l, n|
        @map.text(10, 5 + n, l)
      end
    end

    # up to 2 lines of 10 half-width characters, a tile short of the next
    # column (gold for holos)
    def trader_label(x, y, text, gold)
      GB.wrap(text, 10).first(2).each_with_index do |l, n|
        nx = @map.text(x, y + n, l)
        @map.palette(x, y + n, nx - x, 1, PAL_HOLO_NAME) if gold
      end
    end

    #--------------------------------------------------------------------------
    # confirm layout: what you give on top, what you get below
    #--------------------------------------------------------------------------
    def trader_draw_confirm(offer, give)
      @map.clear
      @trader[:pics] = []
      @map.text(1, 0, _INTL("You give:"))
      give.each_with_index do |id, i|
        c = TRADER_COLS[i]
        card = TCG.card(id)
        trader_pic(c + 1, 1, card.gfx)
        trader_label(c, 4, Screens.name_and_level(card), card.holo?)
      end
      @map.text(1, 7, _INTL("You get:"))
      card = TCG.card(offer[:card].to_sym)
      trader_pic(2, 8, card.gfx)
      nx = @map.text(7, 8, Screens.name_and_level(card))
      @map.palette(7, 8, nx - 7, 1, PAL_HOLO_NAME)
      @map.text(7, 10, _INTL("{1} Holo", TCG.holo_name(offer[:tier].to_sym)))
      render
      trader_draw_pics
    end

    #--------------------------------------------------------------------------
    # the small pictures: [tile x, tile y, gfx or nil, tier for a blank "any
    # holo" card, owned]; holo sparkles move like on the GB screens. owned
    # true / false puts a Poké Ball right of the picture: red and white when
    # you have the card to spare, faded when you don't.
    #--------------------------------------------------------------------------
    TRADER_BALL = ["..KKKK..",
                   ".KRRRRK.",
                   "KRWRRRRK",
                   "KKKWWKKK",
                   "KWWWWWWK",
                   "KWWWWWWK",
                   ".KWWWWK.",
                   "..KKKK.."]

    def trader_pic(x, y, gfx, any_tier = nil, owned = nil)
      @trader[:pics] << [x, y, gfx, any_tier, owned]
    end

    # 8x8 GB pixels at screen size, top left at screen pixel x, y
    def trader_draw_ball(bmp, x, y, z, owned)
      cols = if owned
               { "K" => Color.new(24, 24, 24), "R" => Color.new(232, 40, 32), "W" => Color.new(248, 248, 248) }
             else
               { "K" => Color.new(150, 150, 140), "R" => Color.new(205, 205, 195), "W" => Color.new(232, 232, 222) }
             end
      px = z.round
      TRADER_BALL.each_with_index do |row, j|
        row.each_char.with_index do |ch, i|
          next if ch == "."
          bmp.fill_rect(x + i * px, y + j * px, px, px, cols[ch])
        end
      end
    end

    def trader_draw_pics
      bmp = @trader_spr.bitmap
      bmp.clear
      z = Graphics.width / (COLS * 8.0)
      w = (32 * z).round
      h = (24 * z).round
      tick = TCG.holo_tick
      @trader[:pics].each do |x, y, gfx, any_tier, owned|
        dst = Rect.new((x * 8 * z).round, (y * 8 * z).round, w, h)
        trader_draw_ball(bmp, dst.x + w, dst.y, z, owned) unless owned.nil?
        small_card_blt(bmp, dst, gfx, any_tier, tick)
      end
    end

    # a card picture (gfx, "<gfx>*<tier>" for a holo) stretched into dst with
    # its sparkle frame; gfx nil: a blank card with `any_tier`'s sparkle.
    # Also used by the Card Shop (089l).
    def small_card_blt(bmp, dst, gfx, any_tier, tick)
      if gfx
        src = (RPG::Cache.load_bitmap(GFX + "Cards/", gfx.to_s.split("*", 2)[0]) rescue nil)
        bmp.stretch_blt(dst, src, Rect.new(0, 0, src.width, src.height)) if src
        sheet_name = TCG.holo_sheet(gfx)
      else
        shades = @gb.colors(0)
        bmp.fill_rect(dst, shades[2])
        bmp.fill_rect(dst.x + 2, dst.y + 2, dst.width - 4, dst.height - 4, shades[1])
        sheet_name = (HOLO_TIER_INFO[any_tier.to_sym] || {})[:sheet]
      end
      return unless sheet_name
      sheet = (RPG::Cache.load_bitmap(GFX + "UI/", sheet_name) rescue nil) or return
      frames = sheet.width / 64
      return if frames < 1
      bmp.stretch_blt(dst, sheet, Rect.new((tick % frames) * 64, 0, 64, 48))
    end

    # keep the small pictures' sparkles moving (also under menus): screens
    # with small pictures set @small_pics_redraw while they're open
    alias small_pics_frame frame
    def frame
      small_pics_frame
      return unless @small_pics_redraw
      tick = TCG.holo_tick
      return if tick == @small_pics_tick
      @small_pics_tick = tick
      @small_pics_redraw.call
    end
  end
end

# only from the NPCs placed in the world (not in the card menu), so players
# have to find the traders
def pbTCGCardTrader; TCG::CardTrader.open; end
