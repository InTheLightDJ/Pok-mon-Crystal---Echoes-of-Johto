#===============================================================================
#
#===============================================================================
class PokemonPauseMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["helpwindow"].visible = false
    @sprites["descwindow_bg"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["descwindow"] = Window_UnformattedTextPokemon.newWithSize("", -12, Graphics.height - 80, 182, 100, @viewport)
    @sprites["descwindow"].windowskin = nil
    @sprites["descwindow"].visible = false
    @sprites["timewindow"] = Window_AdvancedTextPokemon.newWithSize("", 0, 0, Graphics.width / 2, 64, @viewport)
    @sprites["timewindow"].letterbyletter = false
    @sprites["timewindow"].viewport = @viewport
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text, Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowInfo1(yPos,text)#light
    @sprites["infowindow"].resizeToFit(text, Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @sprites["infowindow"].y = yPos
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text, Graphics.height)
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
    @sprites["timewindow"].visible = true
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
    @sprites["timewindow"].visible = false
  end

  def pbShowDecription(text)
    @sprites["descwindow_bg"].bitmap.clear
    @sprites["descwindow"].visible = ($PokemonSystem.pause_menu_desc == 0) # on
    if $PokemonSystem.pause_menu_desc == 0 # on
      @sprites["descwindow_bg"].bitmap.fill_rect(0, Graphics.height - 70, 160, 70, Color.white)
      @sprites["descwindow"].text    = text
    end
  end

  def pbShowCommands(commands,cmd)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index    = $game_temp.menu_last_choice
    cmdwindow.resizeToFit(commands)
    cmdwindow.width    = Graphics.width / 2 # 160
    cmdwindow.x        = Graphics.width - cmdwindow.width
    cmdwindow.y        = 0
    cmdwindow.visible  = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      # Clock constantly updating
      time = pbGetTimeNow
      hour = (time.hour >= 24) ? time.hour - 24 : time.hour
      min = time.min
      case hour
        when 0...12 then
          periode = "a.m"
        when 12 then
          periode = "m."
        else
          periode = "p.m"
      end
      hour_digit = (hour >= 10 ? nil : 0)
      min_digit  = (min  >= 10 ? nil : 0)
      @sprites["timewindow"].setText(_INTL("{1}{2} : {3}{4}<r>{5}", hour_digit, hour, min_digit, min, periode))
      text = cmd[cmdwindow.index]["desc"] || ""
      pbShowDecription(text)
      if Input.trigger?(Input::BACK) || Input.trigger?(Input::ACTION)
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = cmdwindow.index
        $game_temp.menu_last_choice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end

#===============================================================================
#
#===============================================================================
class PokemonPauseMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbShowInfo; end

  def pbStartPokemonMenu
    if !$player
      if $DEBUG
        pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
        pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    @scene.pbStartScene
    # Show extra info window if relevant
    pbShowInfo
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pause_menu) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbShowCommands(command_list, commands)
      if choice < 0
        pbPlayCloseMenuSE
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
  end
end

#===============================================================================
# Pause menu commands.
#===============================================================================
MenuHandlers.add(:pause_menu, :pokedex, {
  "name"      => _INTL("Pokédex"),
  "order"     => 10,
  "condition" => proc { next $player.has_pokedex && $player.pokedex.accessible_dexes.length > 0 },
  "desc"      => _INTL("Pokémon database"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    if Settings::USE_CURRENT_REGION_DEX
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    elsif $player.pokedex.accessible_dexes.length == 1
      $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[0]
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    else
      pbFadeOutIn do
        scene = PokemonPokedexMenu_Scene.new
        screen = PokemonPokedexMenuScreen.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      end
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :party, {
  "name"      => _INTL("Pokémon"),
  "order"     => 20,
  "condition" => proc { next $player.party_count > 0 },
  "desc"      => _INTL("Party κΜ status"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    hidden_move = nil
    pbFadeOutIn do
      sscene = PokemonParty_Scene.new
      sscreen = PokemonPartyScreen.new(sscene, $player.party)
      hidden_move = sscreen.pbPokemonScreen
      (hidden_move) ? menu.pbEndScene : menu.pbRefresh
    end
    next false if !hidden_move
    $game_temp.in_menu = false
    pbUseHiddenMove(hidden_move[0], hidden_move[1])
    next true
  }
})

MenuHandlers.add(:pause_menu, :bag, {
  "name"      => _INTL("Pack"),
  "order"     => 30,
  "condition" => proc { next !pbInBugContest? },
  "desc"      => _INTL("Contains items"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    item = nil
    pbFadeOutIn do
      scene = PokemonBag_Scene.new
      screen = PokemonBagScreen.new(scene, $bag)
      item = screen.pbStartScreen
      (item) ? menu.pbEndScene : menu.pbRefresh
    end
    next false if !item
    $game_temp.in_menu = false
    pbUseKeyItemInField(item)
    next true
  }
})

MenuHandlers.add(:pause_menu, :pokegear, {
  "name"      => _INTL("ΡΚgear"),
  "order"     => 40,
  "condition" => proc { next $player.has_pokegear },
  "desc"      => _INTL("Trainer's key device"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonPokegear_Scene.new
      screen = PokemonPokegearScreen.new(scene)
      screen.pbStartScreen
      ($game_temp.fly_destination) ? menu.pbEndScene : menu.pbRefresh
    end
    next pbFlyToNewLocation
  }
})

MenuHandlers.add(:pause_menu, :town_map, {
  "name"      => _INTL("Town Map"),
  "order"     => 40,
  "condition" => proc { next !$player.has_pokegear && $bag.has?(:TOWNMAP) },
  "desc"      => _INTL("Places location"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonRegionMap_Scene.new(-1, false)
      screen = PokemonRegionMapScreen.new(scene)
      ret = screen.pbStartScreen
      $game_temp.fly_destination = ret if ret
      ($game_temp.fly_destination) ? menu.pbEndScene : menu.pbRefresh
    end
    next pbFlyToNewLocation
  }
})

MenuHandlers.add(:pause_menu, :trainer_card, {
  "name"      => proc { next $player.name },
  "order"     => 50,
  "desc"      => _INTL("Your own status"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonTrainerCard_Scene.new
      screen = PokemonTrainerCardScreen.new(scene)
      screen.pbStartScreen
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :save, {
  "name"      => _INTL("Save"),
  "order"     => 60,
  "condition" => proc {
    next $game_system && !$game_system.save_disabled && !pbInSafari? && !pbInBugContest?
  },
  "desc"      => _INTL("Save your progress"),
  "effect"    => proc { |menu|
    menu.pbHideMenu
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    if screen.pbSaveScreen
      menu.pbEndScene
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})

MenuHandlers.add(:pause_menu, :options, {
  "name"      => _INTL("Options"),
  "order"     => 70,
  "desc"      => _INTL("Change settings"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      scene = PokemonOption_Scene.new
      screen = PokemonOptionScreen.new(scene)
      screen.pbStartScreen
      pbUpdateSceneMap
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :debug, {
  "name"      => _INTL("Debug"),
  "order"     => 80,
  "condition" => proc { next $DEBUG },
  "desc"      => _INTL("Debug command list"),
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn do
      pbDebugMenu
      menu.pbRefresh
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :quit_game, {
  "name"      => _INTL("Quit"),
  "order"     => 90,
  "desc"      => _INTL("Exit the game"),
  "effect"    => proc { |menu|
    menu.pbHideMenu
    if pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
      scene = PokemonSave_Scene.new
      screen = PokemonSaveScreen.new(scene)
      screen.pbSaveScreen
      menu.pbEndScene
      $scene = nil
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})







MenuHandlers.add(:pause_menu, :encounters, {
  "name"      =>  _INTL("Encounters"),
  "order"     => 50,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn {
      scene = EncounterList_Scene.new
      screen = EncounterList_Screen.new(scene)
      screen.pbStartScreen
      menu.pbRefresh
    }
    next false
  }
})