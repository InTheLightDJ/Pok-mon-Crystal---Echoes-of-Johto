#===============================================================================
# Coins go up to 999,999 (was Settings::MAX_COINS = 99,999 in
# Data/Scripts/001_Settings.rb), so a 99,999 jackpot doesn't fill the Coin Case.
# Everything that checks the limit reads Settings::MAX_COINS when it runs, so
# changing it here is enough. The slot machines' credit/payout counters had
# room for 5 digits: from 100,000 they show 6 narrower digits in the same space.
#===============================================================================
module Settings
  remove_const(:MAX_COINS) if const_defined?(:MAX_COINS, false)
  MAX_COINS = 999_999
end

class SlotMachineScore
  def refresh
    self.bitmap.clear
    digits = @score >= 100_000 ? 6 : 5
    w = 80 / digits
    digits.times do |i|
      digit = (@score / (10**i)) % 10 # Least significant digit first
      self.bitmap.stretch_blt(Rect.new(80 - w * (i + 1), 0, w, 16), @numbers.bitmap, Rect.new(digit * 16, 0, 16, 16))
    end
  end
end
