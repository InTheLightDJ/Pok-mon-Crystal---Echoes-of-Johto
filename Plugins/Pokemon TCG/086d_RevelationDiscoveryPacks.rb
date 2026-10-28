#==============================================================================
# Pokemon TCG - REVELATION and DISCOVERY booster packs (not in the original).
#   Art: Graphics/Plugins/Pokemon TCG/Boosters/revelation.png, discovery.png
#   Give them like any pack: pbTCGOpenBooster(:REVELATION) or reward: :DISCOVERY
#
#   REVELATION, 4 cards:
#     1 custom card (set NEO, 001b_NeoCards.rb) that isn't a legendary
#     1 Evolution card (Stage 1 or Stage 2) from every card
#     1 legendary from every card (custom ones included) - swapped for
#       another rare card now: legendaries come only from Card Slots and
#       trades (087b_ReservedCards.rb)
#     1 Energy: a basic Energy or a Double Colorless Energy
#   DISCOVERY, 10 different cards: Basic Pokémon from the custom cards,
#     no legendaries
#==============================================================================
module TCG
  # species counted as legendary
  LEGENDARY_NAMES = ["Articuno", "Zapdos", "Moltres", "Mewtwo", "Mew", "Shining Celebi",
                     "Entei", "Raikou", "Suicune", "Ho-Oh", "Celebi", "Shining Mew", "Shining Mewtwo"]
  DISCOVERY_SIZE  = 10

  BOOSTER_PACKS[:REVELATION] = { :set => :REVELATION, :generator => :generate_revelation_booster,
                                 :chances => [0, 0, 0, 0, 0, 0, 0, 0, 0] }
  BOOSTER_PACKS[:DISCOVERY]  = { :set => :DISCOVERY, :generator => :generate_discovery_booster,
                                 :chances => [0, 0, 0, 0, 0, 0, 0, 0, 0] }

  def self.legendary_card?(id); LEGENDARY_NAMES.include?(CARDS[id][:name]); end
  def self.custom_card?(id);    CARDS[id][:sets].first.to_s == "NEO"; end

  def self.pokemon_card?(id); CARDS[id][:type].to_s.start_with?("TYPE_PKMN"); end

  def self.generate_revelation_booster
    custom    = CARD_ORDER.select { |id| custom_card?(id) && !legendary_card?(id) }
    evolution = CARD_ORDER.select { |id| pokemon_card?(id) && %w[STAGE1 STAGE2].include?(CARDS[id][:stage].to_s) }
    legendary = CARD_ORDER.select { |id| pokemon_card?(id) && legendary_card?(id) }
    energy    = BASIC_ENERGY_IDS.first(NUM_COLORED_TYPES) + [:DOUBLE_COLORLESS_ENERGY]
    [custom.sample, evolution.sample, legendary.sample, energy.sample]
  end

  def self.generate_discovery_booster
    pool = CARD_ORDER.select do |id|
      custom_card?(id) && pokemon_card?(id) && CARDS[id][:stage].to_s == "BASIC" && !legendary_card?(id)
    end
    pool.sample(DISCOVERY_SIZE)
  end
end
