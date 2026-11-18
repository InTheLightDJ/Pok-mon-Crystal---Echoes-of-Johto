#===============================================================================
# Blood Mewtwo (server: handlers/blood_mewtwo.js)
#
# A World Boss only players with switch 116 on can see (the game tells the
# server, which only sends him, and his chat announcements, to them). He
# flies around the routes and towns the way the hunt's boss does
# (002_ShadowLugia.rb: the server sends his plan over his current map and
# every game plays it from the same clock), but he hunts: he flies to
# everything on the map (people, Pokémon, item balls, trees, rocks, berry
# trees, doors) one after another and breaks them (they flash red,
# fade and are gone), and when the map has nobody left he flies on to the
# next map. The broken ones stay gone for this game while he's alive (until
# the map is left after he dies; nothing is saved).
#
# The battle: nothing can hurt him but himself. Every other way of losing HP
# is blocked; only the damage he does to himself in confusion counts, shared
# by everyone (the server's HP). Knocked out that way he dies for everyone.
# His moves never run out of PP. Only a Blood Ball can catch him (the first
# catch the server hears of wins); any other ball can't even be thrown.
#
# He comes back once a week after he's beaten (server). An event can wake
# him sooner:   Script: pbSpawnBloodMewtwo        (wherever he'd wake)
#               Script: pbSpawnBloodMewtwo(true)  (next to the player; on a
#                                                  route or town only)
# It only works for a player with switch 116 on, and not while he's awake.
# It returns true if he woke (use it in a Conditional Branch > Script to
# show your own message), false if not (offline, switch off, already
# awake, not outside); it shows no message itself.
#===============================================================================
BLOOD_MEWTWO_SPECIES    = :BLOODMEWTWO
BLOOD_MEWTWO_SWITCH     = 116
BLOOD_MEWTWO_BALL       = :BLOODBALL
BLOOD_MEWTWO_BALL_MULT  = 5           # the Blood Ball's catch rate multiplier on him (x1 on others)
BLOOD_MEWTWO_MOVES      = [:BLOODMOON, :BITTERBLADE, :DRAINPUNCH, :PSYSTRIKE]
BLOOD_MEWTWO_MOVE_SPEED = 3           # 0.25 s a tile: must match MS_PER_TILE (250) on the server
BLOOD_MEWTWO_BREAK_TIME = 0.6         # seconds a broken event takes to fade away
BLOOD_MEWTWO_BREAK_SE   = "Anim/Bite"
BLOOD_MEWTWO_CHARSET    = "Followers/BLOODMEWTWO"

module BloodMewtwo
  # { map_id:, path:, breaks: [[event id, ms]], broken: { map_id => [event ids] },
  #   ms_per_tile:, exit_dir:, started:, hp:, max_hp: }
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @unlock_sent = false
  @fading  = {}     # [map_id, event id] => System.unscaled_uptime the break started
  @alerted = {}     # [plan start, event id] => true: "!" shown over his next victim

  class << self
    attr_reader :state

    def name; GameData::Species.exists?(BLOOD_MEWTWO_SPECIES) ? GameData::Species.get(BLOOD_MEWTWO_SPECIES).name : "Blood Mewtwo"; end
    def unlocked?; $game_switches && $game_switches[BLOOD_MEWTWO_SWITCH]; end
    def online?; ScavengerHunt.online?; end
    def active?; !@state.nil? && unlocked?; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      broken = {}
      (d["broken"] || {}).each { |k, v| broken[k.to_i] = v.map(&:to_i) }
      @state = { map_id: d["map_id"].to_i, path: d["path"].map { |p| p.map(&:to_i) },
                 breaks: (d["breaks"] || []).map { |b| b.map(&:to_i) }, broken: broken,
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 hp: d["hp"].to_i, max_hp: d["max_hp"].to_i,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id]
    end

    # he's gone (dead or caught): the broken events come back when their map
    # is loaded again
    def clear
      @state = nil
      @fading.clear
      @alerted.clear
      destroy_sprite
    end

    def elapsed_ms; ((System.unscaled_uptime - @state[:started]) * 1000).to_i; end

    def position(ahead = false)
      ms = elapsed_ms
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, @state[:exit_dir])
    end

    # the events of map map_id he's broken by now
    def broken_on(map_id)
      ids = (@state[:broken][map_id] || []).dup
      if map_id == @state[:map_id]
        ms = elapsed_ms
        @state[:breaks].each { |eid, at| ids << eid if at <= ms }
      end
      ids - (defined?(BloodCelebi) ? BloodCelebi.restored_on(map_id) : [])   # 002_BloodCelebi.rb
    end

    #---------------------------------------------------------------------------
    # Telling the server this game can see him (once per login)
    #---------------------------------------------------------------------------
    def report_unlock
      return if @unlock_sent || !unlocked? || !online?
      @unlock_sent = true
      NetworkClient.send_msg({ action: "blood_mewtwo_unlock" })
    end

    def logged_in
      @unlock_sent = false
    end

    #---------------------------------------------------------------------------
    # Him on the map
    #---------------------------------------------------------------------------
    def host_map
      id = @state[:map_id]
      return $game_map if $game_map&.map_id == id
      return $map_factory.getMapNoAdd(id) if $map_factory&.hasMap?(id)
      nil
    end

    def destroy_sprite
      @sprite&.dispose
      @sprite = nil
      @char = nil
    end

    def tick
      report_unlock if Graphics.frame_count % 60 == 0
      return destroy_sprite unless active? && online? && $scene.is_a?(Scene_Map)
      break_events
      map = host_map
      if @char && @char.map != map && @char.moving? && !@sprite.disposed?
        @char.update
        @sprite.update
        return
      end
      return destroy_sprite unless map
      if !@char || @char.map != map || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_MEWTWO_CHARSET}") ? BLOOD_MEWTWO_CHARSET : "Followers/000"
        @char = ShadowLugiaCharacter.new(map, BLOOD_MEWTWO_SPECIES, charset)
        @char.move_speed = BLOOD_MEWTWO_MOVE_SPEED
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      hunt_events(map)
      check_trigger
    end

    #---------------------------------------------------------------------------
    # His victims
    #---------------------------------------------------------------------------
    def loaded_maps
      maps = $map_factory ? $map_factory.maps.compact : []
      maps << $game_map if $game_map && !maps.include?($game_map)
      maps
    end

    # an event the game is running now (talking to it...): left alone for now
    def busy?(map, eid)
      interp = $game_system.map_interpreter
      interp.running? && interp.instance_variable_get(:@event_id) == eid &&
        interp.instance_variable_get(:@map_id) == map.map_id
    end

    # the ones he's broken: just broken on a map on screen, they flash red and
    # fade (with a sound); any others are just gone
    def break_events
      now = System.unscaled_uptime
      loaded_maps.each do |map|
        broken_on(map.map_id).each do |eid|
          ev = map.events[eid]
          next if !ev || ev.instance_variable_get(:@erased) || busy?(map, eid)
          key = [map.map_id, eid]
          if (start = @fading[key])
            t = (now - start) / BLOOD_MEWTWO_BREAK_TIME
            if t >= 1
              ev.erase
              ev.opacity = 255
              @fading.delete(key)
            else
              ev.opacity = (255 * (1 - t)).to_i
            end
          elsif just_broken?(map, eid)
            @fading[key] = now
            tint(map, ev)
            pbSEPlay(BLOOD_MEWTWO_BREAK_SE) if map == $game_map && FileTest.audio_exist?("Audio/SE/#{BLOOD_MEWTWO_BREAK_SE}")
          else
            ev.erase
          end
        end
      end
    end

    def just_broken?(map, eid)
      return false unless map.map_id == @state[:map_id]
      b = @state[:breaks].find { |id, _| id == eid }
      b && elapsed_ms - b[1] < 2000
    end

    # the event's sprite goes blood red
    def tint(map, ev)
      ss = $scene.spriteset(map.map_id) rescue nil
      sprites = ss&.instance_variable_get(:@character_sprites) || []
      sprites.each { |s| s.color.set(200, 0, 0, 170) if s.character == ev && !s.disposed? }
    rescue StandardError
      nil
    end

    # the ones he's still coming for stop where they are; the next one sees him coming
    def hunt_events(map)
      return unless map.map_id == @state[:map_id]
      ms = elapsed_ms
      upcoming = @state[:breaks].select { |_, at| at > ms }
      upcoming.each do |eid, _|
        ev = map.events[eid]
        ev.instance_variable_set(:@move_type, 0) if ev   # (each frame: a page change resets it)
      end
      return if upcoming.empty?
      eid = upcoming[0][0]
      key = [@state[:started].round(3), eid]
      return if @alerted[key]
      ev = map.events[eid]
      return unless ev && !ev.instance_variable_get(:@erased)
      @alerted[key] = true
      ev.animation_id = exclaim_anim_id
    end

    def exclaim_anim_id
      @exclaim_anim_id ||= begin
        anims = load_data("Data/Animations.rxdata")
        anims.index { |a| a && a.name == "Exclaim bubble" } || 4
      rescue StandardError
        4
      end
    end

    # standing on the same tile as him starts the battle (once per meeting)
    def check_trigger
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        start_battle
      end
    end

    #---------------------------------------------------------------------------
    # The battle
    #---------------------------------------------------------------------------
    def start_battle
      battle = pbBloodBossBattle("blood_mewtwo", BLOOD_MEWTWO_SPECIES, BLOOD_MEWTWO_MOVES,
                                 Battle::BloodMewtwoEncounter, name)
      clear if battle && (battle.boss_caught || battle.boss_defeated)
    end
  end
end

#===============================================================================
# The other blood bosses (Blood Celebi, Blood Meloetta) don't need switch 116:
# an event releases them for this player (pbReleaseBloodCelebi,
# pbReleaseBloodMeloetta). It's kept in the save; the server is told at every
# login and then sends that boss to this game. The server can release one too
# (a jackpot releases Blood Meloetta for everyone): every game says hello at
# login, and blood_<key>_released marks it in the save.
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :blood_released
  def blood_released; @blood_released ||= {}; end
end

module BloodBoss
  @sent = {}

  def self.released?(key); $PokemonGlobal ? $PokemonGlobal.blood_released[key] == true : false; end
  def self.release(key); $PokemonGlobal.blood_released[key] = true if $PokemonGlobal; end

  # tells the server (once per login, or now with force): released here, or
  # just hello (it may have been released for this player by the server)
  def self.report_release(key, force = false)
    return unless BloodMewtwo.online?
    return if @sent[key] && !force
    return if force && !released?(key)
    @sent[key] = true
    NetworkClient.send_msg({ action: released?(key) ? "blood_#{key}_release" : "blood_#{key}_hello" })
  end

  def self.logged_in; @sent.clear; end
end

NetworkClient.on("login_ok") { |_d| BloodBoss.logged_in }
NetworkClient.on("blood_celebi_released") { |_d| BloodBoss.release(:celebi) }
NetworkClient.on("blood_meloetta_released") { |_d| BloodBoss.release(:meloetta) }

#===============================================================================
# A battle with a Blood boss (Blood Mewtwo, Blood Celebi: 002_BloodCelebi.rb,
# Blood Meloetta: 003_BloodMeloetta.rb).
# net: its server messages' prefix. The battle, or nil if there wasn't one.
# exact_hp: its HP in the battle is the server's own (the gods: 400,000), not
# scaled down to its usual HP.
#===============================================================================
def pbBloodBossBattle(net, species, moves, battle_class, boss_name, exact_hp = false)
  unless $player.party.compact.any? { |p| p.hp > 0 && !p.egg? }
    pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
    return nil
  end
  result = nil
  cb = NetworkClient.on("#{net}_engage") { |d| result = d }
  NetworkClient.send_msg({ action: "#{net}_found", map_id: $game_map.map_id })
  300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.remove("#{net}_engage", cb)
  unless result
    pbMessage(_INTL("Couldn't reach the server. Try again in a moment."))
    return nil
  end
  unless result["active"]
    pbMessage(_INTL("{1} vanished before you could reach it!", boss_name))
    return nil
  end
  return nil unless GameData::Species.exists?(species)
  level = ($player.party.compact.reject(&:egg?).map(&:level).max || 5).clamp(5, GameData::GrowthRate.max_level)
  boss = Pokemon.new(species, level)
  boss.forget_all_moves
  moves.select { |m| GameData::Move.exists?(m) }.each { |m| boss.learn_move(m) }
  boss.item = nil
  max_units = [result["max_hp"].to_i, 1].max
  if exact_hp
    boss.instance_variable_set(:@totalhp, max_units)
    boss.hp = [result["hp"].to_i, 1].max
  else
    boss.hp = [(result["hp"].to_f / max_units * boss.totalhp).round, 1].max
  end

  player_trainers, ally_items, player_party, party_starts =
    BattleCreationHelperMethods.set_up_player_trainers([boss])
  scene  = BattleCreationHelperMethods.create_battle_scene
  battle = battle_class.new(scene, player_party, [boss], player_trainers, boss_name, max_units)
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
  bgm = (pbGetWildBattleBGM([boss]) rescue $data_system.battle_bgm)
  EventHandlers.trigger(:on_start_battle)
  outcome = Battle::Outcome::UNDECIDED
  pbBattleAnimation(bgm, 0, [boss]) do
    pbSceneStandby { outcome = battle.pbStartBattle }
    BattleCreationHelperMethods.after_battle(outcome, false)
  end
  battle.net_cleanup
  battle
end

#===============================================================================
# The battle: nothing hurts him but his own confusion (see "Weaknesses" below),
# shared HP, Blood Balls only
#===============================================================================
class Battle::BloodMewtwoEncounter < Battle
  attr_reader   :boss_caught, :boss_defeated, :boss_name
  attr_accessor :blood_weak_window    # weakness damage is landing right now (:confusion / :effect)
  attr_accessor :blood_weak_move_hit  # a weakness move's hit is about to land (let it through)
  attr_accessor :blood_effect_queue   # pbEOREffectDamage: which effect hurts it next
  attr_accessor :blood_wounds_closed  # a hit on him just did nothing (for the message)

  def initialize(scene, player_party, boss_party, player_trainers, boss_name = "", max_units = 1)
    super(scene, player_party, boss_party, player_trainers, nil)
    @boss_name       = boss_name
    @max_units       = max_units
    @boss_caught     = false
    @boss_defeated   = false
    @self_damage     = 0          # local HP its weaknesses took since the last sync
    @blood_ko_pending = false     # a weakness hit took its last local HP
    @blood_weak_window = nil
    @blood_weak_move_hit = false
    @sync_received   = false
    @sync_data       = nil
    @cleared_ext     = nil
    @_boss_faint_guard = false
    @_hp_cb = NetworkClient.on("#{net}_hp_update") { |d| @sync_data = d; @sync_received = true }
    @_cl_cb = NetworkClient.on("#{net}_cleared") do |d|
      @cleared_ext   = d
      @sync_received = true
    end
  end

  def boss_battler?(b); b && b.index == 1; end

  # its server messages' prefix, and the only things that can hurt it
  # (Blood Celebi, 002_BloodCelebi.rb: "blood_celebi", [:leech_seed])
  def net; "blood_mewtwo"; end
  def weaknesses; [:confusion]; end
  def weak_to?(kind); kind ? weaknesses.include?(kind) : false; end

  # every weakness hit takes this much of its HP (BLOOD_BOSS_WEAKNESS_DIVISOR)
  def weakness_divisor; BLOOD_BOSS_WEAKNESS_DIVISOR; end
  # (rounded up: N hits always do it, never N + 1)
  def weakness_chunk(boss); [[(boss.totalhp + weakness_divisor - 1) / weakness_divisor, 1].max, boss.hp].min; end

  # this move (used by user) hits it through a weakness
  def weak_move?(move, user)
    return true if weak_to?(move.id)
    return true if weak_to?(:ohko) && move.is_a?(Battle::Move::OHKO)
    weak_to?(:transformed) && user && user.effects[PBEffects::Transform] ? true : false
  end

  # Open damage (the blood gods, 005_BloodGods.rb): everything hurts it, but
  # this battle can't take more than damage_cap (server HP) from it a turn
  def open_damage?; false; end
  def damage_cap; 0; end
  def damage_allowance
    left = damage_cap - to_units(@turn_damage.to_i)
    left <= 0 ? 0 : (left.to_f * local_max / @max_units).floor
  end
  def open_damage_landed(lost, ko)
    add_self_damage(lost)
    @turn_damage = @turn_damage.to_i + lost
    @blood_ko_pending = true if ko
  end
  def wounds_text(boss); _INTL("{1}'s wounds close instantly!", boss.pbThis); end

  # only a Blood Ball can be thrown at it (false: nothing can)
  def catchable?; true; end
  def ball_block_text; _INTL("Only a Blood Ball can hold {1}!", @boss_name); end

  # a weakness hit took lost HP: it counts (a knockout is settled in _boss_verify_before_faint)
  def weakness_landed(lost, ko)
    add_self_damage(lost)
    @blood_ko_pending = true if ko
  end
  def defeat_text(by); _INTL("{1} drove {2} to destroy itself!", by, @boss_name); end
  def elsewhere_text; _INTL("{1} has torn itself apart elsewhere too!", @boss_name); end

  # his local HP <-> the server's
  def local_max; [@battlers[1]&.totalhp.to_i, 1].max; end
  def to_units(local); (local.to_f * @max_units / local_max).ceil; end
  def to_local(units); (units.to_f / @max_units * local_max).round.clamp(0, local_max); end

  # what its weaknesses did to it
  def add_self_damage(amt); @self_damage += amt if amt > 0; end

  def restore_boss_pp
    boss = @battlers[1]
    boss&.moves&.each { |m| m.pp = m.total_pp if m && m.total_pp > 0 }
  end

  # only a Blood Ball (other balls can't be thrown at all: see ItemHandlers below)
  def pbThrowPokeBall(idxBattler, ball, catch_rate = nil, showPlayer = false)
    if ball != BLOOD_MEWTWO_BALL
      pbDisplay(_INTL("Only a Blood Ball can hold {1}!", @boss_name))
      return
    end
    super
  end

  # a catch is only kept if it's the first one (the server decides)
  def pbRecordAndStoreCaughtPokemon
    return super if @caughtPokemon.empty?
    result = nil
    cb = NetworkClient.on("#{net}_catch_result") { |d| result = d }
    NetworkClient.send_msg({ action: "#{net}_caught" })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.remove("#{net}_catch_result", cb)
    if result && result["ok"]
      @boss_caught = true
      @caughtPokemon.each(&:heal)
      return super
    end
    @caughtPokemon.clear
    if result && result["caught_by"]
      pbDisplay(_INTL("Too late! {1} already ended {2}!", result["caught_by"], @boss_name))
    else
      pbDisplay(_INTL("{1} tore free of the Blood Ball!", @boss_name))
    end
  end

  def pbEndOfRoundPhase
    @blood_weak_move_hit = false
    super
    restore_boss_pp
    return if decided?
    boss = @battlers[1]
    return unless boss && !boss.fainted?
    units = to_units(@self_damage)
    @self_damage = 0
    _sync_with_server(units, boss)
    @turn_damage = 0
    meloetta_cure(boss) if @meloetta_near && !decided? && !boss.fainted?
  end

  # Blood Meloetta is on this map (the server says so every round): her perk
  # (003_BloodMeloetta.rb)
  def meloetta_cure(boss); end

  # read by the shared Battle::Battler#pbFaint patch (012_NetworkBoss.rb)
  def _boss_faint_guard_active?; @_boss_faint_guard == true; end

  # its local HP hit 0: only a weakness can do that (anything else is undone);
  # the server says whether that's the end of it
  def _boss_verify_before_faint(boss)
    if @blood_ko_pending
      @blood_ko_pending = false
      units = to_units(@self_damage)
      @self_damage = 0
      _sync_with_server(units, boss)
    else
      boss.hp = [to_local(@last_units || @max_units), 1].max
    end
  end

  def net_cleanup
    NetworkClient.remove("#{net}_hp_update", @_hp_cb)
    NetworkClient.remove("#{net}_cleared", @_cl_cb)
  end

  private

  def _sync_with_server(units, boss)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: "#{net}_damage", damage: units })
    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    if (gone = @cleared_ext) && !@sync_data
      if gone["caught_by"]
        pbDisplay(_INTL("{1} sealed {2} in a Blood Ball!", gone["caught_by"], @boss_name))
      elsif gone["by"]
        pbDisplay(defeat_text(gone["by"]))
      else
        pbDisplay(_INTL("{1} vanished!", @boss_name))
      end
      @decision = Battle::Outcome::FLEE
      return
    end
    return unless @sync_data
    units  = @sync_data["hp"].to_i
    others = @sync_data["others_damage"].to_i
    @meloetta_near = @sync_data["meloetta_near"] == true
    @sync_data = nil
    @last_units = units
    if units <= 0
      @boss_defeated = true
      old = boss.hp
      boss.hp = 0
      @scene.pbHPChanged(boss, old) if old > 0
      @_boss_faint_guard = true
      boss.pbFaint
      @_boss_faint_guard = false
      return
    end
    old = boss.hp
    boss.hp = [to_local(units), 1].max
    @scene.pbHPChanged(boss, old) if old != boss.hp
    pbDisplay(elsewhere_text) if others > 0
  end
end

#===============================================================================
# Weaknesses, the same for every blood boss. Nothing hurts one but what its
# battle class lists in `weaknesses`, and every such hit takes exactly
# 1/BLOOD_BOSS_WEAKNESS_DIVISOR of its HP, whatever it would normally do
# (a boss can change that with its own `weakness_divisor`). What it can list:
#   :confusion      its own confusion self-hits                     (Blood Mewtwo)
#   :leech_seed     Leech Seed each turn (takes hold even on Grass) (Blood Celebi)
#   :poison :burn :frostbite      that status each turn (Toxic counts as :poison)
#   :nightmare :curse :salt_cure :splinters   those effects each turn
#   :trapping       Bind / Wrap / Fire Spin / ... each turn
#   :transformed    any damaging move from a transformed Pokemon (Transform, Imposter) (Blood Meloetta)
#   :ohko           one-hit KO moves: Fissure, Guillotine, Horn Drill, Sheer Cold (Blood Deoxys)
#   :water_paralyzed  a Water-type move's hit while the boss is paralyzed (Blood Suicune, 008_BloodSuicune.rb)
#   a move id, e.g. :DREAMEATER   every hit of that move
#===============================================================================
BLOOD_BOSS_WEAKNESS_DIVISOR = 10
BLOOD_BOSS_STATUS_WEAKNESS = { POISON: :poison, BURN: :burn, FROSTBITE: :frostbite }

class Battle
  # runs the block with effect damage on the boss counting, if it's weak to kind
  def _blood_effect_window(kind)
    boss = @battlers[1]
    return yield unless is_a?(Battle::BloodMewtwoEncounter) && weak_to?(kind) && boss && !boss.fainted?
    old = blood_weak_window
    self.blood_weak_window = :effect
    begin
      yield
    ensure
      self.blood_weak_window = old
    end
  end

  alias _blood_boss_pbEORHealingEffects pbEORHealingEffects unless method_defined?(:_blood_boss_pbEORHealingEffects)
  def pbEORHealingEffects(priority)
    boss = @battlers[1]
    kind = (boss && boss.effects[PBEffects::LeechSeed] >= 0) ? :leech_seed : nil
    _blood_effect_window(kind) { _blood_boss_pbEORHealingEffects(priority) }
  end

  alias _blood_boss_pbEORStatusProblemDamage pbEORStatusProblemDamage unless method_defined?(:_blood_boss_pbEORStatusProblemDamage)
  def pbEORStatusProblemDamage(priority)
    boss = @battlers[1]
    _blood_effect_window(boss && BLOOD_BOSS_STATUS_WEAKNESS[boss.status]) { _blood_boss_pbEORStatusProblemDamage(priority) }
  end

  # several effects in one step: queue them in the order it deals them
  alias _blood_boss_pbEOREffectDamage pbEOREffectDamage unless method_defined?(:_blood_boss_pbEOREffectDamage)
  def pbEOREffectDamage(priority)
    boss = @battlers[1]
    return _blood_boss_pbEOREffectDamage(priority) unless is_a?(Battle::BloodMewtwoEncounter) && boss
    queue = []
    if boss.takesIndirectDamage?
      queue << :nightmare if boss.effects[PBEffects::Nightmare] && boss.asleep?
      queue << :curse     if boss.effects[PBEffects::Curse]
      queue << :splinters if boss.effects[PBEffects::Splinters].to_i > 0
      queue << :salt_cure if boss.effects[PBEffects::SaltCure]
    end
    self.blood_effect_queue = queue
    begin
      _blood_boss_pbEOREffectDamage(priority)
    ensure
      self.blood_effect_queue = nil
    end
  end

  alias _blood_boss_pbEORTrappingDamage pbEORTrappingDamage unless method_defined?(:_blood_boss_pbEORTrappingDamage)
  def pbEORTrappingDamage(battler)
    _blood_effect_window(battler && battler.index == 1 ? :trapping : nil) { _blood_boss_pbEORTrappingDamage(battler) }
  end
end

class Battle::Move::StartLeechSeedTarget
  alias _blood_boss_pbFailsAgainstTarget? pbFailsAgainstTarget? unless method_defined?(:_blood_boss_pbFailsAgainstTarget?)
  def pbFailsAgainstTarget?(user, target, show_message)
    if @battle.is_a?(Battle::BloodMewtwoEncounter) && (@battle.weak_to?(:leech_seed) || @battle.open_damage?) &&
       @battle.boss_battler?(target) && target.effects[PBEffects::LeechSeed] < 0
      return false
    end
    _blood_boss_pbFailsAgainstTarget?(user, target, show_message)
  end
end

# Move hits (and its own confusion, which goes through here too)
class Battle::Move
  alias _blood_mewtwo_pbReduceDamage pbReduceDamage unless method_defined?(:_blood_mewtwo_pbReduceDamage)
  def pbReduceDamage(user, target)
    _blood_mewtwo_pbReduceDamage(user, target)
    battle = @battle
    return unless battle.is_a?(Battle::BloodMewtwoEncounter) && battle.boss_battler?(target)
    battle.blood_weak_move_hit = false
    ds = target.damageState
    return if ds.substitute || ds.disguise || ds.iceFace
    if battle.open_damage?      # (pbReduceHP counts it)
      allow = battle.damage_allowance
      battle.blood_wounds_closed = true if allow <= 0 && ds.hpLost > 0
      if ds.hpLost > allow
        ds.totalHPLost -= ds.hpLost - allow
        ds.hpLost = allow
      end
      return
    end
    confusion = battle.blood_weak_window == :confusion
    if confusion || (user != target && battle.weak_move?(self, user))
      amt = battle.weakness_chunk(target)
      ds.totalHPLost += amt - ds.hpLost
      ds.hpLost = amt
      battle.weakness_landed(amt, amt >= target.hp)
      battle.blood_weak_move_hit = !confusion   # (confusion lowers HP itself)
    elsif ds.hpLost > 0
      battle.blood_wounds_closed = true
      ds.totalHPLost -= ds.hpLost
      ds.hpLost = 0
    end
  end

  alias _blood_boss_pbInflictHPDamage pbInflictHPDamage unless method_defined?(:_blood_boss_pbInflictHPDamage)
  def pbInflictHPDamage(target)
    _blood_boss_pbInflictHPDamage(target)
  ensure
    @battle.blood_weak_move_hit = false if @battle.is_a?(Battle::BloodMewtwoEncounter)
  end
end

class Battle::Battler
  alias _blood_mewtwo_pbReduceHP pbReduceHP unless method_defined?(:_blood_mewtwo_pbReduceHP)
  def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
    battle = @battle
    unless battle.is_a?(Battle::BloodMewtwoEncounter) && battle.boss_battler?(self) && amt > 0
      return _blood_mewtwo_pbReduceHP(amt, anim, registerDamage, anyAnim)
    end
    if battle.open_damage?
      amt = [amt, battle.damage_allowance].min
      if amt <= 0
        battle.blood_wounds_closed = true
        return 0
      end
      lost = _blood_mewtwo_pbReduceHP(amt, anim, registerDamage, anyAnim)
      battle.open_damage_landed(lost, @hp <= 0)
      return lost
    end
    if battle.blood_weak_move_hit      # sized and counted in pbReduceDamage
      battle.blood_weak_move_hit = false
      return _blood_mewtwo_pbReduceHP(amt, anim, registerDamage, anyAnim)
    end
    if battle.blood_weak_window == :effect
      lost = _blood_mewtwo_pbReduceHP(battle.weakness_chunk(self), anim, registerDamage, anyAnim)
      battle.weakness_landed(lost, @hp <= 0)
      return lost
    end
    battle.blood_wounds_closed = true
    0
  end

  # pbEOREffectDamage: the next queued effect is the one hurting it
  alias _blood_boss_pbTakeEffectDamage pbTakeEffectDamage unless method_defined?(:_blood_boss_pbTakeEffectDamage)
  def pbTakeEffectDamage(amt, show_anim = true, &block)
    queue = @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.boss_battler?(self) && @battle.blood_effect_queue
    return _blood_boss_pbTakeEffectDamage(amt, show_anim, &block) unless queue
    @battle._blood_effect_window(queue.shift) { _blood_boss_pbTakeEffectDamage(amt, show_anim, &block) }
  end

  alias _blood_mewtwo_pbConfusionDamage pbConfusionDamage unless method_defined?(:_blood_mewtwo_pbConfusionDamage)
  def pbConfusionDamage(msg)
    return _blood_mewtwo_pbConfusionDamage(msg) unless @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.boss_battler?(self) &&
                                                       @battle.weak_to?(:confusion)
    @battle.blood_weak_window = :confusion
    begin
      _blood_mewtwo_pbConfusionDamage(msg)
    ensure
      @battle.blood_weak_window = nil
    end
  end

  alias _blood_mewtwo_pbUseMove pbUseMove unless method_defined?(:_blood_mewtwo_pbUseMove)
  def pbUseMove(choice, specialUsage = false)
    _blood_mewtwo_pbUseMove(choice, specialUsage)
  ensure
    if @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.blood_wounds_closed
      @battle.blood_wounds_closed = false
      boss = @battle.battlers[1]
      @battle.pbDisplay(@battle.wounds_text(boss)) if boss && !boss.fainted?
    end
  end
end

#===============================================================================
# The Blood Ball: only it can be thrown at a blood boss; x5 on them, x1 on anything else.
# Blood Meloetta on the map (her perk) makes it x3 on the others.
#===============================================================================
BLOOD_BOSS_SPECIES = [BLOOD_MEWTWO_SPECIES, :BLOODCELEBI, :BLOODMELOETTA, :BLOODDEOXYS, :BLOODCRESSELIA, :BLOODSUICUNE, :BLOODLUGIA]
BLOOD_BALL_MULT_MELOETTA_NEAR = 3
Battle::PokeBallEffects::ModifyCatchRate.add(BLOOD_MEWTWO_BALL, proc { |ball, catchRate, battle, battler|
  next catchRate unless BLOOD_BOSS_SPECIES.any? { |sp| battler.isSpecies?(sp) }
  near = !battler.isSpecies?(:BLOODMELOETTA) && battle.respond_to?(:meloetta_near?) && battle.meloetta_near?
  next catchRate * (near ? BLOOD_BALL_MULT_MELOETTA_NEAR : BLOOD_MEWTWO_BALL_MULT)
})

class << ItemHandlers
  alias _blood_mewtwo_triggerCanUseInBattle triggerCanUseInBattle unless method_defined?(:_blood_mewtwo_triggerCanUseInBattle)
  def triggerCanUseInBattle(item, pkmn, battler, move, firstAction, battle, scene, showMessages = true)
    if battle.is_a?(Battle::BloodMewtwoEncounter) && (item != BLOOD_MEWTWO_BALL || !battle.catchable?) &&
       GameData::Item.exists?(item) && GameData::Item.get(item).is_poke_ball?
      scene.pbDisplay(battle.ball_block_text) if showMessages
      return false
    end
    _blood_mewtwo_triggerCanUseInBattle(item, pkmn, battler, move, firstAction, battle, scene, showMessages)
  end
end

#===============================================================================
# Event command: wake him now (see the top of this file)
#===============================================================================
def pbSpawnBloodMewtwo(here = false)
  return false unless BloodMewtwo.unlocked? && BloodMewtwo.online?
  BloodMewtwo.report_unlock   # the server must know this game can see him
  result = nil
  cb = NetworkClient.on("blood_mewtwo_force_result") { |d| result = d }
  NetworkClient.send_msg({ action: "blood_mewtwo_force", here: here ? true : false })
  120.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.remove("blood_mewtwo_force_result", cb)
  result ? result["ok"] == true : false
rescue StandardError
  false
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_mewtwo_state") { |d| BloodMewtwo.set_state(d) }
NetworkClient.on("blood_mewtwo_cleared") { |_d| BloodMewtwo.clear }
NetworkClient.on("login_ok") { |_d| BloodMewtwo.logged_in }

EventHandlers.add(:on_enter_map, :blood_mewtwo, proc { |_old_map_id| BloodMewtwo.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_mewtwo, proc { BloodMewtwo.tick })
