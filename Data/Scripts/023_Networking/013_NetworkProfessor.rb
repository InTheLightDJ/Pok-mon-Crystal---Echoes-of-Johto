#===============================================================================
# NetworkProfessor — Professor Oak & Elm collection missions.
#
# Each professor broadcasts a Pokémon request every hour. The first player to
# bring the requested Pokémon to the professor's NPC earns server tokens:
#   2t  — normal Gen 1 (Oak) / Gen 2 (Elm) request
#   4t  — rare Gen 3–4 request
#   10t — legendary / mythical request
#
# NPC event script calls:
#   professorOakRequest   — for Professor Oak's NPC
#   professorElmRequest   — for Professor Elm's NPC
#===============================================================================

module NetworkProfessor
  @oak = nil   # { 'species', 'display_name', 'tokens', 'claimed', 'claimed_by' }
  @elm = nil

  def self.oak_request; @oak; end
  def self.elm_request; @elm; end

  def self.setup_callbacks
    # New request announced (hourly renewal or initial push)
    NetworkClient.on('professor_request') do |d|
      case d['who']
      when 'oak' then @oak = d
      when 'elm' then @elm = d
      end
    end
    # Response to an explicit professor_status query
    NetworkClient.on('professor_status') do |d|
      case d['who']
      when 'oak' then @oak = d
      when 'elm' then @elm = d
      end
    end
    # Someone claimed the request — mark as claimed in cache
    NetworkClient.on('professor_claimed') do |d|
      case d['who']
      when 'oak' then @oak['claimed'] = true; @oak['claimed_by'] = d['claimer'] if @oak
      when 'elm' then @elm['claimed'] = true; @elm['claimed_by'] = d['claimer'] if @elm
      end
    end
  end
end

NetworkProfessor.setup_callbacks

#===============================================================================
# Shared NPC interaction logic
#===============================================================================

def professorInteract(who)
  prof_name = (who == 'oak') ? 'Professor Oak' : 'Professor Elm'

  unless NetworkAuth.logged_in?
    pbMessage("You need to be connected to the server to interact with #{prof_name}.")
    return
  end

  # Fetch the cached request; if missing, ask the server and wait briefly
  req = (who == 'oak') ? NetworkProfessor.oak_request : NetworkProfessor.elm_request
  if req.nil?
    NetworkClient.send_msg({ action: 'professor_status', who: who })
    40.times do
      Graphics.update
      NetworkClient.update
      req = (who == 'oak') ? NetworkProfessor.oak_request : NetworkProfessor.elm_request
      break if req
    end
  end

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

  # Look for the species in the player's party
  species_sym = species_id.to_sym
  party_idx = nil
  $player.party.each_with_index do |pkmn, i|
    if pkmn.isSpecies?(species_sym)
      party_idx = i
      break
    end
  end

  if party_idx.nil?
    pbMessage("Hmm, you don't have a #{display_name} with you right now.\nRemember — it needs to be in your party, not the PC!")
    return
  end

  pkmn = $player.party[party_idx]
  return unless pbConfirmMessage(
    "Give your #{pkmn.name} (Lv.#{pkmn.level}) to #{prof_name} in exchange for #{token_label}?"
  )

  # Send claim and wait for the server's confirmation (up to ~2 seconds)
  result = nil
  cb = NetworkClient.on('professor_claim_result') { |d| result = d if d['who'] == who }
  NetworkClient.send_msg({ action: 'professor_claim', who: who, species: species_id })
  60.times do
    Graphics.update
    NetworkClient.update
    break if result
  end
  NetworkClient.remove('professor_claim_result', cb)

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

def professorOakRequest
  professorInteract('oak')
end

def professorElmRequest
  professorInteract('elm')
end
