#==============================================================================
# Rhythm Game - play along with the InTheLight radio songs, the end
# credits song and the Pokérap: notes slide down a 4-lane track; hit each lane's key as a
# note crosses the line.
#
# From an event: Script command `pbRhythmGame`.
#
#   Lanes   Left / A    Down / S    Up / W    Right / D   (the arrow keys and
#           the WASD keys are read as keys, whatever F1 binds them to)
#   Back    pause (Continue / Quit)
#   A key pressed with no note to hit loses WRONG_PENALTY points and the
#   combo, so mashing every key doesn't pay.
#
# The notes come from Data/Rhythm_Charts.rxdata, made from the songs by
# Rhythm-mod/tools/make_charts.py (beat tracking + onset detection) and
# package_charts.rb. Behind the track one of the Ruins of Alph tile puzzle
# pictures (Graphics/UI/Tile Puzzle) keeps mixing itself up on the beat.
# Best scores are saved with the game ($PokemonGlobal.rhythm_scores).
#==============================================================================
module RhythmGame
  CHART_FILE  = "Data/Rhythm_Charts.rxdata"
  DIFFICULTIES = [:easy, :normal, :hard]
  DIFFICULTY_NAMES = { easy: "Easy", normal: "Normal", hard: "Hard" }
  # pixels a second the notes fall at
  SCROLL_SPEED = { easy: 170, normal: 210, hard: 260 }
  # timing windows (seconds either side of the note) and points
  JUDGEMENTS = [[:perfect, 0.045, 100], [:good, 0.09, 70], [:ok, 0.135, 40]]
  JUDGEMENT_NAMES = { perfect: "PERFECT", good: "GOOD", ok: "OK", miss: "MISS", wrong: "WRONG" }
  # a key pressed with no note there to hit: points lost (and the combo)
  WRONG_PENALTY = 50
  # combo needed for each multiplier step (x2 at 10, x3 at 20, x4 at 30, x5 at 40)
  COMBO_STEP  = 10
  MAX_MULTIPLIER = 5
  # the sounds when the fire lights: x4 (red), x5 (blue), in Audio/SE
  FIRE_SE = { 1 => "Rhythm fire", 2 => "Rhythm blue fire" }
  # sound output lag: notes are judged this much later than the clock
  AUDIO_OFFSET = 0.06
  LEAD_IN = 1.5          # seconds before the music starts
  # accuracy (points / best possible) for each grade
  GRADES = [["S", 0.95], ["A", 0.88], ["B", 0.75], ["C", 0.6], ["D", 0.0]]

  module_function

  def songs
    @songs ||= Marshal.load(Zlib::Inflate.inflate(load_data(CHART_FILE)))
  end

  def grade_for(accuracy)
    GRADES.find { |_, min| accuracy >= min }[0]
  end

  # { "file:difficulty" => [score, grade, full_combo] }
  def scores
    $PokemonGlobal.rhythm_scores ||= {}
  end

  def best(song, difficulty)
    scores["#{song[:file]}:#{difficulty}"]
  end

  # true if it's a new best
  def record(song, difficulty, score, grade, full_combo)
    key = "#{song[:file]}:#{difficulty}"
    old = scores[key]
    return false if score <= 0 || (old && old[0] >= score)
    scores[key] = [score, grade, full_combo]
    true
  end
end

class PokemonGlobalMetadata
  attr_accessor :rhythm_scores
end
