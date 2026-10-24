#===============================================================================
# NetworkIdleTimer — disconnects AFK players after 25 minutes of no input.
# Resets on any button press anywhere (overworld, menus, battles, card
# duels), and never counts time spent in a battle or a Pokémon TCG duel, so a
# long boss battle or duel can't get the player kicked when it ends.
# Shows a 1-minute warning before kicking (on the overworld only).
#===============================================================================

module NetworkIdleTimer
  WARN_SECS = 24 * 60   # warn at 24 min
  KICK_SECS = 25 * 60   # disconnect at 25 min

  # buttons that count as activity (directions are checked with Input.dir4)
  ACTIVITY_BUTTONS = [Input::USE, Input::BACK, Input::ACTION, Input::SPECIAL,
                      Input::AUX1, Input::AUX2]

  @@last_activity = Time.now
  @@warned        = false
  @@kicking       = false

  def self.reset
    @@last_activity = Time.now
    @@warned        = false
    @@kicking       = false
  end

  # in a Pokémon battle (wild, trainer, boss, network) or a Pokémon TCG duel
  def self.in_battle?
    return true if $game_temp && $game_temp.in_battle
    return true if defined?(TCG) && TCG.respond_to?(:dueling?) && TCG.dueling?
    false
  end

  def self.input_active?
    return true if Input.dir4 != 0
    ACTIVITY_BUTTONS.any? { |b| Input.press?(b) }
  end

  # called on every screen update, in every scene
  def self.track_activity
    reset if in_battle? || input_active?
  end

  # overworld only: warning message and disconnect
  def self.update
    return unless NetworkAuth.logged_in?
    return if in_battle?

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

# watch input in every scene (battles, duels and menus included), not only
# while the overworld map updates
module Graphics
  class << Graphics
    alias idle_timer_update update unless method_defined?(:idle_timer_update)
    def update
      idle_timer_update
      NetworkIdleTimer.track_activity
    end
  end
end

EventHandlers.add(:on_frame_update, :idle_timer_update,
  proc { NetworkIdleTimer.update }
)

# a battle that just ended restarts the 25 minutes
EventHandlers.add(:on_end_battle, :idle_timer_reset,
  proc { |*_args| NetworkIdleTimer.reset }
)

# Reset the timer each time the player logs in
NetworkClient.on('login_ok') do |_d|
  NetworkIdleTimer.reset
end
