#===============================================================================
# Auto Reconnect - a dropped connection comes back by itself.
# The server is reached through a Cloudflare tunnel, and the tunnel's own
# connection to Cloudflare drops now and then (a few times a day), taking
# everyone's game connection with it. The game used to say "Lost connection
# to the server" and stay offline until the player visited a PC.
# Now, once the player is back on the map, the game reconnects and logs in
# again as the same player by itself (RETRY_AFTER: seconds after the drop),
# without a message. The login says resume, so the server closes the old
# session if it hasn't noticed it's gone yet (handlers/auth.js). Only if
# every try fails does the player get the "Lost connection" message.
# Not after the idle timer's disconnect, a kick or a ban, or logging out.
#===============================================================================
module AutoReconnect
  RETRY_AFTER    = [1, 3, 6, 10, 20, 30, 45, 60, 90, 120]   # seconds after the drop
  RELAUNCH_AFTER = 3   # failed tries before starting the tunnel helper again

  @online_as  = nil     # the name this game was logged in as
  @lost_at    = nil
  @tries      = 0
  @deliberate = false   # disconnected on purpose (idle timer, logout, kicked): stay offline
  @resuming   = false

  class << self
    attr_reader :resuming
    attr_accessor :deliberate

    def deliberate?; @deliberate; end

    # the player is free on the map: no event, message, menu or battle
    def safe?
      return false unless $scene.is_a?(Scene_Map) && $game_temp && $game_player
      return false if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
      return false if $game_player.move_route_forcing || pbMapInterpreterRunning?
      return false if defined?(TCG) && TCG.respond_to?(:dueling?) && TCG.dueling?
      true
    end

    def frame
      if NetworkAuth.logged_in?
        @online_as = NetworkAuth.username
        @lost_at = nil
        @tries = 0
        return
      end
      return unless @online_as
      if deliberate?
        give_up(nil)
        return
      end
      @lost_at ||= System.uptime
      return unless safe?
      return if System.uptime - @lost_at < RETRY_AFTER[@tries]
      @tries += 1
      return if reconnect
      give_up(_INTL("Lost connection to the server.\nVisit a PC to reconnect.")) if @tries >= RETRY_AFTER.size
    end

    def reconnect
      name = @online_as
      puts "[AutoReconnect] try #{@tries} as #{name}"
      if @tries > RELAUNCH_AFTER && NetworkClient.instance_variable_get(:@tunnel_launched)
        NetworkClient.instance_variable_set(:@tunnel_launched, false)   # the helper may have stopped
      end
      @resuming = true
      return false unless NetworkClient.connect
      ok = NetworkAuth._try_login(name, silent: true)
      ok ||= NetworkAuth._try_login($player.name, silent: true) if $player && $player.name != name && NetworkClient.connected?
      NetworkClient.disconnect unless ok
      puts "[AutoReconnect] #{ok ? 'back online' : 'failed'}"
      ok
    rescue StandardError => e
      puts "[AutoReconnect] #{e.class}: #{e.message}"
      false
    ensure
      @resuming = false
    end

    def give_up(message)
      @online_as = nil
      @lost_at = nil
      @tries = 0
      pbMessage(message) if message
    end
  end
end

class << NetworkClient
  # the login of a reconnect says resume
  alias _auto_reconnect_send_msg send_msg unless method_defined?(:_auto_reconnect_send_msg)
  def send_msg(hash)
    hash = hash.merge(resume: true) if AutoReconnect.resuming && hash[:action] == 'login'
    _auto_reconnect_send_msg(hash)
  end

  # the game closing the connection itself (the idle timer, logging out) is
  # on purpose; a drop comes through _handle_disconnect instead
  alias _auto_reconnect_disconnect disconnect unless method_defined?(:_auto_reconnect_disconnect)
  def disconnect
    AutoReconnect.deliberate = true if connected? && !AutoReconnect.resuming
    _auto_reconnect_disconnect
  end
end

# a drop doesn't say "Lost connection" right away any more (AutoReconnect
# says it if it can't get back)
class << NetworkAuth
  alias _auto_reconnect_try_login _try_login unless method_defined?(:_auto_reconnect_try_login)
  def _try_login(name, silent: false)
    ok = _auto_reconnect_try_login(name, silent: silent)
    if ok == true
      AutoReconnect.deliberate = false
      NetworkClient.off('disconnected')
      NetworkClient.on('disconnected') do |_d|
        NetworkAuth.instance_variable_set(:@username, nil)
        puts "[Auth] Disconnected from server"
      end
    end
    ok
  end
end

# kicked or banned by a moderator: stay offline
NetworkClient.on('kicked') do |d|
  AutoReconnect.deliberate = true
  pbMessage(d['reason'].to_s) unless d['reason'].to_s.empty?
end

EventHandlers.add(:on_frame_update, :auto_reconnect, proc { AutoReconnect.frame })
