#==============================================================================
# Hall of Records - the all-time best of the minigames, from the server
# (ServerStuff handlers/records.js): each Pokémon Pinball table, Tower Defense's
# highest round, the Rhythm Game's best score with its song, and the most
# players ever online at once (with its date in place of a name), the best
# Bug Catching Contest score and Lake of Rage Fishing catch. They never
# reset, unlike the season / weekly / monthly boards. ROWS_PER_PAGE to a
# page; Left / Right turn the pages.
#
# From an event: Script command `pbHallOfRecords`. Online only.
#==============================================================================
module HallOfRecords
  WAIT_FRAMES = 120
  # server key => title
  TITLES = {
    "gbc_red"     => "Pokémon Pinball - Red Field",
    "gbc_blue"    => "Pokémon Pinball - Blue Field",
    "rs_ruby"     => "Pinball R&S - Ruby Field",
    "rs_sapphire" => "Pinball R&S - Sapphire Field",
    "td"          => "Tower Defense",
    "rhythm"      => "Rhythm Game",
    "online"      => "Most Players Online",
    "bug"         => "Bug Catching Contest",
    "fishing"     => "Lake of Rage Fishing Contest",
    "lazor"       => "Lazor Ball"
  }
  ROWS_PER_PAGE = 6
  ROUND_KEYS = ["td"]   # the score is a round reached, not points
  DATE_KEYS  = ["online"]   # the name is a date (YYYY-MM-DD) and the score a number of players
  WEIGHT_KEYS = ["fishing"] # the score is a total weight (lbs.)
  WHITE  = Color.new(248, 248, 248)
  GREY   = Color.new(180, 180, 200)
  GOLD   = Color.new(240, 205, 60)
  SHADOW = Color.new(40, 40, 48)

  @records = nil

  module_function

  def online?
    defined?(NetworkAuth) && NetworkAuth.logged_in?
  rescue StandardError
    false
  end

  def receive(d) = @records = d["records"] || {}

  # asks the server, waits a moment; nil if no answer
  def fetch
    @records = nil
    NetworkClient.send_msg({ action: "records_board" })
    WAIT_FRAMES.times do
      Graphics.update
      Input.update
      NetworkClient.update
      break if @records
    end
    @records
  rescue StandardError
    nil
  end

  # a Rhythm Game song's title (the server sends its file name)
  def song_title(file)
    song = defined?(RhythmGame) && RhythmGame.songs.find { |s| s[:file] == file } rescue nil
    song ? song[:title] : file.to_s
  end

  # "2026-11-15" -> "Nov. 15, 2026" (the game's month names)
  def date_text(date)
    y, m, d = date.to_s.split("-").map(&:to_i)
    return date.to_s unless y && m && d && m.between?(1, 12)
    _INTL("{1} {2}, {3}", pbGetAbbrevMonthName(m), d, y)
  end

  def show(records)
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 200_000
    sprite = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    page = 0
    draw(sprite.bitmap, records, page)
    loop do
      Graphics.update
      Input.update
      break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
      turn = Input.repeat?(Input::RIGHT) ? 1 : Input.repeat?(Input::LEFT) ? -1 : 0
      next if turn == 0 || pages <= 1
      page = (page + turn) % pages
      pbPlayCursorSE
      draw(sprite.bitmap, records, page)
    end
    pbPlayDecisionSE
  ensure
    sprite&.dispose
    viewport&.dispose
  end

  def pages = (TITLES.size + ROWS_PER_PAGE - 1) / ROWS_PER_PAGE

  def draw(b, records, page = 0)
    w = Graphics.width
    b.fill_rect(0, 0, w, Graphics.height, Color.new(18, 14, 28))
    b.fill_rect(0, 0, w, 30, Color.new(60, 44, 20))
    b.fill_rect(0, 30, w, 2, GOLD)
    pbSetSystemFont(b)
    pbDrawTextPositions(b, [[_INTL("Hall of Records"), w / 2, 4, :center, GOLD, SHADOW]])
    pbSetSmallFont(b)
    texts = []
    texts << [_INTL("< {1}/{2} >", page + 1, pages), w - 10, 8, :right, WHITE, SHADOW] if pages > 1
    row_h = 42
    TITLES.keys[page * ROWS_PER_PAGE, ROWS_PER_PAGE].each_with_index do |key, i|
      y = 38 + (i * row_h)
      y2 = y + 19   # the second line
      b.fill_rect(4, y, w - 8, row_h - 4, i.even? ? Color.new(40, 34, 58) : Color.new(32, 28, 48))
      texts << [_INTL(TITLES[key]), 10, y + 2, :left, GREY, SHADOW]
      r = records[key]
      unless r
        texts << [_INTL("No record yet"), 22, y2, :left, GREY, SHADOW]
        next
      end
      score = if ROUND_KEYS.include?(key) then _INTL("Round {1}", r["score"])
              elsif DATE_KEYS.include?(key) then _INTL("{1} players", r["score"])
              elsif WEIGHT_KEYS.include?(key) then _INTL("{1} lbs.", r["score"].to_i.to_s_formatted)
              else r["score"].to_i.to_s_formatted
              end
      name = DATE_KEYS.include?(key) ? date_text(r["name"]) : r["name"].to_s
      texts << [name, 22, y2, :left, GOLD, SHADOW]
      texts << [score, w - 10, y2, :right, WHITE, SHADOW]
      texts << [song_title(r["song"]), w - 10, y + 2, :right, WHITE, SHADOW] if r["song"]
    end
    pbDrawTextPositions(b, texts)
  end
end

NetworkClient.on("records_board") { |d| HallOfRecords.receive(d) } if defined?(NetworkClient)

def pbHallOfRecords
  unless HallOfRecords.online?
    pbMessage(_INTL("Connect to the server to see the Hall of Records."))
    return
  end
  records = HallOfRecords.fetch
  unless records
    pbMessage(_INTL("The Hall of Records couldn't be loaded. Try again in a moment."))
    return
  end
  pbFadeOutIn { HallOfRecords.show(records) }
end
