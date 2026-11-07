#==============================================================================
# Pokémon Tower Defense - the field screen
#
#   arrows     move the cursor; the field scrolls when it's pushed past the
#              edge of the screen
#   C          on grass: buy a tower (a Pidgey: and which way it blows) or a
#              Poison Bomb / on the track: Spikes,
#              Poison Bomb / on a tower: evolve, Potion, sell
#   A          start the next round (between rounds) / speed x1 / x2 (in one)
#   B          menu: start round, speed, items (X Attack, X Defend, Exp.
#              Share), how to play, quit
#
# Towers and walkers are follower sprites (Graphics/Characters/Followers,
# 4x4 frames: rows down / left / right / up). The game's own speed-up
# (TCG.speed_multiplier) speeds this up too.
#==============================================================================
module TowerDefense
  TILE  = 32
  TOP   = 32               # the bar at the top
  SHOT_COLORS = {
    :GRASS => [88, 200, 64], :FIRE => [240, 104, 40], :WATER => [72, 144, 248], :BUG => [176, 192, 40],
    :FLYING => [200, 224, 248], :ELECTRIC => [248, 216, 48], :PSYCHIC => [248, 104, 168]
  }
  MUSIC      = "Battle Frontier"
  BOSS_MUSIC = "GSC 042 Battle! Gym Leader (Johto)"

  def self.speed_multiplier
    defined?(TCG) && TCG.respond_to?(:speed_multiplier) ? TCG.speed_multiplier : 1
  end

  class Scene
    WHITE  = Color.new(248, 248, 248)
    SHADOW = Color.new(56, 56, 64)
    YELLOW = Color.new(248, 216, 72)
    RED    = Color.new(240, 72, 56)
    GREEN  = Color.new(96, 216, 96)
    GREY   = Color.new(176, 176, 184)
    BLUE   = Color.new(80, 152, 248)
    PURPLE = Color.new(176, 88, 200)
    PINK   = Color.new(248, 120, 184)

    def initialize(game = nil)
      @game = game || Game.new
      @view_cols = Graphics.width / TILE
      @view_rows = (Graphics.height - TOP) / TILE
      start = @game.path[0]
      @cursor = [start[0] + 1, [start[1] - 1, 0].max]
      @cam = [0, (start[1] - @view_rows / 2).clamp(0, max_cam[1])]
      @cam_px = [@cam[0] * TILE.to_f, @cam[1] * TILE.to_f]
      @speed = 1
      @sheets = {}
      @floaters = []      # [text, x, y, frames left, colour, on the map?]
      @blasts = []        # [x, y, frames left] (map pixels)
      @flash = {}         # enemy/tower id => frames of white flash
      @enemy_sprites = {}
      @tower_sprites = {}
      @shot_sprites = []
    end

    def max_cam; [[COLS - @view_cols, 0].max, [ROWS - @view_rows, 0].max]; end

    #--------------------------------------------------------------------------
    def main
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99_999   # above the pbFadeOutIn black layer (99999, made earlier)
      @bg = Sprite.new(@viewport)
      @bg.bitmap = draw_field
      @overlay = Sprite.new(@viewport)
      @overlay.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @overlay.z = 900
      @hud = Sprite.new(@viewport)
      @hud.bitmap = Bitmap.new(Graphics.width, TOP)
      @hud.z = 1000
      pbSetSmallFont(@hud.bitmap)
      pbSetSmallFont(@overlay.bitmap)
      @shot_bitmaps = SHOT_COLORS.to_h { |t, c| [t, ball_bitmap(c)] }
      pbBGMPlay(MUSIC)
      update_camera(true)
      sync_sprites
      draw_hud
      pbMessage(_INTL("The wild Pokémon will walk the track from the left. Build towers on the grass, then press the Action button to start round 1!"))
      loop do
        Graphics.update
        Input.update
        break if handle_input == :quit
        step_game if @game.state == :wave
        handle_events
        update_camera
        sync_sprites
        draw_overlay
        draw_hud
        break if @game.state == :over && game_over
      end
      @game.round
    ensure
      dispose
    end

    # one frame of game time: x2 and the game's speed-up both count
    def step_game
      mult = @speed * TowerDefense.speed_multiplier
      n = mult.ceil
      n.times { @game.update(mult / 60.0 / n) }
    end

    def dispose
      [@enemy_sprites.values, @tower_sprites.values, @shot_sprites].flatten.each(&:dispose)
      [@bg, @overlay, @hud].compact.each { |s| s.bitmap&.dispose; s.dispose }
      @sheets.each_value(&:dispose)
      @shot_bitmaps&.each_value(&:dispose)
      @viewport&.dispose
    end

    #--------------------------------------------------------------------------
    # the camera follows the cursor (it slides, a tile at a time)
    #--------------------------------------------------------------------------
    def update_camera(snap = false)
      c, r = @cursor
      @cam[0] = c if c < @cam[0]
      @cam[0] = c - @view_cols + 1 if c > @cam[0] + @view_cols - 1
      @cam[1] = r if r < @cam[1]
      @cam[1] = r - @view_rows + 1 if r > @cam[1] + @view_rows - 1
      @cam[0] = @cam[0].clamp(0, max_cam[0])
      @cam[1] = @cam[1].clamp(0, max_cam[1])
      2.times do |i|
        goal = @cam[i] * TILE.to_f
        @cam_px[i] = snap || (goal - @cam_px[i]).abs < 1 ? goal : @cam_px[i] + (goal - @cam_px[i]) * 0.3
      end
      @bg.x = -@cam_px[0].round
      @bg.y = TOP - @cam_px[1].round
    end

    # map tiles -> screen pixels
    def sx(tx); (tx * TILE - @cam_px[0]).round; end
    def sy(ty); (TOP + ty * TILE - @cam_px[1]).round; end

    #--------------------------------------------------------------------------
    # input
    #--------------------------------------------------------------------------
    def handle_input
      c, r = @cursor
      if Input.repeat?(Input::LEFT)     then c -= 1
      elsif Input.repeat?(Input::RIGHT) then c += 1
      elsif Input.repeat?(Input::UP)    then r -= 1
      elsif Input.repeat?(Input::DOWN)  then r += 1
      end
      nc = [c.clamp(0, COLS - 1), r.clamp(0, ROWS - 1)]
      if nc != @cursor
        @cursor = nc
        pbSEPlay("GUI sel cursor")
      end
      if Input.trigger?(Input::USE)
        tile_menu
      elsif Input.trigger?(Input::ACTION)
        action_button
      elsif Input.trigger?(Input::BACK)
        return pause_menu
      end
      nil
    end

    def action_button
      if @game.state == :build
        start_round
      else
        @speed = @speed == 1 ? 2 : 1
        pbSEPlay("GUI sel decision")
      end
    end

    def start_round
      return unless @game.start_round
      pbSEPlay("GUI sel decision")
      pbBGMPlay(@game.boss_round? || @game.special_round? ? BOSS_MUSIC : MUSIC)
    end

    def item_name(item)
      { :POTION => _INTL("Potion"), :SPIKES => _INTL("Spikes"), :POISON_BOMB => _INTL("Poison Bomb"),
        :X_ATTACK => _INTL("X Attack"), :X_DEFEND => _INTL("X Defend"), :EXP_SHARE => _INTL("Exp. Share") }[item]
    end

    def item_label(item)
      _INTL("{1} - {2} pts", item_name(item), ITEMS[item][:price])
    end

    def tile_menu
      c, r = @cursor
      if (t = @game.tower_at(c, r))
        tower_menu(t)
      elsif @game.trap_at(c, r)
        pbSEPlay("GUI sel buzzer")
      elsif @game.path?(c, r)
        track_menu(c, r)
      elsif @game.buildable?(c, r)
        buy_menu(c, r)
      else
        pbSEPlay("GUI sel buzzer")
      end
    end

    def buy_menu(c, r)
      keys = TOWERS.keys
      names = keys.map do |k|
        _INTL("{1} ({2}) - {3} pts", GameData::Species.get(k).name, GameData::Type.get(TOWERS[k][:type]).name, TowerDefense.cost(k))
      end
      cmd = pbMessage(_INTL("Build a tower here? You have {1} points.", @game.points),
                      names + [item_label(:POISON_BOMB), _INTL("Cancel")], -1)
      return if cmd < 0
      return use_item(:POISON_BOMB, [c, r]) if cmd == keys.size
      return if cmd > keys.size
      key = keys[cmd]
      if @game.rival_near?(key, c, r)
        pbSEPlay("GUI sel buzzer")
        return pbMessage(_INTL("Mew and Mewtwo won't stand that close together!"))
      end
      if @game.points < TowerDefense.cost(key)
        pbSEPlay("GUI sel buzzer")
        return pbMessage(_INTL("Not enough points! {1} costs {2}.", GameData::Species.get(key).name, TowerDefense.cost(key)))
      end
      facing = 0
      if TOWERS[key][:gust]
        facing = pick_direction(key, c, r)
        return if facing.nil?
      end
      pbSEPlay("Battle ball drop") if @game.buy(key, c, r, facing) == :ok
    end

    # which way a Gust tower blows (nil: cancelled); the track's side first
    def pick_direction(key, c, r)
      dirs = [[3, _INTL("Up")], [0, _INTL("Down")], [1, _INTL("Left")], [2, _INTL("Right")]]
      dirs = dirs.sort_by do |f, _|
        dx, dy = DIRS[f]
        -(1..4).count { |k| @game.path?(c + dx * k, r + dy * k) }
      end
      cmd = pbMessage(_INTL("Which way should {1} blow its Gust?", GameData::Species.get(key).name),
                      dirs.map { |_, n| n } + [_INTL("Cancel")], -1)
      cmd >= 0 && cmd < dirs.size ? dirs[cmd][0] : nil
    end

    def track_menu(c, r)
      items = [:SPIKES, :POISON_BOMB]
      cmd = pbMessage(_INTL("Put something on the track? You have {1} points.", @game.points),
                      items.map { |i| item_label(i) } + [_INTL("Cancel")], -1)
      use_item(items[cmd], [c, r]) if cmd >= 0 && cmd < items.size
    end

    def use_item(item, at = nil)
      case @game.use_item(item, at)
      when :ok
        pbSEPlay(item == :POTION ? "Use item in party" : "Battle ball drop")
      when :no_points
        pbSEPlay("GUI sel buzzer")
        pbMessage(_INTL("Not enough points! {1} costs {2}.", item_name(item), ITEMS[item][:price]))
      else
        pbSEPlay("GUI sel buzzer")
        pbMessage(_INTL("{1} is already working this round.", item_name(item))) if [:X_ATTACK, :X_DEFEND, :EXP_SHARE].include?(item)
      end
    end

    def tower_menu(t)
      name = GameData::Species.get(t.species).name
      info = if t.aura?
               _INTL("{1}: slows the Pokémon next to it, HP {2}/{3}{4}. You have {5} points.", name, [t.hp, 0].max, t.max_hp,
                     t.exp_need ? _INTL(", EXP {1}/{2}", t.exp, t.exp_need) : "", @game.points)
             elsif t.boost?
               _INTL("{1}: {2} damage, HP {3}/{4}. The towers around it get more HP and fire faster. You have {5} points.",
                     name, t.damage, [t.hp, 0].max, t.max_hp, @game.points)
             elsif t.exp_need
               _INTL("{1}: {2} damage, HP {3}/{4}, EXP {5}/{6}. You have {7} points.",
                     name, t.damage, [t.hp, 0].max, t.max_hp, t.exp, t.exp_need, @game.points)
             else
               _INTL("{1}: {2} damage, HP {3}/{4}. You have {5} points.", name, t.damage, [t.hp, 0].max, t.max_hp, @game.points)
             end
      cmds = []
      acts = []
      if t.evolve_cost
        nxt = GameData::Species.get(TOWERS[t.key][:line][t.stage + 1]).name
        cmds << if t.exp_ready?
                  _INTL("Evolve into {1} - {2} pts", nxt, t.evolve_cost)
                else
                  _INTL("Evolve (needs {1} more EXP)", t.exp_need - t.exp)
                end
        acts << :evolve
      end
      if t.hp < t.max_hp
        cmds << item_label(:POTION); acts << :potion
      end
      cmds << _INTL("Sell for {1} pts", t.sell_price); acts << :sell
      cmds << _INTL("Cancel"); acts << :cancel
      cmd = pbMessage(info, cmds, cmds.size - 1)
      case acts[cmd]
      when :evolve
        old = name
        case @game.evolve(t)
        when :ok
          pbSEPlay("Voltorb Flip gain coins")
          @flash[t.id] = 12
          pbMessage(_INTL("{1} evolved into {2}!", old, GameData::Species.get(t.species).name) + " " + tower_blurb(t))
        when :no_exp
          pbSEPlay("GUI sel buzzer")
          pbMessage(_INTL("{1} needs more experience first. Each Pokémon it knocks out gives 1 EXP (2 if that Pokémon was evolved).", old))
        when :no_points
          pbSEPlay("GUI sel buzzer")
          pbMessage(_INTL("Not enough points! Evolving costs {1}.", t.evolve_cost))
        end
      when :potion
        use_item(:POTION, t)
      when :sell
        if pbConfirmMessage(_INTL("Sell {1} for {2} points?", name, t.sell_price))
          @game.sell(t)
          pbSEPlay("Slots coin")
        end
      end
    end

    # what an evolved tower does now
    def tower_blurb(t)
      st = t.stats
      return _INTL("Its Gust blows up to {1} Pokémon {2} tiles back.", st[:carry], st[:push]) if t.gust?
      return _INTL("It slows the Pokémon next to it even more.") if t.aura?
      return _INTL("Its shots stun more often ({1}%).", (st[:stun] * 100).round) if st[:stun]
      return _INTL("It drains HP from the Pokémon it hits, healing itself and the towers next to it.") if st[:drain]
      return _INTL("It stings fast, and sometimes poisons.") if st[:poison] && st[:chance]
      return _INTL("Its slow attacks poison the Pokémon they hit.") if st[:poison]
      return _INTL("It fires fast!") if st[:delay] < 0.5
      return _INTL("Its strong shots reach further than anyone's.") if st[:range] >= 4
      _INTL("It does {1} damage now.", t.damage)
    end

    def pause_menu
      loop do
        cmds = []
        acts = []
        if @game.state == :build
          cmds << _INTL("Start round {1}", @game.round + 1); acts << :start
        else
          cmds << (@speed == 1 ? _INTL("Speed: x1") : _INTL("Speed: x2")); acts << :speed
        end
        cmds << _INTL("Items"); acts << :items
        cmds << _INTL("How to play"); acts << :help
        cmds << _INTL("Quit"); acts << :quit
        cmds << _INTL("Back"); acts << :back
        cmd = pbMessage(_INTL("Round {1}. Lives: {2}. Points: {3}.", @game.round, @game.lives, @game.points), cmds, cmds.size - 1)
        case acts[cmd]
        when :start then start_round; return nil
        when :speed then @speed = @speed == 1 ? 2 : 1
        when :items then return nil if items_menu
        when :help  then TowerDefense.how_to_play
        when :quit
          return :quit if pbConfirmMessage(_INTL("Quit this game? Your towers and round will be lost."))
        else return nil
        end
      end
    end

    # X Attack / X Defend (Potions: on a tower; Spikes, Poison Bombs: on a tile)
    def items_menu
      items = [:X_ATTACK, :X_DEFEND, :EXP_SHARE]
      when_text = @game.state == :build ? _INTL("They work for the next round.") : _INTL("They work for the rest of this round.")
      cmd = pbMessage(_INTL("Use an item? You have {1} points. {2}", @game.points, when_text),
                      items.map { |i| item_label(i) } + [_INTL("Cancel")], -1)
      return false if cmd < 0 || cmd >= items.size
      use_item(items[cmd])
      true
    end

    def game_over
      pbBGMStop
      pbSEPlay("Pkmn faint")
      pbMessage(_INTL("The wild Pokémon broke through! Game over on round {1}.", @game.round))
      if TowerDefense.record(@game.round)
        pbMessage(_INTL("That's a new best!"))
      end
      true
    end

    #--------------------------------------------------------------------------
    # what happened this frame: sounds, numbers, flashes
    #--------------------------------------------------------------------------
    def handle_events
      @game.events.each do |ev|
        case ev[0]
        when :hit
          e, dmg, mult = ev[1], ev[2], ev[3]
          @flash[e.id] = 4
          x, y, = @game.position(e.dist)
          if mult > 1
            float("x#{mult.round}!", x, y - 0.9, YELLOW)
          elsif mult < 1
            float("#{dmg}", x, y - 0.9, GREY)
          end
        when :knock_out
          e = ev[1]
          x, y, = @game.position(e.dist)
          float("+#{ev[2]}", x, y - 1.0, GREEN)
          if e.shiny
            float(_INTL("+1 life!"), x, y - 1.5, YELLOW, 70)
            pbSEPlay("Voltorb Flip gain coins")
          else
            pbSEPlay("Battle damage normal", 60)
          end
        when :leak
          pbSEPlay("Battle damage super")
          float(_INTL("-{1}", ev[1].boss ? BOSS_LEAK : 1), Graphics.width - 20, TOP + 8, RED, 40, true)
        when :boss_appears
          pbSEPlay("Battle critical catch throw")
          float(_INTL("BOSS {1}!", GameData::Species.get(ev[1].species).name), Graphics.width / 2, TOP + 120, RED, 90, true)
        when :special_appears
          pbSEPlay("Battle critical catch throw")
          float(_INTL("{1} drains your points!", GameData::Species.get(ev[1].species).name), Graphics.width / 2, TOP + 120, PURPLE, 110, true)
        when :drained
          x, y, = @game.position(ev[1].dist)
          float(_INTL("-{1} pts", ev[2]), x, y - 1.6, PURPLE, 45)
          pbSEPlay("Slots coin", 50, 70)
        when :stunned
          x, y, = @game.position(ev[1].dist)
          float(_INTL("STUN"), x, y - 1.1, YELLOW, 25)
        when :shiny_appears
          pbSEPlay("Anim/shiny")
          float(_INTL("A shiny {1}!", GameData::Species.get(ev[1].species).name), Graphics.width / 2, TOP + 96, YELLOW, 90, true)
        when :boss_attack
          t = ev[2]
          @flash[t.id] = 10
          float("-#{ev[3]}", t.x, t.row - 0.1, RED)
          pbSEPlay("Battle damage weak")
        when :tower_down
          t = ev[1]
          float(_INTL("{1} fainted!", GameData::Species.get(t.species).name), t.x, t.y, RED, 60)
          pbSEPlay("Pkmn faint")
        when :gust
          pbSEPlay("Anim/Gust", 60)
        when :healed
          float("+#{ev[2]}", ev[1].x, ev[1].row - 0.1, GREEN)
        when :spiked
          x, y, = @game.position(ev[1].dist)
          @flash[ev[1].id] = 6
          float("!", x, y - 0.9, GREY)
        when :poisoned
          x, y, = @game.position(ev[1].dist)
          float(_INTL("PSN"), x, y - 1.1, PURPLE, 30)
        when :bomb
          t = ev[1]
          @blasts << [t.x, t.y, 24]
          pbSEPlay("Battle damage super", 70, 60)
        when :item
          case ev[1]
          when :X_ATTACK then float(_INTL("X Attack! Towers hit harder."), Graphics.width / 2, TOP + 110, YELLOW, 70, true)
          when :X_DEFEND then float(_INTL("X Defend! Towers take half damage."), Graphics.width / 2, TOP + 110, BLUE, 70, true)
          when :EXP_SHARE then float(_INTL("Exp. Share! Every knock out trains every tower."), Graphics.width / 2, TOP + 110, BLUE, 80, true)
          when :POTION   then float("+#{POTION_HEAL}", ev[2].x, ev[2].row - 0.1, GREEN)
          end
        when :round_clear
          pbSEPlay("Voltorb Flip gain coins")
          float(_INTL("Round {1} clear! +{2}", ev[1], ev[2]), Graphics.width / 2, TOP + 110, YELLOW, 80, true)
          @game.towers.each { |t| float(_INTL("+{1} EXP", ROUND_EXP), t.x, t.row - 0.1, BLUE, 50) if t.exp_need }
          pbBGMPlay(MUSIC) if @game.boss_round?(ev[1]) || @game.special_round?(ev[1])
        when :round_start
          text = @game.boss_count > 1 ? _INTL("Round {1} - {2} bosses!", ev[1], @game.boss_count) : _INTL("Round {1}", ev[1])
          float(text, Graphics.width / 2, TOP + 110, WHITE, 50, true)
        when :pool_evolved
          float(_INTL("{1} are now {2}!", GameData::Species.get(ev[1]).name, GameData::Species.get(ev[2]).name),
                Graphics.width / 2, TOP + 136, YELLOW, 90, true)
        end
      end
      @game.events.clear
    end

    # x, y: map tiles (moves with the field), or screen pixels if screen
    def float(text, x, y, color, frames = 40, screen = false)
      @floaters << [text, x, y, frames, color, screen, 0.0]
    end

    #--------------------------------------------------------------------------
    # sprites
    #--------------------------------------------------------------------------
    def sheet(species)
      @sheets[species] ||= Bitmap.new(Dex.sprite(species) || "Graphics/Characters/Followers/000")
    end

    def new_walker(species)
      s = Sprite.new(@viewport)
      s.bitmap = sheet(species)
      fw, fh = s.bitmap.width / 4, s.bitmap.height / 4
      s.src_rect.set(0, 0, fw, fh)
      s.ox = fw / 2
      s.oy = fh - 6
      s
    end

    def frame(s, facing, step)
      fw, fh = s.bitmap.width / 4, s.bitmap.height / 4
      s.src_rect.set(step * fw, facing * fh, fw, fh)
    end

    def sync_sprites
      tick = Graphics.frame_count
      # towers
      @tower_sprites.delete_if do |t, s|
        next false if @game.towers.include?(t) && s.bitmap.equal?(sheet(t.species))
        s.dispose
        true
      end
      @game.towers.each do |t|
        s = (@tower_sprites[t] ||= new_walker(t.species))
        s.x = sx(t.x)
        s.y = sy(t.y) + 8
        s.z = 100 + t.row * 10
        frame(s, t.facing, (tick / 16) % 4)
        flash_color(s, t.id)
      end
      # walkers
      @enemy_sprites.delete_if do |e, s|
        next false if @game.enemies.include?(e)
        s.dispose
        true
      end
      @game.enemies.each do |e|
        unless (s = @enemy_sprites[e])
          s = @enemy_sprites[e] = new_walker(e.species)
          s.tone = Tone.new(48, 40, -40, 40) if e.shiny   # no shiny follower sprites: a golden tint
          s.tone = Tone.new(-40, -60, 0, 60) if e.special   # a dark, drained look
        end
        x, y, facing = @game.position(e.dist)
        s.x = sx(x)
        s.y = sy(y) + 8
        s.z = 100 + (y * 10).to_i + 1
        s.zoom_x = s.zoom_y = e.special ? 1.75 : e.boss ? 1.5 : 1.0
        s.visible = e.dist > 0.3
        frame(s, facing, e.stunned? ? 0 : (tick / (e.shiny ? 4 : e.slowed? ? 16 : 8) + e.id) % 4)
        flash_color(s, e.id, e.poisoned?, e.stunned? && (tick / 4).even?, e.slowed?)
      end
      # balls
      while @shot_sprites.size < @game.shots.size
        sp = Sprite.new(@viewport)
        sp.ox = sp.oy = 4
        sp.z = 800
        @shot_sprites << sp
      end
      @shot_sprites.each_with_index do |sp, i|
        shot = @game.shots[i]
        sp.visible = !shot.nil?
        next unless shot
        sp.bitmap = @shot_bitmaps[shot.type] || @shot_bitmaps[:GRASS]
        sp.x = sx(shot.x)
        sp.y = sy(shot.y)
      end
    end

    def flash_color(s, id, poisoned = false, stunned = false, slowed = false)
      n = @flash[id].to_i
      if n > 0
        s.color = Color.new(255, 255, 255, 180)
        @flash[id] = n - 1
      elsif stunned
        s.color = Color.new(248, 224, 48, 140)
      elsif poisoned
        s.color = Color.new(160, 64, 200, 110)
      elsif slowed
        s.color = Color.new(96, 200, 160, 90)
      else
        s.color = Color.new(0, 0, 0, 0)
      end
    end

    #--------------------------------------------------------------------------
    # drawing
    #--------------------------------------------------------------------------
    def draw_hud
      b = @hud.bitmap
      b.clear
      b.fill_rect(0, 0, b.width, TOP, Color.new(40, 48, 72))
      b.fill_rect(0, TOP - 2, b.width, 2, Color.new(24, 24, 40))
      round = @game.round == 0 ? "-" : @game.round.to_s
      hint = if @game.state == :build
               _INTL("A: start round {1}   C: build   B: menu", @game.round + 1)
             elsif @game.special_round?
               _INTL("A: speed x{1}   Stop it before it drains you!", @speed == 1 ? 2 : 1)
             elsif @game.boss_round?
               _INTL("A: speed x{1}   Boss round!", @speed == 1 ? 2 : 1)
             else
               _INTL("A: speed x{1}   Boss in {2}", @speed == 1 ? 2 : 1, BOSS_EVERY - @game.round % BOSS_EVERY)
             end
      texts = [
        [_INTL("Round {1}", round), 6, 0, :left, WHITE, SHADOW],
        [_INTL("Lives {1}", @game.lives), 92, 0, :left, @game.lives <= 3 ? RED : WHITE, SHADOW],
        [_INTL("{1} pts", @game.points), Graphics.width - 6, 0, :right, YELLOW, SHADOW],
        [hint, 6, 15, :left, GREY, SHADOW]
      ]
      texts << [_INTL("X ATK"), 168, 0, :left, YELLOW, SHADOW] if @game.x_attack
      texts << [_INTL("X DEF"), 208, 0, :left, BLUE, SHADOW] if @game.x_defend
      texts << [_INTL("EXP"), 246, 0, :left, GREEN, SHADOW] if @game.exp_share
      texts << ["x2", Graphics.width - 6, 15, :right, GREEN, SHADOW] if @speed == 2 && @game.state == :wave
      pbDrawTextPositions(b, texts)
    end

    def draw_overlay
      b = @overlay.bitmap
      b.clear
      c, r = @cursor
      tick = Graphics.frame_count
      draw_traps(b, tick)
      # the cursor's tower range
      if (t = @game.tower_at(c, r))
        if t.gust?
          dx, dy = DIRS[t.facing]
          (t.range * 4).to_i.times do |k|
            d = 0.5 + k * 0.25
            b.fill_rect(sx(t.x + dx * d) - 1, sy(t.y + dy * d) - 1, 3, 3, Color.new(255, 255, 255, 160))
          end
        else
          circle(b, sx(t.x), sy(t.y), t.range * TILE, t.boost? ? Color.new(248, 120, 184, 170) : Color.new(255, 255, 255, 140))
        end
      end
      draw_gusts(b, tick)
      # cursor (blinking)
      if (tick / 20).even? || @game.state == :build
        col = @game.buildable?(c, r) || @game.tower_at(c, r) || (@game.path?(c, r) && !@game.trap_at(c, r)) ?
              Color.new(255, 255, 255, 220) : Color.new(240, 80, 80, 200)
        x, y = sx(c), sy(r)
        b.fill_rect(x, y, TILE, 2, col); b.fill_rect(x, y + TILE - 2, TILE, 2, col)
        b.fill_rect(x, y, 2, TILE, col); b.fill_rect(x + TILE - 2, y, 2, TILE, col)
      end
      # HP bars: hurt walkers, every boss; shiny sparkles; arrows to Pokémon off the screen
      @game.enemies.each do |e|
        x, y, = @game.position(e.dist)
        px, py = sx(x), sy(y)
        sparkles(b, px, py - 12, tick, e.id) if e.shiny && e.dist > 0.3
        if e.boss || e.hp < e.max_hp
          bar(b, px - 12, py - (e.special ? 52 : e.boss ? 46 : 32), 24, e.hp.to_f / e.max_hp,
              e.special ? PURPLE : e.boss ? RED : e.poisoned? ? PURPLE : GREEN)
        end
        edge_marker(b, px, py, e) if e.dist > 0.3
      end
      # towers: HP if hurt, EXP towards the next evolution
      @game.towers.each do |t|
        x, y = sx(t.x), sy(t.row)
        bar(b, x - 12, y - 4, 24, [t.hp, 0].max.to_f / t.max_hp, YELLOW) if t.hp < t.max_hp
        if t.boosted   # Mew's boost: a little pink diamond
          b.fill_rect(x + 11, y + 3, 2, 6, PINK); b.fill_rect(x + 9, y + 5, 6, 2, PINK)
        end
        next unless t.exp_need
        ready = t.exp_ready?
        bar(b, x - 12, y + TILE + 2, 24, t.exp.to_f / t.exp_need, ready && (tick / 15).even? ? YELLOW : BLUE)
      end
      # Poison Bomb blasts
      @blasts.each do |bx, by, n|
        rad = BOMB_RADIUS * TILE * (1 - n / 30.0)
        circle(b, sx(bx), sy(by), rad, Color.new(176, 88, 200, 60 + n * 8))
      end
      @blasts.each { |bl| bl[2] -= 1 }
      @blasts.reject! { |bl| bl[2] <= 0 }
      # floating texts
      @floaters.each do |f|
        f[6] += 0.5
        f[3] -= 1
        x, y = f[5] ? [f[1], f[2]] : [sx(f[1]), sy(f[2])]
        pbDrawTextPositions(b, [[f[0], x.to_i, (y - f[6]).to_i, :center, f[4], SHADOW]])
      end
      @floaters.reject! { |f| f[3] <= 0 }
    end

    # a Gust: a swirl of wind flying straight
    def draw_gusts(b, tick)
      @game.gusts.each do |g|
        x, y = sx(g.x), sy(g.y) - 6
        3.times do |ring|
          rad = 4 + ring * 4
          6.times do |k|
            a = tick * 0.4 + k * Math::PI / 3 + ring
            col = ring == 1 ? Color.new(255, 255, 255, 200) : Color.new(200, 224, 248, 170)
            b.fill_rect((x + Math.cos(a) * rad).to_i, (y + Math.sin(a) * rad * 0.6).to_i, 2, 2, col)
          end
        end
      end
    end

    def draw_traps(b, tick)
      @game.traps.each do |t|
        x, y = sx(t.col), sy(t.row)
        next if x < -TILE || y < TOP - TILE || x > Graphics.width || y > Graphics.height
        if t.kind == :spikes
          grey = Color.new(120, 120, 136)
          light = Color.new(208, 208, 224)
          [[6, 10], [18, 6], [10, 20], [22, 20]].each do |dx, dy|
            4.times { |k| b.fill_rect(x + dx + k, y + dy + 6 - k * 2, 6 - k * 2, 2, k == 3 ? light : grey) }
          end
          bar(b, x + 4, y + TILE - 5, TILE - 8, t.time / SPIKES_TIME, GREY)
        else
          blink = t.time < 1.5 && (tick / 4).even?
          col = blink ? Color.new(248, 80, 80) : Color.new(120, 56, 152)
          cx, cy = x + TILE / 2, y + TILE / 2 + 2
          7.times do |k|
            w = [3, 5, 6, 7, 6, 5, 3][k] * 2
            b.fill_rect(cx - w / 2, cy - 7 + k * 2, w, 2, col)
          end
          b.fill_rect(cx - 1, cy - 11, 2, 4, Color.new(80, 64, 48))
          b.fill_rect(cx - 3, cy - 4, 3, 3, Color.new(208, 160, 232))
          pbDrawTextPositions(b, [[t.time.ceil.to_s, cx, cy - 4, :center, WHITE, SHADOW]])
        end
      end
    end

    # a few twinkling stars around a shiny
    def sparkles(b, x, y, tick, seed)
      4.times do |i|
        a = (tick + seed * 7) * 0.12 + i * Math::PI / 2
        rad = 12 + 3 * Math.sin((tick + i * 9) * 0.3)
        px = (x + Math.cos(a) * rad).to_i
        py = (y + Math.sin(a) * rad * 0.8).to_i
        col = (tick / 3 + i).even? ? Color.new(255, 255, 255) : Color.new(255, 232, 96)
        size = (tick / 4 + i) % 3 == 0 ? 2 : 1
        b.fill_rect(px - size, py, size * 2 + 1, 1, col)
        b.fill_rect(px, py - size, 1, size * 2 + 1, col)
      end
    end

    # a Pokémon off the screen: a dot on that edge (red for a boss, gold shiny)
    def edge_marker(b, px, py, e)
      return if px.between?(0, Graphics.width) && py.between?(TOP, Graphics.height)
      mx = px.clamp(2, Graphics.width - 5)
      my = py.clamp(TOP + 2, Graphics.height - 5)
      col = e.special ? PURPLE : e.boss ? RED : e.shiny ? YELLOW : Color.new(248, 248, 248, 200)
      b.fill_rect(mx - 1, my - 1, e.boss ? 5 : 3, e.boss ? 5 : 3, col)
    end

    def bar(b, x, y, w, frac, color)
      b.fill_rect(x - 1, y - 1, w + 2, 5, Color.new(32, 32, 32))
      b.fill_rect(x, y, (w * frac.clamp(0, 1)).ceil, 3, color)
    end

    def circle(b, cx, cy, rad, color)
      n = (rad * 2).to_i
      n.times do |i|
        a = i * 2 * Math::PI / n
        b.fill_rect((cx + Math.cos(a) * rad).to_i, (cy + Math.sin(a) * rad).to_i, 2, 2, color)
      end
    end

    def ball_bitmap(rgb)
      bm = Bitmap.new(8, 8)
      8.times do |y|
        8.times do |x|
          d = (x - 3.5)**2 + (y - 3.5)**2
          next if d > 13
          shade = d < 3 && x < 4 && y < 4 ? 70 : (d > 8 ? -50 : 0)
          bm.fill_rect(x, y, 1, 1, Color.new(*rgb.map { |v| (v + shade).clamp(0, 255) }))
        end
      end
      bm
    end

    # the grass, the track, flowers (the whole field; it scrolls)
    def draw_field
      bm = Bitmap.new(COLS * TILE, ROWS * TILE)
      rng = Random.new(@game.path.hash)
      grass = [Color.new(112, 192, 80), Color.new(104, 184, 72)]
      dark  = Color.new(80, 152, 56)
      sand  = Color.new(224, 192, 128)
      edge  = Color.new(176, 136, 80)
      ROWS.times do |r|
        COLS.times do |c|
          x, y = c * TILE, r * TILE
          if @game.path?(c, r)
            bm.fill_rect(x, y, TILE, TILE, sand)
            bm.fill_rect(x, y, TILE, 3, edge) unless @game.path?(c, r - 1)
            bm.fill_rect(x, y + TILE - 3, TILE, 3, edge) unless @game.path?(c, r + 1)
            bm.fill_rect(x, y, 3, TILE, edge) unless @game.path?(c - 1, r) || [c - 1, r] == @game.route.first
            bm.fill_rect(x + TILE - 3, y, 3, TILE, edge) unless @game.path?(c + 1, r) || [c + 1, r] == @game.route.last
            4.times { bm.fill_rect(x + 4 + rng.rand(TILE - 8), y + 4 + rng.rand(TILE - 8), 2, 2, edge) }
          else
            bm.fill_rect(x, y, TILE, TILE, grass[(c + r) % 2])
            5.times do
              gx, gy = x + rng.rand(TILE - 3), y + rng.rand(TILE - 4)
              bm.fill_rect(gx, gy, 1, 3, dark); bm.fill_rect(gx + 2, gy + 1, 1, 2, dark)
            end
            if rng.rand(6) == 0
              fc = [Color.new(248, 248, 248), Color.new(248, 120, 136), Color.new(248, 216, 80)].sample(random: rng)
              fx, fy = x + rng.rand(6..TILE - 8), y + rng.rand(6..TILE - 8)
              bm.fill_rect(fx, fy - 1, 2, 1, fc); bm.fill_rect(fx - 1, fy, 4, 1, fc); bm.fill_rect(fx, fy + 1, 2, 1, fc)
            end
          end
        end
      end
      # entry and exit arrows
      [@game.path.first, @game.path.last].each_with_index do |(c, r), i|
        x = i == 0 ? c * TILE + 2 : c * TILE + TILE - 10
        y = r * TILE + TILE / 2
        4.times { |k| bm.fill_rect(x + k * 2, y - 4 + k, 2, 8 - k * 2, Color.new(200, 64, 48)) }
      end
      bm
    end
  end
end
