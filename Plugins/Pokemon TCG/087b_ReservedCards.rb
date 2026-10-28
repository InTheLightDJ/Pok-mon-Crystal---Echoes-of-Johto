#==============================================================================
# Pokemon TCG - reserved cards: legendaries and special cards (Dark, Light,
# Shining, Crystal Type cards, Shadow Lugia) come only from the Card Slots
# machine (Plugins/Card Slots) and from trades, not from booster packs or the
# Card Shop.
#   Booster packs: a reserved card a pack would give is swapped for another
#   card of the same rarity (same set when there is one). A Destiny pack's
#   chosen card (DESTINY(:MEW)) is given on purpose and stays.
#   Card Shop: the server leaves them out (tcg_trader_cards.json "reserved",
#   made by PokeTCG-mod/tools/trader/make_trader_cards.rb).
#==============================================================================
module TCG
  RESERVED_LEGENDARY = ["Articuno", "Zapdos", "Moltres", "Mewtwo", "Mew", "Raikou", "Entei", "Suicune",
                        "Lugia", "Ho-Oh", "Ho-oh", "Celebi"]
  RESERVED_SPECIAL_NAMES = ["Shadow Lugia"]

  def self.reserved_base_name(name); name.to_s.sub(/\A(Dark|Light|Shining) /, ""); end

  def self.legendary_card_name?(name)
    RESERVED_LEGENDARY.include?(reserved_base_name(name)) && !RESERVED_SPECIAL_NAMES.include?(name)
  end

  # Dark / Light / Shining / Crystal Type / Shadow Lugia (holos too)
  def self.special_card?(id)
    h = CARDS[base_id(id)] or return false
    return false unless h[:type].to_s.start_with?("TYPE_PKMN")
    return true if h[:name].to_s =~ /\A(Dark|Light|Shining) / || RESERVED_SPECIAL_NAMES.include?(h[:name])
    powers = [h[:power]] + Array(h[:attacks])
    powers.compact.any? { |a| a[:name] == "Crystal Type" }
  end

  def self.legendary_card_id?(id)
    h = CARDS[base_id(id)] or return false
    h[:type].to_s.start_with?("TYPE_PKMN") && legendary_card_name?(h[:name])
  end

  def self.reserved_card?(id); special_card?(id) || legendary_card_id?(id); end

  def self.reserved_cards
    @reserved_cards ||= CARD_ORDER.select { |id| reserved_card?(id) }
  end

  # a card for a pack instead of reserved card `id`: same rarity, same set if
  # possible, not already in the pack
  def self.booster_replacement(id, pack_cards)
    h = CARDS[base_id(id)]
    same = CARD_ORDER.select do |k|
      c = CARDS[k]
      c[:type].to_s.start_with?("TYPE_PKMN") && c[:rarity] == h[:rarity] && !reserved_card?(k) && !pack_cards.include?(k)
    end
    in_set = same.select { |k| CARDS[k][:sets].first.to_s == h[:sets].first.to_s }
    (in_set.empty? ? same : in_set).sample || id
  end

  class << self
    alias reserved_generate_booster generate_booster
    def generate_booster(pack)
      cards = reserved_generate_booster(pack).dup
      keep = pack.is_a?(DestinyPack) ? pack.card : nil
      cards.each_with_index.map do |id, i|
        next id if id == keep || !reserved_card?(id)
        cards[i] = booster_replacement(id, cards)
      end
    end
  end
end
