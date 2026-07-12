#===============================================================================
# Unown Form Tracker
# Tracks all 28 Unown forms (A–Z, ?, !).
# Unlock from an NPC: call  pbUnlockUnownTracker  in the event script.
# Open from Pokédex list: press L or R (Q / W).
# Switch 101 = all 28 forms SEEN.
# Switch 102 = all 28 forms CAUGHT.
#===============================================================================

UNOWN_FORM_NAMES = [
  "A","B","C","D","E","F","G","H","I","J","K","L","M",
  "N","O","P","Q","R","S","T","U","V","W","X","Y","Z","?","!"
]

#-------------------------------------------------------------------------------
# Persistent storage on $PokemonGlobal
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :unown_tracker_unlocked  # bool — set true by NPC unlock
  attr_accessor :unown_seen_forms        # Array<Integer> form indices seen
  attr_accessor :unown_caught_forms      # Array<Integer> form indices caught
end

#-------------------------------------------------------------------------------
# Helpers
#-------------------------------------------------------------------------------
def pbUpdateUnownSwitches
  return unless $game_switches && $PokemonGlobal
  seen   = $PokemonGlobal.unown_seen_forms   || []
  caught = $PokemonGlobal.unown_caught_forms || []
  $game_switches[101] = (0..27).all? { |f| seen.include?(f) }
  $game_switches[102] = (0..27).all? { |f| caught.include?(f) }
end

# Call this from an NPC event script to unlock the tracker.
def pbUnlockUnownTracker
  return if $PokemonGlobal.unown_tracker_unlocked
  $PokemonGlobal.unown_tracker_unlocked = true
  $PokemonGlobal.unown_seen_forms   ||= []
  $PokemonGlobal.unown_caught_forms ||= []
  pbMessage(_INTL("The Unown Research Tracker has been added to your Pokédex!"))
end

#-------------------------------------------------------------------------------
# Event hooks
#-------------------------------------------------------------------------------
# Seen: alias WildBattle.start so we get the exact Pokémon object entering the
# fight — not every overworld spawn. on_wild_pokemon_created fires for each
# visible-overworld sprite when it spawns (possibly several Unown at once),
# which caused wrong/extra forms to be recorded before any battle happened.
class WildBattle
  class << self
    alias_method :_unown_tracker_start, :start
    def start(*args, **opts, &block)
      args.each do |arg|
        next unless arg.is_a?(Pokemon) && arg.species == :UNOWN
        $PokemonGlobal.unown_seen_forms ||= []
        form = arg.form
        unless $PokemonGlobal.unown_seen_forms.include?(form)
          $PokemonGlobal.unown_seen_forms << form
          pbUpdateUnownSwitches
        end
      end
      _unown_tracker_start(*args, **opts, &block)
    end
  end
end

# Caught: read the form from the party member that was just added.
EventHandlers.add(:on_wild_battle_end, :unown_tracker_caught,
  proc { |species, _level, decision|
    next unless species == :UNOWN && decision == 4
    unown = $player.party.select { |p| p.species == :UNOWN }.last
    next unless unown
    $PokemonGlobal.unown_caught_forms ||= []
    form = unown.form
    next if $PokemonGlobal.unown_caught_forms.include?(form)
    $PokemonGlobal.unown_caught_forms << form
    pbUpdateUnownSwitches
  }
)

#-------------------------------------------------------------------------------
# Tracker UI
#-------------------------------------------------------------------------------
class UnownTracker_Scene
  COLS = 4
  ROWS = 7
  PAD  = 20

  BG_COLOR      = Color.new(10,  10,  30)
  HEADER_COLOR  = Color.new(0,   0,   50)
  TITLE_COLOR   = Color.new(255, 255, 255)
  SHADOW_COLOR  = Color.new(0,   0,   0)
  BORDER_COLOR  = Color.new(60,  60,  80)
  HINT_COLOR    = Color.new(150, 150, 150)

  FG_CAUGHT  = Color.new(255, 215, 0)     # gold
  FG_SEEN    = Color.new(180, 200, 255)   # pale blue
  FG_UNSEEN  = Color.new(70,  70,  70)    # dim gray

  BG_CAUGHT  = Color.new(80,  60,  0)
  BG_SEEN    = Color.new(20,  30,  70)
  BG_UNSEEN  = Color.new(25,  25,  25)

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    drawTracker
    pbFadeInAndShow(@sprites)
  end

  def drawTracker
    bmp  = @sprites["overlay"].bitmap
    bmp.clear

    seen   = $PokemonGlobal.unown_seen_forms   || []
    caught = $PokemonGlobal.unown_caught_forms || []
    seen_n   = (0..27).count { |f| seen.include?(f) }
    caught_n = (0..27).count { |f| caught.include?(f) }

    # Background
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, BG_COLOR)
    # Header bar — tall enough for two stat lines
    bmp.fill_rect(0, 0, Graphics.width, 72, HEADER_COLOR)

    pbDrawTextPositions(bmp, [
      [_INTL("Unown Research"),          Graphics.width / 2, 4,  :center, TITLE_COLOR, SHADOW_COLOR],
      [_INTL("Seen: {1}/28",   seen_n),  PAD,                30, :left,   FG_SEEN,     SHADOW_COLOR],
      [_INTL("Caught: {1}/28", caught_n), PAD,               50, :left,   FG_CAUGHT,   SHADOW_COLOR],
    ])

    # Grid
    grid_y = 80
    cell_w = (Graphics.width  - PAD * 2) / COLS
    cell_h = (Graphics.height - grid_y - PAD - 28) / ROWS

    UNOWN_FORM_NAMES.each_with_index do |name, i|
      col = i % COLS
      row = i / COLS
      cx  = PAD + col * cell_w
      cy  = grid_y + row * cell_h

      is_caught = caught.include?(i)
      is_seen   = seen.include?(i)

      bg = is_caught ? BG_CAUGHT : (is_seen ? BG_SEEN   : BG_UNSEEN)
      fg = is_caught ? FG_CAUGHT : (is_seen ? FG_SEEN   : FG_UNSEEN)

      # Cell background + top/left border lines
      bmp.fill_rect(cx + 2, cy + 2, cell_w - 4, cell_h - 4, bg)
      bmp.fill_rect(cx + 2, cy + 2, cell_w - 4, 1,          BORDER_COLOR)
      bmp.fill_rect(cx + 2, cy + 2, 1,          cell_h - 4, BORDER_COLOR)

      # Show letter when seen/caught; "?" when not yet seen
      letter = is_seen ? name : "?"
      mid_x  = cx + cell_w / 2

      pbDrawTextPositions(bmp, [
        [letter, mid_x, cy + (cell_h / 2) - 12, :center, fg, SHADOW_COLOR],
      ])
    end

    # Footer legend — two lines
    pbDrawTextPositions(bmp, [
      [_INTL("Gold=Caught  Blue=Seen"), Graphics.width / 2, Graphics.height - 42, :center, HINT_COLOR, SHADOW_COLOR],
      [_INTL("Gray=Unseen"),            Graphics.width / 2, Graphics.height - 22, :center, HINT_COLOR, SHADOW_COLOR],
    ])
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbTracker
    loop do
      Graphics.update
      Input.update
      pbUpdate
      break if Input.trigger?(Input::BACK) || Input.trigger?(Input::USE)
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

def pbOpenUnownTracker
  pbPlayDecisionSE
  scene = UnownTracker_Scene.new
  scene.pbStartScene
  scene.pbTracker
  scene.pbEndScene
end
