#===============================================================================
# Card Trunk - PokéGear Tab
# Adds a :cards page (order 50, after Daycare) that lets the player view, move,
# and reorder their Triple Triad cards via a safe storage called the Trunk.
#
# Required graphics (Graphics/UI/Pokegear/):
#   icon_cards.png, icon_cards_f.png  ← already present
#   bg_cards.png, bg_cards_f.png      ← create these; falls back to bg_daycare
#===============================================================================

#===============================================================================
# Save-data: triad_trunk (separate TriadStorage from the active hand)
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :triad_trunk

  def triad_trunk
    @triad_trunk = TriadStorage.new if !@triad_trunk
    return @triad_trunk
  end
end

#===============================================================================
# Register tab
#===============================================================================
MenuHandlers.add(:pokegear_menu_gsc, :cards, {
  "suffix" => "cards",
  "order"  => 50,
})

#===============================================================================
# PokéGear page wiring
#===============================================================================
class PokemonPokegear_Scene
  # Background — falls back to bg_daycare when bg_cards doesn't exist yet
  alias cards_pbChangeBg pbChangeBg
  def pbChangeBg
    if @page_list[@page] == :cards
      path = "Graphics/UI/Pokegear/bg_cards"
      path += "_f" if $player.female? && pbResolveBitmap(path + "_f")
      @sprites["background"].setBitmap(
        pbResolveBitmap(path) ? path : "Graphics/UI/Pokegear/bg_daycare"
      )
      return
    end
    cards_pbChangeBg
  end

  # Page text: card counts
  alias cards_pbUpdateText pbUpdateText
  def pbUpdateText
    cards_pbUpdateText
    return if pbGetPageId != :cards
    hand  = $PokemonGlobal.triads.total_cards
    trunk = $PokemonGlobal.triad_trunk.total_cards
    pbDrawTextPositions(@sprites["overlay"].bitmap, [
      ["CARD TRUNK",                       Graphics.width - 18, 16, :right, Color.new(224, 248, 160), nil],
      [_INTL("Hand:  {1} cards",  hand),   20, 72, :left, @baseColor, @shadowColor],
      [_INTL("Trunk: {1} cards", trunk),   20, 96, :left, @baseColor, @shadowColor],
    ])
    @helpwindow.text = _INTL("Press A to manage cards.")
  end

  # Open trunk menu when player presses A on the cards page
  alias cards_pbPageControl pbPageControl
  def pbPageControl
    cards_pbPageControl
    return if pbGetPageId != :cards
    return if !Input.trigger?(Input::USE)
    pbPlayDecisionSE
    pbCardTrunkMenu
    drawPage(:cards)
  end

  #=============================================================================
  # Main trunk menu
  #=============================================================================
  def pbCardTrunkMenu
    loop do
      cmd = pbMessage(_INTL("What would you like to do?"), [
        _INTL("View Hand"),
        _INTL("Move to Trunk"),
        _INTL("Take from Trunk"),
        _INTL("Reorder Hand"),
        _INTL("Cancel"),
      ], -1)
      case cmd
      when 0 then pbViewCardStorage($PokemonGlobal.triads,       "hand")
      when 1 then pbTransferCards($PokemonGlobal.triads, $PokemonGlobal.triad_trunk, "hand",  "trunk")
      when 2 then pbTransferCards($PokemonGlobal.triad_trunk, $PokemonGlobal.triads, "trunk", "hand")
      when 3 then pbReorderCards
      else        break
      end
    end
  end

  #=============================================================================
  # View all cards in a storage with live card preview
  #=============================================================================
  def pbViewCardStorage(storage, label)
    if storage.empty?
      pbMessage(_INTL("The {1} has no cards.", label))
      return
    end
    cmds      = _triad_build_commands(storage) + [_INTL("BACK")]
    cmdwindow = _triad_make_cmdwindow(cmds)
    preview   = _triad_make_preview
    lastIndex = -1
    Graphics.frame_reset
    loop do
      Graphics.update; Input.update; pbUpdate
      cmdwindow.update
      if lastIndex != cmdwindow.index
        _triad_update_preview(preview, storage, cmdwindow.index)
        lastIndex = cmdwindow.index
      end
      break if Input.trigger?(Input::BACK)
      break if Input.trigger?(Input::USE) && cmdwindow.index >= storage.length
    end
    cmdwindow.dispose
    _triad_dispose_preview(preview)
    Graphics.frame_reset
  end

  #=============================================================================
  # Transfer cards from source storage to dest storage, one species at a time
  #=============================================================================
  def pbTransferCards(source, dest, source_label, dest_label)
    if source.empty?
      pbMessage(_INTL("The {1} has no cards.", source_label))
      return
    end
    loop do
      cmds      = _triad_build_commands(source) + [_INTL("DONE")]
      cmdwindow = _triad_make_cmdwindow(cmds)
      preview   = _triad_make_preview
      lastIndex = -1
      done      = false
      Graphics.frame_reset
      loop do
        Graphics.update; Input.update; pbUpdate
        cmdwindow.update
        if lastIndex != cmdwindow.index
          _triad_update_preview(preview, source, cmdwindow.index)
          lastIndex = cmdwindow.index
        end
        if Input.trigger?(Input::BACK)
          done = true; break
        elsif Input.trigger?(Input::USE)
          if cmdwindow.index >= source.length
            done = true; break
          end
          item = source.get_item(cmdwindow.index)
          name = GameData::Species.get(item).name
          max  = source.quantity(item)
          qty  = 1
          if max > 1
            cmdwindow.active = false; cmdwindow.update
            params = ChooseNumberParams.new
            params.setRange(1, max)
            params.setInitialValue(1)
            params.setCancelValue(0)
            qty = pbMessageChooseNumber(_INTL("Move how many {1} cards?", name), params)
            cmdwindow.active = true
          end
          if qty > 0
            if !dest.can_add?(item, qty)
              pbMessage(_INTL("No room in the {1}!", dest_label))
            else
              source.remove(item, qty)
              dest.add(item, qty)
              pbMessage(_INTL("Moved {1}x {2} to the {3}.", qty, name, dest_label))
              break  # refresh the list
            end
          end
        end
      end
      cmdwindow.dispose
      _triad_dispose_preview(preview)
      Graphics.frame_reset
      break if done || source.empty?
    end
  end

  #=============================================================================
  # Reorder the active hand by pick-and-swap.
  # Press A on a card to select it (shown with ">"), then A on a destination
  # to swap. Press B to deselect or exit.
  #=============================================================================
  def pbReorderCards
    hand = $PokemonGlobal.triads
    if hand.length < 2
      pbMessage(_INTL("Not enough cards to reorder."))
      return
    end
    cmds      = _triad_build_commands(hand) + [_INTL("DONE")]
    cmdwindow = _triad_make_cmdwindow(cmds)
    preview   = _triad_make_preview
    selected  = -1
    lastIndex = -1
    Graphics.frame_reset
    loop do
      Graphics.update; Input.update; pbUpdate
      cmdwindow.update
      if lastIndex != cmdwindow.index
        _triad_update_preview(preview, hand, cmdwindow.index)
        lastIndex = cmdwindow.index
      end
      if Input.trigger?(Input::BACK)
        if selected >= 0
          # Deselect without swapping
          selected = -1
          cmdwindow.commands = _triad_build_commands(hand) + [_INTL("DONE")]
        else
          break
        end
      elsif Input.trigger?(Input::USE)
        break if cmdwindow.index >= hand.length  # "DONE"
        if selected < 0
          # Pick up this card
          selected = cmdwindow.index
          cmds = _triad_build_commands(hand)
          cmds[selected] = "> " + cmds[selected]
          cmdwindow.commands = cmds + [_INTL("DONE")]
        else
          # Swap picked card with current position
          if selected != cmdwindow.index
            hand.items[selected], hand.items[cmdwindow.index] =
              hand.items[cmdwindow.index], hand.items[selected]
          end
          selected = -1
          cmdwindow.commands = _triad_build_commands(hand) + [_INTL("DONE")]
        end
      end
    end
    cmdwindow.dispose
    _triad_dispose_preview(preview)
    Graphics.frame_reset
  end

  #=============================================================================
  # Private helpers
  #=============================================================================
  private

  def _triad_build_commands(storage)
    cmds = []
    storage.length.times do |i|
      slot = storage[i]
      cmds.push(_INTL("{1} x{2}", GameData::Species.get(slot[0]).name, slot[1]))
    end
    return cmds
  end

  def _triad_make_cmdwindow(commands)
    w = Window_CommandPokemonEx.newWithSize(commands, 0, 0, Graphics.width / 2 + 28, Graphics.height)
    w.z           = 99999
    w.shadowColor = nil
    return w
  end

  def _triad_make_preview
    s       = Sprite.new
    s.x     = (Graphics.width / 2) + 76
    s.y     = (Graphics.height / 2) + 28
    s.z     = 99999
    return s
  end

  def _triad_update_preview(sprite, storage, index)
    sprite.bitmap&.dispose
    sprite.bitmap = nil
    return if index >= storage.length
    sprite.bitmap = TriadCard.new(storage.get_item(index)).createBitmap(1)
  end

  def _triad_dispose_preview(sprite)
    sprite.bitmap&.dispose
    sprite.dispose
  end
end
