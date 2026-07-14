#===============================================================================
# NetworkRanks — Chat cosmetic rank unlocks
#
# NPC script command: pbGiveRank(1)  →  unlocks Glow
#                     pbGiveRank(2)  →  unlocks Shimmer
#                     pbGiveRank(3)  →  unlocks Pop (name bounces on send)
#
# Ranks are stored as a bitmask in save data (PokemonGlobal.cosmetic_rank) and
# persisted server-side in the SQLite DB.  The server is authoritative; the
# local value is synced from login_ok on every session start.
#===============================================================================

class PokemonGlobalMetadata
  def cosmetic_rank
    @cosmetic_rank ||= 0
  end

  def cosmetic_rank=(val)
    @cosmetic_rank = val.to_i
  end

  def cosmetic_rank_active
    @cosmetic_rank_active ||= 0
  end

  def cosmetic_rank_active=(val)
    @cosmetic_rank_active = val.to_i
  end
end

RANK_NAMES = { 1 => "Glow", 2 => "Shimmer", 3 => "Pop", 4 => "Paint Wave",
               5 => "Violet Wave", 6 => "Solar Wave", 7 => "Ocean Wave", 8 => "Shadow Wave",
               # Bits 9-15 are sold (not free-granted) by the Chat Effect Shop —
               # see 030_NetworkChatShop.rb. Listed here too since RANK_NAMES is
               # also used to label them in "you already have..." messages.
               9 => "Glitch", 10 => "Blur & Clear", 11 => "Letter Shake", 12 => "Warp",
               13 => "Pastel Rainbow", 14 => "Squish", 15 => "Ripple" }

# Called from NPC events:  pbGiveRank(1) through pbGiveRank(8)
def pbGiveRank(n)
  n = n.to_i
  return unless (1..8).include?(n)
  bit = 1 << (n - 1)
  if ($PokemonGlobal.cosmetic_rank & bit) != 0
    pbMessage(_INTL("You already have the {1} chat effect!", RANK_NAMES[n]))
    return
  end
  $PokemonGlobal.cosmetic_rank        |= bit
  $PokemonGlobal.cosmetic_rank_active |= bit  # new effects default to ON
  if NetworkAuth.logged_in?
    NetworkClient.send_msg({ action: 'unlock_rank', rank_bit: n })
    NetworkClient.on('rank_granted') { |d|
      $PokemonGlobal.cosmetic_rank_active = (d['active_rank'] || $PokemonGlobal.cosmetic_rank_active).to_i
      NetworkClient.off('rank_granted')
    }
  end
  pbMessage(_INTL("✨ Your chat name has been upgraded with the {1} effect!", RANK_NAMES[n]))
end
