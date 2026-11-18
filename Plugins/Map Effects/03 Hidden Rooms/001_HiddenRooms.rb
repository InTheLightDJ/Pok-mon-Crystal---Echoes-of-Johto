#===============================================================================
# Hidden rooms: terrain tag 20 (HiddenRoom). A tile with it (e.g. a black
# tile laid over a room on a higher layer) fades as the player comes near:
#
#   3+ squares away  opaque          1 square away  75% see-through
#   2 squares away   25% see-through on it          gone (100%)
#
# Squares count diagonals as 1. Each tile fades by its own distance;
# PER_TILE = false fades a patch of touching tiles (up, down, left, right)
# together instead, by the distance to its nearest tile. Only the current
# map's tiles fade.
#
# They're drawn over the events and NPCs on their own square (people on the
# square below still show in front, as usual), and an event standing on one
# fades with it, so its head (character frames are taller than a square)
# doesn't show above the black either. The player and followers don't.
#
# The tile itself doesn't count for walking or terrain: the layers under it
# decide (a table under it still blocks, grass under it still has
# encounters), whatever its own passage setting is.
#
# Setting the tag: RPG Maker XP's tileset screen only goes up to 7, so use
# the game's Debug menu > Editors > Edit terrain tags (it saves
# Data/Tilesets.rxdata; close and reopen RPG Maker XP afterwards, or its next
# save of the tilesets puts the old tags back).
#===============================================================================
GameData::TerrainTag.register({
  :id                 => :HiddenRoom,
  :id_number          => 20,
  :ignore_passability => true
})

module HiddenRooms
  TAG       = 20
  PER_TILE  = true
  OPACITY   = [0, 64, 191]   # on it, 1 away, 2 away (255 further)
  FADE_STEP = 32             # opacity per frame toward the target

  module_function

  # map_id => { [x, y] => patch index } of the map's hidden tiles
  def spots(map)
    @spots ||= {}
    @spots[map.map_id] ||= begin
      tags = map.terrain_tags
      found = {}
      map.width.times do |x|
        map.height.times do |y|
          3.times do |layer|
            id = map.data[x, y, layer]
            next if !id || id < TilemapRenderer::TILES_PER_AUTOTILE || tags[id] != TAG
            found[[x, y]] = nil
            break
          end
        end
      end
      patches(found)
    end
  end

  # numbers each patch of touching spots
  def patches(found)
    n = 0
    found.each_key do |start|
      next if found[start]
      found[start] = n
      todo = [start]
      until todo.empty?
        x, y = todo.pop
        [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]].each do |c|
          next unless found.key?(c) && found[c].nil?
          found[c] = n
          todo << c
        end
      end
      n += 1
    end
    found
  end

  def target(dist)
    dist < OPACITY.length ? OPACITY[dist] : 255
  end

  # [x, y] => opacity right now (fading toward the target)
  def opacities(map)
    spots = spots(map)
    return {} if spots.empty?
    @current = {} if @current_map != map.map_id
    @current_map = map.map_id
    px = $game_player.x
    py = $game_player.y
    dist = ->(x, y) { [(x - px).abs, (y - py).abs].max }
    near = {}   # patch => its distance
    unless PER_TILE
      spots.each { |(x, y), p| d = dist.call(x, y); near[p] = d if !near[p] || d < near[p] }
    end
    spots.each do |(x, y), p|
      want = target(PER_TILE ? dist.call(x, y) : near[p])
      now = @current[[x, y]] || want
      now = want > now ? [now + FADE_STEP, want].min : [now - FADE_STEP, want].max
      @current[[x, y]] = now
    end
    @current
  end

  # the hidden tile's opacity at x/y on the current map (nil: none there)
  def opacity_at(map, x, y)
    return nil if @current_map != map.map_id || !@current
    @current[[x, y]]
  end

  def clear; @spots = {}; @current = {}; @current_map = nil; end
end

# a map is scanned again each time it's entered (tags edited in the Debug menu)
EventHandlers.add(:on_enter_map, :hidden_rooms_rescan, proc { |_old_map_id| HiddenRooms.clear })

class TilemapRenderer
  class TileSprite
    attr_accessor :hidden_room
  end

  alias __hidden_rooms_refresh_tile_bitmap refresh_tile_bitmap unless method_defined?(:__hidden_rooms_refresh_tile_bitmap)
  def refresh_tile_bitmap(tile, map, tile_id)
    __hidden_rooms_refresh_tile_bitmap(tile, map, tile_id)
    tile.hidden_room = tile_id >= TILES_PER_AUTOTILE && map.terrain_tags[tile_id] == HiddenRooms::TAG
    tile.opacity = 255   # a reused sprite may have been a faded one
  end

  alias __hidden_rooms_update update unless method_defined?(:__hidden_rooms_update)
  def update
    __hidden_rooms_update
    update_hidden_rooms
  end

  def update_hidden_rooms
    map = $game_map
    return unless map && $game_player
    ops = HiddenRooms.opacities(map)
    return if ops.empty?
    # the tile sprites showing map x/y (as in #update)
    dx = (map.display_x.to_f / Game_Map::X_SUBPIXELS).round
    dx = ((dx + (Graphics.width / 2)) * ZOOM_X) - (Graphics.width / 2) if ZOOM_X != 1
    dy = (map.display_y.to_f / Game_Map::Y_SUBPIXELS).round
    dy = ((dy + (Graphics.height / 2)) * ZOOM_Y) - (Graphics.height / 2) if ZOOM_Y != 1
    tx = dx / DISPLAY_TILE_WIDTH
    ty = dy / DISPLAY_TILE_HEIGHT
    ops.each do |(x, y), op|
      i = x - tx
      j = y - ty
      next if i < 0 || j < 0 || i >= @tiles_horizontal_count || j >= @tiles_vertical_count
      @tiles[i][j].each do |t|
        next unless t.hidden_room
        t.opacity = op
        t.z = t.y + (2 * DISPLAY_TILE_HEIGHT)   # over the characters on its square
      end
    end
  end
end

class Sprite_Character
  alias __hidden_rooms_update update unless method_defined?(:__hidden_rooms_update)
  def update
    __hidden_rooms_update
    return unless @character.is_a?(Game_Event) && !@character.is_a?(Game_Follower) && @character.map == $game_map
    op = HiddenRooms.opacity_at($game_map, @character.x, @character.y)
    self.opacity = self.opacity * (255 - op) / 255 if op
  end
end
