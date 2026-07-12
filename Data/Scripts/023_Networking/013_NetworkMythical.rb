#===============================================================================
# NetworkMythical — invisible mythical Pokémon encounter.
#
# The server silently picks a species and map tile every 30 minutes.
# No overworld sprite is shown. When the player steps onto the exact tile,
# a wild battle starts at party_max_level + 5 (capped at 100).
# The server despawns it immediately and broadcasts a purple chat announcement.
#
# Species pool: Mew, Jirachi, Phione, Cresselia, Shaymin, Darkrai, Latios, Latias
#===============================================================================

module NetworkMythical
  @species = nil
  @map_id  = nil
  @x       = nil
  @y       = nil

  def self.active?; !@species.nil?; end

  def self.clear
    @species = @map_id = @x = @y = nil
  end

  def self.set(data)
    @species = data['species'].to_sym
    @map_id  = data['map_id'].to_i
    @x       = data['x'].to_i
    @y       = data['y'].to_i
  end

  # Called every frame from on_frame_update.
  def self.tick
    return unless active?
    return unless NetworkAuth.logged_in?
    return unless $scene.is_a?(Scene_Map)
    return if $game_system.map_interpreter.running?
    return unless $game_map&.map_id == @map_id
    return unless $game_player.x == @x && $game_player.y == @y
    _trigger_encounter
  end

  private

  def self._trigger_encounter
    species = @species
    map_id  = @map_id
    clear  # Clear now so tick doesn't re-fire while the battle runs

    # Notify server immediately — despawns for all other clients
    NetworkClient.send_msg({ action: 'mythical_found', species: species.to_s, map_id: map_id })

    level = 5
    if $player&.party && !$player.party.empty?
      level = [$player.party.compact.map(&:level).max.to_i + 5, 100].min
    end

    return unless GameData::Species.exists?(species)
    WildBattle.start(species, level)
  end
end

#-------------------------------------------------------------------------------
# Mythical Hint NPC — pay Server Tokens to learn the current Mythical's map
# and time left (never its exact tile). Call from an NPC event with:
#   pbMythicalHintNPC
#-------------------------------------------------------------------------------
def pbMythicalHintNPC
  unless NetworkAuth.logged_in?
    pbMessage(_INTL("You need to be online to do this."))
    return false
  end
  # Client already knows this in real time via mythical_spawn/mythical_despawn
  # broadcasts — check locally so we never even offer a purchase that's
  # guaranteed to fail. The server re-checks and won't charge either way
  # (see handleHintRequest in ServerStuff/handlers/mythical.js), but there's
  # no reason to make the player confirm paying 50 tokens just to be told
  # there's nothing to sell.
  unless NetworkMythical.active?
    pbMessage(_INTL("Sorry, there's no Mythical Pokémon out there right now."))
    return false
  end
  cost = Settings::MYTHICAL_HINT_TOKEN_COST
  if NetworkTokens.balance < cost
    pbMessage(_INTL("Not enough tokens.\nYou have {1}, need {2}.", NetworkTokens.balance, cost))
    return false
  end
  return false if pbMessage(
    _INTL("For {1} Server Tokens, I can tell you where the current Mythical Pokémon is. Interested?", cost),
    [_INTL("Yes"), _INTL("No")], 2
  ) != 0

  result = nil
  NetworkClient.on('mythical_hint_bought') { |d| result = d }
  NetworkClient.on('mythical_hint_error')  { |d| result = { '_err' => d['message'] } }
  NetworkClient.send_msg({ action: 'mythical_hint_request' })
  300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.off('mythical_hint_bought'); NetworkClient.off('mythical_hint_error')

  if result.is_a?(Hash) && !result['_err']
    NetworkTokens.set(result['new_tokens'])
    mins = result['minutes_left'].to_i
    pbMessage(_INTL("A {1} was spotted around {2}!\nIt should stick around for about {3} more minute{4}!",
                    result['species_name'], result['map_name'], mins, mins == 1 ? '' : 's'))
    true
  else
    pbMessage(_INTL("Sorry - {1}",
                    result.is_a?(Hash) ? (result['_err'] || "no response from the server.") : "no response from the server."))
    false
  end
end

#-------------------------------------------------------------------------------
# Server event handlers
#-------------------------------------------------------------------------------

NetworkClient.on('mythical_spawn') do |data|
  NetworkMythical.set(data)
end

NetworkClient.on('mythical_despawn') do |_data|
  NetworkMythical.clear
end

#-------------------------------------------------------------------------------
# Frame update hook — checks if player has stepped onto the mythical tile.
#-------------------------------------------------------------------------------
EventHandlers.add(:on_frame_update, :network_mythical_tick,
  proc { NetworkMythical.tick if NetworkClient.connected? }
)
