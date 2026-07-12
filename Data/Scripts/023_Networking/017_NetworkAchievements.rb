#===============================================================================
# Network achievements — grant ribbons earned through in-game milestones.
#
# Call pbGiveAchievement(n) from any event script or method.
# The server deduplicates: granting an already-owned achievement is a no-op.
# The player's browser chat receives a toast notification when first granted.
#
# Index list (must stay in sync with ACHIEVEMENT_DEFS in chat_server.js):
#   1 — "e4_10"         — Defeated the Elite Four 10 times
#   2 — "plip_catch"    — Caught a Pokémon with a Plip Ball
#   3 — "reds_mom"      — Defeated Red's mother on Mt. Silver
#   4 — "beat_red"      — Defeated Red on Mt. Silver
#   5 — "eggs_100"      — Hatched 100 Eggs
#   6 — "triad_shiny"   — Won a shiny card in a Triple Triad battle
#   7 — "beat_giovanni" — Fought and defeated Team Rocket's boss, Giovanni
#   8 — "join_rocket"   — Joined Team Rocket
#   9 — "found_pokeflute" — Found the Poké Flute
#  10 — "dex_seen_kanto"      — Seen every Pokémon in the Kanto Pokédex
#  11 — "dex_caught_kanto"    — Caught every Pokémon in the Kanto Pokédex
#  12 — "dex_seen_johto"      — Seen every Pokémon in the Johto Pokédex
#  13 — "dex_caught_johto"    — Caught every Pokémon in the Johto Pokédex
#  14 — "dex_seen_national"   — Seen every Pokémon in the National Pokédex
#  15 — "dex_caught_national" — Caught every Pokémon in the National Pokédex
#  16 — "box_master_100"      — Expanded Pokémon storage to 100 boxes
#  17 — "slots_green777"      — Hit three Green 7s on the Slot Machine
#   (met_admin, boss_slayer, boss_catcher, mythical_finder, bug_contest_top10
#    are auto-granted server-side)
#===============================================================================

ACHIEVEMENT_IDS = [
  nil,                    # 0 — unused
  'e4_10',                # 1
  'plip_catch',           # 2
  'reds_mom',             # 3
  'beat_red',             # 4
  'eggs_100',             # 5
  'triad_shiny',          # 6
  'beat_giovanni',        # 7
  'join_rocket',          # 8
  'found_pokeflute',      # 9
  'dex_seen_kanto',       # 10
  'dex_caught_kanto',     # 11
  'dex_seen_johto',       # 12
  'dex_caught_johto',     # 13
  'dex_seen_national',    # 14
  'dex_caught_national',  # 15
  'box_master_100',       # 16
  'slots_green777',       # 17
]

def pbGiveAchievement(index)
  unless NetworkAuth.logged_in?
    pbMessage("DEBUG: Not logged in (connected=#{NetworkClient.connected?})")
    return
  end
  id = ACHIEVEMENT_IDS[index]
  unless id
    pbMessage("DEBUG: No achievement ID for index #{index}")
    return
  end
  pbMessage("DEBUG: Sending achievement '#{id}'")
  NetworkClient.send_msg({ action: 'grant_achievement', id: id })
end

class PokemonGlobalMetadata
  attr_accessor :granted_achievements
end

# Like pbGiveAchievement, but remembers locally (per save) which indices have
# already been sent so repeatedly-true conditions (e.g. a completed Pokédex)
# don't resend the grant message and DEBUG popup on every subsequent call.
def pbGiveAchievementOnce(index)
  return unless NetworkAuth.logged_in?
  $PokemonGlobal.granted_achievements ||= []
  return if $PokemonGlobal.granted_achievements.include?(index)
  $PokemonGlobal.granted_achievements.push(index)
  pbGiveAchievement(index)
end

# Checks Kanto/Johto/National Pokédex seen & caught completion and grants the
# matching achievement (once) if met. Called on login and after catching a
# new species.
def pbCheckDexCompletionAchievements
  return unless NetworkAuth.logged_in?
  dex = $player.pokedex
  pbGiveAchievementOnce(10) if dex.seen_count(0)   >= pbGetRegionalDexLength(0)
  pbGiveAchievementOnce(11) if dex.owned_count(0)  >= pbGetRegionalDexLength(0)
  pbGiveAchievementOnce(12) if dex.seen_count(1)   >= pbGetRegionalDexLength(1)
  pbGiveAchievementOnce(13) if dex.owned_count(1)  >= pbGetRegionalDexLength(1)
  pbGiveAchievementOnce(14) if dex.seen_count(-1)  >= pbGetRegionalDexLength(-1)
  pbGiveAchievementOnce(15) if dex.owned_count(-1) >= pbGetRegionalDexLength(-1)
end
