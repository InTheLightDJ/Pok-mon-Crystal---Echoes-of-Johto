#==============================================================================
# Pokemon TCG - menu for the Pokégear (and pbTCGMenu for events / other UIs)
#
#   The options of the original's START menu and PC that deal with cards:
#     Deck        DeckSelectionMenu (engine/menus/deck_selection.asm): the 4
#                 deck boxes, hand icon on the dueling deck, "Please select
#                 deck." and the Modify deck / Select deck / Change name /
#                 Cancel box (Modify deck = the deck build screen,
#                 089_DeckEditor.rb); START on a deck lists its cards
#     Card        HandlePlayersCardsScreen (089_DeckEditor.rb)
#     Card Album  the PC's album (pbTCGCardAlbum)
#     Glossary    the PC's Pokémon Card Glossary
#
#   Pokégear: a GSC-style Pokégear (MenuHandlers :pokegear_menu_gsc) gets a
#   tab using the "cards" icon / background; the stock v21 Pokégear
#   (:pokegear_menu) gets a "Card Game" entry.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_unnamed_deck_counter
  def tcg_unnamed_deck_counter; @tcg_unnamed_deck_counter ||= 1; end
end

module TCG
  MENU_OPTIONS = [:deck, :card, :album, :glossary]
  MENU_LABELS  = { :deck => "Deck", :card => "Card", :album => "Card Album", :glossary => "Glossary" }

  # InputCurDeckName.UnnamedDeck: an empty name becomes "Deck 001", "Deck 002"...
  def self.next_unnamed_deck_name
    g = global
    n = g ? g.tcg_unnamed_deck_counter : 1
    g.tcg_unnamed_deck_counter = (n >= 999 ? 1 : n + 1) if g
    format("Deck %03d", n)
  end

  module Screens
    module_function

    DECK_ROW_Y = [0, 3, 6, 9]

    # DrawDecksScreen: four 20x4 boxes, "1・" at 4,y+2, "<name> deck" or
    # "New deck" at 6,y+2, the hand icon (DrawHandCardsTileOnCurDeck) at
    # 2,(deck * 3) + 1 on the dueling deck
    def decks_screen(map, decks, active)
      map.clear
      DECK_ROW_Y.each { |y| map.box(0, y, 20, 4) }
      DECK_ROW_Y.each_with_index do |y, i|
        map.sym(4, y + 2, SYM_0 + i + 1)
        map.sym(5, y + 2, SYM_DOT)
        map.text(6, y + 2, decks[i] ? "#{decks[i][:name]} deck" : "New deck")
      end
      if active && decks[active]
        4.times { |t| map.put(2 + t % 2, active * 3 + 1 + t / 2, [:hand, t]) }
      end
    end

    # DeckSelectionData
    DECK_SUB_MENU = [[2, 14, "Modify deck"], [12, 14, "Select deck"],
                     [2, 16, "Change name"], [12, 16, "Cancel"]]
  end

  class DuelScene
    def visible=(v); @viewport.visible = v; end

    # runs an Essentials screen (deck editor, text entry) over this one
    def outside_scene
      self.visible = false
      yield
    ensure
      self.visible = true
    end

    def draw_decks
      Screens.decks_screen(@map, TCG.saved_decks, $PokemonGlobal&.tcg_active_deck)
    end

    def decks_text(text)
      draw_decks
      Screens.text_box_lines(@map, GB.wrap(text))
    end

    def decks_message(text)
      draw_decks
      GB.wrap(text).each_slice(2) do |pair|
        Screens.text_box_lines(@map, pair)
        blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
      end
    end

    # DeckSelectionMenu: cursor at 1, 2 + 3 * deck; A opens the sub menu,
    # START shows the deck's cards, B leaves
    def deck_selection_screen
      decks = TCG.saved_decks
      cur = $PokemonGlobal&.tcg_active_deck || 0
      loop do
        decks_text("Please select deck.")
        key = blink_wait(1, 2 + 3 * cur, SYM_CURSOR_R, SYM_SPACE,
                         [Input::USE, Input::BACK, Input::UP, Input::DOWN]) do
          Input.trigger?(Input::ACTION) ? :start : nil
        end
        case key
        when Input::UP   then cur = (cur - 1) % NUM_DECKS; pbPlayCursorSE
        when Input::DOWN then cur = (cur + 1) % NUM_DECKS; pbPlayCursorSE
        when Input::BACK then pbPlayCancelSE; return
        when :start
          # HandleStartButtonInDeckSelectionMenu
          if decks[cur]
            pbPlayDecisionSE
            # OpenDeckConfirmationMenu
            deck_confirmation_screen({ :cards => decks[cur][:cards], :number => cur + 1, :name => decks[cur][:name],
                                       :dueling => cur == $PokemonGlobal&.tcg_active_deck })
          else
            pbPlayCancelSE
            decks_message("There is no Deck here!")
          end
        when Input::USE
          pbPlayDecisionSE
          deck_selection_sub_menu(cur)
        end
      end
    end

    # DeckSelectionSubMenu
    def deck_selection_sub_menu(cur)
      decks = TCG.saved_decks
      draw_decks
      Screens.check_menu_items(@map, Screens::DECK_SUB_MENU)
      pos = check_menu_cursor(0, [0, 1, 2, 3])
      case pos
      when 0   # Modify deck (an empty slot builds a new one)
        idx = decks[cur] ? cur : nil
        if pbTCGEditDeck(idx, name_prompt: false, scene: self)
          # a saved deck without a name asks for one (.get_input_deck_name)
          i = idx || decks.size - 1
          deck_change_name(i) if decks[i][:name].to_s.empty?
        end
      when 1   # Select deck
        if decks[cur]
          TCG.set_active_deck(cur)
          decks_message("#{decks[cur][:name]} deck was\nchosen as the dueling deck!")
        else
          decks_message("There is no Deck here!")
        end
      when 2   # Change name
        if decks[cur]
          deck_change_name(cur)
        else
          decks_message("There is no Deck here!")
        end
      end
    end

    # InputCurDeckName (12 characters so "<name> deck" fits the deck box)
    def deck_change_name(i)
      deck = TCG.saved_decks[i]
      return unless deck
      name = nil
      outside_scene { name = pbEnterText(_INTL("Deck name?"), 0, 12, deck[:name]) }
      deck[:name] = (name.nil? || name.strip.empty?) ? TCG.next_unnamed_deck_name : name.strip
    end
  end

  # one option of MENU_OPTIONS in its own screen
  def self.open_menu_option(opt)
    if opt == :album
      pbTCGCardAlbum
      return
    end
    pbFadeOutIn do
      scene = DuelScene.new
      begin
        case opt
        when :deck     then scene.deck_selection_screen
        when :card     then scene.players_cards_screen
        when :glossary then scene.glossary_screen
        end
      ensure
        scene.dispose
      end
    end
  end

  def self.menu_labels; MENU_OPTIONS.map { |o| _INTL(MENU_LABELS[o]) }; end
end

# the card game menu on its own (events, a PC, the stock Pokégear)
def pbTCGMenu
  cmd = 0
  loop do
    cmd = pbMessage(_INTL("Pokémon TCG"), TCG.menu_labels + [_INTL("Cancel")], -1, nil, cmd)
    break if cmd < 0 || cmd >= TCG::MENU_OPTIONS.size
    TCG.open_menu_option(TCG::MENU_OPTIONS[cmd])
  end
end

#------------------------------------------------------------------------------
# GSC-style Pokégear tab
#------------------------------------------------------------------------------
if defined?(PokemonPokegear_Scene) && PokemonPokegear_Scene.method_defined?(:pbPageControl)
  MenuHandlers.add(:pokegear_menu_gsc, :tcg, {
    "suffix" => "cards",   # same icon and background as the Card Trunk tab
    "order"  => 55
  })

  class PokemonPokegear_Scene
    alias tcg_pbUpdateText pbUpdateText
    def pbUpdateText
      tcg_pbUpdateText
      return if pbGetPageId != :tcg
      decks  = TCG.saved_decks
      active = $PokemonGlobal.tcg_active_deck
      deck   = active && decks[active] ? decks[active][:name] : _INTL("None")
      owned  = TCG.collection.values.sum(&:to_i)
      pbDrawTextPositions(@sprites["overlay"].bitmap, [
        [_INTL("POKéMON TCG"), Graphics.width - 18, 16, :right, Color.new(224, 248, 160), nil],
        [_INTL("Deck: {1}", deck),            20, 72,  :left, @baseColor, @shadowColor],
        [_INTL("Decks: {1}/{2}", decks.size, TCG::NUM_DECKS), 20, 96, :left, @baseColor, @shadowColor],
        [_INTL("Cards: {1}", owned),          20, 120, :left, @baseColor, @shadowColor]
      ])
      @helpwindow.text = _INTL("Press A to open the card menu.")
    end

    alias tcg_pbPageControl pbPageControl
    def pbPageControl
      tcg_pbPageControl
      return if pbGetPageId != :tcg
      return unless Input.trigger?(Input::USE)
      pbPlayDecisionSE
      cmd = 0
      loop do
        cmd = pbMessage(_INTL("What would you like to do?"), TCG.menu_labels + [_INTL("Cancel")], -1, nil, cmd)
        break if cmd < 0 || cmd >= TCG::MENU_OPTIONS.size
        TCG.open_menu_option(TCG::MENU_OPTIONS[cmd])
      end
      drawPage(:tcg)
    end
  end
end

#------------------------------------------------------------------------------
# stock v21 Pokégear entry
#------------------------------------------------------------------------------
MenuHandlers.add(:pokegear_menu, :tcg, {
  "name"      => _INTL("Card Game"),
  "icon_name" => "cards",
  "order"     => 40,
  "condition" => proc { next pbResolveBitmap("Graphics/UI/Pokegear/icon_cards") },
  "effect"    => proc { |menu|
    pbTCGMenu
    next false
  }
})
