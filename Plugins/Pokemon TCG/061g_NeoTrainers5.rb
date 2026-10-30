#==============================================================================
# Pokemon TCG - the fifth batch of custom cards: Trainers from the leftover
# Neo sheet slices (data in 001b_NeoCards.rb). Mail from Bill, PokéGear,
# Hyper Potion, Pokémon Nurse (a Supporter on the real card; there are no
# Supporter cards here, so it's a normal Trainer).
#==============================================================================
module TCG
  def self.neo5_cmds(name, *pairs); EFFECT_TABLE["Neo5#{name}EffectCommands"] = pairs; end
  neo5_cmds "MailFromBill",  [EFFECT_INITIAL_EFFECT_1, :Neo5MailFromBill_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo5MailFromBillEffect]
  neo5_cmds "PokeGear",      [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_BEFORE_DAMAGE, :Neo5PokeGearEffect]
  neo5_cmds "HyperPotion",   [EFFECT_INITIAL_EFFECT_1, :Neo5HyperPotion_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo5HyperPotionEffect]
  neo5_cmds "PokemonNurse",  [EFFECT_INITIAL_EFFECT_1, :Neo5PokemonNurse_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo5PokemonNurseEffect]

  class Duel
    # PokéGear: no more Trainer cards this turn
    alias_method :tcg_neo5_cant_use_trainer_due_to_effect?, :cant_use_trainer_due_to_effect?
    def cant_use_trainer_due_to_effect?(d)
      return true if neo_fx_active?(:pokegear, side_of(d))
      tcg_neo5_cant_use_trainer_due_to_effect?(d)
    end

    alias_method :tcg_neo5_play_trainer_card, :play_trainer_card
    def play_trainer_card(idx)
      return :neo_no_more_trainers if neo_fx_active?(:pokegear, @turn)
      tcg_neo5_play_trainer_card(idx)
    end

    # the turn holder's alive Pokémon with damage counters (and basic Energy)
    def neo5_damaged_slots(need_energy = false)
      d = turn_duelist
      (0...d.num_in_play_area).select do |e|
        d.slot_hp[e] > 0 && card_damage_and_max_hp(d, e)[0] > 0 &&
          (!need_energy || d.cards_in_slot(e).any? { |i| d.card(i).basic_energy? })
      end
    end

    def neo5_pick_own(slots, purpose)
      d = turn_duelist
      e = neo_human_choice? ? effect_choice(:play_area, purpose, slots, false) : nil
      slots.include?(e) ? e : slots.max_by { |s| card_damage_and_max_hp(d, s)[0] }
    end
  end

  # Mail from Bill: not with 5+ cards in hand (this one included); draw up to 4
  effect(:Neo5MailFromBill_CheckEffect) do |du|
    du.turn_duelist.hand.size >= 5 ? _INTL("You can't play it with 5 or more cards in your hand.") : false
  end
  effect(:Neo5MailFromBillEffect) do |du|
    # this card is still in the hand until it's discarded
    n = 4 - (du.turn_duelist.hand.size - 1)
    du.adv_draw(n) if n > 0
    false
  end

  # PokéGear: a Trainer card from the top 7 of the deck; no more Trainers this turn
  effect(:Neo5PokeGearEffect) do |du|
    d = du.turn_duelist
    top = d.deck_list.first(7)
    list = top.select { |i| d.card(i).trainer? }
    if list.empty?
      du.ui.message(_INTL("There were no Trainer cards in the top 7 cards."))
    else
      i = du.neo_human_choice? ? du.effect_choice(:card, :AdvSearch, list, true) : list.first
      if list.include?(i)
        du.adv_deck_to_hand(i)
        du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
      end
    end
    du.shuffle_cards_in_deck
    du.neo_fx[:pokegear] = [du.turn, nil, du.duel_turns]
    du.ui.refresh(du); false
  end

  # Hyper Potion: discard 1 or 2 basic Energy from 1 of your Pokémon, remove
  # up to 3 / 5 damage counters
  effect(:Neo5HyperPotion_CheckEffect) do |du|
    du.neo5_damaged_slots(true).empty? ? _INTL("None of your Pokémon have damage counters and basic Energy.") : false
  end
  effect(:Neo5HyperPotionEffect) do |du|
    d = du.turn_duelist
    slots = du.neo5_damaged_slots(true)
    next false if slots.empty?
    e = du.neo5_pick_own(slots, :AdvHeal)
    energy = d.cards_in_slot(e).select { |i| d.card(i).basic_energy? }
    max = [energy.size, 2].min
    dmg = du.card_damage_and_max_hp(d, e)[0]
    n = if du.neo_human_choice? && max > 1
          du.ui.message(_INTL("Discard 1 or 2 basic Energy cards?"))
          du.effect_choice(:number, :Neo5HyperPotion, [1, 2], false).to_i.clamp(1, 2)
        else
          dmg > 30 ? max : 1
        end
    picked = []
    n.times do
      left = energy - picked
      i = du.neo_human_choice? ? du.effect_choice(:card, :AdvDiscardEnergy, left, false) : nil
      picked << (left.include?(i) ? i : left.first)
    end
    picked.each { |i| d.put_card_in_discard_pile(i) }
    du.ui.message(_INTL("{1} Energy card(s) were discarded.", picked.size))
    du.neo4_heal(e, picked.size == 2 ? 50 : 30)
    du.ui.refresh(du); false
  end

  # Pokémon Nurse: remove all damage counters from 1 of your Pokémon, then
  # discard its Energy cards
  effect(:Neo5PokemonNurse_CheckEffect) do |du|
    du.neo5_damaged_slots.empty? ? _INTL("None of your Pokémon have damage counters.") : false
  end
  effect(:Neo5PokemonNurseEffect) do |du|
    d = du.turn_duelist
    slots = du.neo5_damaged_slots
    next false if slots.empty?
    e = du.neo5_pick_own(slots, :AdvHeal)
    du.neo4_heal(e, 9999)
    energy = d.energy_cards_in_slot(e)
    energy.each { |i| d.put_card_in_discard_pile(i) }
    du.ui.message(_INTL("{1} Energy card(s) were discarded.", energy.size)) unless energy.empty?
    du.ui.refresh(du); false
  end
end
