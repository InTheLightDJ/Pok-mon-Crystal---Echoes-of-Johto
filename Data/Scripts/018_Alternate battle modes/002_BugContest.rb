# Persisted across saves
class PokemonGlobalMetadata
  attr_accessor :bug_contest_highest_score
  attr_accessor :bug_contest_player_highest_score
end

# Initialize for new games
EventHandlers.add(:on_new_game, :init_bug_contest_high_scores, proc {
  $PokemonGlobal.bug_contest_highest_score = 0
  $PokemonGlobal.bug_contest_player_highest_score = 0
})

# Migrate old saves
EventHandlers.add(:on_load, :migrate_bug_contest_high_scores, proc {
  $PokemonGlobal.bug_contest_highest_score ||= 0
  $PokemonGlobal.bug_contest_player_highest_score ||= 0
})

#===============================================================================
#
#===============================================================================
class BugContestState
  attr_accessor :ballcount
  attr_accessor :decision
  attr_accessor :lastPokemon
  attr_accessor :timer_start
  attr_accessor :species_chain, :boss_spawned

  CONTESTANT_NAMES = [
    _INTL("Bug Catcher Ed"),
    _INTL("Bug Catcher Benny"),
    _INTL("Bug Catcher Josh"),
    _INTL("Camper Barry"),
    _INTL("Cool Trainer Nick"),
    _INTL("Lass Abby"),
    _INTL("Picnicker Cindy"),
    _INTL("Youngster Samuel"),
    _INTL("Champion Light"),
    _INTL("Kurt"),
    _INTL("Bug Catcher Joe"),
    _INTL("Bug Catcher Tim"),
    _INTL("Bug Catcher Mike"),
    _INTL("Bug Catcher Tom")
  ]
  CUSTOM_CONTESTANTS = []
  TIME_ALLOWED = Settings::BUG_CONTEST_TIME   # In seconds

  def initialize
    clear
    @lastContest = nil
    @bug_contest_highest_score = 700
    @bug_contest_player_highest_score = 0
  end

    def self.contestant_names1
    rival = ($game_variables && $game_variables[12] && $game_variables[12] != "") ? $game_variables[12] : _INTL("Rival")
    # Insert rival between “Champion Light” and “Kurt”
    arr = CONTESTANT_NAMES.dup
    arr.insert(2, rival)
    return arr
  end

  # Returns whether the last contest ended less than 24 hours ago.
  def pbContestHeld?
    return false if !@lastContest
    elapsed = pbGetTimeNow.to_i - @lastContest
    # Negative elapsed means @lastContest is ahead of the game clock (corrupted state).
    # Clear it so the player isn't permanently locked out.
    if elapsed < 0
      @lastContest = nil
      return false
    end
    return elapsed < 24 * 60 * 60
  end

  def self.pbAddContestant(score, name = nil)
    name ||= _INTL("Custom Contestant {1}", CUSTOM_CONTESTANTS.length + 1)
    CUSTOM_CONTESTANTS << [name, score]
  end

  def expired?
    return false if !undecided?
    return false if TIME_ALLOWED <= 0
    return System.uptime - timer_start >= TIME_ALLOWED
  end

  def clear
    @bug_contest_player_highest_score = 600
    @ballcount    = 0
    @ended        = false
    @inProgress   = false
    @decision     = 0
    @lastPokemon  = nil
    @otherparty   = []
    @contestants  = []
    @places       = []
    @start        = nil
    @contestMaps  = []
    @reception    = []
    @species_chain = Hash.new(0)
    @boss_spawned = false
  end

  def inProgress?
    return @inProgress
  end

  def undecided?
    return (@inProgress && @decision == 0)
  end

  def decided?
    return (@inProgress && @decision != 0) || @ended
  end

  def pbSetPokemon(chosenpoke)
    @chosenPokemon = chosenpoke
  end

  def pbSetContestMap(*maps)
    maps.each do |map|
      if map.is_a?(String)   # Map metadata flag
        GameData::MapMetadata.each do |map_data|
          @contestMaps.push(map_data.id) if map_data.has_flag?(map)
        end
      else
        @contestMaps.push(map)
      end
    end
  end

  # Reception map is handled separately from contest map since the reception map
  # can be outdoors, with its own grassy patches.
  def pbSetReception(*maps)
    maps.each do |map|
      if map.is_a?(String)   # Map metadata flag
        GameData::MapMetadata.each do |map_data|
          @reception.push(map_data.id) if map_data.has_flag?(map)
        end
      else
        @reception.push(map)
      end
    end
  end

  def pbOffLimits?(map)
    return false if @contestMaps.include?(map)
    return false if @reception.include?(map)
    return true
  end

  def pbSetJudgingPoint(startMap, startX, startY, dir = 8)
    @start = [startMap, startX, startY, dir]
  end

def pbJudge
  judgearray = []
  # Player row first if caught something
  if @lastPokemon
    score = pbBugContestScore(@lastPokemon)
    score += 100 if @lastPokemon.shiny?
    score += $game_variables[43]
    judgearray.push([-1, @lastPokemon.species, score, @lastPokemon.shiny?])
  end

  # Build encounterable maps
  maps_with_encounters = []
  @contestMaps.each do |map|
    enc_type = :BugContest
    enc_type = :Land if !$PokemonEncounters.map_has_encounter_type?(map, enc_type)
    if $PokemonEncounters.map_has_encounter_type?(map, enc_type)
      maps_with_encounters.push([map, enc_type])
    end
  end
  raise _INTL("There are no Bug Contest/Land encounters for any Bug Contest maps.") if maps_with_encounters.empty?

  # ---- CUSTOM contestants (ONE PASS ONLY) ----
  BugContestState::CUSTOM_CONTESTANTS.each_with_index do |(name, fixed_score), i|
    enc_data = maps_with_encounters.sample
    enc = $PokemonEncounters.choose_wild_pokemon_for_map(enc_data[0], enc_data[1])
    raise _INTL("No encounters for map {1} somehow, so can't judge contest.", enc_data[0]) if !enc
    species = enc[0]
    shiny_flag = rand(100) < 5
    # [contestant_id, species, score, shiny, name_override]
    judgearray.push([10_000 + i, species, fixed_score, shiny_flag, name])
  end

  # ---- RANDOMIZED normal contestants ----
  @contestants.each do |cont|
    enc_data = maps_with_encounters.sample
    enc = $PokemonEncounters.choose_wild_pokemon_for_map(enc_data[0], enc_data[1])
    raise _INTL("No encounters for map {1} somehow, so can't judge contest.", enc_data[0]) if !enc
    pokemon = Pokemon.new(enc[0], enc[1])
    pokemon.hp = rand(1...pokemon.totalhp)
    score = pbBugContestScore(pokemon)
    score += 100
    score += rand(-10..150)
    score += $game_variables[39]
    score -= rand(-10...pbBugContestState.ballcount)
    if pokemon.shiny? == false
      pokemon.shiny = rand(1000) < Settings::SHINY_POKEMON_CHANCE
    end
    score += 100 if pokemon.shiny?
    name = BugContestState.contestant_names1[cont]
    score += 100 if name == "Champion Light" && score > 600
    score += rand(-10..100) if name == "Champion Light"
    $PokemonGlobal.bug_contest_player_highest_score ||= 600
    if score > $PokemonGlobal.bug_contest_player_highest_score + 20
      score = $PokemonGlobal.bug_contest_player_highest_score + 20 + rand(-10...10)
    end
    judgearray.push([cont, pokemon.species, score, pokemon.shiny?])
  end

  # Need at least 3 total entries to place top 3 (player + customs + normals)
  raise _INTL("Too few bug-catching contestants") if judgearray.length < 3

  # Sort by score desc and record top 3
  judgearray.sort! { |a, b| b[2] <=> a[2] }
  @places = []
  @places.push(judgearray[0])
  @places.push(judgearray[1])
  @places.push(judgearray[2])

  # Highest-ever tracking
  $PokemonGlobal.bug_contest_highest_score ||= 0
  $PokemonGlobal.bug_contest_player_highest_score ||= 0
  highest_score_this_contest = judgearray[0][2]
  if highest_score_this_contest > $PokemonGlobal.bug_contest_highest_score
    $PokemonGlobal.bug_contest_highest_score = highest_score_this_contest
  end

  # Player-best tracking
  player_entry = judgearray.find { |entry| entry[0] == -1 }
  if player_entry && player_entry[2] > $PokemonGlobal.bug_contest_player_highest_score
    $PokemonGlobal.bug_contest_player_highest_score = player_entry[2]
  end
end


  def pbGetPlaceInfo(place)
   cont = @places[place][0]
  name_override = @places[place][4] rescue nil  # may be nil

  if cont == -1
    $game_variables[1] = $player.name
  elsif name_override
    $game_variables[1] = name_override
  else
    $game_variables[1] = BugContestState.contestant_names1[cont]
  end
    $game_variables[2] = GameData::Species.get(@places[place][1]).name
    $game_variables[3] = @places[place][2]
    $game_switches[75] = @places[place][3] 
  end

  def pbClearIfEnded
    clear if !@inProgress && (!@start || @start[0] != $game_map.map_id)
  end

  def pbStartJudging
    @decision = 1
    pbJudge
    if $scene.is_a?(Scene_Map)
      pbFadeOutIn do
        $game_temp.player_transferring  = true
        $game_temp.player_new_map_id    = @start[0]
        $game_temp.player_new_x         = @start[1]
        $game_temp.player_new_y         = @start[2]
        $game_temp.player_new_direction = @start[3]
        pbDismountBike
        $scene.transfer_player
        $game_map.need_refresh = true   # in case player moves to the same map
      end
    end
  end

  def pbIsContestant?(i)
    return @contestants.any? { |item| i == item }
  end

  def pbStart(ballcount)
    @ballcount = ballcount
    @inProgress = true
    @otherparty = []
    @lastPokemon = nil
    @lastContest = nil
    @timer_start = System.uptime
    @places = []
    chosenpkmn = $player.party[@chosenPokemon]
    $player.party.length.times do |i|
      @otherparty.push($player.party[i]) if i != @chosenPokemon
    end
    @contestants = []
    [5, CONTESTANT_NAMES.length].min.times do
      loop do
        value = rand(CONTESTANT_NAMES.length)
        next if @contestants.include?(value)
        @contestants.push(value)
        break
      end
    end
    $player.party = [chosenpkmn]
    @decision = 0
    @ended = false
    $stats.bug_contest_count += 1
  end

  def place
    3.times do |i|
      return i if @places[i][0] < 0
    end
    return 3
  end

  def pbEnd(interrupted = false)
    return if !@inProgress
    @otherparty.each { |pkmn| $player.party.push(pkmn) }
    if interrupted
      @ended = false
    else
      pbNicknameAndStore(@lastPokemon) if @lastPokemon
      @ended = true
    end
    BugContestState::CUSTOM_CONTESTANTS.clear
    $stats.bug_contest_wins += 1 if place == 0
    @ballcount = 0
    @inProgress = false
    @decision = 0
    @lastPokemon = nil
    @otherparty = []
    @contestMaps = []
    @reception = []
    @lastContest = pbGetTimeNow.to_i
    $game_map.need_refresh = true
  end
end

def pbRegisterCaughtPokemon(pkmn)
  evo_family = GameData::Species.get(pkmn.species).get_baby_species
  state = pbBugContestState
  state.species_chain[evo_family] += 3
  $game_variables[43] += [(state.species_chain[evo_family] / 2), 1].max
  pbDisplay(_INTL("Chain count for {1}: {2}", pkmn.speciesName, state.species_chain[evo_family]))
end

#===============================================================================
#
#===============================================================================
class TimerDisplay # :nodoc:
  attr_accessor :start_time

  def initialize(start_time, max_time)
    @timer = Window_AdvancedTextPokemon.newWithSize("", Graphics.width - 120, 0, 120, 64)
    @timer.z = 99999
    @start_time = start_time
    @max_time = max_time
    @display_time = nil
  end

  def dispose
    @timer.dispose
  end

  def disposed?
    @timer.disposed?
  end

  def update
    time_left = @max_time - (System.uptime - @start_time).to_i
    time_left = 0 if time_left < 0
    if @display_time != time_left
      @display_time = time_left
      min = @display_time / 60
      sec = @display_time % 60
      @timer.text = _ISPRINTF("<ac>{1:02d}:{2:02d}", min, sec)
    end
  end
end

#===============================================================================
#
#===============================================================================
# Returns a score for this Pokemon in the Bug-Catching Contest.
# Not exactly the HGSS calculation, but it should be decent enough.
def pbBugContestScore(pkmn)
  levelscore = pkmn.level * 4
  ivscore = 0
  pkmn.iv.each_value { |iv| ivscore += iv.to_f / Pokemon::IV_STAT_LIMIT }
  ivscore = (ivscore * 100).floor
  hpscore = (100.0 * pkmn.hp / pkmn.totalhp).floor
  catch_rate = pkmn.species_data.catch_rate
  rarescore = 60
  rarescore += 20 if catch_rate <= 120
  rarescore += 20 if catch_rate <= 60
  return levelscore + ivscore + hpscore + rarescore
end

def pbBugContestState
  if !$PokemonGlobal.bugContestState
    $PokemonGlobal.bugContestState = BugContestState.new
  end
  return $PokemonGlobal.bugContestState
end

# Returns true if the Bug-Catching Contest in progress
def pbInBugContest?
  return pbBugContestState.inProgress?
end

# Returns true if the Bug-Catching Contest in progress and has not yet been judged
def pbBugContestUndecided?
  return pbBugContestState.undecided?
end

# Returns true if the Bug-Catching Contest in progress and is being judged
def pbBugContestDecided?
  return pbBugContestState.decided?
end

def pbBugContestStartOver
  $player.party.each do |pkmn|
    pkmn.heal
    pkmn.makeUnmega
    pkmn.makeUnprimal
  end
  pbBugContestState.pbStartJudging
end

#===============================================================================
#
#===============================================================================
EventHandlers.add(:on_map_or_spriteset_change, :show_bug_contest_timer,
  proc { |scene, _map_changed|
    next if !pbInBugContest? || pbBugContestState.decision != 0 || BugContestState::TIME_ALLOWED == 0
    scene.spriteset.addUserSprite(
      TimerDisplay.new(pbBugContestState.timer_start, BugContestState::TIME_ALLOWED)
    )
  }
)

EventHandlers.add(:on_frame_update, :bug_contest_counter,
  proc {
    next if !pbBugContestState.expired?
    next if $game_player.move_route_forcing || pbMapInterpreterRunning? ||
            $game_temp.message_window_showing
    pbMessage(_INTL("ANNOUNCER: BEEEEEP!"))
    pbMessage(_INTL("Time's up!"))
    pbBugContestState.pbStartJudging
  }
)

EventHandlers.add(:on_enter_map, :end_bug_contest,
  proc { |_old_map_id|
    pbBugContestState.pbClearIfEnded
  }
)

EventHandlers.add(:on_leave_map, :end_bug_contest,
  proc { |new_map_id, new_map|
    next if !pbInBugContest? || !pbBugContestState.pbOffLimits?(new_map_id)
    # Clear bug contest if player flies/warps/teleports out of the contest
    pbBugContestState.pbEnd(true)
  }
)

#===============================================================================
#
#===============================================================================
EventHandlers.add(:on_calling_wild_battle, :bug_contest_battle,
  proc { |pkmn, handled|
    # handled is an array: [nil]. If [true] or [false], the battle has already
    # been overridden (the boolean is its outcome), so don't do anything that
    # would override it again
    next if !handled[0].nil?
    next if !pbInBugContest?
    handled[0] = pbBugContestBattle(pkmn)
  }
)

def pbBugContestBattle(pkmn, level = 1)
  state = pbBugContestState
  state.species_chain ||= {}
  EventHandlers.trigger(:on_start_battle)

  # Check for chain-based reroll
  if pkmn.is_a?(Pokemon) && state.lastPokemon && rand < 0.1
     reroll_level = rand(8..15)
    pkmn = pbGenerateWildPokemon(state.lastPokemon.species, reroll_level)
    #pkmn = state.lastPokemon.species
  end
  # Generate a wild Pokémon based on the species and level if needed
  pkmn = pbGenerateWildPokemon(pkmn, level) if !pkmn.is_a?(Pokemon)

  # Determine evolution family to track chains
  species = pkmn.is_a?(Pokemon) ? pkmn.species : pkmn
  evo_family = GameData::Species.get(species).get_baby_species
  chain_count = state.species_chain[evo_family] || 0
  is_boss = chain_count >= 15 && (!state.boss_spawned || rand < 0.09) || rand < 0.01# 10% chance to spawn a boss if chain count >= 5

  # Chance to evolve if possible (chain_count / 10 probability)
  evolutions = pkmn.species_data.get_evolutions

if !evolutions.empty? && rand < chain_count.to_f / 10
  new_species = evolutions.sample[0]   # Pick a random valid evolution
  pkmn.species = new_species
  pkmn.name = nil
  pkmn.reset_moves
  pkmn.calc_stats
end

  # Apply boss modifications
  if is_boss
    state.boss_spawned = true
    pkmn.level += rand(5..15)  # <-- Boss level boost
    pkmn.level += chain_count if state.boss_spawned
    pkmn.iv.each_key { |stat| pkmn.iv[stat] = 31 }
    pkmn.calc_stats           # <-- Recalculate stats for new level
    pkmn.name = _INTL("Boss {1}", pkmn.species_data.name)
    pkmn.shiny = true if rand < 0.05 # 5% chance to be shiny
    pkmn.learn_move(:HEALORDER)
    pkmn.item = :SILVERPOWDER if pkmn.item.nil? # boosts Bug-type moves
    pbMessage(_INTL("A powerful presence fills the air... A Boss Pokémon appeared!"))
    $PokemonGlobal.nextBattleBGM = "vs Roaming Pokemon"
  else
    weighted_items = [
      [:HONEY, 4],[:POWERWEIGHT, 4],[:POWERBRACER, 4],[:POWERBELT, 4],[:POWERLENS, 4],
      [:TINYMUSHROOM, 4],[:POWERBAND, 4],[:POWERANKLET, 4],
      [:SILVERPOWDER, 3],[:TM06,  3],[:TM62,  3],[:TM81,  3],[:TM84,  3],
      [:NETBALL, 2],[:PPUP, 2],[:HPUP, 2],[:ABILITYCAPSULE, 2],[:RARECANDY, 2],
      [:ABILITYPATCH, 1], [:LONELYMINT,5], [:ADAMANTMINT,5], [:NAUGHTYMINT,5], [:BRAVEMINT,5],
      [:BOLDMINT,5],   [:TIMIDMINT,5],   [:HASTYMINT,5],   [:CALMMINT,5], [:MODESTMINT,5],
      [:IMPISHMINT,5],   [:JOLLYMINT,5],   [:RELAXEDMINT,5], [:SASSYMINT,5],[:QUIETMINT,5],
      [:SLOWMINT,5],   [:RASHMINT,5],   [:GENTLEMINT,5],  [:CAREFULMINT,5],[:LAXMINT,5],[:MILDMINT,5],
      [:NAIVEMINT,5],   [:SERIOUSMINT,5], [:HEARTSCALE, 2]
    ]
    # 40% chance to give an item
    if rand < 0.8
      # Create a weighted pool
      pool = []
      weighted_items.each do |item, weight|
        pool.concat([item] * weight)
      end
      pkmn.item = pool.sample
    end
  end

  foeParty = [pkmn]
  playerTrainer     = [$player]
  playerParty       = $player.party
  playerPartyStarts = [0]

  scene = BattleCreationHelperMethods.create_battle_scene
  battle = BugContestBattle.new(scene, playerParty, foeParty, playerTrainer, nil)
  battle.party1starts = playerPartyStarts
  battle.ballCount = pbBugContestState.ballcount
  setBattleRule("single")
  BattleCreationHelperMethods.prepare_battle(battle)

  outcome = Battle::Outcome::UNDECIDED
  pbBattleAnimation(pbGetWildBattleBGM(foeParty), 0, foeParty) do
    outcome = battle.pbStartBattle
    BattleCreationHelperMethods.after_battle(outcome, true)
    if outcome == Battle::Outcome::WIN
      state.species_chain[evo_family] += 1
    end
    if Battle::Outcome.should_black_out?(outcome)
      $game_system.bgm_unpause
      $game_system.bgs_unpause
      pbBugContestStartOver
    end
  end

  Input.update
  pbBugContestState.ballcount = battle.ballCount

  if pbBugContestState.ballcount == 0
    pbMessage(_INTL("ANNOUNCER: The Bug-Catching Contest is over!"))
    pbBugContestState.pbStartJudging
  end

  BattleCreationHelperMethods.set_outcome(outcome, 1)
  EventHandlers.trigger(:on_wild_battle_end, pkmn.species_data.id, pkmn.level, outcome)

  return !Battle::Outcome.should_black_out?(outcome)
end

#===============================================================================
#
#===============================================================================
class PokemonPauseMenu
  alias __bug_contest_pbShowInfo pbShowInfo unless method_defined?(:__bug_contest_pbShowInfo)

  def pbShowInfo(y_Pos = 50)
    __bug_contest_pbShowInfo
    return if !pbInBugContest?
    if pbBugContestState.lastPokemon
      @scene.pbShowInfo1(y_Pos,_INTL("Caught\n{1} Λ{2}\nBalls: {3}",
                              pbBugContestState.lastPokemon.speciesName,
                              pbBugContestState.lastPokemon.level,
                              pbBugContestState.ballcount))
    else
      @scene.pbShowInfo1(y_Pos,_INTL("Caught\nNone\nBalls: {1}", pbBugContestState.ballcount))
    end
  end
end

MenuHandlers.add(:pause_menu, :quit_bug_contest, {
  "name"      => _INTL("Quit Contest"),
  "order"     => 60,
  "condition" => proc { next pbInBugContest? },
  "desc"      => _INTL("Quit and be judged"),
  "effect"    => proc { |menu|
    menu.pbHideMenu
    if pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
      menu.pbEndScene
      pbBugContestState.pbStartJudging
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})

