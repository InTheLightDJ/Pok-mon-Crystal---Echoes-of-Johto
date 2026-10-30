#==============================================================================
# Pokemon TCG - AI Trainer cards. Port of engine/duel/ai/trainer_cards.asm
# (_AIProcessHandTrainerCards + data/duel/ai_trainer_card_logic.asm) and the
# AIDecide_*/AIPlay_* routines.
#
# AIPlay_* routines in the original preset hTemp* variables and run the
# trainer's effects; here they preset @ai_choices (purpose => answer, or an
# Array consumed in order) that #effect_choice answers from, then play the
# card through the normal engine path.
#==============================================================================
module TCG
  AI_FLAG_MODIFIED_HAND     = 0x08
  AI_FLAG_USED_GUST_OF_WIND = 0x10

  # [phase, trainer card id, decide method, play method]
  AI_TRAINER_CARD_LOGIC = [
    [7,  :POTION,                 :ai_decide_potion_phase07,          :ai_play_potion],
    [10, :POTION,                 :ai_decide_potion_phase10,          :ai_play_potion],
    [8,  :SUPER_POTION,           :ai_decide_super_potion_phase08,    :ai_play_super_potion],
    [11, :SUPER_POTION,           :ai_decide_super_potion_phase11,    :ai_play_super_potion],
    [13, :DEFENDER,               :ai_decide_defender_phase13,        :ai_play_defender],
    [14, :DEFENDER,               :ai_decide_defender_phase14,        :ai_play_defender],
    [13, :PLUSPOWER,              :ai_decide_plus_power_phase13,      :ai_play_plus_power],
    [14, :PLUSPOWER,              :ai_decide_plus_power_phase14,      :ai_play_plus_power],
    [9,  :SWITCH,                 :ai_decide_switch,                  :ai_play_switch],
    [7,  :GUST_OF_WIND,           :ai_decide_gust_of_wind,            :ai_play_gust_of_wind],
    [10, :GUST_OF_WIND,           :ai_decide_gust_of_wind,            :ai_play_gust_of_wind],
    [4,  :BILL,                   :ai_decide_bill,                    :ai_play_bill],
    [5,  :ENERGY_REMOVAL,         :ai_decide_energy_removal,          :ai_play_energy_removal],
    [5,  :SUPER_ENERGY_REMOVAL,   :ai_decide_super_energy_removal,    :ai_play_super_energy_removal],
    [7,  :POKEMON_BREEDER,        :ai_decide_pokemon_breeder,         :ai_play_pokemon_breeder],
    [15, :PROFESSOR_OAK,          :ai_decide_professor_oak,           :ai_play_professor_oak],
    [10, :ENERGY_RETRIEVAL,       :ai_decide_energy_retrieval,        :ai_play_energy_retrieval],
    [11, :SUPER_ENERGY_RETRIEVAL, :ai_decide_super_energy_retrieval,  :ai_play_super_energy_retrieval],
    [6,  :POKEMON_CENTER,         :ai_decide_pokemon_center,          :ai_play_pokemon_center],
    [7,  :IMPOSTER_PROFESSOR_OAK, :ai_decide_imposter_professor_oak,  :ai_play_imposter_professor_oak],
    [12, :ENERGY_SEARCH,          :ai_decide_energy_search,           :ai_play_energy_search],
    [3,  :POKEDEX,                :ai_decide_pokedex,                 :ai_play_pokedex],
    [7,  :FULL_HEAL,              :ai_decide_full_heal,               :ai_play_full_heal],
    [10, :MR_FUJI,                :ai_decide_mr_fuji,                 :ai_play_mr_fuji],
    [10, :SCOOP_UP,               :ai_decide_scoop_up,                :ai_play_scoop_up],
    [2,  :MAINTENANCE,            :ai_decide_maintenance,             :ai_play_maintenance],
    [3,  :RECYCLE,                :ai_decide_recycle,                 :ai_play_recycle],
    [13, :LASS,                   :ai_decide_lass,                    :ai_play_lass],
    [4,  :ITEM_FINDER,            :ai_decide_item_finder,             :ai_play_item_finder],
    [1,  :IMAKUNI_CARD,           :ai_decide_imakuni,                 :ai_play_imakuni],
    [1,  :GAMBLER,                :ai_decide_gambler,                 :ai_play_gambler],
    [5,  :REVIVE,                 :ai_decide_revive,                  :ai_play_revive],
    [13, :POKEMON_FLUTE,          :ai_decide_pokemon_flute,           :ai_play_pokemon_flute],
    [5,  :CLEFAIRY_DOLL,          :ai_decide_doll_or_fossil,          :ai_play_doll_or_fossil],
    [5,  :MYSTERIOUS_FOSSIL,      :ai_decide_doll_or_fossil,          :ai_play_doll_or_fossil],
    [2,  :POKE_BALL,              :ai_decide_pokeball,                :ai_play_pokeball],
    [2,  :COMPUTER_SEARCH,        :ai_decide_computer_search,         :ai_play_computer_search],
    [2,  :POKEMON_TRADER,         :ai_decide_pokemon_trader,          :ai_play_pokemon_trader]
  ]

  # decks with a 50% chance (instead of 25%) to skip a Trainer
  AI_RANDOM_SKIP_50_DECKS = [:MUSCLES_FOR_BRAINS_DECK, :BLISTERING_POKEMON_DECK,
                             :WATERFRONT_POKEMON_DECK, :BOOM_BOOM_SELFDESTRUCT_DECK,
                             :KALEIDOSCOPE_DECK, :RESHUFFLE_DECK]

  # energy card id -> wAttachedEnergies slot it decrements in
  # CheckEnergyNeededForAttackAfterDiscard ("card id - 1": ORIGINAL BUG,
  # Grass/Fire and Water/Lightning slots are swapped)
  AI_DISCARD_ENERGY_SLOT = { :GRASS_ENERGY => 0, :FIRE_ENERGY => 1, :WATER_ENERGY => 2,
                             :LIGHTNING_ENERGY => 3, :FIGHTING_ENERGY => 4, :PSYCHIC_ENERGY => 5,
                             :DARKNESS_ENERGY => DARKNESS, :METAL_ENERGY => METAL }

  class AIController
    attr_accessor :ai_choices, :current_flags

    #--------------------------------------------------------------------------
    # _AIProcessHandTrainerCards
    #--------------------------------------------------------------------------
    def process_hand_trainer_cards(duel, phase)
      return if turn_over?(duel)
      d = duel.turn_duelist
      list = d.hand.dup
      i = 0
      while i < list.size
        card = list[i]
        i += 1
        next unless d.hand.include?(card)
        AI_TRAINER_CARD_LOGIC.each do |ph, id, decide, play|
          @current_flags = 0
          next unless ph == phase
          cid = d.card_id(card)
          next if cid == :SWITCH && (@previous_flags & AI_FLAG_USED_SWITCH) != 0
          next unless cid == id
            next if duel.cant_use_trainer_due_to_effect?(d)
          next if trainer_initial_effect_fails?(duel, card)
          next if ai_choose_randomly_not_to_do_action?
          @trainer_card  = card
          @trainer_param = send(decide, duel)
          next unless @trainer_param
          @trainer_param = 0 if @trainer_param == true
          send(play, duel, card)
          @ai_choices = nil
          @scene&.refresh(duel)
          return if turn_over?(duel)
          @previous_flags |= @current_flags
          if (@previous_flags & AI_FLAG_MODIFIED_HAND) != 0
            list = d.hand.dup
            i = 0
            @previous_flags &= ~AI_FLAG_MODIFIED_HAND
          end
          break
        end
      end
    end

    # LoadNonPokemonCardEffectCommands + EFFECTCMDTYPE_INITIAL_EFFECT_1
    def trainer_initial_effect_fails?(duel, card)
      d = duel.turn_duelist
      old = duel.atk
      duel.atk = AttackContext.new
      duel.atk.card_index  = card
      duel.atk.card_id     = d.card_id(card)
      duel.atk.effect_name = d.card(card).effect
      duel.silently { duel.try_execute_effect_command(EFFECT_INITIAL_EFFECT_1) }
    ensure
      duel.atk = old
    end

    # AIChooseRandomlyNotToDoAction (boss decks: never)
    def ai_choose_randomly_not_to_do_action?
      return false if boss_deck?
      AI_RANDOM_SKIP_50_DECKS.include?(@deck_id) ? rand(4) < 2 : rand(4) < 1
    end

    # answers effect prompts from what the AIPlay_* routine preset
    alias_method :tcg_ai_trainers_effect_choice, :effect_choice
    def effect_choice(duel, kind, purpose, options, cancellable)
      if @ai_choices && @ai_choices.key?(purpose)
        v = @ai_choices[purpose]
        return :none if v == :none        # AI explicitly takes nothing
        if v.is_a?(Proc)               # decided at prompt time (power loops)
          v = v.call(options)
          return v.nil? || options.include?(v) ? v : nil
        end
        if v.is_a?(Array)
          return nil if v.empty?   # preset list used up: stop selecting
          v = v.shift
        end
        return v if !v.nil? && options.include?(v)
      end
      tcg_ai_trainers_effect_choice(duel, kind, purpose, options, cancellable)
    end

    def ai_play_trainer(duel, card, choices)
      @ai_choices = choices
      duel.play_trainer_card(card)
    ensure
      @ai_choices = nil
    end

    #--------------------------------------------------------------------------
    # shared helpers (core.asm / common.asm)
    #--------------------------------------------------------------------------
    # CheckIfDefendingPokemonCanKnockOut: largest KO damage, or nil (no carry)
    def defending_ko_damage(duel, e)
      dmg = [0, 1].map do |ai|
        next 0 if duel.as_non_turn { attack_unusable?(duel, PLAY_AREA_ARENA, ai) }
        dm, = duel.ai_estimate_damage_from_defending(e, ai)
        (duel.turn_duelist.slot_hp[e] - dm) <= 0 ? dm : 0
      end
      return nil if dmg[0] == 0 && dmg[1] == 0
      [dmg[0], dmg[1]].max
    end

    # AIProcessButDontUseAttack: attack index wSelectedAttack ends on, or nil
    # (no carry). ORIGINAL BUG: a best score below $50 still returns carry
    # (the cp $50 carry survives RetrievePlayAreaAIScoreFromBackup2), with
    # wSelectedAttack left at SECOND_ATTACK.
    def ai_process_but_dont_use_attack(duel)
      return @plus_power_attack if (@previous_flags & AI_FLAG_USED_PLUSPOWER) != 0
      return nil if @barrier_flag_counter == AI_MEWTWO_MILL
      saved = [@score, @cannot_damage]
      s0 = get_ai_score_of_attack(duel, 0)
      s1 = get_ai_score_of_attack(duel, 1)
      chosen, best = s1 >= s0 ? [1, s1] : [0, s0]
      return 1 if best < 0x50
      chosen == 1 ? check_whether_to_switch_to_first_attack(duel, s0) : 0
    ensure
      @score, @cannot_damage = saved if saved
    end

    # AICheckIfAttackIsHighRecoil: true ("carry") if the attack is NOT high recoil
    def ai_attack_not_high_recoil?(duel)
      sel = ai_process_but_dont_use_attack(duel)
      return false if sel.nil?
      d = duel.turn_duelist
      atk = d.card(d.arena).attacks[sel]
      !(atk && atk.flag?(:HIGH_RECOIL))
    end

    # CheckLoadedAttackFlag after CheckIfSelectedAttackIsUnusable for ff9d
    def usable_attack_has_boost_if_taken_damage?(duel, ff9d)
      [0, 1].any? do |ai|
        next false if attack_unusable?(duel, ff9d, ai)
        d = duel.turn_duelist
        d.card(d.play_area[ff9d]).attacks[ai].flag?(:BOOST_IF_TAKEN_DAMAGE)
      end
    end

    # CheckIfEnergyIsUseful for Pokemon poke_id of type my_type
    def energy_useful_for?(d, idx, poke_id, my_type)
      id = d.card_id(idx)
      return true if id == :DOUBLE_COLORLESS_ENERGY || my_type == TYPE_ENERGY_DOUBLE_COLORLESS
      special = case poke_id
                when :EXEGGCUTE, :EXEGGUTOR, :PSYDUCK, :GOLDUCK then :PSYCHIC_ENERGY
                when :SURFING_PIKACHU_LV13, :SURFING_PIKACHU_ALT_LV13 then :WATER_ENERGY
                end
      return true if special && id == special
      return true if poke_id == :EEVEE && [:WATER_ENERGY, :FIRE_ENERGY, :LIGHTNING_ENERGY].include?(id)
      d.card(idx).type == my_type
    end

    # AIPickEnergyCardToDiscard: first not-useful energy, else the first; nil if none
    def ai_pick_energy_card_to_discard(d, e)
      list = d.energy_cards_in_slot(e)
      return nil if list.empty?
      pid = d.card_id(d.play_area[e])
      my_type = d.card(d.play_area[e]).type | TYPE_ENERGY
      list.find { |i| !energy_useful_for?(d, i, pid, my_type) } || list.first
    end

    # CheckEnergyNeededForAttackAfterDiscard: true if enough energy remains
    # for attack ai of slot e after AIPickEnergyCardToDiscard's card is gone
    def enough_energy_after_discard?(duel, e, ai)
      d = duel.turn_duelist
      atk = d.card(d.play_area[e]).attacks[ai]
      return false if atk.nil? || atk.pokemon_power?
      en, total = d.attached_energies(e)
      en = en.dup
      card = ai_pick_energy_card_to_discard(d, e)
      if card && d.card_id(card) == :DOUBLE_COLORLESS_ENERGY
        en[COLORLESS] = (en[COLORLESS] - 2) & 0xff
        total = (total - 2) & 0xff
      elsif card
        s = AI_DISCARD_ENERGY_SLOT[d.card_id(card)] || COLORLESS
        en[s] = (en[s] - 1) & 0xff
        total = (total - 1) & 0xff
      end
      # HandleEnergyBurn
      if e == PLAY_AREA_ARENA && d.card_id(d.arena) == :CHARIZARD &&
         !duel.incapable_of_using_pkmn_power?(d, PLAY_AREA_ARENA)
        en = Array.new(NUM_COLORS, 0)
        en[FIRE] = total
      end
      cost_sum = needed = 0
      COLORED_TYPES.each do |col|
        c = atk.cost[col]
        next if c == 0
        cost_sum += c
        needed += c - en[col] if en[col] < c
      end
      rem = total - (cost_sum - needed) - atk.cost[COLORLESS]
      rem >= 0 && needed == 0
    end

    def player_prizes(duel); duel.non_turn_duelist.count_prizes; end

    #--------------------------------------------------------------------------
    # Potion
    #--------------------------------------------------------------------------
    def ai_play_potion(duel, card)
      ai_play_trainer(duel, card, { :Potion => @trainer_param })
    end

    def ai_decide_potion_phase07(duel)
      return false if decide_whether_to_retreat(duel)
      return false if ai_attack_not_high_recoil?(duel)
      dm = defending_ko_damage(duel, PLAY_AREA_ARENA) or return false
      d = duel.turn_duelist
      heal = [duel.card_damage_and_max_hp(d, 0)[0], 20].min
      return false if d.slot_hp[0] + heal - dm <= 0
      0
    end

    def ai_decide_potion_phase10(duel)
      d = duel.turn_duelist
      start = 0
      dm = defending_ko_damage(duel, PLAY_AREA_ARENA)
      if dm
        heal = [duel.card_damage_and_max_hp(d, 0)[0], 20].min
        return false if d.slot_hp[0] + heal - dm > 0   # healing avoids the KO
        start = 1 unless player_prizes(duel) == 1
      end
      (start...d.num_in_play_area).each do |e|
        # hTempPlayAreaLocation_ff9d stays ARENA here (the original checks
        # the Active Pokemon's attacks for every slot)
        next if usable_attack_has_boost_if_taken_damage?(duel, PLAY_AREA_ARENA)
        next unless duel.card_damage_and_max_hp(d, e)[0] >= 20
        if e != 0
          return false if player_prizes(duel) != 1 && rand(10) < 3
          return e
        end
        return false if ai_attack_not_high_recoil?(duel)
        return e
      end
      false
    end

    #--------------------------------------------------------------------------
    # Super Potion
    #--------------------------------------------------------------------------
    def ai_play_super_potion(duel, card)
      d = duel.turn_duelist
      e = @trainer_param
      ai_play_trainer(duel, card, { :SuperPotion => e,
                                    :SuperPotionEnergy => ai_pick_energy_card_to_discard(d, e) })
    end

    def ai_decide_super_potion_phase08(duel)
      return false if decide_whether_to_retreat(duel)
      return false if ai_attack_not_high_recoil?(duel)
      d = duel.turn_duelist
      return false if d.attached_energies(0)[1] == 0
      dm = defending_ko_damage(duel, PLAY_AREA_ARENA) or return false
      heal = [duel.card_damage_and_max_hp(d, 0)[0], 40].min
      return false if d.slot_hp[0] + heal - dm <= 0
      0
    end

    def ai_decide_super_potion_phase11(duel)
      d = duel.turn_duelist
      start = 0
      dm = defending_ko_damage(duel, PLAY_AREA_ARENA)
      if dm
        heal = [duel.card_damage_and_max_hp(d, 0)[0], 40].min
        return false if d.slot_hp[0] + heal - dm > 0
        start = 1 unless player_prizes(duel) == 1
      end
      ff9d = PLAY_AREA_ARENA   # updated by .CheckIfDiscardingMakesAttacksUnusable
      (start...d.num_in_play_area).each do |e|
        next if d.attached_energies(e)[1] == 0
        next if usable_attack_has_boost_if_taken_damage?(duel, ff9d)
        ff9d = e
        next if discarding_makes_attacks_unusable?(duel, e)
        next unless duel.card_damage_and_max_hp(d, e)[0] >= 40
        if e != 0
          return false if player_prizes(duel) != 1 && rand(10) < 3
          return e
        end
        return false if ai_attack_not_high_recoil?(duel)
        return e
      end
      false
    end

    # .CheckIfDiscardingMakesAttacksUnusable
    def discarding_makes_attacks_unusable?(duel, e)
      [0, 1].any? do |ai|
        energy_needed_for_attack(duel, e, ai)[0] && !enough_energy_after_discard?(duel, e, ai)
      end
    end

    # shared opening of Defender/PlusPower phase 13: true ("no carry") if an
    # attack that KOs is usable, or its missing energy is in hand
    def ko_attack_available?(duel)
      ai = any_attack_knocks_out?(duel) or return false
      return true unless attack_unusable?(duel, PLAY_AREA_ARENA, ai)
      energy_needed_for_attack_in_hand?(duel, PLAY_AREA_ARENA, ai)
    end

    def est_from_defending(duel, ai); duel.ai_estimate_damage_from_defending(PLAY_AREA_ARENA, ai)[0]; end
    def defending_attack_unusable?(duel, ai); duel.as_non_turn { attack_unusable?(duel, PLAY_AREA_ARENA, ai) }; end

    #--------------------------------------------------------------------------
    # Defender (always attached to the Active Pokemon)
    #--------------------------------------------------------------------------
    def ai_play_defender(duel, card)
      ai_play_trainer(duel, card, { :Defender => PLAY_AREA_ARENA })
    end

    def ai_decide_defender_phase13(duel)
      return false if ko_attack_available?(duel)
      d = duel.turn_duelist
      # CheckIfAnyDefendingPokemonAttackDealsSameDamageAsHP (exactly 0 HP left)
      sel = [0, 1].find { |ai| d.slot_hp[0] - est_from_defending(duel, ai) == 0 } or return false
      return false if defending_attack_unusable?(duel, sel)
      dmg = est_from_defending(duel, sel)
      other = 1 - sel
      unless defending_attack_unusable?(duel, other)
        od = est_from_defending(duel, other)
        dmg = od if od >= dmg
      end
      d.slot_hp[0] - ((dmg - 20) & 0xff) > 0 ? 0 : false
    end

    # recoil of the attack about to be used (wLoadedAttack ~ @selected_attack)
    def ai_decide_defender_phase14(duel)
      d = duel.turn_duelist
      atk = d.card(d.arena).attacks[@selected_attack || 0] or return false
      return false unless atk.flag?(:HIGH_RECOIL) || atk.flag?(:LOW_RECOIL)
      r = atk.param.to_i
      wr = COLOR_TO_WR[duel.play_area_card_color(d, PLAY_AREA_ARENA)]
      r = (r << 1) & 0xff if (duel.arena_card_weakness(d) & wr) != 0
      if (duel.arena_card_resistance(d) & wr) != 0
        ra = duel.resistance_amount(d)
        return false if r < ra
        r -= ra
      end
      return false if r == 0
      d.slot_hp[0] - ((r - 20) & 0xff) > 0 ? 0 : false
    end

    #--------------------------------------------------------------------------
    # PlusPower
    #--------------------------------------------------------------------------
    def ai_play_plus_power(duel, card)
      @current_flags |= AI_FLAG_USED_PLUSPOWER
      @plus_power_attack = @trainer_param
      ai_play_trainer(duel, card, {})
    end

    # .MrMimeDamageCheck: true (carry) unless boosted damage >= 30 vs Mr. Mime
    def plus_power_mr_mime_ok?(duel, dmg)
      return true if ((dmg + 10) & 0xff) < 30
      duel.non_turn_duelist.card_id(duel.non_turn_duelist.arena) != :MR_MIME
    end

    def ai_decide_plus_power_phase13(duel)
      return false if ko_attack_available?(duel)
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      duel.atk ||= AttackContext.new
      duel.atk.temp_turn_card_id     = d.card_id(d.arena)
      duel.atk.temp_non_turn_card_id = nd.card_id(nd.arena)
      return false if duel.as_non_turn { duel.handle_no_damage_or_effect_substatus }
      [0, 1].each do |ai|
        next if attack_unusable?(duel, PLAY_AREA_ARENA, ai)
        dmg, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, ai)
        hp = nd.slot_hp[0]
        next if hp - dmg <= 0                       # already KOs
        next unless hp - ((dmg + 10) & 0xff) <= 0   # doesn't KO with the boost
        return plus_power_mr_mime_ok?(duel, dmg) ? ai : false
      end
      false
    end

    def ai_decide_plus_power_phase14(duel)
      ai = @selected_attack || 0
      return false if attack_unusable?(duel, PLAY_AREA_ARENA, ai)
      dmg, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, ai)
      return false if duel.non_turn_duelist.slot_hp[0] - dmg <= 0
      # .check_random
      return false if attack_unusable?(duel, PLAY_AREA_ARENA, ai)
      dmg, dmin, = duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, ai)
      return false if dmin < 10
      return false unless rand(10) < 3
      plus_power_mr_mime_ok?(duel, dmg) ? ai : false
    end

    #--------------------------------------------------------------------------
    # Switch
    #--------------------------------------------------------------------------
    def ai_play_switch(duel, card)
      @current_flags |= AI_FLAG_USED_SWITCH
      ai_play_trainer(duel, card, { :Switch => @trainer_param })
      @retreat_score = 0
    end

    def ai_decide_switch(duel)
      d = duel.turn_duelist
      cost = duel.retreat_cost(d, PLAY_AREA_ARENA)
      attached = d.energy_cards_in_slot(PLAY_AREA_ARENA).size
      switch = false
      # (wAIPlayEnergyCardForRetreat != 0 takes this path, despite the comment)
      if @play_energy_for_retreat && cost >= attached && cost - attached >= 2
        switch = true
      end
      switch ||= cost >= 3 || attached < cost
      return false unless switch
      decide_bench_pokemon_to_switch_to(duel) || false
    end

    #--------------------------------------------------------------------------
    # Gust of Wind
    #--------------------------------------------------------------------------
    def ai_play_gust_of_wind(duel, card)
      @current_flags |= AI_FLAG_USED_GUST_OF_WIND
      ai_play_trainer(duel, card, { :GustOfWind => @trainer_param })
    end

    # the player's Active card (deck index and HP only) temporarily
    # overwritten by bench slot e, as the original does
    def with_defending_as_bench(duel, e)
      nd = duel.non_turn_duelist
      old = [nd.play_area[0], nd.slot_hp[0]]
      nd.play_area[0] = nd.play_area[e]
      nd.slot_hp[0]   = nd.slot_hp[e]
      yield
    ensure
      nd.play_area[0], nd.slot_hp[0] = old
    end

    def ai_decide_gust_of_wind(duel)
      d  = duel.turn_duelist
      nd = duel.non_turn_duelist
      return false if nd.num_in_play_area < 2
      return false if (@previous_flags & AI_FLAG_USED_GUST_OF_WIND) != 0
      return false unless arena_can_use_non_residual_attack?(duel)
      return false if ko_attack_available?(duel)
      return false if [:MEW_LV23, :MEWTWO_LV53].include?(d.card_id(d.arena))
      e = gust_find_bench_card_to_knock_out(duel) and return e
      wr = COLOR_TO_WR[duel.play_area_card_color(d, PLAY_AREA_ARENA)]
      if gust_no_attack_deals_damage?(duel)
        # .check_bench_energy
        e = gust_find_bench_card_with_weakness(duel, wr) and return e
        (1...nd.num_in_play_area).each do |s|
          next if nd.attached_energies(s)[1] != 0
          return s if with_defending_as_bench(duel, s) { can_damage_defending?(duel, PLAY_AREA_ARENA) }
        end
        # .check_bench_hp: least HP the Active can damage (ties -> first)
        best_hp = 0xff; best = 0
        (1...nd.num_in_play_area).each do |s|
          next if best_hp <= nd.slot_hp[s]
          next unless with_defending_as_bench(duel, s) { can_damage_defending?(duel, PLAY_AREA_ARENA) }
          best_hp = nd.slot_hp[s]; best = s
        end
        return best == 0 ? false : best
      end
      # skip if the Defending Pokemon is already weak to the Active's color
      return false if (duel.arena_card_weakness(nd) & wr) != 0
      gust_find_bench_card_with_weakness(duel, wr) || false
    end

    # .FindBenchCardWithWeakness. ORIGINAL BUG: the damage check is made
    # against the current Defending Pokemon, not the benched card.
    def gust_find_bench_card_with_weakness(duel, wr)
      nd = duel.non_turn_duelist
      (1...nd.num_in_play_area).each do |s|
        next if (nd.card(nd.play_area[s]).weakness.to_i & wr) == 0
        return s if can_damage_defending?(duel, PLAY_AREA_ARENA)
      end
      nil
    end

    # .CheckIfNoAttackDealsDamage. ORIGINAL BUG: an attack with 0 base
    # damage ("ret z" with no carry), or a missing second attack, counts as
    # dealing damage.
    def gust_no_attack_deals_damage?(duel)
      d = duel.turn_duelist
      [0, 1].all? do |ai|
        atk = d.card(d.arena).attacks[ai]
        next false if atk.nil?
        next true if atk.pokemon_power?
        next false if atk.damage.to_i == 0
        duel.ai_estimate_damage_versus_defending(PLAY_AREA_ARENA, ai)[2] == 0
      end
    end

    # .FindBenchCardToKnockOut
    def gust_find_bench_card_to_knock_out(duel)
      nd = duel.non_turn_duelist
      (1...nd.num_in_play_area).each do |s|
        found = with_defending_as_bench(duel, s) do
          ai = any_attack_knocks_out?(duel)
          ai && (!attack_unusable?(duel, PLAY_AREA_ARENA, ai) ||
                 energy_needed_for_attack_in_hand?(duel, PLAY_AREA_ARENA, ai))
        end
        return s if found
      end
      nil
    end

    #--------------------------------------------------------------------------
    # Bill: more than 9 cards left in the deck
    #--------------------------------------------------------------------------
    def ai_play_bill(duel, card); ai_play_trainer(duel, card, {}); end
    def ai_decide_bill(duel); duel.turn_duelist.cards_in_deck > 9; end

    #--------------------------------------------------------------------------
    # Energy Removal / Super Energy Removal
    # (the player-side checks run with the turn swapped, like the original)
    #--------------------------------------------------------------------------
    # PickAttachedEnergyCardToRemove: Double Colorless, then useful, then first
    def pick_attached_energy_card_to_remove(d, e)
      list = d.energy_cards_in_slot(e)
      return nil if list.empty?
      pid = d.card_id(d.play_area[e])
      my_type = d.card(d.play_area[e]).type | TYPE_ENERGY
      list.find { |i| d.card_id(i) == :DOUBLE_COLORLESS_ENERGY } ||
        list.find { |i| energy_useful_for?(d, i, pid, my_type) } || list.first
    end

    # PickTwoAttachedEnergyCards: [first, second] or nil if < 2 energy cards.
    # ORIGINAL BUG: a lone Double Colorless is also found again as the
    # "useful" second card; the effect then discards it only once.
    def pick_two_attached_energy_cards(d, e)
      list = d.energy_cards_in_slot(e)
      return nil if list.size < 2
      pid = d.card_id(d.play_area[e])
      my_type = d.card(d.play_area[e]).type | TYPE_ENERGY
      first = second = nil
      list.each do |i|
        next unless d.card_id(i) == :DOUBLE_COLORLESS_ENERGY
        first ? (second = i; break) : first = i
      end
      unless second
        list.each do |i|
          next unless energy_useful_for?(d, i, pid, my_type)
          next first = i if first.nil?
          second = i
          break
        end
      end
      unless second
        if first.nil?
          first, second = list[0], list[1]
        else
          second = list.find { |i| i != first }
        end
      end
      [first, second]
    end

    # turn-holder slot has energy enough for attack 1, or for attack 2
    # with fewer than max_surplus surplus (Energy Removal: exactly 0)
    def enough_energy_to_attack_for_removal?(duel, e, max_surplus)
      return true if energy_needed_for_attack(duel, e, 0)[0]
      return false unless energy_needed_for_attack(duel, e, 1)[0]
      s = surplus_energy_for_attack(duel, e, 1)
      s = 0 unless s.is_a?(Integer)
      s < max_surplus
    end

    # .FindHighestDamagingAttack over the turn holder's bench (strictly higher wins)
    def highest_damaging_bench_slot(duel)
      d = duel.turn_duelist
      best = 0; slot = 0
      (1...d.num_in_play_area).each do |e|
        next unless yield(e)
        [0, 1].each do |ai|
          next if d.card(d.play_area[e]).attacks[ai].nil?
          dmg, = duel.ai_estimate_damage_versus_defending(e, ai)
          (best = dmg; slot = e) if dmg != 0 && dmg > best
        end
      end
      slot
    end

    def ai_play_energy_removal(duel, card)
      ai_play_trainer(duel, card, { :EnergyRemoval => [@trainer_param, @energy_removal_card] })
    end

    def ai_decide_energy_removal(duel)
      start = ko_attack_available?(duel) ? 1 : 0
      duel.as_non_turn do
        d = duel.turn_duelist
        target = (start...d.num_in_play_area).find do |e|
          d.attached_energies(e)[1] != 0 && enough_energy_to_attack_for_removal?(duel, e, 1)
        end
        # .default: ORIGINAL BUG — checks the slot past the last Pokemon
        # (never has energy), so the "Active card" fallback never fires
        target ||= begin
          s = highest_damaging_bench_slot(duel) { |e| d.attached_energies(e)[1] != 0 }
          s == 0 ? nil : s
        end
        next false unless target
        @energy_removal_card = pick_attached_energy_card_to_remove(d, target)
        target
      end
    end

    def ai_play_super_energy_removal(duel, card)
      ai_play_trainer(duel, card, {
        :SuperEnergyRemovalOwn => [@trainer_param, @super_removal_own],
        :SuperEnergyRemovalOpp => @super_removal_opp
      })
    end

    def ai_decide_super_energy_removal(duel)
      d = duel.turn_duelist
      # own Benched Pokemon (never the Active) with a basic energy card
      own = (1...d.num_in_play_area).find do |e|
        d.energy_cards_in_slot(e).any? { |i| d.card_id(i) != :DOUBLE_COLORLESS_ENERGY }
      end
      return false unless own
      start = ko_attack_available?(duel) ? 1 : 0
      opp = duel.as_non_turn do
        nd = duel.turn_duelist
        ok = lambda do |e|
          next false if nd.energy_cards_in_slot(e).size < 2
          en, = nd.attached_energies(e)
          next false if COLORED_TYPES.sum { |col| en[col] } + (en[COLORLESS] >> 1) < 2
          enough_energy_to_attack_for_removal?(duel, e, 2)
        end
        t = (start...nd.num_in_play_area).find { |e| ok.call(e) }
        if t && t != 0
          t = highest_damaging_bench_slot(duel) { |e| ok.call(e) }
          t = nil if t == 0
        end
        next nil unless t
        a, b = pick_two_attached_energy_cards(nd, t)
        [t, a] + (b == a ? [] : [b])
      end
      return false unless opp
      @super_removal_opp = opp
      @super_removal_own = ai_pick_energy_card_to_discard(d, own)
      own
    end

    #--------------------------------------------------------------------------
    # Pokemon Breeder
    #--------------------------------------------------------------------------
    AI_BREEDER_PREFERRED = [:VENUSAUR_LV64, :VENUSAUR_LV67, :BLASTOISE, :VILEPLUME, :ALAKAZAM, :GENGAR]

    def ai_play_pokemon_breeder(duel, card)
      ai_play_trainer(duel, card, { :PokemonBreederCard => @breeder_card,
                                    :PokemonBreederSlot => @trainer_param })
    end

    # .CalculateFitness: high nibble = HP counters left (nibble-swapped),
    # low nibble = energy cards attached (capped at 15)
    def breeder_fitness(d, e)
      c = (d.slot_hp[e] / 10) & 0xff
      hi = ((c << 4) | (c >> 4)) & 0xff
      hi | [d.attached_energies(e)[1], 15].min
    end

    def ai_decide_pokemon_breeder(duel)
      return false if duel.prehistoric_power_active?
      d = duel.turn_duelist
      # 1) preferred Stage 2 cards
      scores = Array.new(7, 0); stage2 = {}
      found = 0
      d.hand.each do |i|
        next unless AI_BREEDER_PREFERRED.include?(d.card_id(i))
        (0...d.num_in_play_area).each do |e|
          next unless d.can_evolve_basic_to_stage2?(i, e)
          scores[e] = breeder_fitness(d, e); stage2[e] = i; found += 1
        end
      end
      if found > 0
        best = 0; slot = nil
        (0...d.num_in_play_area).each { |e| (best = scores[e]; slot = e) if scores[e] > best }
        return false if slot.nil?
        @breeder_card = stage2[slot]
        return slot
      end
      # 2) any Stage 2, needing >= 2 energy cards (Dragonite Lv41 special case)
      scores = Array.new(7, 0)
      d.hand.each do |i|
        (0...d.num_in_play_area).each do |e|
          next unless d.can_evolve_basic_to_stage2?(i, e)
          next if breeder_skip_dragonite?(duel, d, i, e)
          scores[e] = breeder_fitness(d, e); stage2[e] = i; found += 1
        end
      end
      return false if found == 0
      best = 0; slot = nil
      (0...d.num_in_play_area).each do |e|
        next unless scores[e] > best && (scores[e] & 0x0f) >= 2
        best = scores[e]; slot = e
      end
      return false if slot.nil?
      @breeder_card = stage2[slot]
      slot
    end

    # .HandleDragoniteLv41Evolution: true (carry) = don't evolve this one.
    # ORIGINAL BUG: the Active check compares HP damage (not counters) to 5.
    def breeder_skip_dragonite?(duel, d, i, e)
      return false unless d.card_id(i) == :DRAGONITE_LV41
      if e != 0
        total = (0...d.num_in_play_area).sum { |s| duel.card_damage_and_max_hp(d, s)[0] / 10 }
        return total <= 7
      end
      return true if duel.card_damage_and_max_hp(d, 0)[0] < 5
      d.energy_cards_in_slot(0).size < 3
    end

    #--------------------------------------------------------------------------
    # Professor Oak
    #--------------------------------------------------------------------------
    def ai_play_professor_oak(duel, card)
      @current_flags |= AI_FLAG_USED_PROFESSOR_OAK | AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, {})
    end

    def ai_decide_professor_oak(duel)
      d = duel.turn_duelist
      return false if d.cards_in_deck <= 6
      case @deck_id
      when :LEGENDARY_ARTICUNO_DECK then return oak_legendary_articuno?(duel, d)
      when :EXCAVATION_DECK
        return false if d.not_in_deck >= 46
        fossil = d.hand.any? { |i| d.card_id(i) == :MYSTERIOUS_FOSSIL } ||
                 (0...d.num_in_play_area).any? { |e| d.card_id(d.play_area[e]) == :MYSTERIOUS_FOSSIL }
        return oak_general_score(duel, d, fossil ? 0x1e : 0x50) >= 60
      when :WONDERS_OF_SCIENCE_DECK
        return false if d.hand.any? { |i| [:GRIMER, :MUK].include?(d.card_id(i)) }
      end
      return false if d.cards_in_deck <= 14
      oak_general_score(duel, d, 30) >= 60
    end

    def oak_general_score(duel, d, score)
      n = d.hand.size
      if n < 4 then score += 50
      elsif n >= 9 then score -= 30
      end
      score += 40 if d.hand.none? { |i| d.card(i).energy? }
      if !duel.toxic_gas_active? && duel.count_pokemon_with_active_pkmn_power(d, :BLASTOISE) > 0 &&
         d.hand.none? { |i| d.card_id(i) == :WATER_ENERGY }
        score += 10
      end
      # .check_hand: ORIGINAL BUG ("jr c" should be "jr nc") makes it test
      # only non-Pokemon cards, whose "stage" byte is the high byte of their
      # effect-command pointer (never 0), so the Basic bonus never applies.
      any_evo = in_hand = false
      (0...d.num_in_play_area).each do |e|
        (0...d.deck_size).each do |i|
          next unless d.check_if_can_evolve_into(i, e) == :ok
          any_evo = true
          if d.card_locations[i] == CARD_LOCATION_HAND
            in_hand = true
            break
          end
        end
      end
      score += 10 if any_evo && !in_hand
      score & 0xff
    end

    def oak_legendary_articuno?(duel, d)
      if d.num_in_play_area < 3
        evo = (0...d.num_in_play_area).any? do |e|
          with_arena_as(d, d.play_area[e]) { d.hand.any? { |i| d.check_if_can_evolve_into(i, 0) == :ok } }
        end
        return true unless evo
      end
      # CountOppEnergyCardsInHand. ORIGINAL BUG: with no energy in hand it
      # returns $ff, so Oak is never played then.
      en = d.hand.count { |i| d.card(i).energy? }
      en = 0xff if en == 0
      return false if en >= 4
      list = d.hand.dup
      2.times { j = list.index { |i| d.card_id(i) == :PROFESSOR_OAK }; list.delete_at(j) if j }
      list.none? { |i| card_can_be_played?(duel, d, i) }
    end

    # CheckIfCardCanBePlayed (true = can be played, i.e. no carry)
    def card_can_be_played?(duel, d, i)
      c = d.card(i)
      if c.energy?
        !duel.already_played_energy
      elsif c.trainer?
        !duel.cant_use_trainer_due_to_effect?(d) && !trainer_initial_effect_fails?(duel, i)
      elsif c.basic?
        d.num_in_play_area < MAX_PLAY_AREA_POKEMON
      else
        return false if duel.prehistoric_power_active?
        (0...d.num_in_play_area).any? { |e| d.check_if_can_evolve_into(i, e) == :ok }
      end
    end

    #--------------------------------------------------------------------------
    # Energy Retrieval / Super Energy Retrieval
    #--------------------------------------------------------------------------
    # FindDuplicateCards: last Pokemon duplicate found, else last non-Pokemon
    # duplicate (the later card of each pair); nil if none
    def find_duplicate_cards(d, list)
      pkmn = other = nil
      list.each_with_index do |i, n|
        c = list[(n + 1)..].find { |j| d.card_id(j) == d.card_id(i) } or next
        d.card(c).type < TYPE_ENERGY ? pkmn = c : other = c
      end
      pkmn || other
    end

    # FindBasicEnergyCardsInLocation (deck index order)
    def basic_energy_cards_in(d, location)
      (0...d.deck_size).select { |i| d.card_locations[i] == location && d.card(i).basic_energy? }
    end

    # useful energies first (one per play area slot, in slot order), then the rest
    def pick_energies_to_retrieve(d, list, max)
      list = list.dup
      picked = []
      (0...d.num_in_play_area).each do |e|
        pid = d.card_id(d.play_area[e])
        my_type = d.card(d.play_area[e]).type | TYPE_ENERGY
        i = list.find { |j| energy_useful_for?(d, j, pid, my_type) } or next
        picked << i
        return picked if picked.size == max
        list.delete(i)
      end
      list.each do |i|
        picked << i
        return picked if picked.size == max
      end
      picked
    end

    def retrieval_allowed?(duel, d)
      return false if d.hand.any? { |i| d.card(i).energy? }   # only with no energy in hand
      if @deck_id == :GO_GO_RAIN_DANCE_DECK && !duel.toxic_gas_active?
        return false if duel.count_pokemon_with_active_pkmn_power(d, :BLASTOISE) == 0
      end
      true
    end

    def ai_play_energy_retrieval(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, { :EnergyRetrievalDiscard => @trainer_param,
                                    :EnergyRetrieval => @retrieve_energies.dup })
    end

    def ai_decide_energy_retrieval(duel)
      d = duel.turn_duelist
      return false unless retrieval_allowed?(duel, d)
      dup = find_duplicate_cards(d, d.hand) or return false
      list = basic_energy_cards_in(d, CARD_LOCATION_DISCARD_PILE)
      return false if list.empty?
      @retrieve_energies = pick_energies_to_retrieve(d, list, 2)
      dup
    end

    def ai_play_super_energy_retrieval(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, { :DiscardHand => [@trainer_param, @super_retrieval_dup2],
                                    :SuperEnergyRetrieval => @retrieve_energies.dup })
    end

    def ai_decide_super_energy_retrieval(duel)
      d = duel.turn_duelist
      return false unless retrieval_allowed?(duel, d)
      hand = d.hand.dup
      dup1 = find_duplicate_cards(d, hand) or return false
      hand.delete(dup1)
      dup2 = find_duplicate_cards(d, hand) or return false
      list = basic_energy_cards_in(d, CARD_LOCATION_DISCARD_PILE)
      return false if list.empty?
      @retrieve_energies = pick_energies_to_retrieve(d, list, 4)
      @super_retrieval_dup2 = dup2
      dup1
    end

    #--------------------------------------------------------------------------
    # Pokemon Center: damage counters > 60% of max HP counters, and
    # damage counters / 2 >= energy attached (all 8-bit like the original)
    #--------------------------------------------------------------------------
    def ai_play_pokemon_center(duel, card); ai_play_trainer(duel, card, {}); end

    def ai_decide_pokemon_center(duel)
      return false if ko_attack_available?(duel)
      d = duel.turn_duelist
      hp = dmg = en = 0
      (0...d.num_in_play_area).each do |e|
        # wLoadedCard1HP (APPROXIMATION: for Doll/Fossil this byte is part
        # of the effect pointer in the original; we use their 10 HP)
        c = d.card(d.play_area[e])
        hp  = (hp + (c.trainer? ? 10 : c.hp.to_i) / 10) & 0xff
        dmg = (dmg + duel.card_damage_and_max_hp(d, e)[0] / 10) & 0xff
        en += d.attached_energies(e)[1]
        return false if en > 0xff
      end
      return false if (dmg >> 1) < en
      return false if (hp * 6) / 10 >= dmg
      0
    end

    #--------------------------------------------------------------------------
    # Imposter Professor Oak (looks at the player's deck and hand)
    #--------------------------------------------------------------------------
    def ai_play_imposter_professor_oak(duel, card); ai_play_trainer(duel, card, {}); end

    def ai_decide_imposter_professor_oak(duel)
      nd = duel.non_turn_duelist
      nd.cards_in_deck > 14 ? nd.hand.size >= 9 : nd.hand.size < 6
    end

    #--------------------------------------------------------------------------
    # Energy Search
    #--------------------------------------------------------------------------
    def ai_play_energy_search(duel, card)
      ai_play_trainer(duel, card, { :EnergySearch => @trainer_param })
    end

    # .CheckForUsefulEnergyCards (types: only Pokemon of these energy types)
    def first_useful_energy(d, list, types = nil)
      (0...d.num_in_play_area).each do |e|
        my_type = d.card(d.play_area[e]).type | TYPE_ENERGY
        next if types && !types.include?(my_type)
        pid = d.card_id(d.play_area[e])
        i = list.find { |j| energy_useful_for?(d, j, pid, my_type) }
        return i if i
      end
      nil
    end

    def ai_decide_energy_search(duel)
      d = duel.turn_duelist
      hand_en = d.hand.select { |i| d.card(i).energy? }
      return false if !hand_en.empty? && first_useful_energy(d, hand_en)
      list = basic_energy_cards_in(d, CARD_LOCATION_DECK)
      return false if list.empty?
      case @deck_id
      when :HEATED_BATTLE_DECK, :WONDERS_OF_SCIENCE_DECK
        # ORIGINAL BUG: Wonders of Science should check Grass, uses Fire/Lightning
        first_useful_energy(d, list, [TYPE_ENERGY | FIRE, TYPE_ENERGY | LIGHTNING]) || false
      else
        first_useful_energy(d, list) || list.first
      end
    end

    #--------------------------------------------------------------------------
    # Pokedex: counter >= 6, deck > 4, 30% chance; order energy, Pokemon,
    # Trainers. (ORIGINAL BUG: "jp" instead of "jp nz" makes every deck use
    # this order; the Pokemon-first PickPokedexCards_Unreferenced is dead.)
    #--------------------------------------------------------------------------
    def ai_play_pokedex(duel, card)
      ai_play_trainer(duel, card, { :Pokedex => @pokedex_order.dup })
    end

    def ai_decide_pokedex(duel)
      d = duel.turn_duelist
      return false if @pokedex_counter < 6
      return false if d.cards_in_deck <= 4
      return false unless rand(10) < 3
      @pokedex_counter = 0
      top = d.deck_list.first(5)
      @pokedex_order = top.select { |i| (d.card(i).type & TYPE_ENERGY) != 0 && d.card(i).type != TYPE_TRAINER } +
                       top.select { |i| d.card(i).type < TYPE_ENERGY } +
                       top.select { |i| d.card(i).type == TYPE_TRAINER }
      0
    end

    #--------------------------------------------------------------------------
    # Full Heal
    #--------------------------------------------------------------------------
    def ai_play_full_heal(duel, card); ai_play_trainer(duel, card, {}); end

    def ai_decide_full_heal(duel)
      d = duel.turn_duelist
      st = d.status
      return false if st == 0
      case st & CNF_SLP_PRZ
      when ASLEEP
        # ORIGINAL BUG: looks in its own Play Area (should be the player's)
        return 0 if (0...d.num_in_play_area).any? { |e| [:GASTLY_LV8, :GASTLY_LV17, :HAUNTER_LV22].include?(d.card_id(d.play_area[e])) }
        full_heal_paralyzed(duel)
      when PARALYZED then full_heal_paralyzed(duel)
      when CONFUSED
        return false if scoop_up_would_be_played?(duel)
        return false unless can_damage_defending?(duel, PLAY_AREA_ARENA)
        @play_energy_for_retreat ? 0 : false
      else 0   # poisoned
      end
    end

    def scoop_up_would_be_played?(duel)
      d = duel.turn_duelist
      d.hand.any? { |i| d.card_id(i) == :SCOOP_UP } && ai_decide_scoop_up(duel)
    end

    # ORIGINAL BUG: CheckIfCanDamageDefendingPokemon fails while paralyzed
    def full_heal_paralyzed(duel)
      return false if scoop_up_would_be_played?(duel)
      return false unless can_damage_defending?(duel, PLAY_AREA_ARENA)
      return 0 if @play_energy_for_retreat
      decide_whether_to_retreat(duel) ? false : 0
    end

    #--------------------------------------------------------------------------
    # Mr. Fuji: benched Pokemon with max HP / damage counters < 20 (lowest)
    #--------------------------------------------------------------------------
    def ai_play_mr_fuji(duel, card)
      ai_play_trainer(duel, card, { :MrFuji => @trainer_param })
    end

    def max_hp_byte(c); c.trainer? ? 10 : c.hp.to_i; end   # APPROXIMATION for Doll/Fossil

    def ai_decide_mr_fuji(duel)
      d = duel.turn_duelist
      return false if d.num_in_play_area < 2
      best = 0xff; slot = nil
      (1...d.num_in_play_area).each do |e|
        cnt = duel.card_damage_and_max_hp(d, e)[0] / 10
        next if cnt == 0
        q = max_hp_byte(d.card(d.play_area[e])) / cnt
        next if q >= 20 || q >= best
        best = q; slot = e
      end
      slot || false
    end

    #--------------------------------------------------------------------------
    # Scoop Up
    #--------------------------------------------------------------------------
    def ai_play_scoop_up(duel, card)
      ai_play_trainer(duel, card, { :ScoopUp => @trainer_param, :ScoopUpReplace => @scoop_up_switch })
    end

    def ai_decide_scoop_up(duel)
      d = duel.turn_duelist
      return false if d.num_in_play_area < 2
      case @deck_id
      when :LEGENDARY_ARTICUNO_DECK
        return false if d.num_in_play_area < 3
        e = scoop_find_bench(d, :ARTICUNO_LV37) and return scoop_articuno_bench(duel, d, e)
        return false unless [:ARTICUNO_LV37, :CHANSEY].include?(d.card_id(d.arena))
        return false if ko_attack_available?(duel)
        return false unless defending_ko_damage(duel, PLAY_AREA_ARENA)
        return scoop_decide_switch(duel)
      when :LEGENDARY_RONALD_DECK
        return false if d.num_in_play_area < 3
        e = scoop_find_bench(d, :ARTICUNO_LV37) and return scoop_articuno_bench(duel, d, e)
        e = scoop_find_bench(d, :ZAPDOS_LV68) || scoop_find_bench(d, :MOLTRES_LV37)
        return e ? scoop_bench_no_energy(d, e) : false
      end
      return false if ko_attack_available?(duel)
      st = d.status & CNF_SLP_PRZ
      unless st == PARALYZED || st == ASLEEP
        return false if d.energy_cards_in_slot(0).size >= duel.retreat_cost(d, 0)
      end
      max_cnt = max_hp_byte(d.card(d.arena)) / 10
      dmg = duel.card_damage_and_max_hp(d, 0)[0]
      return false if dmg == 0 || max_cnt == 0
      return false if dmg / max_cnt < 7
      scoop_decide_switch(duel)
    end

    def scoop_find_bench(d, id)
      (1...d.num_in_play_area).find { |e| d.card_id(d.play_area[e]) == id }
    end

    def scoop_decide_switch(duel)
      s = decide_bench_pokemon_to_switch_to(duel) or return false
      @scoop_up_switch = s
      0
    end

    # ORIGINAL: Snorlax check only on this path; Muk never checked
    def scoop_articuno_bench(duel, d, e)
      nd = duel.non_turn_duelist
      return false if nd.card_id(nd.arena) == :SNORLAX
      scoop_bench_no_energy(d, e)
    end

    def scoop_bench_no_energy(d, e)
      return false unless d.energy_cards_in_slot(e).empty?
      @scoop_up_switch = nil
      e
    end

    #--------------------------------------------------------------------------
    # Maintenance: two duplicate cards (Imakuni?: 20%, two random cards)
    #--------------------------------------------------------------------------
    def ai_play_maintenance(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, { :Maintenance => @two_hand_cards.dup })
    end

    # hand minus excluded cards -> [dup1, dup2] or nil
    def two_duplicate_hand_cards(d, list)
      list = list.dup
      a = find_duplicate_cards(d, list) or return nil
      list.delete(a)
      b = find_duplicate_cards(d, list) or return nil
      [a, b]
    end

    def ai_decide_maintenance(duel)
      d = duel.turn_duelist
      if @deck_id == :IMAKUNI_DECK
        return false unless rand(10) < 2
        return false if d.hand.size < 3
        picks = (d.hand.shuffle - [@trainer_card]).first(2)
        return false if picks.size < 2
        @two_hand_cards = picks
        return 0
      end
      return false if d.hand.size < 4
      @two_hand_cards = two_duplicate_hand_cards(d, d.hand - [@trainer_card]) or return false
      0
    end

    #--------------------------------------------------------------------------
    # Recycle (Fire Charge priorities by default, Ghost deck its own)
    #--------------------------------------------------------------------------
    AI_RECYCLE_PRIORITY = {
      :GHOST_DECK => [:GASTLY_LV17, :GASTLY_LV8, :ZUBAT, :DITTO, :MEOWTH_LV15],
      :default    => [:DOUBLE_COLORLESS_ENERGY, :CHANSEY, :TAUROS, :JIGGLYPUFF_LV12]
    }

    def ai_play_recycle(duel, card)
      ai_play_trainer(duel, card, { :Recycle => @trainer_param })
    end

    def ai_decide_recycle(duel)
      d = duel.turn_duelist
      list = d.discard_pile.reverse
      return false if list.empty?
      prio = AI_RECYCLE_PRIORITY[@deck_id == :GHOST_DECK ? :GHOST_DECK : :default]
      # each slot keeps the LAST matching card in list order
      found = prio.map { |id| list.reverse.find { |i| d.card_id(i) == id } }
      found.compact.first || false
    end

    #--------------------------------------------------------------------------
    # Lass: player hand >= 7 and no other Trainer in own hand
    #--------------------------------------------------------------------------
    def ai_play_lass(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, {})
    end

    def ai_decide_lass(duel)
      d = duel.turn_duelist
      return false if duel.non_turn_duelist.hand.size < 7
      d.hand.none? { |i| d.card_id(i) != :LASS && d.card(i).type == TYPE_TRAINER } ? 0 : false
    end

    #--------------------------------------------------------------------------
    # Item Finder: recover Energy Removal, discarding two duplicates
    # (never Mr. Mime / Pokemon Trader)
    #--------------------------------------------------------------------------
    def ai_play_item_finder(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, { :DiscardHand => @two_hand_cards.dup, :ItemFinder => @trainer_param })
    end

    def ai_decide_item_finder(duel)
      d = duel.turn_duelist
      target = d.discard_pile.reverse.find { |i| d.card_id(i) == :ENERGY_REMOVAL } or return false
      list = d.hand.reject { |i| [:MR_MIME, :POKEMON_TRADER].include?(d.card_id(i)) } - [@trainer_card]
      @two_hand_cards = two_duplicate_hand_cards(d, list) or return false
      target
    end

    #--------------------------------------------------------------------------
    # Imakuni?: unless confused
    #--------------------------------------------------------------------------
    def ai_play_imakuni(duel, card); ai_play_trainer(duel, card, {}); end
    def ai_decide_imakuni(duel)
      (duel.turn_duelist.status & CNF_SLP_PRZ) == CONFUSED ? false : 0
    end

    #--------------------------------------------------------------------------
    # Gambler: vs a Mewtwo Lv53 mill deck when deck <= 4 (Imakuni?: 20%).
    # Non-Imakuni decks cheat the RNG so the coin is always heads.
    #--------------------------------------------------------------------------
    def ai_play_gambler(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      duel.forced_coin = HEADS unless @deck_id == :IMAKUNI_DECK
      ai_play_trainer(duel, card, {})
    ensure
      duel.forced_coin = nil
    end

    def ai_decide_gambler(duel)
      return (rand(10) < 2 ? 0 : false) if @deck_id == :IMAKUNI_DECK
      return false if (@barrier_flag_counter.to_i & AI_MEWTWO_MILL) == 0
      duel.turn_duelist.cards_in_deck <= 4 ? 0 : false
    end

    #--------------------------------------------------------------------------
    # Revive (Muscles for Brains logic). ORIGINAL BUG: swapped lines make
    # Tauros count and Kangaskhan never.
    #--------------------------------------------------------------------------
    def ai_play_revive(duel, card)
      ai_play_trainer(duel, card, { :Revive => @trainer_param })
    end

    def ai_decide_revive(duel)
      d = duel.turn_duelist
      list = d.discard_pile.reverse
      return false if list.empty? || d.num_in_play_area >= 4
      list.find { |i| [:HITMONCHAN, :HITMONLEE, :TAUROS].include?(d.card_id(i)) } || false
    end

    #--------------------------------------------------------------------------
    # Pokemon Flute: player's lowest-HP Basic in their discard if < 50 HP
    #--------------------------------------------------------------------------
    def ai_play_pokemon_flute(duel, card)
      ai_play_trainer(duel, card, { :PokemonFlute => @trainer_param })
    end

    def ai_decide_pokemon_flute(duel)
      nd = duel.non_turn_duelist
      list = nd.discard_pile.reverse
      return false if list.empty? || nd.num_in_play_area >= MAX_PLAY_AREA_POKEMON
      basics = list.select { |i| nd.card(i).type < TYPE_ENERGY && nd.card(i).basic? }
      if @deck_id == :IMAKUNI_DECK
        return false unless rand(10) < 2
        return basics.first || false
      end
      best = 0xff; pick = nil
      basics.each { |i| (best = nd.card(i).hp.to_i; pick = i) if nd.card(i).hp.to_i < best }
      best < 50 ? pick : false
    end

    #--------------------------------------------------------------------------
    # Clefairy Doll / Mysterious Fossil: room on the bench, and fewer than 4
    # Pokemon in play (always with an Active Wigglytuff)
    #--------------------------------------------------------------------------
    def ai_play_doll_or_fossil(duel, card); ai_play_trainer(duel, card, {}); end

    def ai_decide_doll_or_fossil(duel)
      d = duel.turn_duelist
      return false if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
      return 0 if d.card_id(d.arena) == :WIGGLYTUFF
      d.num_in_play_area >= 4 ? false : 0
    end

    #--------------------------------------------------------------------------
    # list helpers (common.asm)
    #--------------------------------------------------------------------------
    # LookForCardIDInLocation_Bank8: first deck index (ascending) or nil
    def card_id_in_location(d, id, location)
      (0...d.deck_size).find { |i| d.card_locations[i] == location && d.card_id(i) == id }
    end
    def card_id_in_deck(d, id); card_id_in_location(d, id, CARD_LOCATION_DECK); end
    def card_id_in_hand?(d, id); d.hand.any? { |i| d.card_id(i) == id }; end
    def card_id_in_play_area?(d, id)
      (0...d.num_in_play_area).any? { |e| d.card_id(d.play_area[e]) == id }
    end
    def card_id_in_hand_or_play_area?(d, id); card_id_in_hand?(d, id) || card_id_in_play_area?(d, id); end

    # LookForCardIDInDeck_GivenCardIDInHandAndPlayArea / _GivenCardIDInHand
    def deck_card_given(d, id1, id2, play_area_too)
      i = card_id_in_deck(d, id1) or return nil
      return nil unless play_area_too ? card_id_in_hand_or_play_area?(d, id2) : card_id_in_hand?(d, id2)
      card_id_in_hand_or_play_area?(d, id1) ? nil : i
    end

    # RemoveFromListDifferentCardOfGivenType (shuffled first: random pick)
    # kind: 0 = Trainer, 1 = Pokemon, 2 = Energy
    def remove_card_of_type(d, list, kind, avoid)
      list.shuffle!
      i = list.find do |c|
        next false if c == avoid
        t = d.card(c).type
        k = t < TYPE_ENERGY ? 1 : (t == TYPE_TRAINER ? 0 : 2)
        k == kind
      end
      list.delete(i) if i
      i
    end

    # two Trainer cards from hand to discard (not the card being played)
    def two_trainers_to_discard(d)
      list = d.hand.dup
      a = remove_card_of_type(d, list, 0, @trainer_card) or return nil
      b = remove_card_of_type(d, list, 0, @trainer_card) or return nil
      [a, b]
    end

    #--------------------------------------------------------------------------
    # Poke Ball (deck-specific search lists only)
    #--------------------------------------------------------------------------
    AI_POKEBALL_PRIORITY = {
      :FIRE_CHARGE_DECK  => [:CHANSEY, :TAUROS, :JIGGLYPUFF_LV12],
      :HARD_POKEMON_DECK => [:RHYHORN, :RHYDON, :ONIX],
      :PIKACHU_DECK      => [:PIKACHU_LV14, :PIKACHU_LV16, :PIKACHU_ALT_LV16, :PIKACHU_LV12, :FLYING_PIKACHU]
    }
    AI_POKEBALL_ETCETERA = [[:FIRE_ENERGY, :CHARMANDER, :MAGMAR_LV31],
                            [:LIGHTNING_ENERGY, :PIKACHU_LV12, :MAGNEMITE_LV13],
                            [:FIGHTING_ENERGY, :DIGLETT, :MACHOP],
                            [:PSYCHIC_ENERGY, :GASTLY_LV8, :JYNX]]

    def ai_play_pokeball(duel, card)
      ai_play_trainer(duel, card, { :PokeBall => @trainer_param })
    end

    def ai_decide_pokeball(duel)
      d = duel.turn_duelist
      if (prio = AI_POKEBALL_PRIORITY[@deck_id])
        prio.each { |id| i = card_id_in_deck(d, id) and return i }
        return false
      end
      case @deck_id
      when :ETCETERA_DECK
        AI_POKEBALL_ETCETERA.each do |energy, p1, p2|
          next unless card_id_in_hand?(d, energy)
          next if card_id_in_hand?(d, p1) || card_id_in_hand?(d, p2)
          i = card_id_in_deck(d, p1) || card_id_in_deck(d, p2)
          return i if i
        end
        false
      when :LOVELY_NIDORAN_DECK
        [[:NIDORANM, :NIDORINO, :NIDOKING], [:NIDORANF, :NIDORINA, :NIDOQUEEN]].each do |b, s1, s2|
          i = deck_card_given(d, s1, b, true) || deck_card_given(d, s2, s1, true) ||
              deck_card_given(d, b, s1, false) || deck_card_given(d, s1, s2, false)
          return i if i
        end
        false
      else false
      end
    end

    #--------------------------------------------------------------------------
    # Computer Search (deck-specific)
    #--------------------------------------------------------------------------
    def ai_play_computer_search(duel, card)
      @current_flags |= AI_FLAG_MODIFIED_HAND
      ai_play_trainer(duel, card, { :DiscardHand => @two_hand_cards.dup,
                                    :ComputerSearchDeck => @trainer_param })
    end

    def ai_decide_computer_search(duel)
      d = duel.turn_duelist
      return false if d.hand.size < 3
      target = case @deck_id
               when :ROCK_CRUSHER_DECK       then cs_rock_crusher(d)
               when :WONDERS_OF_SCIENCE_DECK then cs_wonders_of_science(d)
               when :FIRE_CHARGE_DECK        then cs_fire_charge(d)
               when :ANGER_DECK              then cs_anger(d)
               end
      target || false
    end

    def cs_with_trainer_discards(d, target)
      return nil unless target
      @two_hand_cards = two_trainers_to_discard(d) or return nil
      target
    end

    def cs_rock_crusher(d)
      if d.hand.size == 3
        oak = card_id_in_deck(d, :PROFESSOR_OAK) or return nil
        keep = [:PROFESSOR_OAK, :FIGHTING_ENERGY, :DOUBLE_COLORLESS_ENERGY, :DIGLETT, :GEODUDE, :ONIX, :RHYHORN]
        return nil if d.hand.any? { |i| keep.include?(d.card_id(i)) }
        picks = d.hand - [@trainer_card]
        return nil if picks.size < 2
        @two_hand_cards = picks.first(2)
        return oak
      end
      list = d.hand.dup
      target = nil
      if (i = card_id_in_deck(d, :GRAVELER)) && card_id_in_hand_or_play_area?(d, :GEODUDE) &&
         !card_id_in_hand?(d, :GRAVELER)
        target = i
        j = list.index { |c| d.card_id(c) == :GEODUDE }
        list.delete_at(j) if j
      elsif (i = card_id_in_deck(d, :GOLEM)) && card_id_in_play_area?(d, :GRAVELER) && !card_id_in_hand?(d, :GOLEM)
        target = i
      elsif (i = card_id_in_deck(d, :DUGTRIO)) && card_id_in_play_area?(d, :DIGLETT) && !card_id_in_hand?(d, :DUGTRIO)
        target = i
      else
        return nil
      end
      # Trainers first, then Pokemon, then Energy
      picks = []
      kind = 0
      while picks.size < 2
        c = remove_card_of_type(d, list, kind, @trainer_card)
        if c then picks << c
        else
          kind += 1
          return nil if kind == 3
        end
      end
      @two_hand_cards = picks
      target
    end

    def cs_wonders_of_science(d)
      if d.hand.size < 5 && (oak = card_id_in_deck(d, :PROFESSOR_OAK))
        return cs_with_trainer_discards(d, oak)
      end
      if !card_id_in_hand?(d, :GRIMER)
        return cs_with_trainer_discards(d, card_id_in_deck(d, :GRIMER))
      elsif !card_id_in_hand?(d, :MUK)
        return cs_with_trainer_discards(d, card_id_in_deck(d, :MUK))
      end
      nil
    end

    def cs_fire_charge(d)
      id = [:CHANSEY, :TAUROS, :JIGGLYPUFF_LV12].find { |x| !card_id_in_hand?(d, x) } or return nil
      cs_with_trainer_discards(d, card_id_in_deck(d, id))
    end

    #--------------------------------------------------------------------------
    # Pokemon Trader (deck-specific). param = hand card, @trader_target = deck card
    #--------------------------------------------------------------------------
    def ai_play_pokemon_trader(duel, card)
      ai_play_trainer(duel, card, { :PokemonTraderHand => @trainer_param,
                                    :PokemonTraderDeck => @trader_target })
    end

    # CheckIfHasCardIDInHand: needs TWO copies; returns the second one
    def second_copy_in_hand(d, id)
      d.hand.select { |i| d.card_id(i) == id }[1]
    end

    # FindDuplicatePokemonCards: later card of the last Pokemon pair, or nil
    def duplicate_pokemon_in_hand(d)
      res = nil
      d.hand.each_with_index do |i, n|
        c = d.hand[(n + 1)..].find { |j| d.card_id(j) == d.card_id(i) } or next
        res = c if d.card(c).type < TYPE_ENERGY
      end
      res
    end

    # LookForCardIDToTradeWithDifferentHandCard -> [deck card, hand card]
    def trade_for_with_different_hand_card(d, id1, id2)
      return nil if card_id_in_hand?(d, id1)
      t = card_id_in_deck(d, id1) or return nil
      h = d.hand.find { |i| d.card_id(i) != id2 && d.card(i).type < TYPE_ENERGY } or return nil
      [t, h]
    end

    # pairs [given, target]: try GivenCardIDInHandAndPlayArea, then GivenCardIDInHand
    # in the exact order of the original's calls
    def trader_chain(d, calls)
      calls.each do |kind, id1, id2|
        i = deck_card_given(d, id1, id2, kind == :hp)
        return i if i
      end
      nil
    end

    def trader_with_second_copy(d, target, ids)
      return nil unless target
      ids.each do |id|
        h = second_copy_in_hand(d, id) and return [target, h]
      end
      nil
    end

    def trader_with_duplicate(d, target)
      return nil unless target
      h = duplicate_pokemon_in_hand(d) or return nil
      [target, h]
    end

    def ai_decide_pokemon_trader(duel)
      d = duel.turn_duelist
      res = case @deck_id
            when :LEGENDARY_MOLTRES_DECK then trade_for_with_different_hand_card(d, :MOLTRES_LV37, :MOLTRES_LV35)
            when :STRANGE_POWER_DECK     then trade_for_with_different_hand_card(d, :MR_MIME, :MR_MIME)
            when :LEGENDARY_ARTICUNO_DECK
              if card_id_in_hand_or_play_area?(d, :ARTICUNO_LV35) || card_id_in_hand_or_play_area?(d, :LAPRAS)
                nil
              else
                t = nil
                t = card_id_in_deck(d, :SEEL) unless card_id_in_hand_or_play_area?(d, :SEEL)
                t ||= card_id_in_deck(d, :DEWGONG) unless card_id_in_hand_or_play_area?(d, :DEWGONG)
                trader_with_second_copy(d, t, [:CHANSEY, :DITTO, :ARTICUNO_LV37])
              end
            when :LEGENDARY_DRAGONITE_DECK
              en = d.hand.count { |i| d.card(i).energy? } +
                   (0...d.num_in_play_area).sum { |e| d.energy_cards_in_slot(e).size }
              pk = d.num_in_play_area + d.hand.count { |i| d.card(i).type < TYPE_ENERGY }
              t = if en < 5 || pk < 5
                    card_id_in_deck(d, :KANGASKHAN)
                  else
                    trader_chain(d, [[:hp, :GYARADOS, :MAGIKARP], [:h, :MAGIKARP, :GYARADOS],
                                     [:hp, :DRAGONAIR, :DRATINI], [:hp, :DRAGONITE_LV41, :DRAGONAIR],
                                     [:h, :DRATINI, :DRAGONAIR], [:h, :DRAGONAIR, :DRAGONITE_LV41],
                                     [:hp, :CHARMELEON, :CHARMANDER], [:hp, :CHARIZARD, :CHARMELEON],
                                     [:h, :CHARMANDER, :CHARMELEON], [:h, :CHARMELEON, :CHARIZARD]])
                  end
              trader_with_second_copy(d, t, [:DRAGONAIR, :CHARMELEON, :GYARADOS, :MAGIKARP, :CHARMANDER, :DRATINI])
            when :LEGENDARY_RONALD_DECK
              t = trader_chain(d, [[:hp, :FLAREON_LV22, :EEVEE], [:hp, :VAPOREON_LV29, :EEVEE],
                                   [:hp, :JOLTEON_LV24, :EEVEE], [:h, :EEVEE, :FLAREON_LV22],
                                   [:h, :EEVEE, :VAPOREON_LV29], [:h, :EEVEE, :JOLTEON_LV24],
                                   [:hp, :DRAGONAIR, :DRATINI], [:hp, :DRAGONITE_LV41, :DRAGONAIR],
                                   [:h, :DRATINI, :DRAGONAIR], [:h, :DRAGONAIR, :DRAGONITE_LV41]])
              h = t && [:ZAPDOS_LV68, :ARTICUNO_LV37, :MOLTRES_LV37].map { |id| d.hand.find { |i| d.card_id(i) == id } }.compact.first
              h ? [t, h] : nil
            when :BLISTERING_POKEMON_DECK
              trader_with_duplicate(d, trader_chain(d, [[:hp, :RHYDON, :RHYHORN], [:h, :RHYHORN, :RHYDON],
                                                        [:hp, :MAROWAK_LV26, :CUBONE], [:h, :CUBONE, :MAROWAK_LV26],
                                                        [:hp, :RAPIDASH, :PONYTA], [:h, :PONYTA, :RAPIDASH]]))
            when :SOUND_OF_THE_WAVES_DECK
              t = trader_chain(d, [[:hp, :DEWGONG, :SEEL], [:h, :SEEL, :DEWGONG], [:hp, :KINGLER, :KRABBY],
                                   [:h, :KRABBY, :KINGLER], [:hp, :CLOYSTER, :SHELLDER], [:h, :SHELLDER, :CLOYSTER],
                                   [:hp, :SEADRA, :HORSEA], [:h, :HORSEA, :SEADRA],
                                   [:hp, :TENTACRUEL, :TENTACOOL], [:h, :TENTACOOL, :TENTACRUEL]])
              trader_with_second_copy(d, t, [:SEEL, :KRABBY, :HORSEA, :SHELLDER, :TENTACOOL])
            when :POWER_GENERATOR_DECK
              t = trader_chain(d, [[:hp, :RAICHU_LV40, :PIKACHU_LV14], [:hp, :RAICHU_LV40, :PIKACHU_LV12],
                                   [:h, :PIKACHU_LV14, :RAICHU_LV40], [:h, :PIKACHU_LV12, :RAICHU_LV40],
                                   [:hp, :ELECTRODE_LV42, :VOLTORB], [:hp, :ELECTRODE_LV35, :VOLTORB],
                                   [:h, :VOLTORB, :ELECTRODE_LV42], [:h, :VOLTORB, :ELECTRODE_LV35],
                                   [:hp, :MAGNETON_LV35, :MAGNEMITE_LV13], [:hp, :MAGNETON_LV35, :MAGNEMITE_LV15],
                                   [:hp, :MAGNETON_LV28, :MAGNEMITE_LV13], [:hp, :MAGNETON_LV28, :MAGNEMITE_LV15],
                                   [:h, :MAGNEMITE_LV15, :MAGNETON_LV35], [:h, :MAGNEMITE_LV13, :MAGNETON_LV35],
                                   [:h, :MAGNEMITE_LV15, :MAGNETON_LV28], [:h, :MAGNEMITE_LV13, :MAGNETON_LV28]])
              # ORIGINAL BUG: missing "jr .no_carry" — with no target it still
              # trades a duplicate for a garbage deck index (engine default pick)
              h = duplicate_pokemon_in_hand(d)
              h ? [t, h] : nil
            when :FLOWER_GARDEN_DECK
              trader_with_duplicate(d, trader_chain(d, [[:hp, :IVYSAUR, :BULBASAUR], [:hp, :VENUSAUR_LV67, :IVYSAUR],
                                                        [:h, :BULBASAUR, :IVYSAUR], [:h, :IVYSAUR, :VENUSAUR_LV67],
                                                        [:hp, :WEEPINBELL, :BELLSPROUT], [:hp, :VICTREEBEL, :WEEPINBELL],
                                                        [:h, :BELLSPROUT, :WEEPINBELL], [:h, :WEEPINBELL, :VICTREEBEL],
                                                        [:hp, :GLOOM, :ODDISH], [:hp, :VILEPLUME, :GLOOM],
                                                        [:h, :ODDISH, :GLOOM], [:h, :GLOOM, :VILEPLUME]]))
            when :FLAMETHROWER_DECK
              trader_with_duplicate(d, trader_chain(d, [[:hp, :CHARMELEON, :CHARMANDER], [:hp, :CHARIZARD, :CHARMELEON],
                                                        [:h, :CHARMANDER, :CHARMELEON], [:h, :CHARMELEON, :CHARIZARD],
                                                        [:hp, :NINETALES_LV32, :VULPIX], [:h, :VULPIX, :NINETALES_LV32],
                                                        [:hp, :ARCANINE_LV45, :GROWLITHE], [:h, :GROWLITHE, :ARCANINE_LV45],
                                                        [:hp, :FLAREON_LV28, :EEVEE], [:h, :EEVEE, :FLAREON_LV28]]))
            end
      return false unless res
      @trader_target = res[0]
      res[1]
    end

    def cs_anger(d)
      [[:RATTATA, :RATICATE], [:GROWLITHE, :ARCANINE_LV34], [:DODUO, :DODRIO]].each do |b, s|
        i = deck_card_given(d, s, b, true) || deck_card_given(d, b, s, false)
        return cs_with_trainer_discards(d, i) if i
      end
      nil
    end
  end

  class Duel
    # AIPlay_Gambler's cheated RNG: forces every coin toss result
    attr_accessor :forced_coin
    alias_method :tcg_ai_toss_coin, :toss_coin
    def toss_coin(name = turn_duelist.name)
      return tcg_ai_toss_coin(name) if @forced_coin.nil?
      @ui.coin_toss(name, @forced_coin)
      @forced_coin
    end
  end
end
