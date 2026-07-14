#===============================================================================
# NetworkChatShop — Server Token shop for purchasable chat name effects.
#
# NPC script command:  NetworkChatShop.show_npc_dialogue
#
# Sells the 7 chat effects below for Settings::CHAT_EFFECT_TOKEN_COST Server
# Tokens each. These reuse the exact same cosmetic_rank bitmask as the free
# NPC-granted effects in 014_NetworkRanks.rb, just at bits 9-15 instead of
# 1-8, so ownership/toggling/rendering all work identically once bought.
# Already-owned effects are left off the shop list so a player can't rebuy one.
#===============================================================================

module NetworkChatShop
  # bit => display name. Must match the additions to RANK_NAMES in
  # 014_NetworkRanks.rb and RANK_NAMES in the server's handlers/rank.js.
  SHOP_EFFECTS = {
    9  => "Glitch",
    10 => "Blur & Clear",
    11 => "Letter Shake",
    12 => "Warp",
    13 => "Pastel Rainbow",
    14 => "Squish",
    15 => "Ripple",
  }.freeze

  def self.show_npc_dialogue
    unless NetworkAuth.logged_in?
      pbMessage(_INTL("You need to be online to browse the Chat Effect Shop."))
      return
    end

    loop do
      available = SHOP_EFFECTS.reject { |n, _| ($PokemonGlobal.cosmetic_rank & (1 << (n - 1))) != 0 }

      if available.empty?
        pbMessage(_INTL("\"You've already got every chat effect I sell! Nothing left for me to offer you.\""))
        return
      end

      cost = Settings::CHAT_EFFECT_TOKEN_COST
      commands = available.map { |_n, name| _INTL("{1} ({2} tokens)", name, cost) }
      commands << _INTL("Never mind")

      choice = pbMessage(_INTL("\"Welcome to the Chat Effect Shop! Everything here is {1} Server Tokens a pop.\nYou've got {2} tokens.\"", cost, NetworkTokens.balance),
                          commands, commands.length - 1)
      break if choice == commands.length - 1

      bit, name = available.to_a[choice]
      _buy_effect(bit, name, cost)
    end
  end

  def self._buy_effect(bit, name, cost)
    if NetworkTokens.balance < cost
      pbMessage(_INTL("Not enough tokens.\nYou have {1}, need {2}.", NetworkTokens.balance, cost))
      return
    end

    return unless pbConfirmMessage(_INTL("Buy the {1} chat effect for {2} Server Tokens?", name, cost))

    result = nil
    NetworkClient.on('chat_effect_bought') { |d| result = d }
    NetworkClient.on('chat_effect_error')  { |d| result = { '_err' => d['message'] } }
    NetworkClient.send_msg({ action: 'buy_chat_effect', rank_bit: bit })
    300.times { Graphics.update; Input.update; NetworkClient.update; break if result }
    NetworkClient.off('chat_effect_bought'); NetworkClient.off('chat_effect_error')

    if result.is_a?(Hash) && !result['_err']
      rank_bit = 1 << (bit - 1)
      $PokemonGlobal.cosmetic_rank        |= rank_bit
      $PokemonGlobal.cosmetic_rank_active |= rank_bit   # new effects default to ON
      NetworkTokens.set(result['new_tokens'])
      Game.save(safe: true) rescue nil
      pbMessage(_INTL("✨ Your chat name has been upgraded with the {1} effect!", name))
    else
      pbMessage(_INTL("Purchase failed: {1}",
                      result.is_a?(Hash) ? (result['_err'] || "No response.") : "No response."))
    end
  end
end
