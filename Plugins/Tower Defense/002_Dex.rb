#==============================================================================
# Pokémon Tower Defense - what the rules need from the game's data
#   card_hp      the Pokémon's HP on its card (the lowest one if it has
#                several; 40 if it has none)
#   usable?      a species with a card and a follower sprite
#   evolution    the first evolution that's usable (nil = none)
#   basic?       not evolved from anything
#   types        its types (for Weakness / Resistance)
#   walk_speed   tiles a second, from its Speed stat (0.6 to 1.8)
#   effectiveness  the type chart multiplier
#==============================================================================
module TowerDefense
  module Dex
    @hp = {}

    module_function

    def card_hp(species)
      @hp[species] ||= begin
        name = GameData::Species.get(species).real_name
        hps = TCG::CARDS.select { |k, c| !k.to_s.include?("_HOLO_") && c[:name] == name && c[:type].to_s.start_with?("TYPE_PKMN") }
                        .map { |_, c| c[:hp].to_i }
        hps.empty? ? 40 : hps.min
      end
    end

    def card?(species)
      name = GameData::Species.get(species).real_name
      TCG::CARDS.any? { |k, c| !k.to_s.include?("_HOLO_") && c[:name] == name && c[:type].to_s.start_with?("TYPE_PKMN") }
    end

    def sprite(species); pbResolveBitmap("Graphics/Characters/Followers/#{species}"); end

    def usable?(species)
      GameData::Species.exists?(species) && card?(species) && !sprite(species).nil?
    end

    def evolution(species)
      GameData::Species.get(species).get_evolutions(true).map { |e| e[0] }.find { |s| usable?(s) }
    end

    # not evolved from anything (a knock out gives 1 point, not 2)
    def basic?(species)
      GameData::Species.get(species).get_previous_species == species
    end

    def types(species); GameData::Species.get(species).types; end

    def walk_speed(species)
      spd = GameData::Species.get(species).base_stats[:SPEED].to_i
      (0.55 + spd / 110.0).clamp(0.6, 1.8)
    end

    def effectiveness(type, types); Effectiveness.calculate(type, *types); end
  end
end
