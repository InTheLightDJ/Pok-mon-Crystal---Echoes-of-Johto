#===============================================================================
# NetworkTimeSync — snaps the local UnrealTime clock to the server's game time.
#
# Called automatically on connect (time field bundled in login_ok) and whenever
# the server broadcasts a time_sync event (ServerSync / ForceSync.Username).
#===============================================================================
module NetworkTimeSync
  # Advance the game clock to match server-provided hour/min/wday.
  # Always moves forward (never rewinds) to avoid negative frame counts.
  def self.apply(hour, min, wday)
    return unless defined?(UnrealTime) && UnrealTime::ENABLED
    return unless $PokemonGlobal

    now = pbGetTimeNow

    # Days to advance to reach the target weekday (0 = already correct)
    day_diff = (wday - now.wday + 7) % 7

    # Seconds within the day to advance to reach hour:min
    now_secs    = now.hour * 3600 + now.min * 60 + now.sec
    target_secs = hour * 3600 + min * 60
    time_diff   = target_secs - now_secs

    total_add = day_diff * 86_400 + time_diff

    # If result is negative (same weekday, time already passed today), push
    # to the same weekday next week so we never rewind.
    total_add += 7 * 86_400 if total_add < 0

    return if total_add == 0

    begin
      UnrealTime.add_seconds(total_add)
      puts "[TimeSync] Set to server time #{hour}:#{min.to_s.rjust(2, '0')} day #{wday} (+#{total_add}s)"
    rescue => e
      puts "[TimeSync] Failed: #{e.message}"
    end
  end
end
