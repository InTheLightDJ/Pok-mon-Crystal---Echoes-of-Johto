#==============================================================================
# Pokemon TCG - per-duelist state (wPlayerDuelVariables / wOpponentDuelVariables)
# and the card-movement routines from src/home/duel.asm, ported 1:1.
#
# Cards are identified by deck index (0-59). @deck_cards is ONE 60-entry array
# shared by the discard pile (front, [0...discard_count]) and the remaining deck
# (back, [not_in_deck...60], top of deck = @deck_cards[@not_in_deck]) exactly
# like the original. (A player's deck can be 55-65 cards, so 60 is deck_size.)
#==============================================================================
module TCG
  class Duelist
    attr_accessor :name, :duelist_type, :deck_ids,
                  :card_locations, :prize_cards, :hand, :deck_cards,
                  :not_in_deck, :discard_count, :prizes,
                  :play_area,          # [arena, bench1..5] deck index or nil
                  :slot_hp, :slot_stage, :slot_changed_type,
                  :slot_defender, :slot_pluspower, :slot_flags,
                  :status, :substatus1, :substatus2, :substatus3,
                  :changed_weakness, :changed_resistance,
                  :disabled_attack_index, :last_turn_damage,
                  :last_turn_status, :last_turn_substatus2,
                  :last_turn_change_weak, :last_turn_effect,
                  :rng   # seeded Random in an online duel (089i_NetDuel.rb)

    # deck_ids: array of deck_size card ids (symbols), in deck-index order. Holo
    # versions (011b_HoloCards.rb) are stored as their normal card, with the
    # tier kept in @holo for the screens.
    def initialize(name, deck_ids, duelist_type)
      @name         = name
      @holo         = deck_ids.map { |id| TCG.holo_tier(id) }
      @deck_ids     = deck_ids.map { |id| TCG.base_id(id) }
      @duelist_type = duelist_type
      reset
    end

    def reset
      @card_locations = Array.new(deck_size, CARD_LOCATION_DECK)
      @deck_cards     = (0...deck_size).to_a
      @prize_cards    = Array.new(MAX_PRIZES)
      @hand           = []
      @not_in_deck    = 0
      @discard_count  = 0
      @prizes         = 0
      @play_area      = Array.new(MAX_PLAY_AREA_POKEMON)
      @slot_hp            = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @slot_stage         = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @slot_changed_type  = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @slot_defender      = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @slot_pluspower     = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @slot_flags         = Array.new(MAX_PLAY_AREA_POKEMON, 0)
      @substatus3 = 0
      clear_all_status_conditions
    end

    def player?; @duelist_type == DUELIST_TYPE_PLAYER; end
    def deck_size; @deck_ids.size; end
    def card_id(deck_index); @deck_ids[deck_index]; end
    # the card as shown (its holo version for a holo card)
    def display_id(deck_index)
      t = @holo[deck_index]
      (t && TCG.holo_id(@deck_ids[deck_index], t)) || @deck_ids[deck_index]
    end
    def card(deck_index);    TCG.card(display_id(deck_index)); end

    def arena;              @play_area[PLAY_AREA_ARENA]; end
    def num_in_play_area;   @play_area.count { |c| !c.nil? }; end
    def cards_in_deck;      deck_size - @not_in_deck; end
    def deck_list;          @deck_cards[@not_in_deck...deck_size]; end   # top first
    def discard_pile;       @deck_cards[0...@discard_count]; end
    def bench;              @play_area[1..].compact; end

    # CountPrizes: prizes not yet drawn
    def count_prizes; (0...MAX_PRIZES).count { |i| @prizes[i] == 1 }; end

    #--------------------------------------------------------------------------
    # deck / hand / discard (home/duel.asm L107-L346)
    #--------------------------------------------------------------------------
    def shuffle_deck
      tail = @deck_cards[@not_in_deck...deck_size].shuffle(random: @rng || TCG.rng)
      @deck_cards[@not_in_deck...deck_size] = tail
    end

    # returns deck index, or nil if the deck is empty (carry)
    def draw_card_from_deck
      return nil if @not_in_deck >= deck_size
      idx = @deck_cards[@not_in_deck]
      @not_in_deck += 1
      @card_locations[idx] = CARD_LOCATION_JUST_DRAWN
      idx
    end

    def return_card_to_deck(idx)
      @not_in_deck -= 1
      @deck_cards[@not_in_deck] = idx
      @card_locations[idx] = CARD_LOCATION_DECK
      idx
    end

    # extract a specific card from the deck (keeps the order of the others)
    def search_card_in_deck_and_add_to_hand(idx)
      remaining = deck_list - [idx]
      @not_in_deck += 1
      @deck_cards[@not_in_deck...deck_size] = remaining
      @card_locations[idx] |= CARD_LOCATION_JUST_DRAWN
      idx
    end

    def add_card_to_hand(idx)
      @card_locations[idx] = CARD_LOCATION_HAND
      @hand.push(idx)
      idx
    end

    def remove_card_from_hand(idx)
      @hand.delete(idx)
      idx
    end

    def move_hand_card_to_discard_pile(idx)
      return unless (@card_locations[idx] & ~CARD_LOCATION_JUST_DRAWN) == CARD_LOCATION_HAND
      remove_card_from_hand(idx)
      put_card_in_discard_pile(idx)
    end

    def put_card_in_discard_pile(idx)
      @card_locations[idx] = CARD_LOCATION_DISCARD_PILE
      @discard_count += 1
      @deck_cards[@discard_count - 1] = idx
      idx
    end

    def move_discard_pile_card_to_hand(idx)
      @card_locations[idx] |= CARD_LOCATION_JUST_DRAWN
      return idx if @discard_count == 0
      pile = discard_pile - [idx]
      @discard_count -= 1
      @deck_cards[0...@discard_count] = pile
      idx
    end

    # CheckPrizeTaken: true if prize slot i has been drawn
    def prize_taken?(i); @prizes[i] == 0; end

    #--------------------------------------------------------------------------
    # play area (home/duel.asm L814-L1290)
    #--------------------------------------------------------------------------
    # can the Pokemon at play area slot e evolve into hand card d?
    # returns :ok, :not_this_turn, or :incompatible
    def check_if_can_evolve_into(d, e)
      return :incompatible if @play_area[e].nil?   # an empty slot (the AI checks every slot)
      cur = card(@play_area[e])
      evo = card(d)
      return :incompatible if evo.preevo.nil? || evo.preevo != cur.name
      return :not_this_turn if (@slot_flags[e] & CAN_EVOLVE_THIS_TURN) == 0
      :ok
    end

    # CheckIfCanEvolveInto_BasicToStage2 (Pokemon Breeder)
    def can_evolve_basic_to_stage2?(d, e)
      return false if (@slot_flags[e] & CAN_EVOLVE_THIS_TURN) == 0
      stage1_name = card(d).preevo
      stage1 = TCG::CARDS.find { |_id, h| h[:name] == stage1_name }
      return false unless stage1
      stage1[1][:preevo] == card(@play_area[e]).name
    end

    # EvolvePokemonCard. returns the pre-evolution deck index.
    def evolve_pokemon_card(d, e)
      pre = @play_area[e]
      old_hp = card(pre).hp
      @play_area[e] = d
      put_hand_card_in_play_area(d, e)
      @slot_hp[e] += card(d).hp - old_hp
      @slot_flags[e] = 0
      @slot_changed_type[e] = 0
      clear_all_status_conditions if e == PLAY_AREA_ARENA
      @slot_stage[e] = card(d).stage
      pre
    end

    def clear_all_status_conditions
      @status             = NO_STATUS
      @substatus1         = 0
      @substatus2         = 0
      @changed_weakness   = 0
      @changed_resistance = 0
      @substatus3 = (@substatus3 || 0) & ~SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE
      @disabled_attack_index = 0
      @last_turn_damage      = 0
      @last_turn_status      = 0
      @last_turn_substatus2  = 0
      @last_turn_change_weak = 0
      @last_turn_effect      = 0
    end

    # returns play area slot, or nil if the play area is full (carry)
    def put_hand_pokemon_card_in_play_area(idx)
      e = num_in_play_area
      return nil if e >= MAX_PLAY_AREA_POKEMON
      put_hand_card_in_play_area(idx, e)
      @play_area[e]         = idx
      c = card(idx)
      @slot_hp[e]           = c.hp
      @slot_flags[e]        = 0
      @slot_changed_type[e] = 0
      @slot_pluspower[e]    = 0
      @slot_defender[e]     = 0
      @slot_stage[e]        = c.stage
      clear_all_status_conditions if e == PLAY_AREA_ARENA
      e
    end

    def put_hand_card_in_play_area(idx, e)
      remove_card_from_hand(idx)
      @card_locations[idx] = CARD_LOCATION_PLAY_AREA | e
    end

    # all cards in slot e (Pokemon + evolutions + attached), deck-index order
    def cards_in_slot(e)
      loc = CARD_LOCATION_PLAY_AREA | e
      (0...deck_size).select { |i| @card_locations[i] == loc }
    end

    def move_play_area_card_to_discard_pile(e)
      empty_play_area_slot(e)
      cards_in_slot(e).each { |i| put_card_in_discard_pile(i) }
    end

    def empty_play_area_slot(e)
      @play_area[e]         = nil
      @slot_hp[e]           = 0
      @slot_stage[e]        = 0
      @slot_changed_type[e] = 0
      @slot_defender[e]     = 0
      @slot_pluspower[e]    = 0
    end

    def shift_pokemon_to_first_play_area_slots
      e = 0
      (0...MAX_PLAY_AREA_POKEMON).each do |d|
        next if @play_area[d].nil?
        swap_play_area_pokemon(d, e)
        e += 1
      end
    end

    def swap_arena_with_bench_pokemon(e)
      clear_all_status_conditions
      swap_play_area_pokemon(PLAY_AREA_ARENA, e)
    end

    def swap_play_area_pokemon(d, e)
      return if d == e
      [@play_area, @slot_hp, @slot_flags, @slot_stage, @slot_changed_type,
       @slot_pluspower, @slot_defender].each { |a| a[d], a[e] = a[e], a[d] }
      ld = CARD_LOCATION_PLAY_AREA | d
      le = CARD_LOCATION_PLAY_AREA | e
      @card_locations.map! { |l| l == le ? ld : (l == ld ? le : l) }
    end

    # GetPlayAreaCardAttachedEnergies -> [array by color (7), total]
    # Double Colorless counts as two COLORLESS.
    def attached_energies(e)
      en = Array.new(NUM_COLORS, 0)
      cards_in_slot(e).each do |i|
        c = card(i)
        next unless c.energy?
        col = c.color
        en[col] += 1
        en[col] += 1 if col == COLORLESS
      end
      [en, en.sum]
    end

    def energy_cards_in_slot(e)
      cards_in_slot(e).select { |i| card(i).energy? }
    end

    # CountCardIDInLocation
    def count_card_id_in_location(id, location)
      (0...deck_size).count { |i| @card_locations[i] == location && card_id(i) == id }
    end
  end
end
