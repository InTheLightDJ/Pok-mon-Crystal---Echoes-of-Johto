#===============================================================================
# Player character selection screen.
# Shows a scrollable list of all UNLOCKED player characters on the left, with
# the front and back trainer sprites for the highlighted character on the right.
#
# Call from an event or NPC script with:
#   pbChoosePlayer
#
# Unlock helpers (call from events/scripts):
#   PlayerUnlocks.unlock(id)     — unlock one character by metadata ID
#   PlayerUnlocks.unlock_all     — unlock every defined character
#   PlayerUnlocks.lock(id)       — lock a character (IDs 1 & 2 are protected)
#   PlayerUnlocks.unlocked?(id)  — returns true/false
#===============================================================================

# Adds the unlock list to the save file.
class PokemonGlobalMetadata
  attr_accessor :unlocked_player_ids
end

#-------------------------------------------------------------------------------
# Manages which player characters are available in the selection screen.
# IDs 1 (Ethan) and 2 (Kris) are always unlocked and cannot be locked.
#-------------------------------------------------------------------------------
module PlayerUnlocks
  DEFAULT_IDS = [1, 2].freeze

  def self.unlocked
    $PokemonGlobal.unlocked_player_ids ||= DEFAULT_IDS.dup
  end

  def self.unlocked?(id)
    unlocked.include?(id)
  end

  def self.unlock(id)
    unlocked << id unless unlocked.include?(id)
  end

  def self.unlock_all
    GameData::PlayerMetadata.each { |meta| unlock(meta.id) }
  end

  def self.lock(id)
    return if DEFAULT_IDS.include?(id)
    unlocked.delete(id)
  end
end

#===============================================================================
class PlayerSelect_Scene
  LIST_W = 160   # width of the name list (left panel)

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    # Collect only unlocked player metadata entries in id order
    @players = []
    GameData::PlayerMetadata.each do |meta|
      @players << meta if PlayerUnlocks.unlocked?(meta.id)
    end
    @players.sort_by!(&:id)

    # Build the display name for each entry
    @names = @players.map do |meta|
      GameData::TrainerType.get(meta.trainer_type).name
    end

    # Start cursor on the currently active character (fall back to first)
    @cur_idx  = @players.index { |m| m.id == $player.character_ID } || 0
    @last_idx = -1

    # Background
    @sprites["bg"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["bg"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height,
                                    Color.new(200, 200, 200))

    # Thin vertical divider between list and preview panels
    @sprites["divider"] = BitmapSprite.new(2, Graphics.height, @viewport)
    @sprites["divider"].bitmap.fill_rect(0, 0, 2, Graphics.height,
                                         Color.new(160, 160, 180))
    @sprites["divider"].x = LIST_W

    # Scrollable name list window (left panel, full height)
    @sprites["cmdwindow"] = Window_CommandPokemon.newWithSize(
      @names, 0, 0, LIST_W, Graphics.height, @viewport
    )
    @sprites["cmdwindow"].index = @cur_idx

    # Right panel overlay — redrawn whenever the cursor moves
    rw = Graphics.width - LIST_W
    @sprites["overlay"] = BitmapSprite.new(rw, Graphics.height, @viewport)
    @sprites["overlay"].x = LIST_W

    # Front sprite placeholder
    @sprites["front"] = IconSprite.new(0, 0, @viewport)
    # Back sprite placeholder
    @sprites["back"]  = IconSprite.new(0, 0, @viewport)

    pbRefreshPreview
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbRefreshPreview
    idx = @sprites["cmdwindow"].index
    return if idx == @last_idx
    @last_idx = idx

    meta         = @players[idx]
    trainer_type = meta.trainer_type
    rw           = Graphics.width - LIST_W

    # --- Front sprite ---
    front_file = GameData::TrainerType.front_sprite_filename(trainer_type)
    @sprites["front"].setBitmap(front_file)
    if @sprites["front"].bitmap
      fw = @sprites["front"].bitmap.width
      @sprites["front"].x = LIST_W + (rw - fw) / 2
      @sprites["front"].y = 20
    end

    # --- Back sprite ---
    back_file = GameData::TrainerType.back_sprite_filename(trainer_type)
    @sprites["back"].setBitmap(back_file)
    if @sprites["back"].bitmap
      bw = @sprites["back"].bitmap.width
      @sprites["back"].x = LIST_W + (rw - bw) / 2
      @sprites["back"].y = 154
    end

    # --- Right-panel text overlay ---
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base_color   = Color.new(240, 240, 240)
    shadow_color = Color.new(32, 32, 48)
    gold_color   = Color.new(255, 215, 0)
    gold_shadow  = Color.new(80, 56, 0)

    pbSetSmallFont(overlay)

    texts = [
      [_INTL("FRONT"), rw / 2, 4,   :center, base_color, shadow_color],
      [_INTL("BACK"),  rw / 2, 138, :center, base_color, shadow_color],
    ]
    # Highlight the currently equipped character
    if meta.id == $player.character_ID
      texts << [_INTL("(Current)"), rw / 2, 258, :center, gold_color, gold_shadow]
    end
    pbDrawTextPositions(overlay, texts)
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      pbUpdate
      pbRefreshPreview

      if Input.trigger?(Input::USE)
        idx  = @sprites["cmdwindow"].index
        meta = @players[idx]
        pbPlayDecisionSE
        pbChangePlayer(meta.id)
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

# Metadata ID of the last character in the built-in roster.
# Anything above this is treated as a custom community addition.
LAST_BUILTIN_PLAYER_ID = 302

#-------------------------------------------------------------------------------
# Unlocks every custom character (ID > LAST_BUILTIN_PLAYER_ID) that exists in
# the game data but hasn't been unlocked yet.
#
# Call from an NPC event:  pbGiveAdded
#
# Players can drop in their own POKEMONTRAINER_N sprites, add the matching
# entries to trainer_types.txt and metadata.txt, and this NPC will pick them
# up automatically — no code changes required.
#-------------------------------------------------------------------------------
def pbGiveAdded
  newly_unlocked = []
  GameData::PlayerMetadata.each do |meta|
    next if meta.id <= LAST_BUILTIN_PLAYER_ID
    next if PlayerUnlocks.unlocked?(meta.id)
    PlayerUnlocks.unlock(meta.id)
    newly_unlocked << GameData::TrainerType.get(meta.trainer_type).name
  end
  if newly_unlocked.empty?
    pbMessage(_INTL("No new custom characters were found.\nAdd a sprite sheet and try again!"))
  elsif newly_unlocked.length == 1
    pbMessage(_INTL("✨ {1} has been added to your wardrobe!", newly_unlocked[0]))
  else
    pbMessage(_INTL("✨ {1} new character(s) added to your wardrobe!\n{2}",
                    newly_unlocked.length, newly_unlocked.join(", ")))
  end
end

#-------------------------------------------------------------------------------
# Call this from an event script to open the character selection screen.
#-------------------------------------------------------------------------------
def pbChoosePlayer
  scene = PlayerSelect_Scene.new
  scene.pbStartScene
  scene.pbMain
  scene.pbEndScene
end

#===============================================================================
# Transform — overworld field move that opens the character selection screen.
# Register a Pokémon with Transform in the party to enable the move in the menu.
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:TRANSFORM, proc { |move, pkmn, showmsg|
  next true
})

HiddenMoveHandlers::UseMove.add(:TRANSFORM, proc { |move, pokemon|
  pbHiddenMoveAnimation(pokemon)
  pbChoosePlayer
  next true
})
