#===============================================================================
# Battle Candy — S/M/L. Used mid-battle only (BattleUse = OnPokemon in
# items.txt, no FieldUse). Temporarily raises the level of the Pokémon
# currently in battle by 1/3/5 for the rest of that battle only, boosting its
# stats and level-dependent move power (Seismic Toss, Gyro Ball, etc.) to help
# with fights well above the Pokémon's real level, like World Bosses.
#
# The real Pokemon object's level/exp are never touched — only the in-battle
# Battle::Battler's cached stats are overlaid with a temporary bonus. This
# means normal Exp gained during the same battle still applies to (and
# levels up) the Pokémon's true level exactly as it always would; the candy
# bonus is simply layered back on top every time the battler is refreshed
# (see the pbUpdate alias below). Switching the Pokémon out clears the bonus
# (see the pbInitPokemon alias below) — the boost only lasts while that
# Pokémon stays in the fight.
#===============================================================================

class Pokemon
  # Like calc_stats, but returns the stats this Pokémon would have at
  # new_level without changing anything about the Pokémon itself.
  def temp_stats_at_level(new_level)
    base_stats = self.baseStats
    this_iv    = self.calcIV
    nature_mod = {}
    GameData::Stat.each_main { |s| nature_mod[s.id] = 100 }
    this_nature = self.nature_for_stats
    this_nature&.stat_changes&.each { |change| nature_mod[change[0]] += change[1] }
    stats = {}
    GameData::Stat.each_main do |s|
      if s.id == :HP
        stats[s.id] = calcHP(base_stats[s.id], new_level, this_iv[s.id], @ev[s.id])
      else
        stats[s.id] = calcStat(base_stats[s.id], new_level, this_iv[s.id], @ev[s.id], nature_mod[s.id])
      end
    end
    return stats
  end
end

class Battle::Battler
  attr_accessor :candy_bonus_levels

  # Adds levels of temporary bonus (clamped so real level + bonus never
  # exceeds the level cap). Returns the new effective (real + bonus) level.
  def pbApplyBattleCandy(levels)
    return @level if !@pokemon
    @candy_bonus_levels ||= 0
    max_bonus = GameData::GrowthRate.max_level - @pokemon.level
    new_bonus = [@candy_bonus_levels + levels, max_bonus].min
    return @level if new_bonus <= @candy_bonus_levels
    @candy_bonus_levels = new_bonus
    pbRefreshBattleCandyStats
    return @level
  end

  # Re-applies the current candy bonus on top of the Pokémon's real stats.
  # Called after every pbUpdate so a real mid-battle level-up (from Exp) is
  # still reflected underneath the temporary bonus.
  def pbRefreshBattleCandyStats
    return if !@pokemon || !@candy_bonus_levels || @candy_bonus_levels <= 0
    temp_level = @pokemon.level + @candy_bonus_levels
    new_stats  = @pokemon.temp_stats_at_level(temp_level)
    hp_diff    = new_stats[:HP] - @totalhp
    @totalhp   = new_stats[:HP]
    @hp        = [@hp + hp_diff, 1].max if @hp > 0
    @attack    = new_stats[:ATTACK]
    @defense   = new_stats[:DEFENSE]
    @spatk     = new_stats[:SPECIAL_ATTACK]
    @spdef     = new_stats[:SPECIAL_DEFENSE]
    @speed     = new_stats[:SPEED]
    @level     = temp_level
  end

  alias_method :battle_candy_orig_pbUpdate, :pbUpdate
  def pbUpdate(fullChange = false)
    battle_candy_orig_pbUpdate(fullChange)
    pbRefreshBattleCandyStats
  end

  alias_method :battle_candy_orig_pbInitPokemon, :pbInitPokemon
  def pbInitPokemon(pkmn, idxParty)
    @candy_bonus_levels = 0
    battle_candy_orig_pbInitPokemon(pkmn, idxParty)
  end
end

BATTLE_CANDY_LEVELS = { BATTLECANDYS: 1, BATTLECANDYM: 3, BATTLECANDYL: 5 }.freeze

def pbBattleCandyLevelUp(item, pokemon, battler, scene)
  levels    = BATTLE_CANDY_LEVELS[GameData::Item.get(item).id] || 1
  old_level = battler.level
  new_level = battler.pbApplyBattleCandy(levels)
  if new_level <= old_level
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  end
  scene.pbDisplay(_INTL("{1}'s level rose to {2} for the rest of the battle!", pokemon.name, new_level))
  scene.pbRefresh
  return true
end

ItemHandlers::CanUseInBattle.add(:BATTLECANDYS, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  if !battler
    scene.pbDisplay(_INTL("It can only be used on a Pokémon currently in battle.")) if showMessages
    next false
  end
  if !pokemon.able? || battler.level >= GameData::GrowthRate.max_level
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})
ItemHandlers::CanUseInBattle.copy(:BATTLECANDYS, :BATTLECANDYM, :BATTLECANDYL)

ItemHandlers::BattleUseOnPokemon.add(:BATTLECANDYS, proc { |item, pokemon, battler, choices, scene|
  next pbBattleCandyLevelUp(item, pokemon, battler, scene)
})
ItemHandlers::BattleUseOnPokemon.copy(:BATTLECANDYS, :BATTLECANDYM, :BATTLECANDYL)
