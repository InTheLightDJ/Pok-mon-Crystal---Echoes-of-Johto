#===============================================================================
# Token Event Fixes - Server Tokens from the roaming Gen 3 spawn and the
# Professor Oak / Elm requests were sometimes never given.
#
# Roaming spawn (023_Networking/006_NetworkRoamSpawn.rb):
#  - On a double-battle tile (tall grass, 30%) or with a partner, the spawn was
#    fought in a double battle. Double battles skip :on_calling_wild_battle and
#    :on_wild_battle_end, so the battle result (+1 token) was never sent. The
#    spawn is now always a single battle.
#  - roam_found / roam_result sent while the connection was down (the tunnel
#    drops a few times a day, Auto Reconnect logs back in) were lost. They now
#    wait and go out once logged in again.
#  - The server sends the active spawn at login (handlers/auth.js), so a spawn
#    this player already placed isn't thrown away when it arrives again.
#
# Professors (023_Networking/013_NetworkProfessor.rb):
#  - The claim waited only 60 frames (1 second) for the server. Over the tunnel
#    the answer often came later: the server gave the tokens but the game said
#    "I couldn't reach the server" and kept the Pokémon. It now waits like the
#    other server calls, and if there's still no answer, asks the server who
#    claimed the request.
#  - The request is fetched fresh each time the professor is talked to, so a
#    request missed while disconnected isn't shown (and refused as the wrong
#    species).
#  - professor_claimed raised an error when that professor's request hadn't
#    been fetched yet.
#
# Mythical Hint NPC (023_Networking/013_NetworkMythical.rb):
#  - Same as the professors: the game waited 5 seconds, said "no response from
#    the server" and dropped the answer, but the server had already taken the
#    50 tokens. It now asks again (the server doesn't charge twice for the same
#    spawn, handlers/mythical.js), and a hint that arrives late is kept, so
#    talking to the NPC again shows it for free.
#===============================================================================

#-------------------------------------------------------------------------------
# Roaming spawn
#-------------------------------------------------------------------------------
module NetworkRoamSpawn
  @outbox = []

  class << self
    alias_method :_tef_activate, :activate

    def activate(species_id, map_id, *rest)
      # the spawn this player placed but couldn't report yet: keep it
      return if @spawned_event_id && @claimed_species == species_id.to_sym
      _tef_activate(species_id, map_id, *rest)
    end

    # the overworld Pokémon is this player's roaming spawn
    def roam_pokemon?(pokemon)
      spawned? && pokemon.is_a?(Pokemon) && pokemon.species == @claimed_species
    end

    def send_or_queue(msg)
      if NetworkAuth.logged_in?
        NetworkClient.send_msg(msg)
      else
        @outbox << msg
      end
    end

    def flush_outbox
      return if @outbox.empty? || !NetworkAuth.logged_in?
      @outbox.each { |m| NetworkClient.send_msg(m) }
      @outbox.clear
    end

    def on_spawn_placed(species_id)
      @claimed_species = species_id
      @active          = false
      send_or_queue({ action: 'roam_found', species_id: species_id.to_s })
    end

    def on_battle_ended(outcome)
      return unless @battle_was_server_spawn
      @battle_was_server_spawn = false
      if defined?($game_temp) && $game_temp
        $game_temp.rescue_chain = [0, CHAIN_RESET_SPECIES]
        $game_temp.catch_combo  = [0, CHAIN_RESET_SPECIES]
      end
      decision = case outcome
                 when 1 then 'won'
                 when 4 then 'caught'
                 else        'fled'
                 end
      send_or_queue({ action: 'roam_result', decision: decision })
    end
  end
end

EventHandlers.add(:on_frame_update, :network_roam_outbox,
  proc { NetworkRoamSpawn.flush_outbox }
)

alias _tef_pbSingleOrDoubleWildBattle pbSingleOrDoubleWildBattle

def pbSingleOrDoubleWildBattle(map_id, x, y, pokemon)
  return _tef_pbSingleOrDoubleWildBattle(map_id, x, y, pokemon) unless NetworkRoamSpawn.roam_pokemon?(pokemon)
  WildBattle.start(pokemon, can_override: true)
  $game_temp.encounter_type = nil
  $game_temp.encounter_triggered = true
end

#-------------------------------------------------------------------------------
# Professors
#-------------------------------------------------------------------------------
NetworkClient.off('professor_claimed')
NetworkClient.on('professor_claimed') do |d|
  req = (d['who'] == 'oak') ? NetworkProfessor.oak_request : NetworkProfessor.elm_request
  if req
    req['claimed']    = true
    req['claimed_by'] = d['claimer']
  end
end

module NetworkProfessor
  def self.request_for(who)
    (who == 'oak') ? @oak : @elm
  end

  # asks the server for the current request; nil if it doesn't answer
  def self.fetch(who, frames = 120)
    fresh = nil
    cb = NetworkClient.on('professor_status') { |d| fresh = d if d['who'] == who }
    NetworkClient.send_msg({ action: 'professor_status', who: who })
    frames.times do
      Graphics.update
      NetworkClient.update
      break if fresh
    end
    NetworkClient.remove('professor_status', cb)
    fresh
  end
end

def professorInteract(who)
  prof_name = (who == 'oak') ? 'Professor Oak' : 'Professor Elm'

  unless NetworkAuth.logged_in?
    pbMessage("You need to be connected to the server to interact with #{prof_name}.")
    return
  end

  # the current request (the cached one only if the server doesn't answer)
  req = NetworkProfessor.fetch(who) || NetworkProfessor.request_for(who)

  if req.nil?
    pbMessage("#{prof_name} seems busy right now. Check back in a moment!")
    return
  end

  species_id   = req['species']
  display_name = req['display_name']
  tokens       = req['tokens']
  claimed      = req['claimed']
  claimer      = req['claimed_by']

  if claimed
    claimer_text = claimer ? claimer : 'someone'
    pbMessage("Oh, #{claimer_text} already brought me a #{display_name} for today's study!\nCome back in a bit, I'll have a new request soon!")
    return
  end

  token_label = "#{tokens} server token#{tokens == 1 ? '' : 's'}"
  pbMessage("Ah, #{$player.name}! I'm researching #{display_name} at the moment.\nIf you bring me one from your party I'll reward you with #{token_label}!")

  species_sym = species_id.to_sym
  party_idx = $player.party.index { |pkmn| pkmn.isSpecies?(species_sym) }

  if party_idx.nil?
    pbMessage("Hmm, you don't have a #{display_name} with you right now.\nRemember — it needs to be in your party, not the PC!")
    return
  end

  pkmn = $player.party[party_idx]
  return unless pbConfirmMessage(
    "Give your #{pkmn.name} (Lv.#{pkmn.level}) to #{prof_name} in exchange for #{token_label}?"
  )

  # send the claim and wait for the server (~5 seconds, as the other server calls)
  result = nil
  cb = NetworkClient.on('professor_claim_result') { |d| result = d if d['who'] == who }
  NetworkClient.send_msg({ action: 'professor_claim', who: who, species: species_id })
  300.times do
    Graphics.update
    NetworkClient.update
    break if result
  end
  NetworkClient.remove('professor_claim_result', cb)

  # no answer: the claim may still have gone through, so ask who has it
  unless result
    now = NetworkProfessor.fetch(who, 300)
    if now && now['claimed'] && now['species'] == species_id && now['claimed_by'] == NetworkAuth.username
      result = { 'ok' => true, 'tokens' => now['tokens'] }
    end
  end

  if result && result['ok']
    $player.party.delete_at(party_idx)
    earned = result['tokens']
    pbMessage("Wonderful! This #{display_name} will be invaluable to my research!\nHere are #{earned} server token#{earned == 1 ? '' : 's'} as promised!")
  elsif result
    case result['reason']
    when 'already_claimed'
      pbMessage("Oh! It seems someone just beat you to it — sorry!\nCome back for my next request!")
    when 'wrong_species'
      pbMessage("Hmm, something went wrong with the transfer. Please try again.")
    else
      pbMessage("Something went wrong. Please try again.")
    end
  else
    pbMessage("I couldn't reach the server. Please try again in a moment.")
  end
end

#-------------------------------------------------------------------------------
# Mythical Hint NPC
#-------------------------------------------------------------------------------
module NetworkMythical
  class << self
    attr_reader :species, :map_id
    attr_accessor :bought_hint
  end

  # the hint already paid for, if it's for the current spawn
  def self.hint_for_current
    h = @bought_hint
    return nil unless h && active?
    return nil unless h['species'].to_s == @species.to_s && h['map_id'].to_i == @map_id
    h
  end

  def self.show_hint(h)
    mins = [h['minutes_left'].to_i - ((System.uptime - h['_at']) / 60).floor, 1].max
    pbMessage(_INTL("A {1} was spotted around {2}!
It should stick around for about {3} more minute{4}!",
                    h['species_name'], h['map_name'], mins, mins == 1 ? '' : 's'))
  end
end

# keeps the balance and the hint even when the answer comes after the game
# stopped waiting
NetworkClient.on('mythical_hint_bought') do |d|
  NetworkTokens.set(d['new_tokens']) if d['new_tokens']
  NetworkMythical.bought_hint = d.merge('_at' => System.uptime) if d['species']
end

def pbMythicalHintNPC
  unless NetworkAuth.logged_in?
    pbMessage(_INTL("You need to be online to do this."))
    return false
  end
  unless NetworkMythical.active?
    pbMessage(_INTL("Sorry, there's no Mythical Pokémon out there right now."))
    return false
  end
  if (h = NetworkMythical.hint_for_current)
    NetworkMythical.show_hint(h)
    return true
  end
  cost = Settings::MYTHICAL_HINT_TOKEN_COST
  if NetworkTokens.balance < cost
    pbMessage(_INTL("Not enough tokens.
You have {1}, need {2}.", NetworkTokens.balance, cost))
    return false
  end
  return false if pbMessage(
    _INTL("For {1} Server Tokens, I can tell you where the current Mythical Pokémon is. Interested?", cost),
    [_INTL("Yes"), _INTL("No")], 2
  ) != 0

  # ask, and if there's no answer ask again: a second ask for the same spawn
  # is free, so a lost answer can't cost the tokens twice
  result = nil
  ok_cb  = NetworkClient.on('mythical_hint_bought') { |d| result = d }
  err_cb = NetworkClient.on('mythical_hint_error')  { |d| result = { '_err' => d['message'] } }
  2.times do
    NetworkClient.send_msg({ action: 'mythical_hint_request' })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    break if result
  end
  NetworkClient.remove('mythical_hint_bought', ok_cb)
  NetworkClient.remove('mythical_hint_error', err_cb)

  if result.is_a?(Hash) && !result['_err']
    NetworkMythical.show_hint(result.merge('_at' => System.uptime))
    true
  else
    pbMessage(_INTL("Sorry - {1}",
                    result.is_a?(Hash) ? (result['_err'] || "no response from the server.") : "no response from the server."))
    false
  end
end
