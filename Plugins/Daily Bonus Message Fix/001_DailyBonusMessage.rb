#===============================================================================
# Daily login bonus: "Daily Login Bonus! You received ..." waits for the
# overworld.
# NetworkAuth._try_login (Data/Scripts/023_Networking/002_NetworkAuth.rb)
# showed it right after the wheel, still inside the login: on Continue that's
# before the map is up, just as the chat window (Edge) opens and takes focus,
# and the message box could freeze blank. Now the wheel hands its result here
# instead (the login sees no result and shows nothing), and it's shown once
# the player is back in normal overworld control and the chat window has had
# MESSAGE_DELAY seconds to open - the same way the update notice waits.
#===============================================================================
module DailyBonusMessage
  MESSAGE_DELAY = 3.0   # seconds in the overworld before the message

  @pending = nil
  @since   = nil
  class << self
    attr_reader :pending

    def pending=(result)
      @pending = result
      @since = nil
    end

    # true once the overworld has been free for MESSAGE_DELAY seconds
    def ready?
      @since ||= System.uptime
      System.uptime - @since >= MESSAGE_DELAY
    end

    def show(r)
      if r['item_id']
        sym  = r['item_id'].to_s.upcase.to_sym rescue nil
        name = (sym && GameData::Item.exists?(sym)) ? GameData::Item.get(sym).name : r['item_id'].to_s
        pbMessage(_INTL("Daily Login Bonus!\nYou received a {1}!", name))
      elsif r['tokens'].to_i > 0
        t = r['tokens'].to_i
        pbMessage(_INTL("Daily Login Bonus!\nYou received +{1} Server Token{2}!", t, t == 1 ? '' : 's'))
      end
    end
  end
end

class Scene_DailyWheel
  alias _bonus_msg_main main unless method_defined?(:_bonus_msg_main)
  def main
    _bonus_msg_main
    DailyBonusMessage.pending = @result if @result && !@result['error']
    @result = nil
  end
end

EventHandlers.add(:on_frame_update, :show_daily_bonus_message, proc {
  next unless DailyBonusMessage.pending
  next unless $scene.is_a?(Scene_Map)
  next if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
  next if $game_player.move_route_forcing || pbMapInterpreterRunning?
  next unless DailyBonusMessage.ready?
  r = DailyBonusMessage.pending
  DailyBonusMessage.pending = nil
  DailyBonusMessage.show(r) rescue nil
})
