def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$player
  if SaveData.exists?
    File.open(SaveData::FILE_PATH, "rb") do |r|
      File.open(SaveData::FILE_PATH + ".bak", "wb") do |w|
        loop do
          s = r.read(4096)
          break if !s
          w.write(s)
        end
      end
    end
  end
  if Game.save
    pbMessage("\\se[]" + _INTL("The game was saved.") + "\\me[GUI save game]\\wtnp[20]")
    pbMessage("\\se[]" + _INTL("The previous save file has been backed up.") + "\\wtnp[20]")
  else
    pbMessage("\\se[]" + _INTL("Save failed.") + "\\wtnp[30]")
  end
  $scene = oldscene
end

#===============================================================================
#
#===============================================================================
class PokemonSave_Scene
  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["locwindow"] = pbDisplayPlayerDataWindow($player, $stats.play_time.to_i, nil, @viewport)
    @sprites["locwindow"].visible = true
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

def pbDisplayPlayerDataWindow(player, totalsec, map_id, viewport, y = 0)
  hour = totalsec / 60 / 60
  min = totalsec / 60 % 60
  loctext = ""
  if map_id
    mapname = pbGetMapNameFromId(map_id)
    mapname.gsub!(/\\PN/, player.name)
    loctext += "<ac>" + mapname + "</ac>"
  end
  loctext += _INTL("Player") + "<r>" + player.name + "<br>"
  loctext += _INTL("Badges") + "<r>" + player.badge_count.to_s + "<br>"
  if player.has_pokedex
    loctext += _INTL("Pokédex") + "<r>" + player.pokedex.owned_count.to_s + "<br>"
  end
  loctext += _INTL("Time") + "<r>" + sprintf("%02d : %02d", hour, min) + "<br>"
  playerwindow = Window_AdvancedTextPokemon.new(loctext)
  playerwindow.viewport = @viewport
  playerwindow.width = 228 if playerwindow.width < 228
  playerwindow.x = Graphics.width - playerwindow.width
  playerwindow.y = y < 0 ? Graphics.height - playerwindow.height : y
  return playerwindow
end

#===============================================================================
#
#===============================================================================
class PokemonSaveScreen
  def initialize(scene)
    @scene = scene
  end

  def pbDisplay(text, brief = false)
    @scene.pbDisplay(text, brief)
  end

  def pbDisplayPaused(text)
    @scene.pbDisplayPaused(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  def pbSaveScreen
    ret = false
    @scene.pbStartScreen
    if pbConfirmMessage(_INTL("Would you like to save the game?"))
      if SaveData.exists? && $game_temp.begun_new_game
        if !pbConfirmMessageSerious(_INTL("There is already a save file. Is it OK to overwrite?"))
          @scene.pbEndScreen
          return false
        end
      end
      $game_temp.begun_new_game = false
      if Game.save
        pbMessage(_INTL("\\ts[2]Saving... Don't turn off the \\wtnp[1]Power.\\wtnp[25]"))
        pbMessage("\\se[]" + _INTL("\\ts[2]{1} saved the game.\\me[GUI save game]\\wtnp[30]", $player.name))
        ret = true
      else
        pbMessage("\\se[]" + _INTL("Save failed.") + "\\wtnp[30]")
        ret = false
      end
    else
      pbPlayDecisionSE
    end
    @scene.pbEndScreen
    return ret
  end

  def pbConfirmMessage(message, &block)
    return (pbMessage(message, [_INTL("Yes"), _INTL("No")], 2, &block) == 0)
  end
  
  def pbConfirmMessageSerious(message, &block)
    return (pbMessage(message, [_INTL("No"), _INTL("Yes")], 1, &block) == 1)
  end
  
  def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
    ret = 0
    msgwindow = pbCreateMessageWindow(nil, skin)
    if commands
      ret = pbMessageDisplay(msgwindow, message, true,
                            proc { |msgwndw|
                              next pbShowCommands(msgwndw, commands, cmdIfCancel, defaultCmd, &block)
                            }, &block)
    else
      pbMessageDisplay(msgwindow, message, &block)
    end
    pbDisposeMessageWindow(msgwindow)
    Input.update
    return ret
  end

  def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0)
    return 0 if !commands
    cmdwindow = Window_CommandPokemonEx.new(commands)
    cmdwindow.z = 99999
    cmdwindow.visible = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    pbPositionNearMsgWindow(cmdwindow, msgwindow, :left)
    cmdwindow.index = defaultCmd
    command = 0
    loop do
      Graphics.update
      Input.update
      cmdwindow.update
      msgwindow&.update
      yield if block_given?
      if Input.trigger?(Input::BACK)
        if cmdIfCancel > 0
          command = cmdIfCancel - 1
          break
        elsif cmdIfCancel < 0
          command = cmdIfCancel
          break
        end
      end
      if Input.trigger?(Input::USE)
        command = cmdwindow.index
        break
      end
      pbUpdateSceneMap
    end
    ret = command
    cmdwindow.dispose
    Input.update
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end
