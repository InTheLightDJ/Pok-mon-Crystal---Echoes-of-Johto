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
  @fading  = {}     # [map_id, event id] => System.uptime the break started
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
                 started: System.uptime - (d["elapsed_ms"].to_i / 1000.0) }
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

    def elapsed_ms; ((System.uptime - @state[:started]) * 1000).to_i; end

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
      ids
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
      now = System.uptime
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
      unless $player.party.compact.any? { |p| p.hp > 0 && !p.egg? }
        pbMessage(_INTL("Your Pokémon are too tired to fight!\nHeal them at a Pokémon Center first."))
        return
      end
      boss_name = name
      result = nil
      cb = NetworkClient.on("blood_mewtwo_engage") { |d| result = d }
      NetworkClient.send_msg({ action: "blood_mewtwo_found", map_id: $game_map.map_id })
      300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
      NetworkClient.remove("blood_mewtwo_engage", cb)
      unless result
        pbMessage(_INTL("Couldn't reach the server. Try again in a moment."))
        return
      end
      unless result["active"]
        pbMessage(_INTL("{1} vanished before you could reach it!", boss_name))
        return
      end
      return unless GameData::Species.exists?(BLOOD_MEWTWO_SPECIES)
      level = ($player.party.compact.reject(&:egg?).map(&:level).max || 5).clamp(5, GameData::GrowthRate.max_level)
      boss = Pokemon.new(BLOOD_MEWTWO_SPECIES, level)
      moves = BLOOD_MEWTWO_MOVES.select { |m| GameData::Move.exists?(m) }
      boss.forget_all_moves
      moves.each { |m| boss.learn_move(m) }
      boss.item = nil
      max_units = [result["max_hp"].to_i, 1].max
      boss.hp = [(result["hp"].to_f / max_units * boss.totalhp).round, 1].max

      player_trainers, ally_items, player_party, party_starts =
        BattleCreationHelperMethods.set_up_player_trainers([boss])
      scene  = BattleCreationHelperMethods.create_battle_scene
      battle = Battle::BloodMewtwoEncounter.new(scene, player_party, [boss], player_trainers, boss_name, max_units)
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
      clear if battle.boss_caught || battle.boss_defeated
    end
  end
end

#===============================================================================
# The battle: nothing hurts him but his own confusion, shared HP, Blood Balls only
#===============================================================================
class Battle::BloodMewtwoEncounter < Battle
  attr_reader   :boss_caught, :boss_defeated
  attr_accessor :blood_confusing      # he's hitting himself in confusion right now
  attr_accessor :blood_wounds_closed  # a hit on him just did nothing (for the message)

  def initialize(scene, player_party, boss_party, player_trainers, boss_name = "", max_units = 1)
    super(scene, player_party, boss_party, player_trainers, nil)
    @boss_name       = boss_name
    @max_units       = max_units
    @boss_caught     = false
    @boss_defeated   = false
    @self_damage     = 0          # local HP he's taken from himself since the last sync
    @blood_confusing = false
    @sync_received   = false
    @sync_data       = nil
    @cleared_ext     = nil
    @_boss_faint_guard = false
    @_hp_cb = NetworkClient.on("blood_mewtwo_hp_update") { |d| @sync_data = d; @sync_received = true }
    @_cl_cb = NetworkClient.on("blood_mewtwo_cleared") do |d|
      @cleared_ext   = d
      @sync_received = true
    end
  end

  def boss_battler?(b); b && b.index == 1; end

  # his local HP <-> the server's
  def local_max; [@battlers[1]&.totalhp.to_i, 1].max; end
  def to_units(local); (local.to_f * @max_units / local_max).ceil; end
  def to_local(units); (units.to_f / @max_units * local_max).round.clamp(0, local_max); end

  # in confusion: what he's just done to himself
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
    cb = NetworkClient.on("blood_mewtwo_catch_result") { |d| result = d }
    NetworkClient.send_msg({ action: "blood_mewtwo_caught" })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.remove("blood_mewtwo_catch_result", cb)
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
    super
    restore_boss_pp
    return if decided?
    boss = @battlers[1]
    return unless boss && !boss.fainted?
    units = to_units(@self_damage)
    @self_damage = 0
    _sync_with_server(units, boss)
  end

  # read by the shared Battle::Battler#pbFaint patch (012_NetworkBoss.rb)
  def _boss_faint_guard_active?; @_boss_faint_guard == true; end

  # his local HP hit 0: only his own confusion can do that (anything else is
  # undone); the server says whether that's the end of him
  def _boss_verify_before_faint(boss)
    if @blood_confusing.is_a?(Integer)
      units = to_units(@self_damage + @blood_confusing)
      @self_damage = 0
      @blood_confusing = true
      _sync_with_server(units, boss)
    else
      boss.hp = [to_local(@last_units || @max_units), 1].max
    end
  end

  def net_cleanup
    NetworkClient.remove("blood_mewtwo_hp_update", @_hp_cb)
    NetworkClient.remove("blood_mewtwo_cleared", @_cl_cb)
  end

  private

  def _sync_with_server(units, boss)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: "blood_mewtwo_damage", damage: units })
    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    if (gone = @cleared_ext) && !@sync_data
      if gone["caught_by"]
        pbDisplay(_INTL("{1} sealed {2} in a Blood Ball!", gone["caught_by"], @boss_name))
      elsif gone["by"]
        pbDisplay(_INTL("{1} drove {2} to destroy itself!", gone["by"], @boss_name))
      else
        pbDisplay(_INTL("{1} vanished!", @boss_name))
      end
      @decision = Battle::Outcome::FLEE
      return
    end
    return unless @sync_data
    units  = @sync_data["hp"].to_i
    others = @sync_data["others_damage"].to_i
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
    pbDisplay(_INTL("{1} has torn itself apart elsewhere too!", @boss_name)) if others > 0
  end
end

#===============================================================================
# Nothing but his confusion hurts him
#===============================================================================
class Battle::Move
  alias _blood_mewtwo_pbReduceDamage pbReduceDamage unless method_defined?(:_blood_mewtwo_pbReduceDamage)
  def pbReduceDamage(user, target)
    _blood_mewtwo_pbReduceDamage(user, target)
    battle = @battle
    return unless battle.is_a?(Battle::BloodMewtwoEncounter) && battle.boss_battler?(target)
    return if battle.blood_confusing
    if target.damageState.hpLost > 0 && !target.damageState.substitute
      battle.blood_wounds_closed = true
      target.damageState.hpLost = 0
    end
  end
end

class Battle::Battler
  alias _blood_mewtwo_pbReduceHP pbReduceHP unless method_defined?(:_blood_mewtwo_pbReduceHP)
  def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
    if @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.boss_battler?(self) && amt > 0 && !@battle.blood_confusing
      @battle.blood_wounds_closed = true
      return 0
    end
    _blood_mewtwo_pbReduceHP(amt, anim, registerDamage, anyAnim)
  end

  alias _blood_mewtwo_pbConfusionDamage pbConfusionDamage unless method_defined?(:_blood_mewtwo_pbConfusionDamage)
  def pbConfusionDamage(msg)
    return _blood_mewtwo_pbConfusionDamage(msg) unless @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.boss_battler?(self)
    before = @hp
    @battle.blood_confusing = before   # what he had (for a knockout: _boss_verify_before_faint)
    begin
      _blood_mewtwo_pbConfusionDamage(msg)
      @battle.add_self_damage(before - @hp) if @battle.blood_confusing.is_a?(Integer) && @hp > 0
    ensure
      @battle.blood_confusing = false
    end
  end

  alias _blood_mewtwo_pbUseMove pbUseMove unless method_defined?(:_blood_mewtwo_pbUseMove)
  def pbUseMove(choice, specialUsage = false)
    _blood_mewtwo_pbUseMove(choice, specialUsage)
  ensure
    if @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.blood_wounds_closed
      @battle.blood_wounds_closed = false
      boss = @battle.battlers[1]
      @battle.pbDisplay(_INTL("{1}'s wounds close instantly!", boss.pbThis)) if boss && !boss.fainted?
    end
  end
end

#===============================================================================
# The Blood Ball: only it can be thrown at him; x5 on him, x1 on anything else
#===============================================================================
Battle::PokeBallEffects::ModifyCatchRate.add(BLOOD_MEWTWO_BALL, proc { |ball, catchRate, battle, battler|
  next battler.isSpecies?(BLOOD_MEWTWO_SPECIES) ? catchRate * BLOOD_MEWTWO_BALL_MULT : catchRate
})

class << ItemHandlers
  alias _blood_mewtwo_triggerCanUseInBattle triggerCanUseInBattle unless method_defined?(:_blood_mewtwo_triggerCanUseInBattle)
  def triggerCanUseInBattle(item, pkmn, battler, move, firstAction, battle, scene, showMessages = true)
    if battle.is_a?(Battle::BloodMewtwoEncounter) && item != BLOOD_MEWTWO_BALL &&
       GameData::Item.exists?(item) && GameData::Item.get(item).is_poke_ball?
      scene.pbDisplay(_INTL("Only a Blood Ball can hold {1}!", BloodMewtwo.name)) if showMessages
      return false
    end
    _blood_mewtwo_triggerCanUseInBattle(item, pkmn, battler, move, firstAction, battle, scene, showMessages)
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_mewtwo_state") { |d| BloodMewtwo.set_state(d) }
NetworkClient.on("blood_mewtwo_cleared") { |_d| BloodMewtwo.clear }
NetworkClient.on("login_ok") { |_d| BloodMewtwo.logged_in }

EventHandlers.add(:on_enter_map, :blood_mewtwo, proc { |_old_map_id| BloodMewtwo.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_mewtwo, proc { BloodMewtwo.tick })
