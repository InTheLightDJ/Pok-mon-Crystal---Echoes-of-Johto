#===============================================================================
# Blood Suicune (server: handlers/blood_suicune.js)
#
# The cave blood boss. Every player with 16 badges sees it (no switch, no
# event). It walks the floors of the caves, and every few minutes teleports to
# another one. Come within 6 tiles and it stops for a moment, the Teleport
# animation plays, and it's gone to another cave: you have to reach it before
# then to fight it.
#
# Now and then it teleports into the Goldenrod Game Corner or the Celadon club
# (both floors) instead and breaks everything there but the exits (they flash
# red, fade and are gone while it's alive). Coming near drives it off there too.
#
# The battle: nothing hurts it but Water-type moves, and only while it's
# paralyzed ("Weaknesses" in 001_BloodMewtwo.rb): each hit takes a tenth of its
# HP, shared by everyone. Blood Balls only; back once a week after it's beaten.
#===============================================================================
BLOOD_SUICUNE_SPECIES = :BLOODSUICUNE
BLOOD_SUICUNE_MOVES   = [:HYDROPUMP, :ICEBEAM, :EXTRASENSORY, :CRUNCH]
BLOOD_SUICUNE_CHARSET = "Followers/BLOODSUICUNE"
BLOOD_SUICUNE_BADGES  = 16

# drawn among the cave walls (not above everything, as the flying bosses are)
class BloodSuicuneCharacter < ShadowLugiaCharacter
  def name; "Blood Suicune"; end

  def initialize(map, species, character_name)
    super
    @always_on_top = false
  end
end

module BloodSuicune
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @fading = {}
  @warp_shown = nil     # the plan (its start) whose Teleport animation has played

  class << self
    attr_reader :state, :char, :sprite     # (009_BloodLugia.rb: HP bars, duel hits)

    def name; GameData::Species.exists?(BLOOD_SUICUNE_SPECIES) ? GameData::Species.get(BLOOD_SUICUNE_SPECIES).name : "Blood Suicune"; end

    def can_see?; $player ? $player.badge_count >= BLOOD_SUICUNE_BADGES : false; end
    def active?; !@state.nil? && can_see?; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      broken = {}
      (d["broken"] || {}).each { |k, v| broken[k.to_i] = v.map(&:to_i) }
      @state = { map_id: d["map_id"].to_i, mode: d["mode"].to_s, path: d["path"].map { |p| p.map(&:to_i) },
                 breaks: (d["breaks"] || []).map { |b| b.map(&:to_i) }, broken: broken,
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, warp_at: d["warp_at"].to_i, gone_at: d["gone_at"].to_i,
                 hp: d["hp"].to_i, max_hp: d["max_hp"].to_i,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      # a new place (it teleported): a new sprite there
      destroy_sprite if @char && @char.map.map_id != @state[:map_id]
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
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, 0)
    end

    def warping?; @state && @state[:mode] == "warp"; end
    def gone?; warping? && elapsed_ms >= @state[:gone_at]; end

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

    def tick
      return destroy_sprite unless active? && BloodMewtwo.online? && $scene.is_a?(Scene_Map)
      break_events
      return destroy_sprite if gone?
      map = host_map
      return destroy_sprite unless map
      if !@char || @char.map != map || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_SUICUNE_CHARSET}") ? BLOOD_SUICUNE_CHARSET : "Followers/000"
        @char = BloodSuicuneCharacter.new(map, BLOOD_SUICUNE_SPECIES, charset)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.move_speed = BLOOD_BOSS_SPEEDS[@state[:ms_per_tile]] || 3
      @char.fly_to(*position(true)) unless @char.moving?
      show_warp
      @char.update
      @sprite.update
      check_trigger
    end

    # it stopped (someone came near, or it's moving on): the Teleport animation
    def show_warp
      return unless warping? && elapsed_ms >= @state[:warp_at] && @warp_shown != @state[:started]
      @warp_shown = @state[:started]
      @char.animation_id = (GhostTrainer.teleport_anim_id rescue 16)
      pbSEPlay("Teleport") if @char.map == $game_map && FileTest.audio_exist?("Audio/SE/Teleport")
    end

    # what it's broken in the clubs (as Blood Mewtwo's victims)
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

    # touch it (before it's gone) to fight it
    def check_trigger
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        battle = pbBloodBossBattle("blood_suicune", BLOOD_SUICUNE_SPECIES, BLOOD_SUICUNE_MOVES,
                                   Battle::BloodSuicuneEncounter, name)
        clear if battle && (battle.boss_caught || battle.boss_defeated)
      end
    end
  end
end

#===============================================================================
# The battle: only Water-type moves hurt it, and only while it's paralyzed
#===============================================================================
class Battle::BloodSuicuneEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_suicune"; end
  def weaknesses; [:water_paralyzed]; end
  def wounds_text(boss)
    return _INTL("Water can't reach {1} while it moves so freely!", boss.pbThis) if boss.status != :PARALYSIS
    _INTL("{1}'s wounds close instantly! Only water can hurt it now!", boss.pbThis)
  end
  def defeat_text(by); _INTL("{1} struck {2} down!", by, @boss_name); end
  def elsewhere_text; _INTL("{1} has been struck elsewhere too!", @boss_name); end
end

# the weakness itself (see "Weaknesses" in 001_BloodMewtwo.rb):
#   :water_paralyzed   a Water-type move's hit while the boss is paralyzed (Blood Suicune)
class Battle::BloodMewtwoEncounter
  alias _blood_suicune_weak_move? weak_move? unless method_defined?(:_blood_suicune_weak_move?)
  def weak_move?(move, user)
    if weak_to?(:water_paralyzed)
      boss = @battlers[1]
      type = move.calcType || move.type
      return true if boss && boss.status == :PARALYSIS && type == :WATER
    end
    _blood_suicune_weak_move?(move, user)
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_suicune_state") { |d| BloodSuicune.set_state(d) }
NetworkClient.on("blood_suicune_cleared") { |_d| BloodSuicune.clear }

EventHandlers.add(:on_enter_map, :blood_suicune, proc { |_old_map_id| BloodSuicune.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_suicune, proc { BloodSuicune.tick })
