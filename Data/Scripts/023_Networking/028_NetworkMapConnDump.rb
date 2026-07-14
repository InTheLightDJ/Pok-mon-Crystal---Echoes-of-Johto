#===============================================================================
# NetworkMapConnDump — one-time (or re-run-after-editing-maps) export of
# Data/map_connections.dat so the server knows which maps are physically
# adjacent to which. Used by the Creepy Pasta boss to wander between connected
# maps (see ServerStuff/handlers/creepyboss.js).
#
# Triggered by the admin-only "MapConnDump" chat command, which asks whichever
# admin is currently logged in to read this data straight from their own
# client and send it back — no manual export step needed.
#===============================================================================
NetworkClient.on('request_map_connections') do |_d|
  pairs = []
  names = {}
  begin
    conns = load_data("Data/map_connections.dat")
    conns.each do |conn|
      a = conn[0].to_i
      b = conn[3].to_i
      next if a <= 0 || b <= 0 || a == b
      pairs.push([a, b])
      names[a.to_s] ||= pbGetMapNameFromId(a)
      names[b.to_s] ||= pbGetMapNameFromId(b)
    end
  rescue => e
    puts "[MapConnDump] Failed to load map_connections.dat: #{e.message}"
  end
  NetworkClient.send_msg({ action: 'map_connections_dump', pairs: pairs, names: names })
end
