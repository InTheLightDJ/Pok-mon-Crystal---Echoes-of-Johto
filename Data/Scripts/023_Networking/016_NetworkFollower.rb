#===============================================================================
# Follower Pokemon — network event handlers
#===============================================================================

# FFI admin command — force the follower item flag on for testing
NetworkClient.on('force_follower_item') do |_data|
  next if !$PokemonGlobal
  $PokemonGlobal.follower_hold_item = true
end
