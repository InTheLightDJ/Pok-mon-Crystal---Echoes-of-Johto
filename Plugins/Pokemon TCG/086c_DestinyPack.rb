#==============================================================================
# Pokemon TCG - DESTINY booster pack (not in the original game).
#   Art: Graphics/Plugins/Pokemon TCG/Boosters/destiny.png
#
#   DESTINY(:ABRA)         a Destiny pack whose rare slot is Abra 1 time in 50
#   DESTINY(:ABRA, 100)    ... 1 time in 100 (nil = 50, 1 = always)
#   DESTINY[:ABRA, 100]    same thing with brackets
#   The card can be a card ID (:MEWTWO_LV53) or a card name ("Mewtwo", "abra");
#   a name with several versions picks one of them at random.
#
#   Use it like any pack:
#     pbTCGDuel("Grinder", :FIRE_CHARGE_DECK, reward: DESTINY(:ABRA, 100))
#     pbTCGOpenBooster(DESTINY(:ABRA))
#     DESTINY(:ABRA).open
#
#   10 cards: 4 commons + 2 uncommons from destiny_pokemon (no Stage 2, no
#   legendaries, no custom or Gen 3 cards), the rare slot (the chosen card at 1/rate, otherwise a rare
#   from destiny_pokemon), and
#   3 Energy cards (basic, each 1 in DESTINY_DCE_RATE a Double Colorless).
#   The chosen card is kept out of the other slots, so its odds are exact.
#==============================================================================
module TCG
  DESTINY_DEFAULT_RATE = 50
  DESTINY_DCE_RATE     = 10
  DESTINY_SLOTS        = [[0, 4], [1, 2]]   # [rarity, count]: commons, uncommons
  DESTINY_ENERGIES     = 3

  # never in the random slots (only as the chosen card)
  DESTINY_LEGENDARY_NAMES = ["Articuno", "Zapdos", "Moltres", "Mewtwo", "Mew"]

  # sets never in the random slots: promos and the custom cards
  # (001b_NeoCards.rb), which are given out on purpose, and the Gen 3 cards
  # (001c_AdvCards.rb), which only Card Slots gives
  DESTINY_EXCLUDED_SETS = ["PROMOTIONAL", "NEO", "ADV"]

  # Pokémon the pack can drop: every original non-promo Pokémon except
  # Stage 2 Pokémon and legendaries. Replace with your own list if you like.
  def self.destiny_pokemon
    @destiny_pokemon ||= CARD_ORDER.select do |id|
      h = CARDS[id]
      h[:type].to_s.start_with?("TYPE_PKMN") && BOOSTER_RARITY[h[:rarity]] &&
        !DESTINY_EXCLUDED_SETS.include?(h[:sets].first.to_s) && h[:stage] != "STAGE2" &&
        !DESTINY_LEGENDARY_NAMES.include?(h[:name])
    end
  end

  # card ID or card name -> card ID (several versions: one at random)
  def self.resolve_card(name)
    key = name.to_s.strip
    id = key.upcase.tr(" ", "_").to_sym
    return id if CARDS[id]
    want = key.downcase.tr("_", " ")
    found = CARD_ORDER.select { |i| CARDS[i][:name].downcase == want }
    # the card art's name also works ("chikorita1")
    found = CARD_ORDER.select { |i| CARDS[i][:gfx].to_s.downcase == key.downcase } if found.empty?
    raise ArgumentError, "Unknown TCG card #{name.inspect}" if found.empty?
    found.sample
  end

  class DestinyPack
    attr_reader :card, :rate

    def initialize(card, rate = nil)
      @card = TCG.resolve_card(card)
      @rate = (rate || DESTINY_DEFAULT_RATE).to_i.clamp(1, 1_000_000)
    end

    def generate
      pool = TCG.destiny_pokemon - [@card]
      by_rarity = ->(r) { pool.select { |id| BOOSTER_RARITY[CARDS[id][:rarity]] == r } }
      cards = []
      DESTINY_SLOTS.each do |rarity, n|
        cands = by_rarity.call(rarity) - cards
        n.times { cards << (c = cands.sample); cands.delete(c) }
      end
      rare = rand(@rate) == 0 ? @card : (by_rarity.call(2) - cards).sample
      cards << rare
      DESTINY_ENERGIES.times do
        cards << (rand(DESTINY_DCE_RATE) == 0 ? :DOUBLE_COLORLESS_ENERGY : BASIC_ENERGY_IDS[rand(BASIC_ENERGY_IDS.size)])
      end
      cards.compact
    end

    def open(another = false); pbTCGOpenBooster(self, another); end

    def inspect; "DESTINY(#{@card.inspect}, #{@rate})"; end
  end

  # DESTINY[:ABRA, 100]
  class DestinyMaker
    def [](card, rate = nil); DestinyPack.new(card, rate); end
  end
end

def DESTINY(card, rate = nil)
  TCG::DestinyPack.new(card, rate)
end

DESTINY = TCG::DestinyMaker.new unless defined?(DESTINY)
