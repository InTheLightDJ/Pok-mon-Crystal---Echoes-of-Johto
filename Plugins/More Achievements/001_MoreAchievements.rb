#===============================================================================
# More achievements (ribbons in the browser chat; the list and ribbons are
# ACHIEVEMENT_DEFS in ServerStuff/chat_server.js)
#
#   18 pinball_100m        100,000,000+ in Pokémon Pinball      (server)
#   19 pinball_1b          1,000,000,000+ in Pokémon Pinball    (server)
#   20 tcg_first_win       first card duel won        (here: duels with the
#                          AI; the server: online duels)
#   21 tcg_beat_e4         beat the card-dueling Elite Four: from the event,
#                          Script: pbGrantAchievement(:tcg_beat_e4)
#   22 holo_black_red      a Black & Red holo (1 in 2,000) from a booster pack
#   23 slots_shadow_lugia  3 Shadow Lugia in a row on the Card Slots
#   24 hunt_complete       online when a Scavenger Hunt is completed (server)
#   25 hunt_boss_catch     caught the hunt's boss (server)
#   26 slots_holiday_card  3 of a holiday card in a row on the Card Slots
#
# pbGrantAchievement sends it quietly (pbGiveAchievement shows DEBUG
# messages); the server ignores ones the player already has. Offline: nothing.
#===============================================================================
ACHIEVEMENT_IDS[18] = 'pinball_100m'
ACHIEVEMENT_IDS[19] = 'pinball_1b'
ACHIEVEMENT_IDS[20] = 'tcg_first_win'
ACHIEVEMENT_IDS[21] = 'tcg_beat_e4'
ACHIEVEMENT_IDS[22] = 'holo_black_red'
ACHIEVEMENT_IDS[23] = 'slots_shadow_lugia'
ACHIEVEMENT_IDS[24] = 'hunt_complete'
ACHIEVEMENT_IDS[25] = 'hunt_boss_catch'
ACHIEVEMENT_IDS[26] = 'slots_holiday_card'

# id: an index of ACHIEVEMENT_IDS or its name (:tcg_beat_e4)
def pbGrantAchievement(id)
  id = ACHIEVEMENT_IDS[id] if id.is_a?(Integer)
  return false unless id && ACHIEVEMENT_IDS.include?(id.to_s)
  return false unless defined?(NetworkAuth) && NetworkAuth.logged_in?
  NetworkClient.send_msg({ action: 'grant_achievement', id: id.to_s })
  true
rescue StandardError
  false
end

# a card duel with the AI won (online duels: the server)
alias __achievements_pbTCGDuel pbTCGDuel unless defined?(__achievements_pbTCGDuel)
def pbTCGDuel(*args, **kwargs)
  won = __achievements_pbTCGDuel(*args, **kwargs)
  pbGrantAchievement(:tcg_first_win) if won
  won
end

module TCG
  class << self
    # a booster pack with a Black & Red holo
    alias achievements_pack_pulled pack_pulled unless method_defined?(:achievements_pack_pulled)
    def pack_pulled(cards)
      pbGrantAchievement(:holo_black_red) if cards.any? { |id| holo_tier(id) == :BLACK_RED }
      achievements_pack_pulled(cards)
    end
  end
end

module CardSlots
  class << self
    # 3 in a row of Shadow Lugia, or of a holiday card
    alias achievements_settle settle unless method_defined?(:achievements_settle)
    def settle(s, kind, card)
      if kind == :three
        pbGrantAchievement(:slots_shadow_lugia) if TCG.base_id(card) == :SHADOW_LUGIA
        pbGrantAchievement(:slots_holiday_card) if event_card?(card)
      end
      achievements_settle(s, kind, card)
    end
  end
end
