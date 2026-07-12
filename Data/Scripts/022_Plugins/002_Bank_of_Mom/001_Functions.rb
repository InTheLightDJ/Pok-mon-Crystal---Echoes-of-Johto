#===============================================================================
# Bank of Mom - By Vendily.
# Ported to Essentials GBC by Xaveriux.
#===============================================================================
# This script adds in the Bank of Mom Feature from GSC or HGSS, where
#  the player's mother will save money and occasionally buy items.
# The mom attempts to buy an item after the end of every battle, if she can
#  afford one of the MOM_FIXED_ITEMS or MOM_RANDOM_ITEMS.
# If she buys an item, she will call the player after the battle ends.
#===============================================================================
# Some neat details.
#  - The mom can save 1/4, 1/2 or all the money the player wins in battle.
#     This is set by the player. This does not affect earnings from Pay Day.
#  - pbMomManageBank allows the player to withdraw, deposit, or change the
#     amount saved, or cancel saving altogether.
#  - The mom still spends money even if the player is not saving anymore.
#  - The mom defaults to not saving any money.
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :mom_saving
  attr_writer :mom_item_index
  
  def mom_saving
    return (@mom_saving || 0)
  end
  
  def mom_item_index
    return (@mom_item_index || 0)
  end
  
  def mom_money
    return (@mom_money || 0)
  end

  def mom_money=(value)
    validate value => Integer
    @mom_money = value.clamp(0, Settings::MAX_MOM_MONEY)
  end
end

# type 0 == regular item. More for convience's sake 
def pbMomBoughtMoneyCall(type = 0)
  pbMessage(_INTL("......\\wt[5] ......"))
  pbMessage(_INTL("Hi, {1}! How are you?\\1", $player.name))
  case type
  when 0
    pbMessage(_INTL("I found a useful item shopping, so\\1"))
  end
  pbMessage(_INTL("I bought it with your money. Sorry!\\1"))
  case type
  when 0
    pbMessage(_INTL("It's in your PC. You'll like it!"))
  end
  pbMessage(_INTL("Click!\\wt[10]\\n......\\wt[5] ......"))
end

def pbMomManageBank
  commands = [_INTL("Withdraw"), _INTL("Deposit"), _INTL("Change"), _INTL("Cancel")]
  cmd = 0
  loop do
    cmd = pbMessage(_INTL("\\G\\MGWhat do you want to do?"), commands, -1, nil, cmd)
    case cmd
    when 0 # Withdraw
      params = ChooseNumberParams.new
      params.setRange(0, $PokemonGlobal.mom_money)
      params.setDefaultValue(0)
      newval = pbMessageChooseNumber(
        _INTL("\\G\\MGHow much do you want to take?"), params
      )
      if newval == 0
        next
      elsif (newval + $player.money) > Settings::MAX_MONEY
        pbMessage(_INTL("\\G\\MGYou can't take that much.\\1"))
      else
        pbSEPlay("Mart buy item")
        $player.money += newval
        $PokemonGlobal.mom_money -= newval
        pbMessage(_INTL("\\G\\MG{1}, don't give up!\\1", $player.name))
      end
    when 1 # Deposit
      params = ChooseNumberParams.new
      params.setRange(0, $player.money)
      params.setDefaultValue(0)
      newval = pbMessageChooseNumber(
        _INTL("\\G\\MGHow much do you want to save?"), params
      )
      if newval == 0
        next
      elsif (newval + $PokemonGlobal.mom_money) > Settings::MAX_MOM_MONEY
        pbMessage(_INTL("\\G\\MGYou can't save that much.\\1"))
      else
        pbSEPlay("Mart buy item")
        $player.money -= newval
        $PokemonGlobal.mom_money += newval
        pbMessage(_INTL("\\G\\MGYour money's safe here!\\1"))
      end
    when 2 # Start/Stop Saving
      save_commands = [_INTL("Stop Saving"), _INTL("Save Some"), _INTL("Save Half"), _INTL("Save All")]
      save_texts = [_INTL("\\G\\MGI'm not saving any money.\\nDo you want to save some money?"),
                   _INTL("\\G\\MGI'm saving some of your money.\\nDo you want to save some money?"),
                   _INTL("\\G\\MGI'm saving half of your money.\\nDo you want to save some money?"),
                   _INTL("\\G\\MGI'm saving all of your money.\\nDo you want to save some money?")]
      save_cmd = $PokemonGlobal.mom_saving
      save_cmd = pbMessage(save_texts[save_cmd], save_commands, save_cmd + 1, nil, save_cmd)
      $PokemonGlobal.mom_saving = save_cmd
      if $PokemonGlobal.mom_saving > 0
        pbMessage(_INTL("\\G\\MGOK, I'll save your money. Trust me!\\1"))
      else
        pbMessage(_INTL("\\G\\MGJust do what you can.\\1"))
      end
    else # Cancel
      break
    end
  end
end

def pbGetMomGoldString
  return _INTL("${1}", $PokemonGlobal.mom_money.to_s_formatted)
end

def pbDisplayMomGoldWindow(msgwindow, goldwindow)
  moneyString = pbGetMomGoldString
  mgoldwindow = Window_AdvancedTextPokemon.new(_INTL("Bank:\n<ar>{1}</ar>", moneyString))
  mgoldwindow.setSkin("Graphics/Windowskins/goldskin")
  mgoldwindow.resizeToFit(mgoldwindow.text, Graphics.width)
  mgoldwindow.width = 160 if mgoldwindow.width <= 160
  if msgwindow.y == 0
    mgoldwindow.y = (goldwindow) ? goldwindow.y - mgoldwindow.height : Graphics.height - mgoldwindow.height
  else
    mgoldwindow.y = (goldwindow) ? mgoldwindow.height : 0
  end
  mgoldwindow.viewport = msgwindow.viewport
  mgoldwindow.z = msgwindow.z
  return mgoldwindow
end