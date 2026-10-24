#==============================================================================
# Seasons - swaps a tileset's picture for a seasonal version, from the PC
# clock's month (Time.now, not pbGetTimeNow: this game's Unreal Time makes
# pbGetTimeNow an in-game clock that runs 60x). Works on top of the GSC
# day/morning/night tileset swap in Game_Map (getTilesetID): that picks the
# tileset, this picks the picture for the season. Passages, priorities and terrain tags stay the
# tileset's own, so a seasonal picture must keep the same tile layout.
#
# Files: Graphics/Tilesets/<tileset picture> <season>.png, for example
#   "GSC overworld johto day fall.png". Spring uses the normal picture.
#   A missing seasonal picture falls back to the normal one.
#
# The season is checked when the tileset is refreshed: on map transfer, on a
# fade (refresh_owmap) and when the hour changes, so changing the PC date
# changes the season the next time one of those happens.
#
# Script calls:
#   pbSeason               :spring, :summer, :fall or :winter
#   pbSeasonIs?(:winter)   for a Conditional Branch (not the
#                          same as Essentials' pbIsSeason, which is monthly)
#   Seasons.forced = :winter   force a season (nil = use the clock);
#                              not saved, for testing
#==============================================================================
module Seasons
  # tileset pictures that have seasonal versions
  TILESETS = ["GSC overworld johto day", "GSC overworld johto morning",
              "GSC overworld johto nite"]

  # month => season (northern hemisphere)
  MONTHS = { 3 => :spring, 4 => :spring, 5 => :spring,
             6 => :summer, 7 => :summer, 8 => :summer,
             9 => :fall, 10 => :fall, 11 => :fall,
             12 => :winter, 1 => :winter, 2 => :winter }

  # file name word for each season (nil = the normal picture)
  SUFFIXES = { spring: nil, summer: "summer", fall: "fall", winter: "winter" }

  class << self
    attr_accessor :forced

    def current
      return @forced if @forced
      MONTHS[Time.now.mon] || :spring
    end

    # the picture to use for tileset picture `name` this season
    def tileset_name(name)
      return name if name.nil? || !TILESETS.include?(name)
      suffix = SUFFIXES[current] or return name
      @files ||= {}
      key = "#{name}|#{suffix}"
      return @files[key] if @files.key?(key)
      # the files mix "Summer" and "summer"; try both spellings
      found = [suffix, suffix.capitalize].map { |s| "#{name} #{s}" }
                                         .find { |n| pbResolveBitmap("Graphics/Tilesets/" + n) }
      @files[key] = found || name
    end
  end
end

def pbSeason;             Seasons.current;                 end
def pbSeasonIs?(season);  Seasons.current == season.to_sym; end

class Game_Map
  alias seasons_updateTileset updateTileset unless method_defined?(:seasons_updateTileset)
  def updateTileset
    seasons_updateTileset
    @tileset_name = Seasons.tileset_name(@tileset_name)
  end

  # same as the GSC time system's version, but compares against the
  # seasonal picture so the map only reloads when the picture changes
  def pbChangeTileset
    tileset = $data_tilesets[getTilesetID(@map.tileset_id)]
    return if @tileset_name == Seasons.tileset_name(tileset.tileset_name)
    updateTileset
    $scene.disposeSpritesets if $scene.is_a?(Scene_Map)
    RPG::Cache.clear
    $scene.createSpritesets if $scene.is_a?(Scene_Map)
  end
end

MenuHandlers.add(:debug_menu, :seasons, {
  "name"        => _INTL("Set season"),
  "parent"      => :field_menu,
  "description" => _INTL("Force a season for the seasonal tilesets, or go back to the PC clock."),
  "effect"      => proc {
    seasons = [nil, :spring, :summer, :fall, :winter]
    names = [_INTL("Use PC clock ({1})", Seasons::MONTHS[Time.now.mon].to_s.capitalize),
             _INTL("Spring"), _INTL("Summer"), _INTL("Fall"), _INTL("Winter")]
    i = pbMessage(_INTL("Which season?"), names, -1)
    if i >= 0
      Seasons.forced = seasons[i]
      $game_map.pbChangeTileset if $game_map
    end
  }
})
