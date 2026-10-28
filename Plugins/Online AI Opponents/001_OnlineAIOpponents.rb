#==============================================================================
# Online AI Opponents (server: handlers/ai_opponents.js)
#
# A regular battle or Pokémon Triad challenge to a player in PLAYERS is never
# sent to them: the challenger plays the AI in their own game, with that
# player's real party (battle) or their 5 strongest Triad cards (Triad), and
# their name and trainer sprite. Only while they're online. When they send a
# challenge themselves it's a normal online match. Their game uploads the
# data to the server whenever it changes. Card duels work the same way in the
# Pokemon TCG plugin (089i_NetDuel.rb, NetPvP::AI_DUELISTS).
#
#   Battle: link-battle rules like online battles. Your party is a copy (no
#           HP / PP lost), no Exp. or money, losing doesn't black you out.
#   Triad:  "pickconverted" like online Triad: win and you pick one of their
#           cards you turned to your color; lose and you lose nothing.
#==============================================================================
module OnlineAI
  PLAYERS        = ["InTheLight"]
  UPLOAD_FRAMES  = 300   # how often an AI player's game checks for changes
  LOSE_TEXT      = "Good battle!"

  module_function

  def ai?(name)
    return false if name.nil?
    me = NetworkAuth.username.to_s.downcase
    PLAYERS.any? { |n| n.downcase == name.to_s.downcase && n.downcase != me }
  end

  def i_am_ai?
    me = NetworkAuth.username.to_s.downcase
    PLAYERS.any? { |n| n.downcase == me }
  end

  # asks the server for an AI player's data; returns it or nil (with a message)
  def fetch(name, kind)
    got = nil
    cb = NetworkClient.on("ai_opponent_data") { |d| got = d }
    NetworkClient.send_msg({ action: "ai_opponent_get", name: name, kind: kind })
    200.times do
      break if got
      Graphics.update
      Input.update
      NetworkClient.update
    end
    NetworkClient.remove("ai_opponent_data", cb)
    unless got && got["ok"]
      pbMessage(got ? got["message"].to_s : _INTL("No response from server."))
      return nil
    end
    got
  end

  #----------------------------------------------------------------------------
  # battle against their party, played by the AI
  #----------------------------------------------------------------------------
  def battle(name, size)
    d = fetch(name, "battle") or return
    data = d["data"]
    opp_name = d["name"].to_s
    sprite = data["trainer_sprite"].to_s.to_sym
    sprite = :POKEMONTRAINER_1 unless GameData::TrainerType.exists?(sprite)
    trainer = NPCTrainer.new(opp_name, sprite)
    trainer.party = Array(data["team"]).filter_map { |t| NetworkTrade.deserialize_pokemon(t) }
    trainer.lose_text = _INTL(LOSE_TEXT)
    if trainer.party.empty?
      pbMessage(_INTL("Could not load {1}'s team data.", opp_name))
      return
    end
    if size == "double" && trainer.party.count { |p| p.able? } < 2
      size = "single"
    end
    player_trainers, ally_items, player_party, party_starts =
      BattleCreationHelperMethods.set_up_player_trainers(trainer.party)
    # like an online battle: a copy of the party, so nothing is lost
    player_party = player_party.map { |p| p ? Marshal.load(Marshal.dump(p)) : nil }
    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle.new(scene, player_party, trainer.party, player_trainers, [trainer])
    battle.party1starts   = party_starts
    battle.party2starts   = [0]
    battle.ally_items     = ally_items
    battle.items          = []
    battle.internalBattle = true
    setBattleRule(size == "double" ? "double" : "single") if $game_temp.battle_rules["size"].nil?
    BattleCreationHelperMethods.prepare_battle(battle)
    battle.expGain   = false
    battle.moneyGain = false
    battle.canLose   = true
    $game_temp.clear_battle_rules
    bgm = pbGetTrainerBattleBGM([trainer])
    pbBattleAnimation(bgm, 1, [trainer]) do
      pbSceneStandby { battle.pbStartBattle }
    end
  end

  #----------------------------------------------------------------------------
  # Triad against their 5 strongest cards
  #----------------------------------------------------------------------------
  def triad(name)
    d = fetch(name, "triad") or return
    deck = Array(d["data"]["deck"]).map(&:to_sym)
    unless deck.size == 5 && deck.all? { |s| GameData::Species.exists?(s) }
      pbMessage(_INTL("{1}'s cards can't be used right now.", d["name"]))
      return
    end
    pbTriadDuel(d["name"].to_s, 0, 9, ["pickconverted"], deck)
    Game.save(safe: true) if defined?(Game) && Game.respond_to?(:save)
  end

  #----------------------------------------------------------------------------
  # an AI player's game: keeps the server's copy of their data up to date
  #----------------------------------------------------------------------------
  def best_triad_deck
    cards = []
    $PokemonGlobal.triads.length.times do |i|
      species, count = $PokemonGlobal.triads[i]
      next unless species && GameData::Species.exists?(species)
      c = TriadCard.new(species)
      total = c.north + c.east + c.south + c.west
      count.to_i.times { cards << [total, species] }
    end
    return nil if cards.size < 5
    cards.sort_by { |total, species| [-total, species.to_s] }.first(5).map { |_, s| s.to_s }
  end

  def upload
    return unless NetworkAuth.logged_in? && i_am_ai?
    @timer = (@timer || 0) + 1
    return if @timer < UPLOAD_FRAMES
    @timer = 0
    @sent ||= {}
    team = NetworkBattle._serialize_team($player.party)
    send_kind("battle", { trainer_sprite: $player.trainer_type.to_s, team: team }) unless team.empty?
    deck = best_triad_deck
    send_kind("triad", { deck: deck }) if deck
  end

  def send_kind(kind, data)
    key = data.inspect
    return if @sent[kind] == key
    NetworkClient.send_msg({ action: "ai_opponent_upload", kind: kind, data: data })
    @sent[kind] = key
  end
end

#------------------------------------------------------------------------------
# challenges: an AI player is played locally, anyone else as before
#------------------------------------------------------------------------------
class << NetworkBattle
  alias online_ai_request_battle request_battle
  def request_battle(target_username = nil, size = 'single')
    return online_ai_request_battle(target_username, size) unless NetworkAuth.logged_in?
    if size == 'double' && $player.able_pokemon_count < 2
      pbMessage(_INTL("You need at least 2 able Pokémon in your party for a Double battle."))
      return
    end
    if target_username.nil?
      players = _fetch_online_players
      if players.empty?
        pbMessage(_INTL("No other players are online right now."))
        return
      end
      target_username = _select_player(players)
      return unless target_username
    end
    return OnlineAI.battle(target_username, size) if OnlineAI.ai?(target_username)
    online_ai_request_battle(target_username, size)
  end
end

class << NetworkTriad
  alias online_ai_request_duel request_duel
  def request_duel
    return online_ai_request_duel unless NetworkAuth.logged_in? && pbCanTriadDuel?
    target = @chip_target
    unless target
      players = _fetch_online_players
      if players.empty?
        pbMessage(_INTL("No other players are online right now."))
        return
      end
      target = _select_player(players, "Who do you want to duel?")
      return unless target
    end
    return OnlineAI.triad(target) if OnlineAI.ai?(target)
    # the original asks for the opponent again: give it this one
    @online_ai_target = target
    online_ai_request_duel
  ensure
    @online_ai_target = nil
  end

  alias online_ai_select_player _select_player
  def _select_player(players, prompt)
    return @online_ai_target if @online_ai_target
    online_ai_select_player(players, prompt)
  end
end

EventHandlers.add(:on_frame_update, :online_ai_upload, proc { OnlineAI.upload })
