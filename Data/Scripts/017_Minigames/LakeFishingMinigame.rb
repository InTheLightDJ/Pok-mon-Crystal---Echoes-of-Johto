#===============================================================================
# Lake of Rage Fishing Contest — a 10-minute score-only fishing minigame.
#
# Call from an NPC event's script box:
#   LakeFishingMinigame.show_npc_dialogue
#
# Architecture mirrors the Bug Catching Contest (018_Alternate battle
# modes/002_BugContest.rb): no blocking loop of our own — starting the
# contest just flips switch 104, stamps a start time, and teleports the
# player to the lake. From then on the player plays completely normally:
# they walk around and use their OWN Old/Good/Super Rod from the bag like
# always. While switch 104 is on, the three rod item handlers are
# overridden (see bottom of this file) so a hooked bite runs our Stardew
# Valley-style reel bar (Scene_FishingBar) instead of a real wild encounter.
# Success just adds a rolled weight to the running score — no battling.
#
# A handful of EventHandlers hooks (also bottom of this file) provide:
#   - the on-screen countdown timer (reuses BugContest.rb's TimerDisplay)
#   - automatic session end when the 10 minutes run out
#   - an "end early?" confirmation if the player walks into map 308 while
#     the contest is still running
#
# Ten random tiles within the lake's bounding box (12,6)-(36,27) are picked
# fresh each session as "Gyarados hotspots" — a hooked bite that (secretly)
# lands on one of them adds a big bonus weight on top of the normal roll.
# Occasionally a catch is an item instead of a fish entirely (the player
# keeps these — see ITEM/RARE pools below); those and the final score are
# both handled through the server (ServerStuff/handlers/lakefishing.js)
# exactly like every other multiplayer reward and leaderboard in this game.
#===============================================================================

class PokemonGlobalMetadata
  attr_accessor :lake_fishing_state
end

EventHandlers.add(:on_new_game, :init_lake_fishing_state, proc {
  $PokemonGlobal.lake_fishing_state = nil
})

EventHandlers.add(:on_load, :migrate_lake_fishing_state, proc {
  $PokemonGlobal.lake_fishing_state ||= nil
})

class LakeFishingState
  attr_accessor :active
  attr_accessor :start_time
  attr_accessor :gyarados_tiles
  attr_accessor :weight
  attr_accessor :count
  attr_accessor :gyarados_catches
  attr_accessor :catches

  def initialize
    clear
  end

  def clear
    @active           = false
    @start_time       = nil
    @gyarados_tiles   = []
    @weight           = 0
    @count            = 0
    @gyarados_catches = 0
    @catches          = []
  end

  def expired?
    return false unless @active
    System.uptime - @start_time >= LakeFishingMinigame::SESSION_SECONDS
  end
end

module LakeFishingMinigame
  SESSION_SECONDS = 600   # 10 minutes

  START_MAP_ID = 147
  START_X      = 27
  START_Y      = 32
  START_DIR    = 2   # down

  END_MAP_ID = 308
  END_X      = 23
  END_Y      = 8
  END_DIR    = 4   # left

  # Lake bounding box the Gyarados hotspots are drawn from.
  LAKE_X_RANGE = (12..36)
  LAKE_Y_RANGE = (6..27)
  GYARADOS_TILE_COUNT  = 10
  GYARADOS_BONUS_RANGE = (10..20)

  ROD_WEIGHT_RANGES = {
    OLDROD:   (5..10),
    GOODROD:  (8..15),
    SUPERROD: (10..20),
  }.freeze

  # ── Reward pools ─────────────────────────────────────────────────────────
  COMMON_ITEMS = [
    :GREATBALL, :NETBALL, :LUXURYBALL,
    :REDAPRICORN, :YELLOWAPRICORN, :BLUEAPRICORN, :GREENAPRICORN,
    :PINKAPRICORN, :WHITEAPRICORN, :BLACKAPRICORN, :PURPLEAPRICORN,
    :SUPERPOTION,
    :BATTLECANDYS, :BATTLECANDYM, :BATTLECANDYL,
    :EXPCANDYXS, :EXPCANDYS, :EXPCANDYM, :EXPCANDYL, :EXPCANDYXL,
  ].freeze

  RARE_ITEMS = [
    :RARECANDY, :ULTRABALL, :MASTERBALL,
    :POWERWEIGHT, :POWERBRACER, :POWERBELT, :POWERLENS, :POWERBAND, :POWERANKLET, :DESTINYKNOT,
    :FIRESTONE, :WATERSTONE, :THUNDERSTONE, :LEAFSTONE, :MOONSTONE, :SUNSTONE,
    :DUSKSTONE, :DAWNSTONE, :SHINYSTONE, :ICESTONE, :OVALSTONE,
    :SACREDASH,
    :ULTRACOOLBLOCK, :ULTRABEAUTYBLOCK, :ULTRACUTEBLOCK, :ULTRASMARTBLOCK, :ULTRATOUGHBLOCK,
    :LEGENDPACK,
    :ABILITYCAPSULE,
  ].freeze

  # One extra slot in the rare pool representing "a wardrobe skin", so skins
  # don't drown out the named items despite there being ~170 of them.
  RARE_POOL = (RARE_ITEMS + [:WARDROBE_SKIN]).freeze

  # PlayerMetadata IDs for the wardrobe/skin unlock pool — mirrors
  # ServerStuff/handlers/auction.js's WARDROBE_IDS (131-300, +307 GhostGuy).
  WARDROBE_IDS = ((131..300).to_a + [307]).freeze

  # ── Drop chances ─────────────────────────────────────────────────────────
  # Base 1/10 chance a hooked bite is an item instead of a fish; 1/5 on
  # Wednesday. Of THAT, a further 1/10 chance the item comes from the rare
  # pool (so 1/100 overall on a normal day); on Friday the rare share jumps
  # to 1/2.
  def self._item_chance
    (pbGetTimeNow.wday == 3) ? 0.20 : 0.10   # Wednesday
  end

  def self._rare_share
    (pbGetTimeNow.wday == 5) ? 0.50 : 0.10   # Friday
  end

  def self.state
    $PokemonGlobal.lake_fishing_state ||= LakeFishingState.new
  end

  def self.active?
    state.active
  end

  #=============================================================================
  # NPC entry point
  #=============================================================================
  def self.show_npc_dialogue
    if active?
      pbMessage(_INTL("\"You're already out on the water! Get back here when you're done, or walk into town if you want to call it early.\""))
      return
    end

    commands = [_INTL("Start fishing (10 min)"), _INTL("Check the Hall of Anglers"), _INTL("Never mind")]
    choice = pbMessage(_INTL("The old fisherman leans on his tackle box, eyeing the water.\n" \
                             "\"Lake's been good to me for forty years, {1}. You want in on the ten-minute challenge?\n" \
                             "Bring your own rod - I'm just here to keep score.\"", $player.name),
                       commands, commands.length - 1)
    case choice
    when 0 then start
    when 1 then pbShowLakeFishingLeaderboard
    end
  end

  #=============================================================================
  # Start / end
  #=============================================================================
  def self.start
    state.clear
    state.active     = true
    state.start_time = System.uptime
    state.gyarados_tiles = _pick_gyarados_tiles

    $game_switches[104] = true

    pbMessage(_INTL("\"Alright, {1}! Ten minutes on the clock, starting now.\n" \
                    "Cast out with your rod like normal - I'll take care of the rest!\"", $player.name))

    pbFadeOutIn do
      $game_temp.player_transferring  = true
      $game_temp.player_new_map_id    = START_MAP_ID
      $game_temp.player_new_x         = START_X
      $game_temp.player_new_y         = START_Y
      $game_temp.player_new_direction = START_DIR
      pbDismountBike
      $scene.transfer_player
      $game_map.need_refresh = true
    end
  end

  # teleport: true to force the player to the end coordinates (used when the
  # timer runs out somewhere on the lake). false leaves them wherever they
  # already are (used when they walked into map 308 under their own steam).
  def self.end_session(teleport)
    return unless active?

    # Clear state/switches BEFORE the teleport below — transfer_player may
    # trigger on_enter_map synchronously, and by then this session must
    # already read as inactive so the map-308 early-exit hook doesn't fire
    # a redundant "end early?" prompt right after we just ended it here.
    result = { weight: state.weight, count: state.count, gyarados_catches: state.gyarados_catches, catches: state.catches }
    state.clear
    $game_switches[104] = false
    $game_switches[105] = true

    if teleport
      pbFadeOutIn do
        $game_temp.player_transferring  = true
        $game_temp.player_new_map_id    = END_MAP_ID
        $game_temp.player_new_x         = END_X
        $game_temp.player_new_y         = END_Y
        $game_temp.player_new_direction = END_DIR
        pbDismountBike
        $scene.transfer_player
        $game_map.need_refresh = true
      end
    end

    _finish(result)
  end

  #=============================================================================
  # Gyarados hotspots
  #=============================================================================
  def self._pick_gyarados_tiles
    tiles = []
    while tiles.length < GYARADOS_TILE_COUNT
      pt = [LAKE_X_RANGE.to_a.sample, LAKE_Y_RANGE.to_a.sample]
      tiles << pt unless tiles.include?(pt)
    end
    tiles
  end

  #=============================================================================
  # Called by the rod item handlers (bottom of this file) once pbFishing has
  # already returned true for a hooked bite.
  #=============================================================================
  def self.handle_catch(rod)
    deadline = state.start_time + SESSION_SECONDS
    result = Scene_FishingBar.play(deadline)

    if result == :success
      _resolve_catch(rod)
    else
      pbMessage(_INTL("The line went slack... it got away."))
    end
  end

  def self._resolve_catch(rod)
    if rand < _item_chance
      if rand < _rare_share
        _award_item(RARE_POOL.sample, true)
      else
        _award_item(COMMON_ITEMS.sample, false)
      end
      return
    end

    cast_x = LAKE_X_RANGE.to_a.sample
    cast_y = LAKE_Y_RANGE.to_a.sample
    weight = rand(ROD_WEIGHT_RANGES[rod])
    on_hotspot = state.gyarados_tiles.include?([cast_x, cast_y])
    if on_hotspot
      weight += rand(GYARADOS_BONUS_RANGE)
      state.gyarados_catches += 1
      pbMessage(_INTL("Something huge hit the line! You reeled in a {1} lb monster!", weight))
    else
      pbMessage(_INTL("Got one! Weighs in at {1} lbs.", weight))
    end
    state.weight += weight
    state.count  += 1
  end

  def self._award_item(pick, rare)
    if pick == :WARDROBE_SKIN
      id    = WARDROBE_IDS.sample
      meta  = GameData::PlayerMetadata.get(id) rescue nil
      ttype = (meta && meta.id == id) ? (GameData::TrainerType.get(meta.trainer_type) rescue nil) : nil
      name  = ttype ? "#{ttype.name} Skin" : "Character Skin ##{id}"
      state.catches << { type: 'wardrobe', id: id.to_s, name: name, qty: 1 }
      pbMessage(_INTL("Instead of a fish, something glimmers on the hook...\nA wardrobe charm: {1}!\n(Collect it once you're done fishing!)", name))
    else
      name = GameData::Item.get(pick).name
      qual = rare ? _INTL("You can't believe your luck -") : _INTL("Instead of a fish, you reeled in")
      state.catches << { type: 'item', id: pick.to_s, name: name, qty: 1 }
      pbMessage(_INTL("{1} a {2}!\n(Collect it once you're done fishing!)", qual, name))
    end
  end

  #=============================================================================
  # Wrap-up
  #=============================================================================
  def self._finish(result)
    if NetworkAuth.logged_in?
      if result[:catches].any?
        NetworkClient.send_msg({ action: 'lake_fishing_catches', catches: result[:catches] })
      end
      NetworkClient.send_msg({
        action:       'lake_fishing_score',
        score:        result[:weight],
        display_name: $player.name,
      })
      30.times { Graphics.update; Input.update; NetworkClient.update }
      NetworkAuction.show_prize_claim_dialog
    end
    _show_results(result)
  end

  def self._show_results(result)
    if result[:count] == 0 && result[:catches].empty?
      pbMessage(_INTL("The old fisherman looks at your empty bucket and laughs.\n" \
                      "\"Not a single bite? Happens to the best of us. Come back and try your luck again sometime.\""))
      return
    end

    lines = []
    lines << _INTL("The old fisherman whistles as he tallies up your haul.")
    lines << _INTL("Fish landed: {1}", result[:count])
    lines << _INTL("Total weight: {1} lbs", result[:weight])
    lines << _INTL("Monster bites: {1}", result[:gyarados_catches]) if result[:gyarados_catches] > 0
    pbMessage(lines.join("\n"))

    pbMessage(_INTL("\"That's a score for the books - win or lose, that's fishing. See you back in town!\""))
  end
end

#===============================================================================
# Scene_FishingBar — a Stardew Valley-style reel minigame.
#
# Hold Use to lift the green catch zone; release to let gravity pull it back
# down. Keep the wandering Magikarp icon inside the zone to fill the meter on
# the right before it drains to empty. Returns :success or :failure.
#===============================================================================
class Scene_FishingBar
  TRACK_W = 56
  TRACK_H = 220
  ZONE_H_BASE = 58
  METER_W = 16

  # The catch zone grows with the number of Magikarp in the player's current
  # party, shiny ones counting extra. Six shiny Magikarp: 58 + 6*(5+3) = 106,
  # just under half of TRACK_H (220).
  PER_MAGIKARP_ZONE_BONUS       = 5
  PER_SHINY_MAGIKARP_ZONE_BONUS = 3

  GRAVITY = 0.32
  LIFT    = 0.60
  MAX_VEL = 4.0

  FILL_RATE    = 1.15
  DRAIN_RATE   = 0.65
  MAX_PROGRESS = 100.0

  FISH_INTERVAL_RANGE = (20..50)   # frames between picking a new erratic target
  FISH_LERP           = 0.07

  MAX_SECONDS = 20   # safety cap so a single catch can never hang forever

  def self.play(deadline = nil)
    new.main(deadline)
  end

  def main(deadline)
    @zone_h      = ZONE_H_BASE + _magikarp_zone_bonus
    _create_ui
    @progress    = MAX_PROGRESS * 0.5
    @zone_y      = (TRACK_H - @zone_h) / 2.0
    @zone_vel    = 0.0
    @fish_y      = rand(0..(TRACK_H - 1)).to_f
    @fish_target = @fish_y
    @fish_wait   = 0
    result       = nil
    start_time   = System.uptime

    loop do
      Graphics.update
      Input.update
      _update_zone
      _update_fish
      _update_progress
      _redraw

      if @progress >= MAX_PROGRESS
        result = :success
      elsif @progress <= 0
        result = :failure
      elsif Input.trigger?(Input::BACK)
        result = :failure
      elsif System.uptime - start_time > MAX_SECONDS
        result = :failure
      elsif deadline && System.uptime >= deadline
        result = :failure
      end
      break if result
    end
    result
  ensure
    _dispose
  end

  private

  def _magikarp_zone_bonus
    bonus = 0
    $player.party.each do |pkmn|
      next unless pkmn&.isSpecies?(:MAGIKARP)
      bonus += PER_MAGIKARP_ZONE_BONUS
      bonus += PER_SHINY_MAGIKARP_ZONE_BONUS if pkmn.shiny?
    end
    bonus
  end

  def _create_ui
    sw = Settings::SCREEN_WIDTH
    sh = Settings::SCREEN_HEIGHT
    panel_w = TRACK_W + METER_W + 46
    panel_h = TRACK_H + 56
    @panel_x = (sw - panel_w) / 2
    @panel_y = (sh - panel_h) / 2
    @track_x = @panel_x + 20
    @track_y = @panel_y + 40

    @vp = Viewport.new(0, 0, sw, sh)
    @vp.z = 100000

    @bg_sp = Sprite.new(@vp)
    bmp = Bitmap.new(sw, sh)
    bmp.fill_rect(0, 0, sw, sh, Color.new(0, 0, 0, 140))
    bmp.fill_rect(@panel_x - 2, @panel_y - 2, panel_w + 4, panel_h + 4, Color.new(40, 90, 160))
    bmp.fill_rect(@panel_x, @panel_y, panel_w, panel_h, Color.new(10, 20, 40))
    bmp.font.size  = 15
    bmp.font.bold  = true
    bmp.font.color = Color.new(210, 230, 255)
    bmp.draw_text(@panel_x, @panel_y + 6, panel_w, 20, "Reel it in!", 1)
    @bg_sp.bitmap = bmp

    @track_bmp = Bitmap.new(TRACK_W, TRACK_H)
    @track_sp  = Sprite.new(@vp)
    @track_sp.bitmap = @track_bmp
    @track_sp.x = @track_x
    @track_sp.y = @track_y

    @meter_bmp = Bitmap.new(METER_W, TRACK_H)
    @meter_sp  = Sprite.new(@vp)
    @meter_sp.bitmap = @meter_bmp
    @meter_sp.x = @track_x + TRACK_W + 14
    @meter_sp.y = @track_y

    @fish_sp = Sprite.new(@vp)
    @fish_sp.z = 2
    icon_file = GameData::Species.icon_filename(:MAGIKARP)
    if pbResolveBitmap(icon_file)
      source  = AnimatedBitmap.new(icon_file)
      frame_w = source.width
      frame_h = source.height
      fish_bmp = Bitmap.new(frame_w, frame_h)
      fish_bmp.blt(0, 0, source.bitmap, Rect.new(0, 0, frame_w, frame_h))
      source.dispose
      @fish_sp.bitmap = fish_bmp
      @fish_sp.x  = @track_x + (TRACK_W - frame_w) / 2
      @fish_sp.ox = frame_w / 2
      @fish_sp.oy = frame_h / 2
    end
  end

  def _update_zone
    if Input.press?(Input::USE)
      @zone_vel -= LIFT
    else
      @zone_vel += GRAVITY
    end
    @zone_vel = @zone_vel.clamp(-MAX_VEL, MAX_VEL)
    @zone_y  += @zone_vel
    if @zone_y < 0
      @zone_y   = 0
      @zone_vel = 0
    elsif @zone_y > TRACK_H - @zone_h
      @zone_y   = TRACK_H - @zone_h
      @zone_vel = 0
    end
  end

  def _update_fish
    @fish_wait -= 1
    if @fish_wait <= 0
      @fish_target = rand(0..(TRACK_H - 1)).to_f
      @fish_wait   = rand(FISH_INTERVAL_RANGE)
    end
    @fish_y += (@fish_target - @fish_y) * FISH_LERP
  end

  def _update_progress
    in_zone = @fish_y >= @zone_y && @fish_y <= @zone_y + @zone_h
    @progress += in_zone ? FILL_RATE : -DRAIN_RATE
    @progress = @progress.clamp(0.0, MAX_PROGRESS)
  end

  def _redraw
    @track_bmp.clear
    @track_bmp.fill_rect(0, 0, TRACK_W, TRACK_H, Color.new(20, 60, 110))
    @track_bmp.fill_rect(0, @zone_y.to_i, TRACK_W, @zone_h, Color.new(80, 200, 110, 190))

    @fish_sp.y = @track_y + @fish_y.to_i if @fish_sp.bitmap

    @meter_bmp.clear
    @meter_bmp.fill_rect(0, 0, METER_W, TRACK_H, Color.new(40, 40, 40))
    fill_h = (TRACK_H * (@progress / MAX_PROGRESS)).to_i
    @meter_bmp.fill_rect(0, TRACK_H - fill_h, METER_W, fill_h, Color.new(255, 210, 60))
  end

  def _dispose
    @vp&.dispose
    @bg_sp&.bitmap&.dispose
    @bg_sp&.dispose
    @track_bmp&.dispose
    @track_sp&.dispose
    @meter_bmp&.dispose
    @meter_sp&.dispose
    @fish_sp&.bitmap&.dispose
    @fish_sp&.dispose
  end
end

#===============================================================================
# Rod item handler overrides — identical to the vanilla handlers (see
# 013_Items/002_Item_Effects.rb) except that while the Lake of Rage Fishing
# Contest is active (switch 104 / LakeFishingMinigame.active?), a hooked bite
# runs our own reel-bar catch instead of a real wild encounter. Outside the
# contest, fishing behaves exactly as it always has.
#===============================================================================
ItemHandlers::UseInField.add(:OLDROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  if LakeFishingMinigame.active?
    LakeFishingMinigame.handle_catch(:OLDROD) if pbFishing(true, 1)
  else
    encounter = $PokemonEncounters.has_encounter_type?(:OldRod)
    if pbFishing(encounter, 1)
      $stats.fishing_battles += 1
      pbEncounter(:OldRod)
    end
  end
  next true
})

ItemHandlers::UseInField.add(:GOODROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  if LakeFishingMinigame.active?
    LakeFishingMinigame.handle_catch(:GOODROD) if pbFishing(true, 2)
  else
    encounter = $PokemonEncounters.has_encounter_type?(:GoodRod)
    if pbFishing(encounter, 2)
      $stats.fishing_battles += 1
      pbEncounter(:GoodRod)
    end
  end
  next true
})

ItemHandlers::UseInField.add(:SUPERROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  if LakeFishingMinigame.active?
    LakeFishingMinigame.handle_catch(:SUPERROD) if pbFishing(true, 3)
  else
    encounter = $PokemonEncounters.has_encounter_type?(:SuperRod)
    if pbFishing(encounter, 3)
      $stats.fishing_battles += 1
      pbEncounter(:SuperRod)
    end
  end
  next true
})

#===============================================================================
# EventHandlers — timer HUD, auto-expiry, and the "end early?" prompt.
#===============================================================================

# On-screen countdown, reusing Bug Contest's generic TimerDisplay widget.
EventHandlers.add(:on_map_or_spriteset_change, :show_lake_fishing_timer,
  proc { |scene, _map_changed|
    next unless LakeFishingMinigame.active?
    scene.spriteset.addUserSprite(
      TimerDisplay.new(LakeFishingMinigame.state.start_time, LakeFishingMinigame::SESSION_SECONDS)
    )
  }
)

# Automatically end the session once 10 minutes are up, same guard
# conditions Bug Contest uses so it never interrupts another blocking UI.
EventHandlers.add(:on_frame_update, :lake_fishing_counter,
  proc {
    next unless LakeFishingMinigame.active? && LakeFishingMinigame.state.expired?
    next if $game_player.move_route_forcing || pbMapInterpreterRunning? ||
            $game_temp.message_window_showing
    pbMessage(_INTL("\"Time's up! Reel it in, {1}!\"", $player.name))
    LakeFishingMinigame.end_session(true)
  }
)

# Walking into map 308 while the contest is still running asks if the
# player wants to end early instead of silently doing anything. Declining
# just leaves the contest running and the player standing right where they
# are — deliberately NOT re-teleporting them back to the lake from here,
# since this handler already runs nested inside transfer_player's own call
# stack (Game_MapFactory#setMapChanged -> on_enter_map); starting a second
# transfer_player from inside that stack before the first one unwinds risks
# corrupting the in-progress transfer. They can just walk back on their own.
EventHandlers.add(:on_enter_map, :lake_fishing_early_exit,
  proc { |_old_map_id|
    next unless LakeFishingMinigame.active?
    next unless $game_map.map_id == LakeFishingMinigame::END_MAP_ID
    if pbConfirmMessage(_INTL("\"Heading back already? Want to call the fishing challenge here?\""))
      LakeFishingMinigame.end_session(false)
    else
      pbMessage(_INTL("\"Alright, the clock's still running - head on back to the lake whenever you're ready!\""))
    end
  }
)
