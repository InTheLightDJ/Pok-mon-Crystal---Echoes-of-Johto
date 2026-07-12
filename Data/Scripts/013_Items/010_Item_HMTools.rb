#===============================================================================
# Keep Switch 103 in sync with $PokemonGlobal.flashUsed so NPC events can
# check it without scripting.  Covers all code paths: Flash move, Flashlight
# item, debug toggle, and every map-exit reset.
#===============================================================================
class PokemonGlobalMetadata
  def flashUsed=(val)
    @flashUsed = val
    $game_switches[103] = val if $game_switches
  end
end

#===============================================================================
# HM Tool items — field move effects without needing a Pokémon to know the move.
# All items bypass badge requirements and the party move check.
#
#   GAUNTLETS   — Rock Smash (if facing a smashrock) or Strength (boulders)
#   MACHETTE    — Cut
#   SURFBOARD   — Surf
#   WINGSUIT    — Fly
#   FLOATIES    — Whirlpool
#   HEAVYROCK   — Dive
#   UMBRELLA    — Waterfall (if facing waterfall) or Headbutt (if facing tree)
#   FLASHLIGHT  — Flash
#===============================================================================

#-------------------------------------------------------------------------------
# GAUNTLETS — Rock Smash / Strength
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:GAUNTLETS, proc { |item|
  facingEvent = $game_player.pbFacingEvent
  if facingEvent && facingEvent.name[/smashrock/i]
    next 2
  end
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used."))
    next 0
  end
  next 2
})

ItemHandlers::UseInField.add(:GAUNTLETS, proc { |item|
  facingEvent = $game_player.pbFacingEvent
  if facingEvent && facingEvent.name[/smashrock/i]
    pbSEPlay("Rock Smash")
    $stats.rock_smash_count += 1
    pbSmashEvent(facingEvent)
    pbRockSmashRandomEncounter
    next true
  end
  pbMessage(_INTL("The Gauntlets glow with power!\nBoulders can now be moved!"))
  $PokemonMap.strengthUsed = true
  next true
})

#-------------------------------------------------------------------------------
# MACHETTE — Cut
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:MACHETTE, proc { |item|
  facingEvent = $game_player.pbFacingEvent
  unless facingEvent && facingEvent.name[/cuttree/i]
    pbMessage(_INTL("There's nothing to cut here."))
    next 0
  end
  next 2
})

ItemHandlers::UseInField.add(:MACHETTE, proc { |item|
  facingEvent = $game_player.pbFacingEvent
  unless facingEvent && facingEvent.name[/cuttree/i]
    next false
  end
  pbSEPlay("Cut")
  $stats.cut_count += 1
  pbSmashEvent(facingEvent)
  next true
})

#-------------------------------------------------------------------------------
# SURFBOARD — Surf
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:SURFBOARD, proc { |item|
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing."))
    next 0
  end
  if !$game_player.can_ride_vehicle_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you."))
    next 0
  end
  if $game_map.metadata&.always_bicycle
    pbMessage(_INTL("Let's enjoy cycling!"))
    next 0
  end
  unless $game_player.pbFacingTerrainTag.can_surf_freely &&
         $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbMessage(_INTL("No surfing here!"))
    next 0
  end
  next 2
})

ItemHandlers::UseInField.add(:SURFBOARD, proc { |item|
  $game_temp.in_menu = false
  pbCancelVehicles
  pbMessage(_INTL("You hop on the Surf Board!"))
  surfbgm = GameData::Metadata.get.surf_BGM
  pbCueBGM(surfbgm, 0.5) if surfbgm
  pbStartSurfing
  next true
})

#-------------------------------------------------------------------------------
# WINGSUIT — Fly
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:WINGSUIT, proc { |item|
  if !$game_player.can_map_transfer_with_follower?
    pbMessage(_INTL("It can't be used when you have someone with you."))
    next 0
  end
  if !$game_map.metadata&.outdoor_map
    pbMessage(_INTL("You can't use that here."))
    next 0
  end
  pbFadeOutIn do
    scene = PokemonRegionMap_Scene.new(-1, false)
    screen = PokemonRegionMapScreen.new(scene)
    ret = screen.pbStartScreen
    $game_temp.fly_destination = ret if ret
    next 99999 if ret
  end
  next ($game_temp.fly_destination) ? 2 : 0
})

ItemHandlers::UseInField.add(:WINGSUIT, proc { |item|
  next false if $game_temp.fly_destination.nil?
  pbMessage(_INTL("You don the Wing Suit and leap into the sky!"))
  $stats.fly_count += 1
  pbFadeOutIn do
    pbSEPlay("Fly")
    $game_temp.player_new_map_id    = $game_temp.fly_destination[0]
    $game_temp.player_new_x         = $game_temp.fly_destination[1]
    $game_temp.player_new_y         = $game_temp.fly_destination[2]
    $game_temp.player_new_direction = 2
    pbDismountBike
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
    pbWait(0.25)
  end
  pbEraseEscapePoint
  $game_temp.fly_destination = nil
  next true
})

#-------------------------------------------------------------------------------
# FLOATIES — Whirlpool
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:FLOATIES, proc { |item|
  unless $PokemonGlobal.surfing
    pbMessage(_INTL("You need to be surfing to use this."))
    next 0
  end
  fx, fy = $game_player.front_xy
  tag = ($game_map.terrain_tag(fx, fy) rescue nil)
  unless tag&.whirlpool
    pbMessage(_INTL("There's no whirlpool here."))
    next 0
  end
  next 2
})

ItemHandlers::UseInField.add(:FLOATIES, proc { |item|
  fx, fy = $game_player.front_xy
  tag = ($game_map.terrain_tag(fx, fy) rescue nil)
  next false unless tag&.whirlpool
  if pbConfirmMessage(_INTL("A fierce whirlpool is raging! Use Whirlpool?"))
    pbSEPlay("Whirlwind") rescue nil
    $game_temp.open_whirlpool = [$game_map.map_id, fx, fy]
    next true
  end
  next false
})

#-------------------------------------------------------------------------------
# HEAVYROCK — Dive
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:HEAVYROCK, proc { |item|
  if $PokemonGlobal.diving
    surface_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      surface_map_id = map_data.id
      break
    end
    unless surface_map_id &&
           $map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
      pbMessage(_INTL("You can't use that here."))
      next 0
    end
  else
    unless $game_map.metadata&.dive_map_id
      pbMessage(_INTL("You can't use that here."))
      next 0
    end
    unless $game_player.terrain_tag.can_dive
      pbMessage(_INTL("You can't use that here."))
      next 0
    end
  end
  next 2
})

ItemHandlers::UseInField.add(:HEAVYROCK, proc { |item|
  wasdiving = $PokemonGlobal.diving
  if $PokemonGlobal.diving
    dive_map_id = nil
    GameData::MapMetadata.each do |map_data|
      next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
      dive_map_id = map_data.id
      break
    end
  else
    dive_map_id = $game_map.metadata&.dive_map_id
  end
  next false unless dive_map_id
  pbMessage(_INTL(wasdiving ? "You surface from the deep!" : "You plunge into the depths!"))
  pbFadeOutIn do
    $game_temp.player_new_map_id    = dive_map_id
    $game_temp.player_new_x         = $game_player.x
    $game_temp.player_new_y         = $game_player.y
    $game_temp.player_new_direction = $game_player.direction
    $PokemonGlobal.surfing = wasdiving
    $PokemonGlobal.diving  = !wasdiving
    pbUpdateVehicle
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  end
  next true
})

#-------------------------------------------------------------------------------
# UMBRELLA — Waterfall (facing waterfall) or Headbutt (facing headbuttree)
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:UMBRELLA, proc { |item|
  if $game_player.pbFacingTerrainTag.waterfall
    next 2
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent && facingEvent.name[/headbutttree/i]
    next 2
  end
  pbMessage(_INTL("You can't use that here."))
  next 0
})

ItemHandlers::UseInField.add(:UMBRELLA, proc { |item|
  if $game_player.pbFacingTerrainTag.waterfall
    pbMessage(_INTL("You brace the Umbrella against the current and scale the waterfall!"))
    pbAscendWaterfall
    next true
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent && facingEvent.name[/headbutttree/i]
    if pbConfirmMessage(_INTL("A Pokémon could be in this tree. Would you like to use Headbutt?"))
      $stats.headbutt_count += 1
      pbMessage(_INTL("You smack the tree with the Umbrella!"))
      pbHeadbuttEffect(facingEvent)
      next true
    end
    next false
  end
  next false
})

#-------------------------------------------------------------------------------
# FLASHLIGHT — Flash
#-------------------------------------------------------------------------------
ItemHandlers::UseFromBag.add(:FLASHLIGHT, proc { |item|
  unless $game_map.metadata&.dark_map
    pbMessage(_INTL("It's already bright enough here."))
    next 0
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("The Flashlight is already lighting the way."))
    next 0
  end
  next 2
})

ItemHandlers::UseInField.add(:FLASHLIGHT, proc { |item|
  next false if $PokemonGlobal.flashUsed
  $PokemonGlobal.flashUsed = true
  pbFadeOutIn do
    if $scene.respond_to?(:map_renderer) && (r = $scene.map_renderer)
      r.refresh
      r.update
    end
    spr = $game_temp.darkness_sprite
    spr.radius = spr.radiusMax if spr && !spr.disposed?
  end
  next true
})
