#===============================================================================
# Blood Meloetta (server: handlers/blood_meloetta.js)
#
# The third blood boss. She doesn't need Blood Mewtwo's switch 116. A jackpot
# on a Jackpot Machine releases her for the WHOLE server and wakes her if she's
# gone - the only way she comes back (no respawn timer; the server does it:
# handlers/jackpot.js -> blood_meloetta.js releaseAll). Each game hears of it
# then or at its next login. An event can release her (for everyone) too:
#           Script: pbReleaseBloodMeloetta        (and wakes her now, if she's resting)
#           Script: pbReleaseBloodMeloetta(true)  (and wakes her next to the player)
# She chases the other blood bosses: toward the nearest map with any of them
# on it (Mewtwo, Celebi, Deoxys, Cresselia over a route or town), then follows
# it around (the server plans it). With
# neither awake she wanders. She doesn't touch any events.
#
# Her perk: while she's on the map of a player fighting Blood Mewtwo or Blood
# Celebi, at the end of each round that boss may cure itself of its status
# condition and confusion (BLOOD_MELOETTA_CURE_CHANCE).
#
# The battle: nothing can hurt her but a transformed Pokemon (Transform, or
# Ditto's Imposter). Every hit from one takes 1/10 of her HP ("Weaknesses" in
# 001_BloodMewtwo.rb), shared by everyone (the server's HP). At 0 she dies
# for everyone. Her moves never run out of PP. Only a Blood Ball can catch
# her (the first catch the server hears of wins).
#
# She comes back once a week after she's beaten (server). An event can wake
# her sooner:   Script: pbSpawnBloodMeloetta        (wherever she'd wake)
#               Script: pbSpawnBloodMeloetta(true)  (next to the player; on a
#                                                    route or town only)
# Only once she's been released for this player, not while she's awake;
# true if she woke, false if not; it shows no message itself.
#===============================================================================
BLOOD_MELOETTA_SPECIES    = :BLOODMELOETTA
BLOOD_MELOETTA_MOVES      = [:HYPERVOICE, :PSYCHIC, :SING, :CLOSECOMBAT]
BLOOD_MELOETTA_MOVE_SPEED = 3           # 0.25 s a tile: must match MS_PER_TILE (250) on the server
BLOOD_MELOETTA_CHARSET    = "Followers/BLOODMELOETTA"
BLOOD_MELOETTA_CURE_CHANCE = 50         # % a round her perk cures the boss (when it has something to cure)

module BloodMeloetta
  # { map_id:, path:, ms_per_tile:, exit_dir:, started:, hp:, max_hp: }
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false

  class << self
    attr_reader :state

    def name; GameData::Species.exists?(BLOOD_MELOETTA_SPECIES) ? GameData::Species.get(BLOOD_MELOETTA_SPECIES).name : "Blood Meloetta"; end
    def active?; !@state.nil? && BloodBoss.released?(:meloetta); end
    # she's on this map (the player's, by default)
    def here?(map_id = $game_map&.map_id); active? && !map_id.nil? && @state[:map_id] == map_id; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      @state = { map_id: d["map_id"].to_i, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, exit_dir: d["exit_dir"].to_i,
                 hp: d["hp"].to_i, max_hp: d["max_hp"].to_i,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite unless @char && @char.moving? && @char.map.map_id != @state[:map_id]
    end

    def clear
      @state = nil
      destroy_sprite
    end

    def elapsed_ms; ((System.unscaled_uptime - @state[:started]) * 1000).to_i; end

    def position(ahead = false)
      ms = elapsed_ms
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, @state[:exit_dir])
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
      BloodBoss.report_release(:meloetta) if Graphics.frame_count % 60 == 0
      return destroy_sprite unless active? && BloodMewtwo.online? && $scene.is_a?(Scene_Map)
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
        charset = [BLOOD_MELOETTA_CHARSET, "Followers/BLOODMELOETTE"].find { |c| pbResolveBitmap("Graphics/Characters/#{c}") } || "Followers/000"
        @char = ShadowLugiaCharacter.new(map, BLOOD_MELOETTA_SPECIES, charset)
        @char.move_speed = BLOOD_MELOETTA_MOVE_SPEED
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      check_trigger
    end

    # standing on the same tile as her starts the battle (once per meeting)
    def check_trigger
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        battle = pbBloodBossBattle("blood_meloetta", BLOOD_MELOETTA_SPECIES, BLOOD_MELOETTA_MOVES,
                                   Battle::BloodMeloettaEncounter, name)
        clear if battle && (battle.boss_caught || battle.boss_defeated)
      end
    end
  end
end

#===============================================================================
# The battle: Blood Mewtwo's (001_BloodMewtwo.rb), but only a transformed
# Pokemon hurts her
#===============================================================================
class Battle::BloodMeloettaEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_meloetta"; end
  def weaknesses; [:transformed]; end
  def defeat_text(by); _INTL("{1}'s mirror image silenced {2}!", by, @boss_name); end
  def elsewhere_text; _INTL("A mirror image has wounded {1} elsewhere too!", @boss_name); end
  def meloetta_cure(_boss); end   # (her perk is for the others)
end

#===============================================================================
# Her perk: on the map of a player fighting another blood boss, her song may
# cure that boss of its status condition and confusion at the end of a round
#===============================================================================
class Battle::BloodMewtwoEncounter
  def meloetta_cure(boss)
    confused = boss.effects[PBEffects::Confusion] > 0
    return unless boss.status != :NONE || confused
    return unless pbRandom(100) < BLOOD_MELOETTA_CURE_CHANCE
    pbDisplay(_INTL("{1}'s song echoes from nearby...", BloodMeloetta.name))
    boss.pbCureStatus(true) if boss.status != :NONE
    if confused
      boss.pbCureConfusion
      pbDisplay(_INTL("{1} snapped out of its confusion!", boss.pbThis))
    end
  end
end

#===============================================================================
# Event command: wake her now (see the top of this file)
#===============================================================================
def pbSpawnBloodMeloetta(here = false)
  return false unless BloodBoss.released?(:meloetta) && BloodMewtwo.online?
  BloodBoss.report_release(:meloetta)   # the server must know this game can see her
  result = nil
  cb = NetworkClient.on("blood_meloetta_force_result") { |d| result = d }
  NetworkClient.send_msg({ action: "blood_meloetta_force", here: here ? true : false })
  120.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.remove("blood_meloetta_force_result", cb)
  result ? result["ok"] == true : false
rescue StandardError
  false
end

# Release her for this player (kept in the save), and wake her now if she's
# resting (here: next to the player). Always true; offline, the server hears
# of it at the next login.
def pbReleaseBloodMeloetta(here = false)
  BloodBoss.release(:meloetta)
  return true unless BloodMewtwo.online?
  BloodBoss.report_release(:meloetta, true)
  pbSpawnBloodMeloetta(here)
  true
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_meloetta_state") { |d| BloodMeloetta.set_state(d) }
NetworkClient.on("blood_meloetta_cleared") { |_d| BloodMeloetta.clear }

EventHandlers.add(:on_enter_map, :blood_meloetta, proc { |_old_map_id| BloodMeloetta.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_meloetta, proc { BloodMeloetta.tick })

#===============================================================================
# Her perk in the other blood bosses' battles: she's on the player's map (the
# server's word in the HP updates, or where this game sees her). Mewtwo /
# Celebi may cure themselves (001), one-hit KO moves take a sixth of Deoxys
# instead of a third (004), and a Blood Ball is x3 instead of x5 (001).
#===============================================================================
class Battle::BloodMewtwoEncounter
  def meloetta_near?
    return true if @meloetta_near
    defined?(BloodMeloetta) && BloodMeloetta.here? ? true : false
  end
end
