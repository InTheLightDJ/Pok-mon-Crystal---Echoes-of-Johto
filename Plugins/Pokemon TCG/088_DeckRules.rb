#==============================================================================
# Pokemon TCG - deck building rules (engine/menus/deck_configuration.asm):
#  - a deck has 55-65 cards (DECK_MIN_SIZE-DECK_MAX_SIZE; the original:
#    exactly 60, SaveDeckConfiguration);
#  - at most MAX_NUM_SAME_NAME_CARDS (4) cards sharing a NAME
#    (Shining Pokemon: 1),
#    (.CheckIfCanAddCardWithSameName), basic Energy unlimited, Double
#    Colorless Energy limited;
#  - at least one Basic Pokemon (CheckIfThereAreAnyBasicCardsInDeck; Clefairy
#    Doll / Mysterious Fossil do not count);
#  - NUM_DECKS (4) deck slots.
# Cards in saved decks are part of the collection, so a deck may use
# owned copies minus those already used by the OTHER saved decks.
#==============================================================================
module TCG
  NUM_DECKS               = 4

  def self.card_name(id); CARDS[id][:name]; end

  def self.basic_energy_card?(id); BASIC_ENERGY_IDS.include?(id); end

  def self.basic_pokemon_card?(id)
    h = CARDS[id]
    TYPE_NAMES[h[:type]] < TYPE_ENERGY && h[:stage] == "BASIC"
  end

  # copies of id the deck at index `deck_index` (nil = a new deck) may use
  def self.available_for_deck(id, deck_index = nil)
    used = 0
    saved_decks.each_with_index do |deck, i|
      next if i == deck_index
      used += deck[:cards].count(id)
    end
    card_count(id) - used
  end

  # can one more `id` be added to `cards` (array of ids)? -> nil or reason
  def self.cant_add_reason(cards, id, deck_index = nil)
    return :deck_full if cards.size >= DECK_MAX_SIZE
    return :no_more_copies if cards.count(id) >= available_for_deck(id, deck_index)
    unless basic_energy_card?(id)
      name = card_name(id)
      return :same_name_limit if cards.count { |c| card_name(c) == name } >= MAX_NUM_SAME_NAME_CARDS
      # Shining Pokemon (custom cards): 1 per deck
      return :shining_limit if name.start_with?("Shining ") && cards.any? { |c| card_name(c) == name }
    end
    nil
  end

  # SaveDeckConfiguration checks -> nil or reason
  def self.invalid_deck_reason(cards)
    return :wrong_size unless deck_size_ok?(cards)
    return :no_basic_pokemon unless cards.any? { |c| basic_pokemon_card?(c) }
    nil
  end

  def self.deck_size_ok?(cards); cards && cards.size.between?(DECK_MIN_SIZE, DECK_MAX_SIZE); end

  DECK_RULE_TEXT = {
    :deck_full        => "The deck already has 65 cards.",
    :no_more_copies   => "You have no more copies of that card.",
    :same_name_limit  => "You can only include 4 cards with the same name.",
    :shining_limit    => "You can only include 1 of each Shining Pokémon.",
    :wrong_size       => "The deck must include 55 to 65 cards.",
    :no_basic_pokemon => "You must include a Basic Pokémon in the deck."
  }
  def self.deck_rule_text(reason); _INTL(DECK_RULE_TEXT[reason]); end

  # deck ordering used for display (card id order, like the original lists)
  def self.sort_cards(cards); cards.sort_by { |c| card_order_index(c) || 99_999 }; end

  def self.save_deck(cards, name, index = nil)
    raise ArgumentError, deck_rule_text(invalid_deck_reason(cards)) if invalid_deck_reason(cards)
    entry = { :name => name, :cards => sort_cards(cards) }
    if index then saved_decks[index] = entry
    else
      raise ArgumentError, "All #{NUM_DECKS} deck slots are in use" if saved_decks.size >= NUM_DECKS
      saved_decks << entry
      index = saved_decks.size - 1
    end
    global.tcg_active_deck ||= index if global
    index
  end

  def self.set_active_deck(index)
    global.tcg_active_deck = index if global && saved_decks[index]
  end

  # DismantleDeck: the original refuses to dismantle the only deck
  def self.dismantle_deck(index)
    return false if saved_decks.size <= 1
    saved_decks.delete_at(index)
    if global
      a = global.tcg_active_deck
      global.tcg_active_deck = (a.nil? || a == index) ? 0 : (a > index ? a - 1 : a)
    end
    true
  end
end
