#===============================================================================
#
#===============================================================================
module Battle::PokeBallEffects
  IsUnconditional = ItemHandlerHash.new
  ModifyCatchRate = ItemHandlerHash.new
  OnCatch         = ItemHandlerHash.new
  OnFailCatch     = ItemHandlerHash.new

  def self.isUnconditional?(ball, battle, battler)
    ret = IsUnconditional.trigger(ball, battle, battler)
    return (!ret.nil?) ? ret : false
  end

  def self.modifyCatchRate(ball, catchRate, battle, battler)
    ret = ModifyCatchRate.trigger(ball, catchRate, battle, battler)
    return (!ret.nil?) ? ret : catchRate
  end

  def self.onCatch(ball, battle, pkmn)
    OnCatch.trigger(ball, battle, pkmn)
  end

  def self.onFailCatch(ball, battle, battler)
    $stats.failed_poke_ball_count += 1
    OnFailCatch.trigger(ball, battle, battler)
  end
end

#===============================================================================
# IsUnconditional
#===============================================================================
Battle::PokeBallEffects::IsUnconditional.add(:MASTERBALL, proc { |ball, battle, battler|
  next true
})

Battle::PokeBallEffects::IsUnconditional.add(:ORIGINBALL, proc { |ball, battle, battler|
  next [:DIALGA, :PALKIA, :GIRATINA].include?(battler.species) && battler.form == 1
})

#===============================================================================
# ModifyCatchRate
# NOTE: This code is not called if the battler is an Ultra Beast (except if the
#       Ball is a Beast Ball). In this case, all Balls' catch rates are set
#       elsewhere to 0.1x.
#===============================================================================
Battle::PokeBallEffects::ModifyCatchRate.add(:GREATBALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 1.5
})

Battle::PokeBallEffects::ModifyCatchRate.add(:ULTRABALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 2
})

Battle::PokeBallEffects::ModifyCatchRate.add(:SAFARIBALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 1.5
})

Battle::PokeBallEffects::ModifyCatchRate.add(:NETBALL, proc { |ball, catchRate, battle, battler|
  multiplier = (Settings::NEW_POKE_BALL_CATCH_RATES) ? 3.5 : 3
  catchRate *= multiplier if battler.pbHasType?(:BUG) || battler.pbHasType?(:WATER)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:DIVEBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 3.5 if battle.environment == :Underwater
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:NESTBALL, proc { |ball, catchRate, battle, battler|
  if battler.level <= 30
    catchRate *= [(41 - battler.level) / 10.0, 1].max
  end
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:REPEATBALL, proc { |ball, catchRate, battle, battler|
  multiplier = (Settings::NEW_POKE_BALL_CATCH_RATES) ? 3.5 : 3
  catchRate *= multiplier if battle.pbPlayer.owned?(battler.species)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:TIMERBALL, proc { |ball, catchRate, battle, battler|
  multiplier = [1 + (0.3 * battle.turnCount), 4].min
  catchRate *= multiplier
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:DUSKBALL, proc { |ball, catchRate, battle, battler|
  multiplier = (Settings::NEW_POKE_BALL_CATCH_RATES) ? 3 : 3.5
  catchRate *= multiplier if battle.time == 2   # Night or in cave
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:QUICKBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 5 if battle.turnCount == 0
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:FASTBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= 4 if baseSpeed >= 100
  next [catchRate, 255].min
})

Battle::PokeBallEffects::ModifyCatchRate.add(:LEVELBALL, proc { |ball, catchRate, battle, battler|
  maxlevel = 0
  battle.allSameSideBattlers.each { |b| maxlevel = b.level if b.level > maxlevel }
  if maxlevel >= battler.level * 4
    catchRate *= 8
  elsif maxlevel >= battler.level * 2
    catchRate *= 4
  elsif maxlevel > battler.level
    catchRate *= 2
  end
  next [catchRate, 255].min
})

Battle::PokeBallEffects::ModifyCatchRate.add(:LUREBALL, proc { |ball, catchRate, battle, battler|
  if $game_temp.encounter_type &&
     GameData::EncounterType.get($game_temp.encounter_type).type == :fishing
    multiplier = (Settings::NEW_POKE_BALL_CATCH_RATES) ? 5 : 3
    catchRate *= multiplier
  end
  next [catchRate, 255].min
})

Battle::PokeBallEffects::ModifyCatchRate.add(:HEAVYBALL, proc { |ball, catchRate, battle, battler|
  next 0 if catchRate == 0
  weight = battler.pbWeight
  if Settings::NEW_POKE_BALL_CATCH_RATES
    if weight >= 3000
      catchRate += 30
    elsif weight >= 2000
      catchRate += 20
    elsif weight < 1000
      catchRate -= 20
    end
  else
    if weight >= 4096
      catchRate += 40
    elsif weight >= 3072
      catchRate += 30
    elsif weight >= 2048
      catchRate += 20
    else
      catchRate -= 20
    end
  end
  next catchRate.clamp(1, 255)
})

Battle::PokeBallEffects::ModifyCatchRate.add(:LOVEBALL, proc { |ball, catchRate, battle, battler|
  battle.allSameSideBattlers.each do |b|
    next if b.species != battler.species
    next if b.gender == battler.gender || b.gender == 2 || battler.gender == 2
    catchRate *= 8
    break
  end
  next [catchRate, 255].min
})

Battle::PokeBallEffects::ModifyCatchRate.add(:MOONBALL, proc { |ball, catchRate, battle, battler|
  # NOTE: Moon Ball cares about whether any species in the target's evolutionary
  #       family can evolve with the Moon Stone, not whether the target itself
  #       can immediately evolve with the Moon Stone.
  moon_stone = GameData::Item.try_get(:MOONSTONE)
  if moon_stone && battler.pokemon.species_data.family_item_evolutions_use_item?(moon_stone.id)
    catchRate *= 4
  end
  next [catchRate, 255].min
})

Battle::PokeBallEffects::ModifyCatchRate.add(:SPORTBALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 1.5
})

Battle::PokeBallEffects::ModifyCatchRate.add(:DREAMBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 4 if battler.asleep?
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:BEASTBALL, proc { |ball, catchRate, battle, battler|
  if battler.pokemon.species_data.has_flag?("UltraBeast")
    catchRate *= 5
  else
    catchRate /= 10
  end
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:GSBALL, proc { |ball, catchRate, battle, battler|
  catchRate *= 5 if battler.pbHasType?(:BUG)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:PLIPBALL, proc { |ball, catchRate, battle, battler|
  next catchRate / 20
})

Battle::PokeBallEffects::ModifyCatchRate.add(:RIFTBALL, proc { |ball, catchRate, battle, battler|
  pkmn      = battler.pokemon
  knows_tp  = pkmn.moves.any? { |m| m && m.id == :TELEPORT }
  run_away  = pkmn.hasAbility?(:RUNAWAY)
  fast_base = (pkmn.baseStats[:SPEED] rescue 0) >= 100
  next (knows_tp || run_away || fast_base) ? catchRate * 4.0 : catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:HISUIANPOKEBALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 0.75
})

Battle::PokeBallEffects::ModifyCatchRate.add(:HISUIANGREATBALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 1.5
})

Battle::PokeBallEffects::ModifyCatchRate.add(:HISUIANULTRABALL, proc { |ball, catchRate, battle, battler|
  next catchRate * 2.25
})

Battle::PokeBallEffects::ModifyCatchRate.add(:HISUIANHEAVYBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= 1.25 if baseSpeed <= 50
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:LEADENBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= ((baseSpeed <= 50) ? 2 : 1.25)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:GIGATONBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= ((baseSpeed <= 50) ? 2.75 : 2)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:FEATHERBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= 1.25 if battler.airborne? || baseSpeed >= 100
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:WINGBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= ((battler.airborne? || baseSpeed >= 100) ? 2 : 1.25)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:JETBALL, proc { |ball, catchRate, battle, battler|
  baseStats = battler.pokemon.baseStats
  baseSpeed = baseStats[:SPEED]
  catchRate *= ((battler.airborne? || baseSpeed >= 100) ? 2.75 : 2)
  next catchRate
})

Battle::PokeBallEffects::ModifyCatchRate.add(:STRANGEBALL, proc { |ball, catchRate, battle, battler|
  next catchRate
})

#===============================================================================
# OnCatch
#===============================================================================
Battle::PokeBallEffects::OnCatch.add(:HEALBALL, proc { |ball, battle, pkmn|
  pkmn.heal
})

Battle::PokeBallEffects::OnCatch.add(:FRIENDBALL, proc { |ball, battle, pkmn|
  pkmn.happiness = (Settings::APPLY_HAPPINESS_SOFT_CAP) ? 150 : 200
})

Battle::PokeBallEffects::OnCatch.add(:PLIPBALL, proc { |ball, battle, pkmn|
  # Reroll any IV below 30 once
  [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
    pkmn.iv[stat] = rand(32) if pkmn.iv[stat] < 30
  end
  pkmn.calc_stats
  # Teach a random move in slot 1
  pkmn.moves[0] = Pokemon::Move.new(GameData::Move.keys.sample)
  pbGiveAchievement(2)
})

