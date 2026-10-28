#==============================================================================
# Pokemon TCG - effect functions, batch 12 (effect_functions.asm).
# Imposter Oak, Wildfire, Fire Spin, Energy Retrieval / Super Energy Retrieval
# discard pile selections + apply, Golduck Hyper Beam select, Pokemon Breeder.
#==============================================================================
module TCG
  class Duel
    # pick up to max cards from list one by one; nil from controller = stop
    def pick_up_to(purpose, list, max)
      list = list.dup
      picked = []
      while picked.size < max && !list.empty?
        sel = effect_choice(:card, purpose, list, true)
        break if sel.nil?
        picked << sel
        list.delete(sel)
      end
      picked
    end
  end

  effect(:ImposterProfessorOakEffect) do |du|
    du.as_non_turn do
      d = du.turn_duelist
      d.hand.sort_by { |i| TCG.card_order_index(d.card_id(i)) || 0 }.each do |i|
        d.remove_card_from_hand(i)
        d.return_card_to_deck(i)
      end
      du.shuffle_cards_in_deck
      du.display_draw_n_cards(d, 7)
      7.times do
        i = d.draw_card_from_deck or break
        d.add_card_to_hand(i)
      end
    end
    du.ui.message(_INTL("The opponent shuffled their hand into the Deck and drew 7 cards."))
    false
  end

  # Wildfire: choose how many Fire energy to discard (>= 1, else cancel)
  effect(:Wildfire_PlayerSelectEffect) do |du|
    n = du.pick_up_to(:Wildfire, du.list_of_fire_energy_attached_to_arena, 99).size
    du.set_temp(:a0, n)
    n == 0
  end
  effect(:Wildfire_DiscardDeckEffect) do |du|
    n = du.temp(:a0).to_i
    du.as_non_turn do
      d = du.turn_duelist
      [n, d.cards_in_deck].min.times do
        i = d.draw_card_from_deck
        d.put_card_in_discard_pile(i) if i
      end
    end
    false
  end

  # Fire Spin: discard 2 energy cards (any), cancellable
  effect(:FireSpin_PlayerSelectEffect) do |du|
    d = du.turn_duelist
    list = d.energy_cards_in_slot(PLAY_AREA_ARENA).sort_by { |i| TCG.card_order_index(d.card_id(i)) || 0 }
    picked = du.pick_up_to(:FireSpin, list, 2)
    next true if picked.size < 2
    du.set_temp(:list, picked); false
  end

  # Energy Retrieval: list[0] = hand card, then up to 2 basic energy
  effect(:EnergyRetrieval_PlayerDiscardPileSelection) do |du|
    l = du.temp(:list) || []
    l = l.first(1) + du.pick_up_to(:EnergyRetrieval, du.energy_card_list_from_discard_pile(true), 2)
    du.set_temp(:list, l); false
  end

  # Super Energy Retrieval: list[0..1] = hand cards, then up to 4 basic energy
  effect(:SuperEnergyRetrieval_PlayerDiscardPileSelection) do |du|
    l = (du.temp(:list) || []).first(2)
    l += du.pick_up_to(:SuperEnergyRetrieval, du.energy_card_list_from_discard_pile(true), 4)
    du.set_temp(:list, l); false
  end
  effect(:SuperEnergyRetrieval_DiscardAndAddToHandEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list)
    l[0, 2].each { |i| d.remove_card_from_hand(i); d.put_card_in_discard_pile(i) }
    l[2..].each { |i| d.move_discard_pile_card_to_hand(i); d.add_card_to_hand(i) }
    false
  end

  effect(:GolduckHyperBeam_PlayerSelectEffect) do |du|
    list = du.as_non_turn { du.turn_duelist.energy_cards_in_slot(PLAY_AREA_ARENA) }
    du.set_temp(:a0, list.empty? ? nil : (du.effect_choice(:card, :HyperBeam, list, false) || list.first)); false
  end

  # Pokemon Breeder: choose Stage 2 in hand (a0), then Basic to evolve (a1)
  effect(:PokemonBreeder_PlayerSelection) do |du|
    d = du.turn_duelist
    list = du.playable_stage2_cards_in_hand
    card = du.effect_choice(:card, :PokemonBreederCard, list, true)
    next true if card.nil?
    slots = (0...d.num_in_play_area).select { |e| d.can_evolve_basic_to_stage2?(card, e) }
    e = du.effect_choice(:play_area, :PokemonBreederSlot, slots, true)
    next true if e.nil?
    du.set_temp(:a0, card)
    du.set_temp(:a1, e); false
  end
  effect(:PokemonBreeder_EvolveEffect) do |du|
    d = du.turn_duelist
    card, e = du.temp(:a0), du.temp(:a1)
    d.evolve_pokemon_card(card, e)
    d.slot_stage[e] = STAGE2_WITHOUT_STAGE1
    du.ui.event(:evolve, d.name, card, e)
    saved = du.atk
    du.process_played_pokemon_card(card, e)
    du.atk = saved
    false
  end
end
