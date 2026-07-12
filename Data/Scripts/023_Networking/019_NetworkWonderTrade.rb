#===============================================================================
# NetworkWonderTrade — blind random trade with a random online stranger.
#
# Flow:
#   1. Player picks a Pokémon from their party.
#   2. Client sends wonder_trade_enter with the serialized Pokémon.
#   3. Server either matches immediately (wonder_trade_complete) or puts the
#      player in the waiting pool (wonder_trade_waiting).
#   4. If waiting: silent loop until a match arrives or the player presses B.
#   5. On match: standard trade animation, party slot replaced, auto-save.
#===============================================================================
module NetworkWonderTrade
  @offered_slot = nil
  @offered_pkmn = nil

  def self.start
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to use Wonder Trade."))
      return
    end

    # Must have at least 2 non-egg Pokémon so one always remains
    if $player.party.count { |p| p && !p.egg? } < 2
      pbMessage(_INTL("You need at least 2 Pokémon to use Wonder Trade!"))
      return
    end

    pbMessage(_INTL("Welcome to Wonder Trade!\nYou'll be matched with a stranger\nand swap Pokémon at random!"))

    # Pick a Pokémon
    slot = nil
    pbFadeOutIn do
      scene  = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $player.party)
      screen.pbStartScene(_INTL("Choose a Pokémon to Wonder Trade!"), false)
      slot = screen.pbChoosePokemon
      screen.pbEndScene
    end
    return if slot.nil? || slot < 0

    pkmn = $player.party[slot]
    return if pkmn.nil? || pkmn.egg?

    return unless pbConfirmMessage(
      _INTL("Send {1} for Wonder Trade?\nYou won't know what you'll get!", pkmn.name)
    )

    @offered_slot = slot
    @offered_pkmn = pkmn

    # Register callbacks before sending to avoid missing an instant match
    result = nil
    NetworkClient.on('wonder_trade_waiting')   { result = :waiting }
    NetworkClient.on('wonder_trade_complete')  { |d| result = d }
    NetworkClient.on('wonder_trade_cancelled') { result = :cancelled }

    NetworkClient.send_msg({
      action:  'wonder_trade_enter',
      pokemon: NetworkTrade.serialize_pokemon(pkmn)
    })

    # Wait for immediate server ack (instant match or queued)
    200.times do
      Graphics.update
      Input.update
      NetworkClient.update
      break if result
    end
    NetworkClient.off('wonder_trade_waiting')

    # If queued, show message then poll until matched or cancelled
    if result == :waiting
      pbMessage(_INTL("Searching for a Wonder Trade partner...\n(Press B to cancel)"))
      loop do
        Graphics.update
        Input.update
        NetworkClient.update
        break if result.is_a?(Hash) || result == :cancelled
        if Input.trigger?(Input::BACK)
          NetworkClient.send_msg({ action: 'wonder_trade_cancel' })
          result = :user_cancelled
          break
        end
      end
    end

    NetworkClient.off('wonder_trade_complete')
    NetworkClient.off('wonder_trade_cancelled')

    _finish(result)
  end

  private

  def self._finish(result)
    if result.is_a?(Hash) && result['received']
      received = NetworkTrade.deserialize_pokemon(result['received'])
      if received
        received.obtain_method = 2  # obtained via trade
        partner = result['partner'] || 'a Stranger'
        pbFadeOutInWithMusic do
          scene = PokemonTrade_Scene.new
          scene.pbStartScreen(@offered_pkmn, received, $player.name, partner)
          scene.pbTrade
          scene.pbEndScreen
        end
        $player.party[@offered_slot] = received
        Game.save(safe: true)
      end
    elsif result == :cancelled
      pbMessage(_INTL("The Wonder Trade was cancelled."))
    end
    @offered_slot = nil
    @offered_pkmn = nil
  end
end
