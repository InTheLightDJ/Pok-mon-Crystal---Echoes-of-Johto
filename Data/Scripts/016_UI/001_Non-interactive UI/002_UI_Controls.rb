#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Shows a help screen listing the keyboard controls.
# Display with:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/UI/bg_white_general")
    @labels = []
    @label_screens = []
    @keys = []
    @key_screens = []

    # Arrows, USE and BACK keys
    addImageForScreen(1, 12, 16, _INTL("Graphics/UI/Controls help/help_arrows"))
    addLabelForScreen(1, 100, 14, 220, _INTL("Moves the player and scroll through entries."))
    addImageForScreen(1, 26, 116, _INTL("Graphics/UI/Controls help/help_usekey"))
    addLabelForScreen(1, 84, 114, 220, _INTL("Confirm, check and talk."))
    addImageForScreen(1, 26, 192, _INTL("Graphics/UI/Controls help/help_backkey"))
    addLabelForScreen(1, 84, 190, 220, _INTL("Exit or cancel. While moving, hold to run."))

    # Special and Registered Item keys
    addImageForScreen(2, 26, 16, _INTL("Graphics/UI/Controls help/help_specialkey"))
    addLabelForScreen(2, 84, 14, 220, _INTL("Opens the Pause Menu and other functions."))
    addImageForScreen(2, 26, 128, _INTL("Graphics/UI/Controls help/help_f5"))
    addLabelForScreen(2, 84, 126, 220, _INTL("Opens the Ready Menu, where registered items and field moves can be used."))

    set_up_screen(@current_screen)
    Graphics.transition
    # Go to next screen when user presses USE
    onCTrigger.set(method(:pbOnScreenEnd))
  end

  def addLabelForScreen(number, x, y, width, text)
    @labels.push(addLabel(x, y, width, text))
    @label_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def addImageForScreen(number, x, y, filename)
    @keys.push(addImage(x, y, filename))
    @key_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def set_up_screen(number)
    @label_screens.each_with_index do |screen, i|
      @labels[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    @key_screens.each_with_index do |screen, i|
      @keys[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    pictureWait   # Update event scene with the changes
  end

  def pbOnScreenEnd(scene, *args)
    last_screen = [@label_screens.max, @key_screens.max].max
    if @current_screen >= last_screen
      # End scene
      $game_temp.background_bitmap = Graphics.snap_to_bitmap
      Graphics.freeze
      @viewport.color = Color.black   # Ensure screen is black
      Graphics.transition(8, "fadetoblack")
      $game_temp.background_bitmap.dispose
      scene.dispose
    else
      # Next screen
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end
