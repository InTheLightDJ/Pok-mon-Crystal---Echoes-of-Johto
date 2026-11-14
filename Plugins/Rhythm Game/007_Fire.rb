#==============================================================================
# Rhythm Game - the fire: while the multiplier is high, flames lick up both
# sides of the track, a glow rises from the hit line, and the track (with its
# notes) trembles by a pixel. It fades in and out.
#   x4: red fire, the half tremble (a new one half as often, on one axis)
#   x5: blue fire, the full tremble (both axes, every SHAKE_T)
# The flames are drawn once (FRAMES pictures that loop, the tongues rising).
#==============================================================================
module RhythmGame
  class TrackFire
    FLAME_W  = 20      # how far the flames reach out from the track's sides
    INSIDE   = 3       # and in over its edge
    FRAMES   = 8
    FRAME_T  = 0.06    # seconds a flame picture
    GLOW_H   = 70      # the glow over the track, up from the hit line
    FADE     = 4.0     # level a second
    SHAKE_T  = 0.05    # a new tremble this often (seconds)
    # inside out; the glow's color at its bottom and its top
    STYLES = {
      red:  { colors: [[255, 250, 210], [255, 215, 70], [255, 130, 25], [215, 45, 15]],
              glow: [[255, 220, 40], [255, 140, 40]], shake: :half },
      blue: { colors: [[235, 250, 255], [130, 215, 255], [50, 130, 255], [30, 50, 210]],
              glow: [[120, 210, 255], [40, 110, 255]], shake: :full }
    }

    attr_reader :level

    def initialize(viewport, track_x, track_w, hit_y, z, style = :red)
      @style = STYLES[style]
      @level = 0.0
      @last = nil
      @shake = [0, 0]
      @shake_at = 0
      h = viewport.rect.height rescue Graphics.height
      @frames = { left: Array.new(FRAMES) { |k| flame_bitmap(h, k, true) },
                  right: Array.new(FRAMES) { |k| flame_bitmap(h, k, false) } }
      @left = Sprite.new(viewport)
      @left.x = track_x - FLAME_W
      @right = Sprite.new(viewport)
      @right.x = track_x + track_w - INSIDE
      @glow = Sprite.new(viewport)
      @glow.bitmap = glow_bitmap(track_w)
      @glow.x = track_x
      @glow.y = hit_y + 16 - GLOW_H
      @base = { @left => [@left.x, 0], @right => [@right.x, 0], @glow => [@glow.x, @glow.y] }
      [@left, @right, @glow].each { |s| s.z = z; s.opacity = 0; s.visible = false }
      @left.bitmap = @frames[:left][0]
      @right.bitmap = @frames[:right][0]
    end

    # flames for one side: spiky tongues from the track's edge outwards,
    # rising, a hot core along the edge (INSIDE px of it over the track) and
    # a few embers
    def flame_bitmap(h, k, left)
      w = FLAME_W + INSIDE
      bmp = Bitmap.new(w, h)
      edge = ->(x, width) { left ? w - x - width : x }   # x counted out from the track
      (0...h).step(2) do |y|
        a = (Math.sin(2 * Math::PI * ((y / 36.0) + (k.to_f / FRAMES))) + 1) / 2
        b = (Math.sin(2 * Math::PI * ((y / 92.0) + (2.0 * k / FRAMES))) + 1) / 2
        reach = (FLAME_W * (0.25 + (0.75 * (a**2.2) * (0.55 + (0.45 * b))))).round.clamp(3, FLAME_W)
        # outer (red) first, the inner (yellow, white) ones over them
        colors = @style[:colors]
        (colors.length - 1).downto(0) do |layer|
          lw = INSIDE + (reach * (layer + 1) / colors.length.to_f).round
          r, g, bl = colors[layer]
          bmp.fill_rect(edge.call(0, lw), y, lw, 2, Color.new(r, g, bl, 255 - (layer * 25)))
        end
      end
      # embers: rising sparks, the same ones a frame later a little higher
      rng = Random.new(left ? 7 : 11)
      (h / 24).times do
        x = INSIDE + rng.rand(FLAME_W - 2)
        y = (rng.rand(h) - (k * h / (FRAMES * 6))) % h
        r, g, bl = @style[:colors][rng.rand(2)]
        bmp.fill_rect(edge.call(x, 2), y, 2, 2, Color.new(r, g, bl))
      end
      bmp
    end

    def glow_bitmap(w)
      bmp = Bitmap.new(w, GLOW_H)
      bottom, top = @style[:glow]
      GLOW_H.times do |y|
        c = (0..2).map { |i| top[i] + ((bottom[i] - top[i]) * y / GLOW_H) }
        bmp.fill_rect(0, y, w, 1, Color.new(*c, (y * 90 / GLOW_H)))
      end
      bmp
    end

    # the tremble for this frame: [dx, dy] (0 when the fire is out)
    def shake = @shake

    def update(on, t)
      dt = @last ? (t - @last).clamp(0, 0.1) : 0
      @last = t
      @level = (@level + ((on ? FADE : -FADE) * dt)).clamp(0.0, 1.0)
      visible = @level > 0
      k = (t / FRAME_T).floor % FRAMES
      @left.bitmap = @frames[:left][k]
      @right.bitmap = @frames[:right][(k + 3) % FRAMES]
      flicker = 0.85 + (0.15 * Math.sin(t * 23)) + (rand * 0.05)
      [@left, @right].each { |s| s.visible = visible; s.opacity = (230 * @level * flicker).round.clamp(0, 255) }
      @glow.visible = visible
      @glow.opacity = (255 * @level * (0.8 + (0.2 * Math.sin(t * 11)))).round.clamp(0, 255)
      if @level >= 0.5
        if t >= @shake_at
          if @style[:shake] == :full
            @shake = [rand(-1..1), rand(-1..1)]
            @shake_at = t + SHAKE_T
          else   # half: one axis at a time, half as often
            @shake = rand(2) == 0 ? [rand(-1..1), 0] : [0, rand(-1..1)]
            @shake_at = t + (SHAKE_T * 2)
          end
        end
      else
        @shake = [0, 0]
      end
      @base.each { |s, (x, y)| s.x = x + @shake[0]; s.y = y + @shake[1] }
    end

    def dispose
      glow = @glow.bitmap
      [@left, @right, @glow].each(&:dispose)
      glow&.dispose
      @frames.each_value { |list| list.each(&:dispose) }
    end
  end
end
