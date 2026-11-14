#==============================================================================
# Rhythm Game - playing a song: one track of 4 lanes in front of the puzzle
# background, notes falling to the line near the bottom.
# The clock is System.uptime from when the music was started (the music and
# the clock both run in real time, so they stay together); AUDIO_OFFSET
# covers the sound output's lag.
#==============================================================================
module RhythmGame
  class Scene
    LANES      = 4
    LANE_W     = 34
    TRACK_W    = LANE_W * LANES
    NOTE       = 30
    # lane => [arrow angle, color, raw keys]
    LANE_INFO  = [
      [90,  Color.new(80, 200, 90),  [:LEFT, :A]],
      [180, Color.new(225, 75, 75),  [:DOWN, :S]],
      [0,   Color.new(240, 205, 60), [:UP, :W]],
      [270, Color.new(75, 140, 235), [:RIGHT, :D]]
    ]
    LANE_INPUT = [Input::LEFT, Input::DOWN, Input::UP, Input::RIGHT]
    WHITE  = Color.new(248, 248, 248)
    GREY   = Color.new(200, 200, 215)
    SHADOW = Color.new(40, 40, 48)
    JUDGE_COLORS = { perfect: Color.new(120, 230, 255), good: Color.new(130, 235, 120),
                     ok: Color.new(240, 215, 90), miss: Color.new(235, 90, 90),
                     wrong: Color.new(235, 120, 200) }

    def initialize(song, difficulty)
      @song = song
      @difficulty = difficulty
      @speed = SCROLL_SPEED[difficulty]
      @travel = (hit_y + NOTE) / @speed.to_f
      @notes = []
      song[:charts][difficulty].each do |t, *lanes|
        lanes.each { |l| @notes << { t: t, lane: l } }
      end
      @beats = song[:charts][:easy].map(&:first)   # the background moves on these
      @next_note = 0
      @next_beat = 0
      @live = []
      @score = 0
      @combo = 0
      @max_combo = 0
      @counts = Hash.new(0)
      @points = 0
      @end_time = [song[:duration], (@notes.map { |n| n[:t] }.max || 0) + 2].min
      @top = RhythmGame.top(song)   # this week's #1 on the server (005_Online.rb)
    end

    def multiplier = [1 + (@combo / COMBO_STEP), MAX_MULTIPLIER].min

    # the screen's size is only set after the plugins are loaded
    def track_x = (Graphics.width - TRACK_W) / 2
    def hit_y = Graphics.height - 44     # the line notes are hit on

    #--------------------------------------------------------------------------
    # returns the result (see #finish), or nil if the player quit
    def main
      start
      run
    ensure
      dispose
    end

    def start
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 200_000  # over pbFadeOutIn's black (99_999) and the menus it may be opened from
      @background = PuzzleBackground.new(@viewport)
      @track = Sprite.new(@viewport)
      @track.bitmap = track_bitmap
      @track.x = track_x
      @track.z = 10
      # the dancers (006_Dancers.rb): over the track, under the notes; a row
      # at x4, a second one below it at x5
      lane_xs = Array.new(LANES) { |l| lane_x(l) }
      @dancers = [Dancers.new(@viewport, lane_xs, 15, 0), Dancers.new(@viewport, lane_xs, 16, 1)]
      # the fire (007_Fire.rb): beside and over the track, under the dancers;
      # red at x4, blue at x5
      @fire = TrackFire.new(@viewport, track_x, TRACK_W, hit_y, 13, :red)
      @blue_fire = TrackFire.new(@viewport, track_x, TRACK_W, hit_y, 13, :blue)
      @fire_tier = 0
      # the perfect half (008_Perfect.rb): a purple wave (behind the track,
      # its first sweep over it) and an Igglybuff each side of the track
      @wave = PurpleWave.new(@viewport, 5, 14)
      side = (Graphics.width - TRACK_W) / 4
      @igglybuffs = Igglybuffs.new(@viewport, [side, Graphics.width - side], hit_y - 18, 15)
      @perfect_half = false
      @arrows = LANE_INFO.map { |_, color, _| arrow_bitmap(color) }
      @receptor_bmp = arrow_bitmap(Color.new(70, 70, 82), Color.new(170, 170, 185))
      @receptors = Array.new(LANES) do |l|
        s = arrow_sprite(@receptor_bmp, l)
        s.y = hit_y
        s.z = 11
        s
      end
      @flashes = Array.new(LANES) do |l|
        s = arrow_sprite(@arrows[l], l)
        s.y = hit_y
        s.z = 12
        s.opacity = 0
        s
      end
      @judge = BitmapSprite.new(TRACK_W, 48, @viewport)
      @judge.x = track_x
      @judge.y = hit_y - 120
      @judge.z = 30
      pbSetSystemFont(@judge.bitmap)
      @hud = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @hud.z = 40
      pbSetSmallFont(@hud.bitmap)
      @flash_until = Array.new(LANES, 0)
      @shake = [0, 0]
      @judge_at = nil
      @hud_key = nil
      @base = System.uptime + LEAD_IN    # the clock reads 0 when the music starts
      @music = false
      draw_hud(true)
    end

    def track_bitmap
      bmp = Bitmap.new(TRACK_W, Graphics.height)
      bmp.fill_rect(0, 0, TRACK_W, Graphics.height, Color.new(10, 10, 20, 170))
      (1...LANES).each { |l| bmp.fill_rect(l * LANE_W, 0, 1, Graphics.height, Color.new(120, 120, 140, 120)) }
      bmp.fill_rect(0, 0, 2, Graphics.height, Color.new(200, 200, 220, 200))
      bmp.fill_rect(TRACK_W - 2, 0, 2, Graphics.height, Color.new(200, 200, 220, 200))
      bmp.fill_rect(0, hit_y - 1, TRACK_W, 3, Color.new(255, 255, 255, 90))
      bmp
    end

    # an arrow pointing up, NOTE x NOTE, with a dark (or given) outline
    def arrow_bitmap(color, outline = nil)
      outline ||= Color.new(color.red / 3, color.green / 3, color.blue / 3)
      bmp = Bitmap.new(NOTE, NOTE)
      draw_arrow(bmp, outline, 0)
      draw_arrow(bmp, color, 2)
      bmp
    end

    def draw_arrow(bmp, color, inset)
      mid = NOTE / 2
      head = 15
      (1 + inset...NOTE - 1 - inset).each do |y|
        half = y < head ? ((y - 1) * 13 / (head - 1)) + 1 - inset : 6 - inset
        next if half <= 0
        bmp.fill_rect(mid - half, y, half * 2, 1, color)
      end
    end

    def arrow_sprite(bmp, lane)
      s = Sprite.new(@viewport)
      s.bitmap = bmp
      s.ox = s.oy = NOTE / 2
      s.angle = LANE_INFO[lane][0]
      s.x = track_x + (lane * LANE_W) + (LANE_W / 2)
      s
    end

    #--------------------------------------------------------------------------
    def clock = System.uptime - @base

    # where the song is, as heard
    def song_time = clock - AUDIO_OFFSET

    def run
      loop do
        Graphics.update
        Input.update
        return nil if Input.trigger?(Input::BACK) && !pause
        start_music if !@music && clock >= 0
        now = song_time
        beats(now)
        spawn(now)
        LANES.times { |l| hit(l, now) if pressed?(l) }
        misses(now)
        fire_tier = [multiplier - 3, 0].max   # 1 at x4, 2 at x5
        light_fire(fire_tier)
        @fire.update(fire_tier == 1, System.uptime)
        @blue_fire.update(fire_tier >= 2, System.uptime)
        tremble(*(@blue_fire.shake == [0, 0] ? @fire.shake : @blue_fire.shake))
        draw_notes(now)
        @dancers.each_with_index { |d, row| d.update(fire_tier > row, System.uptime) }
        perfect = perfect_half?
        @wave.update(perfect, System.uptime)
        @igglybuffs.update(perfect, System.uptime)
        update_effects
        @background.update(System.uptime)
        draw_hud
        return finish if now >= @end_time
      end
    end

    def start_music(pos = 0)
      @music = true
      with_guard do
        $game_system.bgm_play_internal2("Audio/BGM/" + @song[:file], 100, 100, pos)
      end
    end

    # the InTheLight radio blocks other music while it's on
    def with_guard
      old = $itl_radio_guard
      $itl_radio_guard = true
      yield
    ensure
      $itl_radio_guard = old
    end

    def pressed?(lane)
      return true if Input.trigger?(LANE_INPUT[lane])
      LANE_INFO[lane][2].any? { |k| Input.triggerex?(k) }
    rescue StandardError
      false
    end

    # Back: the music stops; Continue picks up a second earlier
    def pause
      at = clock
      with_guard { Audio.bgm_stop }
      # the message box is under the screen: hidden while it's up
      @viewport.visible = false
      cmd = pbMessage(_INTL("Paused."), [_INTL("Continue"), _INTL("Quit")], 1)
      @viewport.visible = true
      return false if cmd == 1
      if at > 0
        pos = [at - 1.0, 0].max
        start_music(pos)
        @base = System.uptime - pos
      else
        @base = System.uptime - at
      end
      true
    end

    # the background moves on the beat
    def beats(now)
      while @next_beat < @beats.length && @beats[@next_beat] <= now
        @background.beat(System.uptime)
        @dancers.each(&:beat)
        @next_beat += 1
        @background.change_picture(System.uptime) if @next_beat == @beats.length / 2
      end
    end

    def spawn(now)
      while @next_note < @notes.length && @notes[@next_note][:t] - now <= @travel
        n = @notes[@next_note]
        n[:sprite] = arrow_sprite(@arrows[n[:lane]], n[:lane])
        n[:sprite].z = 20
        @live << n
        @next_note += 1
      end
    end

    def draw_notes(now)
      dx, dy = @shake
      @live.each do |n|
        n[:sprite].x = lane_x(n[:lane]) + dx
        n[:sprite].y = hit_y - ((n[:t] - now) * @speed).round + dy
      end
    end

    def lane_x(lane) = track_x + (lane * LANE_W) + (LANE_W / 2)

    # half the notes played and none missed (nor a wrong press) yet; once it
    # has come, it lasts until the first miss
    def perfect_half?
      clean = @counts[:miss] == 0 && @counts[:wrong] == 0
      played = @counts[:perfect] + @counts[:good] + @counts[:ok]
      @perfect_half ||= clean && !@notes.empty? && played * 2 >= @notes.length
      @perfect_half && clean
    end

    # the fire's sound when it lights (or turns blue)
    def light_fire(tier)
      return if tier == @fire_tier
      if tier > @fire_tier && FIRE_SE[tier]
        begin
          pbSEPlay(FIRE_SE[tier])
        rescue StandardError
          nil
        end
      end
      @fire_tier = tier
    end

    # the fire's tremble: the track, its arrows and notes move by [dx, dy] pixels
    def tremble(dx, dy)
      return if @shake == [dx, dy]
      @shake = [dx, dy]
      @track.x = track_x + dx
      @track.y = dy
      LANES.times do |l|
        [@receptors[l], @flashes[l]].each { |s| s.x = lane_x(l) + dx; s.y = hit_y + dy }
      end
    end

    # the closest note in the lane, if it's close enough
    def hit(lane, now)
      @receptors[lane].zoom_x = @receptors[lane].zoom_y = 0.85
      n = @live.select { |x| x[:lane] == lane }.min_by { |x| (x[:t] - now).abs }
      kind, _, pts = JUDGEMENTS.find { |_, window, _| (n[:t] - now).abs <= window } if n
      return wrong_press unless kind
      @combo += 1
      @max_combo = [@max_combo, @combo].max
      @score += pts * multiplier
      @points += pts
      judge(kind)
      @flash_until[lane] = System.uptime + 0.12
      remove(n)
    end

    def wrong_press
      @combo = 0
      @score = [@score - WRONG_PENALTY, 0].max
      @points = [@points - WRONG_PENALTY, 0].max
      judge(:wrong)
    end

    def misses(now)
      @live.select { |n| now - n[:t] > JUDGEMENTS.last[1] }.each do |n|
        @combo = 0
        judge(:miss)
        remove(n)
      end
    end

    def remove(n)
      n[:sprite].dispose
      @live.delete(n)
    end

    def judge(kind)
      @counts[kind] += 1
      @judge_at = System.uptime
      b = @judge.bitmap
      b.clear
      texts = [[_INTL(JUDGEMENT_NAMES[kind]), TRACK_W / 2, 2, :center, JUDGE_COLORS[kind], SHADOW, :outline]]
      texts << [@combo.to_s, TRACK_W / 2, 24, :center, WHITE, SHADOW, :outline] if @combo >= 5
      pbDrawTextPositions(b, texts)
    end

    def update_effects
      t = System.uptime
      LANES.times do |l|
        r = @receptors[l]
        r.zoom_x = r.zoom_y = [r.zoom_x + 0.02, 1.0].min
        @flashes[l].opacity = t < @flash_until[l] ? 255 : [@flashes[l].opacity - 40, 0].max
      end
      @judge.opacity = @judge_at ? lerp(255, 0, 0.35, @judge_at + 0.25, t) : 0
      @judge.y = hit_y - 120 - (@judge_at ? lerp(0, 6, 0.6, @judge_at, t) : 0)
    end

    def draw_hud(force = false)
      progress = @end_time > 0 ? (song_time / @end_time).clamp(0, 1) : 0
      key = [@score, @combo, multiplier, (progress * 60).to_i]
      return if !force && key == @hud_key
      @hud_key = key
      b = @hud.bitmap
      b.clear
      left = 6
      right = track_x + TRACK_W + 6
      w = Graphics.width - right - 6
      b.fill_rect(0, 0, track_x - 2, 84, Color.new(0, 0, 0, 120))
      b.fill_rect(right - 4, 0, Graphics.width - right + 4, 104, Color.new(0, 0, 0, 120))
      texts = [
        [_INTL("SCORE"), left, 6, :left, GREY, SHADOW],
        [@score.to_s, left, 22, :left, WHITE, SHADOW],
        [_INTL("COMBO"), left, 44, :left, GREY, SHADOW],
        [@combo.to_s, left, 60, :left, WHITE, SHADOW],
        [_INTL("x{1}", multiplier), track_x - 8, 60, :right, LANE_INFO[2][1], SHADOW],
        [_INTL(DIFFICULTY_NAMES[@difficulty]), right, 6, :left, GREY, SHADOW]
      ]
      pbDrawTextPositions(b, texts)
      b.fill_rect(right, 30, w, 8, Color.new(40, 40, 50))
      b.fill_rect(right + 1, 31, ((w - 2) * progress).to_i, 6, LANE_INFO[3][1])
      # the title, as many lines as it takes
      drawTextEx(b, right, 44, w, 3, @song[:title], WHITE, SHADOW, 18)
      draw_top(b, left) if @top
    end

    # this week's #1 on the server, under the score
    def draw_top(b, left)
      name, score, _ = @top
      width = track_x - 2
      b.fill_rect(0, 90, width, 64, Color.new(0, 0, 0, 120))
      gold = LANE_INFO[2][1]
      pbDrawTextPositions(b, [
        [_INTL("#1 THIS WEEK"), left, 94, :left, GREY, SHADOW],
        [fit(b, name.to_s, width - left - 4), left, 112, :left, gold, SHADOW],
        [score.to_s, left, 130, :left, @score > score.to_i ? gold : WHITE, SHADOW]
      ])
    end

    def fit(bitmap, text, width)
      text = text[0...-1] while text.length > 1 && bitmap.text_size(text).width > width
      text
    end

    #--------------------------------------------------------------------------
    def finish
      with_guard { pbBGMFade(1.0) }
      total = @notes.length
      accuracy = total > 0 ? @points / (total * JUDGEMENTS[0][2].to_f) : 0
      grade = RhythmGame.grade_for(accuracy)
      full_combo = total > 0 && @counts[:miss] == 0 && @counts[:wrong] == 0
      new_best = RhythmGame.record(@song, @difficulty, @score, grade, full_combo)
      server_top = RhythmGame.online? && @score > 0 && (!@top || @score > @top[1].to_i)
      RhythmGame.report(@song, @difficulty, @score)
      result = { score: @score, grade: grade, accuracy: accuracy, counts: @counts.dup,
                 max_combo: @max_combo, full_combo: full_combo, new_best: new_best, notes: total,
                 server_top: server_top }
      show_results(result)
      result
    end

    def show_results(r)
      @live.each { |n| n[:sprite].dispose }
      @live.clear
      @judge.opacity = 0
      panel = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      panel.z = 50
      b = panel.bitmap
      pbSetSystemFont(b)
      b.fill_rect(24, 24, Graphics.width - 48, Graphics.height - 48, Color.new(10, 10, 24, 220))
      cx = Graphics.width / 2
      texts = [
        [@song[:title], cx, 34, :center, WHITE, SHADOW],
        [_INTL(DIFFICULTY_NAMES[@difficulty]), cx, 58, :center, GREY, SHADOW],
        [r[:grade], cx, 86, :center, LANE_INFO[2][1], SHADOW, :outline],
        [_INTL("Score: {1}", r[:score]), 44, 120, :left, WHITE, SHADOW],
        [_INTL("Max combo: {1}", r[:max_combo]), 44, 144, :left, WHITE, SHADOW]
      ]
      %i[perfect good ok miss wrong].each_with_index do |k, i|
        x = 44 + ((i % 2) * 124)
        y = 172 + ((i / 2) * 24)
        texts << [_INTL(JUDGEMENT_NAMES[k]), x, y, :left, JUDGE_COLORS[k], SHADOW]
        texts << [r[:counts][k].to_s, x + 108, y, :right, WHITE, SHADOW]
      end
      extra = []
      extra << _INTL("Full Combo!") if r[:full_combo]
      extra << _INTL("New best!") if r[:new_best]
      extra << _INTL("#1 this week!") if r[:server_top]
      texts << [extra.join("  "), cx, 246, :center, JUDGE_COLORS[:perfect], SHADOW] unless extra.empty?
      pbDrawTextPositions(b, texts)
      loop do
        Graphics.update
        Input.update
        @background.update(System.uptime)
        break if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
      end
      pbPlayDecisionSE
      panel.dispose
    end

    def dispose
      @live&.each { |n| n[:sprite]&.dispose }
      @background&.dispose
      @dancers&.each(&:dispose)
      @fire&.dispose
      @blue_fire&.dispose
      @wave&.dispose
      @igglybuffs&.dispose
      [@track, @judge, @hud, *@receptors, *@flashes].each { |s| s&.dispose }
      @track&.bitmap&.dispose
      @arrows&.each(&:dispose)
      @receptor_bmp&.dispose
      @viewport&.dispose
      with_guard { Audio.bgm_stop } if @music
    end
  end
end
