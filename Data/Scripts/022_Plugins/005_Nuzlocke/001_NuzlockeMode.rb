#===============================================================================
# Nuzlocke Mode
# Call pbNuzlockeSetup from an NPC/event script to open the toggle menu.
#
# Rules (each toggleable):
#   one_per_route  — can only catch one Pokémon per route
#   first_only     — that catch must be the very first encounter on the route
#   one_type       — can't catch a Pokémon whose type you've already caught
#   permadeath     — fainted Pokémon are permanently released after each battle
#   no_items       — the Bag (and quick-ball shortcut) is locked in battle
#===============================================================================

module Nuzlocke
  RULES = {
    one_per_route: "1 catch per route",
    first_only:    "First encounter only",
    one_type:      "No duplicate types",
    permadeath:    "Permanent death",
    no_items:      "No items in battle"
  }

  def self.data
    $PokemonGlobal.nuzlocke ||= {
      enabled:            false,
      one_per_route:      false,
      first_only:         false,
      one_type:           false,
      permadeath:         false,
      no_items:           false,
      caught_routes:      [],
      encountered_routes: [],
      caught_types:       []
    }
    $PokemonGlobal.nuzlocke
  end

  def self.enabled?
    return false unless $PokemonGlobal
    data[:enabled]
  end

  def self.rule?(key)
    enabled? && data[key]
  end

  def self.mark_encounter(map_id)
    data[:encountered_routes] |= [map_id]
  end

  def self.encountered_route?(map_id)
    data[:encountered_routes].include?(map_id)
  end

  def self.caught_route?(map_id)
    data[:caught_routes].include?(map_id)
  end

  def self.record_catch(map_id, species_sym)
    data[:caught_routes]      |= [map_id]
    data[:encountered_routes] |= [map_id]
    sp = GameData::Species.try_get(species_sym)
    data[:caught_types] |= sp.types if sp
  end

  # Returns a reason string if this catch should be denied, or nil if allowed.
  # Checks block flag (set before battle) then the one_type rule.
  def self.catch_denied_reason(species_sym)
    if $game_temp.nuzlocke_block_catch
      return "Your encounter for this route is already used up."
    end
    if rule?(:one_type)
      sp = GameData::Species.try_get(species_sym)
      if sp
        overlap = sp.types.select { |t| data[:caught_types].include?(t) }
        unless overlap.empty?
          tnames = overlap.map { |t| GameData::Type.get(t).name }.join("/")
          return "You already caught a #{tnames}-type Pokémon."
        end
      end
    end
    nil
  end
end

#===============================================================================
# Persistent storage
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :nuzlocke
end

#===============================================================================
# Per-battle temp flags
#===============================================================================
class Game_Temp
  attr_accessor :nuzlocke_block_catch
  attr_accessor :nuzlocke_party_size_before
  attr_accessor :nuzlocke_game_over

  def nuzlocke_block_catch
    @nuzlocke_block_catch ||= false
  end
  def nuzlocke_party_size_before
    @nuzlocke_party_size_before ||= 0
  end
  def nuzlocke_game_over
    @nuzlocke_game_over ||= false
  end
end

#===============================================================================
# Setup menu — call from NPC or debug console
#===============================================================================
def pbNuzlockeSetup
  nzd      = Nuzlocke.data
  all_keys = [:enabled] + Nuzlocke::RULES.keys
  all_lbls = ["Nuzlocke: Master Switch"] + Nuzlocke::RULES.values.to_a

  # Build EnumOption objects (same type the Options menu uses).
  # Index 0 = OFF, 1 = ON. Left/right cycling is handled by Window_PokemonOption.
  options = all_keys.each_with_index.map do |key, i|
    EnumOption.new(all_lbls[i], ["OFF", "ON"],
      proc { nzd[key] ? 1 : 0 },
      proc { |val| nzd[key] = (val == 1) }
    )
  end

  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  sprites = {}
  sprites["option"] = Window_PokemonOption.new(options, 0, 0, Graphics.width, Graphics.height)
  sprites["option"].viewport = viewport
  sprites["option"].visible  = true
  options.length.times { |i| sprites["option"].setValueNoRefresh(i, options[i].get || 0) }
  sprites["option"].refresh
  pbDeactivateWindows(sprites)

  pbActivateWindow(sprites, "option") do
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(sprites)
      if sprites["option"].value_changed
        idx = sprites["option"].index
        options[idx].set(sprites["option"][idx])
      end
      break if Input.trigger?(Input::BACK)
      break if Input.trigger?(Input::USE) && sprites["option"].index == options.length
    end
  end

  # Flush any unsaved values before closing
  options.length.times { |i| options[i].set(sprites["option"][i]) }
  pbDisposeSpriteHash(sprites)
  viewport.dispose
  pbMessage("Nuzlocke settings saved.")
end

#===============================================================================
# Wild battle hooks
#===============================================================================

# Before a wild battle — snapshot party size and set the catch-block flag.
EventHandlers.add(:on_calling_wild_battle, :nuzlocke_pre_battle,
  proc { |foe_pokemon, handled|
    next unless Nuzlocke.enabled?
    map_id = $game_map.map_id

    # Remember current party size so we know where the caught Pokémon lands.
    $game_temp.nuzlocke_party_size_before = $player&.party&.length || 0

    # Decide whether catching should be blocked on this encounter.
    block = false
    block = true if Nuzlocke.rule?(:first_only) && Nuzlocke.encountered_route?(map_id)
    block = true if Nuzlocke.rule?(:one_per_route) && Nuzlocke.caught_route?(map_id)
    $game_temp.nuzlocke_block_catch = block

    # Mark this route as "encountered" (uses up the first-encounter slot).
    Nuzlocke.mark_encounter(map_id)
  }
)

# After a wild battle — validate the catch and release it if rules are violated.
EventHandlers.add(:on_wild_battle_end, :nuzlocke_post_catch,
  proc { |species, level, decision|
    next unless Nuzlocke.enabled?
    next unless decision == 4  # only catches

    map_id = $game_map.map_id
    reason = Nuzlocke.catch_denied_reason(species)

    if reason
      # Locate and permanently release the newly caught Pokémon.
      pkmn  = nil
      party = $player&.party
      if party && party.length > $game_temp.nuzlocke_party_size_before
        # Pokémon went to party — it's the last entry.
        pkmn = party.last
        party.pop
      elsif $PokemonStorage
        # Party was full — find it in the PC boxes by species.
        $PokemonStorage.maxBoxes.times do |box|
          $PokemonStorage.maxPokemon(box).times do |slot|
            p = $PokemonStorage[box, slot]
            if p && p.species == species
              $PokemonStorage[box, slot] = nil
              pkmn = p
              break
            end
          end
          break if pkmn
        end
      end
      pbMessage("[NUZLOCKE] #{reason}\n#{pkmn ? pkmn.name : 'The Pokémon'} was released.")
    else
      Nuzlocke.record_catch(map_id, species)
    end

    $game_temp.nuzlocke_block_catch = false
  }
)

# After any battle — release fainted Pokémon when permadeath is on.
EventHandlers.add(:on_end_battle, :nuzlocke_permadeath,
  proc { |outcome, can_lose|
    next unless Nuzlocke.rule?(:permadeath)
    # outcome 2 = LOSE, 5 = DRAW — the game's own blackout handles these.
    next if outcome == 2 || outcome == 5

    party   = $player&.party
    fainted = party&.select { |p| p.fainted? }
    next if fainted.nil? || fainted.empty?

    names = fainted.map(&:name)
    fainted.each { |p| party.delete(p) }

    msg = names.length == 1 ?
      "[NUZLOCKE] #{names[0]} has fainted and is gone forever." :
      "[NUZLOCKE] #{names.join(', ')} have fainted and are gone forever."
    pbMessage(msg)

    if party.empty?
      pbMessage("[NUZLOCKE] You have no Pokémon left. Your Nuzlocke run is over.")
      $game_temp.nuzlocke_game_over = true
    end
  }
)

# Deferred game over — runs on the next overworld frame after permadeath wipes party.
EventHandlers.add(:on_frame_update, :nuzlocke_game_over_trigger,
  proc {
    next unless $game_temp.nuzlocke_game_over
    next unless $player&.party&.empty?
    $game_temp.nuzlocke_game_over = false
    pbBlackOut(false)
  }
)

# TEMPORARY DEBUG — remove once evolution issue is diagnosed
EventHandlers.add(:on_end_battle, :debug_eevee_evo,
  proc { |outcome, _|
    eevee = $player&.party&.find { |p| p.species == :EEVEE }
    next unless eevee
    t = pbGetTimeNow
    puts "=== EEVEE EVO DEBUG ==="
    puts "  happiness    : #{eevee.happiness}"
    puts "  level        : #{eevee.level}"
    puts "  fainted?     : #{eevee.fainted?}"
    puts "  item         : #{eevee.item.inspect}"
    puts "  in-game time : #{t.hour}:#{t.min.to_s.rjust(2,'0')}"
    puts "  isDay?       : #{PBDayNight.isDay?}"
    puts "  isNight?     : #{PBDayNight.isNight?}"
    puts "  evolutions   : #{eevee.species_data.get_evolutions(true).inspect}"
    puts "  evo result   : #{eevee.check_evolution_on_level_up.inspect}"
    puts "======================="
  }
)

#===============================================================================
# No items in battle
#===============================================================================
class Battle::Scene
  # Block the standard Bag menu.
  alias nuzlocke_orig_item_menu pbItemMenu
  def pbItemMenu(idxBattler, firstAction, &block)
    if Nuzlocke.rule?(:no_items)
      pbDisplay("Items are disabled in Nuzlocke mode!")
      return
    end
    nuzlocke_orig_item_menu(idxBattler, firstAction, &block)
  end

  # Block the quick-pokéball shortcut (returns -3 from pbCommandMenuEx).
  alias nuzlocke_orig_cmd_menu_ex pbCommandMenuEx
  def pbCommandMenuEx(idxBattler, texts, mode = 0)
    ret = nuzlocke_orig_cmd_menu_ex(idxBattler, texts, mode)
    if ret == -3 && Nuzlocke.rule?(:no_items)
      pbDisplay("Items are disabled in Nuzlocke mode!")
      return -1  # -1 = cancel → battle loops back to the command menu
    end
    ret
  end
end
