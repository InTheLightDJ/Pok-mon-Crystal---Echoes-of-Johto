#===============================================================================
# The Scavenger Hunt's boss: Shadow Lugia, or on a holiday one of that
# holiday's Pokémon with its holiday look (server: handlers/shadow_lugia.js)
#
# Once a hunt's Shadow Pokémon are all found it flies around Johto or Kanto:
# the server sends the flight over its current map (shadow_lugia_state: the
# spots it flies to, how long it pauses at each, the step it takes across
# onto the connected map, and how far into the flight it is), and this game
# plays it from the same clock, so every player sees it in the same place.
# It flies through everything (Through on), a tile at a time; it only changes
# maps by stepping across onto a connected map. On a connected map that's
# loaded it's drawn there too.
#
# Walking into it (or it into you) starts the battle: a race to catch it.
# Shared HP like the Mini Bosses (032_NetworkMiniBoss.rb); it can't be
# knocked out (the server keeps its HP at 1 or more) and Poké Balls work at
# catch_hp or less. A catch is only kept if the server says it's the first.
# Caught, it's reset to level 5 (as the World Boss) and keeps its look.
#
# Its pictures: Graphics/Pokemon/SHADOWLUGIA(b).png, Icons/SHADOWLUGIA.png,
# Characters/Followers/SHADOWLUGIA.png; a holiday one: <SPECIES> <LOOK>(b).png
# (001_ScavengerHunt.rb) and Followers/<SPECIES> <LOOK>.png, or else its
# normal Followers/<SPECIES>.png, or Followers/000.png.
#===============================================================================
SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND = 1000   # must match MAX_DAMAGE_PER_HIT in handlers/shadow_lugia.js
SHADOW_LUGIA_MOVE_SPEED = 2                # 0.5 s a tile: must match MS_PER_TILE (500) on the server
SHADOW_LUGIA_CAUGHT_LEVEL = 5

#===============================================================================
# Its flight: where it is ms into a flight. Across first, then up/down (as
# the server). Returns [x, y, direction it last flew in].
#===============================================================================
module ShadowLugia
  # { species:, look:, map_id:, path: [[x, y, pause_ms]], ms_per_tile:, exit_dir:, started:,
  #   hp:, max_hp:, catch_hp: }
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false

  class << self
    attr_reader :state

    def active?; !@state.nil?; end

    # "Shadow Lugia", "Christmas Sudowoodo"
    def name
      @state ? ScavengerHunt.look_name(@state[:species], @state[:look]) : ""
    end

    # Its flight ends with a step across the map edge (exit_dir) onto the
    # connected map's tile (here one tile outside this map), a tile's time
    # after it reaches the edge.
    def position_at(path, ms_per_tile, ms, exit_dir = 0)
      t = ms
      dir = 2
      path.each_with_index do |(x, y, hover), i|
        t -= hover
        q = path[i + 1]
        if !q && t >= ms_per_tile && exit_dir > 0
          return [x + (exit_dir == 6 ? 1 : exit_dir == 4 ? -1 : 0), y + (exit_dir == 2 ? 1 : exit_dir == 8 ? -1 : 0), exit_dir]
        end
        return [x, y, dir] if t < 0 || !q
        dx, dy = q[0] - x, q[1] - y
        steps = dx.abs + dy.abs
        walked = (t / ms_per_tile).floor
        if walked < steps
          sx = [walked, dx.abs].min
          dir = sx < dx.abs ? (dx > 0 ? 6 : 4) : (dy > 0 ? 2 : 8)
          return [x + (dx <=> 0) * sx, y + (dy <=> 0) * (walked - sx), dir]
        end
        dir = dy != 0 ? (dy > 0 ? 2 : 8) : (dx > 0 ? 6 : 4) if steps > 0
        t -= steps * ms_per_tile
      end
      last = path[-1]
      [last[0], last[1], dir]
    end

    # where it is now; ahead = where it'll be a tile's time from now (the tile
    # it's flying to, so it gets there on the server's clock)
    def position(ahead = false)
      s = @state
      ms = ((System.uptime - s[:started]) * 1000).to_i
      ms += s[:ms_per_tile] if ahead
      position_at(s[:path], s[:ms_per_tile], ms, s[:exit_dir])
    end

    def set_state(d)
      if !d["active"]
        clear
        return
      end
      look = d["look"].to_s
      @state = { species: (d["species"] || "SHADOWLUGIA").to_sym, look: look.empty? ? nil : look,
                 map_id: d["map_id"].to_i, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 hp: d["hp"].to_i, max_hp: d["max_hp"].to_i, catch_hp: d["catch_hp"].to_i,
                 started: System.uptime - (d["elapsed_ms"].to_i / 1000.0) }
      # a new flight: drawn afresh, unless it's still stepping across onto this map
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id] &&
                            @char.species == @state[:species]
    end

    def clear
      @state = nil
      destroy_sprite
    end

    #---------------------------------------------------------------------------
    # The flying boss on the map
    #---------------------------------------------------------------------------
    # the loaded map it's on (this one or a connected one), or nil
    def host_map
      id = @state[:map_id]
      return $game_map if $game_map&.map_id == id
      return $map_factory.getMapNoAdd(id) if $map_factory&.hasMap?(id)
      nil
    end

    # Followers/<SPECIES> <LOOK>, else Followers/<SPECIES>, else Followers/000
    # (the stand-in for Pokémon without a follower sprite)
    def character_name
      base = "Followers/#{@state[:species]}"
      looked = "#{base} #{@state[:look]}"
      return looked if @state[:look] && pbResolveBitmap("Graphics/Characters/#{looked}")
      pbResolveBitmap("Graphics/Characters/#{base}") ? base : "Followers/000"
    end

    def destroy_sprite
      @sprite&.dispose
      @sprite = nil
      @char = nil
    end

    def tick
      return destroy_sprite unless @state && $scene.is_a?(Scene_Map) && ScavengerHunt.online?
      map = host_map
      # still stepping across onto its new map: finish that step first
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
        @char = ShadowLugiaCharacter.new(map, @state[:species], character_name)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      check_trigger
    end

    # standing on the same tile as it starts the battle (once per meeting)
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
      species, look, boss_name, catch_hp = @state[:species], @state[:look], name, @state[:catch_hp]
      result = nil
      cb = NetworkClient.on("shadow_lugia_engage") { |d| result = d }
      NetworkClient.send_msg({ action: "shadow_lugia_found", map_id: $game_map.map_id })
      300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
      NetworkClient.remove("shadow_lugia_engage", cb)
      unless result
        pbMessage(_INTL("Couldn't reach the server. Try again in a moment."))
        return
      end
      unless result["active"]
        pbMessage(_INTL("{1} flew off before you could reach it!", boss_name))
        return
      end
      return unless GameData::Species.exists?(species)
      level = ($player.party.compact.reject(&:egg?).map(&:level).max || 5).clamp(5, GameData::GrowthRate.max_level)
      boss = Pokemon.new(species, level)
      boss.event_look = look
      NetworkMiniBoss._clean_boss_moveset(boss)
      boss.instance_variable_set(:@totalhp, result["max_hp"].to_i)
      boss.hp = [result["hp"].to_i, 1].max

      player_trainers, ally_items, player_party, party_starts =
        BattleCreationHelperMethods.set_up_player_trainers([boss])
      scene  = BattleCreationHelperMethods.create_battle_scene
      battle = Battle::ShadowLugiaEncounter.new(scene, player_party, [boss], player_trainers, boss_name, catch_hp)
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
      clear if battle.boss_caught
    end
  end
end

#===============================================================================
# The flying boss: Through on, drawn above everything
#===============================================================================
class ShadowLugiaCharacter < Game_Character
  attr_reader :species

  # "airborne": no grass rustling / water ripples under it, no bush depth
  def name; "Hunt boss (airborne)"; end

  def initialize(map, species = :SHADOWLUGIA, character_name = "Followers/SHADOWLUGIA")
    super(map)
    @species        = species
    @character_name = character_name
    @through        = true
    @always_on_top  = true
    @walk_anime     = true
    @step_anime     = true
    self.move_speed = SHADOW_LUGIA_MOVE_SPEED
  end

  # it isn't a real event: stepping doesn't set off tile effects
  def triggerLeaveTile; end

  # a step ends with the game's step handlers (:on_step_taken), which expect
  # a tile on a map; its step across a map edge mustn't stop the game
  def update_move
    super
  rescue StandardError
    @move_timer = nil
  end

  # one tile away: fly there; further (it was off screen, a menu was open): jump there
  def fly_to(x, y, dir)
    if (x - @x).abs + (y - @y).abs == 1
      @move_initial_x = @x
      @move_initial_y = @y
      @direction = x > @x ? 6 : x < @x ? 4 : y > @y ? 2 : 8
      @x, @y = x, y
      @move_timer = 0.0
    else
      moveto(x, y) if x != @x || y != @y
      @direction = dir
    end
  end
end

#===============================================================================
# The battle: shared HP (as Battle::MiniBossEncounter), a race to catch it
#===============================================================================
class Battle::ShadowLugiaEncounter < Battle
  attr_reader :boss_caught

  def initialize(scene, player_party, boss_party, player_trainers, boss_name = "", catch_hp = 0)
    super(scene, player_party, boss_party, player_trainers, nil)
    @boss_name         = boss_name
    @catch_hp          = catch_hp
    @boss_caught       = false
    @hp_before_turn    = nil
    @sync_received     = false
    @sync_data         = nil
    @boss_cleared_ext  = nil
    @_boss_faint_guard = false
    @_hp_cb = NetworkClient.on("shadow_lugia_hp_update") { |d| @sync_data = d; @sync_received = true }
    @_cl_cb = NetworkClient.on("shadow_lugia_cleared") do |d|
      @boss_cleared_ext = d
      @sync_received    = true
    end
  end

  # only once it's worn down to catch_hp or less
  def pbThrowPokeBall(idxBattler, ball, catch_rate = nil, showPlayer = false)
    boss_bat = @battlers[1]
    if boss_bat && boss_bat.hp > @catch_hp
      pbDisplay(_INTL("{1} still has {2} HP! Wear it down to {3} HP or less to catch it.",
                      @boss_name, boss_bat.hp, @catch_hp))
      return
    end
    super
  end

  # a catch is only kept if it's the first one (the server decides)
  def pbRecordAndStoreCaughtPokemon
    return super if @caughtPokemon.empty?
    result = nil
    cb = NetworkClient.on("shadow_lugia_catch_result") { |d| result = d }
    NetworkClient.send_msg({ action: "shadow_lugia_caught" })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.remove("shadow_lugia_catch_result", cb)
    if result && result["ok"]
      @boss_caught = true
      @caughtPokemon.each do |pkmn|
        pkmn.level = SHADOW_LUGIA_CAUGHT_LEVEL
        pkmn.calc_stats
        pkmn.heal
      end
      return super
    end
    @caughtPokemon.clear
    if result && result["caught_by"]
      pbDisplay(_INTL("Too late! {1} caught {2} first!", result["caught_by"], @boss_name))
    else
      pbDisplay(_INTL("{1} broke free and flew off!", @boss_name))
    end
  end

  def pbCanChooseMove?(idxBattler, idxMove, showMessages, *args)
    if idxBattler == 0
      move = @battlers[idxBattler]&.moves&.[](idxMove)
      if move && BOSS_BANNED_PLAYER_MOVES.include?(move.id)
        pbDisplay(_INTL("{1} is immune to that move!", @boss_name)) if showMessages
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
    if boss_bat && boss_bat.hp > 0 && @hp_before_turn.to_i - boss_bat.hp > SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND
      pbDisplay(_INTL("{1} resisted the attack's full force!", @boss_name))
      boss_bat.hp = [@hp_before_turn.to_i - SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND, 1].max
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
    eor_hp = boss_bat ? boss_bat.hp : nil
    super
    return if decided?
    boss_bat = @battlers[1]
    return unless boss_bat && !boss_bat.fainted?
    boss_bat.hp = eor_hp if eor_hp && boss_bat.hp < eor_hp
    damage = [(@hp_before_turn || 0) - boss_bat.hp, 0].max
    if damage > SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND
      pbDisplay(_INTL("{1} resisted the attack's full force!", @boss_name))
      boss_bat.hp = [(@hp_before_turn || 0) - SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND, 1].max
      damage      = SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND
    end
    _sync_with_server(damage, boss_bat)
    @hp_before_turn = boss_bat.hp
  end

  # read by the shared Battle::Battler#pbReduceHP / #pbFaint patches (012_NetworkBoss.rb)
  def boss_hit_cap; SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND; end
  def _boss_faint_guard_active?; @_boss_faint_guard == true; end

  # its local HP hit 0: the server keeps it at 1 or more, it can't be knocked out
  def _boss_verify_before_faint(boss_bat)
    damage = [[(@hp_before_turn || 0) - boss_bat.hp, 0].max, SHADOW_LUGIA_MAX_DAMAGE_PER_ROUND].min
    damage = 1 if damage < 1 && (@hp_before_turn || 0) > 0
    @_boss_faint_guard = true
    _sync_with_server(damage, boss_bat)
    @_boss_faint_guard = false
    return if decided?
    boss_bat.hp = 1 if boss_bat.hp <= 0
    @hp_before_turn = boss_bat.hp
    pbDisplay(_INTL("{1} shrugs off the blow and remains standing!", @boss_name))
  end

  def net_cleanup
    NetworkClient.remove("shadow_lugia_hp_update", @_hp_cb)
    NetworkClient.remove("shadow_lugia_cleared", @_cl_cb)
  end

  private

  def _sync_with_server(damage, boss_bat)
    @sync_received = false
    @sync_data     = nil
    NetworkClient.send_msg({ action: "shadow_lugia_damage", damage: damage })
    120.times do
      Graphics.update; Input.update; NetworkClient.update
      break if @sync_received
    end
    if (gone = @boss_cleared_ext)   # caught by someone else, or flew away
      if gone["caught_by"]
        pbDisplay(_INTL("{1} caught {2}! The race is over.", gone["caught_by"], @boss_name))
      else
        pbDisplay(_INTL("{1} flew off!", @boss_name))
      end
      @decision = Battle::Outcome::FLEE
      return
    end
    return unless @sync_data
    hp     = [@sync_data["hp"].to_i, 1].max
    others = @sync_data["others_damage"].to_i
    @sync_data = nil
    old = boss_bat.hp
    boss_bat.hp = hp
    @scene.pbHPChanged(boss_bat, old) if old != hp
    pbDisplay(_INTL("Other trainers dealt {1} damage to it!", others)) if others > 0
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("shadow_lugia_state") { |d| ShadowLugia.set_state(d) }
NetworkClient.on("shadow_lugia_cleared") { |_d| ShadowLugia.clear }

EventHandlers.add(:on_enter_map, :shadow_lugia, proc { |_old_map_id| ShadowLugia.destroy_sprite })

EventHandlers.add(:on_frame_update, :shadow_lugia, proc { ShadowLugia.tick })
