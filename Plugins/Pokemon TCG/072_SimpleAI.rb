#==============================================================================
# Pokemon TCG - TEMPORARY simple AI. Will be replaced by the port of
# src/engine/duel/ai (AIController). Plays sensibly enough to test the scene.
#==============================================================================
module TCG
  class SimpleAI
    SAFE_TRAINERS = [:BILL, :POTION, :SUPER_POTION, :FULL_HEAL, :PLUSPOWER, :ENERGY_RETRIEVAL,
                     :POKE_BALL, :PROFESSOR_OAK, :COMPUTER_SEARCH, :POKEMON_CENTER]

    def initialize(scene = nil); @scene = scene; end

    def say(duel, text)
      duel.ui.message(text)
    end

    # placed / evolved / attached announcements are shown by the duel scene
    def announce(duel, text)
      say(duel, text) unless duel.ui.shows_card_screens?
    end

    def choose_initial_arena(duel)
      d = duel.turn_duelist
      d.hand.select { |i| duel.playable_as_basic?(d, i) }.max_by { |i| d.card(i).hp.to_i }
    end

    def choose_initial_bench(duel)
      d = duel.turn_duelist
      d.hand.find { |i| d.card(i).basic? }
    end

    def choose_prize(duel, avail); avail.first; end

    def choose_ko_replacement(duel, choices)
      d = duel.turn_duelist
      choices.max_by { |e| d.slot_hp[e] + 10 * d.attached_energies(e)[1] }
    end

    def effect_choice(duel, kind, purpose, options, cancellable)
      return nil if options.empty?
      case kind
      when :play_area
        if purpose.to_s =~ /Potion|Heal/
          d = duel.turn_duelist
          return options.max_by { |e| duel.card_damage_and_max_hp(d, e)[0] }
        end
        options.first
      when :yes_no then options.include?(true) ? true : options.first
      else options.first
      end
    end

    def take_turn(duel)
      d = duel.turn_duelist
      # bench basics
      d.hand.select { |i| d.card(i).basic? }.each do |i|
        break if d.num_in_play_area >= MAX_PLAY_AREA_POKEMON
        announce(duel, _INTL("{1} placed {2} on the Bench.", d.name, d.card(i).name)) if duel.play_basic_pokemon(i) == :ok
      end
      # evolve
      d.hand.select { |i| d.card(i).pokemon? && !d.card(i).basic? }.each do |i|
        t = duel.evolution_targets(i).first
        next unless t && !duel.cant_evolve_reason(i)
        announce(duel, _INTL("{1} evolved into {2}!", d.card(d.play_area[t]).name, d.card(i).name)) if duel.evolve_pokemon(i, t) == :ok
      end
      # trainers
      d.hand.select { |i| SAFE_TRAINERS.include?(d.card_id(i)) }.each do |i|
        next unless d.hand.include?(i)
        id = d.card_id(i)
        next if id == :PROFESSOR_OAK && d.hand.size > 3
        next if [:POTION, :SUPER_POTION, :POKEMON_CENTER].include?(id) && !duel.play_area_has_any_damage?
        next if id == :FULL_HEAL && d.status == 0
        duel.play_trainer_card(i)
        @scene&.refresh(duel)
      end
      # energy: to the arena if its attack still needs it, else the bench
      en = d.hand.find { |i| d.card(i).energy? }
      if en
        target = (0...d.num_in_play_area).find { |e| needs_energy?(duel, d, e) } || 0
        if duel.play_energy_card(en, target) == :ok
          announce(duel, _INTL("{1} attached {2} to {3}.", d.name, d.card(en).name, d.card(d.play_area[target]).name))
        end
      end
      @scene&.refresh(duel)
      return if duel.duel_finished != DUEL_NOT_FINISHED || duel.turn_duelist.arena.nil?
      return if duel.cant_attack_reason
      opts = duel.attack_list.select { |ci, ai| duel.enough_energies_for_attack?(d, ci, ai) }
      best = opts.max_by { |ci, ai| d.card(ci).attacks[ai].damage }
      duel.use_attack(*best) if best
    end

    def needs_energy?(duel, d, e)
      c = d.card(d.play_area[e])
      return false unless c.pokemon?
      top = c.attacks.reject(&:pokemon_power?).max_by(&:total_cost)
      top && d.attached_energies(e)[1] < top.total_cost
    end
  end
end
