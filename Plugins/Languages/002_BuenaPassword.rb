#===============================================================================
# Buena's Password: the radio says the word of the day as a species name in the
# current language, so it matches the translated answer list at the Radio Tower
# (the answer is checked by list position, so the word itself stays English).
# Same show as Data/Scripts/016_UI/010_UI_RadioChannel.rb, re-registered.
#===============================================================================
def pbBuenaPasswordDisplay(word)
  species = GameData::Species.try_get(word.to_sym)
  return species ? species.name.upcase : word
end

RadioHandlers.add(:radio_show, :buenas_password, {
  "name"      => _INTL("Buena's Password"),
  "channel"   => Buena::CHANNEL,
  "condition" => proc {
    time = pbGetTimeNow
    next time.hour >= Buena::START_HOUR && time.hour < Buena::END_HOUR
  },
  "show"      => proc { |window|
    begin
      pbBGMPlay(Buena::BGM_NAME, 100, 100)
    rescue
    end
    word = pbBuenaPasswordDisplay(pbBuenaPasswordOfTheDay)
    intro    = ["Buena : BUENA'S PASSWORD! Live from the RADIO TOWER!"]
    looptext = [
      _INTL("Good evening, listeners!"),
      _INTL("Tonight's password is... {1}!", word),
      _INTL("That's right-{1}! Don't forget it!", word),
      _INTL("Come tell me on 2F of the Radio Tower to earn points!"),
      _INTL("One prize entry per day-see you soon!")
    ]
    next pbGetRadioFormatLine(window, looptext, intro)
  }
})
