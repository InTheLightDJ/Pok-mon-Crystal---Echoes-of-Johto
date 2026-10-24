#==============================================================================
# Pokemon TCG - effects of the second batch of custom cards (Neo Genesis /
# Discovery / Revelation / Destiny, Expedition, Aquapolis, Skyridge,
# Stormfront art; data in 001b_NeoCards.rb). Attacks that work like an
# original one reuse its effect commands (Ember, Leer, Stun Spore, Agility,
# Leech Seed, Mega Drain, Hypnosis...); the new ones are here.
#
# New rules these cards need:
#   Burned      tails on a coin between turns = 2 damage counters; stays
#               until the Pokemon is benched / evolves / is healed
#               (Full Heal, Solar Power), like Poison. Shown with a <FIRE>.
#   Baby        before attacking a Baby Pokemon (Magby) the attacker flips a
#               coin; tails = the attack does nothing.
#   :weakness_amount   +N instead of x2 (Stormfront Scizor: Fire +20)
# Poke-Bodies of the e-Card / DP cards work as Pokemon Powers here (they
# stop like the original game's powers: Muk, Sputter, Sleep etc.).
#==============================================================================
module TCG
  SUBSTATUS1_HIDE        = 0x31   # Oddish: no damage or effects
  SUBSTATUS1_ACCELERATE  = 0x32   # Scizor: no damage or effects
  SUBSTATUS2_SCARY_FACE  = 0x33   # Spinarak: can't attack or retreat
  NO_DAMAGE_OR_EFFECT_HIDE       = 6
  NO_DAMAGE_OR_EFFECT_ACCELERATE = 7
  BURN_DAMAGE = 20
  Duel::NO_DAMAGE_OR_EFFECT_TEXT[NO_DAMAGE_OR_EFFECT_HIDE]       = "No damage or effect due to Hide."
  Duel::NO_DAMAGE_OR_EFFECT_TEXT[NO_DAMAGE_OR_EFFECT_ACCELERATE] = "No damage or effect due to Accelerate."

  def self.neo_cmds(name, *pairs); EFFECT_TABLE[name] = pairs; end
  neo_cmds "LedybaCometPunchEffectCommands",       [EFFECT_BEFORE_DAMAGE, :NeoCometPunch_MultiplierEffect], [EFFECT_AI, :NeoCometPunch_AIEffect]
  neo_cmds "LedybaSupersonicEffectCommands",       [EFFECT_BEFORE_DAMAGE, :Confusion50PercentEffect]
  neo_cmds "SpinarakScaryFaceEffectCommands",      [EFFECT_BEFORE_DAMAGE, :NeoScaryFaceEffect]
  neo_cmds "AriadosSpiderWebEffectCommands",       [EFFECT_BEFORE_DAMAGE, :NeoSpiderWebEffect]
  neo_cmds "AriadosPoisonBiteEffectCommands",      [EFFECT_AFTER_DAMAGE, :NeoPoisonBite_IfDamagedEffect], [EFFECT_AI, :NeoPoison_AIEffect]
  neo_cmds "GolbatPoisonBiteEffectCommands",       [EFFECT_BEFORE_DAMAGE, :PoisonEffect], [EFFECT_AFTER_DAMAGE, :NeoPoisonBite_HealEffect], [EFFECT_AI, :NeoPoison_AIEffect]
  neo_cmds "OddishHideEffectCommands",             [EFFECT_BEFORE_DAMAGE, :NeoHideEffect]
  neo_cmds "GloomStrangePowderEffectCommands",     [EFFECT_BEFORE_DAMAGE, :NeoStrangePowderEffect]
  neo_cmds "GloomStickyNectarEffectCommands",      [EFFECT_BEFORE_DAMAGE, :NeoStickyNectar_DamageEffect], [EFFECT_AFTER_DAMAGE, :NeoStickyNectar_TrapEffect], [EFFECT_AI, :NeoStickyNectar_AIEffect]
  neo_cmds "BellossomSweetNectarEffectCommands",   [EFFECT_BEFORE_DAMAGE, :NeoSweetNectarEffect]
  neo_cmds "BellossomFlowerDanceEffectCommands",   [EFFECT_BEFORE_DAMAGE, :NeoFlowerDance_MultiplierEffect], [EFFECT_AI, :NeoFlowerDance_MultiplierEffect]
  neo_cmds "NeoSwiftEffectCommands",               [EFFECT_BEFORE_DAMAGE, :NeoSwiftEffect]
  neo_cmds "QuilavaFireWindEffectCommands",        [EFFECT_AFTER_DAMAGE, :NeoFireWindEffect]
  neo_cmds "TyphlosionFireBoostEffectCommands",    [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :NeoFireBoostEffect]
  neo_cmds "TyphlosionFlameWheelEffectCommands",   [EFFECT_INITIAL_EFFECT_1, :NeoFlameWheel_CheckEnergy], [EFFECT_DISCARD_ENERGY, :NeoFlameWheel_DiscardEffect], [EFFECT_AFTER_DAMAGE, :NeoFlameWheel_BenchEffect]
  neo_cmds "HeracrossFinalBlowEffectCommands",     [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo_cmds "HeracrossMegahornEffectCommands",      [EFFECT_BEFORE_DAMAGE, :NeoMegahornEffect], [EFFECT_AI, :NeoMegahorn_AIEffect]
  neo_cmds "LedianBatonPassEffectCommands",        [EFFECT_AFTER_DAMAGE, :NeoBatonPassEffect]
  neo_cmds "MagbySputterEffectCommands",           [EFFECT_AFTER_DAMAGE, :NeoSputterEffect]
  neo_cmds "SunfloraPetalDanceEffectCommands",     [EFFECT_BEFORE_DAMAGE, :NeoPetalDance_MultiplierEffect], [EFFECT_AI, :NeoPetalDance_AIEffect]
  neo_cmds "SunkernGrowthEffectCommands",          [EFFECT_BEFORE_DAMAGE, :NeoGrowthEffect]
  neo_cmds "HoundourCollectFireEffectCommands",    [EFFECT_AFTER_DAMAGE, :NeoCollectFireEffect]
  neo_cmds "MoltresCollectFireEffectCommands",     [EFFECT_AFTER_DAMAGE, :NeoCollectFire50PercentEffect]
  neo_cmds "NeoSingeEffectCommands",               [EFFECT_BEFORE_DAMAGE, :NeoBurn50PercentEffect]
  neo_cmds "PinecoBurstEffectCommands",            [EFFECT_BEFORE_DAMAGE, :NeoBurst_CoinsEffect], [EFFECT_AFTER_DAMAGE, :NeoBurst_SelfdestructEffect], [EFFECT_AI, :NeoBurst_AIEffect]
  neo_cmds "YanmaShockwaveEffectCommands",         [EFFECT_BEFORE_DAMAGE, :NeoShockwave_CoinEffect], [EFFECT_AFTER_DAMAGE, :NeoShockwave_BenchAndSwitchEffect]
  neo_cmds "CrobatTriggeredPoisonEffectCommands",  [EFFECT_AFTER_DAMAGE, :NeoTriggeredPoisonEffect]
  neo_cmds "CrobatCrossAttackEffectCommands",      [EFFECT_BEFORE_DAMAGE, :NeoCrossAttack_MultiplierEffect], [EFFECT_AI, :NeoCrossAttack_AIEffect]
  neo_cmds "GolbatScreechEffectCommands",          [EFFECT_AFTER_DAMAGE, :NeoScreechEffect]
  neo_cmds "DarkHoundoomEerieHowlEffectCommands",  [EFFECT_AFTER_DAMAGE, :NeoEerieHowlEffect]
  neo_cmds "DarkHoundoomDarkFireEffectCommands",   [EFFECT_BEFORE_DAMAGE, :NeoDarkFireEffect]
  neo_cmds "DarkQuilavaIncinerateEffectCommands",  [EFFECT_AFTER_DAMAGE, :NeoIncinerateEffect]
  neo_cmds "DarkQuilavaRushingMagmaEffectCommands", [EFFECT_BEFORE_DAMAGE, :NeoRushingMagmaEffect], [EFFECT_AI, :NeoRushingMagma_AIEffect]
  neo_cmds "DarkTyphlosionRushingFlamesEffectCommands", [EFFECT_REQUIRE_SELECTION, :NeoRushingFlames_SelectEffect], [EFFECT_BEFORE_DAMAGE, :NeoRushingFlames_MultiplierEffect], [EFFECT_AI, :NeoRushingFlames_AIEffect]
  neo_cmds "LightArcanineDriveOffEffectCommands",  [EFFECT_INITIAL_EFFECT_2, :NeoDriveOff_CheckUse], [EFFECT_BEFORE_DAMAGE, :NeoDriveOffEffect]
  neo_cmds "LightArcanineGentleFlamesEffectCommands", [EFFECT_BEFORE_DAMAGE, :NeoGentleFlamesEffect], [EFFECT_AI, :NeoGentleFlamesEffect]
  neo_cmds "ShiningCelebiHealingWaterEffectCommands", [EFFECT_BEFORE_DAMAGE, :NeoHealingWaterEffect]
  neo_cmds "ShiningCelebiMiracleLeafEffectCommands", [EFFECT_BEFORE_DAMAGE, :NeoMiracleLeafEffect]
  neo_cmds "CrobatCrystalTypeEffectCommands",      [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo_cmds "CrobatPoisonFlameEffectCommands",      [EFFECT_BEFORE_DAMAGE, :NeoPoisonFlameEffect], [EFFECT_AI, :NeoPoisonFlame_AIEffect]
  neo_cmds "CrobatSquaredAttackEffectCommands",    [EFFECT_BEFORE_DAMAGE, :NeoSquaredAttack_MultiplierEffect], [EFFECT_AI, :NeoCrossAttack_AIEffect]
  neo_cmds "ForretressExoskeletonEffectCommands",  [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo_cmds "ForretressShellRuptureEffectCommands", [EFFECT_AFTER_DAMAGE, :NeoShellRuptureEffect]
  neo_cmds "ForretressDoubleSpinEffectCommands",   [EFFECT_BEFORE_DAMAGE, :NeoDoubleSpin_MultiplierEffect], [EFFECT_AI, :NeoDoubleSpin_AIEffect]
  neo_cmds "MagcargoStreamingMantleEffectCommands", [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :NeoStreamingMantleEffect]
  neo_cmds "MagcargoCrushingLavaEffectCommands",   [EFFECT_REQUIRE_SELECTION, :NeoCrushingLava_SelectEffect], [EFFECT_BEFORE_DAMAGE, :NeoCrushingLava_DiscardEffect], [EFFECT_AI, :NeoCrushingLava_AIEffect]
  neo_cmds "MoltresFireImmunityEffectCommands",    [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo_cmds "MoltresBurningTailEffectCommands",     [EFFECT_AFTER_DAMAGE, :NeoBurningTailEffect]
  neo_cmds "NinetalesMisleadEffectCommands",       [EFFECT_BEFORE_DAMAGE, :NeoMisleadEffect]
  neo_cmds "NinetalesEtherealFlameEffectCommands", [EFFECT_BEFORE_DAMAGE, :NeoEtherealFlameEffect], [EFFECT_AI, :NeoEtherealFlame_AIEffect]
  neo_cmds "RapidashOverrunEffectCommands",        [EFFECT_AFTER_DAMAGE, :NeoOverrunEffect]
  neo_cmds "ScizorHoneycombDefenderEffectCommands", [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo_cmds "ScizorAccelerateEffectCommands",       [EFFECT_AFTER_DAMAGE, :NeoAccelerateEffect]
  neo_cmds "ScizorPoundDownEffectCommands",        [EFFECT_BEFORE_DAMAGE, :NeoPoundDownEffect], [EFFECT_AI, :NeoPoundDownEffect]

  # coin box texts (Duel#coin_check)
  NEO_COIN_TEXT = {}
  NEO_COIN_TEXT[:NeoBurn50PercentEffect]  = "Burn check!\nIf Heads, opponent is Burned."
  NEO_COIN_TEXT[:NeoSpiderWebEffect]      = "If Heads, opponent can't\nRetreat until benched."
  NEO_COIN_TEXT[:NeoScaryFaceEffect]      = "If Heads, opponent can't Attack\nor Retreat during next turn."
  NEO_COIN_TEXT[:NeoHideEffect]           = "If Heads, no damage or effect\nduring opponent's next turn."
  NEO_COIN_TEXT[:NeoStrangePowderEffect]  = "Opponent is Confused if Heads,\nAsleep if Tails."
  NEO_COIN_TEXT[:NeoStickyNectar_DamageEffect] = "Damage check!\nIf Heads, +10 damage!!"
  NEO_COIN_TEXT[:NeoSweetNectarEffect]    = "If Heads, remove all damage\nfrom 1 of your Pokémon."
  NEO_COIN_TEXT[:NeoMegahornEffect]       = "Damage check!\nIf Tails, no damage!"
  NEO_COIN_TEXT[:NeoGrowthEffect]         = "If Heads, attach up to 2\n<GRASS> Energy from your hand."
  NEO_COIN_TEXT[:NeoCollectFire50PercentEffect] = "If Heads, attach 1 <FIRE> Energy\nfrom your Discard Pile."
  NEO_COIN_TEXT[:NeoShockwave_CoinEffect] = "If Heads, 10 damage to each\nof the opponent's Pokémon."
  NEO_COIN_TEXT[:NeoFireWindEffect]       = "Damage check!\nIf Heads, x 10 damage!!"
  NEO_COIN_TEXT[:NeoOverrunEffect]        = "If Heads, 10 damage to\n1 of the opponent's Bench."
  NEO_COIN_TEXT[:NeoBurningTailEffect]    = "If Tails, discard 1 <FIRE> Energy\nattached to Moltres."
  NEO_COIN_TEXT[:NeoMisleadEffect]        = "Confusion check! If any Heads,\nopponent becomes Confused."
  NEO_COIN_TEXT[:NeoPoisonFlameEffect]    = "If Heads, opponent is\nBurned and Poisoned."
  NEO_COIN_TEXT[:NeoMiracleLeafEffect]    = "If any Heads, opponent is\nAsleep, Confused or Poisoned."
  { :NeoCometPunch_MultiplierEffect => 10, :NeoPetalDance_MultiplierEffect => 30,
    :NeoCrossAttack_MultiplierEffect => 20, :NeoSquaredAttack_MultiplierEffect => 20,
    :NeoDoubleSpin_MultiplierEffect => 40, :NeoRushingFlames_MultiplierEffect => 40 }.each do |fn, n|
    NEO_COIN_TEXT[fn] = "Damage check!\nIf Heads, x #{n} damage!!"
  end

  class Duelist
    # burned: Burn; spider_web: can't retreat (Ariados) until benched or
    # evolved; switch_lock: proc, true while Sticky Nectar holds this Active
    attr_accessor :burned, :spider_web, :switch_lock

    alias_method :tcg_neo2_clear_all_status_conditions, :clear_all_status_conditions
    def clear_all_status_conditions
      tcg_neo2_clear_all_status_conditions
      @burned = false
      @spider_web = false
      @switch_lock = nil
    end

    alias_method :tcg_neo2_swap_arena_with_bench_pokemon, :swap_arena_with_bench_pokemon
    def swap_arena_with_bench_pokemon(e)
      return if @switch_lock && @switch_lock.call
      tcg_neo2_swap_arena_with_bench_pokemon(e)
    end
  end

  class Card
    def weakness_amount; @raw && @raw[:weakness_amount]; end
    def baby?;           @raw && @raw[:baby] ? true : false; end
    # attacks on the card page: a :power (passive, shown only) comes first
    def page_attacks
      @page_attacks ||= (@raw && @raw[:power] ? [Attack.new(@raw[:power])] : []) + (@attacks || [])
    end
    def has_pkmn_power?; page_attacks.any?(&:pokemon_power?); end
  end

  class Duel
    #--------------------------------------------------------------------------
    # timed effects: @neo_fx[key] = [side, deck index, last turn (@duel_turns)]
    # cleared at the end of that turn (Screech, Sputter, Triggered Poison,
    # Sticky Nectar, Crystal Type)
    #--------------------------------------------------------------------------
    def neo_fx; @neo_fx ||= {}; end

    def neo_fx_active?(key, side = nil, idx = nil)
      fx = neo_fx[key] or return false
      return false if side && fx[0] != side
      return false if idx && fx[1] != idx
      true
    end

    alias_method :tcg_neo2_handle_duel_setup, :handle_duel_setup
    def handle_duel_setup
      @neo_fx = {}
      tcg_neo2_handle_duel_setup
    end

    alias_method :tcg_neo2_update_substatus_conditions_end_of_turn, :update_substatus_conditions_end_of_turn
    def update_substatus_conditions_end_of_turn
      tcg_neo2_update_substatus_conditions_end_of_turn
      neo_fx.reject! do |key, (side, idx, last)|
        next false if last > @duel_turns
        if key == :crystal_type   # Crobat's color goes back at the end of the turn
          d = @duelists[side]
          e = d.play_area.index(idx)
          d.slot_changed_type[e] = 0 if e
        end
        true
      end
    end

    # a human picks on screen; the AI picks in the effect itself
    def neo_human_choice?
      @controllers[@whose_turn || @turn].is_a?(PlayerController)
    end

    # is the power of card `id` in slot e working? (Pokemon Power rules)
    def neo_power_works?(d, e)
      return false if d.play_area[e].nil?
      !incapable_of_using_pkmn_power?(d, e)
    end

    #--------------------------------------------------------------------------
    # Burn
    #--------------------------------------------------------------------------
    def queue_burn
      queue_status(0xff, :burn)
    end

    alias_method :tcg_neo2_apply_status_condition_to_arena_pokemon, :apply_status_condition_to_arena_pokemon
    def apply_status_condition_to_arena_pokemon(side, mask, st)
      return @duelists[side].burned = true if st == :burn
      tcg_neo2_apply_status_condition_to_arena_pokemon(side, mask, st)
    end

    # HandleBetweenTurnsEvents with Burn (checked after Poison / Sleep)
    def handle_between_turns_events
      d  = turn_duelist
      nd = non_turn_duelist
      something = arena_asleep_or_poisoned?(d) || (d.status & CNF_SLP_PRZ) == PARALYZED ||
                  arena_asleep_or_poisoned?(nd) || (d.arena && d.burned) || (nd.arena && nd.burned)
      unless something
        discard_attached_pluspowers(d)
        discard_attached_defenders(nd)
        return
      end
      @ui.event(:between_turns)
      ko = false
      if d.status != 0
        ko = handle_poison_damage(d)
        unless ko
          handle_sleep_check(d)
          if (d.status & CNF_SLP_PRZ) == PARALYZED
            d.status &= DOUBLE_POISONED
            @ui.refresh(self)
            @ui.event(:status_anim, d.name, :cured_paralysis)
          end
        end
      end
      handle_burn_damage(d) unless ko
      discard_attached_pluspowers(d)
      if nd.status != 0
        ko = handle_poison_damage(nd)
        handle_sleep_check(nd) unless ko
      else
        ko = false
      end
      handle_burn_damage(nd) unless ko
      discard_attached_defenders(nd)
      handle_between_turn_knock_outs
    end

    # tails: 2 damage counters. returns true if knocked out
    def handle_burn_damage(d)
      return false unless d.arena && d.burned && d.slot_hp[PLAY_AREA_ARENA] > 0
      name = d.card(d.arena).name
      coin_check(_INTL("{1} is Burned. Burn check! If Tails, it takes {2} damage.", name, BURN_DAMAGE),
                 "#{name}'s Burn check.\nIf Tails, #{BURN_DAMAGE} damage!")
      return false if toss_coin(d.name) == HEADS
      if @ui.shows_card_screens?
        hp_before = d.slot_hp[PLAY_AREA_ARENA]
        subtract_hp(d, PLAY_AREA_ARENA, BURN_DAMAGE)
        @ui.event(:status_anim, d.name, :burn, BURN_DAMAGE, hp_before)
        return d.slot_hp[PLAY_AREA_ARENA] == 0
      end
      @ui.message(_INTL("{1} received {2} damage due to Burn.", name, BURN_DAMAGE))
      subtract_hp(d, PLAY_AREA_ARENA, BURN_DAMAGE)
      @ui.refresh(self)
      if d.slot_hp[PLAY_AREA_ARENA] == 0
        @ui.message(_INTL("{1} was Knocked Out!", name))
        return true
      end
      false
    end

    #--------------------------------------------------------------------------
    # Baby rule: tails before attacking a Baby Pokemon = no attack
    #--------------------------------------------------------------------------
    alias_method :tcg_neo2_use_attack_or_pokemon_power, :use_attack_or_pokemon_power
    def use_attack_or_pokemon_power
      nd = non_turn_duelist
      if !@atk.pokemon_power? && nd.arena && nd.card(nd.arena).baby?
        name = nd.card(nd.arena).name
        coin_check(_INTL("Baby rule! If Tails, the attack on {1} does nothing.", name),
                   "Baby rule! If Tails,\nthe attack does nothing.")
        if toss_coin == TAILS
          @ui.message(_INTL("The attack on the Baby Pokémon did nothing."))
          clear_non_turn_temporary_duelvars
          return :ok
        end
      end
      tcg_neo2_use_attack_or_pokemon_power
    end

    #--------------------------------------------------------------------------
    # can't attack / retreat
    #--------------------------------------------------------------------------
    alias_method :tcg_neo2_handle_cant_attack_substatus, :handle_cant_attack_substatus
    def handle_cant_attack_substatus(d)
      return :scary_face if d.substatus2 == SUBSTATUS2_SCARY_FACE
      tcg_neo2_handle_cant_attack_substatus(d)
    end

    # Sticky Nectar: Gloom still the opponent's Active, the trapped Pokemon
    # still this side's Active
    def sticky_nectar_active?(d)
      fx = neo_fx[:sticky_nectar] or return false
      side = @duelists.index(d)
      return false unless fx[0] == side && d.arena == fx[1]
      opp = @duelists[1 - side]
      opp.arena == fx[3]
    end

    alias_method :tcg_neo2_unable_to_retreat_due_to_effect?, :unable_to_retreat_due_to_effect?
    def unable_to_retreat_due_to_effect?(d)
      return true if d.substatus2 == SUBSTATUS2_SCARY_FACE || d.spider_web
      return true if sticky_nectar_active?(d)
      tcg_neo2_unable_to_retreat_due_to_effect?(d)
    end

    alias_method :tcg_neo2_cant_retreat_reason, :cant_retreat_reason
    def cant_retreat_reason
      d = turn_duelist
      unless (d.status & CNF_SLP_PRZ) == CONFUSED && @confusion_retreat_check_unsuccessful
        return :scary_face if d.substatus2 == SUBSTATUS2_SCARY_FACE
        return :spider_web if d.spider_web
        return :sticky_nectar if sticky_nectar_active?(d)
      end
      tcg_neo2_cant_retreat_reason
    end

    # Sticky Nectar also stops effects that change that player's Active
    alias_method :tcg_neo2_handle_switch_defending_pokemon, :handle_switch_defending_pokemon
    def handle_switch_defending_pokemon(e)
      if e && sticky_nectar_active?(non_turn_duelist)
        @ui.message(_INTL("The Active Pokémon can't be switched due to Sticky Nectar."))
        return
      end
      tcg_neo2_handle_switch_defending_pokemon(e)
    end

    #--------------------------------------------------------------------------
    # no damage or effect (Hide / Accelerate)
    #--------------------------------------------------------------------------
    alias_method :tcg_neo2_handle_no_damage_or_effect_substatus, :handle_no_damage_or_effect_substatus
    def handle_no_damage_or_effect_substatus
      unless @atk.pokemon_power? || @atk.temp[:swift]
        case turn_duelist.substatus1
        when SUBSTATUS1_HIDE       then return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_HIDE)
        when SUBSTATUS1_ACCELERATE then return set_no_damage_or_effect(NO_DAMAGE_OR_EFFECT_ACCELERATE)
        end
      end
      r = tcg_neo2_handle_no_damage_or_effect_substatus
      if @atk.temp[:swift]
        @atk.no_damage_or_effect = 0
        return false
      end
      r
    end

    #--------------------------------------------------------------------------
    # Sputter: every Pokemon Power stops working (like Toxic Gas)
    #--------------------------------------------------------------------------
    alias_method :tcg_neo2_toxic_gas_active?, :toxic_gas_active?
    def toxic_gas_active?
      return true if neo_fx_active?(:sputter)
      tcg_neo2_toxic_gas_active?
    end

    #--------------------------------------------------------------------------
    # damage: Weakness +N, Screech (+20), Swift (no reductions), Exoskeleton
    # (-10), Honeycomb Defender (-40 with 6+ damage counters)
    #--------------------------------------------------------------------------
    def apply_damage_modifiers_damage_to_target
      @atk.damage_effectiveness = 0
      dmg = @atk.damage
      return 0 if dmg == 0
      d  = turn_duelist
      nd = non_turn_duelist
      dmg = handle_double_damage_substatus(dmg)
      return 0 if dmg == 0
      unless @atk.unaffected_by_wr
        wr = COLOR_TO_WR[play_area_card_color(d, PLAY_AREA_ARENA)]
        if (arena_card_weakness(nd) & wr) != 0
          dmg = neo_apply_weakness(nd, dmg)
          @atk.damage_effectiveness |= WEAKNESS
        end
        if (arena_card_resistance(nd) & wr) != 0
          dmg -= resistance_amount(nd)
          @atk.damage_effectiveness |= RESISTANCE
        end
      end
      dmg += 20 if dmg > 0 && neo_fx_active?(:screech, 1 - @turn, nd.arena)
      dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA)
      dmg -= 20 * attached_count(nd, :DEFENDER, CARD_LOCATION_ARENA)
      dmg = as_non_turn { handle_damage_reduction(dmg) } unless @atk.temp[:swift]
      dmg < 0 ? 0 : dmg
    end

    def apply_damage_modifiers_damage_to_self
      @atk.damage_effectiveness = 0
      dmg = @atk.damage
      return 0 if dmg == 0
      d = turn_duelist
      wr = COLOR_TO_WR[play_area_card_color(d, PLAY_AREA_ARENA)]
      if (arena_card_weakness(d) & wr) != 0
        dmg = neo_apply_weakness(d, dmg)
        @atk.damage_effectiveness |= WEAKNESS
      end
      if (arena_card_resistance(d) & wr) != 0
        dmg -= resistance_amount(d)
        @atk.damage_effectiveness |= RESISTANCE
      end
      dmg += 10 * attached_count(d, :PLUSPOWER, CARD_LOCATION_ARENA)
      dmg -= 20 * attached_count(d, :DEFENDER, CARD_LOCATION_ARENA)
      dmg < 0 ? 0 : dmg
    end

    # x2, or +N for cards with :weakness_amount (changed weakness: x2)
    def neo_apply_weakness(d, dmg)
      amount = d.changed_weakness == 0 ? d.card(d.arena).weakness_amount : nil
      amount ? dmg + amount : dmg * 2
    end

    alias_method :tcg_neo2_handle_transparency, :handle_transparency
    def handle_transparency(e = PLAY_AREA_ARENA)
      return false if @atk.temp[:swift]
      tcg_neo2_handle_transparency(e)
    end

    # remember which slot is being damaged (for bench Pokemon's powers)
    alias_method :tcg_neo2_deal_damage_to_play_area_pokemon, :deal_damage_to_play_area_pokemon
    def deal_damage_to_play_area_pokemon(e, dmg, anim = :ATK_ANIM_BENCH_HIT)
      @atk.temp[:damaged_slot] = e
      tcg_neo2_deal_damage_to_play_area_pokemon(e, dmg, anim)
    ensure
      @atk.temp[:damaged_slot] = nil if @atk
    end

    # turn holder = the damaged side
    alias_method :tcg_neo2_damage_reduction_from_pkmn_power, :damage_reduction_from_pkmn_power
    def damage_reduction_from_pkmn_power(dmg)
      dmg = tcg_neo2_damage_reduction_from_pkmn_power(dmg)
      return dmg if @atk.pokemon_power?
      case @atk.temp_non_turn_card_id
      when :FORRETRESS then [dmg - 10, 0].max
      when :SCIZOR
        e = @atk.temp[:damaged_slot] || PLAY_AREA_ARENA
        d = turn_duelist
        d.play_area[e] && card_damage_and_max_hp(d, e)[0] >= 60 ? [dmg - 40, 0].max : dmg
      else dmg
      end
    end

    #--------------------------------------------------------------------------
    # attaching Energy: Fire Immunity, Crystal Type, Triggered Poison
    #--------------------------------------------------------------------------
    def fire_immunity_blocks?(d, idx, e)
      return false unless d.card_id(idx) == :FIRE_ENERGY
      return false unless d.play_area[e] && d.card_id(d.play_area[e]) == :MOLTRES_NEO
      !toxic_gas_active?
    end

    alias_method :tcg_neo2_can_play_energy?, :can_play_energy?
    def can_play_energy?(idx, e)
      return false if fire_immunity_blocks?(turn_duelist, idx, e)
      tcg_neo2_can_play_energy?(idx, e)
    end

    alias_method :tcg_neo2_play_energy_card, :play_energy_card
    def play_energy_card(idx, e)
      d = turn_duelist
      return :fire_immunity if fire_immunity_blocks?(d, idx, e)
      r = tcg_neo2_play_energy_card(idx, e)
      return r unless r == :ok
      side = @turn
      target = d.play_area[e]
      c = d.card(idx)
      # Crystal Type: a basic Grass, Fire or Psychic Energy changes Crobat's color
      if d.card_id(target) == :CROBAT_LV44 && c.basic_energy? &&
         [GRASS, FIRE, PSYCHIC].include?(c.color) && neo_power_works?(d, e)
        d.slot_changed_type[e] = HAS_CHANGED_COLOR | c.color
        neo_fx[:crystal_type] = [side, target, @duel_turns]
        @ui.message(_INTL("{1}'s Pokémon Power: Crystal Type", d.card(target).name))
        @ui.refresh(self)
      end
      # Triggered Poison: Energy attached to the Pokemon Crobat attacked
      if e == PLAY_AREA_ARENA && neo_fx_active?(:triggered_poison, side, target)
        neo_fx.delete(:triggered_poison)
        d.status = (d.status & CNF_SLP_PRZ) | POISONED
        @ui.message(_INTL("{1} is now Poisoned due to Triggered Poison.", d.card(target).name))
        @ui.refresh(self)
      end
      r
    end

    #--------------------------------------------------------------------------
    # Full Heal / Solar Power also cure Burn
    #--------------------------------------------------------------------------
    def neo_cure_burn(*ds); ds.each { |x| x.burned = false }; end

    #--------------------------------------------------------------------------
    # helpers for the effects
    #--------------------------------------------------------------------------
    # alive benched slots of duelist d
    def neo_alive_bench(d)
      (1...d.num_in_play_area).select { |e| d.slot_hp[e] > 0 }
    end

    # attach card i (discard pile or deck) to the turn holder's slot e
    def neo_attach_from_discard(i, e = PLAY_AREA_ARENA)
      d = turn_duelist
      d.move_discard_pile_card_to_hand(i)
      d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e
    end

    def neo_attach_from_deck(i, e)
      d = turn_duelist
      d.search_card_in_deck_and_add_to_hand(i)
      d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e
    end

    def neo_fire_in_discard(d = turn_duelist)
      d.discard_pile.select { |i| d.card_id(i) == :FIRE_ENERGY }
    end

    # basic Fire Energy cards attached to slot e of d
    def neo_fire_attached(d, e)
      d.cards_in_slot(e).select { |i| d.card_id(i) == :FIRE_ENERGY }
    end

    # the attacker picks one of the opponent's alive benched Pokemon
    def neo_pick_opponent_bench(purpose)
      slots = neo_alive_bench(non_turn_duelist)
      return nil if slots.empty?
      unless neo_human_choice?
        nd = non_turn_duelist
        return slots.min_by { |e| nd.slot_hp[e] }
      end
      @ui.message(_INTL("Choose 1 of your opponent's Benched Pokémon."))
      sel = as_non_turn { effect_choice(:play_area, purpose, slots, false) }
      slots.include?(sel) ? sel : slots.first
    end

    # damage to the opponent's slot e (no Weakness / Resistance on the Bench)
    def neo_damage_opponent_slot(e, n)
      as_non_turn { deal_damage_to_play_area_pokemon(e, n) }
    end

    # the defending duelist picks its new Active among alive benched Pokemon
    def neo_forced_switch
      nd = non_turn_duelist
      slots = neo_alive_bench(nd)
      return if slots.empty?
      sel = @controllers[1 - @turn].effect_choice(self, :play_area, :ForcedSwitch, slots, false)
      handle_switch_defending_pokemon(slots.include?(sel) ? sel : slots.first)
    end
  end

  #----------------------------------------------------------------------------
  # Full Heal / Solar Power cure Burn too
  #----------------------------------------------------------------------------
  base = EffectFunctions[:FullHeal_StatusCheck]
  effect(:FullHeal_StatusCheck) { |du| du.turn_duelist.burned ? false : base.call(du) }
  base_fh = EffectFunctions[:FullHeal_ClearStatusEffect]
  effect(:FullHeal_ClearStatusEffect) { |du| du.neo_cure_burn(du.turn_duelist); base_fh.call(du) }
  base_sp = EffectFunctions[:SolarPower_RemoveStatusEffect]
  effect(:SolarPower_RemoveStatusEffect) { |du| du.neo_cure_burn(*du.duelists); base_sp.call(du) }

  #----------------------------------------------------------------------------
  # shared
  #----------------------------------------------------------------------------
  effect(:NeoPassivePower)    { |du| true }   # works by itself
  effect(:NeoPlayedPowerCheck) { |du| true }  # works only when played

  effect(:NeoBurn50PercentEffect) do |du|
    du.coin_check(_INTL("Burn check! If Heads, the Defending Pokémon is now Burned."), NEO_COIN_TEXT[:NeoBurn50PercentEffect])
    du.queue_burn if du.toss_coin == HEADS
    false
  end

  # Ledyba: 4 coins x 10
  effect(:NeoCometPunch_MultiplierEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 10), NEO_COIN_TEXT[:NeoCometPunch_MultiplierEffect])
    du.set_definite_damage(10 * du.toss_coins(4)); false
  end
  effect(:NeoCometPunch_AIEffect) { |du| du.set_expected_ai_damage(20, 0, 40); false }

  # Spinarak: can't attack or retreat during the opponent's next turn
  effect(:NeoScaryFaceEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon can't attack or retreat during the next turn."), NEO_COIN_TEXT[:NeoScaryFaceEffect])
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_LEER
      du.apply_substatus2_to_defending_card(SUBSTATUS2_SCARY_FACE)
    else
      du.set_was_unsuccessful
    end
    false
  end

  effect(:NeoSpiderWebEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon can't retreat."), NEO_COIN_TEXT[:NeoSpiderWebEffect])
    if du.toss_coin == HEADS
      du.non_turn_duelist.spider_web = true unless du.check_no_damage_or_effect
    else
      du.set_was_unsuccessful
    end
    false
  end

  # Ariados: if damaged, Poisoned + heal half the damage
  effect(:NeoPoisonBite_IfDamagedEffect) do |du|
    next false if du.atk.dealt_damage <= 0
    du.queue_status(CNF_SLP_PRZ, POISONED)
    du.heal_half_dealt_damage
    du.ui.refresh(du); false
  end
  effect(:NeoPoisonBite_HealEffect) do |du|
    du.heal_half_dealt_damage if du.atk.dealt_damage > 0
    du.ui.refresh(du); false
  end
  effect(:NeoPoison_AIEffect) { |du| du.update_expected_ai_damage_account_for_poison(10, 10, 10); false }

  effect(:NeoHideEffect) do |du|
    du.coin_check(_INTL("If Heads, prevent all damage and effects done to {1} next turn.", du.turn_duelist.card(du.turn_duelist.arena).name), NEO_COIN_TEXT[:NeoHideEffect])
    if du.toss_coin == HEADS
      du.atk.temp[:anim] = :ATK_ANIM_AGILITY_PROTECT
      du.apply_substatus1_to_attacking_card(SUBSTATUS1_HIDE)
    else
      du.set_was_unsuccessful
    end
    false
  end

  # Gloom
  effect(:NeoStrangePowderEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is Confused. If Tails, it is Asleep."), NEO_COIN_TEXT[:NeoStrangePowderEffect])
    du.toss_coin == HEADS ? du.queue_status(PSN_DBLPSN, CONFUSED) : du.queue_status(PSN_DBLPSN, ASLEEP)
    false
  end
  effect(:NeoStickyNectar_DamageEffect) do |du|
    du.coin_check(_INTL("Damage check! If Heads, +{1} damage.", 10), NEO_COIN_TEXT[:NeoStickyNectar_DamageEffect])
    if du.toss_coin == HEADS
      du.atk.damage += 10
      du.set_temp(:sticky, true)
    end
    false
  end
  effect(:NeoStickyNectar_TrapEffect) do |du|
    next false unless du.temp(:sticky) && du.atk.no_damage_or_effect == 0
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0
    du.neo_fx[:sticky_nectar] = [1 - du.turn, nd.arena, du.duel_turns + 2, du.turn_duelist.arena]
    nd.switch_lock = -> { du.sticky_nectar_active?(nd) }
    du.ui.message(_INTL("{1} is stuck in the nectar!", nd.card(nd.arena).name))
    false
  end
  effect(:NeoStickyNectar_AIEffect) { |du| du.set_expected_ai_damage(25, 20, 30); false }

  # Bellossom
  effect(:NeoSweetNectarEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("If Heads, remove all damage counters from 1 of your Pokémon."), NEO_COIN_TEXT[:NeoSweetNectarEffect])
    next false unless du.toss_coin == HEADS
    slots = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
    next false if slots.empty?
    tgt = du.effect_choice(:play_area, :NeoSweetNectarHeal, slots, false)
    tgt = slots.max_by { |e| du.card_damage_and_max_hp(d, e)[0] } unless slots.include?(tgt)
    dmg, max = du.card_damage_and_max_hp(d, tgt)
    du.ui.event(:heal, d.name, tgt, dmg)
    d.slot_hp[tgt] = max
    du.ui.refresh(du); false
  end
  effect(:NeoFlowerDance_MultiplierEffect) do |du|
    d = du.turn_duelist
    n = (0...d.num_in_play_area).count { |e| d.card(d.play_area[e]).name.include?("Bellossom") }
    du.set_definite_damage(30 * n); false
  end

  # Swift: no Weakness, Resistance, powers or effects on the Defending Pokemon
  effect(:NeoSwiftEffect) do |du|
    du.atk.unaffected_by_wr = true
    du.set_temp(:swift, true)
    du.atk.no_damage_or_effect = 0
    false
  end

  # Quilava: 1 benched Pokemon, 2 coins x 10
  effect(:NeoFireWindEffect) do |du|
    e = du.neo_pick_opponent_bench(:NeoFireWind) or next false
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 10), NEO_COIN_TEXT[:NeoFireWindEffect])
    n = du.toss_coins(2)
    du.neo_damage_opponent_slot(e, 10 * n) if n > 0
    false
  end

  # Typhlosion: when played, flip; heads = up to 4 Fire Energy from the deck
  effect(:NeoFireBoostEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    du.coin_check(_INTL("Fire Boost! If Heads, attach up to 4 Fire Energy cards from your Deck."),
                  "If Heads, attach up to 4 <FIRE>\nEnergy from your Deck!")
    if du.toss_coin == HEADS
      list = d.deck_list.select { |i| d.card_id(i) == :FIRE_ENERGY }.first(4)
      list.each { |i| du.neo_attach_from_deck(i, e) }
      du.ui.message(_INTL("{1} Fire Energy card(s) were attached to {2}.", list.size, d.card(d.play_area[e]).name))
      du.shuffle_cards_in_deck
      du.ui.refresh(du)
    end
    false
  end

  # Flame Wheel: discard 3 Fire Energy, 20 to every Benched Pokemon
  effect(:NeoFlameWheel_CheckEnergy) do |du|
    d = du.turn_duelist
    du.neo_fire_attached(d, PLAY_AREA_ARENA).size < 3 ? _INTL("Not enough Fire Energy.") : false
  end
  effect(:NeoFlameWheel_DiscardEffect) do |du|
    d = du.turn_duelist
    du.neo_fire_attached(d, PLAY_AREA_ARENA).first(3).each { |i| d.put_card_in_discard_pile(i) }
    false
  end
  effect(:NeoFlameWheel_BenchEffect) do |du|
    du.atk.is_damage_to_self = true
    du.deal_damage_to_all_benched_pokemon(20)
    du.as_non_turn do
      du.atk.is_damage_to_self = false
      du.deal_damage_to_all_benched_pokemon(20)
    end
    false
  end

  # Heracross: Final Blow makes Megahorn 120 at 20 HP or less
  effect(:NeoMegahornEffect) do |du|
    d = du.turn_duelist
    if d.slot_hp[PLAY_AREA_ARENA] <= 20 && du.neo_power_works?(d, PLAY_AREA_ARENA)
      du.set_definite_damage(120)
      du.ui.message(_INTL("{1}'s Pokémon Power: Final Blow", d.card(d.arena).name))
    end
    du.coin_check(_INTL("Damage check! If Tails, no damage."), NEO_COIN_TEXT[:NeoMegahornEffect])
    if du.toss_coin == TAILS
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:NeoMegahorn_AIEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    full = d.slot_hp[e] <= 20 && du.neo_power_works?(d, e) ? 120 : 60
    du.set_expected_ai_damage(full / 2, 0, full); false
  end

  # Ledian: Grass Energy to a Benched Grass Pokemon, then switch with it
  effect(:NeoBatonPassEffect) do |du|
    d = du.turn_duelist
    next false if d.slot_hp[PLAY_AREA_ARENA] == 0
    slots = du.neo_alive_bench(d).select { |e| du.play_area_card_color(d, e) == GRASS }
    next false if slots.empty?
    tgt = du.neo_human_choice? ? du.effect_choice(:play_area, :NeoBatonPass, slots, false) : nil
    tgt = slots.max_by { |e| d.slot_hp[e] } unless slots.include?(tgt)
    grass = d.cards_in_slot(PLAY_AREA_ARENA).select { |i| d.card(i).type == TYPE_NAMES["TYPE_ENERGY_GRASS"] }
    grass.each { |i| d.card_locations[i] = CARD_LOCATION_PLAY_AREA | tgt }
    d.swap_arena_with_bench_pokemon(tgt)
    du.ui.message(_INTL("Baton Pass! {1} is now the Active Pokémon.", d.card(d.arena).name))
    du.ui.refresh(du); false
  end

  # Magby: every Pokemon Power stops until the end of your next turn
  effect(:NeoSputterEffect) do |du|
    du.neo_fx[:sputter] = [du.turn, nil, du.duel_turns + 2]
    du.ui.message(_INTL("Pokémon Powers stop working until the end of your next turn."))
    false
  end

  # Sunflora: 3 coins x 30, then Confused
  effect(:NeoPetalDance_MultiplierEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 30), NEO_COIN_TEXT[:NeoPetalDance_MultiplierEffect])
    du.set_definite_damage(30 * du.toss_coins(3))
    du.confuse_self; false
  end
  effect(:NeoPetalDance_AIEffect) { |du| du.set_expected_ai_damage(45, 0, 90); false }

  # Sunkern: heads = attach up to 2 Grass Energy cards from the hand
  effect(:NeoGrowthEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("If Heads, attach up to 2 Grass Energy cards from your hand."), NEO_COIN_TEXT[:NeoGrowthEffect])
    next false unless du.toss_coin == HEADS
    list = d.hand.select { |i| d.card_id(i) == :GRASS_ENERGY }
    picked = du.neo_human_choice? ? du.pick_up_to(:NeoGrowth, list, 2) : list.first(2)
    picked.each do |i|
      d.put_hand_card_in_play_area(i, PLAY_AREA_ARENA)
      du.ui.event(:attach_energy, d.name, i, PLAY_AREA_ARENA)
    end
    du.ui.refresh(du); false
  end

  # Houndour: 1 Fire Energy from the discard pile to Houndour
  effect(:NeoCollectFireEffect) do |du|
    i = du.neo_fire_in_discard.first or next false
    du.neo_attach_from_discard(i)
    du.ui.message(_INTL("A Fire Energy card was attached from the Discard Pile."))
    du.ui.refresh(du); false
  end
  # Moltres: the same on heads
  effect(:NeoCollectFire50PercentEffect) do |du|
    i = du.neo_fire_in_discard.first or next false
    du.coin_check(_INTL("If Heads, attach 1 Fire Energy card from your Discard Pile."), NEO_COIN_TEXT[:NeoCollectFire50PercentEffect])
    next false unless du.toss_coin == HEADS
    du.neo_attach_from_discard(i)
    du.ui.message(_INTL("A Fire Energy card was attached from the Discard Pile."))
    du.ui.refresh(du); false
  end

  # Pineco: heads = 40 to itself + 10 to every bench; 2nd coin tails = nothing
  effect(:NeoBurst_CoinsEffect) do |du|
    du.coin_check(_INTL("If Heads, Pineco does 40 damage to itself and 10 to each Benched Pokémon."),
                  "If Heads, 40 damage to Pineco\nand 10 to each Bench.")
    du.set_temp(:burst, du.toss_coin == HEADS)
    du.coin_check(_INTL("Success check! If Tails, the attack does nothing."), "Success check!!!\nIf Tails, nothing happens!")
    if du.toss_coin == TAILS
      du.set_temp(:burst, false)
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:NeoBurst_SelfdestructEffect) do |du|
    du.selfdestruct(40, 10) if du.temp(:burst)
    false
  end
  effect(:NeoBurst_AIEffect) { |du| du.set_expected_ai_damage(20, 0, 40); false }

  # Yanma: heads = 10 to each of the opponent's Pokemon; then they switch
  effect(:NeoShockwave_CoinEffect) do |du|
    du.coin_check(_INTL("If Heads, 10 damage to each of your opponent's Pokémon."), NEO_COIN_TEXT[:NeoShockwave_CoinEffect])
    heads = du.toss_coin == HEADS
    du.set_temp(:shockwave, heads)
    if heads
      du.set_definite_damage(10)
      du.atk.unaffected_by_wr = true
    end
    false
  end
  effect(:NeoShockwave_BenchAndSwitchEffect) do |du|
    du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) } if du.temp(:shockwave)
    du.neo_forced_switch if du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] > 0
    false
  end

  # Crobat (Revelation)
  effect(:NeoTriggeredPoisonEffect) do |du|
    next false if du.atk.no_damage_or_effect != 0
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0
    du.neo_fx[:triggered_poison] = [1 - du.turn, nd.arena, du.duel_turns + 1]
    false
  end
  effect(:NeoCrossAttack_MultiplierEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 20), NEO_COIN_TEXT[:NeoCrossAttack_MultiplierEffect])
    n = du.toss_coins(4)
    du.set_definite_damage(20 * n)
    du.queue_status(PSN_DBLPSN, CONFUSED) if n >= 2
    false
  end
  effect(:NeoCrossAttack_AIEffect) { |du| du.set_expected_ai_damage(40, 0, 80); false }
  effect(:NeoSquaredAttack_MultiplierEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 20), NEO_COIN_TEXT[:NeoSquaredAttack_MultiplierEffect])
    du.set_definite_damage(20 * du.toss_coins(4)); false
  end

  # Golbat: +20 damage to the Defending Pokemon until the end of your next turn
  effect(:NeoScreechEffect) do |du|
    next false if du.atk.no_damage_or_effect != 0
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0
    du.neo_fx[:screech] = [1 - du.turn, nd.arena, du.duel_turns + 2]
    du.ui.message(_INTL("{1} will take 20 more damage from attacks.", nd.card(nd.arena).name))
    false
  end

  # Dark Houndoom: a Basic from the opponent's hand to the Bench, then Active
  effect(:NeoEerieHowlEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    list = nd.hand.select { |i| nd.card(i).basic? }
    if list.empty?
      du.ui.message(_INTL("There are no Basic Pokémon in your opponent's hand."))
      next false
    end
    i = nil
    if du.neo_human_choice?
      du.ui.message(_INTL("Choose a Basic Pokémon from your opponent's hand."))
      i = du.as_non_turn { du.effect_choice(:card, :NeoEerieHowl, list, false) }
    end
    i = list.min_by { |k| nd.card(k).hp.to_i } unless list.include?(i)
    e = du.as_non_turn { du.put_basic_pokemon_in_play_area(i) }
    du.ui.message(_INTL("{1} was placed on the opponent's Bench.", nd.card(i).name))
    du.ui.refresh(du)
    du.handle_switch_defending_pokemon(e) if e && nd.slot_hp[PLAY_AREA_ARENA] > 0
    false
  end

  # Dark Fire: +20 (+10 per discarded card) with a Darkness Energy attached
  effect(:NeoDarkFireEffect) do |du|
    d = du.turn_duelist
    dark = d.energy_cards_in_slot(PLAY_AREA_ARENA).find { |i| d.card(i).name.include?("Darkness") }
    if dark
      d.put_card_in_discard_pile(dark)
      du.atk.damage += 30
    end
    false
  end

  # Dark Quilava
  effect(:NeoIncinerateEffect) do |du|
    nd = du.non_turn_duelist
    i = nd.deck_list.first or next false
    c = nd.card(i)
    if c.trainer?
      nd.draw_card_from_deck
      nd.put_card_in_discard_pile(i)
      du.ui.message(_INTL("The top card of the opponent's Deck was {1}. It was discarded.", c.name))
    else
      du.ui.message(_INTL("The top card of the opponent's Deck was {1}.", c.name))
    end
    du.ui.refresh(du); false
  end
  effect(:NeoRushingMagmaEffect) do |du|
    d = du.turn_duelist
    n = 0
    5.times do
      i = d.draw_card_from_deck or break
      d.put_card_in_discard_pile(i)
      n += 1 if d.card_id(i) == :FIRE_ENERGY
    end
    du.ui.message(_INTL("{1} Fire Energy card(s) were discarded from the Deck.", n))
    du.set_definite_damage(20 * n); false
  end
  effect(:NeoRushingMagma_AIEffect) do |du|
    d = du.turn_duelist
    deck = d.deck_list
    fire = deck.count { |i| d.card_id(i) == :FIRE_ENERGY }
    exp = deck.empty? ? 0 : (20.0 * [deck.size, 5].min * fire / deck.size).round(-1).to_i
    du.set_expected_ai_damage(exp, 0, 20 * [fire, 5].min); false
  end

  # Dark Typhlosion: discard any Fire Energy from your Pokemon, 40 per heads
  effect(:NeoRushingFlames_SelectEffect) do |du|
    d = du.turn_duelist
    all = (0...d.num_in_play_area).flat_map { |e| du.neo_fire_attached(d, e) }
    if du.neo_human_choice?
      du.ui.message(_INTL("Choose the Fire Energy cards to discard (B: done)."))
      du.set_temp(:list, du.pick_up_to(:NeoRushingFlames, all, all.size))
    else
      # AI: enough for about a Knock Out, keeping 1 on the Active
      need = 2 * ((du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] + 39) / 40)
      arena = du.neo_fire_attached(d, PLAY_AREA_ARENA)
      order = arena.drop(1) + (all - arena) + arena.first(1)
      du.set_temp(:list, order.first([need, 1].max))
    end
    false
  end
  effect(:NeoRushingFlames_MultiplierEffect) do |du|
    d = du.turn_duelist
    list = du.temp(:list) || []
    list.each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du)
    if list.empty?
      du.set_definite_damage(0)
      next false
    end
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 40), NEO_COIN_TEXT[:NeoRushingFlames_MultiplierEffect])
    du.set_definite_damage(40 * du.toss_coins(list.size)); false
  end
  effect(:NeoRushingFlames_AIEffect) do |du|
    d = du.turn_duelist
    n = (0...d.num_in_play_area).sum { |e| du.neo_fire_attached(d, e).size }
    du.set_expected_ai_damage(20 * n, 0, 40 * n); false
  end

  # Light Arcanine: Active only, once per turn, the opponent switches
  effect(:NeoDriveOff_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only while it is your Active Pokémon.") if slot != PLAY_AREA_ARENA
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    next _INTL("Your opponent has no Benched Pokémon.") if du.neo_alive_bench(du.non_turn_duelist).empty?
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end
  effect(:NeoDriveOffEffect) do |du|
    du.turn_duelist.slot_flags[du.temp(:a0)] |= USED_PKMN_POWER_THIS_TURN
    du.neo_forced_switch
    false
  end
  effect(:NeoGentleFlamesEffect) do |du|
    nd = du.non_turn_duelist
    c = nd.arena && nd.card(nd.arena)
    if c && c.baby? then du.set_definite_damage(10)
    elsif c && c.basic? then du.set_definite_damage(30)
    end
    false
  end

  # Shining Celebi
  effect(:NeoHealingWaterEffect) do |du|
    d = du.turn_duelist
    n = d.cards_in_slot(PLAY_AREA_ARENA).count { |i| d.card_id(i) == :WATER_ENERGY }
    slots = du.neo_alive_bench(d).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
    next false if n == 0 || slots.empty?
    tgt = du.effect_choice(:play_area, :NeoHealingWaterHeal, slots, false)
    tgt = slots.max_by { |e| du.card_damage_and_max_hp(d, e)[0] } unless slots.include?(tgt)
    dmg, max = du.card_damage_and_max_hp(d, tgt)
    heal = [10 * n, dmg].min
    du.ui.event(:heal, d.name, tgt, heal)
    d.slot_hp[tgt] = [d.slot_hp[tgt] + heal, max].min
    du.ui.refresh(du); false
  end
  NEO_MIRACLE_LEAF = { :Asleep => [PSN_DBLPSN, ASLEEP], :Confused => [PSN_DBLPSN, CONFUSED],
                       :Poisoned => [CNF_SLP_PRZ, POISONED] }
  effect(:NeoMiracleLeafEffect) do |du|
    nd = du.non_turn_duelist
    n = nd.arena ? nd.attached_energies(PLAY_AREA_ARENA)[1] : 0
    next false if n == 0
    du.coin_check(_INTL("If any Heads, the Defending Pokémon is Asleep, Confused or Poisoned."), NEO_COIN_TEXT[:NeoMiracleLeafEffect])
    next false if du.toss_coins(n) == 0
    st = du.neo_human_choice? ? du.effect_choice(:status, :NeoMiracleLeaf, NEO_MIRACLE_LEAF.keys, false) : nil
    unless NEO_MIRACLE_LEAF.key?(st)
      st = (nd.status & PSN_DBLPSN) == 0 && nd.slot_hp[PLAY_AREA_ARENA] <= 20 ? :Poisoned : :Asleep
    end
    du.queue_status(*NEO_MIRACLE_LEAF[st])
    false
  end

  # Crobat (Skyridge)
  effect(:NeoPoisonFlameEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is now Burned and Poisoned."), NEO_COIN_TEXT[:NeoPoisonFlameEffect])
    if du.toss_coin == HEADS
      du.queue_burn
      du.queue_status(CNF_SLP_PRZ, POISONED)
    end
    false
  end
  effect(:NeoPoisonFlame_AIEffect) { |du| du.update_expected_ai_damage_account_for_poison(10, 0, 20); false }

  # Forretress
  effect(:NeoShellRuptureEffect) do |du|
    du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    false
  end
  effect(:NeoDoubleSpin_MultiplierEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 40), NEO_COIN_TEXT[:NeoDoubleSpin_MultiplierEffect])
    du.set_definite_damage(40 * du.toss_coins(2)); false
  end
  effect(:NeoDoubleSpin_AIEffect) { |du| du.set_expected_ai_damage(40, 0, 80); false }

  # Magcargo: Streaming Mantle when it evolves the Active Pokemon
  effect(:NeoStreamingMantleEffect) do |du|
    next false unless (du.temp(:power_slot) || PLAY_AREA_ARENA) == PLAY_AREA_ARENA
    d = du.turn_duelist
    if du.neo_human_choice?
      next false unless du.effect_choice(:yes_no, :NeoStreamingMantle, [true, false], false)
    else
      basics = du.energy_card_list_from_discard_pile(true).size
      next false unless basics >= 3 && d.cards_in_deck > 10
    end
    du.neo_streaming_mantle(du.turn)
    du.neo_streaming_mantle(1 - du.turn)
    false
  end

  class Duel
    # discard the top 3 cards, then 3 basic Energy cards from the discard
    # pile go back into the deck (the duelist on `side` picks them)
    def neo_streaming_mantle(side)
      run = lambda do
        d = turn_duelist
        3.times { (i = d.draw_card_from_deck) && d.put_card_in_discard_pile(i) }
        list = energy_card_list_from_discard_pile(true)
        ctrl = @controllers[side]
        picked = []
        if ctrl.is_a?(PlayerController)
          @ui.message(_INTL("{1}: choose 3 basic Energy cards to shuffle into the Deck.", d.name))
          pool = list.dup
          while picked.size < 3 && !pool.empty?
            sel = ctrl.effect_choice(self, :card, :NeoStreamingMantle, pool, false)
            sel = pool.first unless pool.include?(sel)
            picked << pool.delete(sel)
          end
        else
          picked = list.first(3)
        end
        picked.each do |i|
          d.move_discard_pile_card_to_hand(i)
          d.return_card_to_deck(i)
        end
        shuffle_cards_in_deck
        @ui.message(_INTL("{1} discarded 3 cards and shuffled {2} Energy card(s) into the Deck.", d.name, picked.size))
      end
      side == @turn ? run.call : as_non_turn(&run)
      @ui.refresh(self)
    end
  end

  # Crushing Lava: discard Fire (Burned) or Fighting (+20), or nothing
  effect(:NeoCrushingLava_SelectEffect) do |du|
    d = du.turn_duelist
    list = d.cards_in_slot(PLAY_AREA_ARENA).select { |i| [:FIRE_ENERGY, :FIGHTING_ENERGY].include?(d.card_id(i)) }
    sel = nil
    if du.neo_human_choice?
      du.ui.message(_INTL("You may discard a Fire or Fighting Energy card (B: none).")) unless list.empty?
      sel = du.effect_choice(:card, :NeoCrushingLava, list, true) unless list.empty?
    else
      sel = list.find { |i| d.card_id(i) == :FIGHTING_ENERGY }
      sel ||= list.find { |i| d.card_id(i) == :FIRE_ENERGY } unless du.non_turn_duelist.burned
    end
    du.set_temp(:lava, list.include?(sel) ? sel : nil)
    false
  end
  effect(:NeoCrushingLava_DiscardEffect) do |du|
    d = du.turn_duelist
    i = du.temp(:lava) or next false
    fire = d.card_id(i) == :FIRE_ENERGY
    d.put_card_in_discard_pile(i)
    fire ? du.queue_burn : du.atk.damage += 20
    du.ui.refresh(du); false
  end
  effect(:NeoCrushingLava_AIEffect) do |du|
    d = du.turn_duelist
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    fight = d.cards_in_slot(e).any? { |i| d.card_id(i) == :FIGHTING_ENERGY }
    du.set_expected_ai_damage(fight ? 60 : 40, 40, fight ? 60 : 40); false
  end

  # Moltres: tails = discard a Fire Energy card from Moltres
  effect(:NeoBurningTailEffect) do |du|
    du.coin_check(_INTL("If Tails, discard a Fire Energy card attached to Moltres."), NEO_COIN_TEXT[:NeoBurningTailEffect])
    next false if du.toss_coin == HEADS
    d = du.turn_duelist
    i = du.neo_fire_attached(d, PLAY_AREA_ARENA).first
    d.put_card_in_discard_pile(i) if i
    du.ui.refresh(du); false
  end

  # Ninetails (Expedition)
  effect(:NeoMisleadEffect) do |du|
    du.coin_check(_INTL("If either coin is Heads, the Defending Pokémon is now Confused."), NEO_COIN_TEXT[:NeoMisleadEffect])
    du.queue_status(PSN_DBLPSN, CONFUSED) if du.toss_coins(2) > 0
    false
  end
  effect(:NeoEtherealFlameEffect) do |du|
    d = du.turn_duelist
    list = du.neo_fire_attached(d, PLAY_AREA_ARENA)
    list.each { |i| d.put_card_in_discard_pile(i) }
    du.set_definite_damage(30 + 20 * list.size)
    du.ui.refresh(du); false
  end
  effect(:NeoEtherealFlame_AIEffect) do |du|
    d = du.turn_duelist
    n = du.neo_fire_attached(d, du.temp(:power_slot) || PLAY_AREA_ARENA).size
    du.set_definite_damage(30 + 20 * n); false
  end

  # Rapidash: heads = 10 to 1 benched Pokemon
  effect(:NeoOverrunEffect) do |du|
    next false if du.neo_alive_bench(du.non_turn_duelist).empty?
    du.coin_check(_INTL("If Heads, 10 damage to 1 of your opponent's Benched Pokémon."), NEO_COIN_TEXT[:NeoOverrunEffect])
    next false unless du.toss_coin == HEADS
    e = du.neo_pick_opponent_bench(:NeoOverrun)
    du.neo_damage_opponent_slot(e, 10) if e
    false
  end

  # Scizor (Stormfront)
  effect(:NeoAccelerateEffect) do |du|
    nd = du.non_turn_duelist
    if nd.arena && nd.slot_hp[PLAY_AREA_ARENA] == 0 && du.turn_duelist.slot_hp[PLAY_AREA_ARENA] > 0
      du.apply_substatus1_to_attacking_card(SUBSTATUS1_ACCELERATE)
    end
    false
  end
  effect(:NeoPoundDownEffect) do |du|
    d = du.turn_duelist
    powers = (0...d.num_in_play_area).any? { |e| d.card(d.play_area[e]).has_pkmn_power? }
    du.atk.damage += 30 unless powers
    false
  end
end
