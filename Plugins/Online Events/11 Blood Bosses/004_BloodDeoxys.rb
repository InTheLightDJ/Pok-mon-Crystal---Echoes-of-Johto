#===============================================================================
# Blood Deoxys (server: handlers/blood_deoxys.js)
#
# The fourth blood boss. Everyone who's beaten the Elite Four sees him
# (switch BLOOD_DEOXYS_E4_SWITCH, or a Hall of Fame entry); no event needed.
# Like Blood Mewtwo he flies over the routes and towns breaking things, but
# only DOORS AND WARP POINTS (everything with a Transfer Player command): they
# flash red, fade and are gone while he's alive.
#
# He hunts AFK players too: stand still long enough (the server's AFK_MS) on
# one of his maps and he flies over and circles you, 2 tiles away. Still
# standing there when the circle closes, and you're taken to the New
# Dimension (map 508, 14,4); move first and he gives up.
#
# The battle: nothing hurts him but one-hit KO moves (Fissure, Guillotine,
# Horn Drill, Sheer Cold), and each only takes a third of his HP
# ("Weaknesses" in 001_BloodMewtwo.rb): three hits. They work whatever the
# levels are (but still only hit 30% of the time). Shared HP, Blood Balls
# only, back once a week after he's beaten.
#
# An event can wake him sooner:  Script: pbSpawnBloodDeoxys        (wherever he'd wake)
#                                Script: pbSpawnBloodDeoxys(true)  (next to the player)
# (only for a player who's beaten the Elite Four, not while he's awake; true if he woke)
#===============================================================================
BLOOD_DEOXYS_SPECIES    = :BLOODDEOXYS
BLOOD_DEOXYS_MOVES      = [:PSYCHOBOOST, :EXTREMESPEED, :SUPERPOWER, :DARKPULSE]
BLOOD_DEOXYS_CHARSET    = "Followers/BLOODDEOXYS"
BLOOD_DEOXYS_E4_SWITCH  = 12          # "Defeated Elite Four"
BLOOD_DEOXYS_WEAKNESS_DIVISOR = 3     # each one-hit KO move takes 1/3 of his HP
BLOOD_DEOXYS_WEAKNESS_DIVISOR_MELOETTA = 6   # ...1/6 while Blood Meloetta is on the map

# a tile's time (ms) => Game_Character move speed
BLOOD_BOSS_SPEEDS = { 1000 => 1, 500 => 2, 250 => 3, 125 => 4, 100 => 5, 50 => 6 }

module BloodDeoxys
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @fading  = {}
  @abduct  = nil    # [map id, x, y]: the server's sending this game to the New Dimension

  class << self
    attr_reader :state

    def name; GameData::Species.exists?(BLOOD_DEOXYS_SPECIES) ? GameData::Species.get(BLOOD_DEOXYS_SPECIES).name : "Blood Deoxys"; end

    def beaten_e4?
      return false unless $game_switches && $PokemonGlobal
      $game_switches[BLOOD_DEOXYS_E4_SWITCH] || $PokemonGlobal.hallOfFameLastNumber.to_i > 0
    end

    def active?; !@state.nil? && BloodBoss.released?(:deoxys); end

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

    def clear
      @state = nil
      @fading.clear
      destroy_sprite
    end

    def elapsed_ms; ((System.unscaled_uptime - @state[:started]) * 1000).to_i; end

    def position(ahead = false)
      ms = elapsed_ms
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, @state[:exit_dir])
    end

    def broken_on(map_id)
      ids = (@state[:broken][map_id] || []).dup
      if map_id == @state[:map_id]
        ms = elapsed_ms
        @state[:breaks].each { |eid, at| ids << eid if at <= ms }
      end
      ids
    end

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

    def free?
      $scene.is_a?(Scene_Map) && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
        !$game_temp.message_window_showing && !$game_player.moving? && !$game_temp.player_transferring
    end

    def tick
      if Graphics.frame_count % 60 == 0
        BloodBoss.release(:deoxys) if !BloodBoss.released?(:deoxys) && beaten_e4?
        BloodBoss.report_release(:deoxys)
      end
      do_abduct if @abduct && free?
      after_abduct if @abducted_to
      return destroy_sprite unless active? && BloodMewtwo.online? && $scene.is_a?(Scene_Map)
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
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_DEOXYS_CHARSET}") ? BLOOD_DEOXYS_CHARSET : "Followers/000"
        @char = ShadowLugiaCharacter.new(map, BLOOD_DEOXYS_SPECIES, charset)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.move_speed = BLOOD_BOSS_SPEEDS[@state[:ms_per_tile]] || 3
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      check_trigger
    end

    # the doors and warps he's broken (as Blood Mewtwo's victims)
    def break_events
      now = System.unscaled_uptime
      BloodMewtwo.loaded_maps.each do |map|
        broken_on(map.map_id).each do |eid|
          ev = map.events[eid]
          next if !ev || ev.instance_variable_get(:@erased) || BloodMewtwo.busy?(map, eid)
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
            BloodMewtwo.tint(map, ev)
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

    def check_trigger
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        battle = pbBloodBossBattle("blood_deoxys", BLOOD_DEOXYS_SPECIES, BLOOD_DEOXYS_MOVES,
                                   Battle::BloodDeoxysEncounter, name)
        clear if battle && (battle.boss_caught || battle.boss_defeated)
      end
    end

    #---------------------------------------------------------------------------
    # The circle closed round this (AFK) player: off to the New Dimension
    #---------------------------------------------------------------------------
    def abduct(d); @abduct = [d["map_id"].to_i, d["x"].to_i, d["y"].to_i]; end

    def do_abduct
      map_id, x, y = @abduct
      @abduct = nil
      return unless map_id > 0
      $game_temp.player_new_map_id    = map_id
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = 2
      $game_temp.player_transferring  = true
      @abducted_to = map_id
    end

    # there now: what happened
    def after_abduct
      return unless @abducted_to && $game_map&.map_id == @abducted_to && free?
      @abducted_to = nil
      pbMessage(_INTL("{1} circled you... and pulled you into another dimension!", name))
    end
  end
end

#===============================================================================
# The battle: only one-hit KO moves hurt him, a third of his HP each
#===============================================================================
class Battle::BloodDeoxysEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_deoxys"; end
  def weaknesses; [:ohko]; end
  # Blood Meloetta on the map: a sixth instead of a third
  def weakness_divisor; meloetta_near? ? BLOOD_DEOXYS_WEAKNESS_DIVISOR_MELOETTA : BLOOD_DEOXYS_WEAKNESS_DIVISOR; end
  def defeat_text(by); _INTL("{1} struck {2} down!", by, @boss_name); end
  def elsewhere_text; _INTL("{1} has been struck elsewhere too!", @boss_name); end
end

# one-hit KO moves work on a blood boss weak to them whatever the levels (and
# through Sturdy), at their usual 30%
class Battle::Move::OHKO
  def _blood_ohko_boss?(target)
    @battle.is_a?(Battle::BloodMewtwoEncounter) && @battle.weak_to?(:ohko) && @battle.boss_battler?(target)
  end

  alias _blood_deoxys_pbFailsAgainstTarget? pbFailsAgainstTarget? unless method_defined?(:_blood_deoxys_pbFailsAgainstTarget?)
  def pbFailsAgainstTarget?(user, target, show_message)
    return false if _blood_ohko_boss?(target)
    _blood_deoxys_pbFailsAgainstTarget?(user, target, show_message)
  end

  alias _blood_deoxys_pbAccuracyCheck pbAccuracyCheck unless method_defined?(:_blood_deoxys_pbAccuracyCheck)
  def pbAccuracyCheck(user, target)
    return @battle.pbRandom(100) < @accuracy if _blood_ohko_boss?(target)
    _blood_deoxys_pbAccuracyCheck(user, target)
  end
end

#===============================================================================
# Event command: wake him now (see the top of this file)
#===============================================================================
def pbSpawnBloodDeoxys(here = false)
  return false unless BloodDeoxys.beaten_e4? && BloodMewtwo.online?
  BloodBoss.release(:deoxys)
  BloodBoss.report_release(:deoxys, true)
  result = nil
  cb = NetworkClient.on("blood_deoxys_force_result") { |d| result = d }
  NetworkClient.send_msg({ action: "blood_deoxys_force", here: here ? true : false })
  120.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.remove("blood_deoxys_force_result", cb)
  result ? result["ok"] == true : false
rescue StandardError
  false
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_deoxys_state") { |d| BloodDeoxys.set_state(d) }
NetworkClient.on("blood_deoxys_cleared") { |_d| BloodDeoxys.clear }
NetworkClient.on("blood_deoxys_abduct") { |d| BloodDeoxys.abduct(d) }

EventHandlers.add(:on_enter_map, :blood_deoxys, proc { |_old_map_id| BloodDeoxys.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_deoxys, proc { BloodDeoxys.tick })
