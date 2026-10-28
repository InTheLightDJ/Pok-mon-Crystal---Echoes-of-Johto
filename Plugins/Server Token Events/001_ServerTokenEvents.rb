#===============================================================================
# Server Tokens in map events.
# The server keeps the balance, so spending goes through it (the server's
# spend_tokens action in handlers/tokens.js); changing NetworkTokens locally
# would be undone by the next sync.
#
#   Conditional Branch > Script:   pbServerTokens >= 100
#   Script:                         pbSpendServerTokens(100)
#
# pbSpendServerTokens returns true if the tokens were taken, so it can be the
# Conditional Branch itself:
#   Conditional Branch > Script:   pbSpendServerTokens(100, "Prize desk")
# If it fails (offline, not enough tokens, no answer) it says why and
# returns false.
#===============================================================================

# The player's Server Tokens (0 when not logged in).
def pbServerTokens
  return 0 unless defined?(NetworkAuth) && NetworkAuth.logged_in?
  NetworkTokens.balance
end

def pbSpendServerTokens(amount, reason = "event")
  amount = amount.to_i
  return true if amount <= 0
  unless defined?(NetworkAuth) && NetworkAuth.logged_in?
    pbMessage(_INTL("You need to be online to use Server Tokens."))
    return false
  end
  if NetworkTokens.balance < amount
    pbMessage(_INTL("Not enough Server Tokens.\nYou have {1}, need {2}.", NetworkTokens.balance, amount))
    return false
  end
  result = nil
  NetworkClient.on('spend_tokens_ok')    { |d| result = d }
  NetworkClient.on('spend_tokens_error') { |d| result = { '_err' => d['message'] } }
  NetworkClient.send_msg({ action: 'spend_tokens', amount: amount, reason: reason.to_s })
  300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
  NetworkClient.off('spend_tokens_ok'); NetworkClient.off('spend_tokens_error')
  if result.is_a?(Hash) && !result['_err']
    NetworkTokens.set(result['new_tokens'])
    return true
  end
  pbMessage(_INTL("Couldn't use Server Tokens: {1}",
                  result.is_a?(Hash) ? result['_err'] : _INTL("No response.")))
  false
end
