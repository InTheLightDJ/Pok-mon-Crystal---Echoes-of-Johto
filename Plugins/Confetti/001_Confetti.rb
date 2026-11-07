#===============================================================================
# Confetti: the celebration played when an event is done.
# A white flash, confetti bursts from both bottom corners, then rains over the
# screen while a banner drops in with twinkling stars and the title screen song
# (Legends Of Johto Intro) plays. C/B ends it (after 2 seconds), or it ends by
# itself; the music then fades back to what was playing.
#   pbConfetti                                  # the scavenger hunt's banner
#   pbConfetti("Event Complete!", "Thanks for playing!")
# The confetti's movement and the banner's timing (Confetti::Sim,
# Confetti.banner_y, ...) use no RGSS classes, so they can be run outside the
# game for previews.
#===============================================================================
module Confetti
  BGM          = "Legends Of Johto Intro"
  COLORS       = [[248, 56, 56], [248, 160, 32], [248, 216, 40], [72, 200, 72],
                  [56, 152, 248], [168, 96, 248], [248, 112, 184]]
  # [width, height] of each shape: paper bits, squares, streamers
  SHAPES       = [[4, 8], [6, 6], [2, 12]]
  BURST_PIECES = 90     # from each bottom corner
  RAIN_START   = 30     # frames before the rain starts
  RAIN_RATE    = 2.2    # new pieces a frame
  GRAVITY      = 0.14
  MIN_FRAMES   = 120    # C/B can't end it before this
  MAX_FRAMES   = 900    # then it ends by itself
  BANNER_IN    = 30     # the banner drops in from this frame...
  BANNER_DROP  = 36     # ...over this many frames
  BANNER_OUT   = 24     # and leaves over this many
  DIM          = 80     # how dark the screen behind gets

  class Piece
    attr_accessor :x, :y, :vx, :vy, :fall, :angle, :spin, :flip, :flip_speed,
                  :sway, :color, :shape, :front   # front: over the banner

    # 1.0 = face on, 0 = edge on, negative = back side showing
    def face; Math.cos(@flip); end
  end

  class Sim
    attr_reader :pieces, :frame

    def initialize(width, height, rng = Random.new)
      @w, @h, @rng = width, height, rng
      @pieces = []
      @frame = 0
      @raining = true
      @rain = 0.0
      BURST_PIECES.times { @pieces << burst_piece(-4, @h + 4, 1) }
      BURST_PIECES.times { @pieces << burst_piece(@w + 4, @h + 4, -1) }
    end

    def stop_rain; @raining = false; end
    def done?;     !@raining && @pieces.empty?; end

    def update
      @frame += 1
      if @raining && @frame >= RAIN_START
        @rain += RAIN_RATE
        while @rain >= 1
          @rain -= 1
          @pieces << rain_piece
        end
      end
      @pieces.each { |p| move(p) }
      @pieces.reject! { |p| p.y > @h + 16 || (p.vy > 0 && (p.x < -24 || p.x > @w + 24)) }
    end

    private

    def rand_in(a, b); a + @rng.rand * (b - a); end

    def new_piece(x, y)
      p = Piece.new
      p.x, p.y = x, y
      p.fall       = rand_in(0.9, 1.7)
      p.angle      = rand_in(0, 360)
      p.spin       = rand_in(-6, 6)
      p.flip       = rand_in(0, Math::PI * 2)
      p.flip_speed = rand_in(0.06, 0.22)
      p.sway       = rand_in(0, Math::PI * 2)
      p.color      = @rng.rand(COLORS.size)
      p.shape      = @rng.rand(SHAPES.size)
      p.front      = @rng.rand < 0.35
      p
    end

    # shot up and inwards from a bottom corner (dir 1 = to the right)
    def burst_piece(x, y, dir)
      p = new_piece(x, y)
      a = rand_in(52, 84) * Math::PI / 180
      speed = rand_in(5.5, 10.5)
      p.vx = Math.cos(a) * speed * dir
      p.vy = -Math.sin(a) * speed
      p
    end

    def rain_piece
      p = new_piece(rand_in(0, @w), rand_in(-24, -8))
      p.vx = rand_in(-0.4, 0.4)
      p.vy = rand_in(0.4, 1.4)
      p
    end

    def move(p)
      p.vx *= 0.96
      p.vy = [p.vy + GRAVITY, p.fall].min
      p.sway += 0.07
      drift = p.vy > 0 ? Math.sin(p.sway) * 0.7 : 0
      p.x += p.vx + drift
      p.y += p.vy
      p.angle = (p.angle + p.spin) % 360
      p.flip += p.flip_speed
    end
  end

  module_function

  # the banner's top y on frame f: drops from above with a little bounce
  def banner_y(f, height, target)
    t = ((f - BANNER_IN).to_f / BANNER_DROP).clamp(0, 1)
    s = 1.70158   # ease out back
    t -= 1
    k = t * t * ((s + 1) * t + s) + 1
    (-height + (target + height) * k).round
  end

  # ...and while leaving (e = frames since it started leaving)
  def banner_leave_y(e, height, target)
    t = (e.to_f / BANNER_OUT).clamp(0, 1)
    (target - (target + height) * t * t).round
  end

  def dim_opacity(f, leaving = nil)
    return (DIM * (1 - leaving.to_f / BANNER_OUT)).clamp(0, DIM).round if leaving
    (DIM * [f / 20.0, 1].min).round
  end

  # stars on the banner's edge: [x, y] as fractions of its size, a pixel
  # offset from there, and when each one twinkles
  STARS = [[0, 0, 4, 2, 0], [1, 0, -4, 4, 17], [1, 1, -22, 0, 34],
           [0, 1, 22, -2, 8], [0.5, 0, 0, -2, 25], [0.35, 1, 0, 2, 42]]

  def star_opacity(f, phase)
    v = Math.sin((f + phase) * Math::PI / 26)
    v > 0 ? (v * 255).round : 0
  end

  #-----------------------------------------------------------------------------
  # Drawing
  #-----------------------------------------------------------------------------
  CREAM = [230, 230, 197]
  RED   = [230, 0, 0]
  DARK  = [40, 40, 40]
  GREY  = [168, 168, 152]

  class Overlay
    BANNER_W = 288

    def initialize(title, subtitle)
      @vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @vp.z = 999_999
      @sim = Sim.new(Graphics.width, Graphics.height)
      @bitmaps = {}
      @sprites = {}
      @dim = Sprite.new(@vp)
      @dim.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @dim.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
      @dim.opacity = 0
      @banner = Sprite.new(@vp)
      @banner.bitmap = banner_bitmap(title, subtitle)
      @banner.x = (Graphics.width - BANNER_W) / 2
      @banner.z = 10
      @target = (Graphics.height - @banner.bitmap.height) / 2 - 24
      @banner.y = Confetti.banner_y(0, @banner.bitmap.height, @target)
      @stars = STARS.map do |fx, fy, dx, dy, phase|
        s = Sprite.new(@vp)
        s.bitmap = star_bitmap
        s.ox = s.oy = 4
        s.z = 11
        [s, fx, fy, dx, dy, phase]
      end
      @leaving = nil
      @vp.flash(Color.new(255, 255, 255, 200), 16)
    end

    def done?; @leaving && @leaving >= BANNER_OUT && @sim.done?; end

    def leave
      return if @leaving
      @leaving = 0
      @sim.stop_rain
    end

    def update
      f = @sim.frame
      @sim.update
      @leaving += 1 if @leaving
      h = @banner.bitmap.height
      @banner.y = @leaving ? Confetti.banner_leave_y(@leaving, h, @target) : Confetti.banner_y(f, h, @target)
      @dim.opacity = Confetti.dim_opacity(f, @leaving)
      @stars.each do |s, fx, fy, dx, dy, phase|
        s.x = @banner.x + (BANNER_W * fx).round + dx
        s.y = @banner.y + (h * fy).round + dy
        s.opacity = @leaving ? 0 : Confetti.star_opacity(f, phase)
      end
      draw_pieces
      @vp.update
    end

    def dispose
      @sprites.each_value(&:dispose)
      @stars.each { |s, *| s.dispose }
      @bitmaps.each_value(&:dispose)
      @dim.bitmap.dispose
      @dim.dispose
      @banner.bitmap.dispose
      @banner.dispose
      @star_bitmap&.dispose
      @vp.dispose
    end

    private

    def draw_pieces
      alive = {}
      @sim.pieces.each do |p|
        alive[p] = true
        s = (@sprites[p] ||= Sprite.new(@vp))
        s.z = p.front ? 20 : 0
        face = p.face
        s.bitmap = piece_bitmap(p.shape, p.color, face < 0)
        s.ox = s.bitmap.width / 2
        s.oy = s.bitmap.height / 2
        s.x, s.y = p.x.round, p.y.round
        s.angle = p.angle
        s.zoom_y = [face.abs, 0.2].max
      end
      @sprites.delete_if { |p, s| alive[p] ? false : (s.dispose; true) }
    end

    # the back of a piece is a darker shade
    def piece_bitmap(shape, color, back)
      @bitmaps[[shape, color, back]] ||= begin
        w, h = SHAPES[shape]
        r, g, b = COLORS[color]
        r, g, b = [r, g, b].map { |c| c * 5 / 8 } if back
        bmp = Bitmap.new(w, h)
        bmp.fill_rect(0, 0, w, h, Color.new(r, g, b))
        bmp
      end
    end

    # a 4-point twinkle, 9x9
    def star_bitmap
      @star_bitmap ||= begin
        bmp = Bitmap.new(9, 9)
        yellow, white = Color.new(248, 232, 96), Color.new(255, 255, 255)
        bmp.fill_rect(4, 0, 1, 9, yellow)
        bmp.fill_rect(0, 4, 9, 1, yellow)
        bmp.fill_rect(3, 3, 3, 3, yellow)
        bmp.fill_rect(4, 2, 1, 5, white)
        bmp.fill_rect(2, 4, 5, 1, white)
        bmp
      end
    end

    # the game's double red box with the title (wrapped) and a subtitle
    def banner_bitmap(title, subtitle)
      tmp = Bitmap.new(1, 1)
      pbSetSystemFont(tmp)
      lines = Confetti.wrap(title, BANNER_W - 32) { |t| tmp.text_size(t).width }
      pbSetNarrowFont(tmp)   # the subtitle's narrower
      sub = Confetti.wrap(subtitle, BANNER_W - 32) { |t| tmp.text_size(t).width }
      tmp.dispose
      h = 24 + lines.size * 32 + (sub.empty? ? 0 : 8 + sub.size * 32)
      bmp = Bitmap.new(BANNER_W, h)
      cream, red = Color.new(*CREAM), Color.new(*RED)
      bmp.fill_rect(0, 0, BANNER_W, h, red)
      bmp.fill_rect(2, 2, BANNER_W - 4, h - 4, cream)
      bmp.fill_rect(6, 6, BANNER_W - 12, h - 12, red)
      bmp.fill_rect(8, 8, BANNER_W - 16, h - 16, cream)
      pbSetSystemFont(bmp)
      y = 12
      pbDrawTextPositions(bmp, lines.map.with_index { |l, i| [l, BANNER_W / 2, y + i * 32, :center, red, Color.new(248, 160, 144)] })
      y += lines.size * 32 + 8
      pbSetNarrowFont(bmp)
      pbDrawTextPositions(bmp, sub.map.with_index { |l, i| [l, BANNER_W / 2, y + i * 32, :center, Color.new(*DARK), Color.new(*GREY)] })
      bmp
    end
  end

  # words into lines no wider than width (the block measures a line)
  def wrap(text, width)
    lines = []
    text.to_s.split(" ").each do |word|
      if lines.empty? || yield("#{lines[-1]} #{word}") > width
        lines << word
      else
        lines[-1] = "#{lines[-1]} #{word}"
      end
    end
    lines
  end

  def network_update
    NetworkClient.update if defined?(NetworkClient) && NetworkClient.respond_to?(:update)
  rescue StandardError
  end

  def play(title, subtitle = nil, bgm: BGM)
    old_bgm = $game_system&.playing_bgm
    pbBGMPlay(bgm) if bgm
    overlay = Overlay.new(title, subtitle)
    run = proc do
      frames = 0
      loop do
        Graphics.update
        Input.update
        network_update
        frames += 1
        overlay.leave if frames >= MAX_FRAMES ||
                         (frames >= MIN_FRAMES && (Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)))
        overlay.update
        break if overlay.done? || frames >= MAX_FRAMES + 300
      end
    end
    defined?(HeldServerMessages) ? HeldServerMessages.during(&run) : run.call
  ensure
    overlay&.dispose
    if bgm
      pbBGMFade(1.0)
      60.times { Graphics.update; Input.update }
      old_bgm ? $game_system.bgm_play(old_bgm) : pbBGMStop
    end
  end
end

# with no text it's the scavenger hunt's banner
def pbConfetti(title = nil, subtitle = nil, bgm: Confetti::BGM)
  title ||= _INTL("Scavenger Hunt Complete!")
  subtitle ||= _INTL("Everyone gets a prize!")
  Confetti.play(title, subtitle, bgm: bgm)
end

MenuHandlers.add(:debug_menu, :confetti, {
  "name"        => _INTL("Confetti"),
  "parent"      => :main,
  "description" => _INTL("Play the event-finished confetti celebration."),
  "always_show" => true,
  "effect"      => proc {
    pbConfetti
  }
})
