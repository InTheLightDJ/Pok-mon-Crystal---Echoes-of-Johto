#==============================================================================
# Pokemon TCG - script calls for your events (full guide: README.md).
#
#   pbTCGDuel(opponent_name, opponent_deck, player_deck = nil,
#             prizes: 6, id: nil, reward: nil, portrait: nil, ai: nil, medal: nil)
#     opponent_deck / player_deck: a deck constant from TCG::DECKS
#       (e.g. :CHARMANDER_AND_FRIENDS_DECK) or an array of 60 card ids.
#     player_deck nil -> the player's active saved deck, or
#       :CHARMANDER_AND_FRIENDS_DECK if they have none yet.
#     id:       any key (symbol/string) to remember wins (pbTCGBeaten?)
#     reward:   given on a win: a booster pack key, a card id, or an array
#               of them (packs are opened, cards are added)
#     portrait: picture in Graphics/Plugins/Pokemon TCG/Duelists shown
#               before the duel (e.g. "ronald")
#     ai:       deck constant whose AI to use (lets a custom card list play
#               like that deck; defaults to opponent_deck if it is a constant)
#     medal:    Club Master medal given on a win (e.g. :grass), see
#               089f_TrainerCardMedals.rb
#     Returns true if the player won.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_wins
  def tcg_wins; @tcg_wins ||= {}; end   # id => number of wins
end

module TCG
  def self.deck_list(deck)
    return deck.map(&:to_sym) if deck.is_a?(Array)
    d = DECKS[deck.to_sym] or raise ArgumentError, "Unknown TCG deck #{deck.inspect}"
    d[:cards].flat_map { |id, n| [id] * n }.first(DECK_SIZE)
  end

  def self.wins; global ? global.tcg_wins : (@test_wins ||= {}); end

  # gives a reward entry: booster pack key, DESTINY(...) pack, card id, or
  # an array of them
  def self.give_reward(reward)
    packs = 0
    (reward.is_a?(Array) ? reward : [reward]).each do |r|
      if r.is_a?(DestinyPack)
        r.open(packs > 0)
        packs += 1
        next
      end
      r = r.to_sym
      if BOOSTER_PACKS[r]
        pbTCGOpenBooster(r, packs > 0)   # "...And another Booster Pack:"
        packs += 1
      elsif CARDS[r]
        add_card(r)
        pbMessage(_INTL("You got the card {1}!", card_name(r)))
      else
        raise ArgumentError, "Unknown TCG reward #{r.inspect}"
      end
    end
  end

  # speed-up scripts that scale System.uptime (SPEEDUP_STAGES[$GameSpeed],
  # Q to cycle): the GB screens run that many frames per screen update
  def self.speed_multiplier
    return 1 unless defined?(SPEEDUP_STAGES) && $GameSpeed.is_a?(Integer)
    m = SPEEDUP_STAGES[$GameSpeed].to_f
    m > 0 ? m : 1
  end

  # duel music (Audio/BGM): [file, volume, pitch]; nil = keep the map music
  DUEL_BGM = ["Simple and Clean", 100, 150]
  WIN_BGM  = ["Islands", 100, 100]           # result screen after a win
  LOSS_BGM = ["GSC 123 The End", 100, 100]   # result screen after a loss

  def self.play_bgm(entry)
    return unless entry && defined?(pbBGMPlay)
    pbBGMPlay(*entry)
  rescue StandardError
    nil   # missing file: keep whatever is playing
  end

  # remembers the map music, plays the duel music, and puts the map music
  # back afterwards (rewards included)
  def self.with_duel_music
    sys = defined?($game_system) && $game_system
    old = sys ? sys.getPlayingBGM : nil
    play_bgm(DUEL_BGM)
    yield
  ensure
    if sys
      old ? sys.bgm_play(old) : (defined?(pbBGMStop) && pbBGMStop)
    end
  end

  # true while pbTCGDuel runs (an idle timer can treat it like a battle)
  def self.dueling?; @dueling ? true : false; end
  def self.dueling=(v); @dueling = v; end

  # a duel counts as a battle for the "Only Battles" speed-up setting
  # (like its on_start_battle / on_end_battle handlers; Q works all duel)
  def self.with_battle_speed
    battles_only = defined?(SPEEDUP_STAGES) && $PokemonSystem.respond_to?(:only_speedup_battles) &&
                   $PokemonSystem.only_speedup_battles == 1
    if battles_only
      old_toggle = $CanToggle
      $GameSpeed = $PokemonSystem.battle_speed || 0
      $CanToggle = true
    end
    yield
  ensure
    if battles_only
      $PokemonSystem.battle_speed = $GameSpeed
      $GameSpeed = 0
      $CanToggle = old_toggle
    end
  end

  def self.show_portrait(name, opponent_name)
    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = 99_999
    spr = Sprite.new(vp)
    spr.bitmap = RPG::Cache.load_bitmap(GFX + "Duelists/", name.to_s)
    spr.zoom_x = spr.zoom_y = 2
    spr.x = (Graphics.width - spr.bitmap.width * 2) / 2
    spr.y = (Graphics.height - spr.bitmap.height * 2) / 2 - 40
    pbMessage(_INTL("{1} wants to duel!", opponent_name))
  rescue StandardError
    pbMessage(_INTL("{1} wants to duel!", opponent_name))
  ensure
    spr&.dispose
    vp&.dispose
  end
end

def pbTCGDuel(opponent_name, opponent_deck, player_deck = nil, prizes: 6, id: nil,
              reward: nil, portrait: nil, ai: nil, medal: nil)
  player_deck ||= TCG.active_deck_cards || :CHARMANDER_AND_FRIENDS_DECK
  ai ||= opponent_deck.is_a?(Array) ? nil : opponent_deck.to_sym
  player_name = $player ? $player.name : "Player"
  result = nil
  won = false
  TCG.with_duel_music do
    TCG.show_portrait(portrait, opponent_name) if portrait
    TCG.dueling = true
    TCG.with_battle_speed do
      pbFadeOutIn do
        scene = TCG::DuelScene.new
        scene.portrait = portrait
        begin
          duel = TCG::Duel.new(player_name, TCG.deck_list(player_deck), TCG::PlayerController.new(scene),
                               opponent_name, TCG.deck_list(opponent_deck), TCG::AIController.new(scene, ai),
                               prizes: prizes, ui: scene)
          scene.duel = duel
          result = duel.start
        ensure
          scene.dispose
          TCG.dueling = false
        end
      end
    end
    won = (result == TCG::DUEL_WIN)
    if won
      TCG.wins[id] = TCG.wins[id].to_i + 1 if id
      TCG.give_reward(reward) if reward
      TCG.give_medal(medal) if medal
    end
  end
  won
end

#------------------------------------------------------------------------------
# small helpers for event conditions (Script: in a Conditional Branch)
#------------------------------------------------------------------------------
def pbTCGBeaten?(id);                 TCG.wins[id].to_i > 0;              end
def pbTCGWins(id);                    TCG.wins[id].to_i;                  end
def pbTCGHasCard?(card, count = 1);   TCG.card_count(card) >= count;      end
def pbTCGCardCount(card);             TCG.card_count(card);               end
def pbTCGHasDeck?;                    !TCG.active_deck_cards.nil?;        end

def pbTCGGiveCard(card, count = 1, show: true)
  TCG.add_card(card, count)
  pbMessage(_INTL("You got {1} x{2}!", TCG.card_name(card.to_sym), count)) if show
end

# gives a premade deck (cards + saved deck if a slot is free)
def pbTCGGiveDeck(deck, show: true)
  TCG.give_deck(deck.to_sym)
  pbMessage(_INTL("You got the {1} deck!", TCG.deck_name(deck.to_sym))) if show
end
