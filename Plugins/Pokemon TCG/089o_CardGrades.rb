#==============================================================================
# Pokemon TCG - card grades (PSA) for holo cards (not in the original)
#
# Every holo copy has a hidden grade, 1 (poor) to 10 (gem mint). A new holo
# (booster pack, shop, trader, prize...) comes out of the pack at 7-10, very
# rarely 6 (PACK_ODDS); holos owned from before this get one rolled the
# same way but never a 10 (old_roll). A copy wears down with every duel it's in the deck for:
# DROP_AFTER[grade] duels at a grade take it down one; a grade 1 copy falls
# apart after 1000 more (a 10 lasts about 1970 duels). A spare normal copy
# takes a broken card's place in its decks; with none, a deck going under
# 55 cards gets a spare basic Energy, and with none of those either the
# deck editor opens after the duel until it's filled (fill_short_deck).
#
# The Card Appraiser (pbTCGAppraiser) shows a copy's grade for
# APPRAISE_COST Server Tokens; from then on it's on the card's page and
# goes with the card when it's sold on the Player Market. Appraised copies
# sell for PRICE[grade] x the normal price in the Card Shop. Refurbishing
# (REFURBISH_COST tokens, REFURBISH_COST_TO_10 from 9 to 10) takes an
# appraised copy up one grade. Grade 1
# copies get a red outline wherever their picture shows (outside duels).
#
# Saved per copy in $PokemonGlobal.tcg_grades: holo id => one record per
# copy, [grade, duels played at that grade, appraised]. The first copies are
# the ones in decks (as many as the saved decks use); the rest are spare.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_grades
  def tcg_grades; @tcg_grades ||= {}; end
end

module TCG
  module Grades
    PACK_ODDS      = { 10 => 8, 9 => 22, 8 => 35, 7 => 33, 6 => 2 }   # percent
    SHOP_GRADES    = (4..10)   # the Card Shop's ungraded holos (hidden, any of these)
    DROP_AFTER     = { 10 => 2, 9 => 5, 8 => 10, 7 => 15, 6 => 30, 5 => 60, 4 => 100, 3 => 250,
                       2 => 500, 1 => 1000 }   # duels at that grade (1: it breaks)
    PRICE          = { 10 => 10.0, 9 => 5.0, 8 => 3.0, 7 => 2.0, 6 => 1.5, 5 => 1.0, 4 => 0.6,
                       3 => 0.3, 2 => 0.15, 1 => 0.05 }
    NAMES          = { 10 => "GEM MINT", 9 => "MINT", 8 => "NM-MT", 7 => "NEAR MINT", 6 => "EX-MT",
                       5 => "EXCELLENT", 4 => "VG-EX", 3 => "VERY GOOD", 2 => "GOOD", 1 => "POOR" }
    APPRAISE_COST  = 1
    REFURBISH_COST = 5
    REFURBISH_COST_TO_10 = 10   # PSA 9 -> 10
    GRADE, DUELS, APPRAISED = 0, 1, 2

    @pending = []   # messages for the overworld (cards worn out / broken in a duel)
    @short   = []   # saved decks left under 55 cards, to fill in the deck editor

    module_function

    def pending; @pending; end
    def short;   @short;   end
    def store; TCG.global ? TCG.global.tcg_grades : (@test_store ||= {}); end

    def roll
      r = rand(100)
      PACK_ODDS.each { |g, pct| return g if (r -= pct) < 0 }
      7
    end

    def fresh; [new_grade(roll), 0, false]; end

    # a new copy's hidden grade: 1 higher (max 10) while the PSA+1 ability
    # is in the slot (089r)
    def new_grade(g)
      TCG.duel_ability == :PSA_PLUS ? [g + 1, 10].min : g
    end

    # a copy owned from before grades existed: like a pack's, but never a 10
    def old_roll
      r = rand(100 - PACK_ODDS[10])
      PACK_ODDS.each { |g, pct| next if g == 10; return g if (r -= pct) < 0 }
      7
    end

    # the copies' records, one per copy in the collection. New copies get
    # theirs when they're added (TCG.add_card), so a missing one is a copy
    # from before grades: old_roll
    def copies(id)
      id = id.to_sym
      return [] unless TCG.holo?(id)
      n = TCG.card_count(id)
      list = (store[id] ||= [])
      list << [old_roll, 0, false] while list.size < n
      list.pop while list.size > n
      store.delete(id) if list.empty?
      list
    end

    def record(id, copy); copy ? copies(id)[copy] : nil; end
    def name(grade);      _INTL(NAMES[grade.to_i] || "");  end

    # Server Tokens to take a copy from `grade` up one
    def refurbish_cost(grade); grade.to_i >= 9 ? REFURBISH_COST_TO_10 : REFURBISH_COST; end

    # copies in saved decks come first
    def in_decks(id);      TCG.card_count(id) - TCG.available_for_deck(id); end
    def spare_copies(id);  (in_decks(id)...copies(id).size).to_a;            end
    def in_deck?(id, copy); copy < in_decks(id);                            end

    # the spare copy that goes when a card is taken without one being picked
    # (Card Trader): the most worn
    def default_spare(id)
      list = copies(id)
      spare_copies(id).min_by { |i| [list[i][GRADE], -list[i][DUELS]] } || (list.size - 1)
    end

    # sell lists: [id, copy] for each spare copy of a holo, [id, nil] for
    # other cards
    def spare_entries(ids)
      ids.flat_map { |id| TCG.holo?(id) ? spare_copies(id).map { |c| [id, c] } : [[id, nil]] }
    end

    # every holo copy you have (the Appraiser's list)
    def all_entries
      TCG.listing_order.select { |id| TCG.holo?(id) && TCG.card_count(id) > 0 }
         .flat_map { |id| copies(id).each_index.map { |c| [id, c] } }
    end

    # "PSA 9" for an appraised copy, else nil
    def label(id, copy)
      r = record(id, copy)
      r && r[APPRAISED] ? _INTL("PSA {1}", r[GRADE]) : nil
    end

    def price_factor(id, copy)
      r = record(id, copy)
      r && r[APPRAISED] ? PRICE[r[GRADE]] : 1.0
    end

    def worn_out?(id); copies(id).any? { |r| r[GRADE] <= 1 }; end

    # picture name ("<gfx>*<tier>") -> holo ids drawn with it
    def ids_for_gfx(gfx)
      @by_gfx ||= CARDS.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(id, h), m|
        m[h[:gfx].to_s] << id if h[:holo]
      end
      @by_gfx.fetch(gfx.to_s, [])
    end

    def worn_out_gfx?(gfx)
      return false if gfx.nil? || TCG.dueling?
      ids_for_gfx(gfx).any? { |id| TCG.card_count(id) > 0 && worn_out?(id) }
    end

    # takes one particular copy out of the collection
    def remove_copy(id, copy)
      list = copies(id)
      list.delete_at(copy) if copy && copy < list.size
      TCG.grades_remove_card(id, 1)
    end

    # a card that sold on the market or came back from it: its record
    # (from the server) goes on the copy just added
    def import_record(id, rec)
      return unless rec.is_a?(Array) && TCG.holo?(id)
      g = rec[GRADE].to_i
      return unless g.between?(1, 10)
      list = copies(id)
      list[-1] = [g, rec[DUELS].to_i.clamp(0, DROP_AFTER[g]), rec[APPRAISED] == true] unless list.empty?
    end

    #--------------------------------------------------------------------------
    # wear: after a duel played with the active deck
    #--------------------------------------------------------------------------
    def wear(deck)
      active = TCG.active_deck_cards
      return unless active && active.map(&:to_sym).sort == deck.sort
      deck.tally.each do |id, k|
        next unless TCG.holo?(id)
        list = copies(id)
        broken = []
        [k, list.size].min.times do |i|
          r = list[i]
          r[DUELS] += 1
          next if r[DUELS] < DROP_AFTER[r[GRADE]]
          if r[GRADE] <= 1
            broken << i
          else
            r[GRADE] -= 1
            r[DUELS] = 0
            if r[GRADE] == 1
              @pending << _INTL("Your {1} is badly worn! Get it refurbished at the Card Appraiser before it falls apart.",
                                full_name(id))
            end
          end
        end
        broken.reverse_each { |i| break_copy(id, i) }
      end
    end

    def full_name(id)
      _INTL("{1} ({2} Holo)", TCG.card(id).name, TCG.holo_name(TCG.holo_tier(id)))
    end

    # a grade 1 copy falls apart: out of the collection, and out of the
    # decks (a normal copy of the card takes its place if there's one spare)
    def break_copy(id, copy)
      remove_copy(id, copy)
      msg = _INTL("Your {1} fell apart after too many duels...", full_name(id))
      base = TCG.base_id(id)
      decks = TCG.saved_decks
      order = [TCG.global&.tcg_active_deck].compact + (0...decks.size).to_a
      while TCG.available_for_deck(id) < 0
        deck = order.map { |i| decks[i] }.find { |d| d && d[:cards].map(&:to_sym).include?(id) } or break
        at = deck[:cards].index { |c| c.to_sym == id }
        if TCG.available_for_deck(base) > 0
          deck[:cards][at] = base
          msg += "\n" + _INTL("A normal {1} took its place in {2}.", TCG.card(base).name, deck[:name])
        else
          deck[:cards].delete_at(at)
          if deck[:cards].size >= DECK_MIN_SIZE
            msg += "\n" + _INTL("{1} is a card short now.", deck[:name])
          elsif (energy = spare_energy(deck))
            deck[:cards] << energy
            msg += "\n" + _INTL("A {1} took its place in {2}.", TCG.card(energy).name, deck[:name])
          else
            @short << deck unless @short.any? { |d| d.equal?(deck) }
          end
        end
      end
      @pending << msg
    end

    # a basic Energy the player has spare for a deck: the kind it uses most
    def spare_energy(deck)
      used = deck[:cards].map(&:to_sym).tally
      BASIC_ENERGY_IDS.sort_by { |e| -used[e].to_i }
                      .find { |e| TCG.available_for_deck(e) > 0 }
    end

    # a deck left too short: the deck editor until it has 55 cards again
    # (or it's dismantled). Not if there aren't enough cards to fill it.
    def fill_short_deck
      deck = @short.shift
      index = TCG.saved_decks.index { |d| d.equal?(deck) }
      return if index.nil? || TCG.deck_size_ok?(deck[:cards])
      need = DECK_MIN_SIZE - deck[:cards].size
      spare = TCG.collection.keys.sum { |id| [TCG.available_for_deck(id), 0].max }
      if spare < need
        pbMessage(_INTL("{1} is too short to duel with now. Get more cards to put in it!", deck[:name]))
        return
      end
      pbMessage(_INTL("{1} is too short to duel with now. Put more cards in it!", deck[:name]))
      pbTCGEditDeck(index, forced: true)
    end

    def local_controller?(ctrl)
      ctrl.is_a?(PlayerController)   # NetLocalController too
    end

    #--------------------------------------------------------------------------
    # Server Tokens (the server's spend_tokens): nil when spent, else why not
    #--------------------------------------------------------------------------
    def spend_tokens(amount, reason)
      return _INTL("You need to be online for that.") unless NetPvP.online?
      have = CardShop.tokens
      return _INTL("You need {1} Server Tokens. You have {2}.", amount, have) if have < amount
      result = nil
      ok_cb  = NetworkClient.on("spend_tokens_ok")    { |d| result = d }
      err_cb = NetworkClient.on("spend_tokens_error") { |d| result = { "_err" => d["message"].to_s } }
      NetworkClient.send_msg({ action: "spend_tokens", amount: amount, reason: reason })
      300.times do
        break if result
        Graphics.update
        Input.update
        NetworkClient.update
      end
      return _INTL("No response from server.") unless result
      return result["_err"] if result["_err"]
      NetworkTokens.set(result["new_tokens"]) if defined?(NetworkTokens)
      nil
    ensure
      NetworkClient.remove("spend_tokens_ok", ok_cb) if ok_cb
      NetworkClient.remove("spend_tokens_error", err_cb) if err_cb
    end
  end

  #----------------------------------------------------------------------------
  # copies in and out of the collection
  #----------------------------------------------------------------------------
  class << self
    alias grades_add_card add_card unless method_defined?(:grades_add_card)
    alias grades_remove_card remove_card unless method_defined?(:grades_remove_card)

    # new holo copies get a pack grade now (the copies already there first
    # get theirs, so they aren't mistaken for new ones)
    def add_card(id, n = 1)
      return grades_add_card(id, n) unless holo?(id)
      list = Grades.copies(id)
      had = card_count(id)
      result = grades_add_card(id, n)
      (card_count(id) - had).times { list << Grades.fresh }
      Grades.store[id.to_sym] = list unless list.empty?
      result
    end

    # a copy without one being picked: the most worn spare one
    def remove_card(id, n = 1)
      if holo?(id)
        n.times do
          break if card_count(id) <= 0
          Grades.remove_copy(id, Grades.default_spare(id))
        end
        return collection[id.to_sym]
      end
      grades_remove_card(id, n)
    end
  end

  #----------------------------------------------------------------------------
  # wear: duels played by this game's player
  #----------------------------------------------------------------------------
  class Duel
    alias grades_initialize initialize unless method_defined?(:grades_initialize)
    def initialize(player_name, player_deck, player_ctrl, *rest, **kw)
      grades_initialize(player_name, player_deck, player_ctrl, *rest, **kw)
      @grades_deck = player_deck.map(&:to_sym) if Grades.local_controller?(player_ctrl)
    end

    alias grades_start start unless method_defined?(:grades_start)
    def start
      result = grades_start
      Grades.wear(@grades_deck) if @grades_deck && !result.nil?
      result
    end
  end

  #----------------------------------------------------------------------------
  # the card's page (outside duels): its appraised copies' grades
  #----------------------------------------------------------------------------
  module Screens
    class << self
      alias grades_card_page card_page unless method_defined?(:grades_card_page)
      def card_page(map, duel, card, page, du = nil, slot = nil)
        grades_card_page(map, duel, card, page, du, slot)
        return if du || TCG.dueling? || !card.holo?
        grades = Grades.copies(card.id).select { |r| r[Grades::APPRAISED] }.map { |r| r[Grades::GRADE] }
        return if grades.empty?
        map.text(1, 5, "PSA")
        grades.sort.reverse.first(3).each_with_index { |g, i| map.text(2, 6 + i, g.to_s) }
      end
    end
  end

  #----------------------------------------------------------------------------
  # red outline on grade 1 cards
  #----------------------------------------------------------------------------
  module GB
    class Renderer
      alias grades_draw draw unless method_defined?(:grades_draw)
      def draw(map)
        grades_draw(map)
        return if map.flash
        red = Color.new(232, 24, 24)
        map.pictures.each do |x, y, gfx|
          next unless Grades.worn_out_gfx?(gfx)
          px = x * 8 - map.scroll_x.to_i
          py = y * 8 - map.scroll_y.to_i
          @bitmap.fill_rect(px, py, 64, 1, red)
          @bitmap.fill_rect(px, py + 47, 64, 1, red)
          @bitmap.fill_rect(px, py, 1, 48, red)
          @bitmap.fill_rect(px + 63, py, 1, 48, red)
        end
      end
    end
  end

  class DuelScene
    alias grades_small_card_blt small_card_blt unless method_defined?(:grades_small_card_blt)
    def small_card_blt(bmp, dst, gfx, any_tier, tick)
      grades_small_card_blt(bmp, dst, gfx, any_tier, tick)
      shop_frame(bmp, dst, 0, Color.new(232, 24, 24)) if Grades.worn_out_gfx?(gfx)
    end
  end
end

# worn-out / broken card messages, once the player is free in the overworld
if defined?(EventHandlers)   # (not in the headless test harness)
  EventHandlers.add(:on_frame_update, :tcg_grade_messages, proc {
    next if TCG::Grades.pending.empty? && TCG::Grades.short.empty?
    next unless $scene.is_a?(Scene_Map)
    next if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
    next if $game_player.move_route_forcing || pbMapInterpreterRunning?
    if TCG::Grades.pending.empty?
      TCG::Grades.fill_short_deck   # after the "fell apart" messages
    else
      pbMessage(TCG::Grades.pending.shift)
    end
  })
end
