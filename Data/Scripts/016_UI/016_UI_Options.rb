#===============================================================================
#
#===============================================================================
class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :sendtoboxes
  attr_accessor :givenicknames
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :screensize
  attr_accessor :language
  attr_accessor :runstyle
  attr_accessor :bgmvolume
  attr_accessor :sevolume
  attr_accessor :textinput
  attr_accessor :pause_menu_desc
  attr_accessor :instant_battle_prob
  attr_accessor :contestanimations
  attr_writer :show_online_players
  def show_online_players; @show_online_players ||= 0; end
  attr_writer :chat_sounds
  def chat_sounds; @chat_sounds ||= 0; end

  def initialize
    @textspeed     = 1     # Text speed (0=slow, 1=medium, 2=fast, 3=instant)
    @battlescene   = 0     # Battle effects (animations) (0=on, 1=off)
    @battlestyle   = 0     # Battle style (0=switch, 1=set)
    @sendtoboxes   = 0     # Send to Boxes (0=manual, 1=automatic)
    @givenicknames = 0     # Give nicknames (0=give, 1=don't give)
    @frame         = 0     # Default window frame (see also Settings::MENU_WINDOWSKINS)
    @textskin      = 0     # Speech frame
    @screensize    = (Settings::SCREEN_SCALE * 2).floor - 1   # 0=half size, 1=full size, 2=full-and-a-half size, 3=double size
    @language      = 0     # Language (see also Settings::LANGUAGES in script PokemonSystem)
    @runstyle      = 0     # Default movement speed (0=walk, 1=run)
    @bgmvolume     = 80    # Volume of background music and ME
    @sevolume      = 100   # Volume of sound effects
    @textinput     = 0     # Text input mode (0=cursor, 1=keyboard)
    @pause_menu_desc = 1   # Pause Menu description text (0=on, 1=off)
    @instant_battle_prob = Settings::INSTANT_BATTLE_PROB_DEFAULT  # ← here
    @contestanimations   = Settings::CONTEST_ANIMATIONS ? 0 : 1   # Contest effects (0=on, 1=off)
    @show_online_players = 0   # Online players (0=show, 1=hide)
    @chat_sounds         = 0   # Chat sounds (0=on, 1=off)
  end
end

#===============================================================================
#
#===============================================================================
module PropertyMixin
  attr_reader :name

  def get
    return @get_proc&.call
  end

  def set(*args)
    @set_proc&.call(*args)
  end
end

#===============================================================================
#
#===============================================================================
class EnumOption
  include PropertyMixin
  attr_reader :values

  def initialize(name, values, get_proc, set_proc)
    @name     = name
    @values   = values.map { |val| _INTL(val) }
    @get_proc = get_proc
    @set_proc = set_proc
  end

  def next(current)
    index = current + 1
    index = 0 if index > @values.length - 1
    return index
  end

  def prev(current)
    index = current - 1
    index = @values.length - 1 if index < 0
    return index
  end
end

#===============================================================================
#
#===============================================================================
class NumberOption
  include PropertyMixin
  attr_reader :lowest_value
  attr_reader :highest_value

  def initialize(name, range, get_proc, set_proc)
    @name = name
    case range
    when Range
      @lowest_value  = range.begin
      @highest_value = range.end
    when Array
      @lowest_value  = range[0]
      @highest_value = range[1]
    end
    @get_proc = get_proc
    @set_proc = set_proc
  end

  def next(current)
    index = current + @lowest_value
    index += 1
    index = @lowest_value if index > @highest_value
    return index - @lowest_value
  end

  def prev(current)
    index = current + @lowest_value
    index -= 1
    index = @highest_value if index < @lowest_value
    return index - @lowest_value
  end
end

#===============================================================================
#
#===============================================================================
class SliderOption
  include PropertyMixin
  attr_reader :lowest_value
  attr_reader :highest_value

  def initialize(name, range, get_proc, set_proc)
    @name          = name
    @lowest_value  = range[0]
    @highest_value = range[1]
    @interval      = range[2]
    @get_proc      = get_proc
    @set_proc      = set_proc
  end

  def next(current)
    index = current + @lowest_value
    index += @interval
    index = @lowest_value if index > @highest_value
    return index - @lowest_value
  end

  def prev(current)
    index = current + @lowest_value
    index -= @interval
    index = @highest_value if index < @lowest_value
    return index - @lowest_value
  end
end

#===============================================================================
# Main options list
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
  attr_reader :value_changed

  SEL_NAME_BASE_COLOR    = Color.new(192, 120, 0)
  SEL_NAME_SHADOW_COLOR  = Color.new(248, 176, 80)
  SEL_VALUE_BASE_COLOR   = Color.new(248, 48, 24)
  SEL_VALUE_SHADOW_COLOR = Color.new(248, 136, 128)

  def initialize(options, x, y, width, height)
    @options = options
    @values = []
    @options.length.times { |i| @values[i] = 0 }
    @value_changed = false
    super(x, y, width, height)
  end

  def [](i)
    return @values[i]
  end

  def []=(i, value)
    @values[i] = value
    refresh
  end

  def setValueNoRefresh(i, value)
    @values[i] = value
  end

  def itemCount
    return @options.length + 1
  end

  def drawCursor(index, rect)
    if self.index == index
      pbCopyBitmap(self.contents, @selarrow.bitmap, rect.x, rect.y + 2)   # TEXT OFFSET (counters the offset above)
    end
    return Rect.new(rect.x + 16, rect.y, rect.width - 16, rect.height * 2)
  end

  def drawItem(index, _count, rect)
    rect = drawCursor(index, rect)
    sel_index = self.index
    # Draw option's name
    optionname = (index == @options.length) ? _INTL("Close") : @options[index].name
    optionwidth = rect.width * 9 / 20
    pbDrawShadowText(self.contents, rect.x, rect.y, rect.width, rect.height, optionname, self.baseColor, self.shadowColor)
    xpos = rect.x + 134
    return if index == @options.length
    # Draw option's values
    case @options[index]
    when EnumOption
      value = ": #{@options[index].values[self[index]]}"
    when NumberOption
      value = ": Type #{@options[index].lowest_value + self[index]}"
    when SliderOption
      value = sprintf(": %d", @options[index].lowest_value + self[index])
    else
      value = ": #{@options[index].values[self[index]]}"
    end
    pbDrawShadowText(self.contents, xpos, rect.y + 16, rect.width, rect.height, value,
                     Color.new(0, 0, 0))
  end

  def update
    oldindex = self.index
    @value_changed = false
    super
    dorefresh = (self.index != oldindex)
    if self.active && self.index < @options.length
      if Input.repeat?(Input::LEFT)
        self[self.index] = @options[self.index].prev(self[self.index])
        dorefresh = true
        @value_changed = true
      elsif Input.repeat?(Input::RIGHT)
        self[self.index] = @options[self.index].next(self[self.index])
        dorefresh = true
        @value_changed = true
      end
    end
    refresh if dorefresh
  end
end

#===============================================================================
# Options main screen
#===============================================================================
class PokemonOption_Scene
  attr_reader :sprites
  attr_reader :in_load_screen

  def pbStartScene(in_load_screen = false)
    @in_load_screen = in_load_screen
    # Get all options
    @options = []
    @hashes = []
    MenuHandlers.each_available(:options_menu) do |option, hash, name|
      @options.push(
        hash["type"].new(name, hash["parameters"], hash["get_proc"], hash["set_proc"])
      )
      @hashes.push(hash)
    end
    # Create sprites
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["option"] = Window_PokemonOption.new( @options, 0, 0, Graphics.width, Graphics.height )
    @sprites["option"].viewport = @viewport
    @sprites["option"].visible  = true
    # Get the values of each option
    @options.length.times { |i| @sprites["option"].setValueNoRefresh(i, @options[i].get || 0) }
    @sprites["option"].refresh
    pbChangeSelection
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbChangeSelection
    hash = @hashes[@sprites["option"].index]
    # Call selected option's "on_select" proc (if defined)
    hash["on_select"]&.call(self) if hash
  end

  def pbOptions
    pbActivateWindow(@sprites, "option") do
      index = -1
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["option"].index != index
          pbChangeSelection
          index = @sprites["option"].index
        end
        @options[index].set(@sprites["option"][index], self) if @sprites["option"].value_changed
        if Input.trigger?(Input::BACK)
          break
        elsif Input.trigger?(Input::USE)
          break if @sprites["option"].index == @options.length
        end
      end
    end
  end

  def pbEndScene
    pbPlayCloseMenuSE
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Set the values of each option, to make sure they're all set
    @options.length.times do |i|
      @options[i].set(@sprites["option"][i], self)
    end
    pbDisposeSpriteHash(@sprites)
    pbUpdateSceneMap
    @viewport.dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
end

#===============================================================================
#
#===============================================================================
class PokemonOptionScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(in_load_screen = false)
    @scene.pbStartScene(in_load_screen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end

#===============================================================================
# Options Menu commands
#===============================================================================
MenuHandlers.add(:options_menu, :bgm_volume, {
  "name"        => _INTL("Music"),
  "order"       => 10,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Adjust the volume of the background music."),
  "get_proc"    => proc { next $PokemonSystem.bgmvolume },
  "set_proc"    => proc { |value, scene|
    next if $PokemonSystem.bgmvolume == value
    $PokemonSystem.bgmvolume = value
    next if scene.in_load_screen || $game_system.playing_bgm.nil?
    playingBGM = $game_system.getPlayingBGM
    $game_system.bgm_pause
    $game_system.bgm_resume(playingBGM)
  }
})

MenuHandlers.add(:options_menu, :se_volume, {
  "name"        => _INTL("Sound Effect"),
  "order"       => 20,
  "type"        => SliderOption,
  "parameters"  => [0, 100, 5],   # [minimum_value, maximum_value, interval]
  "description" => _INTL("Adjust the volume of sound effects."),
  "get_proc"    => proc { next $PokemonSystem.sevolume },
  "set_proc"    => proc { |value, _scene|
    next if $PokemonSystem.sevolume == value
    $PokemonSystem.sevolume = value
    if $game_system.playing_bgs
      $game_system.playing_bgs.volume = value
      playingBGS = $game_system.getPlayingBGS
      $game_system.bgs_pause
      $game_system.bgs_resume(playingBGS)
    end
    pbPlayCursorSE
  }
})

MenuHandlers.add(:options_menu, :text_speed, {
  "name"        => _INTL("Text Speed"),
  "order"       => 30,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Slow"), _INTL("Mid"), _INTL("Fast"), _INTL("Inst")],
  "description" => _INTL("Choose the speed at which text appears."),
  "get_proc"    => proc { next $PokemonSystem.textspeed },
  "set_proc"    => proc { |value, scene|
    next if value == $PokemonSystem.textspeed
    $PokemonSystem.textspeed = value
    MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(value))
  }
})

MenuHandlers.add(:options_menu, :battle_animations, {
  "name"        => _INTL("Battle Effects"),
  "order"       => 40,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether you wish to see move animations in battle."),
  "get_proc"    => proc { next $PokemonSystem.battlescene },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlescene = value }
})

MenuHandlers.add(:options_menu, :contest_animations, {
  "name"        => _INTL("Contest Effects"),
  "order"       => 45,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Whether to show Pokémon animations during Performance Contests."),
  "get_proc"    => proc { next $PokemonSystem.contestanimations },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.contestanimations = value }
})

MenuHandlers.add(:options_menu, :battle_style, {
  "name"        => _INTL("Battle Style"),
  "order"       => 50,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Switch"), _INTL("Set")],
  "description" => _INTL("Choose whether you can switch Pokémon when an opponent's Pokémon faints."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlestyle = value }
})

MenuHandlers.add(:options_menu, :movement_style, {
  "name"        => _INTL("Default Movement"),
  "order"       => 60,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Walk"), _INTL("Run")],
  "description" => _INTL("Choose your movement speed. Hold Back while moving to move at the other speed."),
  "condition"   => proc { next $player&.has_running_shoes },
  "get_proc"    => proc { next $PokemonSystem.runstyle },
  "set_proc"    => proc { |value, _sceme| $PokemonSystem.runstyle = value }
})

MenuHandlers.add(:options_menu, :send_to_boxes, {
  "name"        => _INTL("Send to Boxes"),
  "order"       => 70,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Manual"), _INTL("Auto")],
  "description" => _INTL("Choose whether caught Pokémon are sent to your Boxes when your party is full."),
  "condition"   => proc { next Settings::NEW_CAPTURE_CAN_REPLACE_PARTY_MEMBER },
  "get_proc"    => proc { next $PokemonSystem.sendtoboxes },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.sendtoboxes = value }
})

MenuHandlers.add(:options_menu, :give_nicknames, {
  "name"        => _INTL("Nicknames"),
  "order"       => 80,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Give"), _INTL("Don't")],
  "description" => _INTL("Choose whether you can give a nickname to a Pokémon when you obtain it."),
  "get_proc"    => proc { next $PokemonSystem.givenicknames },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.givenicknames = value }
})

MenuHandlers.add(:options_menu, :menu_description, {
  "name"        => _INTL("Menu Account"),
  "order"       => 85,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether you wish to see pause menu command description."),
  "get_proc"    => proc { $PokemonSystem.pause_menu_desc = 1 if !$PokemonSystem.pause_menu_desc
                          next $PokemonSystem.pause_menu_desc },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.pause_menu_desc = value }
})

 MenuHandlers.add(:options_menu, :speech_frame, {
   "name"        => _INTL("Speech Frame"),
   "order"       => 90,
   "type"        => NumberOption,
   "parameters"  => 1..Settings::SPEECH_WINDOWSKINS.length,
   "description" => _INTL("Choose the appearance of dialogue boxes."),
   "condition"   => proc { next Settings::SPEECH_WINDOWSKINS.length > 1 },
   "get_proc"    => proc { next $PokemonSystem.textskin },
   "set_proc"    => proc { |value, scene|
     $PokemonSystem.textskin = value
     MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + Settings::SPEECH_WINDOWSKINS[value])
     # Change the windowskin of the options text box to selected one
     # scene.sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame)
   }
 })

MenuHandlers.add(:options_menu, :menu_frame, {
  "name"        => _INTL("Frame"),
  "order"       => 100,
  "type"        => NumberOption,
  "parameters"  => 1..Settings::MENU_WINDOWSKINS.length,
  "description" => _INTL("Choose the appearance of menu boxes."),
  "condition"   => proc { next Settings::MENU_WINDOWSKINS.length > 1 },
  "get_proc"    => proc { next $PokemonSystem.frame },
  "set_proc"    => proc { |value, scene|
    $PokemonSystem.frame = value
    $PokemonSystem.textskin = value
    MessageConfig.pbSetSystemFrame("Graphics/Windowskins/" + Settings::MENU_WINDOWSKINS[value])
    MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + Settings::SPEECH_WINDOWSKINS[value])
    # Change the windowskin of the options text box to selected one
    scene.sprites["option"].setSkin(MessageConfig.pbGetSystemFrame)
  }
})

MenuHandlers.add(:options_menu, :text_input_style, {
  "name"        => _INTL("Text Entry"),
  "order"       => 110,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Cursor"), _INTL("Keyboard")],
  "description" => _INTL("Choose how you want to enter text."),
  "get_proc"    => proc { next $PokemonSystem.textinput },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.textinput = value }
})

MenuHandlers.add(:options_menu, :screen_size, {
  "name"        => _INTL("Screen Size"),
  "order"       => 120,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Small"), _INTL("Medium"), _INTL("Large"), _INTL("XL"), _INTL("Full")],
  "description" => _INTL("Choose the size of the game window."),
  "get_proc"    => proc { next [$PokemonSystem.screensize, 4].min },
  "set_proc"    => proc { |value, _scene|
    next if $PokemonSystem.screensize == value
    $PokemonSystem.screensize = value
    pbSetResizeFactor($PokemonSystem.screensize)
  }
})

  MenuHandlers.add(:options_menu, :visible_overworld_toggle, {
  "name"        => _INTL("Overworld Encounters"),
  "order"       => 65,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Toggle visible overworld encounters. On = overworld only, Off = instant battles."),
  "get_proc"    => proc {
    next ($PokemonSystem.instant_battle_prob.to_i >= 100) ? 1 : 0
  },
  "set_proc"    => proc { |value, _scene|
    # 0 => On (overworld only), 1 => Off (instant only)
    $PokemonSystem.instant_battle_prob = (value == 0) ? 0 : 200
  }
})
# Ensure the option exists on old saves and applies the new default if nil
if defined?($PokemonSystem) && $PokemonSystem
  unless $PokemonSystem.respond_to?(:instant_battle_prob)
    class << $PokemonSystem; attr_accessor :instant_battle_prob; end
  end
  if $PokemonSystem.instant_battle_prob.nil?
    $PokemonSystem.instant_battle_prob = Settings::INSTANT_BATTLE_PROB_DEFAULT
  end
end

MenuHandlers.add(:options_menu, :show_online_players, {
  "name"        => _INTL("Online Players"),
  "order"       => 75,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Show"), _INTL("Hide")],
  "description" => _INTL("Show or hide other players in the overworld."),
  "get_proc"    => proc { next $PokemonSystem.show_online_players },
  "set_proc"    => proc { |value, _scene|
    $PokemonSystem.show_online_players = value
    NetworkOverworld.refresh_visibility if defined?(NetworkOverworld)
  }
})

MenuHandlers.add(:options_menu, :chat_sounds, {
  "name"        => _INTL("Chat Sounds"),
  "order"       => 76,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Play a sound when a chat message or announcement is received."),
  "get_proc"    => proc { next $PokemonSystem.chat_sounds },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.chat_sounds = value }
})

