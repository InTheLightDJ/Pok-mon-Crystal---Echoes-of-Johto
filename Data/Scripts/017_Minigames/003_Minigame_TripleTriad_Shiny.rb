#===============================================================================
# Shiny Triple Triad cards
#
# - Each NPC card has a 1/300 chance to be shiny when placed on the board
# - Shiny cards sparkle while on the field (loops Common:Shiny battle animation)
# - Winning a shiny card adds it to the normal hand (triads) and records the
#   species in triad_shiny_species — shiny cards sell for 5× their normal price
# - MSC.t / MSC.f chat command (mod+admin) forces shiny on/off for testing
#   via $PokemonGlobal.msc_force (nil=normal, true=force all shiny, false=force none)
#===============================================================================

#===============================================================================
# Save data — triad_shiny_species tracks which species the player has won shiny
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :msc_force   # nil = normal  |  true = force all shiny  |  false = force none

  def triad_shiny_species
    @triad_shiny_species ||= []
  end
end

#===============================================================================
# TriadCard — shiny bitmap variant (golden star in top-right corner)
#===============================================================================
class TriadCard
  alias shiny_createBitmap createBitmap
  def createBitmap(owner, shiny = false)
    bmp = shiny_createBitmap(owner)
    if shiny && owner != 0
      bmp.fill_rect(27, 1, 6, 6, Color.new(255, 215, 0))
      bmp.fill_rect(28, 2, 4, 4, Color.new(255, 255, 200))
      bmp.fill_rect(29, 3, 2, 2, Color.new(255, 255, 255))
    end
    return bmp
  end
end

#===============================================================================
# ShinyCardAnim — looping RPG animation centered on a board card position.
#
# Uses "Common:Shiny" battle animation data.  All card overlays share one
# Bitmap loaded once by TriadScene; disposing an instance must NOT dispose it.
#
# Cell X/Y in PBAnimation are stored as screen-space coords where the "focus
# point" is at Battle::Scene::FOCUSTARGET_X/Y.  We subtract that offset and
# add the card's center position to place each particle correctly.
#===============================================================================
class ShinyCardAnim
  CELL_SIZE     = 192
  CELLS_PER_ROW = 5

  def initialize(animation, shared_bitmap, viewport, cx, cy)
    @animation = animation
    @duration  = animation.length
    @tpf       = 1.0 / (animation.speed || 20)
    @t0        = System.uptime
    @last_idx  = -1
    @cx        = cx
    @cy        = cy
    max_cells  = animation.array.map(&:length).max
    @sprites   = Array.new(max_cells) do
      s         = Sprite.new(viewport)
      s.bitmap  = shared_bitmap
      s.z       = 10
      s.visible = false
      s
    end
  end

  def update_anim
    idx = ((System.uptime - @t0) / @tpf).to_i % @duration
    return if idx == @last_idx
    @last_idx = idx
    frame     = @animation[idx]
    @sprites.each { |s| s.visible = false }
    return unless frame
    frame.length.times do |i|
      cel     = frame[i]
      next unless cel
      pattern = cel[AnimFrame::PATTERN]
      next if pattern.nil? || pattern < 0   # skip user/target reference cells
      next if cel[AnimFrame::VISIBLE] == 0
      s = @sprites[i]
      next unless s
      s.visible    = true
      s.src_rect.set((pattern % CELLS_PER_ROW) * CELL_SIZE,
                     (pattern / CELLS_PER_ROW) * CELL_SIZE,
                     CELL_SIZE, CELL_SIZE)
      s.x          = @cx + cel[AnimFrame::X] - Battle::Scene::FOCUSTARGET_X
      s.y          = @cy + cel[AnimFrame::Y] - Battle::Scene::FOCUSTARGET_Y
      s.ox         = CELL_SIZE / 2
      s.oy         = CELL_SIZE / 2
      s.zoom_x     = cel[AnimFrame::ZOOMX]  / 100.0
      s.zoom_y     = cel[AnimFrame::ZOOMY]  / 100.0
      s.angle      = cel[AnimFrame::ANGLE]
      s.mirror     = (cel[AnimFrame::MIRROR] > 0)
      s.opacity    = cel[AnimFrame::OPACITY]
      s.blend_type = cel[AnimFrame::BLENDTYPE] || 0
    end
  end

  def dispose
    @sprites.each do |s|
      s.bitmap = nil   # shared — caller disposes it
      s.dispose
    end
    @sprites.clear
  end
end

#===============================================================================
# ShinyCardGlow — fallback pulsing overlay when the animation data is missing.
#===============================================================================
class ShinyCardGlow
  def initialize(viewport, cx, cy)
    @bm = Bitmap.new(48, 48)
    @bm.fill_rect(0, 0, 48, 48, Color.new(255, 215, 0, 80))
    @spr         = Sprite.new(viewport)
    @spr.bitmap  = @bm
    @spr.ox      = 24
    @spr.oy      = 24
    @spr.x       = cx
    @spr.y       = cy
    @spr.z       = 10
  end

  def update_anim
    @spr.opacity = (Math.sin(System.uptime * 3.5) * 70 + 165).to_i.clamp(60, 235)
  end

  def dispose
    @bm.dispose
    @spr.dispose
  end
end

#===============================================================================
# TriadScene — sparkle overlays on shiny board squares
#===============================================================================
class TriadScene
  alias shiny_pbEndScene pbEndScene
  def pbEndScene
    _dispose_shiny_overlays
    shiny_pbEndScene
  end

  alias shiny_pbRefresh pbRefresh
  def pbRefresh
    shiny_pbRefresh
    _refresh_shiny_overlays
  end

  # Called every game-loop frame — drives continuous sparkle animation.
  alias shiny_pbUpdate pbUpdate
  def pbUpdate
    shiny_pbUpdate
    _tick_shiny_overlays
  end

  # Show sparkle on any player card whose species is already in triad_shiny_species.
  alias shiny_pbEndPlaceCard pbEndPlaceCard
  def pbEndPlaceCard(position, cardIndex)
    shiny_pbEndPlaceCard(position, cardIndex)
    board_idx = (position[1] * @battle.width) + position[0]
    if @boardCards[board_idx] && $PokemonGlobal.triad_shiny_species.include?(@boardCards[board_idx].species)
      $TriadShinyBoard           ||= {}
      $TriadShinyBoard[board_idx]  = @boardCards[board_idx].species
      _refresh_shiny_overlays
    end
  end

  # Roll shiny chance after the opponent commits a card to the board.
  alias shiny_pbEndOpponentPlaceCard pbEndOpponentPlaceCard
  def pbEndOpponentPlaceCard(position, cardIndex)
    shiny_pbEndOpponentPlaceCard(position, cardIndex)
    force     = $PokemonGlobal.msc_force
    is_shiny  = force.nil? ? (rand(300) == 0) : force
    board_idx = (position[1] * @battle.width) + position[0]
    if is_shiny && @boardCards[board_idx]
      $TriadShinyBoard           ||= {}
      $TriadShinyBoard[board_idx]  = @boardCards[board_idx].species
      _refresh_shiny_overlays
    end
  end

  private

  def _shiny_board
    $TriadShinyBoard ||= {}
  end

  # Finds "Common:Shiny" in the battle animation data and loads its sprite sheet
  # bitmap once.  Result cached in @shinyAnim / @shinyAnimBitmap.
  def _load_shiny_animation
    return @shinyAnim if @shinyAnimLoaded
    @shinyAnimLoaded = true
    @shinyAnim       = nil
    @shinyAnimBitmap = nil
    animations = pbLoadBattleAnimations
    return nil unless animations
    animations.each do |a|
      next unless a && a.name == "Common:Shiny"
      @shinyAnim       = a
      @shinyAnimBitmap = pbGetAnimation(a.graphic, a.hue)
      break
    end
    return @shinyAnim
  end

  # Re-applies gold-star card bitmaps and creates sparkle overlays for any
  # shiny board square that doesn't have one yet.
  def _refresh_shiny_overlays
    @shinyOverlays ||= {}
    anim = _load_shiny_animation
    (@battle.width * @battle.height).times do |i|
      species = _shiny_board[i]
      if species && @boardSprites[i]
        owner = @battle.board[i]&.owner || 0
        @boardSprites[i].bitmap&.dispose
        @boardSprites[i].bitmap = TriadCard.new(species).createBitmap(owner, true)
        next if @shinyOverlays[i]
        col     = i % @battle.width
        row     = i / @battle.width
        card_cx = 84 + (col * 58) + 18
        card_cy = 50 + (row * 58) + 20
        @shinyOverlays[i] = if anim && @shinyAnimBitmap
          ShinyCardAnim.new(anim, @shinyAnimBitmap, @viewport, card_cx, card_cy)
        else
          ShinyCardGlow.new(@viewport, card_cx, card_cy)
        end
      elsif !species && @shinyOverlays[i]
        @shinyOverlays[i].dispose
        @shinyOverlays[i] = nil
      end
    end
  end

  # Called every frame — delegates to each overlay's own update_anim method.
  def _tick_shiny_overlays
    return unless @shinyOverlays && !@shinyOverlays.empty?
    @shinyOverlays.each_value { |o| o&.update_anim }
  end

  def _dispose_shiny_overlays
    @shinyOverlays&.each_value { |o| o&.dispose }
    @shinyOverlays   = nil
    @shinyAnimBitmap&.dispose
    @shinyAnimBitmap = nil
    @shinyAnim       = nil
    @shinyAnimLoaded = false
  end
end

#===============================================================================
# pbTriadDuel — won shiny card goes into the normal hand; reset board tracking
#===============================================================================
alias shiny_pbTriadDuel pbTriadDuel
def pbTriadDuel(name, minLevel, maxLevel, rules = nil, oppdeck = nil, prize = nil)
  $TriadShinyBoard = {}
  # Snapshot the hand before the duel so we can diff afterward.
  before_items = $PokemonGlobal.triads.items.map { |s| s.dup }
  result = shiny_pbTriadDuel(name, minLevel, maxLevel, rules, oppdeck, prize)
  if result == 1 && !($TriadShinyBoard || {}).empty?
    shiny_set    = $TriadShinyBoard.values
    before_counts = {}
    before_items.each { |slot| before_counts[slot[0]] = slot[1] }
    # Any species the player gained whose board-slot was shiny gets marked shiny.
    $PokemonGlobal.triads.items.each do |slot|
      sid = slot[0]
      next unless slot[1] > (before_counts[sid] || 0) && shiny_set.include?(sid)
      next if $PokemonGlobal.triad_shiny_species.include?(sid)
      $PokemonGlobal.triad_shiny_species << sid
      pbGiveAchievement(6)
      pbMessage(_INTL("One of {1}'s cards was gleaming!\nYou got a shiny {2} card!",
                      name, GameData::Species.get(sid).name))
    end
  end
  $TriadShinyBoard = nil
  return result
end

#===============================================================================
# pbSellTriads — unified sell screen; shiny species show *and sell at 5× price
#===============================================================================
def pbSellTriads(discount = 0)
  storage   = $PokemonGlobal.triads
  shiny_ids = $PokemonGlobal.triad_shiny_species
  build_cmds = -> {
    cmds = []
    storage.length.times do |i|
      slot    = storage[i]
      species = slot[0]
      prefix  = shiny_ids.include?(species) ? "* " : ""
      cmds.push("#{prefix}#{GameData::Species.get(species).name} x#{slot[1]}")
    end
    cmds.push(_INTL("CANCEL"))
    next cmds
  }

  total_cards = 0
  storage.length.times { |i| total_cards += storage[i][1] }
  if total_cards == 0
    pbMessage(_INTL("You have no cards."))
    return
  end
  pbScrollMap(4, 3, 5)
  commands   = build_cmds.call
  cmdwindow  = Window_CommandPokemonEx.newWithSize(commands, 0, 0, Graphics.width / 2 + 28, Graphics.height)
  cmdwindow.z = 99999
  goldwindow = Window_UnformattedTextPokemon.newWithSize(
    _INTL("Money:\n{1}", pbGetGoldString), 0, 0, 32, 32
  )
  goldwindow.resizeToFit(goldwindow.text, Graphics.width)
  goldwindow.x = Graphics.width - goldwindow.width
  goldwindow.y = 0
  goldwindow.z = 99999
  preview   = Sprite.new
  preview.x = (Graphics.width / 2) + 76
  preview.y = (Graphics.height / 2) + 28
  preview.z = 4
  cur_sp    = storage.get_item(cmdwindow.index)
  preview.bitmap = cur_sp ? TriadCard.new(cur_sp).createBitmap(1, shiny_ids.include?(cur_sp)) : nil
  old_sp    = cur_sp
  done      = false
  Graphics.frame_reset
  until done
    loop do
      Graphics.update
      Input.update
      cmdwindow.active = true
      cmdwindow.update
      goldwindow.update
      cur_sp = storage.get_item(cmdwindow.index)
      if old_sp != cur_sp
        preview.bitmap&.dispose
        preview.bitmap = cur_sp ? TriadCard.new(cur_sp).createBitmap(1, shiny_ids.include?(cur_sp)) : nil
        old_sp = cur_sp
      end
      if Input.trigger?(Input::BACK)
        done = true; break
      end
      next unless Input.trigger?(Input::USE)
      if cmdwindow.index >= storage.length
        done = true; break
      end
      item     = storage.get_item(cmdwindow.index)
      itemname = GameData::Species.get(item).name
      is_shiny = shiny_ids.include?(item)
      quantity = storage.quantity(item)
      base     = TriadCard.new(item).price(discount)
      if base == 0
        pbDisplayPaused(_INTL("The {1} card? I'm not interested in that one right now.", itemname))
        break
      end
      unit = is_shiny ? base * 5 / 4 : base / 4
      cmdwindow.active = false
      cmdwindow.update
      if quantity > 1
        params = ChooseNumberParams.new
        params.setRange(1, quantity)
        params.setInitialValue(1)
        params.setCancelValue(0)
        quantity = pbMessageChooseNumber(
          _INTL("The {1} card? How many would you like to sell?", is_shiny ? "* #{itemname}" : itemname),
          params
        )
      end
      if quantity > 0
        price = unit * quantity
        price -= rand(1...[price / 2, 2].max) if price > 2
        msg = is_shiny ? _INTL("A shiny one! I can pay ${1}. OK?", price.to_s_formatted)
                       : _INTL("I can pay ${1}. Would that be OK?", price.to_s_formatted)
        if pbConfirmMessage(msg)
          $player.money += price
          goldwindow.text = _INTL("Money:\n{1}", pbGetGoldString)
          storage.remove(item, quantity)
          shiny_ids.delete(item) if is_shiny && storage.quantity(item) == 0
          sold_msg = is_shiny ? _INTL("Sold the shiny {1} card for ${2}.", itemname, price.to_s_formatted)
                              : _INTL("Turned over the {1} card and received ${2}.", itemname, price.to_s_formatted)
          pbMessage(sold_msg + "\\se[Mart buy item]")
          commands = build_cmds.call
          cmdwindow.commands = commands
          done = true if storage.empty?
          break
        end
      end
      cmdwindow.active = true
    end
  end
  cmdwindow.dispose
  goldwindow.dispose
  preview.bitmap&.dispose
  preview.dispose
  Graphics.frame_reset
  pbScrollMap(6, 3, 5)
end

#===============================================================================
# Card Trunk — shiny-aware display in the PokéGear menu
#===============================================================================
class PokemonPokegear_Scene
  # Replace the trunk menu: shiny cards are in the normal hand, no separate
  # shiny hand needed.
  def pbCardTrunkMenu
    loop do
      hand_n  = $PokemonGlobal.triads.total_cards
      trunk_n = $PokemonGlobal.triad_trunk.total_cards
      cmd = pbMessage(_INTL("What would you like to do?"), [
        _INTL("View Hand ({1})",   hand_n),
        _INTL("Move to Trunk"),
        _INTL("Take from Trunk ({1})", trunk_n),
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

  private

  # Show shiny bitmap for species in triad_shiny_species.
  alias shiny_triad_update_preview _triad_update_preview
  def _triad_update_preview(sprite, storage, index)
    sprite.bitmap&.dispose
    sprite.bitmap = nil
    return if index >= storage.length
    species  = storage.get_item(index)
    is_shiny = $PokemonGlobal.triad_shiny_species.include?(species)
    sprite.bitmap = TriadCard.new(species).createBitmap(1, is_shiny)
  end

  # Show *prefix for shiny species in the command list.
  alias shiny_triad_build_commands _triad_build_commands
  def _triad_build_commands(storage)
    cmds = []
    storage.length.times do |i|
      slot    = storage[i]
      species = slot[0]
      prefix  = $PokemonGlobal.triad_shiny_species.include?(species) ? "* " : ""
      cmds.push("#{prefix}#{GameData::Species.get(species).name} x#{slot[1]}")
    end
    return cmds
  end
end
