#==============================================================================
# Pokemon TCG - effect functions, batch 1 (effect_functions.asm).
# Return value convention: false/nil = ok; true = carry; String = carry and
# show that text (the original's "ldtx hl, ...; scf").
#==============================================================================
module TCG
  def self.effects(*names, &blk); names.each { |n| effect(n, &blk) }; end

  AI_EFFECT_PHASES = [EFFECT_AI_SELECTION, EFFECT_AI, EFFECT_AI_SWITCH_DEFENDING_PKMN]
  @@set_complete = {}
  def self.effect_set_complete?(name)
    return @@set_complete[name] if @@set_complete.key?(name)
    cmds = EFFECT_TABLE[name] || []
    ok = cmds.all? { |p, f| AI_EFFECT_PHASES.include?(p) || EffectFunctions.key?(f) }
    @@set_complete[name] = ok if ok   # only cache positives (more may load later)
    ok
  end

  class Duel
    alias_method :tcg_try_execute_effect_command_raw, :try_execute_effect_command
    def try_execute_effect_command(phase)
      name = @atk&.effect_name
      return false unless name
      cmds = EFFECT_TABLE[name] or return false
      entry = cmds.find { |p, _| p == phase } or return false
      # only run a command set once every non-AI function in it is ported
      unless TCG.effect_set_complete?(name)
        @ui.event(:missing_effect, name) if phase == EFFECT_INITIAL_EFFECT_1 || cmds.first[0] == phase
        return false
      end
      fn = EffectFunctions[entry[1]]
      r = fn.call(self)
      if r.is_a?(String)
        @ui.message(r) unless @silent_effect_checks
        return true
      end
      r ? true : false
    end

    # AI evaluation runs check commands without printing their failure text
    attr_accessor :silent_effect_checks
    def silently
      old = @silent_effect_checks
      @silent_effect_checks = true
      yield
    ensure
      @silent_effect_checks = old
    end

    # hTemp_ffa0 / hTempPlayAreaLocation_ffa1 / hTempRetreatCostCards etc.
    def temp(key = :a0);      @atk.temp[key]; end
    def set_temp(key, v);     @atk.temp[key] = v; end

    # ApplyExtraWaterEnergyDamageBonus(b = water in cost, c = colorless in cost)
    def apply_extra_water_energy_damage_bonus(b, c)
      if (mc = @atk.temp[:metronome_energy_cost]).to_i > 0
        c = mc; b = 0
      end
      e = @atk.temp[:power_slot] || PLAY_AREA_ARENA
      en, total = turn_duelist.attached_energies(e)
      b += c if c > 0 && total == en[WATER]
      extra = en[WATER] - b
      @atk.damage += 10 * [extra, 2].min if extra > 0
    end

    # PlayerPickFireEnergyCardToDiscard -> temp :a0
    def pick_fire_energy_card_to_discard(purpose)
      list = list_of_fire_energy_attached_to_arena
      sel = effect_choice(:card, purpose, list, false)
      set_temp(:a0, sel || list.first)
      false
    end

    # HandleDefendingPokemonAttackSelection: [deck_index, attack_index] or nil
    def defending_pokemon_attack_options
      nd = non_turn_duelist
      idx = nd.arena
      nd.card(idx).attacks.each_with_index.reject { |a, _| a.pokemon_power? }.map { |_, i| [idx, i] }
    end

    def defending_pokemon_has_any_attack?
      !defending_pokemon_attack_options.empty?
    end

    # PlayerPickAttackForAmnesia -> temp :a0 = attack index; true if cancelled
    def pick_attack_for_amnesia(purpose)
      @ui.message(_INTL("Choose the attack the opponent will not be able to use on the next turn.")) if player_turn?
      sel = effect_choice(:attack, purpose, defending_pokemon_attack_options, true)
      return true if sel.nil?
      set_temp(:a0, sel[1])
      false
    end

    # ApplyAmnesiaToAttack
    def apply_amnesia_to_attack
      apply_substatus2_to_defending_card(SUBSTATUS2_AMNESIA)
      return if @atk.no_damage_or_effect != 0
      nd = non_turn_duelist
      nd.disabled_attack_index = temp(:a0)
      nd.last_turn_effect = LAST_TURN_EFFECT_AMNESIA
      unless player_turn?
        name = nd.card(nd.arena).attacks[temp(:a0)].name
        @ui.message(_INTL("{1} was chosen for the effect of Amnesia.", name))
      end
    end

    # HandleEnergyDiscardEffectSelection (choose an energy on the DEFENDING
    # Pokemon) -> temp :a0 (nil = none)
    def handle_energy_discard_effect_selection(purpose)
      list = as_non_turn { turn_duelist.energy_cards_in_slot(PLAY_AREA_ARENA) }
      if list.empty?
        set_temp(:a0, nil)
        return false
      end
      @ui.message(_INTL("Choose the Energy card attached to the opponent's Active Pokémon to discard.")) if player_turn?
      set_temp(:a0, effect_choice(:card, purpose, list, false) || list.first)
      false
    end

    # MirrorMove_ExecuteStatusEffect
    def mirror_move_execute_status_effect(st)
      psn = st & PSN_DBLPSN
      if psn != 0
        queue_status(CNF_SLP_PRZ, DOUBLE_POISONED) if psn == DOUBLE_POISONED
        queue_status(CNF_SLP_PRZ, POISONED) if psn == POISONED
      end
      case st & CNF_SLP_PRZ
      when CONFUSED  then queue_status(PSN_DBLPSN, CONFUSED)
      when ASLEEP    then queue_status(PSN_DBLPSN, ASLEEP)
      when PARALYZED then queue_status(PSN_DBLPSN, PARALYZED)
      end
    end
  end

  #----------------------------------------------------------------------------
  # passive Pokemon Powers ("scf; ret": can't be activated from the menu)
  #----------------------------------------------------------------------------
  effects(:ToxicGasEffect, :ClairvoyanceEffect, :RainDanceEffect,
          :Quickfreeze_InitialEffect, :Firegiver_InitialEffect,
          :InvisibleWallEffect, :NeutralizingShieldEffect, :StrikesBackEffect,
          :KabutoArmorEffect, :PealOfThunder_InitialEffect, :ThickSkinnedEffect,
          :RetreatAidEffect, :HealingWind_InitialEffect) { |du| true }

  effects(:MagnetonSonicboom_NullEffect, :ElectrodeSonicboom_NullEffect) { |du| false }

  #----------------------------------------------------------------------------
  # Water Gun / Hydro Pump family (ApplyExtraWaterEnergyDamageBonus b, c)
  #----------------------------------------------------------------------------
  { :OmastarWaterGunEffect => [1, 1], :OmanyteWaterGunEffect => [1, 0],
    :HydroPumpEffect => [3, 0], :SeadraWaterGunEffect => [1, 1],
    :PoliwrathWaterGunEffect => [2, 1], :PoliwagWaterGunEffect => [1, 0],
    :LaprasWaterGunEffect => [1, 0] }.each do |name, (b, c)|
    effect(name) { |du| du.apply_extra_water_energy_damage_bonus(b, c); false }
  end

  effect(:Toxic_DoublePoisonEffect) { |du| du.queue_status(CNF_SLP_PRZ, DOUBLE_POISONED); false }

  # CheckIfDeckIsEmpty
  effect(:EnergySpike_DeckCheck) do |du|
    du.turn_duelist.cards_in_deck <= 0 ? _INTL("There are no cards left in the Deck.") : false
  end

  #----------------------------------------------------------------------------
  # discard 1 attached Fire Energy (Ember / Flamethrower / Fire Blast)
  #----------------------------------------------------------------------------
  FIRE_DISCARD = [:Ember, :ArcanineFlamethrower, :FireBlast, :FlareonFlamethrower,
                  :MagmarFlamethrower, :CharmeleonFlamethrower]
  FIRE_DISCARD.each do |n|
    effect(:"#{n}_CheckEnergy") do |du|
      du.turn_duelist.attached_energies(PLAY_AREA_ARENA)[0][FIRE] < 1 ? _INTL("Not enough Fire Energy.") : false
    end
    effect(:"#{n}_PlayerSelectEffect") { |du| du.pick_fire_energy_card_to_discard(:"#{n}_PlayerSelectEffect") }
    effect(:"#{n}_DiscardEffect")      { |du| du.turn_duelist.put_card_in_discard_pile(du.temp(:a0)); false }
  end

  #----------------------------------------------------------------------------
  # Amnesia
  #----------------------------------------------------------------------------
  effect(:PoliwhirlAmnesia_CheckAttacks) do |du|
    du.defending_pokemon_has_any_attack? ? false : _INTL("No attack may be chosen.")
  end
  effect(:SlowpokeAmnesia_CheckAttacks) { |du| !du.defending_pokemon_has_any_attack? }
  effects(:PoliwhirlAmnesia_PlayerSelectEffect, :SlowpokeAmnesia_PlayerSelectEffect) do |du|
    du.pick_attack_for_amnesia(:Amnesia)
  end
  effects(:PoliwhirlAmnesia_DisableEffect, :SlowpokeAmnesia_DisableEffect) { |du| du.apply_amnesia_to_attack; false }

  #----------------------------------------------------------------------------
  # Hyper Beam (Dragonair): select energy on the defending Pokemon
  #----------------------------------------------------------------------------
  effect(:DragonairHyperBeam_PlayerSelectEffect) { |du| du.handle_energy_discard_effect_selection(:HyperBeam) }

  #----------------------------------------------------------------------------
  # Mirror Move (Spearow / Pidgeotto)
  #----------------------------------------------------------------------------
  effect(:MirrorMove_InitialEffect1) do |du|
    d = du.turn_duelist
    if d.last_turn_damage == 0 && d.last_turn_status == 0 && d.last_turn_substatus2 == 0
      _INTL("You did not receive an attack to Mirror Move.")
    else
      false
    end
  end
  effect(:MirrorMove_InitialEffect2) do |du|
    du.set_temp(:a0, nil)
    du.turn_duelist.last_turn_effect == LAST_TURN_EFFECT_AMNESIA ? du.pick_attack_for_amnesia(:MirrorMove) : false
  end
  effect(:MirrorMove_PlayerSelection) do |du|
    du.turn_duelist.last_turn_effect == LAST_TURN_EFFECT_DISCARD_ENERGY ?
      du.handle_energy_discard_effect_selection(:MirrorMove) : false
  end
  effect(:MirrorMove_BeforeDamage) do |du|
    d = du.turn_duelist
    if d.last_turn_effect == LAST_TURN_EFFECT_AMNESIA
      du.apply_amnesia_to_attack
    else
      du.atk.damage = d.last_turn_damage
      du.mirror_move_execute_status_effect(d.last_turn_status) if d.last_turn_status != 0
      du.non_turn_duelist.substatus2 = d.last_turn_substatus2
    end
    false
  end
  effect(:MirrorMove_AfterDamage) do |du|
    next false if du.atk.no_damage_or_effect != 0
    d = du.turn_duelist
    if d.last_turn_effect == LAST_TURN_EFFECT_DISCARD_ENERGY && du.temp(:a0)
      du.as_non_turn do
        du.turn_duelist.put_card_in_discard_pile(du.temp(:a0))
        du.turn_duelist.last_turn_effect = LAST_TURN_EFFECT_DISCARD_ENERGY
      end
    end
    cw = d.last_turn_change_weak
    if cw != 0
      nd = du.non_turn_duelist
      if nd.card(nd.arena).weakness != 0
        nd.changed_weakness = cw
        color = (0..7).find { |i| (cw << i) & 0x80 != 0 }
        du.ui.message(_INTL("Changed the Weakness of {1} to {2}.", nd.card(nd.arena).name, COLOR_NAMES.key(color).to_s.capitalize))
      end
    end
    false
  end
  [:Spearow, :Pidgeotto].each do |p|
    { "InitialEffect1" => :MirrorMove_InitialEffect1, "InitialEffect2" => :MirrorMove_InitialEffect2,
      "PlayerSelection" => :MirrorMove_PlayerSelection, "BeforeDamage" => :MirrorMove_BeforeDamage,
      "AfterDamage" => :MirrorMove_AfterDamage }.each do |suffix, base|
      effect(:"#{p}MirrorMove_#{suffix}") { |du| EffectFunctions[base].call(du) }
    end
  end
end
