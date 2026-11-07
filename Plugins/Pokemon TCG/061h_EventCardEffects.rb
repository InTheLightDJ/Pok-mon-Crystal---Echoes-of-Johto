#==============================================================================
# Pokemon TCG - effects of the event cards' own attacks (001e_EventCards.rb)
#   Cross Attack (Halloween Crobat)  20+: +10 for each Energy beyond its cost,
#                                    up to +20
#   Rest (Thanksgiving Snorlax)      discard 2 Energy cards, remove all damage
#                                    counters, then Asleep
#   Blizzard (Christmas Delibird)    2 coins: both heads -> Paralyzed (frozen)
#   Flail (Christmas Sudowoodo)      20 damage times its damage counters
# Shadow Ball (Halloween Gengar) is plain damage.
#==============================================================================
module TCG
  def self.event_cmds(name, *pairs); EFFECT_TABLE["Event#{name}EffectCommands"] = pairs; end
  event_cmds "CrossAttack", [EFFECT_BEFORE_DAMAGE, :EventCrossAttackEffect], [EFFECT_AI, :EventCrossAttack_AIEffect]
  event_cmds "Rest",        [EFFECT_INITIAL_EFFECT_1, :EventRest_AICheck], [EFFECT_AFTER_DAMAGE, :EventRestEffect]
  event_cmds "Blizzard",    [EFFECT_BEFORE_DAMAGE, :EventBlizzardEffect], [EFFECT_AI, :EventBlizzard_AIEffect]
  event_cmds "Flail",       [EFFECT_BEFORE_DAMAGE, :EventFlailEffect], [EFFECT_AI, :EventFlail_AIEffect]

  NEO_COIN_TEXT[:EventBlizzardEffect] = "Paralysis check! If both are\nHeads, opponent is Paralyzed."

  class Duel
    # +10 for each Energy attached to the attacker beyond the attack's cost, up to +20
    def event_extra_energy_bonus
      e = @atk.temp[:power_slot] || PLAY_AREA_ARENA
      cost = @atk.attack.cost
      extra = turn_duelist.attached_energies(e)[1] - (cost.is_a?(Hash) ? cost.values : cost).sum
      @atk.damage += 10 * [extra, 2].min if extra > 0
    end
  end

  effect(:EventCrossAttackEffect)    { |du| du.event_extra_energy_bonus; false }
  effect(:EventCrossAttack_AIEffect) { |du| du.event_extra_energy_bonus; du.set_definite_ai_damage; false }

  # the AI only rests with 50+ damage (players can any time)
  effect(:EventRest_AICheck) do |du|
    du.neo_human_choice? || du.arena_damage >= 50 ? false : _INTL("Not hurt enough to rest.")
  end
  effect(:EventRestEffect) do |du|
    d = du.turn_duelist
    du.adv_discard_own(2, :AdvDiscardEnergy)
    du.neo4_heal(PLAY_AREA_ARENA, 9999)
    d.status = ASLEEP
    du.ui.message(_INTL("{1} is now Asleep.", d.card(d.arena).name))
    du.ui.refresh(du); false
  end

  effect(:EventBlizzardEffect) do |du|
    du.coin_check(_INTL("Flip 2 coins. If both are heads, the Defending Pokémon is now Paralyzed."),
                  NEO_COIN_TEXT[:EventBlizzardEffect])
    du.queue_status(PSN_DBLPSN, PARALYZED) if du.toss_coins(2) == 2
    false
  end
  effect(:EventBlizzard_AIEffect) { |du| du.set_definite_ai_damage; false }

  effect(:EventFlailEffect)    { |du| du.set_definite_damage(du.arena_damage * 2); false }
  effect(:EventFlail_AIEffect) { |du| du.set_definite_damage(du.arena_damage * 2); du.set_definite_ai_damage; false }
end
