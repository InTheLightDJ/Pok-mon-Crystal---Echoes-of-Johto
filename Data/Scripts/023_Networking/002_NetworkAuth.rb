#===============================================================================
# NetworkAuth — auto-connect using the player's in-game name.
#
# Call from an event or NPC script:
#   NetworkAuth.auto_connect
#
# A UUID in %APPDATA%\<game title>\device_id.dat identifies the player's
# machine. This means tokens and account data survive in-game name changes and
# prevent someone else from logging in with the same username and stealing
# tokens. The file lives outside the game folder so it survives updates.
#
# No password is required. Accounts are created automatically on first login.
#===============================================================================

module NetworkAuth
  # Permanent home — same AppData folder as Game.rxdata (survives game updates).
  DEVICE_ID_PATH        = RTP.getSaveFileName('device_id.dat')
  # Legacy path inside the game folder — only used once for one-time migration.
  DEVICE_ID_LEGACY_PATH = 'device_id.dat'

  @username  = nil
  @device_id = nil  # cached in memory — survives new-game without file I/O

  def self.username
    @username
  end

  def self.logged_in?
    !@username.nil? && NetworkClient.connected?
  end

  # Main entry point. Connects and logs in silently using $player.name.
  # Only shows UI if there is a name conflict (unless silent: true).
  def self.auto_connect(silent: false)
    return true if logged_in?

    unless NetworkClient.connect
      unless silent
        pbMessage(_INTL("Could not connect to the server.\nPlease check your connection."))
      end
      return false
    end

    _try_login($player.name, silent: silent)
  end

  # Kept so existing map events that call show_login_screen still work.
  def self.show_login_screen
    auto_connect
  end

  def self.logout
    NetworkClient.disconnect
    @username = nil
  end

  private

  # UUIDs that were accidentally shipped inside the game distribution and must
  # never be used — any player whose device_id.dat contains one of these will
  # silently get a fresh UUID so they don't share identity with other players.
  DISTRIBUTED_IDS = %w[6311022b-c0e0-4262-80e8-56889a92c8af].freeze

  def self._get_or_create_device_id
    return @device_id if @device_id

    # 1. Check the permanent AppData location first.
    id = _read_device_id(DEVICE_ID_PATH)
    if id
      @device_id = id
      puts "[Auth] device_id loaded from AppData"
      return @device_id
    end

    # 2. One-time migration: move legacy game-folder file to AppData.
    begin
      legacy = File.read(DEVICE_ID_LEGACY_PATH).strip rescue nil
      if legacy && legacy.length >= 10
        File.delete(DEVICE_ID_LEGACY_PATH) rescue nil
        unless DISTRIBUTED_IDS.include?(legacy)
          _write_device_id(DEVICE_ID_PATH, legacy)
          @device_id = legacy
          puts "[Auth] device_id migrated from game folder to AppData"
          return @device_id
        end
        puts "[Auth] Distributed ID in legacy file — regenerating"
      end
    rescue => e
      puts "[Auth] Legacy device_id read failed: #{e.message}"
    end

    # 3. Generate a fresh UUID and save to AppData.
    id = defined?(SecureRandom) ? SecureRandom.uuid : _uuid_fallback
    _write_device_id(DEVICE_ID_PATH, id)
    puts "[Auth] device_id created: #{id[0, 8]}..."
    @device_id = id
  end

  def self._read_device_id(path)
    content = File.read(path).strip rescue nil
    return nil unless content && content.length >= 10
    return nil if DISTRIBUTED_IDS.include?(content)
    content
  end

  def self._write_device_id(path, id)
    File.open(path, 'w') { |f| f.write(id) }
  rescue => e
    puts "[Auth] device_id save failed (session-only): #{e.message}"
  end

  def self._uuid_fallback
    hex = (0..31).map { rand(16).to_s(16) }.join
    "#{hex[0,8]}-#{hex[8,4]}-4#{hex[13,3]}-#{(8 + rand(4)).to_s(16)}#{hex[17,3]}-#{hex[20,12]}"
  end

  def self._try_login(name, silent: false)
    result    = nil
    device_id = _get_or_create_device_id
    NetworkClient.on('login_ok') { |d|
      @username = d['username']
      NetworkTokens.set(d['tokens'] || 0)
      NetworkTokens.daily_available = (d['daily_available'] == true)
      if d['time']
        t = d['time']
        NetworkTimeSync.apply(t['hour'].to_i, t['min'].to_i, t['wday'].to_i)
      end
      $PokemonGlobal.cosmetic_rank        = (d['cosmetic_rank']        || 0).to_i
      $PokemonGlobal.cosmetic_rank_active = (d['cosmetic_rank_active'] || 0).to_i
      result = :ok
    }
    NetworkClient.on('login_fail') { |d| result = d['message'] }

    NetworkClient.send_msg({ action: 'login', username: name, device_id: device_id, client_version: Settings::GAME_VERSION })

    300.times do
      Graphics.update; Input.update; NetworkClient.update
      break if result
    end

    NetworkClient.off('login_ok')
    NetworkClient.off('login_fail')

    if result == :ok
      # Register a one-time disconnect notification for this session so the
      # player sees a message if they drop mid-game instead of silently losing
      # connection with no feedback.
      NetworkClient.off('disconnected')
      NetworkClient.on('disconnected') { |_d|
        @username = nil
        puts "[Auth] Disconnected from server"
        pbMessage(_INTL("Lost connection to the server.\nYou have been disconnected."))
      }
      # Keep time_sync handler alive so ServerSync / ForceSync.Username work mid-session
      NetworkClient.off('time_sync')
      NetworkClient.on('time_sync') { |d|
        NetworkTimeSync.apply(d['hour'].to_i, d['min'].to_i, d['wday'].to_i)
      }
      NetworkOverworld.on_map_enter($game_map.map_id, $game_player.x, $game_player.y)
      # Refresh our world-leaderboard Pokédex totals on the server every login.
      NetworkClient.send_msg({ action: 'dex_sync', seen: $player.pokedex.seen_count, caught: $player.pokedex.owned_count }) rescue nil
      pbCheckDexCompletionAchievements rescue nil
      # Ask server if a world boss is currently active.
      NetworkClient.send_msg({ action: 'boss_status' })
      # Fetch current professor requests so NPC cache is ready.
      NetworkClient.send_msg({ action: 'professor_status', who: 'oak' })
      NetworkClient.send_msg({ action: 'professor_status', who: 'elm' })
      # Daily login spin wheel — show immediately if eligible.
      if NetworkTokens.daily_available
        wheel = Scene_DailyWheel.new
        wheel.main rescue nil
        # Scene is now fully disposed — safe to call pbMessage with no z-order conflict.
        r = wheel.result
        if r && !r['error']
          if r['item_id']
            sym  = r['item_id'].to_s.upcase.to_sym rescue nil
            name = (sym && GameData::Item.exists?(sym)) ? GameData::Item.get(sym).name : r['item_id'].to_s
            pbMessage(_INTL("Daily Login Bonus!\nYou received a {1}!", name)) rescue nil
          elsif r['tokens'].to_i > 0
            t = r['tokens'].to_i
            pbMessage(_INTL("Daily Login Bonus!\nYou received +{1} Server Token{2}!", t, t == 1 ? '' : 's')) rescue nil
          end
        end
      end
      # Server checks our client_version against the latest GitHub release and
      # sends this once, shortly after login_ok, if we're behind. Registered
      # LAST — after the daily wheel and its reward dialog are fully done —
      # so this can never fire its own blocking pbMessage reentrantly from
      # inside another still-open blocking dialog. If the server's message
      # happens to arrive earlier (mid-wheel), it just waits harmlessly in
      # the queue since no callback is registered yet, and gets handled by
      # the very next ordinary frame update once we're back in the overworld.
      NetworkClient.off('update_available')
      NetworkClient.on('update_available') { |d| pbShowUpdateNotice(d) rescue nil }
      return true
    end

    return false if silent

    # Name conflict — ask the player to pick a different online nickname
    msg = result.is_a?(String) ? result : "Could not connect."
    pbMessage(_INTL("{1}\nPlease choose a different name for this session.", msg))
    new_name = pbEnterText(_INTL("Online nickname:"), 0, 12)
    return false if new_name.nil? || new_name.empty?

    _try_login(new_name)
  end
end

#-------------------------------------------------------------------------------
# Update notice — server compares our client_version (sent at login) against
# the latest GitHub release and sends this once if we're behind. Notify-only:
# no auto-download, just points the player at the release page in their browser.
#-------------------------------------------------------------------------------
def pbShowUpdateNotice(d)
  version = d['version'].to_s
  url     = d['url'].to_s
  notes   = d['notes'].to_s.strip
  msg = _INTL("A new version ({1}) of Echoes of Johto is available!", version)
  msg += "\n" + notes[0, 200] unless notes.empty?
  choice = pbMessage(msg, [_INTL("Open download page"), _INTL("Later")], 2)
  if choice == 0 && !url.empty?
    system("start \"\" \"#{url}\"")
  end
end
