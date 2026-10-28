#==============================================================================
# Pokemon TCG - effect functions, batch 14 (effect_functions.asm).
# Devolution helpers + Devolution Spray, Devolution Beam selection, Shift color
# pick, Gambler, Hurricane, Curse transfer, Chain Lightning, Super Potion pick,
# Healing Wind, Heal. Also matches ReplaceKnockedOutPokemon's HP-only check.
#==============================================================================
module TCG
  class Duel
    # GetCardOneStageBelow: [lower deck index, current deck index] or nil if Basic
    def card_one_stage_below(d, e)
      cur = d.play_area[e]
      return nil if d.card(cur).stage == BASIC
      stages = [nil, nil, nil]
      d.cards_in_slot(e).each do |i|
        c = d.card(i)
        # DEVIATION: the original skips Trainer cards here, so a Pokemon that
        # evolved from Mysterious Fossil devolves into garbage ($ff). We treat
        # the Fossil as the Basic stage instead.
        stages[c.stage] = i if (c.pokemon? || c.special_trainer_pokemon?) && c.stage <= STAGE2
      end
      return nil if (st = d.slot_stage[e]) && ((st == STAGE1 || st == STAGE2_WITHOUT_STAGE1) ? stages[0] : stages[1]).nil?
      st = d.slot_stage[e]
      lower = (st == STAGE1 || st == STAGE2_WITHOUT_STAGE1) ? stages[0] : stages[1]
      [lower, cur]
    end

    # UpdateDevolvedCardHPAndStage + ResetDevolvedCardStatus
    def devolve_slot_to(d, e, lower)
      dmg = card_damage_and_max_hp(d, e)[0]
      d.play_area[e] = lower
      d.slot_hp[e] = [d.card(lower).hp - dmg, 0].max
      d.slot_stage[e] = d.card(lower).stage
      d.clear_all_status_conditions if e == PLAY_AREA_ARENA
      d.slot_changed_type[e] = 0
      d.slot_flags[e] = 0
    end

    # HandleEvolvedCardSelection (turn holder) -> slot or nil
    def select_evolved_card(purpose)
      d = turn_duelist
      slots = (0...d.num_in_play_area).select { |e| d.slot_stage[e] != BASIC }
      return nil if slots.empty?
      effect_choice(:play_area, purpose, slots, true)
    end

    # ReplaceKnockedOutPokemon checks HP only, so an emptied arena (Hurricane)
    # is also replaced. Overrides 034.
    def replace_knocked_out_pokemon
      d = turn_duelist
      return false if d.slot_hp[PLAY_AREA_ARENA] > 0
      d.clear_all_status_conditions
      return true unless has_alive_pokemon_in_bench?(d)
      choices = (1...MAX_PLAY_AREA_POKEMON).select { |e| d.play_area[e] && d.slot_hp[e] > 0 }
      e = turn_controller.choose_ko_replacement(self, choices)
      e = choices.first unless choices.include?(e)
      d.swap_play_area_pokemon(e, PLAY_AREA_ARENA)
      @ui.event(:ko_replace, d.name, d.arena)
      false
    end
  end

  # Devolution Spray: :list = [slot, cards to remove (top first)...]
  effect(:DevolutionSpray_DevolutionEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list)
    e = l[0]
    l[1..].each do |_|
      below = du.card_one_stage_below(d, e) or break
      lower, cur = below
      du.devolve_slot_to(d, e, lower)
      d.put_card_in_discard_pile(cur)
    end
    du.ui.message(_INTL("{1} devolved.", d.card(d.play_area[e]).name))
    du.ui.message(_INTL("{1} was Knocked Out!", d.card(d.play_area[e]).name)) if d.slot_hp[e] == 0
    du.handle_destiny_bond_and_between_turn_knock_outs; false
  end

  # Devolution Beam: a0 = side (0 own / 1 opponent), a1 = slot
  effect(:DevolutionBeam_PlayerSelectEffect) do |du|
    loop do
      opts = []
      opts << 0 if du.has_evolved_cards?
      opts << 1 if du.as_non_turn { du.has_evolved_cards? }
      side = du.effect_choice(:yes_no, :DevolutionBeamSide, opts, true)
      break true if side.nil?
      slot = side == 1 ? du.as_non_turn { du.select_evolved_card(:DevolutionBeam) } : du.select_evolved_card(:DevolutionBeam)
      next if slot.nil?
      du.set_temp(:a0, side)
      du.set_temp(:a1, slot)
      break false
    end
  end

  # Shift: choose a color that some Pokemon in play has (atk.temp[:power_param])
  effect(:Shift_PlayerSelectEffect) do |du|
    in_play = lambda do |col|
      [du.turn_duelist, du.non_turn_duelist].any? do |d|
        (0...d.num_in_play_area).any? { |e| du.play_area_card_color(d, e) == col }
      end
    end
    colors = (0...NUM_COLORED_TYPES).select { |c| in_play.call(c) }
    col = du.effect_choice(:color, :Shift, colors, true)
    next true if col.nil?
    du.atk.temp[:power_param] = col; false
  end

  # Gambler: discard Gambler, hand -> deck (sorted), shuffle, draw 8 (heads) / 1
  effect(:GamblerEffect) do |du|
    d = du.turn_duelist
    du.ui.message(_INTL("If Heads, draw 8 cards. If Tails, draw 1 card."))
    r = du.toss_coin
    d.remove_card_from_hand(du.atk.card_index)
    d.put_card_in_discard_pile(du.atk.card_index)
    d.hand.sort_by { |i| TCG.card_order_index(d.card_id(i)) || 0 }.each { |i| d.remove_card_from_hand(i); d.return_card_to_deck(i) }
    du.shuffle_cards_in_deck
    du.display_draw_n_cards(d, r == HEADS ? 8 : 1)
    (r == HEADS ? 8 : 1).times do
      i = d.draw_card_from_deck or break
      d.add_card_to_hand(i)
    end
    false
  end

  # Hurricane: defending Pokemon + attached cards return to the hand
  effect(:HurricaneEffect) do |du|
    next false if du.handle_no_damage_or_effect
    next false if du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] == 0
    du.as_non_turn do
      d = du.turn_duelist
      name = d.card(d.arena).name
      (0...DECK_SIZE).each { |i| d.add_card_to_hand(i) if d.card_locations[i] == CARD_LOCATION_ARENA }
      d.play_area[PLAY_AREA_ARENA] = nil
      d.slot_hp[PLAY_AREA_ARENA] = 0
      du.ui.message(_INTL("{1} and all attached cards were returned to the hand.", name))
    end
    false
  end

  # Curse: move 1 damage counter between the opponent's Pokemon
  # (atk.temp[:play_area_effect_target] loses 10 HP, a1 gains 10 HP)
  effect(:Curse_TransferDamageEffect) do |du|
    du.turn_duelist.slot_flags[(du.temp(:list) || [du.temp(:a0)])[0]] |= USED_PKMN_POWER_THIS_TURN
    du.as_non_turn do
      d = du.turn_duelist
      d.slot_hp[du.atk.temp[:play_area_effect_target]] -= 10
      d.slot_hp[du.temp(:a1)] += 10
    end
    du.handle_destiny_bond_and_between_turn_knock_outs; false
  end

  # Chain Lightning: 10 to each Benched Pokemon (both sides) sharing the
  # defending Pokemon's color, unless that color is Colorless
  effect(:ChainLightningEffect) do |du|
    du.set_definite_damage(10)
    col = du.as_non_turn { du.play_area_card_color(du.turn_duelist, PLAY_AREA_ARENA) }
    next false if col == COLORLESS
    same = lambda do
      d = du.turn_duelist
      (1...d.num_in_play_area).each { |e| du.deal_damage_to_play_area_pokemon(e, 10) if du.play_area_card_color(d, e) == col }
    end
    du.as_non_turn { same.call }
    du.atk.is_damage_to_self = true
    same.call
    false
  end

  # Super Potion: choose a damaged Pokemon with energy, then an energy;
  # heal min(damage, 40)
  effect(:SuperPotion_PlayerSelectEffect) do |du|
    d = du.turn_duelist
    slots = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 && d.attached_energies(e)[1] > 0 }
    e = du.effect_choice(:play_area, :SuperPotion, slots, true)
    next true if e.nil?
    en = du.effect_choice(:card, :SuperPotionEnergy, d.energy_cards_in_slot(e), true)
    next true if en.nil?
    du.set_temp(:a0, en)
    du.set_temp(:a1, e)
    du.atk.temp[:play_area_effect_target] = [du.card_damage_and_max_hp(d, e)[0], 40].min; false
  end

  # Healing Wind (played trigger): heal 20 from each of your Pokemon
  effect(:HealingWind_PlayAreaHealEffect) do |du|
    d = du.turn_duelist
    (0...d.num_in_play_area).each do |e|
      dmg = du.card_damage_and_max_hp(d, e)[0]
      d.slot_hp[e] += [dmg, 20].min if dmg > 0
    end
    du.ui.refresh(du); false
  end

  # Heal (Vileplume): heads -> remove 1 damage counter from a chosen Pokemon
  effect(:Heal_RemoveDamageEffect) do |du|
    d = du.turn_duelist
    du.ui.message(_INTL("If Heads, remove 1 damage counter from 1 of your Pokémon."))
    r = du.toss_coin
    du.atk.temp[:power_param] = r
    if r == HEADS
      slots = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
      tgt = du.effect_choice(:play_area, :Heal, slots, false)
      tgt = slots.first unless slots.include?(tgt)
      du.atk.temp[:play_area_effect_target] = tgt
    end
    d.slot_flags[du.temp(:a0)] |= USED_PKMN_POWER_THIS_TURN
    d.slot_hp[du.atk.temp[:play_area_effect_target]] += 10 if r == HEADS
    du.ui.refresh(du); false
  end
end
