#==============================================================================
# Pokemon TCG - debug menu entry for testing duels (Debug > Pokémon TCG test duel).
#==============================================================================
MenuHandlers.add(:debug_menu, :tcg_test_duel, {
  "name"        => _INTL("Pokémon TCG test duel"),
  "parent"      => :main,
  "description" => _INTL("Start a Pokémon TCG duel against one of the original decks."),
  "always_show" => true,
  "effect"      => proc {
    decks = TCG::DECKS.keys.reject { |k| k.to_s.start_with?("UNNAMED") }
    names = decks.map { |k| k.to_s.sub(/_DECK$/, "").split("_").map(&:capitalize).join(" ") }
    pd = pbMessage(_INTL("Your deck?"), names, -1)
    next if pd < 0
    od = pbMessage(_INTL("Opponent's deck?"), names, -1)
    next if od < 0
    rewards = [nil, :COLOSSEUM_NEUTRAL, :EVOLUTION_NEUTRAL, :MYSTERY_NEUTRAL, :LABORATORY_MOSTLY_NEUTRAL,
               :GENESIS, DESTINY(:ABRA, 10), [:COLOSSEUM_NEUTRAL, :EVOLUTION_NEUTRAL]]
    rnames = [_INTL("None"), _INTL("Colosseum pack"), _INTL("Evolution pack"), _INTL("Mystery pack"),
              _INTL("Laboratory pack"), _INTL("Genesis pack"),
              _INTL("Destiny pack (Abra 1/10)"), _INTL("Colosseum + Evolution packs")]
    rw = pbMessage(_INTL("Reward for winning?"), rnames, 0)
    won = pbTCGDuel("Opponent", decks[od], decks[pd], reward: rewards[[rw, 0].max])
    pbMessage(won ? _INTL("You won!") : _INTL("You lost."))
  }
})

MenuHandlers.add(:debug_menu, :tcg_deck_menu, {
  "name"        => _INTL("Pokémon TCG decks"),
  "parent"      => :main,
  "description" => _INTL("Open the TCG deck menu (choose, edit, build decks)."),
  "always_show" => true,
  "effect"      => proc { pbTCGDeckMenu }
})

MenuHandlers.add(:debug_menu, :tcg_give_cards, {
  "name"        => _INTL("Pokémon TCG give cards"),
  "parent"      => :main,
  "description" => _INTL("Give a starter deck or open booster packs into the TCG collection."),
  "always_show" => true,
  "effect"      => proc {
    case pbMessage(_INTL("Give what?"), [_INTL("Starter deck"), _INTL("Booster pack"), _INTL("Cancel")], 3)
    when 0
      decks = TCG::DECKS.keys.reject { |k| k.to_s.start_with?("UNNAMED") }
      i = pbMessage(_INTL("Which deck?"), decks.map { |k| TCG.deck_name(k) }, -1)
      if i >= 0
        TCG.give_deck(decks[i])
        pbMessage(_INTL("Got the {1} deck.", TCG.deck_name(decks[i])))
      end
    when 1
      packs = TCG::BOOSTER_PACKS.keys
      i = pbMessage(_INTL("Which pack?"), packs.map { |k| k.to_s.split("_").map(&:capitalize).join(" ") }, -1)
      if i >= 0
        pbTCGOpenBooster(packs[i])
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :tcg_card_album, {
  "name"        => _INTL("Pokémon TCG card album"),
  "parent"      => :main,
  "description" => _INTL("Browse the TCG card collection."),
  "always_show" => true,
  "effect"      => proc { pbTCGCardAlbum }
})

MenuHandlers.add(:debug_menu, :tcg_medals, {
  "name"        => _INTL("Pokémon TCG medals"),
  "parent"      => :main,
  "description" => _INTL("Give or take the Club Masters' medals (trainer card's Medals page)."),
  "always_show" => true,
  "effect"      => proc {
    loop do
      names = TCG::MEDALS.map { |m| (TCG.medal?(m) ? "[X] " : "[  ] ") + TCG.medal_name(m) }
      i = pbMessage(_INTL("Toggle which medal?"), names, -1)
      break if i < 0
      m = TCG::MEDALS[i]
      TCG.medal?(m) ? pbTCGRemoveMedal(m) : pbTCGGiveMedal(m, show: false)
    end
  }
})
