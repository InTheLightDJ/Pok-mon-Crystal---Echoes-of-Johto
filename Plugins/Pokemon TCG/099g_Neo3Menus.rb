#==============================================================================
# Pokemon TCG - duel menu texts and turn ending for the third batch of
# custom cards (061d_NeoEffects3.rb), and their AI damage estimates.
#==============================================================================
module TCG
  PlayerController::REASON_TEXT.merge!(
    :neo_no_attack     => "This Pokémon can't attack this turn.",
    :neo_frozen        => "Unable to attack due to Freeze.",
    :energy_immunity   => "That Energy can't be attached to this Pokémon.",
    :neo_cant_evolve   => "This Pokémon can't evolve this turn."
  )

  PlayerController::YES_NO_PROMPTS.merge!(
    :NeoMindGames       => "Use Mind Games on that Trainer card?",
    :NeoHowl            => "Use Howl? (It ends your turn.)",
    :NeoPullIn          => "Switch in 1 of the opponent's Benched Pokémon first?",
    :NeoDragOff         => "Switch in 1 of the opponent's Benched Pokémon first?",
    :NeoLightningStrike => "Discard all Lightning Energy for 80 damage?",
    :NeoGoldScale       => "Draw 2 cards?",
    :NeoGoldScaleOpp    => "Gold Scale: do you draw 2 cards?"
  )

  #----------------------------------------------------------------------------
  # powers that end the turn (Playful Punch, Howl): the duel menu stops
  #----------------------------------------------------------------------------
  module NeoEndTurnMenu
    def take_turn(duel)
      catch(:neo_end_turn) { super }
    end

    %i[menu_hand menu_power].each do |m|
      define_method(m) do |duel, *a|
        r = super(duel, *a)
        if duel.neo_end_turn
          @scene.refresh(duel)
          throw :neo_end_turn
        end
        r
      end
    end
  end
  PlayerController.prepend(NeoEndTurnMenu)

  class Duel
    # the AI's damage estimates don't flip the coins
    %i[ai_calc_one_versus_defending ai_calc_one_from_defending].each do |m|
      alias_method :"tcg_neo3_#{m}", m
      define_method(m) do |*a|
        @neo3_ai_calc = true
        send(:"tcg_neo3_#{m}", *a)
      ensure
        @neo3_ai_calc = false
      end
    end
  end
end
