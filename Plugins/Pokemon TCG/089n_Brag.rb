#==============================================================================
# Pokemon TCG - Brag (not in the original): show off a holo card in the
# server chat. The card menu's Brag option (bottom of this file) lists
# every holo the player owns in the Card Shop's picture grid (089l); A on
# one sends it to the server (chat_server.js handleTcgBrag), which shows its
# picture and its tier's sparkle in the chat. Only holos; the server has a
# copy of the art (ServerStuff/tcg_art, from PokeTCG-mod
# tools/chat_art/make_chat_art.rb). An appraised copy (089o) is listed on its
# own and its PSA grade shows with it in the chat.
# Clicking a bragged card in the chat opens its card page in the clicker's
# game (the server's tcg_card_view): it waits for the overworld to be free
# (no event, message, menu or battle), like the update notice.
#==============================================================================
module TCG
  module Brag
    module_function

    def holos; TCG.listing_order.select { |id| TCG.holo?(id) && TCG.card_count(id) > 0 }; end

    def unappraised(id); Grades.copies(id).count { |r| !r[Grades::APPRAISED] }; end

    # the brag list: each appraised copy on its own (best grade first), then
    # the card's unappraised copies together
    def entries
      holos.flat_map do |id|
        list = Grades.copies(id)
        graded = list.each_index.select { |c| list[c][Grades::APPRAISED] }.sort_by { |c| -list[c][Grades::GRADE] }
        graded.map { |c| [id, c] } + (unappraised(id) > 0 ? [[id, nil]] : [])
      end
    end

    # a card clicked in the chat, waiting to be shown
    def pending_view; @pending_view; end
    def pending_view=(id); @pending_view = id; end

    def open
      unless NetPvP.online?
        pbMessage(_INTL("Connect to the server to show off your cards."))
        return
      end
      if holos.empty?
        pbMessage(_INTL("You have no holo cards. Only holo cards can be shown off."))
        return
      end
      pbFadeOutIn do
        scene = DuelScene.new
        begin
          scene.with_shop_layer { scene.brag_screen }
        ensure
          scene.dispose
        end
      end
    end
  end

  class DuelScene
    # entries: [id, copy] for each appraised copy (its PSA goes to the chat,
    # 089o), [id, nil] for a card's unappraised copies
    def brag_screen
      cur = 0
      entries = Brag.entries
      loop do
        brag_draw(entries, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          brag_send(*entries[cur])
        else
          n = shop_move(cur, key, entries.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def brag_draw(entries, cur)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (entries.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Brag {1}/{2}", page + 1, pages))
      id, copy = entries[cur]
      shop_draw_big_card(id)
      if copy
        @map.text(10, 4, Grades.label(id, copy))
      else
        @map.text(10, 4, _INTL("Owned: {1}", TCG.card_count(id)))
      end
      @map.text(10, 5, _INTL("A: show off"))
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      entries[first, CardShop::GRID_CELLS].each_with_index do |(x, c), i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :count => c ? 0 : Brag.unappraised(x),
                 :label => c ? Grades.label(x, c) : nil)
      end
      render
      shop_draw_pics
    end

    def brag_send(id, copy = nil)
      name = _INTL("{1} Holo {2}", TCG.holo_name(TCG.holo_tier(id)), TCG.card(id).name)
      psa = copy && Grades.record(id, copy)&.dig(Grades::APPRAISED) ? Grades.record(id, copy)[Grades::GRADE] : nil
      name = _INTL("PSA {1} {2}", psa, name) if psa
      return unless shop_yes_no(_INTL("Show off your {1} in the server chat?", name))
      msg = { action: "tcg_brag", card: id.to_s }
      msg[:psa] = psa if psa
      d = CardTrader.request(msg, "tcg_brag_result")
      if !d
        shop_say(_INTL("No response from server."))
      elsif d["ok"]
        shop_say(_INTL("Your {1} is in the server chat!", name))
      else
        shop_say(d["message"].to_s.empty? ? _INTL("That didn't work.") : d["message"].to_s)
      end
    end
  end
end

def pbTCGBrag; TCG::Brag.open; end

# "Brag" in the card game menu (Pokégear)
TCG::MENU_OPTIONS << :brag unless TCG::MENU_OPTIONS.include?(:brag)
TCG::MENU_LABELS[:brag] = "Brag"

module TCG
  class << self
    alias brag_open_menu_option open_menu_option
    def open_menu_option(opt)
      return Brag.open if opt == :brag
      brag_open_menu_option(opt)
    end
  end
end

# a bragged card clicked in the chat: show it when the overworld is free
if defined?(NetworkClient)
  NetworkClient.on('tcg_card_view') do |data|
    id = data['card'].to_s.to_sym
    TCG::Brag.pending_view = id if TCG::CARDS[id]
  end
end

if defined?(EventHandlers)
  EventHandlers.add(:on_frame_update, :tcg_brag_card_view, proc {
    next unless TCG::Brag.pending_view
    next if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
    next if $game_player.move_route_forcing || pbMapInterpreterRunning?
    id = TCG::Brag.pending_view
    TCG::Brag.pending_view = nil
    pbFadeOutIn { pbTCGShowCard(id) }
  })
end
