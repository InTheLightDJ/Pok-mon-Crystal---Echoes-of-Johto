#==============================================================================
# Pokemon TCG - deck view (the deck build menu's "View", 089_DeckEditor.rb)
#
# Not from the original: every card of the deck as its card page (the
# 160x144 overview page), 10 per row, on one big screen made for
# screenshots. The game screen is resized to fit the whole grid while
# this is open (the window is scaled down to fit the display; fullscreen
# shows it as large as the monitor allows) and put back afterwards.
#
#   ACTION   all cards / one of each with "x2", "x3"... under it
#   USE      saves the grid at full size to Screenshots/
#   SPECIAL  shows / hides the key help
#   BACK     leaves
#==============================================================================
module TCG
  module DeckView
    include GB

    module_function

    CARD_W   = COLS * 8
    CARD_H   = ROWS * 8
    PER_ROW  = 10
    GAP      = 8
    HEADER_H = 32
    COUNT_H  = 20   # the "x3" line under a card in the stacked view
    # colors as methods: the headless harness loads this without mkxp
    def bg_color;    Color.new(40, 40, 48); end
    def text_base;   Color.new(248, 248, 248); end
    def text_shadow; Color.new(96, 96, 112); end

    # [card id, copies] in deck order; copies = nil in the all-cards view
    def cells(cards, stacked)
      sorted = TCG.sort_cards(cards)
      return sorted.map { |id| [id, nil] } unless stacked
      sorted.uniq.map { |id| [id, cards.count(id)] }
    end

    def size_for(n, stacked)
      rows = [(n + PER_ROW - 1) / PER_ROW, 1].max
      cell_h = CARD_H + (stacked ? COUNT_H : 0)
      [PER_ROW * CARD_W + (PER_ROW + 1) * GAP, HEADER_H + rows * (cell_h + GAP)]
    end

    # the card's first page (overview / energy / trainer page 1) as a bitmap
    def card_bitmap(renderer, id)
      card = TCG.card(id)
      map = TileMap.new
      Screens.card_page(map, nil, card, Screens.card_pages(card)[0])
      renderer.draw(map)
      renderer.sprite.bitmap.clone
    end

    def compose(cards, name, stacked, pics)
      list = cells(cards, stacked)
      w, h = size_for(list.size, stacked)
      bmp = Bitmap.new(w, h)
      bmp.fill_rect(0, 0, w, h, bg_color)
      pbSetSystemFont(bmp)
      title = name.to_s.empty? ? "Deck" : "#{name} deck"
      pbDrawTextPositions(bmp, [
        [title, GAP, 6, :left, text_base, text_shadow],
        ["#{cards.size} cards", w - GAP, 6, :right, text_base, text_shadow]
      ])
      cell_h = CARD_H + (stacked ? COUNT_H : 0)
      list.each_with_index do |(id, copies), i|
        x = GAP + (i % PER_ROW) * (CARD_W + GAP)
        y = HEADER_H + (i / PER_ROW) * (cell_h + GAP)
        pic = pics[id]
        bmp.blt(x, y, pic, Rect.new(0, 0, pic.width, pic.height))
        next unless copies
        pbDrawTextPositions(bmp, [["x#{copies}", x + CARD_W / 2, y + CARD_H, :center, text_base, text_shadow]])
      end
      bmp
    end

    def save_png(bmp, name)
      safe = name.to_s.gsub(/[^0-9A-Za-z _\-]/, "").strip
      safe = "Deck" if safe.empty?
      Dir.mkdir("Screenshots") unless File.directory?("Screenshots")
      path = "Screenshots/Deck - #{safe} #{Time.now.strftime('%Y%m%d-%H%M%S')}.png"
      bmp.to_file(path)
      path
    rescue StandardError
      nil
    end
  end

  class DuelScene
    # st: the deck build screen's state (:cards, :name)
    def deck_view_screen(st)
      cards = st[:cards]
      return if cards.empty?
      old_w = Graphics.width
      old_h = Graphics.height
      old_scale = Graphics.scale rescue 1.0
      stacked = false
      vp = nil
      grid = nil
      hint = nil
      pics = {}
      outside_scene do
        vp = Viewport.new(0, 0, old_w, old_h)
        vp.z = 100_001
        renderer = Renderer.new(vp)
        renderer.sprite.visible = false
        renderer.holo = false   # still pictures: no sparkle (089j_HoloSparkle.rb)
        cards.uniq.each { |id| pics[id] = DeckView.card_bitmap(renderer, id) }
        renderer.dispose
        grid = Sprite.new(vp)
        hint = Sprite.new(vp)
        hint.z = 1
        rebuild = lambda do
          grid.bitmap&.dispose
          grid.bitmap = DeckView.compose(cards, st[:name], stacked, pics)
          deck_view_fit(grid.bitmap.width, grid.bitmap.height, vp)
          deck_view_hint(hint, nil)
        end
        rebuild.call
        hint_timer = 240
        loop do
          Graphics.update
          Input.update
          if hint_timer > 0
            hint_timer -= 1
            hint.visible = false if hint_timer == 0
          end
          if Input.trigger?(Input::BACK)
            pbPlayCancelSE
            break
          elsif Input.trigger?(Input::ACTION)
            pbPlayDecisionSE
            stacked = !stacked
            rebuild.call
            hint.visible = true
            hint_timer = 240
          elsif Input.trigger?(Input::USE)
            path = DeckView.save_png(grid.bitmap, st[:name])
            path ? pbPlayDecisionSE : pbPlayBuzzerSE
            deck_view_hint(hint, path ? "Saved #{path}" : "Couldn't save the image.")
            hint.visible = true
            hint_timer = 240
          elsif Input.trigger?(Input::SPECIAL)
            hint.visible = !hint.visible
            hint_timer = 0
          end
        end
      ensure
        hint&.bitmap&.dispose
        hint&.dispose
        grid&.bitmap&.dispose
        grid&.dispose
        pics.each_value(&:dispose)
        vp&.dispose
        Graphics.resize_screen(old_w, old_h)
        Graphics.scale = old_scale rescue nil
        Graphics.center rescue nil
      end
    end

    # screen = the grid's size; the window shrinks to fit the display
    def deck_view_fit(w, h, vp)
      Graphics.resize_screen(w, h)
      vp.rect = Rect.new(0, 0, w, h)
      return if (Graphics.fullscreen rescue false)
      dw = Graphics.respond_to?(:display_width) ? Graphics.display_width : 1920
      dh = Graphics.respond_to?(:display_height) ? Graphics.display_height : 1080
      scale = [1.0, dw * 0.95 / w, dh * 0.88 / h].min
      Graphics.scale = [scale, 0.5].max rescue nil
      Graphics.center rescue nil
    end

    # key help (or `text`) in a bar at the bottom; never in the saved image
    def deck_view_hint(sprite, text)
      text ||= "ACTION: all cards / one of each    USE: save image    SPECIAL: hide help    BACK: exit"
      sprite.bitmap&.dispose
      sprite.bitmap = Bitmap.new(Graphics.width, 28)
      sprite.bitmap.fill_rect(0, 0, Graphics.width, 28, Color.new(0, 0, 0, 200))
      pbSetSmallFont(sprite.bitmap)
      pbDrawTextPositions(sprite.bitmap, [[text, Graphics.width / 2, 6, :center, Color.new(248, 248, 248), Color.new(64, 64, 64)]])
      sprite.y = Graphics.height - 28
    end
  end
end
