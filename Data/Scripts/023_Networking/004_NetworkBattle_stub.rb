#===============================================================================
# NetworkBattle — stub for future PvP battle implementation.
#
# Planned flow:
#   1. Player A calls NetworkBattle.challenge("PlayerB")
#   2. Server sends battle_request to Player B
#   3. Both accept -> server generates shared RNG seed (like VMS.sync_seed)
#      and sends it to both clients so battle RNG is deterministic on both ends
#   4. Each turn: both clients send their chosen move, server broadcasts
#      battle_turn_result when both moves are received
#   5. battle_end event fires when a winner is determined
#===============================================================================

module NetworkBattle
  def self.challenge(target_username)
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be connected online to battle."))
      return
    end
    pbMessage(_INTL("Online battles are coming soon!"))
  end
end
