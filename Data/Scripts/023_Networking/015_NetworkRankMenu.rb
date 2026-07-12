#===============================================================================
# Chat cosmetic rank toggles — appear inside the Options menu once unlocked.
#
# One EnumOption entry per effect (Glow / Shimmer / Pop), each conditionally
# visible: only shown when the player owns that rank bit.  Left/right cycles
# On <-> Off and immediately syncs with the server if online.
#
# Each entry is registered via a helper method so that n and bit are bound to
# a fresh method scope per call — avoiding the Ruby closure capture issue where
# all procs in an `each` loop would otherwise share the same variable binding.
#===============================================================================

def pbRegisterChatEffect(n)
  bit = 1 << (n - 1)
  MenuHandlers.add(:options_menu, :"chat_effect_#{n}", {
    "name"        => _INTL("Chat {1}", RANK_NAMES[n]),
    "order"       => 76 + n,   # 77, 78, 79  — just after Chat Sounds (76)
    "type"        => EnumOption,
    "parameters"  => [_INTL("On"), _INTL("Off")],
    "description" => _INTL("Toggle the {1} name effect in chat.", RANK_NAMES[n]),
    "condition"   => proc { $PokemonGlobal && ($PokemonGlobal.cosmetic_rank & bit) != 0 },
    "get_proc"    => proc {
      next (($PokemonGlobal.cosmetic_rank_active & bit) != 0) ? 0 : 1
    },
    "set_proc"    => proc { |value, _scene|
      enable = (value == 0)
      if enable
        $PokemonGlobal.cosmetic_rank_active |= bit
      else
        $PokemonGlobal.cosmetic_rank_active &= ~bit
      end
      if NetworkAuth.logged_in?
        NetworkClient.send_msg({ action: 'toggle_rank', rank_bit: n, active: enable })
      end
    }
  })
end

pbRegisterChatEffect(1)
pbRegisterChatEffect(2)
pbRegisterChatEffect(3)
pbRegisterChatEffect(4)
pbRegisterChatEffect(5)
pbRegisterChatEffect(6)
pbRegisterChatEffect(7)
pbRegisterChatEffect(8)
