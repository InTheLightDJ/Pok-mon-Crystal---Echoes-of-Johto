#-------------------------------------------------------------------------------
# Apply recolor_gray (desaturation tone) to the follower sprite every frame.
# The hue is already handled via character_hue in change_sprite.
#-------------------------------------------------------------------------------
class FollowerSprites
  alias __recolor__update update unless method_defined?(:__recolor__update)
  def update(*args)
    __recolor__update(*args)
    return if !FollowingPkmn.active?
    first_pkmn = FollowingPkmn.get_pokemon
    return if !first_pkmn
    gray = first_pkmn.recolor_gray.to_i
    tone = gray > 0 ? Tone.new(0, 0, 0, gray) : Tone.new(0, 0, 0, 0)
    @sprites.each_with_index do |sprite, i|
      next if !$PokemonGlobal.followers[i] || !$PokemonGlobal.followers[i].following_pkmn?
      sprite.tone = tone
    end
  end
end
