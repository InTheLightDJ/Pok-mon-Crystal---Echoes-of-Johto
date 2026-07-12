module FollowingPkmn
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon event and corresponding
  # Follower Data
  #-----------------------------------------------------------------------------
  def self.get
    return nil if !FollowingPkmn.can_check?
    $game_temp.followers.each_follower do |event, follower|
      next if !follower.following_pkmn?
      return [event, follower]
    end
    return nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon event
  #-----------------------------------------------------------------------------
  def self.get_event
    return nil if !FollowingPkmn.can_check?
    ret = FollowingPkmn.get
    return ret.is_a?(Array) ? ret[0] : nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon FollowerData
  #-----------------------------------------------------------------------------
  def self.get_data
    return nil if !FollowingPkmn.can_check?
    ret = FollowingPkmn.get
    return ret.is_a?(Array) ? ret[1] : nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Pokemon Object of the Following Pokemon
  #-----------------------------------------------------------------------------
  def self.get_pokemon
    return nil if !FollowingPkmn.can_check?
    return $player.first_able_pokemon
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking whether the current follower is airborne
  #-----------------------------------------------------------------------------
  def self.airborne_follower?
    return false if !FollowingPkmn.can_check?
    pkmn = FollowingPkmn.get_pokemon
    return false if !pkmn
    return true if pkmn.hasType?(:FLYING)
    return true if pkmn.hasAbility?(:LEVITATE)
    return true if FollowingPkmn::LEVITATING_FOLLOWERS.any? { |s| s == pkmn.species || s.to_s == "#{pkmn.species}_#{pkmn.form}" }
    return false
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking whether the current follower is waterborne
  #-----------------------------------------------------------------------------
  def self.waterborne_follower?
    return false if !FollowingPkmn.can_check?
    pkmn = FollowingPkmn.get_pokemon
    return false if !pkmn
    return true if pkmn.hasType?(:WATER)
    # Don't follow if the Pokemon is manually selected
    return false if FollowingPkmn::SURFING_FOLLOWERS_EXCEPTIONS.any? do |s|
      s == pkmn.species || s.to_s == "#{pkmn.species}_#{pkmn.form}"
    end
    # Follow if the Pokemon flies or levitates
    return true if FollowingPkmn.airborne_follower?
    return false
  end
  #-----------------------------------------------------------------------------
  # Forcefully refresh Following Pokemon sprite with animation (if specified)
  #-----------------------------------------------------------------------------
  def self.refresh(anim = false)
    return if !FollowingPkmn.can_check?
    event = FollowingPkmn.get_event
    FollowingPkmn.remove_sprite
    event&.calculate_bush_depth
    first_pkmn = FollowingPkmn.get_pokemon
    return if !first_pkmn
    FollowingPkmn.refresh_internal
    ret = FollowingPkmn.active?
    event = FollowingPkmn.get_event
    if anim
      anim_name = ret ? :ANIMATION_COME_OUT : :ANIMATION_COME_IN
      anim_id   = nil
      anim_id   = FollowingPkmn.const_get(anim_name) if FollowingPkmn.const_defined?(anim_name)
      if event && anim_id
        $scene.spriteset.addUserAnimation(anim_id, event.x, event.y, false, 1)
        pbMoveRoute($game_player, [PBMoveRoute::WAIT, 2])
        pbWait(0.2)
      end
    end
    FollowingPkmn.change_sprite(first_pkmn) if ret
    FollowingPkmn.move_route([(ret ? PBMoveRoute::STEP_ANIME_ON : PBMoveRoute::STEP_ANIME_OFF)]) if FollowingPkmn::ALWAYS_ANIMATE
    event&.calculate_bush_depth
    $PokemonGlobal.time_taken = 0 if !ret
    return ret
  end
  #-----------------------------------------------------------------------------
  # Forcefully refresh Following Pokemon sprite with animation (if specified)
  #-----------------------------------------------------------------------------
  def self.remove_sprite
    FollowingPkmn.get_event&.character_name = ""
    FollowingPkmn.get_data&.character_name  = ""
    FollowingPkmn.get_event&.character_hue  = 0
    FollowingPkmn.get_data&.character_hue   = 0
  end
  #-----------------------------------------------------------------------------
  # Set the Following Pokemon sprite to a different Pokemon
  #-----------------------------------------------------------------------------
  def self.change_sprite(pkmn)
  # 1) Build intended filename from species/form/gender/shiny/shadow
  shiny = pkmn.shiny?
  shiny = pkmn.superVariant if (pkmn.respond_to?(:superVariant) && !pkmn.superVariant.nil? && pkmn.superShiny?)
  begin
    fname_full = GameData::Species.ow_sprite_filename(pkmn.species, pkmn.form,
      pkmn.gender, shiny, pkmn.shadow)
  rescue
    fname_full = nil
  end

  # 2) Strip the Graphics/Characters/ prefix for character_name
  fname = fname_full ? fname_full.sub(/^Graphics\/Characters\//, "") : nil

  # 3) Fallback if missing or file not found on disk
  #    pbResolveBitmap returns a full path if it exists, or nil if not.
  unless fname && pbResolveBitmap("Graphics/Characters/#{fname}")
    fname = "PKMN-01_A"   # <-- your default follower sheet (put it in Graphics/Characters)
  end

  # 4) Apply to the event + follower data
  ev  = FollowingPkmn.get_event
  dat = FollowingPkmn.get_data
  ev&.character_name  = fname
  dat&.character_name = fname

  # 5) Hue: always apply recolor_hue; super-shiny overrides it during a forced move route
  recolor_hue = pkmn.recolor_hue.to_i
  if ev&.move_route_forcing && pkmn.respond_to?(:superShiny?) && pkmn.superShiny? &&
     pkmn.respond_to?(:superHue)
    hue = pkmn.superHue
  else
    hue = recolor_hue
  end
  ev&.character_hue  = hue
  dat&.character_hue = hue if dat
end
  #-----------------------------------------------------------------------------
end
