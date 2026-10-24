#==============================================================================
# Pokemon TCG - AI energy attachment. Port of engine/duel/ai/energy.asm
# (AIProcessEnergyCards, DetermineAIScoreOfAttackEnergyRequirement,
# FindPlayAreaCardWithHighestAIScore, AITryToPlayEnergyCard,
# GetEnergyCardForDiscardOrEnergyBoostAttack, CheckIfEvolutionNeedsEnergyForAttack,
# CheckSpecificDecksToAttachDoubleColorless) + core.asm helpers
# (CheckIfNoSurplusEnergyForAttack, HandleAIEnergyScoringForRepeatedBenchPokemon,
# boss deck checks).
#==============================================================================
module TCG
  AI_ENERGY_FLAG_DONT_PLAY       = 0x01
  AI_ENERGY_FLAG_SKIP_EVOLUTION  = 0x02
  AI_ENERGY_FLAG_SKIP_ARENA_CARD = 0x04

  class AIController
    # CheckIfOpponentHasBossDeckID: LEGENDARY_MOLTRES .. before MUSCLES_FOR_BRAINS
    def boss_deck?
      keys = DECKS.keys
      i = keys.index(@deck_id) or return false
      i >= keys.index(:LEGENDARY_MOLTRES_DECK) && i < keys.index(:MUSCLES_FOR_BRAINS_DECK)
    end

    # CheckIfNotABossDeckID (no story: legendary cards never received)
    def apply_boss_energy_scoring?; boss_deck?; end

    # per-deck wAICardListEnergyBonus: { card_id => [max_energy, score] } — TODO step G
    def energy_bonus_list; {}; end

    # CheckIfNoSurplusEnergyForAttack: :no_attack, :not_enough, :exact, or surplus Integer
    def surplus_energy_for_attack(duel, e, ai)
      d = duel.turn_duelist
      atk = d.card(d.play_area[e]).attacks[ai]
      return :no_attack if atk.nil? || atk.pokemon_power?
      en, total = duel.attached_energies_with_energy_burn(d, e)
      used = (0...NUM_COLORED_TYPES).sum { |col| [atk.cost[col], en[col]].min }
      rem = total - used - atk.cost[COLORLESS]
      return :not_enough if rem < 0
      rem == 0 ? :exact : rem
    end

    # CheckCardEvolutionInHandOrDeck: evolution deck index or nil
    def card_evolution_in_hand_or_deck(d, idx)
      with_arena_as(d, idx) do
        (0...DECK_SIZE).find do |i|
          l = d.card_locations[i]
          (l == CARD_LOCATION_DECK || l == CARD_LOCATION_HAND) && d.check_if_can_evolve_into(i, 0) == :ok
        end
      end
    end

    def hand_has_id?(d, id); d.hand.any? { |i| d.card_id(i) == id }; end

    #--------------------------------------------------------------------------
    # AIProcessAndTryToPlayEnergy / AIProcessEnergyCards
    # returns the chosen slot (or nil). Plays the card unless DONT_PLAY.
    #--------------------------------------------------------------------------
    def process_and_try_to_play_energy(duel, flags = 0)
      d = duel.turn_duelist
      return nil if flags == 0 && d.hand.none? { |i| d.card(i).energy? }
      saved_score = @score
      energy_ai = Array.new(MAX_PLAY_AREA_POKEMON, 0x80)
      score_legendary_articuno_cards(duel, energy_ai) if @deck_id == :LEGENDARY_ARTICUNO_DECK
      scores = []
      (0...d.num_in_play_area).each do |e|
        @score = 0x80
        @evo_in_hand = nil
        if (flags & AI_ENERGY_FLAG_SKIP_EVOLUTION) == 0
          idx = d.play_area[e]
          unless energy_flags_needed_in_hand?(d, attacks_energy_cost_bits(d.card(idx)))
            scores[e] = @score
            next
          end
          if (evo = with_arena_as(d, idx) { d.hand.find { |i| d.check_if_can_evolve_into(i, 0) == :ok } })
            @evo_in_hand = evo
            ai_encourage(2)
          elsif evolution_for_in?(duel, d, idx, CARD_LOCATION_DECK)
            ai_encourage(1)
          end
        end
        ai_encourage(1) if !duel.toxic_gas_active? && duel.count_pokemon_with_active_pkmn_power(d, :VENUSAUR_LV67) > 0
        if e == 0
          if (@barrier_flag_counter & AI_MEWTWO_MILL) != 0
            ai_discourage(5)
            arena_danger(duel, d)
          else
            ai_encourage(4)
            hp = dmg_counters(d.slot_hp[0])
            if hp < 3 && ((hp == 2 && (d.status & DOUBLE_POISONED) == DOUBLE_POISONED) ||
                          (hp != 2 && (d.status & POISONED) != 0))
              ai_discourage(10)
              ai_encourage(6) if d.num_in_play_area == 1
            else
              arena_danger(duel, d)
            end
          end
        else
          hp = dmg_counters(d.slot_hp[e])
          ai_discourage(3 - hp) if hp < 3
        end
        # wAICardListEnergyBonus
        if (bonus = energy_bonus_list[d.card_id(d.play_area[e])])
          max, sc = bonus
          if d.attached_energies(e)[1] >= max
            ai_discourage(10)
            scores[e] = @score   # ORIGINAL BUG: skips the rest (should continue)
            next
          end
          sc >= 0x80 ? ai_encourage(sc - 0x80) : ai_discourage(0x80 - sc)
        end
        if apply_boss_energy_scoring?
          energy_scoring_for_repeated_bench_pokemon(duel, energy_ai) if e == 0 || true
          v = energy_ai[e]
          v >= 0x80 ? ai_encourage(v - 0x80) : ai_discourage(0x80 - v)
        end
        ai_encourage(1)
        determine_attack_energy_requirement_score(duel, e, 0)
        determine_attack_energy_requirement_score(duel, e, 1)
        scores[e] = @score
      end
      slot = find_play_area_card_with_highest_score(d, scores, flags)
      @score = saved_score
      return slot if flags != 0 || slot.nil?
      try_to_play_energy_card(duel, slot) ? slot : nil
    end

    def arena_danger(duel, d)
      if defending_pokemon_can_knock_out(duel, PLAY_AREA_ARENA)[0]
        ai_discourage(10)
        ai_encourage(6) if d.num_in_play_area == 1
      end
    end

    # used by special_attacks (Energy Spike)
    def energy_would_be_useful_somewhere?(duel)
      !process_and_try_to_play_energy(duel, AI_ENERGY_FLAG_DONT_PLAY | AI_ENERGY_FLAG_SKIP_EVOLUTION).nil?
    end

    # FindPlayAreaCardWithHighestAIScore
    def find_play_area_card_with_highest_score(d, scores, flags)
      if (flags & AI_ENERGY_FLAG_SKIP_ARENA_CARD) != 0
        return nil if d.num_in_play_area < 2
        best = 0; slot = 1
        (1...d.num_in_play_area).each { |e| (best = scores[e]; slot = e) if scores[e] > best }
        return slot
      end
      best = 0; slot = 0
      (0...d.num_in_play_area).each { |e| (best = scores[e]; slot = e) if scores[e] > best }
      best >= 0x85 ? slot : nil
    end

    # DetermineAIScoreOfAttackEnergyRequirement
    def determine_attack_energy_requirement_score(duel, e, ai)
      d = duel.turn_duelist
      atk = d.card(d.play_area[e]).attacks[ai]
      ok, b, c, id = energy_needed_for_attack(duel, e, ai)
      if !ok && atk
        ai_discourage(5) if atk.flag?(:IGNORE_THIS_ATTACK)
        if b > 0 && hand_has_id?(d, id)
          ai_encourage(4)
          if b + c == 1
            ai_encourage(3)
            attack_kos_bonus(duel, e, ai)
          end
        elsif c > 0
          ai_encourage(3)
          if b + c == 1
            ai_encourage(3)
            attack_kos_bonus(duel, e, ai)
          end
        end
      elsif ok && atk
        if atk.flag?(:ATTACHED_ENERGY_BOOST)
          if atk.param == 2   # MAX_ENERGY_BOOST_IS_LIMITED
            s = surplus_energy_for_attack(duel, e, ai)
            if s.is_a?(Integer) && s >= 3
              ai_discourage(5)
            else
              energy_boost_bonus(duel, e, ai, atk)
            end
          else
            ai_encourage(atk.param)
          end
        elsif atk.flag?(:DISCARD_ENERGY) && d.card_id(d.play_area[e]) != :ZAPDOS_LV64
          s = surplus_energy_for_attack(duel, e, ai)
          s.is_a?(Integer) ? ai_discourage(5) : energy_boost_bonus(duel, e, ai, atk)
        end
      end
      evolution_energy_bonus(duel, d, e, ai) if @evo_in_hand
    end

    def energy_boost_bonus(duel, e, ai, atk)
      ai_encourage(2)
      return unless atk.flag?(:ATTACHED_ENERGY_BOOST)
      dmg, = duel.ai_estimate_damage_versus_defending(e, ai)
      hp = duel.non_turn_duelist.slot_hp[0]
      return if hp - dmg <= 0
      return unless hp - (dmg + 10) <= 0
      ai_encourage(20)
      ai_encourage(10) if e == 0
    end

    def attack_kos_bonus(duel, e, ai)
      return unless e == 0
      dmg, = duel.ai_estimate_damage_versus_defending(e, ai)
      return unless duel.non_turn_duelist.slot_hp[0] - dmg <= 0
      ai_encourage(20)
      ai_encourage(10)   # ORIGINAL: duplicated "is active" check
    end

    def evolution_energy_bonus(duel, d, e, ai)
      with_arena_slot_as(d, e, @evo_in_hand) do
        ok, b, c, id = energy_needed_for_attack(duel, e, ai)
        atk = d.card(@evo_in_hand).attacks[ai]
        next if ok || atk.nil? || atk.flag?(:IGNORE_THIS_ATTACK)
        if b > 0 && hand_has_id?(d, id)
          ai_encourage(2)
        elsif c > 0
          ai_encourage(1)
        end
      end
    end

    # HandleAIEnergyScoringForRepeatedBenchPokemon (boss decks): among bench
    # Pokemon sharing a card ID, favour the one with the best
    # (2 x energy - damage counters) score
    def energy_scoring_for_repeated_bench_pokemon(duel, energy_ai)
      return if @repeated_scored == duel.duel_turns
      @repeated_scored = duel.duel_turns
      d = duel.turn_duelist
      handled = []
      (1...d.num_in_play_area).each do |e|
        next if handled.include?(e)
        id = d.card_id(d.play_area[e])
        same = (e...d.num_in_play_area).select { |x| d.card_id(d.play_area[x]) == id }
        handled.concat(same)
        next if same.size < 2
        sc = same.map { |x| [0x80 + 2 * d.energy_cards_in_slot(x).size - dmg_counters(duel.card_damage_and_max_hp(d, x)[0]), x] }
        best = sc.max_by(&:first)[1]
        same.each { |x| x == best ? energy_ai[x] += 1 : energy_ai[x] -= 1 }
      end
    end

    # ScoreLegendaryArticunoCards (core.asm) — TODO
    def score_legendary_articuno_cards(duel, energy_ai); end

    #--------------------------------------------------------------------------
    # AITryToPlayEnergyCard — returns true if an energy card was played
    #--------------------------------------------------------------------------
    def try_to_play_energy_card(duel, e)
      d = duel.turn_duelist
      [0, 1].each do |ai|
        ok, b, c, id = energy_needed_for_attack(duel, e, ai)
        next if ok || (b == 0 && c == 0)
        return true if attach_needed(duel, d, e, b, c, id)
        return false if ai == 1
      end
      # neither attack needs energy: discard / energy boost attacks
      [0, 1].each do |ai|
        atk = d.card(d.play_area[e]).attacks[ai]
        next unless atk && (atk.flag?(:ATTACHED_ENERGY_BOOST) || atk.flag?(:DISCARD_ENERGY))
        r = energy_for_discard_or_boost(d, e, ai)
        return false if r.nil?   # Zapdos Thunderbolt
        b, c, id = r
        return attach_needed(duel, d, e, b, c, id, true)
      end
      return false unless evolution_needs_energy_for_attack?(duel, d, e)
      ok, b, c, id = energy_needed_for_attack(duel, e, 1)
      attach_needed(duel, d, e, b, c, id, true)
    end

    def attach_needed(duel, d, e, b, c, id, done_after = false)
      if (dce = specific_deck_double_colorless(d, e))
        return play_energy(duel, d, dce, e)
      end
      if b > 0 && (card = d.hand.find { |i| d.card_id(i) == id })
        return play_energy(duel, d, card, e)
      end
      if e == 0 && c == 2 && b == 0 && (card = d.hand.find { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY })
        return play_energy(duel, d, card, e)
      end
      return false if e == 0 && c == 0
      d.hand.select { |i| d.card(i).energy? }.shuffle.each do |i|
        next if boss_deck? && d.card_id(i) == :DOUBLE_COLORLESS_ENERGY
        return play_energy(duel, d, i, e)
      end
      false
    end

    def play_energy(duel, d, card, e)
      return false unless duel.play_energy_card(card, e) == :ok
      say(duel, _INTL("{1} attached {2} to {3}.", d.name, d.card(card).name, d.card(d.play_area[e]).name))
      true
    end

    # GetEnergyCardForDiscardOrEnergyBoostAttack -> [b, c, energy_id] or nil
    def energy_for_discard_or_boost(d, e, ai)
      id = d.card_id(d.play_area[e])
      if ai == 1
        return nil if id == :ZAPDOS_LV64
        return [0, 1, nil] if id == :CHARIZARD || id == :EXEGGUTOR
      end
      atk = d.card(d.play_area[e]).attacks[ai]
      col = [FIRE, GRASS, LIGHTNING, WATER, FIGHTING].find { |x| atk.cost[x] > 0 } || PSYCHIC
      [1, 0, COLOR_ENERGY_ID[col]]
    end

    # CheckIfEvolutionNeedsEnergyForAttack (second attack)
    def evolution_needs_energy_for_attack?(duel, d, e)
      evo = card_evolution_in_hand_or_deck(d, d.play_area[e]) or return false
      with_arena_slot_as(d, e, evo) { !energy_needed_for_attack(duel, e, 1)[0] }
    end

    # CheckSpecificDecksToAttachDoubleColorless -> DCE deck index or nil
    def specific_deck_double_colorless(d, e)
      ids = case @deck_id
            when :LEGENDARY_DRAGONITE_DECK then [:CHARMANDER, :DRATINI]
            when :FIRE_CHARGE_DECK then [:GROWLITHE]
            when :LEGENDARY_RONALD_DECK then [:DRATINI]
            else []
            end
      return nil unless ids.include?(d.card_id(d.play_area[e]))
      return nil if d.attached_energies(e)[0][COLORLESS] > 0
      d.hand.find { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY }
    end
  end
end
