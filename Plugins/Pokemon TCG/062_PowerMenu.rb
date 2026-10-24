#==============================================================================
# Pokemon TCG - Pkmn Power menu (core.asm DisplayPlayAreaScreenToUsePkmnPower):
# the power's INITIAL_EFFECT_1 command runs when it is selected; carry means
# it can't be used (passive powers return carry, as do failed checks).
#==============================================================================
module TCG
  class Duel
    # slots whose Pokemon has a Pokemon Power (for the menu)
    def pkmn_power_slots(d = turn_duelist)
      (0...d.num_in_play_area).select { |e| d.card(d.play_area[e]).attacks.any?(&:pokemon_power?) }
    end

    def use_pkmn_power(e)
      d = turn_duelist
      idx = d.play_area[e]
      ai = d.card(idx).attacks.index(&:pokemon_power?)
      return :no_power unless ai
      copy_attack_data_and_damage(idx, ai)
      @atk.temp[:power_slot] = e
      # DisplayUsePokemonPowerScreen (+ OppAction_UsePokemonPower's text)
      @ui.event(:power_screen, d.name, e, ai) if @ui.shows_card_screens?
      return :cant_use if try_execute_effect_command(EFFECT_INITIAL_EFFECT_1)
      # UseThisPokemonPowerText yes/no for the player
      ctrl = turn_controller
      if @ui.shows_card_screens? && ctrl.respond_to?(:confirm_pkmn_power)
        return :cancelled unless ctrl.confirm_pkmn_power(self)
      end
      use_pokemon_power
    end
  end
end
