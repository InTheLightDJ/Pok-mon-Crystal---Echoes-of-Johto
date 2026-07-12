#===============================================================================
# "Slot Machine" mini-game
# By Maruno
#-------------------------------------------------------------------------------
# Run with:      pbSlotMachine(1)
# - The number is either 0 (easy), 1 (default) or 2 (hard).
#===============================================================================
class SlotMachineReel < BitmapSprite
  SCROLL_SPEED = 640   # Pixels moved per second
  ICONS_SETS = [[3, 2, 7, 6, 3, 1, 5, 2, 3, 0, 6, 4, 7, 5, 1, 3, 2, 3, 6, 0, 4, 5],   # Reel 1
                [0, 4, 1, 2, 7, 4, 6, 0, 1, 5, 4, 0, 1, 3, 4, 0, 1, 6, 7, 0, 1, 5],   # Reel 2
                [6, 2, 1, 4, 3, 2, 1, 4, 7, 3, 2, 1, 4, 3, 7, 2, 4, 3, 1, 2, 4, 5]]   # Reel 3
  SLIPPING    = [0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3]
  GREEN_SEVEN = 8   # icon index for green 7 (column 8 on the images sheet)

  def initialize(x, y, reel_num, difficulty = 1)
    @viewport = Viewport.new(x, y, 32, 96)
    @viewport.z = 99999
    super(32, 96, @viewport)
    @reel_num = reel_num
    @difficulty = difficulty
    @reel = ICONS_SETS[reel_num - 1].clone
    @original_reel = @reel.dup
    @toppos = 0
    @current_y_pos = -1
    @spin_speed = SCROLL_SPEED
    @spin_speed /= 1.5 if difficulty == 0
    @spinning = false
    @stopping = false
    @slipping = 0
    @__snapping = false
    @index = rand(@reel.length)
    @images = AnimatedBitmap.new(_INTL("Graphics/UI/Slot Machine/images"))
    @shading = AnimatedBitmap.new("Graphics/UI/Slot Machine/ReelOverlay")
    update
  end

  def enable_green7
    @reel = @original_reel.dup
    # Spread 3 green 7 icons evenly across the 22-slot reel
    @reel[3]  = GREEN_SEVEN
    @reel[10] = GREEN_SEVEN
    @reel[17] = GREEN_SEVEN
  end

  def disable_green7
    @reel = @original_reel.dup
  end

  def startSpinning
    @spinning = true
    @spin_timer_start = System.uptime
    @initial_index = @index + 1
    @current_y_pos = -1
  end

  def spinning?
    return @spinning || !!@__snapping
  end

  def stopSpinning(noslipping = false)
    @stopping = true
    @slipping = SLIPPING.sample
    case @difficulty
    when 0   # Easy
      second_slipping = SLIPPING.sample
      @slipping = [@slipping, second_slipping].min
    when 2   # Hard
      second_slipping = SLIPPING.sample
      @slipping = [@slipping, second_slipping].max
    end
    @slipping = 0 if noslipping
  end

  def slowExtraSpin(num_icons)
    @__snap_target = (@index + num_icons) % @reel.length
    @__snap_at = System.uptime + num_icons * 0.3
    @__snapping = true
  end

  def showing
    array = []
    3.times do |i|
      num = @index - i
      num += @reel.length if num < 0
      array.push(@reel[num])
    end
    return array   # [0] = top, [1] = middle, [2] = bottom
  end

  def update
    self.bitmap.clear
    if @spinning
      new_y_pos = (System.uptime - @spin_timer_start) * @spin_speed
      new_index = (new_y_pos / @images.height).to_i
      old_index = (@current_y_pos / @images.height).to_i
      @current_y_pos = new_y_pos
      @toppos = new_y_pos
      while @toppos > 0
        @toppos -= @images.height
      end
      if new_index != old_index
        if @stopping
          if @slipping == 0
            @spinning = false
            @stopping = false
            @toppos = 0
          else
            @slipping = [@slipping - new_index + old_index, 0].max
          end
        end
        if @spinning
          @index = (new_index + @initial_index) % @reel.length
        end
      end
    end
    if @__snapping && System.uptime >= @__snap_at
      @index = @__snap_target
      @__snapping = false
    end
    4.times do |i|
      num = @index - i
      num += @reel.length if num < 0
      self.bitmap.blt(0, @toppos + (i * 32), @images.bitmap, Rect.new(@reel[num] * 32, 0, 32, 32))
    end
    self.bitmap.blt(0, 0, @shading.bitmap, Rect.new(0, 0, 32, 96))
  end
end

#===============================================================================
#
#===============================================================================
class SlotMachineScore < BitmapSprite
  attr_reader :score

  def initialize(x, y, score = 0)
    @viewport = Viewport.new(x, y, 80, 16)
    @viewport.z = 99999
    super(80, 16, @viewport)
    @numbers = AnimatedBitmap.new("Graphics/UI/Slot Machine/numbers")
    self.score = score
  end

  def score=(value)
    @score = value
    @score = Settings::MAX_COINS if @score > Settings::MAX_COINS
    refresh
  end

  def refresh
    self.bitmap.clear
    5.times do |i|
      digit = (@score / (10**i)) % 10 # Least significant digit first
      self.bitmap.blt(16 * (4 - i), 0, @numbers.bitmap, Rect.new(digit * 16, 0, 16, 16))
    end
  end
end

#===============================================================================
#
#===============================================================================
class SlotMachineScene
  attr_accessor :gameRunning
  attr_accessor :gameEnd
  attr_accessor :wager
  attr_accessor :replay

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def pbPayout
    @replay = false
    payout = 0
    bonus = 0
    green7_award = 0
    wonRow = []
    # Get reel pictures
    reel1 = @sprites["reel1"].showing
    reel2 = @sprites["reel2"].showing
    reel3 = @sprites["reel3"].showing
    combinations = [[reel1[1], reel2[1], reel3[1]],   # Centre row
                    [reel1[0], reel2[0], reel3[0]],   # Top row
                    [reel1[2], reel2[2], reel3[2]],   # Bottom row
                    [reel1[0], reel2[1], reel3[2]],   # Diagonal top left -> bottom right
                    [reel1[2], reel2[1], reel3[0]]]   # Diagonal bottom left -> top right
    combinations.length.times do |i|
      break if i >= 1 && @wager <= 1 # One coin = centre row only
      break if i >= 3 && @wager <= 2 # Two coins = three rows only
      wonRow[i] = true
      case combinations[i]
      when [1, 1, 1]   # Three Black Pokeballs
        payout += 40
      when [2, 2, 2]   # Three Staryus
        payout += 8
      when [3, 3, 3]   # Three Pikachus
        payout += 15
      when [4, 4, 4]   # Three Psyducks
        payout += 15
      when [5, 5, 6], [5, 6, 5], [6, 5, 5], [6, 6, 5], [6, 5, 6], [5, 6, 6]   # 777 multi-colored
        payout += 90
        green7_award = [green7_award, 1].max
        bonus = 1 if bonus < 1
      when [5, 5, 5]  # Red 777, blue 777
        payout += 500
        green7_award = [green7_award, 5].max
        if $player.bugshop_purchases != {}
          $player.bugshop_purchases.delete(:MASTERBALL)
          $player.bugshop_purchases.delete(:ABILITYPATCH)
          $player.bugshop_purchases.delete(:PPMAX)
          $player.bugshop_purchases.delete(:SACREDASH)
          $player.bugshop_purchases.delete(:THUNDERSTONE)
          $player.bugshop_purchases.delete(:FIRESTONE)
          $player.bugshop_purchases.delete(:WATERSTONE)
          $player.bugshop_purchases.delete(:LEAFSTONE)
          $player.bugshop_purchases.delete(:MOONSTONE)
          $player.bugshop_purchases.delete(:KINGSROCK)
          $player.bugshop_purchases.delete(:METALCOAT)
          $player.bugshop_purchases.delete(:LINKINGCORD)
          pbMessage("The Bug Shop has been refreshed! You can now buy everything again.")
        end
        bonus = 2 if bonus < 2
      when [6, 6, 6]   # Blue 777
        payout += 300
        green7_award = [green7_award, 3].max
        if $player.bugshop_purchases != {}
          $player.bugshop_purchases.delete(:MASTERBALL)
          $player.bugshop_purchases.delete(:ABILITYPATCH)
          $player.bugshop_purchases.delete(:PPMAX)
          $player.bugshop_purchases.delete(:SACREDASH)
          $player.bugshop_purchases.delete(:THUNDERSTONE)
          $player.bugshop_purchases.delete(:FIRESTONE)
          $player.bugshop_purchases.delete(:WATERSTONE)
          $player.bugshop_purchases.delete(:LEAFSTONE)
          $player.bugshop_purchases.delete(:MOONSTONE)
          $player.bugshop_purchases.delete(:KINGSROCK)
          $player.bugshop_purchases.delete(:METALCOAT)
          $player.bugshop_purchases.delete(:LINKINGCORD)
          pbMessage("The Bug Shop has been refreshed! You can now buy everything again.")
        end
        bonus = 2 if bonus < 2
      when [7, 7, 7]   # Three replays
        @replay = true
      else
        if combinations[i][0] == 0   # Left cherry
          if combinations[i][1] == 0   # Centre cherry as well
            if combinations[i][2] == 0   # right cherry as well
              payout += 10
            else
              payout += 4
            end
          else
            payout += 2
          end
        else
          wonRow[i] = false
        end
      end
    end
    @sprites["payout"].score = payout
    if payout > 0 || @replay
      if bonus > 0
        pbMEPlay("Slots big win")
      else
        pbMEPlay("Slots win")
      end
      # Show winning animation
      timer_start = System.uptime
      loop do
        frame = ((System.uptime - timer_start) / 0.125).to_i
        @sprites["window2"].bitmap&.clear
        @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/win"))
        @sprites["window1"].src_rect.set(Graphics.width * (frame % 4), 0, Graphics.width, 96)
        if bonus > 0
          @sprites["window2"].setBitmap(_INTL("Graphics/UI/Slot Machine/bonus"))
          @sprites["window2"].src_rect.set(Graphics.width * (bonus - 1), 0, Graphics.width, 96)
        end
        @sprites["light1"].visible = true
        @sprites["light1"].src_rect.set(0, 178 * (frame % 4), Graphics.width, 178)
        @sprites["light2"].visible = true
        @sprites["light2"].src_rect.set(0, 178 * (frame % 4), Graphics.width, 178)
        (1..5).each do |i|
          if wonRow[i - 1]
            @sprites["row#{i}"].visible = frame.even?
          else
            @sprites["row#{i}"].visible = false
          end
        end
        Graphics.update
        Input.update
        update
        break if System.uptime - timer_start >= 3.0
      end
      @sprites["light1"].visible = false
      @sprites["light2"].visible = false
      @sprites["window1"].src_rect.set(0, 0, 152, 208)
      # Pay out
      timer_start = System.uptime
      last_paid_tick = -1
      loop do
        break if @sprites["payout"].score <= 0
        Graphics.update
        Input.update
        update
        this_tick = ((System.uptime - timer_start) * 20).to_i   # Pay out 1 coin every 1/20 seconds
        if this_tick != last_paid_tick
          @sprites["payout"].score -= 1
          @sprites["credit"].score += 1
          this_tick = last_paid_tick
        end
        if Input.trigger?(Input::USE) || @sprites["credit"].score == Settings::MAX_COINS
          @sprites["credit"].score += @sprites["payout"].score
          @sprites["payout"].score = 0
        end
      end
      # Wait
      timer_start = System.uptime
      loop do
        Graphics.update
        Input.update
        update
        break if System.uptime - timer_start >= 0.5
      end
    else
      # Show losing animation
      timer_start = System.uptime
      loop do
        frame = ((System.uptime - timer_start) / 0.25).to_i
        @sprites["window2"].bitmap&.clear
        @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/lose"))
        @sprites["window1"].src_rect.set(Graphics.width * (frame % 2), 0, Graphics.width, 96)
        Graphics.update
        Input.update
        update
        break if System.uptime - timer_start >= 2.0
      end
    end
    @green7_spins += green7_award if green7_award > 0
    @wager = 0
  end

  def pbSpecialEvent1
    num_icons = 3 + rand(5)  # 3-7 extra icon positions, slow spin
    @sprites["reel3"].slowExtraSpin(num_icons)
    loop do
      Graphics.update
      Input.update
      update
      break unless @sprites["reel3"].spinning?
    end
    pbSEPlay("Slots stop")
  end

  def pbSpecialEvent2
    num_rocks = 4 + rand(4)  # 4-7 rocks

    # Wigglytuff follower sprite — determine cell size dynamically
    wiggly_bmp = AnimatedBitmap.new("Graphics/Characters/Followers/WIGGLYTUFF")
    cell_w     = wiggly_bmp.width / 4
    cell_h     = wiggly_bmp.height / 4
    wiggly_vp  = Viewport.new(0, 0, Graphics.width, Graphics.height)
    wiggly_vp.z = 100001
    wiggly_spr  = Sprite.new(wiggly_vp)
    wiggly_spr.bitmap = wiggly_bmp.bitmap

    # Rock animation sheet — 96×96 cells, 5 per row
    rock_src  = AnimatedBitmap.new("Graphics/Animations/Scratch-Slash-Cut-STEEL-ROCK")
    rock_sz   = 40
    rock_draw = Bitmap.new(rock_sz, rock_sz)
    rock_vp   = Viewport.new(0, 0, Graphics.width, Graphics.height)
    rock_vp.z = 100002
    rock_spr  = Sprite.new(rock_vp)
    rock_spr.bitmap = rock_draw
    rock_spr.ox = rock_sz / 2
    rock_spr.oy = rock_sz / 2
    rock_spr.visible = false

    down_row    = 0   # facing-down row in follower sheet
    right_row   = 2   # facing-right row
    left_row    = 1   # facing-left row
    walk_frames = [0, 1, 2, 1]
    walk_speed  = 120.0  # px/s

    # Reel 3 viewport is at x=208, y=64, size 32×96
    target_x = 208
    target_y = 160 - cell_h   # just below reel bottom (y=160)
    rock_ox  = target_x + cell_w / 2   # hands x: 208+16=224
    rock_oy  = target_y + 4            # hands y
    rock_tx  = 208 + 16                # center of reel 3
    rock_ty  = 64 + 48                 # mid-reel y

    # Walk in from off-screen left using right-facing frames
    wiggly_x = -cell_w.to_f
    wiggly_spr.x = wiggly_x.to_i
    wiggly_spr.y = target_y
    f_timer = System.uptime
    f_idx   = 0
    prev_t  = System.uptime

    until wiggly_x >= target_x
      now      = System.uptime
      delta    = now - prev_t
      prev_t   = now
      wiggly_x = [wiggly_x + walk_speed * delta, target_x.to_f].min
      wiggly_spr.x = wiggly_x.to_i
      if now - f_timer >= 0.12
        f_timer = now
        f_idx   = (f_idx + 1) % 4
      end
      wiggly_spr.src_rect.set(walk_frames[f_idx] * cell_w, right_row * cell_h, cell_w, cell_h)
      Graphics.update; Input.update; update
    end

    # Face down, idle
    wiggly_spr.src_rect.set(cell_w, down_row * cell_h, cell_w, cell_h)
    t0 = System.uptime
    loop { Graphics.update; Input.update; update; break if System.uptime - t0 >= 0.3 }

    num_rocks.times do |i|
      # Wind-up frame
      wiggly_spr.src_rect.set(0, down_row * cell_h, cell_w, cell_h)
      t0 = System.uptime
      loop { Graphics.update; Input.update; update; break if System.uptime - t0 >= 0.15 }

      # Show rock at hands — frame 12: row 2 col 1 → x=96, y=192
      rock_draw.clear
      rock_draw.stretch_blt(Rect.new(0, 0, rock_sz, rock_sz),
                            rock_src.bitmap, Rect.new(96, 192, 96, 96))
      rock_spr.x = rock_ox
      rock_spr.y = rock_oy
      rock_spr.visible = true

      # Throw frame
      wiggly_spr.src_rect.set(2 * cell_w, down_row * cell_h, cell_w, cell_h)

      # Fly rock up to reel center
      fly_start = System.uptime
      loop do
        t = [(System.uptime - fly_start) / 0.35, 1.0].min
        rock_spr.x = (rock_ox + (rock_tx - rock_ox) * t).to_i
        rock_spr.y = (rock_oy + (rock_ty - rock_oy) * t).to_i
        Graphics.update; Input.update; update
        break if t >= 1.0
      end
      rock_spr.x = rock_tx
      rock_spr.y = rock_ty

      # Impact: frames 12,13,13,14,14,15,15  (all row 2: y=192; cols 1,2,3,4 → x=96,192,288,384)
      [[96, 192], [192, 192], [192, 192],
       [288, 192], [288, 192], [384, 192], [384, 192]].each do |fx, fy|
        rock_draw.clear
        rock_draw.stretch_blt(Rect.new(0, 0, rock_sz, rock_sz),
                              rock_src.bitmap, Rect.new(fx, fy, 96, 96))
        t0 = System.uptime
        loop { Graphics.update; Input.update; update; break if System.uptime - t0 >= 0.07 }
      end

      rock_spr.visible = false
      wiggly_spr.src_rect.set(cell_w, down_row * cell_h, cell_w, cell_h)

      # Each rock hit randomly spins reel 3
      @sprites["reel3"].slowExtraSpin(1 + rand(4))
      loop { Graphics.update; Input.update; update; break unless @sprites["reel3"].spinning? }
      pbSEPlay("Slots stop")

      unless i == num_rocks - 1
        t0 = System.uptime
        loop { Graphics.update; Input.update; update; break if System.uptime - t0 >= 0.25 }
      end
    end

    # Walk Wigglytuff off-screen left
    f_idx   = 0
    f_timer = System.uptime
    prev_t  = System.uptime
    until wiggly_x <= -cell_w.to_f
      now      = System.uptime
      delta    = now - prev_t
      prev_t   = now
      wiggly_x = [wiggly_x - walk_speed * delta, -cell_w.to_f].max
      wiggly_spr.x = wiggly_x.to_i
      if now - f_timer >= 0.12
        f_timer = now
        f_idx   = (f_idx + 1) % 4
      end
      wiggly_spr.src_rect.set(walk_frames[f_idx] * cell_w, left_row * cell_h, cell_w, cell_h)
      Graphics.update; Input.update; update
    end

    wiggly_spr.dispose
    wiggly_vp.dispose
    wiggly_bmp.dispose
    rock_spr.dispose
    rock_vp.dispose
    rock_draw.dispose
    rock_src.dispose
  end

  def pbGreenSevenJackpot
    # Build pool of breedable, non-legendary, non-mythical base-form species
    valid_species = []
    GameData::Species.each do |sp|
      next if sp.form.to_i > 0
      next if (sp.has_flag?("Legendary") rescue false)
      next if (sp.has_flag?("Mythical")  rescue false)
      next if (sp.has_flag?("UltraBeast") rescue false)
      next if sp.egg_groups.include?(:Undiscovered)
      valid_species << sp.id
    end
    if valid_species.empty?
      pbMessage(_INTL("The green light faded with nothing inside..."))
      return
    end
    if pbBoxesFull?
      pbMessage(_INTL("Your PC Boxes are full!\nThe mysterious Egg disappeared..."))
      return
    end
    species  = valid_species.sample
    egg      = Pokemon.new(species, Settings::EGG_LEVEL)
    egg.name = _INTL("Egg")
    hatch    = (egg.species_data.hatch_steps rescue 0)
    egg.steps_to_hatch = hatch > 0 ? hatch : 5120
    egg.obtain_text    = _INTL("Slot Machine")
    egg.calc_stats
    stored_box = $PokemonStorage.pbStoreCaught(egg)
    box_name   = ($PokemonStorage[stored_box].name rescue "a Box")
    pbMEPlay("Slots big win")
    pbMessage(_INTL("Three Green 7s!\nA mysterious Egg was sent to Box \"{1}\"!", box_name))
    pbGiveAchievementOnce(17) rescue nil
  end

  def pbShowPayoutGuide
    vp  = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = 100000
    spr = BitmapSprite.new(Graphics.width, Graphics.height, vp)
    bmp = spr.bitmap
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    icons = AnimatedBitmap.new("Graphics/UI/Slot Machine/images")

    row_h   = 28
    y_start = 34
    pad     = 4
    icon_sz = 24

    bmp.font.bold  = true
    bmp.font.size  = 20
    bmp.font.color = Color.new(255, 220, 0)
    bmp.draw_text(0, 4, Graphics.width, 26, "PRIZE GUIDE", 1)

    rows = [
      [[0, 0, 0],    "Cherry × 3",     "10"],
      [[0, 0, nil],  "Cherry  L + C",  "4"],
      [[0, nil, nil],"Cherry  L only", "2"],
      [[1, 1, 1],    "Poké Ball × 3",  "40"],
      [[2, 2, 2],    "Staryu × 3",     "8"],
      [[3, 3, 3],    "Pikachu × 3",    "15"],
      [[4, 4, 4],    "Squirtle × 3",   "15"],
      [[5, 6, 5],    "Rainbow 7s",     "90"],
      [[5, 5, 5],    "Red 777",        "500"],
      [[6, 6, 6],    "Blue 777",       "300"],
      [[7, 7, 7],    "Replay",         "FREE"],
    ]

    icon_area = 3 * icon_sz          # 72px
    tx_start  = pad + icon_area + 6  # 82px from left
    label_w   = 140
    val_left  = tx_start + label_w   # 222px
    val_right = Graphics.width - pad # 316px
    val_w     = val_right - val_left # 94px

    rows.each_with_index do |(ids, label, value), i|
      y   = y_start + i * row_h
      iy  = y + (row_h - icon_sz) / 2
      ty  = y + (row_h - 18) / 2

      ids.each_with_index do |id, j|
        next unless id
        bmp.stretch_blt(Rect.new(pad + j * icon_sz, iy, icon_sz, icon_sz),
                        icons.bitmap, Rect.new(id * 32, 0, 32, 32))
      end

      bmp.font.bold  = false
      bmp.font.size  = 14
      bmp.font.color = Color.new(210, 210, 210)
      bmp.draw_text(tx_start, ty, label_w, 18, label)

      bmp.font.bold  = true
      bmp.font.color = Color.new(255, 200, 50)
      bmp.draw_text(val_left, ty, val_w, 18, value, 2)
    end

    note_y = y_start + rows.size * row_h + 4
    bmp.font.bold  = false
    bmp.font.size  = 11
    bmp.font.color = Color.new(140, 140, 110)
    bmp.draw_text(0, note_y, Graphics.width, 14, "777 also resets the Bug Shop", 1)

    bmp.font.size  = 13
    bmp.font.color = Color.new(100, 100, 100)
    bmp.draw_text(0, Graphics.height - 18, Graphics.width, 16, "Q / W  —  Close", 1)

    loop do
      Graphics.update
      Input.update
      break if Input.trigger?(Input::L) || Input.trigger?(Input::R) || Input.trigger?(Input::BACK)
    end

    icons.dispose
    spr.dispose
    vp.dispose
  end

  def pbStartScene(difficulty)
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites, "bg", "Slot Machine/bg", @viewport)
    @sprites["reel1"] = SlotMachineReel.new(80, 64, 1, difficulty)
    @sprites["reel2"] = SlotMachineReel.new(144, 64, 2, difficulty)
    @sprites["reel3"] = SlotMachineReel.new(208, 64, 3, difficulty)
    (1..3).each do |i|
      @sprites["button#{i}"] = IconSprite.new(88 + (64 * (i - 1)), 168, @viewport)
      @sprites["button#{i}"].setBitmap("Graphics/UI/Slot Machine/button")
      @sprites["button#{i}"].visible = false
    end
    (1..5).each do |i|
      y = [106, 74, 138, 42, 42][i - 1]
      @sprites["row#{i}"] = IconSprite.new(52, y, @viewport)
      @sprites["row#{i}"].setBitmap(sprintf("Graphics/UI/Slot Machine/line%1d%s",
                                            1 + (i / 2), (i >= 4) ? ((i == 4) ? "a" : "b") : ""))
      @sprites["row#{i}"].visible = false
    end
    @sprites["light1"] = IconSprite.new(0, 10, @viewport)
    @sprites["light1"].setBitmap("Graphics/UI/Slot Machine/lights")
    @sprites["light1"].visible = false
    @sprites["light2"] = IconSprite.new(512, 384, @viewport)
    @sprites["light2"].setBitmap("Graphics/UI/Slot Machine/lights")
    @sprites["light2"].mirror = true
    @sprites["light2"].visible = false
    @sprites["window1"] = IconSprite.new(0, 192, @viewport)
    @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/insert"))
    @sprites["window1"].src_rect.set(0, 0, Graphics.width, 96)
    @sprites["window2"] = IconSprite.new(0, 192, @viewport)
    @sprites["credit"] = SlotMachineScore.new(64, 16, $player.coins)
    @sprites["payout"] = SlotMachineScore.new(176, 16, 0)
    @wager = 0
    @green7_spins = 0
    update
    pbFadeInAndShow(@sprites)
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      update
      @sprites["window1"].bitmap&.clear
      @sprites["window2"].bitmap&.clear
      if @sprites["credit"].score == Settings::MAX_COINS
        pbMessage(_INTL("You've got {1} Coins.", Settings::MAX_COINS.to_s_formatted))
        break
      elsif $player.coins == 0
        pbMessage(_INTL("You've run out of Coins.\nGame over!"))
        break
      elsif @gameRunning   # Reels are spinning
        @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/stop"))
        timer_start = System.uptime
        loop do
          frame = ((System.uptime - timer_start) / 0.25).to_i
          @sprites["window1"].src_rect.set(Graphics.width * (frame % 4), 0, Graphics.width, 96)
          Graphics.update
          Input.update
          update
          if Input.trigger?(Input::USE)
            pbSEPlay("Slots stop")
            if @sprites["reel1"].spinning?
              @sprites["reel1"].stopSpinning(@replay)
              @sprites["button1"].visible = true
            elsif @sprites["reel2"].spinning?
              @sprites["reel2"].stopSpinning(@replay)
              @sprites["button2"].visible = true
            elsif @sprites["reel3"].spinning?
              @sprites["reel3"].stopSpinning(@replay)
              @sprites["button3"].visible = true
            end
          end
          if !@sprites["reel3"].spinning?
            @gameEnd = true
            @gameRunning = false
          end
          break if !@gameRunning
        end
      elsif @gameEnd   # Reels have been stopped
        reel1 = @sprites["reel1"].showing
        reel2 = @sprites["reel2"].showing
        reel3 = @sprites["reel3"].showing
        was_in_green7 = @green7_spins > 0
        green7_jackpot = false
        green7_bonus   = false
        if was_in_green7
          # Build active paylines (same wager rules as pbPayout)
          g7_combos = [[reel1[1], reel2[1], reel3[1]]]   # centre row always
          if @wager >= 2
            g7_combos << [reel1[0], reel2[0], reel3[0]]  # top row
            g7_combos << [reel1[2], reel2[2], reel3[2]]  # bottom row
          end
          if @wager >= 3
            g7_combos << [reel1[0], reel2[1], reel3[2]]  # diagonal TL→BR
            g7_combos << [reel1[2], reel2[1], reel3[0]]  # diagonal BL→TR
          end
          g7 = SlotMachineReel::GREEN_SEVEN
          best_count = g7_combos.map { |c| c.count { |ic| ic == g7 } }.max
          if best_count == 3
            green7_jackpot = true
            @green7_spins  = 0
          elsif best_count == 2
            @green7_spins += 1   # bonus: this spin is free
            green7_bonus   = true
          end
          @green7_spins -= 1 unless green7_jackpot
          @green7_spins  = [@green7_spins, 0].max
          (1..3).each { |r| @sprites["reel#{r}"].disable_green7 } if @green7_spins <= 0
        end
        if green7_jackpot
          pbGreenSevenJackpot
        else
          unless was_in_green7
            # Special event check: first 2 reels show red 7, third is something else
            active_combos = [[reel1[1], reel2[1], reel3[1]]]
            if @wager >= 2
              active_combos << [reel1[0], reel2[0], reel3[0]]
              active_combos << [reel1[2], reel2[2], reel3[2]]
            end
            if @wager >= 3
              active_combos << [reel1[0], reel2[1], reel3[2]]
              active_combos << [reel1[2], reel2[1], reel3[0]]
            end
            special_trigger = active_combos.any? { |c| c[0] == 5 && c[1] == 5 && c[2] != 5 && c[2] != 6 }
            if special_trigger && rand(2) == 0
              rand(2) == 0 ? pbSpecialEvent1 : pbSpecialEvent2
            end
          end
          pbPayout
          # Green 7 mode just activated by this spin's 777 result
          if @green7_spins > 0 && !was_in_green7
            (1..3).each { |r| @sprites["reel#{r}"].enable_green7 }
            pbMessage(_INTL("The reels shimmer green!\nYou have {1} Green 7 spins!", @green7_spins))
          elsif was_in_green7
            if green7_bonus && @green7_spins > 0
              pbMessage(_INTL("So close! +1 bonus spin! {1} spins left!", @green7_spins))
            elsif @green7_spins <= 0
              pbMessage(_INTL("The Green 7 bonus is over!"))
            end
          end
        end
        # Reset graphics
        @sprites["button1"].visible = false
        @sprites["button2"].visible = false
        @sprites["button3"].visible = false
        (1..5).each do |i|
          @sprites["row#{i}"].visible = false
        end
        @gameEnd = false
      else   # Awaiting coins for the next spin
        @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/insert"))
        timer_start = System.uptime
        loop do
          frame = ((System.uptime - timer_start) / 0.4).to_i
          @sprites["window1"].src_rect.set(Graphics.width * (frame % 2), 0, Graphics.width, 96)
          if @wager > 0
            @sprites["window2"].setBitmap(_INTL("Graphics/UI/Slot Machine/press"))
            @sprites["window2"].src_rect.set(Graphics.width * (frame % 2), 0, Graphics.width, 96)
          end
          Graphics.update
          Input.update
          update
          if Input.trigger?(Input::DOWN) && @wager < 3 && @sprites["credit"].score > 0
            pbSEPlay("Slots coin")
            @wager += 1
            @sprites["credit"].score -= 1
            if @wager >= 3
              @sprites["row5"].visible = true
              @sprites["row4"].visible = true
            elsif @wager >= 2
              @sprites["row3"].visible = true
              @sprites["row2"].visible = true
            elsif @wager >= 1
              @sprites["row1"].visible = true
            end
          elsif @wager >= 3 || (@wager > 0 && @sprites["credit"].score == 0) ||
                (Input.trigger?(Input::USE) && @wager > 0) || @replay
            if @replay
              @wager = 3
              (1..5).each { |i| @sprites["row#{i}"].visible = true }
            end
            @sprites["reel1"].startSpinning
            @sprites["reel2"].startSpinning
            @sprites["reel3"].startSpinning
            @gameRunning = true
          elsif Input.trigger?(Input::L) || Input.trigger?(Input::R)
            pbShowPayoutGuide
          elsif Input.trigger?(Input::BACK) && @wager == 0
            break
          end
          break if @gameRunning
        end
        break if !@gameRunning
      end
    end
    old_coins = $player.coins
    $player.coins = @sprites["credit"].score
    if $player.coins > old_coins
      $stats.coins_won += $player.coins - old_coins
    elsif $player.coins < old_coins
      $stats.coins_lost += old_coins - $player.coins
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class SlotMachine
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(difficulty)
    @scene.pbStartScene(difficulty)
    @scene.pbMain
    @scene.pbEndScene
  end
end

#===============================================================================
#
#===============================================================================
def pbSlotMachine(difficulty = 1)
  if !$bag.has?(:COINCASE)
    pbMessage(_INTL("It's a Slot Machine."))
  elsif $player.coins == 0
    pbMessage(_INTL("You don't have any Coins to play!"))
  elsif $player.coins == Settings::MAX_COINS
    pbMessage(_INTL("Your Coin Case is full!"))
  else
    pbFadeOutIn do
      scene = SlotMachineScene.new
      screen = SlotMachine.new(scene)
      screen.pbStartScreen(difficulty)
    end
  end
end
