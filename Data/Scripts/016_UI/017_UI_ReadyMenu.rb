#===============================================================================
#
#===============================================================================
class ReadyMenuButton < Sprite
  attr_reader :index   # ID of button

  def initialize(command, index, type, viewport = nil)
    super(viewport)
    @index = index
    @type = type
    @command = command   # Item/move ID, name, mode (T move/F item), pkmnIndex
    @contents = Bitmap.new(64, 64)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    @bg = pbCreateMessageWindow(viewport)
    @bg.width = @contents.width
    @bg.height = @contents.height
    if @type
      @icon = PokemonIconSprite.new($player.party[@command[@index][3]], viewport)
      @icon.setOffset(PictureOrigin::CENTER)
    else
      @icon = ItemIconSprite.new(0, 0, @command[@index][0], viewport)
    end
     @bg.z = self.z
     @icon.z = self.z + 1
    refresh
  end

  def dispose
    pbDisposeMessageWindow(@bg)
    @contents.dispose
    @icon.dispose
    super
  end

  def visible=(val)
    @icon.visible = val
    @bg.visible = val
    super(val)
  end

  def index=(val)
    oldindex = @index
    @index = val
    refresh if oldindex != val
  end

  def refresh
    self.y = ((Graphics.height - 64) / 2)
    if @type   # Pokémon
      @icon.pokemon = $player.party[@command[@index][3]]
      self.x = 32
      @icon.x = self.x + 31
      @icon.y = self.y + 39
    else   # Item
      @icon.item = @command[@index][0]
      self.x = Graphics.width - 96
      @icon.x = self.x + 30
      @icon.y = self.y + 34
    end
    @bg.x = self.x
    @bg.y = self.y
  end

  def update
    @icon&.update
    super
  end
end
#===============================================================================
#
#===============================================================================
class PokemonReadyMenu_Scene
  attr_reader :sprites

  def pbStartScene(commands)
    @commands = commands
    @movecommands = []
    @itemcommands = []
    @commands[0].length.times do |i|
      @movecommands.push(@commands[0][i][1])
    end
    @commands[1].length.times do |i|
      @itemcommands.push(@commands[1][i][1])
    end
    @index = $bag.ready_menu_selection
    if @index[0] >= @movecommands.length && @movecommands.length > 0
      @index[0] = @movecommands.length - 1
    end
    if @index[1] >= @itemcommands.length && @itemcommands.length > 0
      @index[1] = @itemcommands.length - 1
    end
    if @index[2] == 0 && @movecommands.length == 0
      @index[2] = 1
    elsif @index[2] == 1 && @itemcommands.length == 0
      @index[2] = 0
    end
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 4
    @sprites["textbg"] = pbCreateMessageWindow(@viewport)
    @sprites["textbg"].height = 80
    @sprites["textbg"].y = Graphics.height - @sprites["textbg"].height
    @sprites["textbg"].z = 3
    @sprites["left"] = AnimatedSprite.new("Graphics/UI/arrow_left", 8, 16, 18, 2, @viewport)
    @sprites["left"].z = 1
    @sprites["left"].play
    @sprites["right"] = AnimatedSprite.new("Graphics/UI/arrow_right", 8, 16, 18, 2, @viewport)	
    @sprites["right"].z = 1
    @sprites["right"].play	
    @sprites["up"] = AnimatedSprite.new("Graphics/UI/arrow_up", 8, 18, 16, 2, @viewport)
    @sprites["up"].z = 1
    @sprites["up"].play
    @sprites["down"] = AnimatedSprite.new("Graphics/UI/arrow_down", 8, 18, 16, 2, @viewport)
    @sprites["down"].z = 1
    @sprites["down"].play
    @sprites["cmdwindow"] = Window_CommandPokemon.new((@index[2] == 0) ? @movecommands : @itemcommands)
    @sprites["cmdwindow"].height = 192
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["movebutton"] = ReadyMenuButton.new(@commands[0], @index[0], true, @viewport)
    @sprites["itembutton"] = ReadyMenuButton.new(@commands[1], @index[1], false, @viewport)
    pbSEPlay("GUI menu open")
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = false
    @sprites["movebutton"].visible = true
    @sprites["itembutton"].visible = true
    pbUpdate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["movebutton"].visible = false
    @sprites["itembutton"].visible = false
    @sprites["up"].visible    = false
    @sprites["down"].visible  = false
    @sprites["right"].visible = false
    @sprites["left"].visible  = false
  end

  def pbShowCommands
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = (@index[2] == 0) ? @movecommands : @itemcommands
    cmdwindow.index    = @index[@index[2]]
    cmdwindow.visible  = false
    loop do
      pbUpdate
      if Input.trigger?(Input::LEFT) && @index[2] == 1 && @movecommands.length > 0
        @index[2] = 0
        pbChangeSide
      elsif Input.trigger?(Input::RIGHT) && @index[2] == 0 && @itemcommands.length > 0
        @index[2] = 1
        pbChangeSide
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        ret = -1
        break
      elsif Input.trigger?(Input::USE)
        ret = [@index[2], cmdwindow.index]
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeMessageWindow(@sprites["textbg"])
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbChangeSide
    @sprites["cmdwindow"].commands = (@index[2] == 0) ? @movecommands : @itemcommands
    @sprites["cmdwindow"].index = @index[@index[2]]
  end

  def pbRefresh; end

  def pbUpdate
    oldindex = @index[@index[2]]
    @index[@index[2]] = @sprites["cmdwindow"].index
    if @index[@index[2]] != oldindex
      case @index[2]
      when 0
        @sprites["movebutton"].index = @index[@index[2]]
      when 1
        @sprites["itembutton"].index = @index[@index[2]]
      end
    end
    # Arrow Positions
    @sprites["left"].x  = 206
    @sprites["left"].y  = 136
    @sprites["right"].x = 98
    @sprites["right"].y = 136
    # Positions          [pokemon, item]
    @sprites["up"].x   = [ 54, 246][@index[2]]
    @sprites["up"].y   = [ 94,  94][@index[2]]
    @sprites["down"].x = [ 54, 246][@index[2]]
    @sprites["down"].y = [178, 178][@index[2]]
    @sprites["up"].visible    = (@commands[@index[2]].length > 1)
    @sprites["down"].visible  = (@commands[@index[2]].length > 1)
    @sprites["right"].visible = (@commands[1].length > 0 && @index[2] == 0)
    @sprites["left"].visible  = (@commands[0].length > 0 && @index[2] == 1)
    pbUpdateSpriteHash(@sprites)
    @sprites["overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["overlay"].bitmap, [
         [@commands[@index[2]][@index[@index[2]]][1], Graphics.width / 2, 244, :center, Color.new(0, 0, 0),Color.new(248, 248, 248)]	
      ])
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
end

#===============================================================================
#
#===============================================================================
class PokemonReadyMenu
  def initialize(scene)
    @scene = scene
  end

  def pbHideMenu
    @scene.pbHideMenu
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartReadyMenu(moves, items)
    commands = [[], []]   # Moves, items
    moves.each do |i|
      commands[0].push([i[0], GameData::Move.get(i[0]).name, true, i[1]])
    end
    commands[0].sort! { |a, b| a[1] <=> b[1] }
    items.each do |i|
      commands[1].push([i, GameData::Item.get(i).name, false])
    end
    commands[1].sort! { |a, b| a[1] <=> b[1] }
    @scene.pbStartScene(commands)
    loop do
      command = @scene.pbShowCommands
      break if command == -1
      if command[0] == 0   # Use a move
        move = commands[0][command[1]][0]
        user = $player.party[commands[0][command[1]][3]]
        if move == :FLY
          ret = nil
          pbFadeOutInWithUpdate(99999, @scene.sprites) do
            pbHideMenu
            scene = PokemonRegionMap_Scene.new(-1, false)
            screen = PokemonRegionMapScreen.new(scene)
            ret = screen.pbStartFlyScreen
            pbShowMenu if !ret
          end
          if ret
            $game_temp.fly_destination = ret
            $game_temp.in_menu = false
            pbUseHiddenMove(user, move)
            break
          end
        else
          pbHideMenu
          if pbConfirmUseHiddenMove(user, move)
            $game_temp.in_menu = false
            pbUseHiddenMove(user, move)
            break
          else
            pbShowMenu
          end
        end
      else   # Use an item
        item = commands[1][command[1]][0]
        pbHideMenu
        if ItemHandlers.triggerConfirmUseInField(item)
          $game_temp.in_menu = false
          break if pbUseKeyItemInField(item)
          $game_temp.in_menu = true
        end
      end
      pbShowMenu
    end
    @scene.pbEndScene
  end
end

#===============================================================================
# Using a registered item
#===============================================================================
def pbUseKeyItem
  # First check for registered items
  real_items = []
  $bag.registered_items.each do |i|
    itm = GameData::Item.get(i).id
    real_items.push(itm) if $bag.has?(itm)
  end

  # Try to use the first valid registered item
  if !real_items.empty?
    item = real_items[0]
    if ItemHandlers.triggerConfirmUseInField(item)
      $game_temp.in_menu = false
      pbUseKeyItemInField(item) || pbMessage(_INTL("Can't use that item here."))
    else
      pbMessage(_INTL("Can't use that item here."))
    end
    return
  end

  # Fallback: Try using hidden moves instead
  moves = [:CUT, :DEFOG, :DIG, :DIVE, :FLASH, :FLY, :HEADBUTT, :ROCKCLIMB,
           :ROCKSMASH, :SECRETPOWER, :STRENGTH, :SURF, :SWEETSCENT, :TELEPORT,
           :WATERFALL, :WHIRLPOOL]
  $player.party.each do |pkmn|
    next if pkmn.egg?
    moves.each do |move|
      next if !pkmn.hasMove?(move)
      if pbCanUseHiddenMove?(pkmn, move)
        if pbConfirmUseHiddenMove(pkmn, move)
          pbUseHiddenMove(pkmn, move)
        end
        return
      end
    end
  end

  # If nothing usable at all
  pbMessage(_INTL("There's nothing registered that can be used now."))
end
