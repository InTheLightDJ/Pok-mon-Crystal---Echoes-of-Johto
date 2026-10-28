#==============================================================================
# Pokemon TCG - holo cards (not in the original). Every card except the
# Energy cards has a holo version in each HOLO_TIERS color,
# :<ID>_HOLO_<TIER> (e.g. :CHARIZARD_HOLO_RED_BLUE). Every booster pack turns
# one of its cards into a holo (089j_HoloSparkle.rb). A holo is the same card:
# same name (it counts toward the 4 cards with the same name), same stats,
# same effects. Only the look differs: its tier's sparkle over the picture
# (Graphics/Plugins/Pokemon TCG/UI/<file>.png) and a gold name.
#
#   Collection, saved decks and booster lists hold the holo id itself.
#   In a duel each Duelist keeps the normal id (card_id) for the engine and
#   the AI, which compare card ids, and remembers each card's tier
#   (Duelist#card / #display_id give the holo version for the screens).
#   Holo ids are not in CARD_ORDER (booster pools, album sets, rankings);
#   listing_order / card_order_index put them right after their card.
#==============================================================================
module TCG
  # least to most rare: [tier, name, 1 in N chance, sparkle sheet]. A pack's
  # holo is the rarest tier whose 1-in-N roll succeeds, else the first.
  HOLO_TIERS = [
    [:BLUE,         "Blue",            1,    "holo_sparkle_blue"],
    [:YELLOW,       "Yellow",          3,    "holo_sparkle_yellow"],
    [:RED,          "Red",             8,    "holo_sparkle_red"],
    [:PURPLE,       "Purple",          16,   "holo_sparkle_purple"],
    [:RED_BLUE,     "Red & Blue",      32,   "holo_sparkle_red & blue"],
    [:GREEN_PURPLE, "Green & Purple",  64,   "holo_sparkle_green & purple"],
    [:WHITE,        "White",           128,  "holo_sparkle_white"],
    [:GREY_WHITE,   "Grey & White",    256,  "holo_sparkle_grey and white"],
    [:BLACK_YELLOW, "Black & Yellow",  500,  "holo_sparkle_black & yellow"],
    [:BLACK_PURPLE, "Black & Purple",  1000, "holo_sparkle_black & purple"],
    [:BLACK_RED,    "Black & Red",     2000, "holo_sparkle_Black & red"]
  ]
  HOLO_TIER_INFO = HOLO_TIERS.to_h { |t, name, odds, sheet| [t, { :name => name, :odds => odds, :sheet => sheet }] }

  CARD_ORDER.each do |id|
    h = CARDS[id]
    next if h[:type].to_s.start_with?("TYPE_ENERGY")
    HOLO_TIERS.each do |tier, *_|
      # "<gfx>*<tier>" on the picture tells the renderer which sparkle to draw
      CARDS[:"#{id}_HOLO_#{tier}"] = h.merge(:holo => tier, :base => id, :gfx => "#{h[:gfx]}*#{tier}",
                                             :label => "#{h[:label]}Holo#{tier}")
    end
  end

  # the card's holo tier (nil for a normal card)
  def self.holo_tier(id); h = CARDS[id.to_sym]; h ? h[:holo] : nil; end
  def self.holo?(id);     !holo_tier(id).nil?; end
  def self.base_id(id);   h = CARDS[id.to_sym]; (h && h[:base]) || id.to_sym; end

  # a card's version in that tier (nil tier: the normal card); nil if none
  def self.holo_id(id, tier)
    return base_id(id) unless tier
    hid = :"#{base_id(id)}_HOLO_#{tier}"
    CARDS[hid] ? hid : nil
  end

  # every version of a card: the normal one first, then the tiers
  def self.versions(id)
    b = base_id(id)
    [b] + HOLO_TIERS.map { |t, *_| holo_id(b, t) }.compact
  end

  # the tier's name in the current language ("" for none)
  def self.holo_name(tier)
    return "" unless HOLO_TIERS.assoc(tier&.to_sym)
    _INTL(HOLO_TIERS.assoc(tier.to_sym)[1])
  end

  # CARD_ORDER with each card's holo versions right after it
  def self.listing_order
    @listing_order ||= CARD_ORDER.flat_map { |id| versions(id) }
  end

  def self.card_order_index(id)
    @card_order_index ||= listing_order.each_with_index.to_h
    @card_order_index[id.to_sym]
  end

  class Card
    def holo_tier; @raw[:holo]; end
    def holo?; !@raw[:holo].nil?; end
  end
end
