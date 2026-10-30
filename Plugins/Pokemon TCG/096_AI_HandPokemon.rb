#==============================================================================
# Pokemon TCG - AI: playing Basic Pokemon and evolving.
# Port of engine/duel/ai/hand_pokemon.asm (AIDecidePlayPokemonCard,
# AIDecideEvolution, AIDecideSpecialEvolutions, AIDecidePlayLegendaryBirds)
# + core.asm helpers.
#==============================================================================
module TCG
  ENERGY_CARD_IDS = { :GRASS_ENERGY => 1, :FIRE_ENERGY => 2, :WATER_ENERGY => 3, :LIGHTNING_ENERGY => 4,
                      :FIGHTING_ENERGY => 5, :PSYCHIC_ENERGY => 6, :DOUBLE_COLORLESS_ENERGY => 7 }
  ENERGY_FLAG = { :FIRE_ENERGY => 0x01, :GRASS_ENERGY => 0x02, :LIGHTNING_ENERGY => 0x04,
                  :WATER_ENERGY => 0x08, :FIGHTING_ENERGY => 0x10, :PSYCHIC_ENERGY => 0x20,
                  :DOUBLE_COLORLESS_ENERGY => 0x40, :DARKNESS_ENERGY => 0x80, :METAL_ENERGY => 0x100 }
  ENERGY_FLAGS_ANY = 0x1ff
  COLOR_ENERGY_ID = [:FIRE_ENERGY, :GRASS_ENERGY, :LIGHTNING_ENERGY, :WATER_ENERGY,
                     :FIGHTING_ENERGY, :PSYCHIC_ENERGY, :DOUBLE_COLORLESS_ENERGY,
                     :DARKNESS_ENERGY, :METAL_ENERGY]

  class AIController
    # with the turn holder's arena temporarily replaced by deck index idx
    def with_arena_as(d, idx)
      old = d.play_area[0]
      d.play_area[0] = idx
      yield
    ensure
      d.play_area[0] = old
    end

    # CheckEnergyNeededForAttack: [enough?, colored_needed, colorless_needed, energy_id]
    def energy_needed_for_attack(duel, e, ai)
      d = duel.turn_duelist
      atk = d.card(d.play_area[e]).attacks[ai]
      return [false, 0, 0, nil] if atk.nil? || atk.pokemon_power?
      en, total = duel.attached_energies_with_energy_burn(d, e)
      cost_sum = needed = 0
      type = nil
      COLORED_TYPES.each do |col|
        c = atk.cost[col]
        next if c == 0
        cost_sum += c
        if en[col] < c
          needed += c - en[col]
          type = col
        end
      end
      used = cost_sum - needed
      rem = total - used - atk.cost[COLORLESS]
      return [true, 0, 0, nil] if rem >= 0 && needed == 0
      colorless = rem < 0 ? -rem : 0
      [false, needed, colorless, type ? COLOR_ENERGY_ID[type] : nil]
    end

    # GetAttacksEnergyCostBits (any colorless cost => $ff)
    def attacks_energy_cost_bits(card)
      bits = 0
      card.attacks.each do |a|
        COLORED_TYPES.each { |col| bits |= (1 << col) if a.cost[col] > 0 }
        bits = ENERGY_FLAGS_ANY if a.cost[COLORLESS] > 0
      end
      bits
    end

    # CheckEnergyFlagsNeededInList: is there an energy card in hand whose type
    # is among the attacks' cost flags ($ff when any attack has colorless cost)
    def energy_flags_needed_in_hand?(d, flags)
      d.hand.any? do |i|
        f = ENERGY_FLAG[d.card_id(i)]
        f && (f & flags) != 0
      end
    end

    # CheckForEvolutionInList / CheckForEvolutionInDeck: uses the ARENA slot's
    # can-evolve flag while the card is put in the arena temporarily
    def evolution_for_in?(duel, d, idx, location)
      with_arena_as(d, idx) do
        (0...d.deck_size).any? do |i|
          d.card_locations[i] == location && d.check_if_can_evolve_into(i, 0) == :ok
        end
      end
    end

    # CheckIfAnyAttackKnocksOutDefendingCard; slot e attacker
    def any_attack_knocks_out?(duel, e = PLAY_AREA_ARENA)
      [0, 1].each do |ai|
        dmg, = duel.ai_estimate_damage_versus_defending(e, ai)
        return ai if duel.non_turn_duelist.slot_hp[0] - dmg <= 0
      end
      nil
    end

    # CheckIfActiveCardCanKnockOut
    def active_card_can_knock_out?(duel)
      ai = any_attack_knocks_out?(duel)
      ai && !attack_unusable?(duel, PLAY_AREA_ARENA, ai)
    end

    # CanArenaCardUseNonResidualAttack
    def arena_can_use_non_residual_attack?(duel)
      d = duel.turn_duelist
      [0, 1].any? do |ai|
        next false if attack_unusable?(duel, PLAY_AREA_ARENA, ai)
        !d.card(d.arena).attacks[ai].residual?
      end
    end

    # CheckIfCanDamageDefendingPokemon (slot e)
    def can_damage_defending?(duel, e)
      [0, 1].any? do |ai|
        next false if attack_unusable?(duel, e, ai)
        duel.ai_estimate_damage_versus_defending(e, ai)[0] != 0
      end
    end

    # CheckDamageToMrMime: true (carry) = fine
    def ok_against_mr_mime?(duel, e)
      nd = duel.non_turn_duelist
      return true unless nd.card_id(nd.arena) == :MR_MIME
      can_damage_defending?(duel, e)
    end

    # LookForEnergyNeededInHand
    def energy_needed_in_hand?(duel)
      d = duel.turn_duelist
      [0, 1].each do |ai|
        ok, b, c, id = energy_needed_for_attack(duel, PLAY_AREA_ARENA, ai)
        next if ok
        if b + c == 1
          return b == 0 ? d.hand.any? { |i| d.card(i).energy? } : d.hand.any? { |i| d.card_id(i) == id }
        elsif b + c == 2 && c == 2
          return d.hand.any? { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY }
        end
      end
      false
    end

    def play_from_hand_priority; []; end   # per-deck list: see 099b

    # SortTempHandByIDList: in-place swaps, listed IDs moved to the front
    # in list order (unlisted cards keep the order the swaps leave them in)
    def sort_temp_hand_by_id_list(d, list)
      c = 0
      play_from_hand_priority.each do |id|
        (c...list.size).each do |i|
          next unless d.card_id(list[i]) == id
          list[c], list[i] = list[i], list[c]
          c += 1
        end
      end
      list
    end

    #--------------------------------------------------------------------------
    # AIDecidePlayPokemonCard — returns true if the turn ended
    #--------------------------------------------------------------------------
    def decide_play_pokemon_card(duel)
      d = duel.turn_duelist
      hand = d.hand.dup
      sort_temp_hand_by_id_list(d, hand)
      hand.each do |i|
        next unless d.hand.include?(i)
        c = d.card(i)
        next unless c.pokemon? && c.stage == BASIC
        @score = 130
        decide_play_legendary_birds(duel, d, i)
        d.num_in_play_area >= 4 ? ai_discourage(20) : ai_encourage(50)
        ai_encourage(20) if defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)[0]
        ai_encourage(20) if energy_flags_needed_in_hand?(d, attacks_energy_cost_bits(c))
        ai_encourage(20) if evolution_for_in?(duel, d, i, CARD_LOCATION_HAND)
        ai_encourage(10) if evolution_for_in?(duel, d, i, CARD_LOCATION_DECK)
        next if @score < 180
        next if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        if duel.play_basic_pokemon(i) == :ok
          say(duel, _INTL("{1} placed {2} on the Bench.", d.name, c.name))
        end
        return true if turn_over?(duel)
      end
      decide_evolution(duel)
      turn_over?(duel)
    end

    # AIDecidePlayLegendaryBirds
    def decide_play_legendary_birds(duel, d, idx)
      return unless [:LEGENDARY_ZAPDOS_DECK, :LEGENDARY_ARTICUNO_DECK, :LEGENDARY_RONALD_DECK].include?(@deck_id)
      case d.card_id(idx)
      when :ARTICUNO_LV37
        return if d.num_in_play_area < 2
        nd = duel.non_turn_duelist
        bad = active_card_can_knock_out?(duel) || !arena_can_use_non_residual_attack?(duel) ||
              decide_whether_to_retreat(duel) || (nd.status & CNF_SLP_PRZ) != 0
        unless bad
          opp_power = nd.card(nd.arena).attacks.first&.pokemon_power?
          return if !opp_power && d.num_in_play_area >= MAX_BENCH_POKEMON
          bad = duel.toxic_gas_active? || nd.card_id(nd.arena) == :SNORLAX
        end
        bad ? ai_discourage(100) : ai_encourage(70)
      when :MOLTRES_LV37
        ai_discourage(100) if d.not_in_deck >= 56
      when :ZAPDOS_LV68
        ai_discourage(100) if duel.toxic_gas_active?
      end
    end

    #--------------------------------------------------------------------------
    # AIDecideEvolution
    #--------------------------------------------------------------------------
    def decide_evolution(duel)
      d = duel.turn_duelist
      d.hand.dup.each do |i|
        next unless d.hand.include?(i)
        next if duel.prehistoric_power_active?
        c = d.card(i)
        next unless c.pokemon? && c.stage != BASIC
        (0...d.num_in_play_area).each do |e|
          next unless d.check_if_can_evolve_into(i, e) == :ok
          @score = 0x80
          decide_special_evolutions(duel, d, e)
          # current card
          can_attack = !attack_unusable?(duel, e, 0) || !attack_unusable?(duel, e, 1)
          can_ko = false
          if can_attack && (k = any_attack_knocks_out?(duel, e)) && !attack_unusable?(duel, e, k)
            can_ko = true
          end
          # evolution in place
          with_arena_slot_as(d, e, i) do
            if !attack_unusable?(duel, e, 0) || !attack_unusable?(duel, e, 1)
              ai_encourage(5)
            elsif can_attack
              ai_discourage(2)
              ai_encourage(7) if !duel.already_played_energy && e == 0 && energy_needed_in_hand?(duel)
            end
            if can_attack && e == 0
              k = any_attack_knocks_out?(duel, e)
              if k && !attack_unusable?(duel, e, k)
                ai_encourage(5)
              elsif can_ko
                ai_discourage(20)
              end
            end
            ai_discourage(5) if e == 0 && defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)[0]
            ai_discourage(20) unless ok_against_mr_mime?(duel, e)
          end
          if e == 0
            ai_encourage(5) if defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)[0]
            ai_encourage(4) if d.status != 0
          end
          if evolution_for_in?(duel, d, i, CARD_LOCATION_HAND)
            ai_encourage(2)
          elsif evolution_for_in?(duel, d, i, CARD_LOCATION_DECK)
            ai_encourage(1)
          end
          dmg = duel.card_damage_and_max_hp(d, e)[0]
          ai_discourage(dmg_counters(dmg >> 2)) if dmg > 0
          cur = d.card(d.play_area[e])
          if d.card_id(d.play_area[e]) == :MYSTERIOUS_FOSSIL
            ai_encourage(5)
          elsif cur.ai_info == ["AI_INFO_ENCOURAGE_EVO"]   # ORIGINAL BUG: HAS_EVOLUTION not masked
            ai_encourage(2)
          end
          if @deck_id == :PIKACHU_DECK && [:PIKACHU_LV12, :PIKACHU_LV14, :PIKACHU_LV16, :PIKACHU_ALT_LV16].include?(d.card_id(d.play_area[e]))
            ai_discourage(3)
          end
          next if @score < 133
          from = cur.name
          if duel.evolve_pokemon(i, e) == :ok
            say(duel, _INTL("{1} evolved into {2}!", from, c.name))
          end
          break
        end
      end
    end

    # temporarily put card idx in play area slot e (for evaluation)
    def with_arena_slot_as(d, e, idx)
      old = d.play_area[e]
      d.play_area[e] = idx
      yield
    ensure
      d.play_area[e] = old
    end

    # AIDecideSpecialEvolutions
    def decide_special_evolutions(duel, d, e)
      id = d.card_id(d.play_area[e])
      case @deck_id
      when :LEGENDARY_DRAGONITE_DECK
        case id
        when :CHARMELEON
          if d.energy_cards_in_slot(e).size >= 3 && d.energy_cards_in_slot(e).size + d.hand.count { |i| d.card(i).energy? } >= 6
            ai_encourage(3)
          else
            ai_discourage(10)
          end
        when :MAGIKARP
          ai_encourage(3) if e != 0 && d.energy_cards_in_slot(e).size >= 2
        when :DRAGONAIR then special_evolution_dragonair(duel, d, e)
        end
      when :INVINCIBLE_RONALD_DECK
        ai_encourage(10) if id == :GRIMER && e != 0
      when :LEGENDARY_RONALD_DECK
        special_evolution_dragonair(duel, d, e) if id == :DRAGONAIR
      end
    end

    def special_evolution_dragonair(duel, d, e)
      ok = if e != 0
             (0...d.num_in_play_area).sum { |s| duel.card_damage_and_max_hp(d, s)[0] } > 70
           else
             duel.card_damage_and_max_hp(d, 0)[0] >= 50 && d.attached_energies(0)[1] >= 3
           end
      ok && !duel.toxic_gas_active? ? ai_encourage(10) : ai_discourage(10)
    end
  end
end
