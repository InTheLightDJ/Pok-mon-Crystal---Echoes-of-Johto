#===============================================================================
# * Hall of Fame - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It makes a recordable Hall of Fame
# like the Gen 3 games.
#
#===============================================================================
#
# To this scripts works, put it above main, put a 512x384 picture in
# hallfamebars and a 8x24 background picture in hallfamebg. To call this script,
# use 'pbHallOfFameEntry'. After you recorder the first entry, you can access
# the hall teams using a PC. You can also check the player Hall of Fame last
# number using '$PokemonGlobal.hallOfFameLastNumber'.
#
#===============================================================================
class HallOfFame_Scene
  # When true, all pokémon will be in one line.
  # When false, all pokémon will be in two lines.
  SINGLE_ROW_OF_POKEMON = true
  # Make the pokémon movement ON in hall entry.
  ANIMATION = true
  # Time in seconds for a Pokémon to slide to its position from off-screen.
  APPEAR_SPEED = 0.4
  # Entry wait time (in seconds) between showing each Pokémon (and trainer).
  ENTRY_WAIT_TIME = 3.0
  # Wait time (in seconds) when showing "Welcome to the Hall of Fame!".
  WELCOME_WAIT_TIME = 4.0
  # Maximum number limit of simultaneous hall entries saved.
  # 0 = Doesn't save any hall. -1 = no limit
  # Prefer to use larger numbers (like 500 and 1000) than don't put a limit.
  # If a player exceed this limit, the first one will be removed.
  HALL_ENTRIES_LIMIT = 50
  # The entry music name. Put "" to doesn't play anything.
  HALL_OF_FAME_BGM = "Hall of Fame"
  # Allow eggs to be show and saved in hall.
  ALLOW_EGGS = true
  # Remove the hallbars when the trainer sprite appears.
  REMOVE_BARS_WHEN_SHOWING_TRAINER = true
  # The final fade speed on entry.
  FINAL_FADE_DURATION = 1.0
  # Sprite's opacity value when it isn't selected.
  OPACITY = 0
  TEXT_BASE_COLOR   = Color.new(0, 0, 0)
  TEXT_SHADOW_COLOR = Color.new(248, 248, 248)

  # Placement for pokemon icons
  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    # Comment the below line to doesn't use a background
    addBackgroundPlane(@sprites, "bg", "bg_white_general", @viewport)
    @sprites["headerbar"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, Graphics.width, 80, @viewport)
    @sprites["headerbar"].visible = false
    @sprites["textbar"] = pbCreateMessageWindow(@viewport)
    @sprites["textbar"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 999
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @alreadyFadedInEnd = false
    @useMusic = false
    @battlerIndex = 0
    @hallEntry = []
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
  end

  def pbStartSceneEntry
    pbStartScene
    @useMusic = (HALL_OF_FAME_BGM && HALL_OF_FAME_BGM != "")
    pbBGMPlay(HALL_OF_FAME_BGM) if @useMusic
    saveHallEntry
    @movements = []
    createBattlers
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartScenePC
    pbStartScene
    @hallIndex = $PokemonGlobal.hallOfFame.size - 1
    @hallEntry = $PokemonGlobal.hallOfFame[-1]
    @sprites["headerbar"].visible = true
    @sprites["textbar"].visible = true
    createBattlers(false)
    pbFadeInAndShow(@sprites) { pbUpdate }
    pbUpdatePC
  end

  def pbEndScene
    $game_map.autoplay if @useMusic
    pbFadeOutAndHide(@sprites) { pbUpdate } if !@alreadyFadedInEnd
    pbDisposeMessageWindow(@sprites["textbar"])
    @sprites.delete("textbar")
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def slowFadeOut(duration)
    col = Color.new(0, 0, 0, 0)
    timer_start = System.uptime
    loop do
      col.alpha = lerp(0, 255, duration, timer_start, System.uptime)
      @viewport.color = col
      Graphics.update
      Input.update
      pbUpdate
      break if col.alpha == 255
    end
  end

  def saveHallEntry
    $player.party.each do |pkmn|
      # Clones every pokémon object
      @hallEntry.push(pkmn.clone) if !pkmn.egg? || ALLOW_EGGS
    end
    # Update the global variables
    $PokemonGlobal.hallOfFame.push(@hallEntry)
    $PokemonGlobal.hallOfFameLastNumber += 1
    if HALL_ENTRIES_LIMIT >= 0 && $PokemonGlobal.hallOfFame.size > HALL_ENTRIES_LIMIT
      $PokemonGlobal.hallOfFame.delete_at(0)
    end
  end

  def createBattlers(hide = true)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setPokemonBitmap(@hallEntry[0])
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = Graphics.width / 2
    @sprites["pokemon"].y = Graphics.height / 2
    @sprites["pokemon"].visible = !hide
  end

  def createTrainerBattler
    @sprites["trainer"] = IconSprite.new(@viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_back_sprite_filename($player.trainer_type))
    if @sprites["trainer"].width > @sprites["trainer"].height * 2
      @sprites["trainer"].src_rect.x     = 0
      @sprites["trainer"].src_rect.width = @sprites["trainer"].width / 5
    end
    @sprites["trainer"].ox = @sprites["trainer"].width / 2
    @sprites["trainer"].oy = @sprites["trainer"].height
    @sprites["trainer"].x = Graphics.width + (@sprites["trainer"].width / 2)
    @sprites["trainer"].y = Graphics.height
    @sprites["trainer"].visible = true
  end

  def writeTrainerData
    if $PokemonGlobal.hallOfFameLastNumber == 1
      totalsec = $stats.time_to_enter_hall_of_fame.to_i
    else
      totalsec = $stats.play_time.to_i
    end
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    pubid = sprintf("%05d", $player.public_ID)
    # How many Pokémon the player has seen
    seen_pkmn = $player.pokedex.seen_count
    # How many Pokémon the player owns
    own_pkmn = $player.pokedex.owned_count
    # Conditions for ME
    if own_pkmn >= 251
      rating_music = "Pokedex Evaluation... Complete!"
    elsif own_pkmn >= 240
      rating_music = "Pokedex Evaluation... Just a Little More!"
    elsif own_pkmn >= 180
      rating_music = "Pokedex Evaluation... Keep at It!"
    elsif own_pkmn >= 120
      rating_music = "Pokedex Evaluation... Not Bad!"
    elsif own_pkmn >= 60
      rating_music = "Pokedex Evaluation... You're on Your Way!"
    else
      rating_music = "Pokedex Evaluation... No Good!"
    end
    lefttext = _INTL("<ac>{1}</ac>", $player.name)
    lefttext += _INTL("ΙΝ<r>{1}", pubid) + "<br>"
    lefttext += _INTL("Play Time")
    lefttext += sprintf("<ac>%02d : %02d</ac>", hour, min)
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport = @viewport
    @sprites["messagebox"].width = 176
    @sprites["messagebox"].y = 32
    pbMessageDisplay(@sprites["textbar"],
                     _INTL("{1} Pokémon seen\n{2} Pokémon owned", seen_pkmn, own_pkmn))
    pbMessageDisplay(@sprites["textbar"], _INTL("Prof. Oak's\nRating:"))
    if own_pkmn < 10
      pbMessageDisplay(@sprites["textbar"], _INTL("Look for Pokémon in grassy areas!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 10 && own_pkmn <= 19
      pbMessageDisplay(@sprites["textbar"], _INTL("Good! I see you understand how to use Poké Balls.\1\\me[{1}]", rating_music))
    elsif own_pkmn >= 20 && own_pkmn <= 34
      pbMessageDisplay(@sprites["textbar"], _INTL("You're getting good at this. But you have a long way to go.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 35 && own_pkmn <= 49
      pbMessageDisplay(@sprites["textbar"], _INTL("You need to fill up the Pokédex. Catch different kinds of Pokémon!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 50 && own_pkmn <= 64
      pbMessageDisplay(@sprites["textbar"], _INTL("You're trying--I can see that. Your Pokédex is coming together.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 65 && own_pkmn <= 80
      pbMessageDisplay(@sprites["textbar"], _INTL("To evolve, some Pokémon grow, others use the effects of Stones.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 81 && own_pkmn <= 94
      pbMessageDisplay(@sprites["textbar"], _INTL("Have you gotten a fishing Rod? You can catch Pokémon by fishing.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 95 && own_pkmn <= 109
      pbMessageDisplay(@sprites["textbar"], _INTL("Excellent! You seem to like collecting things!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 110 && own_pkmn <= 124
      pbMessageDisplay(@sprites["textbar"], _INTL("Some Pokémon only appear during certain times of the day.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 125 && own_pkmn <= 139
      pbMessageDisplay(@sprites["textbar"], _INTL("Your Pokédex is filling up. Keep up the good work!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 140 && own_pkmn <= 154
      pbMessageDisplay(@sprites["textbar"], _INTL("I'm impressed. You're evolving Pokémon, not just catching them.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 155 && own_pkmn <= 169
      pbMessageDisplay(@sprites["textbar"], _INTL("Have you met Kurt? His custom Poké Balls should help.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 170 && own_pkmn <= 184
      pbMessageDisplay(@sprites["textbar"], _INTL("Wow. You've found more Pokémon than the last Pokédex research project.\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 185 && own_pkmn <= 199
      pbMessageDisplay(@sprites["textbar"], _INTL("Are you trading your Pokémon? It's tough to do this alone!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 200 && own_pkmn <= 214
      pbMessageDisplay(@sprites["textbar"], _INTL("Wow! You've hit 200! Your Pokédex is looking great!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 215 && own_pkmn <= 229
      pbMessageDisplay(@sprites["textbar"], _INTL("You've found so many Pokémon! You've really helped my studies!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 230 && own_pkmn <= 244
      pbMessageDisplay(@sprites["textbar"], _INTL("Magnificent! You could become a Pokémon professor right now!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 245 && own_pkmn <= 249
      pbMessageDisplay(@sprites["textbar"], _INTL("Your Pokédex is amazing! You're ready to turn professional!\\wt[8]\\me[{1}]", rating_music))
    elsif own_pkmn >= 250 && own_pkmn <= 251
      pbMessageDisplay(@sprites["textbar"], _INTL("Whoa! A perfect Pokédex! I've dreamt about this! Congratulations!\\wt[8]\\me[{1}]", rating_music))
    end
  end

  def writePokemonData(pokemon, hallNumber = -1)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    speciesname = pokemon.speciesName
    pokename = _INTL("/{1}", pokemon.name)
    pokename = _INTL("Egg") + "/" + _INTL("Egg") if pokemon.egg?
    idno = (pokemon.owner.name.empty? || pokemon.egg?) ? "?????" : sprintf("%05d", pokemon.owner.public_id)
    dexnumber = _INTL("Ν ???")
    if !pokemon.egg?
      number = @nationalDexList.index(pokemon.species) || 0
      dexnumber = _ISPRINTF("Ν {1:03d}", number)
    end
    textPositions = [
      [dexnumber, 16, 208, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [speciesname, 120, 208, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [pokename, Graphics.width / 2, 224, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [_INTL("Λ{1}", pokemon.egg? ? "?" : pokemon.level),
       18, 256, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [_INTL("ΙΝ/ {1}", pokemon.egg? ? "?????" : idno),
       176, 256, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]
    ]
    if pokemon.male?
      textPositions.push([_INTL("♂"), 288, 210, :left, Color.blue, TEXT_SHADOW_COLOR])
    else
      textPositions.push([_INTL("♀"), 290, 210, :left, Color.red, TEXT_SHADOW_COLOR])
    end
    if hallNumber > -1
      textPositions.push([_INTL("{1}-Time Famer", hallNumber.to_s), Graphics.width / 2, 32, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
    else
      textPositions.push([_INTL("New   Hall   of   Famer!"), Graphics.width / 2, 32, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
    end
    pbDrawTextPositions(overlay, textPositions)
  end

  def pbAnimationLoop
    loop do
      Graphics.update
      Input.update
      pbUpdate
      pbUpdateAnimation
      break if @battlerIndex == @hallEntry.size + 1
    end
  end

  def pbPCSelection
    loop do
      Graphics.update
      Input.update
      pbUpdate
      continueScene = true
      break if Input.trigger?(Input::BACK)   # Exits
      if Input.trigger?(Input::USE)   # Moves the selection one entry backward
        @battlerIndex += 10
        continueScene = pbUpdatePC
      end
      if Input.trigger?(Input::LEFT)   # Moves the selection one pokémon forward
        @battlerIndex -= 1
        continueScene = pbUpdatePC
      end
      if Input.trigger?(Input::RIGHT)   # Moves the selection one pokémon backward
        @battlerIndex += 1
        continueScene = pbUpdatePC
      end
      break if !continueScene
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateAnimation
    if @battlerIndex < @hallEntry.size
      @battlerIndex += 1
      @sprites["headerbar"].visible = false
      @sprites["textbar"].visible = false
      @sprites["overlay"].bitmap.clear
      # Back Animation
      start_time = System.uptime
      @sprites["pokemon"].setPokemonBitmap(@hallEntry[@battlerIndex - 1], true)
      @sprites["pokemon"].setOffset(PictureOrigin::BOTTOM)
      @sprites["pokemon"].y = Graphics.height
      @sprites["pokemon"].x = Graphics.width + (@sprites["pokemon"].width / 2)
      @sprites["pokemon"].visible = true
      loop do
        Graphics.update
        pbUpdate
        @sprites["pokemon"].x = lerp(Graphics.width + (@sprites["pokemon"].width / 2), -(@sprites["pokemon"].width / 2), 1, start_time, System.uptime).to_i
        break if @sprites["pokemon"].x <= -(@sprites["pokemon"].width / 2)
      end
      # Front Animation
      @sprites["pokemon"].setPokemonBitmap(@hallEntry[@battlerIndex - 1])
      @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokemon"].y = Graphics.height / 2
      start_time = System.uptime
      loop do
        Graphics.update
        pbUpdate
        @sprites["pokemon"].x = lerp(-(@sprites["pokemon"].width / 2), Graphics.width / 2, 1, start_time, System.uptime).to_i
        break if @sprites["pokemon"].x >= Graphics.width / 2
      end
      @sprites["headerbar"].visible = true
      @sprites["textbar"].visible = true
      @hallEntry[@battlerIndex - 1].play_cry
      writePokemonData(@hallEntry[@battlerIndex - 1])
      timer_start = System.uptime
      loop do
        Graphics.update
        Input.update
        pbUpdate
        break if System.uptime - timer_start >= ENTRY_WAIT_TIME
      end
    else
      @sprites["pokemon"].visible = false if @battlerIndex >= @hallEntry.size
      @sprites["headerbar"].visible = false
      @sprites["textbar"].visible = false
      @sprites["overlay"].bitmap.clear
      # Back Trainer Animation
      start_time = System.uptime
      createTrainerBattler
      loop do
        Graphics.update
        pbUpdate
        @sprites["trainer"].x = lerp(Graphics.width + (@sprites["trainer"].width / 2), -(@sprites["trainer"].width / 2), 1, start_time, System.uptime).to_i
        break if @sprites["trainer"].x <= -(@sprites["trainer"].width / 2)
      end
      # Front Animation
      @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
      @sprites["trainer"].oy = @sprites["trainer"].height / 2
      @sprites["trainer"].y  = (Graphics.height / 2) - 20
      start_time = System.uptime
      loop do
        Graphics.update
        pbUpdate
        @sprites["trainer"].x = lerp(-(@sprites["trainer"].width / 2), Graphics.width * 3 / 4, 1, start_time, System.uptime).to_i
        break if @sprites["trainer"].x >= Graphics.width * 3 / 4
      end
      # Write the trainer data and fade
      @sprites["textbar"].visible = true
      writeTrainerData
      timer_start = System.uptime
      loop do
        Graphics.update
        Input.update
        pbUpdate
        break if System.uptime - timer_start >= ENTRY_WAIT_TIME
      end
      pbBGMFade(FINAL_FADE_DURATION) if @useMusic
      slowFadeOut(FINAL_FADE_DURATION)
      @alreadyFadedInEnd = true
      @battlerIndex += 1
    end
  end

  def pbUpdatePC
    # Change the team
    if @battlerIndex >= @hallEntry.size
      @hallIndex -= 1
      return false if @hallIndex == -1
      @hallEntry = $PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex = 0
      # createBattlers(false)
    elsif @battlerIndex < 0
      @hallIndex += 1
      return false if @hallIndex >= $PokemonGlobal.hallOfFame.size
      @hallEntry = $PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex = @hallEntry.size - 1
      # createBattlers(false)
    end
    # Change the pokemon
    @sprites["pokemon"].setPokemonBitmap(@hallEntry[@battlerIndex])
    @hallEntry[@battlerIndex].play_cry
    # setPokemonSpritesOpacity(@battlerIndex, OPACITY)
    hallNumber = $PokemonGlobal.hallOfFameLastNumber + @hallIndex -
                 $PokemonGlobal.hallOfFame.size + 1
    writePokemonData(@hallEntry[@battlerIndex], hallNumber)
    return true
  end
end

#===============================================================================
#
#===============================================================================
class HallOfFameScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreenEntry
    @scene.pbStartSceneEntry
    @scene.pbAnimationLoop
    @scene.pbEndScene
  end

  def pbStartScreenPC
    @scene.pbStartScenePC
    @scene.pbPCSelection
    @scene.pbEndScene
  end
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pc_menu, :hall_of_fame, {
  "name"      => _INTL("Hall of Fame"),
  "order"     => 40,
  "condition" => proc { next $PokemonGlobal.hallOfFameLastNumber > 0 },
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("Accessed the Hall of Fame."))
    pbHallOfFamePC
    next false
  }
})

#===============================================================================
#
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :hallOfFame
  # Number necessary if hallOfFame array reach in its size limit
  attr_writer :hallOfFameLastNumber

  def hallOfFame
    @hallOfFame = [] if !@hallOfFame
    return @hallOfFame
  end

  def hallOfFameLastNumber
    return @hallOfFameLastNumber || 0
  end
end

#===============================================================================
#
#===============================================================================
def pbHallOfFameEntry
  scene = HallOfFame_Scene.new
  screen = HallOfFameScreen.new(scene)
  screen.pbStartScreenEntry
end

def pbHallOfFamePC
  scene = HallOfFame_Scene.new
  screen = HallOfFameScreen.new(scene)
  screen.pbStartScreenPC
end
