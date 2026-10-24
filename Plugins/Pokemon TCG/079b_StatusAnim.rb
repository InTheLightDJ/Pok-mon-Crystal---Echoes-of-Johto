#==============================================================================
# Pokemon TCG - between turns (HandleBetweenTurnsEvents, engine/duel/core.asm)
#   "Between Turns." box message, then for each Arena Pokémon its poison
#   damage (text, DUEL_ANIM_POISON, damage numbers, HUD, Knocked Out text),
#   sleep check result (SLEEP / HEAL animation) and paralysis recovery.
#   Also prints "X was\nKnocked Out!" with the original line break.
#==============================================================================
module TCG
  class DuelScene
    STATUS_TEXTS = {
      :poison          => "%s received\n%d damage due to Poison.",
      :double_poison   => "%s received\n%d damage due to Double Poison.",
      :burn            => "%s received\n%d damage due to Burn.",
      :still_asleep    => "%s is\nstill Asleep.",
      :cured_sleep     => "%s is\ncured of Sleep.",
      :cured_paralysis => "%s is\ncured of Paralysis."
    }
    STATUS_ANIMS = { :poison => :DUEL_ANIM_POISON, :still_asleep => :DUEL_ANIM_SLEEP,
                     :cured_sleep => :DUEL_ANIM_HEAL, :cured_paralysis => :DUEL_ANIM_HEAL,
                     :burn => :DUEL_ANIM_SMALL_FLAME }

    # PlayBetweenTurnsAnimation: one duel animation on the main scene
    def play_between_turns_animation(name, du)
      @anim_screen = :main
      @anim_target = du
      @tracks = []
      spawn_duel_anim(name, du, 0)
      run_tracks { @tracks.all?(&:done) }
    end

    def between_turns_screen
      @map.clear
      @map.wide_text_box
      render
      show_banner(:between_turns)
      message("Between Turns.", keep: true)
      hide_banner
    end

    def status_anim_event(name, kind, dmg = nil, hp_before = nil)
      du = @duel.duelists.find { |x| x.name == name }
      return unless du && du.arena
      card = du.card(du.arena)
      text_kind = kind == :poison && dmg.to_i > PSN_DAMAGE ? :double_poison : kind
      text = format(STATUS_TEXTS[text_kind], card.name, dmg.to_i)
      @anim_hp_after = hp_before ? [du, PLAY_AREA_ARENA, hp_before] : nil
      with_anim_hp { Screens.duel_main_scene(@map, @duel) }
      Screens.text_box_lines(@map, GB.wrap(text))
      render
      play_between_turns_animation(STATUS_ANIMS[kind], du)
      if kind == :poison || kind == :burn   # Burn: 061c_NeoEffects2.rb
        # SubtractHP + DUEL_ANIM_DAMAGE_HUD (damage numbers, HUD redrawn)
        @anim_hp_after = nil
        Screens.duel_main_scene(@map, @duel)
        Screens.text_box_lines(@map, GB.wrap(text))
        x, y, = anim_coords(du, 0, [])
        spawn_damage_numbers(x, y, dmg.to_i, 0)
        run_tracks { @tracks.all?(&:done) }
        if du.slot_hp[PLAY_AREA_ARENA] == 0
          # PrintKnockedOutIfHLZero: text, 40 frames
          Screens.text_box_lines(@map, GB.wrap("#{card.name} was\nKnocked Out!"))
          render_anim
          40.times { frame }
        end
      else
        Screens.duel_main_scene(@map, @duel)
        Screens.text_box_lines(@map, GB.wrap(text))
      end
      render_anim
      blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
    ensure
      @anim_hp_after = nil
      @tracks = nil
      @map.objs.clear
    end

    # WasKnockedOutText keeps the name on its own line
    alias_method :tcg_status_message, :message
    def message(text, keep: false)
      text = text.to_s.sub(/\A(.+) was Knocked Out!\z/m, "\\1 was\nKnocked Out!")
      tcg_status_message(text, keep: keep)
    end

    alias_method :tcg_status_event, :event
    def event(type, *args)
      case type
      when :between_turns then between_turns_screen
      when :status_anim   then status_anim_event(*args)
      else tcg_status_event(type, *args)
      end
    end
  end
end
