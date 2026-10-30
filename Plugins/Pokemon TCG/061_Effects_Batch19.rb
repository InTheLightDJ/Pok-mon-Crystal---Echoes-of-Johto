#==============================================================================
# Pokemon TCG - effect functions, batch 19 (effect_functions.asm).
# Metronome, Morph, Firegiver, Devolution Spray selection.
#==============================================================================
module TCG
  class Duel
    # HandlePlayerMetronomeEffect: the current attack becomes the chosen
    # defending Pokemon's attack. true (carry) = cancelled / failed.
    def handle_metronome(energy_cost)
      @atk.temp[:metronome_energy_cost] = energy_cost
      sel = effect_choice(:attack, :Metronome, defending_pokemon_attack_options, true)
      return true if sel.nil?
      nd = non_turn_duelist
      copied = nd.card(sel[0]).attacks[sel[1]]
      return true if copied.name == @atk.attack.name   # can't copy Metronome itself
      @atk.attack      = copied
      @atk.effect_name = copied.effect
      @atk.damage      = copied.damage
      @atk.card_id     = nd.card_id(sel[0])
      return true if try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
      return true if try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
      false
    end
  end

  effect(:ClefableMetronome_UseAttackEffect) { |du| du.handle_metronome(1) }
  effect(:ClefairyMetronome_UseAttackEffect) { |du| du.handle_metronome(3) }

  # Morph: Ditto becomes a random Basic Pokemon from the deck (not Ditto) for
  # the rest of the duel, at full HP, with status cleared
  effect(:MorphEffect) do |du|
    d = du.turn_duelist
    pick = d.deck_list.shuffle(random: TCG.rng).find { |i| d.card(i).basic? && d.card_id(i) != :DITTO }
    next false if pick.nil?
    if d.slot_stage[PLAY_AREA_ARENA] != BASIC
      below = du.card_one_stage_below(d, PLAY_AREA_ARENA)
      d.put_card_in_discard_pile(below[0]) if below
      d.slot_stage[PLAY_AREA_ARENA] = BASIC
    end
    ditto = d.arena
    old = d.card(ditto).name
    d.deck_ids[ditto] = d.card_id(pick)
    d.slot_hp[PLAY_AREA_ARENA] = d.card(ditto).hp
    d.slot_changed_type[PLAY_AREA_ARENA] = 0
    d.clear_all_status_conditions
    du.ui.message(_INTL("{1} morphed into {2}!", old, d.card(ditto).name))
    du.ui.refresh(du); false
  end

  # Firegiver (power trigger on play): 1-4 random Fire Energy from deck to hand
  effect(:Firegiver_AddToHandEffect) do |du|
    d = du.turn_duelist
    fire = TYPE_NAMES["TYPE_ENERGY_FIRE"]
    list = (0...d.deck_size).select { |i| d.card_locations[i] == CARD_LOCATION_DECK && d.card(i).type == fire }
    unless list.empty?
      n = [1 + TCG.rng.rand(4), list.size].min
      list.first(n).each { |i| d.search_card_in_deck_and_add_to_hand(i); d.add_card_to_hand(i) }
      du.ui.message(_INTL("{1} Fire Energy card(s) were put into the hand.", n))
    end
    du.shuffle_cards_in_deck; false
  end

  # Pokedex: put the top min(5, deck) cards in the chosen order (:list top first)
  effect(:Pokedex_PlayerSelection) do |du|
    order = du.choose_deck_top_order(:Pokedex, 5)
    du.set_temp(:list, order); false
  end

  # Devolution Spray: choose an evolved Pokemon and how many stages to remove.
  # :list = [slot, removed cards (top first)...]
  effect(:DevolutionSpray_PlayerSelection) do |du|
    d = du.turn_duelist
    slots = (0...d.num_in_play_area).select { |e| d.slot_stage[e] != BASIC }
    e = du.effect_choice(:play_area, :DevolutionSpray, slots, true)
    next true if e.nil?
    removed = []
    stack = d.cards_in_slot(e).select { |i| d.card(i).pokemon? }.sort_by { |i| -d.card(i).stage }
    stack.each do |i|
      break if d.card(i).stage == BASIC
      removed << i
      nxt = stack[stack.index(i) + 1]
      break if nxt.nil? || d.card(nxt).stage == BASIC
      break unless du.effect_choice(:yes_no, :DevolutionSprayMore, [true, false], false) == true
    end
    ok = du.effect_choice(:yes_no, :DevolutionSprayConfirm, [true, false], false)
    next true if ok == false
    du.set_temp(:list, [e] + removed); false
  end
end
