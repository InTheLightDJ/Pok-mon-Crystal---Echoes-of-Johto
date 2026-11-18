#===============================================================================
# Blood Lugia (server: handlers/blood_lugia.js)
#
# Unlocked for everyone the first time someone completes the Shadow Lugia event
# (catches the hunt boss). He wanders the caves and goes from cave to cave by
# the stairs, and he comes after anyone who enters his cave (touch him to fight).
#
# Blood Suicune is his enemy: in the same cave they go for each other, circle
# and fight, HP bars over their heads (Suicune hits twice as hard). Low on HP:
# he runs for the stairs with Suicune on his heels (if he makes it he's gone to
# another cave; if not, Suicune kills him); Suicune teleports away.
#
# The battle: nothing you do hurts him; only Suicune can. Catch him with a Blood
# Ball once Suicune has worn him down (the lower his HP, the better the odds).
# Hurt but left alone for 2 hours he's back to full HP (Suicune: 1 hour).
#===============================================================================
BLOOD_LUGIA_SPECIES = :BLOODLUGIA
BLOOD_LUGIA_MOVES   = [:AEROBLAST, :EXTRASENSORY, :DRAGONPULSE, :HYDROPUMP]
BLOOD_LUGIA_CHARSET = "Followers/BLOODLUGIA"
BLOOD_DUEL_HIT_SE   = "Battle damage normal"

# a small HP bar over a boss's head (shown while the two are in the same cave)
class BloodBossHpBar
  W = 34
  H = 5

  def initialize(viewport)
    @sprite = Sprite.new(viewport)
    @sprite.bitmap = Bitmap.new(W, H)
    @ratio = nil
  end

  def disposed?; @sprite.disposed?; end
  def dispose; @sprite.bitmap&.dispose; @sprite.dispose; end

  def update(char_sprite, char, ratio)
    return unless char_sprite && char && !char_sprite.disposed?
    redraw(ratio) if ratio != @ratio
    h = char_sprite.src_rect.height > 0 ? char_sprite.src_rect.height : 64
    @sprite.x = char.screen_x - (W / 2)
    @sprite.y = char.screen_y - h - H - 2
    @sprite.z = char_sprite.z + 1
    @sprite.visible = char_sprite.visible
  end

  def redraw(ratio)
    @ratio = ratio
    b = @sprite.bitmap
    b.clear
    b.fill_rect(0, 0, W, H, Color.new(20, 10, 10))
    fill = ((W - 2) * ratio.clamp(0.0, 1.0)).round
    color = ratio > 0.5 ? Color.new(80, 220, 90) : ratio > 0.25 ? Color.new(240, 200, 40) : Color.new(230, 50, 40)
    b.fill_rect(1, 1, fill, H - 2, color) if fill > 0
  end
end

# drawn among the cave walls, like Blood Suicune (008_BloodSuicune.rb)
class BloodLugiaCharacter < ShadowLugiaCharacter
  def name; "Blood Lugia"; end

  def initialize(map, species, character_name)
    super
    @always_on_top = false
  end
end

module BloodLugia
  @state  = nil
  @char   = nil
  @sprite = nil
  @battle_triggered = false
  @bars = {}            # :lugia / :suicune => BloodBossHpBar

  class << self
    attr_reader :state

    def name; GameData::Species.exists?(BLOOD_LUGIA_SPECIES) ? GameData::Species.get(BLOOD_LUGIA_SPECIES).name : "Blood Lugia"; end
    def active?; !@state.nil?; end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      @state = { map_id: d["map_id"].to_i, mode: d["mode"].to_s, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, gone_at: d["gone_at"].to_i,
                 hp: d["hp"].to_i, max_hp: [d["max_hp"].to_i, 1].max, dueling: d["dueling"] == true,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite if @char && @char.map.map_id != @state[:map_id]
    end

    def clear
      @state = nil
      destroy_sprite
    end

    def elapsed_ms; ((System.unscaled_uptime - @state[:started]) * 1000).to_i; end

    def position(ahead = false)
      ms = elapsed_ms
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, 0)
    end

    # he's gone up the stairs
    def gone?; @state[:gone_at] >= 0 && elapsed_ms >= @state[:gone_at]; end

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
      dispose_bars
    end

    def dispose_bars
      @bars.each_value { |b| b.dispose unless b.disposed? }
      @bars.clear
    end

    def tick
      return destroy_sprite unless active? && BloodMewtwo.online? && $scene.is_a?(Scene_Map)
      return destroy_sprite if gone?
      map = host_map
      return destroy_sprite unless map
      if !@char || @char.map != map || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        charset = pbResolveBitmap("Graphics/Characters/#{BLOOD_LUGIA_CHARSET}") ? BLOOD_LUGIA_CHARSET : "Followers/000"
        @char = BloodLugiaCharacter.new(map, BLOOD_LUGIA_SPECIES, charset)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.move_speed = BLOOD_BOSS_SPEEDS[@state[:ms_per_tile]] || 3
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      update_bars
      check_trigger
    end

    # HP bars over both while they're in this cave together
    def update_bars
      s = defined?(BloodSuicune) ? BloodSuicune : nil
      together = @char.map == $game_map && (@state[:dueling] ||
                 (s&.state && s.char && s.char.map == $game_map && !s.gone?))
      return dispose_bars unless together
      vp = Spriteset_Map.viewport
      return unless vp
      @bars[:lugia] ||= BloodBossHpBar.new(vp)
      @bars[:lugia].update(@sprite, @char, @state[:hp].to_f / @state[:max_hp])
      if s&.state && s.char && s.sprite && !s.sprite.disposed? && s.char.map == $game_map
        @bars[:suicune] ||= BloodBossHpBar.new(vp)
        @bars[:suicune].update(s.sprite, s.char, s.state[:hp].to_f / [s.state[:max_hp], 1].max)
      elsif @bars[:suicune]
        @bars.delete(:suicune).dispose
      end
    end

    # a blow in their fight: both HPs, a red flash on whoever took it
    def duel_hit(d)
      return unless $game_map && d["map_id"].to_i == $game_map.map_id
      @state[:hp] = d["lugia_hp"].to_i if @state
      if defined?(BloodSuicune) && BloodSuicune.state
        BloodSuicune.state[:hp] = d["suicune_hp"].to_i
        BloodSuicune.state[:max_hp] = d["suicune_max"].to_i
      end
      target = d["by"] == "suicune" ? @sprite : (defined?(BloodSuicune) ? BloodSuicune.sprite : nil)
      target.flash(Color.new(255, 40, 40, 220), 12) if target && !target.disposed?
      pbSEPlay(BLOOD_DUEL_HIT_SE, 60) if FileTest.audio_exist?("Audio/SE/#{BLOOD_DUEL_HIT_SE}")
    end

    # touch him to fight him
    def check_trigger
      return unless @char && @char.map == $game_map
      here = $game_player.x == @char.x && $game_player.y == @char.y
      if !here
        @battle_triggered = false
      elsif !@battle_triggered && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
            !$game_temp.message_window_showing
        @battle_triggered = true
        battle = pbBloodBossBattle("blood_lugia", BLOOD_LUGIA_SPECIES, BLOOD_LUGIA_MOVES,
                                   Battle::BloodLugiaEncounter, name)
        clear if battle && (battle.boss_caught || battle.boss_defeated)
      end
    end
  end
end

#===============================================================================
# The battle: nothing hurts him (only Blood Suicune can); Blood Balls only
#===============================================================================
class Battle::BloodLugiaEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_lugia"; end
  def weaknesses; []; end
  def wounds_text(boss)
    _INTL("{1} is untouchable! Only Blood Suicune can wound it... throw a Blood Ball!", boss.pbThis)
  end
  def elsewhere_text; _INTL("{1} has been wounded elsewhere!", @boss_name); end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_lugia_state") { |d| BloodLugia.set_state(d) }
NetworkClient.on("blood_lugia_cleared") { |_d| BloodLugia.clear }
NetworkClient.on("blood_duel_hit") { |d| BloodLugia.duel_hit(d) }

EventHandlers.add(:on_enter_map, :blood_lugia, proc { |_old_map_id| BloodLugia.destroy_sprite })
EventHandlers.add(:on_frame_update, :blood_lugia, proc { BloodLugia.tick })
