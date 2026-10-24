#==============================================================================
# Pokemon TCG - damage texts (PrintDamageText / GetDamageText,
# engine/duel/animations/commands.asm). The attack animations themselves are
# not ported; the text is printed on the screen the original animates on:
# the main scene for the Arena, the play area of the damaged side
# (DealDamageToPlayAreaPokemon_RegularAnim) for the Bench.
#==============================================================================
module TCG
  module Screens
    module_function

    # GetDamageText (nil when nothing is printed)
    def damage_text(card, dmg, eff, no_damage_or_effect)
      name = name_and_level(card)
      if dmg > 0
        if (eff & WEAKNESS) != 0
          "#{name} received\n#{dmg} damage due to Weakness!"
        elsif (eff & RESISTANCE) != 0
          "#{name} received\n#{dmg} damage due to Resistance!"
        else
          "#{name} took\n#{dmg} damage."
        end
      else
        return nil if no_damage_or_effect   # CheckNoDamageOrEffect prints its own text
        (eff & RESISTANCE) != 0 ? "#{name} did not\nreceive damage due to Resistance." : "#{name} did not\nreceive damage!"
      end
    end
  end

  class DuelScene
    NO_DAMAGE_TEXT_ANIMS = %w[ATK_ANIM_HEAL ATK_ANIM_HEALING_WIND_PLAY_AREA]

    # text box over the current screen; A/B goes on (the original keeps the
    # text up until the next box)
    def damage_message(text)
      return unless text
      message(text, keep: true)
    end

    def no_damage_or_effect?
      @duel.atk && @duel.atk.no_damage_or_effect.to_i != 0
    end

    alias_method :tcg_damage_event, :event
    def event(type, *args)
      case type
      when :attack_animation
        # PlayAttackAnimation_DealAttackDamage: defending Arena Pokemon
        anim, dmg, eff = args
        nd = @duel.non_turn_duelist
        return unless nd.arena
        text = nil
        unless NO_DAMAGE_TEXT_ANIMS.include?(anim.to_s)
          text = Screens.damage_text(nd.card(nd.arena), dmg.to_i, eff.to_i, no_damage_or_effect?)
        end
        return if play_attack_animation(anim, @duel.turn_duelist, nd, PLAY_AREA_ARENA, dmg.to_i, eff.to_i, text)
        Screens.duel_main_scene(@map, @duel)
        damage_message(text)
      when :damage
        # DealDamageToPlayAreaPokemon: Arena on the main scene, Bench on the
        # damaged duelist's play area
        name, e, dmg, anim = args
        du = @duel.duelists.find { |x| x.name == name }
        return unless du && du.play_area[e]
        text = nil
        unless NO_DAMAGE_TEXT_ANIMS.include?(anim.to_s) || dmg.to_i <= 0
          text = Screens.damage_text(du.card(du.play_area[e]), dmg.to_i, 0, false)
        end
        attacker = @duel.duelists[@duel.whose_turn || @duel.turn]
        return if play_attack_animation(anim || :ATK_ANIM_BENCH_HIT, attacker, du, e, dmg.to_i, 0, text)
        if e == PLAY_AREA_ARENA
          Screens.duel_main_scene(@map, @duel)
        else
          Screens.your_or_opp_play_area(@map, @duel, du, du.player?)
        end
        damage_message(text)
      when :self_damage
        # confusion / recoil: the attacker damages itself
        anim, dmg = args
        d = @duel.turn_duelist
        return unless d.arena
        text = Screens.damage_text(d.card(d.arena), dmg.to_i, 0, false)
        return if play_attack_animation(anim, d, d, PLAY_AREA_ARENA, dmg.to_i, 0, text)
        Screens.duel_main_scene(@map, @duel)
        damage_message(text)
      else tcg_damage_event(type, *args)
      end
    end
  end
end
