#===============================================================================
# Move effects for the "creepy pasta" World Boss move pool (see
# ServerStuff/handlers/creepyboss.js and 023_Networking/027_NetworkCreepyBoss.rb).
# CreepyCrawl reuses the existing BindTarget (Infestation) FunctionCode as-is —
# no new class needed for it.
#===============================================================================

#===============================================================================
# Zombify — 1/3 chance (EffectChance) to inflict the custom ZMB status. Status
# moves normally apply their effect unconditionally on hit in this engine
# (EffectChance/pbAdditionalEffect is normally only for damaging moves' bonus
# effects), so the chance roll is done by hand here via pbAdditionalEffectChance
# so Serene Grace etc. still apply correctly.
#===============================================================================
class Battle::Move::InflictZombie < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return !target.pbCanInflictStatus?(:ZMB, user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, @effectChance)
    return if @battle.pbRandom(100) >= chance
    target.pbInflictStatus(:ZMB, 0, nil, user) if target.pbCanInflictStatus?(:ZMB, user, false, self)
  end
end

#===============================================================================
# Slaphappy — hits 1-10 times. First hit deals a random 1-3 fixed damage; every
# hit after that deals exactly double the previous hit's damage. Mirrors Triple
# Kick's escalating-damage pattern (HitThreeTimesPowersUpWithEachHit) but with
# a doubling sequence instead of a fixed multiplier, and a random hit count.
#===============================================================================
class Battle::Move::SlaphappyEscalating < Battle::Move::FixedDamageMove
  def multiHitMove?; return true; end

  def pbNumHits(user, targets)
    return 1 + @battle.pbRandom(10)
  end

  def pbOnStartUse(user, targets)
    @slaphappyDmg = 0
  end

  def pbFixedDamage(user, target)
    @slaphappyDmg = (@slaphappyDmg == 0) ? (1 + @battle.pbRandom(3)) : (@slaphappyDmg * 2)
    return @slaphappyDmg
  end
end

#===============================================================================
# Vast Void — doubles the power of the user's own next move, and halves the
# power of the target's next two moves. Implemented via two new PBEffects
# slots (see 001_PBEffects.rb) checked generically in pbCalcDamageMultipliers
# (003_Move_UsageCalculations.rb) so they apply no matter which move either
# side uses next, not just moves from this file.
#===============================================================================
class Battle::Move::VastVoidBoostSelfWeakenTarget < Battle::Move
  def pbEffectAgainstTarget(user, target)
    return if target.damageState.substitute
    user.effects[PBEffects::VastVoidBoost]  = true
    target.effects[PBEffects::VastVoidWeaken] = 2
    @battle.pbDisplay(_INTL("{1} was pulled toward the vast void!", target.pbThis))
  end
end

#===============================================================================
# Secret Lair — two-turn semi-invisible move like Dig/Fly, but the exception
# that can still hit the user isn't a fixed move list — it's "any Psychic-type
# move." See the new "TwoTurnAttackInvulnerableInVoid" branch added to
# pbSuccessCheckPerHit in 009_Battler_UseMoveSuccessChecks.rb.
#===============================================================================
class Battle::Move::TwoTurnAttackInvulnerableInVoid < Battle::Move::TwoTurnMove
  def pbChargingTurnMessage(user, targets)
    @battle.pbDisplay(_INTL("{1} slipped away into its secret lair!", user.pbThis))
  end
end

#===============================================================================
# End Times — costs the user 100 HP to use (regardless of whether it hits),
# in exchange for being a one-hit KO move like Fissure/Sheer Cold.
#===============================================================================
class Battle::Move::EndTimesOHKO < Battle::Move::OHKO
  def pbEffectGeneral(user)
    user.pbReduceHP(100, false)
    @battle.pbDisplay(_INTL("{1} drew on 100 HP to unleash the end times!", user.pbThis))
  end
end

#===============================================================================
# Perfect Dark — fixed 20 HP damage to the target, heals the user a flat 30 HP
# (unrelated to the damage dealt, unlike a normal drain move), and lowers the
# target's accuracy by one stage.
#===============================================================================
class Battle::Move::PerfectDarkDrainLowerAccuracy < Battle::Move::FixedDamageMove
  def pbFixedDamage(user, target)
    return 20
  end

  def pbEffectAgainstTarget(user, target)
    return if target.damageState.substitute
    user.pbRecoverHP(30)
    @battle.pbDisplay(_INTL("{1} restored some HP!", user.pbThis))
    if target.pbCanLowerStatStage?(:ACCURACY, user)
      target.pbLowerStatStage(:ACCURACY, 1, user)
    end
  end
end
