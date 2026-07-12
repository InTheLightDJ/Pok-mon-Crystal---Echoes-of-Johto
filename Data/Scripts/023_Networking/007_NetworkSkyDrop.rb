#===============================================================================
# NetworkSkyDrop — server-driven item ball events in the overworld.
#
# Every hour the server announces "Items are falling from the sky in Route X!"
# and broadcasts a sky_drop event with 3 item ball positions on that route.
# Each ball is rendered as a pokéball sprite (Items-02_C row 1) using the same
# Spriteset_Map viewport as other players and followers.
#
# Pickup: auto-triggered when the player steps onto an item ball tile.
#   - Ball is removed instantly for the stepping player.
#   - sky_drop_pickup is sent to the server.
#   - Server broadcasts sky_drop_item_taken so all other clients remove it.
#   - After 10 minutes (or once all 3 are claimed) sky_drop_cleared clears all.
#
# Late arrivals: the map_change handler on the server re-sends the active event
#   (unclaimed balls only) when a player enters the relevant map.
#
# Reroll: if a chosen drop tile is impassable (wall/water/tree), the client
#   picks the first passable spare candidate tile from the route's full tile
#   pool. The drop's x/y is updated so step detection uses the new position.
#===============================================================================

#-------------------------------------------------------------------------------
# Lightweight Game_Character for a static item ball sprite.
# Uses row 1 (0-based) of the Items-02_C sheet — the overworld pokéball graphic.
#-------------------------------------------------------------------------------
class ItemBallCharacter < Game_Character
  def initialize(x, y)
    super()
    @move_speed = 3
    moveto(x, y)
  end
end

#===============================================================================
# NetworkSkyDrop module
#===============================================================================
module NetworkSkyDrop
  @active_event = nil  # { event_id, map_id, route_name, item_id, item_name, drops, candidates }
  @item_sprites = {}   # drop_id => { char_obj, sprite, ch }
  @claimed_ids  = {}   # drop_id => true (claimed this session — prevents re-trigger)
  @last_px      = nil
  @last_py      = nil
  @current_map  = nil

  # -------------------------------------------------------------------------
  # Called every frame by on_frame_update hook.
  # -------------------------------------------------------------------------
  def self.tick
    return unless NetworkAuth.logged_in?
    return unless @active_event
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?

    current_map = $game_map&.map_id
    if current_map != @current_map
      @current_map = current_map
      _rebuild_sprites
    end

    if current_map == @active_event[:map_id]
      px = $game_player.x
      py = $game_player.y
      if px != @last_px || py != @last_py
        @last_px = px
        @last_py = py
        _check_step(px, py)
      end
    end

    _update_sprites
  end

  # -------------------------------------------------------------------------
  # Called when a sky_drop event arrives from the server.
  # -------------------------------------------------------------------------
  def self.on_sky_drop(data)
    _clear_all
    drops = (data['drops'] || []).map do |d|
      { id: d['id'], x: d['x'].to_i, y: d['y'].to_i, taken: false }
    end
    candidates = (data['candidates'] || []).map do |c|
      { x: c['x'].to_i, y: c['y'].to_i }
    end
    @active_event = {
      event_id:   data['event_id'],
      map_id:     data['map_id'].to_i,
      route_name: data['route_name'],
      item_id:    data['item_id'].to_sym,
      item_name:  data['item_name'],
      drops:      drops,
      candidates: candidates
    }
    @claimed_ids.clear
    @last_px = @last_py = nil
    if $game_map&.map_id == @active_event[:map_id]
      @current_map = $game_map.map_id  # prevent tick from triggering a redundant rebuild
      _rebuild_sprites
    end
  end

  # -------------------------------------------------------------------------
  # Called when another player claimed a specific ball.
  # -------------------------------------------------------------------------
  def self.on_item_taken(drop_id)
    if @item_sprites[drop_id]
      @item_sprites[drop_id][:sprite]&.dispose
      @item_sprites.delete(drop_id)
    end
    if @active_event
      drop = @active_event[:drops].find { |d| d[:id] == drop_id }
      drop[:taken] = true if drop
    end
  end

  # -------------------------------------------------------------------------
  # Called when the event expires or all balls are claimed.
  # -------------------------------------------------------------------------
  def self.on_cleared
    _clear_all
  end

  private

  def self._clear_all
    @item_sprites.each_value { |s| s[:sprite]&.dispose }
    @item_sprites.clear
    @active_event = nil
    @claimed_ids.clear
    @last_px = @last_py = nil
    @current_map = nil
  end

  # Build item ball sprites for every unclaimed ball on the current map.
  # If a drop's tile is impassable, reroll it to the first passable spare
  # candidate from the route's full tile pool.
  def self._rebuild_sprites
    @item_sprites.each_value { |s| s[:sprite]&.dispose }
    @item_sprites.clear
    return unless @active_event
    return unless $game_map&.map_id == @active_event[:map_id]
    vp = Spriteset_Map.viewport
    return unless vp

    # Spare candidates = full tile pool minus positions currently assigned to a drop
    drop_positions = @active_event[:drops].map { |d| [d[:x], d[:y]] }
    spare = (@active_event[:candidates] || []).reject { |c| drop_positions.include?([c[:x], c[:y]]) }.dup

    bmp_full = RPG::Cache.character('Items-02_C', 0)
    cols = 4; rows = 4
    cw = bmp_full.width  / cols
    ch = bmp_full.height / rows
    frame_bmp = Bitmap.new(cw, ch)
    frame_bmp.blt(0, 0, bmp_full, Rect.new(0, ch, cw, ch))  # col 0, row 1 = pokéball

    @active_event[:drops].each do |drop|
      next if drop[:taken]
      next if @claimed_ids[drop[:id]]

      unless [2, 4, 6, 8].any? { |d| $game_map.passable?(drop[:x], drop[:y], d) }
        reroll_idx = spare.index { |c| [2, 4, 6, 8].any? { |d| $game_map.passable?(c[:x], c[:y], d) } }
        if reroll_idx
          reroll = spare.delete_at(reroll_idx)
          drop[:x] = reroll[:x]
          drop[:y] = reroll[:y]
        else
          next
        end
      end

      char_obj = ItemBallCharacter.new(drop[:x], drop[:y])
      sprite   = Sprite.new(vp)
      sprite.bitmap = frame_bmp
      sprite.ox     = cw / 2
      sprite.oy     = ch
      @item_sprites[drop[:id]] = { char_obj: char_obj, sprite: sprite, ch: ch }
    end
  end

  # Check if the player just stepped onto any unclaimed ball tile.
  def self._check_step(px, py)
    return unless @active_event
    @active_event[:drops].each do |drop|
      next if drop[:taken]
      next if @claimed_ids[drop[:id]]
      next unless drop[:x] == px && drop[:y] == py
      _pickup_drop(drop)
      break
    end
  end

  # Give item, remove sprite locally, notify server.
  def self._pickup_drop(drop)
    drop[:taken]             = true
    @claimed_ids[drop[:id]] = true

    @item_sprites[drop[:id]]&.tap { |s| s[:sprite]&.dispose }
    @item_sprites.delete(drop[:id])

    item_sym  = @active_event[:item_id]
    item_name = @active_event[:item_name]

    pbMessage(_INTL("Oh! You found a {1}!", item_name))
    pbReceiveItem(item_sym)

    NetworkClient.send_msg({ action: 'sky_drop_pickup', drop_id: drop[:id] })
  end

  # Position item sprites from tile coords each frame.
  def self._update_sprites
    @item_sprites.each do |_drop_id, s|
      next unless s[:sprite] && !s[:sprite].disposed?
      s[:sprite].x = s[:char_obj].screen_x
      s[:sprite].y = s[:char_obj].screen_y
      s[:sprite].z = s[:char_obj].screen_z(s[:ch])
    end
  end
end

#-------------------------------------------------------------------------------
# Server event callbacks
#-------------------------------------------------------------------------------
NetworkClient.on('sky_drop')            { |d| NetworkSkyDrop.on_sky_drop(d) }
NetworkClient.on('sky_drop_item_taken') { |d| NetworkSkyDrop.on_item_taken(d['drop_id']) }
NetworkClient.on('sky_drop_cleared')    { |_| NetworkSkyDrop.on_cleared }

#-------------------------------------------------------------------------------
# Frame update hook — runs step detection and sprite update every frame.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_frame_update, :network_sky_drop_tick,
  proc { NetworkSkyDrop.tick if NetworkClient.connected? }
)
