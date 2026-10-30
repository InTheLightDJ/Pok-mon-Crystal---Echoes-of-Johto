#==============================================================================
# Pokemon TCG - Special Packs (not in the original)
#
# Any booster pack (shop, prizes, Jackpot Machines, Destiny packs...) can
# come out as a Special Pack, as rarely as a wild Pokémon is shiny
# (Settings::SHINY_POKEMON_CHANCE in 65536, 1 in 4096). In a Special Pack:
#   - one Energy card becomes a random legendary (087b legendary_card_id?);
#     with no Energy in the pack, a Basic Pokémon does
#   - every card is a holo, each tier rolled like a pack's holo (Energy cards
#     have no holo, so any other Energy cards stay as they are)
# Opening it says so before the cards are shown.
#==============================================================================
module TCG
  module SpecialPacks
    @special = {}   # cards array object_id => true (to tell the opening screen)

    module_function

    def chance
      (defined?(Settings::SHINY_POKEMON_CHANCE) ? Settings::SHINY_POKEMON_CHANCE : 16) / 65536.0
    end
    def roll?;  rand < chance; end

    def legendaries
      @legendaries ||= CARD_ORDER.select { |id| TCG.legendary_card_id?(id) }
    end

    def energy?(id); CARDS[base(id)][:type].to_s.start_with?("TYPE_ENERGY"); end
    def basic?(id)
      h = CARDS[base(id)]
      h[:type].to_s.start_with?("TYPE_PKMN") && h[:stage] == "BASIC"
    end
    def base(id); TCG.base_id(id); end

    # the pack's cards made special
    def make(cards)
      cards = cards.dup
      at = cards.index { |id| energy?(id) } || cards.index { |id| basic?(id) } || cards.size - 1
      cards[at] = legendaries.sample if at && !legendaries.empty?
      cards.map! { |id| energy?(id) ? id : (TCG.holo_id(base(id), TCG.roll_holo_tier) || id) }
      @special[cards.object_id] = true
      cards
    end

    def special?(cards); @special.key?(cards.object_id); end
    def forget(cards);   @special.delete(cards.object_id); end
  end

  class << self
    alias special_generate_booster generate_booster unless method_defined?(:special_generate_booster)
    def generate_booster(pack)
      cards = special_generate_booster(pack)
      SpecialPacks.roll? ? SpecialPacks.make(cards) : cards
    end
  end

  class DuelScene
    alias special_booster_pack_screen booster_pack_screen unless method_defined?(:special_booster_pack_screen)
    def booster_pack_screen(pack, cards, another)
      if SpecialPacks.special?(cards)
        SpecialPacks.forget(cards)
        @special_pack = true
      end
      special_booster_pack_screen(pack, cards, another)
    ensure
      @special_pack = false
    end

    # the "checked the cards" line: a Special Pack says so first
    alias special_message message unless method_defined?(:special_message)
    def message(text, keep: false)
      if @special_pack && text.to_s.include?("checked the cards")
        @special_pack = false
        pbMEPlay("Slots big win") rescue nil
        special_message(_INTL("WOW! It's a SPECIAL PACK!!\nEvery card is a holo!"), keep: keep)
      end
      special_message(text, keep: keep)
    end
  end
end
