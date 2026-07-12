#==============================================================================
# Home
#==============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :home, {
  "suffix"    => "home",
  "order"     => 0,
})

class PokemonPokegear_Scene
  alias home_pbUpdateText pbUpdateText
  def pbUpdateText
    home_pbUpdateText
    if pbGetPageId == :home
      textPositions = []
      time = pbGetTimeNow
      wday = time.wday
      day = [
       _INTL("Sunday"),
       _INTL("Monday"),
       _INTL("Tuesday"),
       _INTL("Wednesday"),
       _INTL("Thursday"),
       _INTL("Friday"),
       _INTL("Saturday")][wday]
      hour = (time.hour > 12) ? time.hour - 12 : time.hour
      periode = (time.hour > 12) ? "PM" : "AM"
      textPositions = [
          [_INTL("{1}", day), 168, 88, :center, @baseColor, @shadowColor],
          [sprintf("%02d : %02d", hour, time.min), 176, 120, :right, @baseColor, @shadowColor],
          [_INTL("{1}", periode), 224, 120, :right, @baseColor, @shadowColor]
        ]
      @helpwindow.text = _INTL("Press any button to exit.")
      pbDrawTextPositions(@sprites["overlay"].bitmap, textPositions)
    end
  end
end

#==============================================================================
# Map
#==============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :map, {
  "suffix"    => "map",
  "order"     => 10,
})

class PokemonPokegear_Scene
  LEFT          = 0
  TOP           = 0
  SQUARE_WIDTH  = 16
  SQUARE_HEIGHT = 16

  alias map_pbCustomStartScene pbCustomStartScene
  def pbCustomStartScene
    map_pbCustomStartScene
    # Map
    @region = -1 ; @wallmap = true
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
    @sprites["map_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    if playerpos && mapindex == playerpos[0]
      meta = GameData::PlayerMetadata.get($player.character_ID)
      filename = pbGetPlayerCharset(meta.walk_charset, $player, true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename, @viewport)
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x = point_x_to_screen_x(@map_x)
      @sprites["player"].y = point_y_to_screen_y(@map_y)
    end
    @sprites["mapcursor"] = IconSprite.new(0, 0, @viewport)
    @sprites["mapcursor"].setBitmap("Graphics/UI/Town Map/cursor")
    @sprites["mapcursor"].x        = point_x_to_screen_x(@map_x)
    @sprites["mapcursor"].y        = point_y_to_screen_y(@map_y)
    @sprites["mapcursor"].visible = false
    # Get available location
    @available_map_point = []
    @map_idx = -1
    @map.point.each_with_index do |point,i|
      next if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      @map_idx = @available_map_point.length if point[0] == @map_x && point[1] == @map_y
      @available_map_point.push(i)
    end
    # Get available other information
    @map_information_data = {:none => [], :berry => [], :roam => []}
    @map_info_pages = [:none]
    # Berry Tree
    GameData::MapMetadata.each do |map_data|
      map_id = map_data.id
      next if !map_data.town_map_position || !@available_map_point.include?(map_id)
      next if map_data.town_map_position[0] != pbGetCurrentRegion
      x = map_data.town_map_position[1]
      y = map_data.town_map_position[2]
      map = $map_factory.getMapNoAdd(map_id)
      if map&.events
        if map.events.any? {|id,event| event.name == "BerryPlant" && $PokemonGlobal.eventvars[[map_id, id]]}
          @map_information_data[:berry].push([x,y])
        end
      end
    end
    @map_info_pages.push(:berry) if !@map_information_data[:berry].empty?
    # Roaming Pokemon
    Settings::ROAMING_SPECIES.each_with_index{|pkmn,index|
      next if pkmn[2] > 0 && !$game_switches[pkmn[2]]
      roam_map = $PokemonGlobal.roamPosition[index]
      next if !roam_map
      map_metadata = GameData::MapMetadata.try_get(roam_map)
      next if !map_metadata || !map_metadata.town_map_position ||
              map_metadata.town_map_position[0] != pbGetCurrentRegion
      x = map_metadata.town_map_position[1]
      y = map_metadata.town_map_position[2]
      sp = GameData::Species.get(pkmn[0])
      next if !$player.seen?(sp.id) && !$DEBUG
      @map_information_data[:roam].push([x, y, sp.name.upcase])
    }
    @map_info_pages.push(:roam) if @map_information_data[:roam].length > 0
    @map_pages = :none
    @map_pages = $game_temp.pokegearMapTracker if $game_temp.pokegearMapTracker && @map_info_pages.include?($game_temp.pokegearMapTracker)
    @map_info_pages_id = @map_info_pages.find_index(@map_pages)
  end

  alias map_drawPage drawPage
  def drawPage(page_id)
    map_drawPage(page_id)
    @frame = 0 if page_id == :map
    @helpwindow.visible = (page_id != :map)
    @sprites["fill_overlay"].visible = (page_id != :map)
    @sprites["map"].visible = (page_id == :map)
    @sprites["player"].visible = (page_id == :map) if @sprites["player"]
    @sprites["mapcursor"].visible = (page_id == :map) if @sprites["mapcursor"]
    @sprites["map_overlay"].visible = (page_id == :map)
  end

  alias map_pbUpdateText pbUpdateText
  def pbUpdateText
    map_pbUpdateText
    if pbGetPageId == :map
      textPositions = []
      if @map_startime
        case @map_pages
        when :none  then maptext = "TRACKER: OFF"
        when :berry then maptext = "TRACKER: BERRIES"
        when :roam  then maptext = "TRACKER: ROAMS"
        end
      else
        maptext = pbGetMapLocation(@map_x, @map_y)
      end
      words = pbTextSpliter(@helpwindow, maptext, 10)
      i = 0
      for text in words
        textPositions.push([text.upcase, 144, 16 * i, :left, @baseColor, @shadowColor])
        i += 1
      end
      pbDrawTextPositions(@sprites["overlay"].bitmap, textPositions)
    end
  end

  alias map_pbPageControl pbPageControl
  def pbPageControl
    map_pbPageControl
    if pbGetPageId == :map
      oldmap_pages = @map_pages
      if Input.trigger?(Input::UP)
        pbControlMap(1)
      elsif Input.trigger?(Input::DOWN)
        pbControlMap(-1)
      elsif Input.trigger?(Input::AUX1)
        pbSwitchRegion(-1)
      elsif Input.trigger?(Input::AUX2)
        pbSwitchRegion(1)
      elsif Input.trigger?(Input::USE)
        @map_info_pages_id += 1
        @map_info_pages_id = 0 if @map_info_pages_id > @map_info_pages.length - 1
        @map_pages = @map_info_pages[@map_info_pages_id]
        if oldmap_pages != @map_pages
          $game_temp.pokegearMapTracker = @map_pages
          @map_startime = System.uptime
          pbMapUpdatePages
          pbUpdateText
        end
      end
    end
  end

  alias map_pbUpdate pbUpdate
  def pbUpdate
    if pbGetPageId == :map
      if @map_startime && System.uptime - @map_startime > 1
        @map_startime = nil
        pbUpdateText
      end
      if @frame == 20
        @frame = 0
        @sprites["map_overlay"].visible = !@sprites["map_overlay"].visible
      else
        @frame += 1
      end
    end
    map_pbUpdate
  end

  def pbMapUpdatePages
    overlay = @sprites["map_overlay"].bitmap
    overlay.clear
    imagepos = []
    @map_information_data[@map_pages].each{|point|
      if @map_pages == :berry
        icon = "Graphics/UI/Pokegear/berrytree"
      else
        icon = "Graphics/UI/Pokegear/roam"
        icon += "_" + point[2] if pbCheckGraphicFile(icon + "_" + point[2])
      end
      imagepos.push([icon, point_x_to_screen_x(point[0]), point_y_to_screen_y(point[1])])
    }
    pbDrawImagePositions(overlay, imagepos)
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

  def pbControlMap(sum)
    @map_idx += sum
    @map_idx = 0 if @map_idx >= @map.point.length
    @map_idx = @map.point.length-1 if @map_idx <0
    @map_x = @map.point[@available_map_point[@map_idx]][0]
    @map_y = @map.point[@available_map_point[@map_idx]][1]
    @sprites["mapcursor"].x = point_x_to_screen_x(@map_x)
    @sprites["mapcursor"].y = point_y_to_screen_y(@map_y)
    @map_startime = nil
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
    @sprites["player"].visible = (pbGetPageId == :map && playerpos && new_region_id == playerpos[0]) if @sprites["player"]
    @available_map_point = []
    @map_idx = -1
    @map.point.each_with_index do |point, idx|
      next if point[7] && (@wallmap || point[7] <= 0 || !$game_switches[point[7]])
      @available_map_point.push(idx)
    end
    if !@available_map_point.empty?
      @map_idx = 0
      @map_x = @map.point[@available_map_point[0]][0]
      @map_y = @map.point[@available_map_point[0]][1]
      @sprites["mapcursor"].x = point_x_to_screen_x(@map_x)
      @sprites["mapcursor"].y = point_y_to_screen_y(@map_y)
      @sprites["mapcursor"].visible = true
    else
      @sprites["mapcursor"].visible = false
    end
    @map_startime = nil
    pbUpdateText
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
end

#==============================================================================
# Phone
#==============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :phone, {
  "suffix"    => "phone",
  "order"     => 20,
  "condition" => proc { next $PokemonGlobal.phone && $PokemonGlobal.phone.contacts.length > 0 },
})

class PokemonPokegear_Scene
  alias phone_pbCustomStartScene pbCustomStartScene
  def pbCustomStartScene
    phone_pbCustomStartScene
    @sprites["signal"] = IconSprite.new(274, 20, @viewport)
    @sprites["signal"].setBitmap("Graphics/UI/Pokegear/signal")
    @sprites["signal"].src_rect = Rect.new(Phone::Call.can_make? ? 26 : 0, 0, 26, 24)
    @sprites["list"] = Window_PhoneList.newEmpty(-12, 35, 288, 176, @viewport)
    @sprites["list"].windowskin  = nil
    @sprites["list"].active = false
    @sprites["list"].visible = false
    @sprites["list"].shadowColor = Color.new(248, 248, 248, 0)
    # Rematch readiness icons
    if Phone.rematches_enabled
      @sprites["list"].page_item_max.times do |i|
        @sprites["rematch_#{i}"] = IconSprite.new(286, 61 + (i * 32), @viewport)
      end
    end
    pbRefreshList
  end

  alias phone_drawPage drawPage
  def drawPage(page_id)
    phone_drawPage(page_id)
    @phone_switch_index = -1
    @phone_index = -1
    @sprites["signal"].visible = (page_id == :phone)
    @sprites["list"].visible = (page_id == :phone)
    @sprites["list"].active = (page_id == :phone)
    for i in 0...@sprites["list"].page_item_max
      if @sprites["rematch[#{i}]"]
        @sprites["rematch[#{i}]"].visible = (page_id == :phone)
      end
    end    
    pbRefreshScreen if page_id == :phone # Update for phone
  end

  alias phone_pbUpdateText pbUpdateText
  def pbUpdateText
    phone_pbUpdateText
    @helpwindow.text = _INTL("Whom do you want to call?") if pbGetPageId == :phone
  end

  alias phone_pbPageControl pbPageControl
  def pbPageControl
    phone_pbPageControl
    if pbGetPageId == :phone
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        index = @sprites["list"].index
        contact = @contacts[@sprites["list"].index]
        phone_ContactCommand(contact)
      end
    end
  end

  def phone_ContactCommand(contact)
    loop do
      commands = []
      commands.push(_INTL("Call"))
      commands.push(_INTL("Delete")) if contact.can_hide?
      commands.push(_INTL("Sort"))
      commands.push(_INTL("Cancel"))
      cmd = pbShowCommands(@sprites["helpwindow"], commands, -1)
      cmd += 1 if cmd >= 1 && !contact.can_hide?
      case cmd
      when 0   # Call
        Phone::Call.make_outgoing(contact)
      when 1   # Delete
        contact_count = 0
        $PokemonGlobal.phone.contacts.each { |con| contact_count += 1 if con.visible? }
        if contact_count > 1
          name = contact.display_name
          if pbConfirmMessage(_INTL("Are you sure you want to delete {1} from your phone?", name))
            contact.visible = false
            $PokemonGlobal.phone.sort_contacts
            pbRefreshList
            pbMessage(_INTL("{1} was deleted from your phone contacts.", name))
          end
        else
          pbMessage(_INTL("You cannot delete your last contact!"))
        end
      when 2   # Sort Contacts
        case pbMessage(_INTL("How do you want to sort the contacts?"),
                       [_INTL("By name"),
                        _INTL("By Trainer type"),
                        _INTL("Special first"),
                        _INTL("Cancel")], -1, nil, 0)
        when 0   # By name
          $PokemonGlobal.phone.contacts.sort! { |a, b| a.name <=> b.name }
          $PokemonGlobal.phone.sort_contacts
          pbRefreshList
        when 1   # By trainer type
          $PokemonGlobal.phone.contacts.sort! { |a, b| a.display_name <=> b.display_name }
          $PokemonGlobal.phone.sort_contacts
          pbRefreshList
        when 2   # Special contacts first
          new_contacts = []
          2.times do |i|
            $PokemonGlobal.phone.contacts.each do |con|
              next if (i == 0 && con.trainer?) || (i == 1 && !con.trainer?)
              new_contacts.push(con)
            end
          end
          $PokemonGlobal.phone.contacts = new_contacts
          $PokemonGlobal.phone.sort_contacts
          pbRefreshList
        end
      else
        break
      end
    end
  end

  def pbRefreshList
    @contacts = []
    $PokemonGlobal.phone.contacts.each do |contact|
      @contacts.push(contact) if contact.visible?
    end
    # Create list of commands (display names of contacts) and count rematches
    @commands = []
    @contacts.each do |contact|
      if contact.trainer_type
        @commands.push("#{contact.trainer_type.upcase}:#{contact.name.upcase}")
      else
        @commands.push("#{contact.display_name.upcase}:")
      end
    end
    if @commands.length <= 4
      @blankContact = 4 - @commands.length
      @blankContact.times do
        @commands.push("")
      end
    end
    # Set list's commands
    @sprites["list"].commands = @commands
    @sprites["list"].index = @commands.length - 1 if @sprites["list"].index >= @commands.length
    if @sprites["list"].top_row > @sprites["list"].itemCount - @sprites["list"].page_item_max
      @sprites["list"].top_row = @sprites["list"].itemCount - @sprites["list"].page_item_max
    end
    pbRefreshScreen
  end

  def pbRefreshScreen
    @sprites["list"].refresh
    # Redraw rematch readiness icons
    if @sprites["rematch_0"]
      @sprites["list"].page_item_max.times do |i|
        @sprites["rematch_#{i}"].clearBitmaps
        j = i + @sprites["list"].top_item
        if j < @contacts.length && @contacts[j].can_rematch?
          @sprites["rematch_#{i}"].setBitmap("Graphics/UI/Phone/icon_rematch")
        end
      end
    end
  end
end

#==============================================================================
# Radio
#==============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :radio, {
  "suffix"    => "radio",
  "order"     => 30,
})

class PokemonPokegear_Scene
  alias radio_pbCustomStartScene pbCustomStartScene
  def pbCustomStartScene
    radio_pbCustomStartScene
    @frame_radio = 0
    @radio = []
    @intro = true
    @oldline = ''
    @index_radio = ($game_temp.pokegearRadioCh) ? $game_temp.pokegearRadioCh : 0.5
    @sprites["radio_pointer"] = IconSprite.new(144 + 4 * ((@index_radio / 0.5) - 1), 16, @viewport)
    poinBitmap = Bitmap.new(2, 48)
    poinRect = Rect.new(0, 0, poinBitmap.width, poinBitmap.height)
    poinBitmap.fill_rect(poinRect, Color.new(248, 152, 80))
    @sprites["radio_pointer"].bitmap = poinBitmap
    @sprites["radio_pointer"].visible = false
  end

  alias radio_drawPage drawPage
  def drawPage(page_id)
    radio_drawPage(page_id)
    @sprites["radio_pointer"].visible = (page_id == :radio)
  end

  alias radio_pbUpdateText pbUpdateText
  def pbUpdateText
    radio_pbUpdateText
    if pbGetPageId == :radio
      pbSEPlay("RadioTuning") # Tuning Sound
      @frame = 0
      @frame_radio = 0
      @oldline = ''
      @intro = true
      @radio = pbUpdateRadio
      @helpwindow.text = @radio[1] ? _INTL("{1}", @radio[1][0]) : ""
      @oldline = @helpwindow.text
      textPositions = [
        [_INTL("{1}", @radio[0]), 32, 146, :left, @baseColor, @shadowColor]
      ]
      pbDrawTextPositions(@sprites["overlay"].bitmap, textPositions)
    end
  end

  alias radio_pbPageControl pbPageControl
  def pbPageControl
    radio_pbPageControl
    if pbGetPageId == :radio
      if Input.trigger?(Input::UP) && @index_radio < 20.5
        @index_radio += 0.5 # Increase Freq
        @sprites["radio_pointer"].x += 4
        pbBGMStop
        pbUpdateText
      elsif Input.trigger?(Input::DOWN) && @index_radio > 0.5
        @index_radio -= 0.5 # Decrease Freq
        @sprites["radio_pointer"].x -= 4
        pbBGMStop
        pbUpdateText
      end
    end
    $game_temp.pokegearRadioCh = @index_radio if Input.trigger?(Input::BACK)
  end

  alias radio_pbUpdate pbUpdate
  def pbUpdate
    # Auto update radio
    if pbGetPageId == :radio
      @frame += 1
      if @frame == 80 && @radio[1] # update text
        @frame = 0
        text = @radio[2]
        text = @radio[1] if @intro && @radio[1] # for intro
        oldline = @oldline
        @frame_radio += 1
        if !@intro && text.length == 1
          @helpwindow.text = _INTL("{1}", text[0])
        elsif @frame_radio > text.length - 1 # loop
          if @intro
            @intro = false
            text = @radio[2]
          else
            @radio = pbUpdateRadio
            text = @radio[2]
          end
          @frame_radio = 0
          @helpwindow.text = _INTL("{1}\n{2}", oldline, text[@frame_radio])
        else # run
          @helpwindow.text = _INTL("{1}\n{2}", oldline, text[@frame_radio])
        end
        @oldline = text[@frame_radio]
      end
    end
    radio_pbUpdate
  end

  def pbUpdateRadio
    ret = [] ; array = []
    index = @index_radio
    # Reset Black and White Flute effect
    if $PokemonMap
      if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
        @higher_level_wild_pokemon = false # Black Flute
        @lower_level_wild_pokemon = false # White Flute
      else
        @lower_encounter_rate = false # Black Flute
        @higher_encounter_rate = false # White Flute
      end
    end
    channel = RadioHandlers.get_channel(:radio_show, index)
    if channel
      name = channel[0]
      radio_channel = channel[1]
      text_array = RadioHandlers.call(:radio_show, radio_channel, "show", @helpwindow) || ""
      music = RadioHandlers.get(:radio_show, radio_channel, "bgm")
      pbBGMPlay(music, 80, 100) if music
      ret.push(name)
      for lines in text_array
        ret.push(lines)
      end
    end
    return ret
  end
end

#==============================================================================
# Daycare
#==============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :daycare, {
  "suffix"    => "daycare",
  "order"     => 40,
})

class PokemonPokegear_Scene
  alias daycare_pbCustomStartScene pbCustomStartScene
  def pbCustomStartScene
    daycare_pbCustomStartScene
    $PokemonGlobal.day_care.slots.each_with_index{|slot,i|
      pkmn = slot.pokemon
      @sprites["daycare_slot_#{i}"] = PokemonIconSprite.new(pkmn, @viewport)
      @sprites["daycare_slot_#{i}"].setOffset(PictureOrigin::CENTER)
      @sprites["daycare_slot_#{i}"].active = @active
      @sprites["daycare_slot_#{i}"].x = 66 + 188 * i
      @sprites["daycare_slot_#{i}"].y = 160
    }
    @sprites["daycare_egg"] = IconSprite.new(100, 102, @viewport)
    @sprites["daycare_egg"].setBitmap("Graphics/Pokemon/Eggs/000")
    @sprites["daycare_egg"].visible = false
  end

  alias daycare_drawPage drawPage
  def drawPage(page_id)
    daycare_drawPage(page_id)
    @sprites["daycare_egg"].visible = (page_id == :daycare && DayCare.egg_generated?)
    DayCare.count.times {|i|
      @sprites["daycare_slot_#{i}"].visible = (page_id == :daycare)
    }
  end

  alias daycare_pbUpdateText pbUpdateText
  def pbUpdateText
    daycare_pbUpdateText
    if pbGetPageId == :daycare
      textPositions = []
      textPositions.push(["DAY CARE", Graphics.width - 18, 16, :right, Color.new(224, 248, 160), nil])
      y = 54
      $PokemonGlobal.day_care.slots.each_with_index{|slot,i|
        pkmn = slot.pokemon
        next if !pkmn
        gender = pkmn.male? ? _INTL("♂") : pkmn.female? ? _INTL("♀") : ""
        level_text = sprintf("Λ %03d ", pkmn.level) + gender
        if i == 0
          textPositions.push([pkmn.name, 20, y, :left, Color.new(224, 248, 160), nil])
          textPositions.push([level_text, 20, y + 24, :left, Color.new(224, 248, 160), nil])
        else
          textPositions.push([pkmn.name, Graphics.width - 18, y, :right, Color.new(224, 248, 160), nil])
          textPositions.push([level_text, Graphics.width - 18, y + 24, :right, Color.new(224, 248, 160), nil])
        end
      }
      @helpwindow.text = _INTL("Your Pokémon was holding an Egg!") if DayCare.egg_generated?
      pbDrawTextPositions(@sprites["overlay"].bitmap, textPositions)
    end
  end
end