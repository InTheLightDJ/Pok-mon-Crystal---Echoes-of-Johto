#===============================================================================
#
#===============================================================================
module Graphics
  @@transition = nil
  STOP_WHILE_TRANSITION = true

  unless defined?(transition_KGC_SpecialTransition)
    class << Graphics
      alias transition_KGC_SpecialTransition transition
    end

    class << Graphics
      alias update_KGC_SpecialTransition update
    end
  end

  # duration is in 1/20ths of a second
  def self.transition(duration = 8, filename = "", vague = 20)
    duration = duration.floor
    if judge_special_transition(duration, filename)
      duration = 0
      filename = ""
    end
    duration *= Graphics.frame_rate / 20   # For default fade-in animation, must be in frames
    begin
      transition_KGC_SpecialTransition(duration, filename, vague)
    rescue Exception
      transition_KGC_SpecialTransition(duration, "", vague) if filename != ""
    end
    if STOP_WHILE_TRANSITION && !@_interrupt_transition
      while @@transition && !@@transition.disposed?
        update
      end
    end
  end

  def self.update
    update_KGC_SpecialTransition
    @@transition.update if @@transition && !@@transition.disposed?
    @@transition = nil if @@transition&.disposed?
  end

  def self.judge_special_transition(duration, filename)
    return false if @_interrupt_transition
    ret = true
    if @@transition && !@@transition.disposed?
      @@transition.dispose
      @@transition = nil
    end
    duration /= 20.0   # Turn into seconds
    dc = File.basename(filename).downcase
    case dc
    # Other coded transitions
    when "breakingglass"    then @@transition = Transitions::BreakingGlass.new(duration)
    when "rotatingpieces"   then @@transition = Transitions::ShrinkingPieces.new(duration, true)
    when "shrinkingpieces"  then @@transition = Transitions::ShrinkingPieces.new(duration, false)
    when "splash"           then @@transition = Transitions::SplashTransition.new(duration, 9.6)
    when "random_stripe_v"  then @@transition = Transitions::RandomStripeTransition.new(duration, 0)
    when "random_stripe_h"  then @@transition = Transitions::RandomStripeTransition.new(duration, 1)
    when "zoomin"           then @@transition = Transitions::ZoomInTransition.new(duration)
    when "scrolldown"       then @@transition = Transitions::ScrollScreen.new(duration, 2)
    when "scrollleft"       then @@transition = Transitions::ScrollScreen.new(duration, 4)
    when "scrollright"      then @@transition = Transitions::ScrollScreen.new(duration, 6)
    when "scrollup"         then @@transition = Transitions::ScrollScreen.new(duration, 8)
    when "scrolldownleft"   then @@transition = Transitions::ScrollScreen.new(duration, 1)
    when "scrolldownright"  then @@transition = Transitions::ScrollScreen.new(duration, 3)
    when "scrollupleft"     then @@transition = Transitions::ScrollScreen.new(duration, 7)
    when "scrollupright"    then @@transition = Transitions::ScrollScreen.new(duration, 9)
    when "mosaic"           then @@transition = Transitions::MosaicTransition.new(duration)
    # GSC transitions
    when "circle"           then @@transition = Transitions::Circle.new(duration)
    when "fading"           then @@transition = Transitions::Fading.new(duration)
    when "boxout"           then @@transition = Transitions::BoxOut.new(duration)
    when "distortion"       then @@transition = Transitions::Distortion.new(duration)
    # Graphic transitions
    when "fadetoblack"      then @@transition = Transitions::FadeToBlack.new(duration)
    when "fadefromblack"    then @@transition = Transitions::FadeFromBlack.new(duration)
    else                         ret = false
    end
    Graphics.frame_reset if ret
    return ret
  end
end

#===============================================================================
# Screen transition animation classes.
#===============================================================================
module Transitions
  #=============================================================================
  # A base class that all other screen transition animations inherit from.
  #=============================================================================
  class Transition_Base
    DURATION = nil

    def initialize(duration, *args)
      @disposed = false
      if duration <= 0
        @disposed = true
        return
      end
      @duration = self.class::DURATION || duration
      @parameters = args
      @timer_start = System.uptime
      @overworld_bitmap = $game_temp.background_bitmap
      initialize_bitmaps
      return if disposed?
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = []
      @overworld_sprite = new_sprite(0, 0, @overworld_bitmap)
      @overworld_sprite.z = -1
      initialize_sprites
      @timings = []
      set_up_timings
    end

    def new_sprite(x, y, bitmap, ox = 0, oy = 0)
      s = Sprite.new(@viewport)
      s.x = x
      s.y = y
      s.ox = ox
      s.oy = oy
      s.bitmap = bitmap
      return s
    end

    def timer
      return System.uptime - @timer_start
    end

    def dispose
      return if disposed?
      dispose_all
      @sprites.each { |s| s&.dispose }
      @sprites.clear
      @overworld_sprite.dispose
      @overworld_bitmap&.dispose
      @viewport&.dispose
      @disposed = true
    end

    def disposed?; return @disposed; end

    def update
      return if disposed?
      if timer >= @duration
        dispose
        return
      end
      update_anim
    end

    def initialize_bitmaps; end
    def initialize_sprites; end
    def set_up_timings;     end
    def dispose_all;        end
    def update_anim;        end
  end

  #=============================================================================
  #
  #=============================================================================
  class BreakingGlass < Transition_Base
    NUM_SPRITES_X = 8
    NUM_SPRITES_Y = 6

    def initialize_sprites
      @overworld_sprite.visible = false
      # Overworld sprites
      sprite_width = @overworld_bitmap.width / NUM_SPRITES_X
      sprite_height = @overworld_bitmap.height / NUM_SPRITES_Y
      NUM_SPRITES_Y.times do |j|
        NUM_SPRITES_X.times do |i|
          idx_sprite = (j * NUM_SPRITES_X) + i
          @sprites[idx_sprite] = new_sprite(i * sprite_width, j * sprite_height, @overworld_bitmap)
          @sprites[idx_sprite].src_rect.set(i * sprite_width, j * sprite_height, sprite_width, sprite_height)
        end
      end
    end

    def set_up_timings
      @start_y = []
      NUM_SPRITES_Y.times do |j|
        NUM_SPRITES_X.times do |i|
          idx_sprite = (j * NUM_SPRITES_X) + i
          @start_y[idx_sprite] = @sprites[idx_sprite].y
          @timings[idx_sprite] = 0.5 + rand
        end
      end
    end

    def update_anim
      proportion = timer / @duration
      @sprites.each_with_index do |sprite, i|
        sprite.y = @start_y[i] + (Graphics.height * @timings[i] * proportion * proportion)
        sprite.opacity = 255 * (1 - proportion)
      end
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class ShrinkingPieces < Transition_Base
    NUM_SPRITES_X = 8
    NUM_SPRITES_Y = 6

    def initialize_sprites
      @overworld_sprite.visible = false
      # Overworld sprites
      sprite_width = @overworld_bitmap.width / NUM_SPRITES_X
      sprite_height = @overworld_bitmap.height / NUM_SPRITES_Y
      NUM_SPRITES_Y.times do |j|
        NUM_SPRITES_X.times do |i|
          idx_sprite = (j * NUM_SPRITES_X) + i
          @sprites[idx_sprite] = new_sprite((i + 0.5) * sprite_width, (j + 0.5) * sprite_height,
                                            @overworld_bitmap, sprite_width / 2, sprite_height / 2)
          @sprites[idx_sprite].src_rect.set(i * sprite_width, j * sprite_height, sprite_width, sprite_height)
        end
      end
    end

    def update_anim
      proportion = timer / @duration
      @sprites.each_with_index do |sprite, i|
        sprite.zoom_x = (1 - proportion).to_f
        sprite.zoom_y = sprite.zoom_x
        if @parameters[0]   # Rotation
          direction = (1 - (2 * (((i / NUM_SPRITES_X) + (i % NUM_SPRITES_X)) % 2)))
          sprite.angle = direction * 360 * 2 * proportion
        end
      end
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class SplashTransition < Transition_Base
    NUM_SPRITES_X = 16
    NUM_SPRITES_Y = 12
    SPEED         = 40

    def initialize_sprites
      @overworld_sprite.visible = false
      # Black background
      @black_sprite = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @black_sprite.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.black)
      # Overworld sprites
      sprite_width = @overworld_bitmap.width / NUM_SPRITES_X
      sprite_height = @overworld_bitmap.height / NUM_SPRITES_Y
      NUM_SPRITES_Y.times do |j|
        NUM_SPRITES_X.times do |i|
          idx_sprite = (j * NUM_SPRITES_X) + i
          @sprites[idx_sprite] = new_sprite((i + 0.5) * sprite_width, (j + 0.5) * sprite_height,
                                            @overworld_bitmap, sprite_width / 2, sprite_height / 2)
          @sprites[idx_sprite].src_rect.set(i * sprite_width, j * sprite_height, sprite_width, sprite_height)
        end
      end
    end

    def set_up_timings
      @start_positions = []
      @move_vectors = []
      vague = (@parameters[0] || 9.6) * SPEED
      NUM_SPRITES_Y.times do |j|
        NUM_SPRITES_X.times do |i|
          idx_sprite = (j * NUM_SPRITES_X) + i
          spr = @sprites[idx_sprite]
          @start_positions[idx_sprite] = [spr.x, spr.y]
          dx = spr.x - (Graphics.width / 2)
          dy = spr.y - (Graphics.height / 2)
          move_x = move_y = 0
          if dx == 0 && dy == 0
            move_x = (dx == 0) ? rand_sign * vague : dx * SPEED * 1.5
            move_y = (dy == 0) ? rand_sign * vague : dy * SPEED * 1.5
          else
            radius = Math.sqrt((dx**2) + (dy**2))
            move_x = dx * vague / radius
            move_y = dy * vague / radius
          end
          move_x += (rand - 0.5) * vague
          move_y += (rand - 0.5) * vague
          @move_vectors[idx_sprite] = [move_x, move_y]
        end
      end
    end

    def update_anim
      proportion = timer / @duration
      @sprites.each_with_index do |sprite, i|
        sprite.x = @start_positions[i][0] + (@move_vectors[i][0] * proportion)
        sprite.y = @start_positions[i][1] + (@move_vectors[i][1] * proportion)
        sprite.opacity = 384 * (1 - proportion)
      end
    end

    #---------------------------------------------------------------------------

    private

    def rand_sign
      return (rand(2) == 0) ? 1 : -1
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class RandomStripeTransition < Transition_Base
    STRIPE_WIDTH = 2

    def initialize_sprites
      @overworld_sprite.visible = false
      # Overworld sprites
      if @parameters[0] == 0   # Vertical stripes
        sprite_width = STRIPE_WIDTH
        sprite_height = @overworld_bitmap.height
        num_stripes_x = @overworld_bitmap.width / STRIPE_WIDTH
        num_stripes_y = 1
      else   # Horizontal stripes
        sprite_width = @overworld_bitmap.width
        sprite_height = STRIPE_WIDTH
        num_stripes_x = 1
        num_stripes_y = @overworld_bitmap.height / STRIPE_WIDTH
      end
      num_stripes_y.times do |j|
        num_stripes_x.times do |i|
          idx_sprite = (j * num_stripes_x) + i
          @sprites[idx_sprite] = new_sprite(i * sprite_width, j * sprite_height, @overworld_bitmap)
          @sprites[idx_sprite].src_rect.set(i * sprite_width, j * sprite_height, sprite_width, sprite_height)
        end
      end
    end

    def set_up_timings
      @sprites.length.times do |i|
        @timings[i] = @duration * i / @sprites.length
      end
      @timings.shuffle!
    end

    def update_anim
      @sprites.each_with_index do |sprite, i|
        next if @timings[i] < 0 || timer < @timings[i]
        sprite.visible = false
        @timings[i] = -1
      end
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class ZoomInTransition < Transition_Base
    def initialize_sprites
      @overworld_sprite.x = Graphics.width / 2
      @overworld_sprite.y = Graphics.height / 2
      @overworld_sprite.ox = @overworld_bitmap.width / 2
      @overworld_sprite.oy = @overworld_bitmap.height / 2
    end

    def update_anim
      proportion = timer / @duration
      @overworld_sprite.zoom_x = 1 + (7 * proportion)
      @overworld_sprite.zoom_y = @overworld_sprite.zoom_x
      @overworld_sprite.opacity = 255 * (1 - proportion)
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class ScrollScreen < Transition_Base
    def update_anim
      proportion = timer / @duration
      if (@parameters[0] % 3) != 2
        @overworld_sprite.x = [1, -1, 0][@parameters[0] % 3] * Graphics.width * proportion
      end
      if ((@parameters[0] - 1) / 3) != 1
        @overworld_sprite.y = [1, 0, -1][(@parameters[0] - 1) / 3] * Graphics.height * proportion
      end
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class MosaicTransition < Transition_Base
    MAX_PIXELLATION_FACTOR = 16

    def initialize_bitmaps
      @buffer_original = @overworld_bitmap.clone   # Copy of original, never changes
      @buffer_temp = @overworld_bitmap.clone       # "Clipboard" holding shrunken overworld
    end

    def set_up_timings
      @start_black_fade = @duration * 0.8
    end

    def dispose_all
      @buffer_original&.dispose
      @buffer_temp&.dispose
    end

    def update_anim
      proportion = timer / @duration
      inv_proportion = 1 / (1 + (proportion * (MAX_PIXELLATION_FACTOR - 1)))
      new_size_rect = Rect.new(0, 0, @overworld_bitmap.width * inv_proportion,
                               @overworld_bitmap.height * inv_proportion)
      # Take all of buffer_original, shrink it and put it into buffer_temp
      @buffer_temp.stretch_blt(new_size_rect,
                               @buffer_original, Rect.new(0, 0, @overworld_bitmap.width, @overworld_bitmap.height))
      # Take shrunken area from buffer_temp and stretch it into buffer
      @overworld_bitmap.stretch_blt(Rect.new(0, 0, @overworld_bitmap.width, @overworld_bitmap.height),
                                    @buffer_temp, new_size_rect)
      if timer >= @start_black_fade
        @overworld_sprite.opacity = 255 * (1 - ((timer - @start_black_fade) / (@duration - @start_black_fade)))
      end
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class FadeToBlack < Transition_Base
    def update_anim
      @overworld_sprite.opacity = 255 * (1 - (timer / @duration))
    end
  end

  #=============================================================================
  #
  #=============================================================================
  class FadeFromBlack < Transition_Base
    def update_anim
      @overworld_sprite.opacity = 255 * timer / @duration
    end
  end

  #=============================================================================
  # GSC Wild battle - Circle
  #=============================================================================
  class Circle < Transition_Base
    def initialize_bitmaps
      @bitmap = RPG::Cache.transition("encounterWild")
      dispose if !@bitmap
    end

    def initialize_sprites
      width  = @bitmap.width
      height = @bitmap.height
      cx = width / Graphics.width     # 28
      cy = height / Graphics.height   # 01
      @numtiles = cx * cy
      # Transition
      @sprites[0] = new_sprite(0, 0, @bitmap)
      @sprites[0].src_rect.set(0, 0, Graphics.width, Graphics.height)
      @sprites[0].visible = false
    end

    def dispose_all
      # Dispose bitmaps
      @bitmap&.dispose
    end

    def update_anim
      xpos = (timer * @numtiles / @duration).floor
      @sprites[0].visible = true
      @sprites[0].src_rect.set(xpos*Graphics.width, 0, Graphics.width, Graphics.height)
    end
  end

  #=============================================================================
  # GSC Wild battle - Fading
  #=============================================================================
  class Fading < Transition_Base
    def initialize_bitmaps
      @bitmap = RPG::Cache.transition("black_square")
      dispose if !@bitmap
    end

    def initialize_sprites
      width  = @bitmap.width
      height = @bitmap.height
      cx = Graphics.width / width     # 28
      cy = Graphics.height / height   # 18
      numtiles = cx * cy
      # Transition
      @black_tiles = []
      numtiles.times do |i|
        @sprites[i] = new_sprite((i%cx)*width, (i/cx).floor*height, @bitmap)
        @sprites[i].visible = false
        @black_tiles.push(i)
      end
    end

    def dispose_all
      # Dispose bitmaps
      @bitmap&.dispose
    end

    def set_up_timings
      @sprites.length.times do |i|
        @timings[i] = @duration * i / @sprites.length
      end
      @timings.shuffle!
    end

    def update_anim
      @sprites.each_with_index do |sprite, i|
        next if @timings[i] < 0 || timer < @timings[i]
        sprite.visible = true
        @timings[i] = -1
      end
    end
  end

  #=============================================================================
  # GSC Wild battle - Box Out
  #=============================================================================
  class BoxOut < Transition_Base
    def initialize_bitmaps
      @bitmap = RPG::Cache.transition("black_square")
      dispose if !@bitmap
    end

    def initialize_sprites
      width  = @bitmap.width
      height = @bitmap.height
      @max_zoom = 20
      # Transition
      @sprites[0] = new_sprite(0, 0, @bitmap)
      @sprites[0].x = Graphics.width/2
      @sprites[0].y = Graphics.height/2
      @sprites[0].ox = width/2
      @sprites[0].oy = height/2
      @sprites[0].visible = false
    end

    def dispose_all
      # Dispose bitmaps
      @bitmap&.dispose
    end

    def update_anim
      zoom = (timer * @max_zoom / (@duration * 2)).floor * 2 # there are 2 to make the zoom animation stiff
      @sprites[0].visible = true
      @sprites[0].zoom_x = zoom
      @sprites[0].zoom_y = zoom
    end
  end

  #=============================================================================
  # GSC Wild battle - Distortion
  #=============================================================================
  class Distortion < Transition_Base
    STRIPE_WIDTH = 2

    def initialize_bitmaps
      @bitmap = RPG::Cache.transition("black_square")
      dispose if !@bitmap
    end

    def initialize_sprites
      @overworld_sprite.visible = false
      # Overworld sprites
      sprite_width = @overworld_bitmap.width
      sprite_height = STRIPE_WIDTH
      num_stripes = @overworld_bitmap.height / STRIPE_WIDTH
      @max_x = 216
      @sprites[0] = new_sprite(0, 0, @bitmap)
      @sprites[0].zoom_x = 20
      @sprites[0].zoom_y = 20
      num_stripes.times do |i|
        @sprites[i+1] = new_sprite(0, i * STRIPE_WIDTH, @overworld_bitmap)
        @sprites[i+1].src_rect.set(0, i * STRIPE_WIDTH, sprite_width, sprite_height)
      end
    end

    def dispose_all
      # Dispose bitmaps
      @bitmap&.dispose
    end

    def update_anim
      @sprites.each_with_index do |sprite, i|
        # 42 pixel curve
        real_idx = i-1
        curve_id = real_idx % 21
        # curve magic number
                     # 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21
        curve_value = [1,1,2,2,4,6,7,8,9,9,10,10,10,9,9,8, 7, 6, 4, 2, 2, 1][curve_id]
        xpos = (timer * 20 * curve_value / @duration).floor
        curve_set = real_idx / 42
        dir = curve_set.odd? ? -1 : 1
        sprite.x = dir * xpos
      end
    end
  end
end