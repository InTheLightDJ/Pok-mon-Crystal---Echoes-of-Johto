#===============================================================================
#
#===============================================================================
class Window_Pokedex < Window_DrawableCommand
  def initialize(x, y, width, height, viewport)
    @commands = []
    super(x, y, width, height, viewport)
    @selarrow     = AnimatedBitmap.new("Graphics/UI/Pokedex/cursor_list")
    @pokeballOwn  = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_own")
    @pokeballSeen = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_seen")
    self.baseColor   = Color.new(248, 248, 248)
    self.shadowColor = Color.new(0, 0, 0)
    self.windowskin  = nil
  end

  def commands=(value)
    @commands = value
    refresh
  end

  def dispose
    @pokeballOwn.dispose
    @pokeballSeen.dispose
    super
  end

  def species
    return (@commands.length == 0) ? 0 : @commands[self.index][:species]
  end

  def itemCount
    return @commands.length
  end

  def drawItem(index, _count, rect)
    return if index >= self.top_row + self.page_item_max
    rect = Rect.new(rect.x + 16, rect.y + 2, rect.width - 16, rect.height)
    species     = @commands[index][:species]
    indexNumber = @commands[index][:number]
    indexNumber -= 1 if @commands[index][:shift]
    if $player.seen?(species)
      if $player.owned?(species)
        pbCopyBitmap(self.contents, @pokeballOwn.bitmap, rect.x - 14, rect.y + 14)
      else
        pbCopyBitmap(self.contents, @pokeballSeen.bitmap, rect.x - 14, rect.y + 14)
      end
      num_text = sprintf("%03d", indexNumber)
      name_text = @commands[index][:name]
    else
      num_text = sprintf("%03d", indexNumber)
      name_text = "-----"
    end
    pbDrawShadowText(self.contents, rect.x + 2, rect.y - 2, rect.width, rect.height,
                     num_text, self.baseColor, self.shadowColor)
    pbDrawShadowText(self.contents, rect.x + 2, rect.y + 14, rect.width, rect.height,
                     name_text, self.baseColor, self.shadowColor)
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    @item_max.times do |i|
      next if i < self.top_item || i > self.top_item + self.page_item_max
      drawItem(i, @item_max, itemRect(i))
    end
    drawCursor(self.index, itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
#
#===============================================================================
class PokedexSearchSelectionSprite < Sprite
  attr_reader :index
  attr_accessor :cmds
  attr_accessor :minmax

  def initialize(viewport = nil)
    super(viewport)
    @selbitmap = AnimatedBitmap.new("Graphics/UI/sel_arrow_white")
    self.bitmap = @selbitmap.bitmap
    self.mode = -1
    @index = 0
    refresh
  end

  def dispose
    @selbitmap.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def mode=(value)
    @mode = value
    case @mode
    when 0     # Order
      @xstart = 46
      @ystart = 128
      @xgap = 236
      @ygap = 64
      @cols = 2
    when 1     # Name
      @xstart = 78
      @ystart = 114
      @xgap = 52
      @ygap = 52
      @cols = 7
    when 2     # Type
      @xstart = 8
      @ystart = 104
      @xgap = 124
      @ygap = 44
      @cols = 4
    when 3, 4   # Height, weight
      @xstart = 44
      @ystart = 110
      @xgap = 8
      @ygap = 112
    when 5     # Color
      @xstart = 62
      @ystart = 114
      @xgap = 132
      @ygap = 52
      @cols = 3
    when 6     # Shape
      @xstart = 82
      @ystart = 116
      @xgap = 70
      @ygap = 70
      @cols = 5
    end
  end

  def refresh
    # Position cursor
    case @index
    when 0; self.x = 34; self.y = 58 # Type 1
    when 1; self.x = 34; self.y = 90 # Type 2
    when 2; self.x = 34; self.y = 202 # Search
    when 3; self.x = 34; self.y = 234 # Cancel
    end
  end
end

#===============================================================================
# Pokédex main screen
#===============================================================================
class PokemonPokedex_Scene
  MODENUMERICAL = 0
  MODEATOZ      = 1
  MODETALLEST   = 2
  MODESMALLEST  = 3
  MODEHEAVIEST  = 4
  MODELIGHTEST  = 5

  def pbUpdate
    if @sprites["searchbg"].visible
      if @frame == 10
        @frame = 0
        @sprites["searchcursor"].visible = !(@sprites["searchcursor"].visible)
      end
      @frame += 1
    end
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_slider")
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites, "background", "Pokedex/bg_list", @viewport)
    # Suggestion for changing the background depending on region. You can
    # comment out the line above and uncomment the following lines:
    #    if pbGetPokedexRegion == -1   # Using national Pokédex
    #      addBackgroundPlane(@sprites, "background", "Pokedex/bg_national", @viewport)
    #    elsif pbGetPokedexRegion == 0   # Using first regional Pokédex
    #      addBackgroundPlane(@sprites, "background", "Pokedex/bg_regional", @viewport)
    #    end
    addBackgroundPlane(@sprites, "searchbg", "Pokedex/bg_search", @viewport)
    @sprites["searchbg"].visible = false
    @sprites["pokedex"] = Window_Pokedex.new(110, 0, 210, 272, @viewport)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::CENTER)
    @sprites["icon"].x = 62
    @sprites["icon"].y = 72
    @sprites["icon"].tone = Tone.new(0, 0, 0, 248)
    @sprites["icon"].opacity = 77
    @sprites["overlayscrn"] = BitmapSprite.new(112, 112, @viewport)
    @sprites["overlayscrn"].x = 6
    @sprites["overlayscrn"].y = 16
    @sprites["overlayscrn"].bitmap.fill_rect(0, 0, 112, 112, Color.new(160,64,248))
    @sprites["overlayscrn"].blend_type = 2
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @sprites["searchanim"] = IconSprite.new(128, 144, @viewport)
    @sprites["searchanim"].setBitmap("Graphics/UI/Pokedex/icon_searching")
    @sprites["searchanim"].src_rect.set(0, 0, 48, 48)
    @sprites["searchanim"].visible = false
    @frame = 0
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode, -1, 0, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @viewport.dispose
  end

  # Gets the region used for displaying Pokédex entries. Species will be listed
  # according to the given region's numbering and the returned region can have
  # any value defined in the town map data file. It is currently set to the
  # return value of pbGetCurrentRegion, and thus will change according to the
  # current map's MapPosition metadata setting.
  def pbGetPokedexRegion
    if Settings::USE_CURRENT_REGION_DEX
      region = pbGetCurrentRegion
      region = -1 if region >= $player.pokedex.dexes_count - 1
      return region
    else
      return $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
    end
  end

  # Determines which index of the array $PokemonGlobal.pokedexIndex to save the
  # "last viewed species" in. All regional dexes come first in order, then the
  # National Dex at the end.
  def pbGetSavePositionIndex
    index = pbGetPokedexRegion
    if index == -1   # National Dex (comes after regional Dex indices)
      index = $player.pokedex.dexes_count - 1
    end
    return index
  end

  def pbCanAddForModeList?(mode, species)
    case mode
    when MODEATOZ
      return $player.seen?(species)
    when MODEHEAVIEST, MODELIGHTEST, MODETALLEST, MODESMALLEST
      return $player.owned?(species)
    end
    return true   # For MODENUMERICAL
  end

  def pbGetDexList
    region = pbGetPokedexRegion
    regionalSpecies = pbAllRegionalSpecies(region)
    if !regionalSpecies || regionalSpecies.length == 0
      # If no Regional Dex defined for the given region, use the National Pokédex
      regionalSpecies = []
      GameData::Species.each_species { |s| regionalSpecies.push(s.id) }
    end
    shift = Settings::DEXES_WITH_OFFSETS.include?(region)
    ret = []
    regionalSpecies.each_with_index do |species, i|
      next if !species
      next if !pbCanAddForModeList?($PokemonGlobal.pokedexMode, species)
      _gender, _shiny, form = $player.pokedex.last_form_seen(species)
      species_data = GameData::Species.get_species_form(species, form)
      next if !species_data  # Skip if invalid
      ret.push({
        :species => species,
        :name    => species_data.name,
        :height  => species_data.height,
        :weight  => species_data.weight,
        :number  => i + 1,
        :shift   => shift,
        :types   => species_data.types,
        :color   => species_data.color,
        :shape   => species_data.shape
      })
    end
    return ret
  end

  def pbRefreshDexList(index = 0)
    dexlist = pbGetDexList
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL
      # Hide the Dex number 0 species if unseen
      dexlist[0] = nil if dexlist[0][:shift] && !$player.seen?(dexlist[0][:species])
      # Remove unseen species from the end of the list
      i = dexlist.length - 1
      loop do
        break if i < 0 || !dexlist[i] || $player.seen?(dexlist[i][:species])
        dexlist[i] = nil
        i -= 1
      end
      dexlist.compact!
      # Sort species in ascending order by Regional Dex number
      dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ
      dexlist.sort! { |a, b| (a[:name] == b[:name]) ? a[:number] <=> b[:number] : a[:name] <=> b[:name] }
    when MODEHEAVIEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : b[:weight] <=> a[:weight] }
    when MODELIGHTEST
      dexlist.sort! { |a, b| (a[:weight] == b[:weight]) ? a[:number] <=> b[:number] : a[:weight] <=> b[:weight] }
    when MODETALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : b[:height] <=> a[:height] }
    when MODESMALLEST
      dexlist.sort! { |a, b| (a[:height] == b[:height]) ? a[:number] <=> b[:number] : a[:height] <=> b[:height] }
    end
    @dexlist = dexlist
    @sprites["pokedex"].commands = @dexlist
    @sprites["pokedex"].index    = index
    @sprites["pokedex"].refresh
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(0, 0, 0)
    iconspecies = @sprites["pokedex"].species
    iconspecies = nil if !$player.seen?(iconspecies)
    # Write various bits of text
    dexname = _INTL("Pokédex")
    if $player.pokedex.dexes_count > 1
      thisdex = Settings.pokedex_names[pbGetSavePositionIndex]
      if thisdex
        dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
      end
    end
    textpos = []
    if @searchResults
      textpos.push([_INTL("Found"), 6, 192, :left, base, shadow])
      textpos.push([@dexlist.length.to_s, 120, 200, :right, base, shadow])
    else
      textpos.push([_INTL("Seen:"), 6, 168, :left, base, shadow])
      textpos.push([$player.pokedex.seen_count(pbGetPokedexRegion).to_s, 118, 184, :right, base, shadow])
      textpos.push([_INTL("Own:"), 6, 216, :left, base, shadow])
      textpos.push([$player.pokedex.owned_count(pbGetPokedexRegion).to_s, 118, 232, :right, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Set Pokémon sprite
    setIconBitmap(iconspecies)
    # Draw slider arrows
    itemlist = @sprites["pokedex"]
    showslider = false
    if itemlist.top_row > 0
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      showslider = true
    end
    # Draw slider box
    if showslider
      y = 10
      y += 242 * itemlist.index / (itemlist.row_max - 1)
      overlay.blt(308, y, @sliderbitmap.bitmap, Rect.new(0, 0, 10, 10))
    end
  end

  def pbRefreshDexSearch(params, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(0, 0, 0)
    # Write various bits of text
    textpos = []
    if params[2] >= 0
      textpos.push([_INTL("{1}", GameData::Type.get(@typeCommands[params[2]].id).name), 208, 64, :center, base, shadow, :outline])
    else
      textpos.push(["----", 208, 64, :center, base, shadow, :outline])
    end
    if params[3] >= 0
      textpos.push([_INTL("{1}", GameData::Type.get(@typeCommands[params[3]].id).name), 208, 96, :center, base, shadow, :outline])
    else
      textpos.push(["----", 208, 96, :center, base, shadow, :outline])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def pbRefreshDexSearchParam(mode, cmds, sel, _index)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(0, 0, 0)
    # Write various bits of text
    textpos = [
      [_INTL("Mode"), Graphics.width / 2, 8, :center, base, shadow],
      [_INTL("OK"), 36, 250, :left, base, shadow, :outline],
      [_INTL("Cancel"), Graphics.width - 20, 250, :right, base, shadow, :outline]
    ]
    title = [_INTL("Order"), _INTL("Name"), _INTL("Type"), _INTL("Height"),
             _INTL("Weight"), _INTL("Color"), _INTL("Shape")][mode]
    textpos.push([title, 20, (mode == 6) ? 40 : 40, :left, base, shadow])
    case mode
    when 0   # Order
      xstart = 46
      ystart = 128
      xgap = 236
      ygap = 64
      halfwidth = 92
      cols = 2
      selbuttony = 0
      selbuttonheight = 44
    when 1   # Name
      xstart = 78
      ystart = 114
      xgap = 52
      ygap = 52
      halfwidth = 22
      cols = 7
      selbuttony = 156
      selbuttonheight = 44
    when 2   # Type
      xstart = 8
      ystart = 104
      xgap = 124
      ygap = 44
      halfwidth = 62
      cols = 4
      selbuttony = 44
      selbuttonheight = 44
    when 3, 4   # Height, weight
      xstart = 44
      ystart = 110
      xgap = 304 / (cmds.length + 1)
      ygap = 112
      halfwidth = 60
      cols = cmds.length + 1
    when 5   # Color
      xstart = 62
      ystart = 114
      xgap = 132
      ygap = 52
      halfwidth = 62
      cols = 3
      selbuttony = 44
      selbuttonheight = 44
    when 6   # Shape
      xstart = 82
      ystart = 116
      xgap = 70
      ygap = 70
      halfwidth = 0
      cols = 5
      selbuttony = 88
      selbuttonheight = 68
    end
    # Draw selected option(s) text in top bar
    case mode
    when 2   # Type icons
      2.times do |i|
        if !sel[i] || sel[i] < 0
          textpos.push(["----", 130 + (80 * i), 40, :left, base, shadow, :outline])
        else
          type_number = @typeCommands[sel[i]].icon_position
          typerect = Rect.new(0, type_number * 28, 64, 28)
          overlay.blt(130 + (80 * i), 42, @typebitmap.bitmap, typerect)
        end
      end
    when 3   # Height range
      ht1 = (sel[0] < 0) ? 0 : (sel[0] >= @heightCommands.length) ? 999 : @heightCommands[sel[0]]
      ht2 = (sel[1] < 0) ? 999 : (sel[1] >= @heightCommands.length) ? 0 : @heightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"    # If the user is in the United States
        ht1 = (sel[0] >= @heightCommands.length) ? 99 * 12 : (ht1 / 0.254).round
        ht2 = (sel[1] < 0) ? 99 * 12 : (ht2 / 0.254).round
        txt1 = sprintf("%d'%02d''", ht1 / 12, ht1 % 12)
        txt2 = sprintf("%d'%02d''", ht2 / 12, ht2 % 12)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", ht1 / 10.0)
        txt2 = sprintf("%.1f", ht2 / 10.0)
      end
    when 4   # Weight range
      wt1 = (sel[0] < 0) ? 0 : (sel[0] >= @weightCommands.length) ? 9999 : @weightCommands[sel[0]]
      wt2 = (sel[1] < 0) ? 9999 : (sel[1] >= @weightCommands.length) ? 0 : @weightCommands[sel[1]]
      hwoffset = false
      if System.user_language[3..4] == "US"   # If the user is in the United States
        wt1 = (sel[0] >= @weightCommands.length) ? 99_990 : (wt1 / 0.254).round
        wt2 = (sel[1] < 0) ? 99_990 : (wt2 / 0.254).round
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
        hwoffset = true
      else
        txt1 = sprintf("%.1f", wt1 / 10.0)
        txt2 = sprintf("%.1f", wt2 / 10.0)
      end
    when 5   # Color
      if sel[0] < 0
        textpos.push(["----", 362, 66, :center, base, shadow, :outline])
      else
        textpos.push([cmds[sel[0]].name, 362, 66, :center, base, shadow, :outline])
      end
    when 6   # Shape icon
      if sel[0] >= 0
        shaperect = Rect.new(0, @shapeCommands[sel[0]].icon_position * 60, 60, 60)
        overlay.blt(332, 50, @shapebitmap.bitmap, shaperect)
      end
    else
      if sel[0] < 0
        text = ["----", "-", "----", "", "", "----", ""][mode]
        textpos.push([text, 300, 40, :center, base, shadow, :outline])
      else
        textpos.push([cmds[sel[0]], 300, 40, :center, base, shadow, :outline])
      end
    end
    # Draw selected option(s) button graphic
    if [3, 4].include?(mode)   # Height, weight
      xpos1 = xstart + ((sel[0] + 1) * xgap)
      xpos1 = xstart if sel[0] < -1
      xpos2 = xstart + ((sel[1] + 1) * xgap)
      xpos2 = xstart + (cols * xgap) if sel[1] < 0
      xpos2 = xstart if sel[1] >= cols - 1
      ypos1 = ystart + 180
      ypos2 = ystart + 36
      overlay.blt(16, 120, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[1] < cols - 1
      overlay.blt(464, 120, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[1] >= 0
      overlay.blt(16, 264, @searchsliderbitmap.bitmap, Rect.new(0, 192, 32, 44)) if sel[0] >= 0
      overlay.blt(464, 264, @searchsliderbitmap.bitmap, Rect.new(32, 192, 32, 44)) if sel[0] < cols - 1
      hwrect = Rect.new(0, 0, 120, 96)
      overlay.blt(xpos2, ystart, @searchsliderbitmap.bitmap, hwrect)
      hwrect.y = 96
      overlay.blt(xpos1, ystart + ygap, @searchsliderbitmap.bitmap, hwrect)
      textpos.push([txt1, xpos1 + halfwidth, ypos1, :center, base])
      textpos.push([txt2, xpos2 + halfwidth, ypos2, :center, base])
    else
      sel.length.times do |i|
        selrect = Rect.new(0, selbuttony, @selbitmap.bitmap.width, selbuttonheight)
        if sel[i] >= 0
          overlay.blt(xstart + ((sel[i] % cols) * xgap),
                      ystart + ((sel[i] / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        else
          overlay.blt(xstart + ((cols - 1) * xgap),
                      ystart + ((cmds.length / cols).floor * ygap),
                      @selbitmap.bitmap, selrect)
        end
      end
    end
    # Draw options
    case mode
    when 0, 1   # Order, name
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap)
        textpos.push([cmds[i], x, y, :center, base, shadow, :outline])
      end
      if mode != 0
        textpos.push([(mode == 1) ? "-" : "----",
                      xstart + halfwidth + ((cols - 1) * xgap),
                      ystart + 14 + ((cmds.length / cols).floor * ygap),
                      :center, base, shadow, :outline])
      end
    when 2   # Type
      typerect = Rect.new(0, 0, 64, 28)
      cmds.length.times do |i|
        typerect.y = @typeCommands[i].icon_position * 28
        overlay.blt(xstart + 14 + ((i % cols) * xgap),
                    ystart + 6 + ((i / cols).floor * ygap),
                    @typebitmap.bitmap, typerect)
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap),
                    :center, base, shadow, :outline])
    when 5   # Color
      cmds.length.times do |i|
        x = xstart + halfwidth + ((i % cols) * xgap)
        y = ystart + 14 + ((i / cols).floor * ygap)
        textpos.push([cmds[i].name, x, y, :center, base, shadow, :outline])
      end
      textpos.push(["----",
                    xstart + halfwidth + ((cols - 1) * xgap),
                    ystart + 14 + ((cmds.length / cols).floor * ygap),
                    :center, base, shadow, :outline])
    when 6   # Shape
      shaperect = Rect.new(0, 0, 60, 60)
      cmds.length.times do |i|
        shaperect.y = @shapeCommands[i].icon_position * 60
        overlay.blt(xstart + 4 + ((i % cols) * xgap),
                    ystart + 4 + ((i / cols).floor * ygap),
                    @shapebitmap.bitmap, shaperect)
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
  end

  def setIconBitmap(species)
    gender, _shiny, form = $player.pokedex.last_form_seen(species)
    @sprites["icon"].setSpeciesBitmap(species, gender, false, false, form)
  end

  def pbSearchDexList(params)
    $PokemonGlobal.pokedexMode = params[0]
    dexlist = pbGetDexList
    # Filter by name
    if params[1] >= 0
      scanNameCommand = @nameCommands[params[1]].scan(/./)
      dexlist = dexlist.find_all do |item|
        next false if !$player.seen?(item[:species])
        firstChar = item[:name][0, 1]
        next scanNameCommand.any? { |v| v == firstChar }
      end
    end
    # Filter by type
    if params[2] >= 0 || params[3] >= 0
      stype1 = (params[2] >= 0) ? @typeCommands[params[2]].id : nil
      stype2 = (params[3] >= 0) ? @typeCommands[params[3]].id : nil
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        types = item[:types]
        if stype1 && stype2
          # Find species that match both types
          next types.include?(stype1) && types.include?(stype2)
        elsif stype1
          # Find species that match first type entered
          next types.include?(stype1)
        elsif stype2
          # Find species that match second type entered
          next types.include?(stype2)
        else
          next false
        end
      end
    end
    # Filter by height range
    if params[4] >= 0 || params[5] >= 0
      minh = (params[4] < 0) ? 0 : (params[4] >= @heightCommands.length) ? 999 : @heightCommands[params[4]]
      maxh = (params[5] < 0) ? 999 : (params[5] >= @heightCommands.length) ? 0 : @heightCommands[params[5]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        height = item[:height]
        next height >= minh && height <= maxh
      end
    end
    # Filter by weight range
    if params[6] >= 0 || params[7] >= 0
      minw = (params[6] < 0) ? 0 : (params[6] >= @weightCommands.length) ? 9999 : @weightCommands[params[6]]
      maxw = (params[7] < 0) ? 9999 : (params[7] >= @weightCommands.length) ? 0 : @weightCommands[params[7]]
      dexlist = dexlist.find_all do |item|
        next false if !$player.owned?(item[:species])
        weight = item[:weight]
        next weight >= minw && weight <= maxw
      end
    end
    # Filter by color
    if params[8] >= 0
      scolor = @colorCommands[params[8]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:color] == scolor
      end
    end
    # Filter by shape
    if params[9] >= 0
      sshape = @shapeCommands[params[9]].id
      dexlist = dexlist.find_all do |item|
        next $player.seen?(item[:species]) && item[:shape] == sshape
      end
    end
    # Remove all unseen species from the results
    dexlist = dexlist.find_all { |item| next $player.seen?(item[:species]) }
    case $PokemonGlobal.pokedexMode
    when MODENUMERICAL then dexlist.sort! { |a, b| a[:number] <=> b[:number] }
    when MODEATOZ      then dexlist.sort! { |a, b| a[:name] <=> b[:name] }
    when MODEHEAVIEST  then dexlist.sort! { |a, b| b[:weight] <=> a[:weight] }
    when MODELIGHTEST  then dexlist.sort! { |a, b| a[:weight] <=> b[:weight] }
    when MODETALLEST   then dexlist.sort! { |a, b| b[:height] <=> a[:height] }
    when MODESMALLEST  then dexlist.sort! { |a, b| a[:height] <=> b[:height] }
    end
    return dexlist
  end

  def pbCloseSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    oldspecies = @sprites["pokedex"].species
    @searchResults = false
    $PokemonGlobal.pokedexMode = MODENUMERICAL
    @searchParams = [$PokemonGlobal.pokedexMode, -1, 0, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    @dexlist.length.times do |i|
      next if @dexlist[i][:species] != oldspecies
      @sprites["pokedex"].index = i
      pbRefresh
      break
    end
    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexEntry(index)
    oldsprites = pbFadeOutAndHide(@sprites)
    region = -1
    if !Settings::USE_CURRENT_REGION_DEX
      dexnames = Settings.pokedex_names
      if dexnames[pbGetSavePositionIndex].is_a?(Array)
        region = dexnames[pbGetSavePositionIndex][1]
      end
    end
    scene = PokemonPokedexInfo_Scene.new
    screen = PokemonPokedexInfoScreen.new(scene)
    ret = screen.pbStartScreen(@dexlist, index, region)
    if @searchResults
      dexlist = pbSearchDexList(@searchParams)
      @dexlist = dexlist
      @sprites["pokedex"].commands = @dexlist
      ret = @dexlist.length - 1 if ret >= @dexlist.length
      ret = 0 if ret < 0
    else
      pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
      $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = ret
    end
    @sprites["pokedex"].index = ret
    @sprites["pokedex"].refresh
    pbRefresh
    pbFadeInAndShow(@sprites, oldsprites)
  end

  def pbDexSearchCommands(mode, selitems, mainindex)
    cmds = [@orderCommands, @nameCommands, @typeCommands, @heightCommands,
            @weightCommands, @colorCommands, @shapeCommands][mode]
    cols = [2, 7, 4, 1, 1, 3, 5][mode]
    ret = nil
    # Set background
    case mode
    when 0, 1    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    when 2
      count = 0
      GameData::Type.each { |t| count += 1 if !t.pseudo_type && t.id != :SHADOW }
      if count == 18
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
      else
        @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
      end
    when 3, 4 then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    when 5    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    when 6    then @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    end
    selindex = selitems.clone
    index     = selindex[0]
    oldindex  = index
    minmax    = 1
    oldminmax = minmax
    index = oldindex = selindex[minmax] if [3, 4].include?(mode)
    @sprites["searchcursor"].mode   = mode
    @sprites["searchcursor"].cmds   = cmds.length
    @sprites["searchcursor"].minmax = minmax
    @sprites["searchcursor"].index  = index
    nextparam = cmds.length % 2
    pbRefreshDexSearchParam(mode, cmds, selindex, index)
    loop do
      pbUpdate
      if index != oldindex || minmax != oldminmax
        @sprites["searchcursor"].minmax = minmax
        @sprites["searchcursor"].index  = index
        oldindex  = index
        oldminmax = minmax
      end
      Graphics.update
      Input.update
      if [3, 4].include?(mode)
        if Input.trigger?(Input::UP)
          if index < -1   # From OK/Cancel
            minmax = 0
            index = selindex[minmax]
          elsif minmax == 0
            minmax = 1
            index = selindex[minmax]
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.trigger?(Input::DOWN)
          case minmax
          when 1
            minmax = 0
            index = selindex[minmax]
          when 0
            minmax = -1
            index = -2
          end
          if index != oldindex || minmax != oldminmax
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::LEFT)
          if index == -3
            index = -2
          elsif index >= -1
            if minmax == 1 && index == -1
              index = cmds.length - 1 if selindex[0] < cmds.length - 1
            elsif minmax == 1 && index == 0
              index = cmds.length if selindex[0] < 0
            elsif index > -1 && !(minmax == 1 && index >= cmds.length)
              index -= 1 if minmax == 0 || selindex[0] <= index - 1
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        elsif Input.repeat?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index >= -1
            if minmax == 1 && index >= cmds.length
              index = 0
            elsif minmax == 1 && index == cmds.length - 1
              index = -1
            elsif index < cmds.length && !(minmax == 1 && index < 0)
              index += 1 if minmax == 1 || selindex[1] == -1 ||
                            (selindex[1] < cmds.length && selindex[1] >= index + 1)
            end
          end
          if index != oldindex
            selindex[minmax] = index if minmax >= 0
            pbPlayCursorSE
            pbRefreshDexSearchParam(mode, cmds, selindex, index)
          end
        end
      else
        if Input.trigger?(Input::UP)
          if index == -1   # From blank
            index = cmds.length - 1 - ((cmds.length - 1) % cols) - 1
          elsif index == -2   # From OK
            index = ((cmds.length - 1) / cols).floor * cols
          elsif index == -3 && mode == 0   # From Cancel
            index = cmds.length - 1
          elsif index == -3   # From Cancel
            index = -1
          elsif index >= cols
            index -= cols
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::DOWN)
          if index == -1   # From blank
            index = -3
          elsif index >= 0
            if index + cols < cmds.length
              index += cols
            elsif (index / cols).floor < ((cmds.length - 1) / cols).floor
              index = (index % cols < cols / 2.0) ? cmds.length - 1 : -1
            else
              index = (index % cols < cols / 2.0) ? -2 : -3
            end
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::LEFT)
          if index == -3
            index = -2
          elsif index == -1
            index = cmds.length - 1
          elsif index > 0 && index % cols != 0
            index -= 1
          end
          pbPlayCursorSE if index != oldindex
        elsif Input.trigger?(Input::RIGHT)
          if index == -2
            index = -3
          elsif index == cmds.length - 1 && mode != 0
            index = -1
          elsif index >= 0 && index % cols != cols - 1
            index += 1
          end
          pbPlayCursorSE if index != oldindex
        end
      end
      if Input.trigger?(Input::ACTION)
        index = -2
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        ret = nil
        break
      elsif Input.trigger?(Input::USE)
        if index == -2      # OK
          pbSEPlay("GUI pokedex open")
          ret = selindex
          break
        elsif index == -3   # Cancel
          pbPlayCloseMenuSE
          ret = nil
          break
        elsif selindex != index && mode != 3 && mode != 4
          if mode == 2
            if index == -1
              nextparam = (selindex[1] >= 0) ? 1 : 0
            elsif index >= 0
              nextparam = (selindex[0] < 0) ? 0 : (selindex[1] < 0) ? 1 : nextparam
            end
            if index < 0 || selindex[(nextparam + 1) % 2] != index
              pbPlayDecisionSE
              selindex[nextparam] = index
              nextparam = (nextparam + 1) % 2
            end
          else
            pbPlayDecisionSE
            selindex[0] = index
          end
          pbRefreshDexSearchParam(mode, cmds, selindex, index)
        end
      end
    end
    Input.update
    # Set background image
    @sprites["searchbg"].setBitmap("Graphics/UI/Pokedex/bg_search")
    @sprites["searchcursor"].mode = -1
    @sprites["searchcursor"].index = mainindex
    return ret
  end

  def pbDexSearch
    oldsprites = pbFadeOutAndHide(@sprites)
    params = @searchParams.clone
    @typeCommands = []
    GameData::Type.each { |t| @typeCommands.push(t) if !t.pseudo_type }
    @sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["searchcursor"].visible = true
    @sprites["searchanim"].visible   = true
    index = 0
    oldindex = index
    @sprites["searchcursor"].mode    = -1
    @sprites["searchcursor"].index   = index
    pbRefreshDexSearch(params, index)
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if index != oldindex
        @sprites["searchcursor"].index = index
        oldindex = index
      end
      if Input.trigger?(Input::UP)
        index -= 1 if index > 0
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::DOWN)
      index += 1 if index < 3
        pbPlayCursorSE if index != oldindex
      elsif Input.trigger?(Input::LEFT)
        if index==0 || index==1
          param_index = [2,3][index]
          param = params[param_index]
          param -= 1
          param = @typeCommands.length - 1 if (index == 1 && param < -1) || (index == 0 && param < 0)
          params[param_index] = param
          pbRefreshDexSearch(params,index)
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index==0 || index==1
          param_index = [2,3][index]
          param = params[param_index]
          param += 1
          param = index == 0 ? 0 : -1 if param > @typeCommands.length - 1
          params[param_index] = param
          pbRefreshDexSearch(params,index)
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE if index > 2
        case index
        when 2  # Start search (filter)
          @frame = 0
          @sprites["searchcursor"].visible = true
          pbAnimSearch
          dexlist = pbSearchDexList(params)
          if dexlist.length == 0
            pbMessage(_INTL("No matching Pokémon were found.\\wtnp[40]"), nil, :left,
                            "Graphics/Windowskins/ui_pokedex_search")
          else
            @dexlist = dexlist
            @sprites["pokedex"].commands = @dexlist
            @sprites["pokedex"].index    = 0
            @sprites["pokedex"].refresh
            @searchResults = true
            @searchParams = params
            break
          end
        when 3   # Cancel
          pbPlayCloseMenuSE
          break
        end
      end
    end
    pbFadeOutAndHide(@sprites)
    if @searchResults
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/UI/Pokedex/bg_list")
    end
    pbRefresh
    @sprites["searchanim"].visible = false
    pbFadeInAndShow(@sprites, oldsprites)
    Input.update
    return 0
  end

  def pbAnimSearch
    duration = 0.04
    pbWait(0.5)
    start_time = System.uptime
    anim_time = start_time
    i = 0
    loop do
      Graphics.update
      pbUpdate
      if System.uptime - anim_time >= duration
        i += 1
        i = 0 if i >= 5
        @sprites["searchanim"].src_rect.set(48 * i, 0, 48, 48)
        anim_time = System.uptime
      end
      break if @sprites["searchanim"].src_rect.x == 0 && System.uptime - start_time >= duration * 5 * 5
    end
    pbWait(duration)
  end

  def pbPokedex
    pbActivateWindow(@sprites, "pokedex") do
      loop do
        Graphics.update
        Input.update
        oldindex = @sprites["pokedex"].index
        pbUpdate
        if oldindex != @sprites["pokedex"].index
          $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
          pbRefresh
        end
        if Input.trigger?(Input::ACTION)
          pbSEPlay("GUI pokedex open")
          @sprites["pokedex"].active = false
          pbDexSearch
          @sprites["pokedex"].active = true
        elsif Input.trigger?(Input::BACK)
          pbPlayCloseMenuSE
          if @searchResults
            pbCloseSearch
          else
            break
          end
        elsif Input.trigger?(Input::USE)
          if $player.seen?(@sprites["pokedex"].species)
            pbSEPlay("GUI pokedex open")
            pbDexEntry(@sprites["pokedex"].index)
          end
        elsif (Input.trigger?(Input::L) || Input.trigger?(Input::R)) &&
              $PokemonGlobal&.unown_tracker_unlocked
          pbOpenUnownTracker
        end
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbPokedex
    @scene.pbEndScene
  end
end
