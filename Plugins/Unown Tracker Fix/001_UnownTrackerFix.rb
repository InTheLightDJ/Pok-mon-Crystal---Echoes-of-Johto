#===============================================================================
# Unown Tracker fix (Data/Scripts/022_Plugins/008_UnownTracker)
# The tracker recorded a catch by reading the last Unown in the party, so a
# catch sent to the PC (full party) or a party holding an older Unown recorded
# the wrong letter, and switch 102 never turned on. Catches are now recorded
# from the caught Pokemon itself, and the party and PC boxes are scanned so
# saves that already missed forms get them back.
#===============================================================================

EventHandlers.remove(:on_wild_battle_end, :unown_tracker_caught)

def pbRecordUnownCaught(pkmn)
  return false unless pkmn.is_a?(Pokemon) && pkmn.species == :UNOWN && !pkmn.egg?
  return false unless $PokemonGlobal
  $PokemonGlobal.unown_seen_forms   ||= []
  $PokemonGlobal.unown_caught_forms ||= []
  form = pkmn.form
  changed = false
  [$PokemonGlobal.unown_seen_forms, $PokemonGlobal.unown_caught_forms].each do |list|
    next if list.include?(form)
    list << form
    changed = true
  end
  changed
end

# A test build of this fix appended the PC boxes (empty slots too) to the
# party itself. Undo that in any save made with it: drop the empty slots and
# any party member that is the very same object as a boxed Pokemon.
def pbRepairUnownSyncParty
  party = $player.party
  return if party.length <= Settings::MAX_PARTY_SIZE && !party.include?(nil)
  boxed = {}
  if $PokemonStorage
    $PokemonStorage.maxBoxes.times do |b|
      $PokemonStorage.maxPokemon(b).times do |i|
        pkmn = $PokemonStorage[b, i]
        boxed[pkmn.object_id] = true if pkmn
      end
    end
  end
  party.reject! { |pkmn| pkmn.nil? || boxed[pkmn.object_id] }
end

# Adds every Unown form in the party and PC boxes to the tracker.
def pbSyncUnownTracker
  return unless $PokemonGlobal && $player
  pbRepairUnownSyncParty
  mons = $player.party.dup
  if $PokemonStorage
    $PokemonStorage.maxBoxes.times do |b|
      $PokemonStorage.maxPokemon(b).times { |i| mons << $PokemonStorage[b, i] }
    end
  end
  mons.each { |pkmn| pbRecordUnownCaught(pkmn) }
  pbUpdateUnownSwitches
end

# Shared by normal wild battles and the Safari Zone.
module Battle::CatchAndStoreMixin
  alias _unown_fix_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon
  def pbRecordAndStoreCaughtPokemon
    changed = false
    @caughtPokemon.each { |pkmn| changed = true if pbRecordUnownCaught(pkmn) }
    pbUpdateUnownSwitches if changed
    _unown_fix_pbRecordAndStoreCaughtPokemon
  end
end

module Game
  class << self
    alias _unown_fix_load load
    def load(save_data)
      _unown_fix_load(save_data)
      pbSyncUnownTracker rescue nil
    end
  end
end

alias _unown_fix_pbOpenUnownTracker pbOpenUnownTracker
def pbOpenUnownTracker
  pbSyncUnownTracker
  _unown_fix_pbOpenUnownTracker
end
