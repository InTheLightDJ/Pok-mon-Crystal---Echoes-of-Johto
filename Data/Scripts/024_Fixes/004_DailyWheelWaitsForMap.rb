#===============================================================================
# By InTheLight
# Daily login wheel: it waits for the overworld.
# NetworkAuth._try_login (Data/Scripts/023_Networking/002_NetworkAuth.rb) opened
# Scene_DailyWheel right after logging in. On Continue that's before the map is
# up, while the screen is still frozen black for the change of scene: the wheel
# ran (waiting for Enter) but couldn't be seen, so the game looked stuck on a
# black screen until the player happened to press Enter twice.
# Now the login only notes that a spin is waiting, and the wheel opens once the
# player is on the map with nothing else going on (WHEEL_DELAY seconds later).
# Its prize message still waits as before (001_DailyBonusMessageFix.rb).
#===============================================================================
module DailyWheelWait
  WHEEL_DELAY = 1.0   # seconds on the map before the wheel

  @pending = false
  @running = false
  @since   = nil
  class << self
    attr_accessor :pending, :running

    def ready?
      @since ||= System.unscaled_uptime
      System.unscaled_uptime - @since >= WHEEL_DELAY
    end

    def reset_wait; @since = nil; end
  end
end

class Scene_DailyWheel
  alias _wheel_wait_main main unless method_defined?(:_wheel_wait_main)
  def main
    return _wheel_wait_main if DailyWheelWait.running
    DailyWheelWait.pending = true     # (the login sees no result and shows nothing)
    DailyWheelWait.reset_wait
    @result = nil
  end
end

EventHandlers.add(:on_frame_update, :daily_wheel_waits_for_map, proc {
  next unless DailyWheelWait.pending
  next unless $scene.is_a?(Scene_Map)
  next if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
  next if $game_temp.player_transferring || $game_player.move_route_forcing || pbMapInterpreterRunning?
  next unless DailyWheelWait.ready?
  DailyWheelWait.pending = false
  next unless NetworkAuth.logged_in? && NetworkTokens.daily_available
  DailyWheelWait.running = true
  begin
    Scene_DailyWheel.new.main
  rescue StandardError => e
    echoln("[DailyWheel] #{e.message}") rescue nil
  ensure
    DailyWheelWait.running = false
  end
})
