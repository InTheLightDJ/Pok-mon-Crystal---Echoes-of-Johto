#===============================================================================
# NetworkAuction — Auction house client.
#
# Server sends auction events over TCP; players interact via NPC event.
#
# NPC event script box (one call handles everything):
#   NetworkAuction.show_auction_dialog
#
# The server uses a 5-min cycle: 4-min bidding window, 1-min downtime.
# Pokemon lots are sold as eggs — species hidden until hatch.
#===============================================================================

module NetworkAuction
  @@status_ready  = false
  @@cached_status = nil
  @@bid_ready     = false
  @@bid_result    = nil
  @@claim_ready   = false
  @@claim_data    = nil

  # ── Called by event handlers ─────────────────────────────────────────────
  def self._set_status(data)
    @@cached_status = data
    @@status_ready  = true
  end

  def self._set_bid_result(data)
    @@bid_result = data
    @@bid_ready  = true
  end

  def self._set_claim(data)
    @@claim_data  = data
    @@claim_ready = true
  end

  # ── Network requests ─────────────────────────────────────────────────────
  def self.request_status
    @@status_ready = false
    NetworkClient.send_msg({ action: 'auction_status' })
  end

  def self.wait_status(frames = 150)
    frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return @@cached_status if @@status_ready
    end
    nil
  end

  def self.place_bid(amount)
    @@bid_ready = false
    NetworkClient.send_msg({ action: 'auction_bid', amount: amount })
  end

  def self.wait_bid(frames = 150)
    frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return @@bid_result if @@bid_ready
    end
    nil
  end

  def self.request_claim
    @@claim_ready = false
    NetworkClient.send_msg({ action: 'auction_claim' })
  end

  def self.wait_claim(frames = 150)
    frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return @@claim_data if @@claim_ready
    end
    nil
  end

  # ── Item name resolution (client-side — GameData has full TM data) ──────
  # Returns "TM01 (Focus Punch)" for TMs, or the plain item name for others.
  def self._resolve_item_name(item_id, fallback = '???')
    return fallback unless item_id && !item_id.empty?
    data = GameData::Item.get(item_id.to_sym) rescue nil
    return fallback unless data
    move_sym = data.move rescue nil
    if move_sym
      move_name = GameData::Move.get(move_sym).name rescue nil
      return move_name ? "#{data.name} (#{move_name})" : data.name
    end
    data.name
  end

  # Returns "Kris Skin" for wardrobe lots using the local PlayerMetadata/TrainerType tables.
  def self._resolve_wardrobe_name(wardrobe_id, fallback = '???')
    return fallback unless wardrobe_id
    id   = wardrobe_id.to_i
    return fallback if id <= 0
    meta = GameData::PlayerMetadata.get(id) rescue nil
    return fallback unless meta
    ttype = GameData::TrainerType.get(meta.trainer_type) rescue nil
    return fallback unless ttype
    "#{ttype.name} Skin"
  end

  # ── Number-input window ──────────────────────────────────────────────────
  # Returns the entered integer, or -1 if cancelled.
  def self._choose_number(default_val, max_digits = 4)
    chosen = -1
    begin
      win = Window_InputNumberPokemon.new(max_digits)
      win.z = 99999
      win.number = default_val.clamp(0, 10 ** max_digits - 1)
      win.x = (Graphics.width  - win.width)  / 2
      win.y = (Graphics.height - win.height) / 2
      win.visible = true
      loop do
        Graphics.update
        Input.update
        NetworkClient.update
        pbUpdateSceneMap
        win.update
        if Input.trigger?(Input::USE)
          chosen = win.number
          break
        end
        break if Input.trigger?(Input::BACK)
      end
      win.dispose
    rescue => e
      puts "[Auction] _choose_number error: #{e.message}"
      chosen = -1
    end
    chosen
  end

  # ── Prize delivery ───────────────────────────────────────────────────────
  def self._deliver_prizes(prizes)
    return if prizes.nil? || prizes.empty?
    prizes.each do |prize|
      case prize['type']
      when 'item'
        item_sym = prize['item_id'].to_sym
        pbReceiveItem(item_sym, prize['quantity'] || 1)
      when 'pokemon'
        species_sym = prize['item_id'].to_sym
        begin
          egg = Pokemon.new(species_sym, 1)
          egg.name           = "Egg"
          egg.steps_to_hatch = (GameData::Species.get(species_sym).hatch_steps rescue 5120)
          egg.steps_to_hatch = 5120 if egg.steps_to_hatch <= 0
          egg.happiness      = 40
          if $player.party.length < 6
            $player.party.push(egg)
            pbMessage(_INTL("You received a mysterious Sinnoh Egg!"))
          elsif !$PokemonStorage.full?
            stored_box = $PokemonStorage.pbStoreCaught(egg)
            box_name   = ($PokemonStorage[stored_box].name rescue "a Box")
            pbMessage(_INTL("Your party was full — the Sinnoh Egg was sent to Box \"%s\"!", box_name))
          else
            pbMessage(_INTL("Your party and PC are both full!\nYour Egg could not be stored. Please contact an admin."))
          end
        rescue => e
          puts "[Auction] Egg delivery failed for #{prize['item_id']}: #{e.message}"
          pbMessage(_INTL("There was an issue with your Egg. Please contact an admin."))
        end
      when 'wardrobe'
        char_id = prize['item_id'].to_i
        if PlayerUnlocks.unlocked?(char_id)
          pbMessage(_INTL("You already have #{prize['name']}!\n(A duplicate was in your prize queue — sorry about that!)"))
        else
          PlayerUnlocks.unlock(char_id)
          pbMessage(_INTL("You unlocked #{prize['name']}!\nCheck the character select screen to use it."))
        end
      end
    end
  end

  # ── Main NPC dialog — call this from the event script box ────────────────
  def self.show_auction_dialog
    request_status
    status = wait_status
    unless status
      pbMessage(_INTL("The auction house seems to be offline. Try again in a moment."))
      return
    end

    # Deliver any unclaimed prizes first
    pending_count = (status['pending'] || 0)
    if pending_count > 0
      # If any pending prize is an egg and there's nowhere to put it, warn first.
      pending_types = status['pending_types'] || []
      has_egg = pending_types.any? { |t| t == 'pokemon' }
      if has_egg && $player.party.length >= 6 && $PokemonStorage.full?
        pbMessage(_INTL("You have unclaimed prize(s), but your party and all PC Boxes are full!\nFree up some space and come back."))
        return
      end
      if pbConfirmMessage(_INTL("You have #{pending_count} unclaimed prize(s)! Claim them now?"))
        request_claim
        data = wait_claim
        if data && data['success']
          _deliver_prizes(data['prizes'])
        else
          pbMessage(_INTL("Couldn't retrieve your prizes. Try again."))
        end
        return
      end
    end

    # No active auction
    unless status['active']
      secs = (status['seconds'] || 0)
      pbMessage(_INTL("The Auction House is between sales.\nNext sale starts in about #{secs} seconds."))
      return
    end

    item_name = if status['item_type'] == 'wardrobe'
      _resolve_wardrobe_name(status['wardrobe_id'], status['item_name'] || '???')
    else
      _resolve_item_name(status['item_id'], status['item_name'] || '???')
    end
    lot_qty = status['quantity'] || 1
    item_name = "#{lot_qty}x #{item_name}" if lot_qty > 1
    start_bid  = status['start_bid']  || 1
    curr_bid   = status['current_bid'] || 0
    bidder     = status['bidder']
    time_left  = status['time_left']  || 0
    tokens     = status['tokens']     || 0

    bidder_line = bidder ? "Highest bidder: #{bidder}" : "No bids yet!"

    pbMessage(_INTL("Up for auction: #{item_name}\n" \
                    "Starting bid: #{start_bid} tokens\n" \
                    "Current bid: #{curr_bid} tokens\n" \
                    "#{bidder_line}\n" \
                    "Time left: #{time_left}s  |  Your tokens: #{tokens}"))

    if tokens <= curr_bid
      pbMessage(_INTL("You don't have enough tokens to outbid the current offer."))
      return
    end

    return unless pbConfirmMessage(_INTL("Would you like to place a bid?"))

    min_bid = curr_bid + 1
    max_digits = [tokens.to_s.length, 4].max
    pbMessage(_INTL("Enter your bid (min #{min_bid}).\nUse arrows to change digits, Z to confirm, X to cancel."))
    amount = _choose_number(min_bid, max_digits)

    return if amount < 0

    if amount <= curr_bid
      pbMessage(_INTL("Your bid of #{amount} is too low — must be at least #{min_bid}."))
      return
    end

    if amount > tokens
      pbMessage(_INTL("You only have #{tokens} tokens — that bid is too high."))
      return
    end

    place_bid(amount)
    result = wait_bid
    if result && result['success']
      pbMessage(_INTL("Your bid of #{amount} tokens has been placed!"))
    else
      msg = result ? result['message'] : "Bid failed. Please try again."
      pbMessage(_INTL(msg))
    end
  end
end

#===============================================================================
# TCP event handlers
#===============================================================================

NetworkClient.on('auction_status') do |data|
  NetworkAuction._set_status(data)
end

NetworkClient.on('auction_bid_response') do |data|
  NetworkAuction._set_bid_result(data)
end

NetworkClient.on('auction_claim_response') do |data|
  NetworkAuction._set_claim(data)
end

# Background update — silently refreshes cached bid info for the next dialog open.
NetworkClient.on('auction_update') do |data|
  cached = NetworkAuction.class_variable_get(:@@cached_status) rescue nil
  next unless cached.is_a?(Hash)
  cached['current_bid'] = data['current_bid'] if data.key?('current_bid')
  cached['bidder']      = data['bidder']       if data.key?('bidder')
  cached['time_left']   = data['time_left']    if data.key?('time_left')
end

# Fired when a player is outbid — interrupts to notify them.
NetworkClient.on('auction_outbid') do |data|
  item = if data['wardrobe_id']
    NetworkAuction._resolve_wardrobe_name(data['wardrobe_id'], data['item'] || 'the current lot')
  else
    NetworkAuction._resolve_item_name(data['item_id'], data['item'] || 'the current lot')
  end
  qty  = data['quantity'] || 1
  item = "#{qty}x #{item}" if qty > 1
  by      = data['by']      || 'someone'
  new_bid = data['new_bid']
  pbMessage(_INTL("You were outbid on #{item}!\n#{by} bid #{new_bid} tokens.\nHead back to the Auction House to rebid!"))
end

# The server can't read this game's PBS files (it doesn't run on this
# machine), so it asks a connected client to resolve TM → move names using
# its own GameData — that's also correct if this player has modded items.txt
# or moves.txt, since it reflects what's actually installed. Answers are
# cached server-side, so this only fires for IDs nobody has resolved yet.
NetworkClient.on('resolve_tm_names') do |data|
  ids   = data['ids'] || []
  names = {}
  ids.each do |id|
    item_data = GameData::Item.get(id.to_sym) rescue nil
    move_sym  = item_data&.move rescue nil
    move_name = move_sym ? (GameData::Move.get(move_sym).name rescue nil) : nil
    names[id] = move_name if move_name
  end
  NetworkClient.send_msg({ action: 'resolve_tm_names_response', names: names }) unless names.empty?
end

# Same idea for wardrobe/character skin auctions: the server's wardrobe id is a
# PlayerMetadata id, not a TrainerType id, so it has to go through the same
# indirection _resolve_wardrobe_name does (PlayerMetadata → TrainerType → name).
# The `meta.id == id` check guards against PlayerMetadata.get() silently
# falling back to player 1's data for an id that doesn't actually exist.
NetworkClient.on('resolve_wardrobe_names') do |data|
  ids   = data['ids'] || []
  names = {}
  ids.each do |id|
    wid   = id.to_i
    meta  = GameData::PlayerMetadata.get(wid) rescue nil
    next unless meta && meta.id == wid
    ttype = GameData::TrainerType.get(meta.trainer_type) rescue nil
    names[id.to_s] = ttype.name if ttype
  end
  NetworkClient.send_msg({ action: 'resolve_wardrobe_names_response', names: names }) unless names.empty?
end

# Fired when a player wins — they need to collect from the NPC.
NetworkClient.on('auction_won') do |data|
  item = if data['wardrobe_id']
    NetworkAuction._resolve_wardrobe_name(data['wardrobe_id'], data['item'] || 'your prize')
  else
    NetworkAuction._resolve_item_name(data['item_id'], data['item'] || 'your prize')
  end
  qty  = data['quantity'] || 1
  item = "#{qty}x #{item}" if qty > 1
  cost = data['cost']
  pbMessage(_INTL("Congratulations! You won the auction for #{item} at #{cost} tokens!\nVisit the Auction House NPC to claim your prize."))
end
