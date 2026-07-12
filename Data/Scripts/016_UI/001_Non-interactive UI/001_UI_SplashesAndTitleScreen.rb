# Walk-in-place character sprite for the title screen
class TitleWalker < Sprite
  # filename: name under Graphics/Characters (no extension)
  # x,y: screen position; dir_row 0..3 (0=down,1=left,2=right,3=up)
  # anim_speed: lower = faster; 8 is a comfy default
  def initialize(viewport, filename, x, y, dir_row = 2, anim_speed = 8, z = 200)
    super(viewport)
    @bmp = Bitmap.new("Graphics/Characters/#{filename}")
    self.bitmap = @bmp
    @cols = (@bmp.width % 4 == 0) ? 4 : 3   # handle 3- or 4-frame charsets
    @rows = 4
    @cw   = @bmp.width / @cols
    @ch   = @bmp.height / @rows
    @row  = [[dir_row, 0].max, @rows - 1].min
    @pattern    = 0
    @tick       = 0
    @anim_speed = anim_speed

    self.ox = @cw / 2
    self.oy = @ch
    self.x  = x
    self.y  = y
    self.z  = z
    refresh
  end

  def refresh
    self.src_rect.set(@cw * @pattern, @ch * @row, @cw, @ch)
  end

  def update
    super
    @tick += 1
    if @tick >= @anim_speed
      @tick = 0
      @pattern = (@pattern + 1) % @cols
      refresh
    end
  end

  def dispose
    self.bitmap&.dispose
    super
  end
end


#===============================================================================
#
#===============================================================================
class IntroEventScene < EventScene
  # Splash screen images that appear for a few seconds and then disappear.
  SPLASH_IMAGES         = ["splash1", "splash2"]
  # The main title screen background image.
  TITLE_BG_IMAGE        = "title"
  TITLE_START_IMAGE     = "start"
  TITLE_START_IMAGE_X   = -10
  TITLE_START_IMAGE_Y   = 250
  SECONDS_PER_SPLASH    = 2
  TICKS_PER_ENTER_FLASH = 40   # 20 ticks per second
  FADE_TICKS            = 8    # 20 ticks per second

  #TITLE_CHAR_1  = "girl_run"      # Graphics/Characters/TitleHero.png
  #TITLE_CHAR_2  = "Followers/PIKACHU"  # Graphics/Characters/TitleFollower.png
  TITLE_CHAR_X  = 180
  TITLE_CHAR_Y  = 250
  TITLE_FOLLOWER_X_OFFSET = -40    # 20 px behind to the left
  TITLE_ANIM_SPEED = 8             # lower = faster leg cycle
  # --- Randomization setup ---
  HERO_CHOICES        = %w[boy_run girl_run]
  FOLLOWER_SUBDIR     = "Followers"
  FOLLOWER_DIR_FULL   = "Graphics/Characters/#{FOLLOWER_SUBDIR}"   # => Graphics/Characters/Followers
  FOLLOWER_FALLBACK   = "#{FOLLOWER_SUBDIR}/PIKACHU"               # used if folder has no PNGs

  def initialize(viewport = nil)
    super(viewport)
    @pic = addImage(0, 0, "")
    @pic.setOpacity(0, 0)        # set opacity to 0 after waiting 0 frames
    @pic2 = addImage(0, 0, "")   # flashing "Press Enter" picture
    @pic2.setOpacity(0, 0)       # set opacity to 0 after waiting 0 frames
    @index = 0
    if SPLASH_IMAGES.empty?
      open_title_screen(self, nil)
    else
      open_splash(self, nil)
    end
  end

  def pick_random_follower
    files = Dir.glob("#{FOLLOWER_DIR_FULL}/*.{png,PNG}").select { |f| File.file?(f) }
    return FOLLOWER_FALLBACK if files.empty?
    rel = files.sample
    # turn "Graphics/Characters/Followers/EEVEE.png" into "Followers/EEVEE"
    rel.sub(%r{\AGraphics/Characters/}, "").sub(/\.(png)\z/i, "")
  end

  def open_splash(_scene, *args)
    #pbBGMPlay("Legends Of Johto Intro")
    onCTrigger.clear
    @pic.name = "Graphics/Titles/" + SPLASH_IMAGES[@index]
    # fade to opacity 255 in FADE_TICKS ticks after waiting 0 frames
    @pic.moveOpacity(0, FADE_TICKS, 255)
    pictureWait
    @timer = System.uptime                  # reset the timer
    onUpdate.set(method(:splash_update))    # called every frame
    onCTrigger.set(method(:close_splash))   # called when C key is pressed
  end

  # Smoothly run the title walkers to the right, then return.
# dx: total pixels to move; frames: how many frames to take.
def walkers_run_off(dx = 200, frames = 40)
  return if (!@walker1 && !@walker2)
  # Stop the "Press Enter" blink while we animate
  @pic2.clearProcesses
  @pic2.setVisible(0, false)

  w1 = @walker1
  w2 = @walker2
  x1f = w1 ? w1.x.to_f : 0.0
  x2f = w2 ? w2.x.to_f : 0.0
  step = dx.to_f / frames

  frames.times do
    if w1
      x1f += step
      w1.x = x1f.round
      w1.update
    end
    if w2
      x2f += step
      w2.x = x2f.round
      w2.update
    end
    Graphics.update
    Input.update
  end
end

  def close_splash(scene, args)
    onUpdate.clear
    onCTrigger.clear
    @pic.moveOpacity(0, FADE_TICKS, 0)
    pictureWait
    @index += 1   # Move to the next picture
    if @index >= SPLASH_IMAGES.length
      open_title_screen(scene, args)
    else
      open_splash(scene, args)
    end
  end

  def splash_update(scene, args)
    close_splash(scene, args) if System.uptime - @timer >= SECONDS_PER_SPLASH
  end

  def open_title_screen(_scene, *args)
    onUpdate.clear
    onCTrigger.clear
    @pic.name = "Graphics/Titles/" + TITLE_BG_IMAGE
    @pic.moveOpacity(0, FADE_TICKS, 255)
    @pic2.name = "Graphics/Titles/" + TITLE_START_IMAGE
    @pic2.setXY(0, TITLE_START_IMAGE_X, TITLE_START_IMAGE_Y)
    @pic2.setVisible(0, true)
    @pic2.moveOpacity(0, FADE_TICKS, 255)

    # Create walking sprites (facing right = row 2)
 # Pick sprites each time the title opens
hero_name     = HERO_CHOICES.sample                     # "boy_run" or "girl_run"
follower_name = pick_random_follower                    # e.g. "Followers/EEVEE"

@walker1&.dispose
@walker2&.dispose
@walker1 = TitleWalker.new(@viewport, hero_name,     TITLE_CHAR_X, TITLE_CHAR_Y, 2, TITLE_ANIM_SPEED)
@walker2 = TitleWalker.new(@viewport, follower_name, TITLE_CHAR_X + TITLE_FOLLOWER_X_OFFSET, TITLE_CHAR_Y, 2, TITLE_ANIM_SPEED)

    pictureWait
    #pbBGMPlay($data_system.title_bgm)
    pbBGMPlay(Settings::USE_AI_MUSIC ? "Legends Of Johto Intro" : "Added song")
    onUpdate.set(method(:title_screen_update))    # called every frame
    onCTrigger.set(method(:close_title_screen))   # called when C key is pressed
  end

  def fade_out_title_screen(scene)
    onUpdate.clear
    onCTrigger.clear
    # Play random cry
    species_keys = GameData::Species.keys
    species_data = GameData::Species.get(species_keys.sample)
    Pokemon.play_cry(species_data.species, species_data.form)
    walkers_run_off(200, 40)      # run +200px in ~1s
    @pic.moveXY(0, 20, 0, 0)   # Adds 20 ticks (1 second) pause
    pictureWait
    # Fade out
    @pic.moveOpacity(0, FADE_TICKS, 0)
    @pic2.clearProcesses
    @pic2.moveOpacity(0, FADE_TICKS, 0)
    pbBGMStop(1.0)

    @walker1&.dispose
    @walker2&.dispose

    pictureWait
    scene.dispose   # Close the scene
  end

  def close_title_screen(scene, *args)
  #  walkers_run_off(200, 40)      # run +200px in ~1s
    fade_out_title_screen(scene)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def close_title_screen_delete(scene, *args)
   # walkers_run_off(200, 40)      # run +200px in ~1s
    fade_out_title_screen(scene)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartDeleteScreen
  end

  def title_screen_update(scene, args)
    @walker1&.update
    @walker2&.update
    # Flashing of "Press Enter" picture
    if !@pic2.running?
      @pic2.moveOpacity(TICKS_PER_ENTER_FLASH * 2 / 10, TICKS_PER_ENTER_FLASH * 4 / 10, 0)
      @pic2.moveOpacity(TICKS_PER_ENTER_FLASH * 6 / 10, TICKS_PER_ENTER_FLASH * 4 / 10, 255)
    end
    if Input.press?(Input::DOWN) &&
       Input.press?(Input::BACK) &&
       Input.press?(Input::CTRL)
      close_title_screen_delete(scene, args)
    end
  end
end

#===============================================================================
#
#===============================================================================
class Scene_Intro
  def main
    Graphics.transition(0)
    @eventscene = IntroEventScene.new
    @eventscene.main
    Graphics.freeze
  end
end
