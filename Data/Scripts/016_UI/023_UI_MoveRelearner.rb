#===============================================================================
# Scene class for handling appearance of the screen
#===============================================================================
class MoveRelearner_Scene
  VISIBLEMOVES = 3

  def pbDisplay(msg, brief = false)
    UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(pokemon, moves)
    @pokemon = pokemon
    @moves = moves
    moveCommands = []
    moves.each { |m| moveCommands.push(GameData::Move.get(m).name) }
    # Create sprite hash
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    addBackgroundPlane(@sprites, "bg", "bg_white_general", @viewport)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x = 264
    @sprites["pokeicon"].y = 16
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlaydesc"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSmallFont(@sprites["overlaydesc"].bitmap)
    @sprites["commands"] = Window_CommandPokemon.new(moveCommands, 32)
    @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
    @sprites["commands"].visible = false
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible = false
    @sprites["msgwindow"].viewport = @viewport
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    pbDrawMoveList
    pbDeactivateWindows(@sprites)
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawMoveList
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    overlaydesc = @sprites["overlaydesc"].bitmap
    overlaydesc.clear
    base = Color.new(0, 0, 0)
    shadow = Color.new(248, 248, 248)
    # Write the title text
    textpos = [
      [_INTL("Teach which move?"), 4, 2, :left, base, shadow]
    ]
    imagepos = []
    yPos = 60
    VISIBLEMOVES.times do |i|
      moveobject = @moves[@sprites["commands"].top_item + i]
      if moveobject
        moveData = GameData::Move.get(moveobject)
        type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 32, yPos + 16, 0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE])
        textpos.push([moveData.name, 4, yPos, :left, base, shadow])
        if moveData.total_pp > 0
          textpos.push(["ρρ" + " " + moveData.total_pp.to_s + "/" + moveData.total_pp.to_s, Graphics.width, yPos + 16, :right,
                        base, shadow])
        else
          textpos.push(["ρρ --", Graphics.width, yPos + 16, :right, base, shadow])
        end
      end
      yPos += 36
    end
    imagepos.push(["Graphics/UI/Move Reminder/cursor",
                   0, 56 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 36),
                   0, 0, Graphics.width, 36])
    selMoveData = GameData::Move.get(@moves[@sprites["commands"].index])
    power = selMoveData.display_damage(@pokemon)
    category = selMoveData.display_category(@pokemon)
    accuracy = selMoveData.display_accuracy(@pokemon)
    textpos.push([_INTL("Categ."), 4, 22, :left, base, shadow])
    textpos.push([_INTL("Power"), 120, 22, :left, base, shadow])
    textpos.push([power <= 1 ? power == 1 ? "???" : "---" : power.to_s, 200, 42, :right,
                  base, shadow])
    textpos.push([_INTL("Accur."), 230, 22, :left, base, shadow])
    textpos.push([accuracy == 0 ? "---" : "#{accuracy}%", 308, 42, :right,
                  base, shadow])
    pbDrawTextPositions(overlay, textpos)
    imagepos.push(["Graphics/UI/category", 28, 42, 0, category * GameData::Move::CATEGORY_ICON_SIZE[1], *GameData::Move::CATEGORY_ICON_SIZE])
    if @sprites["commands"].index < @moves.length - 1
      imagepos.push(["Graphics/UI/Move Reminder/buttons", 143, 163, 0, 0, 16, 16])
    end
    if @sprites["commands"].index > 0
      imagepos.push(["Graphics/UI/Move Reminder/buttons", 161, 163, 16, 0, 16, 16])
    end
    pbDrawImagePositions(overlay, imagepos)
    drawTextEx(overlaydesc, 2, 178, Graphics.width, 5, selMoveData.description,
               base, shadow)
  end

  # Processes the scene
  def pbChooseMove
    oldcmd = -1
    pbActivateWindow(@sprites, "commands") do
      loop do
        oldcmd = @sprites["commands"].index
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["commands"].index != oldcmd
          pbDrawMoveList
        end
        if Input.trigger?(Input::BACK)
          return nil
        elsif Input.trigger?(Input::USE)
          return @moves[@sprites["commands"].index]
        end
      end
    end
  end

  # End the scene here
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end
end

#===============================================================================
# Screen class for handling game logic
#===============================================================================
class MoveRelearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbGetRelearnableMoves(pkmn)
    return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
    moves = []
    pkmn.getMoveList.each do |m|
      next if m[0] > pkmn.level || pkmn.hasMove?(m[1])
      moves.push(m[1]) if !moves.include?(m[1])
    end
    if Settings::MOVE_RELEARNER_CAN_TEACH_MORE_MOVES && pkmn.first_moves
      tmoves = []
      pkmn.first_moves.each do |i|
        tmoves.push(i) if !moves.include?(i) && !pkmn.hasMove?(i)
      end
      moves = tmoves + moves   # List first moves before level-up moves
    end
    return moves | []   # remove duplicates
  end

  def pbStartScreen(pkmn)
    moves = pbGetRelearnableMoves(pkmn)
    @scene.pbStartScene(pkmn, moves)
    loop do
      move = @scene.pbChooseMove
      if move
        if @scene.pbConfirm(_INTL("Teach {1}?", GameData::Move.get(move).name))
          if pbLearnMove(pkmn, move)
            $stats.moves_taught_by_reminder += 1
            @scene.pbEndScene
            return true
          end
        end
      elsif @scene.pbConfirm(_INTL("Give up trying to teach a new move to {1}?", pkmn.name))
        @scene.pbEndScene
        return false
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbRelearnMoveScreen(pkmn)
  retval = true
  pbFadeOutIn do
    scene = MoveRelearner_Scene.new
    screen = MoveRelearnerScreen.new(scene)
    retval = screen.pbStartScreen(pkmn)
  end
  return retval
end
