#===============================================================================
# The regular Game Corner machine (Data/Scripts/017_Minigames/
# 003_Minigame_SlotMachine.rb) without the Green 7 bonus messages: the green
# reels show the bonus is on, so "The reels shimmer green!", "So close! +1
# bonus spin!" and "The Green 7 bonus is over!" are skipped. The Egg prize
# message stays.
#===============================================================================
class SlotMachineScene
  private

  def pbMessage(text, *args, &block)
    return 0 if green7_status_message?(text)
    super
  end

  def green7_status_message?(text)
    n = @green7_spins
    [_INTL("The reels shimmer green!\nYou have {1} Green 7 spins!", n),
     _INTL("So close! +1 bonus spin! {1} spins left!", n),
     _INTL("The Green 7 bonus is over!")].include?(text)
  end
end
