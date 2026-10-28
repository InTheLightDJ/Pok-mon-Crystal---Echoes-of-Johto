#==============================================================================
# Pokemon TCG - player controller: the duel menu (core.asm DuelMainInterface:
# Hand / Attack / Check / Pkmn Power / Retreat / Done) and every decision the
# engine asks the human for, using the original screens (070_Scene.rb).
#==============================================================================
module TCG
  class PlayerController
    REASON_TEXT = {
      :already_played_energy => "You may only attach 1 Energy card per turn.",
      :no_space => "There is no space on the Bench.",
      :not_this_turn => "You cannot evolve a Pokémon in the same turn it was placed.",
      :no_evolution_target => "There is no Pokémon to evolve.",
      :prehistoric_power => "Unable to evolve due to Prehistoric Power.",
      :cant_evolve => "Unable to evolve.",
      :headache => "Unable to use Trainer cards due to Headache.",
      :paralyzed => "Unable to do that due to Paralysis.",
      :asleep => "Unable to do that due to Sleep.",
      :acid => "Unable to retreat due to Acid.",
      :no_bench => "There are no Pokémon on the Bench.",
      :trainer_in_arena => "Unable to retreat.",
      :not_enough_energy => "Not enough Energy cards.",
      :confusion_check_failed => "Unable to retreat this turn due to Confusion.",
      :tail_wag => "Unable to attack due to Tail Wag.",
      :leer => "Unable to attack due to Leer.",
      :bone_attack => "Unable to attack due to Bone Attack.",
      :amnesia => "Unable to use that attack due to Amnesia.",
      :cant_use => "", :cancelled => ""
    }

    def initialize(scene); @scene = scene; end

    def say(reason)
      t = REASON_TEXT[reason]
      @scene.message(_INTL(t)) if t && !t.empty?
    end

    def name_of(d, i)
      c = d.card(i)
      c.pokemon? && c.level ? "#{c.name} Lv#{c.level}" : c.name
    end

    def slot_label(d, e)
      i = d.play_area[e]
      return "-" unless i
      "#{e == 0 ? _INTL('Active') : _INTL('Bench {1}', e)}: #{name_of(d, i)} (#{d.slot_hp[e]}HP)"
    end

    # list menu; returns chosen element or nil when cancelled
    def pick(prompt, items, labels, cancellable = true)
      return nil if items.empty?
      cmds = labels.dup
      cmds << _INTL("Cancel") if cancellable
      loop do
        r = pbMessage(_INTL(prompt), cmds, cancellable ? cmds.size : -1)
        return nil if cancellable && (r < 0 || r >= items.size)
        return items[r] if r >= 0 && r < items.size
      end
    end

    #--------------------------------------------------------------------------
    # setup
    #--------------------------------------------------------------------------
    def choose_initial_arena(duel)
      d = duel.turn_duelist
      opts = d.hand.select { |i| duel.playable_as_basic?(d, i) }
      @scene.show_banner(:arena)
      @scene.message(_INTL("Choose a Basic Pokémon
to place in the Arena."))
      @scene.hide_banner
      place_initial_card(d, opts, _INTL("Please choose an
Active Pokémon."), false)
    end

    def choose_initial_bench(duel)
      d = duel.turn_duelist
      opts = d.hand.select { |i| d.card(i).basic? }
      return nil if opts.empty?
      unless @bench_prompted
        @bench_prompted = true
        @scene.show_banner(:bench)
        @scene.message(_INTL("You may choose up to 5 Basic Pokémon
to place on the Bench."))
        @scene.hide_banner
      end
      place_initial_card(d, opts, _INTL("Choose your
Bench Pokémon."), true)
    end

    # DisplayPlaceInitialPokemonCardsScreen: the whole hand, Play/Check menu,
    # non-Basic cards rejected with "You cannot select this card."
    def place_initial_card(d, opts, info, cancellable)
      loop do
        i = @scene.card_list_screen(d, d.hand.dup, _INTL("{1}'s Hand", d.name), info,
                                    menu: :play, cancellable: cancellable)
        return nil if i.nil?
        return i if opts.include?(i)
        @scene.message(_INTL("You cannot select this card."))
      end
    end

    def card_list_header(duel, owner, options)
      loc = owner.card_locations[options[0]] & ~CARD_LOCATION_JUST_DRAWN
      case loc
      when CARD_LOCATION_HAND         then _INTL("{1}'s Hand", owner.name)
      when CARD_LOCATION_DISCARD_PILE then _INTL("{1}'s Discard Pile", owner.name)
      when CARD_LOCATION_DECK         then _INTL("{1}'s Deck", owner.name)
      else owner.name
      end
    end

    def choose_prize(duel, avail)
      d = duel.turn_duelist
      # GetFirstSetPrizeCard from the last position
      start = avail.find { |i| i >= @prize_pos.to_i } || avail.first
      i = @scene.prize_select_screen(duel, d, avail, start)
      @prize_pos = i
      # OpenCardPage_FromHand for the card taken
      @scene.show_card_page(d.display_id(d.prize_cards[i]))
      i
    end

    def choose_ko_replacement(duel, choices)
      d = duel.turn_duelist
      @scene.play_area_screen(duel, d, exclude_arena: true, allowed: choices, cancellable: false,
                              select_menu: true)
    end

    #--------------------------------------------------------------------------
    # effect choices
    #--------------------------------------------------------------------------
    def effect_choice(duel, kind, purpose, options, cancellable)
      return nil if options.empty?
      prompt = "Choose."
      case kind
      when :card
        # cards belong to the side the engine is currently looking at
        owner = duel.turn_duelist
        return @scene.card_list_screen(owner, options, card_list_header(duel, owner, options),
                                       _INTL("Choose a card."), menu: :select,
                                       cancellable: cancellable)
      when :play_area
        return @scene.play_area_screen(duel, duel.turn_duelist, allowed: options,
                                       exclude_arena: !options.include?(0), cancellable: cancellable)
      when :attack
        # HandleDefendingPokemonAttackSelection: the attack menu of the Defending Pokémon
        loop do
          r = @scene.attack_menu(duel, options, du: duel.non_turn_duelist)
          return r if r || cancellable
        end
      when :color
        return choose_color(duel, purpose, options, cancellable)
      when :yes_no
        return choose_yes_no(duel, purpose, options, cancellable)
      when :peek
        seen = @scene.peek_screen(duel)
        return options.include?(seen) ? seen : options.first
      else
        labels = options.map(&:to_s)
      end
      pick(prompt, options, labels, cancellable)
    end

    COLOR_PROMPTS = {
      :Conversion1 => "Choose the Weakness you wish\nto change with Conversion 1.",
      :Conversion2 => "Choose the Resistance you wish\nto change with Conversion 2.",
      :Shift       => "Choose the Pokémon whose color you\nwish to change with Color change."
    }

    # HandleColorChangeScreen: Conversion 1 shows the Defending Pokémon,
    # Conversion 2 the Active Pokémon, Shift the Pokémon using the power;
    # a color not in `options` gives "Unable to select."
    def choose_color(duel, purpose, options, cancellable)
      if purpose == :Conversion1
        du, slot = duel.non_turn_duelist, 0
      else
        du = duel.turn_duelist
        slot = purpose == :Shift ? (duel.atk.temp[:power_slot] || 0) : 0
      end
      loop do
        col = @scene.color_change_screen(duel, du, slot, _INTL(COLOR_PROMPTS[purpose] || "Choose a type."))
        if col.nil?
          return nil if cancellable
          next
        end
        return col if options.include?(col)
        @scene.message(_INTL("Unable to select."))
      end
    end

    YES_NO_PROMPTS = {
      :DevolutionSprayMore    => "Devolve it one more stage?",
      :DevolutionSprayConfirm => "Devolve this Pokémon?"
    }

    def choose_yes_no(duel, purpose, options, cancellable)
      if options.all? { |o| o == true || o == false }
        return @scene.yes_no_menu(_INTL(YES_NO_PROMPTS[purpose] || "Is that OK?"))
      end
      # Prophecy / Devolution Beam: TwoItemHorizontalMenu, side 0 = yours, 1 = opponent's
      text = purpose == :ProphecyDeck ? "Please select the Deck:" : "Please select the Play Area:"
      loop do
        r = @scene.two_item_menu(_INTL(text) + "\n            Yours   Opponent's")
        return nil if r.nil? && cancellable
        return r if r && options.include?(r)
      end
    end

    #--------------------------------------------------------------------------
    # DuelMainInterface
    #--------------------------------------------------------------------------
    def take_turn(duel)
      @scene.refresh(duel)
      loop do
        return if duel.duel_finished != DUEL_NOT_FINISHED
        d = duel.turn_duelist
        r = @scene.duel_menu(duel)
        case r
        when 0 then menu_hand(duel)
        when 1 then return if menu_attack(duel)
        when 2 then menu_check(duel)
        when 3 then menu_power(duel)
        when 4 then menu_retreat(duel)
        when 5 then return
        end
        @scene.refresh(duel)
        return if d.arena.nil?
      end
    end

    def menu_hand(duel)
      d = duel.turn_duelist
      if d.hand.empty?
        @scene.message(_INTL("No cards in hand."))
        return
      end
      i = @scene.card_list_screen(d, d.hand.dup, _INTL("{1}'s Hand", d.name),
                                  _INTL("Please select
Hand."), menu: :play, start: @hand_item.to_i)
      return unless i
      @hand_item = d.hand.index(i)
      c = d.card(i)
      r = if c.energy?
            e = @scene.play_area_screen(duel, d)
            e.nil? ? :cancelled : duel.play_energy_card(i, e)
          elsif c.trainer?
            duel.play_trainer_card(i)
          elsif c.basic?
            duel.play_basic_pokemon(i)
          else
            why = duel.cant_evolve_reason(i)
            if why
              why
            else
              t = duel.evolution_targets(i)
              e = t.size == 1 ? t[0] : @scene.play_area_screen(duel, d, allowed: t)
              e.nil? ? :cancelled : duel.evolve_pokemon(i, e)
            end
          end
      say(r) unless r == :ok
    end

    # returns true if an attack was made (turn ends). Like DuelMenu_Attack,
    # a failed attempt (not enough energy, Amnesia) goes back to the attack menu.
    def menu_attack(duel)
      if (why = duel.cant_attack_reason)
        say(why)
        return false
      end
      list = duel.attack_list
      if list.empty?
        @scene.message(_INTL("No selectable Attack"))
        return false
      end
      start = 0
      loop do
        sel = @scene.attack_menu(duel, list, start)
        return false unless sel
        start = list.index(sel)
        r = duel.use_attack(*sel)
        return true if r == :ok || r == :duel_finished
        return false if r == :cancelled
        say(r)
        return false if duel.cant_attack_reason
      end
    end

    def menu_check(duel)
      @scene.check_menu(duel)
    end

    def menu_power(duel)
      d = duel.turn_duelist
      slots = duel.pkmn_power_slots
      return @scene.message(_INTL("No Pokémon with a Pokémon Power.")) if slots.empty?
      e = @scene.play_area_screen(duel, d, allowed: slots)
      return unless e
      say(duel.use_pkmn_power(e))
    end

    # DisplayPlayAreaScreenToUsePkmnPower: "Use this Pokémon Power?"
    def confirm_pkmn_power(duel)
      @scene.yes_no_menu(_INTL("Use this Pokémon Power?"), true, keep: true)
    end

    def menu_retreat(duel)
      d = duel.turn_duelist
      if (why = duel.cant_retreat_reason)
        return say(why)
      end
      cost = duel.retreat_cost(d)
      picked = []
      total = 0
      pool = d.energy_cards_in_slot(0)
      while total < cost
        i = @scene.card_list_screen(d, pool, _INTL("{1}'s Play Area", d.name),
                                    _INTL("Choose the Energy
to discard ({1}/{2}).", total, cost))
        return unless i
        picked << i
        pool.delete(i)
        total += d.card(i).type == TYPE_ENERGY_DOUBLE_COLORLESS ? 2 : 1
      end
      bench = (1...d.num_in_play_area).to_a
      e = @scene.play_area_screen(duel, d, exclude_arena: true)
      return unless e
      say(duel.attempt_retreat(picked, e))
    end
  end
end
