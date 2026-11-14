#==============================================================================
# Rhythm Game - the server's weekly scoreboard (ServerStuff handlers/rhythm.js)
# Online, a finished song's score is sent in; the server keeps each player's
# best this week on each song (any difficulty), and when the week ends the
# #1 of each song gets a Server Token. The song list's "Scoreboard" shows
# every song's top scores; while playing, a box under the score shows the
# song's #1 this week.
#==============================================================================
module RhythmGame
  BOARD_WAIT = 90   # frames to wait for the server's boards
  DIFFICULTY_LETTERS = { "easy" => "E", "normal" => "N", "hard" => "H" }

  @board = nil      # { song file => [[name, score, difficulty]...] }
  @board_dirty = true

  class << self
    attr_reader :board, :week_ends, :prize

    def online?
      defined?(NetworkAuth) && NetworkAuth.logged_in?
    rescue StandardError
      false
    end

    def receive_board(d)
      @board = d["songs"] || {}
      @week_ends = d["week_ends"].to_i
      @prize = d["prize"].to_i
      @board_dirty = false
    end

    # asks the server for the boards (when they may have changed) and waits a
    # moment for them
    def fetch_board
      return unless online? && @board_dirty
      @board_dirty = :waiting
      NetworkClient.send_msg({ action: "rhythm_board" })
      BOARD_WAIT.times do
        Graphics.update
        Input.update
        NetworkClient.update
        break unless @board_dirty
      end
      @board_dirty = true if @board_dirty
    rescue StandardError
      nil
    end

    # this week's #1 on the song: [name, score, difficulty] or nil
    def top(song)
      @board && @board[song[:file]]&.first
    end

    def report(song, difficulty, score)
      return unless online? && score > 0
      NetworkClient.send_msg({ action: "rhythm_result", song: song[:file], difficulty: difficulty.to_s, score: score })
      @board_dirty = true
    rescue StandardError
      nil
    end

    def days_left
      return 0 unless @week_ends
      [((@week_ends - Time.now.to_i) / 86_400.0).ceil, 0].max
    end
  end

  #----------------------------------------------------------------------------
  # Every song's top scores this week, 8 songs a page (Left / Right)
  #----------------------------------------------------------------------------
  class BoardScreen
    PER_PAGE = 8
    ROW_H    = 30
    WHITE  = Color.new(248, 248, 248)
    GREY   = Color.new(190, 190, 205)
    GOLD   = Color.new(240, 205, 60)
    SHADOW = Color.new(40, 40, 48)

    def main
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 200_000
      @sprite = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSmallFont(@sprite.bitmap)
      @pages = (RhythmGame.songs.length + PER_PAGE - 1) / PER_PAGE
      @page = 0
      draw
      loop do
        Graphics.update
        Input.update
        break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
        step = Input.trigger?(Input::RIGHT) ? 1 : Input.trigger?(Input::LEFT) ? -1 : 0
        next if step == 0
        @page = (@page + step) % @pages
        pbPlayCursorSE
        draw
      end
    ensure
      @sprite&.dispose
      @viewport&.dispose
    end

    def draw
      b = @sprite.bitmap
      w = Graphics.width
      b.fill_rect(0, 0, w, Graphics.height, Color.new(16, 16, 32))
      texts = [
        [_INTL("This week's top scores"), 8, 4, :left, GOLD, SHADOW],
        [_INTL("{1}/{2}", @page + 1, @pages), w - 8, 4, :right, GREY, SHADOW],
        [_INTL("#1 on each song wins {1} token(s)", RhythmGame.prize || 1), 8, 20, :left, GREY, SHADOW],
        [_INTL("Ends in {1} day(s)", RhythmGame.days_left), w - 8, 20, :right, GREY, SHADOW]
      ]
      RhythmGame.songs[@page * PER_PAGE, PER_PAGE].each_with_index do |song, i|
        y = 42 + (i * ROW_H)
        b.fill_rect(4, y - 1, w - 8, ROW_H - 2, i.even? ? Color.new(36, 36, 60) : Color.new(28, 28, 48))
        texts << [song[:title], 8, y, :left, WHITE, SHADOW]
        top = RhythmGame.board && RhythmGame.board[song[:file]]
        if top && !top.empty?
          name, score, diff = top[0]
          texts << [fit(b, name.to_s, 150), 20, y + 13, :left, GOLD, SHADOW]
          texts << ["#{score} #{DIFFICULTY_LETTERS[diff]}", w - 10, y + 13, :right, WHITE, SHADOW]
        else
          texts << [_INTL("No scores yet"), 20, y + 13, :left, GREY, SHADOW]
        end
      end
      pbDrawTextPositions(b, texts)
    end

    def fit(bitmap, text, width)
      text = text[0...-1] while text.length > 1 && bitmap.text_size(text).width > width
      text
    end
  end
end

NetworkClient.on("rhythm_board") { |d| RhythmGame.receive_board(d) } if defined?(NetworkClient)
