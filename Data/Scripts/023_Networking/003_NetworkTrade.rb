#===============================================================================
# NetworkTrade — online Pokémon trading between two connected players.
#
# REQUESTER (you initiate):
#   NetworkTrade.request_trade
#     1. Show online player list → pick target
#     2. Send request, wait for server ack
#     3. Silent wait for partner to accept (B cancels)
#     4. Pick a Pokémon → trade screen
#
# ACCEPTER (passive — no action needed):
#   Trade requests arrive automatically while logged in.
#   A dialog appears in the overworld: "X wants to trade! Accept/Decline"
#   If accepted → pick a Pokémon → trade screen
#
# open_trade_waiting_room is kept for map events that call it, but trades
# now arrive automatically — the waiting room just blocks until one arrives.
#===============================================================================

module NetworkTrade
  @trade_id          = nil
  @partner_name      = nil
  @my_offer          = nil   # Pokemon object we're sending
  @their_offer       = nil   # serialized Pokemon hash from partner
  @partner_confirmed = false
  @pending_request   = nil   # incoming request queued by the background listener

  def self.active?
    !@trade_id.nil?
  end

  #-----------------------------------------------------------------------------
  # Called every frame by the on_frame_update hook.
  # Shows the incoming trade dialog when safe (overworld, not busy).
  #-----------------------------------------------------------------------------
  def self.process_pending
    return unless @pending_request && !@trade_id
    return if _busy?
    req = @pending_request
    @pending_request = nil
    _handle_incoming(req)
  end

  #-----------------------------------------------------------------------------
  # Requester side: pick target → wait for accept → pick Pokémon → trade screen
  #-----------------------------------------------------------------------------
  def self.request_trade(target_username = nil)
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to trade."))
      return
    end

    # Step 1 — choose who to trade with
    if target_username.nil?
      players = _fetch_online_players
      if players.empty?
        pbMessage(_INTL("No other players are online right now."))
        return
      end
      target_username = _select_player(players)
      return unless target_username
    end

    # Step 2 — send the request, wait for server ack (trade_pending) or trade_error
    puts "[Trade] Sending trade_request to: #{target_username.inspect}"
    NetworkClient.send_msg({ action: 'trade_request', target_username: target_username })

    pending_result = nil
    NetworkClient.on('trade_pending') { |d| @trade_id = d['trade_id']; pending_result = :ok }
    NetworkClient.on('trade_error')   { |d| pending_result = d['message'] }
    200.times do
      Graphics.update; Input.update; NetworkClient.update
      break if pending_result
    end
    NetworkClient.off('trade_pending')
    NetworkClient.off('trade_error')

    unless pending_result == :ok
      pbMessage(_INTL(pending_result.is_a?(String) ? pending_result : "No response from server."))
      _reset
      return
    end

    @partner_name = target_username

    # Step 3 — wait for the partner to accept or decline (B to cancel)
    accepted      = false
    cancel_reason = nil
    NetworkClient.on('trade_accepted')  { |_| accepted = true }
    NetworkClient.on('trade_cancelled') { |d| cancel_reason = d['reason'] }

    timed_out = true
    1800.times do
      Graphics.update; Input.update; NetworkClient.update
      if accepted || cancel_reason
        timed_out = false
        break
      end
      if Input.trigger?(Input::BACK)
        NetworkClient.send_msg({ action: 'trade_cancel' })
        cancel_reason = 'You cancelled'
        timed_out = false
        break
      end
    end
    NetworkClient.off('trade_accepted')
    NetworkClient.off('trade_cancelled')

    unless accepted
      pbMessage(_INTL(timed_out ? "{1} did not respond." : "Trade cancelled: {1}",
                      timed_out ? target_username : (cancel_reason || 'Unknown')))
      _reset
      return
    end

    # Step 4 — partner accepted: now choose a Pokémon to offer
    slot = _pick_pokemon_for_trade
    if slot.nil?
      NetworkClient.send_msg({ action: 'trade_cancel' })
      _reset
      return
    end
    @my_offer = $player.party[slot]

    # Step 5 — open the trade screen (sends initial offer internally)
    _run_trade_screen
  end

  #-----------------------------------------------------------------------------
  # Optional explicit waiting room — blocks until a request arrives or B pressed.
  # Trades also arrive passively (process_pending), so this is optional.
  #-----------------------------------------------------------------------------
  def self.open_trade_waiting_room
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to trade."))
      return
    end
    pbMessage(_INTL("Waiting for a trade request...\n(Press B to cancel)"))
    loop do
      Graphics.update; Input.update; NetworkClient.update
      break if @pending_request || @trade_id || Input.trigger?(Input::BACK)
    end
    # process_pending fires on the next frame update if @pending_request is set
  end

  #-----------------------------------------------------------------------------
  # Pokémon serialization — mirrors ServerStuff/utils/pokemon.js fields
  #-----------------------------------------------------------------------------
  def self.serialize_pokemon(pkmn)
    moves = pkmn.moves.map { |m| m ? m.id.to_s : nil }.compact
    {
      'species'   => pkmn.species.to_s,
      'level'     => pkmn.level,
      'exp'       => pkmn.exp,
      'nickname'  => pkmn.nicknamed? ? pkmn.name : nil,
      'gender'    => pkmn.gender,
      'nature'    => pkmn.nature_id.to_s,
      'ability'   => pkmn.ability_id.to_s,
      'item'      => pkmn.item_id ? pkmn.item_id.to_s : nil,
      'moves'     => moves,
      'ivs'       => {
        'hp'  => pkmn.iv[:HP],  'atk' => pkmn.iv[:ATTACK],
        'def' => pkmn.iv[:DEFENSE], 'spa' => pkmn.iv[:SPECIAL_ATTACK],
        'spd' => pkmn.iv[:SPECIAL_DEFENSE], 'spe' => pkmn.iv[:SPEED]
      },
      'evs'       => {
        'hp'  => pkmn.ev[:HP],  'atk' => pkmn.ev[:ATTACK],
        'def' => pkmn.ev[:DEFENSE], 'spa' => pkmn.ev[:SPECIAL_ATTACK],
        'spd' => pkmn.ev[:SPECIAL_DEFENSE], 'spe' => pkmn.ev[:SPEED]
      },
      'hp'        => pkmn.hp,
      'shiny'     => pkmn.shiny?,
      'ball'      => pkmn.poke_ball ? pkmn.poke_ball.to_s : 'POKEBALL',
      'ot_name'   => pkmn.owner.name,
      'ot_id'     => pkmn.owner.id,
      'ot_gender' => pkmn.owner.gender,
      'ribbons'   => pkmn.ribbons.map(&:to_s),
      'form'      => pkmn.form,
      'happiness' => pkmn.happiness,
      'contest'   => {
        'cool'   => pkmn.cool,   'beauty' => pkmn.beauty,
        'cute'   => pkmn.cute,   'smart'  => pkmn.smart,
        'tough'  => pkmn.tough,  'sheen'  => pkmn.sheen
      }
    }
  end

  def self.deserialize_pokemon(data)
    species = data['species'].to_sym
    return nil unless GameData::Species.exists?(species)

    pkmn = Pokemon.new(species, data['level'])
    pkmn.name      = data['nickname']    if data['nickname']
    pkmn.shiny     = true                if data['shiny']
    pkmn.form      = data['form'].to_i
    pkmn.exp       = data['exp'].to_i    if data['exp']
    pkmn.gender    = data['gender'].to_i unless data['gender'].nil?
    pkmn.happiness = data['happiness'].to_i if data['happiness']

    if data['nature']
      nat = data['nature'].to_sym
      pkmn.nature = nat if GameData::Nature.exists?(nat)
    end

    if data['ability']
      ab = data['ability'].to_sym
      pkmn.ability = ab if GameData::Ability.exists?(ab)
    end

    if data['item']
      it = data['item'].to_sym
      pkmn.item = it if GameData::Item.exists?(it)
    end

    pkmn.poke_ball = data['ball'].to_sym if data['ball']

    if data['ot_name'] && data['ot_id']
      pkmn.owner = Pokemon::Owner.new(data['ot_id'].to_i, data['ot_name'],
                                      (data['ot_gender'] || 0).to_i, 0)
    end

    pkmn.reset_moves
    (data['moves'] || []).each_with_index do |move_id, i|
      next unless move_id && GameData::Move.exists?(move_id.to_sym)
      pkmn.moves[i] = Pokemon::Move.new(move_id.to_sym)
    end

    { 'hp' => :HP, 'atk' => :ATTACK, 'def' => :DEFENSE,
      'spa' => :SPECIAL_ATTACK, 'spd' => :SPECIAL_DEFENSE, 'spe' => :SPEED
    }.each do |key, stat|
      pkmn.iv[stat] = data['ivs'][key].to_i if data['ivs']
      pkmn.ev[stat] = data['evs'][key].to_i if data['evs']
    end

    if data['contest']
      c = data['contest']
      pkmn.cool   = c['cool'].to_i   if c['cool']
      pkmn.beauty = c['beauty'].to_i if c['beauty']
      pkmn.cute   = c['cute'].to_i   if c['cute']
      pkmn.smart  = c['smart'].to_i  if c['smart']
      pkmn.tough  = c['tough'].to_i  if c['tough']
      pkmn.sheen  = c['sheen'].to_i  if c['sheen']
    end

    (data['ribbons'] || []).each do |r|
      sym = r.to_sym
      pkmn.giveRibbon(sym) if GameData::Ribbon.exists?(sym)
    end

    pkmn.calc_stats
    pkmn.hp = data['hp'].to_i if data['hp']  # restore pre-battle HP (after calc_stats sets totalhp)
    pkmn
  end

  private

  #-----------------------------------------------------------------------------
  # Returns true when the player cannot safely receive a trade dialog right now.
  #-----------------------------------------------------------------------------
  def self._busy?
    return true unless $scene.is_a?(Scene_Map)
    return true if $game_system&.map_interpreter&.running?
    return true if $game_temp&.in_battle
    return true if $game_temp&.message_window_showing
    return true if $game_temp&.in_menu
    false
  end

  #-----------------------------------------------------------------------------
  # Stored by the persistent background listener; processed by process_pending.
  # If the player is busy right now, decline immediately so the requester gets
  # a clear "player is busy" message instead of waiting for a server timeout.
  #-----------------------------------------------------------------------------
  def self._store_request(data)
    return if @trade_id
    if _busy?
      NetworkClient.send_msg({ action: 'trade_decline', trade_id: data['trade_id'], reason: 'busy' })
    else
      @pending_request = data
    end
  end

  #-----------------------------------------------------------------------------
  # Accepter flow: show dialog, accept/decline, pick Pokémon, trade screen
  #-----------------------------------------------------------------------------
  def self._handle_incoming(req)
    response = pbMessage(
      _INTL("{1} wants to trade!", req['from']),
      [_INTL("Accept"), _INTL("Decline")], 2
    )

    if response != 0
      NetworkClient.send_msg({ action: 'trade_decline', trade_id: req['trade_id'] })
      return
    end

    @partner_name = req['from']
    @trade_id     = req['trade_id']
    NetworkClient.send_msg({ action: 'trade_accept', trade_id: @trade_id })

    slot = _pick_pokemon_for_trade
    if slot.nil?
      NetworkClient.send_msg({ action: 'trade_cancel' })
      _reset
      return
    end

    @my_offer = $player.party[slot]
    _run_trade_screen
  end

  #-----------------------------------------------------------------------------
  # Fetch the list of other logged-in players from the server
  #-----------------------------------------------------------------------------
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

  def self._select_player(players)
    cmds   = players + [_INTL("Cancel")]
    choice = pbMessage(_INTL("Who do you want to trade with?"), cmds, cmds.length)
    return nil if choice < 0 || choice == players.length
    players[choice]
  end

  def self._pick_pokemon_for_trade
    pbMessage(_INTL("Choose a Pokémon to offer."))
    chosen = nil
    pbFadeOutIn do
      scene  = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $player.party)
      screen.pbStartScene(_INTL("Choose a Pokémon to trade."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
    return nil if chosen < 0
    return nil if $player.party[chosen].egg?
    chosen
  end

  #-----------------------------------------------------------------------------
  # Trade screen — registers callbacks first, then sends initial offer, then loops
  #-----------------------------------------------------------------------------
  def self._run_trade_screen
    trade_result  = nil
    cancel_reason = nil
    waiting       = false

    NetworkClient.on('trade_partner_offer') do |d|
      @their_offer       = d['pokemon']
      @partner_confirmed = false
      waiting = false if waiting
    end
    NetworkClient.on('trade_partner_confirmed') { |_| @partner_confirmed = true }
    NetworkClient.on('trade_complete')          { |d| trade_result = d['received'] }
    NetworkClient.on('trade_cancelled')         { |d| trade_result = :cancelled; cancel_reason = d['reason'] }

    # Send our offer now that callbacks are registered (avoids race condition)
    NetworkClient.send_msg({
      action:   'trade_offer',
      trade_id: @trade_id,
      pokemon:  serialize_pokemon(@my_offer)
    })

    loop do
      Graphics.update; Input.update; NetworkClient.update
      break if trade_result

      if waiting
        if Input.trigger?(Input::BACK)
          NetworkClient.send_msg({ action: 'trade_cancel' })
          trade_result  = :cancelled
          cancel_reason = 'You cancelled'
        end
        next
      end

      partner_str = @their_offer ? @their_offer['species'] : _INTL("Waiting for {1}...", @partner_name)
      partner_str += _INTL(" (ready!)") if @partner_confirmed && @their_offer
      my_str = @my_offer.species.to_s

      cmd = pbMessage(
        _INTL("{1} offers: {2}\nYou offer: {3}", @partner_name, partner_str, my_str),
        [_INTL("Confirm"), _INTL("Change offer"), _INTL("Cancel")], 3
      )

      break if trade_result

      case cmd
      when 0
        NetworkClient.send_msg({ action: 'trade_confirm', trade_id: @trade_id })
        waiting = true
      when 1
        slot = _pick_pokemon_for_trade
        if slot
          @my_offer = $player.party[slot]
          NetworkClient.send_msg({
            action:   'trade_offer',
            trade_id: @trade_id,
            pokemon:  serialize_pokemon(@my_offer)
          })
        end
      when 2
        NetworkClient.send_msg({ action: 'trade_cancel' })
        trade_result  = :cancelled
        cancel_reason = 'You cancelled'
      end
    end

    NetworkClient.off('trade_partner_offer')
    NetworkClient.off('trade_partner_confirmed')
    NetworkClient.off('trade_complete')
    NetworkClient.off('trade_cancelled')

    if trade_result.is_a?(Hash)
      received = deserialize_pokemon(trade_result)
      if received
        received.obtain_method = 2  # obtained via trade
        slot = $player.party.index(@my_offer)
        pbFadeOutInWithMusic do
          scene = PokemonTrade_Scene.new
          scene.pbStartScreen(@my_offer, received, $player.name, @partner_name)
          scene.pbTrade
          scene.pbEndScreen
        end
        $player.party[slot] = received if slot
        Game.save(safe: true)
      end
    elsif trade_result == :cancelled
      pbMessage(_INTL("Trade cancelled: {1}", cancel_reason || 'Unknown'))
    end

    _reset
  end

  def self._reset
    @trade_id          = nil
    @partner_name      = nil
    @my_offer          = nil
    @their_offer       = nil
    @partner_confirmed = false
    @pending_request   = nil
  end
end

#-------------------------------------------------------------------------------
# Persistent background listener — stores incoming trade requests so they can
# be shown by process_pending without requiring open_trade_waiting_room.
#-------------------------------------------------------------------------------
NetworkClient.on('trade_request') { |d| NetworkTrade._store_request(d) }

EventHandlers.add(:on_frame_update, :network_trade_incoming,
  proc { NetworkTrade.process_pending if NetworkClient.connected? }
)
