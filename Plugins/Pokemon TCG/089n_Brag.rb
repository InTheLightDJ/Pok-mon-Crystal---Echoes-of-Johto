#==============================================================================
# Pokemon TCG - Brag (not in the original): show off a holo card in the
# server chat. The card menu's Brag option (bottom of this file) lists
# every holo the player owns in the Card Shop's picture grid (089l); A on
# one sends it to the server (chat_server.js handleTcgBrag), which shows its
# picture and its tier's sparkle in the chat. Only holos; the server has a
# copy of the art (ServerStuff/tcg_art, from PokeTCG-mod
# tools/chat_art/make_chat_art.rb).
# Clicking a bragged card in the chat opens its card page in the clicker's
# game (the server's tcg_card_view): it waits for the overworld to be free
# (no event, message, menu or battle), like the update notice.
#==============================================================================
module TCG
  module Brag
    module_function

    def holos; TCG.listing_order.select { |id| TCG.holo?(id) && TCG.card_count(id) > 0 }; end

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
    def brag_screen
      cur = 0
      ids = Brag.holos
      loop do
        brag_draw(ids, cur)
        key = shop_wait_key
        case key
        when Input::BACK then pbPlayCancelSE; return
        when Input::USE
          pbPlayDecisionSE
          brag_send(ids[cur])
        else
          n = shop_move(cur, key, ids.size)
          if n != cur
            cur = n
            pbPlayCursorSE
          end
        end
      end
    end

    def brag_draw(ids, cur)
      @map.clear
      @shop[:pics] = []
      page = cur / CardShop::GRID_CELLS
      pages = (ids.size + CardShop::GRID_CELLS - 1) / CardShop::GRID_CELLS
      @map.text(1, 0, _INTL("Brag {1}/{2}", page + 1, pages))
      id = ids[cur]
      shop_draw_big_card(id)
      @map.text(10, 4, _INTL("Owned: {1}", TCG.card_count(id)))
      @map.text(10, 5, _INTL("A: show off"))
      @map.box(0, 7, 20, 11)
      first = page * CardShop::GRID_CELLS
      ids[first, CardShop::GRID_CELLS].each_with_index do |x, i|
        shop_pic(CardShop::GRID_X[i % 4], CardShop::GRID_Y[i / 4], :gfx => TCG.card(x).gfx,
                 :sel => first + i == cur, :count => TCG.card_count(x))
      end
      render
      shop_draw_pics
    end

    def brag_send(id)
      name = _INTL("{1} Holo {2}", TCG.holo_name(TCG.holo_tier(id)), TCG.card(id).name)
      return unless shop_yes_no(_INTL("Show off your {1} in the server chat?", name))
      d = CardTrader.request({ action: "tcg_brag", card: id.to_s }, "tcg_brag_result")
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
