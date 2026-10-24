#==============================================================================
# Pokemon TCG - deck building screen and the player's cards screen
# (engine/menus/deck_configuration.asm), drawn on the GB tile map.
#
#   pbTCGEditDeck(index)  -> HandleDeckBuildScreen for a saved deck (nil = a
#                            new one); true if the deck was saved
#   pbTCGDeckMenu         -> the deck selection screen (089d_PokegearMenu.rb)
#
# Deck build screen: "X/60" at 15,0, the 9 card type filters (icons at
# 1+2i,2, counts below, cursor above), a 6-card list from 1,7 as
# "NAME Lv  X/Y" (X in the deck, Y owned and not used by the other decks).
# Filters: LEFT/RIGHT pick, DOWN/A go to the list, B opens the Confirm /
# View / Name / Save / Dismantle / Cancel menu, START shows the deck.
# List: RIGHT adds, LEFT removes, A shows the card page, B back to the
# filters, START shows the deck, SELECT+UP/DOWN scrolls a page.
# Rules: 088_DeckRules.rb (adding fails silently like TryAddCardToDeck).
#==============================================================================
module TCG
  module Screens
    module_function

    # CardTypeFilters / DrawCardTypeIcons.CardTypeIcons: [filter, icon tile
    # (DuelCgbSymbolGraphics), palette (GetCardTypeIconPalette)]
    CARD_TYPE_FILTERS = [[0x01, 0x14, 2], [0x00, 0x10, 1], [0x03, 0x1c, 2], [0x02, 0x18, 1],
                         [0x04, 0x20, 3], [0x05, 0x24, 3], [0x06, 0x28, 0],
                         [:trainer, 0x0c, 2], [:energy, 0x2c, 2]]
    NUM_FILTERED_LIST_VISIBLE_CARDS     = 6
    NUM_DECK_CONFIRMATION_VISIBLE_CARDS = 7

    def filter_match?(id, filter)
      t = TCG.card(id).type
      case filter
      when :trainer then t >= TYPE_TRAINER
      when :energy  then t >= TYPE_ENERGY && t < TYPE_TRAINER
      else t == filter
      end
    end

    # CountNumberOfCardsForEachCardType
    def filter_counts(cards)
      CARD_TYPE_FILTERS.map { |f, _, _| cards.count { |id| filter_match?(id, f) } }
    end

    # ConvertToNumericalDigits: tens (blank when 0) and ones symbols
    def num2(map, x, y, n)
      n = n.clamp(0, 99)
      map.sym(x, y, n >= 10 ? SYM_0 + n / 10 : SYM_SPACE)
      map.sym(x + 1, y, SYM_0 + n % 10)
    end

    # DrawCardTypeIcons (y = 2)
    def card_type_icons(map)
      CARD_TYPE_FILTERS.each_with_index do |(_, t, pal), i|
        x = 1 + 2 * i
        map.cgb(x, 2, t); map.cgb(x + 1, 2, t + 1)
        map.cgb(x, 3, t + 2); map.cgb(x + 1, 3, t + 3)
        map.palette(x, 2, 2, 2, pal)
      end
    end

    # FillBGMapLineWithA (SYM_BOX_TOP, palette 4)
    def box_top_line(map, y)
      COLS.times { |x| map.sym(x, y, SYM_BOX_TOP) }
      map.palette(0, y, COLS, 1, PAL_TEXTBOX)
    end

    # "X/60" (PrintTotalCardCount + PrintSlashSixty)
    def total_slash_sixty(map, x, y, n)
      num2(map, x, y, n)
      map.sym(x + 2, y, SYM_SLASH)
      map.sym(x + 3, y, SYM_0 + 6)
      map.sym(x + 4, y, SYM_0)
    end

    # DrawCardTypeIconsAndPrintCardCounts
    def deck_build_header(map, cards)
      map.clear
      box_top_line(map, 5)
      card_type_icons(map)
      filter_counts(cards).each_with_index { |n, i| num2(map, 1 + 2 * i, 4, n) }
      total_slash_sixty(map, 15, 0, cards.size)
    end

    # PrintDeckBuildingCardList: 6 cards from 1,7, "X/Y" at 14,
    # arrows at 19,6 / 19,17
    def deck_build_list(map, ids, offset, cards, owned)
      map.sym(19, 6, offset > 0 ? SYM_CURSOR_U : SYM_SPACE)
      NUM_FILTERED_LIST_VISIBLE_CARDS.times do |n|
        y = 7 + n * 2
        map.fill(1, y, 18, 1)
        id = ids[offset + n]
        next unless id
        map.text(1, y, padded_name(TCG.card(id), 13))
        num2(map, 14, y, cards.count(id))
        map.sym(16, y, SYM_SLASH)
        num2(map, 17, y, owned[id])
      end
      more = offset + NUM_FILTERED_LIST_VISIBLE_CARDS < ids.size
      map.sym(19, 17, more ? SYM_CURSOR_D : SYM_SPACE)
    end

    # DeckBuildMenuData in a 20x6 box at the top
    DECK_BUILD_MENU = [[2, 2, "Confirm"], [9, 2, "View"], [16, 2, "Name"],
                       [2, 4, "Save"], [9, 4, "Dismantle"], [16, 4, "Cancel"]]
    DECK_BUILD_MENU_CURSOR = [[1, 2], [8, 2], [15, 2], [1, 4], [8, 4], [15, 4]]

    def deck_build_menu(map)
      map.box(0, 0, 20, 6)
      DECK_BUILD_MENU.each { |x, y, t| map.text(x, y, t) }
    end

    # ShowDeckInfoHeader: deck number and name, hand icon on the dueling
    # deck, "X/60" at 14,1, "No cards chosen." for an empty deck
    def deck_info_header(map, cards, number, name, dueling)
      map.clear
      map.box(0, 0, 20, 4)
      if name && !name.empty?
        if number
          num2(map, 3, 2, number)
          map.sym(5, 2, SYM_DOT)
        end
        map.text(6, 2, "#{name} deck")
        4.times { |t| map.put(2 + t % 2, 1 + t / 2, [:hand, t]) } if dueling
      end
      total_slash_sixty(map, 14, 1, cards.size)
      map.text(11, 1, "No cards chosen.") if cards.empty?
    end

    # PrintConfirmationCardList: 7 cards from 3,5 with their type icon at
    # 1,y-1 and "×count", arrows at 19,4 / 19,17
    def deck_confirmation_list(map, ids, offset, cards)
      map.sym(19, 4, offset > 0 ? SYM_CURSOR_U : SYM_SPACE)
      NUM_DECK_CONFIRMATION_VISIBLE_CARDS.times do |n|
        y = 5 + n * 2
        map.fill(1, y - 1, 18, 2)
        id = ids[offset + n]
        next unless id
        card = TCG.card(id)
        card_symbol(map, 1, y - 1, card)
        map.text(3, y, padded_name(card, 13))
        map.sym(16, y, SYM_CROSS)
        num2(map, 17, y, cards.count(id))
      end
      more = offset + NUM_DECK_CONFIRMATION_VISIBLE_CARDS < ids.size
      map.sym(19, 17, more ? SYM_CURSOR_D : SYM_SPACE)
    end

    # PrintPlayersCardsHeaderInfo: "<PLAYER>'s Cards" at 1,0, the total at
    # 13,0, icons at y 2, line at y 4
    def players_cards_header(map, player, total)
      map.clear
      box_top_line(map, 4)
      x = map.text(1, 0, player)
      map.text(x, 0, "'s Cards")
      s = total.to_s.rjust(5)[-5, 5]
      s.each_char.with_index { |ch, i| map.sym(13 + i, 0, ch == " " ? SYM_SPACE : SYM_0 + ch.to_i) }
      card_type_icons(map)
    end

    # PrintCardSelectionList: 7 cards from 2,5, owned count at 16,
    # arrows at 19,5 / 19,17
    def players_cards_list(map, ids, offset)
      map.sym(19, 5, offset > 0 ? SYM_CURSOR_U : SYM_SPACE)
      NUM_DECK_CONFIRMATION_VISIBLE_CARDS.times do |n|
        y = 5 + n * 2
        map.fill(2, y, 17, 1)
        id = ids[offset + n]
        next unless id
        map.text(2, y, padded_name(TCG.card(id), 14))
        num2(map, 16, y, TCG.card_count(id))
      end
      more = offset + NUM_DECK_CONFIRMATION_VISIBLE_CARDS < ids.size
      map.sym(19, 17, more ? SYM_CURSOR_D : SYM_SPACE)
    end
  end

  class DuelScene
    #--------------------------------------------------------------------------
    # shared list input (HandleDeckCardSelectionList): returns :use, :back,
    # :start, :left, :right, or nil after moving the cursor / scrolling
    #--------------------------------------------------------------------------
    def list_input(st, cx, cy, visible)
      n = st[:ids].size
      positions = [n, visible].min
      key = blink_wait(cx, cy + st[:cur] * 2, SYM_CURSOR_R, SYM_SPACE, [Input::USE, Input::BACK]) do
        if Input.trigger?(Input::ACTION) then :start
        elsif Input.press?(Input::SPECIAL) && Input.repeat?(Input::UP) then :page_up
        elsif Input.press?(Input::SPECIAL) && Input.repeat?(Input::DOWN) then :page_down
        elsif Input.repeat?(Input::UP) then :up
        elsif Input.repeat?(Input::DOWN) then :down
        elsif Input.repeat?(Input::LEFT) then :left
        elsif Input.repeat?(Input::RIGHT) then :right
        end
      end
      case key
      when Input::USE  then return :use
      when Input::BACK then return :back
      when :up
        if st[:cur] > 0 then st[:cur] -= 1; pbPlayCursorSE
        elsif st[:off] > 0 then st[:off] -= 1; pbPlayCursorSE
        end
      when :down
        if st[:cur] + 1 < positions then st[:cur] += 1; pbPlayCursorSE
        elsif st[:off] + visible < n then st[:off] += 1; pbPlayCursorSE
        end
      when :page_up, :page_down
        # HandleSelectUpAndDownInList / HandleLeftRightInCardList
        old = st[:off]
        st[:off] = list_page(st[:off], positions, n, key == :page_up)
        pbPlayCursorSE if st[:off] != old
      else return key
      end
      nil
    end

    # OpenCardPageFromCardList: UP / DOWN show the previous / next card of
    # the list; returns the index shown last
    def browse_card_pages(ids, index)
      loop do
        card = TCG.card(ids[index])
        pages = Screens.card_pages(card)
        n = 0
        moved = false
        loop do
          Screens.card_page(@map, nil, card, pages[n])
          render
          dir = nil
          loop do
            frame
            if Input.trigger?(Input::BACK) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::SPECIAL)
              return index
            elsif Input.trigger?(Input::USE)
              n += 1
              return index if n >= pages.size
              break
            elsif Input.trigger?(Input::RIGHT) then n = (n + 1) % pages.size; break
            elsif Input.trigger?(Input::LEFT)  then n = [n - 1, 0].max; break
            elsif Input.repeat?(Input::UP) && index > 0 then dir = -1; break
            elsif Input.repeat?(Input::DOWN) && index < ids.size - 1 then dir = 1; break
            end
          end
          next unless dir
          index += dir
          pbPlayCursorSE
          moved = true
          break
        end
        next if moved
      end
    end

    def keep_in_view(st, index, visible)
      st[:off] = index if index < st[:off]
      st[:off] = index - visible + 1 if index >= st[:off] + visible
      st[:cur] = index - st[:off]
    end

    # horizontal filter cursor (HandleCardSelectionInput, cursor at 1+2i,1):
    # returns :use, :back, :start, :down or nil after moving
    def filter_input(st)
      key = blink_wait(1 + 2 * st[:filter], 1, SYM_CURSOR_D, SYM_SPACE, [Input::USE, Input::BACK]) do
        if Input.trigger?(Input::ACTION) then :start
        elsif Input.repeat?(Input::DOWN) then :down
        elsif Input.repeat?(Input::LEFT) then :left
        elsif Input.repeat?(Input::RIGHT) then :right
        end
      end
      case key
      when Input::USE  then :use
      when Input::BACK then :back
      when :left, :right
        st[:filter] = (st[:filter] + (key == :left ? -1 : 1)) % Screens::CARD_TYPE_FILTERS.size
        pbPlayCursorSE
        nil
      else key
      end
    end

    #--------------------------------------------------------------------------
    # HandleDeckBuildScreen. number: deck number shown in the confirmation
    # header (nil = none). Returns [:save, cards, name], [:dismantle] or nil.
    #--------------------------------------------------------------------------
    def deck_build_screen(cards, index, name, number: nil, dueling: false)
      original = TCG.sort_cards(cards)
      orig_name = name.to_s
      st = { :cards => cards.dup, :name => orig_name, :index => index, :number => number,
             :dueling => dueling, :filter => 0, :off => 0, :cur => 0 }
      mode = :filters
      loop do
        refresh_deck_build(st)
        case mode
        when :filters
          case filter_input(st)
          when :start then pbPlayDecisionSE; deck_confirmation_screen(st)
          when :use, :down
            st[:off] = 0
            st[:cur] = 0
            mode = :list unless st[:ids].empty?
          when :back
            pbPlayCancelSE
            r = deck_build_menu(st, original, orig_name)
            return r if r != :continue
          else st[:off] = 0
          end
        when :list
          case list_input(st, 0, 7, Screens::NUM_FILTERED_LIST_VISIBLE_CARDS)
          when :back then pbPlayCancelSE; mode = :filters
          when :start then pbPlayDecisionSE; deck_confirmation_screen(st)
          when :use
            pbPlayDecisionSE
            i = browse_card_pages(st[:ids], st[:off] + st[:cur])
            keep_in_view(st, i, Screens::NUM_FILTERED_LIST_VISIBLE_CARDS)
          when :right
            # TryAddCardToDeck (no message when it can't)
            id = st[:ids][st[:off] + st[:cur]]
            if id && st[:cards].size < DECK_SIZE && st[:cards].count(id) < st[:owned][id] &&
               (TCG.basic_energy_card?(id) ||
                st[:cards].count { |c| TCG.card_name(c) == TCG.card_name(id) } < MAX_NUM_SAME_NAME_CARDS)
              st[:cards] << id
              pbPlayCursorSE
            end
          when :left
            id = st[:ids][st[:off] + st[:cur]]
            if id && (i = st[:cards].index(id))
              st[:cards].delete_at(i)
              pbPlayCursorSE
            end
          end
        end
      end
    end

    def refresh_deck_build(st)
      f = Screens::CARD_TYPE_FILTERS[st[:filter]][0]
      decks = TCG.saved_decks
      # CreateFilteredCardList: owned cards (or cards in any deck) of the type
      st[:owned] = Hash.new { |h, id| h[id] = TCG.available_for_deck(id, st[:index]) }
      st[:ids] = CARD_ORDER.select do |id|
        Screens.filter_match?(id, f) &&
          (st[:owned][id] > 0 || st[:cards].include?(id) || decks.any? { |d| d[:cards].include?(id) })
      end
      Screens.deck_build_header(@map, st[:cards])
      Screens.deck_build_list(@map, st[:ids], st[:off], st[:cards], st[:owned])
    end

    # HandleDeckConfigurationMenu: returns :continue (back to the screen),
    # [:save, cards, name], [:dismantle] or nil (cancel)
    def deck_build_menu(st, original, orig_name)
      pos = 0
      loop do
        refresh_deck_build(st)
        Screens.deck_build_menu(@map)
        pos = deck_build_menu_cursor(pos)
        return :continue if pos.nil?
        case pos
        when 0 then deck_confirmation_screen(st)   # Confirm
        when 1 then deck_view_screen(st)           # View (089h_DeckView.rb)
        when 2                                     # Name
          name = nil
          outside_scene { name = pbEnterText(_INTL("Deck name?"), 0, 12, st[:name]) }
          st[:name] = name.strip if name && !name.strip.empty?
          return :continue
        when 3                                     # Save
          if st[:cards].size != DECK_SIZE
            message("This isn't a 60-card deck!", keep: true)
            return nil if yes_no_menu("Return to original configuration?", true, keep: true)
            message("The Deck must include 60 cards!", keep: true)
          elsif yes_no_menu("Save this Deck?", true, keep: true)
            return [:save, st[:cards], st[:name]] if st[:cards].any? { |c| TCG.basic_pokemon_card?(c) }
            message("There are no Basic Pokémon\nin this Deck!", keep: true)
            message("You must include a Basic Pokémon\nin the Deck!", keep: true)
          end
        when 4                                     # Dismantle
          if yes_no_menu("Dismantle this Deck?", true, keep: true)
            return [:dismantle] if st[:index].nil? || TCG.saved_decks.size > 1
            message("There is only 1 Deck, so this\nDeck cannot be dismantled.", keep: true)
          end
        when 5                                     # Cancel
          changed = TCG.sort_cards(st[:cards]) != original || st[:name] != orig_name
          return nil if !changed || yes_no_menu("Quit modifying the Deck?", true, keep: true)
        end
      end
    end

    # DeckConfigurationMenu_TransitionTable: 3x2, LEFT/RIGHT wrap in a row
    def deck_build_menu_cursor(pos)
      loop do
        x, y = Screens::DECK_BUILD_MENU_CURSOR[pos]
        key = blink_wait(x, y, SYM_CURSOR_R, SYM_SPACE,
                         [Input::USE, Input::BACK, Input::UP, Input::DOWN, Input::LEFT, Input::RIGHT])
        case key
        when Input::USE  then pbPlayDecisionSE; return pos
        when Input::BACK then pbPlayCancelSE; return nil
        when Input::UP, Input::DOWN then pos = (pos + 3) % 6
        when Input::LEFT  then pos = pos / 3 * 3 + (pos % 3 + 2) % 3
        when Input::RIGHT then pos = pos / 3 * 3 + (pos % 3 + 1) % 3
        end
        pbPlayCursorSE
      end
    end

    # HandleDeckConfirmationMenu: the deck's cards by ID, one line each
    def deck_confirmation_screen(st)
      cards = st[:cards]
      vis = Screens::NUM_DECK_CONFIRMATION_VISIBLE_CARDS
      if cards.empty?
        Screens.deck_info_header(@map, cards, st[:number], st[:name], st[:dueling])
        render
        loop { frame; break if Input.trigger?(Input::BACK) }
        pbPlayCancelSE
        return
      end
      cst = { :ids => TCG.sort_cards(cards).uniq, :off => 0, :cur => 0 }
      loop do
        Screens.deck_info_header(@map, cards, st[:number], st[:name], st[:dueling])
        Screens.deck_confirmation_list(@map, cst[:ids], cst[:off], cards)
        key = list_input(cst, 0, 5, vis)
        case key
        when :back then pbPlayCancelSE; return
        when :use, :start
          pbPlayDecisionSE
          keep_in_view(cst, browse_card_pages(cst[:ids], cst[:off] + cst[:cur]), vis)
        when :left, :right
          # HandleLeftRightInCardList: a page up / down
          n = cst[:ids].size
          old = cst[:off]
          cst[:off] = list_page(cst[:off], [n, vis].min, n, key == :left)
          pbPlayCursorSE if cst[:off] != old
        end
      end
    end

    def list_page(off, pos, n, up)
      up ? [off - pos, 0].max : [off + pos, [n - pos, 0].max].min
    end

    #--------------------------------------------------------------------------
    # HandlePlayersCardsScreen (the START menu's "Card")
    #--------------------------------------------------------------------------
    def players_cards_screen
      player = $player ? $player.name : "PLAYER"
      st = { :filter => 0, :off => 0, :cur => 0 }
      vis = Screens::NUM_DECK_CONFIRMATION_VISIBLE_CARDS
      mode = :filters
      loop do
        f = Screens::CARD_TYPE_FILTERS[st[:filter]][0]
        st[:ids] = CARD_ORDER.select { |id| Screens.filter_match?(id, f) && TCG.card_count(id) > 0 }
        Screens.players_cards_header(@map, player, TCG.collection.values.sum(&:to_i))
        Screens.players_cards_list(@map, st[:ids], st[:off])
        if mode == :filters
          case filter_input(st)
          when :back then pbPlayCancelSE; return
          when :use, :down
            st[:off] = 0
            st[:cur] = 0
            mode = :list unless st[:ids].empty?
          else st[:off] = 0
          end
        else
          case list_input(st, 1, 5, vis)
          when :back then pbPlayCancelSE; mode = :filters
          when :use, :start
            pbPlayDecisionSE
            keep_in_view(st, browse_card_pages(st[:ids], st[:off] + st[:cur]), vis)
          end
        end
      end
    end
  end
end

# edit one saved deck (nil = build a new one). Returns true if saved.
def pbTCGEditDeck(index = nil, name_prompt: true, scene: nil)
  decks = TCG.saved_decks
  if index.nil? && decks.size >= TCG::NUM_DECKS
    pbMessage(_INTL("All {1} deck slots are in use.", TCG::NUM_DECKS))
    return false
  end
  deck = index && decks[index]
  run = lambda do |sc|
    sc.deck_build_screen(deck ? deck[:cards] : [], index, deck ? deck[:name] : "",
                         number: (index || decks.size) + 1,
                         dueling: index && index == $PokemonGlobal&.tcg_active_deck)
  end
  result = nil
  if scene
    result = run.call(scene)
  else
    pbFadeOutIn do
      sc = TCG::DuelScene.new
      begin
        result = run.call(sc)
      ensure
        sc.dispose
      end
    end
  end
  case result && result[0]
  when :save
    _, cards, name = result
    name = name.to_s.strip
    if name.empty? && name_prompt
      name = pbEnterText(_INTL("Deck name?"), 0, 12, "").to_s.strip
    end
    name = TCG.next_unnamed_deck_name if name.empty? && name_prompt
    TCG.save_deck(cards, name, index)
    true
  when :dismantle
    TCG.dismantle_deck(index) if index
    false
  else
    false
  end
end

# the deck selection screen on its own
def pbTCGDeckMenu
  TCG.open_menu_option(:deck)
end
