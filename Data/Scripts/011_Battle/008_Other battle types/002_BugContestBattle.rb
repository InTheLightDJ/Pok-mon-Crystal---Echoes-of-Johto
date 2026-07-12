#===============================================================================
# Bug-Catching Contest battle scene (the visuals of the battle)
#===============================================================================
class Battle::Scene
  alias _bugContest_pbInitSprites pbInitSprites unless method_defined?(:_bugContest_pbInitSprites)

  def pbInitSprites
    _bugContest_pbInitSprites
    # "helpwindow" shows the currently caught Pokémon's details when asking if
    # you want to replace it with a newly caught Pokémon.
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 240, 96, @viewport)
    @sprites["helpwindow"].z       = 200
    @sprites["helpwindow"].visible = false
    @sprites["helpwindow2"] = Window_UnformattedTextPokemon.newWithSize("", 0,96, 240, 96, @viewport)
    @sprites["helpwindow2"].z       = 200
    @sprites["helpwindow2"].visible = false
    @sprites["helpwindow_header"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["helpwindow_header"].z = 201
    pbSetSystemFont(@sprites["helpwindow_header"].bitmap)
  end

  def pbShowHelp(stock, cur)
    @sprites["helpwindow"].text    = stock
    @sprites["helpwindow"].visible = true
    @sprites["helpwindow2"].text    = cur
    @sprites["helpwindow2"].visible = true
    @sprites["helpwindow_header"].bitmap.clear
    header = []
    header.push([_INTL("Stock κΜ"), @sprites["helpwindow"].x + 120, @sprites["helpwindow"].y, :center, Color.black])
    header.push([_INTL("This κΜ"), @sprites["helpwindow2"].x + 120, @sprites["helpwindow2"].y, :center, Color.black])
    header_width = @sprites["helpwindow_header"].bitmap.text_size(header[0][0]).width
    @sprites["helpwindow_header"].bitmap.fill_rect(@sprites["helpwindow"].x + 118 - (header_width / 2), 0, header_width + 4, 16, Color.white)
    header_width = @sprites["helpwindow_header"].bitmap.text_size(header[1][0]).width
    @sprites["helpwindow_header"].bitmap.fill_rect(@sprites["helpwindow2"].x + 118 - (header_width / 2), 96, header_width + 4, 16, Color.white)
    pbDrawTextPositions(@sprites["helpwindow_header"].bitmap, header)
  end

  def pbHideHelp
    @sprites["helpwindow"].visible = false
    @sprites["helpwindow2"].visible = false
    @sprites["helpwindow_header"].visible = false
  end
end

#===============================================================================
# Bug-Catching Contest battle class
#===============================================================================
class BugContestBattle < Battle
  attr_accessor :ballCount

  def initialize(*arg)
    @ballCount = 0
    @ballConst = GameData::Item.get(:SPORTBALL).id
    super(*arg)
  end

  def pbItemMenu(idxBattler, _firstAction)
    return pbRegisterItem(idxBattler, @ballConst, 1)
  end

  def pbCommandMenu(idxBattler, _firstAction)
    return @scene.pbCommandMenuEx(idxBattler,
                                  [_INTL("Left/\n{1} balls", @ballCount),
                                   _INTL("Fight"),
                                   _INTL("κΜ"),
                                   _INTL("Ball"),
                                   _INTL("Run")], 4)
  end

  def pbConsumeItemInBag(_item, _idxBattler)
    @ballCount -= 1 if @ballCount > 0
  end

  def pbStorePokemon(pkmn)
    if pbBugContestState.lastPokemon
      lastPokemon = pbBugContestState.lastPokemon
      pbDisplayPaused(_INTL("You already caught a {1}.", lastPokemon.name))
      stocktext = _INTL("{1} Λ{2}\nHealth : {3}", lastPokemon.name, lastPokemon.level, lastPokemon.totalhp)
      curtext   = _INTL("{1} Λ{2}\nHealth : {3}", pkmn.name, pkmn.level, pkmn.totalhp)
      @scene.pbShowHelp(stocktext, curtext)
      if pbDisplayConfirm(_INTL("Switch κΜ?"))
        pbBugContestState.lastPokemon = pkmn
        pbRegisterCaughtPokemon(pkmn)
        @scene.pbHideHelp
      else
        @scene.pbHideHelp
        return
      end
    else
      pbBugContestState.lastPokemon = pkmn
    end
      # ✅ Give boss ribbon if this is the boss
    if pkmn.name.include?("Boss") && !pkmn.hasRibbon?(:BUGBOSS)
      pkmn.giveRibbon(:BUGBOSS)
      party_pkmn = $player.party[0]
      if !party_pkmn.hasRibbon?(:BUGBOSSBEATER)
        party_pkmn.giveRibbon(:BUGBOSSBEATER)
        pbMessage(_INTL("{1} received the BUGBOSS Ribbon!", party_pkmn.name))
      end
    end
    pbDisplay(_INTL("Caught {1}!", pkmn.name))
  end

  def pbEndOfRoundPhase
    super
    @decision = Battle::Outcome::FLEE if @ballCount <= 0 && !decided?
  end
end
