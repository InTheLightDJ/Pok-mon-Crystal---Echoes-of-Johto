#==============================================================================
# Pokemon TCG - animations started by effects (not by the attack damage)
#   :heal          ApplyAndAnimateHPRecovery (ATK_ANIM_HEAL, arrow + amount)
#                  / HealPlayAreaCardHP (ATK_ANIM_HEALING_WIND_PLAY_AREA, then
#                  PokemonHealedDamageText)
#   :trainer_anim  Trainer card animations (Full Heal, Gust of Wind, ...)
#   :anim          *_LoadAnimation picks the next attack animation (Gale,
#                  Devolution Beam = none); other names play right away
#                  (Solar Power, Quickfreeze)
#==============================================================================
module TCG
  class DuelScene
    LOAD_ANIMS = [:ATK_ANIM_GALE, :NONE]

    def effect_anim_event(type, *args)
      case type
      when :heal
        name, e, n, anim = args
        du = @duel.duelists.find { |x| x.name == name }
        return unless du && du.play_area[e]
        anim ||= :ATK_ANIM_HEAL
        # ORIGINAL BUG: ApplyAndAnimateHPRecovery never sets h (the side), so
        # the animation side is left over from earlier; the healed side is used here
        play_attack_animation(anim, du, du, e, n.to_i, 0, nil, heal: true)
        if anim == :ATK_ANIM_HEALING_WIND_PLAY_AREA
          message("#{Screens.name_and_level(du.card(du.play_area[e]))} healed\n#{n} damage!", keep: true)
        end
      when :trainer_anim
        d = @duel.turn_duelist
        play_attack_animation(args[0], d, @duel.non_turn_duelist, 0, 0, 0, nil)
      when :anim
        name = args[0].to_s.to_sym
        if LOAD_ANIMS.include?(name)
          @loaded_attack_anim = name
        else
          name = :"ATK_ANIM_#{name}" unless name.to_s.start_with?("ATK_ANIM_")
          d = @duel.turn_duelist
          slot = (@duel.atk && @duel.atk.temp[:power_slot]) || 0
          play_attack_animation(name, d, d, slot, 0, 0, nil)
        end
      end
    end

    # card shuffle / draw animations of the portraits screen (centered)
    def play_card_anim(name, times = 1)
      @anim_screen = :main
      @anim_target = @duel.duelists[0]
      @tracks = []
      times.times { spawn_duel_anim(name, @duel.duelists[0], 0) }
    ensure
      @tracks = nil
      @map.objs.clear
    end

    # TurnDuelistTakePrizes: the player is told and then picks the prizes;
    # the opponent's play area is shown while the AI takes them (60 frames)
    def prize_event(type, name, n)
      du = @duel.duelists.find { |x| x.name == name }
      return unless du
      text = type == :will_draw_prizes ? "#{du.name} will draw #{n} Prize(s)." : "#{du.name} drew #{n} Prize(s)."
      if du.player?
        message(text) if type == :will_draw_prizes
        return
      end
      Screens.your_or_opp_play_area(@map, @duel, du, false)
      if type == :will_draw_prizes
        Screens.text_box_lines(@map, GB.wrap(text))
        render
        60.times { frame }
      else
        message(text, keep: true)
      end
    end

    # DisplayUsePokemonPowerScreen: card information row at the top, the
    # power name at 1,4 and its description from 1,6 (1,5 for 7+ lines)
    def power_screen(name, e, ai)
      du = @duel.duelists.find { |x| x.name == name }
      return unless du && du.play_area[e]
      card = du.card(du.play_area[e])
      power = card.attacks[ai]
      @map.clear
      Screens.play_area_card_information(@map, @duel, du, e, 0)
      @map.text(1, 4, power.name)
      lines = GB.wrap(power.desc.to_s)
      lines.pop while lines.any? && lines[-1].empty?
      y = lines.size >= 7 ? 5 : 6
      lines.first(8).each_with_index { |l, n| @map.text(1, y + n, l) }
      render
      return if du.player?
      # OppAction_UsePokemonPower: WillUseThePokemonPowerText
      message("#{card.name} will use the\nPokémon Power #{power.name}.", keep: true)
    end

    alias_method :tcg_effect_anim_event, :event
    def event(type, *args)
      case type
      when :heal, :trainer_anim, :anim then effect_anim_event(type, *args)
      when :will_draw_prizes, :drew_prizes then prize_event(type, *args)
      when :power_screen then power_screen(*args)
      when :retreat
        # OppAction_AttemptRetreat: RetreatedToTheBenchText on the main scene
        du = @duel.duelists.find { |x| x.name == args[0] }
        if du && !du.player? && du.play_area[args[1]]
          message("#{du.card(du.play_area[args[1]]).name}
Retreated to the Bench.")
        end
      when :attack_animation
        # a *_LoadAnimation effect replaces the attack's animation
        if @loaded_attack_anim
          args = [@loaded_attack_anim == :NONE ? nil : @loaded_attack_anim] + args[1..]
          @loaded_attack_anim = nil
        end
        tcg_effect_anim_event(type, *args)
      else tcg_effect_anim_event(type, *args)
      end
    end
  end
end
