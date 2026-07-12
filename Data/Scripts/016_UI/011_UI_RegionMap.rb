#===============================================================================
#
#===============================================================================
class MapBottomSprite < Sprite
  attr_reader :mapname, :maplocation

  def initialize(viewport = nil)
    super(viewport)
    @mapname     = ""
    @maplocation = ""
    @mapdetails  = ""
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def mapname=(value)
    return if @mapname == value
    @mapname = value
    refresh
  end

  def maplocation=(value)
    return if @maplocation == value
    @maplocation = value
    refresh
  end

  # From Wichu
  def mapdetails=(value)
    return if @mapdetails == value
    @mapdetails = value
    refresh
  end

  def refresh
    bitmap.clear
    textpos = []
    pbDrawTextPositions(bitmap, textpos)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonRegionMap_Scene
  LEFT          = 0
  TOP           = 0
  RIGHT         = 29
  BOTTOM        = 19
  SQUARE_WIDTH  = 16
  SQUARE_HEIGHT = 16

  def initialize(region = - 1, wallmap = true)
    @region  = region
    @wallmap = wallmap
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(as_editor = false, fly_map = false)
    @editor   = as_editor
    @baseColor   = Color.new(0, 0, 0)
    @shadowColor = Color.new(248, 248, 248, 0)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @fly_map = fly_map
    @mode    = fly_map ? 1 : 0
    map_metadata = $game_map.metadata
    playerpos = (map_metadata) ? map_metadata.town_map_position : nil
    if !playerpos
      mapindex = 0
      @map     = GameData::TownMap.get(0)
      @map_x   = LEFT
      @map_y   = TOP
    elsif @region >= 0 && @region != playerpos[0] && GameData::TownMap.exists?(@region)
      mapindex = @region
      @map     = GameData::TownMap.get(@region)
      @map_x   = LEFT
      @map_y   = TOP
    else
      mapindex = playerpos[0]
      @map     = GameData::TownMap.get(playerpos[0])
      @map_x   = playerpos[1]
      @map_y   = playerpos[2]
      mapsize  = map_metadata.town_map_size
      if mapsize && mapsize[0] && mapsize[0] > 0
        sqwidth  = mapsize[0]
        sqheight = (mapsize[1].length.to_f / mapsize[0]).ceil
        @map_x += ($game_player.x * sqwidth / $game_map.width).floor if sqwidth > 1
        @map_y += ($game_player.y * sqheight / $game_map.height).floor if sqheight > 1
      end
    end
    if !@map
      pbMessage(_INTL("The map data cannot be found."))
      return false
    end
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @helpwindow = @sprites["helpwindow"]
    @helpwindow.viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], 2)
    @helpwindow.width = Graphics.width
    @helpwindow.text = _INTL("")
    @helpwindow.baseColor = @baseColor
    @helpwindow.shadowColor = @shadowColor
    @helpwindow.windowskin = nil
    @helpwindow.visible = true
    addBackgroundOrColoredPlane(@sprites, "background", @fly_map ? "Town Map/bg_fly" : "Town Map/bg_wallmap" , Color.black, @viewport)
    @sprites["map"] = IconSprite.new(0, 0, @viewport)
    @sprites["map"].setBitmap("Graphics/UI/Town Map/#{@map.filename}")
    @sprites["map"].x += (Graphics.width - @sprites["map"].bitmap.width) / 2
    @sprites["map"].y += (Graphics.height - @sprites["map"].bitmap.height) / 2
    @sprites["map"].z = @sprites["background"].z - 1
    Settings::REGION_MAP_EXTRAS.each do |graphic|
      next if graphic[0] != mapindex || !location_shown?(graphic)
      if !@sprites["map2"]
        @sprites["map2"] = BitmapSprite.new(480, 320, @viewport)
        @sprites["map2"].x = @sprites["map"].x
        @sprites["map2"].y = @sprites["map"].y
      end
      pbDrawImagePositions(
        @sprites["map2"].bitmap,
        [["Graphics/UI/Town Map/#{graphic[4]}", graphic[2] * SQUARE_WIDTH, graphic[3] * SQUARE_HEIGHT]]
      )
    end
    @sprites["mapbottom"] = MapBottomSprite.new(@viewport)
    @sprites["mapbottom"].mapname     = @map.name
    @sprites["mapbottom"].maplocation = pbGetMapLocation(@map_x, @map_y)
    @sprites["mapbottom"].mapdetails  = pbGetMapDetails(@map_x, @map_y)
    if playerpos && mapindex == playerpos[0]
      meta = GameData::PlayerMetadata.get($player.character_ID)
      filename = pbGetPlayerCharset(meta.walk_charset, $player, true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename, @viewport)
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x = point_x_to_screen_x(@map_x)
      @sprites["player"].y = point_y_to_screen_y(@map_y)
    end

    # Get available location
    @available_map_point = []
    @map_idx = -1
    @map.point.each_with_index do |point,i|
      healspot = pbGetHealingSpot(point[0], point[1])
      next if @fly_map && (!healspot || (healspot && !$PokemonGlobal.visitedMaps[healspot[0]]))
      next if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      @map_idx = @available_map_point.length if point[0] == @map_x && point[1] == @map_y
      @available_map_point.push(i)
    end
    @map_idx = 0 if @fly_map && @map_idx < 0 && !@available_map_point.empty?
    @sprites["cursor"] = AnimatedSprite.create(@fly_map ? "Graphics/UI/Town Map/icon_fly" : "Graphics/UI/Town Map/cursor",
                                               @fly_map ? 2 : 1, 2)
    @sprites["cursor"].viewport = @viewport
    @sprites["cursor"].x        = point_x_to_screen_x(@map_x)
    @sprites["cursor"].y        = point_y_to_screen_y(@map_y)
    @sprites["cursor"].play
    @sprites["cursor"].visible  = (@map_idx >= 0)
    @sprites["help"] = BitmapSprite.new(Graphics.width, 32, @viewport)
    pbSetSystemFont(@sprites["help"].bitmap)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbControlMap(0)
    @changed = false
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def point_x_to_screen_x(x)
    return (-SQUARE_WIDTH / 2) + (x * SQUARE_WIDTH) + ((Graphics.width - @sprites["map"].bitmap.width) / 2)
  end

  def point_y_to_screen_y(y)
    return (-SQUARE_HEIGHT / 2) + (y * SQUARE_HEIGHT) + ((Graphics.height - @sprites["map"].bitmap.height) / 2)
  end

  def location_shown?(point)
    return point[5] if @wallmap
    return point[1] > 0 && $game_switches[point[1]]
  end

  def pbSaveMapData
    GameData::TownMap.save
    Compiler.write_town_map
  end

  def pbGetMapLocation(x, y)
    return "" if !@map.point
    @map.point.each do |point|
      next if point[0] != x || point[1] != y
      return "" if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      name = pbGetMessageFromHash(MessageTypes::REGION_LOCATION_NAMES, point[2])
      return (@editor) ? point[2] : name
    end
    return ""
  end

  def pbControlMap(sum)
    return if @map_idx < 0
    @map_idx += sum
    @map_idx = 0 if @map_idx >= @available_map_point.length
    @map_idx = @available_map_point.length - 1 if @map_idx < 0
    @map_x = @map.point[@available_map_point[@map_idx]][0]
    @map_y = @map.point[@available_map_point[@map_idx]][1]
    @sprites["cursor"].x        = point_x_to_screen_x(@map_x)
    @sprites["cursor"].y        = point_y_to_screen_y(@map_y)
    pbUpdateText
  end

  def pbSwitchRegion(direction)
    all_regions = []
    i = 0
    while GameData::TownMap.exists?(i)
      all_regions << i
      i += 1
    end
    return if all_regions.length <= 1
    current_idx = all_regions.index(@map.id) || 0
    new_region_id = all_regions[(current_idx + direction) % all_regions.length]
    @map = GameData::TownMap.get(new_region_id)
    @sprites["map"].setBitmap("Graphics/UI/Town Map/#{@map.filename}")
    @sprites["map"].x = (Graphics.width - @sprites["map"].bitmap.width) / 2
    @sprites["map"].y = (Graphics.height - @sprites["map"].bitmap.height) / 2
    map_metadata = $game_map.metadata
    playerpos = map_metadata ? map_metadata.town_map_position : nil
    @sprites["player"].visible = (playerpos && new_region_id == playerpos[0]) if @sprites["player"]
    @available_map_point = []
    @map_idx = -1
    @map.point.each_with_index do |point, idx|
      healspot = pbGetHealingSpot(point[0], point[1])
      next if @fly_map && (!healspot || !$PokemonGlobal.visitedMaps[healspot[0]])
      next if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      @available_map_point.push(idx)
    end
    if !@available_map_point.empty?
      @map_idx = 0
      @map_x = @map.point[@available_map_point[0]][0]
      @map_y = @map.point[@available_map_point[0]][1]
      @sprites["cursor"].x = point_x_to_screen_x(@map_x)
      @sprites["cursor"].y = point_y_to_screen_y(@map_y)
      @sprites["cursor"].visible = true
    else
      @sprites["cursor"].visible = false
    end
    pbUpdateText
  end

  def pbUpdateText
      overlay = @sprites["help"].bitmap
      @sprites["help"].bitmap.clear
      textPositions = []
      @maplocation = pbGetMapLocation(@map_x, @map_y)
      max = @fly_map ? 16 : 10
      words = pbTextSpliter(@helpwindow, @maplocation, max)
      words.each_with_index{|text,i|
        if @fly_map
            textPositions.push([text.upcase, 32, 16 + 16 * i, :left, @baseColor, @shadowColor])
        else
            textPositions.push([text.upcase, 144, 16 * i, :left, @baseColor, @shadowColor])
        end
      }
      pbDrawTextPositions(overlay, textPositions)
  end

  def pbChangeMapLocation(x, y)
    return "" if !@editor || !@map.point
    point = @map.point.select { |loc| loc[0] == x && loc[1] == y }[0]
    currentobj  = point
    currentname = (point) ? point[2] : ""
    currentname = pbMessageFreeText(_INTL("Set the name for this point."), currentname, false, 250) { pbUpdate }
    if currentname
      if currentobj
        currentobj[2] = currentname
      else
        newobj = [x, y, currentname, ""]
        @map.point.push(newobj)
      end
      @changed = true
    end
  end

  def pbGetMapDetails(x, y)
    return "" if !@map.point
    @map.point.each do |point|
      next if point[0] != x || point[1] != y
      return "" if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      return "" if !point[3]
      mapdesc = pbGetMessageFromHash(MessageTypes::REGION_LOCATION_DESCRIPTIONS, point[3])
      return (@editor) ? point[3] : mapdesc
    end
    return ""
  end

  def pbGetHealingSpot(x, y)
    return nil if !@map.point
    @map.point.each do |point|
      next if point[0] != x || point[1] != y
      return nil if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      return (point[4] && point[5] && point[6]) ? [point[4], point[5], point[6]] : nil
    end
    return nil
  end

  def refresh_fly_screen
    return if @fly_map || !Settings::CAN_FLY_FROM_TOWN_MAP || !pbCanFly?
    @sprites["help"].bitmap.clear
    text = (@mode == 0) ? _INTL("ACTION: Fly") : _INTL("ACTION: Cancel Fly")
    pbDrawTextPositions(
      @sprites["help"].bitmap,
      [[text, Graphics.width - 16, 4, :right, Color.new(248, 248, 248), Color.black]]
    )
    @sprites.each do |key, sprite|
      next if !key.include?("point")
      sprite.visible = (@fly_map)
      sprite.frame   = 0
    end
  end

  def pbMapScene
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @map_idx < 0
        pbMessage(_INTL("You don't know any locations to fly to."))
        break
      end
      if Input.trigger?(Input::BACK)
          break
      elsif Input.trigger?(Input::USE) && @fly_map   # Choosing an area to fly to
        healspot = pbGetHealingSpot(@map_x, @map_y)
        if healspot && ($PokemonGlobal.visitedMaps[healspot[0]] ||
           ($DEBUG && Input.press?(Input::CTRL)))
          return healspot if @fly_map
          name = pbGetMapNameFromId(healspot[0])
          return healspot if pbConfirmMessage(_INTL("Would you like to use Fly to go to {1}?", name)) { pbUpdate }
        end
      elsif Input.trigger?(Input::UP)
        pbControlMap(1)
      elsif Input.trigger?(Input::DOWN)
        pbControlMap(-1)
      elsif Input.trigger?(Input::AUX1)
        pbSwitchRegion(-1)
      elsif Input.trigger?(Input::AUX2)
        pbSwitchRegion(1)
      end
    end
    pbPlayCloseMenuSE
    return nil
  end
end

#===============================================================================
#
#===============================================================================
class PokemonRegionMapScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartFlyScreen
    @scene.pbStartScene(false, true)
    ret = @scene.pbMapScene
    @scene.pbEndScene
    return ret
  end

  def pbStartScreen
    @scene.pbStartScene($DEBUG)
    ret = @scene.pbMapScene
    @scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbShowMap(region = -1, wallmap = true)
  pbFadeOutIn do
    scene = PokemonRegionMap_Scene.new(region, wallmap)
    screen = PokemonRegionMapScreen.new(scene)
    ret = screen.pbStartScreen
    $game_temp.fly_destination = ret if ret && !wallmap
  end
end
