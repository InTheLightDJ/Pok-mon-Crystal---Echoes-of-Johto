#===============================================================================
# The blood gods (server: handlers/blood_god.js): Sapusaur, Charcolt, Rainer
#
# One of the three lives on the New Dimension (BLOOD_GOD_MAP, where Blood
# Deoxys sends AFK players); the server swaps it for another every couple of
# days, or brings the next one an hour after one is beaten. Everyone on the
# map sees it (no switch, no release).
#
# It walks the corridors to a spot, rests a while, and walks on. Come within
# 4 tiles and it chases you, each its own way:
#   Charcolt   lines up with you, winds up and charges straight past you
#   Rainer     weaves side to side as it runs at you
#   Sapusaur   steps back, crouches, then lunges at where you were
# If it touches you, EVERY player on the map is pulled into a battle with it
# (each in their own battle, sharing its HP).
#
# The battle: 400,000 HP shared by everyone, and everything hurts it (no type,
# ability or status immunities), but no player's battle can take more than
# BLOOD_GOD_TURN_CAP of it in one turn (poison, Super Fang, one-hit KO
# moves... all count toward that). It can't be caught.
#
# On its map, Space throws a Blood Ball (not one of yours) BLOOD_GOD_THROW_RANGE
# tiles the way you face. If it hits the god, it stops for a moment and loses a
# tenth of its HP, for everyone.
#
# Beaten: everyone who fought it (or hit it) gets a Blood Shard, 10 Server
# Tokens and a 1% chance at a glitch Pokémon's Egg; one of them also gets a
# random item (006_BloodLoot.rb).
#===============================================================================
BLOOD_GOD_MAP = 508
BLOOD_GODS = {
  SAPUSAUR: { moves: [:FRENZYPLANT, :SLUDGEBOMB, :EARTHQUAKE, :SLEEPPOWDER],
              charsets: ["Followers/SAPUSAUR", "Followers/VENUSAUR"] },
  CHARCOLT: { moves: [:BLASTBURN, :AIRSLASH, :DRAGONPULSE, :WILLOWISP],
              charsets: ["Followers/CHARCOLT", "Followers/CHARIZARD"] },
  RAINER:   { moves: [:HYDROCANNON, :FLASHCANNON, :ICEBEAM, :AURASPHERE],
              charsets: ["Followers/RAINER", "Followers/BLASTOISE"] },
}
BLOOD_GOD_TURN_CAP       = 1000    # must match TURN_CAP (server)
BLOOD_GOD_THROW_RANGE    = 5       # must match THROW_RANGE (server)
BLOOD_GOD_THROW_COOLDOWN = 3.0     # seconds between throws
BLOOD_GOD_BALL_TILE_TIME = 0.06    # seconds the ball takes a tile
BLOOD_GOD_BALL_GRAPHIC   = "Graphics/Items/BLOODBALL"
BLOOD_GOD_BATTLE_GAP     = 8.0     # after a battle with it, it can't pull you in again this soon
BLOOD_GOD_ENGAGE_WINDOW  = 10.0    # a pull into its battle lasts this long (if you're in a menu...)

module BloodGod
  @state   = nil   # { species:, path:, ms_per_tile:, started:, hp:, max_hp:, mode: }
  @char    = nil
  @sprite  = nil
  @bar     = nil
  @ball    = nil   # { tile: [x, y], dir: [dx, dy], from: [x, y], t0:, steps: }
  @hello   = false
  @engage  = nil   # System.unscaled_uptime the server pulled this game into the battle
  @touched = 0.0   # last touch sent
  @thrown  = 0.0
  @calm_until = 0.0

  class << self
    attr_reader :state

    def name(sp = @state && @state[:species])
      return "" unless sp
      GameData::Species.exists?(sp) ? GameData::Species.get(sp).name : sp.to_s.capitalize
    end

    def here?; $game_map&.map_id == BLOOD_GOD_MAP && $scene.is_a?(Scene_Map); end

    def free?
      $scene.is_a?(Scene_Map) && !$game_system.map_interpreter.running? && !$game_temp.in_menu &&
        !$game_temp.message_window_showing && !$game_temp.player_transferring
    end

    def set_state(d)
      unless d["active"]
        clear
        return
      end
      old = @state && @state[:species]
      @state = { species: d["species"].to_s.to_sym, path: d["path"].map { |p| p.map(&:to_i) },
                 ms_per_tile: [d["ms_per_tile"].to_i, 1].max, mode: d["mode"].to_s,
                 hp: d["hp"].to_i, max_hp: [d["max_hp"].to_i, 1].max,
                 started: System.unscaled_uptime - (d["elapsed_ms"].to_i / 1000.0) }
      destroy_sprite if old && old != @state[:species]
      @bar_drawn = nil
    end

    def set_hp(d)
      return unless @state
      @state[:hp] = d["hp"].to_i
      @state[:max_hp] = [d["max_hp"].to_i, 1].max
    end

    def clear
      @state = nil
      @engage = nil
      destroy_sprite
    end

    def entered_map
      @hello = false
      destroy_sprite
      @state = nil unless $game_map&.map_id == BLOOD_GOD_MAP
    end

    def position(ahead = false)
      ms = ((System.unscaled_uptime - @state[:started]) * 1000).to_i
      ms += @state[:ms_per_tile] if ahead
      ShadowLugia.position_at(@state[:path], @state[:ms_per_tile], ms, 0)
    end

    # the tiles it's on (where the server says, and where it's drawn)
    def tiles
      t = [position[0, 2]]
      t << [@char.x, @char.y] if @char
      t
    end

    def destroy_sprite
      @sprite&.dispose
      @sprite = nil
      @char = nil
      @bar&.bitmap&.dispose
      @bar&.dispose
      @bar = nil
      end_ball
    end

    def tick
      return destroy_sprite unless here? && BloodMewtwo.online?
      unless @hello
        @hello = true
        NetworkClient.send_msg({ action: "blood_god_hello" })
      end
      return destroy_sprite unless @state
      if !@char || @sprite.disposed?
        destroy_sprite
        vp = Spriteset_Map.viewport
        return unless vp
        charset = BLOOD_GODS.dig(@state[:species], :charsets)&.find { |c| pbResolveBitmap("Graphics/Characters/#{c}") } || "Followers/000"
        @char = ShadowLugiaCharacter.new($game_map, @state[:species], charset)
        @char.moveto(*position[0, 2])
        @sprite = Sprite_Character.new(vp, @char)
      end
      @char.move_speed = BLOOD_BOSS_SPEEDS[@state[:ms_per_tile]] || 3
      @char.fly_to(*position(true)) unless @char.moving?
      @char.update
      @sprite.update
      update_bar
      update_ball
      return unless free?
      if @engage
        @engage = nil if System.unscaled_uptime - @engage > BLOOD_GOD_ENGAGE_WINDOW
        return start_battle if @engage && System.unscaled_uptime >= @calm_until
      end
      check_touch
      check_throw
    end

    #---------------------------------------------------------------------------
    # Touching it / its battle
    #---------------------------------------------------------------------------
    def check_touch
      return if System.unscaled_uptime < @calm_until || System.unscaled_uptime - @touched < 1.0
      return unless tiles.include?([$game_player.x, $game_player.y])
      @touched = System.unscaled_uptime
      NetworkClient.send_msg({ action: "blood_god_touch" })
    end

    # the server: it caught someone, and everyone on the map is in the fight
    def engage_all(_d); @engage = System.unscaled_uptime if @state; end

    def start_battle
      @engage = nil
      sp = @state[:species]
      battle = pbBloodBossBattle("blood_god", sp, BLOOD_GODS.dig(sp, :moves) || [], Battle::BloodGodEncounter, name, true)
      @calm_until = System.unscaled_uptime + BLOOD_GOD_BATTLE_GAP
      clear if battle && battle.boss_defeated
    end

    #---------------------------------------------------------------------------
    # Space: a ball, BLOOD_GOD_THROW_RANGE tiles the way the player faces
    #---------------------------------------------------------------------------
    def space_pressed?
      return Input.triggerex?(:SPACE) if Input.respond_to?(:triggerex?)
      Input.trigger?(Input::USE)
    end

    def check_throw
      return if @ball || System.unscaled_uptime - @thrown < BLOOD_GOD_THROW_COOLDOWN
      return unless space_pressed?
      return if $game_player.pbFacingEvent
      d = $game_player.direction
      dir = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }[d]
      return unless dir
      @thrown = System.unscaled_uptime
      from = [$game_player.x, $game_player.y]
      @ball = { tile: from.dup, dir: dir, from: from, t0: System.unscaled_uptime, steps: 0, d: d }
      vp = Spriteset_Map.viewport
      path = pbResolveBitmap(BLOOD_GOD_BALL_GRAPHIC)
      if vp && path
        @ball[:sprite] = Sprite.new(vp)
        @ball[:sprite].bitmap = Bitmap.new(path)
        @ball[:sprite].ox = @ball[:sprite].bitmap.width / 2
        @ball[:sprite].oy = @ball[:sprite].bitmap.height / 2
        @ball[:sprite].zoom_x = @ball[:sprite].zoom_y = 0.5
        @ball[:sprite].z = 999_999
      end
      pbSEPlay("Battle throw") if FileTest.audio_exist?("Audio/SE/Battle throw")
    end

    def end_ball
      return unless @ball
      @ball[:sprite]&.bitmap&.dispose
      @ball[:sprite]&.dispose
      @ball = nil
    end

    def update_ball
      return unless @ball
      b = @ball
      flown = (System.unscaled_uptime - b[:t0]) / BLOOD_GOD_BALL_TILE_TIME
      while b[:steps] < flown.floor
        x, y = b[:tile]
        nx, ny = x + b[:dir][0], y + b[:dir][1]
        unless $game_map.valid?(nx, ny) && $game_map.passable?(x, y, b[:d]) && $game_map.passable?(nx, ny, 10 - b[:d])
          return end_ball
        end
        b[:tile] = [nx, ny]
        b[:steps] += 1
        if tiles.include?(b[:tile])
          hit(b[:tile])
          return end_ball
        end
        return end_ball if b[:steps] >= BLOOD_GOD_THROW_RANGE
      end
      s = b[:sprite]
      return unless s
      f = [flown, BLOOD_GOD_THROW_RANGE].min
      fx = b[:from][0] + (b[:dir][0] * f)
      fy = b[:from][1] + (b[:dir][1] * f)
      s.x = ((fx * Game_Map::REAL_RES_X - $game_map.display_x) / Game_Map::X_SUBPIXELS).round + (Game_Map::TILE_WIDTH / 2)
      s.y = ((fy * Game_Map::REAL_RES_Y - $game_map.display_y) / Game_Map::Y_SUBPIXELS).round + (Game_Map::TILE_HEIGHT / 2) - 8
      s.angle = (f * 120) % 360
    end

    def hit(tile)
      NetworkClient.send_msg({ action: "blood_god_hit", x: tile[0], y: tile[1] })
      @sprite&.flash(Color.new(255, 255, 255, 220), 16)
      pbSEPlay("Battle damage normal") if FileTest.audio_exist?("Audio/SE/Battle damage normal")
    end

    #---------------------------------------------------------------------------
    # Its HP, at the top of the screen
    #---------------------------------------------------------------------------
    def update_bar
      w, h = 200, 34
      unless @bar
        @bar = Sprite.new
        @bar.bitmap = Bitmap.new(w, h)
        @bar.x = (Graphics.width - w) / 2
        @bar.y = 4
        @bar.z = 99_999
        @bar_drawn = nil
      end
      key = [@state[:species], @state[:hp], @state[:max_hp]]
      return if @bar_drawn == key
      @bar_drawn = key
      bmp = @bar.bitmap
      bmp.clear
      pbSetSmallFont(bmp)
      pbDrawTextPositions(bmp, [[name, w / 2, 0, :center, Color.new(255, 230, 230), Color.new(60, 0, 0)]])
      bmp.fill_rect(0, 20, w, 12, Color.new(30, 0, 0, 220))
      fill = ((w - 4) * @state[:hp].to_f / @state[:max_hp]).round.clamp(0, w - 4)
      bmp.fill_rect(2, 22, fill, 8, Color.new(200, 20, 30))
      bmp.fill_rect(2, 22, fill, 3, Color.new(240, 90, 90))
    end
  end
end

#===============================================================================
# The battle: everything hurts it, at most BLOOD_GOD_TURN_CAP a turn per battle
#===============================================================================
class Battle::BloodGodEncounter < Battle::BloodMewtwoEncounter
  def net; "blood_god"; end
  def weaknesses; []; end
  def open_damage?; true; end
  def damage_cap; BLOOD_GOD_TURN_CAP; end
  def catchable?; false; end
  def ball_block_text; _INTL("{1} can't be caught!", @boss_name); end
  def wounds_text(boss); _INTL("{1} can't be hurt any more this turn!", boss.pbThis); end
  def defeat_text(by); _INTL("{1} felled {2}!", by, @boss_name); end
  def elsewhere_text; _INTL("Other trainers are fighting {1} too!", @boss_name); end
  def meloetta_cure(_boss); end
  def god?(battler); battler && boss_battler?(battler); end
end

# no immunities: a move that wouldn't affect it hits it normally...
class Battle::Move
  alias _blood_god_pbCalcTypeMod pbCalcTypeMod unless method_defined?(:_blood_god_pbCalcTypeMod)
  def pbCalcTypeMod(moveType, user, target)
    ret = _blood_god_pbCalcTypeMod(moveType, user, target)
    if @battle.is_a?(Battle::BloodGodEncounter) && @battle.god?(target) && Effectiveness.ineffective?(ret)
      ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    end
    ret
  end
end

# ...and its types and flying don't keep anything off it (status, powders, Ground moves...)
class Battle::Battler
  attr_accessor :blood_untyped

  def _blood_god?; @battle.is_a?(Battle::BloodGodEncounter) && @battle.god?(self); end

  def _blood_untyped_while
    old = @blood_untyped
    @blood_untyped = true
    yield
  ensure
    @blood_untyped = old
  end

  alias _blood_god_pbHasType? pbHasType? unless method_defined?(:_blood_god_pbHasType?)
  def pbHasType?(type)
    return false if @blood_untyped
    _blood_god_pbHasType?(type)
  end

  alias _blood_god_airborne? airborne? unless method_defined?(:_blood_god_airborne?)
  def airborne?
    return false if _blood_god?
    _blood_god_airborne?
  end

  alias _blood_god_pbCanInflictStatus? pbCanInflictStatus? unless method_defined?(:_blood_god_pbCanInflictStatus?)
  def pbCanInflictStatus?(newStatus, user, showMessages, move = nil, ignoreStatus = false)
    return _blood_god_pbCanInflictStatus?(newStatus, user, showMessages, move, ignoreStatus) unless _blood_god?
    _blood_untyped_while { _blood_god_pbCanInflictStatus?(newStatus, user, showMessages, move, ignoreStatus) }
  end

  alias _blood_god_pbSuccessCheckAgainstTarget pbSuccessCheckAgainstTarget unless method_defined?(:_blood_god_pbSuccessCheckAgainstTarget)
  def pbSuccessCheckAgainstTarget(move, user, target, targets)
    return _blood_god_pbSuccessCheckAgainstTarget(move, user, target, targets) unless target&._blood_god?
    target._blood_untyped_while { _blood_god_pbSuccessCheckAgainstTarget(move, user, target, targets) }
  end
end

#===============================================================================
# Server messages and hooks
#===============================================================================
NetworkClient.on("blood_god_state") { |d| BloodGod.set_state(d) }
NetworkClient.on("blood_god_hp") { |d| BloodGod.set_hp(d) }
NetworkClient.on("blood_god_cleared") { |_d| BloodGod.clear }
NetworkClient.on("blood_god_engage_all") { |d| BloodGod.engage_all(d) }
NetworkClient.on("login_ok") { |_d| BloodGod.entered_map }

EventHandlers.add(:on_enter_map, :blood_god, proc { |_old_map_id| BloodGod.entered_map })
EventHandlers.add(:on_frame_update, :blood_god, proc { BloodGod.tick })
