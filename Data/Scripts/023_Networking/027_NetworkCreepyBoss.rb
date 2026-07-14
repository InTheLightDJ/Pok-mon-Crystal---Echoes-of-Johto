#===============================================================================
# NetworkCreepyBoss — invisible, uncatchable "creepypasta" World Boss variant
# (Buried Alive / Dark Mew / Fossel / Fossil / Missigno / Ghost).
#
# Spawns silently like a Mythical (see 013_NetworkMythical.rb) — no overworld
# sprite, just a map/tile that triggers a battle on step-in — rather than the
# visible-sprite pattern the regular World Boss uses (012_NetworkBoss.rb).
#
# HP is shared/global like the regular World Boss (500,000 here vs. 20,000),
# scaled the same way for display, and synced with the server after every
# round. Reuses the regular World Boss's banned-move lists (see
# BOSS_BANNED_HEALING_MOVES / BOSS_BANNED_PLAYER_MOVES in 012_NetworkBoss.rb)
# since it should behave "just like the world bosses we already have" there.
#
# Key differences from the regular World Boss:
#   • Never catchable, under any HP — pbThrowPokeBall always refuses.
#   • Once a player has fought this spawn, they can't fight it again until it
#     despawns/respawns (server-enforced via creepy_boss_already_challenged).
#   • Moveset isn't the species' natural learnset — the server picks 3 random
#     moves from the custom creepy-boss move pool plus 1 random Ghost/Psychic
#     move at spawn time, and sends the exact 4 move IDs to use.
#   • Max single-hit damage is capped at 500 (vs. 3,000 for the regular boss).
#===============================================================================

CREEPY_BOSS_GLOBAL_MAX_HP = 500_000
CREEPY_BOSS_MAX_DAMAGE_PER_HIT = 500

#===============================================================================
# Battle::CreepyBossEncounter — Battle subclass for the creepy boss fight.
#===============================================================================
class Battle::CreepyBossEncounter < Battle
  # Set the moment the server confirms THIS player's own hit was the one that
  # brought the shared HP pool to 0 (see _register_callbacks below) — the
  # Pokémon that was this player's active battler at that instant. Read by
  # NetworkCreepyBoss._start_battle once the battle scene has closed, to check
  # Ghost's kill-triggered evolution into Ghostly (evolution scenes shouldn't
  # run stacked inside an active battle scene).
  attr_reader :kill_evolution_pkmn

  def initialize(scene, player_party, boss_party, player_trainers, local_max_hp)
    super(scene, player_party, boss_party, player_trainers, nil)
    @local_max_hp   = local_max_hp.to_f
    @scale          = CREEPY_BOSS_GLOBAL_MAX_HP / @local_max_hp
    @hp_before_turn = nil
    @sync_received  = false
    @sync_data      = nil
    @boss_cleared_ext     = false
    @kill_evolution_pkmn  = nil
    _register_callbacks
  end

  # Never catchable, at any HP.
  def pbThrowPokeBall(idxBattler, ball, critChance = nil, showAnimation = true)
    pbDisplay(_INTL("This creature cannot be captured. Something about it refuses to be caught."))
  end

  # Block the same moves the regular World Boss blocks.
  def pbCanChooseMove?(idxBattler, idxMove, showMessages, *args)
    if idxBattler == 0
      move = @battlers[idxBattler]&.moves&.[](idxMove)
      if move && BOSS_BANNED_PLAYER_MOVES.include?(move.id)
        pbDisplay(_INTL("The boss is immune to that move!")) if showMessages
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
      if drop > CREEPY_BOSS_MAX_DAMAGE_PER_HIT
        pbDisplay(_INTL("The boss resisted the attack's full force!"))
        boss_bat.hp = [@hp_before_turn.to_i - CREEPY_BOSS_MAX_DAMAGE_PER_HIT, 1].max
      end
    end
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp == 0 && (@hp_before_turn || 0) > 0
      damage_local  = [@hp_before_turn.to_i, CREEPY_BOSS_MAX_DAMAGE_PER_HIT].min
      damage_global = [(damage_local * @scale).round, 1].max
      NetworkClient.send_msg({ action: 'creepy_boss_damage', damage: damage_global })
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
      rescue; end
    end
    begin
      if [:Sandstorm, :Hail].include?(@field.weather)
        @field.weather         = :None
        @field.weatherDuration = 0
      end
    rescue; end

    @_eor_boss_hp = boss_bat ? boss_bat.hp : nil

    super

    return if @boss_cleared_ext
    boss_bat = @battlers[1]
    return unless boss_bat

    if @_eor_boss_hp && boss_bat.hp < @_eor_boss_hp
      boss_bat.hp = @_eor_boss_hp
    end

    damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max

    if damage_local > CREEPY_BOSS_MAX_DAMAGE_PER_HIT
      pbDisplay(_INTL("The boss resisted the attack's full force!"))
      boss_bat.hp = [(@hp_before_turn || 0) - CREEPY_BOSS_MAX_DAMAGE_PER_HIT, 1].max
      damage_local = CREEPY_BOSS_MAX_DAMAGE_PER_HIT
    end

    damage_global = damage_local > 0 ? [(damage_local * @scale).round, 1].max : 0
    _sync_with_server(damage_global, boss_bat)
    @hp_before_turn = boss_bat.hp
  end

  def net_cleanup
    NetworkClient.remove('creepy_boss_hp_update', @_hp_cb)
    NetworkClient.remove('creepy_boss_cleared',   @_cl_cb)
  end

  private

  def _register_callbacks
    @_hp_cb = NetworkClient.on('creepy_boss_hp_update') do |d|
      @sync_data     = d
      @sync_received = true
      # This message is only ever sent directly to whoever's hit the server
      # just processed — d['is_killer'] means THAT hit brought the pool to 0.
      # Captured here (rather than in _sync_with_server) because a kill
      # often actually gets reported earlier, via pbAttackPhase's
      # fire-and-forget send when the boss's local HP hits 0 mid-turn — this
      # callback still fires for that response even though nothing is
      # explicitly waiting on it at that moment.
      if d['is_killer'] && @battlers[0]&.pokemon
        @kill_evolution_pkmn = @battlers[0].pokemon
      end
    end
    @_cl_cb = NetworkClient.on('creepy_boss_cleared') do |d|
      @boss_cleared_ext = true
      @sync_received    = true
      @sync_data        = { 'hp' => 0, 'max_hp' => CREEPY_BOSS_GLOBAL_MAX_HP, 'others_damage' => 0 }
    end
  end

  def _sync_with_server(damage_global, boss_bat)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: 'creepy_boss_damage', damage: damage_global })

    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    return unless @sync_data

    new_global = @sync_data['hp'].to_i
    others     = @sync_data['others_damage'].to_i

    old_local = boss_bat.hp
    new_local = [(new_global / CREEPY_BOSS_GLOBAL_MAX_HP.to_f * @local_max_hp).round, 0].max
    boss_bat.hp = new_local
    @scene.pbHPChanged(boss_bat, old_local) if old_local != new_local

    @sync_data     = nil
    @sync_received = false

    if new_global == 0
      boss_bat.pbFaint(false)
      pbDisplay(_INTL("It has been put down for good.")) unless decided?
      pbJudge
      return
    end

    pbDisplay(_INTL("Other trainers dealt {1} damage!", others)) if others > 0
  end
end

#===============================================================================
# NetworkCreepyBoss — module that manages the invisible spawn/trigger.
#===============================================================================
module NetworkCreepyBoss
  @active   = false
  @species  = nil
  @map_id   = nil
  @x        = nil
  @y        = nil
  @global_hp = 0
  @moves    = []
  @battle_triggered = false

  def self.active?; @active; end
  def self.global_hp; @global_hp; end

  def self.set_global_hp(hp)
    @global_hp = [hp.to_i, 0].max
  end

  def self.clear
    @active = false
    @species = @map_id = @x = @y = nil
    @moves = []
  end

  def self.activate(data)
    @active    = true
    @species   = data['species'].to_s
    @map_id    = data['map_id'].to_i
    @x         = data['x'].to_i
    @y         = data['y'].to_i
    @global_hp = (data['hp'] || CREEPY_BOSS_GLOBAL_MAX_HP).to_i
    @moves     = data['moves'] || []
    @battle_triggered = false
  end

  # Called every frame from on_frame_update.
  def self.tick
    return unless @active && NetworkAuth.logged_in?
    return if $scene.is_a?(Battle::Scene)
    return unless $scene.is_a?(Scene_Map)
    return unless $game_map&.map_id == @map_id
    return if $game_system.map_interpreter.running?
    px = $game_player.x
    py = $game_player.y
    if px == @x && py == @y && !@battle_triggered
      @battle_triggered = true
      _trigger_encounter
    elsif px != @x || py != @y
      @battle_triggered = false
    end
  end

  private

  def self._trigger_encounter
    species = @species
    map_id  = @map_id

    result = nil
    NetworkClient.on('creepy_boss_engage')            { |d| result = d }
    NetworkClient.on('creepy_boss_already_challenged') { |_d| result = :already }
    NetworkClient.send_msg({ action: 'creepy_boss_found', species: species, map_id: map_id })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('creepy_boss_engage')
    NetworkClient.off('creepy_boss_already_challenged')

    if result == :already
      pbMessage(_INTL("You've already faced this thing once. It won't engage with you again — not this time."))
      return
    end
    unless result
      pbMessage(_INTL("...\nWhatever it was, it's gone now."))
      return
    end

    _start_battle(result)
  end

  def self._start_battle(data)
    unless $player.party.compact.any? { |p| p.hp > 0 }
      pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
      return
    end

    species_sym = data['species'].to_s.to_sym
    unless GameData::Species.exists?(species_sym)
      puts "[CreepyBoss] Unknown species: #{data['species']}"
      return
    end

    level = ($player.party.compact.map(&:level).max || 5).clamp(5, 100)
    boss  = Pokemon.new(species_sym, level)
    boss.instance_variable_set(:@totalhp, CREEPY_BOSS_GLOBAL_MAX_HP)
    local_max_hp = CREEPY_BOSS_GLOBAL_MAX_HP.to_f
    boss.hp = [data['hp'].to_i, 1].max

    move_ids = (data['moves'] || []).first(4)
    move_ids = ['TACKLE'] if move_ids.empty?
    # Assign by index (mirroring _clean_boss_moveset in 012_NetworkBoss.rb)
    # rather than replacing the whole array, since Pokemon#moves is always a
    # fixed 4-slot array under the hood.
    move_ids.each_with_index { |id, i| boss.moves[i] = Pokemon::Move.new(id.to_sym) }

    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers([boss])

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle::CreepyBossEncounter.new(
      scene, player_party, [boss], player_trainers, local_max_hp
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

    bgm = begin
      pbGetWildBattleBGM([boss])
    rescue
      $data_system.battle_bgm
    end

    EventHandlers.trigger(:on_start_battle)

    outcome = Battle::Outcome::UNDECIDED
    pbBattleAnimation(bgm, 0, [boss]) do
      pbSceneStandby { outcome = battle.pbStartBattle }
      BattleCreationHelperMethods.after_battle(outcome, false)
    end

    battle.net_cleanup
    NetworkCreepyBoss.clear if NetworkCreepyBoss.global_hp == 0

    # Ghost's kill-triggered evolution into Ghostly (Event 900 — see
    # PBS/pokemon.txt and 007_Evolution.rb): only fires if THIS player's own
    # active battler landed the finishing blow, not merely for participating.
    # Checked here, back in the overworld, rather than mid-battle.
    kill_pkmn = battle.kill_evolution_pkmn
    kill_pkmn.trigger_event_evolution(900) if kill_pkmn && kill_pkmn.species == :GHOST
  end
end

#===============================================================================
# Server event handlers
#===============================================================================

NetworkClient.on('creepy_boss_spawn') do |d|
  NetworkCreepyBoss.activate(d)
end

NetworkClient.on('creepy_boss_cleared') do |_d|
  NetworkCreepyBoss.clear
end

#===============================================================================
# Hooks
#===============================================================================
EventHandlers.add(:on_frame_update, :network_creepy_boss_tick,
  proc { NetworkCreepyBoss.tick if NetworkClient.connected? }
)
