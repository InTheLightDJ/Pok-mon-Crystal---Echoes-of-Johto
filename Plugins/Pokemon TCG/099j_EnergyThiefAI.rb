#==============================================================================
# Pokemon TCG - the AI uses Energy Thief (061i_EnergyThief.rb) whenever the
# opponent has Darkness Energy in play, moving it all to its Active Pokémon.
#==============================================================================
module TCG
  class AIController
    alias_method :tcg_energy_thief_handle_pkmn_powers, :handle_pkmn_powers
    def handle_pkmn_powers(duel)
      return true if tcg_energy_thief_handle_pkmn_powers(duel)
      return false if duel.toxic_gas_active?
      d = duel.turn_duelist
      (0...d.num_in_play_area).each do |c|
        break if c >= d.num_in_play_area
        idx = d.play_area[c]
        next unless d.card_id(idx) == :SHADOW_LUGIA_DARK
        next if power_initial_effect_2_fails?(duel, c)
        @power_card = idx
        ai_use_power(duel, c, { :EnergyThiefTo => ->(_o) { PLAY_AREA_ARENA } })
        return true if turn_over?(duel)
      end
      false
    end
  end
end
