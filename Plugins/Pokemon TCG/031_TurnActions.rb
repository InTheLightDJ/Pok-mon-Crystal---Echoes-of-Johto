#==============================================================================
# Pokemon TCG - turn actions available from the duel menu, plus the Pokemon
# Power / substatus checks they depend on.
#   core.asm: PlayEnergyCard, PlayPokemonCard, CheckAbleToRetreat, AttemptRetreat,
#             TurnDuelistTakePrizes / _SelectPrizeCards (engine/menus/duel.asm)
#   home/substatus.asm: Pkmn Power counting, Rain Dance, Prehistoric Power,
#             Retreat Aid, Acid, Headache, Clairvoyance
# Each action returns a symbol: :ok or the reason it failed (UI shows the text).
#==============================================================================
module TCG
  class Duel
    #--------------------------------------------------------------------------
    # Pokemon Power counting (home/substatus.asm)
    #--------------------------------------------------------------------------
    # CountTurnDuelistPokemonWithActivePkmnPower: arena only counts if it has
    # no CNF/SLP/PRZ; bench always counts.
    def count_pokemon_with_active_pkmn_power(d, id)
      n = 0
      a = d.arena
      n += 1 if a && d.card_id(a) == id && (d.status & CNF_SLP_PRZ) == 0
      d.bench.each { |b| n += 1 if d.card_id(b) == id }
      n
    end

    def count_pokemon_with_active_pkmn_power_both(id)
      @duelists.sum { |d| count_pokemon_with_active_pkmn_power(d, id) }
    end

    def toxic_gas_active?; count_pokemon_with_active_pkmn_power_both(:MUK) > 0; end

    # CheckIsIncapableOfUsingPkmnPower
    def incapable_of_using_pkmn_power?(d, e)
      return true if e == PLAY_AREA_ARENA && (d.status & CNF_SLP_PRZ) != 0
      toxic_gas_active?
    end

    def clairvoyance_active?(d)
      return false if toxic_gas_active?
      count_pokemon_with_active_pkmn_power(d, :OMANYTE) > 0
    end

    def prehistoric_power_active?
      return false if count_pokemon_with_active_pkmn_power_both(:AERODACTYL) == 0
      !toxic_gas_active?
    end

    def rain_dance_active?(d)
      return false if count_pokemon_with_active_pkmn_power(d, :BLASTOISE) == 0
      !toxic_gas_active?
    end

    # GetPlayAreaCardColor: changed type overrides the card's color
    def play_area_card_color(d, e)
      ct = d.slot_changed_type[e]
      return ct & 0x0f if (ct & HAS_CHANGED_COLOR) != 0
      d.card(d.play_area[e]).color
    end

    # GetLoadedCard1RetreatCost (Retreat Aid counts bench Dodrio only)
    def retreat_cost(d, e = PLAY_AREA_ARENA)
      cost = d.card(d.play_area[e]).retreat
      dodrio = d.bench.count { |b| d.card_id(b) == :DODRIO }
      return cost if dodrio == 0 || toxic_gas_active?
      [cost - dodrio, 0].max
    end

    def unable_to_retreat_due_to_effect?(d); d.substatus2 == SUBSTATUS2_ACID; end
    def cant_use_trainer_due_to_effect?(d);  (d.substatus3 & SUBSTATUS3_HEADACHE) != 0; end

    #--------------------------------------------------------------------------
    # PlayEnergyCard
    #--------------------------------------------------------------------------
    # can the turn holder attach energy idx to slot e right now?
    def can_play_energy?(idx, e)
      d = turn_duelist
      return true if rain_dance_scenario?(d, idx, e)
      !@already_played_energy
    end

    def rain_dance_scenario?(d, idx, e)
      d.card(idx).type == TYPE_NAMES["TYPE_ENERGY_WATER"] &&
        rain_dance_active?(d) && play_area_card_color(d, e) == WATER
    end

    def play_energy_card(idx, e)
      d = turn_duelist
      return :already_played_energy unless can_play_energy?(idx, e)
      @already_played_energy = true unless rain_dance_scenario?(d, idx, e)
      d.put_hand_card_in_play_area(idx, e)
      @ui.event(:attach_energy, d.name, idx, e)
      :ok
    end

    #--------------------------------------------------------------------------
    # PlayPokemonCard
    #--------------------------------------------------------------------------
    def play_basic_pokemon(idx)
      d = turn_duelist
      return :no_space if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
      e = put_basic_pokemon_in_play_area(idx)
      d.slot_stage[e] = BASIC
      @ui.event(:play_pokemon, d.name, idx, e)
      process_played_pokemon_card(idx, e)
      :ok
    end

    # slots that hand card idx could evolve right now
    def evolution_targets(idx)
      d = turn_duelist
      (0...d.num_in_play_area).select { |e| d.check_if_can_evolve_into(idx, e) == :ok }
    end

    # why a Stage 1/2 card can't be played (nil if it can)
    def cant_evolve_reason(idx)
      d = turn_duelist
      res = (0...d.num_in_play_area).map { |e| d.check_if_can_evolve_into(idx, e) }
      return :prehistoric_power if res.include?(:ok) && prehistoric_power_active?
      return nil if res.include?(:ok)
      res.include?(:not_this_turn) ? :not_this_turn : :no_evolution_target
    end

    def evolve_pokemon(idx, e)
      d = turn_duelist
      return :prehistoric_power if prehistoric_power_active?
      return :cant_evolve unless d.check_if_can_evolve_into(idx, e) == :ok
      d.evolve_pokemon_card(idx, e)
      @ui.event(:evolve, d.name, idx, e)
      process_played_pokemon_card(idx, e)
      :ok
    end

    #--------------------------------------------------------------------------
    # Retreat (CheckAbleToRetreat / AttemptRetreat)
    #--------------------------------------------------------------------------
    # nil if able, otherwise the reason
    def cant_retreat_reason
      d = turn_duelist
      return :confusion_check_failed if (d.status & CNF_SLP_PRZ) == CONFUSED && @confusion_retreat_check_unsuccessful
      return :acid if unable_to_retreat_due_to_effect?(d)
      st = d.status & CNF_SLP_PRZ
      return :paralyzed if st == PARALYZED
      return :asleep if st == ASLEEP
      return :no_bench if d.bench.empty?
      return :trainer_in_arena if d.card(d.arena).trainer?
      return :not_enough_energy if d.attached_energies(PLAY_AREA_ARENA)[1] < retreat_cost(d)
      nil
    end

    # energy_cards: deck indices to discard (chosen by controller, must cover
    # the cost, counting DCE as 2); bench_slot: Pokemon to switch in.
    # returns :ok, :confused_failed, or a cant_retreat_reason
    def attempt_retreat(energy_cards, bench_slot)
      reason = cant_retreat_reason
      return reason if reason
      d = turn_duelist
      confused = (d.status & CNF_SLP_PRZ) == CONFUSED
      energy_cards.each { |i| d.put_card_in_discard_pile(i) }
      if confused
        coin_check(_INTL("Confusion check! If Heads, {1} can retreat.", d.card(d.arena).name),
                   "Confusion check!\nIf Tails, unable to Retreat.")
        if toss_coin == TAILS
          @confusion_retreat_check_unsuccessful = true
          @ui.message(_INTL("Unable to retreat due to Confusion."))
          return :confused_failed
        end
      end
      d.swap_arena_with_bench_pokemon(bench_slot)
      @confusion_retreat_check_unsuccessful = false
      @ui.event(:retreat, d.name, bench_slot)
      :ok
    end

    #--------------------------------------------------------------------------
    # Prizes (TurnDuelistTakePrizes / _SelectPrizeCards)
    #--------------------------------------------------------------------------
    # take n prizes; the controller picks prize slots. Returns true if the
    # turn holder has no prizes left afterwards (wins).
    def turn_duelist_take_prizes(n)
      d = turn_duelist
      n.times do
        break if d.prizes == 0
        avail = (0...6).select { |i| d.prizes[i] == 1 }
        slot = turn_controller.choose_prize(self, avail)
        slot = avail.first unless avail.include?(slot)
        d.prizes &= ~(1 << slot)
        idx = d.prize_cards[slot]
        d.add_card_to_hand(idx)
        @ui.event(:take_prize, d.name, idx)
      end
      d.prizes == 0
    end

    # filled in by later scripts
    def process_played_pokemon_card(idx, e); end
  end
end
