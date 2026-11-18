#===============================================================================
# Server messages wait while a minigame is on screen.
# Server events are handled in NetworkClient.update, and some of their
# handlers show a message straight away (a legendary boss or Mini Boss
# appearing, Lost connection, ...). Minigames that keep the connection going
# run NetworkClient.update themselves (Pinball for its high scores, the
# Jackpot Machines, TCG online duels), so the message opened under the
# minigame's screen and the game stopped on a text box nobody could see.
# Now, while one of those minigames is running (HeldServerMessages.during, or
# a TCG duel), a plain message (no choices) from a server event is held and
# shown once the player is back in the overworld. Messages with choices still
# show straight away, so nothing gets answered for the player.
#===============================================================================
module HeldServerMessages
  MAX_HELD = 10

  @queue = []
  @dispatching = false
  @minigames = 0

  class << self
    attr_reader :queue

    # while the block runs, server messages are held
    def during
      @minigames += 1
      yield
    ensure
      @minigames -= 1
    end

    def minigame?
      return true if @minigames > 0
      defined?(TCG) && TCG.respond_to?(:dueling?) && TCG.dueling?
    end

    # true while server events are being handled
    def dispatching
      was = @dispatching
      @dispatching = true
      yield
    ensure
      @dispatching = was
    end

    def dispatching?; @dispatching; end
    def hold?;        @dispatching && minigame?; end

    def hold(message)
      @queue << message
      @queue.shift while @queue.size > MAX_HELD
    end

    # the player is walking around: nothing else on screen
    def overworld_free?
      return false if minigame?
      return false unless $scene.is_a?(Scene_Map) && $game_temp && $game_player
      return false if $game_temp.in_menu || $game_temp.in_battle || $game_temp.message_window_showing
      return false if $game_player.move_route_forcing || pbMapInterpreterRunning?
      true
    end
  end
end

class << NetworkClient
  alias _held_messages_update update unless method_defined?(:_held_messages_update)
  def update
    HeldServerMessages.dispatching { _held_messages_update }
  end
end

alias _held_messages_pbMessage pbMessage unless defined?(_held_messages_pbMessage)
def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  if commands.nil? && block.nil? && HeldServerMessages.hold?
    HeldServerMessages.hold(message)
    return 0
  end
  _held_messages_pbMessage(message, commands, cmdIfCancel, skin, defaultCmd, &block)
end

# the minigames that run NetworkClient.update
alias _held_messages_pinball pbPokemonPinball unless defined?(_held_messages_pinball)
def pbPokemonPinball(*args)
  HeldServerMessages.during { _held_messages_pinball(*args) }
end

alias _held_messages_jackpot pbJackpotMachine unless defined?(_held_messages_jackpot)
def pbJackpotMachine(*args)
  HeldServerMessages.during { _held_messages_jackpot(*args) }
end

# one held message a frame, once the player is free again
EventHandlers.add(:on_frame_update, :show_held_server_messages, proc {
  next if HeldServerMessages.queue.empty? || HeldServerMessages.dispatching?
  next unless HeldServerMessages.overworld_free?
  pbMessage(HeldServerMessages.queue.shift)
})
