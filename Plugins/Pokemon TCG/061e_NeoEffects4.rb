#==============================================================================
# Pokemon TCG - effects of the fourth batch of custom cards (Neo, e-Card,
# Skyridge / Aquapolis Crystal cards, Shadow Lugia; data in 001b_NeoCards.rb).
# Attacks that work like an original one reuse its effect commands (Body
# Slam, Hypnosis, Lullaby, Stomp, Slam, Rage, Growl, Withdraw, Agility, Fly,
# Confuse Ray, Horn Hazard...); the new ones are here.
#
# Pokémon Powers (Poké-Powers / Poké-Bodies work as Pokémon Powers here):
#   menu      Moonlight (Clefable), Tailwind (Dragonite, from the Bench),
#             Gaze (Igglybuff), Glaring Gaze (Noctowl), Lolling About (Snorlax)
#   played    Softboiled (Blissey)
#   attaching Crystal Type (Celebi, Charizard, Ho-Oh, Lugia), Energy
#             Evolution (Eevee)
#   page only Gift (Light Togetic: no Pokémon Tool cards here), Spatial
#             Distortion (Dark Porygon2: no Stadium cards here)
# Trainers: Team Rocket's Evil Deeds, Energy Ark, Energy Removal 2, Fossil
# Egg, Professor Elm, Ruin Wall, Super Scoop Up.
#==============================================================================
module TCG
  def self.neo4_cmds(name, *pairs); EFFECT_TABLE["Neo4#{name}EffectCommands"] = pairs; end
  neo4_cmds "TwoCoins",          [EFFECT_BEFORE_DAMAGE, :Neo4TwoCoinsEffect], [EFFECT_AI, :Neo4TwoCoins_AIEffect]
  neo4_cmds "Recoil40",          [EFFECT_AFTER_DAMAGE, :Neo4Recoil40Effect]
  neo4_cmds "DiscardOwnEnergy",  [EFFECT_AFTER_DAMAGE, :Neo4DiscardOwnEnergyEffect]
  neo4_cmds "ScaldingSteam",     [EFFECT_BEFORE_DAMAGE, :NeoBurn50PercentEffect], [EFFECT_AFTER_DAMAGE, :Neo4DiscardOwnEnergyEffect]
  neo4_cmds "Squaredance",       [EFFECT_AFTER_DAMAGE, :Neo4SquaredanceEffect]
  neo4_cmds "MinorErrand",       [EFFECT_AFTER_DAMAGE, :Neo4MinorErrandEffect]
  neo4_cmds "Eeeeeeek",          [EFFECT_AFTER_DAMAGE, :Neo4EeeeeeekEffect]
  neo4_cmds "Present",           [EFFECT_BEFORE_DAMAGE, :Neo4Present_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo4Present_HealEffect], [EFFECT_AI, :Neo4Present_AIEffect]
  neo4_cmds "HealingLight",      [EFFECT_AFTER_DAMAGE, :Neo4HealingLightEffect]
  neo4_cmds "EmpathicHealing",   [EFFECT_AFTER_DAMAGE, :Neo4EmpathicHealingEffect]
  neo4_cmds "Nap",               [EFFECT_AFTER_DAMAGE, :Neo4NapEffect]
  neo4_cmds "MilkDrink",         [EFFECT_AFTER_DAMAGE, :Neo4MilkDrinkEffect]
  neo4_cmds "RagingCharge",      [EFFECT_BEFORE_DAMAGE, :FlareonRage_DamageBoostEffect], [EFFECT_AFTER_DAMAGE, :Neo4Recoil20Effect],
                                 [EFFECT_AI, :Neo4RagingCharge_AIEffect]
  neo4_cmds "EnergyTimes10",     [EFFECT_BEFORE_DAMAGE, :Neo4EnergyTimes10Effect], [EFFECT_AI, :Neo4EnergyTimes10Effect]
  neo4_cmds "ElementalBlast",    [EFFECT_INITIAL_EFFECT_1, :Neo4ElementalBlast_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo4ElementalBlastEffect]
  neo4_cmds "FlashingEyes",      [EFFECT_BEFORE_DAMAGE, :Neo4FlashingEyesEffect]
  neo4_cmds "SteelWing",         [EFFECT_BEFORE_DAMAGE, :Neo4SteelWingEffect]
  neo4_cmds "Headpress",         [EFFECT_BEFORE_DAMAGE, :Neo4HeadpressEffect], [EFFECT_AI, :Neo3HalfDamage_AIEffect]
  neo4_cmds "ContinuousTumble",  [EFFECT_BEFORE_DAMAGE, :Neo4ContinuousTumbleEffect], [EFFECT_AI, :Neo4ContinuousTumble_AIEffect]
  neo4_cmds "Roar",              [EFFECT_AFTER_DAMAGE, :Neo4RoarEffect]
  neo4_cmds "SweetKiss",         [EFFECT_AFTER_DAMAGE, :Neo4SweetKissEffect]
  neo4_cmds "Grab",              [EFFECT_AFTER_DAMAGE, :Neo4GrabEffect]
  neo4_cmds "Scout",             [EFFECT_AFTER_DAMAGE, :Neo4ScoutEffect]
  neo4_cmds "Sketch",            [EFFECT_INITIAL_EFFECT_1, :Neo4Sketch_CheckEffect], [EFFECT_INITIAL_EFFECT_2, :Neo4Sketch_CopyEffect]
  neo4_cmds "SuperMetronome",    [EFFECT_INITIAL_EFFECT_1, :ClefairyMetronome_CheckAttacks], [EFFECT_INITIAL_EFFECT_2, :Neo4SuperMetronomeEffect],
                                 [EFFECT_AI_SELECTION, :ClefairyMetronome_AISelectEffect]
  neo4_cmds "EvolutionSong",     [EFFECT_AFTER_DAMAGE, :Neo4EvolutionSongEffect]
  neo4_cmds "Softboiled",        [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :Neo4SoftboiledEffect]
  neo4_cmds "Moonlight",         [EFFECT_INITIAL_EFFECT_1, :Neo4Moonlight_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo4MoonlightEffect]
  neo4_cmds "Tailwind",          [EFFECT_INITIAL_EFFECT_1, :Neo4Tailwind_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo4TailwindEffect]
  neo4_cmds "Gaze",              [EFFECT_INITIAL_EFFECT_1, :Neo4Gaze_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo4GazeEffect]
  neo4_cmds "GlaringGaze",       [EFFECT_INITIAL_EFFECT_1, :Neo4GlaringGaze_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo4GlaringGazeEffect]
  neo4_cmds "LollingAbout",      [EFFECT_INITIAL_EFFECT_1, :Neo4LollingAbout_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo4LollingAboutEffect]
  # Trainers
  neo4_cmds "EvilDeeds",         [EFFECT_INITIAL_EFFECT_1, :Neo4EvilDeeds_HandCheck], [EFFECT_BEFORE_DAMAGE, :Neo4EvilDeedsEffect]
  neo4_cmds "EnergyArk",         [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_BEFORE_DAMAGE, :Neo4EnergyArkEffect]
  neo4_cmds "EnergyRemoval2",    [EFFECT_INITIAL_EFFECT_1, :EnergyRemoval_EnergyCheck], [EFFECT_INITIAL_EFFECT_2, :EnergyRemoval_PlayerSelection],
                                 [EFFECT_BEFORE_DAMAGE, :Neo4EnergyRemoval2Effect], [EFFECT_AI_SELECTION, :EnergyRemoval_AISelection]
  neo4_cmds "FossilEgg",         [EFFECT_INITIAL_EFFECT_1, :Neo4FossilEgg_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo4FossilEggEffect]
  neo4_cmds "ProfessorElm",      [EFFECT_BEFORE_DAMAGE, :Neo4ProfessorElmEffect]
  neo4_cmds "RuinWall",          [EFFECT_INITIAL_EFFECT_1, :Neo4RuinWall_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo4RuinWallEffect]
  neo4_cmds "SuperScoopUp",      [EFFECT_INITIAL_EFFECT_1, :ScoopUp_BenchCheck], [EFFECT_INITIAL_EFFECT_2, :ScoopUp_PlayerSelection],
                                 [EFFECT_BEFORE_DAMAGE, :Neo4SuperScoopUpEffect]

  { :Neo4Present_CoinEffect      => "1 Heads: 40 damage. 2: heal 30.\n3: 60 damage. 0: heal all.",
    :Neo4FlashingEyesEffect      => "1 Heads: Asleep. 2: Confused.\n3 Heads: Paralyzed.",
    :Neo4SteelWingEffect         => "If Heads, -20 damage during\nopponent's next turn.",
    :Neo4HeadpressEffect         => "If Heads, opponent is Paralyzed.\nIf Tails, no damage.",
    :Neo4ContinuousTumbleEffect  => "Damage check! Flip until Tails:\n+30 damage for each Heads!!",
    :Neo4MilkDrinkEffect         => "Flip 2 coins!\nHeal 20 for each Heads.",
    :Neo4RoarEffect              => "If Heads, the opponent\nswitches the Defending Pokémon.",
    :Neo4SoftboiledEffect        => "Heads: heal 80.\nTails: heal 40.",
    :Neo4GlaringGazeEffect       => "If Heads, look at the\nopponent's hand.",
    :Neo4SuperMetronomeEffect    => "If Heads, copy 1 of the\nopponent's attacks.",
    :Neo4EnergyArkEffect         => "Flip 2 coins! 1 basic Energy\nfrom the deck for each Heads.",
    :Neo4MinorErrandEffect       => "Flip 2 coins! 1 basic Energy\nfrom the deck for each Heads.",
    :Neo4SquaredanceEffect       => "1 coin for each Pokémon in play!\n1 basic Energy for each Heads.",
    :Neo4EnergyRemoval2Effect    => "If Heads, discard that\nEnergy card.",
    :Neo4FossilEggEffect         => "If Heads, a Mysterious Fossil\nevolution onto your Bench.",
    :Neo4SuperScoopUpEffect      => "If Heads, return that Pokémon\nand its cards to your hand." }.each { |fn, t| NEO_COIN_TEXT[fn] = t }

  # Crystal Type: basic Energy colors that change the card's color this turn
  NEO4_CRYSTAL_TYPE = { :CELEBI_LV30 => [GRASS, WATER, PSYCHIC], :CHARIZARD_NEO => [FIRE, LIGHTNING, FIGHTING],
                        :HO_OH_LV45 => [FIRE, WATER, LIGHTNING], :LUGIA_LV35 => [FIRE, WATER, PSYCHIC] }
  NEO4_FOSSIL = "Mysterious Fossil"

  class Duel
    # the last attack used (Sketch): [side, card, attack index, @duel_turns, cards in play on the other side]
    attr_accessor :neo4_last_attack

    alias_method :tcg_neo4_handle_duel_setup, :handle_duel_setup
    def handle_duel_setup
      @neo4_last_attack = nil
      tcg_neo4_handle_duel_setup
    end

    alias_method :tcg_neo4_use_attack_or_pokemon_power, :use_attack_or_pokemon_power
    def use_attack_or_pokemon_power
      d = turn_duelist
      nd = non_turn_duelist
      attack = !@atk.pokemon_power? && [d.arena, @atk.attack_index]
      in_play = (0...nd.num_in_play_area).map { |e| nd.play_area[e] }
      r = tcg_neo4_use_attack_or_pokemon_power
      @neo4_last_attack = [@turn, attack[0], attack[1], @duel_turns, in_play] if attack && attack[1]
      r
    end

    #--------------------------------------------------------------------------
    # helpers
    #--------------------------------------------------------------------------
    # remove up to n damage from the turn holder's slot e; returns the amount
    def neo4_heal(e, n, d = turn_duelist)
      return 0 if d.play_area[e].nil? || d.slot_hp[e] == 0
      n = [n, card_damage_and_max_hp(d, e)[0]].min
      return 0 if n <= 0
      d == turn_duelist ? heal_play_area_card_hp(e, n) : as_non_turn { heal_play_area_card_hp(e, n) }
      n
    end

    # the turn holder takes up to n basic Energy cards from the deck into the
    # hand (one pick each), then shuffles
    def neo4_search_basic_energy(n, purpose)
      d = turn_duelist
      got = 0
      n.times do
        list = d.deck_list.select { |i| d.card(i).basic_energy? }
        break if list.empty?
        i = neo_human_choice? ? effect_choice(:card, purpose, list, true) : list.first
        break unless list.include?(i)
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
        got += 1
      end
      @ui.message(_INTL("{1} basic Energy card(s) were put into the hand.", got)) if got > 0
      shuffle_cards_in_deck
      @ui.refresh(self)
      got
    end

    # shuffle the hand into the deck, draw n (Professor Elm, Eeeeeeek)
    def neo4_shuffle_hand_and_draw(n)
      d = turn_duelist
      d.hand.dup.each do |i|
        d.remove_card_from_hand(i)
        d.return_card_to_deck(i)
      end
      shuffle_cards_in_deck
      display_draw_n_cards(d, n, _INTL("Draw {1} cards.", n))
      n.times do
        i = d.draw_card_from_deck or break
        d.add_card_to_hand(i)
      end
      @ui.refresh(self)
    end

    # an Energy card attached to the turn holder's Active goes to the discard pile
    def neo4_discard_own_energy(purpose)
      d = turn_duelist
      list = d.energy_cards_in_slot(PLAY_AREA_ARENA)
      return if list.empty? || d.slot_hp[PLAY_AREA_ARENA] == 0
      i = neo_human_choice? ? effect_choice(:card, purpose, list, false) : nil
      i = list.first unless list.include?(i)
      d.put_card_in_discard_pile(i)
      @ui.message(_INTL("{1} was discarded.", d.card(i).name))
      @ui.refresh(self)
    end

    # duelist d's alive Pokemon a card in d's deck evolves from: { slot => [cards] }
    def neo4_evolutions_in_deck(d)
      (0...d.num_in_play_area).each_with_object({}) do |e, h|
        next if d.slot_hp[e] == 0
        name = d.card(d.play_area[e]).name
        list = d.deck_list.select { |i| d.card(i).pokemon? && d.card(i).preevo == name }
        h[e] = list unless list.empty?
      end
    end

    # card i from the turn holder's deck evolves slot e
    def neo4_evolve_from_deck(i, e)
      d = turn_duelist
      old = d.card(d.play_area[e]).name
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      d.evolve_pokemon_card(i, e)
      @ui.event(:evolve, d.name, i, e)
      @ui.message(_INTL("{1} evolved into {2}!", old, d.card(i).name))
      @ui.refresh(self)
    end

    # the attacker's player picks from the opponent's side (the list shows
    # the opponent's cards / play area, the choice stays with the attacker)
    def neo4_pick_on_opponent_side(kind, purpose, options, cancellable = false)
      ctrl = @controllers[@whose_turn || @turn]
      as_non_turn { ctrl.effect_choice(self, kind, purpose, options, cancellable) }
    end

    # the turn holder's player sees the opponent's hand and may pick a card
    # (nil: just looked); the AI picks the first card `pick` accepts
    def neo4_look_at_opponent_hand(purpose, pick = nil)
      nd = non_turn_duelist
      return nil if nd.hand.empty?
      list = pick ? nd.hand.select { |i| pick.call(nd.card(i)) } : nd.hand.dup
      if neo_human_choice?
        sel = neo4_pick_on_opponent_side(:card, purpose, nd.hand.dup, true)
        return list.include?(sel) ? sel : nil
      end
      pick ? list.first : nil
    end

    # card i of the opponent's hand is shuffled into the opponent's deck
    def neo4_shuffle_opponent_hand_card(i)
      nd = non_turn_duelist
      nd.remove_card_from_hand(i)
      nd.return_card_to_deck(i)
      as_non_turn { shuffle_cards_in_deck }
      @ui.message(_INTL("{1} was shuffled into the opponent's deck.", nd.card(i).name))
      @ui.refresh(self)
    end

    #--------------------------------------------------------------------------
    # Crystal Type / Energy Evolution: attaching basic Energy from the hand
    #--------------------------------------------------------------------------
    alias_method :tcg_neo4_play_energy_card, :play_energy_card
    def play_energy_card(idx, e)
      r = tcg_neo4_play_energy_card(idx, e)
      return r unless r == :ok
      d = turn_duelist
      target = d.play_area[e]
      c = d.card(idx)
      return r unless target && c.basic_energy? && neo_power_works?(d, e)
      colors = NEO4_CRYSTAL_TYPE[d.card_id(target)]
      if colors && colors.include?(c.color)
        d.slot_changed_type[e] = HAS_CHANGED_COLOR | c.color
        neo_fx[:crystal_type] = [@turn, target, @duel_turns]
        @ui.message(_INTL("{1}'s Pokémon Power: Crystal Type", d.card(target).name))
        @ui.refresh(self)
      end
      neo4_energy_evolution(e, c.color) if d.card_id(target) == :EEVEE_NEO
      r
    end

    def neo4_energy_evolution(e, color)
      d = turn_duelist
      @ui.message(_INTL("Eevee's Pokémon Power: Energy Evolution"))
      coin_check(_INTL("Energy Evolution! If Heads, Eevee evolves from your deck."), "If Heads, Eevee evolves into\nthat Energy's type!")
      return unless toss_coin == HEADS
      list = d.deck_list.select { |i| d.card(i).pokemon? && d.card(i).preevo == "Eevee" && d.card(i).color == color }
      if list.empty?
        @ui.message(_INTL("There is no card of that type that evolves from Eevee in the deck."))
      else
        i = neo_human_choice? ? effect_choice(:card, :NeoEnergyEvolution, list, false) : nil
        i = list.first unless list.include?(i)
        neo4_evolve_from_deck(i, e)
      end
      shuffle_cards_in_deck
    end

    #--------------------------------------------------------------------------
    # Gaze: a Benched Pokemon's power stops working this turn
    #--------------------------------------------------------------------------
    alias_method :tcg_neo4_incapable_of_using_pkmn_power?, :incapable_of_using_pkmn_power?
    def incapable_of_using_pkmn_power?(d, e)
      return true if e != PLAY_AREA_ARENA && d.play_area[e] && neo_fx_active?(:gaze, side_of(d), d.play_area[e])
      tcg_neo4_incapable_of_using_pkmn_power?(d, e)
    end

    #--------------------------------------------------------------------------
    # Tailwind: the Active's Retreat Cost is 0 this turn
    #--------------------------------------------------------------------------
    alias_method :tcg_neo4_retreat_cost, :retreat_cost
    def retreat_cost(d, e = PLAY_AREA_ARENA)
      return 0 if e == PLAY_AREA_ARENA && d.play_area[e] && neo_fx_active?(:tailwind, side_of(d), d.play_area[e])
      tcg_neo4_retreat_cost(d, e)
    end

    #--------------------------------------------------------------------------
    # Professor Elm: no more Trainer cards this turn
    #--------------------------------------------------------------------------
    alias_method :tcg_neo4_cant_use_trainer_due_to_effect?, :cant_use_trainer_due_to_effect?
    def cant_use_trainer_due_to_effect?(d)
      return true if neo_fx_active?(:elm, side_of(d))
      tcg_neo4_cant_use_trainer_due_to_effect?(d)
    end

    alias_method :tcg_neo4_play_trainer_card, :play_trainer_card
    def play_trainer_card(idx)
      return :neo_elm if neo_fx_active?(:elm, @turn)
      tcg_neo4_play_trainer_card(idx)
    end
  end

  #----------------------------------------------------------------------------
  # damage
  #----------------------------------------------------------------------------
  # flip 2 coins: the printed damage times the number of heads
  effect(:Neo4TwoCoinsEffect) do |du|
    n = du.atk.attack.damage
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", n), "Damage check!\nIf Heads, x #{n} damage!!")
    du.set_definite_damage(n * du.toss_coins(2)); false
  end
  effect(:Neo4TwoCoins_AIEffect) { |du| n = du.atk.attack.damage; du.set_expected_ai_damage(n, 0, 2 * n); false }
  effect(:Neo4Recoil40Effect) { |du| du.deal_recoil_damage_to_self(40); false }
  effect(:Neo4Recoil20Effect) { |du| du.deal_recoil_damage_to_self(20); false }
  effect(:Neo4RagingCharge_AIEffect) { |du| n = 10 + du.arena_damage; du.set_expected_ai_damage(n, n, n); false }
  effect(:Neo4DiscardOwnEnergyEffect) { |du| du.neo4_discard_own_energy(:NeoDiscardEnergy); false }

  # Lugia (Crystal): 10 x the Energy cards on the Defending Pokemon
  effect(:Neo4EnergyTimes10Effect) do |du|
    nd = du.non_turn_duelist
    du.set_definite_damage(nd.arena ? 10 * nd.energy_cards_in_slot(PLAY_AREA_ARENA).size : 0); false
  end

  # Lugia: discard a Fire, a Water and a Lightning Energy card
  NEO4_ELEMENTAL = [:FIRE_ENERGY, :WATER_ENERGY, :LIGHTNING_ENERGY]
  effect(:Neo4ElementalBlast_CheckEffect) do |du|
    d = du.turn_duelist
    NEO4_ELEMENTAL.all? { |id| !du.neo3_attached(d, PLAY_AREA_ARENA, id).empty? } ? false :
      _INTL("Needs a Fire, a Water and a Lightning Energy card attached.")
  end
  effect(:Neo4ElementalBlastEffect) do |du|
    d = du.turn_duelist
    next false if d.slot_hp[PLAY_AREA_ARENA] == 0
    NEO4_ELEMENTAL.each { |id| (i = du.neo3_attached(d, PLAY_AREA_ARENA, id).first) && d.put_card_in_discard_pile(i) }
    du.ui.message(_INTL("A Fire, a Water and a Lightning Energy card were discarded."))
    du.ui.refresh(du); false
  end

  # Delibird: 3 coins
  effect(:Neo4Present_CoinEffect) do |du|
    du.coin_check(_INTL("Present! 1 Heads: 40 damage. 2: remove 3 damage counters. 3: 60 damage. 0: remove all."),
                  NEO_COIN_TEXT[:Neo4Present_CoinEffect])
    heads = du.toss_coins(3)
    du.set_temp(:present, heads)
    du.set_definite_damage({ 1 => 40, 3 => 60 }[heads] || 0)
    false
  end
  effect(:Neo4Present_HealEffect) do |du|
    heads = du.temp(:present)
    next false unless [0, 2].include?(heads)
    nd = du.non_turn_duelist
    next false if nd.arena.nil?
    n = du.neo4_heal(PLAY_AREA_ARENA, heads == 2 ? 30 : 9999, nd)
    du.ui.message(_INTL("No damage counters were removed.")) if n == 0
    false
  end
  effect(:Neo4Present_AIEffect) { |du| du.set_expected_ai_damage(22, 0, 60); false }

  # Shining Noctowl: 3 coins
  effect(:Neo4FlashingEyesEffect) do |du|
    du.coin_check(_INTL("Flashing Eyes! 1 Heads: Asleep. 2 Heads: Confused. 3 Heads: Paralyzed."), NEO_COIN_TEXT[:Neo4FlashingEyesEffect])
    case du.toss_coins(3)
    when 1 then du.queue_status(PSN_DBLPSN, ASLEEP)
    when 2 then du.queue_status(PSN_DBLPSN, CONFUSED)
    when 3 then du.queue_status(PSN_DBLPSN, PARALYZED)
    end
    false
  end

  # Skarmory: -20 damage during the opponent's next turn (after Weakness / Resistance)
  effect(:Neo4SteelWingEffect) do |du|
    du.coin_check(_INTL("Steel Wing! If Heads, damage to Skarmory is reduced by 20 during your opponent's next turn."),
                  NEO_COIN_TEXT[:Neo4SteelWingEffect])
    du.apply_substatus1_to_attacking_card(SUBSTATUS1_REDUCE_BY_20) if du.toss_coin == HEADS
    false
  end

  # Ursaring: heads Paralyzed, tails nothing
  effect(:Neo4HeadpressEffect) do |du|
    du.coin_check(_INTL("Headpress! If Heads, the Defending Pokémon is Paralyzed. If Tails, this attack does nothing."),
                  NEO_COIN_TEXT[:Neo4HeadpressEffect])
    if du.toss_coin == HEADS
      du.queue_status(PSN_DBLPSN, PARALYZED)
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end

  # Snorlax: flip until tails (at most 20 coins)
  effect(:Neo4ContinuousTumbleEffect) do |du|
    du.coin_check(_INTL("Continuous Tumble! Flip until Tails: 30 damage for each Heads."), NEO_COIN_TEXT[:Neo4ContinuousTumbleEffect])
    heads = 0
    heads += 1 while heads < 20 && du.toss_coin == HEADS
    du.ui.message(_INTL("{1} Heads!", heads))
    du.set_definite_damage(30 * heads); false
  end
  effect(:Neo4ContinuousTumble_AIEffect) { |du| du.set_expected_ai_damage(30, 0, 90); false }

  #----------------------------------------------------------------------------
  # healing
  #----------------------------------------------------------------------------
  effect(:Neo4HealingLightEffect) do |du|
    d = du.turn_duelist
    n = (0...d.num_in_play_area).count { |e| du.neo4_heal(e, 10) > 0 }
    du.ui.message(_INTL("None of your Pokémon have damage counters.")) if n == 0
    du.ui.refresh(du); false
  end
  # Celebi: 2 damage counters from Celebi and each Pokemon of its color
  effect(:Neo4EmpathicHealingEffect) do |du|
    d = du.turn_duelist
    color = du.play_area_card_color(d, PLAY_AREA_ARENA)
    n = (0...d.num_in_play_area).count { |e| du.play_area_card_color(d, e) == color && du.neo4_heal(e, 20) > 0 }
    du.ui.message(_INTL("None of those Pokémon have damage counters.")) if n == 0
    du.ui.refresh(du); false
  end
  effect(:Neo4NapEffect) do |du|
    du.ui.message(_INTL("There are no damage counters.")) if du.neo4_heal(PLAY_AREA_ARENA, 10) == 0
    du.ui.refresh(du); false
  end
  effect(:Neo4MilkDrinkEffect) do |du|
    du.coin_check(_INTL("Milk Drink! Remove 2 damage counters for each Heads."), NEO_COIN_TEXT[:Neo4MilkDrinkEffect])
    heads = du.toss_coins(2)
    du.neo4_heal(PLAY_AREA_ARENA, 20 * heads) if heads > 0
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # deck / hand
  #----------------------------------------------------------------------------
  effect(:Neo4MinorErrandEffect) do |du|
    du.coin_check(_INTL("Flip 2 coins: 1 basic Energy card from your deck for each Heads."), NEO_COIN_TEXT[:Neo4MinorErrandEffect])
    heads = du.toss_coins(2)
    du.neo4_search_basic_energy(heads, :NeoEnergySearch) if heads > 0
    false
  end
  effect(:Neo4SquaredanceEffect) do |du|
    n = du.duelists.sum { |x| (0...x.num_in_play_area).count { |e| x.slot_hp[e] > 0 } }
    du.coin_check(_INTL("Squaredance! Flip {1} coins: 1 basic Energy card from your deck for each Heads.", n),
                  NEO_COIN_TEXT[:Neo4SquaredanceEffect])
    heads = du.toss_coins(n)
    du.neo4_search_basic_energy(heads, :NeoEnergySearch) if heads > 0
    false
  end
  effect(:Neo4EeeeeeekEffect) { |du| du.neo4_shuffle_hand_and_draw(7); false }

  # Light Togetic: the opponent may draw a card
  effect(:Neo4SweetKissEffect) do |du|
    nd = du.non_turn_duelist
    ctrl = du.controllers[1 - du.turn]
    draw = ctrl.is_a?(PlayerController) ? ctrl.effect_choice(du, :yes_no, :NeoSweetKiss, [true, false], false) : nd.hand.size < 7
    if draw && (i = nd.draw_card_from_deck)
      nd.add_card_to_hand(i)
      du.ui.message(_INTL("Your opponent drew a card."))
    end
    du.ui.refresh(du); false
  end

  # Sentret: look at the opponent's hand
  effect(:Neo4ScoutEffect) do |du|
    if du.non_turn_duelist.hand.empty?
      du.ui.message(_INTL("Your opponent has no cards in hand."))
    else
      du.neo4_look_at_opponent_hand(:NeoScout)
    end
    false
  end

  # Aipom: a PlusPower / Defender on the opponent's Pokemon goes into their deck
  effect(:Neo4GrabEffect) do |du|
    nd = du.non_turn_duelist
    list = (0...nd.num_in_play_area).flat_map { |e| nd.cards_in_slot(e).select { |i| nd.card(i).trainer? } }
    if list.empty?
      du.ui.message(_INTL("No Trainer cards are attached to your opponent's Pokémon."))
      next false
    end
    i = du.neo_human_choice? ? du.neo4_pick_on_opponent_side(:card, :NeoGrab, list) : nil
    i = list.first unless list.include?(i)
    e = nd.card_locations[i] & ~CARD_LOCATION_PLAY_AREA
    case nd.card_id(i)
    when :DEFENDER  then nd.slot_defender[e] = [nd.slot_defender[e] - 1, 0].max
    when :PLUSPOWER then nd.slot_pluspower[e] = [nd.slot_pluspower[e] - 1, 0].max
    end
    nd.return_card_to_deck(i)
    du.as_non_turn { du.shuffle_cards_in_deck }
    du.ui.message(_INTL("{1} was shuffled into the opponent's deck.", nd.card(i).name))
    du.ui.refresh(du); false
  end

  # Snubbull: heads, the opponent switches its Active (they choose)
  effect(:Neo4RoarEffect) do |du|
    next false if du.neo_alive_bench(du.non_turn_duelist).empty?
    du.coin_check(_INTL("Roar! If Heads, your opponent switches the Defending Pokémon."), NEO_COIN_TEXT[:Neo4RoarEffect])
    du.neo_forced_switch if du.toss_coin == HEADS
    false
  end

  # Light Wigglytuff: the opponent, then the attacker, may evolve 1 Pokemon from the deck
  effect(:Neo4EvolutionSongEffect) do |du|
    [1 - du.turn, du.turn].each do |side|
      run = lambda do
        d = du.turn_duelist
        evo = du.neo4_evolutions_in_deck(d)
        next if evo.empty?
        ctrl = du.controllers[side]
        human = ctrl.is_a?(PlayerController)
        prompt = side == du.turn ? :NeoEvolutionSong : :NeoEvolutionSongOpp
        next unless human ? ctrl.effect_choice(du, :yes_no, prompt, [true, false], false) : true
        e = human ? ctrl.effect_choice(du, :play_area, :NeoEvolutionSong, evo.keys, false) : evo.keys.first
        e = evo.keys.first unless evo.key?(e)
        i = human ? ctrl.effect_choice(du, :card, :NeoEvolutionSong, evo[e], false) : evo[e].first
        i = evo[e].first unless evo[e].include?(i)
        du.neo4_evolve_from_deck(i, e)
        du.shuffle_cards_in_deck
      end
      side == du.turn ? run.call : du.as_non_turn { run.call }
    end
    false
  end

  #----------------------------------------------------------------------------
  # copying attacks
  #----------------------------------------------------------------------------
  # Smeargle: the attack the Defending Pokemon used last turn while Smeargle was in play
  effect(:Neo4Sketch_CheckEffect) do |du|
    la = du.neo4_last_attack
    nd = du.non_turn_duelist
    ok = la && la[0] == 1 - du.turn && la[3] == du.duel_turns - 1 && la[1] == nd.arena &&
         la[4].include?(du.turn_duelist.arena) && nd.card(la[1]).attacks[la[2]]
    ok ? false : _INTL("The Defending Pokémon didn't attack Smeargle's side last turn.")
  end
  effect(:Neo4Sketch_CopyEffect) do |du|
    la = du.neo4_last_attack
    nd = du.non_turn_duelist
    copied = nd.card(la[1]).attacks[la[2]]
    next true if copied.name == du.atk.attack.name
    du.ui.message(_INTL("Smeargle sketched {1}!", copied.name))
    du.atk.attack      = copied
    du.atk.effect_name = copied.effect
    du.atk.damage      = copied.damage
    du.atk.card_id     = nd.card_id(la[1])
    next true if du.try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
    next true if du.try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
    false
  end

  # Togetic: heads, copy an attack of the Defending Pokemon; tails, nothing
  effect(:Neo4SuperMetronomeEffect) do |du|
    du.coin_check(_INTL("Super Metronome! If Heads, copy 1 of your opponent's attacks."), NEO_COIN_TEXT[:Neo4SuperMetronomeEffect])
    if du.toss_coin == TAILS
      du.ui.message(_INTL("Super Metronome did nothing."))
      du.set_definite_damage(0)
      du.set_was_unsuccessful
      next false
    end
    du.handle_metronome(1)
  end

  #----------------------------------------------------------------------------
  # Pokemon Powers
  #----------------------------------------------------------------------------
  # Blissey, when played: heads 8 damage counters off, tails 4
  effect(:Neo4SoftboiledEffect) do |du|
    e = du.power_slot
    next false if du.card_damage_and_max_hp(du.turn_duelist, e)[0] == 0
    du.coin_check(_INTL("Softboiled! Heads: remove 8 damage counters. Tails: remove 4."), NEO_COIN_TEXT[:Neo4SoftboiledEffect])
    du.neo4_heal(e, du.toss_coin == HEADS ? 80 : 40)
    du.ui.refresh(du); false
  end

  # once per turn, any slot (a String = why not)
  NEO4_ONCE = lambda do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end
  def self.neo4_power_used(du)
    du.turn_duelist.slot_flags[du.temp(:a0) || PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
  end

  # Clefable: a hand card on top of the deck, then a basic Energy from the deck
  effect(:Neo4Moonlight_CheckUse) do |du|
    r = NEO4_ONCE.call(du)
    next r if r
    d = du.turn_duelist
    next _INTL("Not while affected by a Special Condition.") if du.temp(:a0) == PLAY_AREA_ARENA && d.status != NO_STATUS
    next _INTL("There are no cards in your hand.") if d.hand.empty?
    d.deck_list.any? { |i| d.card(i).basic_energy? } ? false : _INTL("There are no basic Energy cards in the deck.")
  end
  effect(:Neo4MoonlightEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    list = d.hand.dup
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoMoonlight, list, false) : nil
    i = list.min_by { |k| d.card(k).energy? ? 1 : 0 } unless list.include?(i)
    d.remove_card_from_hand(i)
    d.return_card_to_deck(i)
    du.ui.message(_INTL("A card was put back on top of the deck."))
    du.neo4_search_basic_energy(1, :NeoEnergySearch)
    false
  end

  # Dragonite on the Bench: the Active's Retreat Cost is 0 this turn
  effect(:Neo4Tailwind_CheckUse) do |du|
    r = NEO4_ONCE.call(du)
    next r if r
    du.temp(:a0) == PLAY_AREA_ARENA ? _INTL("Only while Dragonite is on your Bench.") : false
  end
  effect(:Neo4TailwindEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    du.neo_fx[:tailwind] = [du.turn, d.arena, du.duel_turns]
    du.ui.message(_INTL("{1}'s Retreat Cost is 0 this turn.", d.card(d.arena).name))
    false
  end

  # Igglybuff: an opponent's Benched Pokemon's power stops working this turn
  def self.neo4_gaze_targets(du)
    nd = du.non_turn_duelist
    du.neo_alive_bench(nd).select { |e| nd.card(nd.play_area[e]).has_pkmn_power? }
  end
  effect(:Neo4Gaze_CheckUse) do |du|
    r = NEO4_ONCE.call(du)
    next r if r
    TCG.neo4_gaze_targets(du).empty? ? _INTL("Your opponent has no Benched Pokémon with a Pokémon Power.") : false
  end
  effect(:Neo4GazeEffect) do |du|
    TCG.neo4_power_used(du)
    nd = du.non_turn_duelist
    slots = TCG.neo4_gaze_targets(du)
    e = du.neo_human_choice? ? du.neo4_pick_on_opponent_side(:play_area, :NeoGaze, slots) : nil
    e = slots.first unless slots.include?(e)
    du.neo_fx[:gaze] = [1 - du.turn, nd.play_area[e], du.duel_turns]
    du.ui.message(_INTL("{1}'s Pokémon Power stops working this turn.", nd.card(nd.play_area[e]).name))
    false
  end

  # Noctowl: heads, a Trainer card from the opponent's hand into their deck
  effect(:Neo4GlaringGaze_CheckUse) { |du| NEO4_ONCE.call(du) }
  effect(:Neo4GlaringGazeEffect) do |du|
    TCG.neo4_power_used(du)
    du.coin_check(_INTL("Glaring Gaze! If Heads, look at your opponent's hand."), NEO_COIN_TEXT[:Neo4GlaringGazeEffect])
    next false unless du.toss_coin == HEADS
    nd = du.non_turn_duelist
    if nd.hand.empty?
      du.ui.message(_INTL("Your opponent has no cards in hand."))
      next false
    end
    i = du.neo4_look_at_opponent_hand(:NeoGlaringGaze, ->(c) { c.trainer? })
    if i
      du.neo4_shuffle_opponent_hand_card(i)
    elsif nd.hand.none? { |k| nd.card(k).trainer? }
      du.ui.message(_INTL("Your opponent has no Trainer cards in hand."))
    end
    false
  end

  # Snorlax: Active, no Special Condition: 1 damage counter off, then Asleep
  effect(:Neo4LollingAbout_CheckUse) do |du|
    r = NEO4_ONCE.call(du)
    next r if r
    next _INTL("Only while it is your Active Pokémon.") if du.temp(:a0) != PLAY_AREA_ARENA
    du.turn_duelist.status != NO_STATUS ? _INTL("Not while affected by a Special Condition.") : false
  end
  effect(:Neo4LollingAboutEffect) do |du|
    TCG.neo4_power_used(du)
    d = du.turn_duelist
    du.neo4_heal(PLAY_AREA_ARENA, 10)
    d.status = ASLEEP
    du.ui.message(_INTL("{1} is now Asleep.", d.card(d.arena).name))
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Trainers
  #----------------------------------------------------------------------------
  effect(:Neo4EvilDeeds_HandCheck) do |du|
    du.non_turn_duelist.hand.empty? ? _INTL("Your opponent has no cards in hand.") : false
  end
  effect(:Neo4EvilDeedsEffect) do |du|
    nd = du.non_turn_duelist
    i = du.neo4_look_at_opponent_hand(:NeoEvilDeeds, ->(c) { true })
    i ||= nd.hand.first
    du.neo4_shuffle_opponent_hand_card(i)
    ctrl = du.controllers[1 - du.turn]
    draw = ctrl.is_a?(PlayerController) ? ctrl.effect_choice(du, :yes_no, :NeoEvilDeedsDraw, [true, false], false) : true
    if draw
      n = 0
      2.times { (k = nd.draw_card_from_deck) && nd.add_card_to_hand(k) && (n += 1) }
      du.ui.message(_INTL("Your opponent drew {1} card(s).", n))
    end
    du.ui.refresh(du); false
  end

  effect(:Neo4EnergyArkEffect) do |du|
    du.coin_check(_INTL("Flip 2 coins: 1 basic Energy card from your deck for each Heads."), NEO_COIN_TEXT[:Neo4EnergyArkEffect])
    heads = du.toss_coins(2)
    heads > 0 ? du.neo4_search_basic_energy(heads, :NeoEnergySearch) : du.ui.message(_INTL("No Energy cards were found."))
    false
  end

  effect(:Neo4EnergyRemoval2Effect) do |du|
    du.coin_check(_INTL("If Heads, discard that Energy card."), NEO_COIN_TEXT[:Neo4EnergyRemoval2Effect])
    if du.toss_coin == HEADS
      EffectFunctions[:EnergyRemoval_DiscardEffect].call(du)
    else
      du.ui.message(_INTL("Energy Removal 2 did nothing."))
    end
    false
  end

  def self.neo4_fossil_cards(d)
    (d.hand + d.deck_list).select { |i| d.card(i).pokemon? && d.card(i).preevo == NEO4_FOSSIL }
  end
  effect(:Neo4FossilEgg_CheckEffect) do |du|
    d = du.turn_duelist
    next du.no_bench_space_text if du.no_bench_space_text
    TCG.neo4_fossil_cards(d).empty? ? _INTL("No card that evolves from Mysterious Fossil.") : false
  end
  effect(:Neo4FossilEggEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("If Heads, put a card that evolves from Mysterious Fossil onto your Bench."), NEO_COIN_TEXT[:Neo4FossilEggEffect])
    unless du.toss_coin == HEADS
      du.ui.message(_INTL("Fossil Egg did nothing."))
      next false
    end
    list = TCG.neo4_fossil_cards(d)
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoFossilEgg, list, false) : nil
    i = list.first unless list.include?(i)
    from_deck = d.deck_list.include?(i)
    if from_deck
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
    end
    e = du.put_basic_pokemon_in_play_area(i)
    d.slot_stage[e] = BASIC if e
    du.ui.message(_INTL("{1} was put onto the Bench.", d.card(i).name))
    du.shuffle_cards_in_deck if from_deck
    du.ui.refresh(du); false
  end

  effect(:Neo4ProfessorElmEffect) do |du|
    du.neo4_shuffle_hand_and_draw(7)
    du.neo_fx[:elm] = [du.turn, nil, du.duel_turns]
    false
  end

  def self.neo4_unown(d); d.deck_list.select { |i| d.card(i).pokemon? && d.card(i).basic? && d.card(i).name.start_with?("Unown") }; end
  effect(:Neo4RuinWall_CheckEffect) do |du|
    next du.no_bench_space_text if du.no_bench_space_text
    TCG.neo4_unown(du.turn_duelist).empty? ? _INTL("There is no Unown in the deck.") : false
  end
  effect(:Neo4RuinWallEffect) do |du|
    d = du.turn_duelist
    list = TCG.neo4_unown(d)
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoRuinWall, list, false) : nil
    i = list.first unless list.include?(i)
    d.search_card_in_deck_and_add_to_hand(i)
    d.add_card_to_hand(i)
    e = du.put_basic_pokemon_in_play_area(i)
    d.slot_stage[e] = BASIC if e
    du.ui.message(_INTL("{1} was put onto the Bench.", d.card(i).name))
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end

  # heads: the picked Pokemon and every card attached to it go to the hand
  effect(:Neo4SuperScoopUpEffect) do |du|
    du.coin_check(_INTL("If Heads, return that Pokémon and all cards attached to it to your hand."), NEO_COIN_TEXT[:Neo4SuperScoopUpEffect])
    unless du.toss_coin == HEADS
      du.ui.message(_INTL("Super Scoop Up did nothing."))
      next false
    end
    d = du.turn_duelist
    e = du.temp(:a0)
    name = d.card(d.play_area[e]).name
    d.cards_in_slot(e).each { |i| d.add_card_to_hand(i) }
    d.empty_play_area_slot(e)
    d.clear_all_status_conditions if e == PLAY_AREA_ARENA
    d.swap_play_area_pokemon(du.temp(:a1), PLAY_AREA_ARENA) if e == PLAY_AREA_ARENA && du.temp(:a1)
    du.duelists.each(&:shift_pokemon_to_first_play_area_slots)
    du.ui.message(_INTL("{1} and its cards were returned to the hand.", name))
    du.ui.refresh(du); false
  end
end
