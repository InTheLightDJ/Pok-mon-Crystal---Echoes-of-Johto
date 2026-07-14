#===============================================================================
# NetworkTourney — PvP bracket tournament client.
#
# NPC event script box (one call handles everything):
#   BracketTourney("Viridian City", "MEGASTONES")
#   BracketTourney("Goldenrod City", "SUPERITEMS")
#   BracketTourney("Blackthorn City", "POKEMONEGGS")
#
# Prize types:
#   MEGASTONES  — a random Mega Stone (specific stone revealed at NPC)
#   SUPERITEMS  — Master Ball, Big Nugget, Legendary Pack, Exp Share, or Lucky Egg
#   POKEMONEGGS — a random Gen 1-4 Pokémon Egg (species revealed at NPC)
#
# Flow:
#   Player talks to NPC → tourney_interact sent → server returns tourney_status
#   If signup open: player can join (sends tourney_signup with team)
#   When match ready: server sends tourney_match (notification between battles)
#   Player auto-responds with tourney_ready (team snapshot at match time)
#   Server sends tourney_battle_start with both teams → battle runs
#   After battle: tourney_result sent (winner + stats)
#   Server announces winner, awards prize via auction_prizes table
#   Prize claimed at Tournament Host NPC (same as auction NPC claim flow)
#===============================================================================

module NetworkTourney
  # ── State ────────────────────────────────────────────────────────────────────
  @@status_ready   = false
  @@cached_status  = nil
  @@signup_ready   = false
  @@signup_result  = nil
  @@pending_match  = nil   # set by tourney_match event; processed by on_frame_update
  @@pending_start  = nil   # set by tourney_battle_start event; processed by on_frame_update
  @@in_match       = false

  # ── Called by event handlers ─────────────────────────────────────────────────
  def self._set_status(data)
    @@cached_status = data
    @@status_ready  = true
  end

  def self._set_signup_result(data)
    @@signup_result = data
    @@signup_ready  = true
  end

  def self._set_pending_match(data)
    return if @@in_match
    @@pending_match = data
  end

  def self._set_pending_start(data)
    @@pending_start = data
  end

  # ── Network helpers ───────────────────────────────────────────────────────────
  def self._send(hash)
    NetworkClient.send_msg(hash)
  end

  def self._wait(frames = 150, &block)
    frames.times do
      Graphics.update; Input.update; NetworkClient.update
      return true if block.call
    end
    false
  end

  def self._serialize_team(party)
    party.filter_map { |p| p && !p.egg? ? NetworkTrade.serialize_pokemon(p) : nil }
  end

  # ── Prize delivery (reuse auction delivery) ───────────────────────────────────
  def self._deliver_prizes(prizes)
    return if prizes.nil? || prizes.empty?
    prizes.each do |prize|
      case prize['type']
      when 'item'
        pbReceiveItem(prize['item_id'].to_sym, 1)
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
            pbMessage(_INTL("You received a {1} Egg from the tournament!", prize['item_id']))
          elsif !$PokemonStorage.full?
            box = $PokemonStorage.pbStoreCaught(egg)
            pbMessage(_INTL("Your party was full — the egg was sent to Box {1}!",
                            ($PokemonStorage[box].name rescue "a Box")))
          else
            pbMessage(_INTL("Your party and PC are full! Contact an admin for your prize."))
          end
        rescue => e
          puts "[Tourney] Egg delivery error: #{e.message}"
          pbMessage(_INTL("There was a problem with your prize. Contact an admin."))
        end
      end
    end
  end

  # ── Claim pending prizes (same table as auction) ──────────────────────────────
  def self._try_claim_prizes
    @@signup_ready = false
    _send({ action: 'auction_claim' })
    done = false
    NetworkClient.on('auction_claim_response') { |d| @@signup_result = d; done = true }
    _wait(150) { done }
    NetworkClient.off('auction_claim_response')

    data = @@signup_result
    if data && data['success'] && data['prizes']
      prizes = data['prizes'].select { |p| p['type'] == 'item' || p['type'] == 'pokemon' }
      _deliver_prizes(prizes)
    end
  end

  # ── on_frame_update hook ──────────────────────────────────────────────────────
  # Processes incoming tourney_match and tourney_battle_start while in overworld.
  def self.process_pending
    return unless NetworkClient.connected?
    return if @@in_match

    if @@pending_match
      return unless $scene.is_a?(Scene_Map)
      return if $game_system.map_interpreter.running?
      data = @@pending_match
      @@pending_match = nil
      _handle_pending_match(data)
    end

    if @@pending_start
      return unless $scene.is_a?(Scene_Map)
      return if $game_system.map_interpreter.running?
      data = @@pending_start
      @@pending_start = nil
      @@in_match = true
      _run_tourney_battle(data)
      @@in_match = false
    end
  end

  # Called when tourney_match arrives (server wants our team, sends match info)
  def self._handle_pending_match(data)
    pbMessage(_INTL("Tournament match ready!\n{1}: {2} vs {3}\nGet ready!",
                    data['match_label'] || 'Match',
                    NetworkAuth.username,
                    data['opponent'] || '???'))

    _send({
      action:          'tourney_ready',
      battle_id:       data['battle_id'],
      team:            _serialize_team($player.party),
      trainer_sprite:  $player.trainer_type.to_s,
    })

    pbMessage(_INTL("Waiting for opponent to ready up..."))
  end

  # ── Battle engine ─────────────────────────────────────────────────────────────
  def self._run_tourney_battle(data)
    battle_id  = data['battle_id']
    seed       = data['seed'].to_i
    opp_name   = data['opp_name']   || 'Opponent'
    opp_sprite = data['opp_sprite'] || 'POKEMONTRAINER_1'
    is_p1      = data['is_player1']

    srand(seed)

    opp_sym     = opp_sprite.to_sym
    opp_sym     = :POKEMONTRAINER_1 unless GameData::TrainerType.exists?(opp_sym)
    opp_trainer = NPCTrainer.new(opp_name, opp_sym)
    opp_trainer.party = (data['opp_team'] || []).filter_map { |d| NetworkTrade.deserialize_pokemon(d) }

    if opp_trainer.party.empty?
      pbMessage(_INTL("Could not load {1}'s team. Match cancelled.", opp_name))
      _send({ action: 'tourney_result', battle_id: battle_id, winner: nil,
              pokemon_remaining: $player.party.count { |p| p && !p.fainted? },
              total_hp: $player.party.sum { |p| (p && !p.fainted?) ? p.hp : 0 } })
      return
    end

    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers(opp_trainer.party)
    player_party = player_party.map { |p| p ? Marshal.load(Marshal.dump(p)) : nil }

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle::TourneyPvP.new(
      scene, player_party, opp_trainer.party,
      player_trainers, [opp_trainer],
      battle_id
    )
    battle.is_challenger  = is_p1
    battle.party1starts   = party_starts
    battle.party2starts   = [0]
    battle.ally_items     = ally_items
    battle.items          = []
    battle.internalBattle = true
    battle.expGain        = false
    battle.moneyGain      = false

    setBattleRule("single") if $game_temp.battle_rules["size"].nil?
    # Same fix as Battle::NetworkPvP#_run_battle (004_NetworkBattle.rb) — force
    # neutral weather/terrain/environment so two players standing on different
    # maps can't silently simulate the same moves under different conditions.
    setBattleRule("weather", :None)      if $game_temp.battle_rules["defaultWeather"].nil?
    setBattleRule("terrain", :None)      if $game_temp.battle_rules["defaultTerrain"].nil?
    setBattleRule("environment", :None)  if $game_temp.battle_rules["environment"].nil?
    BattleCreationHelperMethods.prepare_battle(battle)
    battle.switchStyle = false
    $game_temp.clear_battle_rules

    bgm = pbGetTrainerBattleBGM([opp_trainer])
    pbBattleAnimation(bgm, 1, [opp_trainer]) do
      pbSceneStandby { battle.pbStartBattle }
    end

    battle.net_cleanup

    # Collect battle stats
    my_remaining = 0
    my_total_hp  = 0
    begin
      battle.pbParty(0).each do |pkmn|
        next unless pkmn
        next if pkmn.fainted?
        my_remaining += 1
        my_total_hp  += pkmn.hp
      end
    rescue => e
      puts "[Tourney] Stat collection error: #{e.message}"
    end

    # Determine winner from this client's perspective
    timed_out = battle.instance_variable_get(:@tourney_timed_out)
    winner_username = if timed_out
      nil
    elsif battle.decision == 1  # Battle::Outcome::WIN
      NetworkAuth.username
    else
      opp_name
    end

    _send({
      action:            'tourney_result',
      battle_id:         battle_id,
      winner:            winner_username,
      pokemon_remaining: my_remaining,
      total_hp:          my_total_hp,
    })
  end

  # ── NPC dialog — called from BracketTourney(city, prize_type) ─────────────────
  def self.show_dialog(city, prize_type)
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to use the Tournament Host."))
      return
    end

    # Request status / trigger signup
    @@status_ready = false
    _send({ action: 'tourney_interact', city: city, prize_type: prize_type })
    _wait(150) { @@status_ready }

    status = @@cached_status
    unless status
      pbMessage(_INTL("The Tournament Host is offline. Try again in a moment."))
      return
    end

    phase = status['phase'] || 'idle'

    case phase
    when 'idle'
      next_in = status['next_in_s'] || 0
      if next_in > 0
        mins = next_in / 60
        pbMessage(_INTL("No tournament is scheduled right now.\nNext tournament: Monday at noon (~{1} min).", mins))
      else
        pbMessage(_INTL("A tournament signup just opened! Talk to me again in a moment."))
      end

    when 'signup'
      prize_str = _prize_display(status['prize_type'], status['prize_id'], status['prize_idtype'])
      count     = status['player_count'] || 0
      secs      = status['time_left_s']  || 0
      mins      = secs / 60

      if status['in_signup']
        pbMessage(_INTL("You're already registered!\nPrize: {1}\nPlayers: {2}/8  Time left: {3} min",
                        prize_str, count, mins))
        return
      end

      pbMessage(_INTL("A {1} Bracket Tournament is underway!\nPrize: {2}\nPlayers signed up: {3}/8\nTime to sign up: {4} min",
                      city, prize_str, count, mins))

      return unless pbConfirmMessage(_INTL("Register for the tournament?"))

      @@signup_ready = false
      _send({
        action:         'tourney_signup',
        trainer_sprite: $player.trainer_type.to_s,
        team:           _serialize_team($player.party),
      })
      _wait(150) { @@signup_ready }

      result = @@signup_result
      if result && result['success']
        pbMessage(_INTL("You've entered! You're player {1}.\nStand by - the tournament starts when 4+ players are registered or time runs out.", result['position']))
      else
        msg = result ? result['message'] : "Registration failed."
        pbMessage(_INTL(msg))
      end

    when 'active'
      pbMessage(_INTL("The tournament is in progress!\n\n{1}", status['bracket'] || ''))
    end
  end

  def self._prize_display(prize_type, prize_id, prize_idtype)
    return '???' unless prize_type && prize_id
    case prize_type
    when 'MEGASTONES'  then "Mega Stone (#{prize_id})"
    when 'SUPERITEMS'  then prize_id.capitalize
    when 'POKEMONEGGS' then "#{prize_id} Egg"
    else prize_id
    end
  end
end

#===============================================================================
# Battle::TourneyPvP — subclass of Battle::NetworkPvP that uses tourney_*
# events and sends tourney_result after each match.
#===============================================================================
class Battle::TourneyPvP < Battle::NetworkPvP
  def initialize(scene, my_party, opp_party, my_trainers, opp_trainers, battle_id)
    super
    @tourney_timed_out = false
    @tourney_ended     = false
  end

  def _register_net_callbacks
    NetworkClient.on('tourney_moves_ready') do |d|
      @current_turn_seed    = d['turn_seed']
      @net_opp_move_pending = d['opp_move']
      @net_moves_ready      = true
    end
    NetworkClient.on('tourney_opp_switch_result') { |d| @opp_switch_queue << d['party_slot'].to_i }
    NetworkClient.on('tourney_timeout')           { |d| @tourney_timed_out = true; @battle_ended_ext = true }
    NetworkClient.on('tourney_match_over')        { |d| @tourney_ended = true; @battle_ended_ext = true }
    NetworkClient.on('tourney_disqualified')      { |d| @tourney_ended = true; @battle_ended_ext = true }
    NetworkClient.on('disconnected')              { |_| @lost_connection = true; @battle_ended_ext = true }
    NetworkClient.on('tourney_hp_sync')           { |d| @hp_sync_data = d['hp']; @hp_sync_received = true }
    NetworkClient.on('tourney_hp_update')         { |d| @hp_update_queue << d }
  end

  def net_cleanup
    NetworkClient.off('tourney_moves_ready')
    NetworkClient.off('tourney_opp_switch_result')
    NetworkClient.off('tourney_timeout')
    NetworkClient.off('tourney_match_over')
    NetworkClient.off('tourney_disqualified')
    NetworkClient.off('disconnected')
    NetworkClient.off('tourney_hp_sync')
    NetworkClient.off('tourney_hp_update')
  end

  def _net_send_my_choice
    c = @choices[0]
    data = case c[0]
           when :UseMove   then { 'action' => 'fight',  'move_index' => c[1], 'target_index' => c[3] }
           when :SwitchOut then { 'action' => 'switch', 'party_slot' => c[1] }
           when :Run       then { 'action' => 'run' }
           else                 { 'action' => 'forced' }
           end
    NetworkClient.send_msg({ action: 'tourney_move', battle_id: @battle_id, move: data })
  end

  def pbSwitchInBetween(idxBattler, checkLaxOnly = false, canCancel = false)
    if pbOwnedByPlayer?(idxBattler)
      slot = pbPartyScreen(idxBattler, checkLaxOnly, canCancel)
      NetworkClient.send_msg({ action: 'tourney_faint_switch',
                               battle_id: @battle_id, party_slot: slot })
      return slot
    else
      until !@opp_switch_queue.empty? || @battle_ended_ext
        Graphics.update; Input.update; NetworkClient.update
      end
      return @battle_ended_ext ? 0 : @opp_switch_queue.shift
    end
  end

  def _send_hp_sync
    hp = @battlers.map { |b| b ? { 'hp' => b.hp } : nil }
    NetworkClient.send_msg({ action: 'tourney_turn_sync', battle_id: @battle_id, hp: hp })
  end

  def _net_after_hp_reduced(battler)
    return if @battle_ended_ext
    if @is_challenger
      NetworkClient.send_msg({ action: 'tourney_hp_update', battle_id: @battle_id,
                               idx: battler.index, hp: battler.hp })
    else
      challenger_idx = battler.index ^ 1
      60.times do
        NetworkClient.update
        update = @hp_update_queue.find { |u| u['idx'].to_i == challenger_idx }
        if update
          @hp_update_queue.delete(update)
          battler.hp = update['hp'].to_i
          break
        end
        Graphics.update; Input.update
      end
    end
  end

  def pbRunMenu(idxBattler)
    return false unless pbConfirmMessage(_INTL("Forfeit this tournament match?"))
    NetworkClient.send_msg({ action: 'tourney_forfeit', battle_id: @battle_id })
    @decision = Battle::Outcome::LOSE
    true
  end

  private

  def _net_check_ext_end
    return false unless @battle_ended_ext
    return false if decided?
    if @lost_connection
      pbDisplayPaused(_INTL("Lost connection to the server."))
      @decision = Battle::Outcome::LOSE
    elsif @tourney_timed_out
      pbDisplayPaused(_INTL("Time's up! The match has ended."))
      # decision determined by server stats — set LOSE as placeholder
      @decision = Battle::Outcome::LOSE
    elsif @tourney_ended
      pbDisplayPaused(_INTL("Match over!"))
      @decision ||= Battle::Outcome::LOSE
    end
    @command_phase = false
    true
  end
end

#===============================================================================
# TCP event handlers
#===============================================================================

NetworkClient.on('tourney_status') do |data|
  NetworkTourney._set_status(data)
end

NetworkClient.on('tourney_signup_response') do |data|
  NetworkTourney._set_signup_result(data)
end

# Incoming match — queue for process_pending
NetworkClient.on('tourney_match') do |data|
  NetworkTourney._set_pending_match(data)
end

# Battle start — queue for process_pending
NetworkClient.on('tourney_battle_start') do |data|
  NetworkTourney._set_pending_start(data)
end

# Show bracket update between matches
NetworkClient.on('tourney_bracket') do |data|
  text = data['text'] || ''
  pbMessage(_INTL("Tournament Bracket:\n{1}", text)) if text.length > 0
end

# Match over
NetworkClient.on('tourney_match_over') do |data|
  result = data['result'] || 'ended'
  winner = data['winner'] || '???'
  if result == 'won'
    pbMessage(_INTL("You won the match!\nYour party will be healed for the next battle."))
  else
    pbMessage(_INTL("You lost the match.\n{1} wins!\nHanging around for the bracket results...", winner))
  end
end

# Heal between matches
NetworkClient.on('tourney_heal') do |data|
  $player.party.each { |p| p.heal if p }
  pbMessage(_INTL("Your Pokemon have been healed for the next round!"))
end

# Tournament complete
NetworkClient.on('tourney_complete') do |data|
  winner = data['winner']   || '???'
  label  = data['prize_label'] || '???'
  if data['you_won']
    pbMessage(_INTL("You won the tournament!\nYou earned: {1}!\nClaim your prize here at the Tournament Host.", label))
    # Prize already added server-side — claim via NPC (auction_claim flow)
  else
    pbMessage(_INTL("Tournament over!\n{1} wins and takes home {2}!\nBetter luck next time!", winner, label))
  end
end

# Disqualified
NetworkClient.on('tourney_disqualified') do |data|
  reason = data['reason'] || 'unknown reason'
  pbMessage(_INTL("You have been disqualified from the tournament!\nReason: {1}", reason))
end

# Frame-update hook — processes pending matches when safe (overworld, not mid-event)
EventHandlers.add(:on_frame_update, :network_tourney_pending,
  proc { NetworkTourney.process_pending if NetworkClient.connected? }
)

#===============================================================================
# BracketTourney(city, prize_type) — called from NPC event script boxes.
#===============================================================================
def BracketTourney(city, prize_type)
  NetworkTourney.show_dialog(city, prize_type)
end

#===============================================================================
# ClaimEventPrizes — standalone prize-claim NPC.
# Place this call in any event script box to let players collect pending prizes
# from tournaments (and auctions — they share the same prize table).
#
#   ClaimEventPrizes()
#
# Shows prize count, asks to claim, delivers items/eggs directly to party/PC.
#===============================================================================
def ClaimEventPrizes
  unless NetworkAuth.logged_in?
    pbMessage(_INTL("You need to be online to claim prizes."))
    return
  end

  # Use the auction module's request/wait flow — it has the working permanent listener.
  NetworkAuction.request_status
  status = NetworkAuction.wait_status
  unless status
    pbMessage(_INTL("Could not reach the server. Try again in a moment."))
    return
  end

  pending_count = status['pending'] || 0

  if pending_count == 0
    pbMessage(_INTL("You have no unclaimed prizes right now.\nWin a tournament or auction to earn prizes!"))
    return
  end

  return unless pbConfirmMessage(_INTL("You have {1} unclaimed prize(s)!\nClaim them now?", pending_count))

  NetworkAuction.request_claim
  data = NetworkAuction.wait_claim
  if data && data['success'] && data['prizes'] && !data['prizes'].empty?
    NetworkAuction._deliver_prizes(data['prizes'])
  else
    pbMessage(_INTL("Could not retrieve prizes. Try again or contact an admin."))
  end
end
