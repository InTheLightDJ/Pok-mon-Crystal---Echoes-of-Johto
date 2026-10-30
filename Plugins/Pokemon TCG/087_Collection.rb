#==============================================================================
# Pokemon TCG - card collection, saved decks and booster packs.
#
# Saved with the game in $PokemonGlobal (no core scripts touched: the
# accessors are added to PokemonGlobalMetadata from this plugin).
#
# Booster generation is a port of engine/booster_packs.asm
# (GenerateBoosterPack): energies first, then rare -> uncommon -> common
# picks by weighted card type, each drawn type's chance dropping by the
# pack's average chance (minimum 1); a pack with no valid card is redrawn.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_collection, :tcg_decks, :tcg_active_deck
  def tcg_collection;  @tcg_collection ||= {}; end   # card id => count
  def tcg_decks;       @tcg_decks ||= [];      end   # [{:name, :cards => [60 ids]}]
  def tcg_active_deck; @tcg_active_deck;       end   # index into tcg_decks
end

module TCG
  MAX_CARD_COPIES_IN_COLLECTION = 99
  NUM_CARDS_IN_BOOSTER          = 10
  BASIC_ENERGY_IDS = [:GRASS_ENERGY, :FIRE_ENERGY, :WATER_ENERGY, :LIGHTNING_ENERGY,
                      :FIGHTING_ENERGY, :PSYCHIC_ENERGY, :DARKNESS_ENERGY, :METAL_ENERGY]
  # the original game's 6 (its own booster packs only give these)
  CLASSIC_ENERGY_IDS = BASIC_ENERGY_IDS.first(NUM_COLORED_TYPES)

  # booster card types: Grass Fire Water Lightning Fighting Psychic Colorless Trainer Energy
  # CardTypeTable (FIRE=0 -> 1 ...); Darkness / Metal count as Psychic / Fighting
  BOOSTER_TYPE_OF_PKMN_TYPE = [1, 0, 3, 2, 4, 5, 6, 5, 4]
  BOOSTER_RARITY = { "CIRCLE" => 0, "DIAMOND" => 1, "STAR" => 2 }

  def self.global; $PokemonGlobal; end

  #----------------------------------------------------------------------------
  # collection
  #----------------------------------------------------------------------------
  def self.collection
    global ? global.tcg_collection : (@test_collection ||= {})
  end

  def self.card_count(id); collection[id.to_sym].to_i; end

  # AddCardToCollection (capped at 99 copies)
  def self.add_card(id, n = 1)
    id = id.to_sym
    raise ArgumentError, "Unknown TCG card #{id.inspect}" unless CARDS[id]
    collection[id] = [card_count(id) + n, MAX_CARD_COPIES_IN_COLLECTION].min
  end

  def self.remove_card(id, n = 1)
    id = id.to_sym
    left = card_count(id) - n
    left > 0 ? collection[id] = left : collection.delete(id)
  end

  def self.add_cards(ids); ids.each { |i| add_card(i) }; ids; end

  #----------------------------------------------------------------------------
  # booster packs
  #----------------------------------------------------------------------------
  def self.booster_type_of(id)
    t = TYPE_NAMES[CARDS[id][:type]]
    return BOOSTER_TYPE_OF_PKMN_TYPE[t] if t < TYPE_ENERGY
    return 8 if t < TYPE_TRAINER
    7
  end

  # GenerateBoosterPack: returns the 10 card ids (non-energies first)
  def self.generate_booster(pack)
    return pack.generate if pack.is_a?(DestinyPack)   # 086c
    data = BOOSTER_PACKS[pack] or raise ArgumentError, "Unknown booster pack #{pack.inspect}"
    return generate_genesis_booster if data[:energy] == :GenerateGenesisBooster   # 086b
    return send(data[:generator]) if data[:generator]                          # 086d
    loop do
      cards = try_generate_booster(data)
      return cards if cards
    end
  end

  def self.try_generate_booster(data)
    drawn = Hash.new(0)
    energies = []
    nonen = []
    chances = data[:chances].dup
    nz = chances.reject(&:zero?)
    avg = nz.empty? ? 0 : nz.sum / nz.size
    amounts = BOOSTER_RARITY_AMOUNTS[data[:set]][1, 3]   # common, uncommon, rare
    add_energy = lambda { |id| energies << id; drawn[id] += 1 }
    random_energy = lambda { CLASSIC_ENERGY_IDS[rand(NUM_COLORED_TYPES)] }
    case data[:energy]
    when nil
    when :GenerateRandomEnergy then add_energy.call(random_energy.call)
    when :GenerateRandomEnergyBooster
      NUM_CARDS_IN_BOOSTER.times { add_energy.call(random_energy.call) }
      amounts = [0, 0, 0]
    when :GenerateEnergyBoosterLightningFire, :GenerateEnergyBoosterWaterFighting,
         :GenerateEnergyBoosterGrassPsychic, :GenerateEnergyBoosterDarknessMetal
      pair = { :GenerateEnergyBoosterLightningFire => [:LIGHTNING_ENERGY, :FIRE_ENERGY],
               :GenerateEnergyBoosterWaterFighting => [:WATER_ENERGY, :FIGHTING_ENERGY],
               :GenerateEnergyBoosterGrassPsychic  => [:GRASS_ENERGY, :PSYCHIC_ENERGY],
               :GenerateEnergyBoosterDarknessMetal => [:DARKNESS_ENERGY, :METAL_ENERGY] }[data[:energy]]
      pair.each { |e| (NUM_CARDS_IN_BOOSTER / 2).times { add_energy.call(e) } }
      amounts = [0, 0, 0]
    else add_energy.call(data[:energy])
    end
    2.downto(0) do |rarity|
      while amounts[rarity] > 0
        # FindCardsInSetAndRarity (card id order, not already drawn)
        viable = CARD_ORDER.select do |id|
          next false if drawn[id] >= 1
          h = CARDS[id]
          next false unless BOOSTER_RARITY[h[:rarity]] == rarity
          booster_type_of(id) == 8 || h[:sets].first.to_s == data[:set].to_s
        end
        by_type = Array.new(9) { [] }
        viable.each { |id| by_type[booster_type_of(id)] << id }
        # CalculateTypeChances
        tchances = (0...9).map { |t| by_type[t].empty? ? 0 : chances[t] }
        sum = tchances.sum
        return nil if sum == 0                       # no valid cards: redraw pack
        # DetermineBoosterCardType / DetermineBoosterCard
        r = rand(sum)
        type = (0...9).find { |t| tchances[t] != 0 && (r -= tchances[t]) < 0 }
        card = by_type[type][rand(by_type[type].size)]
        # UpdateBoosterCardTypesChanceByte
        chances[type] -= avg
        chances[type] = 1 if chances[type] <= 0
        nonen << card
        drawn[card] += 1
        amounts[rarity] -= 1
      end
    end
    nonen + energies
  end

  # opens a pack into the collection; returns the cards
  def self.give_booster(pack)
    cards = add_cards(generate_booster(pack))
    pack_pulled(cards) if respond_to?(:pack_pulled)   # rare holo points (089g)
    cards
  end

  #----------------------------------------------------------------------------
  # saved decks
  #----------------------------------------------------------------------------
  def self.saved_decks; global ? global.tcg_decks : (@test_decks ||= []); end

  def self.active_deck_cards
    return nil unless global && global.tcg_active_deck
    saved_decks[global.tcg_active_deck]&.dig(:cards)
  end

  # readable name of a premade deck ("CharmanderAndFriendsDeck" -> "Charmander And Friends")
  def self.deck_name(deck_id)
    label = DECKS[deck_id] && DECKS[deck_id][:label] || deck_id.to_s
    label.sub(/Deck\z/, "").gsub(/([a-z])([A-Z])/, '\1 \2').strip
  end

  # adds every card of a premade deck (TCG::DECKS) to the collection and,
  # optionally, saves it as a deck if a slot is free (made active when none is)
  def self.give_deck(deck_id, save_as_deck: true, name: nil)
    cards = deck_list(deck_id)
    add_cards(cards)
    if save_as_deck && saved_decks.size < NUM_DECKS
      saved_decks << { :name => name || deck_name(deck_id), :cards => cards }
      global.tcg_active_deck ||= saved_decks.size - 1 if global
    end
    cards
  end
end
