#==============================================================================
# Pokemon TCG - effect functions, batch 9 (effect_functions.asm).
# Call for Family placement, Selfdestruct variants, Petal Dance, Fly, Mega
# Drain/Absorb, Karate Chop, Pay Day, Blizzard, Wildfire, Gigashock, Hyper Beam/
# Whirlpool discards, trainers (Computer Search, Item Finder, Recycle, Revive,
# Pokemon Flute, Trader, Energy Search, Energy Removal, Defender, Gust of Wind).
#==============================================================================
module TCG
  class Duel
    # *_PutInPlayAreaEffect (Call for Family / Sprout): bench card a0, shuffle
    def put_deck_card_in_play_area_from_temp
      d = turn_duelist
      i = temp(:a0)
      if i
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
        put_basic_pokemon_in_play_area(i)
        @ui.message(_INTL("{1} was placed on the Bench.", d.card(i).name)) unless player_turn?
      end
      shuffle_cards_in_deck
    end

    def selfdestruct(self_dmg, bench)
      deal_recoil_damage_to_self(self_dmg)
      @atk.is_damage_to_self = true
      deal_damage_to_all_benched_pokemon(bench)
      as_non_turn do
        @atk.is_damage_to_self = false
        deal_damage_to_all_benched_pokemon(bench)
      end
    end

    # half of dealt damage, rounded up to 10 (Mega Drain / Absorb)
    def heal_half_dealt_damage
      n = @atk.dealt_damage >> 1
      n += 5 if n.odd?
      apply_and_animate_hp_recovery(n)
    end

    # discard defending Pokemon's energy a0 (Hyper Beam / Whirlpool)
    def discard_defending_energy_from_temp(mark_last_turn)
      return if handle_no_damage_or_effect
      i = temp(:a0)
      return if i.nil?
      as_non_turn do
        turn_duelist.put_card_in_discard_pile(i)
        turn_duelist.last_turn_effect = LAST_TURN_EFFECT_DISCARD_ENERGY if mark_last_turn
      end
    end

    def draw_one_card_effect
      d = turn_duelist
      display_draw_n_cards(d, 1, _INTL("Draw 1 card from the Deck."))
      i = d.draw_card_from_deck
      return unless i
      d.add_card_to_hand(i)
      @ui.event(:draw, d.name, i)
    end
  end

  effects(:BellsproutCallForFamily_PutInPlayAreaEffect, :KrabbyCallForFamily_PutInPlayAreaEffect,
          :NidoranFCallForFamily_PutInPlayAreaEffect, :MarowakCallForFamily_PutInPlayAreaEffect,
          :Sprout_PutInPlayAreaEffect) { |du| du.put_deck_card_in_play_area_from_temp; false }

  { :MagnemiteSelfdestructEffect => [40, 10], :MagnetonLv28SelfdestructEffect => [80, 20],
    :MagnetonLv35SelfdestructEffect => [100, 20] }.each do |name, (s, b)|
    effect(name) { |du| du.selfdestruct(s, b); false }
  end

  effect(:PetalDance_MultiplierEffect) do |du|
    du.ui.message(_INTL("Damage check! {1} damage for each Heads.", 40))
    du.set_definite_damage(40 * du.toss_coins(3))
    du.confuse_self; false
  end

  effect(:Fly_Success50PercentEffect) do |du|
    du.ui.message(_INTL("Success check! If Heads, the attack is successful."))
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_AGILITY_PROTECT
      du.apply_substatus1_to_attacking_card(SUBSTATUS1_FLY)
    else
      du.atk.temp[:anim] = :NONE
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:MoltresLv37DiveBomb_Success50PercentEffect) do |du|
    du.ui.message(_INTL("Success check! If Heads, the attack is successful."))
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_DIVE_BOMB
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end

  effects(:ButterfreeMegaDrainEffect, :AbsorbEffect) { |du| du.heal_half_dealt_damage; false }

  effect(:KarateChop_DamageSubtractionEffect) do |du|
    du.atk.damage = [du.atk.damage - du.arena_damage, 0].max; false
  end

  effect(:PayDayEffect) do |du|
    du.ui.message(_INTL("If Heads, draw 1 card from the Deck."))
    du.draw_one_card_effect if du.toss_coin == HEADS; false
  end

  effect(:SpacingOut_HealEffect) do |du|
    next false if du.temp(:a0) == TAILS || du.arena_damage == 0
    du.turn_duelist.slot_hp[PLAY_AREA_ARENA] += 10; false
  end

  effect(:Prophecy_CheckDeck) do |du|
    du.turn_duelist.not_in_deck < DECK_SIZE || du.non_turn_duelist.not_in_deck < DECK_SIZE ?
      false : _INTL("There are no cards left in the Deck.")
  end
  effect(:Wail_BenchCheck) do |du|
    du.turn_duelist.num_in_play_area < MAX_PLAY_AREA_POKEMON ||
      du.non_turn_duelist.num_in_play_area < MAX_PLAY_AREA_POKEMON ? false : _INTL("There is no space on the Bench.")
  end

  effect(:Blizzard_BenchDamageEffect) do |du|
    if du.temp(:a0) == HEADS
      du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    else
      du.atk.is_damage_to_self = true
      du.deal_damage_to_all_benched_pokemon(10)
    end
    false
  end

  # Wildfire: discard a0 Fire energy cards (count chosen earlier)
  effect(:Wildfire_DiscardEnergyEffect) do |du|
    n = du.temp(:a0).to_i
    du.list_of_fire_energy_attached_to_arena.first(n).each { |i| du.turn_duelist.put_card_in_discard_pile(i) }
    false
  end

  effect(:Gigashock_BenchDamageEffect) do |du|
    du.as_non_turn { (du.temp(:list) || []).each { |e| du.deal_damage_to_play_area_pokemon(e, 10) } }; false
  end

  effects(:DragonairHyperBeam_DiscardEffect, :GolduckHyperBeam_DiscardEffect) do |du|
    du.discard_defending_energy_from_temp(true); false
  end
  effect(:Whirlpool_DiscardEffect) { |du| du.discard_defending_energy_from_temp(false); false }

  #----------------------------------------------------------------------------
  # trainers
  #----------------------------------------------------------------------------
  effect(:ComputerSearch_DiscardAddToHandEffect) do |du|
    d = du.turn_duelist
    l = du.temp(:list)
    l[0, 2].each { |i| d.remove_card_from_hand(i); d.put_card_in_discard_pile(i) }
    d.search_card_in_deck_and_add_to_hand(l[2])
    d.add_card_to_hand(l[2])
    du.shuffle_cards_in_deck; false
  end

  effect(:ItemFinder_PlayerSelection) do |du|
    next true if du.handle_selection_2_hand_cards(:DiscardHand, _INTL("Choose 2 cards from your hand to discard."))
    list = du.trainer_card_list_from_discard_pile
    l = du.temp(:list)
    l[2] = du.effect_choice(:card, :ItemFinder, list, false) || list.first
    du.set_temp(:list, l); false
  end

  # Recycle: chosen discard card goes on TOP of the deck
  effect(:Recycle_AddToHandEffect) do |du|
    i = (du.temp(:list) || [])[0]
    next false if i.nil?
    d = du.turn_duelist
    d.move_discard_pile_card_to_hand(i)
    d.return_card_to_deck(i)
    du.ui.message(_INTL("{1} was chosen.", d.card(i).name)) unless du.player_turn?
    false
  end

  effect(:Revive_PlayerSelection) do |du|
    du.ui.message(_INTL("Choose a Basic Pokémon to place on the Bench.")) if du.player_turn?
    list = du.basic_pokemon_from_discard_pile
    du.set_temp(:a0, du.effect_choice(:card, :Revive, list, false) || list.first); false
  end
  effect(:PokemonFlute_PlayerSelection) do |du|
    list = du.as_non_turn { du.basic_pokemon_from_discard_pile }
    du.set_temp(:a0, du.effect_choice(:card, :PokemonFlute, list, false) || list.first); false
  end
  effect(:PokemonTrader_PlayerHandSelection) do |du|
    du.ui.message(_INTL("Choose a card from your hand to switch.")) if du.player_turn?
    list = du.pokemon_cards_in_hand
    du.set_temp(:a0, du.effect_choice(:card, :PokemonTraderHand, list, false) || list.first); false
  end

  effect(:EnergySearch_AddToHandEffect) do |du|
    d = du.turn_duelist
    i = du.temp(:a0)
    if i
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      du.ui.message(_INTL("{1} was placed in the hand.", d.card(i).name)) unless du.player_turn?
    end
    du.shuffle_cards_in_deck; false
  end

  effect(:EnergyRemoval_DiscardEffect) do |du|
    du.as_non_turn { du.turn_duelist.put_card_in_discard_pile(du.temp(:a1)) }
    du.ui.refresh(du); false
  end

  effect(:DevolutionSpray_PlayAreaEvolutionCheck) do |du|
    du.has_evolved_cards? ? false : _INTL("There are no Stage 1 Pokémon.")
  end

  effect(:Defender_AttachDefenderEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:a0)
    d.put_hand_card_in_play_area(du.atk.card_index, e)
    d.slot_defender[e] += 1
    du.ui.refresh(du); false
  end

  effect(:GustOfWind_SwitchEffect) do |du|
    du.ui.event(:trainer_anim, :ATK_ANIM_GUST_OF_WIND)
    du.as_non_turn { du.turn_duelist.swap_arena_with_bench_pokemon(du.temp(:a0)) }
    du.clear_damage_reduction_substatus2(du.turn_duelist)
    du.ui.refresh(du); false
  end
end
