#==============================================================================
# Pokemon TCG - GENESIS booster pack (not in the original game).
#   Art: Graphics/Plugins/Pokemon TCG/Boosters/genesis.png
#   10 cards: 1 promo card from GENESIS_PROMOS, a Ditto, 1 random common
#   (non-Energy) card, then 7 random basic Energy cards.
#   Give it like any pack: pbTCGOpenBooster(:GENESIS) or reward: :GENESIS
#==============================================================================
module TCG
  # the promotional cards no other pack has (Imakuni? left out)
  GENESIS_PROMOS = [
    :VENUSAUR_LV64, :MOLTRES_LV37, :ARTICUNO_LV37, :ZAPDOS_LV68, :DRAGONITE_LV41, :MEW_LV15,
    :ARCANINE_LV34, :PIKACHU_LV16, :PIKACHU_ALT_LV16, :FLYING_PIKACHU, :SURFING_PIKACHU_LV13,
    :SURFING_PIKACHU_ALT_LV13, :ELECTABUZZ_LV20, :SLOWPOKE_LV9, :MEWTWO_LV60, :MEWTWO_ALT_LV60,
    :MEW_LV8, :JIGGLYPUFF_LV12, :SUPER_ENERGY_RETRIEVAL
  ]

  BOOSTER_PACKS[:GENESIS] = { :set => :GENESIS, :energy => :GenerateGenesisBooster,
                              :chances => [0, 0, 0, 0, 0, 0, 0, 0, 0] }

  def self.generate_genesis_booster
    commons = CARD_ORDER.select do |id|
      BOOSTER_RARITY[CARDS[id][:rarity]] == 0 && booster_type_of(id) != 8 &&
        !GENESIS_PROMOS.include?(id) && id != :DITTO
    end
    cards = [GENESIS_PROMOS.sample, :DITTO, commons.sample]
    cards + Array.new(NUM_CARDS_IN_BOOSTER - cards.size) { BASIC_ENERGY_IDS[rand(NUM_COLORED_TYPES)] }
  end
end
