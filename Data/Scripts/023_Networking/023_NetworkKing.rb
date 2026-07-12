#===============================================================================
# NetworkKing — "King of the Hill" server minigame.
#
# A fixed NPC (built in RPG Maker by the map designer) starts out holding the
# title. The NPC's event should look roughly like this:
#
#   ◆Script: next false unless NetworkKing.npc_challengeable?
#   ◆Trainer Battle: [whatever trainer the designer wants]
#     : Win
#       ◆Script: NetworkKing.claim_from_npc
#     : Lose
#       (nothing required)
#
# Once a player takes the crown from the NPC, they become the reigning king.
# From then on, ANY player who challenges them through the normal online
# Battle menu (NetworkBattle.request_battle) is automatically fighting for the
# title — the server marks that battle "forced" and the king cannot decline
# (see 004_NetworkBattle.rb's handling of the `forced` flag). Win streak
# milestones (10 / 25 / 50 / 100 wins) are delivered automatically by the
# server via the `king_prize` event.
#
# If the king logs out, the server reverts the title to the NPC (retaining
# their name + streak in case they log back in before anyone else claims it) —
# no client-side action needed for that part.
#===============================================================================

module NetworkKing
  @holder   = 'npc'   # 'npc' | 'player'
  @username = nil
  @wins     = 0

  def self.holder;   @holder;   end
  def self.username; @username; end
  def self.wins;     @wins;     end

  # true while a player (not the NPC) currently holds the title.
  def self.player_king?
    @holder == 'player' && !@username.nil?
  end

  # Fetches the latest status from the server and updates the cache.
  # Returns the raw hash: { 'holder' => .., 'username' => .., 'wins' => .. }
  def self.request_status
    result = nil
    cb = NetworkClient.on('king_status') { |d| result = d }
    NetworkClient.send_msg({ action: 'king_status' })
    200.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.remove('king_status', cb)
    _apply(result) if result
    result
  end

  #-----------------------------------------------------------------------------
  # Condition-check script for the NPC event — call this in a conditional
  # branch (or "next false unless ...") before the Trainer Battle command.
  # Returns false (and shows a message) if a player currently holds the title.
  #-----------------------------------------------------------------------------
  def self.npc_challengeable?
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to challenge the King of the Hill."))
      return false
    end

    status = request_status || { 'holder' => @holder, 'username' => @username }
    if status['holder'] == 'player' && status['username']
      pbMessage(_INTL("The throne is currently held by {1}! Defeat them to take the crown.", status['username']))
      return false
    end
    true
  end

  #-----------------------------------------------------------------------------
  # Win-branch script for the NPC's Trainer Battle event.
  #-----------------------------------------------------------------------------
  def self.claim_from_npc
    result = nil
    cb = NetworkClient.on('king_claim_result') { |d| result = d }
    NetworkClient.send_msg({ action: 'king_claim_npc' })
    200.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.remove('king_claim_result', cb)

    if result && result['success']
      pbMessage(_INTL("You have claimed the King of the Hill title!\nDefend it well — you cannot refuse a challenge."))
    elsif result
      pbMessage(_INTL(result['message'] || "Could not claim the title. Try again."))
    end
  end

  def self._apply(data)
    @holder   = data['holder']   || 'npc'
    @username = data['username']
    @wins     = (data['wins'] || 0).to_i
  end
end

#===============================================================================
# Server event handlers
#===============================================================================

# Pushed on login, on any title change, and in reply to an explicit king_status request.
NetworkClient.on('king_status') { |d| NetworkKing._apply(d) }

# King-of-the-Hill milestone prize (10/25/50/100 wins) — delivered directly
# since the king is always online when a defense resolves.
NetworkClient.on('king_prize') do |d|
  next unless d['kind'] == 'item'
  sym = d['item_id'].to_s.upcase.to_sym rescue nil
  next unless sym && GameData::Item.exists?(sym)
  qty = (d['qty'] || 1).to_i
  # pbReceiveItem already announces the item (or a bag-full message) itself.
  pbReceiveItem(sym, qty) rescue nil
end
