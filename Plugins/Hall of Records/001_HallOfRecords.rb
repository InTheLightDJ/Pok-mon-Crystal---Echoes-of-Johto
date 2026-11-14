#==============================================================================
# Hall of Records - the all-time best of the minigames, from the server
# (ServerStuff handlers/records.js): each Pokémon Pinball table, Tower Defense's
# highest round and the Rhythm Game's best score with its song. They never
# reset, unlike the season / weekly boards.
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
    "rhythm"      => "Rhythm Game"
  }
  ROUND_KEYS = ["td"]   # the score is a round reached, not points
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

  def show(records)
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 200_000
    sprite = BitmapSprite.new(Graphics.width, Graphics.height, viewport)
    draw(sprite.bitmap, records)
    loop do
      Graphics.update
      Input.update
      break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
    end
    pbPlayDecisionSE
  ensure
    sprite&.dispose
    viewport&.dispose
  end

  def draw(b, records)
    w = Graphics.width
    b.fill_rect(0, 0, w, Graphics.height, Color.new(18, 14, 28))
    b.fill_rect(0, 0, w, 30, Color.new(60, 44, 20))
    b.fill_rect(0, 30, w, 2, GOLD)
    pbSetSystemFont(b)
    pbDrawTextPositions(b, [[_INTL("Hall of Records"), w / 2, 4, :center, GOLD, SHADOW]])
    pbSetSmallFont(b)
    texts = []
    row_h = 42
    TITLES.keys.each_with_index do |key, i|
      y = 38 + (i * row_h)
      b.fill_rect(4, y, w - 8, row_h - 4, i.even? ? Color.new(40, 34, 58) : Color.new(32, 28, 48))
      texts << [_INTL(TITLES[key]), 10, y + 2, :left, GREY, SHADOW]
      r = records[key]
      unless r
        texts << [_INTL("No record yet"), 22, y + 19, :left, GREY, SHADOW]
        next
      end
      score = ROUND_KEYS.include?(key) ? _INTL("Round {1}", r["score"]) : r["score"].to_i.to_s_formatted
      texts << [r["name"].to_s, 22, y + 19, :left, GOLD, SHADOW]
      texts << [score, w - 10, y + 19, :right, WHITE, SHADOW]
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
