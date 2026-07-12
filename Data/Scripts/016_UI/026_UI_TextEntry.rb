#===============================================================================
#
#===============================================================================
class Window_CharacterEntry < Window_DrawableCommand
  XSIZE = 13
  YSIZE = 4

  def initialize(charset, viewport = nil)
    @viewport = viewport
    @charset = charset
    @othercharset = ""
    super(0, 96, 480, 192)
    self.baseColor, self.shadowColor = getDefaultTextColors(self.windowskin)
    self.columns = XSIZE
    refresh
  end

  def setOtherCharset(value)
    @othercharset = value.clone
    refresh
  end

  def setCharset(value)
    @charset = value.clone
    refresh
  end

  def character
    if self.index < 0 || self.index >= @charset.length
      return ""
    else
      return @charset[self.index]
    end
  end

  def command
    return -1 if self.index == @charset.length
    return -2 if self.index == @charset.length + 1
    return -3 if self.index == @charset.length + 2
    return self.index
  end

  def itemCount
    return @charset.length + 3
  end

  def drawItem(index, _count, rect)
    rect = drawCursor(index, rect)
    if index == @charset.length # -1
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, "[ ]",
                       self.baseColor, self.shadowColor)
    elsif index == @charset.length + 1 # -2
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, @othercharset,
                       self.baseColor, self.shadowColor)
    elsif index == @charset.length + 2 # -3
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, _INTL("OK"),
                       self.baseColor, self.shadowColor)
    else
      pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, @charset[index],
                       self.baseColor, self.shadowColor)
    end
  end
end

#===============================================================================
# Text entry screen - free typing.
#===============================================================================
class PokemonEntryScene
  @@Characters = [
    [("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").scan(/./), "[*]"],
    [("0123456789   !@\#$%^&*()   ~`-_+={}[]   :;'\"<>,.?/   ").scan(/./), "[A]"]
  ]
  USEKEYBOARD = true

  def pbStartScene(helptext, minlength, maxlength, initialText, subject = 0, pokemon = nil)
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    if USEKEYBOARD
      @sprites["entry"] = Window_TextEntry_Keyboard.new(
        initialText, 0, 0, 400 - 112, 96, helptext, true
      )
      Input.text_input = true
    else
      @sprites["entry"] = Window_TextEntry.new(initialText, 0, 0, 400, 96, helptext, true)
    end
    @sprites["entry"].x = (Graphics.width / 2) - (@sprites["entry"].width / 2) + 32
    @sprites["entry"].viewport = @viewport
    @sprites["entry"].visible = true
    @minlength = minlength
    @maxlength = maxlength
    @symtype = 0
    @sprites["entry"].maxlength = maxlength
    if !USEKEYBOARD
      @sprites["entry2"] = Window_CharacterEntry.new(@@Characters[@symtype][0])
      @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
      @sprites["entry2"].viewport = @viewport
      @sprites["entry2"].visible = true
      @sprites["entry2"].x = (Graphics.width / 2) - (@sprites["entry2"].width / 2)
    end
    if minlength == 0
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("Enter text using the keyboard. Press\nEnter to confirm, or Esc to cancel."),
        0, Graphics.height - 96, Graphics.width - 32, 96, @viewport
      )
    else
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize(
        _INTL("Enter text using the keyboard.\nPress Enter to confirm."),
        0, Graphics.height - 96, Graphics.width - 32, 96, @viewport
      )
    end
    @sprites["helpwindow"].letterbyletter = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["helpwindow"].visible = USEKEYBOARD
    @sprites["helpwindow"].baseColor = Color.new(0, 0, 0)
    @sprites["helpwindow"].shadowColor = Color.new(248, 248, 248)
    addBackgroundPlane(@sprites, "background", "bg_white_general", @viewport)
    case subject
    when 1   # Player
      meta = GameData::PlayerMetadata.get($player.character_ID)
      if meta
        filename = pbGetPlayerCharset(meta.walk_charset, nil, true)
        @sprites["subject"] = TrainerWalkingCharSprite.new(filename, @viewport)
        @sprites["subject"].x = 32
        @sprites["subject"].y = 24
      end
    when 2   # Pokémon
      if pokemon
        @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
        @sprites["subject"].setOffset(PictureOrigin::CENTER)
        @sprites["subject"].x = 50
        @sprites["subject"].y = 44
        @sprites["gender"] = BitmapSprite.new(32, 32, @viewport)
        @sprites["gender"].x = 18
        @sprites["gender"].y = 32
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos = []
        if pokemon.male?
          textpos.push([_INTL("♂"), 0, 2, :left, Color.blue, Color.white])
        elsif pokemon.female?
          textpos.push([_INTL("♀"), 0, 2, :left, Color.red, Color.white])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap, textpos)
      end
    when 3   # NPC
      @sprites["subject"] = TrainerWalkingCharSprite.new(pokemon.to_s, @viewport)
      @sprites["subject"].x = 32
      @sprites["subject"].y = 24
    when 4   # Storage box
      @sprites["subject"] = IconSprite.new(32, 24, @viewport)
      @sprites["subject"].setBitmap("Graphics/UI/Naming/icon_storage")
    end
    pbFadeInAndShow(@sprites)
  end

  def pbEntry1
    ret = ""
    loop do
      Graphics.update
      Input.update
      if Input.triggerex?(:ESCAPE) && @minlength == 0
        ret = ""
        break
      elsif Input.triggerex?(:RETURN) && @sprites["entry"].text.length >= @minlength
        ret = @sprites["entry"].text
        break
      end
      @sprites["helpwindow"].update
      @sprites["entry"].update
      @sprites["subject"]&.update
    end
    Input.update
    return ret
  end

  def pbEntry2
    ret = ""
    loop do
      Graphics.update
      Input.update
      @sprites["helpwindow"].update
      @sprites["entry"].update
      @sprites["entry2"].update
      @sprites["subject"]&.update
      if Input.trigger?(Input::USE)
        index = @sprites["entry2"].command
        if index == -3 # Confirm text
          ret = @sprites["entry"].text
          if ret.length < @minlength || ret.length > @maxlength
            pbPlayBuzzerSE
          else
            pbPlayDecisionSE
            break
          end
        elsif index == -1   # Insert a space
          if @sprites["entry"].insert(" ")
            pbPlayDecisionSE
          else
            pbPlayBuzzerSE
          end
        elsif index == -2   # Change character set
          pbPlayDecisionSE
          @symtype += 1
          @symtype = 0 if @symtype >= @@Characters.length
          @sprites["entry2"].setCharset(@@Characters[@symtype][0])
          @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
        else   # Insert given character
          if @sprites["entry"].insert(@sprites["entry2"].character)
            pbPlayDecisionSE
          else
            pbPlayBuzzerSE
          end
        end
        next
      end
    end
    Input.update
    return ret
  end

  def pbEntry
    return USEKEYBOARD ? pbEntry1 : pbEntry2
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    Input.text_input = false if USEKEYBOARD
  end
end

#===============================================================================
# Text entry screen - arrows to select letter.
#===============================================================================
class PokemonEntryScene2
  @@Characters = [
    [("ABCDEFGHIJKLM" + "NOPQRSTUVW" + "XYZ♂♀-?!/.,  ").scan(/./), _INTL("UPPER")],
    [("abcdefghijklm" + "nopqrstuvw" + "xyz♂♀×():;[] ").scan(/./), _INTL("lower")]
  ]
  ROWS    = 9
  COLUMNS = 4
  MODE    = -3
  BACK    = -2
  OK      = -1

  class NameEntryCursor
    def initialize(viewport)
      @sprite = Sprite.new(viewport)
      @cursortype = 0
      @cursor1 = AnimatedBitmap.new("Graphics/UI/Naming/cursor_1")
      @cursor2 = AnimatedBitmap.new("Graphics/UI/Naming/cursor_2")
      @cursorPos = 0
      @frames = 0
      updateInternal
    end

    def setCursorPos(value)
      @cursorPos = value
    end

    def updateCursorPos
      value = @cursorPos
      case value
      when PokemonEntryScene2::MODE   # Upper case
        @sprite.x = 30
        @sprite.y = 254
        @cursortype = 1
      when PokemonEntryScene2::BACK   # Back
        @sprite.x = 126
        @sprite.y = 254
        @cursortype = 1
      when PokemonEntryScene2::OK   # OK
        @sprite.x = 222
        @sprite.y = 254
        @cursortype = 1
      else
        if value >= 0
          @sprite.x = 30 + (32 * (value % PokemonEntryScene2::ROWS))
          @sprite.y = 126 + (32 * (value / PokemonEntryScene2::ROWS))
          @cursortype = 0
        end
      end
    end

    def visible=(value)
      @sprite.visible = value
    end

    def visible
      @sprite.visible
    end

    def color=(value)
      @sprite.color = value
    end

    def color
      @sprite.color
    end

    def disposed?
      @sprite.disposed?
    end

    def updateInternal
      @cursor1.update
      @cursor2.update
      @frames += 1
      if @frames >= 10
        self.visible = !self.visible
        @frames = 0
      end
      updateCursorPos
      case @cursortype
      when 0 then @sprite.bitmap = @cursor1.bitmap
      when 1 then @sprite.bitmap = @cursor2.bitmap
      end
    end

    def update
      updateInternal
    end

    def dispose
      @cursor1.dispose
      @cursor2.dispose
      @sprite.dispose
    end
  end

  def pbStartScene(helptext, minlength, maxlength, initialText, subject = 0, pokemon = nil)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @helptext = helptext
    @helper = CharacterEntryHelper.new(initialText)
    # Create bitmaps
    @bitmaps = [
      BitmapSprite.new(Graphics.width, Graphics.height, @viewport),
      BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    ]
    @bitmaps[2] = @bitmaps[0].bitmap.clone
    @bitmaps[3] = @bitmaps[1].bitmap.clone
    for i in 0...2
      pos = 0
      pbSetSystemFont(@bitmaps[i + 2])
      textPos = []
      for y in 0...COLUMNS
        for x in 0...ROWS
          textPos.push([@@Characters[i][0][pos], 32 + (x * 32), 128 + (y * 32), :left,
                        MessageConfig::DARK_TEXT_MAIN_COLOR])
          pos += 1
        end
      end
      modeswap = [_INTL("lower"), _INTL("UPPER")]
      textPos.push([modeswap[i], 32, 256, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
      textPos.push([_INTL("DEL"), 144, 256, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
      textPos.push([_INTL("END"), 240, 256, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
      pbDrawTextPositions(@bitmaps[i + 2], textPos)
    end
    @bitmaps[4] = BitmapWrapper.new(16, 4)
    @bitmaps[4].fill_rect(2, 0, 16, 4, MessageConfig::DARK_TEXT_MAIN_COLOR)
    # Create sprites
    @sprites = {}
    @sprites["bg"] = IconSprite.new(0, 0, @viewport)
    @sprites["bg"].setBitmap("Graphics/UI/Naming/bg")
    case subject
    when 1   # Player
      meta = GameData::PlayerMetadata.get($player.character_ID)
      if meta
        filename = pbGetPlayerCharset(meta.walk_charset, nil, true)
        @sprites["subject"] = TrainerWalkingCharSprite.new(filename, @viewport)
        @sprites["subject"].x = 32
        @sprites["subject"].y = 24
      end
    when 2   # Pokémon
      if pokemon
        @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
        @sprites["subject"].setOffset(PictureOrigin::CENTER)
        @sprites["subject"].x = 50
        @sprites["subject"].y = 44
        @sprites["gender"] = BitmapSprite.new(32, 32, @viewport)
        @sprites["gender"].x = 18
        @sprites["gender"].y = 32
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos = []
        if pokemon.male?
          textpos.push([_INTL("♂"), 0, 2, :left, Color.blue, Color.white])
        elsif pokemon.female?
          textpos.push([_INTL("♀"), 0, 2, :left, Color.red, Color.white])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap, textpos)
      end
    when 3   # NPC
      @sprites["subject"] = TrainerWalkingCharSprite.new(pokemon.to_s, @viewport)
      @sprites["subject"].x = 32
      @sprites["subject"].y = 24
    when 4   # Storage box
      @sprites["subject"] = IconSprite.new(32, 24, @viewport)
      @sprites["subject"].setBitmap("Graphics/UI/Naming/icon_storage")
    end
    @sprites["bgoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbDoUpdateOverlay
    @blanks = []
    @mode = 0
    @minlength = minlength
    @maxlength = maxlength
    @maxlength.times do |i|
      @sprites["blank#{i}"] = Sprite.new(@viewport)
      @sprites["blank#{i}"].x = 80 + (16 * i)
      @sprites["blank#{i}"].bitmap = @bitmaps[@bitmaps.length - 1]
      @blanks[i] = 0
    end
    @sprites["bottomtab"] = Sprite.new(@viewport)   # Current tab
    @sprites["bottomtab"].x = 0
    @sprites["bottomtab"].y = 0
    @sprites["bottomtab"].bitmap = @bitmaps[@@Characters.length]
    @init = true
    @sprites["cursor"] = NameEntryCursor.new(@viewport)
    @cursorpos = 0
    @refreshOverlay = true
    @sprites["cursor"].setCursorPos(@cursorpos)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbUpdateOverlay
    @refreshOverlay = true
  end

  def pbDoUpdateOverlay
    return if !@refreshOverlay
    @refreshOverlay = false
    bgoverlay = @sprites["bgoverlay"].bitmap
    bgoverlay.clear
    pbSetSystemFont(bgoverlay)
    textPositions = []
    # split text into 2 lines if its too long
    if bgoverlay.text_size(@helptext).width > 226
      helptexts = @helptext.split(" ")
      echoln @helptext
      last_text = helptexts[0]
      line = 0
      helptexts.each_with_index do |word,i|
        next if i == 0
        textwidth = bgoverlay.text_size(last_text + " " + word).width
        last_text += " " + word if textwidth <= 226
        2.times do |j|
          next if j > 0 && i < helptexts.length - 1
          textPositions.push([last_text, 80, 32 + line * 32, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
          line += 1
          last_text = word
        end
      end
    else
      textPositions.push([@helptext, 80, 32, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
    end
    chars = @helper.textChars
    x = 80
    chars.each do |ch|
      textPositions.push([ch, x, 88, :left, MessageConfig::DARK_TEXT_MAIN_COLOR])
      x += 16
    end
    pbDrawTextPositions(bgoverlay, textPositions)
  end

  def pbChangeTab(newtab = @mode + 1)
    @mode = (newtab) % 2
    newtab = @bitmaps[(@mode) + 2]
    @sprites["bottomtab"].bitmap = newtab
  end

  def pbUpdate
    for i in 0...2
      @bitmaps[i].update
    end
    # Update which inputted text's character's underline is lowered to indicate
    # which character is selected
    if @init || Graphics.frame_count % 5 == 0
      @init = false
      cursorpos = @helper.cursor
      cursorpos = @maxlength - 1 if cursorpos >= @maxlength
      cursorpos = 0 if cursorpos < 0
      chars = @helper.textChars
      @maxlength.times { |i|
         @sprites["blank#{i}"].visible = i >= chars.length
         if i == cursorpos
           @blanks[i] = 1
         else
           @blanks[i] = 0
         end
      @sprites["blank#{i}"].y = [102, 108][@blanks[i]]
      } 
    end
    pbDoUpdateOverlay
    pbUpdateSpriteHash(@sprites)
  end

  def pbColumnEmpty?(m)
    return false if m >= ROWS - 1
    chset = @@Characters[@mode][0]
    COLUMNS.times do |i|
      return false if chset[(i * ROWS) + m] != " "
    end
    return true
  end

  def wrapmod(x, y)
    result = x % y
    result += y if result < 0
    return result
  end

  def pbMoveCursor
    oldcursor = @cursorpos
    cursordiv = @cursorpos / ROWS   # The row the cursor is in
    cursormod = @cursorpos % ROWS   # The column the cursor is in
    cursororigin = @cursorpos - cursormod
    if Input.repeat?(Input::LEFT)
      if @cursorpos < 0   # Controls
        @cursorpos -= 1
        @cursorpos = OK if @cursorpos < MODE
      else
        loop do
          cursormod = wrapmod(cursormod - 1, ROWS)
          @cursorpos = cursororigin + cursormod
          break unless pbColumnEmpty?(cursormod)
        end
      end
    elsif Input.repeat?(Input::RIGHT)
      if @cursorpos < 0   # Controls
        @cursorpos += 1
        @cursorpos = MODE if @cursorpos > OK
      else
        loop do
          cursormod = wrapmod(cursormod + 1, ROWS)
          @cursorpos = cursororigin + cursormod
          break unless pbColumnEmpty?(cursormod)
        end
      end
    elsif Input.repeat?(Input::UP)
      if @cursorpos < 0         # Controls
        case @cursorpos
        when MODE then @cursorpos = ROWS * (COLUMNS - 1)
        when BACK  then @cursorpos = (ROWS * (COLUMNS - 1)) + 3
        when OK    then @cursorpos = (ROWS * (COLUMNS - 1)) + 6
        end
      elsif @cursorpos < ROWS   # Top row of letters
        case @cursorpos
        when 0, 1, 2  then @cursorpos = MODE
        when 3, 4, 5  then @cursorpos = BACK
        when 6, 7, 8  then @cursorpos = OK
        end
      else
        cursordiv = wrapmod(cursordiv - 1, COLUMNS)
        @cursorpos = (cursordiv * ROWS) + cursormod
      end
    elsif Input.repeat?(Input::DOWN)
      if @cursorpos < 0                      # Controls
        case @cursorpos
        when MODE  then @cursorpos = 0
        when BACK  then @cursorpos = 3
        when OK    then @cursorpos = 6
        end
      elsif @cursorpos >= ROWS * (COLUMNS - 1)   # Bottom row of letters
        case cursormod
        when 0, 1, 2 then @cursorpos = MODE
        when 3, 4, 5 then @cursorpos = BACK
        else         @cursorpos = OK
        end
      else
        cursordiv = wrapmod(cursordiv + 1, COLUMNS)
        @cursorpos = (cursordiv * ROWS) + cursormod
      end
    end
    if @cursorpos != oldcursor   # Cursor position changed
      @sprites["cursor"].setCursorPos(@cursorpos)
      pbPlayCursorSE
      return true
    end
    return false
  end

  def pbEntry
    ret = ""
    loop do
      Graphics.update
      Input.update
      pbUpdate
      next if pbMoveCursor
      if Input.trigger?(Input::SPECIAL)
        pbChangeTab
      elsif Input.trigger?(Input::ACTION)
        @cursorpos = OK
        @sprites["cursor"].setCursorPos(@cursorpos)
      elsif Input.trigger?(Input::BACK)
        @helper.delete
        pbPlayCancelSE
        pbUpdateOverlay
      elsif Input.trigger?(Input::USE)
        case @cursorpos
        when BACK   # Backspace
          @helper.delete
          pbPlayCancelSE
          pbUpdateOverlay
        when OK     # Done
          pbPlayDecisionSE
          if @helper.length >= @minlength
            ret = @helper.text
            break
          end
        when MODE
          pbChangeTab
        else
          cursormod = @cursorpos % ROWS
          cursordiv = @cursorpos / ROWS
          charpos = (cursordiv * ROWS) + cursormod
          chset = @@Characters[@mode][0]
          @helper.delete if @helper.length >= @maxlength
          @helper.insert(chset[charpos])
          pbPlayCursorSE
          if @helper.length >= @maxlength
            @cursorpos = OK
            @sprites["cursor"].setCursorPos(@cursorpos)
          end
          pbUpdateOverlay
          # Auto-switch to lowercase letters after the first uppercase letter is selected
          pbChangeTab(1) if @mode == 0 && @helper.cursor == 1
        end
      end
    end
    Input.update
    return ret
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    @bitmaps.each do |bitmap|
      bitmap&.dispose
    end
    @bitmaps.clear
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonEntry
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(helptext, minlength, maxlength, initialText, mode = -1, pokemon = nil)
    @scene.pbStartScene(helptext, minlength, maxlength, initialText, mode, pokemon)
    ret = @scene.pbEntry
    @scene.pbEndScene
    return ret
  end
end

#===============================================================================
#
#===============================================================================
def pbEnterText(helptext, minlength, maxlength, initialText = "", mode = 0, pokemon = nil, nofadeout = false)
  ret = ""
  if ($PokemonSystem.textinput == 1 rescue false)   # Keyboard
    pbFadeOutIn(99999, nofadeout) do
      sscene = PokemonEntryScene.new
      sscreen = PokemonEntry.new(sscene)
      ret = sscreen.pbStartScreen(helptext, minlength, maxlength, initialText, mode, pokemon)
    end
  else   # Cursor
    pbFadeOutIn(99999, nofadeout) do
      sscene = PokemonEntryScene2.new
      sscreen = PokemonEntry.new(sscene)
      ret = sscreen.pbStartScreen(helptext, minlength, maxlength, initialText, mode, pokemon)
    end
  end
  return ret
end

def pbEnterPlayerName(helptext, minlength, maxlength, initialText = "", nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 1, nil, nofadeout)
end

def pbEnterPokemonName(helptext = "", minlength = 1, maxlength = 10, initialText = "", pokemon = nil, nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 2, pokemon, nofadeout)
end

def pbEnterNPCName(helptext, minlength, maxlength, initialText = "", id = 0, nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 3, id, nofadeout)
end

def pbEnterBoxName(helptext, minlength, maxlength, initialText = "", nofadeout = false)
  return pbEnterText(helptext, minlength, maxlength, initialText, 4, nil, nofadeout)
end
