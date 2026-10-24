#==============================================================================
# Pokemon TCG - effects of the custom cards (001b_NeoCards.rb). Attacks that
# work like an original one reuse its effect commands (Leech Seed, Kakuna's
# Poisonpowder, Lullaby, Snorlax's Body Slam); the new ones are here.
#==============================================================================
module TCG
  SUBSTATUS1_POLLEN_SHIELD = 0x30   # unused by the original

  EFFECT_TABLE["BayleefPollenShieldEffectCommands"]   = [[EFFECT_BEFORE_DAMAGE, :PollenShieldEffect]]
  EFFECT_TABLE["MeganiumSoothingScentEffectCommands"] = [[EFFECT_BEFORE_DAMAGE, :ConfusionEffect]]
  EFFECT_TABLE["MeganiumWildGrowthEffectCommands"]    = [[EFFECT_INITIAL_EFFECT_1, :WildGrowthEffect]]
  EFFECT_TABLE["MeganiumHerbalScentEffectCommands"]   = [[EFFECT_INITIAL_EFFECT_1, :HerbalScentCheckUse],
                                                          [EFFECT_PKMN_POWER_TRIGGER, :HerbalScentEffect]]
  EFFECT_TABLE["IvysaurStrangeScentEffectCommands"]   = [[EFFECT_AFTER_DAMAGE, :StrangeScentEffect]]
  EFFECT_TABLE["VenusaurHarvestBountyEffectCommands"] = [[EFFECT_INITIAL_EFFECT_1, :HarvestBountyEffect]]

  class Duel
    # Pollen Shield: the protected Pokemon can't get a new status condition
    # from the opponent's attacks ("No effect" like Snorlax's Thick Skinned)
    alias_method :tcg_neo_queue_status, :queue_status
    def queue_status(keep_mask, status)
      if @turn == @whose_turn && non_turn_duelist.substatus1 == SUBSTATUS1_POLLEN_SHIELD
        @atk.temp[:no_effect_from_which_status] = status
        set_no_effect_from_status
        return false
      end
      tcg_neo_queue_status(keep_mask, status)
    end

    # Wild Growth: an active Meganium Lv40 makes every basic Grass Energy
    # card attached to its owner's Pokemon count as 2 Grass for attacks
    def wild_growth_active?(d)
      return false if toxic_gas_active?
      count_pokemon_with_active_pkmn_power(d, :MEGANIUM_LV40) > 0
    end

    alias_method :tcg_neo_attached_energies_with_energy_burn, :attached_energies_with_energy_burn
    def attached_energies_with_energy_burn(d, e)
      en, total = tcg_neo_attached_energies_with_energy_burn(d, e)
      return [en, total] unless wild_growth_active?(d)
      extra = d.cards_in_slot(e).count { |i| d.card_id(i) == :GRASS_ENERGY }
      return [en, total] if extra == 0 || en[GRASS] == 0   # Energy Burn turned it all to Fire
      en = en.dup
      en[GRASS] += extra
      [en, total + extra]
    end

    #--------------------------------------------------------------------------
    # Harvest Bounty (Venusaur, Expedition): after attaching the turn's Energy
    # card to the Active Pokemon, 1 more Energy card may go to it, once a turn
    #--------------------------------------------------------------------------
    attr_reader :energy_to_arena_this_turn, :harvest_bounty_used

    alias_method :tcg_neo_init_variables_to_begin_turn, :init_variables_to_begin_turn
    def init_variables_to_begin_turn
      tcg_neo_init_variables_to_begin_turn
      @energy_to_arena_this_turn = false
      @harvest_bounty_used = false
    end

    # a Venusaur with Harvest Bounty that isn't Asleep, Confused, Paralyzed
    # or Poisoned (benched Pokemon have no conditions)
    def harvest_bounty_active?(d)
      return false if toxic_gas_active?
      d.play_area.each_with_index.any? do |idx, e|
        next false unless idx && d.card_id(idx) == :VENUSAUR_NEO
        e != PLAY_AREA_ARENA || d.status == NO_STATUS
      end
    end

    def harvest_bounty_available?(d = turn_duelist)
      @already_played_energy && @energy_to_arena_this_turn && !@harvest_bounty_used &&
        harvest_bounty_active?(d)
    end

    alias_method :tcg_neo_can_play_energy?, :can_play_energy?
    def can_play_energy?(idx, e)
      return true if e == PLAY_AREA_ARENA && harvest_bounty_available?
      tcg_neo_can_play_energy?(idx, e)
    end

    alias_method :tcg_neo_play_energy_card, :play_energy_card
    def play_energy_card(idx, e)
      d = turn_duelist
      bounty = e == PLAY_AREA_ARENA && harvest_bounty_available?(d)
      first = !@already_played_energy
      r = tcg_neo_play_energy_card(idx, e)
      return r unless r == :ok
      if bounty
        @harvest_bounty_used = true
        @ui.message(_INTL("{1}'s Pokémon Power: Harvest Bounty", TCG.card(:VENUSAUR_NEO).name))
      elsif first && @already_played_energy
        @energy_to_arena_this_turn = (e == PLAY_AREA_ARENA)
      end
      r
    end

    # Strange Scent: duelist `side` removes up to 3 damage counters from its
    # own Pokemon, one at a time; the player picks on the play area screen
    # (shown for their own side), the AI takes the most damaged Pokemon
    def strange_scent_heal(side)
      d = @duelists[side]
      ctrl = @controllers[side]
      3.times do
        slots = (0...d.num_in_play_area).select { |e| card_damage_and_max_hp(d, e)[0] > 0 }
        break if slots.empty?
        tgt = nil
        if ctrl.is_a?(PlayerController)
          pick = -> { tgt = ctrl.effect_choice(self, :play_area, :StrangeScent, slots, false) }
          side == @turn ? pick.call : as_non_turn(&pick)
        end
        tgt = slots.max_by { |e| card_damage_and_max_hp(d, e)[0] } unless slots.include?(tgt)
        d.slot_hp[tgt] += 10
        @ui.refresh(self)
      end
    end

    # damage taken off by the defending card's resistance
    def resistance_amount(d, e = PLAY_AREA_ARENA)
      return 30 if e == PLAY_AREA_ARENA && d.changed_resistance != 0
      d.card(d.play_area[e]).resistance_amount
    end
  end

  class Card
    def resistance_amount; (@raw && @raw[:resistance_amount]) || 30; end
  end

  effect(:PollenShieldEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_POLLEN_SHIELD); false }
  effect(:WildGrowthEffect)   { |du| true }   # passive power
  effect(:HerbalScentCheckUse) { |du| true }  # works only when played

  # Herbal Scent: flip a coin; heads heals all of your Grass Pokemon
  effect(:HerbalScentEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("Herbal Scent! If Heads, heal all your Grass Pokémon."),
                  "If Heads, remove all damage\nfrom your <GRASS> Pokémon.")
    if du.toss_coin == HEADS
      (0...d.num_in_play_area).each do |e|
        c = d.card(d.play_area[e])
        next unless c.pokemon? && c.type == GRASS
        dmg, max = du.card_damage_and_max_hp(d, e)
        next if dmg == 0
        du.ui.event(:heal, d.name, e, dmg)
        d.slot_hp[e] = max
      end
      du.ui.refresh(du)
    end
    false
  end

  effect(:HarvestBountyEffect) { |du| true }   # works through attaching Energy

  # Strange Scent: each player (attacker first) flips a coin; heads heals
  effect(:StrangeScentEffect) do |du|
    [du.turn, 1 - du.turn].each do |side|
      d = du.duelists[side]
      du.coin_check(_INTL("{1}: If Heads, remove 3 damage counters.", d.name),
                    "If Heads, remove 3 damage\ncounters from your Pokémon.")
      du.strange_scent_heal(side) if du.toss_coin(d.name) == HEADS
    end
    false
  end
end
