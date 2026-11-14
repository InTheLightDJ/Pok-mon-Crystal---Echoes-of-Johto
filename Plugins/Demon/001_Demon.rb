#===============================================================================
# Demon (PBS: pokemon.txt [DEMON], abilities.txt [DEMONSOUL])
#
# A Ghost-type recolored Pikachu, Raichu's stats +2 each, built to hunt the
# creepy pasta Pokémon (the World Boss's species and the Ghost Guy's aces).
# Its ability, Demon Soul, only works against those species:
#   - its moves do DAMAGE_MULT times the damage to them, and its Ghost moves
#     hit them even through a Normal type (Missigno);
#   - their moves do 1/DAMAGE_MULT of the damage to it (Slaphappy's fixed
#     damage too);
#   - End Times and Zombify (BLOCKED_MOVES) don't affect it at all;
#   - against the creepy pasta World Boss its hits aren't capped (below).
#===============================================================================
module DemonSoul
  ABILITY = :DEMONSOUL
  CREEPY_SPECIES = [:BURRIEDALIVE, :DARKMEW, :FOSSEL, :FOSSIL, :MISSIGNO, :GHOST, :GHOSTLY]
  DAMAGE_MULT = 4
  BLOCKED_MOVES = ["EndTimesOHKO", "InflictZombie"]

  def self.creepy?(battler)
    return !battler.nil? && CREEPY_SPECIES.include?(battler.species)
  end
end

Battle::AbilityEffects::DamageCalcFromUser.add(DemonSoul::ABILITY,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= DemonSoul::DAMAGE_MULT if DemonSoul.creepy?(target)
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(DemonSoul::ABILITY,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= DemonSoul::DAMAGE_MULT if DemonSoul.creepy?(user)
  }
)

Battle::AbilityEffects::MoveImmunity.add(DemonSoul::ABILITY,
  proc { |ability, user, target, move, type, battle, show_message|
    next false unless DemonSoul::BLOCKED_MOVES.include?(move.function_code)
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}'s {2} blocks {3}!", target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

# its moves hit a creepy pasta Pokémon through any type immunity (Ghost moves
# on Missigno's Normal type)
module DemonSoulTypeMod
  def pbCalcTypeModSingle(moveType, defType, user, target)
    ret = super
    if user && user.hasActiveAbility?(DemonSoul::ABILITY) && DemonSoul.creepy?(target) &&
       Effectiveness.ineffective_type?(moveType, defType)
      ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    end
    return ret
  end
end
Battle::Move.prepend(DemonSoulTypeMod)

# Slaphappy's damage is fixed (no damage multipliers): cut it here
module DemonSoulSlaphappy
  def pbFixedDamage(user, target)
    ret = super
    if target.hasActiveAbility?(DemonSoul::ABILITY) && DemonSoul.creepy?(user)
      ret = [ret / DemonSoul::DAMAGE_MULT, 1].max
    end
    return ret
  end
end
Battle::Move::SlaphappyEscalating.prepend(DemonSoulSlaphappy)
#===============================================================================
# The creepy pasta World Boss (Battle::CreepyBossEncounter,
# 027_NetworkCreepyBoss.rb) caps each hit at CREEPY_BOSS_MAX_DAMAGE_PER_HIT
# here and at MAX_DAMAGE_PER_HIT on the server (handlers/creepyboss.js). While
# Demon is the player's Pokémon in battle neither applies: its damage goes to
# the shared HP in full (a local KO ends the boss for everyone), and the
# damage it reports carries demon: true so the server takes it all.
#===============================================================================
module DemonSoul
  SPECIES = :DEMON
  @uncapped_send = false

  class << self
    attr_accessor :uncapped_send

    def uncapped
      old = @uncapped_send
      @uncapped_send = true
      yield
    ensure
      @uncapped_send = old
    end
  end
end

# (an alias, like Auto Reconnect's: a prepend here and its alias would call
# each other forever)
class << NetworkClient
  alias _demon_send_msg send_msg unless method_defined?(:_demon_send_msg)
  def send_msg(hash)
    if DemonSoul.uncapped_send && hash.is_a?(Hash) && hash[:action] == 'creepy_boss_damage'
      hash = hash.merge(demon: true)
    end
    _demon_send_msg(hash)
  end
end

# The three methods below are the ones of Battle::CreepyBossEncounter with
# the cap taken out, used only while Demon is in battle.
module DemonSoulWorldBoss
  def demon_uncapped?
    pkmn = @battlers[0]&.pokemon
    return !pkmn.nil? && !pkmn.egg? && pkmn.species == DemonSoul::SPECIES
  end

  def boss_hit_cap
    return nil if demon_uncapped?
    return super
  end

  def pbAttackPhase
    return super unless demon_uncapped?
    DemonSoul.uncapped do
      boss_bat = @battlers[1]
      @hp_before_turn = boss_bat ? boss_bat.hp : 0
      Battle.instance_method(:pbAttackPhase).bind_call(self)
      boss_bat = @battlers[1]
      if boss_bat && boss_bat.hp == 0 && (@hp_before_turn || 0) > 0
        damage_global = [(@hp_before_turn.to_i * @scale).round, 1].max
        NetworkClient.send_msg({ action: 'creepy_boss_damage', damage: damage_global })
        @hp_before_turn = 0
      end
    end
  end

  def pbEndOfRoundPhase
    return super unless demon_uncapped?
    DemonSoul.uncapped do
      boss_bat = @battlers[1]
      if boss_bat
        if [:POISON, :BURN].include?(boss_bat.status)
          boss_bat.status      = :NONE
          boss_bat.statusCount = 0
        end
        begin
          boss_bat.effects[PBEffects::LeechSeed] = -1
          boss_bat.effects[PBEffects::Curse]     = false
          boss_bat.effects[PBEffects::Trapping]  = 0
        rescue
        end
      end
      begin
        if [:Sandstorm, :Hail].include?(@field.weather)
          @field.weather         = :None
          @field.weatherDuration = 0
        end
      rescue
      end
      @_eor_boss_hp = boss_bat ? boss_bat.hp : nil
      Battle.instance_method(:pbEndOfRoundPhase).bind_call(self)
      next if @boss_cleared_ext
      boss_bat = @battlers[1]
      next unless boss_bat
      boss_bat.hp = @_eor_boss_hp if @_eor_boss_hp && boss_bat.hp < @_eor_boss_hp
      damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
      damage_global = damage_local > 0 ? [(damage_local * @scale).round, 1].max : 0
      _sync_with_server(damage_global, boss_bat)
      @hp_before_turn = boss_bat.hp
    end
  end

  def _boss_verify_before_faint(boss_bat)
    return super unless demon_uncapped?
    DemonSoul.uncapped do
      damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
      damage_local = 1 if damage_local < 1 && (@hp_before_turn || 0) > 0
      damage_global = damage_local > 0 ? [(damage_local * @scale).round, 1].max : 0
      @_boss_faint_guard = true
      _sync_with_server(damage_global, boss_bat)
      @_boss_faint_guard = false
      if boss_bat.hp > 0
        @hp_before_turn = boss_bat.hp
        pbDisplay(_INTL("The boss shrugs off the blow and remains standing!"))
      end
    end
  end
end
Battle::CreepyBossEncounter.prepend(DemonSoulWorldBoss)
