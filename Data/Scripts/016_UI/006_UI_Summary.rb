#===============================================================================
#
#===============================================================================
class MoveSelectionSprite < Sprite
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport = nil, fifthmove = false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_move")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 0
    self.y = 162 + (self.index * 20)
    self.y -= 10 if @fifthmove
    self.y -= 3 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class RibbonSelectionSprite < MoveSelectionSprite
  def initialize(viewport = nil)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/UI/Summary/cursor_ribbon")
    @frame = 0
    @index = 0
    @preselected = false
    @updating = false
    @spriteVisible = true
    refresh
  end

  def visible=(value)
    super
    @spriteVisible = value if !@updating
  end

  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = ((self.index % 8) * 36)
    self.y = 140 + ((self.index / 8).floor * 36)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end

  def update
    @updating = true
    super
    self.visible = @spriteVisible && @index >= 0 && @index < 16
    @movesel.update
    @updating = false
    refresh
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
  MARK_WIDTH  = 16
  MARK_HEIGHT = 16
  # Colors used for messages in this scene
  RED_TEXT_BASE     = Color.red
  RED_TEXT_SHADOW   = Color.white
  BLACK_TEXT_BASE   = Color.black
  BLACK_TEXT_SHADOW = RED_TEXT_SHADOW

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party, partyindex, inbattle = false)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport2.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = 60
    @sprites["pokemon"].y = 65
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].mirror = true
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(30, 320, @pokemon.item_id, @viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport2)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlaysmall"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSmallFont(@sprites["overlaysmall"].bitmap)
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/arrow_up", 8, 18, 16, 2, @viewport)
    @sprites["uparrow"].x = 296
    @sprites["uparrow"].y = 146
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/arrow_down", 8, 18, 16, 2, @viewport)
    @sprites["downarrow"].x = 296
    @sprites["downarrow"].y = 198
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["markingbg"] = IconSprite.new(76, 92, @viewport2)
    @sprites["markingbg"].setBitmap("Graphics/UI/Summary/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport2)
    @sprites["markingoverlay"].visible = false
    pbSetSmallFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0, 0, @viewport2)
    @sprites["markingsel"].setBitmap("Graphics/UI/Summary/cursor_marking")
    @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
    @sprites["markingsel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"], 2)
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party, partyindex, move_to_learn)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 4
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlaysmall"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSmallFont(@sprites["overlaysmall"].bitmap)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    drawSelectedMove(new_move, @pokemon.moves[0])
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @markingbitmap&.dispose
    @viewport.dispose
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::USE)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"), _INTL("No")])) do
      cmdwindow.z       = @viewport.z + 1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::BACK)
            ret = false
            break
          elsif Input.trigger?(Input::USE) && @sprites["messagebox"].resume
            ret = (cmdwindow.index == 0)
            break
          end
        end
      end
    end
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands, index = 0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) do
      cmdwindow.z = @viewport.z + 1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    end
    return ret
  end

  def drawMarkings(bitmap, x, y)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    markings = @pokemon.markings
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
      markrect.x = i * MARK_WIDTH
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + (i * MARK_WIDTH), y, @markingbitmap.bitmap, markrect)
    end
  end

#===============================================================================
# Information for all pages
#===============================================================================
  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg
      return
    end
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    @sprites["overlaysmall"].bitmap.clear
    dexNumBase = (@pokemon.shiny?) ? Color.gold : BLACK_TEXT_BASE
    # Set background image
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{[page, 6].min}")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 126, 100])
    # Show Pokérus cured icon
    if @pokemon.pokerusStage == 2
      imagepos.push(["Graphics/UI/Summary/icon_pokerus", 160, 104])
    end
    # Show shininess star
    imagepos.push(["Graphics/UI/shiny", 304, 0]) if @pokemon.shiny?
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    textpos = [
      [@pokemon.name, 128, 24, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW],
      [_INTL("/{1}", @pokemon.speciesName), 144, 56, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW],
      [_INTL("Λ{1}",@pokemon.level.to_s), 226, 2, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW]
    ]
    # Write the Regional/National Dex number
    dexnum = 0
    dexnumshift = false
    if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
      dexnum = @nationalDexList.index(@pokemon.species_data.species) || 0
      dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
    else
      ($player.pokedex.dexes_count - 1).times do |i|
        next if !$player.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i, @pokemon.species)
        break if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum <= 0
      textpos.push(["???", 128, 2, :left, dexNumBase, BLACK_TEXT_SHADOW])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("Ν %03d", dexnum), 128, 2, :left, dexNumBase, BLACK_TEXT_SHADOW])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"), 288, 2, :left, Color.blue, BLACK_TEXT_SHADOW])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"), 288, 2, :left, RED_TEXT_BASE, RED_TEXT_SHADOW])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 188, 76)
    # Draw page-specific information
    case page
    when 1 then drawPageOne
    when 2 then drawPageTwo
    when 3 then drawPageThree
    when 4 then drawPageFour
    when 5 then drawPageFive
    when 6 then drawPageSix
    when 7 then drawPageSeven
    end
  end

#===============================================================================
# Page One: Pokémon general information
#===============================================================================
  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    # Variable which stores the Pokémon next level
    if @pokemon.level < 100
      nextlevel = @pokemon.level + 1
    else
      nextlevel = 100
    end
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
      imagepos = [
        ["Graphics/UI/Summary/overlay_shadow", 154, 254],
        ["Graphics/UI/Summary/overlay_shadowbar", 154, 254, 0, 0, (shadowfract * 248).floor, -1]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    imagepos = []
    # Show status/fainted/Pokérus infected icon
    status = -1
    if @pokemon.fainted?
      status = GameData::Status.count - 1
    elsif @pokemon.status != :NONE
      status = GameData::Status.get(@pokemon.status).icon_position
    elsif @pokemon.pokerusStage == 1
      status = GameData::Status.count
    end
    if status >= 0
      imagepos.push(["Graphics/UI/statuses", 96, 208, :left, status * GameData::Status::ICON_SIZE[1], *GameData::Status::ICON_SIZE])      
    end
    # Write various bits of text
    textpos = [
      [sprintf("%d/ %d", @pokemon.hp, @pokemon.totalhp), 124, 130, :right, BLACK_TEXT_BASE],
      [_INTL("Status/"), 0, 176, :left, BLACK_TEXT_BASE],
      [_INTL("Type/"), 0, 208, :left, BLACK_TEXT_BASE],
      [_INTL("OT/"), 0, 240, :left, BLACK_TEXT_BASE],
      [_INTL("ΙΝ"), 0, 272, :left, BLACK_TEXT_BASE]
    ]
    # No status condition
    if @pokemon.status == :NONE
      textpos.push([_INTL("OK"), 96, 192, :left, BLACK_TEXT_BASE])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.owner.name.empty?
      textpos.push([_INTL("RENTAL"), 16, 256, :left, BLACK_TEXT_BASE])
      textpos.push(["?????", 48, 272, :left, BLACK_TEXT_BASE])
    else
      textpos.push([@pokemon.owner.name, 16, 256, :left, BLACK_TEXT_BASE])
      textpos.push([sprintf("%05d", @pokemon.owner.public_id), 48, 272, :left, BLACK_TEXT_BASE])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      textpos.push([_INTL("Heart Gauge"), 152, 128, :left, BLACK_TEXT_BASE])
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      heartmessage = [_INTL("Heart open! Undo the final lock!"),
                      _INTL("Its heart is almost fully open."),
                      _INTL("Its heart is nearly open."),
                      _INTL("Its heart is opening wider."),
                      _INTL("The door to its heart is opening up."),
                      _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      memo = black_text_tag + heartmessage
      drawFormattedTextEx(overlay, 160, 167, 160, memo)
    else
      endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
      textpos.push([_INTL("Exp. Points"), 160, 144, :left, BLACK_TEXT_BASE])
      textpos.push([@pokemon.exp.to_s_formatted, 320, 160, :right, BLACK_TEXT_BASE])
      textpos.push([_INTL("Level Up"), 160, 192, :left, BLACK_TEXT_BASE])
      textpos.push([(endexp - @pokemon.exp).to_s_formatted, 320, 208, :right, BLACK_TEXT_BASE])
      textpos.push([_INTL("to Λ{1}", nextlevel), 226, 226, :left, BLACK_TEXT_BASE])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon type(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE)
      type_x = (@pokemon.types.length == 1) ? 16 : 16 + (GameData::Type::ICON_SIZE[0] * i)
      overlay.blt(type_x, 225, @typebitmap.bitmap, type_rect)
    end
    # Draw HP bar
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      pbDrawImagePositions(overlay,
                          [["Graphics/UI/Summary/overlay_hp", 32, 150, 0, hpzone * 4, w, 4]])
    end
    # Draw Exp bar
    if @pokemon.level < GameData::GrowthRate.max_level
      w = @pokemon.exp_fraction * 128
      w = ((w / 2).round) * 2
      pbDrawImagePositions(overlay,
                           [["Graphics/UI/Summary/overlay_exp", 176, 262, 0, 0, w, 4]])
    end
  end

#===============================================================================
# Egg Page
#===============================================================================
  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item_id
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Set background image
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_egg")
    # Write various bits of text
    textpos = [
      [_INTL("Egg"), 128, 0, :left, BLACK_TEXT_BASE],
      [_INTL("?????"), 176, 30, :left, BLACK_TEXT_BASE],
      [_INTL("OT/"), 128, 64, :left, BLACK_TEXT_BASE],
      [_INTL("?????"), 176, 64, :left, BLACK_TEXT_BASE]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Write Egg Watch blurb
    eggstate = _INTL("This Egg needs a lot more time to hatch.")
    eggstate = _INTL("Wonder what's inside? It needs more time, though.") if @pokemon.steps_to_hatch < 10_200
    eggstate = _INTL("It moves around inside sometimes. It must be close to hatching.") if @pokemon.steps_to_hatch < 2550
    eggstate = _INTL("It's making sounds inside. It's going to hatch soon!") if @pokemon.steps_to_hatch < 1275
    # Draw all text
    drawFormattedTextEx(overlay, 16, 136, 288, eggstate)
    # Draw the Pokémon's markings
    drawMarkings(overlay, 188, 76)
  end

#===============================================================================
# Page Two: Moves
#===============================================================================
  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    textpos  = [
      [_INTL("Moves/"), 2, 128, :left, BLACK_TEXT_BASE],
      [_INTL("C → Info"), 320, 128, :right, BLACK_TEXT_BASE]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 152
    Pokemon::MAX_MOVES.times do |i|
      move = @pokemon.moves[i]
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 122, yPos + 17, 0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE])
        textpos.push([move.name, 2, yPos, :left, BLACK_TEXT_BASE])
        if move.total_pp > 0
          textpos.push([_INTL("ρρ"), 192, yPos + 16, :left, BLACK_TEXT_BASE])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 320, yPos + 16, :right, BLACK_TEXT_BASE])
        end
      else
        textpos.push(["-", 130, yPos, :left, BLACK_TEXT_BASE])
        textpos.push(["--", 194, yPos + 16, :right, BLACK_TEXT_BASE])
      end
      yPos += 32
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
  end

#===============================================================================
# Page Two: Move Selection
#===============================================================================
  def drawPageTwoSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_2_move")
    end
    # Write various bits of text
    textpos = [
      [_INTL("Categ."), 8, 253, :left, BLACK_TEXT_BASE],
      [_INTL("Power"), 120, 253, :left, BLACK_TEXT_BASE],
      [_INTL("Accur."), 230, 253, :left, BLACK_TEXT_BASE]
    ]
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 164
    yPos -= 10 if move_to_learn
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    limit.times do |i|
      move = @pokemon.moves[i]
      if i == Pokemon::MAX_MOVES
        move = move_to_learn
        yPos -= 3
      end
      if move
        # Type icon
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), 40, 272, 0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE])
        # Move name
        textpos.push([move.name, 2, yPos, :left, BLACK_TEXT_BASE])
        # PP left
        textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 320, yPos, :right, BLACK_TEXT_BASE])
      else
        textpos.push(["-", 2, yPos, :left, BLACK_TEXT_BASE])
        textpos.push(["--", 320, yPos, :right, BLACK_TEXT_BASE])
      end
      yPos += 20
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
  end

#===============================================================================
# Selection move when a Pokémon wants to learn a new one
#===============================================================================
  def drawSelectedMove(move_to_learn, selected_move)
    overlay = @sprites["overlay"].bitmap
    small_overlay = @sprites["overlaysmall"].bitmap
    overlay.clear
    small_overlay.clear
    # Draw all of page two, except selected move's details
    drawPageTwoSelecting(move_to_learn)
    # Set various values
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    textpos = []
    # Write power and accuracy values for selected move
    case selected_move.display_damage(@pokemon)
    when 0 then textpos.push(["---", 200, 272, :right, BLACK_TEXT_BASE])   # Status move
    when 1 then textpos.push(["???", 200, 272, :right, BLACK_TEXT_BASE])   # Variable power move
    else        textpos.push([selected_move.display_damage(@pokemon).to_s, 200, 272, :right, BLACK_TEXT_BASE])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 308, 272, :right, BLACK_TEXT_BASE])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 294 + overlay.text_size("%").width, 272, :right, BLACK_TEXT_BASE])
    end
    # Contest toggle hint (top-right, above move list)
    @show_contest ||= false
    hint = @show_contest ? _INTL("> Move Info") : _INTL("> Contest")
    textpos.push([hint, Graphics.width - 2, 128, :right, Color.new(160, 160, 160)])
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/UI/category", 8, 272, 0, selected_move.display_category(@pokemon) * GameData::Move::CATEGORY_ICON_SIZE[1], *GameData::Move::CATEGORY_ICON_SIZE]]
    # Draw selected move's type icon
    type_number = GameData::Type.get(selected_move.display_type(@pokemon)).icon_position
    imagepos.push([_INTL("Graphics/UI/types"), 40, 272, 0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE])
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description or contest stats
    if @show_contest
      _draw_contest_info(small_overlay, selected_move)
    else
      drawTextEx(small_overlay, 2, 0, 318, 5, selected_move.description, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
    end
  end

  def _draw_contest_info(bmp, move)
    type_sym, appeal, jam = ContestData.for(move.id)
    unless type_sym && appeal > 0
      drawTextEx(bmp, 2, 0, 318, 3, _INTL("No contest effect."), BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      return
    end
    type_name  = type_sym.to_s.capitalize
    type_color = case type_sym
                 when :COOL   then Color.new(100, 140, 255)
                 when :BEAUTY then Color.new(255, 100, 180)
                 when :CUTE   then Color.new(255, 180, 210)
                 when :SMART  then Color.new(100, 200, 100)
                 when :TOUGH  then Color.new(200, 110, 40)
                 else BLACK_TEXT_BASE
                 end
    drawTextEx(bmp, 2,  0, 318, 1, _INTL("Contest / {1}", type_name), type_color, BLACK_TEXT_SHADOW)
    jam_text = jam.to_s
    drawTextEx(bmp, 2, 18, 318, 1, _INTL("Appeal: {1}   Jam: {2}", appeal.to_s, jam_text), BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
  end

#===============================================================================
# Page Three: Item, nature and stats
#===============================================================================
  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    # Nature color variables
    increase = Color.red  # Red
    decrease = Color.blue # Blue
    # Held item's name
    if @pokemon.hasItem?
      item_name = @pokemon.item.name
    else
      item_name = "---"
    end 
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statsbase = {}
    GameData::Stat.each_main { |s| statsbase[s.id] = BLACK_TEXT_BASE }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statsbase[change[0]] = increase if change[1] > 0
        statsbase[change[0]] = decrease if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
      # Item
      [_INTL("Item/ {1}", item_name), 2, 128, :left, BLACK_TEXT_BASE],
      # Nature
      [_INTL("Nature/ {1}", @pokemon.nature.name), 2, 152, :left, BLACK_TEXT_BASE],
      # Stats text
      [_INTL("STAT"), 144, 176, :left, BLACK_TEXT_BASE],
      [_INTL("IV"), 244, 176, :left, BLACK_TEXT_BASE],
      [_INTL("EV"), 320, 176, :right, BLACK_TEXT_BASE],
      # Stats
      ## HP
      [_INTL("HP"), 2, 192, :left, statsbase[:HP]],
      [sprintf("%d", @pokemon.totalhp), 160, 192, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:HP]), 240, 192, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:HP]), 320, 192, :right, BLACK_TEXT_BASE],
      ## Attack
      [_INTL("Attack"), 2, 208, :left, statsbase[:ATTACK]],
      [sprintf("%d", @pokemon.attack), 160, 208, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:ATTACK]), 240, 208, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:ATTACK]), 320, 208, :right, BLACK_TEXT_BASE],
      ## Defense
      [_INTL("Defense"), 2, 224, :left, statsbase[:DEFENSE]],
      [sprintf("%d", @pokemon.defense), 160, 224, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:DEFENSE]), 240, 224, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:DEFENSE]), 320, 224, :right, BLACK_TEXT_BASE],
      ## Special Attack
      [_INTL("Spcl. Atk"), 2, 240, :left, statsbase[:SPECIAL_ATTACK]],
      [sprintf("%d", @pokemon.spatk), 160, 240, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), 240, 240, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), 320, 240, :right, BLACK_TEXT_BASE],
      ## Special Defense
      [_INTL("Spcl. Def"), 2, 256, :left, statsbase[:SPECIAL_DEFENSE]],
      [sprintf("%d", @pokemon.spdef), 160, 256, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), 240, 256, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), 320, 256, :right, BLACK_TEXT_BASE],
      ## Speed
      [_INTL("Speed"), 2, 272, :left, statsbase[:SPEED]],
      [sprintf("%d", @pokemon.speed), 160, 272, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.iv[:SPEED]), 240, 272, :left, BLACK_TEXT_BASE],
      [sprintf("%d", @pokemon.ev[:SPEED]), 320, 272, :right, BLACK_TEXT_BASE]
    ]
    # Checks the Pokémon's nature to draw increase or decrease arrows
    #==============================================
      # Increase arrow (red color)
      
      # Attack up
      if @pokemon.nature == :ADAMANT || @pokemon.nature == :NAUGHTY || @pokemon.nature == :LONELY || @pokemon.nature == :BRAVE
        textpos.push([_INTL("↑"), 144, 208, :left, increase])
        # Defense up
      elsif @pokemon.nature == :BOLD || @pokemon.nature == :IMPISH || @pokemon.nature == :LAX || @pokemon.nature == :RELAXED
        textpos.push([_INTL("↑"), 144, 224, :left, increase])
        # Spcl. Atk up
      elsif @pokemon.nature == :MODEST || @pokemon.nature == :MILD || @pokemon.nature == :RASH || @pokemon.nature == :QUIET
        textpos.push([_INTL("↑"), 144 , 240 , :left, increase])
        # Spcl. Def up
      elsif @pokemon.nature == :CALM || @pokemon.nature == :GENTLE || @pokemon.nature == :CAREFUL || @pokemon.nature == :SASSY
        textpos.push([_INTL("↑"), 144 , 256, :left, increase])
        # Speed up
      elsif @pokemon.nature == :TIMID || @pokemon.nature == :HASTY || @pokemon.nature == :JOLLY || @pokemon.nature == :NAIVE
        textpos.push([_INTL("↑"), 144, 272, :left, increase])
      end
      
      #==============================================
      # Decrease arrow (blue color)
      
      # Attack down
      if @pokemon.nature == :BOLD || @pokemon.nature == :MODEST || @pokemon.nature == :CALM || @pokemon.nature == :TIMID
        textpos.push([_INTL("↓"), 144, 208, :left, decrease])
        # Defense down
      elsif @pokemon.nature == :LONELY || @pokemon.nature == :MILD || @pokemon.nature == :GENTLE || @pokemon.nature == :HASTY
        textpos.push([_INTL("↓"), 144, 224, :left, decrease])
        # Spcl. Atk down
      elsif @pokemon.nature == :ADAMANT || @pokemon.nature == :IMPISH || @pokemon.nature == :CAREFUL || @pokemon.nature == :JOLLY
        textpos.push([_INTL("↓"), 144, 240, :left, decrease])
        # Spcl. Def down
      elsif @pokemon.nature == :NAUGHTY || @pokemon.nature == :LAX || @pokemon.nature == :RASH || @pokemon.nature == :NAIVE
        textpos.push([_INTL("↓"), 144, 256, :left, decrease])
        # Speed down
      elsif @pokemon.nature == :BRAVE || @pokemon.nature == :RELAXED || @pokemon.nature == :QUIET || @pokemon.nature == :SASSY
        textpos.push([_INTL("↓"), 144, 272, :left, decrease])
      end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

#===============================================================================
# Page Four: Ability 
#===============================================================================
  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    ability = @pokemon.ability
    index = @pokemon.ability_index
    ability_page_shadow_color = Color.new(248, 248, 248, 0)
    case index 
      when 0 then abtext = "1"
      when 1 then abtext = "2"
      else
        abtext = "Hidden"
      end
    # Draw ability name and description
    textpos = [
      [_INTL("Ability/{1}", abtext), 2, 128, :left, BLACK_TEXT_BASE],
      [ability.name, 320, 140, :right, BLACK_TEXT_BASE]
    ]
    drawTextEx(overlay, 2, 160, 318, 4, ability.description, BLACK_TEXT_BASE, ability_page_shadow_color)
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

#===============================================================================
# Page Five: Other data (trainer memo, happiness, hidden power)
#===============================================================================
  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    # Write characteristic
    best_stat = nil
    best_iv = 0
    stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
    start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
    stats_order.length.times do |i|
      stat = stats_order[(i + start_point) % stats_order.length]
      if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
        best_stat = stat
        best_iv = @pokemon.iv[best_stat]
      end
    end
    characteristics = {
      :HP              => [_INTL("Loves to eat."),
                         _INTL("Takes plenty of siestas."),
                         _INTL("Nods off a lot."),
                         _INTL("Scatters things often."),
                         _INTL("Likes to relax.")],
      :ATTACK          => [_INTL("Proud of its power."),
                         _INTL("Likes to thrash about."),
                         _INTL("A little quick tempered."),
                         _INTL("Likes to fight."),
                         _INTL("Quick tempered.")],
      :DEFENSE         => [_INTL("Sturdy body."),
                         _INTL("Capable of taking hits."),
                         _INTL("Highly persistent."),
                         _INTL("Good endurance."),
                         _INTL("Good perseverance.")],
      :SPECIAL_ATTACK  => [_INTL("Highly curious."),
                         _INTL("Mischievous."),
                         _INTL("Thoroughly cunning."),
                         _INTL("Often lost in thought."),
                         _INTL("Very finicky.")],
      :SPECIAL_DEFENSE => [_INTL("Strong willed."),
                         _INTL("Somewhat vain."),
                         _INTL("Strongly defiant."),
                         _INTL("Hates to lose."),
                         _INTL("Somewhat stubborn.")],
      :SPEED           => [_INTL("Likes to run."),
                         _INTL("Alert to sounds."),
                         _INTL("Impetuous and silly."),
                         _INTL("Somewhat of a clown."),
                         _INTL("Quick to flee.")]
    }
    # Obtain methods
    case @pokemon.obtain_method
      when 0 then obtain_text = "Met"
      when 1 then obtain_text = "Egg"
      when 2 then obtain_text = "Trade"
      when 4 then obtain_text = "Fateful encounter"
    end
    # Obtain map variables
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = pbGetMapNameFromId(@pokemon.hatched_map) if @pokemon.obtain_method == 1 # Egg hatched
    # Hidden Power variable
    hiddenpower = pbHiddenPower(@pokemon)
    
    # Write various bits of text
    textpos = [
      [_INTL("{1} at Λ{2}", obtain_text, @pokemon.obtain_level), 2, 128, :left, BLACK_TEXT_BASE],
      [_INTL("Place/"), 2, 146, :left, BLACK_TEXT_BASE],
      [_INTL("{1}", mapname), 16, 164, :left, BLACK_TEXT_BASE],
      [_INTL("Personality/"), 2, 186, :left, BLACK_TEXT_BASE],
      [_INTL("{1}", characteristics[best_stat][best_iv % 5]), 16, 204, :left, BLACK_TEXT_BASE],
      [_INTL("Other data/"), 2, 234, :left, BLACK_TEXT_BASE],
      [_INTL("Happiness → {1}", @pokemon.happiness), 16, 252, :left, BLACK_TEXT_BASE],
      [_INTL("Hidden Power → {1}", GameData::Type.get(hiddenpower[0]).name), 16, 270, :left, BLACK_TEXT_BASE]
    ]
    
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end


#===============================================================================
# Page six: Ribbons
#===============================================================================
  def drawPageSix
    overlay = @sprites["overlay"].bitmap
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
    # Write various bits of text
    textpos = [
      [_INTL("No. of Ribbons: {1}", @pokemon.numRibbons.to_s), 2, 128, :left, BLACK_TEXT_BASE]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Show all ribbons
    imagepos = []
    coord = 0
    (@ribbonOffset * 8...(@ribbonOffset * 8) + 16).each do |i|
      break if !@pokemon.ribbons[i]
      ribbon_data = GameData::Ribbon.get(@pokemon.ribbons[i])
      ribn = ribbon_data.icon_position
      imagepos.push(["Graphics/UI/Summary/ribbons",
                     6 + (36 * (coord % 8)), 146 + (36 * (coord / 8).floor),
                     32 * (ribn % 8), (32 * (ribn / 8).floor), 32, 32])
      coord += 1
    end
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPageSeven
    overlay = @sprites["overlay"].bitmap
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false

    # Match page 3 coordinate system: content runs x=2..~290, y=128..~272
    label_x = 2
    bar_x   = 76
    bar_w   = 174
    bar_h   = 10
    val_x   = 256
    row_h   = 20    # tighter spacing so all 6 rows fit on screen

    all_rows = [
      [_INTL("Cool"),   @pokemon.cool.to_i,   Color.new(60,  160, 220)],
      [_INTL("Beauty"), @pokemon.beauty.to_i, Color.new(230, 100, 170)],
      [_INTL("Cute"),   @pokemon.cute.to_i,   Color.new(240, 140, 140)],
      [_INTL("Smart"),  @pokemon.smart.to_i,  Color.new(80,  190, 100)],
      [_INTL("Tough"),  @pokemon.tough.to_i,  Color.new(210, 100,  60)],
      [_INTL("Sheen"),  @pokemon.sheen.to_i,  Color.new(200, 200, 200)]
    ]

    textpos = [[_INTL("Contest Conditions"), label_x, 128, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW]]

    all_rows.each_with_index do |(label, val, color), i|
      row_y  = 148 + i * row_h
      bar_y  = row_y + 4
      filled = (val * bar_w / 255.0).round

      textpos.push([label,    label_x, row_y, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW])
      textpos.push([val.to_s, val_x,   row_y, :left, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW])

      overlay.fill_rect(bar_x, bar_y, bar_w, bar_h, Color.new(180, 180, 180))
      overlay.fill_rect(bar_x, bar_y, filled, bar_h, color) if filled > 0
    end

    pbDrawTextPositions(overlay, textpos)
  end

  def drawSelectedRibbon(ribbonid)
    # Draw all of page six
    drawPage(6)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    small_overlay = @sprites["overlaysmall"].bitmap
    small_overlay.clear
    # Get data for selected ribbon
    name = ribbonid ? GameData::Ribbon.get(ribbonid).name : ""
    desc = ribbonid ? GameData::Ribbon.get(ribbonid).description : ""
    # Draw the description box
    imagepos = [
      ["Graphics/UI/Summary/overlay_ribbon", 0, 220]
    ]
    pbDrawImagePositions(overlay, imagepos)
    # Draw name of selected ribbon
    textpos = [
      [name, Graphics.width / 2, 226, :center, BLACK_TEXT_BASE]
    ]
    pbDrawTextPositions(overlay, textpos)
    # Draw selected ribbon's description
    drawFormattedTextEx(small_overlay, 2, 246, Graphics.width - 2, desc, BLACK_TEXT_BASE, BLACK_TEXT_SHADOW, 16)
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex > 0
      newindex -= 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex < @party.length - 1
      newindex += 1
      if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    @pokemon = @party[@partyindex]
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["itemicon"].item = @pokemon.item_id
    pbSEStop
    @pokemon.play_cry
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching  = false
    @show_contest = false
    drawSelectedMove(nil, @pokemon.moves[selmove])
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index == @sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z + 1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        if selmove == Pokemon::MAX_MOVES
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        elsif !@pokemon.shadowPokemon?
          if switching
            tmpmove                    = @pokemon.moves[oldselmove]
            @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
            @pokemon.moves[selmove]    = tmpmove
            @sprites["movepresel"].visible = false
            switching = false
            drawSelectedMove(nil, @pokemon.moves[selmove])
          else
            @sprites["movepresel"].index   = selmove
            @sprites["movepresel"].visible = true
            oldselmove = selmove
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = @pokemon.numMoves - 1 if selmove < 0
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
        selmove = 0 if selmove >= Pokemon::MAX_MOVES
        selmove = Pokemon::MAX_MOVES if selmove < 0
        @sprites["movesel"].index = selmove
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      elsif (Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)) &&
            selmove < @pokemon.numMoves && !switching
        @show_contest = !@show_contest
        pbPlayCursorSE
        drawSelectedMove(nil, @pokemon.moves[selmove])
      end
    end
    @sprites["movesel"].visible = false
  end

  def pbRibbonSelection
    @sprites["ribbonsel"].visible = true
    @sprites["ribbonsel"].index   = 0
    selribbon    = @ribbonOffset * 8
    oldselribbon = selribbon
    switching = false
    numRibbons = @pokemon.ribbons.length
    numRows    = [((numRibbons + 7) / 8).floor, 2].max
    drawSelectedRibbon(@pokemon.ribbons[selribbon])
    loop do
      @sprites["uparrow"].visible   = (@ribbonOffset > 0)
      @sprites["downarrow"].visible = (@ribbonOffset < numRows - 2)
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["ribbonpresel"].index == @sprites["ribbonsel"].index
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z + 1
      else
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
      end
      hasMovedCursor = false
      if Input.trigger?(Input::BACK)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["ribbonpresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::USE)
        if switching
          pbPlayDecisionSE
          tmpribbon                      = @pokemon.ribbons[oldselribbon]
          @pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
          @pokemon.ribbons[selribbon]    = tmpribbon
          if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
            @pokemon.ribbons.compact!
            if selribbon >= numRibbons
              selribbon = numRibbons - 1
              hasMovedCursor = true
            end
          end
          @sprites["ribbonpresel"].visible = false
          switching = false
          drawSelectedRibbon(@pokemon.ribbons[selribbon])
        else
          if @pokemon.ribbons[selribbon]
            pbPlayDecisionSE
            @sprites["ribbonpresel"].index = selribbon - (@ribbonOffset * 8)
            oldselribbon = selribbon
            @sprites["ribbonpresel"].visible = true
            switching = true
          end
        end
      elsif Input.trigger?(Input::UP)
        selribbon -= 8
        selribbon += numRows * 8 if selribbon < 0
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        selribbon += 8
        selribbon -= numRows * 8 if selribbon >= numRows * 8
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        selribbon -= 1
        selribbon += 8 if selribbon % 8 == 7
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        selribbon += 1
        selribbon -= 8 if selribbon % 8 == 0
        hasMovedCursor = true
        pbPlayCursorSE
      end
      next if !hasMovedCursor
      @ribbonOffset = (selribbon / 8).floor if selribbon < @ribbonOffset * 8
      @ribbonOffset = (selribbon / 8).floor - 1 if selribbon >= (@ribbonOffset + 2) * 8
      @ribbonOffset = 0 if @ribbonOffset < 0
      @ribbonOffset = numRows - 2 if @ribbonOffset > numRows - 2
      @sprites["ribbonsel"].index    = selribbon - (@ribbonOffset * 8)
      @sprites["ribbonpresel"].index = oldselribbon - (@ribbonOffset * 8)
      drawSelectedRibbon(@pokemon.ribbons[selribbon])
    end
    @sprites["ribbonsel"].visible = false
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base   = Color.new(0, 0, 0)
    shadow = Color.new(248, 248, 248)
    ret = pokemon.markings.clone
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(105 + (48 * (i % 3)), 115 + (44 * (i / 3)),
                                                @markingbitmap.bitmap, markrect)
        end
        textpos = [
          [_INTL("OK"), Graphics.width / 2 + 1, 204, :center, base, shadow],
          [_INTL("Cancel"), Graphics.width / 2 + 1, 248, :center, base, shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 94 + (48 * (index % 3))
      @sprites["markingsel"].y = 106 + (44 * (index / 3))
      case index
      when 6   # OK
        @sprites["markingsel"].x = 93
        @sprites["markingsel"].y = 194
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      when 7   # Cancel
        @sprites["markingsel"].x = 93
        @sprites["markingsel"].y = 238
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      else
        @sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          ret = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      elsif Input.trigger?(Input::ACTION)
        if index < 6 && markings[index] > 0
          pbPlayDecisionSE
          markings[index] = 0
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index == 7
          index = 6
        elsif index == 6
          index = 4
        elsif index < 3
          index = 7
        else
          index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index == 7
          index = 1
        elsif index == 6
          index = 7
        elsif index >= 3
          index = 6
        else
          index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index < 6
          index -= 1
          index += 3 if index % 3 == 2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index < 6
          index += 1
          index -= 3 if index % 3 == 0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings != ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbOptions
    dorefresh = false
    commands = []
    cmdGiveItem   = -1
    cmdTakeItem   = -1
    cmdNickname   = -1
    cmdPokedex    = -1
    cmdMark       = -1
    cmdRecolor    = -1
    cmdCheckMoves = -1
    cmdLearnMoves = -1
    cmdForgetMove = -1
    cmdTeachTMs   = -1
    case @page
    when 4
      commands[cmdCheckMoves = commands.length] = _INTL("Check Moves") if !@pokemon.moves.empty?
      commands[cmdLearnMoves = commands.length] = _INTL("Remember Moves") if @pokemon.can_relearn_move?
      commands[cmdForgetMove = commands.length] = _INTL("Forget Moves") if @pokemon.moves.length > 1
      commands[cmdTeachTMs   = commands.length] = _INTL("Use TM's")
    else
      if !@pokemon.egg?
        commands[cmdGiveItem = commands.length] = _INTL("Give item")
        commands[cmdTakeItem = commands.length] = _INTL("Take item") if @pokemon.hasItem?
        commands[cmdNickname = commands.length] = _INTL("Nickname") if !@pokemon.foreign?
        commands[cmdPokedex  = commands.length] = _INTL("View Pokédex") if $player.has_pokedex
        commands[cmdRecolor  = commands.length] = _INTL("Recolor")
      end
      commands[cmdMark = commands.length] = _INTL("Mark")
    end
    commands[commands.length] = _INTL("Cancel")
    command = pbShowCommands(commands)
    if cmdGiveItem >= 0 && command == cmdGiveItem
      item = nil
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbChooseItemScreen(proc { |itm| GameData::Item.get(itm).can_hold? })
      end
      dorefresh = pbGiveItemToPokemon(item, @pokemon, self, @partyindex) if item
    elsif cmdTakeItem >= 0 && command == cmdTakeItem
      dorefresh = pbTakeItemFromPokemon(@pokemon, self)
    elsif cmdNickname >= 0 && command == cmdNickname
      nickname = pbEnterPokemonName(_INTL("{1}'s nickname?", @pokemon.name), 0, Pokemon::MAX_NAME_SIZE, "", @pokemon, true)
      @pokemon.name = nickname
      dorefresh = true
    elsif cmdPokedex >= 0 && command == cmdPokedex
      $player.pokedex.register_last_seen(@pokemon)
      pbFadeOutIn do
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbStartSceneSingle(@pokemon.species)
      end
      dorefresh = true
    elsif cmdRecolor >= 0 && command == cmdRecolor
      pbPokemonRecolor(@pokemon)
      dorefresh = true
    elsif cmdMark >= 0 && command == cmdMark
      dorefresh = pbMarking(@pokemon)
    elsif cmdCheckMoves >= 0 && command == cmdCheckMoves
      pbPlayDecisionSE
      pbMoveSelection
      dorefresh = true
    elsif cmdLearnMoves >= 0 && command == cmdLearnMoves
      pbRelearnMoveScreen(@pokemon)
      dorefresh = true
    elsif cmdForgetMove >= 0 && command == cmdForgetMove
      move_index = pbForgetMove(@pokemon, nil)
      if move_index >= 0
        old_move_name = @pokemon.moves[move_index].name
        pbMessage(_INTL("{1} forgot how to use {2}.", @pokemon.name, old_move_name))
        @pokemon.forget_move_at_index(move_index)
        dorefresh = true
      end
    elsif cmdTeachTMs >= 0 && command == cmdTeachTMs
      item = nil
      pbFadeOutIn {
        scene  = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbChooseItemScreen(Proc.new{ |itm|
          move = GameData::Item.get(itm).move  
          next false if !move || @pokemon.hasMove?(move) || !@pokemon.compatible_with_move?(move)
          next true
        })
      }
      if item
        pbUseItemOnPokemon(item, @pokemon, self)
        dorefresh = true
      end
    end
    return dorefresh
  end

  def pbChooseMoveToForget(move_to_learn)
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    selmove = 0
    maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        selmove = Pokemon::MAX_MOVES
        pbPlayCloseMenuSE if new_move
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove > maxmove
        if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
          selmove = (new_move) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
        drawSelectedMove(new_move, selected_move)
      end
    end
    return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
  end

  def pbScene
    @pokemon.play_cry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
        @pokemon.play_cry
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @page == 2
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif @page == 6
          pbPlayDecisionSE
          pbRibbonSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        else
          break
        end
      elsif Input.trigger?(Input::UP) && @partyindex > 0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex < @party.length - 1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 7 if @page < 1
        @page = 1 if @page > 7
        if @page != oldpage   # Move to next page
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 7 if @page < 1
        @page = 1 if @page > 7
        if @page != oldpage   # Move to next page
          @ribbonOffset = 0
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @partyindex
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummaryScreen
  def initialize(scene, inbattle = false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party, partyindex)
    @scene.pbStartScene(party, partyindex, @inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party, partyindex, move_to_learn)
    ret = -1
    @scene.pbStartForgetScene(party, partyindex, move_to_learn)
    loop do
      ret = @scene.pbChooseMoveToForget(move_to_learn)
      break if ret < 0 || !move_to_learn
      break if $DEBUG || !party[partyindex].moves[ret].hidden_move?
      pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party, partyindex, message)
    ret = -1
    @scene.pbStartForgetScene(party, partyindex, nil)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(nil)
      break if ret >= 0
      pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
    end
    @scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbChooseMove(pokemon, variableNumber, nameVarNumber)
  return if !pokemon
  ret = -1
  pbFadeOutIn do
    scene = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    ret = screen.pbStartForgetScreen([pokemon], 0, nil)
  end
  $game_variables[variableNumber] = ret
  if ret >= 0
    $game_variables[nameVarNumber] = pokemon.moves[ret].name
  else
    $game_variables[nameVarNumber] = ""
  end
  $game_map.need_refresh = true if $game_map
end
