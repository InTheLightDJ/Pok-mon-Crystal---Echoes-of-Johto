#===============================================================================
# GSC Style Pokégear
# How to use: call script "pbPokegear"
#===============================================================================

#===============================================================================
# Settings
#===============================================================================
module Settings
  # Rocket Take Over Radio Station switch
  # When ON, every Channel will change into Team Rocket Broadcasting
  ROCKET_TAKEOVER = 59

  # These are Trainer Types that will not be mentioned in "Places & People
  # Channel"
  # You can add whatever you want
  UNPUBLICIZED_TRAINERS = [
    :LEADER_Falkner,
    :ROCKETGRUNT_M,
    :ROCKETGRUNT_F,
    :RIVAL1,
    :CHAMPION_Lance
  ]
end

#===============================================================================
# Game_Temp to keep the last Radio Channel and Tracker toogle
#===============================================================================
class Game_Temp
  attr_accessor :pokegearUse
  attr_accessor :pokegearRadioCh
  attr_accessor :pokegearMapTracker
end

#===============================================================================
# Phone window related
#===============================================================================
class Window_AdvancedTextPokemon < SpriteWindow_Base
  def allocPause
    return if @pausesprite
    windowpause = $game_temp.pokegearUse ? "_pokegear" : ""
    @pausesprite = AnimatedSprite.create("Graphics/UI/pause_arrow" + windowpause, 2, 12)
    @pausesprite.z       = 100000
    @pausesprite.visible = false
  end
end

#===============================================================================
# Pokegear Core
#===============================================================================
def pbPokegear
  pbFadeOutIn{
    scene = PokemonPokegear_Scene.new
    screen = PokemonPokegearScreen.new(scene)
    ret = screen.pbStartScreen
  }
end

class PokemonPokegearScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    $game_temp.pokegearUse = true
    @scene.pbStartScene
    ret = @scene.pbScene
    @scene.pbEndScene
    $game_temp.pokegearUse = nil
    return ret
  end
end

class PokemonPokegear_Scene  
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @baseColor   = Color.new(0, 0, 0)
    @shadowColor = Color.new(248, 248, 248, 0)
    @sprites = {}
    @page_list = []
    @page_hash = []
    MenuHandlers.each_available(:pokegear_menu_gsc) do |option, hash, name|
      @page_list.push(option)
      @page_hash.push(hash)
    end
    @page = 0
    @offset_page = 0   
    
    # Sprites
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    pbChangeBg

    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @helpwindow = @sprites["helpwindow"]
    @helpwindow.viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], 2)
    @helpwindow.width = Graphics.width
    @helpwindow.text = _INTL("Press any button to exit.")
    @helpwindow.baseColor = @baseColor
    @helpwindow.shadowColor = @shadowColor
    @helpwindow.visible = true
    @sprites["fill_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["fill_overlay"].bitmap.fill_rect(@helpwindow.x, @helpwindow.y, @helpwindow.width, @helpwindow.height, Color.new(24,0,88))
    @sprites["fill_overlay"].blend_type = 2
    @sprites["fill_overlay"].z = @helpwindow.z + 1

    pbCustomStartScene
        
    # Icon
    icofile = pbCheckGraphicFile("Graphics/UI/Pokegear/icon")
    4.times do |i|
      next if @sprites["icon#{i}"]
      @sprites["icon#{i}"] = IconSprite.new(8 + 28 * i, 0, @viewport)
      @sprites["icon#{i}"].setBitmap(icofile)
      @sprites["icon#{i}"].src_rect = Rect.new(i > @page_list.length - 1 ? 28 : 0, 0, 28, 32)
    end

    # Cursor
    @sprites["cursor"] = IconSprite.new(0, 26, @viewport)
    @sprites["cursor"].setBitmap(pbCheckGraphicFile("Graphics/UI/Pokegear/cursor"))
    
    # Text
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["icon_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    drawPage(pbGetPageId)
    
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbScene
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldpage = @page
      oldpageID = pbGetPageId
      pbPageControl
      if Input.trigger?(Input::BACK)
        if $game_system.getPlayingBGM == nil
          $game_map.autoplay
        end
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::LEFT) && @page > 0
        @page -= 1
        @offset_page -= 1 if @page < @offset_page + 1 && @offset_page > 0
      elsif Input.trigger?(Input::RIGHT) && @page < @page_list.length - 1
        @page += 1
        @offset_page += 1 if @page > @offset_page + 2 && @offset_page < @page_list.length - 4\
      end
      if @page != oldpage
        drawPage(pbGetPageId)
        if pbGetPageId == :radio
          $game_system.bgm_memorize
          pbBGMStop
        elsif oldpageID == :radio
          $game_system.bgm_restore
        end
      end
    end
  end
  
  def pbGetPageId
    return @page_list[@page]
  end

  def pbCursorPosition
    @sprites["cursor"].x = 10 + 28 * (@page - @offset_page)
  end

  def pbCheckGraphicFile(path)
    return path + "_f" if $player.female? && pbResolveBitmap(path + "_f")
    return path
  end

  def pbChangeBg
    page_id = @page_hash[@page]["suffix"]
    @sprites["background"].setBitmap(pbCheckGraphicFile("Graphics/UI/Pokegear/bg_#{page_id}"))
  end

  def drawPage(page_id)
    @helpwindow.text = ""
    pbChangeBg
    pbDrawIcon
    pbCursorPosition
    pbUpdateText
  end

  def pbDrawIcon
    overlay = @sprites["icon_overlay"].bitmap
    overlay.clear
    imagepos = []
    [@page_list.length, 4].min.times do |i|
      page_suffix = @page_hash[i + @offset_page]["suffix"]
      imagepos.push([pbCheckGraphicFile("Graphics/UI/Pokegear/icon_#{page_suffix}"), 10 + 28 * i, 4])
    end
    xleft  = @page_list.length <= 4 ? 0 : @page > 0 ? 8 : 16
    xright = @page_list.length <= 4 ? 0 : @page < @page_list.length - 1 ? 8 : 16
    arrow_img = pbCheckGraphicFile("Graphics/UI/Pokegear/arrow")
    imagepos.push([arrow_img, 0, 0, xleft, 0, 8, 32]) # left arrow
    imagepos.push([arrow_img, 120, 0, xright, 32, 8, 32]) # right arrow
    pbDrawImagePositions(overlay, imagepos)
  end

  #===============================================================
  # Overwrite for Pokegear
  #===============================================================
  def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0)
    return 0 if !commands
    cmdwindow = Window_CommandPokemonEx.new(commands)
    cmdwindow.z = 99999
    cmdwindow.visible = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    pbPositionNearMsgWindow(cmdwindow, msgwindow, :right)
    cmdwindow.index = defaultCmd
    cmdwindow.shadowColor = nil
    fill_overlay = BitmapSprite.new(Graphics.width, Graphics.height)
    fill_overlay.bitmap.fill_rect(cmdwindow.x, cmdwindow.y, cmdwindow.width, cmdwindow.height, Color.new(24,0,88))
    fill_overlay.blend_type = 2
    fill_overlay.z = cmdwindow.z + 1
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
    fill_overlay.dispose
    Input.update
    return ret
  end

  def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
    ret = 0
    msgwindow = pbCreateMessageWindow(nil, skin)
    fill_overlay = BitmapSprite.new(Graphics.width, Graphics.height)
    fill_overlay.bitmap.fill_rect(msgwindow.x, msgwindow.y, msgwindow.width, msgwindow.height, Color.new(24,0,88))
    fill_overlay.blend_type = 2
    fill_overlay.z = msgwindow.z + 1
    if commands
      ret = pbMessageDisplay(msgwindow, message, true,
                             proc { |msgwndw|
                               next pbShowCommands(msgwndw, commands, cmdIfCancel, defaultCmd, &block)
                             }, &block)
    else
      pbMessageDisplay(msgwindow, message, &block)
    end
    pbDisposeMessageWindow(msgwindow)
    fill_overlay.dispose
    Input.update
    return ret
  end

  #===============================================================
  # Method that will be called by alias
  #===============================================================
  def pbCustomStartScene
  end
  
  def pbUpdate
    # Sprite Hash Update
    pbUpdateSpriteHash(@sprites)
  end

  def pbPageControl
  end
  
  def pbUpdateText
    @sprites["overlay"].bitmap.clear
  end
end