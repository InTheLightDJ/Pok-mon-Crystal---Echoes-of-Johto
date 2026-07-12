#===============================================================================
# NetworkOverworld — real-time overworld presence for online players.
#
# Each logged-in player on the same map is rendered as a moving character
# sprite (with optional follower and name tag) using the same viewport as
# followers and overworld encounters (Spriteset_Map.viewport / @@viewport1).
#
# THROTTLE: position is sent every MOVE_THROTTLE frames (~6-7 /sec at 40 fps),
#   but only when x/y/direction has actually changed.
# APPEARANCE: character_name, follower_name, follower_hue are included in every
#   move packet (cheap strings).  Server stores and relays them to late arrivals.
# FOLLOWERS: positions are derived client-side from the peer's position +
#   direction — no extra network data required.
# Settings toggle: Options → "Online Players" (Show / Hide)
#   When hidden, peer data is still tracked in @peers so sprites can be
#   instantly recreated when the setting is turned back on.
#===============================================================================

MOVE_THROTTLE = 6    # frames between position sends

#-------------------------------------------------------------------------------
# Lightweight Game_Character subclass representing a remote player (or their
# follower) in the overworld.  Drives Sprite_Character without needing a real
# RPGMaker map event.
#-------------------------------------------------------------------------------
class OtherPlayerCharacter < Game_Character
  attr_accessor :character_name, :character_hue

  def initialize(data)
    super()
    @character_name = data['character_name'].to_s
    @character_hue  = (data['character_hue'] || 0).to_i
    @direction      = (data['direction'] || 2).to_i
    @move_speed     = 3
    @walk_anime     = true
    @step_anime     = false
    moveto((data['x'] || 0).to_i, (data['y'] || 0).to_i)
  end

  def update_appearance(char_name, hue = 0)
    @character_name = char_name.to_s
    @character_hue  = hue.to_i
  end

  def update_position(x, y, dir)
    moveto(x.to_i, y.to_i)
    @direction = dir.to_i
  end

  # Sprite_Character calls these to position itself on screen.
  # Delegate to the standard Game_Character screen coordinates.
  def screen_z(height = 0)
    super(height)
  end
end

#===============================================================================
# NetworkOverworld — module managing peer sprites, throttled sends, and
# server event callbacks.
#===============================================================================
module NetworkOverworld
  # Offsets (dx, dy) to place a follower one tile behind the peer.
  FOLLOWER_OFFSET = { 2 => [0, -1], 4 => [1, 0], 6 => [-1, 0], 8 => [0, 1] }

  # Peer entry structure (values in @peers hash):
  #   { 'x', 'y', 'direction', 'character_name', 'follower_name', 'follower_hue',
  #     :char_obj   => OtherPlayerCharacter,
  #     :foll_obj   => OtherPlayerCharacter | nil }

  @peers           = {}   # username => peer data
  @char_sprites    = {}   # username => Sprite_Character
  @follow_sprites  = {}   # username => Sprite_Character | nil
  @name_sprites    = {}   # username => Sprite (name tag bitmap)
  @peer_roles      = {}   # username => role last used to color their name tag
  @frame_count     = 0
  @current_map_id  = nil
  @last_x          = nil
  @last_y          = nil
  @last_dir        = nil
  @last_char       = nil
  @last_foll       = nil  # [name, hue]
  @pending_teleport = nil  # { map_id:, x:, y: } — set by teleport event, executed in tick

  # -------------------------------------------------------------------------
  # Called when the player enters a new map.  Tears down old sprites, sends
  # map_change to the server (which triggers player_left on the old map and
  # returns map_peers for the new map), and registers event callbacks.
  # -------------------------------------------------------------------------
  def self.on_map_enter(map_id, x, y)
    return unless NetworkAuth.logged_in?
    return if map_id == @current_map_id  # already handled this map
    @current_map_id = map_id
    _destroy_all_peers
    _unregister_callbacks
    _register_callbacks
    appearance = _get_my_appearance
    NetworkClient.send_msg({
      action:         'map_change',
      map_id:         map_id,
      x:              x,
      y:              y,
      direction:      $game_player.direction,
      character_name: appearance[:character_name],
      follower_name:  appearance[:follower_name],
      follower_hue:   appearance[:follower_hue]
    })
    # Reset last-sent state so the first move tick always fires a position update
    @last_x = @last_y = @last_dir = @last_char = @last_foll = nil
  end

  # -------------------------------------------------------------------------
  # Called from on_frame_update every frame.
  # -------------------------------------------------------------------------
  def self.tick
    return unless NetworkAuth.logged_in?
    # Execute a pending teleport when the overworld scene is fully in control.
    if @pending_teleport && $scene.is_a?(Scene_Map)
      tp = @pending_teleport
      @pending_teleport = nil
      $game_temp.player_new_map_id    = tp[:map_id]
      $game_temp.player_new_x         = tp[:x]
      $game_temp.player_new_y         = tp[:y]
      $game_temp.player_new_direction = $game_player.direction
      $game_temp.player_transferring  = true
      return
    end
    # Catch map changes that the on_enter_map hook may miss (e.g. some transfers)
    current_map = $game_map&.map_id
    if current_map && current_map != @current_map_id
      on_map_enter(current_map, $game_player.x, $game_player.y)
      return
    end
    @frame_count += 1
    _send_position_if_changed if (@frame_count % MOVE_THROTTLE) == 0
    _update_sprites
  end

  # -------------------------------------------------------------------------
  # Called when the "Online Players" setting is toggled.
  # -------------------------------------------------------------------------
  def self.refresh_visibility
    if $PokemonSystem.show_online_players == 1
      # Hide — dispose sprites but keep peer data
      @char_sprites.each_value   { |s| s&.dispose }
      @follow_sprites.each_value { |s| s&.dispose }
      @name_sprites.each_value   { |s| s&.dispose }
      @char_sprites.clear
      @follow_sprites.clear
      @name_sprites.clear
    else
      # Show — rebuild sprites from existing peer data
      @peers.each { |username, data| _build_sprites_for(username, data) }
    end
  end

  private

  # -------------------------------------------------------------------------
  # Register server event callbacks.
  # -------------------------------------------------------------------------
  def self._register_callbacks
    NetworkClient.on('map_peers') do |d|
      (d['players'] || []).each { |p| _create_peer(p) }
    end
    NetworkClient.on('player_arrived') { |d| _create_peer(d) }
    NetworkClient.on('player_moved')   { |d| _update_peer(d) }
    NetworkClient.on('player_left')    { |d| _destroy_peer(d['username']) }
    NetworkClient.on('teleport') do |d|
      mid = d['map_id'].to_i
      next if mid <= 0
      @pending_teleport = { map_id: mid, x: d['x'].to_i, y: d['y'].to_i }
    end
    NetworkClient.on('world_event_teleport') do |d|
      min_badges = d['min_badges'].to_i
      if min_badges > 0 && $player.badge_count < min_badges
        pbMessage(_INTL("You need at least #{min_badges} Badge#{min_badges == 1 ? '' : 's'} to join the #{d['event_name']} event!"))
      else
        @pending_teleport = { map_id: d['map_id'].to_i, x: d['x'].to_i, y: d['y'].to_i }
      end
    end
    NetworkClient.on('set_invisible') do |d|
      $game_player.transparent = d['value'] ? true : false
    end
  end

  def self._unregister_callbacks
    %w[map_peers player_arrived player_moved player_left teleport set_invisible world_event_teleport].each do |ev|
      NetworkClient.off(ev)
    end
  end

  # -------------------------------------------------------------------------
  # Build the local player's current appearance hash.
  # -------------------------------------------------------------------------
  def self._get_my_appearance
    char_name = $game_player.character_name
    follower  = $PokemonGlobal.followers&.first
    {
      character_name: char_name.to_s,
      follower_name:  follower ? follower.character_name.to_s : nil,
      follower_hue:   follower ? (follower.character_hue || 0).to_i : 0
    }
  end

  # -------------------------------------------------------------------------
  # Send current position + appearance if anything changed since last send.
  # -------------------------------------------------------------------------
  def self._send_position_if_changed
    x   = $game_player.x
    y   = $game_player.y
    dir = $game_player.direction
    app = _get_my_appearance
    foll_key = [app[:follower_name], app[:follower_hue]]
    return if x == @last_x && y == @last_y && dir == @last_dir &&
              app[:character_name] == @last_char && foll_key == @last_foll
    NetworkClient.send_msg({
      action:         'move',
      x:              x,
      y:              y,
      direction:      dir,
      character_name: app[:character_name],
      follower_name:  app[:follower_name],
      follower_hue:   app[:follower_hue]
    })
    @last_x    = x
    @last_y    = y
    @last_dir  = dir
    @last_char = app[:character_name]
    @last_foll = foll_key
  end

  # -------------------------------------------------------------------------
  # Create a peer entry and its sprites.
  # -------------------------------------------------------------------------
  def self._create_peer(data)
    username = data['username']
    return unless username
    return if username == NetworkAuth.username  # never render self
    _destroy_peer(username) if @peers[username] # replace stale entry
    char_obj = OtherPlayerCharacter.new(data)
    foll_obj = _make_follower_obj(data, char_obj) if data['follower_name']
    @peers[username] = data.merge(':char_obj' => char_obj, ':foll_obj' => foll_obj)
    _build_sprites_for(username, @peers[username]) if $PokemonSystem.show_online_players == 0
  end

  # Create the Sprite_Character (and name/follower sprites) for an existing peer.
  def self._build_sprites_for(username, data)
    vp = Spriteset_Map.viewport
    return unless vp
    char_obj = data[':char_obj']
    foll_obj = data[':foll_obj']
    @char_sprites[username]   = Sprite_Character.new(vp, char_obj)
    @follow_sprites[username] = foll_obj ? Sprite_Character.new(vp, foll_obj) : nil
    @name_sprites[username]   = _make_name_sprite(username, data['role'], vp)
    @peer_roles[username]     = data['role']
  end

  # -------------------------------------------------------------------------
  # Update an existing peer's position and appearance.
  # -------------------------------------------------------------------------
  def self._update_peer(data)
    username = data['username']
    return unless username && @peers[username]
    peer = @peers[username]
    peer.merge!(data)
    char_obj = peer[':char_obj']
    char_obj.update_position(data['x'], data['y'], data['direction'])
    char_obj.update_appearance(data['character_name'], 0) if data['character_name']
    # Re-color the name tag if the peer's role changed since we last drew it
    # (e.g. they claimed or lost the King of the Hill title while already on-screen).
    if data['role'] && data['role'] != @peer_roles[username] && @name_sprites[username]
      vp = Spriteset_Map.viewport
      if vp
        @name_sprites[username]&.dispose
        @name_sprites[username] = _make_name_sprite(username, data['role'], vp)
        @peer_roles[username]   = data['role']
      end
    end
    if peer[':foll_obj']
      _reposition_follower(peer[':foll_obj'], char_obj)
    elsif data['follower_name']
      # Follower just appeared — create its object and sprite
      foll_obj = _make_follower_obj(data, char_obj)
      peer[':foll_obj'] = foll_obj
      if @char_sprites[username] && $PokemonSystem.show_online_players == 0
        @follow_sprites[username] = Sprite_Character.new(Spriteset_Map.viewport, foll_obj)
      end
    end
    if !data['follower_name'] && peer[':foll_obj']
      # Follower dismissed
      @follow_sprites[username]&.dispose
      @follow_sprites[username] = nil
      peer[':foll_obj'] = nil
    end
  end

  # -------------------------------------------------------------------------
  # Remove a peer and dispose all its sprites.
  # -------------------------------------------------------------------------
  def self._destroy_peer(username)
    return unless username
    @char_sprites[username]&.dispose
    @follow_sprites[username]&.dispose
    @name_sprites[username]&.dispose
    @char_sprites.delete(username)
    @follow_sprites.delete(username)
    @name_sprites.delete(username)
    @peer_roles.delete(username)
    @peers.delete(username)
  end

  def self._destroy_all_peers
    @peers.keys.each { |u| _destroy_peer(u) }
  end

  # -------------------------------------------------------------------------
  # Every-frame sprite update: animate walk cycles and reposition name tags.
  # -------------------------------------------------------------------------
  def self._update_sprites
    return if @peers.empty?
    @char_sprites.each do |username, sprite|
      next unless sprite && !sprite.disposed?
      next unless @peers[username]
      sprite.update
      foll_sprite = @follow_sprites[username]
      foll_sprite.update if foll_sprite && !foll_sprite.disposed?
      name_sprite = @name_sprites[username]
      if name_sprite && !name_sprite.disposed?
        name_sprite.x = sprite.x - (name_sprite.bitmap&.width || 0) / 2
        name_sprite.y = sprite.y - 40
        name_sprite.z = sprite.z + 1
      end
    end
  end

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------

  # Build a follower OtherPlayerCharacter offset one tile behind the peer.
  def self._make_follower_obj(data, char_obj)
    dir    = (data['direction'] || char_obj.direction || 2).to_i
    offset = FOLLOWER_OFFSET[dir] || [0, -1]
    foll_data = {
      'x'             => char_obj.x + offset[0],
      'y'             => char_obj.y + offset[1],
      'direction'     => dir,
      'character_name'=> data['follower_name'].to_s,
      'character_hue' => (data['follower_hue'] || 0).to_i
    }
    OtherPlayerCharacter.new(foll_data)
  end

  # Reposition an existing follower object behind its peer.
  def self._reposition_follower(foll_obj, char_obj)
    dir    = char_obj.direction || 2
    offset = FOLLOWER_OFFSET[dir] || [0, -1]
    foll_obj.update_position(char_obj.x + offset[0], char_obj.y + offset[1], dir)
  end

  # Create a small name-tag sprite above the peer.
  # role: 'admin' => purple, 'mod' => pink, 'king' => yellow, anything else => white
  def self._make_name_sprite(username, role, viewport)
    text_color = case role
                 when 'admin' then Color.new(180, 80, 255, 255)
                 when 'mod'   then Color.new(255, 105, 180, 255)
                 when 'king'  then Color.new(255, 215, 0, 255)
                 else              Color.new(255, 255, 255, 255)
                 end
    font_size = 16
    padding   = 4
    bmp       = Bitmap.new(username.length * (font_size / 2 + 2) + padding * 2, font_size + padding)
    bmp.font.size    = font_size
    bmp.font.bold    = false
    bmp.font.color   = Color.new(0, 0, 0, 200)
    bmp.draw_text(1, 1, bmp.width, font_size, username, 1)
    bmp.font.color   = text_color
    bmp.draw_text(0, 0, bmp.width, font_size, username, 1)
    sprite         = Sprite.new(viewport)
    sprite.bitmap  = bmp
    sprite.ox      = bmp.width / 2
    sprite.oy      = 0
    sprite
  end
end

#-------------------------------------------------------------------------------
# Hooks
#-------------------------------------------------------------------------------
EventHandlers.add(:on_enter_map, :network_overworld_enter,
  proc { |map_id|
    NetworkOverworld.on_map_enter(map_id, $game_player.x, $game_player.y) if NetworkClient.connected?
  }
)

EventHandlers.add(:on_frame_update, :network_overworld_tick,
  proc { NetworkOverworld.tick if NetworkClient.connected? }
)
