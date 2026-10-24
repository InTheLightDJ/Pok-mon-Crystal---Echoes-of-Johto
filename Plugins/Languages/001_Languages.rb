#==============================================================================
# Languages - the game's languages, a language picker before the title
# screen the first time the game starts, and a Language option in Options.
#
# The chosen language is kept in "language.txt" next to the save file (not
# in the save), so it is known before any save is loaded and a new save
# doesn't ask again. Translations are the Essentials files
# Data/messages_<folder>_core.dat / _game.dat (made from the
# Text_<folder>_core / Text_<folder>_game folders).
#==============================================================================
module Settings
  remove_const(:LANGUAGES) if const_defined?(:LANGUAGES)
  # [name shown in the picker, file folder name]
  LANGUAGES = [
    ["English",   "english"],
    ["Español",   "spanish"],
    ["Deutsch",   "german"],
    ["Français",  "french"],
    ["Português", "portuguese"],
    ["Italiano",  "italian"]
  ]
end

module Languages
  FILE_NAME = "language.txt"

  module_function

  def file_path
    File.join(File.dirname(SaveData::FILE_PATH), FILE_NAME)
  end

  # index into Settings::LANGUAGES saved in language.txt, or nil
  def saved_index
    return nil unless File.exist?(file_path)
    folder = File.read(file_path).strip.downcase
    Settings::LANGUAGES.index { |l| l[1] == folder }
  rescue StandardError
    nil
  end

  def save_index(index)
    File.open(file_path, "wb") { |f| f.write(Settings::LANGUAGES[index][1]) }
  rescue StandardError
    nil   # read-only folder: the picker shows again next time
  end

  # switch the game's text to language `index` and remember it
  def apply(index)
    index = 0 unless index.is_a?(Integer) && Settings::LANGUAGES[index]
    $PokemonSystem.language = index if $PokemonSystem
    MessageTypes.load_message_files(Settings::LANGUAGES[index][1])
    save_index(index)
  end

  # black screen with the language names, before the title screen
  def choose_on_black_screen
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99_999
    bg = Sprite.new(viewport)
    bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    bg.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    title = Window_UnformattedTextPokemon.newWithSize(
      "Language / Idioma / Sprache\nLangue / Lingua", 0, 0, Graphics.width, 64, viewport
    )
    title.resizeToFit(title.text, Graphics.width)
    title.x = (Graphics.width - title.width) / 2
    cmds = Window_CommandPokemonEx.new(Settings::LANGUAGES.map { |l| l[0] })
    cmds.viewport = viewport
    cmds.resizeToFit(cmds.commands)
    cmds.x = (Graphics.width - cmds.width) / 2
    title.y = (Graphics.height - title.height - cmds.height) / 2
    cmds.y = title.y + title.height
    choice = nil
    loop do
      Graphics.update
      Input.update
      cmds.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        choice = cmds.index
        break
      end
    end
    choice
  ensure
    cmds&.dispose
    title&.dispose
    bg&.bitmap&.dispose
    bg&.dispose
    viewport&.dispose
  end
end

module Game
  # same as the original, but the language comes from language.txt; with no
  # language.txt yet, the player picks one on a black screen first
  def self.set_up_system
    save_data = (SaveData.exists?) ? SaveData.read_from_file(SaveData::FILE_PATH) : {}
    if save_data.empty?
      SaveData.initialize_bootup_values
    else
      SaveData.load_bootup_values(save_data)
    end
    pbSetResizeFactor([$PokemonSystem.screensize, 4].min)
    index = Languages.saved_index
    index ||= (Settings::LANGUAGES.length >= 2) ? Languages.choose_on_black_screen : 0
    Languages.apply(index)
  end
end

# the load screen's Language command (and anything else using this) also
# remembers the choice
alias languages_pbChooseLanguage pbChooseLanguage unless defined?(languages_pbChooseLanguage)
def pbChooseLanguage
  index = languages_pbChooseLanguage
  Languages.save_index(index)
  index
end

MenuHandlers.add(:options_menu, :language, {
  "name"        => _INTL("Language"),
  "order"       => 5,
  "type"        => EnumOption,
  "parameters"  => Settings::LANGUAGES.map { |l| l[0] },
  "description" => _INTL("Choose the language of the game's text."),
  "get_proc"    => proc { next $PokemonSystem.language || 0 },
  "set_proc"    => proc { |value, _scene|
    next if ($PokemonSystem.language || 0) == value
    Languages.apply(value)
  }
})
