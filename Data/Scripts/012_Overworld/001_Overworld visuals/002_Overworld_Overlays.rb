#===============================================================================
# Location signpost
#===============================================================================
class LocationWindow
  APPEAR_TIME = 0.4   # In seconds; is also the disappear time
  LINGER_TIME = 1.8   # In seconds; time during which self is fully visible

  def initialize(name)
    @window = Window_AdvancedTextPokemon.new(name)
    @window.setSkin("Graphics/Windowskins/ui_showarea")
    @window.baseColor = Color.new(0, 0, 0)
    @window.shadowColor = Color.new(248, 248, 248, 0)
    @window.width     = Graphics.width
    @window.height    = 64
    @window.x         = 0
    @window.y         = Graphics.height + @window.height
    @window.viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @window.viewport.z = 99999
    @currentmap = $game_map.map_id
    @timer_start = System.uptime
    @delayed = !$game_temp.fly_destination.nil?
  end

  def disposed?
    return @window.disposed?
  end

  def dispose
    @window.dispose
  end

  def update
    return if @window.disposed? || $game_temp.fly_destination
    if @delayed
      @timer_start = System.uptime
      @delayed = false
    end
    @window.update
    if $game_temp.message_window_showing || @currentmap != $game_map.map_id
      @window.dispose
      return
    end
    if System.uptime - @timer_start >= APPEAR_TIME + LINGER_TIME
      @window.y = lerp(Graphics.height - @window.height, Graphics.height + @window.height, APPEAR_TIME, @timer_start + APPEAR_TIME + LINGER_TIME, System.uptime)
      @window.dispose if @window.y + @window.height <= 0
    else
      @window.y = lerp(Graphics.height + @window.height, Graphics.height - @window.height, APPEAR_TIME, @timer_start, System.uptime)
    end
  end
end

#===============================================================================
# Visibility circle in dark maps
#===============================================================================
#===============================================================================
# Visibility circle in dark maps
#===============================================================================
class DarknessSprite < Sprite
  attr_reader :radius

  def initialize(viewport = nil)
    super(viewport)
    @darkness = Bitmap.new(Graphics.width, Graphics.height)
    @radius   = radiusMin
    self.bitmap = @darkness
    self.z      = 99998
    refresh
  end

  def dispose
    @darkness.dispose
    super
  end

  def radiusMin; return 64;  end   # Before using Flash
  def radiusMax; return 176; end   # After using Flash

  def radius=(value)
    @radius = value.round
    refresh
  end

  def refresh
    @darkness.fill_rect(0, 0, Graphics.width, Graphics.height, Color.black)
    cx = Graphics.width / 2
    cy = Graphics.height / 2
    cradius = @radius
    numfades = 5
    (1..numfades).each do |i|
      (cx - cradius..cx + cradius).each do |j|
        diff2 = (cradius * cradius) - ((j - cx) * (j - cx))
        next if diff2 < 0
        diff = Math.sqrt(diff2)
        @darkness.fill_rect(j, cy - diff, 1, diff * 2, Color.new(0, 0, 0, 255.0 * (numfades - i) / numfades))
      end
      cradius = (cradius * 0.9).floor
    end
  end

  def update
    super
    # Snap to correct radius depending on Flash usage
    target = ($PokemonGlobal&.flashUsed) ? radiusMax : radiusMin
    self.radius = target if @radius != target
  end
end

def pbRebuildDarknessOverlay(vp_override = nil)
  ss = ($scene.spritesets[$game_map.map_id] rescue nil)
  vp = vp_override || $game_temp.map_viewport
  return unless ss && vp   # only build when we *know* the map viewport

  # dispose old one
  if (spr = $game_temp.darkness_sprite) && !spr.disposed?
    spr.dispose
  end
  $game_temp.darkness_sprite = nil

  # if this map isn’t dark, also clear Flash
  unless $game_map.metadata&.dark_map
    $PokemonGlobal.flashUsed = false
    Graphics.update
    return
  end

  # build correct overlay on the real map viewport
  spr = DarknessSprite.new(vp)
  ss.addUserSprite(spr)
  $game_temp.darkness_sprite = spr
  spr.radius = ($PokemonGlobal.flashUsed) ? spr.radiusMax : spr.radiusMin
  spr.refresh
  Graphics.update
end

#===============================================================================
# Dark maps
#===============================================================================
def isDarkMap
  map_metadata = $game_map.metadata
  return map_metadata&.dark_map
end

def isDark
  return isDarkMap && !$PokemonGlobal.flashUsed
end

def updateColor
  @color = Color.new(0, 0, 0, 0)
  @color = Color.new(0, 0, 0, 255) if isDark
end

#===============================================================================
# Light effects
#===============================================================================
class LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    @light = IconSprite.new(0, 0, viewport)
    if !nil_or_empty?(filename) && pbResolveBitmap("Graphics/Pictures/" + filename)
      @light.setBitmap("Graphics/Pictures/" + filename)
    else
      @light.setBitmap("Graphics/Pictures/LE")
    end
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
  end

  def disposed?
    return @disposed
  end

  def dispose
    @light.dispose
    @map = nil
    @event = nil
    @disposed = true
  end

  def update
    @light.update
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_Lamp < LightEffect
  def initialize(event, viewport = nil, map = nil)
    lamp = AnimatedBitmap.new("Graphics/Pictures/LE")
    @light = Sprite.new(viewport)
    @light.bitmap = Bitmap.new(128, 64)
    src_rect = Rect.new(0, 0, 64, 64)
    @light.bitmap.blt(0, 0, lamp.bitmap, src_rect)
    @light.bitmap.blt(20, 0, lamp.bitmap, src_rect)
    @light.visible = true
    @light.z       = 1000
    lamp.dispose
    @map = (map) ? map : $game_map
    @event = event
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_Basic < LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    super
    @light.ox = @light.bitmap.width / 2
    @light.oy = @light.bitmap.height / 2
    @light.opacity = 100
  end

  def update
    return if !@light || !@event
    super
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event) - (@event.height * Game_Map::TILE_HEIGHT / 2)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
      @light.zoom_y = @light.zoom_x
    else
      @light.x = @event.screen_x
      @light.y = @event.screen_y - (Game_Map::TILE_HEIGHT / 2)
    end
    @light.tone = $game_screen.tone
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_DayNight < LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    super
    @light.ox = @light.bitmap.width / 2
    @light.oy = @light.bitmap.height / 2
  end

  def update
    return if !@light || !@event
    super
    shade = PBDayNight.getShade
    if shade >= 144   # If light enough, call it fully day
      shade = 255
    elsif shade <= 64   # If dark enough, call it fully night
      shade = 0
    else
      shade = 255 - (255 * (144 - shade) / (144 - 64))
    end
    @light.opacity = 255 - shade
    if @light.opacity > 0
      if (Object.const_defined?(:ScreenPosHelper) rescue false)
        @light.x      = ScreenPosHelper.pbScreenX(@event)
        @light.y      = ScreenPosHelper.pbScreenY(@event) - (@event.height * Game_Map::TILE_HEIGHT / 2)
        @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
        @light.zoom_y = ScreenPosHelper.pbScreenZoomY(@event)
      else
        @light.x = @event.screen_x
        @light.y = @event.screen_y - (Game_Map::TILE_HEIGHT / 2)
      end
      @light.tone.set($game_screen.tone.red,
                      $game_screen.tone.green,
                      $game_screen.tone.blue,
                      $game_screen.tone.gray)
    end
  end
end

#===============================================================================
#
#===============================================================================
EventHandlers.add(:on_new_spriteset_map, :add_light_effects,
  proc { |spriteset, viewport|
    map = spriteset.map   # Map associated with the spriteset (not necessarily the current map)
    map.events.each_key do |i|
      if map.events[i].name[/^outdoorlight\((\w+)\)$/i]
        filename = $~[1].to_s
        spriteset.addUserSprite(LightEffect_DayNight.new(map.events[i], viewport, map, filename))
      elsif map.events[i].name[/^outdoorlight$/i]
        spriteset.addUserSprite(LightEffect_DayNight.new(map.events[i], viewport, map))
      elsif map.events[i].name[/^light\((\w+)\)$/i]
        filename = $~[1].to_s
        spriteset.addUserSprite(LightEffect_Basic.new(map.events[i], viewport, map, filename))
      elsif map.events[i].name[/^light$/i]
        spriteset.addUserSprite(LightEffect_Basic.new(map.events[i], viewport, map))
      end
    end
  }
)

EventHandlers.add(:on_new_spriteset_map, :add_darkness_overlay,
  proc { |spriteset, viewport|
    map = spriteset.map
    next unless map&.metadata&.dark_map
    spr = DarknessSprite.new(viewport)
    spriteset.addUserSprite(spr)
    $game_temp.darkness_sprite = spr     # <— keep a handle
  }
)
EventHandlers.add(:on_new_spriteset_map, :clear_flash_on_light_maps,
  proc { |spriteset, _viewport|
    map = spriteset.map
    unless map.metadata&.dark_map
      $PokemonGlobal.flashUsed = false
      if $game_temp.respond_to?(:darkness_sprite) && (spr = $game_temp.darkness_sprite)
        spr.dispose unless spr.disposed?
        $game_temp.darkness_sprite = nil
      end
    end
  }
)

EventHandlers.add(:on_new_spriteset_map, :flash_dark_rebuild,
  proc { |spriteset, viewport|
    if spriteset.map&.metadata&.dark_map
      pbRebuildDarknessOverlay(viewport)   # <-- pass viewport here
    else
      $PokemonGlobal.flashUsed = false
      if $game_temp.respond_to?(:darkness_sprite) && (spr = $game_temp.darkness_sprite)
        spr.dispose unless spr.disposed?
        $game_temp.darkness_sprite = nil
      end
    end
  }
)

EventHandlers.add(:on_new_spriteset_map, :darkness_setup,
  proc { |_spriteset, _viewport|
    pbRebuildDarknessOverlay
  }
)



class Game_Temp
  attr_accessor :map_viewport, :darkness_sprite
end

EventHandlers.add(:on_new_spriteset_map, :setup_darkness_once,
  proc { |spriteset, viewport|
    # Remember the current map viewport
    $game_temp.map_viewport = viewport

    if spriteset.map&.metadata&.dark_map
      pbRebuildDarknessOverlay(viewport)   # pass the real map viewport
    else
      # Leaving a dark map: clear Flash + any old overlay
      $PokemonGlobal.flashUsed = false
      if (spr = $game_temp.darkness_sprite)
        spr.dispose unless spr.disposed?
        $game_temp.darkness_sprite = nil
      end
    end
  }
)