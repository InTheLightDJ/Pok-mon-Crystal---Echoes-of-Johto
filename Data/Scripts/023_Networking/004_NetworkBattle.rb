#===============================================================================
# NetworkBattle — PvP trainer battles over TCP.
#
# DESIGN: lockstep relay with per-turn RNG re-seeding
#   Both clients run the Essentials battle engine.  The server generates a fresh
#   seed each turn and includes it in battle_moves_ready.  Both clients call
#   srand(turn_seed) before attack phase so speed-tie resolution, damage rolls,
#   accuracy, and crits are calculated identically on both screens.
#
#   Sharing a seed only works if both clients start from identical battle
#   conditions, though — prepare_battle (Overworld_BattleStarting.rb) otherwise
#   pulls defaultWeather/defaultTerrain/environment from each player's OWN
#   current map. Two players in different places (e.g. one standing on a
#   permanently sunny route) would silently simulate every move under
#   different conditions from turn one, with nothing ever flagging it as a
#   "desync" since both screens are self-consistent. _run_battle forces
#   weather/terrain/environment to :None before calling prepare_battle so
#   map location can never be a source of divergence.
#
#   After each round BOTH clients send their own view of HP/status to the
#   server (battle_turn_sync) from Battle::NetworkPvP#pbEORSwitch — BEFORE the
#   base engine's pbJudge/fainted-battler switch-in loop runs (see pbEORSwitch
#   below for why the timing matters: syncing any later, e.g. from
#   pbEndOfRoundPhase after switches have already resolved, is too late to
#   stop a Pokémon that only fainted on one screen from leaving that screen's
#   switch-in prompt stuck waiting forever). The server reconciles the two
#   independent reports of each Pokémon — trusting the lower HP and, if
#   statuses disagree, the non-NONE one (see
#   ServerStuff/handlers/battle.js _reconcileAndSendSync) — and relays the
#   agreed-upon truth back to both clients, each in its own battler-index
#   space. If that correction reveals a fainted battler neither screen had
#   caught yet, _wait_for_hp_sync forces it through the real pbFaint pipeline
#   right then. Either screen can drift (e.g. an item/ability effect that
#   computed differently client-side, or a dropped per-move battle_hp_update);
#   this guarantees neither screen can stay wrong for more than one round.
#
#   Every displayed battle message plus a per-round HP/status dump is also
#   written to Data/battle_log.txt on each client (see NetworkBattleLog). The
#   in-game/Discord \issue chat command asks both clients in a battle to
#   upload that file so a dev can diff the two screens after a report.
#
# FLOW:
#   Challenger: NetworkBattle.request_battle
#     1. Pick target from online list
#     2. Send battle_request with own team + trainer sprite
#     3. Wait for battle_start (contains seed, opp team, opp sprite)
#     4. Run Battle::NetworkPvP (is_challenger = true)
#
#   Accepter (passive — no action needed beyond overworld):
#     battle_request arrives → "X wants to battle!" dialog
#     Accept → send battle_accept with own team + trainer sprite
#     Wait for battle_start → run Battle::NetworkPvP (is_challenger = false)
#
# PROTOCOL MESSAGES (client → server):
#   battle_request      { target_username, trainer_sprite, team }
#   battle_accept       { battle_id, trainer_sprite, team }
#   battle_decline      { battle_id }
#   battle_move         { battle_id, move: { action, move_index, target_index } }
#   battle_faint_switch { battle_id, party_slot }
#   battle_turn_sync    { battle_id, hp: [{hp,totalhp,status,name,species,level}, ...] }  ← both sides
#   battle_forfeit      { battle_id }
#   battle_end          { battle_id }
#   battle_log_upload   { battle_id, text }  ← reply to battle_log_request, see NetworkBattleLog
#
# PROTOCOL MESSAGES (server → client):
#   battle_request       { from, battle_id, trainer_sprite, team }
#   battle_pending       { battle_id }
#   battle_start         { battle_id, seed, my_team, opp_team, my_sprite, opp_sprite, opp_name }
#   battle_moves_ready   { my_move, opp_move, turn_seed }
#   battle_opp_switch_result { party_slot }
#   battle_hp_sync       { hp: [{hp,status,...}, ...] } ← both sides; server-reconciled truth,
#                                                          indexed in the recipient's own battler order
#   battle_ended         { reason }
#   battle_error         { message }
#   battle_log_request   { battle_id }  ← sent to both players when either types \issue in chat
#===============================================================================

# Patch Battle::Battler so every HP reduction notifies the network battle.
# Only active inside Battle::NetworkPvP (guarded by respond_to?).
class Battle::Battler
  unless method_defined?(:_net_orig_pbReduceHP)
    alias_method :_net_orig_pbReduceHP, :pbReduceHP
    def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
      result = _net_orig_pbReduceHP(amt, anim, registerDamage, anyAnim)
      @battle._net_after_hp_reduced(self) if @battle.respond_to?(:_net_after_hp_reduced)
      result
    end
  end
end

#===============================================================================
# Battle::NetworkAI — replaces the normal AI for the opponent side.
# Instead of choosing moves algorithmically, it applies whatever choice the
# server relayed from the real player on the other machine.
#===============================================================================
class Battle::NetworkAI < Battle::AI
  # Called by pbCommandPhaseLoop(false) for each opponent battler.
  # The received move is pre-stored in @battle.net_opp_move_pending.
  def pbDefaultChooseEnemyCommand(idxBattler)
    opp = @battle.net_opp_move_pending
    return if opp.nil?
    @battle.net_register_opp_action(idxBattler, opp)
    @battle.net_opp_move_pending = nil
  end

  # After a faint the engine calls this for the opponent side.
  # The actual wait/apply happens in Battle::NetworkPvP#pbSwitchInBetween.
  def pbDefaultChooseNewEnemy(_idxBattler)
    return 0
  end
end

#===============================================================================
# Battle::NetworkPvP — Battle subclass that synchronises each turn over the
# network instead of using the local AI.
#===============================================================================
class Battle::NetworkPvP < Battle
  attr_accessor :net_opp_move_pending, :is_challenger

  def initialize(scene, my_party, opp_party, my_trainers, opp_trainers, battle_id)
    super(scene, my_party, opp_party, my_trainers, opp_trainers)
    @switchStyle          = false  # Set mode: no free switch after KO (ivar used directly by engine)
    @battle_id            = battle_id
    @net_moves_ready      = false
    @net_opp_move_pending = nil
    @current_turn_seed    = nil
    @opp_switch_queue     = []   # queue of party slots from opponent faint-switches
    @battle_ended_ext     = false
    @battle_ended_reason  = nil
    @battle_ended_outcome = nil
    @lost_connection      = false
    @is_challenger        = false   # set by _run_battle before pbStartBattle
    @hp_sync_data         = nil
    @hp_sync_received     = false
    @hp_update_queue      = []     # per-move HP corrections from challenger (opponent only)
    # Override the AI that was just created by super
    @battleAI = Battle::NetworkAI.new(self)
    _register_net_callbacks
  end

  #-----------------------------------------------------------------------------
  # Apply the opponent's received move data into @choices[idxBattler].
  # Called from Battle::NetworkAI#pbDefaultChooseEnemyCommand.
  #-----------------------------------------------------------------------------
  def net_register_opp_action(idxBattler, move_data)
    case move_data['action']
    when 'fight'
      idx = move_data['move_index'].to_i
      pbRegisterMove(idxBattler, idx, false)
      raw = (move_data['target_index'] || -1).to_i
      # The sender's battler layout is the mirror of ours: their battler[0] is their
      # Pokémon (our battler[1]) and vice versa.  XOR 1 maps 0↔1 and 2↔3 so the
      # target resolves to the correct battler on our side.
      @choices[idxBattler][3] = raw >= 0 ? (raw ^ 1) : raw
    when 'switch'
      pbRegisterSwitch(idxBattler, move_data['party_slot'].to_i)
    when 'run'
      # Opponent forfeited mid-turn — treated as disconnect; battle_ended fires
    # 'forced' means the opponent is locked into a multi-turn move;
    # @choices[idxBattler] already holds the forced action from a prior turn.
    end
  end

  #-----------------------------------------------------------------------------
  # Command phase: player picks action → send to server → wait for both →
  # re-seed RNG → AI phase applies received opponent action.
  #-----------------------------------------------------------------------------
  def pbCommandPhase
    @command_phase = true
    @scene.pbBeginCommandPhase
    @battlers.each_with_index { |b, i| pbClearChoice(i) if b && pbCanShowCommands?(i) }
    2.times do |side|
      @megaEvolution[side].each_with_index { |e, i| @megaEvolution[side][i] = -1 if e >= 0 }
    end

    # 1. Player picks their action normally
    pbCommandPhaseLoop(true)
    return (@command_phase = false) if decided?
    return if _net_check_ext_end

    # 2. Send our choice to the server
    _net_send_my_choice

    # 3. Spin until the server confirms both players have submitted
    @net_moves_ready = false
    loop do
      Graphics.update; Input.update; NetworkClient.update
      break if @net_moves_ready
      return if _net_check_ext_end
      if Input.trigger?(Input::BACK)
        next unless pbConfirmMessage(_INTL("Forfeit the battle?"))
        NetworkClient.send_msg({ action: 'battle_forfeit', battle_id: @battle_id })
        @decision      = Battle::Outcome::LOSE
        @command_phase = false
        return
      end
      if Input.trigger?(Input::R)
        next unless pbConfirmMessage(_INTL("Abandon battle?\nBoth players will return to the overworld."))
        NetworkClient.send_msg({ action: 'battle_abandon', battle_id: @battle_id })
        pbDisplayPaused(_INTL("Battle abandoned. Returning to overworld."))
        @battle_ended_reason = 'abandoned'
        @battle_ended_ext    = true
        @decision            = Battle::Outcome::LOSE
        @command_phase       = false
        return
      end
    end

    # 4. Re-seed RNG so speed ties, damage rolls, accuracy, and crits are
    #    calculated identically on both clients this turn.
    srand(@current_turn_seed) if @current_turn_seed

    # 5. Let NetworkAI apply the received opponent move (@net_opp_move_pending)
    pbCommandPhaseLoop(false)

    @command_phase = false
  end

  #-----------------------------------------------------------------------------
  # Logs the post-round board state once end-of-round effects (and any
  # switch-ins — see pbEORSwitch below) have resolved. Purely a diagnostic
  # transcript for the \issue command; the actual desync safety net lives in
  # pbEORSwitch, not here.
  #-----------------------------------------------------------------------------
  def pbEndOfRoundPhase
    super
    NetworkBattleLog.round_summary(@battlers) rescue nil
  end

  #-----------------------------------------------------------------------------
  # Both sides report their own view of HP/status to the server and wait for
  # the reconciled truth back, BEFORE pbJudge/the fainted-battler switch-in
  # loop run (this is what the base class's pbEORSwitch does — see super
  # below). Positioning the sync here, ahead of super, is what guarantees a
  # Pokémon that fainted on only one screen (e.g. from a mid-round item/ability
  # difference, or a dropped per-move battle_hp_update) still gets recognised
  # as fainted on BOTH screens before either client decides whether a switch
  # prompt is needed — not just eventually, next round, once it's too late to
  # matter. See _wait_for_hp_sync for the force-faint half of this.
  #-----------------------------------------------------------------------------
  def pbEORSwitch(favorDraws = false)
    if !@battle_ended_ext && !decided?
      _send_hp_sync
      _wait_for_hp_sync
    end
    super
  end

  #-----------------------------------------------------------------------------
  # Speed-tie tiebreaker fix.
  # Essentials assigns randomOrder[battlerIndex] as the tiebreaker value.  On the
  # challenger's screen battler[0] is the challenger's Pokémon; on the accepter's
  # screen battler[0] is the accepter's Pokémon.  Both clients get the same RNG
  # shuffle, so the same Pokémon would "win" on both screens — but it's battler[0]
  # on each, meaning a different Pokémon each time.  Fix: on the accepter's screen,
  # swap the tiebreaker values for battlers 0 and 1 so the canonical assignment
  # (challenger's Pokémon always gets randomOrder[0]) is honoured on both screens.
  #-----------------------------------------------------------------------------
  def pbCalculatePriority(fullCalc = false, indexArray = nil)
    super(fullCalc, indexArray)
    return unless fullCalc && !@is_challenger
    e0 = @priority.find { |e| e[0].index == 0 }
    e1 = @priority.find { |e| e[0].index == 1 }
    return unless e0 && e1
    e0[6], e1[6] = e1[6], e0[6]
    @priority.sort! do |a, b|
      if    a[5] != b[5] then b[5] <=> a[5]
      elsif a[4] != b[4] then b[4] <=> a[4]
      elsif @priorityTrickRoom then (a[1] == b[1]) ? b[6] <=> a[6] : a[1] <=> b[1]
      else  (a[1] == b[1]) ? b[6] <=> a[6] : b[1] <=> a[1]
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Every displayed battle message (moves used, damage, status, fainting...)
  # also gets captured into Data/battle_log.txt — see NetworkBattleLog and the
  # \issue chat command. Purely observational; behaviour is unchanged.
  #-----------------------------------------------------------------------------
  def pbDisplay(msg, &block)
    NetworkBattleLog.write(msg) rescue nil
    super
  end

  def pbDisplayBrief(msg)
    NetworkBattleLog.write(msg) rescue nil
    super
  end

  def pbDisplayPaused(msg, &block)
    NetworkBattleLog.write(msg) rescue nil
    super
  end

  #-----------------------------------------------------------------------------
  # Switch-in-between (post-faint replacement):
  #   - Own side: show party screen, then report choice to server.
  #   - Opponent side: wait for server to relay the opponent's choice.
  #-----------------------------------------------------------------------------
  def pbSwitchInBetween(idxBattler, checkLaxOnly = false, canCancel = false)
    if pbOwnedByPlayer?(idxBattler)
      slot = pbPartyScreen(idxBattler, checkLaxOnly, canCancel)
      NetworkClient.send_msg({ action: 'battle_faint_switch',
                               battle_id: @battle_id, party_slot: slot })
      return slot
    else
      until !@opp_switch_queue.empty? || @battle_ended_ext
        Graphics.update; Input.update; NetworkClient.update
      end
      if @battle_ended_ext
        @decision = Battle::Outcome::WIN
        return 0
      end
      return @opp_switch_queue.shift
    end
  end

  # Set mode only — no "Would you like to switch?" prompt after a KO.
  def switchStyle; false; end

  # Items are disabled in PvP.
  def pbItemMenu(_idxBattler, _firstAction)
    pbDisplay(_INTL("Items cannot be used in online battles."))
    false
  end

  # Run = forfeit prompt
  def pbRunMenu(_idxBattler)
    return false unless pbConfirmMessage(_INTL("Forfeit the battle?"))
    NetworkClient.send_msg({ action: 'battle_forfeit', battle_id: @battle_id })
    @decision = Battle::Outcome::LOSE
    true
  end

  # Clean up callbacks when battle finishes (called by _run_battle).
  def net_cleanup
    NetworkClient.off('battle_moves_ready')
    NetworkClient.off('battle_opp_switch_result')
    NetworkClient.off('battle_ended')
    NetworkClient.off('disconnected')
    NetworkClient.off('battle_hp_sync')
    NetworkClient.off('battle_hp_update')
  end

  private

  def _register_net_callbacks
    NetworkClient.on('battle_moves_ready') do |d|
      @current_turn_seed    = d['turn_seed']
      @net_opp_move_pending = d['opp_move']
      @net_moves_ready      = true
    end
    NetworkClient.on('battle_opp_switch_result') { |d| @opp_switch_queue << d['party_slot'].to_i }
    NetworkClient.on('battle_ended')             { |d| @battle_ended_reason = d['reason']; @battle_ended_outcome = d['outcome']; @battle_ended_ext = true }
    NetworkClient.on('disconnected')             { |_| @lost_connection = true; @battle_ended_ext = true }
    NetworkClient.on('battle_hp_sync')           { |d| @hp_sync_data = d['hp']; @hp_sync_received = true }
    NetworkClient.on('battle_hp_update')         { |d| @hp_update_queue << d }
  end

  # Returns true (and sets @decision) if the battle ended externally.
  def _net_check_ext_end
    return false unless @battle_ended_ext
    return false if decided?  # already handled (e.g. we initiated the abandon)
    if @battle_ended_outcome == 'void'
      # Sent by the admin ForceBattleEnd(name) command — Battle::Outcome::DRAW
      # so _run_battle's win/lose check below is skipped and neither side's
      # pvp_result gets sent; this must stay neutral for both recipients.
      pbDisplayPaused(_INTL(@battle_ended_reason || "This battle has been ended."))
      @decision = Battle::Outcome::DRAW
    elsif @battle_ended_outcome
      # Sent only by the server's per-turn timeout path (King of the Hill
      # forced fights) — reason text is already worded for this recipient.
      pbDisplayPaused(_INTL(@battle_ended_reason || "The battle has ended."))
      @decision = (@battle_ended_outcome == 'win') ? Battle::Outcome::WIN : Battle::Outcome::LOSE
    elsif @lost_connection
      pbDisplayPaused(_INTL("Lost connection to the server."))
      @decision = Battle::Outcome::LOSE
    elsif @battle_ended_reason == 'abandoned'
      pbDisplayPaused(_INTL("Battle abandoned. Returning to overworld."))
      @decision = Battle::Outcome::LOSE
    else
      pbDisplayPaused(_INTL("Your opponent disconnected. You win!"))
      @decision = Battle::Outcome::WIN
    end
    @command_phase = false
    true
  end

  # Serialise @choices[0] into a compact hash for the network.
  def _net_send_my_choice
    c = @choices[0]
    data = case c[0]
    when :UseMove   then { 'action' => 'fight',  'move_index'  => c[1], 'target_index' => c[3] }
    when :SwitchOut then { 'action' => 'switch', 'party_slot'  => c[1] }
    when :Run       then { 'action' => 'run' }
    else                 { 'action' => 'forced' }
    end
    NetworkClient.send_msg({ action: 'battle_move', battle_id: @battle_id, move: data })
  end

  # Send our own view of HP/status to the server after each round for
  # reconciliation against the other side's report (see _wait_for_hp_sync).
  # totalhp/name/species/level ride along purely for admin battle-spectating
  # (see ServerStuff/handlers/battle.js handleTurnSync + registerSpectator) —
  # the server caches and mirrors this whole payload to any watching admin.
  def _send_hp_sync
    hp = @battlers.map { |b|
      next nil unless b
      {
        'hp'      => b.hp,
        'totalhp' => b.totalhp,
        'status'  => b.status.to_s,
        'name'    => b.name,
        'species' => b.species.to_s,
        'level'   => b.level
      }
    }
    NetworkClient.send_msg({ action: 'battle_turn_sync', battle_id: @battle_id, hp: hp })
  end

  # Wait for the server's reconciled HP/status (already translated into our
  # own battler-index order — see _reconcileAndSendSync server-side) and
  # apply it, correcting any drift between what we computed locally and what
  # the other client computed. If the correction reveals a battler that's now
  # fainted but wasn't recognised as such locally, force it through the real
  # pbFaint pipeline right now — before returning to pbEORSwitch's caller,
  # which is about to judge/switch based on exactly this fainted? state.
  def _wait_for_hp_sync
    @hp_sync_received = false
    300.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @hp_sync_received || @battle_ended_ext
    end
    if @battle_ended_ext || !@hp_sync_data
      NetworkBattleLog.note("Round sync timed out waiting for the server.") if !@battle_ended_ext && !@hp_sync_received rescue nil
      return
    end
    @hp_sync_data.each_with_index do |data, i|
      next unless data
      b = @battlers[i]
      next unless b
      was_fainted = b.fainted?
      new_hp = data['hp'].to_i
      if b.hp != new_hp
        NetworkBattleLog.note("HP desync corrected: #{b.name} #{b.hp} -> #{new_hp}") rescue nil
        b.hp = new_hp
      end
      new_status = (data['status'] || 'NONE').to_s.to_sym
      if b.status != new_status
        NetworkBattleLog.note("Status desync corrected: #{b.name} #{b.status} -> #{new_status}") rescue nil
        b.status = new_status
      end
      if !was_fainted && b.fainted?
        NetworkBattleLog.note("#{b.name} fainted on the other screen but not locally — forcing faint now.") rescue nil
        b.pbFaint
      end
    end
    @hp_sync_data     = nil
    @hp_sync_received = false
  end

  # Called from the Battle::Battler patch after every pbReduceHP.
  # Challenger: relay authoritative HP to the opponent immediately.
  # Opponent:   block briefly and apply challenger's value before faint detection runs.
  def _net_after_hp_reduced(battler)
    return if @battle_ended_ext
    if @is_challenger
      NetworkClient.send_msg({
        action:    'battle_hp_update',
        battle_id: @battle_id,
        idx:       battler.index,
        hp:        battler.hp
      })
    else
      challenger_idx = battler.index ^ 1
      update = nil
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
      if !update
        NetworkBattleLog.note("Per-move HP update from challenger timed out for #{battler.name} — relying on next round's sync.") rescue nil
      end
    end
  end
end

#===============================================================================
# NetworkBattle — module that manages the full PvP challenge/accept flow and
# spawns Battle::NetworkPvP once both players are ready.
#===============================================================================
module NetworkBattle
  @pending_request = nil
  @battle_id       = nil

  def self.active?
    !@battle_id.nil?
  end

  #-----------------------------------------------------------------------------
  # Called every frame by the on_frame_update hook.
  # Shows an incoming challenge dialog when safe (overworld, not busy).
  #-----------------------------------------------------------------------------
  def self.process_pending
    return unless @pending_request && !@battle_id
    return if _busy?
    req = @pending_request
    @pending_request = nil
    _handle_incoming(req)
  end

  #-----------------------------------------------------------------------------
  # Challenger side: pick target → wait for accept → run battle
  #-----------------------------------------------------------------------------
  def self.request_battle(target_username = nil)
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to battle."))
      return
    end

    if target_username.nil?
      players = _fetch_online_players
      if players.empty?
        pbMessage(_INTL("No other players are online right now."))
        return
      end
      target_username = _select_player(players)
      return unless target_username
    end

    # Send challenge with our team and trainer sprite
    NetworkClient.send_msg({
      action:          'battle_request',
      target_username: target_username,
      trainer_sprite:  $player.trainer_type.to_s,
      team:            _serialize_team($player.party)
    })

    # Wait for server ack
    pending_result = nil
    NetworkClient.on('battle_pending') { |d| @battle_id = d['battle_id']; pending_result = :ok }
    NetworkClient.on('battle_error')   { |d| pending_result = d['message'] }
    200.times { Graphics.update; Input.update; NetworkClient.update; break if pending_result }
    NetworkClient.off('battle_pending')
    NetworkClient.off('battle_error')

    unless pending_result == :ok
      pbMessage(_INTL(pending_result.is_a?(String) ? pending_result : "No response from server."))
      _reset; return
    end

    # Wait for the opponent to accept / for battle_start / battle_ended
    battle_data   = nil
    cancel_reason = nil
    NetworkClient.on('battle_start')  { |d| battle_data   = d }
    NetworkClient.on('battle_ended')  { |d| cancel_reason = d['reason'] }

    timed_out = true
    1800.times do
      Graphics.update; Input.update; NetworkClient.update
      if battle_data || cancel_reason; timed_out = false; break; end
      if Input.trigger?(Input::BACK)
        NetworkClient.send_msg({ action: 'battle_forfeit', battle_id: @battle_id })
        cancel_reason = 'You cancelled'; timed_out = false; break
      end
    end
    NetworkClient.off('battle_start')
    NetworkClient.off('battle_ended')

    unless battle_data
      pbMessage(_INTL(timed_out ? "{1} did not respond." : "Battle cancelled: {1}",
                      timed_out ? target_username : (cancel_reason || 'Unknown')))
      _reset; return
    end

    _run_battle(battle_data, true)  # is_challenger = true
  end

  #-----------------------------------------------------------------------------
  # Background listener stores incoming challenges for process_pending.
  # Immediately declines if the player is busy so the challenger gets a clear
  # message instead of waiting for the server timeout.
  #-----------------------------------------------------------------------------
  def self._store_request(data)
    return if @battle_id
    if _busy?
      NetworkClient.send_msg({ action: 'battle_decline', battle_id: data['battle_id'], reason: 'busy' })
    else
      @pending_request = data
    end
  end

  private

  #-----------------------------------------------------------------------------
  # Returns true when the player cannot safely receive a battle dialog right now.
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
  # Accepter flow: show dialog, accept/decline, then wait for battle_start
  #-----------------------------------------------------------------------------
  def self._handle_incoming(req)
    if req['forced']
      # King of the Hill title challenge — the reigning king cannot decline.
      pbMessage(_INTL("{1} challenges you for the King of the Hill title!\nYou must defend the crown!", req['from']))
    else
      response = pbMessage(
        _INTL("{1} wants to battle!", req['from']),
        [_INTL("Accept"), _INTL("Decline")], 2
      )

      if response != 0
        NetworkClient.send_msg({ action: 'battle_decline', battle_id: req['battle_id'] })
        return
      end
    end

    @battle_id = req['battle_id']
    NetworkClient.send_msg({
      action:         'battle_accept',
      battle_id:      @battle_id,
      trainer_sprite: $player.trainer_type.to_s,
      team:           _serialize_team($player.party)
    })

    # Wait for battle_start from server
    battle_data   = nil
    cancel_reason = nil
    NetworkClient.on('battle_start')  { |d| battle_data   = d }
    NetworkClient.on('battle_ended')  { |d| cancel_reason = d['reason'] }
    1800.times do
      Graphics.update; Input.update; NetworkClient.update
      break if battle_data || cancel_reason
    end
    NetworkClient.off('battle_start')
    NetworkClient.off('battle_ended')

    unless battle_data
      pbMessage(_INTL("Battle cancelled: {1}", cancel_reason || 'Timeout'))
      _reset; return
    end

    _run_battle(battle_data, false)  # is_challenger = false
  end

  #-----------------------------------------------------------------------------
  # Build and run the actual Essentials battle
  #-----------------------------------------------------------------------------
  def self._run_battle(data, is_challenger)
    battle_id  = data['battle_id']
    seed       = data['seed'].to_i
    opp_name   = data['opp_name']   || 'Challenger'
    opp_sprite = data['opp_sprite'] || 'POKEMONTRAINER_1'

    # Initial seed syncs the very first turn; per-turn re-seeding handles the rest
    srand(seed)

    # Build the opponent trainer object
    opp_sym  = opp_sprite.to_sym
    opp_sym  = :POKEMONTRAINER_1 unless GameData::TrainerType.exists?(opp_sym)
    opp_trainer       = NPCTrainer.new(opp_name, opp_sym)
    opp_trainer.party = (data['opp_team'] || []).filter_map { |d| NetworkTrade.deserialize_pokemon(d) }

    if opp_trainer.party.empty?
      pbMessage(_INTL("Could not load {1}'s team data.", opp_name))
      _reset; return
    end

    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers(opp_trainer.party)
    # PvP is link-cable style: deep-copy the player's party so HP/PP damage
    # during the battle doesn't persist on the overworld Pokémon, and so that
    # a second battle attempt never fails with "trainers 0v1" (fainted party).
    player_party = player_party.map { |p| p ? Marshal.load(Marshal.dump(p)) : nil }

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle::NetworkPvP.new(
      scene, player_party, opp_trainer.party,
      player_trainers, [opp_trainer],
      battle_id
    )
    battle.is_challenger  = is_challenger
    battle.party1starts   = party_starts
    battle.party2starts   = [0]
    battle.ally_items     = ally_items
    battle.items          = []
    battle.internalBattle = true
    battle.expGain        = false
    battle.moneyGain      = false

    setBattleRule("single") if $game_temp.battle_rules["size"].nil?
    # PvP battles must simulate identically on both clients, but prepare_battle
    # (called below) otherwise pulls defaultWeather/defaultTerrain/environment
    # from THIS player's own current map (see Overworld_BattleStarting.rb) —
    # each client sets these independently from wherever it happens to be
    # standing. Two players on different maps (e.g. one on a permanently
    # sunny route, one not) would then silently simulate the same moves under
    # different conditions forever after (Fire moves boosted on only one
    # screen, etc.), with no round ever flagging as a "desync" since both
    # sides genuinely believe their own calculation is correct. Forcing
    # neutral conditions here removes map location as a source of divergence.
    setBattleRule("weather", :None)      if $game_temp.battle_rules["defaultWeather"].nil?
    setBattleRule("terrain", :None)      if $game_temp.battle_rules["defaultTerrain"].nil?
    setBattleRule("environment", :None)  if $game_temp.battle_rules["environment"].nil?
    BattleCreationHelperMethods.prepare_battle(battle)
    battle.switchStyle = false  # prepare_battle overwrites from player Options; force Set mode for PvP
    $game_temp.clear_battle_rules

    NetworkBattleLog.start(NetworkAuth.username, opp_name, player_party, opp_trainer.party) rescue nil

    bgm = pbGetTrainerBattleBGM([opp_trainer])
    pbBattleAnimation(bgm, 1, [opp_trainer]) do
      pbSceneStandby { battle.pbStartBattle }
    end

    battle.net_cleanup

    # Reported so the server can resolve King of the Hill title changes;
    # ordinary battles simply ignore this field.
    winner_username = if battle.decision == Battle::Outcome::WIN
      NetworkAuth.username
    elsif battle.decision == Battle::Outcome::LOSE
      opp_name
    end

    result_text = case battle.decision
                  when Battle::Outcome::WIN  then "won"
                  when Battle::Outcome::LOSE then "lost"
                  else "undecided (#{battle.decision})"
                  end
    NetworkBattleLog.close(result_text) rescue nil

    NetworkClient.send_msg({ action: 'battle_end', battle_id: battle_id, winner: winner_username })
    if battle.decision == Battle::Outcome::WIN
      NetworkClient.send_msg({ action: 'pvp_result', won: true })
    elsif battle.decision == Battle::Outcome::LOSE
      NetworkClient.send_msg({ action: 'pvp_result', won: false })
    end
    _reset
  end

  #-----------------------------------------------------------------------------
  # Helpers
  #-----------------------------------------------------------------------------
  def self._fetch_online_players
    players = nil; king = nil; done = false
    NetworkClient.on('players_list') { |d| players = d['players']; king = d['king']; done = true }
    NetworkClient.send_msg({ action: 'players_list' })
    200.times { Graphics.update; Input.update; NetworkClient.update; break if done }
    NetworkClient.off('players_list')
    @_last_king = king
    players || []
  end

  def self._select_player(players)
    # Choice-list windows draw plain text (no \c[n] color parsing like message
    # boxes get), so the king is marked with a plain-text tag instead of color.
    cmds = players.map { |p| (@_last_king && p.casecmp?(@_last_king)) ? "[KING] #{p}" : p }
    cmds << _INTL("Cancel")
    choice = pbMessage(_INTL("Who do you want to battle?"), cmds, cmds.length)
    return nil if choice < 0 || choice == players.length
    players[choice]
  end

  def self._serialize_team(party)
    party.filter_map { |p| p && !p.egg? ? NetworkTrade.serialize_pokemon(p) : nil }
  end

  def self._reset
    @battle_id       = nil
    @pending_request = nil
  end
end

#-------------------------------------------------------------------------------
# Persistent background listener — queues incoming battle requests so they can
# be shown by process_pending without requiring an open waiting room.
#-------------------------------------------------------------------------------
NetworkClient.on('battle_request') { |d| NetworkBattle._store_request(d) }

EventHandlers.add(:on_frame_update, :network_battle_incoming,
  proc { NetworkBattle.process_pending if NetworkClient.connected? }
)
