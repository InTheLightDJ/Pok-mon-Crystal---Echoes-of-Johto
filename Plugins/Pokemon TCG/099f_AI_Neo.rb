#==============================================================================
# Pokemon TCG - AI for the custom cards' powers (001b_NeoCards.rb).
#   Harvest Bounty: after the turn's Energy went to the Active Pokemon, the
#   AI attaches 1 more there when an attack still needs it.
#==============================================================================
module TCG
  class AIController
    alias_method :tcg_neo_process_and_try_to_play_energy, :process_and_try_to_play_energy
    def process_and_try_to_play_energy(duel, flags = 0)
      r = tcg_neo_process_and_try_to_play_energy(duel, flags)
      if duel.harvest_bounty_available?
        d = duel.turn_duelist
        try_to_play_energy_card(duel, PLAY_AREA_ARENA) if d.hand.any? { |i| d.card(i).energy? }
      end
      r
    end
  end
end

#==============================================================================
# second batch (061c_NeoEffects2.rb):
#   Heal (Vileplume, Jungle art) like the original Vileplume;
#   Drive Off (Light Arcanine) when the Defending Pokémon has 2+ Energy or
#   could Knock Out Light Arcanine.
# Choices inside the new attacks are made in the effects themselves.
#==============================================================================
module TCG
  PlayerController::REASON_TEXT.merge!(
    :scary_face    => "Unable to do that due to Scary Face.",
    :spider_web    => "Unable to retreat due to Spider Web.",
    :sticky_nectar => "Unable to retreat due to Sticky Nectar.",
    :fire_immunity => "Fire Immunity: Fire Energy can't be attached to Moltres."
  )

  class AIController
    alias_method :tcg_neo2_handle_pkmn_powers, :handle_pkmn_powers
    def handle_pkmn_powers(duel)
      return true if tcg_neo2_handle_pkmn_powers(duel)
      return false if duel.toxic_gas_active?
      d = duel.turn_duelist
      (0...d.num_in_play_area).each do |c|
        break if c >= d.num_in_play_area
        idx = d.play_area[c]
        next unless [:VILEPLUME_NEO, :LIGHT_ARCANINE].include?(d.card_id(idx))
        next if power_initial_effect_2_fails?(duel, c)
        @power_card = idx
        case d.card_id(idx)
        when :VILEPLUME_NEO  then ai_power_heal(duel, c)
        when :LIGHT_ARCANINE then ai_power_drive_off(duel, c)
        end
        return true if turn_over?(duel)
      end
      false
    end

    def ai_power_drive_off(duel, c)
      nd = duel.non_turn_duelist
      threat = nd.attached_energies(PLAY_AREA_ARENA)[1] >= 2 || defending_ko_damage(duel, PLAY_AREA_ARENA)
      ai_use_power(duel, c, {}) if threat
    end
  end
end
