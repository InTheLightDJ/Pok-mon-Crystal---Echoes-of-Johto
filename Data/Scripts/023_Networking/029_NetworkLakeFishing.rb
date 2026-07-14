#===============================================================================
# NetworkLakeFishing
#
# Caches the Lake of Rage Fishing Contest leaderboard (top-10 all-time total
# weight in lbs) and shows a congratulations message if the player's latest
# submission qualified. The actual minigame lives in
# 017_Minigames/LakeFishingMinigame.rb — this file is just the network glue,
# mirroring 021_NetworkBugContest.rb's pattern.
#
# Wall poster / NPC script:  pbShowLakeFishingLeaderboard
#===============================================================================

class PokemonGlobalMetadata
  attr_accessor :lake_fishing_board   # Array of { 'name' => str, 'score' => int }
end

EventHandlers.add(:on_new_game, :init_lake_fishing_board, proc {
  $PokemonGlobal.lake_fishing_board = nil
})

EventHandlers.add(:on_load, :migrate_lake_fishing_board, proc {
  $PokemonGlobal.lake_fishing_board ||= nil
})

# ── Server → client ────────────────────────────────────────────────────────────

NetworkClient.on('lake_fishing_board') do |data|
  board = data['board']
  next unless board.is_a?(Array)
  $PokemonGlobal.lake_fishing_board = board
  if data['qualified'] == true
    pbMessage(_INTL("Your haul made it onto the Lake of Rage Hall of Anglers!"))
  end
end

# ── Wall poster / NPC display ──────────────────────────────────────────────────

def pbShowLakeFishingLeaderboard
  if NetworkAuth.logged_in?
    NetworkClient.send_msg({ action: 'lake_fishing_scores_request' })
  end

  board = ($PokemonGlobal.lake_fishing_board || []).first(10)

  if board.empty?
    pbMessage(_INTL("The Lake of Rage Hall of Anglers is empty..."))
    return
  end

  suffixes = ["st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th"]

  top5_lines = board[0..4].each_with_index.map do |entry, i|
    name  = (entry['name']  || '???').to_s.ljust(12)
    score = (entry['score'] || 0).to_s.rjust(4)
    "#{(i + 1).to_s}#{suffixes[i]}: #{name} #{score} lbs"
  end

  bot5_lines = board[5..9]&.each_with_index&.map do |entry, i|
    name  = (entry['name']  || '???').to_s.ljust(12)
    score = (entry['score'] || 0).to_s.rjust(4)
    "#{(i + 6).to_s}th: #{name} #{score} lbs"
  end

  pbMessage(_INTL("Lake of Rage Hall of Anglers\n") + top5_lines.join("\n"))
  pbMessage(bot5_lines.join("\n")) if bot5_lines && !bot5_lines.empty?
end
