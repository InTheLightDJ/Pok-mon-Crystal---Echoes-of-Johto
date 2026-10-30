#==============================================================================
# Pokemon TCG - World Rankings: +1 point per different card ever owned.
# Works like the Pokedex "seen" count: every card id the player has owned is
# remembered in the save (even if it later leaves the collection), and the
# count is sent to the server as { action: 'card_sync', cards: n }:
#   - with every dex_sync (that's sent on login and when catching), so cards
#     found while offline count the next time the player logs in
#   - right away when a new card is added while logged in
# The server keeps it in players.tcg_cards and adds it to the score
# (ServerStuff: handlers/leaderboard.js, db/database.js SCORE_EXPR).
# Rare holo pulls add points too: a booster pack opened (any pack, from a
# reward, the Card Shop, a Destiny pack...) whose holo is one of
# HOLO_PULL_POINTS adds that many points, kept in the save. Buying or
# trading for a holo card doesn't count.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_cards_seen
  def tcg_cards_seen; @tcg_cards_seen ||= {}; end   # card id => true
  attr_writer :tcg_pull_points
  def tcg_pull_points; @tcg_pull_points || 0; end   # rare holo pulls
end

module TCG
  # every card id ever owned (old saves: filled from the collection)
  def self.cards_seen
    return {} unless global
    seen = global.tcg_cards_seen
    collection.each { |id, n| seen[base_id(id)] = true if n.to_i > 0 && !seen[base_id(id)] }
    seen
  end

  def self.cards_seen_count; cards_seen.size; end

  # holo tier pulled from a booster pack => World Rankings points
  HOLO_PULL_POINTS = { :GREY_WHITE => 1, :BLACK_YELLOW => 2, :BLACK_PURPLE => 3, :BLACK_RED => 5 }

  def self.pull_points; global ? global.tcg_pull_points : (@test_pull_points ||= 0); end

  # what goes to the server: different cards owned + rare pull points
  def self.ranking_score; cards_seen_count + pull_points; end

  # a booster pack's cards, just opened: points for its rare holos;
  # returns the points added
  def self.pack_pulled(cards)
    pts = cards.sum { |id| HOLO_PULL_POINTS[holo_tier(id)].to_i }
    return 0 if pts == 0
    global ? global.tcg_pull_points += pts : @test_pull_points = pull_points + pts
    sync_ranking_cards
    pts
  end

  def self.sync_ranking_cards
    return unless defined?(NetworkClient) && NetworkClient.connected?
    NetworkClient.send_msg({ action: 'card_sync', cards: ranking_score })
  rescue StandardError
    nil
  end

  class << self
    alias ranking_add_card add_card unless method_defined?(:ranking_add_card)
    def add_card(id, n = 1)
      new_card = global && !cards_seen[base_id(id)]
      r = ranking_add_card(id, n)
      if new_card
        global.tcg_cards_seen[base_id(id)] = true
        sync_ranking_cards
      end
      r
    end
  end
end

# piggyback on dex_sync (login + catches) so the server always gets the
# latest count, including cards found offline
if defined?(NetworkClient)
  module NetworkClient
    class << self
      alias tcg_ranking_send_msg send_msg unless method_defined?(:tcg_ranking_send_msg)
      def send_msg(hash)
        r = tcg_ranking_send_msg(hash)
        if hash.is_a?(Hash) && (hash[:action] || hash["action"]).to_s == "dex_sync"
          tcg_ranking_send_msg({ action: "card_sync", cards: TCG.ranking_score }) rescue nil
        end
        r
      end
    end
  end
end

module TCG
  # "A rare pull!" after a pack with a rare holo (points from pack_pulled)
  def self.pull_message(pts)
    pbMessage(_INTL("A rare pull! +{1} World Rankings points!", pts)) if pts.to_i > 0
  end
end
