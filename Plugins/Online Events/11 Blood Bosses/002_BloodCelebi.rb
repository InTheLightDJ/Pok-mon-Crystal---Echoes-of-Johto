#===============================================================================
# Blood Celebi (server: handlers/blood_celebi.js)
#
# Blood Mewtwo's partner. It doesn't need his switch 116. Losing the
# Bug-Catching Contest (someone else wins) releases it for the WHOLE server and
# wakes it if it's gone - the only way it comes back (no respawn timer). An
# event can do the same:
#           Script: pbReleaseBloodCelebi        (and wakes it now, if it's resting)
#           Script: pbReleaseBloodCelebi(true)  (and wakes it next to the player)
# It flies over the routes and towns like him, but what it does depends on him:
#   Blood Mewtwo awake:   it RESTORES. It flies to the events that are gone
#                         (the ones he broke on maps he's left, and its own)
#                         and they come back (a green flash as they fade in).
#   Blood Mewtwo resting: it BREAKS them, the way he does.
# Events the game itself erased (Erase Event) are never brought back.
#
# The battle: nothing can hurt it but Leech Seed (it works on it, though
# it's part Grass). Only what Leech Seed drains counts, shared by everyone
# (the server's HP). Drained to 0 it dies for everyone. Its moves never run
# out of PP. Only a Blood Ball can catch it (the first catch the server
# hears of wins).
#
# It comes back once a week after it's beaten (server). An event can wake it
# sooner:   Script: pbSpawnBloodCelebi        (wherever it'd wake)
#           Script: pbSpawnBloodCelebi(true)  (next to the player; on a
#                                              route or town only)
# Only once it's been released for this player, not while it's awake;
# true if it woke, false if not; it shows no message itself.
#===============================================================================
BLOOD_CELEBI_SPECIES    = :BLOODCELEBI
BLOOD_CELEBI_MOVES      = [:GIGADRAIN, :BITTERMALICE, :PSYCHIC, :ANCIENTPOWER]
BLOOD_CELEBI_MOVE_SPEED = 3           # 0.25 s a tile: must match MS_PER_TILE (250) on the server
BLOOD_CELEBI_FADE_TIME  = 0.6         # seconds an event takes to fade away / back in
BLOOD_CELEBI_BREAK_SE   = "Anim/Bite"
BLOOD_CELEBI_RESTORE_SE = "Anim/Recover"
BLOOD_CELEBI_CHARSET    = "Followers/BLOODCELEBI"

module BloodCelebi
  # { map_id:, mode: "break" | "restore", path:, acts: [[event id, ms]],
  #   broken: { map_id => [event ids] }, ms_per_tile:, exit_dir:, started:, hp:, max_hp: }
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @fading    = {}   # [map_id, event id] => System.unscaled_uptime it started fading out
  @restoring = {}   # [map_id, event id] => System.unscaled_uptime it started fading in
  @alerted   = {}   # [plan start, event id] => true: "!" shown over its next victim

  class << self
    attr_reader :state

    def name; GameData::Species.exists?(BLOOD_CELEBI_SPECIES) ? GameData::Species.get(BLOOD_CELEBI_SPECIES).name : "Blood Celebi"; end
    def active?; !@state.nil? && BloodBoss.released?(:celebi); end
    def restoring?; @state && @state[:mode] == "restore"; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      broken = {}
      (d["broken"] || {}).each { |k, v| broken[k.to_i] = v.map(&:to_i) }
      @state = { map_id: d["map_id"].to_i, mode: d["mode"].to_s, path: d["path"].map { |p| p.map(&:to_i) },
                 acts: (d["acts"] || []).map { |b| b.map(&:to_i) }, broken: broken,
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 hp: d["hp"].to_i, max_hp: d["max_hp"].to_i,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id]
    end

    # it's gone (dead or caught): what it broke comes back when its map is
    # loaded again
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

    # the events of map map_id it has worked on so far in this plan
    def done_on(map_id)
      return [] unless @state && map_id == @state[:map_id]
      ms = elapsed_ms
      @state[:acts].select { |_, at| at <= ms }.map(&:first)
    end

    # the ones it has brought back (Blood Mewtwo's broken_on leaves them out)
    def restored_on(map_id)
      restoring? ? done_on(map_id) : []
    end

    # the ones it has broken
    def broken_on(map_id)
      return [] unless @state
      ids = (@state[:broken][map_id] || []).dup
      ids.concat(done_on(map_id)) unless restoring?
      ids - restored_on(map_id)
    end

    #---------------------------------------------------------------------------
    # It on the map
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
      BloodBoss.report_release(:celebi) if Graphics.frame_count % 60 == 0
      return destroy_sprite unless active? && BloodMewtwo.online? && $scene.is_a?(Scene_Map)
      update_events
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
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_CELEBI_CHARSET}") ? BLOOD_CELEBI_CHARSET : "Followers/000"
        @char = ShadowLugiaCharacter.new(map, BLOOD_CELEBI_SPECIES, charset)
        @char.move_speed = BLOOD_CELEBI_MOVE_SPEED
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      hunt_events(map) unless restoring?
      check_trigger
    end

    #---------------------------------------------------------------------------
    # The events it breaks / brings back
    #---------------------------------------------------------------------------
    def update_events
      now = System.unscaled_uptime
      BloodMewtwo.loaded_maps.each do |map|
        broken_on(map.map_id).each { |eid| break_event(map, eid, now) }
        restored_on(map.map_id).each { |eid| restore_event(map, eid, now) }
      end
      fade_in(now)
    end

    # just broken on a map on screen: it flashes red and fades (with a
    # sound); otherwise it's just gone
    def break_event(map, eid, now)
      ev = map.events[eid]
      return if !ev || ev.instance_variable_get(:@erased) || BloodMewtwo.busy?(map, eid)
      key = [map.map_id, eid]
      if (start = @fading[key])
        t = (now - start) / BLOOD_CELEBI_FADE_TIME
        if t >= 1
          ev.erase
          ev.opacity = 255
          @fading.delete(key)
        else
          ev.opacity = (255 * (1 - t)).to_i
        end
      elsif just_done?(map, eid)
        @fading[key] = now
        tint(map, ev, Color.new(200, 0, 0, 170))
        play_se(map, BLOOD_CELEBI_BREAK_SE)
      else
        ev.erase
      end
    end

    # gone (broken by Blood Mewtwo or by it, not erased by the game itself):
    # it's back, fading in with a green flash if it's just happened
    def restore_event(map, eid, now)
      ev = map.events[eid]
      return if !ev || !ev.instance_variable_get(:@erased)
      return if $PokemonMap&.erasedEvents&.[]([map.map_id, eid])
      @fading.delete([map.map_id, eid])
      ev.instance_variable_set(:@erased, false)
      ev.refresh
      ev.opacity = 255
      return unless just_done?(map, eid)
      @restoring[[map.map_id, eid]] = now
      ev.opacity = 0
      play_se(map, BLOOD_CELEBI_RESTORE_SE)
    end

    def fade_in(now)
      @restoring.delete_if do |(map_id, eid), start|
        map = BloodMewtwo.loaded_maps.find { |m| m.map_id == map_id }
        ev = map&.events&.[](eid)
        next true unless ev
        t = ((now - start) / BLOOD_CELEBI_FADE_TIME).clamp(0, 1)
        ev.opacity = (255 * t).to_i
        tint(map, ev, Color.new(80, 255, 120, (170 * (1 - t)).to_i))
        t >= 1
      end
    end

    def just_done?(map, eid)
      return false unless map.map_id == @state[:map_id]
      b = @state[:acts].find { |id, _| id == eid }
      b && elapsed_ms - b[1] < 2000
    end

    def tint(map, ev, color)
      ss = $scene.spriteset(map.map_id) rescue nil
      sprites = ss&.instance_variable_get(:@character_sprites) || []
      sprites.each { |s| s.color = color if s.character == ev && !s.disposed? }
    rescue StandardError
      nil
    end

    def play_se(map, se)
      pbSEPlay(se) if map == $game_map && FileTest.audio_exist?("Audio/SE/#{se}")
    end

    # breaking: the ones it's still coming for stop where they are; the next
    # one sees it coming
    def hunt_events(map)
      return unless map.map_id == @state[:map_id]
      ms = elapsed_ms
      upcoming = @state[:acts].select { |_, at| at > ms }
      upcoming.each do |eid, _|
        ev = map.events[eid]
        ev.instance_variable_set(:@move_type, 0) if ev
      end
      return if upcoming.empty?
      eid = upcoming[0][0]
      key = [@state[:started].round(3), eid]
      return if @alerted[key]
      ev = map.events[eid]
      return unless ev && !ev.instance_variable_get(:@erased)
      @alerted[key] = true
      ev.animation_id = BloodMewtwo.exclaim_anim_id
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
        battle = pbBloodBossBattle("blood_celebi", BLOOD_CELEBI_SPECIES, BLOOD_CELEBI_MOVES,
                                   Battle::BloodCelebiEncounter, name)
        clear if battle && (battle.boss_caught || battle.boss_defeated)
      end
    end
  end
end

#===============================================================================
# The battle: Blood Mewtwo's (001_BloodMewtwo.rb), but only Leech Seed hurts it
#===============================================================================
class Battle::BloodCelebiEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_celebi"; end
  def weaknesses; [:leech_seed]; end
  def defeat_text(by); _INTL("{1}'s Leech Seed drained {2} dry!", by, @boss_name); end
  def elsewhere_text; _INTL("Leech Seed has drained {1} elsewhere too!", @boss_name); end
end

# How Leech Seed hurts it (1/10 a turn, works on Grass) is shared by every
# blood boss: "Weaknesses" in 001_BloodMewtwo.rb

#===============================================================================
# Event command: wake it now (see the top of this file)
#===============================================================================
def pbSpawnBloodCelebi(here = false)
  return false unless BloodBoss.released?(:celebi) && BloodMewtwo.online?
  BloodBoss.report_release(:celebi)   # the server must know this game can see it
  result = nil
  cb = NetworkClient.on("blood_celebi_force_result") { |d| result = d }
  NetworkClient.send_msg({ action: "blood_celebi_force", here: here ? true : false })
  120.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.remove("blood_celebi_force_result", cb)
  result ? result["ok"] == true : false
rescue StandardError
  false
end

# Release it for this player (kept in the save), and wake it now if it's
# resting (here: next to the player). Always true; offline, the server hears
# of it at the next login.
def pbReleaseBloodCelebi(here = false)
  BloodBoss.release(:celebi)
  return true unless BloodMewtwo.online?
  BloodBoss.report_release(:celebi, true)
  pbSpawnBloodCelebi(here)
  true
end

# The Bug-Catching Contest: the player lost (someone else won, after the judging)
class BugContestState
  alias _blood_celebi_pbJudge pbJudge unless method_defined?(:_blood_celebi_pbJudge)
  def pbJudge
    _blood_celebi_pbJudge
    winner = @places && @places[0]
    return unless winner && winner[0] != -1
    pbReleaseBloodCelebi
  rescue StandardError => e
    echoln("[BloodCelebi] contest release: #{e.message}") if defined?(echoln)
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_celebi_state") { |d| BloodCelebi.set_state(d) }
NetworkClient.on("blood_celebi_cleared") { |_d| BloodCelebi.clear }

EventHandlers.add(:on_enter_map, :blood_celebi, proc { |_old_map_id| BloodCelebi.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_celebi, proc { BloodCelebi.tick })
