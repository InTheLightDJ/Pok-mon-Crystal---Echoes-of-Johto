#==============================================================================
# Rhythm Game - choosing a song and a difficulty: pbRhythmGame
# The song list shows each song's best grade (of any difficulty); the
# difficulty list shows the best score at each. After a song it's back to
# the list; Cancel / Back leaves, and the music from before comes back.
#==============================================================================
module RhythmGame
  module_function

  def best_grade(song)
    grades = DIFFICULTIES.filter_map { |d| best(song, d)&.at(1) }
    grades.min_by { |g| GRADES.index { |name, _| name == g } }
  end

  def song_label(song)
    g = best_grade(song)
    g ? "#{song[:title]}  [#{g}]" : song[:title]
  end

  def difficulty_label(song, d)
    b = best(song, d)
    name = _INTL(DIFFICULTY_NAMES[d])
    return name unless b
    _INTL("{1} (best {2}, {3}{4})", name, b[0], b[1], b[2] ? " FC" : "")
  end

  def menu
    song_cmd = 0
    loop do
      fetch_board
      commands = songs.map { |s| song_label(s) } + [_INTL("Scoreboard"), _INTL("Cancel")]
      song_cmd = pbMessage(_INTL("Which song?"), commands, -1, nil, song_cmd)
      if song_cmd == songs.length
        show_board
        next
      end
      break if song_cmd < 0 || song_cmd > songs.length
      song = songs[song_cmd]
      d = pbMessage(_INTL("{1}\nWhich difficulty?", song[:title]),
                    DIFFICULTIES.map { |x| difficulty_label(song, x) } + [_INTL("Cancel")], -1, nil, 1)
      next if d < 0 || d >= DIFFICULTIES.length
      play(song, DIFFICULTIES[d])
    end
  end

  def show_board
    unless online?
      pbMessage(_INTL("Connect to the server to see the scoreboard."))
      return
    end
    unless board
      pbMessage(_INTL("The scoreboard couldn't be loaded. Try again in a moment."))
      return
    end
    pbFadeOutIn { BoardScreen.new.main }
  end

  def play(song, difficulty)
    pbFadeOutIn { Scene.new(song, difficulty).main }
  end
end

def pbRhythmGame
  unless FileTest.exist?(RhythmGame::CHART_FILE)
    pbMessage(_INTL("The music isn't ready yet."))
    return
  end
  $game_system.bgm_memorize
  old_guard = $itl_radio_guard
  $itl_radio_guard = true
  pbBGMFade(0.5)
  $itl_radio_guard = old_guard
  RhythmGame.menu
ensure
  if $game_system
    $itl_radio_guard = true
    $game_system.bgm_restore
    $itl_radio_guard = old_guard
  end
end
