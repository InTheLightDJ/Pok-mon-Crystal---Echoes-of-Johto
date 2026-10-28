#==============================================================================
# Pokemon TCG - effect functions, batch 17 (effect_functions.asm).
# Thunderstorm, Magnetic Storm, Lass, Gigashock selection.
#==============================================================================
module TCG
  # Thunderstorm: a coin per opponent bench Pokemon; heads = 20 to it,
  # each tails = 10 recoil to Zapdos (recoil applied first)
  effect(:ThunderstormEffect) do |du|
    results = du.as_non_turn do
      (1...du.turn_duelist.num_in_play_area).map do |e|
        du.ui.message(_INTL("{1}: If Heads, 20 damage.", du.turn_duelist.card(du.turn_duelist.play_area[e]).name))
        du.as_non_turn { du.toss_coin }
      end
    end
    tails = results.count(TAILS)
    du.deal_recoil_damage_to_self(10 * tails) if tails > 0
    du.as_non_turn do
      results.each_with_index { |r, i| du.deal_damage_to_play_area_pokemon(i + 1, 20) if r == HEADS }
    end
    false
  end

  # Magnetic Storm: shuffle all your attached energy and redistribute it evenly.
  # ORIGINAL BUG: the leftover cards are not randomized, they go to the arena,
  # bench 1, bench 2, ... in order.
  effect(:MagneticStormEffect) do |du|
    d = du.turn_duelist
    energies = (0...DECK_SIZE).select { |i| (d.card_locations[i] & CARD_LOCATION_PLAY_AREA) != 0 && d.card(i).energy? }
    n = d.num_in_play_area
    per = energies.size / n
    pool = energies.shuffle(random: TCG.rng)
    n.times { |e| per.times { d.card_locations[pool.shift] = CARD_LOCATION_PLAY_AREA | e } }
    pool.each_with_index { |i, k| d.card_locations[i] = CARD_LOCATION_PLAY_AREA | k }
    du.ui.refresh(du); false
  end

  # Lass: discard Lass, then both players shuffle their hand's Trainer cards
  # into their decks (opponent first)
  effect(:LassEffect) do |du|
    d = du.turn_duelist
    d.remove_card_from_hand(du.atk.card_index)
    d.put_card_in_discard_pile(du.atk.card_index)
    du.ui.event(:show_hand, du.non_turn_duelist.name)
    shuffle_trainers = lambda do
      x = du.turn_duelist
      trainers = x.hand.select { |i| x.card(i).trainer? }.sort_by { |i| TCG.card_order_index(x.card_id(i)) || 0 }
      trainers.each { |i| x.remove_card_from_hand(i); x.return_card_to_deck(i) }
      du.shuffle_cards_in_deck if trainers.any?
    end
    du.as_non_turn { shuffle_trainers.call }
    shuffle_trainers.call
    false
  end

  # Gigashock: choose up to 3 different opponent bench Pokemon (:list of slots)
  effect(:Gigashock_PlayerSelectEffect) do |du|
    slots = du.as_non_turn { (1...du.turn_duelist.num_in_play_area).to_a }
    if slots.empty?
      du.set_temp(:list, [])
    else
      need = [3, slots.size].min
      picked = []
      while picked.size < need
        sel = du.as_non_turn { du.effect_choice(:play_area, :Gigashock, slots - picked, false) }
        sel = (slots - picked).first unless (slots - picked).include?(sel)
        picked << sel
      end
      du.set_temp(:list, picked)
    end
    false
  end
end
