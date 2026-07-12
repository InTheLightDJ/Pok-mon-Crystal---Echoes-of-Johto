#===============================================================================
# NetworkIdleTimer — disconnects AFK players after 25 minutes of no input.
# Resets on any directional movement, confirm, or cancel press.
# Shows a 1-minute warning before kicking.
#===============================================================================

module NetworkIdleTimer
  WARN_SECS = 24 * 60   # warn at 24 min
  KICK_SECS = 25 * 60   # disconnect at 25 min

  @@last_activity = Time.now
  @@warned        = false
  @@kicking       = false

  def self.reset
    @@last_activity = Time.now
    @@warned        = false
    @@kicking       = false
  end

  def self.update
    return unless NetworkAuth.logged_in?

    # Any input resets the timer
    if Input.dir4 != 0 || Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
      reset
      return
    end

    idle_secs = Time.now - @@last_activity

    if !@@warned && idle_secs >= WARN_SECS
      @@warned = true
      pbMessage(_INTL("You've been idle for 24 minutes!\nYou'll be disconnected in 1 minute if you don't move."))
    end

    if !@@kicking && idle_secs >= KICK_SECS
      @@kicking = true
      NetworkClient.disconnect
      pbMessage(_INTL("You were disconnected due to inactivity.\nVisit a PC to reconnect."))
    end
  end
end

EventHandlers.add(:on_frame_update, :idle_timer_update,
  proc { NetworkIdleTimer.update }
)

# Reset the timer each time the player logs in
NetworkClient.on('login_ok') do |_d|
  NetworkIdleTimer.reset
end
