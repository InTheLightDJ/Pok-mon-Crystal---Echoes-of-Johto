#===============================================================================
# NetworkMiniBoss — visible Gen 1-2 "Mini Boss" wild encounters on early routes.
#
# Same overall shape as the regular World Boss (023_Networking/012_NetworkBoss.rb)
# — a shared-HP overworld encounter that appears as a follower-sprite Pokémon
# you walk into — but there can be up to 7 of these active at once (one per
# route), so state here is keyed by a per-spawn id instead of a single set of
# flat @-variables. Reuses 012_NetworkBoss.rb's BOSS_BANNED_HEALING_MOVES /
# BOSS_BANNED_PLAYER_MOVES constants directly (same banned-move policy).
#
# Never catchable, at any HP — pbThrowPokeBall always refuses, same as the
# Creepy Pasta boss (023_Networking/027_NetworkCreepyBoss.rb).
#===============================================================================

MINI_BOSS_MAX_DAMAGE_PER_ROUND = 1000   # must match MAX_DAMAGE_PER_HIT in handlers/miniboss.js

#===============================================================================
# Battle::MiniBossEncounter — Battle subclass for a Mini Boss fight.
#===============================================================================
class Battle::MiniBossEncounter < Battle
  attr_reader :boss_id

  # local_max_hp : this specific spawn's max HP (already route/shiny-scaled server-side)
  def initialize(scene, player_party, boss_party, player_trainers, local_max_hp, boss_id)
    super(scene, player_party, boss_party, player_trainers, nil)
    @boss_id          = boss_id
    @local_max_hp     = local_max_hp.to_f
    @hp_before_turn   = nil
    @sync_received    = false
    @sync_data        = nil
    @boss_cleared_ext = false
    @struggle_warned  = false
    @_boss_faint_guard = false
    _register_callbacks
  end

  def pbCommandPhase
    _warn_if_boss_out_of_pp
    super
  end

  # Never catchable, at any HP.
  def pbThrowPokeBall(idxBattler, ball, critChance = nil, showAnimation = true)
    pbDisplay(_INTL("This Pokémon shrugs off the Poké Ball entirely. It can't be caught."))
  end

  def pbCanChooseMove?(idxBattler, idxMove, showMessages, *args)
    if idxBattler == 0
      move = @battlers[idxBattler]&.moves&.[](idxMove)
      if move && BOSS_BANNED_PLAYER_MOVES.include?(move.id)
        pbDisplay(_INTL("The mini boss is immune to that move!")) if showMessages
        return false
      end
    end
    super(idxBattler, idxMove, showMessages, *args)
  end

  def pbAttackPhase
    boss_bat = @battlers[1]
    @hp_before_turn = boss_bat ? boss_bat.hp : 0
    super
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp > 0 && @hp_before_turn.to_i > 0
      drop = @hp_before_turn.to_i - boss_bat.hp
      if drop > MINI_BOSS_MAX_DAMAGE_PER_ROUND
        pbDisplay(_INTL("The mini boss resisted the attack's full force!"))
        boss_bat.hp = [@hp_before_turn.to_i - MINI_BOSS_MAX_DAMAGE_PER_ROUND, 1].max
      end
    end
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp == 0 && (@hp_before_turn || 0) > 0
      damage_global   = [@hp_before_turn.to_i, MINI_BOSS_MAX_DAMAGE_PER_ROUND].min
      NetworkClient.send_msg({ action: 'mini_boss_damage', id: @boss_id, damage: damage_global })
      @hp_before_turn = 0
    end
  end

  def pbEndOfRoundPhase
    boss_bat = @battlers[1]
    if boss_bat
      if [:POISON, :BURN].include?(boss_bat.status)
        boss_bat.status      = :NONE
        boss_bat.statusCount = 0
      end
      begin
        boss_bat.effects[PBEffects::LeechSeed] = -1
        boss_bat.effects[PBEffects::Curse]     = false
        boss_bat.effects[PBEffects::Trapping]  = 0
      rescue StandardError
      end
    end
    begin
      if [:Sandstorm, :Hail].include?(@field.weather)
        @field.weather         = :None
        @field.weatherDuration = 0
      end
    rescue StandardError
    end

    @_eor_boss_hp = boss_bat ? boss_bat.hp : nil
    super
    return if @boss_cleared_ext
    boss_bat = @battlers[1]
    return unless boss_bat

    boss_bat.hp = @_eor_boss_hp if @_eor_boss_hp && boss_bat.hp < @_eor_boss_hp

    damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
    if damage_local > MINI_BOSS_MAX_DAMAGE_PER_ROUND
      pbDisplay(_INTL("The mini boss resisted the attack's full force!"))
      boss_bat.hp  = [(@hp_before_turn || 0) - MINI_BOSS_MAX_DAMAGE_PER_ROUND, 1].max
      damage_local = MINI_BOSS_MAX_DAMAGE_PER_ROUND
    end

    _sync_with_server(damage_local, boss_bat)
    @hp_before_turn = boss_bat.hp
  end

  # Read by the shared Battle::Battler#pbReduceHP patch in 012_NetworkBoss.rb.
  def boss_hit_cap
    MINI_BOSS_MAX_DAMAGE_PER_ROUND
  end

  # Read by the shared Battle::Battler#pbFaint patch in 012_NetworkBoss.rb.
  def _boss_faint_guard_active?
    @_boss_faint_guard == true
  end

  # See the matching method on Battle::BossEncounter (012_NetworkBoss.rb) for
  # the full rationale — verifies with the server before letting the boss
  # actually be declared fainted, reviving its local hp if the shared pool
  # (kept in sync across every player currently fighting it) disagrees. This
  # is exactly the Kadabra case reported: the boss's own forced Struggle
  # recoiled on itself once its true hp was already below the per-hit cap,
  # locally zeroing it out while the server's copy still had HP left.
  def _boss_verify_before_faint(boss_bat)
    damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
    damage_local = [damage_local, MINI_BOSS_MAX_DAMAGE_PER_ROUND].min
    damage_local = 1 if damage_local < 1 && (@hp_before_turn || 0) > 0

    @_boss_faint_guard = true
    _sync_with_server(damage_local, boss_bat)
    @_boss_faint_guard = false

    if boss_bat.hp > 0
      @hp_before_turn = boss_bat.hp
      pbDisplay(_INTL("The mini boss shrugs off the blow and remains standing!"))
    end
  end

  def net_cleanup
    NetworkClient.remove('mini_boss_hp_update', @_hp_cb)
    NetworkClient.remove('mini_boss_cleared',   @_cl_cb)
  end

  private

  def _boss_out_of_pp?
    boss_bat = @battlers[1]
    return false unless boss_bat && !boss_bat.fainted?
    real_moves = boss_bat.moves.compact
    return false if real_moves.empty?
    real_moves.all? { |m| m.total_pp > 0 && m.pp <= 0 }
  end

  def _warn_if_boss_out_of_pp
    return if @struggle_warned
    return unless _boss_out_of_pp?
    @struggle_warned = true
    pbDisplay(_INTL("The mini boss has no PP left and will Struggle!\nIts recoil could make it faint here — consider retreating and coming back for a fresh fight."))
  end

  # Only reacts to updates/clears for THIS specific spawn — other Mini Bosses
  # may be actively fought by other players at the same time.
  def _register_callbacks
    @_hp_cb = NetworkClient.on('mini_boss_hp_update') do |d|
      next unless d['id'] == @boss_id
      @sync_data     = d
      @sync_received = true
    end
    @_cl_cb = NetworkClient.on('mini_boss_cleared') do |d|
      next unless d['id'] == @boss_id
      @boss_cleared_ext = true
      @sync_received    = true
      @sync_data        = { 'hp' => 0, 'max_hp' => @local_max_hp.to_i, 'others_damage' => 0 }
    end
  end

  def _sync_with_server(damage_global, boss_bat)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: 'mini_boss_damage', id: @boss_id, damage: damage_global })

    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    return unless @sync_data

    new_global = @sync_data['hp'].to_i
    others     = @sync_data['others_damage'].to_i
    NetworkMiniBoss.set_hp(@boss_id, new_global)

    old_local = boss_bat.hp
    boss_bat.hp = new_global
    @scene.pbHPChanged(boss_bat, old_local) if old_local != new_global

    @sync_data     = nil
    @sync_received = false

    if new_global == 0
      boss_bat.pbFaint(false)
      pbDisplay(_INTL("The mini boss was brought down!")) unless decided?
      pbJudge
      return
    end

    pbDisplay(_INTL("Other trainers dealt {1} damage to it!", others)) if others > 0
  end
end

#===============================================================================
# NetworkMiniBoss — module managing every active spawn, their overworld
# sprites, and starting battles.
#===============================================================================
module NetworkMiniBoss
  @bosses = {}   # id => { species:, shiny:, map_id:, x:, y:, hp:, max_hp:, location_name:, char_obj:, char_sprite:, battle_triggered: }

  def self.known?(id)
    @bosses.key?(id)
  end

  def self.set_hp(id, hp)
    b = @bosses[id]
    return unless b
    b[:hp] = [hp.to_i, 0].max
  end

  # ── Called from on_frame_update ───────────────────────────────────────────────
  def self.tick
    return unless NetworkAuth.logged_in?
    return if $scene.is_a?(Battle::Scene)
    @bosses.each_value do |b|
      if $game_map&.map_id != b[:map_id]
        _destroy_sprite(b)
        next
      end
      _update_sprite(b)
    end
    _check_trigger
  end

  def self.activate(data)
    id = data['id'].to_s
    return if id.empty?
    b = (@bosses[id] ||= {})
    b[:id]               = id
    b[:species]           = data['species'].to_s
    b[:shiny]             = data['shiny'] == true
    b[:map_id]            = data['map_id'].to_i
    b[:x]                 = data['x'].to_i
    b[:y]                 = data['y'].to_i
    b[:hp]                = (data['hp'] || data['max_hp']).to_i
    b[:max_hp]            = data['max_hp'].to_i
    b[:location_name]     = data['name'].to_s
    b[:battle_triggered]  = false
    _rebuild_sprite(b) if $game_map&.map_id == b[:map_id]
  end

  def self.deactivate(id)
    b = @bosses.delete(id.to_s)
    _destroy_sprite(b) if b
  end

  # Wholesale replace — used for the login/map-catch-up 'mini_boss_list' reply.
  def self.set_all(list)
    @bosses.each_value { |b| _destroy_sprite(b) }
    @bosses = {}
    (list || []).each { |d| activate(d) }
  end

  def self.on_map_enter(map_id)
    @bosses.each_value { |b| _destroy_sprite(b) }
    @bosses.each_value { |b| _rebuild_sprite(b) if b[:map_id] == map_id }
  end

  private

  def self._check_trigger
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?
    px = $game_player.x
    py = $game_player.y
    cur_map = $game_map&.map_id
    @bosses.each_value do |b|
      next unless b[:map_id] == cur_map
      if px == b[:x] && py == b[:y] && !b[:battle_triggered]
        b[:battle_triggered] = true
        _start_boss_battle(b)
      elsif px != b[:x] || py != b[:y]
        b[:battle_triggered] = false
      end
    end
  end

  def self._start_boss_battle(b)
    unless $player.party.compact.any? { |p| p.hp > 0 }
      pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
      return
    end

    # Register as a participant before anything else — this is what makes us
    # eligible for the drop/token/rank rewards when the boss goes down, and
    # gives us the authoritative current HP (it may already have been chipped
    # by other players since our last local update).
    result = nil
    NetworkClient.on('mini_boss_engage') { |d| result = d }
    NetworkClient.send_msg({ action: 'mini_boss_found', id: b[:id], species: b[:species], map_id: b[:map_id] })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('mini_boss_engage')

    unless result
      pbMessage(_INTL("Couldn't reach the server. Try again in a moment."))
      return
    end
    b[:hp]     = result['hp'].to_i
    b[:max_hp] = result['max_hp'].to_i

    level = ($player.party.compact.map(&:level).max || 5).clamp(5, 100)
    species_sym = b[:species].to_sym
    unless GameData::Species.exists?(species_sym)
      puts "[MiniBoss] Unknown species: #{b[:species]}"
      return
    end

    boss = Pokemon.new(species_sym, level)
    _clean_boss_moveset(boss)
    boss.instance_variable_set(:@totalhp, b[:max_hp])
    local_max_hp = b[:max_hp].to_f
    boss.hp = [b[:hp], 1].max

    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers([boss])

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle::MiniBossEncounter.new(
      scene, player_party, [boss], player_trainers, local_max_hp, b[:id]
    )
    battle.party1starts   = party_starts
    battle.party2starts   = [0]
    battle.ally_items     = ally_items
    battle.items          = []
    battle.internalBattle = true
    battle.expGain        = true
    battle.moneyGain      = false

    setBattleRule("single") if $game_temp.battle_rules["size"].nil?
    BattleCreationHelperMethods.prepare_battle(battle)
    $game_temp.clear_battle_rules

    begin
      bgm = pbGetWildBattleBGM([boss])
    rescue StandardError
      bgm = $data_system.battle_bgm
    end

    EventHandlers.trigger(:on_start_battle)

    outcome = Battle::Outcome::UNDECIDED
    pbBattleAnimation(bgm, 0, [boss]) do
      pbSceneStandby { outcome = battle.pbStartBattle }
      BattleCreationHelperMethods.after_battle(outcome, false)
    end

    battle.net_cleanup

    # If our own battle brought it down, the 'mini_boss_cleared' broadcast may
    # have arrived while our battle-scoped listener had shadowed the outer
    # persistent one (same reentrancy note as NetworkBoss._start_boss_battle
    # in 012_NetworkBoss.rb) — deactivate manually here as a fallback.
    NetworkMiniBoss.deactivate(b[:id]) if boss.hp == 0
  end

  def self._clean_boss_moveset(boss)
    return unless boss.moves.is_a?(Array)
    fallback = GameData::Move.exists?(:EXTREMESPEED) ? :EXTREMESPEED : :TACKLE
    boss.moves.each_with_index do |move, i|
      next unless move && BOSS_BANNED_HEALING_MOVES.include?(move.id)
      boss.moves[i] = Pokemon::Move.new(fallback)
    end
  end

  # No shiny follower art exists yet for any species — this falls back
  # gracefully (identical to the non-shiny sprite) until shiny variants are
  # ever added under the same "Followers/<SPECIES>" convention.
  def self._rebuild_sprite(b)
    _destroy_sprite(b)
    return unless b[:species]
    data = {
      'x' => b[:x], 'y' => b[:y], 'direction' => 2,
      'character_name' => "Followers/#{b[:species]}", 'character_hue' => 0,
    }
    b[:char_obj] = OtherPlayerCharacter.new(data)
    vp = Spriteset_Map.viewport
    return unless vp
    b[:char_sprite] = Sprite_Character.new(vp, b[:char_obj])
  end

  def self._destroy_sprite(b)
    return unless b
    b[:char_sprite]&.dispose
    b[:char_sprite] = nil
    b[:char_obj]    = nil
  end

  def self._update_sprite(b)
    return unless b[:char_sprite] && !b[:char_sprite].disposed?
    b[:char_sprite].update
  end
end

#===============================================================================
# Server event handlers
#===============================================================================

# A new Mini Boss spawned — only announce if we didn't already know about it
# (map-change/login catch-up resends this same event but shouldn't re-announce).
NetworkClient.on('mini_boss_spawn') do |d|
  id     = d['id'].to_s
  is_new = !NetworkMiniBoss.known?(id)
  NetworkMiniBoss.activate(d)
  if is_new && $scene.is_a?(Scene_Map)
    species_name = d['species'].to_s.capitalize
    loc_name     = d['name'] || 'a nearby route'
    lead_in      = (d['shiny'] == true) ? "✨ A shiny" : "A"
    pbMessage(_INTL("{1} {2} has appeared at {3}!", lead_in, species_name, loc_name))
  end
end

# Full active-list response — sent on login and doesn't announce anything.
NetworkClient.on('mini_boss_list') do |d|
  NetworkMiniBoss.set_all(d['bosses'])
end

# Defeated (by anyone) or despawned unfought — remove the overworld sprite.
NetworkClient.on('mini_boss_cleared') do |d|
  NetworkMiniBoss.deactivate(d['id'])
end

#===============================================================================
# Hooks
#===============================================================================
EventHandlers.add(:on_enter_map, :network_mini_boss_enter,
  proc { |map_id| NetworkMiniBoss.on_map_enter(map_id) if NetworkAuth.logged_in? }
)

EventHandlers.add(:on_frame_update, :network_mini_boss_tick,
  proc { NetworkMiniBoss.tick if NetworkClient.connected? }
)
