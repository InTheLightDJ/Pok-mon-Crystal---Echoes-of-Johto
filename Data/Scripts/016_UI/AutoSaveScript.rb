#===============================================================================
# "Autosave Feature v21.1"
# By Caruban
#-------------------------------------------------------------------------------
# Features:
# - Automatically saved
#   With this plugin, the game saves automatically when a player catches a Pokémon 
#   or transfers to another map.
#   Except :
#   o Transferring between 2 indoor maps
#   o Transferring between 2 outdoor maps
#   o Transferring while doing the safari game
#   o Transferring while doing a bug catching contest
#   o Transferring while doing a battle challenge
#
# - Manually autosaved
#   You can manually trigger the autosave feature by using the script 'pbAutosave'
#
# - Disabled temporarily by script
#   This plugin can be temporarily toggled on or off using this script
#   'pbSetDisableAutosave = value # (true or false)'
#   or it can be permanently adjusted in the game options.
#
# - Customizable visual indicator
#   The autosave indicator can be customized using text, static images, or animations.
#
# - Map ID autosave overide (New)
#   This feature allows you to customize the autosave function based on map ID. It could 
#   trigger or skip autosave when entering defined maps. You can configure it to either 
#   trigger or skip autosaves when entering specific maps. Additionally, it can be configured
#   to save only when entering a particular map from another designated map. For example, 
#   an autosave only occurs when entering a map with ID 2 from a map with ID 5, not other maps.
#===============================================================================
# Autosave bitmap class
#===============================================================================
class Autosave
  SCREEN_WIDTH  = 320
  SCREEN_HEIGHT = 288
  # All IDs in this array will not be autosaved even if all requirements are met.
  # IDs can be written as Integer (target map id) or 2 length Array (target map id and previous map id)
  AUTOSAVE_BLACKLIST_MAPID = [
    # 2, [7, 5]
  ]

  # All IDs in this array will not be autosaved even if all requirements aren't met.
  AUTOSAVE_WHITELIST_MAPID = [
    # [2,5], 3
  ]
  # Text array
  # [text, x, y, text alignment, text base color, text shadow color]
  SAVE_TEXTS = [
    ["Now Saving...", SCREEN_WIDTH - 4, 4, :right, Color.new(248,248,248), Color.new(97,97,97)]
    # ["Now Saving...", SCREEN_WIDTH - 46, SCREEN_HEIGHT - 34 + 8, :right, Color.new(248,248,248), Color.new(97,97,97)]
  ]

  # Static sprite array
  # [sprite, x, y, clip x, clip y, clip width, clip height]
  SAVE_GRAPHICS = [
    # ["Graphics/UI/Autosave/save_bar", SCREEN_WIDTH - 164, SCREEN_HEIGHT - 34 + 2]
  ]

  # Animated sprite array
  # [sprite, x, y, frame count, frame width, frame height, frame skip]
  ANIMATED_SPRITES = [
    # ["Graphics/UI/Autosave/loading", SCREEN_WIDTH - 30, SCREEN_HEIGHT - 34 + 6, 8, 22, 22, 4]
  ]

  # Use flashing animation for the sprites
  FLASHING_ANIMATION = true

  # Animation duration (min. 0.6 seconds for flashing 3 times)
  ANIMATION_DURATION = 3

  def initialize
    # Bitmap sprite setup
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @viewport.visible = true
    @sprites = {}
    sprites_id = 0
    SAVE_GRAPHICS.each do |sp|
      @sprites["sprite_#{sprites_id}"] = IconSprite.new(sp[1], sp[2], @viewport)
      @sprites["sprite_#{sprites_id}"].setBitmap(sp[0])
      @sprites["sprite_#{sprites_id}"].src_rect = Rect.new(sp[3], sp[4], sp[5], sp[6]) if sp[3] && sp[4] && sp[5] && sp[6]
      @sprites["sprite_#{sprites_id}"].opacity = 0
      sprites_id += 1
    end
    ANIMATED_SPRITES.each do |sp|
      @sprites["sprite_#{sprites_id}"] = AnimatedSprite.new(sp[0], sp[3], sp[4], sp[5], sp[6], @viewport)
      @sprites["sprite_#{sprites_id}"].x = sp[1]
      @sprites["sprite_#{sprites_id}"].y = sp[2]
      @sprites["sprite_#{sprites_id}"].opacity = 0
      @sprites["sprite_#{sprites_id}"].play
      sprites_id += 1
    end
    @bitmapsprite = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    bitmap = @bitmapsprite.bitmap
    pbSetSmallFont(bitmap)
    @bitmapsprite.visible = true
    @bitmapsprite.opacity = 0
    @looptime = 0
    @timer =  System.uptime
    @currentmap = $game_map.map_id
    # Draw texts
    pbDrawTextPositions(bitmap, SAVE_TEXTS)
  end

  def disposed?
    return @bitmapsprite.disposed?
  end
  
  def dispose
    @bitmapsprite.dispose if @bitmapsprite
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def update
    # Clear sprites
    if @currentmap != $game_map.map_id
      # @bitmapsprite.dispose
      self.dispose
      return
    end
    # Animated sprite update
    @sprites.each_value do |s|
      s.update
    end
    # Sprites animations
    duration = [ANIMATION_DURATION / 6.0, 0.1].max
    end_opacity = @looptime % 2 == 0 ? 255 : 0
    cur_opacity = lerp(@looptime % 2 == 0 ? 0 : 255, end_opacity, duration, @timer, System.uptime)
    if FLASHING_ANIMATION || [0,5].include?(@looptime)
      @bitmapsprite.opacity = cur_opacity 
      @sprites.each_value do |s|
        s.opacity = cur_opacity
      end
    end
    if cur_opacity == end_opacity
      @looptime += 1
      @timer = System.uptime
      self.dispose if @looptime >= 6
    end
  end

  def self.can_save_between_maps?(map_id, old_map_id)
    return true  if AUTOSAVE_WHITELIST_MAPID.include?(map_id) || AUTOSAVE_WHITELIST_MAPID.include?([map_id, old_map_id])
    return false if AUTOSAVE_BLACKLIST_MAPID.include?(map_id) || AUTOSAVE_BLACKLIST_MAPID.include?([map_id, old_map_id])
    return false if $map_factory.areConnected?(map_id, old_map_id)
    map_metadata = GameData::MapMetadata.try_get(map_id)
    old_map_metadata = GameData::MapMetadata.try_get(old_map_id)
    return false if !map_metadata || !old_map_metadata
    return true if map_metadata.outdoor_map != old_map_metadata.outdoor_map
    return false
  end
end

#===============================================================================
# Game Option
#===============================================================================
MenuHandlers.add(:options_menu, :autosave, {
  "name"        => _INTL("Autosave"),
  "order"       => 81,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether your game saved automatically or not."),
  "get_proc"    => proc { next $PokemonSystem.autosave },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.autosave = value }
})

#===============================================================================
# General Scripts
#===============================================================================
def pbCanAutosave?
  return $PokemonSystem.autosave == 0 && !$game_temp.disableAutosave
end

def pbSetDisableAutosave=(value)
  $game_temp.disableAutosave = value
end

def pbAutosave(scene = nil)
  scene = $scene if !scene
  return if $PokemonSystem.autosave != 0
  if !pbInSafari? && !pbInBugContest? && !pbBattleChallenge.pbInChallenge?
    echoln "save"
    Game.save(safe: true)
    scene.spriteset.addUserSprite(Autosave.new)
  end
end

#=============================================================================== 
# System and Temp Variables
#===============================================================================
class Game_Temp
  attr_accessor :nextFrameAutosave
  attr_accessor :disableAutosave
  
  def nextFrameAutosave
    @nextFrameAutosave = false if !@nextFrameAutosave
    return @nextFrameAutosave
  end
  def disableAutosave
    @disableAutosave = false if !@disableAutosave
    return @disableAutosave
  end
end

class PokemonSystem
  attr_accessor :autosave
  def autosave
    # Autosave (0=on, 1=off)
    @autosave = 0 if !@autosave
    return @autosave
  end
end

#=============================================================================== 
# Game Screen
#===============================================================================
class Game_Screen
  attr_reader :tone_timer_start
end

#===============================================================================
# Event Handlers
#===============================================================================
# Check if the map are connected
EventHandlers.add(:on_enter_map, :autosave,
  proc { |old_map_id|   # previous map ID, is 0 if no map ID
    next if old_map_id <= 0
    next if !pbCanAutosave?
    $game_temp.nextFrameAutosave = true if Autosave.can_save_between_maps?($game_map.map_id, old_map_id)
  }
)

# On frame update after Walk in or out of a building
EventHandlers.add(:on_frame_update, :autosave,
  proc {
    next if !pbCanAutosave?
    next if !$game_temp.nextFrameAutosave
    next if $game_temp.in_menu || $game_temp.in_battle || $game_player.move_route_forcing || $game_player.moving? ||
            $game_temp.message_window_showing || pbMapInterpreterRunning?
    next if $game_temp.transition_processing
    next if $game_temp.message_window_showing
    next if $game_screen.tone_timer_start
    pbAutosave
    $game_temp.nextFrameAutosave = false
  }
)

# Autosave when caught a pokemon
EventHandlers.add(:on_wild_battle_end, :autosave_catchpkm,
  proc { |species, level, decision|
    next if !pbCanAutosave?
    $game_temp.nextFrameAutosave = true  if decision==4
  }
)

# F5 — manual autosave
EventHandlers.add(:on_frame_update, :autosave_f5,
  proc {
    next if !Input.triggerex?(:F5)
    next if !pbCanAutosave?
    next if $game_temp.in_battle || $game_temp.transition_processing ||
            $game_temp.message_window_showing || pbMapInterpreterRunning? ||
            $game_player.move_route_forcing || $game_screen.tone_timer_start
    pbAutosave
  }
)
