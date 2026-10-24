#==============================================================================
# Pokemon TCG - effect functions, batch 13 (effect_functions.asm).
# Prophecy, Pokemon Trader deck pick, Energy Spike attach, Curse check, Super
# Energy Removal apply, Mystery Attack, Imakuni?, Gale, Energy Search pick.
#==============================================================================
module TCG
  class Duel
    # HandleProphecyScreen: reorder the top 3 cards of the turn holder's deck.
    # returns the chosen order (top first)
    def choose_deck_top_order(purpose, n = 3)
      top = turn_duelist.deck_list.first(n)
      order = []
      until top.empty?
        sel = effect_choice(:card, purpose, top, false) || top.first
        order << sel
        top.delete(sel)
      end
      order
    end

    def reorder_deck_top(d, order)
      order.each { |i| d.search_card_in_deck_and_add_to_hand(i) }
      order.reverse_each { |i| d.return_card_to_deck(i) }
    end
  end

  # Prophecy: :list = [deck choice (0 own / 1 opp), order...]
  effect(:Prophecy_PlayerSelectEffect) do |du|
    opts = []
    opts << 0 if du.turn_duelist.not_in_deck < DECK_SIZE
    opts << 1 if du.non_turn_duelist.not_in_deck < DECK_SIZE
    which = du.effect_choice(:yes_no, :ProphecyDeck, opts, false)
    which = opts.first unless opts.include?(which)
    order = which == 1 ? du.as_non_turn { du.choose_deck_top_order(:Prophecy) } : du.choose_deck_top_order(:Prophecy)
    du.set_temp(:list, [which] + order); false
  end
  effect(:Prophecy_ReorderDeckEffect) do |du|
    l = du.temp(:list)
    next false if l.nil? || l[0].nil?
    if l[0] == 1
      du.as_non_turn { du.reorder_deck_top(du.turn_duelist, l[1..]) }
    else
      du.reorder_deck_top(du.turn_duelist, l[1..])
    end
    false
  end

  # Pokemon Trader: pick a Pokemon from the deck (the traded hand card counts
  # as being in the deck while choosing, like the original)
  effect(:PokemonTrader_PlayerDeckSelection) do |du|
    d = du.turn_duelist
    list = (d.deck_list + [du.temp(:a0)]).select { |i| d.card(i).pokemon? }
    du.set_temp(:a1, du.effect_choice(:card, :PokemonTraderDeck, list, false) || list.first); false
  end

  # Energy Spike: attach deck energy a0 to slot a1, then shuffle
  effect(:EnergySpike_AttachEnergyEffect) do |du|
    d = du.turn_duelist
    if (i = du.temp(:a0))
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      d.put_hand_card_in_play_area(i, du.temp(:a1))
      du.ui.message(_INTL("{1} was attached to {2}.", d.card(i).name, d.card(d.play_area[du.temp(:a1)]).name)) unless du.player_turn?
    end
    du.shuffle_cards_in_deck; false
  end

  effect(:Curse_CheckDamageAndBench) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next true if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    next true if du.non_turn_duelist.num_in_play_area < 2
    next true unless du.as_non_turn { du.play_area_has_any_damage? }
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end

  # Super Energy Removal: :list = [own slot, own energy, opp slot, opp energies...]
  effect(:SuperEnergyRemoval_DiscardEffect) do |du|
    l = du.temp(:list)
    du.turn_duelist.put_card_in_discard_pile(l[1])
    du.as_non_turn { l[3..].each { |i| du.turn_duelist.put_card_in_discard_pile(i) } }
    du.ui.refresh(du); false
  end

  # Mystery Attack: 10 dmg + random effect (temp a0 = roll 0..7)
  effect(:MysteryAttack_RandomEffect) do |du|
    du.set_definite_damage(10)
    r = TCG.rng.rand(8)
    du.set_temp(:a0, r)
    case r
    when 0 then du.queue_status(PSN_DBLPSN, PARALYZED)
    when 1 then du.queue_status(CNF_SLP_PRZ, POISONED)
    when 2 then du.queue_status(PSN_DBLPSN, ASLEEP)
    when 3 then du.queue_status(PSN_DBLPSN, CONFUSED)
    when 6 then du.set_definite_damage(20)
    when 7
      du.atk.temp[:anim] = :ATK_ANIM_GLOW_EFFECT
      du.set_definite_damage(0)
      du.set_no_effect_from_status
    end
    false   # 4 = recover (handled by MysteryAttack_RecoverEffect), 5 = nothing
  end

  # Imakuni?: confuse your own active Pokemon (unless Doll/Fossil/protected Snorlax)
  effect(:ImakuniEffect) do |du|
    d = du.turn_duelist
    id = d.card_id(d.arena)
    blocked = id == :CLEFAIRY_DOLL || id == :MYSTERIOUS_FOSSIL ||
              (id == :SNORLAX && !du.incapable_of_using_pkmn_power?(d, PLAY_AREA_ARENA))
    du.ui.event(:trainer_anim, :ATK_ANIM_OWN_CONFUSION)
    d.status = (d.status & PSN_DBLPSN) | CONFUSED unless blocked
    du.ui.refresh(du); false
  end

  # Gale: defender switches with a random bench Pokemon (unless protected),
  # then the attacker always switches with a random bench Pokemon
  effect(:Gale_SwitchEffect) do |du|
    switch_random = lambda do
      d = du.turn_duelist
      next false if d.num_in_play_area < 2
      d.swap_arena_with_bench_pokemon(1 + TCG.rng.rand(d.num_in_play_area - 1))
      true
    end
    unless du.handle_no_damage_or_effect
      du.handle_destiny_bond_substatus if du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] == 0
      du.as_non_turn { du.atk.dealt_damage = 0 if switch_random.call }
    end
    switch_random.call
    du.ui.refresh(du); false
  end

  # Energy Search: pick a basic energy from the deck (nil if none)
  effect(:EnergySearch_PlayerSelection) do |du|
    list = du.turn_duelist.deck_list.select { |i| du.turn_duelist.card(i).basic_energy? }
    du.set_temp(:a0, list.empty? ? nil : du.effect_choice(:card, :EnergySearch, list, true)); false
  end
end
