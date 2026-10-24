#==============================================================================
# Pokemon TCG - effect functions, batch 16 (effect_functions.asm).
# Call for Family picks, Energy Spike pick, Devolution Beam apply, Scoop Up
# apply, Super Energy Removal selection.
#==============================================================================
module TCG
  effect(:BellsproutCallForFamily_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.pick_matching_deck_card(:CallForFamily) { |_, id| id == :BELLSPROUT }); false
  end
  effect(:KrabbyCallForFamily_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.pick_matching_deck_card(:CallForFamily) { |_, id| id == :KRABBY }); false
  end
  # ORIGINAL BUG: the "can't cancel" check only looks for Nidoran F, so with
  # only Nidoran M left in the deck the player may back out.
  effect(:NidoranFCallForFamily_PlayerSelectEffect) do |du|
    d = du.turn_duelist
    list = d.deck_list.select { |i| [:NIDORANF, :NIDORANM].include?(d.card_id(i)) }
    if list.empty?
      du.set_temp(:a0, nil)
    else
      can_cancel = list.none? { |i| d.card_id(i) == :NIDORANF }
      sel = du.effect_choice(:card, :CallForFamily, list, can_cancel)
      sel = list.first if sel.nil? && !can_cancel
      du.set_temp(:a0, sel)
    end
    false
  end
  effect(:MarowakCallForFamily_PlayerSelectEffect) do |du|
    du.set_temp(:a0, du.pick_matching_deck_card(:CallForFamily) { |c, _| c.basic? && c.type == FIGHTING }); false
  end

  # Energy Spike: basic energy from the deck (a0) -> one of your Pokemon (a1)
  effect(:EnergySpike_PlayerSelectEffect) do |du|
    i = du.pick_matching_deck_card(:EnergySpike) { |c, _| c.basic_energy? }
    du.set_temp(:a0, i)
    if i
      d = du.turn_duelist
      e = du.effect_choice(:play_area, :EnergySpikeTarget, (0...d.num_in_play_area).to_a, false)
      du.set_temp(:a1, e || 0)
    end
    false
  end

  # Devolution Beam: a0 = side (0 own / 1 opp), a1 = slot. The removed card
  # goes to the HAND.
  effect(:DevolutionBeam_DevolveEffect) do |du|
    side, e = du.temp(:a0), du.temp(:a1)
    next false if side.nil?
    devolve = lambda do
      d = du.turn_duelist
      next if d.play_area[e].nil? || d.slot_stage[e] == BASIC
      du.atk.temp_non_turn_card_id = d.card_id(d.play_area[e])
      blocked = e == PLAY_AREA_ARENA ? du.handle_no_damage_or_effect_substatus : false
      du.handle_damage_reduction_or_no_damage_from_pkmn_power_effects(e, 0) unless blocked
      next if du.check_no_damage_or_effect
      below = du.card_one_stage_below(d, e) or next
      lower, cur = below
      du.ui.message(_INTL("{1} devolved to {2}!", d.card(cur).name, d.card(lower).name))
      du.devolve_slot_to(d, e, lower)
      d.add_card_to_hand(cur)
      du.ui.message(_INTL("{1} was Knocked Out!", d.card(lower).name)) if d.slot_hp[e] == 0
    end
    if side == 0
      devolve.call
    else
      du.as_non_turn do
        next if e == PLAY_AREA_ARENA && du.handle_no_damage_or_effect
        devolve.call
      end
    end
    false
  end

  # Scoop Up: only the Basic Pokemon card returns to the hand; evolutions and
  # attached cards are discarded
  effect(:ScoopUp_ReturnToHandEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    d.cards_in_slot(e).each { |i| d.add_card_to_hand(i) if d.card(i).basic? }
    d.move_play_area_card_to_discard_pile(e)
    d.clear_all_status_conditions if e == 0
    d.swap_play_area_pokemon(du.temp(:a1), PLAY_AREA_ARENA) if e == 0 && du.temp(:a1)
    du.duelists.each(&:shift_pokemon_to_first_play_area_slots)
    du.ui.refresh(du); false
  end

  # Super Energy Removal: :list = [own slot, own energy, opp slot, opp energies (1-2)]
  effect(:SuperEnergyRemoval_PlayerSelection) do |du|
    next true if du.handle_pokemon_and_energy_selection(:SuperEnergyRemovalOwn)
    own_slot, own_card = du.temp(:a0), du.temp(:a1)
    res = du.as_non_turn do
      d = du.turn_duelist
      slots = (0...d.num_in_play_area).select { |s| d.attached_energies(s)[1] > 0 }
      s = du.effect_choice(:play_area, :SuperEnergyRemovalOpp, slots, true)
      next nil if s.nil?
      [s, du.pick_up_to(:SuperEnergyRemovalOpp, d.energy_cards_in_slot(s), 2)]
    end
    next true if res.nil? || res[1].empty?
    du.set_temp(:list, [own_slot, own_card, res[0]] + res[1]); false
  end
end
