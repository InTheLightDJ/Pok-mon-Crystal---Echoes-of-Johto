#==============================================================================
# Pokemon TCG - duel scene. Screens are ported tile for tile from the
# original (engine/duel/core.asm) onto a GB::TileMap (069_GBScreen.rb):
#   DrawDuelMainScene / DrawDuelHUDs / DrawDuelHUD, the duel menu
#   (PrintDuelMenuAndHandleInput), the attack menu
#   (PrintAndLoadAttacksToDuelTempList / PrintAttackOrPkmnPowerInformation)
#   and the wide text box (DrawWideTextBox_WaitForInput).
#==============================================================================
module TCG
  GFX = "Graphics/Plugins/Pokemon TCG/"

  # turn <FIRE> etc. inside card text into readable words (for pbMessage menus)
  def self.plain_text(s)
    return "" if s.nil?
    s.gsub(/<(FIRE|GRASS|LIGHTNING|WATER|FIGHTING|PSYCHIC|COLORLESS)>/) { $1.capitalize[0] }
     .gsub("<RAMTEXT>", "").gsub("\n", " ")
  end

  #----------------------------------------------------------------------------
  # tile map drawing (no mkxp calls: the headless preview uses these too)
  #----------------------------------------------------------------------------
  module Screens
    include GB

    module_function

    # CopyCardNameAndLevel for half-width names: "Charizard Lv76"
    def name_and_level(card)
      card.pokemon? && card.level.to_i > 0 ? "#{card.name} Lv#{card.level}" : card.name
    end

    # length in tiles of plain half-width text (GetTextLengthInTiles)
    def text_tiles(s); (s.size + 1) / 2; end

    # DrawDuelMainScene: always drawn from the player's side
    def duel_main_scene(map, duel)
      map.clear
      pl, op = duel.duelists
      map.picture(0, 5, pl.card(pl.arena).gfx) if pl.arena
      map.picture(12, 1, op.card(op.arena).gfx) if op.arena
      # DuelEAndHPTileData
      map.sym(1, 1, SYM_E); map.sym(1, 2, SYM_HP)
      map.sym(9, 8, SYM_E); map.sym(9, 9, SYM_HP)
      duel_horizontal_separator(map)
      # DrawDuelHUDs
      duel_hud(map, duel, pl, 1, 11, 11, 8)
      st = pl.status
      print_cnf_slp_prz(map, 8, 5, st)
      print_poisoned(map, 8, 6, st)
      print_double_poisoned(map, 8, 7, st)
      print_burned(map, 8, 8, pl)
      duel_hud(map, duel, op, 7, 0, 3, 1)
      st = op.status
      print_cnf_slp_prz(map, 11, 6, st)
      print_poisoned(map, 11, 5, st)
      print_double_poisoned(map, 11, 4, st)
      print_burned(map, 11, 3, op)
      map.wide_text_box
    end

    # DuelHorizontalSeparatorTileData + DuelHorizontalSeparatorCGBPalData
    def duel_horizontal_separator(map)
      9.times { |i| map.sym(i, 4, 0x37) }
      map.sym(9, 4, 0x31); map.sym(10, 4, 0x32)
      map.sym(9, 5, 0x33); map.sym(10, 5, 0x34)
      map.sym(9, 6, 0x33); map.sym(10, 6, 0x34)
      map.sym(9, 7, 0x35); map.sym(10, 7, 0x36)
      (11..19).each { |i| map.sym(i, 7, 0x37) }
      map.palette(0, 4, 11, 1, 2)
      map.palette(9, 5, 2, 2, 2)
      map.palette(9, 7, 11, 1, 2)
    end

    # DrawDuelHUD: d,e = arena card name coordinates (e == 0 -> opponent),
    # b,c = attached energies / HP bar coordinates
    def duel_hud(map, duel, du, nx, ny, bx, by)
      ix = ny == 0 ? 1 : 15
      map.sym(ix, ny, SYM_POKEMON)
      map.sym(ix + 1, ny, SYM_0 - 1 + du.num_in_play_area)
      map.sym(ix + 2, ny, SYM_PRIZE)
      map.sym(ix + 3, ny, SYM_0 + du.count_prizes)
      return unless du.arena
      c = du.card(du.arena)
      name = name_and_level(c)
      nx = COLS - text_tiles(name) if ny == 0
      card_text(map, nx, ny, c, name)
      map.sym(nx - 1, ny, COLOR_SYMBOLS[duel.play_area_card_color(du, 0)])
      attached_energies(map, du, 0, bx, by)
      hp_bar(map, bx, by + 1, c.hp, du.slot_hp[0])
      if du.slot_pluspower[0] > 0
        map.sym(bx + 6, by + 1, SYM_PLUSPOWER)
        map.sym(bx + 7, by + 1, SYM_0 + du.slot_pluspower[0])
      end
      if du.slot_defender[0] > 0
        map.sym(bx + 6, by + 2, SYM_DEFENDER)
        map.sym(bx + 7, by + 2, SYM_0 + du.slot_defender[0])
      end
    end

    # PrintPlayAreaCardAttachedEnergies: 8 tiles, a "+" in the 8th past 8 energies
    def attached_energies(map, du, e, x, y)
      en, total = du.attached_energies(e)
      row = []
      SYMBOL_ORDER.each { |col| en[col].times { row << COLOR_SYMBOLS[col] } }
      row = row.first(8)
      row << SYM_SPACE while row.size < 8
      row[7] = SYM_PLUS if total >= 9
      row.each_with_index { |s, i| map.sym(x + i, y, s) }
    end

    # DrawHPBar: 12 tiles of 10 HP in two rows of 6 (over 120 HP, as Shadow
    # Lugia's 300, each tile is a twelfth of the HP)
    def hp_bar(map, x, y, max_hp, cur_hp)
      step = max_hp > 120 ? max_hp / 12.0 : 10
      bar = Array.new(12) do |i|
        hp = ((i + 1) * step).round
        hp > max_hp ? SYM_SPACE : (hp > cur_hp ? SYM_HP_NOK : SYM_HP_OK)
      end
      bar.each_with_index { |s, i| map.sym(x + i % 6, y + i / 6, s) }
    end

    def print_cnf_slp_prz(map, x, y, st)
      s = { CONFUSED => SYM_CONFUSED, ASLEEP => SYM_ASLEEP, PARALYZED => SYM_PARALYZED }[st & CNF_SLP_PRZ]
      map.sym(x, y, s || SYM_SPACE)
    end

    def print_poisoned(map, x, y, st)
      map.sym(x, y, (st & POISONED) != 0 ? SYM_POISONED : SYM_SPACE)
    end

    def print_double_poisoned(map, x, y, st)
      map.sym(x, y, (st & DOUBLE_POISONED & ~POISONED) != 0 ? SYM_POISONED : SYM_SPACE)
    end

    # Burn (custom cards, 061c_NeoEffects2.rb): a <FIRE> next to the others
    def print_burned(map, x, y, du)
      map.sym(x, y, du.burned ? SYM_FIRE : SYM_SPACE)
    end

    # DuelMenuData
    DUEL_MENU_ITEMS = [[3, 14, "Hand"], [3, 16, "Attack"], [9, 14, "Check"],
                       [9, 16, "PKMN Power"], [15, 14, "Retreat"], [15, 16, "Done"]]
    DUEL_MENU_CURSOR = [[2, 14], [2, 16], [8, 14], [8, 16], [14, 14], [14, 16]]

    def duel_menu(map)
      map.wide_text_box
      DUEL_MENU_ITEMS.each { |x, y, t| map.text(x, y, t) }
    end

    # PrintAttackOrPkmnPowerInformation at row y (menu: show the ATK_DESCR icon)
    def attack_info(map, atk, y, menu = true)
      map.text(7, y, atk.name)
      map.sym(18, y, SYM_ATK_DESCR) if menu && atk.desc && !atk.desc.empty?
      map.number(15, y + 1, atk.damage) if atk.damage > 0
      if atk.pokemon_power?
        map.text(2, y, "PKMN PWR")
        return
      end
      case atk.base_category
      when DAMAGE_PLUS  then map.sym(18, y + 1, SYM_PLUS)
      when DAMAGE_MINUS then map.sym(18, y + 1, SYM_MINUS)
      when DAMAGE_X     then map.sym(18, y + 1, SYM_CROSS)
      end
      x = 2
      SYMBOL_ORDER.each { |col| atk.cost[col].times { map.sym(x, y, COLOR_SYMBOLS[col]); x += 1 } }
    end

    # PrintAndLoadAttacksToDuelTempList: rows 13 and 15 of the wide text box
    def attack_menu(map, card, list)
      map.wide_text_box
      list.each_with_index { |(_, ai), n| attack_info(map, card.attacks[ai], 13 + n * 2) }
    end

    #--------------------------------------------------------------------------
    # play area card list (PrintPlayAreaCardList), 3 rows per slot
    #--------------------------------------------------------------------------
    # PlayAreaLocationTileNumbers ($e0.. = DuelCgbSymbolGraphics + $40 here);
    # the non-player side uses the inverted letters 10 tiles further
    PLAY_AREA_LOCATION_TILES = [[0x40, 0x41, 0x42], [0x43, 0x44, 0x45], [0x43, 0x44, 0x46],
                                [0x43, 0x44, 0x47], [0x43, 0x44, 0x48], [0x43, 0x44, 0x49]]
    # FaceDownCardTileNumbers: first tile ($d0 = cgb $30), CGB palette
    FACE_DOWN_CARD_TILES = [[0x30, 2], [0x34, 2], [0x38, 1], [0x3c, 1]]

    def play_area_card_list(map, duel, du)
      map.clear
      off = du.player? ? 0 : 0x0a
      MAX_PLAY_AREA_POKEMON.times do |e|
        y = e * 3
        play_area_card_information(map, duel, du, e, y) if du.play_area[e]
        PLAY_AREA_LOCATION_TILES[e].each_with_index { |t, j| map.cgb(1, y + j, t + off) }
      end
    end

    def play_area_card_information(map, duel, du, e, y)
      c = du.card(du.play_area[e])
      # PrintPlayAreaCardHeader
      card_text(map, 4, y, c, c.name[0, 10])
      map.sym(18, y, COLOR_SYMBOLS[duel.play_area_card_color(du, e)])
      if c.level.to_i > 0   # custom cards with a single art have no level
        map.sym(14, y, SYM_LV)
        lv = c.level.to_i.to_s.rjust(2)
        lv.each_char.with_index { |ch, i| map.sym(15 + i, y, ch == " " ? SYM_SPACE : SYM_0 + ch.to_i) }
      end
      t, pal = FACE_DOWN_CARD_TILES[du.slot_stage[e].to_i] || FACE_DOWN_CARD_TILES[0]
      map.cgb(2, y, t); map.cgb(3, y, t + 1)
      map.cgb(2, y + 1, t + 2); map.cgb(3, y + 1, t + 3)
      map.palette(2, y, 2, 2, pal)
      if e == 0
        st = du.status
        print_cnf_slp_prz(map, 2, y + 2, st)
        print_poisoned(map, 3, y + 2, st)
        print_double_poisoned(map, 4, y + 2, st)
        print_burned(map, 5, y + 2, du)
      end
      if du.slot_pluspower[e] > 0
        map.sym(15, y + 1, SYM_PLUSPOWER); map.sym(16, y + 1, SYM_0 + du.slot_pluspower[e])
      end
      if du.slot_defender[e] > 0
        map.sym(17, y + 1, SYM_DEFENDER); map.sym(18, y + 1, SYM_0 + du.slot_defender[e])
      end
      # PrintPlayAreaCardInformation
      attached_energies(map, du, e, 7, y + 1)
      map.sym(5, y + 1, SYM_E)
      map.sym(5, y + 2, SYM_HP)
      if du.slot_hp[e] > 0
        12.times do |i|
          hp = (i + 1) * 10
          map.sym(7 + i, y + 2, hp > c.hp ? SYM_SPACE : (hp > du.slot_hp[e] ? SYM_HP_NOK : SYM_HP_OK))
        end
      else
        map.text(7, y + 2, "Knock Out")
      end
    end

    #--------------------------------------------------------------------------
    # card list screen (DrawCardListScreenLayout + DisplayCardList)
    #--------------------------------------------------------------------------
    # CardSymbolTable: first tile ($d0 = DuelCgbSymbolGraphics + 0), CGB palette
    # (+ 12 / 13: Darkness / Metal Energy, added below the original tiles)
    CARD_SYMBOLS = [[0x10, 1], [0x14, 2], [0x18, 1], [0x1c, 2], [0x20, 3], [0x24, 3],
                    [0x28, 0], [0x2c, 2], [0x00, 2], [0x04, 2], [0x08, 1], [0x0c, 2],
                    [0x88, PAL_DARKNESS], [0x8c, PAL_METAL]]
    CARD_LIST_VISIBLE = 5

    # CardTypeToSymbolID
    def card_symbol_id(card)
      return 11 if card.trainer?
      return { DARKNESS => 12, METAL => 13 }.fetch(card.color, card.color) if card.energy?
      card.stage.to_i + 8
    end

    # DrawCardSymbol at d-2, e-1 (2x2)
    def card_symbol(map, x, y, card)
      t, pal = CARD_SYMBOLS[card_symbol_id(card)] || CARD_SYMBOLS[11]
      map.cgb(x, y, t); map.cgb(x + 1, y, t + 1)
      map.cgb(x, y + 1, t + 2); map.cgb(x + 1, y + 1, t + 3)
      map.palette(x, y, 2, 2, pal)
    end

    # name + " Lv" + level, padded to `tiles` (CopyCardNameAndLevel)
    def padded_name(card, tiles)
      name_and_level(card).ljust(tiles * 2)[0, tiles * 2]
    end

    # one 20x13 box with up to 5 cards (CardListParameters: cursor 1,3, item x 4,
    # 14 tiles per name, 2 rows apart), scroll arrows at 18,2 / 18,11, the
    # narrow info box and the picture of the selected card at 12,12
    def card_list(map, du, cards, cur, scroll, header, info)
      map.clear
      map.box(0, 0, 20, 13)
      map.text(1, 1, header)
      map.sym(18, 2, scroll > 0 ? SYM_CURSOR_U : SYM_SPACE)
      map.sym(18, 11, scroll + CARD_LIST_VISIBLE < cards.size ? SYM_CURSOR_D : SYM_SPACE)
      cards[scroll, CARD_LIST_VISIBLE].each_with_index do |i, n|
        y = 3 + n * 2
        c = du.card(i)
        card_symbol(map, 2, y - 1, c)
        card_text(map, 4, y, c, padded_name(c, 14))
      end
      map.box(0, 12, 12, 6)
      map.text(1, 14, info, line_step: 2)
      map.picture(12, 12, du.card(cards[cur]).gfx) if cards[cur]
    end

    #--------------------------------------------------------------------------
    # card pages (OpenCardPage / CardPageDisplayPointerTable)
    #--------------------------------------------------------------------------
    RARITY_TILES = { "CIRCLE" => 0x52, "DIAMOND" => 0x53, "STAR" => 0x54 }
    HEADER_ROWS  = { :trainer => 0, :energy => 2, :pokemon => 4 }
    DESC_PAGE_LINES = 7

    # description lines (wrapped to the 19-tile text line), split in pages of 7
    def desc_pages(text)
      lines = GB.wrap(text.to_s, 36)
      lines.pop while lines.any? && lines[-1].empty?
      return [[]] if lines.empty?
      lines.each_slice(DESC_PAGE_LINES).to_a
    end

    # GoToFirstOrNextCardPage order: overview, attack 1 (2 pages), attack 2
    # (2 pages), description; energy: 1 page; trainer: 2 pages
    def card_pages(card)
      if card.pokemon? && !card.special_trainer_pokemon?
        pages = [[:overview]]
        card.page_attacks.each_with_index do |a, i|
          desc_pages(a.desc).each_index { |n| pages << [:attack, i, n] }
        end
        pages << [:description]
      elsif card.energy?
        [[:energy, 0]]
      else
        desc_pages(card.desc).each_index.map { |n| [:trainer, n] }
      end
    end

    # DrawCardPageSurroundingBox + card image at 6,4
    def card_page_frame(map, card)
      map.box(0, 0, 20, 18)
      map.picture(6, 4, card.gfx)
    end

    # DrawCardPageSet2AndRarityIcons (the set 2 icon needs data we don't have)
    def rarity_icon(map, card)
      t = RARITY_TILES[card.rarity.to_s]
      map.full(18, 9, t) if t
    end

    # PrintPokemonCardPageGenericInformation
    def card_page_generic(map, card, color)
      card_page_frame(map, card)
      card_text(map, 5, 1, card, card.name)
      map.sym(18, 1, COLOR_SYMBOLS[color])
      rarity_icon(map, card)
    end

    def two_digits(map, x, y, n)
      n.to_i.to_s.rjust(2).each_char.with_index do |ch, i|
        map.sym(x + i, y, ch == " " ? SYM_SPACE : SYM_0 + ch.to_i)
      end
    end

    # PrintCardPageWeaknessesOrResistances: one symbol per WR bit, FIRE first
    def wr_symbols(map, x, y, bits)
      WR_COLORS.each do |col|
        next if (bits & COLOR_TO_WR[col]) == 0
        map.sym(x, y, COLOR_SYMBOLS[col])
        x += 1
      end
    end

    def lv_hp(map, card)
      map.sym(15, 2, SYM_HP)
      card_symbol(map, 1, 1, card)
      if card.level.to_i > 0   # custom cards with a single art have no level
        map.sym(11, 2, SYM_LV)
        two_digits(map, 12, 2, card.level)
      end
      map.number(16, 2, card.hp)
    end

    # page = [:overview] etc.; du/slot given for a play area card page
    def card_page(map, duel, card, page, du = nil, slot = nil)
      map.clear
      color = du ? duel.play_area_card_color(du, slot) : card.color
      case page[0]
      when :overview
        if du
          card_page_frame(map, card)
          rarity_icon(map, card)
          map.sym(15, 16, SYM_NO)
          play_area_card_information(map, duel, du, slot, 1)
          PLAY_AREA_LOCATION_TILES[slot].each_with_index do |t, j|
            map.cgb(1, 1 + j, t + (du.player? ? 0 : 0x0a))
          end
        else
          card_page_generic(map, card, color)
          lv_hp(map, card)
          map.sym(15, 16, SYM_NO)
          map.text(1, 3, card.preevo.to_s) if card.stage.to_i > 0
        end
        map.text(1, 14, "Retreat Cost"); map.text(1, 15, "Weakness"); map.text(1, 16, "Resistance")
        map.number(16, 16, card.dex.to_i)
        # a power + 2 attacks (custom cards): the power takes 1 row
        rows = card.page_attacks.size == 3 ? [10, 11, 13] : [10, 12]
        card.page_attacks.each_with_index { |a, i| attack_info(map, a, rows[i], false) }
        card.retreat.to_i.clamp(0, 10).times { |i| map.sym(8 + i, 14, SYM_COLORLESS) }
        if du && slot == 0
          weak = duel.respond_to?(:arena_card_weakness) ? duel.arena_card_weakness(du) : card.weakness
          res  = duel.respond_to?(:arena_card_resistance) ? duel.arena_card_resistance(du) : card.resistance
        else
          weak = card.weakness; res = card.resistance
        end
        wr_symbols(map, 8, 15, weak.to_i)
        wr_symbols(map, 8, 16, res.to_i)
      when :attack
        card_page_generic(map, card, color)
        atk = card.page_attacks[page[1]]
        attack_info(map, atk, 2, false)
        lines = desc_pages(atk.desc)[page[2]] || []
        y = lines.size >= 7 ? 10 : 11
        lines.each_with_index { |l, n| map.text(1, y + n, l) }
      when :description
        card_page_generic(map, card, color)
        lv_hp(map, card)
        map.text(1, 10, "#{card.raw[:category]} Pokémon")
        map.text(1, 11, "Length"); map.text(1, 12, "Weight")
        ft, inch = card.raw[:length] || [0, 0]
        x = 5
        ft.to_s.each_char { |ch| map.sym(x, 11, SYM_0 + ch.to_i); x += 1 }
        map.full(x, 11, 0x7a); x += 1
        inch.to_s.each_char { |ch| map.sym(x, 11, SYM_0 + ch.to_i); x += 1 }
        map.full(x, 11, 0x7b)
        w = card.weight.to_i
        x = 5
        ((w / 10).to_s + (w % 10 > 0 ? ".#{w % 10}" : "")).each_char do |ch|
          map.sym(x, 12, ch == "." ? SYM_DOT : SYM_0 + ch.to_i); x += 1
        end
        map.text(x, 12, "lbs.")
        lines = GB.wrap(card.desc.to_s, 36)
        y = lines.size >= 4 ? 13 : 14
        lines.first(5).each_with_index { |l, n| map.text(1, y + n, l) }
      when :energy, :trainer
        map.box(0, 0, 20, 18)
        card_text(map, 4, 3, card, card.name)
        map.picture(6, 4, card.gfx)
        row = HEADER_ROWS[page[0] == :energy ? :energy : :trainer]
        16.times { |i| map.header(6 + i % 8, 1 + i / 8, row * 8 + i) }
        rarity_icon(map, card)
        lines = desc_pages(card.desc)[page[1]] || []
        y = lines.size >= 7 ? 10 : 11
        lines.each_with_index { |l, n| map.text(1, y + n, l) }
      end
    end

    #--------------------------------------------------------------------------
    # Your / Opp. Play Area screen (_DrawYourOrOppPlayAreaScreen); tiles from
    # LoadDeckAndDiscardPileIcons ($d0 = DuelCgbSymbolGraphics + $54)
    #--------------------------------------------------------------------------
    ICON_DECK = 0x58; ICON_DISCARD = 0x5c; ICON_PRIZE = 0x60; ICON_NO_PRIZE = 0x64
    ICON_BENCH = 0x68; ICON_NO_BENCH = 0x78; ICON_ARROW = 0x7c
    # PrizeCardsCoordinateData_YourOrOppPlayArea, stored as (y, x): the
    # table is read into e then d by DrawPlayArea_PrizeCards
    PRIZE_COORDS_OWN = [[2, 1], [2, 3], [4, 1], [4, 3], [6, 1], [6, 3]].map(&:reverse)
    PRIZE_COORDS_OPP = [[9, 17], [9, 15], [7, 17], [7, 15], [5, 17], [5, 15]].map(&:reverse)
    # PlayAreaIconCoordinates: hand, deck, discard pile
    ICON_COORDS_OWN = [[15, 7], [15, 2], [15, 4]]
    ICON_COORDS_OPP = [[1, 5], [1, 9], [1, 7]]
    # YourOrOppPlayAreaArrowPositions: Pokemon, hand, discard (own, then opp)
    ARROWS = [[[5, 5], [0, 10], [4, 10], [8, 10], [12, 10], [16, 10]], [[14, 7]], [[14, 5]],
              [[5, 7], [0, 3], [4, 3], [8, 3], [12, 3], [16, 3]], [[0, 5]], [[0, 8]]]

    def cgb_rect(map, x, y, tile, pal)
      map.cgb(x, y, tile); map.cgb(x + 1, y, tile + 1)
      map.cgb(x, y + 1, tile + 2); map.cgb(x + 1, y + 1, tile + 3)
      map.palette(x, y, 2, 2, pal)
    end

    # cross + CalculateOnesAndTensDigits (tens blank when 0)
    def cross_number(map, x, y, n)
      map.sym(x, y, SYM_CROSS)
      map.sym(x + 1, y, n >= 10 ? SYM_0 + (n / 10) % 10 : SYM_SPACE)
      map.sym(x + 2, y, SYM_0 + n % 10)
    end

    # 7-9 Prizes (not in the original): 3 columns 13 pixels apart, the own
    # side moved 8 pixels left and the opponent's mirrored, so they fit
    # beside the Active Pokemon's picture. Rows stay on the original tiles.
    PRIZE_COLS_PX_OWN = [0, 13, 26]
    PRIZE_COLS_PX_OPP = [145, 132, 119]

    def three_column_prizes?(duel); duel.initial_prizes > 6; end

    # prize i's top-left pixel in the 3-column layout (coords: the side's
    # original 6-prize table, whose rows it keeps)
    def prize_px(coords, i, own)
      rows = [coords[0][1], coords[2][1], coords[4][1]]
      [(own ? PRIZE_COLS_PX_OWN : PRIZE_COLS_PX_OPP)[i % 3], rows[i / 3] * 8]
    end

    # DrawPlayArea_PrizeCards; px tiles are tagged [:prize, i] so a
    # selection can blink (TileMap#hidden_tag)
    def draw_prizes(map, duel, du, coords, own)
      duel.initial_prizes.times do |i|
        t = du.prize_taken?(i) ? ICON_NO_PRIZE : ICON_PRIZE
        if three_column_prizes?(duel)
          map.px_cgb_rect(*prize_px(coords, i, own), t, 2, [:prize, i])
        else
          cgb_rect(map, *coords[i], t, 2)
        end
      end
    end

    # 3-column prize cursor: the prize reached from i by key (:up / :down /
    # :left / :right, as seen on screen), or nil past the left / right edge
    def prize_grid_move(i, n, key, own)
      col, row = i % 3, i / 3
      rows = (n + 2) / 3
      cols_in = ->(r) { [n - r * 3, 3].min }
      # the opponent's prizes are mirrored: index 0 is bottom right
      dir = own ? 1 : -1
      case key
      when :up, :down
        row = (row + (key == :down ? dir : -dir)) % rows
        col = [col, cols_in.call(row) - 1].min
      when :left, :right
        col += (key == :right ? dir : -dir)
        return nil if col < 0 || col >= cols_in.call(row)
      end
      row * 3 + col
    end

    # own: the screen of the duelist whose turn it is (player layout)
    def your_or_opp_play_area(map, duel, du, own)
      map.clear
      # ORIGINAL BUG: (6 - name tiles) / 2 + 4 is unsigned, so a name over 6
      # tiles wraps the title off screen; clamped here so it stays visible
      x = (6 - text_tiles(du.name)) / 2 + 4
      map.text(x.clamp(0, 19), 0, "#{du.name}'s Play Area")
      draw_prizes(map, duel, du, own ? PRIZE_COORDS_OWN : PRIZE_COORDS_OPP, own)
      map.picture(6, own ? 2 : 5, du.card(du.arena).gfx) if du.arena
      bx, by, step = own ? [1, 9, 4] : [17, 2, -4]
      (1...MAX_PLAY_AREA_POKEMON).each do |e|
        if e < du.num_in_play_area
          st = du.slot_stage[e].to_i
          cgb_rect(map, bx, by, ICON_BENCH + st * 4, st >= STAGE2 ? 1 : 2)
        else
          cgb_rect(map, bx, by, ICON_NO_BENCH, 2)
        end
        bx += step
      end
      (hx, hy), (dx, dy), (px, py) = own ? ICON_COORDS_OWN : ICON_COORDS_OPP
      map.text(hx, hy, "Hand")
      cross_number(map, hx + 2, hy, du.hand.size)
      cgb_rect(map, dx, dy, ICON_DECK, 2)
      cross_number(map, dx + 2, dy + 1, du.cards_in_deck)
      cgb_rect(map, px, py, ICON_DISCARD, 2)
      cross_number(map, px + 2, py + 1, du.discard_pile.size)
    end

    # _SelectPrizeCards cursor_transition_table: OAM cursor tile position,
    # x-flip, and the prize reached with up / down / right / left
    PRIZE_CURSOR = [[0, 24, false, 4, 2, 1, 1], [40, 24, true, 5, 3, 0, 0],
                    [0, 40, false, 0, 4, 3, 3], [40, 40, true, 1, 5, 2, 2],
                    [0, 56, false, 2, 0, 5, 5], [40, 56, true, 3, 1, 4, 4]]

    #--------------------------------------------------------------------------
    # In Play Area screen (DrawInPlayAreaScreen / OpenInPlayAreaScreen)
    #--------------------------------------------------------------------------
    PRIZE_COORDS_IN_PLAY_AREA_OWN = [[9, 1], [9, 3], [11, 1], [11, 3], [13, 1], [13, 3]].map(&:reverse)
    PRIZE_COORDS_IN_PLAY_AREA_OPP = [[6, 17], [6, 15], [4, 17], [4, 15], [2, 17], [2, 15]].map(&:reverse)
    ICON_COORDS_IN_PLAY_AREA_OWN = [[15, 14], [15, 9], [15, 11]]
    ICON_COORDS_IN_PLAY_AREA_OPP = [[0, 2], [0, 6], [0, 4]]
    # INPLAYAREA_* positions
    IPA_PLAYER_BENCH_1 = 0; IPA_PLAYER_ACTIVE = 5; IPA_PLAYER_HAND = 6
    IPA_PLAYER_DISCARD = 7; IPA_OPP_ACTIVE = 8; IPA_OPP_HAND = 9; IPA_OPP_DISCARD = 10
    IPA_OPP_BENCH_1 = 11; IPA_PLAYER_PLAY_AREA = 16; IPA_OPP_PLAY_AREA = 17
    # OpenInPlayAreaScreen_TransitionTable1: OAM x-8 / y-16 pixels, x-flip,
    # up, down, right, left
    IPA_CURSOR = [
      [16, 124, false, 5, 16, 1, 4], [40, 124, false, 5, 16, 2, 0], [64, 124, false, 5, 16, 3, 1],
      [88, 124, false, 5, 16, 4, 2], [112, 124, false, 5, 16, 0, 3],
      [40, 92, false, 8, 0, 7, 7], [112, 112, false, 7, 0, 5, 5], [112, 96, false, 8, 6, 5, 5],
      [112, 36, true, 11, 5, 10, 10], [40, 16, true, 11, 10, 8, 8], [40, 40, true, 11, 5, 8, 8],
      [136, 4, true, 17, 8, 15, 12], [112, 4, true, 17, 8, 11, 13], [88, 4, true, 17, 8, 12, 14],
      [64, 4, true, 17, 8, 13, 15], [40, 4, true, 17, 8, 14, 11]]

    def in_play_area(map, duel)
      map.clear
      pl, op = duel.duelists
      draw_prizes(map, duel, pl, PRIZE_COORDS_IN_PLAY_AREA_OWN, true)
      draw_prizes(map, duel, op, PRIZE_COORDS_IN_PLAY_AREA_OPP, false)
      [[pl, 3, 15, 3], [op, 15, 0, -3]].each do |du, bx, by, step|
        (1...MAX_PLAY_AREA_POKEMON).each do |e|
          if e < du.num_in_play_area
            st = du.slot_stage[e].to_i
            cgb_rect(map, bx, by, ICON_BENCH + st * 4, st >= STAGE2 ? 1 : 2)
          else
            cgb_rect(map, bx, by, ICON_NO_BENCH, 2)
          end
          bx += step
        end
      end
      [[pl, ICON_COORDS_IN_PLAY_AREA_OWN], [op, ICON_COORDS_IN_PLAY_AREA_OPP]].each do |du, ic|
        (hx, hy), (dx, dy), (px, py) = ic
        map.text(hx, hy, "Hand")
        cross_number(map, hx + 2, hy, du.hand.size)
        cgb_rect(map, dx, dy, ICON_DECK, 2)
        cross_number(map, dx + 2, dy + 1, du.cards_in_deck)
        cgb_rect(map, px, py, ICON_DISCARD, 2)
        cross_number(map, px + 2, py + 1, du.discard_pile.size)
      end
      map.picture(6, 9, pl.card(pl.arena).gfx) if pl.arena
      map.picture(6, 2, op.card(op.arena).gfx) if op.arena
    end

    # OpenInPlayAreaScreen.print_associated_text at 1,17
    def in_play_area_text(map, duel, pos)
      18.times { |i| map.sym(1 + i, 17, SYM_SPACE) }
      pl, op = duel.duelists
      du, slot = case pos
                 when 0..4 then [pl, pos + 1]
                 when IPA_PLAYER_ACTIVE then [pl, 0]
                 when IPA_OPP_ACTIVE then [op, 0]
                 when 11..15 then [op, pos - 10]
                 end
      if du
        idx = du.play_area[slot]
        card_text(map, 1, 17, du.card(idx)) if idx
      else
        du = pos <= IPA_PLAYER_DISCARD ? pl : op
        map.text(1, 17, [IPA_PLAYER_HAND, IPA_OPP_HAND].include?(pos) ? "#{du.name}'s Hand" : "#{du.name}'s Discard Pile")
      end
    end

    # HandleColorChangeScreen.DrawScreen: ShiftListItemToColor order,
    # ColorTileAndBGP icons (card symbol tiles) at 2,2i; names at 4,1 double
    # spaced; card image 9,2; name 7,0; Type/Weakness/Resistance at 10,9..11
    COLOR_LIST  = [GRASS, FIRE, WATER, LIGHTNING, FIGHTING, PSYCHIC]
    COLOR_ICONS = [[0x14, 2], [0x10, 1], [0x1c, 2], [0x18, 1], [0x20, 3], [0x24, 3]]
    COLOR_NAMES_TEXT = %w[Grass Fire Water Lightning Fighting Psychic]

    def color_change(map, duel, du, slot, prompt)
      map.clear
      c = du.card(du.play_area[slot])
      map.picture(9, 2, c.gfx)
      card_text(map, 7, 0, c)
      COLOR_ICONS.each_with_index { |(t, pal), i| cgb_rect(map, 2, i * 2, t, pal) }
      COLOR_NAMES_TEXT.each_with_index { |n, i| map.text(4, 1 + i * 2, n) }
      map.text(10, 9, "Type"); map.text(10, 10, "Weakness"); map.text(10, 11, "Resistance")
      map.sym(15, 9, COLOR_SYMBOLS[duel.play_area_card_color(du, slot)])
      weak = slot == 0 ? duel.arena_card_weakness(du) : c.weakness
      res  = slot == 0 ? duel.arena_card_resistance(du) : c.resistance
      wr_symbols(map, 15, 10, weak.to_i)
      wr_symbols(map, 15, 11, res.to_i)
      map.wide_text_box
      GB.wrap(prompt).first(2).each_with_index { |l, n| map.text(1, 14 + n * 2, l) }
    end

    # PeekYourPlayAreaTransitionTable / PeekOppPlayAreaTransitionTable:
    # 0-5 prizes, 6 hand (random card), 7 deck (top card);
    # cursor pixels, x-flip, up, down, right, left
    PEEK_OWN = [[0, 24, false, 4, 2, 1, 7], [40, 24, true, 5, 3, 7, 0],
                [0, 40, false, 0, 4, 3, 7], [40, 40, true, 1, 5, 7, 2],
                [0, 56, false, 2, 0, 5, 7], [40, 56, true, 3, 1, 7, 4],
                [112, 64, false, 7, 7, 0, 1], [112, 24, false, 7, 7, 0, 1]]
    PEEK_OPP = [[152, 80, true, 2, 4, 7, 1], [112, 80, false, 3, 5, 0, 7],
                [152, 64, true, 4, 0, 6, 3], [112, 64, false, 5, 1, 2, 6],
                [152, 48, true, 0, 2, 6, 5], [112, 48, false, 1, 3, 4, 6],
                [0, 40, false, 7, 7, 5, 4], [0, 80, false, 6, 6, 1, 0]]

    # DrawLargePictureOfCard (LargeCardTileData): border from DuelOtherGraphics
    # + $15 ($d0-$d7), type header rows 1-2, picture 6,3, at x 5..14, y 0..11
    def large_card(map, card)
      map.clear
      o = ->(x, y, t) { map.put(x, y, [:other, 0x15 + t]) }
      o.call(5, 0, 0); o.call(14, 0, 1); o.call(5, 11, 2); o.call(14, 11, 3)
      (6..13).each { |x| o.call(x, 0, 4); o.call(x, 11, 5) }
      (1..10).each { |y| o.call(5, y, 6); o.call(14, y, 7) }
      row = card.trainer? ? 0 : (card.energy? ? 2 : 4)
      16.times { |i| map.header(6 + i % 8, 1 + i / 8, row * 8 + i) }
      map.picture(6, 3, card.gfx)
    end

    # OpenGlossaryScreen_TransitionTable: cursor pixels, up, down, right, left;
    # position 9 is "To next page" / "To previous page"
    GLOSSARY_CURSOR = [[0, 24, 4, 1, 5, 5], [0, 40, 0, 2, 6, 6], [0, 56, 1, 3, 7, 7],
                       [0, 72, 2, 4, 8, 8], [0, 88, 3, 0, 9, 9], [80, 24, 9, 6, 0, 0],
                       [80, 40, 5, 7, 1, 1], [80, 56, 6, 8, 2, 2], [80, 72, 7, 9, 3, 3],
                       [80, 88, 8, 5, 4, 4]]

    # OpenGlossaryScreen.display_menu / .print_menu
    def glossary_menu(map, page)
      map.clear
      map.text(5, 0, "Pokémon Card Glossary")
      map.sym(16, 1, SYM_0 + 1 + page); map.sym(17, 1, SYM_SLASH); map.sym(18, 1, SYM_0 + 2)
      TCG::GLOSSARY_MENU[page].each_with_index { |l, n| map.text(1, 3 + n * 2, l) }
      map.wide_text_box
      map.text(1, 14, "Choose a word and press the\nA button.", line_step: 2)
    end

    # OpenGlossaryScreen.print_description
    def glossary_entry(map, page, item)
      x, title, lines = TCG::GLOSSARY[page * 9 + item]
      map.clear
      map.text(5, 0, "Pokémon Card Glossary")
      map.box(0, 4, 20, 14)
      map.text(x, 2, title)
      lines.each_with_index { |l, n| map.text(1, 5 + n, l) }
    end

    # DrawDuelistPortraitsAndNames: player name 0,11 + portrait 0,5; opponent
    # name right-aligned on row 0 + portrait 13,1; middle separator
    def duelist_portraits(map, duel, opp_portrait)
      map.clear
      pl, op = duel.duelists
      map.text(0, 11, pl.name)
      map.picture(0, 5, "Duelists/player", 6, 6)
      map.text(COLS - text_tiles(op.name), 0, op.name)
      map.picture(13, 1, "Duelists/#{opp_portrait}", 6, 6) if opp_portrait
      duel_horizontal_separator(map)
    end

    # DeckAndHandIconsTileData / CGBPalData ($f4-$fb = DuelOtherGraphics + $29)
    def deck_and_hand_icons(map)
      map.sym(4, 3, SYM_CROSS); map.sym(10, 3, SYM_CROSS)
      map.sym(9, 10, SYM_CROSS); map.sym(15, 10, SYM_CROSS)
      [[8, 2, 0], [2, 2, 4], [7, 9, 0], [13, 9, 4]].each do |x, y, t|
        4.times { |i| map.put(x + i % 2, y + i / 2, [:other, 0x29 + t + i]) }
        map.palette(x, y, 2, 2, 2)
      end
    end

    # PrintPlayer/OpponentNumberOfHandAndDeckCards
    def draw_counts(map, pl_hand, pl_deck, op_hand, op_deck)
      two_digits(map, 16, 10, pl_hand); two_digits(map, 10, 10, pl_deck)
      two_digits(map, 5, 3, op_hand); two_digits(map, 11, 3, op_deck)
    end

    # WriteTwoDigitNumberInTxSymbol_PadSpace
    def two_digits(map, x, y, n)
      map.sym(x, y, n >= 10 ? SYM_0 + (n / 10) % 10 : SYM_SPACE)
      map.sym(x + 1, y, SYM_0 + n % 10)
    end

    # _DrawPlayAreaToPlacePrizeCards: bench stage icons (player from 0,10
    # rightwards, opponent from 18,0 leftwards), hand/deck/discard icons and
    # the Poke Ball fields ($a0-$ab = DuelOtherGraphics 0-$b) at 8,6 / 8,3
    PLACE_PRIZE_ICONS_OWN = [[15, 11], [15, 6], [15, 8]]
    PLACE_PRIZE_ICONS_OPP = [[0, 0], [0, 4], [0, 2]]
    # HandleDuelSetup.PrizeCardCoordinates: player x, y, opponent x, y
    PRIZE_PLACE_COORDS = [[5, 6, 14, 5], [6, 6, 13, 5], [5, 7, 14, 4],
                          [6, 7, 13, 4], [5, 8, 14, 3], [6, 8, 13, 3]]
    PRIZE_TILE = [:other, 0x0c]   # $ac
    # 7-9 Prizes: 3 columns (player 4-6, opponent 15-13), same rows
    PRIZE_PLACE_COORDS_9 = (0...MAX_PRIZES).map do |i|
      [4 + i % 3, 6 + i / 3, 15 - i % 3, 5 - i / 3]
    end

    def placing_prizes(map, duel, decks)
      map.clear
      [[0, 0, 10, 3, PLACE_PRIZE_ICONS_OWN, 6], [1, 18, 0, -3, PLACE_PRIZE_ICONS_OPP, 3]].each do |w, bx, by, step, icons, fy|
        du = duel.duelists[w]
        (1...du.num_in_play_area).each do |e|
          st = du.slot_stage[e].to_i
          cgb_rect(map, bx, by, ICON_BENCH + st * 4, st >= STAGE2 ? 1 : 2)
          bx += step
        end
        (hx, hy), (dx, dy), (px, py) = icons
        map.text(hx, hy, "Hand")
        cross_number(map, hx + 2, hy, du.hand.size)
        cgb_rect(map, dx, dy, ICON_DECK, 2)
        cross_number(map, dx + 2, dy + 1, decks[w])
        cgb_rect(map, px, py, ICON_DISCARD, 2)
        cross_number(map, px + 2, py + 1, du.discard_pile.size)
        12.times { |i| map.put(8 + i % 4, fy + i / 4, [:other, i]) }
      end
    end

    # DisplayNoBasicPokemonInHandScreen: bare list of the 7 hand cards
    def no_basic_hand(map, du)
      map.clear
      map.box(0, 0, 20, 18)
      du.hand.first(7).each_with_index do |i, n|
        c = du.card(i)
        card_symbol(map, 2, 2 + n * 2, c)
        card_text(map, 4, 3 + n * 2, c, padded_name(c, 14))
      end
      map.text(1, 1, "#{du.name}'s Hand")
    end

    def play_area_arrows(map, index, tile)
      ARROWS[index].each { |x, y| tile ? map.cgb(x, y, tile) : map.sym(x, y, SYM_SPACE) }
    end

    # CheckMenuData / YourPlayAreaMenuData / OppPlayAreaMenuData(_WithClairvoyance),
    # indexed by cursor position 2*y + x
    CHECK_MENU = [[2, 14, "In Play Area"], [12, 14, "Glossary"], [2, 16, "Your Play Area"],
                  [12, 16, "Opp. Play Area"]]
    YOUR_PLAY_AREA_MENU = [[2, 14, "Your Pokémon"], [12, 14, "Your Hand"], [2, 16, "Your Discard Pile"]]
    OPP_PLAY_AREA_MENU  = [[2, 14, "Opponent's Pokémon"], [12, 14, "Opponent Hand"],
                           [2, 16, "Opponent's Discard Pile"]]

    def check_menu_items(map, items)
      map.wide_text_box
      items.each { |it| map.text(it[0], it[1], it[2]) if it }
    end

    # DrawWideTextBox_PrintText: text at 1,14, lines 2 tiles apart
    def text_box_lines(map, lines)
      map.wide_text_box
      lines.first(2).each_with_index { |l, n| map.text(1, 14 + n * 2, l) }
    end
  end

  #----------------------------------------------------------------------------
  class DuelScene < DuelUI
    include GB

    BANNER = { :player_turn => 0, :opponent_turn => 1, :between_turns => 2,
               :decision => 3, :bench => 4, :arena => 5, :coin => 6 }

    attr_accessor :duel
    attr_reader :map

    attr_accessor :portrait   # opponent portrait (Graphics/.../Duelists)

    def shows_card_screens?; true; end

    def initialize
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      # same z as pbFadeOutIn's black overlay but created after it, so the duel
      # draws on top while pbTCGDuel runs inside pbFadeOutIn (at 99_990 the
      # whole duel stayed hidden behind the black fade)
      @viewport.z = 99_999
      @map = TileMap.new
      @gb = Renderer.new(@viewport)
      @banners = RPG::Cache.load_bitmap(GFX + "UI/", "box_messages")
      @banner = Sprite.new(@viewport)
      @banner.z = 10
      @banner.visible = false
      @menu_item = 0
    end

    def dispose
      @gb.dispose
      @banner.bitmap&.dispose
      @banner.dispose
      @viewport.dispose
    end

    def render; @gb.draw(@map); end

    # one GB frame. With a speed-up script (SPEEDUP_STAGES / $GameSpeed, Q
    # to change) several GB frames share one screen update, so the duel runs
    # 1.5x / 2x / 3x / 4x like the rest of the game
    def frame
      @frame_debt = (@frame_debt || 0) + 1.0 / TCG.speed_multiplier
      if @frame_debt >= 1
        @frame_debt -= 1
        Graphics.update
      end
      Input.update
    end

    # blinking cursor (16-frame period, like HandleMenuInput) until a key in
    # `keys` is pressed; returns that key. A block may handle other input and
    # return non-nil to stop.
    def blink_wait(x, y, on, off, keys)
      counter = 0
      loop do
        if counter % 16 == 0
          @map.sym(x, y, (counter / 16).even? ? on : off)
          render
        end
        counter += 1
        frame
        keys.each { |k| return k if Input.trigger?(k) }
        if block_given? && (r = yield)
          @map.sym(x, y, off)
          return r
        end
      end
    end

    #--------------------------------------------------------------------------
    # DuelUI interface
    #--------------------------------------------------------------------------
    def refresh(duel)
      @duel = duel
      return unless duel
      Screens.duel_main_scene(@map, duel)
      render
      Graphics.update
    end

    # DrawWideTextBox_WaitForInput (2 lines per box, A/B for the next one);
    # keep: print over the screen currently shown instead of the main scene
    def message(text, keep: false)
      Screens.duel_main_scene(@map, @duel) if @duel && !keep
      lines = GB.wrap(text.to_s.gsub("<RAMTEXT>", ""))
      lines.each_slice(2) do |pair|
        Screens.text_box_lines(@map, pair)
        blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
      end
    end

    # coin_toss: see 075_CoinToss.rb (_TossCoin)

    def event(type, *args)
      case type
      when :turn_start
        # MainDuelLoop: wCurrentDuelMenuItem = 0, the cursor starts on Hand
        @menu_item = 0
        refresh(@duel)
        show_banner(args[0] == @duel.duelists[0].name ? :player_turn : :opponent_turn)
        pbWait(0.6)
        hide_banner
      when :between_turns
        show_banner(:between_turns); pbWait(0.4); hide_banner
      when :draw
        # DisplayPlayerDrawCardScreen: the player's draws, and the opponent's
        # while the player's Omanyte has Clairvoyance
        du = @duel.duelists.find { |x| x.name == args[0] }
        if du && args[2] == :turn && (du.player? || @duel.clairvoyance_active?(@duel.duelists[0]))
          card_detail(du.display_id(args[1]), du.player? ? "You drew <RAMTEXT>." : "#{du.name} drew <RAMTEXT>.")
        end
      when :play_pokemon
        # OppAction_PlayBasicPokemonCard (large picture) / PlayPokemonCard (text box)
        du = @duel.duelists.find { |x| x.name == args[0] }
        return unless du
        if du.player?
          message("Placed #{Screens.name_and_level(du.card(args[1]))}\non the Bench.")
        else
          card_detail(du.display_id(args[1]), "Placed <RAMTEXT>\non the Bench.")
        end
      when :attach_energy
        # PrintAttachedEnergyToPokemon: over the play area list (player) or
        # the large picture of the energy (OppAction_PlayEnergyCard)
        du = @duel.duelists.find { |x| x.name == args[0] }
        return unless du
        text = "Attached #{du.card(args[1]).name}\nto #{du.card(du.play_area[args[2]]).name}."
        if du.player?
          Screens.play_area_card_list(@map, @duel, du)
          message(text, keep: true)
        else
          card_detail(du.display_id(args[1]), text)
        end
      when :evolve
        # PrintPokemonEvolvedIntoPokemon
        du = @duel.duelists.find { |x| x.name == args[0] }
        return unless du
        c = du.card(args[1])
        text = "#{c.preevo} evolved\ninto #{c.name}."
        if du.player?
          Screens.play_area_card_list(@map, @duel, du)
          message(text, keep: true)
        else
          card_detail(du.display_id(args[1]), text)
        end
      when :trainer_used
        # DisplayUsedTrainerCardDetailScreen (+ PrintUsedTrainerCardDescription
        # for the opponent: name at 1,1 and the card text from 1,3)
        du = @duel.duelists.find { |x| x.name == args[0] }
        return unless du
        id = du.display_id(args[1])
        card_detail(id, "Used <RAMTEXT>.")
        unless du.player?
          @map.clear
          Screens.card_text(@map, 1, 1, TCG.card(id), TCG.card(id).name)
          GB.wrap(TCG.card(id).desc.to_s).first(8).each_with_index { |l, n| @map.text(1, 3 + n, l) }
          message("Used #{TCG.card(id).name}.", keep: true)
        end
      when :opp_attack
        # DisplayOpponentUsedAttackScreen: attack at row 1, description from
        # 1,4 (1,3 when 7+ lines), then PrintPokemonsAttackText
        atk = TCG.card(args[0]).attacks[args[1]]
        @map.clear
        Screens.attack_info(@map, atk, 1, false)
        lines = GB.wrap(atk.desc.to_s)
        lines.pop while lines.any? && lines[-1].empty?
        y = lines.size >= 7 ? 3 : 4
        lines.first(8).each_with_index { |l, n| @map.text(1, y + n, l) }
        message(args[2], keep: true)
      when :shuffle_draw then shuffle_and_draw_screen(args[0])
      when :no_basic     then no_basic_screen(args[0])
      when :place_prizes then place_prizes_screen(args[0])
      when :draw_n
        du = @duel.duelists.find { |x| x.name == args[0] }
        draw_cards_screen(du, args[1]) if du
      when :show_hand
        # Lass shows the opponent's hand
        du = @duel.duelists.find { |x| x.name == args[0] }
        if du && !du.player? && !du.hand.empty?
          card_list_screen(du, du.hand.dup, "#{du.name}'s Hand", "Choose the card\nyou wish to examine.", menu: :view)
        end
      end
    end

    #--------------------------------------------------------------------------
    # duel setup / draw screens (the card flying animations are not ported:
    # each card is a short delay, skippable with B like CheckSkipDelayAllowed)
    #--------------------------------------------------------------------------
    CARD_ANIM_FRAMES = 16

    def anim_delay(frames)
      frames.times do
        frame
        break if Input.press?(Input::BACK)
      end
    end

    def wait_text_box_input
      blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
    end

    # hand/deck numbers while `drawers` draw their k-th card; `base` = cards
    # already drawn before the screen (the engine draws before the setup one)
    def draw_counts(drawers, k, base)
      a = @duel.duelists.map do |x|
        drawers.include?(x) ? [x.hand.size - base + k, x.cards_in_deck + base - k] : [x.hand.size, x.cards_in_deck]
      end
      Screens.draw_counts(@map, *a[0], *a[1])
    end

    # PlayShuffleAndDrawCardsAnimation (name nil: both duelists)
    def shuffle_and_draw_screen(name)
      du = name && @duel.duelists.find { |x| x.name == name }
      drawers = du ? [du] : @duel.duelists
      Screens.duelist_portraits(@map, @duel, @portrait)
      practice = !du && @duel.is_practice
      text = if du then "#{du.name} shuffles the Deck."
             elsif practice then "Since this is just practice,\nDo not shuffle the Deck."
             else "Each player will\nshuffle the opponent's Deck."
             end
      Screens.text_box_lines(@map, GB.wrap(text))
      render
      if practice
        wait_text_box_input
      else
        play_card_anim(du ? (du.player? ? :DUEL_ANIM_PLAYER_SHUFFLE : :DUEL_ANIM_OPP_SHUFFLE) : :DUEL_ANIM_BOTH_SHUFFLE, 3)
      end
      Screens.deck_and_hand_icons(@map)
      draw_counts(drawers, 0, STARTING_HAND_SIZE)
      Screens.text_box_lines(@map, GB.wrap(du ? "#{du.name}\ndrew 7 cards." : "Each player will draw 7 cards."))
      render
      STARTING_HAND_SIZE.times do |k|
        play_card_anim(du ? (du.player? ? :DUEL_ANIM_PLAYER_DRAW : :DUEL_ANIM_OPP_DRAW) : :DUEL_ANIM_BOTH_DRAW)
        draw_counts(drawers, k + 1, STARTING_HAND_SIZE)
        render
      end
      anim_delay(30)
    end

    # DisplayNoBasicPokemonInHandScreen(AndText) / NeitherPlayerHasBasicPkmnText
    def no_basic_screen(name)
      if name
        du = @duel.duelists.find { |x| x.name == name }
        message("There are no Basic Pokémon\nin #{du.name}'s hand.", keep: true)
        Screens.no_basic_hand(@map, du)
        render
        wait_text_box_input
      else
        message("Neither player has any Basic\nPokémon in his or her hand.", keep: true)
        @duel.duelists.each do |x|
          Screens.no_basic_hand(@map, x)
          render
          wait_text_box_input
        end
      end
      message("Return the cards to the Deck\nand draw again.", keep: true)
    end

    # HandleDuelSetup: DrawPlayAreaToPlacePrizeCards + .PlacePrizes
    def place_prizes_screen(n)
      decks = @duel.duelists.map { |x| x.cards_in_deck + n }
      Screens.placing_prizes(@map, @duel, decks)
      message("Placing the Prizes...", keep: true)
      Screens.text_box_lines(@map, GB.wrap("Please place\n#{n} Prizes."))
      render
      n.times do |i|
        anim_delay(20)
        px, py, ox, oy = (n > 6 ? Screens::PRIZE_PLACE_COORDS_9 : Screens::PRIZE_PLACE_COORDS)[i]
        @map.put(px, py, Screens::PRIZE_TILE)
        @map.put(ox, oy, Screens::PRIZE_TILE)
        # the original always counts down from DECK_SIZE - 7 - 1 for both
        # (decks can be 55-65 cards now: each counts down from its own)
        Screens.two_digits(@map, 3, 5, decks[1] - 1 - i)
        Screens.two_digits(@map, 18, 7, decks[0] - 1 - i)
        render
      end
      wait_text_box_input
    end

    # DisplayDrawNCardsScreen (before the cards are drawn)
    def draw_cards_screen(du, n)
      # ORIGINAL BUG: trying to draw more cards than are left sets the number
      # to 0, so it says no cards can be drawn even when a few are left
      n = 0 if du.cards_in_deck < n
      Screens.duelist_portraits(@map, @duel, @portrait)
      Screens.deck_and_hand_icons(@map)
      draw_counts([du], 0, 0)
      if n == 0
        message("Cannot draw a card because\nthere are no cards in the Deck.", keep: true)
        return
      end
      Screens.text_box_lines(@map, GB.wrap("Draw #{n} card(s) from the Deck."))
      render
      n.times do |k|
        play_card_anim(du.player? ? :DUEL_ANIM_PLAYER_DRAW : :DUEL_ANIM_OPP_DRAW)
        draw_counts([du], k + 1, 0)
        render
      end
      anim_delay(30)
    end

    def show_banner(key)
      @banner.bitmap&.dispose
      @banner.bitmap = Bitmap.new(160, 64)
      @banner.bitmap.stretch_blt(Rect.new(0, 0, 160, 64), @banners, Rect.new(0, BANNER[key] * 32, 80, 32))
      @banner.x = (Graphics.width - 160) / 2
      @banner.y = (192 - 64) / 2
      @banner.visible = true
      Graphics.update
    end

    def hide_banner; @banner.visible = false; end

    #--------------------------------------------------------------------------
    # menus
    #--------------------------------------------------------------------------
    # PrintDuelMenuAndHandleInput + HandleDuelMenuInput; returns 0-5
    # (Hand, Attack, Check, PKMN Power, Retreat, Done)
    def duel_menu(duel)
      Screens.duel_main_scene(@map, duel)
      Screens.duel_menu(@map)
      loop do
        x, y = Screens::DUEL_MENU_CURSOR[@menu_item]
        key = blink_wait(x, y, SYM_CURSOR_R, SYM_SPACE,
                         [Input::USE, Input::UP, Input::DOWN, Input::LEFT, Input::RIGHT])
        @map.sym(x, y, SYM_SPACE)
        case key
        when Input::USE then return @menu_item
        when Input::UP, Input::DOWN then @menu_item ^= 1
        when Input::LEFT
          @menu_item = @menu_item >= 2 ? @menu_item - 2 : (@menu_item & 1) + 4
        when Input::RIGHT
          @menu_item = @menu_item + 2 < 6 ? @menu_item + 2 : (@menu_item & 1)
        end
        pbPlayCursorSE
      end
    end

    # DisplayPlayAreaScreen. Returns the chosen slot (PLAY_AREA_*) or nil (B).
    #   exclude_arena: cursor starts at the bench (wExcludeArenaPokemon)
    #   allowed:       slots that may be picked (others are ignored)
    #   view_only:     A opens the card page instead of selecting
    #                  (OpenPlayAreaScreenForViewing); START always does
    # select_menu: SELECT opens the "Selecting Bench Pokémon..." menu
    # (wPlayAreaSelectAction, used when replacing a Knocked Out Pokémon)
    def play_area_screen(duel, du, exclude_arena: false, allowed: nil, view_only: false,
                         cancellable: true, select_menu: false)
      first = exclude_arena ? 1 : 0
      slots = (first...du.num_in_play_area).to_a
      return nil if slots.empty?
      idx = 0
      loop do
        Screens.play_area_card_list(@map, duel, du)
        loop do
          y = slots[idx] * 3
          keys = [Input::USE, Input::BACK, Input::UP, Input::DOWN, Input::ACTION]
          keys << Input::SPECIAL if select_menu
          key = blink_wait(0, y, SYM_CURSOR_R, SYM_SPACE, keys)
          @map.sym(0, y, SYM_SPACE)
          case key
          when Input::SPECIAL
            selecting_bench_menu(duel, du)
            break
          when Input::UP   then idx = (idx - 1) % slots.size; pbPlayCursorSE
          when Input::DOWN then idx = (idx + 1) % slots.size; pbPlayCursorSE
          when Input::BACK
            return nil if cancellable
          when Input::ACTION
            show_card_page(du.display_id(du.play_area[slots[idx]]), du, slots[idx])
            break
          when Input::USE
            e = slots[idx]
            if view_only
              show_card_page(du.display_id(du.play_area[e]), du, e)
              break
            end
            next if du.slot_hp[e] == 0
            next if allowed && !allowed.include?(e)
            return e
          end
        end
      end
    end

    # SelectingBenchPokemonMenu: Hand / Examine / Back over the main scene;
    # START = Arena card page, SELECT = In Play Area (HandleSpecialDuelMainSceneHotkeys)
    def selecting_bench_menu(duel, du)
      item = 0
      loop do
        Screens.duel_main_scene(@map, duel)
        Screens.text_box_lines(@map, GB.wrap("Selecting Bench Pokémon...\n    Hand        Examine     Back"))
        loop do
          x = item * 6 + 2
          key = blink_wait(x, 16, SYM_CURSOR_R, SYM_SPACE,
                           [Input::USE, Input::LEFT, Input::RIGHT, Input::ACTION, Input::SPECIAL])
          @map.sym(x, 16, SYM_SPACE)
          case key
          when Input::LEFT  then item = (item - 1) % 3; pbPlayCursorSE
          when Input::RIGHT then item = (item + 1) % 3; pbPlayCursorSE
          when Input::ACTION
            show_card_page(du.display_id(du.arena), du, 0) if du.arena
            break
          when Input::SPECIAL
            in_play_area_screen(duel)
            return
          when Input::USE
            case item
            when 0
              card_list_screen(du, du.hand.dup, "#{du.name}'s Hand", "", menu: :view) unless du.hand.empty?
            when 1 then check_menu(duel)
            else return
            end
            break
          end
        end
      end
    end

    # DisplayCardList. Returns the chosen deck index or nil (B).
    #   menu: :play  -> Play/Check box on A (OpenPlayerHandScreen)
    #         :select -> Select/Check box on A
    #         :view  -> A opens the card page (OpenDiscardPileScreen)
    #         nil    -> A returns the card directly
    def card_list_screen(du, cards, header, info, menu: nil, cancellable: true, start: 0)
      return nil if cards.empty?
      cards = cards.dup
      sorted = false
      cur = start.clamp(0, cards.size - 1)
      scroll = [cur - Screens::CARD_LIST_VISIBLE + 1, 0].max
      loop do
        Screens.card_list(@map, du, cards, cur, scroll, header, info)
        y = 3 + (cur - scroll) * 2
        key = blink_wait(1, y, SYM_CURSOR_R, SYM_SPACE,
                         [Input::USE, Input::BACK, Input::UP, Input::DOWN, Input::ACTION, Input::SPECIAL])
        case key
        when Input::SPECIAL
          # DisplayCardList.select_pressed: sort by card ID once, back to the top
          next if sorted
          cards = cards.sort_by.with_index { |i, n| [TCG.card_order_index(du.display_id(i)) || 0, n] }
          sorted = true
          cur = 0
          scroll = 0
        when Input::UP
          if cur > 0
            cur -= 1
            scroll = cur if cur < scroll
            pbPlayCursorSE
          end
        when Input::DOWN
          if cur < cards.size - 1
            cur += 1
            scroll = cur - Screens::CARD_LIST_VISIBLE + 1 if cur >= scroll + Screens::CARD_LIST_VISIBLE
            pbPlayCursorSE
          end
        when Input::BACK
          return nil if cancellable
        when Input::ACTION
          show_card_page(du.display_id(cards[cur]))
        when Input::USE
          case menu
          when nil then return cards[cur]
          when :view then show_card_page(du.display_id(cards[cur]))
          else
            case item_selection_menu(menu == :play ? "  Play
  Check" : "  Select
  Check")
            when 0 then return cards[cur]
            when 1 then show_card_page(du.display_id(cards[cur]))
            end
          end
        end
      end
    end

    # CardListItemSelectionMenu: narrow box, cursor 1,14 / 1,16; nil on B
    def item_selection_menu(text)
      @map.box(0, 12, 12, 6)
      @map.text(1, 14, text, line_step: 2)
      idx = 0
      loop do
        y = 14 + idx * 2
        key = blink_wait(1, y, SYM_CURSOR_R, SYM_SPACE, [Input::USE, Input::BACK, Input::UP, Input::DOWN])
        @map.sym(1, y, SYM_SPACE)
        case key
        when Input::USE  then return idx
        when Input::BACK then return nil
        else idx ^= 1; pbPlayCursorSE
        end
      end
    end

    #--------------------------------------------------------------------------
    # Check menu (_OpenDuelCheckMenu)
    #--------------------------------------------------------------------------
    # 2x2 check menu cursor (HandleCheckMenuInput): position 2*y + x, cursor
    # at 1 + 10x, 14 + 2y. allowed: positions that exist; horizontal false
    # when only the left column exists (wce5e bit 7). Returns position or nil.
    # The block is called every frame with the current position.
    def check_menu_cursor(pos, allowed, horizontal = true)
      loop do
        x = pos & 1
        y = pos >> 1
        key = blink_wait(1 + 10 * x, 14 + 2 * y, SYM_CURSOR_R, SYM_SPACE,
                         [Input::USE, Input::BACK, Input::UP, Input::DOWN, Input::LEFT, Input::RIGHT]) do
          yield(pos) if block_given?
          nil
        end
        @map.sym(1 + 10 * x, 14 + 2 * y, SYM_SPACE)
        case key
        when Input::USE  then return pos
        when Input::BACK then return nil
        when Input::LEFT, Input::RIGHT
          next unless horizontal
          y = 0 if y == 1 && !allowed.include?(3)   # HandleCheckMenuInput_YourOrOppPlayArea
          x ^= 1
        when Input::UP, Input::DOWN
          x = 0 if x == 1 && !allowed.include?(3)
          y ^= 1
        end
        np = 2 * y + x
        if allowed.include?(np)
          pos = np
          pbPlayCursorSE
        end
      end
    end

    def check_menu(duel)
      pos = 0
      loop do
        Screens.duel_main_scene(@map, duel)
        Screens.check_menu_items(@map, Screens::CHECK_MENU)
        pos = check_menu_cursor(pos, [0, 1, 2, 3])
        return if pos.nil?
        case pos
        when 0 then in_play_area_screen(duel)
        when 1 then glossary_screen
        when 2 then your_or_opp_play_area_menu(duel, duel.duelists[0], true)
        when 3
          your_or_opp_play_area_menu(duel, duel.duelists[1], false,
                                     clairvoyance: duel.clairvoyance_active?(duel.duelists[0]))
        end
      end
    end

    # DuelCheckMenu_YourPlayArea / DuelCheckMenu_OppPlayArea
    def your_or_opp_play_area_menu(duel, du, own, clairvoyance: false)
      items = own ? Screens::YOUR_PLAY_AREA_MENU : Screens::OPP_PLAY_AREA_MENU
      items = [items[0], nil, items[2]] if !own && !clairvoyance
      allowed = items.each_index.select { |i| items[i] }
      pos = 0
      loop do
        Screens.your_or_opp_play_area(@map, duel, du, own)
        Screens.check_menu_items(@map, items)
        shown = nil
        pos = check_menu_cursor(pos, allowed, own || clairvoyance) do |p|
          if shown != p
            Screens.play_area_arrows(@map, (own ? 0 : 3) + shown, nil) if shown
            Screens.play_area_arrows(@map, (own ? 0 : 3) + p, Screens::ICON_ARROW)
            shown = p
            render
          end
        end
        return if pos.nil?
        examine = "Choose the card\nyou wish to examine."
        case pos
        when 0 then play_area_screen(duel, du, view_only: true)
        when 1 then card_list_screen(du, du.hand.dup, "#{du.name}'s Hand", examine, menu: :view)
        when 2
          if du.discard_pile.empty?
            message(_INTL("The Discard Pile has no cards."))
          else
            card_list_screen(du, du.discard_pile.dup, own ? "Your Discard Pile" : "Opponent's Discard Pile",
                             examine, menu: :view)
          end
        end
      end
    end

    # _SelectPrizeCards: own play area screen + "Please choose a Prize.";
    # the cursor moves over all 6 positions and A on a taken one is ignored.
    # Returns the prize index.
    def prize_select_screen(duel, du, avail, start = 0)
      pos = start
      Screens.your_or_opp_play_area(@map, duel, du, true)
      @map.wide_text_box
      @map.text(1, 14, "Please choose a Prize.")
      return prize_select_grid(duel, avail, pos) if Screens.three_column_prizes?(duel)
      counter = 0
      loop do
        x, y, flip, up, down, right, left = Screens::PRIZE_CURSOR[pos]
        @map.sprites.clear
        @map.sprites << [x, y, flip] if (counter / 16).even?
        render if counter % 16 == 0
        counter += 1
        frame
        np = if Input.trigger?(Input::UP) then up
             elsif Input.trigger?(Input::DOWN) then down
             elsif Input.trigger?(Input::RIGHT) then right
             elsif Input.trigger?(Input::LEFT) then left
             end
        if np
          pos = np
          counter = 0
          pbPlayCursorSE
        elsif Input.trigger?(Input::USE) && avail.include?(pos)
          @map.sprites.clear
          return pos
        end
      end
    end

    # 7-9 Prizes: no room for the arrow between the columns, so the chosen
    # prize blinks instead
    def prize_select_grid(duel, avail, pos)
      n = duel.initial_prizes
      pos = avail.first unless pos && pos < n
      counter = 0
      loop do
        @map.hidden_tag = (counter / 16).odd? ? [:prize, pos] : nil
        render if counter % 16 == 0
        counter += 1
        frame
        key = if Input.trigger?(Input::UP) then :up
              elsif Input.trigger?(Input::DOWN) then :down
              elsif Input.trigger?(Input::RIGHT) then :right
              elsif Input.trigger?(Input::LEFT) then :left
              end
        np = key && Screens.prize_grid_move(pos, n, key, true)
        if np && np != pos
          pos = np
          counter = 0
          pbPlayCursorSE
        elsif Input.trigger?(Input::USE) && avail.include?(pos)
          @map.hidden_tag = nil
          return pos
        end
      end
    end

    # Peek with 7-9 Prizes: the chosen prize blinks; the hand and the deck
    # keep their arrows (table rows 6 and 7). Returns what was seen, or nil
    # for B.
    def peek_grid(duel, du, own, table)
      n = duel.initial_prizes
      hand, deck = n, n + 1
      pos = 0
      counter = 0
      loop do
        blink_off = (counter / 16).odd?
        @map.sprites.clear
        @map.hidden_tag = nil
        if pos < n
          @map.hidden_tag = [:prize, pos] if blink_off
        elsif !blink_off
          x, y, flip = table[pos == hand ? 6 : 7]
          @map.sprites << [x, y, flip]
        end
        render if counter % 16 == 0
        counter += 1
        frame
        key = if Input.trigger?(Input::UP) then :up
              elsif Input.trigger?(Input::DOWN) then :down
              elsif Input.trigger?(Input::RIGHT) then :right
              elsif Input.trigger?(Input::LEFT) then :left
              end
        np = if key.nil? then nil
             elsif pos < n
               # past the side of the prizes: the hand / deck column
               Screens.prize_grid_move(pos, n, key, own) || (!own && key == :left ? hand : deck)
             elsif key == :up || key == :down then pos == hand ? deck : hand
             else 0
             end
        if np && np != pos
          pos = np
          counter = 0
          pbPlayCursorSE
        elsif Input.trigger?(Input::BACK)
          @map.sprites.clear
          @map.hidden_tag = nil
          return nil
        elsif Input.trigger?(Input::USE)
          card, seen = if pos < n
                         du.prize_taken?(pos) ? nil : [du.prize_cards[pos], :prize]
                       elsif pos == hand
                         du.hand.empty? ? nil : [du.hand.sample, own ? :own_hand : :opp_hand]
                       else
                         du.deck_list.empty? ? nil : [du.deck_list.first, own ? :own_deck : :opp_deck]
                       end
          next unless card
          @map.sprites.clear
          @map.hidden_tag = nil
          show_card_page(du.display_id(card))
          return seen
        end
      end
    end

    # OpenInPlayAreaScreen: A/START opens what the cursor is on, moving onto
    # the row past a bench opens that side's Pokémon list, B returns.
    # (ORIGINAL BUG "Duel Escape": A on the same frame as a move to the play
    # area rows jumps past the end of .PositionsJumpTable; not reproduced.)
    def in_play_area_screen(duel)
      pl, op = duel.duelists
      table = Screens::IPA_CURSOR.map(&:dup)
      # TransitionTable2 (Clairvoyance): up from the opponent's discard pile
      # goes to the opponent's hand
      table[Screens::IPA_OPP_DISCARD][3] = Screens::IPA_OPP_HAND if duel.clairvoyance_active?(pl)
      pos = Screens::IPA_PLAYER_ACTIVE
      loop do
        Screens.in_play_area(@map, duel)
        Screens.in_play_area_text(@map, duel, pos)
        counter = 0
        action = nil
        loop do
          x, y, flip = table[pos]
          @map.sprites.clear
          @map.sprites << [x, y, flip] if (counter / 16).even?
          render if counter % 16 == 0
          counter += 1
          frame
          dir = [Input::UP, Input::DOWN, Input::RIGHT, Input::LEFT].index { |k| Input.trigger?(k) }
          if dir
            prev = pos
            np = table[pos][3 + dir]
            # .player_area / .opponent_area: skip empty bench slots
            if np < Screens::IPA_PLAYER_ACTIVE
              n = pl.num_in_play_area - 1
              np = if n == 0 then Screens::IPA_PLAYER_PLAY_AREA
                   elsif np >= n then (dir == 2 ? 0 : n - 1)
                   else np
                   end
            elsif np >= Screens::IPA_OPP_BENCH_1 && np < Screens::IPA_PLAYER_PLAY_AREA
              n = op.num_in_play_area - 1
              np = if n == 0 then Screens::IPA_OPP_PLAY_AREA
                   elsif np - Screens::IPA_OPP_BENCH_1 >= n then (dir == 3 ? Screens::IPA_OPP_BENCH_1 : n + Screens::IPA_OPP_DISCARD)
                   else np
                   end
            end
            pbPlayCursorSE
            if np >= Screens::IPA_PLAYER_PLAY_AREA
              action = [np, prev]
              break
            end
            pos = np
            counter = 0
            Screens.in_play_area_text(@map, duel, pos)
          elsif Input.trigger?(Input::BACK)
            @map.sprites.clear
            return
          elsif Input.trigger?(Input::USE) || Input.trigger?(Input::ACTION)
            action = [pos, pos]
            break
          end
        end
        @map.sprites.clear
        target, pos = action
        case target
        when Screens::IPA_PLAYER_PLAY_AREA then play_area_screen(duel, pl, view_only: true)
        when Screens::IPA_OPP_PLAY_AREA then play_area_screen(duel, op, view_only: true)
        when 0..4, Screens::IPA_PLAYER_ACTIVE
          slot = target == Screens::IPA_PLAYER_ACTIVE ? 0 : target + 1
          show_card_page(pl.display_id(pl.play_area[slot]), pl, slot) if pl.play_area[slot]
        when Screens::IPA_OPP_ACTIVE, 11..15
          slot = target == Screens::IPA_OPP_ACTIVE ? 0 : target - 10
          show_card_page(op.display_id(op.play_area[slot]), op, slot) if op.play_area[slot]
        when Screens::IPA_PLAYER_HAND
          card_list_screen(pl, pl.hand.dup, "#{pl.name}'s Hand", "Choose the card\nyou wish to examine.", menu: :view)
        when Screens::IPA_OPP_HAND
          card_list_screen(op, op.hand.dup, "#{op.name}'s Hand", "Choose the card\nyou wish to examine.", menu: :view)
        when Screens::IPA_PLAYER_DISCARD, Screens::IPA_OPP_DISCARD
          du = target == Screens::IPA_PLAYER_DISCARD ? pl : op
          if du.discard_pile.empty?
            message(_INTL("The Discard Pile has no cards."))
          else
            card_list_screen(du, du.discard_pile.dup, du == pl ? "Your Discard Pile" : "Opponent's Discard Pile",
                             "Choose the card\nyou wish to examine.", menu: :view)
          end
        end
      end
    end

    #--------------------------------------------------------------------------
    # small menus in the wide text box
    #--------------------------------------------------------------------------
    # YesOrNoMenuWithText: text at 1,14, "Yes     No" at 7,16, cursor 6 / 10.
    # The cursor starts on No unless yes_default (..._SetCursorToYes).
    # keep: ask over the screen currently shown (YesOrNoMenuWithText)
    def yes_no_menu(text, yes_default = false, keep: false)
      two_item_core(text, "Yes     No", 7, 6, yes_default ? 0 : 1, false, keep) == 0
    end

    # TwoItemHorizontalMenu: the text's second line holds the two items,
    # cursor 6 / 10, starts on the first item; nil when B is pressed
    def two_item_menu(text)
      two_item_core(text, nil, 0, 6, 0, true)
    end

    def two_item_core(text, items, ix, cx, cur, cancellable, keep = false)
      Screens.duel_main_scene(@map, @duel) if @duel && !keep
      lines = GB.wrap(text)
      Screens.text_box_lines(@map, lines)
      @map.text(ix, 16, items) if items
      loop do
        x = cx + cur * 4
        key = blink_wait(x, 16, SYM_CURSOR_R, SYM_SPACE, [Input::USE, Input::BACK, Input::LEFT, Input::RIGHT])
        @map.sym(x, 16, SYM_SPACE)
        case key
        when Input::USE  then return cur
        when Input::BACK then return nil if cancellable
        else cur ^= 1; pbPlayCursorSE
        end
      end
    end

    # four or fewer choices laid out like the Check menu (fallback for
    # selections that have no dedicated screen yet)
    def box_menu(text, labels, cancellable = true)
      message(text)
      items = labels.first(4).each_with_index.map { |l, i| [2 + 10 * (i % 2), 14 + 2 * (i / 2), l] }
      Screens.duel_main_scene(@map, @duel) if @duel
      @map.wide_text_box
      items.each { |x, y, t| @map.text(x, y, t) }
      loop do
        pos = check_menu_cursor(0, (0...items.size).to_a)
        return pos if pos
        return nil if cancellable
      end
    end

    # HandleColorChangeScreen: du's play area card at slot, 6 colors listed
    # GRASS FIRE WATER LIGHTNING FIGHTING PSYCHIC; returns the color or nil (B)
    def color_change_screen(duel, du, slot, prompt)
      Screens.color_change(@map, duel, du, slot, prompt)
      idx = 0
      loop do
        y = 1 + idx * 2
        key = blink_wait(1, y, SYM_CURSOR_R, SYM_SPACE, [Input::USE, Input::BACK, Input::UP, Input::DOWN])
        @map.sym(1, y, SYM_SPACE)
        case key
        when Input::USE  then return Screens::COLOR_LIST[idx]
        when Input::BACK then return nil
        when Input::UP   then idx = (idx - 1) % 6; pbPlayCursorSE
        when Input::DOWN then idx = (idx + 1) % 6; pbPlayCursorSE
        end
      end
    end

    # OpenGlossaryScreen: A on a word shows its page (B returns), A on the
    # last item or SELECT (SPECIAL) flips the page, B leaves
    def glossary_screen
      page = 0
      pos = 0
      Screens.glossary_menu(@map, page)
      counter = 0
      loop do
        x, y, up, down, right, left = Screens::GLOSSARY_CURSOR[pos]
        @map.sprites.clear
        @map.sprites << [x, y, false] if (counter / 16).even?
        render if counter % 16 == 0
        counter += 1
        frame
        np = if Input.trigger?(Input::UP) then up
             elsif Input.trigger?(Input::DOWN) then down
             elsif Input.trigger?(Input::RIGHT) then right
             elsif Input.trigger?(Input::LEFT) then left
             end
        if np
          pos = np
          counter = 0
          pbPlayCursorSE
        elsif Input.trigger?(Input::BACK)
          @map.sprites.clear
          return
        elsif Input.trigger?(Input::USE) || Input.trigger?(Input::SPECIAL)
          if pos == 9 || Input.trigger?(Input::SPECIAL)
            page ^= 1
          else
            @map.sprites.clear
            Screens.glossary_entry(@map, page, pos)
            render
            loop { frame; break if Input.trigger?(Input::BACK) }
          end
          Screens.glossary_menu(@map, page)
          counter = 0
        end
      end
    end

    # _DisplayCardDetailScreen: large picture + text box (<RAMTEXT> = name)
    def card_detail(id, text)
      card = TCG.card(id)
      Screens.large_card(@map, card)
      lines = GB.wrap(text.gsub("<RAMTEXT>", Screens.name_and_level(card)))
      lines.each_slice(2) do |pair|
        Screens.text_box_lines(@map, pair)
        blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
      end
    end

    # _HandlePeekSelection: Your / Opp. Play Area (B not allowed), then a
    # cursor over that side's prizes, hand and deck. A shows the card page and
    # ends the power; B goes back to the first menu. Returns what was seen.
    def peek_screen(duel)
      pl, op = duel.duelists
      loop do
        Screens.your_or_opp_play_area(@map, duel, pl, true)
        @map.wide_text_box
        @map.text(2, 14, "Your Play Area")
        @map.text(2, 16, "Opp. Play Area")
        idx = 0
        loop do
          y = 14 + idx * 2
          key = blink_wait(1, y, SYM_CURSOR_R, SYM_SPACE, [Input::USE, Input::UP, Input::DOWN])
          @map.sym(1, y, SYM_SPACE)
          break if key == Input::USE
          idx ^= 1
          pbPlayCursorSE
        end
        own = idx == 0
        du = own ? pl : op
        Screens.your_or_opp_play_area(@map, duel, du, own)
        @map.wide_text_box
        @map.text(1, 14, "Which card would you like to see?")
        table = own ? Screens::PEEK_OWN : Screens::PEEK_OPP
        if Screens.three_column_prizes?(duel)
          seen = peek_grid(duel, du, own, table)
          return seen if seen
          next
        end
        pos = 0
        counter = 0
        loop do
          x, y, flip, up, down, right, left = table[pos]
          @map.sprites.clear
          @map.sprites << [x, y, flip] if (counter / 16).even?
          render if counter % 16 == 0
          counter += 1
          frame
          np = if Input.trigger?(Input::UP) then up
               elsif Input.trigger?(Input::DOWN) then down
               elsif Input.trigger?(Input::RIGHT) then right
               elsif Input.trigger?(Input::LEFT) then left
               end
          if np
            pos = np
            counter = 0
            pbPlayCursorSE
          elsif Input.trigger?(Input::BACK)
            @map.sprites.clear
            break
          elsif Input.trigger?(Input::USE)
            card, seen = case pos
                         when 0..5
                           du.prize_taken?(pos) ? nil : [du.prize_cards[pos], :prize]
                         when 6
                           du.hand.empty? ? nil : [du.hand.sample, own ? :own_hand : :opp_hand]
                         else
                           du.deck_list.empty? ? nil : [du.deck_list.first, own ? :own_deck : :opp_deck]
                         end
            next unless card
            @map.sprites.clear
            show_card_page(du.display_id(card))
            return seen
          end
        end
      end
    end

    # OpenCardPage: A/START next page (closes after the last), RIGHT next
    # (wraps), LEFT previous, B closes. du/slot: play area card page.
    def show_card_page(id, du = nil, slot = nil)
      card = TCG.card(id)
      pages = Screens.card_pages(card)
      n = 0
      loop do
        Screens.card_page(@map, @duel, card, pages[n], du, slot)
        render
        loop do
          frame
          if Input.trigger?(Input::BACK)
            n = nil
            break
          elsif Input.trigger?(Input::USE) || Input.trigger?(Input::ACTION)
            n += 1
            n = nil if n >= pages.size
            break
          elsif Input.trigger?(Input::RIGHT)
            n = (n + 1) % pages.size
            break
          elsif Input.trigger?(Input::LEFT)
            n = [n - 1, 0].max
            break
          end
        end
        return if n.nil?
      end
    end


    # DuelMenu_Attack: returns the chosen [deck_index, attack_index] or nil (B).
    # A on an attack returns it; the ACTION key (START) shows its text.
    def attack_menu(duel, list, start = 0, du: nil)
      d = du || duel.turn_duelist
      card = d.card(d.arena)
      idx = start.clamp(0, list.size - 1)
      loop do
        Screens.duel_main_scene(@map, duel)
        Screens.attack_menu(@map, card, list)
        loop do
          y = 13 + idx * 2
          key = blink_wait(1, y, SYM_CURSOR_R, SYM_SPACE,
                           [Input::USE, Input::BACK, Input::UP, Input::DOWN, Input::ACTION])
          @map.sym(1, y, SYM_SPACE)
          case key
          when Input::USE  then @attack_item = idx; return list[idx]
          when Input::BACK then return nil
          when Input::UP, Input::DOWN
            idx = (idx + 1) % list.size if list.size > 1
            pbPlayCursorSE
          when Input::ACTION
            atk = card.attacks[list[idx][1]]
            message(atk.desc) if atk.desc && !atk.desc.empty?
            break
          end
        end
      end
    end
  end
end
