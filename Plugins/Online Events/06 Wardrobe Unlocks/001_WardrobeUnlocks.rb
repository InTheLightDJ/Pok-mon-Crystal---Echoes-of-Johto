#===============================================================================
# Characters given out in the game (events: PlayerUnlocks.unlock(id)) instead
# of by pbGiveAdded (Data/Scripts/016_UI/028_UI_PlayerSelect.rb), which gives
# every character past LAST_BUILTIN_PLAYER_ID (302). pbGiveAdded now skips
# up to LAST_GIVEN_PLAYER_ID too; ones added after it are still its own.
#
#   303 Leaf Sygna   304 Fem Ranger   305 Karen     306 Whitney
#   307 GhostGuy     308 Callie       309 Coyote    310 Killua
#   311 Kris         312 Marie        313 Rock Volnutt
#   314 Ghost Admin  315 Ghost Mod    (Ghost Guy wins: server handlers/ghost_trainer.js)
#===============================================================================
LAST_GIVEN_PLAYER_ID = 315

def pbGiveAdded
  newly_unlocked = []
  GameData::PlayerMetadata.each do |meta|
    next if meta.id <= LAST_BUILTIN_PLAYER_ID || meta.id <= LAST_GIVEN_PLAYER_ID
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
