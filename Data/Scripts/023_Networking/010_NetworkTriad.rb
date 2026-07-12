#===============================================================================
# NetworkTriad — PvP Pokémon Triad duels over TCP.
#
# REQUESTER (you initiate):
#   NetworkTriad.request_duel
#     1. Pick opponent from online list
#     2. Pick 5 cards from your collection
#     3. Send triad_request {target_username, deck}
#     4. Wait for triad_start — then run the networked duel
#
# ACCEPTER (passive — no action needed beyond overworld):
#   triad_request arrives → "X wants to duel!" dialog
#   Accept → pick 5 cards → send triad_accept {triad_id, deck}
#   Wait for triad_start → run the networked duel
#
# PROTOCOL (client → server):
#   triad_request  { target_username, deck:[species_str,...] }
#   triad_accept   { triad_id, deck:[species_str,...] }
#   triad_decline  { triad_id }
#   triad_move     { triad_id, card_index, x, y }
#   triad_result   { triad_id, won:true/false/nil, prize_card:str_or_nil }
#
# PROTOCOL (server → client):
#   triad_pending    { triad_id }
#   triad_request    { from, triad_id }
#   triad_start      { triad_id, opp_name, my_deck, opp_deck, i_go_first }
#   triad_move_relay { card_index, x, y }
#   triad_prize_take { card }
#   triad_declined   { from }
#   triad_ended      { reason }
#   triad_error      { message }
#===============================================================================

module NetworkTriad
  @triad_id        = nil
  @pending_request = nil   # incoming challenge queued for safe-frame display
  @pending_move    = nil   # relayed opponent move
  @move_ready      = false
  @pending_prize   = nil   # opponent's chosen prize card (symbol)
  @prize_ready     = false

  def self.active?
    !@triad_id.nil?
  end

  #-----------------------------------------------------------------------------
  # Called every frame — shows incoming duel dialogs when the overworld is idle.
  #-----------------------------------------------------------------------------
  def self.process_pending
    return unless @pending_request && !@triad_id
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?
    req = @pending_request
    @pending_request = nil
    _handle_incoming(req)
  end

  #-----------------------------------------------------------------------------
  # Requester: pick opponent → pick cards → send challenge → wait → play
  #-----------------------------------------------------------------------------
  def self.request_duel
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to duel."))
      return
    end
    unless pbCanTriadDuel?
      pbMessage(_INTL("You don't have enough cards to duel."))
      return
    end

    # Step 1 — pick opponent
    players = _fetch_online_players
    if players.empty?
      pbMessage(_INTL("No other players are online right now."))
      return
    end
    target = _select_player(players, "Who do you want to duel?")
    return unless target

    # Step 2 — pick 5 cards
    deck = _pick_deck
    return unless deck

    # Step 3 — send challenge
    NetworkClient.send_msg({ action: 'triad_request', target_username: target, deck: deck.map(&:to_s) })

    pending_result = nil
    NetworkClient.on('triad_pending') { |d| @triad_id = d['triad_id']; pending_result = :ok }
    NetworkClient.on('triad_error')   { |d| pending_result = d['message'] }
    200.times do
      Graphics.update; Input.update; NetworkClient.update
      break if pending_result
    end
    NetworkClient.off('triad_pending')
    NetworkClient.off('triad_error')

    unless pending_result == :ok
      pbMessage(_INTL(pending_result.is_a?(String) ? pending_result : "No response from server."))
      _reset
      return
    end

    # Step 4 — wait for opponent to accept or decline (B to cancel)
    start_data    = nil
    cancel_reason = nil
    NetworkClient.on('triad_start')    { |d| start_data = d }
    NetworkClient.on('triad_declined') { |d| cancel_reason = "#{d['from']} declined the duel." }
    NetworkClient.on('triad_ended')    { |d| cancel_reason = d['reason'] }

    timed_out = true
    1800.times do
      Graphics.update; Input.update; NetworkClient.update
      if start_data || cancel_reason
        timed_out = false
        break
      end
      if Input.trigger?(Input::BACK)
        NetworkClient.send_msg({ action: 'triad_decline', triad_id: @triad_id })
        cancel_reason = 'You cancelled'
        timed_out = false
        break
      end
    end
    NetworkClient.off('triad_start')
    NetworkClient.off('triad_declined')
    NetworkClient.off('triad_ended')

    unless start_data
      msg = timed_out ? "#{target} did not respond." : (cancel_reason || 'Cancelled.')
      pbMessage(_INTL(msg))
      _reset
      return
    end

    _run_duel(start_data)
  end

  # ============================================================================
  # Internals
  # ============================================================================

  def self._fetch_online_players
    players = nil
    done    = false
    NetworkClient.on('players_list') { |d| players = d['players']; done = true }
    NetworkClient.send_msg({ action: 'players_list' })
    200.times do
      Graphics.update; Input.update; NetworkClient.update
      break if done
    end
    NetworkClient.off('players_list')
    players || []
  end

  def self._select_player(players, prompt)
    cmds   = players + [_INTL("Cancel")]
    choice = pbMessage(_INTL(prompt), cmds, cmds.length - 1)
    return nil if choice < 0 || choice == players.length
    players[choice]
  end

  def self._pick_deck
    # Build a local copy of the player's card collection for the picker UI.
    triad_cards = []
    $PokemonGlobal.triads.length.times do |i|
      item = $PokemonGlobal.triads[i]
      ItemStorageHelper.add(triad_cards, $PokemonGlobal.triads.maxSize,
                            TriadStorage::MAX_PER_SLOT, item[0], item[1])
    end

    # Spin up a minimal TriadScreen/TriadScene just for the card selection UI.
    scene  = TriadScene.new
    screen = TriadScreen.new(scene)
    screen.instance_variable_set(:@playerName,   $player ? $player.name : "Trainer")
    screen.instance_variable_set(:@opponentName, "Network Duel")
    screen.instance_variable_set(:@board, Array.new(9) { TriadSquare.new })

    deck = nil
    pbFadeOutInWithMusic do
      scene.pbStartScene(screen)
      if triad_cards.inject(0) { |s, i| s + i[1] } < screen.maxCards
        scene.pbDisplayPaused(_INTL("You don't have enough cards ({1} needed).", screen.maxCards))
      else
        deck = scene.pbChooseTriadCard(triad_cards)
      end
      scene.pbEndScene
    end
    deck
  end

  def self._run_duel(data)
    @triad_id    = data['triad_id']
    opp_name     = data['opp_name'].to_s
    my_deck      = data['my_deck'].map  { |s| s.to_sym }
    opp_deck     = data['opp_deck'].map { |s| s.to_sym }
    i_go_first   = data['i_go_first']

    pbFadeOutInWithMusic do
      scene  = TriadScene.new
      screen = TriadScreen.new(scene)
      screen.pbStartPvP(opp_name, my_deck, opp_deck, i_go_first, @triad_id)
    end

    Game.save(safe: true)
    _reset
  end

  def self._handle_incoming(req)
    return unless pbCanTriadDuel?
    from     = req['from'].to_s
    triad_id = req['triad_id'].to_s

    response = pbMessage(
      _INTL("{1} wants to duel at Pokémon Triad! Accept?", from),
      [_INTL("Accept"), _INTL("Decline")], 1
    )

    if response != 0
      NetworkClient.send_msg({ action: 'triad_decline', triad_id: triad_id })
      return
    end

    deck = _pick_deck
    if deck.nil?
      NetworkClient.send_msg({ action: 'triad_decline', triad_id: triad_id })
      return
    end

    NetworkClient.send_msg({ action: 'triad_accept', triad_id: triad_id, deck: deck.map(&:to_s) })

    # Wait for triad_start
    start_data    = nil
    cancel_reason = nil
    NetworkClient.on('triad_start')  { |d| start_data = d }
    NetworkClient.on('triad_ended')  { |d| cancel_reason = d['reason'] }
    600.times do
      Graphics.update; Input.update; NetworkClient.update
      break if start_data || cancel_reason
    end
    NetworkClient.off('triad_start')
    NetworkClient.off('triad_ended')

    if start_data
      _run_duel(start_data)
    else
      pbMessage(_INTL(cancel_reason || "No response from server."))
      _reset
    end
  end

  def self._reset
    @triad_id = nil
  end

  # Blocking wait for the next relayed opponent move — pumps the game loop.
  def self.wait_for_move(timeout_frames = 3600)
    @pending_move = nil
    @move_ready   = false
    timeout_frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return @pending_move if @move_ready
    end
    nil
  end

  # Blocking wait for the opponent's prize card choice after they win.
  def self.wait_for_prize(timeout_frames = 3600)
    @pending_prize = nil
    @prize_ready   = false
    timeout_frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return @pending_prize if @prize_ready
    end
    nil
  end
end

#===============================================================================
# Server → client event handlers
#===============================================================================

# Incoming challenge — queue for safe display on the next idle overworld frame.
NetworkClient.on('triad_request') { |d| NetworkTriad.instance_variable_set(:@pending_request, d) }

# Opponent's move relay.
NetworkClient.on('triad_move_relay') do |d|
  NetworkTriad.instance_variable_set(:@pending_move, d)
  NetworkTriad.instance_variable_set(:@move_ready,   true)
end

# Prize card the opponent wants to take from us.
NetworkClient.on('triad_prize_take') do |d|
  sym = d['card']&.to_sym
  NetworkTriad.instance_variable_set(:@pending_prize, sym)
  NetworkTriad.instance_variable_set(:@prize_ready,   true)
end

# Disconnect / abort during a wait loop — unblock wait_for_move.
NetworkClient.on('triad_ended') do |_d|
  NetworkTriad.instance_variable_set(:@move_ready,  true)  if NetworkTriad.active?
  NetworkTriad.instance_variable_set(:@prize_ready, true)  if NetworkTriad.active?
end

# Frame-update hook — shows pending challenges when it's safe to interrupt.
EventHandlers.add(:on_frame_update, :network_triad_pending,
  proc { NetworkTriad.process_pending if NetworkAuth.logged_in? }
)

#===============================================================================
# TriadScreen#pbStartPvP — networked duel using existing scene/sprites.
#
# Mirrors pbStartScreen but:
#   - Skips card selection (both decks already exchanged via server)
#   - On opponent turns: waits for triad_move_relay instead of running AI
#   - On win: player picks a card from converted opponent cards → sends prize
#   - On loss: waits for triad_prize_take → removes card from collection
#===============================================================================
class TriadScreen
  def pbStartPvP(opp_name, my_deck, opp_deck, i_go_first, triad_id)
    @playerName   = $player ? $player.name : "Trainer"
    @opponentName = opp_name
    @board        = Array.new(@width * @height) { TriadSquare.new }

    @scene.pbStartScene(self)

    cards         = my_deck.map  { |s| GameData::Species.try_get(s)&.id }.compact
    opponentCards = opp_deck.map { |s| GameData::Species.try_get(s)&.id }.compact

    if cards.length < maxCards || opponentCards.length < maxCards
      @scene.pbDisplayPaused(_INTL("Invalid decks. Duel cancelled."))
      @scene.pbEndScene
      NetworkClient.send_msg({ action: 'triad_result', triad_id: triad_id, won: nil })
      return 0
    end

    originalOpponentCards = opponentCards.clone

    @scene.pbNotifyCards(cards.clone, opponentCards.clone)
    @scene.pbShowPlayerCards(cards)
    @scene.pbShowOpponentCards(opponentCards)
    @scene.pbUpdateScore

    playerTurn = i_go_first
    @scene.pbDisplay(_INTL("{1} will go first.", playerTurn ? @playerName : @opponentName))

    (@width * @height).times do
      position  = nil
      triadCard = nil
      cardIndex = 0

      if playerTurn
        # Interactive player turn — same as single-player
        until position
          cardIndex = @scene.pbPlayerChooseCard(cards.length)
          triadCard = TriadCard.new(cards[cardIndex])
          position  = @scene.pbPlayerPlaceCard(cardIndex)
        end
        # Relay our move to the server so the opponent receives it.
        NetworkClient.send_msg({
          action:     'triad_move',
          triad_id:   triad_id,
          card_index: cardIndex,
          x:          position[0],
          y:          position[1]
        })
      else
        # Networked opponent turn — wait for relay.
        @scene.pbDisplay(_INTL("{1} is making a move...", @opponentName))
        move = NetworkTriad.wait_for_move
        if move.nil?
          # Timeout or disconnect.
          @scene.pbDisplayPaused(_INTL("Connection lost. Duel ended."))
          @scene.pbEndScene
          NetworkClient.send_msg({ action: 'triad_result', triad_id: triad_id, won: nil })
          NetworkTriad.instance_variable_set(:@triad_id, nil)
          return 0
        end
        cardIndex = move['card_index'].to_i.clamp(0, opponentCards.length - 1)
        position  = [move['x'].to_i, move['y'].to_i]
        triadCard = TriadCard.new(opponentCards[cardIndex])
        @scene.pbOpponentPlaceCard(triadCard, position, cardIndex)
      end

      boardIndex              = (position[1] * @width) + position[0]
      @board[boardIndex].card = triadCard
      @board[boardIndex].owner      = playerTurn ? 1 : 2
      @board[boardIndex].orig_owner = (playerTurn ? 1 : 2) if @board[boardIndex].orig_owner == 0
      flipBoard(position[0], position[1])

      if playerTurn
        cards.delete_at(cardIndex)
        @scene.pbEndPlaceCard(position, cardIndex)
      else
        opponentCards.delete_at(cardIndex)
        @scene.pbEndOpponentPlaceCard(position, cardIndex)
      end

      playerTurn = !playerTurn
    end

    # ── Determine outcome ──────────────────────────────────────────────────────
    player_count   = @board.count { |sq| sq.owner == 1 }
    opponent_count = @board.count { |sq| sq.owner == 2 }

    if player_count == opponent_count
      @scene.pbDisplayPaused(_INTL("The game is a draw!"))
      NetworkClient.send_msg({ action: 'triad_result', triad_id: triad_id, won: nil })
      @scene.pbEndScene
      return 3
    elsif player_count > opponent_count
      @scene.pbDisplayPaused(_INTL("{1} won against {2}!", @playerName, @opponentName))
      prize_card = _pvp_pick_prize(@opponentName)
      pbGiveAchievement(6) if prize_card && ($TriadShinyBoard || {}).value?(prize_card)
      NetworkClient.send_msg({
        action:     'triad_result',
        triad_id:   triad_id,
        won:        true,
        prize_card: prize_card&.to_s
      })
      @scene.pbEndScene
      return 1
    else
      @scene.pbDisplayPaused(_INTL("{1} won against {2}!", @opponentName, @playerName))
      @scene.pbDisplay(_INTL("{1} is choosing their prize...", @opponentName))
      prize_sym = NetworkTriad.wait_for_prize
      if prize_sym
        $PokemonGlobal.triads.remove(prize_sym)
        name = GameData::Species.get(prize_sym).name rescue prize_sym.to_s
        @scene.pbDisplayPaused(_INTL("{1} took your {2} card!", @opponentName, name))
      else
        @scene.pbDisplayPaused(_INTL("{1} didn't convert any cards, so no prize was taken.", @opponentName))
      end
      NetworkClient.send_msg({ action: 'triad_result', triad_id: triad_id, won: false })
      @scene.pbEndScene
      return 2
    end
  end

  private

  # Winner picks one converted (flipped) opponent card as their prize.
  def _pvp_pick_prize(opp_name)
    converted = Hash.new(0)
    (@width * @height).times do |i|
      sq = @board[i]
      next unless sq.card
      if sq.owner == 1 && sq.orig_owner == 2
        sid = GameData::Species.get_species_form(sq.card.species, sq.card.form).id
        converted[sid] += 1
      end
    end

    if converted.empty?
      @scene.pbDisplayPaused(_INTL("You didn't convert any of {1}'s cards.", opp_name))
      return nil
    end

    opts   = converted.keys
    labels = opts.map do |sid|
      nm  = GameData::Species.get(sid).name
      cnt = converted[sid]
      cnt > 1 ? _INTL("{1} x{2}", nm, cnt) : nm
    end
    choice = pbMessage(_INTL("Choose a prize card from {1}'s converted cards.", opp_name), labels, -1)
    return nil if choice.nil? || choice < 0

    sid = opts[choice]
    $PokemonGlobal.triads.add(sid)
    @scene.pbDisplayPaused(_INTL("Took {1} card!", GameData::Species.get(sid).name))
    sid
  end
end
