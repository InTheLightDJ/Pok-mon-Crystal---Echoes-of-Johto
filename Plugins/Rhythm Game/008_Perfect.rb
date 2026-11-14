#==============================================================================
# Rhythm Game - the perfect half: when half the song's notes are played
# without a miss (or a wrong press), a purple wave sweeps up the screen and
# keeps rolling up behind the track, and an Igglybuff walks in on each side
# of the track (beside it, not on it), glows holding a step forward, and
# turns into the end credits' dancing Igglybuff (credits4_pkmn). On the
# first miss the wave fades and they turn back and walk off.
#==============================================================================
module RhythmGame
  class PurpleWave
    COLOR   = [185, 90, 255]
    PERIOD  = 96       # pixels between the rolling waves
    SPEED   = 40.0     # how fast they roll up, pixels a second
    SWEEP_H = 56       # the first wave, sweeping up over everything
    SWEEP_T = 0.9      # seconds to cross the screen
    FADE    = 2.0      # level a second

    def initialize(viewport, z_back, z_front)
      @w = Graphics.width
      @h = Graphics.height
      @level = 0.0
      @last = nil
      @sweep_at = nil
      @bands = Sprite.new(viewport)
      @bands.bitmap = band_bitmap
      @bands.z = z_back
      @sweep = Sprite.new(viewport)
      @sweep.bitmap = sweep_bitmap
      @sweep.z = z_front
      [@bands, @sweep].each { |s| s.visible = false; s.opacity = 0 }
    end

    # wavy purple bands, PERIOD apart, one period taller than the screen
    def band_bitmap
      bmp = Bitmap.new(@w, @h + PERIOD)
      r, g, b = COLOR
      (0...@w).step(4) do |x|
        off = 10 * Math.sin(2 * Math::PI * x / 90.0)
        (0...(@h + PERIOD)).step(2) do |y|
          a = (0.5 + (0.5 * Math.sin(2 * Math::PI * (y + off) / PERIOD)))**3
          next if a < 0.04
          bmp.fill_rect(x, y, 4, 2, Color.new(r, g, b, (125 * a).round))
        end
      end
      bmp
    end

    # one bright wavy band
    def sweep_bitmap
      bmp = Bitmap.new(@w, SWEEP_H)
      r, g, b = COLOR
      half = SWEEP_H / 2.0
      (0...@w).step(4) do |x|
        off = 7 * Math.sin(2 * Math::PI * x / 70.0)
        (0...SWEEP_H).step(2) do |y|
          d = 1 - ((y - half - off).abs / (half - 7))
          next if d <= 0
          light = (d**2 * 120).round
          bmp.fill_rect(x, y, 4, 2, Color.new([r + light, 255].min, [g + light, 255].min, 255, (220 * d**1.5).round))
        end
      end
      bmp
    end

    def update(on, t)
      dt = @last ? (t - @last).clamp(0, 0.1) : 0
      @last = t
      @sweep_at ||= t if on
      @level = (@level + ((on ? FADE : -FADE) * dt)).clamp(0.0, 1.0)
      @bands.visible = @level > 0
      @bands.opacity = (255 * @level * (0.8 + (0.2 * Math.sin(t * 3)))).round.clamp(0, 255)
      @bands.y = -((t * SPEED) % PERIOD).round
      k = @sweep_at ? (t - @sweep_at) / SWEEP_T : 2
      @sweep.visible = k < 1
      return unless @sweep.visible
      @sweep.y = (@h - ((@h + SWEEP_H) * k)).round
      @sweep.opacity = (255 * [1.0, (1 - k) * 3].min).round
    end

    def dispose
      [@bands, @sweep].each { |s| s.bitmap&.dispose; s.dispose }
    end
  end

  class Igglybuffs
    WALKER  = ["Graphics/Characters/Followers/", "IGGLYBUFF"]
    DANCER  = ["Graphics/Titles/Crystal/", "credits4_pkmn"]   # 4 frames, as in the end credits
    SPEED   = 70.0     # walking, pixels a second
    STEP    = 0.14     # seconds a walk frame
    GLOW_T  = 2.5      # glowing, holding a step, before it turns
    FLASH_T = 0.4      # the dancer fading in from white
    DANCE_T = 0.1      # seconds a dance frame (the credits' 2/20)
    DOWN, LEFT, RIGHT, UP = 0, 1, 2, 3

    # homes: the x each stands at (left side, right side); feet: their y
    def initialize(viewport, homes, feet, z)
      walk = (RPG::Cache.load_bitmap(*WALKER) rescue nil)
      dance = (RPG::Cache.load_bitmap(*DANCER) rescue nil)
      @buffs = []
      return unless walk && dance
      fw = walk.width / 4
      fh = walk.height / 4
      dw = dance.width / 4
      dh = dance.height
      homes.each_with_index do |home, i|
        w = Sprite.new(viewport)
        w.bitmap = walk
        w.ox = fw / 2
        w.oy = fh
        w.y = feet
        d = Sprite.new(viewport)
        d.bitmap = dance
        d.ox = dw / 2
        d.oy = dh - 2
        d.x = home
        d.y = feet
        [w, d].each { |s| s.z = z; s.visible = false }
        off = i == 0 ? -fw : Graphics.width + fw
        @buffs << { walker: w, dancer: d, fw: fw, fh: fh, dw: dw, dh: dh, home: home, off: off,
                    x: off.to_f, state: :off, since: 0, inward: i == 0 ? RIGHT : LEFT, outward: i == 0 ? LEFT : RIGHT }
      end
      @last = nil
    end

    def update(on, t)
      dt = @last ? (t - @last).clamp(0, 0.1) : 0
      @last = t
      @buffs.each do |b|
        w = b[:walker]
        d = b[:dancer]
        if on && %i[off leave].include?(b[:state])
          b[:state] = :walk_in
        elsif !on && %i[walk_in glow dance].include?(b[:state])
          b[:state] = :leave
          b[:since] = t
        end
        case b[:state]
        when :walk_in
          b[:x] = [b[:x] + (SPEED * dt), b[:home]].min if b[:inward] == RIGHT
          b[:x] = [b[:x] - (SPEED * dt), b[:home]].max if b[:inward] == LEFT
          walk_frame(b, b[:inward], t)
          w.tone = Tone.new(0, 0, 0)
          if b[:x] == b[:home]
            b[:state] = :glow
            b[:since] = t
          end
        when :glow
          # faces forward, holding a step, glowing brighter and brighter
          k = ((t - b[:since]) / GLOW_T).clamp(0.0, 1.0)
          w.src_rect.set(b[:fw], DOWN * b[:fh], b[:fw], b[:fh])
          v = ((200 * k) + (55 * k * (0.5 + (0.5 * Math.sin((t - b[:since]) * (6 + (14 * k))))))).round
          w.tone = Tone.new(v, (v * 0.85).round, v)
          if k >= 1
            b[:state] = :dance
            b[:since] = t
          end
        when :dance
          e = t - b[:since]
          frame = (e / DANCE_T).floor % 4
          d.src_rect.set(frame * b[:dw], 0, b[:dw], b[:dh])
          v = (255 * (1 - (e / FLASH_T))).round.clamp(0, 255)
          d.tone = Tone.new(v, (v * 0.85).round, v)
        when :leave
          b[:x] = b[:outward] == LEFT ? [b[:x] - (SPEED * 1.5 * dt), b[:off]].max : [b[:x] + (SPEED * 1.5 * dt), b[:off]].min
          walk_frame(b, b[:outward], t)
          w.tone = Tone.new(0, 0, 0)
          b[:state] = :off if b[:x] == b[:off]
        end
        w.x = b[:x].round
        w.visible = %i[walk_in glow leave].include?(b[:state])
        d.visible = b[:state] == :dance
      end
    end

    def walk_frame(b, dir, t)
      frame = (t / STEP).floor % 4
      b[:walker].src_rect.set(frame * b[:fw], dir * b[:fh], b[:fw], b[:fh])
    end

    # :off, :walk_in, :glow, :dance, :leave (for the tests)
    def states = @buffs.map { |b| b[:state] }

    def dispose
      @buffs.each { |b| b[:walker].dispose; b[:dancer].dispose }
    end
  end
end
