#-------------------------------------------------------------------------------
# Change EBDX Following Pokemon check since EBDX hasn't updated
#-------------------------------------------------------------------------------
if PluginManager.installed?("Elite Battle: DX")
  module EliteBattle
    def self.follower(battle)
      return nil if !EliteBattle::USE_FOLLOWER_EXCEPTION
      return (FollowingPkmn.active? && battle.scene.firstsendout) ? 0 : nil
    end
  end
end

#-------------------------------------------------------------------------------
# New GameData::Species method for easily get the appropriate Following Pokemon
# graphic
#-------------------------------------------------------------------------------
module GameData
  class Species 
  
    def self.followers_check_graphic_file(path, species, form = 0, gender = 0, shiny = false, shadow = false, subfolder = "")
      try_subfolder = sprintf("%s/", subfolder)
      try_species = species
      try_form    = (form > 0) ? sprintf("_%d", form) : ""
      try_gender  = (gender == 1) ? "_female" : ""
      try_shadow  = (shadow) ? "_shadow" : ""
      factors = []
      factors.push([4, sprintf("%s shiny/", subfolder), try_subfolder]) if shiny
      factors.push([3, try_shadow, ""]) if shadow
      factors.push([2, try_gender, ""]) if gender == 1
      factors.push([1, try_form, ""]) if form > 0
      factors.push([0, try_species, "000"])
      # Go through each combination of parameters in turn to find an existing sprite
      (2**factors.length).times do |i|
        # Set try_ parameters for this combination
        factors.each_with_index do |factor, index|
          value = ((i / (2**index)).even?) ? factor[1] : factor[2]
          case factor[0]
          when 0 then try_species   = value
          when 1 then try_form      = value
          when 2 then try_gender    = value
          when 3 then try_shadow    = value
          when 4 then try_subfolder = value   # Shininess
          end
        end
        # Look for a graphic matching this combination's parameters
        try_species_text = try_species
        ret = pbResolveBitmap(sprintf("%s%s%s%s%s%s", path, try_subfolder,
                                      try_species_text, try_form, try_gender, try_shadow))
        return ret if ret
      end
      return nil
    end
	
    def self.ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      ret = self.followers_check_graphic_file("Graphics/Characters/", species, form,
                                    gender, shiny, shadow, "Followers")
      ret = "Graphics/Characters/Followers/" if nil_or_empty?(ret)
	    return ret
    end
  end
end

#-------------------------------------------------------------------------------
# Prevent Enhanced Stairs from messing with FollowingPokemon
#-------------------------------------------------------------------------------
class Game_FollowerFactory
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    followers = $PokemonGlobal.followers
    return if followers.length == 0
    leader = $game_player
    followers.each_with_index do |follower, i|
      event = @events[i]
      next if !@events[i]
      event.move_speed = leader.move_speed if follower.following_pkmn?
      leader = event
    end
  end
end

#-------------------------------------------------------------------------------
# Make sure shadows of Following Pokemon exist
#-------------------------------------------------------------------------------
class Game_Follower
  alias __followingpkmn__initialize initialize unless method_defined?(:__followingpkmn__initialize)
  def initialize(*args)
    __followingpkmn__initialize(*args)
    calculate_bush_depth
  end
end

#-------------------------------------------------------------------------------
# New option in the Options menu to toggle Following Pokemon
#-------------------------------------------------------------------------------
MenuHandlers.add(:options_menu, :follower_toggle, {
  "name"        => _INTL("Following Pokemon"),
  "order"       => 999,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Let the first Pokemon in your party follow you in the overworld."),
  "condition"   => proc { FollowingPkmn.can_check? && FollowingPkmn.get_event && FollowingPkmn::SHOW_TOGGLE_IN_OPTIONS },
  "get_proc"    => proc { next ($PokemonGlobal&.follower_toggled ? 0 : 1) },
  "set_proc"    => proc { |value, _scene|
    next if !FollowingPkmn.can_check?
    next if $PokemonGlobal.follower_toggled == (value == 0)
    $PokemonGlobal.follower_toggled = (value == 0)
    FollowingPkmn.refresh(false)
  }
})

class PokemonOptionScreen
  alias __followingpkmn__pbStartScreen pbStartScreen unless method_defined?(:__followingpkmn__pbStartScreen)
  def pbStartScreen(*args)
    __followingpkmn__pbStartScreen(*args)
    pbRefreshSceneMap
  end
end

#-------------------------------------------------------------------------------
# New trigger method for Named Events that returns the value of the callback
#-------------------------------------------------------------------------------
class NamedEvent
  def trigger_2(*args)
    @callbacks.each_value { |callback|
      ret = callback.call(*args)
      return ret if !ret.nil?
    }
    return -1
  end
end

#-------------------------------------------------------------------------------
# New trigger method for EventHandlers that returns the value of the callback
#-------------------------------------------------------------------------------
module EventHandlers
  def self.trigger_2(event, *args)
    return @@events[event]&.trigger_2(*args)
  end
end
