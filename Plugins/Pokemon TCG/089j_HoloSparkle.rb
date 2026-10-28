#==============================================================================
# Pokemon TCG - holo cards' looks and pulls (not in the original; the cards
# themselves: 011b_HoloCards.rb)
#   - their tier's animated sparkle over the card picture on the GB screens
#     (card pages, play areas, the duel screen, card lists)
#   - a gold name wherever a card is listed (Screens.card_text)
#   - every booster pack turns one random non-Energy card into a holo of a
#     tier rolled with HOLO_TIERS' odds
#
#   HOLO_FRAME_TICKS  screen frames per animation frame (6 = 100 ms)
#   Sparkle sheets: frames of 64x48 side by side (any number), made from a
#   sparkle GIF by PokeTCG-mod/tools/make_holo_sparkle.py
#==============================================================================
module TCG
  HOLO_FRAME_TICKS = 6
  PAL_HOLO_NAME    = 5   # GB::PALETTES entry for gold names

  # gold: card names print in the palette's darkest shade
  GB::PALETTES << [[28, 28, 24], [30, 26, 8], [28, 21, 2], [25, 17, 0]] if GB::PALETTES.size == PAL_HOLO_NAME

  # "<gfx>*<tier>" -> the tier's sparkle sheet name, or nil
  def self.holo_sheet(gfx)
    tier = gfx.to_s.split("*", 2)[1]
    return nil if tier.nil? || tier.empty?
    (HOLO_TIER_INFO[tier.to_sym] || {})[:sheet]
  end

  def self.holo_tick; Graphics.frame_count / HOLO_FRAME_TICKS; end

  # the rarest tier whose 1-in-N roll succeeds (the first tier always does)
  def self.roll_holo_tier
    HOLO_TIERS.reverse_each { |tier, _, odds, _| return tier if odds <= 1 || rand(odds) == 0 }
    HOLO_TIERS.first[0]
  end

  # every pack: one random non-Energy card becomes a holo
  class << self
    alias holo_generate_booster generate_booster
    def generate_booster(pack)
      cards = holo_generate_booster(pack)
      slots = cards.each_index.select { |i| holo_id(cards[i], HOLO_TIERS.first[0]) }
      return cards if slots.empty?
      i = slots.sample
      cards = cards.dup
      cards[i] = holo_id(cards[i], roll_holo_tier)
      cards
    end
  end

  module Screens
    module_function

    # a card's name (default: name and level) at x, y, in gold for a holo;
    # returns the next free x like TileMap#text
    def card_text(map, x, y, card, text = nil)
      nx = map.text(x, y, text || name_and_level(card))
      map.palette(x, y, nx - x, 1, PAL_HOLO_NAME) if card.holo?
      nx
    end
  end

  module GB
    class Renderer
      # false for still pictures (the deck view's card images)
      attr_writer :holo

      alias holo_pic pic
      def pic(gfx)
        holo_pic(gfx.to_s.split("*", 2)[0])
      end

      alias holo_draw draw
      def draw(map)
        holo_draw(map)
        return if map.flash || @holo == false
        map.pictures.each do |x, y, gfx|
          name = TCG.holo_sheet(gfx) or next
          sheet = (RPG::Cache.load_bitmap(GFX + "UI/", name) rescue nil) or next
          frames = sheet.width / 64
          next if frames < 1
          src = Rect.new((TCG.holo_tick % frames) * 64, 0, 64, 48)
          @bitmap.blt(x * 8 - map.scroll_x.to_i, y * 8 - map.scroll_y.to_i, sheet, src)
        end
      end
    end
  end

  class DuelScene
    # redraw when the sparkle moves on to its next frame
    alias holo_frame frame
    def frame
      holo_frame
      return if @map.flash || @map.pictures.none? { |_, _, gfx| TCG.holo_sheet(gfx) }
      tick = TCG.holo_tick
      return if tick == @holo_tick
      @holo_tick = tick
      render
    end
  end
end
