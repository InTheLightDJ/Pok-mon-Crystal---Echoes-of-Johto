#==============================================================================
# Pokemon TCG - effects of the third batch of custom cards (Neo, e-Card and
# promo cards; data in 001b_NeoCards.rb). Attacks that work like an original
# one reuse its effect commands (Agility, Withdraw, Water Gun, Flail, Rage,
# Psychic, Smokescreen, Prophecy...); the new ones are here.
#
# Pokémon Powers (Poké-Powers / Poké-Bodies work as Pokémon Powers here):
#   menu      Jet Stream, Super Dynamo, Playful Punch (ends the turn), Major
#             Tsunami, [Join]
#   played    Howl (ends the turn), Berserk
#   passive   Water Immunity, Anti-Lightning, Crystal Type (Kingdra),
#             Conductivity, Lightning Burst, Deep Sleep, Thick Shell, Dense
#             Body, Suction Cups, Mind Games, Crystal Body, Time Travel, Bolt,
#             Hydroelectric Power (in Floodlight), [Anger] (in Hidden Power)
#   page only Prehistoric Memory (Aerodactyl): shown on the card, no effect
# Psymimic (Alakazam) is used from the attack menu: it copies one of the
# Defending Pokémon's attacks, energy cost included.
#==============================================================================
module TCG
  SUBSTATUS1_DODGE         = 0x34   # Hitmonchan: coin, heads = no damage
  SUBSTATUS1_PULSE_GUARD   = 0x35   # Light Jolteon: 30 or more = no damage
  SUBSTATUS1_SLIME         = 0x36   # Wooper: attacker's coin, tails = no damage
  SUBSTATUS1_ENDURE        = 0x37   # Phanpy: a Knock Out leaves 10 HP
  SUBSTATUS1_REFLECT       = 0x38   # Shining Mewtwo: coin, heads = no damage + 20 back
  SUBSTATUS1_COUNTER       = 0x39   # Wobbuffet: coin, heads = the same damage back

  def self.neo3_cmds(name, *pairs); EFFECT_TABLE["Neo3#{name}EffectCommands"] = pairs; end
  neo3_cmds "PassivePower",       [EFFECT_INITIAL_EFFECT_1, :NeoPassivePower]
  neo3_cmds "Psymimic",           [EFFECT_INITIAL_EFFECT_1, :Neo3Psymimic_CheckEffect], [EFFECT_INITIAL_EFFECT_2, :Neo3Psymimic_CopyEffect]
  neo3_cmds "Syncroblast",        [EFFECT_BEFORE_DAMAGE, :Neo3SyncroblastEffect], [EFFECT_AI, :Neo3SyncroblastEffect]
  neo3_cmds "Gigaspark",          [EFFECT_BEFORE_DAMAGE, :Neo3Gigaspark_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3Gigaspark_BenchEffect]
  neo3_cmds "FreezeSolid",        [EFFECT_AFTER_DAMAGE, :Neo3FreezeSolidEffect]
  neo3_cmds "IceCyclone",         [EFFECT_BEFORE_DAMAGE, :Neo3IceCyclone_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3IceCyclone_BenchEffect]
  neo3_cmds "JetStream",          [EFFECT_INITIAL_EFFECT_1, :Neo3ActiveOncePower_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo3JetStreamEffect]
  neo3_cmds "EnergyCannon",       [EFFECT_BEFORE_DAMAGE, :Neo3EnergyCannonEffect], [EFFECT_AI, :Neo3EnergyCannonEffect]
  neo3_cmds "PsychicDamage",      [EFFECT_AFTER_DAMAGE, :Neo3PsychicDamageEffect], [EFFECT_AI, :Neo3PsychicDamage_AIEffect]
  neo3_cmds "Bonfire",            [EFFECT_BEFORE_DAMAGE, :Neo3Bonfire_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3Bonfire_DamageEffect], [EFFECT_AI, :Neo3Bonfire_AIEffect]
  neo3_cmds "TakeDown",           [EFFECT_AFTER_DAMAGE, :Neo3Recoil10Effect]
  neo3_cmds "JawClamp",           [EFFECT_AFTER_DAMAGE, :Neo3JawClampEffect]
  neo3_cmds "ShockBolt",          [EFFECT_AFTER_DAMAGE, :Neo3ShockBoltEffect]
  neo3_cmds "Psysplash",          [EFFECT_AFTER_DAMAGE, :Neo3PsysplashEffect], [EFFECT_AI, :Neo3Psysplash_AIEffect]
  neo3_cmds "HighVoltage",        [EFFECT_AFTER_DAMAGE, :Neo3HighVoltageEffect]
  neo3_cmds "StunWave",           [EFFECT_AFTER_DAMAGE, :Neo3StunWaveEffect]
  neo3_cmds "PullIn",             [EFFECT_BEFORE_DAMAGE, :Neo3PullInEffect]
  neo3_cmds "CallBack",           [EFFECT_INITIAL_EFFECT_1, :Neo3CallBack_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3CallBackEffect]
  neo3_cmds "Surround",           [EFFECT_BEFORE_DAMAGE, :Neo3SurroundEffect]
  neo3_cmds "PrehistoricWater",   [EFFECT_AFTER_DAMAGE, :Neo3PrehistoricWaterEffect]
  neo3_cmds "DarkTentacle",       [EFFECT_AFTER_DAMAGE, :Neo3DarkTentacleEffect]
  neo3_cmds "RapidSpin",          [EFFECT_AFTER_DAMAGE, :Neo3RapidSpinEffect]
  neo3_cmds "TuskToss",           [EFFECT_AFTER_DAMAGE, :Neo3TuskTossEffect]
  neo3_cmds "SuperDynamo",        [EFFECT_INITIAL_EFFECT_1, :Neo3SuperDynamo_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo3SuperDynamoEffect]
  neo3_cmds "PlayfulPunch",       [EFFECT_INITIAL_EFFECT_1, :Neo3PlayfulPunch_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo3PlayfulPunchEffect]
  neo3_cmds "ProtectiveFlame",    [EFFECT_AFTER_DAMAGE, :Neo3ProtectiveFlameEffect]
  neo3_cmds "Howl",               [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :Neo3HowlEffect]
  neo3_cmds "SearingFlames",      [EFFECT_AFTER_DAMAGE, :Neo3SearingFlamesEffect]
  neo3_cmds "Berserk",            [EFFECT_INITIAL_EFFECT_1, :NeoPlayedPowerCheck], [EFFECT_PKMN_POWER_TRIGGER, :Neo3BerserkEffect]
  neo3_cmds "Chomp",              [EFFECT_BEFORE_DAMAGE, :Neo3ChompEffect], [EFFECT_AI, :Neo3Chomp_AIEffect]
  neo3_cmds "MajorTsunami",       [EFFECT_INITIAL_EFFECT_1, :Neo3MajorTsunami_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo3MajorTsunamiEffect]
  neo3_cmds "RendingJaws",        [EFFECT_BEFORE_DAMAGE, :Neo3RendingJawsEffect], [EFFECT_AI, :Neo3RendingJawsEffect]
  neo3_cmds "Discharge",          [EFFECT_BEFORE_DAMAGE, :Neo3DischargeEffect], [EFFECT_AI, :Neo3Discharge_AIEffect]
  neo3_cmds "ElectricCurrent",    [EFFECT_AFTER_DAMAGE, :Neo3ElectricCurrentEffect]
  neo3_cmds "StunPoison",         [EFFECT_BEFORE_DAMAGE, :Neo3StunPoisonEffect], [EFFECT_AI, :NeoPoison_AIEffect]
  neo3_cmds "Dodge",              [EFFECT_BEFORE_DAMAGE, :Neo3DodgeEffect]
  neo3_cmds "TripleKick",         [EFFECT_BEFORE_DAMAGE, :Neo3TripleKickEffect], [EFFECT_AI, :Neo3TripleKick_AIEffect]
  neo3_cmds "Stoke",              [EFFECT_AFTER_DAMAGE, :Neo3StokeEffect]
  neo3_cmds "Hydrocutter",        [EFFECT_BEFORE_DAMAGE, :Neo3HydrocutterEffect], [EFFECT_AI, :Neo3Hydrocutter_AIEffect]
  neo3_cmds "Aquabomb",           [EFFECT_AFTER_DAMAGE, :Neo3AquabombEffect]
  neo3_cmds "DualBurn",           [EFFECT_AFTER_DAMAGE, :Neo3DualBurnEffect]
  neo3_cmds "DragonTornado",      [EFFECT_AFTER_DAMAGE, :Neo3DragonTornadoEffect]
  neo3_cmds "Conduction",         [EFFECT_BEFORE_DAMAGE, :Neo3ConductionEffect], [EFFECT_AI, :Neo3Conduction_AIEffect]
  neo3_cmds "Floodlight",         [EFFECT_BEFORE_DAMAGE, :Neo3FloodlightEffect], [EFFECT_AI, :Neo3Floodlight_AIEffect]
  neo3_cmds "BubbleJump",         [EFFECT_AFTER_DAMAGE, :Neo3BubbleJumpEffect]
  neo3_cmds "PulseGuard",         [EFFECT_BEFORE_DAMAGE, :Neo3PulseGuardEffect]
  neo3_cmds "ThunderNeedle",      [EFFECT_BEFORE_DAMAGE, :Neo3ThunderNeedleEffect], [EFFECT_AI, :Neo3ThunderNeedle_AIEffect]
  neo3_cmds "WashAway",           [EFFECT_BEFORE_DAMAGE, :Neo3WashAwayEffect]
  neo3_cmds "Hypnoshower",        [EFFECT_BEFORE_DAMAGE, :SleepEffect], [EFFECT_AFTER_DAMAGE, :Neo3HypnoshowerEffect]
  neo3_cmds "SeethingAnger",      [EFFECT_BEFORE_DAMAGE, :Neo3SeethingAngerEffect], [EFFECT_AI, :Neo3SeethingAnger_AIEffect]
  neo3_cmds "FocusEnergy",        [EFFECT_BEFORE_DAMAGE, :Neo3FocusEnergyEffect]
  neo3_cmds "BounceOff",          [EFFECT_AFTER_DAMAGE, :Neo3BounceOffEffect]
  neo3_cmds "MagneticWave",       [EFFECT_BEFORE_DAMAGE, :Neo3MagneticWaveEffect], [EFFECT_AI, :Neo3MagneticWaveEffect]
  neo3_cmds "StaticElectricity",  [EFFECT_INITIAL_EFFECT_1, :Neo3StaticElectricity_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3StaticElectricityEffect]
  neo3_cmds "BubbleBomb",         [EFFECT_BEFORE_DAMAGE, :Neo3BubbleBomb_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3BubbleBomb_RecoilEffect]
  neo3_cmds "SuperPsywave",       [EFFECT_AFTER_DAMAGE, :Neo3SuperPsywaveEffect], [EFFECT_AI, :Neo3SuperPsywave_AIEffect]
  neo3_cmds "NightEyes",          [EFFECT_BEFORE_DAMAGE, :SleepEffect], [EFFECT_AFTER_DAMAGE, :Neo3NightEyesEffect]
  neo3_cmds "PerishSong",         [EFFECT_BEFORE_DAMAGE, :Neo3PerishSongEffect], [EFFECT_AI, :Neo3PerishSongEffect]
  neo3_cmds "MurkrowCallForFamily", [EFFECT_INITIAL_EFFECT_1, :Neo3CallForFamily_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3CallForFamilyEffect]
  neo3_cmds "FlockAttack",        [EFFECT_BEFORE_DAMAGE, :Neo3FlockAttackEffect], [EFFECT_AI, :Neo3FlockAttack_AIEffect]
  neo3_cmds "Telekinesis",        [EFFECT_AFTER_DAMAGE, :Neo3TelekinesisEffect], [EFFECT_AI, :Neo3Telekinesis_AIEffect]
  neo3_cmds "WaterOfEvolution",   [EFFECT_INITIAL_EFFECT_1, :Neo3WaterOfEvolution_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3WaterOfEvolutionEffect]
  neo3_cmds "DragOff",            [EFFECT_BEFORE_DAMAGE, :Neo3DragOffEffect]
  neo3_cmds "Endure",             [EFFECT_BEFORE_DAMAGE, :Neo3EndureEffect]
  neo3_cmds "Zzzap",              [EFFECT_AFTER_DAMAGE, :Neo3ZzzapEffect]
  neo3_cmds "Freeze",             [EFFECT_AFTER_DAMAGE, :Neo3FreezeEffect]
  neo3_cmds "EnergySplash",       [EFFECT_AFTER_DAMAGE, :Neo3EnergySplashEffect]
  neo3_cmds "BellyDrum",          [EFFECT_AFTER_DAMAGE, :Neo3BellyDrumEffect]
  neo3_cmds "DustDevil",          [EFFECT_AFTER_DAMAGE, :Neo3DustDevilEffect]
  neo3_cmds "LightningTackle",    [EFFECT_BEFORE_DAMAGE, :Neo3RecoilCoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3RecoilOnTails20Effect]
  neo3_cmds "Sharpshooting",      [EFFECT_AFTER_DAMAGE, :Neo3SharpshootingEffect]
  neo3_cmds "LightningStrike",    [EFFECT_BEFORE_DAMAGE, :Neo3LightningStrikeEffect], [EFFECT_AI, :Neo3LightningStrike_AIEffect]
  neo3_cmds "Plasma",             [EFFECT_AFTER_DAMAGE, :Neo3PlasmaEffect]
  neo3_cmds "WaterBullet",        [EFFECT_BEFORE_DAMAGE, :Neo3WaterBulletEffect], [EFFECT_AI, :Neo3WaterBullet_AIEffect]
  neo3_cmds "WhiteHotFlame",      [EFFECT_INITIAL_EFFECT_1, :Neo3WhiteHotFlame_CheckEffect], [EFFECT_BEFORE_DAMAGE, :Neo3RecoilCoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3WhiteHotFlameEffect]
  neo3_cmds "Outrage",            [EFFECT_BEFORE_DAMAGE, :Neo3OutrageEffect], [EFFECT_AI, :Neo3Outrage_AIEffect]
  neo3_cmds "Devastate",          [EFFECT_INITIAL_EFFECT_1, :Neo3Devastate_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3DevastateEffect]
  neo3_cmds "LightningCut",       [EFFECT_BEFORE_DAMAGE, :Neo3LightningCut_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3LightningCut_AfterEffect]
  neo3_cmds "WaterSlash",         [EFFECT_BEFORE_DAMAGE, :Neo3WaterSlashEffect], [EFFECT_AI, :Neo3WaterSlashEffect]
  neo3_cmds "GoldScale",          [EFFECT_AFTER_DAMAGE, :Neo3GoldScaleEffect]
  neo3_cmds "DragonBond",         [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :Neo3DragonBondEffect]
  neo3_cmds "FlashSearch",        [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_AFTER_DAMAGE, :Neo3FlashSearchEffect]
  neo3_cmds "MysticFire",         [EFFECT_BEFORE_DAMAGE, :Neo3MysticFireEffect]
  neo3_cmds "ReflectShield",      [EFFECT_BEFORE_DAMAGE, :Neo3ReflectShieldEffect]
  neo3_cmds "Psyburst",           [EFFECT_BEFORE_DAMAGE, :Neo3PsyburstEffect], [EFFECT_AI, :Neo3Psyburst_AIEffect]
  neo3_cmds "Thundersquall",      [EFFECT_AFTER_DAMAGE, :Neo3ThundersquallEffect]
  neo3_cmds "CrushingEarth",      [EFFECT_BEFORE_DAMAGE, :Neo3CrushingEarth_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3CrushingEarthEffect], [EFFECT_AI, :Neo3HalfDamage_AIEffect]
  neo3_cmds "MountainCrush",      [EFFECT_AFTER_DAMAGE, :Neo3MountainCrushEffect]
  neo3_cmds "DestructiveFire",    [EFFECT_BEFORE_DAMAGE, :Neo3DestructiveFire_CoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3DestructiveFireEffect], [EFFECT_AI, :Neo3HalfDamage_AIEffect]
  neo3_cmds "MindBlast",          [EFFECT_BEFORE_DAMAGE, :Neo3MindBlastEffect], [EFFECT_AI, :Neo3MindBlast_AIEffect]
  neo3_cmds "FishingTail",        [EFFECT_INITIAL_EFFECT_1, :Neo3FishingTail_CheckEffect], [EFFECT_AFTER_DAMAGE, :Neo3FishingTailEffect]
  neo3_cmds "Psykiss",            [EFFECT_AFTER_DAMAGE, :Neo3PsykissEffect]
  neo3_cmds "BeatUp",             [EFFECT_BEFORE_DAMAGE, :Neo3BeatUpEffect], [EFFECT_AI, :Neo3BeatUp_AIEffect]
  neo3_cmds "AuroraWave",         [EFFECT_BEFORE_DAMAGE, :Neo3AuroraWaveEffect]
  neo3_cmds "Trample",            [EFFECT_AFTER_DAMAGE, :Neo3TrampleEffect]
  neo3_cmds "FeintAttack",        [EFFECT_AFTER_DAMAGE, :Neo3FeintAttackEffect], [EFFECT_AI, :Neo3FeintAttack_AIEffect]
  neo3_cmds "HiddenPower",        [EFFECT_BEFORE_DAMAGE, :Neo3HiddenPowerEffect], [EFFECT_AI, :Neo3HiddenPowerEffect]
  neo3_cmds "Join",               [EFFECT_INITIAL_EFFECT_1, :Neo3Join_CheckUse], [EFFECT_BEFORE_DAMAGE, :Neo3JoinEffect]
  neo3_cmds "GiantWave",          [EFFECT_AFTER_DAMAGE, :Neo3NoAttackNextTurnEffect]
  neo3_cmds "Counter",            [EFFECT_BEFORE_DAMAGE, :Neo3CounterEffect]
  neo3_cmds "Slime",              [EFFECT_BEFORE_DAMAGE, :Neo3SlimeEffect]
  neo3_cmds "LightningStorm",     [EFFECT_BEFORE_DAMAGE, :Neo3RecoilCoinEffect], [EFFECT_AFTER_DAMAGE, :Neo3LightningStormEffect]
  neo3_cmds "MasterBall",         [EFFECT_INITIAL_EFFECT_1, :Neo3DeckCheck], [EFFECT_BEFORE_DAMAGE, :Neo3MasterBallEffect]
  neo3_cmds "NewPokedex",         [EFFECT_INITIAL_EFFECT_1, :Pokedex_DeckCheck], [EFFECT_DISCARD_ENERGY, :Neo3ShuffleDeckEffect],
                                  [EFFECT_REQUIRE_SELECTION, :Pokedex_PlayerSelection], [EFFECT_BEFORE_DAMAGE, :Pokedex_OrderDeckCardsEffect]

  { :Neo3Bonfire_CoinEffect => "If Heads, discard 1 <FIRE> Energy\nand 10 damage to each Pokémon.",
    :Neo3Gigaspark_CoinEffect => "If Heads, opponent is Paralyzed\nand 10 damage to each Bench.",
    :Neo3IceCyclone_CoinEffect => "Heads: 10 to opponent's Bench.\nTails: 10 to all your Pokémon.",
    :Neo3StunPoisonEffect => "If Heads, opponent is\nParalyzed and Poisoned.",
    :Neo3TripleKickEffect => "Damage check!\nIf Heads, x 30 damage!!",
    :Neo3ThunderNeedleEffect => "Damage check!\nIf Heads, x 20 damage!!",
    :Neo3RecoilCoinEffect => "Recoil check!\nIf Tails, damage to yourself!",
    :Neo3AuroraWaveEffect => "Both Heads: Paralyzed.\nOne Heads: Asleep.",
    :Neo3MindBlastEffect => "If Heads, +10 damage\nand opponent is Confused.",
    :Neo3OutrageEffect => "If Tails, no damage!\nIf Heads, + damage counters.",
    :Neo3DodgeEffect => "If Heads, no damage\nduring opponent's next turn." }.each { |fn, t| NEO_COIN_TEXT[fn] = t }

  class Duelist
    # Piloswine's Freeze: can't attack until benched or evolved
    attr_accessor :neo_frozen

    alias_method :tcg_neo3_clear_all_status_conditions, :clear_all_status_conditions
    def clear_all_status_conditions
      tcg_neo3_clear_all_status_conditions
      @neo_frozen = false
    end
  end

  class Duel
    attr_accessor :neo_end_turn   # Playful Punch / Howl end the turn

    alias_method :tcg_neo3_init_variables_to_begin_turn, :init_variables_to_begin_turn
    def init_variables_to_begin_turn
      tcg_neo3_init_variables_to_begin_turn
      @neo_end_turn = false
    end

    def side_of(d); @duelists.index(d); end

    # number of `id` Pokemon whose power works for duelist d (any slot)
    def neo3_power_count(d, id)
      return 0 if toxic_gas_active?
      d.play_area.each_index.select { |e| d.play_area[e] }.count { |e| d.card_id(d.play_area[e]) == id && !incapable_of_using_pkmn_power?(d, e) }
    end

    def neo3_in_play?(d, id)
      d.play_area.each_index.select { |e| d.play_area[e] }.any? { |e| d.card_id(d.play_area[e]) == id }
    end

    # Pokemon in play (alive), as [duelist, slot], turn holder first
    def neo3_all_pokemon
      [turn_duelist, non_turn_duelist].flat_map do |d|
        (0...d.num_in_play_area).select { |e| d.slot_hp[e] > 0 }.map { |e| [d, e] }
      end
    end

    # the attacker picks 1 of the opponent's Pokemon (Active included)
    def neo3_pick_opponent_pokemon(purpose, dmg = 0)
      nd = non_turn_duelist
      slots = (0...nd.num_in_play_area).select { |e| nd.slot_hp[e] > 0 }
      return nil if slots.empty?
      unless neo_human_choice?
        ko = slots.select { |e| nd.slot_hp[e] <= dmg }
        return (ko.empty? ? [PLAY_AREA_ARENA] : ko).max_by { |e| nd.card(nd.play_area[e]).hp }
      end
      @ui.message(_INTL("Choose 1 of your opponent's Pokémon."))
      sel = as_non_turn { effect_choice(:play_area, purpose, slots, false) }
      slots.include?(sel) ? sel : slots.first
    end

    # damage to any of the opponent's Pokemon without Weakness / Resistance
    def neo3_damage_opponent_any(e, n)
      e == PLAY_AREA_ARENA ? neo3_damage_opponent_arena(n) : neo_damage_opponent_slot(e, n)
    end

    def neo3_damage_opponent_arena(n)
      nd = non_turn_duelist
      return if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0
      as_non_turn { deal_damage_to_play_area_pokemon(PLAY_AREA_ARENA, n, :ATK_ANIM_HIT) }
    end

    # damage counters on the opponent's slot e (Psychic Damage, Super Psywave)
    def neo3_counters_on_opponent(e, n)
      nd = non_turn_duelist
      return if n <= 0 || nd.play_area[e].nil? || nd.slot_hp[e] == 0
      return if e == PLAY_AREA_ARENA && @atk.no_damage_or_effect != 0
      subtract_hp(nd, e, 10 * n)
      @ui.message(_INTL("{1} damage counter(s) were put on {2}.", n, nd.card(nd.play_area[e]).name))
      @ui.refresh(self)
      @ui.message(_INTL("{1} was Knocked Out!", nd.card(nd.play_area[e]).name)) if nd.slot_hp[e] == 0
    end

    # the turn holder's own Pokemon at slot e takes n (no Weakness/Resistance)
    def neo3_damage_own(e, n)
      d = turn_duelist
      return if d.play_area[e].nil? || d.slot_hp[e] == 0
      subtract_hp(d, e, n)
      @ui.message(_INTL("{1} took {2} damage.", d.card(d.play_area[e]).name, n))
      @ui.message(_INTL("{1} was Knocked Out!", d.card(d.play_area[e]).name)) if d.slot_hp[e] == 0
    end

    # basic Energy cards of `type` (:LIGHTNING_ENERGY...) attached to slot e
    def neo3_attached(d, e, id)
      d.cards_in_slot(e).select { |i| d.card_id(i) == id }
    end

    # the player picks n Energy cards attached to the Defending Pokemon to
    # discard (all of them if fewer)
    def neo3_discard_defending_energy(n, purpose)
      nd = non_turn_duelist
      return if nd.arena.nil? || n <= 0
      list = nd.energy_cards_in_slot(PLAY_AREA_ARENA)
      picked = []
      while picked.size < n && !list.empty?
        sel = neo_human_choice? ? as_non_turn { effect_choice(:card, purpose, list, false) } : nil
        sel = list.first unless list.include?(sel)
        picked << list.delete(sel)
      end
      picked.each { |i| nd.put_card_in_discard_pile(i) }
      @ui.message(_INTL("{1} Energy card(s) were discarded from {2}.", picked.size, nd.card(nd.arena).name)) unless picked.empty?
      @ui.refresh(self)
    end

    # the turn holder's player picks one of the alive benched Pokemon of d
    def neo3_pick_own_bench(purpose, slots)
      return nil if slots.empty?
      sel = neo_human_choice? ? effect_choice(:play_area, purpose, slots, false) : nil
      slots.include?(sel) ? sel : slots.max_by { |e| turn_duelist.slot_hp[e] }
    end

    # the turn holder switches its Active with a benched Pokemon (picked)
    def neo3_switch_own_active(purpose)
      d = turn_duelist
      e = neo3_pick_own_bench(purpose, neo_alive_bench(d)) or return
      d.swap_arena_with_bench_pokemon(e)
      @ui.message(_INTL("{1} is now the Active Pokémon.", d.card(d.arena).name))
      @ui.refresh(self)
    end

    # outside an attack: the opponent switches its Active (they choose)
    def neo3_opponent_switches_now
      nd = non_turn_duelist
      slots = neo_alive_bench(nd)
      return if slots.empty?
      sel = @controllers[1 - @turn].effect_choice(self, :play_area, :ForcedSwitch, slots, false)
      sel = slots.first unless slots.include?(sel)
      nd.swap_arena_with_bench_pokemon(sel)
      @ui.message(_INTL("{1} is now the opponent's Active Pokémon.", nd.card(nd.arena).name))
      @ui.refresh(self)
    end

    # a Pokemon in play and everything attached to it go into its owner's deck
    def neo3_shuffle_into_deck(d, e)
      cards = d.cards_in_slot(e)
      name = d.card(d.play_area[e]).name
      d.empty_play_area_slot(e)
      cards.each { |i| d.return_card_to_deck(i) }
      side = side_of(d)
      side == @turn ? shuffle_cards_in_deck : as_non_turn { shuffle_cards_in_deck }
      @ui.message(_INTL("{1} and its cards were shuffled into the deck.", name))
      @ui.refresh(self)
    end

    # discard the top n cards of d's deck
    def neo3_mill(d, n)
      k = 0
      n.times do
        i = d.draw_card_from_deck or break
        d.put_card_in_discard_pile(i)
        k += 1
      end
      @ui.message(_INTL("{1} discarded the top {2} card(s) of the deck.", d.name, k))
      @ui.refresh(self)
      k
    end

    # Energy attached beyond `need` (count of Energy cards; DCE counts 2)
    def neo3_extra_energy(e, need, d = turn_duelist)
      [d.attached_energies(e)[1] - need, 0].max
    end
  end

  #----------------------------------------------------------------------------
  # Energy attaching: Water Immunity / Anti-Lightning, Crystal Type
  # (Kingdra), Conductivity, Lightning Burst
  #----------------------------------------------------------------------------
  NEO3_ENERGY_IMMUNITY = { :ARTICUNO => :WATER_ENERGY, :ZAPDOS => :LIGHTNING_ENERGY }

  class Duel
    def neo3_energy_immunity_blocks?(d, idx, e)
      id = d.play_area[e] && d.card_id(d.play_area[e])
      NEO3_ENERGY_IMMUNITY[id] == d.card_id(idx) && !toxic_gas_active?
    end

    alias_method :tcg_neo3_can_play_energy?, :can_play_energy?
    def can_play_energy?(idx, e)
      return false if neo3_energy_immunity_blocks?(turn_duelist, idx, e)
      tcg_neo3_can_play_energy?(idx, e)
    end

    alias_method :tcg_neo3_play_energy_card, :play_energy_card
    def play_energy_card(idx, e)
      d = turn_duelist
      return :energy_immunity if neo3_energy_immunity_blocks?(d, idx, e)
      r = tcg_neo3_play_energy_card(idx, e)
      return r unless r == :ok
      target = d.play_area[e]
      c = d.card(idx)
      # Crystal Type: a basic Water, Lightning or Psychic Energy changes Kingdra's color
      if d.card_id(target) == :KINGDRA_LV48 && c.basic_energy? &&
         [WATER, LIGHTNING, PSYCHIC].include?(c.color) && neo_power_works?(d, e)
        d.slot_changed_type[e] = HAS_CHANGED_COLOR | c.color
        neo_fx[:crystal_type] = [@turn, target, @duel_turns]
        @ui.message(_INTL("{1}'s Pokémon Power: Crystal Type", d.card(target).name))
        @ui.refresh(self)
      end
      # Lightning Burst: the opponent switches its Active
      if d.card_id(target) == :RAIKOU && d.card_id(idx) == :LIGHTNING_ENERGY && neo_power_works?(d, e) &&
         !neo_alive_bench(non_turn_duelist).empty?
        @ui.message(_INTL("{1}'s Pokémon Power: Lightning Burst", d.card(target).name))
        neo3_opponent_switches_now
      end
      # Conductivity: 10 damage to the Pokemon the Energy went to
      nd = non_turn_duelist
      if neo3_power_count(nd, :DARK_AMPHAROS) == 1 &&
         (0...nd.num_in_play_area).count { |x| nd.card_id(nd.play_area[x]) == :DARK_AMPHAROS } == 1 &&
         d.slot_hp[e] > 0
        @ui.message(_INTL("Dark Ampharos's Pokémon Power: Conductivity"))
        neo3_damage_own(e, 10)
        @ui.refresh(self)
        handle_between_turn_knock_outs if d.slot_hp[e] == 0
      end
      r
    end
  end

  #----------------------------------------------------------------------------
  # Deep Sleep: 2 coins at the Sleep check, both Heads to wake up
  #----------------------------------------------------------------------------
  class Duel
    alias_method :tcg_neo3_handle_sleep_check, :handle_sleep_check
    def handle_sleep_check(d)
      return tcg_neo3_handle_sleep_check(d) unless (d.status & CNF_SLP_PRZ) == ASLEEP
      return tcg_neo3_handle_sleep_check(d) if @duelists.all? { |x| neo3_power_count(x, :DARK_GENGAR) == 0 }
      name = d.card(d.arena).name
      coin_check(_INTL("{1} is still asleep. Deep Sleep! If both coins are Heads, it wakes up.", name),
                 "#{name}'s Sleep check.\nDeep Sleep: 2 coins!")
      if toss_coins(2, d.name) == 2
        d.status &= DOUBLE_POISONED
        @ui.shows_card_screens? ? @ui.event(:status_anim, d.name, :cured_sleep) : @ui.message(_INTL("{1} woke up.", name))
      elsif @ui.shows_card_screens?
        @ui.event(:status_anim, d.name, :still_asleep)
      end
      @ui.refresh(self)
    end
  end

  #----------------------------------------------------------------------------
  # damage: Thick Shell, Dense Body, Dodge, Pulse Guard, Slime, Endure,
  # Reflect Shield, Protective Flame (turn holder = the damaged side)
  #----------------------------------------------------------------------------
  class Duel
    alias_method :tcg_neo3_damage_reduction_from_pkmn_power, :damage_reduction_from_pkmn_power
    def damage_reduction_from_pkmn_power(dmg)
      dmg = tcg_neo3_damage_reduction_from_pkmn_power(dmg)
      return dmg if @atk.pokemon_power? || dmg <= 0
      attacker = @atk.temp_turn_card_id && TCG.card(@atk.temp_turn_card_id)
      case @atk.temp_non_turn_card_id
      when :KABUTO_NEO
        dmg -= 10 if attacker && attacker.pokemon? && !attacker.basic?
      when :SLOWBRO_NEO
        dmg -= 20 if attacker && attacker.basic? && !attacker.baby?
      end
      [dmg, 0].max
    end

    alias_method :tcg_neo3_handle_damage_reduction_except_substatus2, :handle_damage_reduction_except_substatus2
    def handle_damage_reduction_except_substatus2(dmg)
      dmg = tcg_neo3_handle_damage_reduction_except_substatus2(dmg)
      return dmg if dmg <= 0 || @atk.is_damage_to_self
      d = turn_duelist
      if @neo3_ai_calc
        return 0 if d.substatus1 == SUBSTATUS1_PULSE_GUARD && dmg >= 30
        return [dmg, d.slot_hp[PLAY_AREA_ARENA] - 10].min if d.substatus1 == SUBSTATUS1_ENDURE && d.slot_hp[PLAY_AREA_ARENA] > 10
        return dmg
      end
      case d.substatus1
      when SUBSTATUS1_DODGE
        coin_check(_INTL("Dodge! If Heads, {1} takes no damage.", d.card(d.arena).name), NEO_COIN_TEXT[:Neo3DodgeEffect])
        return 0 if toss_coin(d.name) == HEADS
      when SUBSTATUS1_PULSE_GUARD
        return 0 if dmg >= 30
      when SUBSTATUS1_SLIME
        coin_check(_INTL("Slime! If Tails, the attack does no damage."), "Slime check!\nIf Tails, no damage!")
        return 0 if as_non_turn { toss_coin } == TAILS
      when SUBSTATUS1_ENDURE
        hp = d.slot_hp[PLAY_AREA_ARENA]
        if dmg >= hp && hp > 10
          @ui.message(_INTL("{1} endured the hit!", d.card(d.arena).name))
          return hp - 10
        end
      when SUBSTATUS1_REFLECT
        coin_check(_INTL("Reflect Shield! If Heads, no damage and 20 damage to the attacker."),
                   "Reflect Shield check!\nIf Heads, 20 damage back!")
        if toss_coin(d.name) == HEADS
          a = non_turn_duelist
          if a.arena && a.slot_hp[PLAY_AREA_ARENA] > 0
            subtract_hp(a, PLAY_AREA_ARENA, 20)
            @ui.message(_INTL("{1} took 20 damage from Reflect Shield.", a.card(a.arena).name))
          end
          return 0
        end
      end
      dmg
    end

    # Protective Flame: no damage or effects to the protected Bench
    alias_method :tcg_neo3_deal_damage_to_play_area_pokemon, :deal_damage_to_play_area_pokemon
    def deal_damage_to_play_area_pokemon(e, dmg, anim = :ATK_ANIM_BENCH_HIT)
      if e != PLAY_AREA_ARENA && @atk && !@atk.pokemon_power? && !@atk.is_damage_to_self &&
         neo_fx_active?(:protective_flame, @turn)
        @ui.message(_INTL("Protective Flame prevented the damage to the Bench."))
        return
      end
      tcg_neo3_deal_damage_to_play_area_pokemon(e, dmg, anim)
    end

    # Counter: after the attack's damage, heads = the same damage back
    alias_method :tcg_neo3_handle_after_damage_effects, :handle_after_damage_effects
    def handle_after_damage_effects
      nd = non_turn_duelist
      d = turn_duelist
      if nd.substatus1 == SUBSTATUS1_COUNTER && @atk.dealt_damage > 0 && d.arena && d.slot_hp[PLAY_AREA_ARENA] > 0
        coin_check(_INTL("Counter! If Heads, {1} takes the same damage.", d.card(d.arena).name), "Counter check!\nIf Heads, damage back!")
        if as_non_turn { toss_coin } == HEADS
          subtract_hp(d, PLAY_AREA_ARENA, @atk.dealt_damage)
          @ui.message(_INTL("{1} took {2} damage from Counter.", d.card(d.arena).name, @atk.dealt_damage))
          @ui.refresh(self)
          @ui.message(_INTL("{1} was Knocked Out!", d.card(d.arena).name)) if d.slot_hp[PLAY_AREA_ARENA] == 0
        end
      end
      neo3_time_travel_or_bolt
      tcg_neo3_handle_after_damage_effects
    end

    # Time Travel (Celebi): heads = not Knocked Out, back into the deck.
    # Bolt (Entei promo): damaged but not Knocked Out, heads = back into the deck.
    def neo3_time_travel_or_bolt
      nd = non_turn_duelist
      return if nd.arena.nil? || @atk.pokemon_power?
      id = nd.card_id(nd.arena)
      return unless [:CELEBI, :ENTEI_LV40].include?(id)
      return unless as_non_turn { neo_power_works?(turn_duelist, PLAY_AREA_ARENA) }
      hp = nd.slot_hp[PLAY_AREA_ARENA]
      name = nd.card(nd.arena).name
      if id == :CELEBI
        return unless hp == 0 && @atk.dealt_damage > 0
        coin_check(_INTL("Time Travel! If Heads, {1} isn't Knocked Out.", name), "Time Travel check!\nIf Heads, back to the Deck!")
      else
        return unless hp > 0 && @atk.dealt_damage > 0
        coin_check(_INTL("Bolt! If Heads, {1} returns to the deck.", name), "Bolt check!\nIf Heads, back to the Deck!")
      end
      return if as_non_turn { toss_coin } == TAILS
      neo3_shuffle_into_deck(nd, PLAY_AREA_ARENA)
    end
  end

  #----------------------------------------------------------------------------
  # can't attack (Freeze, Giant Wave, Crushing Earth), can't evolve (Dark
  # Tentacle), Stun Wave, Crystal Body, Suction Cups, Mind Games
  #----------------------------------------------------------------------------
  class Duel
    alias_method :tcg_neo3_handle_cant_attack_substatus, :handle_cant_attack_substatus
    def handle_cant_attack_substatus(d)
      return :neo_frozen if d.neo_frozen
      return :neo_no_attack if d.arena && neo_fx_active?(:no_attack, side_of(d), d.arena)
      tcg_neo3_handle_cant_attack_substatus(d)
    end

    def neo3_cant_evolve_slot?(e)
      d = turn_duelist
      d.play_area[e] && neo_fx_active?(:dark_tentacle, @turn, d.play_area[e])
    end

    alias_method :tcg_neo3_evolution_targets, :evolution_targets
    def evolution_targets(idx)
      tcg_neo3_evolution_targets(idx).reject { |e| neo3_cant_evolve_slot?(e) }
    end

    alias_method :tcg_neo3_cant_evolve_reason, :cant_evolve_reason
    def cant_evolve_reason(idx)
      r = tcg_neo3_cant_evolve_reason(idx)
      return r if r
      evolution_targets(idx).empty? ? :neo_cant_evolve : nil
    end

    alias_method :tcg_neo3_evolve_pokemon, :evolve_pokemon
    def evolve_pokemon(idx, e)
      return :neo_cant_evolve if neo3_cant_evolve_slot?(e)
      tcg_neo3_evolve_pokemon(idx, e)
    end

    alias_method :tcg_neo3_incapable_of_using_pkmn_power?, :incapable_of_using_pkmn_power?
    def incapable_of_using_pkmn_power?(d, e)
      return true if d.play_area[e] && neo_fx_active?(:stun_wave, side_of(d), d.play_area[e])
      tcg_neo3_incapable_of_using_pkmn_power?(d, e)
    end

    # Crystal Body: no effects other than damage from the opponent's attacks
    def neo3_crystal_body?
      nd = non_turn_duelist
      nd.arena && nd.card_id(nd.arena) == :SUICUNE && as_non_turn { neo_power_works?(turn_duelist, PLAY_AREA_ARENA) }
    end

    alias_method :tcg_neo3_queue_status, :queue_status
    def queue_status(keep_mask, status)
      if @turn == @whose_turn && neo3_crystal_body?
        set_no_effect_from_status
        return false
      end
      tcg_neo3_queue_status(keep_mask, status)
    end

    alias_method :tcg_neo3_apply_substatus2_to_defending_card, :apply_substatus2_to_defending_card
    def apply_substatus2_to_defending_card(v)
      return if neo3_crystal_body?
      tcg_neo3_apply_substatus2_to_defending_card(v)
    end

    # Suction Cups: retreating from Octillery discards all of that Pokemon's Energy
    alias_method :tcg_neo3_attempt_retreat, :attempt_retreat
    def attempt_retreat(energy_cards, bench_slot)
      r = tcg_neo3_attempt_retreat(energy_cards, bench_slot)
      return r unless r == :ok
      nd = non_turn_duelist
      if nd.arena && nd.card_id(nd.arena) == :OCTILLERY && as_non_turn { neo_power_works?(turn_duelist, PLAY_AREA_ARENA) }
        d = turn_duelist
        list = d.energy_cards_in_slot(bench_slot)
        unless list.empty?
          list.each { |i| d.put_card_in_discard_pile(i) }
          @ui.message(_INTL("Suction Cups! {1} Energy card(s) were discarded.", list.size))
          @ui.refresh(self)
        end
      end
      r
    end

    # Mind Games: the opponent's Slowking may stop a Trainer card (heads)
    alias_method :tcg_neo3_play_trainer_card, :play_trainer_card
    def play_trainer_card(idx)
      d = turn_duelist
      nd = non_turn_duelist
      slots = (0...nd.num_in_play_area).select { |e| nd.card_id(nd.play_area[e]) == :SLOWKING }
      if !cant_use_trainer_due_to_effect?(d) && slots.any? { |e| as_non_turn { neo_power_works?(turn_duelist, e) } }
        @atk = AttackContext.new
        @atk.card_index  = idx
        @atk.card_id     = d.card_id(idx)
        @atk.effect_name = d.card(idx).effect
        return :cant_use if try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
        ctrl = @controllers[1 - @turn]
        use = ctrl.is_a?(PlayerController) ? ctrl.effect_choice(self, :yes_no, :NeoMindGames, [true, false], false) : true
        if use
          @ui.message(_INTL("Slowking's Pokémon Power: Mind Games"))
          coin_check(_INTL("Mind Games! If Heads, {1} does nothing.", d.card(idx).name), "Mind Games check!\nIf Heads, the card fails!")
          if as_non_turn { toss_coin } == HEADS
            d.remove_card_from_hand(idx)
            d.return_card_to_deck(idx)
            @ui.message(_INTL("{1} did nothing and was put on top of the deck.", d.card(idx).name))
            @ui.refresh(self)
            return :ok
          end
        end
      end
      tcg_neo3_play_trainer_card(idx)
    end
  end



  #----------------------------------------------------------------------------
  # shared effects
  #----------------------------------------------------------------------------
  effect(:Neo3DeckCheck)       { |du| du.deck_empty_text }
  effect(:Neo3ShuffleDeckEffect) { |du| du.shuffle_cards_in_deck; false }
  effect(:Neo3Recoil10Effect)  { |du| du.deal_recoil_damage_to_self(10); false }
  effect(:Neo3HalfDamage_AIEffect) { |du| d = du.atk.damage; du.set_expected_ai_damage(d / 2, 0, d); false }

  # coin before damage; tails = recoil after it (Lightning Tackle, White-hot Flame, Lightning Storm)
  effect(:Neo3RecoilCoinEffect) do |du|
    du.coin_check(_INTL("Recoil check! If Tails, the attacker takes damage."), NEO_COIN_TEXT[:Neo3RecoilCoinEffect])
    du.set_temp(:recoil, du.toss_coin == TAILS)
    false
  end
  effect(:Neo3RecoilOnTails20Effect) { |du| du.deal_recoil_damage_to_self(20) if du.temp(:recoil); false }

  # once per turn, Active only (Jet Stream)
  effect(:Neo3ActiveOncePower_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only while it is your Active Pokémon.") if slot != PLAY_AREA_ARENA
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end

  #----------------------------------------------------------------------------
  # Alakazam
  #----------------------------------------------------------------------------
  effect(:Neo3Psymimic_CheckEffect) do |du|
    next _INTL("Not while affected by a Special Condition.") if du.turn_duelist.status != NO_STATUS
    du.defending_pokemon_has_any_attack? ? false : _INTL("No attack may be chosen.")
  end
  effect(:Neo3Psymimic_CopyEffect) do |du|
    d = du.turn_duelist
    nd = du.non_turn_duelist
    sel = du.effect_choice(:attack, :Metronome, du.defending_pokemon_attack_options, true)
    next true if sel.nil?
    copied = nd.card(sel[0]).attacks[sel[1]]
    # its Energy cost too
    en, total = du.attached_energies_with_energy_burn(d, PLAY_AREA_ARENA)
    need = 0
    ok = NUM_COLORED_TYPES.times.all? { |col| need += copied.cost[col]; copied.cost[col] <= en[col] }
    unless ok && total - need >= copied.cost[COLORLESS]
      du.ui.message(_INTL("Not enough Energy for {1}.", copied.name))
      next true
    end
    du.atk.attack      = copied
    du.atk.effect_name = copied.effect
    du.atk.damage      = copied.damage
    du.atk.card_id     = nd.card_id(sel[0])
    next true if du.try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
    next true if du.try_execute_effect_command(EFFECT_INITIAL_EFFECT_2)
    false
  end
  effect(:Neo3SyncroblastEffect) do |du|
    d = du.turn_duelist
    nd = du.non_turn_duelist
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    mine = d.energy_cards_in_slot(e).size
    theirs = nd.arena ? nd.energy_cards_in_slot(PLAY_AREA_ARENA).size : 0
    du.set_definite_damage(20) if mine != theirs
    false
  end

  #----------------------------------------------------------------------------
  # Ampharos / Azumarill: heads = Paralyzed + 10 to each Benched
  #----------------------------------------------------------------------------
  effect(:Neo3Gigaspark_CoinEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is Paralyzed and 10 damage to each Benched Pokémon."), NEO_COIN_TEXT[:Neo3Gigaspark_CoinEffect])
    heads = du.toss_coin == HEADS
    du.set_temp(:giga, heads)
    du.queue_status(PSN_DBLPSN, PARALYZED) if heads
    false
  end
  effect(:Neo3Gigaspark_BenchEffect) do |du|
    du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) } if du.temp(:giga)
    false
  end

  #----------------------------------------------------------------------------
  # Articuno
  #----------------------------------------------------------------------------
  effect(:Neo3FreezeSolidEffect) do |du|
    d = du.turn_duelist
    i = d.discard_pile.find { |k| d.card_id(k) == :WATER_ENERGY } or next false
    du.coin_check(_INTL("If Heads, attach 1 Water Energy card from your Discard Pile."), "If Heads, attach 1 <WATER> Energy\nfrom your Discard Pile.")
    next false unless du.toss_coin == HEADS
    du.neo_attach_from_discard(i)
    du.ui.message(_INTL("A Water Energy card was attached from the Discard Pile."))
    du.ui.refresh(du); false
  end
  effect(:Neo3IceCyclone_CoinEffect) do |du|
    du.coin_check(_INTL("Heads: 10 damage to each of your opponent's Benched Pokémon. Tails: 10 damage to each of your Pokémon."), NEO_COIN_TEXT[:Neo3IceCyclone_CoinEffect])
    du.set_temp(:cyclone, du.toss_coin)
    false
  end
  effect(:Neo3IceCyclone_BenchEffect) do |du|
    if du.temp(:cyclone) == HEADS
      du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    else
      du.deal_recoil_damage_to_self(10)
      du.atk.is_damage_to_self = true
      du.deal_damage_to_all_benched_pokemon(10)
      du.atk.is_damage_to_self = false
    end
    false
  end

  #----------------------------------------------------------------------------
  # Blastoise
  #----------------------------------------------------------------------------
  effect(:Neo3JetStreamEffect) do |du|
    d = du.turn_duelist
    d.slot_flags[PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
    du.coin_check(_INTL("Jet Stream! If Heads, discard an Energy from Blastoise and 1 from the Defending Pokémon."),
                  "If Heads, discard 1 Energy from\neach Active Pokémon.")
    next false unless du.toss_coin == HEADS
    mine = d.energy_cards_in_slot(PLAY_AREA_ARENA)
    unless mine.empty?
      sel = du.neo_human_choice? ? du.effect_choice(:card, :NeoJetStream, mine, false) : nil
      d.put_card_in_discard_pile(mine.include?(sel) ? sel : mine.first)
    end
    du.neo3_discard_defending_energy(1, :NeoJetStream)
    false
  end
  # Energy Cannon: +10 per Energy beyond the cost, at most +20
  effect(:Neo3EnergyCannonEffect) do |du|
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    need = du.atk.attack.cost.sum
    du.atk.damage += 10 * [du.neo3_extra_energy(e, need), 2].min
    false
  end

  #----------------------------------------------------------------------------
  # Celebi: 3 coins, 1 damage counter per heads
  #----------------------------------------------------------------------------
  effect(:Neo3PsychicDamageEffect) do |du|
    du.coin_check(_INTL("1 damage counter on the Defending Pokémon for each Heads."), "Flip 3 coins!\n1 damage counter for each Heads.")
    du.neo3_counters_on_opponent(PLAY_AREA_ARENA, du.toss_coins(3))
    false
  end
  effect(:Neo3PsychicDamage_AIEffect) { |du| du.set_expected_ai_damage(15, 0, 30); false }

  #----------------------------------------------------------------------------
  # Charmeleon: Bonfire
  #----------------------------------------------------------------------------
  effect(:Neo3Bonfire_CoinEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("For each Heads, discard 1 Fire Energy; 10 damage to each of your opponent's Pokémon for each."),
                  "Flip 3 coins!\nDiscard 1 <FIRE> Energy for each Heads.")
    heads = du.toss_coins(3)
    fire = du.neo_fire_attached(d, PLAY_AREA_ARENA)
    n = [heads, fire.size].min
    fire.first(n).each { |i| d.put_card_in_discard_pile(i) }
    du.set_temp(:bonfire, n)
    du.set_definite_damage(10 * n)
    du.atk.unaffected_by_wr = true
    du.set_was_unsuccessful if n == 0
    du.ui.refresh(du); false
  end
  effect(:Neo3Bonfire_DamageEffect) do |du|
    n = du.temp(:bonfire).to_i
    du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10 * n) } if n > 0
    false
  end
  effect(:Neo3Bonfire_AIEffect) { |du| du.set_expected_ai_damage(15, 0, 30); false }

  #----------------------------------------------------------------------------
  # Croconaw: Jaw Clamp (no switching / retreat until the end of the opponent's next turn)
  #----------------------------------------------------------------------------
  effect(:Neo3JawClampEffect) do |du|
    next false unless du.atk.no_damage_or_effect == 0
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0
    du.neo_fx[:sticky_nectar] = [1 - du.turn, nd.arena, du.duel_turns + 1, du.turn_duelist.arena]
    nd.switch_lock = -> { du.sticky_nectar_active?(nd) }
    du.ui.message(_INTL("{1} is caught in Croconaw's jaws!", nd.card(nd.arena).name))
    false
  end

  #----------------------------------------------------------------------------
  # Dark Ampharos / Raichu: discard all Lightning Energy
  #----------------------------------------------------------------------------
  effect(:Neo3ShockBoltEffect) do |du|
    d = du.turn_duelist
    du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY).each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Dark Espeon: 10 per Energy to each of the opponent's Pokemon
  #----------------------------------------------------------------------------
  effect(:Neo3PsysplashEffect) do |du|
    nd = du.non_turn_duelist
    (0...nd.num_in_play_area).each do |e|
      n = nd.energy_cards_in_slot(e).size
      next if n == 0 || nd.slot_hp[e] == 0
      du.neo3_damage_opponent_any(e, 10 * n)
    end
    false
  end
  effect(:Neo3Psysplash_AIEffect) do |du|
    nd = du.non_turn_duelist
    n = nd.arena ? 10 * nd.energy_cards_in_slot(PLAY_AREA_ARENA).size : 0
    du.set_expected_ai_damage(n, n, n); false
  end

  #----------------------------------------------------------------------------
  # Dark Flaaffy
  #----------------------------------------------------------------------------
  effect(:Neo3HighVoltageEffect) do |du|
    du.coin_check(_INTL("If Heads, your opponent can't play Trainer cards next turn."), "If Heads, opponent can't use\nTrainer cards next turn.")
    next false unless du.toss_coin == HEADS
    next false if du.check_no_damage_or_effect
    du.non_turn_duelist.substatus3 |= SUBSTATUS3_HEADACHE
    du.ui.message(_INTL("Your opponent can't play Trainer cards during their next turn."))
    false
  end
  effect(:Neo3StunWaveEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0 || du.atk.no_damage_or_effect != 0
    next false unless nd.card(nd.arena).has_pkmn_power?
    du.neo_fx[:stun_wave] = [1 - du.turn, nd.arena, du.duel_turns + 2]
    du.ui.message(_INTL("{1}'s Pokémon Power stopped working.", nd.card(nd.arena).name))
    false
  end

  #----------------------------------------------------------------------------
  # Dark Gengar: Pull In (switch first, then Asleep)
  #----------------------------------------------------------------------------
  effect(:Neo3PullInEffect) do |du|
    nd = du.non_turn_duelist
    slots = du.neo_alive_bench(nd)
    unless slots.empty?
      e = nil
      if du.neo_human_choice?
        e = du.effect_choice(:yes_no, :NeoPullIn, [true, false], false) ? du.neo_pick_opponent_bench(:NeoPullIn) : nil
      else
        e = slots.min_by { |x| nd.slot_hp[x] }
        e = nil if nd.slot_hp[e] >= nd.slot_hp[PLAY_AREA_ARENA]
      end
      if e
        du.handle_switch_defending_pokemon(e)
        du.atk.temp_non_turn_card_id = nd.card_id(nd.arena)
        du.atk.defending_was_forced_to_switch = false
      end
    end
    du.queue_status(PSN_DBLPSN, ASLEEP)
    false
  end

  #----------------------------------------------------------------------------
  # Dark Haunter
  #----------------------------------------------------------------------------
  effect(:Neo3CallBack_CheckEffect) do |du|
    nd = du.non_turn_duelist
    next _INTL("Your opponent's Bench is full.") if nd.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    nd.discard_pile.any? { |i| nd.card(i).basic? } ? false : _INTL("There are no Basic Pokémon in your opponent's Discard Pile.")
  end
  effect(:Neo3CallBackEffect) do |du|
    nd = du.non_turn_duelist
    list = nd.discard_pile.select { |i| nd.card(i).basic? }
    next false if list.empty? || nd.num_in_play_area >= MAX_PLAY_AREA_POKEMON
    i = du.neo_human_choice? ? du.as_non_turn { du.effect_choice(:card, :NeoCallBack, list, false) } : nil
    i = list.min_by { |k| nd.card(k).hp.to_i } unless list.include?(i)
    nd.move_discard_pile_card_to_hand(i)
    e = du.as_non_turn { du.put_basic_pokemon_in_play_area(i) }
    if e
      du.subtract_hp(nd, e, 10)
      du.ui.message(_INTL("{1} was put onto the opponent's Bench with 1 damage counter.", nd.card(i).name))
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3SurroundEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is Asleep. If Tails, it can't retreat."), "Heads: opponent is Asleep.\nTails: opponent can't Retreat.")
    if du.toss_coin == HEADS
      du.queue_status(PSN_DBLPSN, ASLEEP)
    else
      du.apply_substatus2_to_defending_card(SUBSTATUS2_ACID)
    end
    false
  end

  #----------------------------------------------------------------------------
  # Dark Omastar
  #----------------------------------------------------------------------------
  effect(:Neo3PrehistoricWaterEffect) do |du|
    nd = du.non_turn_duelist
    slots = (0...nd.num_in_play_area).select { |e| nd.slot_hp[e] > 0 && nd.slot_stage[e] != BASIC }
    next false if slots.empty?
    e = du.neo_human_choice? ? du.as_non_turn { du.effect_choice(:play_area, :NeoPrehistoricWater, slots, false) } : nil
    e = slots.max_by { |x| nd.slot_stage[x] } unless slots.include?(e)
    du.coin_check(_INTL("If Heads, the highest Stage Evolution card goes back into the deck."), "If Heads, the Evolution card\ngoes back into the Deck!")
    next false unless du.toss_coin == HEADS
    next false if e == PLAY_AREA_ARENA && du.check_no_damage_or_effect
    du.as_non_turn do
      d = du.turn_duelist
      below = du.card_one_stage_below(d, e)
      if below
        lower, cur = below
        du.ui.message(_INTL("{1} devolved to {2}!", d.card(cur).name, d.card(lower).name))
        du.devolve_slot_to(d, e, lower)
        d.return_card_to_deck(cur)
        du.shuffle_cards_in_deck
        du.ui.message(_INTL("{1} was Knocked Out!", d.card(lower).name)) if d.slot_hp[e] == 0
      end
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3DarkTentacleEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || nd.slot_hp[PLAY_AREA_ARENA] == 0 || du.atk.no_damage_or_effect != 0
    du.neo_fx[:dark_tentacle] = [1 - du.turn, nd.arena, du.duel_turns + 1]
    false
  end

  #----------------------------------------------------------------------------
  # Donphan / Dark Donphan
  #----------------------------------------------------------------------------
  effect(:Neo3RapidSpinEffect) do |du|
    du.neo_forced_switch if du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] > 0
    d = du.turn_duelist
    du.neo3_switch_own_active(:NeoRapidSpin) if d.slot_hp[PLAY_AREA_ARENA] > 0
    false
  end
  effect(:Neo3TuskTossEffect) do |du|
    nd = du.non_turn_duelist
    next false if du.neo_alive_bench(nd).empty? || nd.slot_hp[PLAY_AREA_ARENA] == 0
    du.coin_check(_INTL("Heads: the Defending Pokémon goes back to the hand. Tails: your opponent switches."),
                  "Heads: back to the hand!\nTails: opponent switches.")
    if du.toss_coin == HEADS
      next false if du.check_no_damage_or_effect
      cards = nd.cards_in_slot(PLAY_AREA_ARENA)
      name = nd.card(nd.arena).name
      nd.empty_play_area_slot(PLAY_AREA_ARENA)
      cards.each { |i| nd.add_card_to_hand(i) }
      nd.clear_all_status_conditions
      du.ui.message(_INTL("{1} and its cards went back to the opponent's hand.", name))
      du.ui.refresh(du)
    else
      du.neo_forced_switch
    end
    false
  end

  #----------------------------------------------------------------------------
  # Electrode: Super Dynamo
  #----------------------------------------------------------------------------
  effect(:Neo3SuperDynamo_CheckUse) do |du|
    r = EffectFunctions[:Neo3ActiveOncePower_CheckUse].call(du)
    next r if r
    d = du.turn_duelist
    d.discard_pile.any? { |i| d.card_id(i) == :LIGHTNING_ENERGY } ? false : _INTL("There are no Lightning Energy cards in the Discard Pile.")
  end
  effect(:Neo3SuperDynamoEffect) do |du|
    d = du.turn_duelist
    d.slot_flags[PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
    du.coin_check(_INTL("If Heads, attach a Lightning Energy card from your Discard Pile to 1 of your Pokémon."), "If Heads, attach 1 <LIGHTNING> Energy\nfrom your Discard Pile.")
    next false unless du.toss_coin == HEADS
    i = d.discard_pile.find { |k| d.card_id(k) == :LIGHTNING_ENERGY } or next false
    slots = (0...d.num_in_play_area).to_a
    e = du.neo_human_choice? ? du.effect_choice(:play_area, :NeoSuperDynamo, slots, false) : PLAY_AREA_ARENA
    e = PLAY_AREA_ARENA unless slots.include?(e)
    du.neo_attach_from_discard(i, e)
    du.ui.message(_INTL("A Lightning Energy card was attached to {1}.", d.card(d.play_area[e]).name))
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Elekid: Playful Punch (heads = 20 to the opponent's Active, ends the turn)
  #----------------------------------------------------------------------------
  effect(:Neo3PlayfulPunch_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end
  effect(:Neo3PlayfulPunchEffect) do |du|
    d = du.turn_duelist
    nd = du.non_turn_duelist
    slot = du.temp(:a0) || PLAY_AREA_ARENA
    d.slot_flags[slot] |= USED_PKMN_POWER_THIS_TURN
    du.coin_check(_INTL("Playful Punch! If Heads, 20 damage to your opponent's Active Pokémon."), "If Heads, 20 damage to\nthe opponent's Active Pokémon!")
    if du.toss_coin == HEADS && nd.arena && nd.slot_hp[PLAY_AREA_ARENA] > 0
      dmg = 20
      wr = COLOR_TO_WR[du.play_area_card_color(d, slot)]
      dmg *= 2 if (du.arena_card_weakness(nd) & wr) != 0
      dmg -= du.resistance_amount(nd) if (du.arena_card_resistance(nd) & wr) != 0
      dmg = [dmg, 0].max
      du.subtract_hp(nd, PLAY_AREA_ARENA, dmg)
      du.ui.message(_INTL("{1} took {2} damage.", nd.card(nd.arena).name, dmg))
      du.ui.refresh(du)
      if nd.slot_hp[PLAY_AREA_ARENA] == 0
        du.ui.message(_INTL("{1} was Knocked Out!", nd.card(nd.arena).name))
        du.handle_between_turn_knock_outs
      end
    end
    du.ui.message(_INTL("Playful Punch ends the turn."))
    du.neo_end_turn = true
    false
  end

  #----------------------------------------------------------------------------
  # Entei
  #----------------------------------------------------------------------------
  effect(:Neo3ProtectiveFlameEffect) do |du|
    du.neo_fx[:protective_flame] = [du.turn, nil, du.duel_turns + 1]
    du.ui.message(_INTL("Your Benched Pokémon are protected during your opponent's next turn."))
    false
  end
  effect(:Neo3HowlEffect) do |du|
    d = du.turn_duelist
    if du.neo_human_choice?
      next false unless du.effect_choice(:yes_no, :NeoHowl, [true, false], false)
    else
      next false   # the AI doesn't end its turn early
    end
    top = d.deck_list.first(5)
    fire = []
    top.each do |i|
      d.draw_card_from_deck
      d.put_card_in_discard_pile(i)
      fire << i if d.card_id(i) == :FIRE_ENERGY
    end
    du.ui.message(_INTL("{1} card(s) were discarded, {2} of them Fire Energy.", top.size, fire.size))
    fire.each do |i|
      slots = (0...d.num_in_play_area).select { |e| du.play_area_card_color(d, e) == FIRE }
      break if slots.empty?
      e = du.effect_choice(:play_area, :NeoHowl, slots, false)
      e = slots.first unless slots.include?(e)
      du.neo_attach_from_discard(i, e)
    end
    du.ui.message(_INTL("Howl ends the turn."))
    du.neo_end_turn = true
    du.ui.refresh(du); false
  end
  effect(:Neo3SearingFlamesEffect) do |du|
    d = du.turn_duelist
    du.neo_fire_attached(d, PLAY_AREA_ARENA).first(2).each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Feraligatr
  #----------------------------------------------------------------------------
  effect(:Neo3BerserkEffect) do |du|
    du.coin_check(_INTL("Berserk! Heads: discard the top 5 cards of your opponent's deck. Tails: of your deck."),
                  "Heads: opponent discards 5.\nTails: you discard 5.")
    du.toss_coin == HEADS ? du.neo3_mill(du.non_turn_duelist, 5) : du.neo3_mill(du.turn_duelist, 5)
    false
  end
  effect(:Neo3ChompEffect) do |du|
    n = du.arena_damage / 10
    next false if n == 0
    du.coin_check(_INTL("Flip a coin for each damage counter on Feraligatr: +10 for each Heads."), "Damage check!\nIf Heads, +10 damage!!")
    du.atk.damage += 10 * du.toss_coins(n)
    false
  end
  effect(:Neo3Chomp_AIEffect) { |du| n = du.arena_damage / 10; du.set_expected_ai_damage(50 + 5 * n, 50, 50 + 10 * n); false }
  effect(:Neo3MajorTsunami_CheckUse) do |du|
    r = EffectFunctions[:Neo3ActiveOncePower_CheckUse].call(du)
    next r if r
    du.neo_alive_bench(du.turn_duelist).empty? && du.neo_alive_bench(du.non_turn_duelist).empty? ? _INTL("Nobody has Benched Pokémon.") : false
  end
  effect(:Neo3MajorTsunamiEffect) do |du|
    d = du.turn_duelist
    d.slot_flags[PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
    du.neo3_opponent_switches_now
    du.neo3_switch_own_active(:NeoMajorTsunami)
    false
  end
  effect(:Neo3RendingJawsEffect) do |du|
    du.set_definite_damage(40) if du.as_non_turn { du.arena_damage } == 0
    false
  end

  #----------------------------------------------------------------------------
  # Flaaffy
  #----------------------------------------------------------------------------
  effect(:Neo3DischargeEffect) do |du|
    d = du.turn_duelist
    list = du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY)
    list.each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du)
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 30), "Damage check!\nIf Heads, x 30 damage!!")
    du.set_definite_damage(30 * du.toss_coins(list.size)); false
  end
  effect(:Neo3Discharge_AIEffect) do |du|
    n = du.neo3_attached(du.turn_duelist, du.temp(:power_slot) || PLAY_AREA_ARENA, :LIGHTNING_ENERGY).size
    du.set_expected_ai_damage(15 * n, 0, 30 * n); false
  end
  effect(:Neo3ElectricCurrentEffect) do |du|
    d = du.turn_duelist
    i = du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY).first or next false
    slots = du.neo_alive_bench(d)
    if slots.empty?
      d.put_card_in_discard_pile(i)
    else
      e = du.neo3_pick_own_bench(:NeoElectricCurrent, slots)
      d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e
      du.ui.message(_INTL("A Lightning Energy card moved to {1}.", d.card(d.play_area[e]).name))
    end
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Gligar / Hitmonchan / Hitmontop / Ho-Oh
  #----------------------------------------------------------------------------
  effect(:Neo3StunPoisonEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon is now Paralyzed and Poisoned."), NEO_COIN_TEXT[:Neo3StunPoisonEffect])
    if du.toss_coin == HEADS
      du.queue_status(PSN_DBLPSN, PARALYZED)
      du.queue_status(CNF_SLP_PRZ, POISONED)
    end
    false
  end
  effect(:Neo3DodgeEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_DODGE); false }
  effect(:Neo3TripleKickEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 30), NEO_COIN_TEXT[:Neo3TripleKickEffect])
    du.set_definite_damage(30 * du.toss_coins(3)); false
  end
  effect(:Neo3TripleKick_AIEffect) { |du| du.set_expected_ai_damage(45, 0, 90); false }
  effect(:Neo3StokeEffect) do |du|
    d = du.turn_duelist
    i = d.deck_list.find { |k| d.card_id(k) == :FIRE_ENERGY }
    if i
      du.neo_attach_from_deck(i, PLAY_AREA_ARENA)
      du.ui.message(_INTL("A Fire Energy card was attached from the Deck."))
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Kabutops: 1 coin per Energy (max 3), 40 per heads
  #----------------------------------------------------------------------------
  effect(:Neo3HydrocutterEffect) do |du|
    n = [du.turn_duelist.energy_cards_in_slot(PLAY_AREA_ARENA).size, 3].min
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 40), "Damage check!\nIf Heads, x 40 damage!!")
    du.set_definite_damage(40 * du.toss_coins(n)); false
  end
  effect(:Neo3Hydrocutter_AIEffect) do |du|
    n = [du.turn_duelist.energy_cards_in_slot(du.temp(:power_slot) || PLAY_AREA_ARENA).size, 3].min
    du.set_expected_ai_damage(20 * n, 0, 40 * n); false
  end

  #----------------------------------------------------------------------------
  # Kingdra (Aquapolis / Neo Genesis)
  #----------------------------------------------------------------------------
  effect(:Neo3AquabombEffect) do |du|
    du.neo3_damage_own(PLAY_AREA_ARENA, 10)
    du.ui.refresh(du); false
  end
  effect(:Neo3DualBurnEffect) do |du|
    d = du.turn_duelist
    du.coin_check(_INTL("For each Tails, discard 1 Energy card attached to Kingdra."), "Flip 2 coins!\nDiscard 1 Energy for each Tails.")
    tails = 2 - du.toss_coins(2)
    list = d.energy_cards_in_slot(PLAY_AREA_ARENA)
    tails.times do
      break if list.empty?
      sel = du.neo_human_choice? ? du.effect_choice(:card, :NeoDualBurn, list, false) : nil
      sel = list.first unless list.include?(sel)
      d.put_card_in_discard_pile(list.delete(sel))
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3DragonTornadoEffect) do |du|
    nd = du.non_turn_duelist
    next false if nd.slot_hp[PLAY_AREA_ARENA] == 0
    e = du.neo_pick_opponent_bench(:NeoDragonTornado) or next false
    du.handle_switch_defending_pokemon(e)
    false
  end

  #----------------------------------------------------------------------------
  # Lanturn
  #----------------------------------------------------------------------------
  effect(:Neo3ConductionEffect) do |du|
    d = du.turn_duelist
    list = du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY)
    list.each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du)
    next false if list.empty?
    du.coin_check(_INTL("Damage check! +{1} damage for each Heads.", 40), "Damage check!\nIf Heads, +40 damage!!")
    du.atk.damage += 40 * du.toss_coins(list.size); false
  end
  effect(:Neo3Conduction_AIEffect) do |du|
    n = du.neo3_attached(du.turn_duelist, du.temp(:power_slot) || PLAY_AREA_ARENA, :LIGHTNING_ENERGY).size
    du.set_expected_ai_damage(30 + 20 * n, 30, 30 + 40 * n); false
  end
  # Floodlight + Hydroelectric Power: +10 per Water Energy not paying the cost
  effect(:Neo3FloodlightEffect) do |du|
    d = du.turn_duelist
    if du.neo_power_works?(d, PLAY_AREA_ARENA)
      water = du.neo3_attached(d, PLAY_AREA_ARENA, :WATER_ENERGY).size
      if water > 0
        du.atk.damage += 10 * water
        du.ui.message(_INTL("{1}'s Pokémon Power: Hydroelectric Power", d.card(d.arena).name))
      end
    end
    du.coin_check(_INTL("If Heads, the Defending Pokémon is now Paralyzed."), "Paralysis check!\nIf Heads, opponent is Paralyzed.")
    du.queue_status(PSN_DBLPSN, PARALYZED) if du.toss_coin == HEADS
    false
  end
  effect(:Neo3Floodlight_AIEffect) do |du|
    water = du.neo3_attached(du.turn_duelist, du.temp(:power_slot) || PLAY_AREA_ARENA, :WATER_ENERGY).size
    du.atk.damage += 10 * water; false
  end

  #----------------------------------------------------------------------------
  # Light Azumarill / Light Jolteon / Light Vaporeon
  #----------------------------------------------------------------------------
  effect(:Neo3BubbleJumpEffect) do |du|
    d = du.turn_duelist
    slots = du.neo_alive_bench(d)
    next false if slots.empty? || d.slot_hp[PLAY_AREA_ARENA] == 0
    du.coin_check(_INTL("If Heads, 2 Energy go to a Benched Pokémon and Light Azumarill returns to your hand."),
                  "If Heads, Light Azumarill\nreturns to your hand!")
    next false unless du.toss_coin == HEADS
    e = du.neo3_pick_own_bench(:NeoBubbleJump, slots)
    d.energy_cards_in_slot(PLAY_AREA_ARENA).first(2).each { |i| d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e }
    cards = d.cards_in_slot(PLAY_AREA_ARENA)
    d.swap_arena_with_bench_pokemon(e)
    d.empty_play_area_slot(e)
    cards.each { |i| d.add_card_to_hand(i) }
    d.shift_pokemon_to_first_play_area_slots
    du.ui.message(_INTL("Light Azumarill returned to the hand. {1} is now the Active Pokémon.", d.card(d.arena).name))
    du.ui.refresh(du); false
  end
  effect(:Neo3PulseGuardEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_PULSE_GUARD); false }
  effect(:Neo3ThunderNeedleEffect) do |du|
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 20), NEO_COIN_TEXT[:Neo3ThunderNeedleEffect])
    n = du.toss_coins(3)
    du.set_definite_damage(20 * n)
    du.queue_status(PSN_DBLPSN, PARALYZED) if n >= 2
    false
  end
  effect(:Neo3ThunderNeedle_AIEffect) { |du| du.set_expected_ai_damage(30, 0, 60); false }
  effect(:Neo3WashAwayEffect) do |du|
    d = du.turn_duelist
    slots = du.neo_alive_bench(d).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
    next false if slots.empty?
    du.coin_check(_INTL("If Heads, remove all damage counters from 1 of your Benched Pokémon."), "If Heads, heal 1 of your\nBenched Pokémon!")
    next false unless du.toss_coin == HEADS
    e = du.neo3_pick_own_bench(:NeoWashAway, slots)
    dmg, max = du.card_damage_and_max_hp(d, e)
    du.ui.event(:heal, d.name, e, dmg)
    d.slot_hp[e] = max
    d.energy_cards_in_slot(e).each { |i| d.put_card_in_discard_pile(i) }
    du.ui.refresh(du); false
  end
  effect(:Neo3HypnoshowerEffect) do |du|
    [du.turn_duelist, du.non_turn_duelist].each do |d|
      (1...d.num_in_play_area).each do |e|
        dmg, max = du.card_damage_and_max_hp(d, e)
        d.slot_hp[e] = [d.slot_hp[e] + 10, max].min if dmg > 0 && d.slot_hp[e] > 0
      end
    end
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Machamp / Machoke
  #----------------------------------------------------------------------------
  effect(:Neo3SeethingAngerEffect) do |du|
    n = du.arena_damage / 10
    next false if n == 0
    du.coin_check(_INTL("Flip a coin for each damage counter on Machamp: +10 for each Heads."), "Damage check!\nIf Heads, +10 damage!!")
    du.atk.damage += 10 * du.toss_coins(n); false
  end
  effect(:Neo3SeethingAnger_AIEffect) { |du| n = du.arena_damage / 10; du.set_expected_ai_damage(20 + 5 * n, 20, 20 + 10 * n); false }
  effect(:Neo3FocusEnergyEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE); false }

  #----------------------------------------------------------------------------
  # Magneton
  #----------------------------------------------------------------------------
  effect(:Neo3BounceOffEffect) do |du|
    d = du.turn_duelist
    nd = du.non_turn_duelist
    next false if nd.arena.nil? || d.slot_hp[PLAY_AREA_ARENA] == 0
    mine = d.energy_cards_in_slot(PLAY_AREA_ARENA).size
    theirs = nd.energy_cards_in_slot(PLAY_AREA_ARENA).size
    next false if mine == theirs
    if mine < theirs
      du.neo3_switch_own_active(:NeoBounceOff)
    elsif nd.slot_hp[PLAY_AREA_ARENA] > 0
      du.neo_forced_switch
    end
    false
  end
  effect(:Neo3MagneticWaveEffect) do |du|
    diff = du.turn_duelist.bench.size - du.non_turn_duelist.bench.size
    du.atk.damage += 10 * diff if diff > 0
    false
  end

  #----------------------------------------------------------------------------
  # Mareep: a Lightning Energy from the deck for each Mareep in play
  #----------------------------------------------------------------------------
  effect(:Neo3StaticElectricity_CheckEffect) { |du| du.deck_empty_text }
  effect(:Neo3StaticElectricityEffect) do |du|
    d = du.turn_duelist
    slots = d.play_area.each_index.select { |e| d.play_area[e] }.select { |e| d.card(d.play_area[e]).name == "Mareep" && d.slot_hp[e] > 0 }
    n = 0
    slots.each do |e|
      i = d.deck_list.find { |k| d.card_id(k) == :LIGHTNING_ENERGY } or break
      du.neo_attach_from_deck(i, e)
      n += 1
    end
    du.ui.message(_INTL("{1} Lightning Energy card(s) were attached.", n))
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Marill: Bubble Bomb
  #----------------------------------------------------------------------------
  effect(:Neo3BubbleBomb_CoinEffect) do |du|
    du.coin_check(_INTL("Heads: the Defending Pokémon is Paralyzed. Tails: Marill takes 10 damage."), "Heads: opponent is Paralyzed.\nTails: 10 damage to yourself.")
    heads = du.toss_coin == HEADS
    du.set_temp(:recoil, !heads)
    du.queue_status(PSN_DBLPSN, PARALYZED) if heads
    false
  end
  effect(:Neo3BubbleBomb_RecoilEffect) { |du| du.deal_recoil_damage_to_self(10) if du.temp(:recoil); false }

  #----------------------------------------------------------------------------
  # Mew: Super Psywave
  #----------------------------------------------------------------------------
  effect(:Neo3SuperPsywaveEffect) do |du|
    nd = du.non_turn_duelist
    best = (0...nd.num_in_play_area).select { |e| nd.slot_hp[e] > 0 }
    next false if best.empty?
    e = nil
    if du.neo_human_choice?
      du.ui.message(_INTL("Choose 1 of your opponent's Pokémon."))
      e = du.as_non_turn { du.effect_choice(:play_area, :NeoSuperPsywave, best, false) }
    end
    e = best.max_by { |x| nd.energy_cards_in_slot(x).size * 100 - nd.slot_hp[x] } unless best.include?(e)
    du.neo3_counters_on_opponent(e, nd.energy_cards_in_slot(e).size)
    false
  end
  effect(:Neo3SuperPsywave_AIEffect) do |du|
    nd = du.non_turn_duelist
    n = nd.arena ? 10 * nd.energy_cards_in_slot(PLAY_AREA_ARENA).size : 0
    du.set_expected_ai_damage(n, n, n); false
  end

  #----------------------------------------------------------------------------
  # Misdreavus
  #----------------------------------------------------------------------------
  effect(:Neo3NightEyesEffect) do |du|
    nd = du.non_turn_duelist
    du.neo_fx[:night_eyes] = [1 - du.turn, nd.arena, du.duel_turns + 2] if nd.arena && du.atk.no_damage_or_effect == 0
    false
  end
  effect(:Neo3PerishSongEffect) do |du|
    nd = du.non_turn_duelist
    if nd.arena && (nd.status & CNF_SLP_PRZ) == ASLEEP && du.neo_fx_active?(:night_eyes, 1 - du.turn, nd.arena)
      du.set_definite_damage(nd.slot_hp[PLAY_AREA_ARENA])
      du.atk.unaffected_by_wr = true
      du.set_temp(:swift, true)
    end
    false
  end

  #----------------------------------------------------------------------------
  # Murkrow
  #----------------------------------------------------------------------------
  effect(:Neo3CallForFamily_CheckEffect) do |du|
    du.deck_empty_text || du.no_bench_space_text
  end
  effect(:Neo3CallForFamilyEffect) do |du|
    d = du.turn_duelist
    i = d.deck_list.find { |k| d.card(k).name == "Murkrow" && d.card(k).basic? }
    if i && d.num_in_play_area < MAX_PLAY_AREA_POKEMON
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      du.put_basic_pokemon_in_play_area(i)
      du.ui.message(_INTL("Murkrow was placed on the Bench."))
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  effect(:Neo3FlockAttackEffect) do |du|
    d = du.turn_duelist
    n = d.bench.count { |i| d.card(i).name == "Murkrow" }
    next false if n == 0
    du.coin_check(_INTL("Damage check! +10 damage for each Heads."), "Damage check!\nIf Heads, +10 damage!!")
    du.atk.damage += 10 * du.toss_coins(n); false
  end
  effect(:Neo3FlockAttack_AIEffect) do |du|
    d = du.turn_duelist
    n = d.bench.count { |i| d.card(i).name == "Murkrow" }
    du.set_expected_ai_damage(10 + 5 * n, 10, 10 + 10 * n); false
  end

  #----------------------------------------------------------------------------
  # snipers: Natu, Remoraid, Umbreon, Shining Raichu
  #----------------------------------------------------------------------------
  effect(:Neo3TelekinesisEffect) do |du|
    e = du.neo3_pick_opponent_pokemon(:NeoTelekinesis, 20) or next false
    du.neo3_damage_opponent_any(e, 20); false
  end
  effect(:Neo3Telekinesis_AIEffect) { |du| du.set_expected_ai_damage(20, 20, 20); false }
  effect(:Neo3SharpshootingEffect) do |du|
    du.coin_check(_INTL("If Heads, 20 damage to 1 of your opponent's Pokémon."), "If Heads, 20 damage to 1\nof the opponent's Pokémon.")
    next false unless du.toss_coin == HEADS
    e = du.neo3_pick_opponent_pokemon(:NeoSharpshooting, 20) or next false
    du.neo3_damage_opponent_any(e, 20); false
  end
  effect(:Neo3FeintAttackEffect) do |du|
    e = du.neo3_pick_opponent_pokemon(:NeoFeintAttack, 30) or next false
    if e == PLAY_AREA_ARENA
      du.set_temp(:swift, true)
      du.atk.no_damage_or_effect = 0
    end
    du.neo3_damage_opponent_any(e, 30); false
  end
  effect(:Neo3FeintAttack_AIEffect) { |du| du.set_expected_ai_damage(30, 30, 30); false }
  effect(:Neo3ThundersquallEffect) do |du|
    n = du.neo3_attached(du.turn_duelist, PLAY_AREA_ARENA, :WATER_ENERGY).size
    next false if n == 0
    e = du.neo_pick_opponent_bench(:NeoThundersquall) or next false
    du.neo_damage_opponent_slot(e, 10 * n); false
  end

  #----------------------------------------------------------------------------
  # Omanyte
  #----------------------------------------------------------------------------
  effect(:Neo3WaterOfEvolution_CheckEffect) do |du|
    d = du.turn_duelist
    d.hand.any? { |i| d.card(i).name == "Omastar" && d.card(i).preevo == "Omanyte" } ? false : _INTL("There is no Omastar in your hand.")
  end
  effect(:Neo3WaterOfEvolutionEffect) do |du|
    d = du.turn_duelist
    next false if d.slot_hp[PLAY_AREA_ARENA] == 0
    list = d.hand.select { |i| d.card(i).name == "Omastar" && d.card(i).preevo == "Omanyte" }
    next false if list.empty?
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoWaterOfEvolution, list, false) : nil
    i = list.first unless list.include?(i)
    d.evolve_pokemon_card(i, PLAY_AREA_ARENA)
    du.ui.event(:evolve, d.name, i, PLAY_AREA_ARENA)
    du.ui.message(_INTL("Omanyte evolved into {1}!", d.card(i).name))
    du.ui.refresh(du); false
  end
  effect(:Neo3DragOffEffect) do |du|
    nd = du.non_turn_duelist
    slots = du.neo_alive_bench(nd)
    next false if slots.empty?
    e = nil
    if du.neo_human_choice?
      e = du.effect_choice(:yes_no, :NeoDragOff, [true, false], false) ? du.neo_pick_opponent_bench(:NeoDragOff) : nil
    else
      e = slots.min_by { |x| nd.slot_hp[x] }
      e = nil if nd.slot_hp[e] > 20
    end
    if e
      du.handle_switch_defending_pokemon(e)
      du.atk.temp_non_turn_card_id = nd.card_id(nd.arena)
      du.atk.defending_was_forced_to_switch = false
    end
    false
  end

  #----------------------------------------------------------------------------
  # Phanpy / Pichu / Piloswine / Politoed / Poliwhirl / Pupitar
  #----------------------------------------------------------------------------
  effect(:Neo3EndureEffect) do |du|
    du.coin_check(_INTL("If Heads, Phanpy can't be Knocked Out by the next attack."), "If Heads, Phanpy endures\nthe next attack!")
    if du.toss_coin == HEADS
      du.apply_substatus1_to_attacking_card(SUBSTATUS1_ENDURE)
    else
      du.set_was_unsuccessful
    end
    false
  end
  effect(:Neo3ZzzapEffect) do |du|
    [[du.non_turn_duelist, true], [du.turn_duelist, false]].each do |d, opp|
      (0...d.num_in_play_area).each do |e|
        next if d.slot_hp[e] == 0 || !d.card(d.play_area[e]).has_pkmn_power?
        if opp
          du.neo3_damage_opponent_any(e, 20)
        else
          du.neo3_damage_own(e, 20)
        end
      end
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3FreezeEffect) do |du|
    du.coin_check(_INTL("If Heads, the Defending Pokémon can't attack."), "If Heads, opponent can't Attack\nuntil it is Benched.")
    nd = du.non_turn_duelist
    if du.toss_coin == HEADS && nd.arena && nd.slot_hp[PLAY_AREA_ARENA] > 0 && !du.check_no_damage_or_effect && !du.neo3_crystal_body?
      nd.neo_frozen = true
      du.ui.message(_INTL("{1} is frozen and can't attack.", nd.card(nd.arena).name))
    end
    false
  end
  effect(:Neo3EnergySplashEffect) do |du|
    d = du.turn_duelist
    slots = du.neo_alive_bench(d)
    next false if slots.empty?
    du.neo3_attached(d, PLAY_AREA_ARENA, :WATER_ENERGY).first(2).each do |i|
      e = du.neo3_pick_own_bench(:NeoEnergySplash, slots)
      d.card_locations[i] = CARD_LOCATION_PLAY_AREA | e
      du.ui.message(_INTL("A Water Energy card moved to {1}.", d.card(d.play_area[e]).name))
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3BellyDrumEffect) do |du|
    d = du.turn_duelist
    du.neo3_damage_own(PLAY_AREA_ARENA, 30)
    if d.slot_hp[PLAY_AREA_ARENA] > 0
      list = d.deck_list.select { |i| d.card(i).basic_energy? }.first(2)
      list.each { |i| du.neo_attach_from_deck(i, PLAY_AREA_ARENA) }
      du.ui.message(_INTL("{1} basic Energy card(s) were attached.", list.size))
      du.shuffle_cards_in_deck
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3DustDevilEffect) do |du|
    [[du.non_turn_duelist, true], [du.turn_duelist, false]].each do |d, opp|
      (0...d.num_in_play_area).each do |e|
        next if d.slot_hp[e] == 0 || du.play_area_card_color(d, e) == FIGHTING
        opp ? du.neo3_damage_opponent_any(e, 10) : du.neo3_damage_own(e, 10)
      end
    end
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Raichu / Zapdos (Plasma)
  #----------------------------------------------------------------------------
  effect(:Neo3LightningStrikeEffect) do |du|
    d = du.turn_duelist
    list = du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY)
    use = if du.neo_human_choice?
            du.effect_choice(:yes_no, :NeoLightningStrike, [true, false], false)
          else
            du.non_turn_duelist.slot_hp[PLAY_AREA_ARENA] > 40
          end
    if use && !list.empty?
      list.each { |i| d.put_card_in_discard_pile(i) }
      du.set_definite_damage(80)
      du.ui.refresh(du)
    end
    false
  end
  effect(:Neo3LightningStrike_AIEffect) { |du| du.set_expected_ai_damage(80, 40, 80); false }
  effect(:Neo3PlasmaEffect) do |du|
    d = du.turn_duelist
    i = d.discard_pile.find { |k| d.card_id(k) == :LIGHTNING_ENERGY } or next false
    du.coin_check(_INTL("If Heads, attach 1 Lightning Energy card from your Discard Pile."), "If Heads, attach 1 <LIGHTNING> Energy\nfrom your Discard Pile.")
    next false unless du.toss_coin == HEADS
    du.neo_attach_from_discard(i)
    du.ui.message(_INTL("A Lightning Energy card was attached from the Discard Pile."))
    du.ui.refresh(du); false
  end
  effect(:Neo3LightningStormEffect) do |du|
    du.neo3_damage_own(PLAY_AREA_ARENA, 20) if du.temp(:recoil)
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Seadra: 1 coin per Water Energy, +10 per heads
  #----------------------------------------------------------------------------
  effect(:Neo3WaterBulletEffect) do |du|
    n = du.neo3_attached(du.turn_duelist, PLAY_AREA_ARENA, :WATER_ENERGY).size
    next false if n == 0
    du.coin_check(_INTL("Damage check! +10 damage for each Heads."), "Damage check!\nIf Heads, +10 damage!!")
    du.atk.damage += 10 * du.toss_coins(n); false
  end
  effect(:Neo3WaterBullet_AIEffect) do |du|
    n = du.neo3_attached(du.turn_duelist, du.temp(:power_slot) || PLAY_AREA_ARENA, :WATER_ENERGY).size
    du.set_expected_ai_damage(30 + 5 * n, 30, 30 + 10 * n); false
  end

  #----------------------------------------------------------------------------
  # Shining Charizard / Gyarados / Kabutops / Magikarp / Mew / Mewtwo /
  # Steelix / Tyranitar
  #----------------------------------------------------------------------------
  effect(:Neo3WhiteHotFlame_CheckEffect) do |du|
    d = du.turn_duelist
    ok = !du.neo_fire_attached(d, PLAY_AREA_ARENA).empty? && !du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY).empty?
    ok ? false : _INTL("A Fire and a Lightning Energy card are needed.")
  end
  effect(:Neo3WhiteHotFlameEffect) do |du|
    d = du.turn_duelist
    [du.neo_fire_attached(d, PLAY_AREA_ARENA).first, du.neo3_attached(d, PLAY_AREA_ARENA, :LIGHTNING_ENERGY).first].compact.each { |i| d.put_card_in_discard_pile(i) }
    du.deal_recoil_damage_to_self(30) if du.temp(:recoil)
    du.ui.refresh(du); false
  end
  effect(:Neo3OutrageEffect) do |du|
    du.coin_check(_INTL("If Heads, +10 damage for each damage counter on Shining Gyarados. If Tails, no damage."), NEO_COIN_TEXT[:Neo3OutrageEffect])
    if du.toss_coin == HEADS
      du.atk.damage += du.arena_damage
    else
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:Neo3Outrage_AIEffect) { |du| n = 30 + du.arena_damage; du.set_expected_ai_damage(n / 2, 0, n); false }
  effect(:Neo3Devastate_CheckEffect) do |du|
    du.neo_fire_attached(du.turn_duelist, PLAY_AREA_ARENA).size < 2 ? _INTL("Not enough Fire Energy.") : false
  end
  effect(:Neo3DevastateEffect) do |du|
    d = du.turn_duelist
    du.neo_fire_attached(d, PLAY_AREA_ARENA).first(2).each { |i| d.put_card_in_discard_pile(i) }
    du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    du.coin_check(_INTL("If Heads, discard 1 Energy card from each of your opponent's Pokémon."), "If Heads, discard 1 Energy from\neach of the opponent's Pokémon.")
    if du.toss_coin == HEADS
      nd = du.non_turn_duelist
      (0...nd.num_in_play_area).each do |e|
        list = nd.energy_cards_in_slot(e)
        next if list.empty?
        sel = du.neo_human_choice? ? du.as_non_turn { du.effect_choice(:card, :NeoDevastate, list, false) } : nil
        nd.put_card_in_discard_pile(list.include?(sel) ? sel : list.first)
      end
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3LightningCut_CoinEffect) do |du|
    du.coin_check(_INTL("Heads: +10 damage and 10 to each Benched Pokémon. Tails: 10 damage to Shining Kabutops."), "Heads: +10 and 10 to the Bench.\nTails: 10 damage to yourself.")
    heads = du.toss_coin == HEADS
    du.set_temp(:cut, heads)
    du.atk.damage += 10 if heads
    false
  end
  effect(:Neo3LightningCut_AfterEffect) do |du|
    if du.temp(:cut)
      du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    else
      du.deal_recoil_damage_to_self(10)
    end
    false
  end
  effect(:Neo3WaterSlashEffect) do |du|
    e = du.temp(:power_slot) || PLAY_AREA_ARENA
    water = du.neo3_attached(du.turn_duelist, e, :WATER_ENERGY).size
    du.atk.damage += 10 * [water - 2, 0].max
    du.set_temp(:no_resistance, true)
    false
  end
  effect(:Neo3GoldScaleEffect) do |du|
    nd = du.non_turn_duelist
    d = du.turn_duelist
    ctrl = du.controllers[1 - du.turn]
    opp = ctrl.is_a?(PlayerController) ? ctrl.effect_choice(du, :yes_no, :NeoGoldScaleOpp, [true, false], false) : nd.hand.size < 6
    if opp
      du.as_non_turn { 2.times { (i = nd.draw_card_from_deck) && nd.add_card_to_hand(i) } }
      du.ui.message(_INTL("Your opponent drew 2 cards."))
    end
    me = du.neo_human_choice? ? du.effect_choice(:yes_no, :NeoGoldScale, [true, false], false) : d.cards_in_deck > 5
    if me
      2.times { (i = d.draw_card_from_deck) && d.add_card_to_hand(i) && du.ui.event(:draw, d.name, i) }
      du.ui.message(_INTL("{1} drew 2 cards.", d.name))
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3DragonBondEffect) do |du|
    d = du.turn_duelist
    list = d.deck_list.select { |i| ["Gyarados", "Dark Gyarados", "Shining Gyarados"].include?(d.card(i).name) }
    unless list.empty?
      i = du.neo_human_choice? ? du.effect_choice(:card, :NeoDragonBond, list, true) : list.first
      if i
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
        du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
      end
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  effect(:Neo3FlashSearchEffect) do |du|
    d = du.turn_duelist
    top = d.deck_list.first(3)
    next false if top.empty?
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoFlashSearch, top, false) : nil
    i = top.find { |k| d.card(k).pokemon? } || top.first unless top.include?(i)
    d.search_card_in_deck_and_add_to_hand(i)
    d.add_card_to_hand(i)
    du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end
  effect(:Neo3MysticFireEffect) do |du|
    d = du.turn_duelist
    i = du.neo_fire_attached(d, PLAY_AREA_ARENA).first
    if i.nil?
      du.set_definite_damage(0)
      du.set_was_unsuccessful
      next false
    end
    d.put_card_in_discard_pile(i)
    du.ui.refresh(du)
    du.coin_check(_INTL("If Heads, the Defending Pokémon is Confused. If Tails, it is Asleep."), NEO_COIN_TEXT[:NeoStrangePowderEffect])
    du.toss_coin == HEADS ? du.queue_status(PSN_DBLPSN, CONFUSED) : du.queue_status(PSN_DBLPSN, ASLEEP)
    false
  end
  effect(:Neo3ReflectShieldEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_REFLECT); false }
  effect(:Neo3PsyburstEffect) do |du|
    d = du.turn_duelist
    i = du.neo_fire_attached(d, PLAY_AREA_ARENA).first
    if i.nil?
      du.set_definite_damage(0)
      du.set_was_unsuccessful
      next false
    end
    d.put_card_in_discard_pile(i)
    du.atk.damage += du.energy_attached_multiplier_damage
    du.ui.refresh(du); false
  end
  effect(:Neo3Psyburst_AIEffect) do |du|
    fire = !du.neo_fire_attached(du.turn_duelist, du.temp(:power_slot) || PLAY_AREA_ARENA).empty?
    du.set_definite_damage(fire ? 40 + du.energy_attached_multiplier_damage : 0); false
  end
  effect(:Neo3CrushingEarth_CoinEffect) do |du|
    du.coin_check(_INTL("If Heads, 10 damage to each Benched Pokémon. If Tails, no damage."), "Heads: 10 to every Bench.\nTails: no damage!")
    heads = du.toss_coin == HEADS
    du.set_temp(:quake, heads)
    unless heads
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    false
  end
  effect(:Neo3CrushingEarthEffect) do |du|
    if du.temp(:quake)
      du.atk.is_damage_to_self = true
      du.deal_damage_to_all_benched_pokemon(10)
      du.atk.is_damage_to_self = false
      du.as_non_turn { du.deal_damage_to_all_benched_pokemon(10) }
    end
    EffectFunctions[:Neo3NoAttackNextTurnEffect].call(du)
  end
  effect(:Neo3NoAttackNextTurnEffect) do |du|
    d = du.turn_duelist
    du.neo_fx[:no_attack] = [du.turn, d.arena, du.duel_turns + 2] if d.arena && d.slot_hp[PLAY_AREA_ARENA] > 0
    false
  end
  effect(:Neo3MountainCrushEffect) do |du|
    du.coin_check(_INTL("Flip until Tails: your opponent discards the top card of their deck for each Heads."), "Flip until Tails!\nOpponent discards 1 for each Heads.")
    heads = 0
    heads += 1 while du.toss_coin == HEADS && heads < 60
    du.neo3_mill(du.non_turn_duelist, heads) if heads > 0
    false
  end
  effect(:Neo3DestructiveFire_CoinEffect) do |du|
    d = du.turn_duelist
    fire = du.neo_fire_attached(d, PLAY_AREA_ARENA)
    du.coin_check(_INTL("For each Heads, discard 1 Fire Energy card and 1 of the Defending Pokémon's Energy cards."), "Flip a coin for each <FIRE> Energy!\nDiscard for each Heads.")
    heads = du.toss_coins(fire.size)
    fire.first(heads).each { |i| d.put_card_in_discard_pile(i) }
    du.set_temp(:destruct, heads)
    if heads == 0
      du.set_definite_damage(0)
      du.set_was_unsuccessful
    end
    du.ui.refresh(du); false
  end
  effect(:Neo3DestructiveFireEffect) do |du|
    n = du.temp(:destruct).to_i
    du.neo3_discard_defending_energy(n, :NeoDestructiveFire) if n > 0 && !du.check_no_damage_or_effect
    false
  end

  #----------------------------------------------------------------------------
  # Slowking / Slowpoke / Smoochum / Sneasel / Suicune / Tyranitar
  #----------------------------------------------------------------------------
  effect(:Neo3MindBlastEffect) do |du|
    du.coin_check(_INTL("If Heads, +10 damage and the Defending Pokémon is now Confused."), NEO_COIN_TEXT[:Neo3MindBlastEffect])
    if du.toss_coin == HEADS
      du.atk.damage += 10
      du.queue_status(PSN_DBLPSN, CONFUSED)
    end
    false
  end
  effect(:Neo3MindBlast_AIEffect) { |du| du.set_expected_ai_damage(25, 20, 30); false }
  effect(:Neo3FishingTail_CheckEffect) do |du|
    d = du.turn_duelist
    d.discard_pile.any? { |i| (c = d.card(i)).pokemon? || c.basic_energy? } ? false : _INTL("There are no such cards in the Discard Pile.")
  end
  effect(:Neo3FishingTailEffect) do |du|
    d = du.turn_duelist
    list = d.discard_pile.select { |i| (c = d.card(i)).pokemon? || c.basic_energy? }
    next false if list.empty?
    i = du.neo_human_choice? ? du.effect_choice(:card, :NeoFishingTail, list, false) : nil
    i = (list.find { |k| d.card(k).pokemon? } || list.first) unless list.include?(i)
    d.move_discard_pile_card_to_hand(i)
    du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
    du.ui.refresh(du); false
  end
  effect(:Neo3PsykissEffect) do |du|
    nd = du.non_turn_duelist
    du.coin_check(_INTL("If Heads, a Special Energy card goes back into your opponent's deck."), "If Heads, shuffle a Special\nEnergy into the opponent's Deck.")
    next false unless du.toss_coin == HEADS
    list = (0...nd.num_in_play_area).flat_map { |e| nd.energy_cards_in_slot(e) }.reject { |i| nd.card(i).basic_energy? }
    if list.empty?
      du.ui.message(_INTL("There are no Special Energy cards in play."))
      next false
    end
    i = du.neo_human_choice? ? du.as_non_turn { du.effect_choice(:card, :NeoPsykiss, list, false) } : nil
    i = list.first unless list.include?(i)
    nd.put_card_in_discard_pile(i)
    nd.move_discard_pile_card_to_hand(i)
    nd.return_card_to_deck(i)
    du.as_non_turn { du.shuffle_cards_in_deck }
    du.ui.message(_INTL("{1} was shuffled into the opponent's deck.", nd.card(i).name))
    du.ui.refresh(du); false
  end
  effect(:Neo3BeatUpEffect) do |du|
    n = du.turn_duelist.num_in_play_area
    du.coin_check(_INTL("Damage check! {1} damage for each Heads.", 20), "Damage check!\nIf Heads, x 20 damage!!")
    du.set_definite_damage(20 * du.toss_coins(n)); false
  end
  effect(:Neo3BeatUp_AIEffect) { |du| n = du.turn_duelist.num_in_play_area; du.set_expected_ai_damage(10 * n, 0, 20 * n); false }
  effect(:Neo3AuroraWaveEffect) do |du|
    du.coin_check(_INTL("Both Heads: the Defending Pokémon is Paralyzed. 1 Heads: it is Asleep."), NEO_COIN_TEXT[:Neo3AuroraWaveEffect])
    case du.toss_coins(2)
    when 2 then du.queue_status(PSN_DBLPSN, PARALYZED)
    when 1 then du.queue_status(PSN_DBLPSN, ASLEEP)
    end
    false
  end
  effect(:Neo3TrampleEffect) do |du|
    d = du.turn_duelist
    nd = du.non_turn_duelist
    (1...nd.num_in_play_area).each do |e|
      next if nd.slot_hp[e] == 0
      du.coin_check(_INTL("If Heads, 30 damage to {1}.", nd.card(nd.play_area[e]).name), "If Heads, 30 damage\nto that Pokémon!")
      du.neo_damage_opponent_slot(e, 30) if du.toss_coin == HEADS
    end
    (1...d.num_in_play_area).each do |e|
      next if d.slot_hp[e] == 0
      du.coin_check(_INTL("If Heads, 30 damage to {1}.", d.card(d.play_area[e]).name), "If Heads, 30 damage\nto that Pokémon!")
      next unless du.toss_coin == HEADS
      du.atk.is_damage_to_self = true
      du.deal_damage_to_play_area_pokemon(e, 30)
      du.atk.is_damage_to_self = false
    end
    false
  end

  #----------------------------------------------------------------------------
  # Unown: Hidden Power (+[Anger]) / [Join]
  #----------------------------------------------------------------------------
  effect(:Neo3HiddenPowerEffect) do |du|
    d = du.turn_duelist
    e = d.play_area.each_index.find { |x| d.play_area[x] && d.card_id(d.play_area[x]) == :UNOWN_A && du.neo_power_works?(d, x) }
    if e
      dmg = du.card_damage_and_max_hp(d, e)[0]
      du.atk.damage += dmg if dmg > 0
    end
    false
  end
  NEO3_JOIN = ["Unown [J]", "Unown [O]", "Unown [I]", "Unown Dragon"]
  effect(:Neo3Join_CheckUse) do |du|
    slot = du.power_slot
    du.set_temp(:a0, slot)
    d = du.turn_duelist
    names = d.bench.map { |i| d.card(i).name }
    next _INTL("Unown [J], [O], [I] and Dragon must be on your Bench.") unless (NEO3_JOIN - names).empty?
    next _INTL("Only once per turn.") if (d.slot_flags[slot] & USED_PKMN_POWER_THIS_TURN) != 0
    r = du.deck_empty_text
    next r if r
    du.incapable_of_using_pkmn_power?(d, slot) ? true : false
  end
  effect(:Neo3JoinEffect) do |du|
    d = du.turn_duelist
    d.slot_flags[du.temp(:a0) || PLAY_AREA_ARENA] |= USED_PKMN_POWER_THIS_TURN
    list = d.deck_list.select { |i| d.card(i).pokemon? }
    unless list.empty?
      i = du.neo_human_choice? ? du.effect_choice(:card, :NeoJoin, list, true) : list.first
      if i
        d.search_card_in_deck_and_add_to_hand(i)
        d.add_card_to_hand(i)
        du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
      end
    end
    du.shuffle_cards_in_deck; false
  end

  #----------------------------------------------------------------------------
  # Wobbuffet / Wooper
  #----------------------------------------------------------------------------
  effect(:Neo3CounterEffect) { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_COUNTER); false }
  effect(:Neo3SlimeEffect)   { |du| du.apply_substatus1_to_attacking_card(SUBSTATUS1_SLIME); false }

  #----------------------------------------------------------------------------
  # Master Ball: a Basic Pokemon or Evolution card from the top 7
  #----------------------------------------------------------------------------
  effect(:Neo3MasterBallEffect) do |du|
    d = du.turn_duelist
    top = d.deck_list.first(7)
    list = top.select { |i| d.card(i).pokemon? }
    if list.empty?
      du.ui.message(_INTL("There are no Pokémon in the top 7 cards."))
    else
      i = du.neo_human_choice? ? du.effect_choice(:card, :NeoMasterBall, list, false) : nil
      i = list.max_by { |k| d.card(k).stage.to_i } unless list.include?(i)
      d.search_card_in_deck_and_add_to_hand(i)
      d.add_card_to_hand(i)
      du.ui.message(_INTL("{1} was put into the hand.", d.card(i).name))
    end
    du.shuffle_cards_in_deck
    du.ui.refresh(du); false
  end

  #----------------------------------------------------------------------------
  # Water Slash: no Resistance
  #----------------------------------------------------------------------------
  class Duel
    alias_method :tcg_neo3_arena_card_resistance, :arena_card_resistance
    def arena_card_resistance(d)
      return 0 if @atk && @atk.temp[:no_resistance] && d == non_turn_duelist
      tcg_neo3_arena_card_resistance(d)
    end
  end
end
