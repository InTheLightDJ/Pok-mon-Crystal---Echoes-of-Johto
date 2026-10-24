#==============================================================================
# Pokemon TCG - AI Pokemon Powers. Port of engine/duel/ai/pkmn_powers.asm
# (HandleAIPkmnPowers + Heal/Shift/Peek/Strange Behavior/Curse, Cowardice).
# Powers are used through Duel#use_pkmn_power with @ai_choices preset, the
# same way the AIPlay_* trainer routines work.
#==============================================================================
module TCG
  class AIController
    def ai_use_power(duel, e, choices)
      @ai_choices = choices
      r = duel.use_pkmn_power(e)
      @scene&.refresh(duel)
      r
    ensure
      @ai_choices = nil
    end

    # EFFECTCMDTYPE_INITIAL_EFFECT_2 of the slot's first attack/power
    def power_initial_effect_2_fails?(duel, e)
      d = duel.turn_duelist
      old = duel.atk
      duel.copy_attack_data_and_damage(d.play_area[e], 0)
      duel.atk.temp[:power_slot] = e
      duel.silently { duel.try_execute_effect_command(EFFECT_INITIAL_EFFECT_2) }
    ensure
      duel.atk = old
    end

    #--------------------------------------------------------------------------
    # HandleAIPkmnPowers: true if the turn/duel ended
    #--------------------------------------------------------------------------
    def handle_pkmn_powers(duel)
      return false if duel.toxic_gas_active?
      return false if ai_choose_randomly_not_to_do_action?
      d = duel.turn_duelist
      n = d.num_in_play_area
      skip_arena = (d.status & CNF_SLP_PRZ) != 0
      (0...n).each do |c|
        next if c == 0 && skip_arena
        break if c >= d.num_in_play_area
        idx = d.play_area[c]
        atk = d.card(idx).attacks[0]
        next unless atk && atk.pokemon_power?
        next if power_initial_effect_2_fails?(duel, c)
        @power_card = idx
        case d.card_id(idx)
        when :VILEPLUME then ai_power_heal(duel, c)
        when :VENOMOTH  then ai_power_shift(duel, c)
        when :MANKEY    then ai_power_peek(duel, c)
        when :SLOWBRO   then ai_power_strange_behavior(duel, c)
        when :GENGAR    then ai_power_curse(duel, c)
        end
        return true if turn_over?(duel)
      end
      false
    end

    #--------------------------------------------------------------------------
    # Heal (Vileplume)
    #--------------------------------------------------------------------------
    def ai_power_heal(duel, c)
      t = heal_target(duel) or return
      ai_use_power(duel, c, { :Heal => t })
    end

    def heal_target(duel)
      d = duel.turn_duelist
      if duel.card_damage_and_max_hp(d, 0)[0] != 0
        dm = defending_ko_damage(duel, PLAY_AREA_ARENA)
        return 0 unless dm
        heal = [duel.card_damage_and_max_hp(d, 0)[0], 10].min
        return 0 if d.slot_hp[0] + heal - dm > 0
      end
      best = 0; slot = 0
      (1...d.num_in_play_area).each do |e|
        dmg = duel.card_damage_and_max_hp(d, e)[0]
        (best = dmg; slot = e) if dmg > best
      end
      slot == 0 ? nil : slot
    end

    #--------------------------------------------------------------------------
    # Shift (Venomoth, Active only): change to the Defending Pokemon's weakness
    #--------------------------------------------------------------------------
    def ai_power_shift(duel, c)
      return if c != 0
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      wr = COLOR_TO_WR[duel.play_area_card_color(d, 0)]
      weak = duel.arena_card_weakness(nd)
      return if weak == 0 || (weak & wr) != 0
      # ORIGINAL BUG: GetCardType on a Trainer (Doll/Fossil) reads past the
      # WR table; we treat it as matching nothing.
      has = lambda do |x|
        (0...x.num_in_play_area).any? { |e| (COLOR_TO_WR.fetch(x.card(x.play_area[e]).type, 0) & weak) != 0 }
      end
      return unless has.call(d) || has.call(nd)
      color = (0..7).find { |b| (weak << b) & 0x80 != 0 }
      ai_use_power(duel, c, { :Shift => color })
    end

    #--------------------------------------------------------------------------
    # Peek (Mankey): 3 in 50; own prize / player's hand / player's deck
    #--------------------------------------------------------------------------
    def ai_power_peek(duel, c)
      return unless rand(50) < 3
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      case rand(3)
      when 0
        @peeked_prizes = (d.prizes & (@peeked_prizes || 0xff)) & 0xff
        return if @peeked_prizes == 0
        bit = @peeked_prizes & -@peeked_prizes
        @peeked_prizes -= bit
        target = :prize
      when 1
        return if nd.hand.empty?
        target = :opp_hand
      else
        return if nd.not_in_deck >= DECK_SIZE - 1
        target = :opp_deck
      end
      ai_use_power(duel, c, { :Peek => target })
    end

    #--------------------------------------------------------------------------
    # Strange Behavior (Slowbro on the bench): pull the Active's counters
    #--------------------------------------------------------------------------
    def ai_power_strange_behavior(duel, c)
      return if c == 0
      d = duel.turn_duelist
      dmg = duel.card_damage_and_max_hp(d, 0)[0]
      return if dmg == 0
      room = d.slot_hp[c] - 10
      return if room == 0
      n = [room, dmg].min / 10
      ai_use_power(duel, c, { :StrangeBehavior => [PLAY_AREA_ARENA] * n })
    end

    #--------------------------------------------------------------------------
    # Curse (Gengar): move a counter onto the player's lowest-HP damaged card
    #--------------------------------------------------------------------------
    def ai_power_curse(duel, c)
      nd = duel.non_turn_duelist
      cnt = 0; low = 0xff; h = 0
      (0...nd.num_in_play_area).each do |e|
        next if duel.card_damage_and_max_hp(nd, e)[0] == 0
        cnt += 1
        (low = nd.slot_hp[e]; h = e) if nd.slot_hp[e] < low
      end
      return if cnt < 2
      start = low == 10 ? 0 : 1
      src = (start...nd.num_in_play_area).find { |e| e != h && duel.card_damage_and_max_hp(nd, e)[0] != 0 }
      return unless src
      ai_use_power(duel, c, { :CurseFrom => src, :CurseTo => h })
    end

    #--------------------------------------------------------------------------
    # HandleAICowardice (Tentacool with damage counters)
    #--------------------------------------------------------------------------
    def handle_cowardice(duel)
      return if duel.toxic_gas_active?
      return if ai_choose_randomly_not_to_do_action?
      d = duel.turn_duelist
      return if d.num_in_play_area == 1
      c = (d.status & CNF_SLP_PRZ) != 0 ? 1 : 0
      while c < d.num_in_play_area
        if d.card_id(d.play_area[c]) == :TENTACOOL && use_cowardice?(duel, c)
          return if d.num_in_play_area <= 1 || turn_over?(duel)
          c = 0
        else
          c += 1
        end
      end
    end

    def use_cowardice?(duel, c)
      d = duel.turn_duelist
      return false if duel.card_damage_and_max_hp(d, c)[0] == 0
      sw = nil
      if c == 0
        sw = decide_bench_pokemon_to_switch_to(duel) or return false
      end
      r = ai_use_power(duel, c, { :Cowardice => sw })
      ![:cant_use, :no_power, :cancelled].include?(r)
    end

    #--------------------------------------------------------------------------
    # HandleAIEnergyTrans (Venusaur Lv67). mode :retreat / :attack / :to_bench
    #--------------------------------------------------------------------------
    def grass_energy_cards_in(d, slots)
      (0...DECK_SIZE).select do |i|
        loc = d.card_locations[i]
        (loc & CARD_LOCATION_PLAY_AREA) != 0 && slots.include?(loc & 0x0f) && d.card_id(i) == :GRASS_ENERGY
      end
    end

    # highest play area slot holding Venusaur Lv67
    def venusaur_lv67_slot(d)
      (0...d.num_in_play_area).to_a.reverse.find { |e| d.card_id(d.play_area[e]) == :VENUSAUR_LV67 }
    end

    def handle_energy_trans(duel, mode)
      return if ai_choose_randomly_not_to_do_action?
      d = duel.turn_duelist
      return if d.num_in_play_area < 2
      return if duel.count_pokemon_with_active_pkmn_power(d, :VENUSAUR_LV67) == 0
      return if duel.toxic_gas_active?
      return energy_trans_to_bench(duel) if mode == :to_bench
      n = mode == :retreat ? energy_trans_needed_for_retreat(duel) : energy_trans_needed_for_attack(duel)
      return unless n && n > 0
      v = venusaur_lv67_slot(d) or return
      bench = (1...d.num_in_play_area).to_a
      cards = grass_energy_cards_in(d, bench).first(n)
      from = cards.map { |i| d.card_locations[i] & 0x0f }
      ai_use_power(duel, v, { :EnergyTransFrom => from, :EnergyTransTo => [PLAY_AREA_ARENA] * from.size })
    end

    def bench_grass_count(d); grass_energy_cards_in(d, (1...d.num_in_play_area).to_a).size; end

    # .CheckEnoughGrassEnergyCardsForAttack. ORIGINAL: when colorless energy is
    # needed, only that amount is checked (basic energy still needed ignored).
    def energy_trans_needed_for_attack(duel)
      d = duel.turn_duelist
      if d.card_id(d.arena) == :EXEGGUTOR
        g = bench_grass_count(d)
        return g == 0 ? nil : g
      end
      ok, b, c, id = energy_needed_for_attack(duel, PLAY_AREA_ARENA, 1)
      return nil if ok
      if c == 0
        return nil if b == 0 || id != :GRASS_ENERGY
        c = b
      end
      bench_grass_count(d) >= c ? c : nil
    end

    def energy_trans_needed_for_retreat(duel)
      d = duel.turn_duelist
      cost = duel.retreat_cost(d, PLAY_AREA_ARENA)
      have = d.energy_cards_in_slot(PLAY_AREA_ARENA).size
      return nil if have >= cost
      c = cost - have
      bench_grass_count(d) >= c ? c : nil
    end

    # AIEnergyTransTransferEnergyToBench: save Grass energy from a doomed Active
    def energy_trans_to_bench(duel)
      d = duel.turn_duelist
      return unless defending_ko_damage(duel, PLAY_AREA_ARENA)
      return if ai_process_but_dont_use_attack(duel)
      return if d.attached_energies(PLAY_AREA_ARENA)[0][GRASS] == 0
      flags = AI_ENERGY_FLAG_DONT_PLAY | AI_ENERGY_FLAG_SKIP_EVOLUTION | AI_ENERGY_FLAG_SKIP_ARENA_CARD
      return unless process_and_try_to_play_energy(duel, flags)
      v = venusaur_lv67_slot(d) or return
      target = nil
      from = lambda do |_opts|
        next nil if grass_energy_cards_in(d, [PLAY_AREA_ARENA]).empty?
        target = process_and_try_to_play_energy(duel, flags)
        target ? PLAY_AREA_ARENA : nil
      end
      ai_use_power(duel, v, { :EnergyTransFrom => from, :EnergyTransTo => ->(_o) { target } })
    end

    #--------------------------------------------------------------------------
    # HandleAIDamageSwap (Alakazam): Active Abra line / Mr Mime -> bench tank
    #--------------------------------------------------------------------------
    AI_DAMAGE_SWAP_TANKS = [:CHANSEY, :KANGASKHAN, :SNORLAX, :MR_MIME]

    # .CheckForDamageSwapTargetInBench: last energyless candidate with >= 20 HP,
    # else the last candidate with >= 20 HP; nil if none
    def damage_swap_target(d)
      any = none = nil
      (1...d.num_in_play_area).each do |c|
        next unless AI_DAMAGE_SWAP_TANKS.include?(d.card_id(d.play_area[c]))
        next if d.slot_hp[c] < 20
        any = c
        none = c if d.energy_cards_in_slot(c).empty?
      end
      none || any
    end

    def handle_damage_swap(duel)
      d = duel.turn_duelist
      return if d.num_in_play_area < 2
      return if ai_choose_randomly_not_to_do_action?
      return if duel.count_pokemon_with_active_pkmn_power(d, :ALAKAZAM) == 0
      return if duel.toxic_gas_active?
      return unless [:ALAKAZAM, :KADABRA, :ABRA, :MR_MIME].include?(d.card_id(d.arena))
      dmg = duel.card_damage_and_max_hp(d, PLAY_AREA_ARENA)[0]
      return if dmg == 0
      left = dmg / 10
      a = (1...d.num_in_play_area).find { |e| d.card_id(d.play_area[e]) == :ALAKAZAM } || PLAY_AREA_ARENA
      return unless damage_swap_target(d)
      tgt = nil
      from = lambda do |_o|
        next nil if left == 0
        tgt = damage_swap_target(d) or next nil
        left -= 1
        PLAY_AREA_ARENA
      end
      ai_use_power(duel, a, { :DamageSwapFrom => from, :DamageSwapTo => ->(_o) { tgt } })
    end

    #--------------------------------------------------------------------------
    # HandleAIGoGoRainDanceEnergy: attach every needed energy via Rain Dance
    #--------------------------------------------------------------------------
    def handle_go_go_rain_dance_energy(duel)
      return unless @deck_id == :GO_GO_RAIN_DANCE_DECK
      d = duel.turn_duelist
      return if duel.count_pokemon_with_active_pkmn_power(d, :BLASTOISE) == 0
      return if duel.toxic_gas_active?
      60.times { break unless process_and_try_to_play_energy(duel) }
    end

    #--------------------------------------------------------------------------
    # common.asm HandleAIAntiMewtwoDeckStrategy: false (no carry) = skip the
    # normal turn and go straight to attacking
    #--------------------------------------------------------------------------
    def anti_mewtwo_deck_strategy(duel)
      bc = @barrier_flag_counter.to_i
      return true if (bc & AI_MEWTWO_MILL) == 0
      if bc >= AI_MEWTWO_MILL + 2
        @barrier_flag_counter = 0
        return true
      end
      return true if count_set_up_bench_pokemon(duel) < 4
      process_hand_trainer_cards(duel, 5)
      false
    end

    #--------------------------------------------------------------------------
    # per-deck list pointers (085_AI_DeckLists.rb, generated from decks/*.asm)
    #--------------------------------------------------------------------------
    def ai_table; AI_TABLES[AI_DECK_TABLE[@deck_id]] || {}; end
    def energy_bonus_list;       ai_table[:energy_bonus] || {}; end
    def retreat_bonus_list;      ai_table[:retreat_bonus] || {}; end
    def play_from_hand_priority; ai_table[:play_from_hand_priority] || []; end
    def avoid_prize_list;        ai_table[:avoid_prize] || []; end
    def arena_priority_list;     ai_table[:arena_priority] || []; end
    def bench_priority_list;     ai_table[:bench_priority] || []; end
  end
end
