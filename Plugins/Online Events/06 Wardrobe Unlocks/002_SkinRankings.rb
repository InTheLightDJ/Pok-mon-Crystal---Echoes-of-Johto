#===============================================================================
# World Rankings: +1 point per player character (wardrobe skin) owned. The
# count is sent to the server as { action: 'skin_sync', skins: n, total: m }
# (ServerStuff: handlers/leaderboard.js, db/database.js SCORE_EXPR):
#   - with every dex_sync (login and catches), as the TCG card count is
#   - when a character is unlocked while logged in (once that frame, however
#     many were unlocked)
# Owning every one: the server tells everyone online (skins_complete) and each
# game shows the confetti once the player is free on the map.
#===============================================================================
module SkinRankings
  @confetti = []   # names of players who just got every skin
  @dirty = false   # a character was unlocked: sync on the next frame

  class << self
    attr_reader :confetti
    attr_accessor :dirty

    def owned
      ids = GameData::PlayerMetadata.keys
      PlayerUnlocks.unlocked.count { |id| ids.include?(id) }
    end

    def total; GameData::PlayerMetadata.count; end

    def message; { action: "skin_sync", skins: owned, total: total }; end

    def sync
      return unless defined?(NetworkClient) && NetworkClient.connected? && $PokemonGlobal
      NetworkClient.send_msg(message)
    rescue StandardError
      nil
    end
  end
end

module PlayerUnlocks
  class << self
    alias skin_rankings_unlock unlock unless method_defined?(:skin_rankings_unlock)
    def unlock(id)
      new_one = !unlocked?(id)
      r = skin_rankings_unlock(id)
      SkinRankings.dirty = true if new_one
      r
    end
  end
end

# piggyback on dex_sync (login + catches) so skins unlocked offline count too
module NetworkClient
  class << self
    alias skin_rankings_send_msg send_msg unless method_defined?(:skin_rankings_send_msg)
    def send_msg(hash)
      r = skin_rankings_send_msg(hash)
      if hash.is_a?(Hash) && (hash[:action] || hash["action"]).to_s == "dex_sync" && $PokemonGlobal
        skin_rankings_send_msg(SkinRankings.message) rescue nil
      end
      r
    end
  end
end

NetworkClient.on("skins_complete") { |d| SkinRankings.confetti << d["username"].to_s }

EventHandlers.add(:on_frame_update, :skin_rankings,
  proc {
    if SkinRankings.dirty
      SkinRankings.dirty = false
      SkinRankings.sync
    end
    next if SkinRankings.confetti.empty? || !HeldServerMessages.overworld_free?
    name = SkinRankings.confetti.shift
    if name.casecmp?(NetworkAuth.username.to_s)
      pbConfetti(_INTL("Wardrobe Complete!"), _INTL("You have every outfit!"))
    else
      pbConfetti(_INTL("Wardrobe Complete!"), _INTL("{1} has every outfit!", name))
    end
  }
)
