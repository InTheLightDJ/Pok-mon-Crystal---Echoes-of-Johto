#===============================================================================
# NetworkModTools — responds to mod/admin party inspection requests.
#
# party_request:      Server asks for brief party list (name + level).
#                     Response shown in chat to the requesting mod.
#
# party_view_request: Server asks for full serialized data for one party slot.
#                     Response is sent to the mod's in-game client as
#                     party_view_show, which opens PokemonSummaryScreen.
#
# party_view_show:    Received by the requesting mod's client.
#                     Opens the standard Pokémon summary screen (read-only).
#===============================================================================

NetworkClient.on('party_request') do |_data|
  party      = $player&.party || []
  serialized = party.map { |pkmn| { 'name' => pkmn.name, 'level' => pkmn.level } }
  NetworkClient.send_msg({ action: 'party_response', party: serialized })
end

NetworkClient.on('party_view_request') do |data|
  slot = data['slot'].to_i - 1  # server sends 1-based index
  pkmn = $player&.party&.[](slot)
  NetworkClient.send_msg({
    action:  'party_view_response',
    slot:    data['slot'],
    pokemon: pkmn ? NetworkTrade.serialize_pokemon(pkmn) : nil
  })
end

NetworkClient.on('game_switches_request') do |_data|
  on_ids = []
  if $game_switches
    max_id = (defined?($data_switches) && $data_switches.is_a?(Array)) ? $data_switches.size - 1 : 999
    (1..max_id).each { |i| on_ids << i if $game_switches[i] }
  end
  NetworkClient.send_msg({ action: 'game_switches_response', switches: on_ids })
end

NetworkClient.on('game_variables_request') do |_data|
  vars = []
  if $game_variables
    max_id = (defined?($data_variables) && $data_variables.is_a?(Array)) ? $data_variables.size - 1 : 999
    (1..max_id).each do |i|
      v = $game_variables[i]
      vars << { 'id' => i, 'value' => v } if !v.nil? && v != 0
    end
  end
  NetworkClient.send_msg({ action: 'game_variables_response', variables: vars })
end

NetworkClient.on('set_game_switch') do |data|
  id = data['id'].to_i
  $game_switches[id] = (data['value'] == true) if id > 0
end

NetworkClient.on('set_game_variable') do |data|
  id = data['id'].to_i
  $game_variables[id] = data['value'].to_i if id > 0
end

NetworkClient.on('force_save') do |_data|
  begin
    pbSaveGame
  rescue => e
    puts "[ForceSave] #{e.message}"
  end
end

NetworkClient.on('set_debug_mode') do |data|
  $DEBUG = (data['value'] == true)
  puts "[DebugMode] $DEBUG set to #{$DEBUG}"
end

NetworkClient.on('give_badge') do |data|
  idx = data['index'].to_i
  next unless $player && idx >= 0 && idx <= 15
  $player.badges[idx] = true
  puts "[Admin] Badge #{idx + 1} (index #{idx}) granted."
end

NetworkClient.on('set_bug_contest_state') do |data|
  next unless $PokemonGlobal
  state = pbBugContestState
  if data['value']
    state.instance_variable_set(:@lastContest, pbGetTimeNow.to_i)
  else
    state.instance_variable_set(:@lastContest, nil)
  end
end

NetworkClient.on('set_shiny_cards') do |data|
  if data['value'] == true
    $PokemonGlobal.msc_force = true
    puts "[MSC] Shiny cards forced ON."
  else
    $PokemonGlobal.msc_force = false
    puts "[MSC] Shiny cards forced OFF."
  end
end

NetworkClient.on('unlock_wardrobe') do |data|
  if data['mode'] == 'all'
    PlayerUnlocks.unlock_all
  else
    id = data['id'].to_i
    PlayerUnlocks.unlock(id) if id > 0
  end
end

NetworkClient.on('show_team_request') do |_data|
  slots = ($player&.party || []).map do |pkmn|
    {
      'species_name' => pkmn.species_data.name,
      'name'         => pkmn.name,
      'level'        => pkmn.level,
      'shiny'        => pkmn.shiny?,
      'gender'       => pkmn.gender,
      'nature'       => pkmn.nature_id.to_s.downcase.capitalize,
      'ball'         => pkmn.poke_ball ? pkmn.poke_ball.to_s : 'POKEBALL',
      'ivs'          => {
        'hp'  => pkmn.iv[:HP],              'atk' => pkmn.iv[:ATTACK],
        'def' => pkmn.iv[:DEFENSE],         'spa' => pkmn.iv[:SPECIAL_ATTACK],
        'spd' => pkmn.iv[:SPECIAL_DEFENSE], 'spe' => pkmn.iv[:SPEED]
      },
      'evs'          => {
        'hp'  => pkmn.ev[:HP],              'atk' => pkmn.ev[:ATTACK],
        'def' => pkmn.ev[:DEFENSE],         'spa' => pkmn.ev[:SPECIAL_ATTACK],
        'spd' => pkmn.ev[:SPECIAL_DEFENSE], 'spe' => pkmn.ev[:SPEED]
      }
    }
  end
  NetworkClient.send_msg({ action: 'show_team_data', slots: slots })
end

NetworkClient.on('show_pkmn_request') do |data|
  slot = data['slot'].to_i - 1
  pkmn = $player&.party&.[](slot)
  unless pkmn
    NetworkClient.send_msg({ action: 'show_pkmn_data', slot: data['slot'], pkmn: nil })
    next
  end
  NetworkClient.send_msg({
    action: 'show_pkmn_data',
    slot:   data['slot'],
    pkmn:   {
      'species_name' => pkmn.species_data.name,
      'name'         => pkmn.name,
      'shiny'        => pkmn.shiny?,
      'gender'       => pkmn.gender,
      'nature'       => pkmn.nature_id.to_s.downcase.capitalize,
      'ball'         => pkmn.poke_ball ? pkmn.poke_ball.to_s : 'POKEBALL',
      'ivs'          => {
        'hp'  => pkmn.iv[:HP],              'atk' => pkmn.iv[:ATTACK],
        'def' => pkmn.iv[:DEFENSE],         'spa' => pkmn.iv[:SPECIAL_ATTACK],
        'spd' => pkmn.iv[:SPECIAL_DEFENSE], 'spe' => pkmn.iv[:SPEED]
      },
      'evs'          => {
        'hp'  => pkmn.ev[:HP],              'atk' => pkmn.ev[:ATTACK],
        'def' => pkmn.ev[:DEFENSE],         'spa' => pkmn.ev[:SPECIAL_ATTACK],
        'spd' => pkmn.ev[:SPECIAL_DEFENSE], 'spe' => pkmn.ev[:SPEED]
      }
    }
  })
end

NetworkClient.on('set_speed_boost') do |data|
  max = data['max_stage'].to_i.clamp(0, SPEEDUP_STAGES.size - 1)
  $MaxSpeedStage = max
  $GameSpeed = $GameSpeed.clamp(0, $MaxSpeedStage)
  $RefreshEventsForTurbo = true
end

NetworkClient.on('lvl_move_request') do |data|
  query = (data['query'] || '').strip
  sym   = query.upcase.to_sym
  sp    = GameData::Species.try_get(sym)
  unless sp
    GameData::Species.each { |s| (sp = s; break) if s.real_name.casecmp?(query) }
  end
  unless sp
    NetworkClient.send_msg({ action: 'lvl_move_data', text: "Pokémon \"#{query}\" not found." })
    next
  end
  parts = sp.moves.map { |lvl, move_sym|
    mv = GameData::Move.try_get(move_sym)
    mv ? "#{lvl}:#{mv.real_name}" : nil
  }.compact
  text = parts.empty? ? "#{sp.real_name} has no level-up moves." \
                      : "#{sp.real_name} moves: #{parts.join(', ')}"
  NetworkClient.send_msg({ action: 'lvl_move_data', text: text })
end

NetworkClient.on('lvl_evo_request') do |data|
  query = (data['query'] || '').strip
  sym   = query.upcase.to_sym
  sp    = GameData::Species.try_get(sym)
  unless sp
    GameData::Species.each { |s| (sp = s; break) if s.real_name.casecmp?(query) }
  end
  unless sp
    NetworkClient.send_msg({ action: 'lvl_evo_data', text: "Pokémon \"#{query}\" not found." })
    next
  end
  evos = sp.get_evolutions(false).reject { |e| e[1] == :None }
  if evos.empty?
    text = "#{sp.real_name} has no evolutions."
  else
    parts = evos.map do |evo|
      evo_name = GameData::Species.try_get(evo[0])&.real_name || evo[0].to_s
      param    = evo[2] ? " (#{evo[2]})" : ''
      "#{evo_name} via #{evo[1]}#{param}"
    end
    text = "#{sp.real_name} evolves: #{parts.join(', ')}"
  end
  NetworkClient.send_msg({ action: 'lvl_evo_data', text: text })
end

NetworkClient.on('kurt_balls_finish') do |_data|
  jobs = $player&.kurt_jobs
  next unless jobs && jobs.any?
  totals = Hash.new(0)
  jobs.each { |job| totals[job[:ball]] += job[:qty] }
  $player.kurt_jobs = []
  totals.each { |ball_sym, qty| pbReceiveItem(ball_sym, qty) }
end

NetworkClient.on('give_item') do |data|
  item_sym = (data['item'] || '').upcase.to_sym
  next unless GameData::Item.exists?(item_sym) && $bag
  $bag.add(item_sym)
  puts "[Admin] Item #{item_sym} granted."
end

NetworkClient.on('give_money') do |data|
  amount = data['amount'].to_i
  next if amount <= 0 || !$player
  $player.money += amount
  puts "[Admin] ¥#{amount} granted."
end

NetworkClient.on('party_view_show') do |data|
  pkmn_data = data['pokemon']
  unless pkmn_data
    pbMessage(_INTL("That slot is empty."))
    next
  end
  pkmn = NetworkTrade.deserialize_pokemon(pkmn_data)
  next unless pkmn
  pbFadeOutIn do
    scene  = PokemonSummary_Scene.new
    screen = PokemonSummaryScreen.new(scene)
    screen.pbStartScreen([pkmn], 0)
  end
end
