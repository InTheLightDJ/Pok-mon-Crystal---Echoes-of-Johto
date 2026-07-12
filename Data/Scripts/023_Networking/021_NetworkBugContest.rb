#===============================================================================
# NetworkBugContest
#
# Submits the player's 1st-place Bug Contest score to the server leaderboard,
# caches the top-10 board received from the server, and provides
# pbShowBugContestLeaderboard for use by an in-game event (e.g. a wall poster).
#
# Wall poster event script:  pbShowBugContestLeaderboard
#===============================================================================

# Persist the board across saves
class PokemonGlobalMetadata
  attr_accessor :bug_contest_board  # Array of { 'name' => str, 'score' => int }
end

EventHandlers.add(:on_new_game, :init_bug_contest_board, proc {
  $PokemonGlobal.bug_contest_board = nil
})

EventHandlers.add(:on_load, :migrate_bug_contest_board, proc {
  $PokemonGlobal.bug_contest_board ||= nil
})

# ── Server → client ────────────────────────────────────────────────────────────

NetworkClient.on('bug_contest_board') do |data|
  board = data['board']
  next unless board.is_a?(Array)
  $PokemonGlobal.bug_contest_board = board
  # If this was a qualifying score, congratulate the player
  if data['qualified'] == true
    pbMessage(_INTL("Your score made it onto the Bug Contest Hall of Fame!"))
  end
end

# ── On login, request the current leaderboard ──────────────────────────────────

NetworkClient.on('auth_ok') do |_data|
  NetworkClient.send_msg({ action: 'bug_contest_scores_request' })
end

# ── Submit score after a 1st-place finish ─────────────────────────────────────

class BugContestState
  alias __network_pbEnd pbEnd unless method_defined?(:__network_pbEnd)

  def pbEnd(interrupted = false)
    # Capture result before the state is cleared
    won_first = !interrupted && @places.any? && place == 0
    score     = won_first ? @places[0][2] : nil
    __network_pbEnd(interrupted)
    if won_first && score && NetworkAuth.logged_in?
      NetworkClient.send_msg({
        action:       'bug_contest_score',
        score:        score,
        display_name: $player.name
      })
    end
  end
end

# ── Wall poster display ────────────────────────────────────────────────────────

def pbShowBugContestLeaderboard
  # Refresh the board from server if online
  if NetworkAuth.logged_in?
    NetworkClient.send_msg({ action: 'bug_contest_scores_request' })
  end

  board = ($PokemonGlobal.bug_contest_board || []).first(10)

  if board.empty?
    pbMessage(_INTL("The Bug Contest scoreboard is empty..."))
    return
  end

  suffixes = ["st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th"]

  top5_lines = board[0..4].each_with_index.map do |entry, i|
    name  = (entry['name']  || '???').to_s.ljust(12)
    score = (entry['score'] || 0).to_s.rjust(4)
    "#{(i + 1).to_s}#{suffixes[i]}: #{name} #{score} pts"
  end

  bot5_lines = board[5..9]&.each_with_index&.map do |entry, i|
    name  = (entry['name']  || '???').to_s.ljust(12)
    score = (entry['score'] || 0).to_s.rjust(4)
    "#{(i + 6).to_s}th: #{name} #{score} pts"
  end

  pbMessage(_INTL("Bug Contest Hall of Fame\n") + top5_lines.join("\n"))
  pbMessage(bot5_lines.join("\n")) if bot5_lines && !bot5_lines.empty?
end
