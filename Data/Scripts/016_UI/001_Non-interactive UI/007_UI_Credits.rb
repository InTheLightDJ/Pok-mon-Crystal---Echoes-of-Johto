#==============================================================================
# * Scene_Credits
#------------------------------------------------------------------------------
# Scrolls the credits you make below. Original Author unknown.
#
## Edited by MiDas Mike so it doesn't play over the Title, but runs by calling
# the following:
#    $scene = Scene_Credits.new
#
## New Edit 3/6/2007 11:14 PM by AvatarMonkeyKirby.
# Ok, what I've done is changed the part of the script that was supposed to make
# the credits automatically end so that way they actually end! Yes, they will
# actually end when the credits are finished! So, that will make the people you
# should give credit to now is: Unknown, MiDas Mike, and AvatarMonkeyKirby.
#                                             -sincerly yours,
#                                               Your Beloved
# Oh yea, and I also added a line of code that fades out the BGM so it fades
# sooner and smoother.
#
## New Edit 24/1/2012 by Maruno.
# Added the ability to split a line into two halves with <s>, with each half
# aligned towards the centre. Please also credit me if used.
#
## New Edit 22/2/2012 by Maruno.
# Credits now scroll properly when played with a zoom factor of 0.5. Music can
# now be defined. Credits can't be skipped during their first play.
#
## New Edit 25/3/2020 by Maruno.
# Scroll speed is now independent of frame rate. Now supports non-integer values
# for SCROLL_SPEED.
#
## New Edit 21/8/2020 by Marin.
# Now automatically inserts the credits from the plugins that have been
# registered through the PluginManager module.
#==============================================================================
class Scene_Credits
  # Call this before $scene = Scene_Credits.new to warp the player after credits.
  #   Scene_Credits.schedule_transfer(96, 10, 21, 2)
  #   $scene = Scene_Credits.new
  @@post_transfer = nil
  def self.schedule_transfer(map_id, x, y, direction = 2)
    @@post_transfer = [map_id, x, y, direction]
  end

  # Backgrounds to show in credits. Found in Graphics/Titles/ folder
  BACKGROUNDS_LIST       = ["credits1", "credits2", "credits3", "credits4"]
  BGM_AI                 = "the kid i was"
  BGM_ADDED              = "Added song"
  SCROLL_SPEED           = 40   # Pixels per second

  def self.bgm
    Settings::USE_AI_MUSIC ? BGM_AI : BGM_ADDED
  end
  SECONDS_PER_PAGES      = 7

  def add_names_to_credits(credits, names, with_final_new_line = true)
    names_array = []
    if names.length >= 5
      i = 0
      loop do
        names_array.push(names[i] + "<s>" + (names[i + 1] || ""))
        i += 2
        break if i >= names.length
      end
    else
      names.each { |name| names_array.push(name) }
    end
    credits.push(names_array)
    credits.push("") if with_final_new_line
  end

  def get_text
    ret = Settings.game_credits || []
    # Add plugin credits
    if PluginManager.plugins.length > 0
      ret.push("")
      PluginManager.plugins.each do |plugin|
        pcred = PluginManager.credits(plugin)
        ret.push(_INTL("\"{1}\" v.{2} by:", plugin, PluginManager.version(plugin)))
        add_names_to_credits(ret, pcred)
      end
    end
    # Add GSC Kit credits
    ret.push(_INTL("\"Pokémon Essentials GBC Kit\"\nwas created by:"))
    add_names_to_credits(ret, [
      "Xaveriux"
    ])
    ret.push(_INTL("With contributions from:"))
    add_names_to_credits(ret, [
      "Caruban", "Taynathon", "Tomed01", "Boonzeet", "Vendily",
      "AwfullyWaffley", "TechSkylander1518", "James Davy"
    ])
    ret.push(_INTL("\"Pokémon Essentials GS\" base resources made by:"))
    add_names_to_credits(ret, [
      "COMBOY"
    ])
    # Add Essentials credits
    ret.push(_INTL("\"Pokémon Essentials\" was created by:"))
    add_names_to_credits(ret, [
      "Poccil (Peter O.)",
      "Maruno",
      _INTL("Inspired by work by Flameguru")
    ])
    ret.push(_INTL("With contributions from:"))
    add_names_to_credits(ret, [
      "AvatarMonkeyKirby", "Boushy", "Brother1440", "FL.", "Genzai Kawakami",
      "Golisopod User", "help-14", "IceGod64", "Jacob O. Wobbrock", "KitsuneKouta",
      "Lisa Anthony", "Luka S.J.", "Marin", "MiDas Mike", "Near Fantastica",
      "PinkMan", "Popper", "Rataime", "Savordez", "SoundSpawn",
      "the__end", "Venom12", "Wachunga"
    ])
    ret.push(_INTL("and everyone else who helped out"))
    ret.push("") # print next credit at different page
    ret.push(_INTL("\"mkxp-z\" by:"))
    add_names_to_credits(ret, [
      "Anon",
      _INTL("Based on \"mkxp\" by Ancurio et al.")
    ])
    ret.push(_INTL("\"RPG Maker XP\" by:"))
    add_names_to_credits(ret, ["Enterbrain"])
    ret.push(_INTL("Pokémon is owned by:"))
    add_names_to_credits(ret, [
      "The Pokémon Company",
      "Nintendo",
      _INTL("Affiliated with Game Freak")
    ])
    ret.push(_INTL("This is a non-profit fan-made game."),
             _INTL("No copyright infringements intended."),
             _INTL("Please support the official games!"))
    return ret
  end

  # Pass inline: true when calling from within a running Scene_Map event
  # (e.g. "saved = $scene; Scene_Credits.new.main(true); $scene = saved").
  # This freezes the screen first so Graphics.transition doesn't flash white,
  # resets the screen tone after credits, and skips the $scene assignment so
  # the calling scene can keep running.
  def main(inline = false)
    @quit = false
    #-------------------------------
    # Timer and Index setup
    #-------------------------------
    @timer_start = System.uptime   # Time when the credits started
    @bg_timer = System.uptime
    @page_timer = System.uptime
    @credit_index = 0
    @bg_index = 0
    @phase = 0
    @dir = Settings::GS_STYLE_CREDIT ? "GS" : "Crystal" # image directory location
    #-------------------------------
    # Credits text Setup
    #-------------------------------
    credit_lines = get_text
    #-------------------------------
    # Make background and text sprites
    #-------------------------------
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999
    @viewport = viewport
    text_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    text_viewport.z = 99999
    @background_sprite = AnimatedPlane.new(viewport)
    @background_sprite.setBitmap("Graphics/Titles/#{@dir}/" + BACKGROUNDS_LIST[0])
    createPokemonAnimation
    #-------------------------------
    # Generate text into an array of wall text
    #-------------------------------
    @credit_pages = []
    pages = []
    header = ""
    max_line = Settings::GS_STYLE_CREDIT ? 4 : 5
    credit_lines.each{|line|
      if (!line.is_a?(Array) && line == "" && pages.length > 0) # page break
        case pages.length
        when 1
          pages.unshift("")
          pages.unshift("") if max_line > 4
          pages.push("","")
        when 2
          pages.unshift("")
          pages.push("","")
        when 3
          pages.unshift("") if max_line > 4
          pages.push("")
        when 4
          pages.push("")
        end
        @credit_pages.push(pages)
        pages = []
      elsif !line.is_a?(Array) && line != ""
        header = line
        pages.push(line)
      elsif line.is_a?(Array) # names
        line.each_with_index{|name_list,i|
          pages.push(header) if i > 0 && pages.empty?
          pages.push(name_list)
          if pages.length >= max_line
            @credit_pages.push(pages)
            pages = []
          end
        }
        if pages.length < max_line && line.length > max_line-1 # names
          (max_line-pages.length).times do
            pages.push("")
          end
          @credit_pages.push(pages)
          pages = []
        end
      end
    }
    @credit_pages.push(pages) if pages.length > 0
    @credit_pages.push("Graphics/Titles/#{@dir}/creditEnd1","Graphics/Titles/#{@dir}/creditEnd2") if pages.length > 0 # Add last credit image
    @credit_bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(@credit_bitmap)
    @credit_bitmap.font.color = Settings::GS_STYLE_CREDIT ? Color.new(0, 0, 0) : Color.new(248, 248, 248)
    @credit_sprite = Sprite.new(text_viewport)
    @credit_sprite.z      = 9998
    drawCreditList
    @total_time = SECONDS_PER_PAGES * @credit_pages.length # Total time for credit scene
    @seconds_per_bg = (@total_time/BACKGROUNDS_LIST.length).floor # Total time per background
    #-------------------------------
    # Setup
    #-------------------------------
    # Stops all audio but background music
    previousBGM = $game_system.getPlayingBGM
    pbMEStop
    pbBGSStop
    pbSEStop
    pbBGMFade(2.0)
    pbBGMPlay(Scene_Credits.bgm)
    # When called inline from an event, the screen isn't frozen yet.
    # Freezing here prevents Graphics.transition from flashing white.
    Graphics.freeze if inline
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if @quit
    end
    $game_temp.background_bitmap = Graphics.snap_to_bitmap
    pbBGMFade(2.0)
    Graphics.freeze
    viewport.color = Color.black   # Ensure screen is black
    text_viewport.color = Color.black   # Ensure screen is black
    Graphics.transition(8, "fadetoblack")
    $game_temp.background_bitmap.dispose
    @background_sprite.dispose
    disposePokemonAnimation
    @credit_bitmap&.dispose
    @credit_sprite&.dispose
    viewport.dispose
    text_viewport.dispose
    $PokemonGlobal.creditsPlayed = true
    pbBGMPlay(previousBGM)
    # Reset any screen tone leftover from the Hall of Fame event.
    $game_screen.start_tone_change(Tone.new(0, 0, 0, 0), 0) if $game_screen
    # Apply a scheduled post-credits map transfer if one was set before calling credits.
    if @@post_transfer
      mid, x, y, dir = @@post_transfer
      @@post_transfer = nil
      $game_temp.player_new_map_id    = mid
      $game_temp.player_new_x         = x
      $game_temp.player_new_y         = y
      $game_temp.player_new_direction = dir
      $game_temp.player_transferring  = true
      # The Hall of Fame autorun event was mid-execution when credits started.
      # Its interpreter is still "running", which blocks player movement in the
      # new scene. Clear it so the player can move normally after arriving home.
      $game_player.straighten rescue nil
      $game_player.instance_variable_set(:@move_route_forcing, false) rescue nil
      $game_system.map_interpreter.setup([], 0) rescue nil
    end
    $scene = ($game_map) ? Scene_Map.new : nil
  end

  # Check if the credits should be cancelled
  def cancel?
    @quit = true if Input.trigger?(Input::USE) && $PokemonGlobal.creditsPlayed
    return @quit
  end

  # Checks if credits bitmap has reached its ending point
  def last?
    @quit = true if System.uptime - @timer_start >= @total_time
    return @quit
  end

  def update
    # Update pokemon animation
    @animatedPokemon.each { |anim| anim.update } if @animatedPokemon
    # Update background
    if System.uptime - @bg_timer > 0.1
      @background_sprite.ox -= 3
      @background_sprite.update
      @bg_timer = System.uptime
    end
    return if cancel?
    return if last?
    if @phase == 0 # Game Titles
      if System.uptime - @timer_start >= SECONDS_PER_PAGES # First page for Game Titles
        @animatedPokemon.each{|s| s.visible = true }
        @phase += 1
      end
    end
    # Credit Text update
    if System.uptime - @page_timer >= SECONDS_PER_PAGES
      @credit_index += 1
      if (System.uptime - @timer_start) >= (@seconds_per_bg * (@bg_index+1)) && @bg_index < BACKGROUNDS_LIST.length - 1 # update bg
        @bg_index += 1
        @background_sprite.setBitmap("Graphics/Titles/#{@dir}/" + BACKGROUNDS_LIST[@bg_index])
        createPokemonAnimation
      end
      drawCreditList
      @page_timer = System.uptime
    end
  end

  def createPokemonAnimation
    disposePokemonAnimation
    #-------------------------------
    # Make Animated Pokémon
    #-------------------------------
    @animatedPokemon = []
    frameskip = Settings::GS_STYLE_CREDIT ? 4 : 2
    size = Settings::GS_STYLE_CREDIT ? 10 : 5
    size.times do |i|
      @animatedPokemon[i] = AnimatedSprite.create("Graphics/Titles/#{@dir}/"+ BACKGROUNDS_LIST[@bg_index] + "_pkmn",4,frameskip)
      @animatedPokemon[i].viewport = @viewport
      @animatedPokemon[i].x = 64*(i%5)
      @animatedPokemon[i].y = (i>=5) ? Graphics.height - 64 : 0
      @animatedPokemon[i].visible = (@phase > 0)
      @animatedPokemon[i].play
    end
  end

  def disposePokemonAnimation
    @animatedPokemon.each { |anim| anim.dispose } if @animatedPokemon
  end

  def drawCreditList(index = -1)
    @credit_bitmap.clear
    index = @credit_index if index < 0
    if !@credit_pages[index].is_a?(Array) && @credit_pages[index].start_with?("Graphics/Titles/")
      pbDrawImagePositions(@credit_bitmap, [[@credit_pages[index], 0, 0]])
    else
      @credit_pages[index].each_with_index {|line,j|
        line += " " if line.end_with?("<s>")
        line = line.split("<s>")
        xpos = 0
        align = 1   # Centre align
        linewidth = Graphics.width
        line.length.times do |k|
          text = line[k].strip
          if line.length > 1
            xpos = (k == 0) ? 0 : 20 + (Graphics.width / 2)
            align = (k == 0) ? 2 : 0   # Right align : left align
            linewidth = (Graphics.width / 2) - 20
          end
          @credit_bitmap.draw_text(xpos, (j * 32) + 96, linewidth, 32, text, align)
        end
      }
      @credit_sprite.bitmap = @credit_bitmap
    end
  end
end
