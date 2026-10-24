#==============================================================================
# Pokemon TCG - effect functions, batch 18 (effect_functions.asm).
# Damage Swap, Curse selection, Energy Trans. The original runs a player-only
# interactive loop in BEFORE_DAMAGE and applies the AI's precomputed single
# step through phase 4 via OppAction; here both player and AI controllers use
# the same loop (effect_choice), so the phase-4 "AI step" functions are no-ops.
#==============================================================================
module TCG
  effects(:DamageSwap_SwapEffect, :StrangeBehavior_SwapEffect, :EnergyTrans_AIEffect) { |du| false }

  # Damage Swap: repeatedly move 1 damage counter between your Pokemon.
  # A move is refused if it would knock out the receiver.
  effect(:DamageSwap_SelectAndSwapEffect) do |du|
    d = du.turn_duelist
    loop do
      sources = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
      break if sources.empty?
      src = du.effect_choice(:play_area, :DamageSwapFrom, sources, true)
      break if src.nil?
      targets = (0...d.num_in_play_area).select { |e| d.slot_hp[e] > 10 }
      tgt = du.effect_choice(:play_area, :DamageSwapTo, targets, true)
      next if tgt.nil?   # counter returns to where it was taken from
      d.slot_hp[tgt] -= 10
      d.slot_hp[src] += 10
      du.ui.refresh(du)
    end
    false
  end

  # Curse: pick a damaged opponent Pokemon (a1) and a different one to receive
  # the counter (atk.temp[:play_area_effect_target]). Cancel on the first pick.
  effect(:Curse_PlayerSelectEffect) do |du|
    res = du.as_non_turn do
      d = du.turn_duelist
      loop do
        sources = (0...d.num_in_play_area).select { |e| du.card_damage_and_max_hp(d, e)[0] > 0 }
        src = du.effect_choice(:play_area, :CurseFrom, sources, true)
        break nil if src.nil?
        tgt = du.effect_choice(:play_area, :CurseTo, (0...d.num_in_play_area).to_a - [src], true)
        next if tgt.nil?
        break [src, tgt]
      end
    end
    next true if res.nil?
    du.set_temp(:a1, res[0])
    du.atk.temp[:play_area_effect_target] = res[1]
    false
  end

  # Energy Trans: repeatedly move Grass Energy between your Pokemon
  effect(:EnergyTrans_TransferEffect) do |du|
    d = du.turn_duelist
    grass = TYPE_NAMES["TYPE_ENERGY_GRASS"]
    loop do
      sources = (0...d.num_in_play_area).select { |e| d.energy_cards_in_slot(e).any? { |i| d.card(i).type == grass } }
      break if sources.empty?
      src = du.effect_choice(:play_area, :EnergyTransFrom, sources, true)
      break if src.nil?
      card = d.energy_cards_in_slot(src).find { |i| d.card(i).type == grass }
      tgt = du.effect_choice(:play_area, :EnergyTransTo, (0...d.num_in_play_area).to_a, true)
      next if tgt.nil?
      d.card_locations[card] = CARD_LOCATION_PLAY_AREA | tgt
      du.ui.refresh(du)
    end
    false
  end
end
