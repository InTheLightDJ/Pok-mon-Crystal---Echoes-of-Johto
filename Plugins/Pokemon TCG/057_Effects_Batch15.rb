#==============================================================================
# Pokemon TCG - effect functions, batch 15 (effect_functions.asm).
# Strange Behavior, Poke Ball pick, Pokemon Center, Mr. Fuji, Wail, Peek,
# Sprout pick, Mix Up.
#==============================================================================
module TCG
  class Duel
    # LookForCardsInDeck-style pick: if any card matches, one MUST be chosen;
    # otherwise nil (the original only lets you back out when none exist)
    def pick_matching_deck_card(purpose, &match)
      d = turn_duelist
      list = d.deck_list.select { |i| match.call(d.card(i), d.card_id(i)) }
      return nil if list.empty?
      sel = effect_choice(:card, purpose, list, false)
      return nil if sel == :none          # AI selection chose no card ($ff)
      list.include?(sel) ? sel : list.first
    end

    # fill the turn holder's bench with random Basic Pokemon from the deck
    def fill_bench_from_deck
      d = turn_duelist
      return if d.cards_in_deck == 0
      d.deck_list.shuffle(random: TCG.rng).each do |i|
        break if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        next unless d.card(i).basic?
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
        put_basic_pokemon_in_play_area(i)
      end
      shuffle_cards_in_deck
    end
  end

  # Strange Behavior: move damage counters one at a time onto Slowbro (a0)
  effect(:StrangeBehavior_SelectAndSwapEffect) do |du|
    d = du.turn_duelist
    slowbro = du.temp(:a0)
    loop do
      slots = (0...d.num_in_play_area).select { |e| e != slowbro && du.card_damage_and_max_hp(d, e)[0] > 0 }
      break if slots.empty? || d.slot_hp[slowbro] <= 10
      e = du.effect_choice(:play_area, :StrangeBehavior, slots, true)
      break if e.nil?
      d.slot_hp[slowbro] -= 10
      d.slot_hp[e] += 10
      du.ui.refresh(du)
    end
    false
  end

  # Poke Ball: coin (:list[0]); heads -> pick a Pokemon from the deck (:list[1])
  effect(:PokeBall_PlayerSelection) do |du|
    du.ui.message(_INTL("If Heads, take a Pokémon card from your Deck."))
    r = du.toss_coin
    pick = r == HEADS ? du.pick_matching_deck_card(:PokeBall) { |c, _| c.pokemon? } : nil
    du.set_temp(:list, [r, pick]); false
  end

  # Pokemon Center: heal all damage, discard all energy from healed Pokemon
  effect(:PokemonCenter_HealDiscardEnergyEffect) do |du|
    d = du.turn_duelist
    (0...d.num_in_play_area).each do |e|
      dmg = du.card_damage_and_max_hp(d, e)[0]
      next if dmg == 0
      du.heal_play_area_card_hp(e, dmg)
      d.energy_cards_in_slot(e).each { |i| d.put_card_in_discard_pile(i) }
    end
    false
  end

  # Mr. Fuji: bench Pokemon a0 and attached cards go back into the deck
  effect(:MrFuji_ReturnToDeckEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    name = d.card(d.play_area[e]).name
    d.cards_in_slot(e).each { |i| d.return_card_to_deck(i) }
    d.empty_play_area_slot(e)
    du.duelists.each(&:shift_pokemon_to_first_play_area_slots)
    du.ui.message(_INTL("{1} and all attached cards were returned to the Deck.", name)) unless du.player_turn?
    du.shuffle_cards_in_deck; false
  end

  # Wail: both players fill their benches from their decks (opponent first)
  effect(:Wail_FillBenchEffect) do |du|
    du.as_non_turn { du.fill_bench_from_deck }
    du.fill_bench_from_deck
    du.ui.refresh(du); false
  end

  # Peek: look at one hidden card (own deck top, opponent's deck top,
  # opponent's hand card, or one of your prizes). Information only.
  effect(:Peek_SelectEffect) do |du|
    d = du.turn_duelist
    d.slot_flags[du.temp(:a0)] |= USED_PKMN_POWER_THIS_TURN
    opts = [:own_deck, :opp_deck, :opp_hand, :prize]
    sel = du.effect_choice(:peek, :Peek, opts, false) || :own_deck
    du.atk.temp[:power_param] = sel
    du.ui.event(:peek, sel) if du.player_turn?   # (the duel scene shows the card while selecting)
    false
  end

  effect(:Sprout_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.pick_matching_deck_card(:Sprout) { |_, id| id == :ODDISH }); false
  end

  # Mix Up: opponent's hand Pokemon -> deck, shuffle, then the same number of
  # Pokemon are taken from the top of the deck
  effect(:MixUpEffect) do |du|
    du.as_non_turn do
      d = du.turn_duelist
      mons = d.hand.select { |i| d.card(i).pokemon? }.sort_by { |i| CARD_ORDER.index(d.card_id(i)) || 0 }
      mons.each { |i| d.remove_card_from_hand(i); d.return_card_to_deck(i) }
      du.shuffle_cards_in_deck
      d.deck_list.select { |i| d.card(i).pokemon? }.first(mons.size).each do |i|
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
      end
    end
    false
  end
end
