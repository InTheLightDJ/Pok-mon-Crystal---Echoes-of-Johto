#==============================================================================
# Pokemon TCG - hand-ported EFFECTCMDTYPE_AI functions (effect_functions.asm).
# Most run the real damage step and then SetDefiniteAIDamage (min = max = damage).
# Water Gun / Hydro Pump / Do the Wave / Sonicboom reuse their phase-3 functions.
#==============================================================================
module TCG
  class Duel
    def set_definite_ai_damage
      @atk.ai_min = @atk.ai_max = @atk.damage
    end
  end

  # NOTE (original): Rage/Flail AI use the ARENA Pokemon's damage even when the
  # AI is evaluating a benched attacker.
  { :KinglerFlail_AIEffect => :KinglerFlail_HPCheck, :MagikarpFlail_AIEffect => :MagikarpFlail_HPCheck,
    :FlamesOfRage_AIEffect => :FlamesOfRage_DamageBoostEffect, :FlareonRage_AIEffect => :FlareonRage_DamageBoostEffect,
    :MrMimeMeditate_AIEffect => :MrMimeMeditate_DamageBoostEffect, :Psychic_AIEffect => :Psychic_DamageBoostEffect,
    :JynxMeditate_AIEffect => :JynxMeditate_DamageBoostEffect, :CuboneRage_AIEffect => :CuboneRage_DamageBoostEffect,
    :KarateChop_AIEffect => :KarateChop_DamageSubtractionEffect, :DodrioRage_AIEffect => :DodrioRage_DamageBoostEffect,
    :SuperFang_AIEffect => :SuperFang_HalfHPEffect }.each do |ai, real|
    effect(ai) do |du|
      EffectFunctions[real].call(du)
      du.set_definite_ai_damage
      false
    end
  end

  effect(:Rampage_AIEffect) do |du|
    du.atk.damage += du.arena_damage
    du.set_definite_ai_damage; false
  end

  # Big Eggsplosion: max = 20 x energy (cap 255), avg = max / 2, min = 0
  effect(:BigEggsplosion_AIEffect) do |du|
    e = du.atk.temp[:power_slot] || PLAY_AREA_ARENA
    mx = [20 * du.turn_duelist.attached_energies(e)[1], 255].min
    du.atk.ai_max = mx
    du.atk.damage = mx >> 1
    du.atk.ai_min = 0
    false
  end

  # Mirror Move: expected damage = damage received last turn
  effect(:MirrorMove_AIEffect) do |du|
    v = du.turn_duelist.last_turn_damage & 0xff
    du.atk.ai_min = du.atk.ai_max = v
    false
  end
  effects(:SpearowMirrorMove_AIEffect, :PidgeottoMirrorMove_AIEffect) { |du| EffectFunctions[:MirrorMove_AIEffect].call(du) }
end
