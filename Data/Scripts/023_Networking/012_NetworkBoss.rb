#===============================================================================
# NetworkBoss — shared world boss battle (Groudon / Kyogre / Rayquaza).
#
# The boss has 20,000 HP shared across all online players.  Each player fights
# it at the level of their highest-level team member.  Damage is reported to the
# server after each turn; the server returns the updated global HP plus how much
# other players dealt simultaneously.  Capture is blocked until HP < 5%.
#
# The boss spawns once per game-week (≈ 2.8 real hours) at game noon on a
# specific in-game weekday.  Only players whose in-game weekday matches can fight.
# The boss Pokémon appears as an overworld sprite — walk into it to start the fight.
#
# Follower sprite names (adjust to match actual filenames in Graphics/Characters/):
#   GROUDON  → Followers/383   (or Followers/Groudon, etc.)
#   KYOGRE   → Followers/382
#   RAYQUAZA → Followers/384
#===============================================================================

BOSS_SPRITES = {
  'GROUDON'   => 'Followers/GROUDON',
  'KYOGRE'    => 'Followers/KYOGRE',
  'RAYQUAZA'  => 'Followers/RAYQUAZA',
  'JIRACHI'   => 'Followers/JIRACHI',
  'DEOXYS'    => 'Followers/DEOXYS',
  'MEWTWO'    => 'Followers/MEWTWO',
  'ARTICUNO'  => 'Followers/ARTICUNO',
  'ZAPDOS'    => 'Followers/ZAPDOS',
  'MOLTRES'   => 'Followers/MOLTRES',
  'DIALGA'    => 'Followers/DIALGA',
  'PALKIA'    => 'Followers/PALKIA',
  'GIRATINA'  => 'Followers/GIRATINA',
  'HEATRAN'   => 'Followers/HEATRAN',
  'REGIGIGAS' => 'Followers/REGIGIGAS',
}

BOSS_GLOBAL_MAX_HP     = 20_000
BOSS_CAPTURE_THRESHOLD = 0.05  # 5% of 20,000 = 1,000 HP

# Maximum damage any single player can deal in one round.
# Prevents Endeavor (sets HP to user's HP — instant ~18k damage) and similar
# one-shot mechanics from wrecking the shared HP pool.
BOSS_MAX_DAMAGE_PER_ROUND = 3_000

# Moves removed from the boss's learned moveset before the battle starts.
# Replaced with Extreme Speed so the move count stays at 4.
BOSS_BANNED_HEALING_MOVES = %i[
  ROOST RECOVER REST SOFTBOILED MOONLIGHT MORNINGSUN SYNTHESIS
  MILKDRINK SLACKOFF HEALINGWISH LUNARDANCE WISH AQUARING INGRAIN
  HEALBELL AROMATHERAPY REFRESH
]

# Player moves blocked in boss battles — set HP to a specific value or
# one-shot, bypassing the per-round damage cap.
BOSS_BANNED_PLAYER_MOVES = %i[
  ENDEAVOR SUPERFANG FINALGAMBIT
  GUILLOTINE FISSURE HORNDRILL SHEERCOLD
  TOXIC POISONPOWDER
  WILLOWISP
  LEECHSEED
  CURSE
  SANDSTORM HAIL
  WRAP BIND CLAMP FIRESPIN WHIRLPOOL MAGMASTORM INFESTATION
]

#===============================================================================
# Battle::BossEncounter — Battle subclass for the shared boss fight.
#
# Key behaviours vs normal wild Battle:
#   • Syncs damage with the server after each turn.
#   • Shows "Other trainers dealt X damage!" if others attacked simultaneously.
#   • Blocks Poké Ball throws until global HP < 5%.
#   • Reports a successful catch to the server.
#===============================================================================
class Battle::BossEncounter < Battle
  attr_reader :boss_was_caught

  # local_max_hp : the boss Pokémon's actual max HP at its battle level (for scaling)
  def initialize(scene, player_party, boss_party, player_trainers, local_max_hp)
    super(scene, player_party, boss_party, player_trainers, nil)
    @local_max_hp   = local_max_hp.to_f
    @scale          = BOSS_GLOBAL_MAX_HP / @local_max_hp  # global HP per 1 local HP point
    @hp_before_turn = nil
    @sync_received  = false
    @sync_data      = nil
    @boss_was_caught = false
    @boss_cleared_ext = false
    @struggle_warned = false
    @_boss_faint_guard = false
    _register_callbacks
  end

  #-----------------------------------------------------------------------------
  # Warn the player before they choose their action for the round if the boss
  # has burned through every move's PP and will be forced to use Struggle next
  # turn. Struggle's recoil can solo-kill the boss, prematurely ending this
  # player's fight for only capped chip damage — better to let them retreat
  # and come back for a fresh (full-PP) fight instead.
  #
  # Checked here (start of pbCommandPhase, before the player picks Fight/Run)
  # rather than via pbCanShowFightMenu? because that also returns false while
  # Encored, which isn't actually a PP-exhaustion case.
  #-----------------------------------------------------------------------------
  def pbCommandPhase
    _warn_if_boss_out_of_pp
    super
  end

  #-----------------------------------------------------------------------------
  # Block Poké Ball throws until global HP is below the 5% threshold.
  #-----------------------------------------------------------------------------
  def pbThrowPokeBall(idxBattler, ball, critChance = nil, showAnimation = true)
    if NetworkBoss.global_hp_pct > BOSS_CAPTURE_THRESHOLD
      pct = (NetworkBoss.global_hp_pct * 100).round
      pbDisplay(_INTL("The Boss still has {1}% HP! Weaken it below 5% to attempt capture.", pct))
      return
    end
    super(idxBattler, ball, critChance, showAnimation)
  end

  #-----------------------------------------------------------------------------
  # Block player moves that bypass the per-round damage cap.
  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  # Record boss HP before the attack phase so we can measure damage per turn.
  #-----------------------------------------------------------------------------
  def pbAttackPhase
    boss_bat = @battlers[1]
    @hp_before_turn = boss_bat ? boss_bat.hp : 0
    super
    # Immediately cap any single-turn HP drop that exceeds the per-round limit.
    # Catches Endeavor / Super Fang / OHKOs that slip through via Metronome, Assist, etc.
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp > 0 && @hp_before_turn.to_i > 0
      drop = @hp_before_turn.to_i - boss_bat.hp
      if drop > BOSS_MAX_DAMAGE_PER_ROUND
        pbDisplay(_INTL("The boss resisted the attack's full force!"))
        boss_bat.hp = [@hp_before_turn.to_i - BOSS_MAX_DAMAGE_PER_ROUND, 1].max
      end
    end
    # If the boss reached 0 HP during the attack phase (Struggle recoil, direct kill,
    # etc.), the battle loop calls decided? and may skip pbEndOfRoundPhase entirely.
    # Fire-and-forget the damage so the server doesn't leave a zombie boss.
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp == 0 && (@hp_before_turn || 0) > 0
      damage_local  = [@hp_before_turn.to_i, BOSS_MAX_DAMAGE_PER_ROUND].min
      damage_global = [(damage_local * @scale).round, 1].max
      NetworkClient.send_msg({ action: 'boss_damage', damage: damage_global })
      @hp_before_turn = 0  # prevent double-sync if pbEndOfRoundPhase still runs
    end
  end

  #-----------------------------------------------------------------------------
  # After all end-of-round effects: calculate damage, sync HP with server.
  #
  # Blocked indirect damage sources (restored before sync):
  #   • Leech Seed drain       • Poison / Toxic chip
  #   • Sandstorm / Hail chip  • Curse drain
  #   • Binding / Wrap damage
  #
  # Endeavor / instant-kill cap: if one player's round exceeds
  # BOSS_MAX_DAMAGE_PER_ROUND, boss HP is restored to just below the cap
  # and only the capped amount is reported to the server.
  #-----------------------------------------------------------------------------
  def pbEndOfRoundPhase
    boss_bat = @battlers[1]

    # Strip every HP-draining condition from the boss BEFORE calling super
    # so that chip damage never fires in the first place.
    # This catches moves that slipped through via Metronome / Assist / etc.
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
    # Remove sandstorm / hail so weather-chip never fires against the boss.
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

    # Restore HP lost to indirect end-of-round effects (leech seed, poison chip,
    # weather chip, curse drain, etc.). Only direct attack damage is synced.
    if @_eor_boss_hp && boss_bat.hp < @_eor_boss_hp
      boss_bat.hp = @_eor_boss_hp
    end

    damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max

    # Cap Endeavor / jump-HP moves from one-shotting the shared pool.
    if damage_local > BOSS_MAX_DAMAGE_PER_ROUND
      pbDisplay(_INTL("The boss resisted the attack's full force!"))
      boss_bat.hp = [(@hp_before_turn || 0) - BOSS_MAX_DAMAGE_PER_ROUND, 1].max
      damage_local = BOSS_MAX_DAMAGE_PER_ROUND
    end

    damage_global = damage_local > 0 ? [(damage_local * @scale).round, 1].max : 0
    _sync_with_server(damage_global, boss_bat)
    @hp_before_turn = boss_bat.hp
  end

  # Called by the battle system just before the caught Pokémon is stored.
  # Reset to level 5 here so the party/PC always receives the correct stats.
  def pbStorePokemon(pkmn)
    @boss_was_caught = true
    pkmn.level = 5
    pkmn.calc_stats
    pkmn.heal
    super(pkmn)
  end

  # Read by the shared Battle::Battler#pbReduceHP patch below.
  def boss_hit_cap
    BOSS_MAX_DAMAGE_PER_ROUND
  end

  # Read by the shared Battle::Battler#pbFaint patch below.
  def _boss_faint_guard_active?
    @_boss_faint_guard == true
  end

  #-----------------------------------------------------------------------------
  # Called by the shared Battle::Battler#pbFaint patch the instant the boss's
  # local hp would otherwise be declared fainted (hp <= 0), from WHEREVER that
  # happened this round — a direct hit, a multi-hit move, or (the reported
  # case) the boss's own Struggle recoil finishing itself off once its real hp
  # was already below the per-round cap. Every one of those paths still funnels
  # through this single choke point, so instead of chasing down each possible
  # trigger individually, just verify with the server before the battle is
  # allowed to actually end: report this round's (capped) damage and block for
  # the real answer. If the shared HP pool is still alive server-side (other
  # participants, or a stale local cache), revive the boss's local hp to the
  # authoritative value instead of letting the fight end early.
  #-----------------------------------------------------------------------------
  def _boss_verify_before_faint(boss_bat)
    damage_local = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
    damage_local = [damage_local, BOSS_MAX_DAMAGE_PER_ROUND].min
    damage_local = 1 if damage_local < 1 && (@hp_before_turn || 0) > 0
    damage_global = damage_local > 0 ? [(damage_local * @scale).round, 1].max : 0

    @_boss_faint_guard = true
    _sync_with_server(damage_global, boss_bat)
    @_boss_faint_guard = false

    if boss_bat.hp > 0
      @hp_before_turn = boss_bat.hp
      pbDisplay(_INTL("The boss shrugs off the blow and remains standing!"))
    end
  end

  def net_cleanup
    NetworkClient.remove('boss_hp_update', @_hp_cb)
    NetworkClient.remove('boss_cleared',   @_cl_cb)
  end

  private

  # True only when every one of the boss's moves has a normal PP pool
  # (total_pp > 0) that's fully depleted (pp <= 0) — i.e. the same condition
  # that forces Struggle (see pbCanShowFightMenu? in Battle_CommandPhase.rb).
  # Deliberately narrower than pbCanShowFightMenu?, which also returns false
  # for reasons unrelated to PP (Encore lock, etc.).
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
    pbDisplay(_INTL("The boss has no PP left and will Struggle!\nIts recoil could make it faint here — consider retreating and coming back for a fresh fight."))
  end

  def _register_callbacks
    @_hp_cb = NetworkClient.on('boss_hp_update') do |d|
      @sync_data     = d
      @sync_received = true
    end
    # If the boss is cleared by another player mid-battle, end gracefully.
    @_cl_cb = NetworkClient.on('boss_cleared') do |d|
      @boss_cleared_ext = true
      @sync_received    = true
      @sync_data        = { 'hp' => 0, 'max_hp' => BOSS_GLOBAL_MAX_HP, 'others_damage' => NetworkBoss.global_hp }
    end
  end

  def _sync_with_server(damage_global, boss_bat)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: 'boss_damage', damage: damage_global })

    # Wait up to 3 seconds for server response.
    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    return unless @sync_data

    new_global = @sync_data['hp'].to_i
    others     = @sync_data['others_damage'].to_i
    NetworkBoss.set_global_hp(new_global)

    # Map global HP → local HP for the battle display.
    old_local = boss_bat.hp
    new_local = [(new_global / BOSS_GLOBAL_MAX_HP.to_f * @local_max_hp).round, 0].max
    boss_bat.hp = new_local
    @scene.pbHPChanged(boss_bat, old_local) if old_local != new_local

    @sync_data     = nil
    @sync_received = false

    # If the server reports HP = 0, end the battle immediately so the player
    # can't act on a dead boss.  pbFaint has an @fainted guard so it's a no-op
    # if the player's own attack already triggered the faint this turn.
    if new_global == 0
      boss_bat.pbFaint(false)
      pbDisplay(_INTL("The boss was brought down by all trainers combined!")) unless decided?
      pbJudge
      return
    end

    # Show simultaneous damage from other players.
    pbDisplay(_INTL("Other trainers dealt {1} damage to the boss!", others)) if others > 0
  end
end

#===============================================================================
# Shared fix for World Boss / Creepy Boss / Mini Boss: a single overcapped hit
# (Struggle is the common trigger — a PP-exhausted boss forces the player to
# Struggle, and its damage routinely dwarfs a mini/creepy boss's tiny per-hit
# cap) could drop the boss's LOCAL hp to 0 in one blow. The per-round
# corrections in each Encounter's pbAttackPhase/pbEndOfRoundPhase run only
# *after* `super`, but the battle engine's own fainted-check (and "It
# fainted!"/victory handling) already fires the instant hp hits 0 inside
# `super` — by then it's too late, the battle has already locally ended even
# though the real, capped damage report hasn't reached the server yet and the
# shared HP pool is still very much alive.
#
# Fixed at the source: Battle::Battler#pbReduceHP is the single choke point
# every damage source funnels through. When the target is the boss battler
# (index 1) in one of these three encounter types, and it still has more HP
# than the cap, a single call can never remove more than the cap — so hp can
# only ever reach 0 here when it was already at or below the cap going in,
# which is exactly when the server would allow a real kill too.
#===============================================================================
class Battle::Battler
  alias_method :pbReduceHP_before_shared_boss_cap, :pbReduceHP
  def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
    if index == 1 && @battle.respond_to?(:boss_hit_cap)
      cap = @battle.boss_hit_cap
      amt = cap if cap && @hp > cap && amt > cap
    end
    pbReduceHP_before_shared_boss_cap(amt, anim, registerDamage, anyAnim)
  end

  #-----------------------------------------------------------------------------
  # Belt-and-suspenders for the same class of bug: even with the pbReduceHP cap
  # above, the boss's local hp can still legitimately reach 0 within a single
  # round (its remaining hp was already at/below the cap, a multi-hit move
  # chipped it down cumulatively, or — the actually-reported case — the boss's
  # own forced Struggle recoils on ITSELF once its true hp was already low).
  # Whatever the trigger, every one of those paths still has to call pbFaint
  # before the battle engine will treat the boss as dead. Intercept there:
  # verify with the server FIRST (the shared hp pool may still be very much
  # alive — other participants may have healed the gap, or our local cache is
  # simply stale) and only let the real pbFaint/battle-end logic run once the
  # server actually confirms it. If the server disagrees, the boss's hp is
  # revived to the authoritative value and the fight continues.
  #-----------------------------------------------------------------------------
  alias_method :pbFaint_before_shared_boss_check, :pbFaint
  def pbFaint(showMessage = true)
    if index == 1 && @battle.respond_to?(:_boss_verify_before_faint) && !@battle._boss_faint_guard_active?
      @battle._boss_verify_before_faint(self)
      return
    end
    pbFaint_before_shared_boss_check(showMessage)
  end
end

#===============================================================================
# NetworkBoss — module that manages boss state, overworld sprite, and battle.
#===============================================================================
module NetworkBoss
  @active      = false
  @species     = nil
  @map_id      = nil
  @spawn_x     = nil
  @spawn_y     = nil
  @global_hp   = 0
  @spawn_wday  = nil
  @location_name = nil

  @char_obj        = nil   # OtherPlayerCharacter for overworld display
  @char_sprite     = nil   # Sprite_Character
  @battle_triggered = false

  # ── Accessors ────────────────────────────────────────────────────────────────
  def self.active?;         @active;                                    end
  def self.global_hp;       @global_hp;                                 end
  def self.global_hp_pct;   @global_hp / BOSS_GLOBAL_MAX_HP.to_f;      end

  def self.set_global_hp(hp)
    @global_hp = [hp.to_i, 0].max
  end

  # ── Called from on_frame_update ───────────────────────────────────────────────
  def self.tick
    return unless @active && NetworkAuth.logged_in?
    return if $scene.is_a?(Battle::Scene)
    # Defensive: if the sprite leaked to the wrong map (e.g. on_enter_map fired
    # before viewport was ready), destroy it now rather than letting it render.
    if $game_map&.map_id != @map_id
      _destroy_sprite
      return
    end
    _update_sprite
    _check_trigger
  end

  # ── Activate / deactivate (from server events) ────────────────────────────────
  def self.activate(data)
    @active        = true
    @species       = data['species'].to_s
    @map_id        = data['map_id'].to_i
    @spawn_x       = data['x'].to_i
    @spawn_y       = data['y'].to_i
    @global_hp     = (data['hp'] || BOSS_GLOBAL_MAX_HP).to_i
    @spawn_wday    = data['wday'].to_i
    @location_name = data['name'].to_s
    @battle_triggered = false
    _rebuild_sprite if $game_map&.map_id == @map_id
  end

  def self.deactivate
    @active = false
    _destroy_sprite
  end

  # ── Overworld sprite ──────────────────────────────────────────────────────────
  def self.on_map_enter(map_id)
    _destroy_sprite
    _rebuild_sprite if @active && map_id == @map_id
  end

  # ── Called after catching the boss ───────────────────────────────────────────
  def self.report_caught
    NetworkClient.send_msg({ action: 'boss_caught' })
  end

  private

  def self._check_trigger
    return unless $game_map&.map_id == @map_id
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?
    px = $game_player.x
    py = $game_player.y
    if px == @spawn_x && py == @spawn_y && !@battle_triggered
      @battle_triggered = true
      _start_boss_battle
    elsif px != @spawn_x || py != @spawn_y
      @battle_triggered = false
    end
  end

  def self._start_boss_battle
    # Guard: refuse to start if party is entirely fainted (prevents nil crash in battle intro).
    unless $player.party.compact.any? { |p| p.hp > 0 }
      pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
      return
    end

    # Level: match the player's highest-level party member.
    level = ($player.party.compact.map(&:level).max || 5).clamp(5, 100)

    # Create the boss Pokémon.
    species_sym = @species.to_sym
    unless GameData::Species.exists?(species_sym)
      puts "[Boss] Unknown species: #{@species}"
      return
    end

    boss = Pokemon.new(species_sym, level)
    _clean_boss_moveset(boss)
    # Show the global HP pool directly: every local damage point = 1 global HP.
    boss.instance_variable_set(:@totalhp, BOSS_GLOBAL_MAX_HP)
    local_max_hp = BOSS_GLOBAL_MAX_HP.to_f
    boss.hp = [@global_hp, 1].max

    # Set up the player's side of the battle.
    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers([boss])

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle::BossEncounter.new(
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

    # Use wild-battle BGM (or override to a legendary track if preferred).
    begin
      bgm = pbGetWildBattleBGM([boss])
    rescue
      bgm = $data_system.battle_bgm
    end

    # Mirrors WildBattle.start_core — initialises $game_temp fields that
    # on_end_battle handlers (e.g. Shadow Pokémon heart-gauge check) expect.
    EventHandlers.trigger(:on_start_battle)

    outcome = Battle::Outcome::UNDECIDED
    pbBattleAnimation(bgm, 0, [boss]) do
      pbSceneStandby { outcome = battle.pbStartBattle }
      BattleCreationHelperMethods.after_battle(outcome, false)
    end

    battle.net_cleanup

    if battle.boss_was_caught
      NetworkBoss.report_caught
      NetworkBoss.deactivate
      pbMessage(_INTL("You caught the legendary {1}!\nWord spreads across Johto...",
                      boss.species.to_s.downcase.capitalize))
    elsif NetworkBoss.global_hp == 0
      # Defeated — same issue: our listener was removed, deactivate manually.
      NetworkBoss.deactivate
    end
  end

  def self._clean_boss_moveset(boss)
    return unless boss.moves.is_a?(Array)
    fallback = GameData::Move.exists?(:EXTREMESPEED) ? :EXTREMESPEED : :TACKLE
    boss.moves.each_with_index do |move, i|
      next unless move && BOSS_BANNED_HEALING_MOVES.include?(move.id)
      puts "[Boss] Replacing healing move #{move.id} on #{boss.species} with #{fallback}"
      boss.moves[i] = Pokemon::Move.new(fallback)
    end
  end

  def self._rebuild_sprite
    _destroy_sprite
    return unless @species
    sprite_name = BOSS_SPRITES[@species] || "Followers/#{@species}"
    data = {
      'x'              => @spawn_x,
      'y'              => @spawn_y,
      'direction'      => 2,
      'character_name' => sprite_name,
      'character_hue'  => 0,
    }
    @char_obj = OtherPlayerCharacter.new(data)
    vp = Spriteset_Map.viewport
    return unless vp
    @char_sprite = Sprite_Character.new(vp, @char_obj)
  end

  def self._destroy_sprite
    @char_sprite&.dispose
    @char_sprite = nil
    @char_obj    = nil
  end

  def self._update_sprite
    return unless @char_sprite && !@char_sprite.disposed?
    @char_sprite.update
  end
end

#===============================================================================
# Server event handlers
#===============================================================================

# Boss spawned — activate for all connected players.
NetworkClient.on('boss_spawn') do |d|
  NetworkBoss.activate(d)
  species_name = d['species'].to_s.capitalize
  loc_name     = d['name'] || 'the wild'
  pbMessage(_INTL("A legendary {1} has appeared in {2}!\nWork with other trainers to defeat it!", species_name, loc_name)) if $scene.is_a?(Scene_Map)
end

# Status response — sent on login and when arriving to the boss map.
NetworkClient.on('boss_status') do |d|
  next unless d['active']
  NetworkBoss.activate(d)
end

# Boss defeated or caught by someone — remove the overworld sprite.
NetworkClient.on('boss_cleared') do |d|
  NetworkBoss.deactivate
  next unless $scene.is_a?(Scene_Map)
  if d['reason'] == 'caught'
    catcher = d['caught_by'] || 'A trainer'
    pbMessage(_INTL("{1} caught the legendary boss!\nPeace returns to Johto.", catcher))
  elsif d['reason'] == 'defeated'
    pbMessage(_INTL("The legendary boss has been defeated!\nPeace returns to Johto."))
  end
end

#===============================================================================
# Hooks
#===============================================================================
EventHandlers.add(:on_enter_map, :network_boss_enter,
  proc { |map_id| NetworkBoss.on_map_enter(map_id) if NetworkAuth.logged_in? }
)

EventHandlers.add(:on_frame_update, :network_boss_tick,
  proc { NetworkBoss.tick if NetworkClient.connected? }
)
