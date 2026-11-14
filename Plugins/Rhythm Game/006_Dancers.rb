#==============================================================================
# Rhythm Game - the dancers: a row of four Pokemon (their follower sprites)
# that walk in over the top of the track while the multiplier is high enough,
# one over each lane (the first two from the left, the others from the
# right), and dance there: the walk animation, turning now and then on the
# beat. When the multiplier drops they walk back off the way they came (and
# turn around again if it comes back first).
#   x4: Jigglypuff, Chansey, Clefairy, Mew (ROWS[0], along the top)
#   x5: Celebi, Grovyle, Bellsprout, Flygon (ROWS[1], just below them)
#==============================================================================
module RhythmGame
  class Dancers
    ROWS = [
      { species: ["JIGGLYPUFF", "CHANSEY", "CLEFAIRY", "MEW"], top: 2 },
      { species: ["CELEBI", "GROVYLE", "BELLSPROUT", "FLYGON"], top: 34 }
    ]
    FOLDER  = "Graphics/Characters/Followers/"
    SPEED   = 160.0    # walking, pixels a second
    STEP    = 0.14     # seconds a walk frame
    TURN_CHANCE = 0.3  # each beat, each dancer turns this often
    DOWN, LEFT, RIGHT, UP = 0, 1, 2, 3   # rows of a character sheet

    # lane_xs: the middle of each lane, on the screen; row: an index of ROWS
    def initialize(viewport, lane_xs, z, row = 0)
      @last = nil
      @on = false
      top = ROWS[row][:top]
      @dancers = ROWS[row][:species].each_with_index.filter_map do |species, i|
        bmp = (RPG::Cache.load_bitmap(FOLDER, species) rescue nil)
        next unless bmp
        fw = bmp.width / 4
        fh = bmp.height / 4
        s = Sprite.new(viewport)
        s.bitmap = bmp
        s.ox = fw / 2
        s.y = top
        s.z = z
        s.visible = false
        off = i < 2 ? -fw : Graphics.width + fw
        { sprite: s, fw: fw, fh: fh, home: lane_xs[i], off: off, x: off.to_f, dir: DOWN, phase: (i * 0.37) + (row * 0.2) }
      end
    end

    # on: walk in (true) or off (false)
    def update(on, t)
      dt = @last ? (t - @last).clamp(0, 0.1) : 0
      @last = t
      @on = on
      @dancers.each do |d|
        s = d[:sprite]
        target = on ? d[:home] : d[:off]
        if d[:x] != target
          d[:dir] = target > d[:x] ? RIGHT : LEFT
          step = SPEED * dt
          d[:x] = target > d[:x] ? [d[:x] + step, target].min : [d[:x] - step, target].max
          d[:dir] = DOWN if d[:x] == target && on   # arrived: face the player
        end
        s.visible = on || d[:x] != d[:off]
        frame = ((t / STEP) + d[:phase]).floor % 4
        s.src_rect.set(frame * d[:fw], d[:dir] * d[:fh], d[:fw], d[:fh])
        s.x = d[:x].round
      end
    end

    # on the beat, the ones dancing at home may turn
    def beat
      return unless @on
      @dancers.each do |d|
        next unless d[:x] == d[:home] && rand < TURN_CHANCE
        d[:dir] = ([DOWN, LEFT, RIGHT, UP] - [d[:dir]]).sample
      end
    end

    def dispose
      @dancers.each { |d| d[:sprite].dispose }
    end
  end
end
