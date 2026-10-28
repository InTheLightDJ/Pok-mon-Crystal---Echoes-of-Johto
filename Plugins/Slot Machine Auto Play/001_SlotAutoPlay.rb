#===============================================================================
# Auto play for the Game Corner slot machine
# (Data/Scripts/017_Minigames/003_Minigame_SlotMachine.rb).
# Hold A (Enter): after AUTO_HOLD seconds the machine bets 3 Coins, spins,
# and stops each reel at a random moment in a short window. Let go of A to
# play normally again. Messages (Green 7s etc.) still need a press.
# It works by giving the machine the button presses a player would make:
# the scene's update (run every frame after Input.update) picks this frame's
# press, and Input.trigger? reports it until the next Input.update.
#===============================================================================
module SlotAutoPlay
  AUTO_HOLD = 0.5   # seconds A is held before auto play starts
  STOP_MIN  = 0.4   # each reel stops STOP_MIN..STOP_MAX seconds after the last
  STOP_MAX  = 1.0

  @press = nil
  class << self
    attr_accessor :press
  end
end

module Input
  class << self
    alias _slot_auto_update update
    def update
      SlotAutoPlay.press = nil
      _slot_auto_update
    end

    alias _slot_auto_trigger? trigger?
    def trigger?(button)
      return true if SlotAutoPlay.press && button == SlotAutoPlay.press
      _slot_auto_trigger?(button)
    end
  end
end

class SlotMachineScene
  alias _slot_auto_scene_update update
  def update
    _slot_auto_scene_update
    slot_auto_play
  end

  def slot_auto_play
    now = System.uptime
    if !Input.press?(Input::USE)
      @auto_held_since = nil
      @auto_stop_at = nil
      return
    end
    @auto_held_since ||= now
    return if now - @auto_held_since < SlotAutoPlay::AUTO_HOLD
    if @gameRunning
      @auto_stop_at ||= now + SlotAutoPlay::STOP_MIN + rand * (SlotAutoPlay::STOP_MAX - SlotAutoPlay::STOP_MIN)
      if now >= @auto_stop_at
        SlotAutoPlay.press = Input::USE   # stops the next reel
        @auto_stop_at = nil
      end
    elsif @gameEnd
      SlotAutoPlay.press = Input::USE     # skips the payout count
    else
      @auto_stop_at = nil
      # bet a coin a frame; 3 coins (or the last coins) start the spin
      SlotAutoPlay.press = Input::DOWN if @wager < 3 && @sprites["credit"].score > 0
    end
  end
end
