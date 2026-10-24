#==============================================================================
# Pokemon TCG - attack animations (PlayAttackAnimationCommands,
# engine/duel/animations/*.asm) driven by the generated 078_AnimData.rb.
#   Commands run in order like the original wDuelAnimBuffer: each duel
#   animation plays until its sprite animation ends (a frame with count -1),
#   then _UpdateQueuedAnimations disables the sprite.
#   anim_player = the duelist whose turn it is, anim_opponent = the other one
#   (a duel against the AI, wDuelType != 0), anim_play_area = the damaged slot.
#   DUEL_ANIM_SHOW_DAMAGE prints the damage text, starts the damage numbers
#   (CreateDamageCharSprite) and updates the HUD.
#==============================================================================
module TCG
  module GB
    class Renderer
      alias_method :tcg_anim_obj_sheet, :obj_sheet
      # [gfx, PALETTE_*, cgb pal] -> Anims/<gfx>.png colored, 4 flip columns
      def obj_sheet(sheet)
        return tcg_anim_obj_sheet(sheet) unless sheet.is_a?(Array)
        @anim_sheets ||= {}
        @anim_sheets[sheet] ||= begin
          gfx, pal, idx = sheet
          set = AnimData::PALETTES[pal] || []
          rgb = set[idx] || set[0] || [[31, 31, 31], [21, 21, 21], [10, 10, 10], [0, 0, 0]]
          cols = rgb.map { |r, g, b| Color.new(r * 255 / 31, g * 255 / 31, b * 255 / 31) }
          src = RPG::Cache.load_bitmap(GFX + "Anims/", gfx.to_s)
          tw = [src.width / 8, 1].max
          n = tw * (src.height / 8)
          bmp = Bitmap.new(32, [n, 1].max * 8)
          n.times do |t|
            ox = (t % tw) * 8
            oy = (t / tw) * 8
            8.times do |y|
              8.times do |x|
                v = src.get_pixel(ox + x, oy + y)
                s = 3 - ((v.red + v.green + v.blue) / 3 + 42) / 85
                next if s <= 0
                c = cols[s.clamp(0, 3)]
                bmp.set_pixel(x, t * 8 + y, c)
                bmp.set_pixel(15 - x, t * 8 + y, c)
                bmp.set_pixel(16 + x, t * 8 + 7 - y, c)
                bmp.set_pixel(31 - x, t * 8 + 7 - y, c)
              end
            end
          end
          bmp
        end
      end

      alias_method :tcg_anim_dispose, :dispose
      def dispose
        @anim_sheets&.each_value(&:dispose)
        tcg_anim_dispose
      end
    end
  end

  module AnimData
    # AnimationCoordinates: x, y (OAM), flags
    COORDS = [
      [88, 88, [:SPRITE_ANIM_FLAG_3]],
      [40, 80, []],
      [136, 48, [:SPRITE_ANIM_FLAG_Y_FLIP, :SPRITE_ANIM_FLAG_X_FLIP,
                 :SPRITE_ANIM_FLAG_Y_INVERTED, :SPRITE_ANIM_FLAG_X_INVERTED]],
      [88, 72, []], [24, 96, []], [56, 96, []], [88, 96, []], [120, 96, []], [152, 96, []],
      [88, 80, []], [152, 40, []], [120, 40, []], [88, 40, []], [56, 40, []], [24, 40, []]
    ]
    # ScreenAnimationFunctions: duration and (timer, offset) shakes
    SMALL_SHAKE = [24, [[21, 2], [17, -2], [13, 2], [9, -2], [5, 1], [1, -1]]]
    BIG_SHAKE   = [32, [[29, 4], [25, -4], [21, 4], [17, -4], [13, 3], [9, -3], [5, 2], [1, -2]]]
    # CreateDamageCharSprite: x offsets of the 3 digits, WEAK, RESIST, arrow
    DAMAGE_CHAR_X = [-16, -8, 0, 8, -8, -16]

    # one sprite animation (sprite_anim_struct)
    class Track
      attr_reader :done

      def initialize(data, sheet, pal, x, y, flags, delay = 0)
        @table, @frames = ANIMS[data]
        @gfx = sheet
        @pal = pal
        @x = x
        @y = y
        @xflip = flags.include?(:SPRITE_ANIM_FLAG_X_FLIP)
        @yflip = flags.include?(:SPRITE_ANIM_FLAG_Y_FLIP)
        @xinv  = flags.include?(:SPRITE_ANIM_FLAG_X_INVERTED)
        @yinv  = flags.include?(:SPRITE_ANIM_FLAG_Y_INVERTED)
        @delay = delay
        @i = -1
        @frame = nil
        @done = @frames.nil?
        next_frame if !@done && @delay <= 0
      end

      # HandleAnimationFrame / SetAnimationCounterAndLoop (count 0 loops)
      def next_frame
        tries = 0
        loop do
          @i += 1
          fr = @frames[@i]
          if fr.nil? || (tries += 1) > @frames.size + 1
            @done = true
            return
          end
          f, count, dx, dy = fr
          if count == 0
            @i = -1
            next
          end
          @frame = f
          @counter = count
          @x += @xinv ? -dx : dx
          @y += @yinv ? -dy : dy
          @done = true if count < 0
          return
        end
      end

      def update
        return if @done
        if @delay > 0
          @delay -= 1
          next_frame if @delay == 0
          return
        end
        @counter -= 1
        next_frame if @counter <= 0
      end

      # DrawSpriteAnimationFrame: OAM x - 8, y - 16
      def draw(objs)
        return if @done || @delay > 0 || @frame.nil? || @frame < 0
        (FRAMES[@table] || [])[@frame].to_a.each do |oy, ox, t, xf, yf, pal|
          px = @xflip ? @x - (ox + 8) : @x + ox
          py = @yflip ? @y - (oy + 8) : @y + oy
          objs << [px - 8, py - 16, t, xf ^ @xflip, yf ^ @yflip, [@gfx, @pal, pal]]
        end
      end
    end
  end

  class DuelScene
    # anim: ATK_ANIM_*; attacker: duelist whose turn it is ("player" side);
    # target / slot: the damaged Pokemon; text: damage text (SHOW_DAMAGE).
    # Returns false when there is no animation (nothing was shown).
    def play_attack_animation(anim, attacker, target, slot, dmg, eff, text, heal: false)
      @anim_heal = heal
      anim = anim.to_s.to_sym
      # PlayAttackAnimation: ATK_ANIM_HIT with 70+ damage becomes BIG_HIT
      anim = :ATK_ANIM_BIG_HIT if anim == :ATK_ANIM_HIT && dmg >= 70
      cmds = AnimData::ATTACK[anim]
      return false unless cmds
      @anim_screen = :main
      @anim_target = target
      @anim_hp_after = nil
      @tracks = []
      side = attacker
      location = 0
      draw_anim_base
      shown_damage = false
      cmds.each do |cmd, arg|
        case cmd
        when :anim_end then break
        when :anim_screen
          @anim_screen = arg == :SET_ANIM_SCREEN_PLAY_AREA ? :play_area : :main
          draw_anim_base
          next
        when :anim_player   then side = attacker
        when :anim_opponent then side = @duel.duelists.find { |x| x != attacker }
        when :anim_play_area
          side = target
          location = slot
        end
        case arg
        when :DUEL_ANIM_SHOW_DAMAGE
          show_damage_step(side, location, target, slot, dmg, eff, text)
          shown_damage = true
        when :DUEL_ANIM_SHAKE1, :DUEL_ANIM_SHAKE2, :DUEL_ANIM_SHAKE3
          # .check_duelist: X shake on the player's turn, Y on the opponent's
          x_first = attacker.player?
          x_first = !x_first if arg == :DUEL_ANIM_SHAKE3
          shake(arg == :DUEL_ANIM_SHAKE2 ? AnimData::BIG_SHAKE : AnimData::SMALL_SHAKE, x_first)
        when :DUEL_ANIM_SMALL_SHAKE_X then shake(AnimData::SMALL_SHAKE, true)
        when :DUEL_ANIM_BIG_SHAKE_X   then shake(AnimData::BIG_SHAKE, true)
        when :DUEL_ANIM_SMALL_SHAKE_Y then shake(AnimData::SMALL_SHAKE, false)
        when :DUEL_ANIM_BIG_SHAKE_Y   then shake(AnimData::BIG_SHAKE, false)
        when :DUEL_ANIM_FLASH         then white_flash
        when :DUEL_ANIM_UPDATE_HUD    then draw_anim_base
        else
          spawn_duel_anim(arg, side, location)
        end
      end
      run_tracks { @tracks.all?(&:done) }
      if shown_damage && text
        blink_wait(18, 17, SYM_CURSOR_D, SYM_BOX_BOTTOM, [Input::USE, Input::BACK])
      end
      true
    ensure
      @map.objs.clear
      @map.scroll_x = @map.scroll_y = 0
      @map.flash = false
      @tracks = nil
    end

    def draw_anim_base
      if @anim_screen == :main
        with_anim_hp { Screens.duel_main_scene(@map, @duel) }
      else
        with_anim_hp { Screens.your_or_opp_play_area(@map, @duel, @anim_target, @anim_target.player?) }
        @map.wide_text_box
      end
      render_anim
    end

    # the HUD shows the HP after the damage once SHOW_DAMAGE updated it
    def with_anim_hp
      return yield unless @anim_hp_after
      du, e, hp = @anim_hp_after
      old = du.slot_hp[e]
      du.slot_hp[e] = hp
      begin
        yield
      ensure
        du.slot_hp[e] = old
      end
    end

    def render_anim
      @map.objs.clear
      @tracks&.each { |t| t.draw(@map.objs) }
      render
    end

    def run_tracks
      300.times do
        break if yield
        @tracks.each(&:update)
        render_anim
        frame
      end
    end

    # AnimationCoordinatesIndex + GetAnimCoordsAndFlags
    def anim_coords(side, location, flags)
      idx = if flags.include?(:SPRITE_ANIM_FLAG_CENTERED) then 0
            elsif @anim_screen == :main then side.player? ? 1 : 2
            else (@anim_target.player? ? 3 : 9) + location
            end
      x, y, cflags = AnimData::COORDS[idx] || AnimData::COORDS[0]
      [x, y, flags & cflags]
    end

    def spawn_duel_anim(name, side, location)
      entry = AnimData::DUEL[name]
      return unless entry
      sheet, pal, data, flags = entry
      x, y, f = anim_coords(side, location, flags)
      track = AnimData::Track.new(data, sheet, pal, x, y, f)
      @tracks << track
      run_tracks { track.done }
    end

    def shake(spec, x_axis)
      duration, offsets = spec
      pos = 0
      i = 0
      duration.times do
        duration -= 1
        if i < offsets.size && duration < offsets[i][0]
          pos += offsets[i][1]
          i += 1
        end
        x_axis ? @map.scroll_x = pos : @map.scroll_y = pos
        @tracks.each(&:update)
        render_anim
        frame
      end
      @map.scroll_x = @map.scroll_y = 0
      render_anim
    end

    def white_flash
      @map.flash = true
      8.times do
        @tracks.each(&:update)
        render_anim
        frame
      end
      @map.flash = false
      render_anim
    end

    # DUEL_ANIM_PRINT_DAMAGE + DUEL_ANIM_DAMAGE_HUD + DUEL_ANIM_UPDATE_HUD
    def show_damage_step(side, location, target, slot, dmg, eff, text)
      hp = target.slot_hp[slot]
      if @anim_heal
        c = target.card(target.play_area[slot])
        max = c.trainer? ? 10 : c.hp.to_i
        @anim_hp_after = [target, slot, [hp + dmg, max].min]
      elsif dmg > 0
        @anim_hp_after = [target, slot, [hp - dmg, 0].max]
      end
      draw_anim_base
      Screens.text_box_lines(@map, GB.wrap(text)) if text
      x, y, = anim_coords(side, location, [])
      spawn_damage_numbers(x, y, dmg, eff, @anim_heal)
      render_anim
    end

    # DrawDamageAnimationNumbers + the effectiveness sprites. The decomp's
    # wDuelAnimEffectiveness bits are 0 = arrow (healing), 1 = Weakness,
    # 2 = Resistance (its routine names are shifted by one: "Weak" draws the
    # arrow, SPRITE_ANIM_91 / frame 12; "Resist" draws WEAK, 90; "Arrow"
    # draws RESIST, 89). WEAK waits 18 frames, RESIST 18 more after WEAK.
    def spawn_damage_numbers(x, y, dmg, eff, arrow = false)
      return if dmg >= 1000
      digits = [dmg / 100 % 10, dmg / 10 % 10, dmg % 10]
      digits[0] = nil if dmg < 100
      digits[1] = nil if dmg < 10
      digits.each_with_index do |d, i|
        next unless d
        @tracks << AnimData::Track.new(:"AnimData#{79 + d}", :damage, :PALETTE_DAMAGE,
                                       x + AnimData::DAMAGE_CHAR_X[i], y, [])
      end
      if arrow
        @tracks << AnimData::Track.new(:AnimData91, :damage, :PALETTE_DAMAGE, x + AnimData::DAMAGE_CHAR_X[3], y, [], 0)
      end
      delay = 18
      if (eff & WEAKNESS) != 0
        @tracks << AnimData::Track.new(:AnimData90, :damage, :PALETTE_DAMAGE, x + AnimData::DAMAGE_CHAR_X[4], y, [], delay)
        delay += 18
      end
      if (eff & RESISTANCE) != 0
        @tracks << AnimData::Track.new(:AnimData89, :damage, :PALETTE_DAMAGE, x + AnimData::DAMAGE_CHAR_X[5], y, [], delay)
      end
    end
  end
end
