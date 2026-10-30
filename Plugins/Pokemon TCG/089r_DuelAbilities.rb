#==============================================================================
# Pokemon TCG - duel abilities (not in the original)
#
# The player has one ability slot. Abilities are found in the world: an
# event gives one with pbTCGGiveAbility(:SPEED), and the card game menu's
# "Ability" option picks which one is in the slot (or none). An NPC can
# duel with one too: pbTCGDuel(..., ability: :SPEED). In an online duel
# both games swap their players' abilities before the duel starts.
#
#   :HEADS          Heads Not Tails: your coins come up heads 2 times in 3
#                   during your turn (not the toss for who goes first)
#   :HP_BOOST       HP Boost: your Pokémon have 10 more HP
#   :DESTINY_DRAW   Destiny Draw: once per duel, when your opponent has 1
#                   Prize left, your turn's draw is the card you need most:
#                   an Evolution of your Active Pokémon, then of a Benched
#                   one, then a draw/search Trainer (DESTINY_TRAINERS), then
#                   an Energy your Pokémon's attacks use, then any Energy.
#                   Or, as a safety net (same one use): a Basic Pokémon when
#                   your Active is your only Pokémon, has 20 HP or less, you
#                   have no Basic in your hand and the opponent's Active has
#                   the Energy for one of its attacks
#   :SPEED          Speed: you go first (both players have it: the coin toss)
#   :NO_WEAKNESS    Ignore Weakness: no Pokémon has Weakness (both players)
#   :NO_RESISTANCE  Ignore Resistance: no Pokémon has Resistance (both players)
#   :PREVENTION     Prevention: no ability works this duel (both players)
#   :PSA_PLUS       PSA+1 (not a duel ability): while it's in the slot,
#                   every new holo copy's hidden grade is 1 higher (max 10;
#                   089o_CardGrades.rb Grades.new_grade). Cards bought on
#                   the Player Market keep the grade they had.
#   :ENERGY         Energy Saver: your attacks cost 1 less Energy, a
#                   Colorless one first, else one of a type it needs 2+ of;
#                   never under 1 Energy and never without a type it needs
#                   (Fire + Water + Grass stays as it is)
#
# The changed HP / Weakness / Resistance / costs come from the duelist's
# card (Duelist#card), so the rules, the AI and the screens all see them.
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :tcg_abilities, :tcg_ability
  def tcg_abilities; @tcg_abilities ||= []; end   # found abilities
  def tcg_ability;   @tcg_ability;          end   # the one in the slot (nil = none)
end

module TCG
  module DuelAbilities
    LIST = [:HEADS, :HP_BOOST, :DESTINY_DRAW, :SPEED, :NO_WEAKNESS, :NO_RESISTANCE, :PREVENTION, :ENERGY, :PSA_PLUS]
    # abilities that do nothing in a duel (not shown or swapped there)
    NOT_IN_DUELS = [:PSA_PLUS]
    NAMES = {
      :HEADS         => "Heads Not Tails",
      :HP_BOOST      => "HP Boost",
      :DESTINY_DRAW  => "Destiny Draw",
      :SPEED         => "Speed",
      :NO_WEAKNESS   => "Ignore Weakness",
      :NO_RESISTANCE => "Ignore Resistance",
      :PREVENTION    => "Prevention",
      :ENERGY        => "Energy Saver",
      :PSA_PLUS      => "PSA+1"
    }
    DESCRIPTIONS = {
      :HEADS         => "Your coins come up heads 2 times out of 3 during your turn.",
      :HP_BOOST      => "Your Pokémon have 10 more HP.",
      :DESTINY_DRAW  => "Once per duel, when your opponent has 1 Prize left, you draw the card you need most. Or, if you're about to lose your only Pokémon, a Basic Pokémon.",
      :SPEED         => "You always go first.",
      :NO_WEAKNESS   => "Neither player's Pokémon have Weakness.",
      :NO_RESISTANCE => "Neither player's Pokémon have Resistance.",
      :PREVENTION    => "Neither player's ability works.",
      :ENERGY        => "Your attacks need 1 less Energy (at least 1, and still one of each type).",
      :PSA_PLUS      => "New holo cards you get have a hidden PSA grade 1 higher (up to 10)."
    }
    DESTINY_TRAINERS = [:PROFESSOR_OAK, :POKE_BALL, :ENERGY_SEARCH, :COMPUTER_SEARCH, :BILL, :POKEMON_TRADER]
    HP_BONUS = 10
    SAFETY_NET_HP = 20   # Destiny Draw's safety net: Active at this HP or less

    module_function

    def name(ab);        _INTL(NAMES[ab] || ab.to_s);         end
    def description(ab); _INTL(DESCRIPTIONS[ab] || "");      end
    def valid?(ab);      LIST.include?(ab);                  end

    # a card with the duelist's changes (mods: :hp, :no_weak, :no_res, :cost)
    def modded(card, mods)
      return card unless card.hp
      c = card.dup
      c.instance_variable_set(:@hp, card.hp + HP_BONUS) if mods[:hp]
      c.instance_variable_set(:@weakness, 0) if mods[:no_weak]
      c.instance_variable_set(:@resistance, 0) if mods[:no_res]
      c.instance_variable_set(:@attacks, card.attacks.map { |a| cheaper(a) }) if mods[:cost]
      c
    end

    # Energy Saver: 1 less Energy, Colorless first, else a type needed 2+
    def cheaper(atk)
      cost = atk.cost.dup
      return atk if atk.pokemon_power? || cost.sum <= 1
      if cost[COLORLESS] > 0
        cost[COLORLESS] -= 1
      else
        col = COLORED_TYPES.select { |i| cost[i] >= 2 }.max_by { |i| [cost[i], -i] }
        return atk unless col
        cost[col] -= 1
      end
      a = atk.dup
      a.instance_variable_set(:@cost, cost)
      a
    end
  end

  def self.abilities; global ? global.tcg_abilities : (@test_abilities ||= []); end

  # the player's ability in the slot (nil = none)
  def self.duel_ability
    ab = global ? global.tcg_ability : @test_ability
    ab && abilities.include?(ab) ? ab : nil
  end

  def self.duel_ability=(ab)
    ab = nil unless ab && abilities.include?(ab)
    global ? global.tcg_ability = ab : @test_ability = ab
  end

  #----------------------------------------------------------------------------
  # the duelist's cards with the changes
  #----------------------------------------------------------------------------
  class Duelist
    attr_reader :ability_mods

    def ability_mods=(mods)
      @ability_mods = mods && !mods.empty? ? mods : nil
      @ability_cards = {}
    end

    alias ability_card card unless method_defined?(:ability_card)
    def card(deck_index)
      c = ability_card(deck_index)
      return c unless @ability_mods
      @ability_cards[c.id] ||= DuelAbilities.modded(c, @ability_mods)
    end
  end

  #----------------------------------------------------------------------------
  # the duel
  #----------------------------------------------------------------------------
  class Duel
    attr_accessor :abilities   # [player's, opponent's] as chosen (nil = none)

    # the ability that works for side (0 / 1) this duel
    def ability(side); @working_abilities && @working_abilities[side]; end
    def ability?(side, ab); ability(side) == ab; end
    def any_ability?(ab); ability?(0, ab) || ability?(1, ab); end

    alias ability_start start unless method_defined?(:ability_start)
    def start
      exchange_abilities if respond_to?(:exchange_abilities)
      set_up_abilities
      ability_start
    end

    def set_up_abilities
      abs = (@abilities || [nil, nil]).map do |a|
        DuelAbilities.valid?(a&.to_sym) && !DuelAbilities::NOT_IN_DUELS.include?(a.to_sym) ? a.to_sym : nil
      end
      @abilities = abs
      @working_abilities = abs.include?(:PREVENTION) ? [nil, nil] : abs
      @destiny_used = [false, false]
      @duelists.each_with_index do |d, side|
        mods = {}
        mods[:hp] = true if ability?(side, :HP_BOOST)
        mods[:cost] = true if ability?(side, :ENERGY)
        mods[:no_weak] = true if any_ability?(:NO_WEAKNESS)
        mods[:no_res] = true if any_ability?(:NO_RESISTANCE)
        d.ability_mods = mods
      end
      @abilities_shown = false
    end

    # each player's ability, once, before the toss for who goes first
    def show_abilities
      return if @abilities_shown
      @abilities_shown = true
      @abilities.each_with_index do |ab, side|
        next unless ab
        @ui.message(_INTL("{1}'s ability: {2}!", @duelists[side].name, DuelAbilities.name(ab)))
      end
      if @abilities.include?(:PREVENTION) && @abilities.any? { |a| a && a != :PREVENTION }
        @ui.message(_INTL("Prevention! No ability works this duel."))
      end
    end

    # Speed: the one player with it goes first
    alias ability_first_turn_toss first_turn_toss unless method_defined?(:ability_first_turn_toss)
    def first_turn_toss(flipper)
      show_abilities
      fast = [0, 1].select { |side| ability?(side, :SPEED) }
      return ability_first_turn_toss(flipper) unless fast.size == 1
      first = @duelists[fast[0]]
      @ui.message(_INTL("{1}'s Speed: {1} goes first!", first.name))
      first.equal?(flipper) ? HEADS : TAILS
    end

    # Heads Not Tails: heads 2 times in 3 on the holder's turn (not the
    # toss for who goes first)
    alias ability_coin_result coin_result unless method_defined?(:ability_coin_result)
    def coin_result
      return ability_coin_result unless ability?(@turn, :HEADS) && !@deciding_first
      TCG.rng.rand(3) == 0 ? TAILS : HEADS
    end

    alias ability_handle_duel_setup handle_duel_setup unless method_defined?(:ability_handle_duel_setup)
    def handle_duel_setup
      @deciding_first = true
      ability_handle_duel_setup
    ensure
      @deciding_first = false
    end

    # Destiny Draw: the card goes on top of the deck before the turn's draw
    alias ability_handle_turn handle_turn unless method_defined?(:ability_handle_turn)
    def handle_turn
      destiny_draw
      ability_handle_turn
    end

    def destiny_draw
      return unless ability?(@turn, :DESTINY_DRAW) && !@destiny_used[@turn]
      d = turn_duelist
      idx = destiny_safety_net(d)
      idx ||= destiny_card(d) if non_turn_duelist.count_prizes == 1
      return unless idx
      @destiny_used[@turn] = true
      d.deck_cards[d.not_in_deck...d.deck_size] = [idx] + (d.deck_list - [idx])
      @ui.message(_INTL("{1}'s DESTINY DRAW!", d.name))
    end

    # safety net: a Basic Pokémon (deck index) when the Active is the only
    # Pokémon in play, has 20 HP or less, there's no Basic in the hand and
    # the opponent's Active has the Energy for one of its attacks; else nil
    def destiny_safety_net(d)
      return nil unless d.num_in_play_area == 1 && d.arena && d.slot_hp[PLAY_AREA_ARENA] <= DuelAbilities::SAFETY_NET_HP
      return nil if d.hand.any? { |i| (c = d.card(i)).pokemon? && c.basic? }
      opp = non_turn_duelist
      return nil unless opp.arena
      return nil unless opp.card(opp.arena).attacks.each_index.any? { |a| enough_energies_for_attack?(opp, opp.arena, a) }
      d.deck_list.find { |x| (c = d.card(x)).pokemon? && c.basic? }
    end

    # the card Destiny Draw draws (deck index), or nil
    def destiny_card(d)
      deck = d.deck_list
      return nil if deck.empty?
      in_play = (0...d.num_in_play_area).map { |e| d.play_area[e] }.compact
      in_play.each do |i|   # Active first, then the Bench
        name = d.card(i).name
        evo = deck.find { |x| (c = d.card(x)).pokemon? && !c.basic? && c.preevo == name }
        return evo if evo
      end
      DuelAbilities::DESTINY_TRAINERS.each do |id|
        t = deck.find { |x| d.card_id(x) == id }
        return t if t
      end
      in_play.each do |i|
        d.card(i).attacks.each do |a|
          next if a.pokemon_power?
          COLORED_TYPES.each do |col|
            next if a.cost[col] == 0
            en = deck.find { |x| (c = d.card(x)).energy? && c.basic_energy? && c.color == col }
            return en if en
          end
        end
      end
      deck.find { |x| d.card(x).energy? }
    end

    # Ignore Weakness / Resistance: also what effects changed them to
    alias ability_arena_card_weakness arena_card_weakness unless method_defined?(:ability_arena_card_weakness)
    def arena_card_weakness(d)
      any_ability?(:NO_WEAKNESS) ? 0 : ability_arena_card_weakness(d)
    end

    alias ability_arena_card_resistance arena_card_resistance unless method_defined?(:ability_arena_card_resistance)
    def arena_card_resistance(d)
      any_ability?(:NO_RESISTANCE) ? 0 : ability_arena_card_resistance(d)
    end
  end

  # online: the games swap their players' abilities (after the build ids)
  class NetDuel
    def exchange_abilities
      mine = TCG.duel_ability
      @session.send_event(["ability", mine&.to_s])
      ev = @session.pull
      theirs = ev.is_a?(Array) && ev[0] == "ability" && ev[1] ? ev[1].to_sym : nil
      @abilities = [mine, theirs]
    end
  end

  #----------------------------------------------------------------------------
  # the slot: "Ability" in the card game menu
  #----------------------------------------------------------------------------
  module DuelAbilities
    module_function

    def menu
      if TCG.abilities.empty?
        pbMessage(_INTL("You haven't found any duel abilities yet."))
        return
      end
      cmd = 0
      loop do
        found = LIST.select { |ab| TCG.abilities.include?(ab) }
        cur = TCG.duel_ability
        names = found.map { |ab| ab == cur ? _INTL("{1} (in use)", name(ab)) : name(ab) }
        cmd = pbMessage(_INTL("Ability in use: {1}", cur ? name(cur) : _INTL("None")),
                        names + [_INTL("None"), _INTL("Cancel")], -1, nil, cmd)
        break if cmd < 0 || cmd > found.size
        if cmd == found.size
          TCG.duel_ability = nil
          pbMessage(_INTL("You won't use an ability in duels."))
          next
        end
        ab = found[cmd]
        next unless pbConfirmMessage(_INTL("{1}: {2}\nUse this ability?", name(ab), description(ab)))
        TCG.duel_ability = ab
        pbMessage(_INTL("{1} is your duel ability now!", name(ab)))
      end
    end
  end
end

unless TCG::MENU_OPTIONS.include?(:ability)   # after "Card"
  TCG::MENU_OPTIONS.insert((TCG::MENU_OPTIONS.index(:card) || TCG::MENU_OPTIONS.size - 1) + 1, :ability)
end
TCG::MENU_LABELS[:ability] = "Ability"

module TCG
  class << self
    alias ability_open_menu_option open_menu_option
    def open_menu_option(opt)
      return DuelAbilities.menu if opt == :ability
      ability_open_menu_option(opt)
    end
  end
end

#------------------------------------------------------------------------------
# script calls for events
#------------------------------------------------------------------------------
# finds an ability (the first one found goes in the empty slot)
def pbTCGGiveAbility(ab, show: true)
  ab = ab.to_sym
  raise ArgumentError, "Unknown duel ability #{ab.inspect}" unless TCG::DuelAbilities.valid?(ab)
  return false if TCG.abilities.include?(ab)
  TCG.abilities << ab
  TCG.duel_ability = ab if TCG.duel_ability.nil?
  if show
    pbMessage(_INTL("You found the duel ability {1}!", TCG::DuelAbilities.name(ab)))
    pbMessage(_INTL("{1}", TCG::DuelAbilities.description(ab)))
  end
  true
end

def pbTCGHasAbility?(ab); TCG.abilities.include?(ab.to_sym); end
def pbTCGAbilityMenu;     TCG::DuelAbilities.menu;           end
