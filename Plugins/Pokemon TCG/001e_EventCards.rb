#==============================================================================
# Pokemon TCG - event cards (not in the original): copies of a card with
# their own art that only one day of the year gives.
#
#   Halloween (Oct 31):     Absol, Gengar, Crobat (Lv38)
#   Thanksgiving (US, 4th Thursday of November): Pikachu (Lv12), Snorlax
#   Christmas (Dec 25):     Delibird, Sudowoodo
#
# Each is its card with a holiday name, art (Cards/<holiday>_<pokemon>.png)
# and the changes in EVENT_CARD_CHANGES (more HP, new attacks: effects in
# 061h_EventCardEffects.rb).
# Only on Card Slots' Lv 4 reels (legendary & one-of-a-kind), and only on
# their day (Plugins/Card Slots). The server announces them in the chat that
# day (ServerStuff handlers/event_cards.js).
#
# They're reserved (087b): never in booster packs or the Card Shop. The Card
# Trader doesn't offer them (PokeTCG-mod/tools/trader/make_trader_cards.rb);
# players can still trade them. They evolve like their normal card
# (Card#evo_name, 011c): Raichu evolves from Thanksgiving Pikachu.
#==============================================================================
module TCG
  # card => [month, day] it's given on (day :thanksgiving = 4th Thursday)
  EVENT_CARD_DAYS = {
    :HALLOWEEN_ABSOL      => [10, 31],
    :HALLOWEEN_GENGAR     => [10, 31],
    :HALLOWEEN_CROBAT     => [10, 31],
    :THANKSGIVING_PIKACHU => [11, :thanksgiving],
    :THANKSGIVING_SNORLAX => [11, :thanksgiving],
    :CHRISTMAS_DELIBIRD   => [12, 25],
    :CHRISTMAS_SUDOWOODO  => [12, 25]
  }

  # event card => the card it's a copy of
  EVENT_CARD_BASES = {
    :HALLOWEEN_ABSOL      => :ABSOL,
    :HALLOWEEN_GENGAR     => :GENGAR,
    :HALLOWEEN_CROBAT     => :CROBAT_LV38,
    :THANKSGIVING_PIKACHU => :PIKACHU_LV12,
    :THANKSGIVING_SNORLAX => :SNORLAX,
    :CHRISTMAS_DELIBIRD   => :DELIBIRD,
    :CHRISTMAS_SUDOWOODO  => :SUDOWOODO
  }

  def self.event_card_data(id, base, changes = {})
    holiday, pkmn = id.to_s.split("_", 2).map(&:capitalize)
    CARDS[base].merge(:label => "#{holiday}#{pkmn}Card", :gfx => id.to_s.downcase,
                      :name => "#{holiday} #{CARDS[base][:name]}").merge(changes)
  end

  def self.event_attack(name, cost, damage, desc, effect, anim, category = "DAMAGE_NORMAL", flags1 = [])
    { :cost => cost, :name => name, :desc => desc, :damage => damage, :category => [category], :effect => effect,
      :flags1 => flags1, :flags2 => [], :flags3 => [], :param => 0, :anim => anim }
  end

  # each card's changes from its normal card (the user's, 2026-11-03)
  EVENT_CARD_CHANGES = {
    :HALLOWEEN_ABSOL      => { :hp => CARDS[:ABSOL][:hp] + 10 },
    :HALLOWEEN_GENGAR     => { :hp => 90, :attacks => [
      event_attack("Shadow Ball", { "PSYCHIC" => 3 }, 40, nil, nil, "ATK_ANIM_DARK_MIND"),
      CARDS[:GENGAR][:attacks][1]] },
    :HALLOWEEN_CROBAT     => { :hp => 120, :attacks => [
      CARDS[:CROBAT_LV38][:attacks][0],
      event_attack("Cross Attack", { "GRASS" => 2, "COLORLESS" => 1 }, 20,
                   "Does 20 damage plus 10 more damage\nfor each Energy attached to Crobat\nbut not used to pay for this\n" \
                   "attack's Energy cost. You can't add\nmore than 20 damage in this way.",
                   "EventCrossAttackEffectCommands", "ATK_ANIM_MULTIPLE_SLASH", "DAMAGE_PLUS")] },
    :THANKSGIVING_PIKACHU => { :hp => 70 },
    :THANKSGIVING_SNORLAX => { :hp => 120, :attacks => [
      event_attack("Rest", { "COLORLESS" => 2 }, 0,
                   "Discard 2 Energy cards attached to\nSnorlax. Remove all damage counters\nfrom Snorlax. Snorlax is now Asleep.",
                   "EventRestEffectCommands", "ATK_ANIM_RECOVER", "RESIDUAL"),
      CARDS[:SNORLAX][:attacks][1]] },
    :CHRISTMAS_DELIBIRD   => { :hp => 100, :attacks => [
      CARDS[:DELIBIRD][:attacks][0],
      event_attack("Blizzard", { "WATER" => 3 }, 40,
                   "Flip 2 coins. If both of them are\nheads, the Defending Pokémon is now\nParalyzed.",
                   "EventBlizzardEffectCommands", "ATK_ANIM_BLIZZARD", "DAMAGE_NORMAL", ["INFLICT_PARALYSIS"])] },
    :CHRISTMAS_SUDOWOODO  => { :hp => 100, :attacks => [
      CARDS[:SUDOWOODO][:attacks][0].merge(:damage => 20, :effect => "EventFlailEffectCommands",
                                           :desc => "Does 20 damage times the number of\ndamage counters on Sudowoodo."),
      CARDS[:SUDOWOODO][:attacks][1]] }
  }

  EVENT_CARDS = EVENT_CARD_BASES.to_h { |id, base| [id, event_card_data(id, base, EVENT_CARD_CHANGES[id] || {})] }

  EVENT_CARDS.each { |id, h| CARDS[id] = h }
  EVENT_CARD_BASES.each { |id, base| CARD_ORDER.insert(CARD_ORDER.index(base) + 1, id) unless CARD_ORDER.include?(id) }

  # event card name => its normal card's name ("Thanksgiving Pikachu" => "Pikachu")
  EVENT_CARD_BASE_NAMES = EVENT_CARD_BASES.to_h { |id, base| [CARDS[id][:name], CARDS[base][:name]] }

  def self.event_card?(id); EVENT_CARD_DAYS.key?(base_id(id)); end

  # the name a card evolves as (an event card evolves like its normal card)
  def self.evolves_as(name); EVENT_CARD_BASE_NAMES[name] || name; end

  # US Thanksgiving: the 4th Thursday of November
  def self.thanksgiving_day(year)
    1 + (4 - Time.new(year, 11, 1).wday) % 7 + 21
  end

  # is today event card id's day? (the game's clock)
  def self.event_card_day?(id, now = (pbGetTimeNow rescue Time.now))
    m, d = EVENT_CARD_DAYS[base_id(id)]
    d = thanksgiving_day(now.year) if d == :thanksgiving
    m && now.month == m && now.day == d
  end
end
