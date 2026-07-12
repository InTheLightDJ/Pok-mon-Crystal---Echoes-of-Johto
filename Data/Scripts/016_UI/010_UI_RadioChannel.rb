#===============================================================================
# Radio text copied from
# https://gamefaqs.gamespot.com/gbc/198308-pokemon-gold-version/faqs/49457
#===============================================================================
# Radio Handlers
#===============================================================================
module RadioHandlers
  $in_the_light_track1 = nil
  $in_the_light_track2 = nil
  $in_the_light_start_time = nil
  $in_the_light_last_bgm_name ||= nil

  @@handlers = {}

  def self.add(menu, option, hash)
    @@handlers[menu] = HandlerHash.new if !@@handlers.has_key?(menu)
    @@handlers[menu].add(option, hash)
  end

  def self.remove(menu, option)
    @@handlers[menu]&.remove(option)
  end

  def self.clear(menu)
    @@handlers[menu]&.clear
  end

  def self.each(menu)
    return if !@@handlers.has_key?(menu)
    @@handlers[menu].each { |option, hash| yield option, hash }
  end

  def self.each_available(menu, *args)
    return if !@@handlers.has_key?(menu)
    options = @@handlers[menu]
    keys = options.keys
    sorted_keys = keys.sort_by { |option| options[option]["channel"] || keys.index(option) }
    sorted_keys.each do |option|
      hash = options[option]
      next if hash["condition"] && !hash["condition"].call(*args)
      if hash["name"].is_a?(Proc)
        name = hash["name"].call
      else
        name = _INTL(hash["name"])
      end
      yield option, hash, name
    end
  end

  def self.call(menu, option, function, *args)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash || !option_hash[function]
    return option_hash[function].call(*args)
  end

  def self.get_channel(menu, channel, *args)
    return nil if !@@handlers.has_key?(menu)
    ret = nil
    channel_id = nil
    options = @@handlers[menu]
    keys = options.keys
    sorted_keys = keys.sort_by { |option| options[option]["channel"] || keys.index(option) }
    sorted_keys.each do |option|
      hash = options[option]
      next if !hash["channel"] || (hash["channel"] != channel && hash["channel"] > 0)
      next if hash["condition"] && !hash["condition"].call(*args)
      channel_id = option if !channel_id # save the "take over" radio id
      next if hash["channel"] < 0
      if hash["name"].is_a?(Proc)
        name = hash["name"].call
      else
        name = _INTL(hash["name"])
      end
      ret = [name, channel_id]
      break
    end
    return ret
  end

  def self.get(menu, option, function, *args)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash || !option_hash[function]
    if option_hash[function].is_a?(Proc)
      return option_hash[function].call(*args)
    else
      return option_hash[function]
    end
  end
end

#===============================================================================
# String splitter
#===============================================================================
def pbTextSpliter(window, str, maxchar = nil)
  words = str.split(' ')
  words = [""] if words==[]
  line = words[0]
  arr = []
  if words.length > 1
    for word in words[1...words.length]
        test = line + " " + word
        maxlength = window.contents.width
        if window.contents.text_size(test).width > maxlength || 
          (maxchar && test.length > maxchar)
            arr.push(line)
            line = word
        else
            line = test
        end
    end
  end
  arr.push(line)
  return arr
end
def pbGetRadioFormatLine(window, looptext, intro = nil)
  looptext = looptext.split('\n') if !looptext.is_a?(Array)
  text = [looptext]
  text.unshift(intro) if intro
  i = 0 ; text_array = [[], []]
  for item in text
    for lines in item
      breakline = pbTextSpliter(window, lines)
      for line in breakline
        text_array[i].push(line)
      end
    end
    i += 1
  end
  return text_array
end

def reset_in_the_light_radio
  $in_the_light_track1 = nil
  $in_the_light_track2 = nil
  $in_the_light_start_time = nil
  $in_the_light_last_bgm_name = nil
end

#===============================================================================
# Team Rocket Take Over the Radio
#===============================================================================
RadioHandlers.add(:radio_show, :rocket_takeover, {
  "channel"   => -1, # For any radio that will take over other channels
  "bgm"       => "Team Rockets Radio Tower",#"Radio - Tower Occupied",
  "condition" => proc { next $game_switches[Settings::ROCKET_TAKEOVER] },
  "show"      => proc { |window|
        $PokemonGlobal.radioStation = :rocket_takeover
        InTheLightRadio.start_if_needed  # << add this
                        looptext = [_INTL("... ...Ahem,"),
                                    _INTL("we are TEAM ROCKET!"),
                                    _INTL("After three years of preparation,"),
                                    _INTL("we have risen again from the ashes!"),
                                    _INTL("GIOVANNI!"),
                                    _INTL("Can you hear?"),
                                    _INTL("We did it!"),
                                    _INTL("Where is our Boss?"),
                                    _INTL("Is he listening?")
                                    ]
                        array = pbGetRadioFormatLine(window, looptext)
                        next array
                }
})
#===============================================================================
# Prof Oak TalkShow
#===============================================================================
RadioHandlers.add(:radio_show, :oak_talk_show, {
  "name"      => _INTL("OAK's Pokémon Talk"),
  "channel"   => 4.5,
  "condition" => proc { time = pbGetTimeNow
                        next time.hour >= 4 && time.hour <= 10 },
  "bgm"       => "Radio - Professor Oak's Talk",
  "show"      => proc { |window|
                        array = []
                        route = []
                        GameData::Encounter.each_of_version($PokemonGlobal.encounter_version){|enc|
                          route.push(enc)
                        }
                        enc_data = route.sample
                        return "" if !enc_data
                        get_species_from_table = lambda do |encounter_table|
                          return nil if !encounter_table || encounter_table.length == 0
                          len = [encounter_table.length, 4].min   # From first 4 slots only
                          return encounter_table[rand(len)][1]
                        end
                        enc_tables = enc_data.types
                        species = get_species_from_table.call(enc_tables[:Land])
                        if !species
                          [:Cave, :LandDay, :LandMorning, :LandNight, :Water].each{|enc|
                            species = get_species_from_table.call(enc_tables[enc])
                            break if species
                          }
                        end
                        if !species
                          return [["Oak : Hmm... no Pokémon spotted in this area!"]]
                        end
                        mapname = pbGetMapNameFromId(enc_data.map)
                        
                        text1 = [
                            "almost poisonously",
                            "aptly named and",
                            "evolution must be",
                            "heart-meltingly",
                            "looks in water is",
                            "ooh, so sensually",
                            "provocatively",
                            "so flipped out and",
                            "so mischievously",
                            "so very topically",
                            "so, so unbearably",
                            "sure addictively",
                            "sweet and adorably",
                            "undeniably kind of",
                            "wiggly and slickly",
                            "wow, impressively",
                        ]
                        text2 = [
                            "bold, sort of.",
                            "cute",
                            "exciting",
                            "friendly.",
                            "frightening.",
                            "guarded.",
                            "hot, hot, hot!",
                            "inspiring.",
                            "lovely.",
                            "now!",
                            "pleasant.",
                            "powerful.",
                            "speedy.",
                            "stimulating.",
                            "suave & debonair!",
                            "weird.",
                        ]
                        a = GameData::Species.get(species).name.upcase
                        b = text1[rand(text1.length)]
                        c = text2[rand(text2.length)]
                        intro = [
                            "Mary : PROF.OAK'S POKEMON TALK! With me, MARY!"
                        ]
                        oak = _INTL("Oak : {1} may be seen around {2}.", a, mapname.upcase)
                        mary = _INTL("Mary : {1}'s {2} {3}.", a, b, c)
                        array = pbGetRadioFormatLine(window, [oak, mary], intro)
                        next array
                }
})
#===============================================================================
# Pokedex Show
#===============================================================================
RadioHandlers.add(:radio_show, :pokedex_show, {
  "name"      => _INTL("Pokédex Show"),
  "channel"   => 4.5,
  "condition" => proc { time = pbGetTimeNow
                        next !(time.hour >= 4 && time.hour <= 10) },
  "bgm"       => "Radio - Pokedex Show",
  "show"      => proc { |window|
    owned = GameData::Species.keys.select { |key| $player.owned?(key) }

    # Fallback if not enough owned species yet
    if owned.length < 2
      intro    = ["DJ Mary : POKÉDEX SHOW!"]
      looptext = [
        "No Pokédex entries yet!",
        "Catch some Pokémon and tune in again!"
      ]
      next pbGetRadioFormatLine(window, looptext, intro)
    end

    sample = owned.sample(2)
    input  = []
    sample.each do |key|
      sp = GameData::Species.get(key)
      data = []
      data.push(sp.name.upcase)
      data.push(sp.form_name.upcase) if sp.form > 0 && sp.form_name && !sp.form_name.empty?
      data.push(sp.category.upcase)
      data.push(sp.pokedex_entry)
      input.push(data)
    end
    next pbGetRadioFormatLine(window, input[0], input[1])
  }
})
#==============================================================================
# POKEMON Music
#==============================================================================
RadioHandlers.add(:radio_show, :pokemon_music, {
  "name"      => _INTL("Pokémon Music"),
  "channel"   => 7.5,
  "condition" => proc { next pbGetCurrentRegion == 0 },
  "show"      => proc { |window|
                        time = pbGetTimeNow
                        wday = time.wday
                        day = [
                        _INTL("Sunday"),
                        _INTL("Monday"),
                        _INTL("Tuesday"),
                        _INTL("Wednesday"),
                        _INTL("Thursday"),
                        _INTL("Friday"),
                        _INTL("Saturday")][wday]
                        intro = (wday % 2 == 0) ? 
                                _INTL("so let us jam to") :
                                _INTL("so chill out to")
                        if wday % 2 == 0 # March
                          pbBGMPlay("Radio - Pokemon March", 100, 100)
                          if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
                            $PokemonMap.lower_level_wild_pokemon = true
                            $PokemonMap.higher_level_wild_pokemon = false
                          else
                            $PokemonMap.higher_encounter_rate = true
                            $PokemonMap.lower_encounter_rate = false
                          end
                        else
                          pbBGMPlay("Radio - Pokemon Lullaby", 100, 100)
                          if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
                            $PokemonMap.higher_level_wild_pokemon = true
                            $PokemonMap.lower_level_wild_pokemon = false
                          else
                            $PokemonMap.lower_encounter_rate = true
                            $PokemonMap.higher_encounter_rate = false
                          end
                        end
                        looptext = (wday % 2 == 0) ? 
                                _INTL("POKEMON MARCH!") :
                                _INTL("POKEMON Lullaby!")
                        text = ["Ben : POKEMON MUSIC CHANNEL!",
                                _INTL("It's me, DJ BEN! Today's {1}, {2}", day.upcase, intro)]
                        array = pbGetRadioFormatLine(window, [looptext], text)
                        next array
                }
})
#==============================================================================
# Let's All Sing!
#==============================================================================
RadioHandlers.add(:radio_show, :lets_all_sing, {
  "name"      => _INTL("Let's All Sing!"),
  "channel"   => 18.5,
  "condition" => proc { next pbGetCurrentRegion == 1 },
  "show"      => proc { |window|
                        time = pbGetTimeNow
                        wday = time.wday
                        day = [
                        _INTL("Sunday"),
                        _INTL("Monday"),
                        _INTL("Tuesday"),
                        _INTL("Wednesday"),
                        _INTL("Thursday"),
                        _INTL("Friday"),
                        _INTL("Saturday")][wday]
                        intro = (wday % 2 == 0)? 
                                _INTL("so let us jam to") :
                                _INTL("so chill out to")
                        if wday % 2 == 0 # March
                          pbBGMPlay("Radio - Pokemon March", 100, 100)
                          if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
                            $PokemonMap.lower_level_wild_pokemon = true
                            $PokemonMap.higher_level_wild_pokemon = false
                          else
                            $PokemonMap.higher_encounter_rate = true
                            $PokemonMap.lower_encounter_rate = false
                          end
                        else
                          pbBGMPlay("Radio - Pokemon Lullaby", 100, 100)
                          if Settings::FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS
                            $PokemonMap.higher_level_wild_pokemon = true
                            $PokemonMap.lower_level_wild_pokemon = false
                          else
                            $PokemonMap.lower_encounter_rate = true
                            $PokemonMap.higher_encounter_rate = false
                          end
                        end
                        looptext = (wday % 2 == 0) ? 
                                _INTL("POKEMON MARCH!") :
                                _INTL("POKEMON Lullaby!")
                        text = ["FERN: POKéMUSIC! With DJ FERN!",
                                _INTL("It's me, DJ BEN! Today's {1}, {2}", day.upcase, intro)]
                        array = pbGetRadioFormatLine(window, [looptext], text)
                        next array
                }
})
#==============================================================================
# Lucky Number Show 
#==============================================================================
class PokemonGlobalMetadata
  attr_accessor :lotteryNumber
  attr_accessor :lotteryTime
  attr_accessor :radioStation
  attr_accessor :update_news_idx
  attr_accessor :update_news_started_at
end

def getlastFriday(time)
  time = pbGetTimeNow if !time
  wday = time.wday
  diff_day = wday > 5 ? wday - 5 : wday + 2
  last_friday = time - (diff_day * 24 * 3600)
  last_friday -= (time.hour * 3600) + (time.min * 60) + time.sec + time.subsec
  return last_friday
end

# Clear radio station flag on new games and when loading a save
EventHandlers.add(:on_new_game, :init_radio_station, proc {
  $PokemonGlobal.radioStation = nil
})

EventHandlers.add(:on_load, :clear_radio_station_on_load, proc {
  $PokemonGlobal.radioStation = nil
})

RadioHandlers.add(:radio_show, :lucky_number, {
  "name"      => _INTL("Lucky Channel"),
  "channel"   => 8.5,
  "bgm"       => "Radio - Lucky Channel, Game Corner",
  "show"      => proc { |window|
                  time = pbGetTimeNow
                  if !$PokemonGlobal.lotteryTime ||
                      ($PokemonGlobal.lotteryTime &&
                       time - $PokemonGlobal.lotteryTime >= 7 * 24 * 3600)
                    pbSetLotteryNumber(1)
                    $PokemonGlobal.lotteryNumber = pbGet(1)
                    $PokemonGlobal.lotteryTime = getlastFriday(time)
                  end
                  number = $PokemonGlobal.lotteryNumber
                  looptext = ["Reed : Yeehaw! How y'al doin' now?",
                              "Whether you're up or way down low, don't you miss the LUCKY NUMBER SHOW!",
                              _INTL("This week's Lucky Number is {1}!", number),
                              _INTL("I'll repeat that! This week's Lucky Number is {1}!", number),
                              "Match it and go to the RADIO TOWER!"
                          ]
                  array = pbGetRadioFormatLine(window, looptext, looptext)
                  next array
                }
})
#==============================================================================
# Places & People
#==============================================================================
RadioHandlers.add(:radio_show, :places_people, {
  "name"      => _INTL("Places & People"),
  "channel"   => 16.5,
  "bgm"       => "Radio - Places and People",
  "show"      => proc { |window|
                  text2 = [
                    "is actually great.",
                    "is always happy.",
                    "is cute",
                    "is definitely odd!",
                    "is inspiring!",
                    "is just my type.",
                    "is just so-so.",
                    "is kind of weird.",
                    "is precocious.",
                    "is quite noisy.",
                    "is right for me?",
                    "is so cool, no?",
                    "is sort of OK.",
                    "is sort of lazy.",
                    "is somewhat bold.",
                    "is too picky!",
                  ]
                  looptext = []
                  trainers = []
                  $player.resetBattleRecord if !$player.battleRecord
                  GameData::Trainer.each{|trainer|
                    next if Settings::UNPUBLICIZED_TRAINERS.include?(trainer.trainer_type)
                    next if !$player.battleRecord.fought_trainer?(trainer.trainer_type, trainer.name, trainer.version)
                    trainers.push(trainer)
                  }
                  2.times do
                    if rand(100) < 50 && trainers.length > 0
                      # Trainer
                      trainer = trainers.sample
                      name = trainer.fullname
                    else
                      # Place
                      map = GameData::TownMap.get(0) # only first region
                      map_point = map.point.sample
                      name = pbGetMessageFromHash(MessageTypes::REGION_LOCATION_NAMES, map_point[2])
                    end
                    adj = text2[rand(text2.length)]
                    looptext.push(_INTL("{1} {2}!", name.upcase, adj))
                  end
                  intro = ["Lily : PLACES AND PEOPLE!",
                          "Brought to you by me, DJ LILY!"]
                  array = pbGetRadioFormatLine(window, looptext, intro)
                  next array
                }
})


RadioHandlers.add(:radio_show, :in_the_light, {
  "name"      => _INTL("InTheLight Station"),
  "channel"   => 12.5,
  "condition" => proc { true },
  "show"      => proc { |window|
    $PokemonGlobal.radioStation = :in_the_light
    InTheLightRadio.start_if_needed
    looptext = [
      _INTL("Now playing: {1}", InTheLightRadio.track1),
      _INTL("Up next: {1}", InTheLightRadio.track2),
      _INTL("You're listening to InTheLight."),
      _INTL("Album title Johto Vibes"), 
      _INTL("By LightTheInn which is another name for InTheLight."),
      _INTL("Playing this may effect Pokemon in the wild.")
    ]
    intro = [_INTL("This is the InTheLight Radio Station.")]
    next pbGetRadioFormatLine(window, looptext, intro)
  }
})

RadioHandlers.add(:radio_show, :buffer_station_left, {
  "name"      => _INTL(""),
  "channel"   => 12,  # Channel before InTheLight (12.5)
  "condition" => proc {
    $itl_radio_guard = false
    $PokemonGlobal.radioStation = nil
    reset_in_the_light_radio
    next false  # Do not display in menu
  }
})

RadioHandlers.add(:radio_show, :buffer_station_right, {
  "name"      => _INTL(""),
  "channel"   => 13,  # Channel after InTheLight
  "condition" => proc {
    $itl_radio_guard = false
    $PokemonGlobal.radioStation = nil
    reset_in_the_light_radio
    next false  # Do not display in menu
  }
})





#==============================================================================
# Other Changes
#==============================================================================
# Player battle record attribute
class Player < Trainer
  # @return [BattleRecord] the player's battle record
  attr_reader   :battleRecord

  alias gsc_init initialize
  def initialize(name, trainer_type)
    gsc_init(name, trainer_type)
    resetBattleRecord
  end

  def resetBattleRecord
    @battleRecord = BattleRecord.new
  end

  # Represents the player's battle record.
  class BattleRecord
    # Creates an empty battle record.
    def initialize
      self.clear
    end

    # Clears the battle record.
    def clear
      @fought          = {}
      @defeated        = {}
    end

    # Sets the given trainer as fought in battle record.
    def set_fought(tr_type, tr_name, tr_version = 0)
      trainer_type = GameData::TrainerType.try_get(tr_type)&.id
      return if trainer_type.nil?
      @fought[trainer_type] ||= {}
      @fought[trainer_type][tr_name] = []
      @fought[trainer_type][tr_name][tr_version] = true
    end

    # @return [Boolean] whether the trainer is fought.
    def fought_trainer?(tr_type, tr_name, tr_version = -1)
      trainer_type = GameData::TrainerType.try_get(tr_type)&.id
      return false if trainer_type.nil?
      @fought[trainer_type] ||= {}
      @fought[trainer_type][tr_name] = []
      return @fought[trainer_type][tr_name][tr_version]
    end

    # Sets the given trainer as defeated in battle record.
    def set_defeated(tr_type, tr_name, tr_version = 0)
      trainer_type = GameData::TrainerType.try_get(tr_type)&.id
      return if trainer_type.nil?
      @defeated[trainer_type] ||= {}
      @defeated[trainer_type][tr_name] = []
      @defeated[trainer_type][tr_name][tr_version] = true
    end

    # @return [Boolean] whether the trainer is defeated.
    def defeated_trainer?(tr_type, tr_name, tr_version = -1)
      trainer_type = GameData::TrainerType.try_get(tr_type)&.id
      return false if trainer_type.nil?
      @defeated[trainer_type] ||= {}
      @defeated[trainer_type][tr_name] = []
      return @defeated[trainer_type][tr_name][tr_version]
    end
  end
end

#===============================================================================
# Helper methods for setting up and closing down battles
#===============================================================================
module BattleCreationHelperMethods
  module_function

  unless defined?(gsc_prepare_battle)
    class << BattleCreationHelperMethods
      alias gsc_prepare_battle prepare_battle
    end

    class << BattleCreationHelperMethods
      alias gsc_set_outcome set_outcome
    end
  end

  alias gsc_prepare_battle prepare_battle
  def prepare_battle(battle)
    gsc_prepare_battle(battle)
    @battle = battle
  end

  alias gsc_set_outcome set_outcome
  def set_outcome(outcome, outcome_variable = 1, trainer_battle = false)
    gsc_set_outcome(outcome, outcome_variable, trainer_battle)
    # set foe trainer as fought and/or defeated
    if trainer_battle
      @battle.opponent.each{|trainer|
        $player.resetBattleRecord if !$player.battleRecord
        $player.battleRecord.set_fought(trainer.trainer_type, trainer.name, trainer.version)
        $player.battleRecord.set_defeated(trainer.trainer_type, trainer.name, trainer.version) if outcome == 1 # Win
      }
    end
  end
end

#==============================================================================
# Unown Transmission
#==============================================================================
RadioHandlers.add(:radio_show, :unown_transmition, {
  "name"      => _INTL("Unown Transmission"),
  "channel"   => 13.5,
  "bgm"       => "Radio - Unown Transmission",
  "condition" => proc { next $game_map.map_id == 41 }
})

$itl_radio_guard = false


module InTheLightRadio
  TRACKS = {
    "Catch That Bug" => 222,
    "Apricorn Beat" => 180,
    "Slowpoke Well Vibe" => 212,
    "Johto Forever" => 187,
    "Legends Of Johto" => 174,
    "Rage Red Tide" => 238,
    "First steps In Johto" => 194,
    "You've Gotta Know Your Type" => 232,
    "Crystal Waters - Eusine" => 281,
    "Olivine Light - Jasmine" => 300,
    "Kimono Dance" => 228,
    "Fate Of The S.S.Anne" => 199,
    "The MewTwo Heart" => 214,
    "Team Rockets Radio Tower" => 228,
  }

  @track1 = nil
  @track2 = nil
  @start_time = nil
  @last_played = nil

  class << self
    attr_reader :track1, :track2

    # Is the station currently considered active?
    def active?
  st = $PokemonGlobal&.radioStation
  return false if st.nil?
  case st
  when :in_the_light
    # Only outdoors (keeps your original behavior)
    return $game_map&.metadata&.outdoor_map
  when :rocket_takeover
    # Play everywhere (maps, menus, battles)
    return true
  else
    return false
  end
end

    # Call this instead of pbBGMPlay from inside the radio.
    # It sets a guard so your own BGM calls aren't blocked by the engine patch.
    def radio_play(name, vol = 100, pit = 100)
      begin
        $itl_radio_guard = true
        pbBGMPlay(name, vol, pit)
      ensure
        $itl_radio_guard = false
      end
    end

    def start_if_needed
  st = $PokemonGlobal&.radioStation
  return unless [:in_the_light, :rocket_takeover].include?(st)
  return if @track1 && @track2 && @start_time

  if !Settings::USE_AI_MUSIC
    @track1 = "Added song"
    @track2 = "Added song"
    @start_time = System.uptime
  elsif st == :rocket_takeover
    @track1 = "Team Rockets Radio Tower"
    @track2 = "Team Rockets Radio Tower"
  else
    pick_initial_pair  # your random pair from TRACKS
  end
  play_current
end

    def tick
      return unless active?
      start_if_needed
      return unless @track1

      duration = (TRACKS[@track1] || 180) * SPEEDUP_STAGES[$GameSpeed]
      if System.uptime - @start_time >= duration
        if Settings::USE_AI_MUSIC
          @track1 = @track2
          @track2 = (TRACKS.keys - [@track1]).sample
        else
          @track1 = "Added song"
          @track2 = "Added song"
        end
        play_current
      else
        radio_play(@track1, 100, 100) if @last_played != @track1
        @last_played = @track1
      end
    end

    def stop
      @track1 = @track2 = nil
      @start_time = nil
      @last_played = nil
    end

    private

    def pick_initial_pair
      @track1 = TRACKS.keys.sample
      @track2 = (TRACKS.keys - [@track1]).sample
      @start_time = System.uptime
    end

    def play_current
      @start_time = System.uptime
      radio_play(@track1, 100, 100)
      @last_played = @track1
    end
  end
end

# Keep ticking each frame
EventHandlers.add(:on_frame_update, :in_the_light_radio_tick,
  proc { InTheLightRadio.tick })

  # Simple rotating segments for the update news station
# --- Game Update News data/state ---
module RadioUpdateNews
  # Edit your segments here
  SEGS = [
    { title: "v1.1.0", lines: [
      "Online CHAT: connect to the server and talk to other trainers in real time!",
      "Type /help in the chat window for a full list of commands.",
      "Online TRADING: use /trade to swap Pokemon with another player.",
      "Online BATTLES: use /battle to challenge a trainer to a full 6v6 match.",
      "TRIPLE TRIAD is here! Collect cards and challenge NPCs - or use /triad for PvP!",
      "Roaming Legendaries now roam Johto - listen for the special music when one is near.",
      "Stay tuned for more updates!"
    ]}
  ]

  module_function

  def idx
    $PokemonGlobal.update_news_idx ||= 0
    $PokemonGlobal.update_news_idx = 0 if $PokemonGlobal.update_news_idx >= SEGS.length
    return $PokemonGlobal.update_news_idx
  end

  def seg
    return SEGS[idx]
  end

  def title
    return seg[:title]
  end

  def lines
    return seg[:lines]
  end

  # Call this if you want to advance to the next segment (e.g., per day or on close)
  def next!
    $PokemonGlobal.update_news_idx = (idx + 1) % SEGS.length
  end
end

# --- Station definition: shows ONLY the current segment ---
RadioHandlers.add(:radio_show, :game_update_news, {
  "name"      => proc { _INTL("Update News ({1})", RadioUpdateNews.title) },
  "channel"   => 13.5,
  "bgm"       => "Radio - Lucky Channel, Game Corner",
  "condition" => proc { true },
  "show"      => proc { |window|
    # init a per-station timer
    $PokemonGlobal.update_news_started_at ||= System.uptime

    # advance when player presses ACTION (typically X/Z, whatever you mapped),
    # or auto-advance every 12 seconds while tuned in
    if Input.trigger?(Input::ACTION) || (System.uptime - $PokemonGlobal.update_news_started_at >= 12)
      RadioUpdateNews.next!
      $PokemonGlobal.update_news_started_at = System.uptime
      pbSEPlay("GUI sel") rescue nil
    end

    # build text for the CURRENT segment only
    intro    = ["DJ Patch : GAME UPDATE NEWS!"]
    looptext = RadioUpdateNews.lines
    next pbGetRadioFormatLine(window, looptext, intro)
  }
})



# ===============================
# Buena's Password (Crystal-style)
# ===============================

# ---- Configurable word list (feel free to customize) ----
module Buena
  WORDS = %w[
    ABRA RATTATA VULPIX ODDISH DROWZEE PIKACHU GROWLITHE EKANS CUBONE
    KOFFING MAGNEMITE HOPPIP MAREEP SNUBBULL GIRAFARIG GLIGAR NATU
    HOOTHOOT SPINARAK TEDDIURSA WOOPER SHUCKLE SMEARGLE SNEASEL
  ]
  CHANNEL = 10.5
  START_HOUR = 18  # 6 PM
  END_HOUR   = 24  # midnight (exclusive)
  BGM_NAME   = "Radio - Buenas Password"  # change to whatever your filename is
  POINTS_PER_CORRECT = 1
end

# ---- Save data slots ----
class PokemonGlobalMetadata
  attr_accessor :buena_points        # Integer
  attr_accessor :buena_last_claim    # String day key "YYYYJJJ" (JJJ = yday)
end

EventHandlers.add(:on_new_game, :init_buena_points, proc {
  $PokemonGlobal.buena_points     = 0
  $PokemonGlobal.buena_last_claim = nil
})

# ---- Helpers for daily word/claim ----
def buena_day_key(time=nil)
  t = time || pbGetTimeNow
  # Year + day-of-year (keeps it unique and easy to compare)
  return sprintf("%04d%03d", t.year, t.yday)
end

def pbBuenaPasswordOfTheDay(time=nil)
  t   = time || pbGetTimeNow
  idx = (t.year * 1000 + t.yday) % Buena::WORDS.length
  return Buena::WORDS[idx]
end

def pbBuenaHasClaimedToday?(time=nil)
  ($PokemonGlobal.buena_last_claim == buena_day_key(time))
end

# Call this from Buena’s NPC when the player answers.
# Returns true if accepted (and awards points), false otherwise.
def pbBuenaTryClaim(answer, time=nil)
  t = time || pbGetTimeNow
  return false if pbBuenaHasClaimedToday?(t)
  return false if !answer || answer.strip.empty?
  today = pbBuenaPasswordOfTheDay(t)
  if answer.upcase.strip == today.upcase
    $PokemonGlobal.buena_points     ||= 0
    $PokemonGlobal.buena_points     += Buena::POINTS_PER_CORRECT
    $PokemonGlobal.buena_last_claim  = buena_day_key(t)
    return true
  end
  return false
end

# Optional helper to spend points on prizes
def pbBuenaSpendPoints(cost)
  $PokemonGlobal.buena_points ||= 0
  return false if cost < 0 || $PokemonGlobal.buena_points < cost
  $PokemonGlobal.buena_points -= cost
  return true
end

# ---- Channel registration ----
RadioHandlers.add(:radio_show, :buenas_password, {
  "name"      => _INTL("Buena's Password"),
  "channel"   => Buena::CHANNEL,
  "condition" => proc {
    time = pbGetTimeNow
    next time.hour >= Buena::START_HOUR && time.hour < Buena::END_HOUR
  },
  "show"      => proc { |window|
    # Play show BGM (only while tuned here)
    begin
      pbBGMPlay(Buena::BGM_NAME, 100, 100)
    rescue
      # If the BGM file isn't present, just ignore
    end

    word = pbBuenaPasswordOfTheDay
    # Keep it flavorful; Crystal/HGSS vibe
    intro    = ["Buena : BUENA'S PASSWORD! Live from the RADIO TOWER!"]
    looptext = [
      _INTL("Good evening, listeners!"),
      _INTL("Tonight's password is... {1}!", word),
      _INTL("That's right-{1}! Don't forget it!", word),
      _INTL("Come tell me on 2F of the Radio Tower to earn points!"),
      _INTL("One prize entry per day-see you soon!")
    ]
    next pbGetRadioFormatLine(window, looptext, intro)
  }
})

# ==============================
# Password/Buena Points Helpers
# ==============================
def pbBuenaPoints
  $PokemonGlobal.buena_points ||= 0
  return $PokemonGlobal.buena_points
end

def pbBuenaAddPoints(n)
  $PokemonGlobal.buena_points = [0, pbBuenaPoints + n].max
end

def pbBuenaSpendPoints(n)
  return false if pbBuenaPoints < n
  $PokemonGlobal.buena_points -= n
  return true
end

# ==================================
# Password Points Prize Shop (v21.1)
# ==================================
# list: [[:ULTRABALL, 2], [:RARECANDY, 8], ...]
# title: shown at the top of the menu
# allow_multiple: ask "How many?" if true
def pbPasswordPointShop(list, title = _INTL("Prize Shop"), allow_multiple = true)
  # Resolve/sanitize items
  entries = []
  list.each do |id, cost|
    item = GameData::Item.try_get(id)
    next if !item || !cost || cost <= 0
    entries << [item, cost]
  end
  if entries.empty?
    pbMessage(_INTL("No prizes are available right now."))
    return
  end

  last_index = 0
  loop do
    # Build command list
    commands = entries.map { |(item, cost)| _INTL("{1} - {2} pts", item.name, cost) }
    commands << _INTL("Exit")

    # Create a message window and show header text in it
    header = _INTL("{1}\nYou have {2} point(s).", title, ($PokemonGlobal.buena_points ||= 0))
    msgwindow = pbCreateMessageWindow
    pbMessageDisplay(msgwindow, header, false)  # show text, keep window open

    # Show the commands near the header window
    cmd = pbShowCommands(msgwindow, commands, last_index)
    pbDisposeMessageWindow(msgwindow)

    break if cmd.nil? || cmd < 0 || cmd >= entries.length
    last_index = cmd

    item, cost = entries[cmd]
    max_by_points = ($PokemonGlobal.buena_points / cost).to_i
    if max_by_points <= 0
      pbMessage(_INTL("You don't have enough points."))
      next
    end

    qty = 1
    if allow_multiple && max_by_points > 1
      pbMessage(_INTL("Each {1} costs {2} point(s).", item.name, cost))
      qty = pbChooseNumber(_INTL("How many {1} would you like?", item.name), [99, max_by_points].min)
      next if qty <= 0
    end

    total = cost * qty
    next unless pbConfirmMessage(_INTL("Spend {1} point(s) for {2}× {3}?", total, qty, item.name))
    if $PokemonGlobal.buena_points < total
      pbMessage(_INTL("You don't have enough points."))
      next
    end

    # Give items first; only deduct points if it succeeded
    if pbReceiveItem(item.id, qty)
      $PokemonGlobal.buena_points -= total
      pbMessage(_INTL("You have {1} point(s) remaining.", $PokemonGlobal.buena_points))
    else
      pbMessage(_INTL("Your Bag is full."))
    end
  end

  pbMessage(_INTL("Come again!"))
end