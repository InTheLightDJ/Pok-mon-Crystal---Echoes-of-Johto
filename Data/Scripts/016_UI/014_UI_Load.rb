class Player
  attr_accessor :new_game_plus_unlocked
  alias __ngp_init initialize
  def initialize(*args)
    __ngp_init(*args)
    @new_game_plus_unlocked ||= false
  end
end

# ========= New Game+ : PC Item carryover helpers =========
module NGPlus
  # Set to true if you also want to keep the Metadata starter item in the PC.
  KEEP_STARTING_PC_ITEM = false

  # Returns an array of [item_symbol, quantity] from a PCItemStorage-like object.
  def self.extract_pc_items(storage)
    return [] if !storage
    # Try common APIs in newer/older Essentials
    if storage.respond_to?(:items)
      list = storage.items
      return list.map { |itm, qty| [itm, qty] }
    end
    if storage.respond_to?(:to_h)
      h = storage.to_h
      return h.map { |k, v| [k, v] }
    end
    iv = storage.instance_variable_get(:@items) rescue nil
    if iv.is_a?(Hash)
      return iv.map { |k, v| [k, v] }
    elsif iv.is_a?(Array)
      return iv.map do |e|
        if e.is_a?(Array)
          [e[0], e[1] || 1]
        elsif e.respond_to?(:item) && e.respond_to?(:quantity)
          [e.item, e.quantity]
        else
          nil
        end
      end.compact
    end
    []
  end

  # Clears target storage (unless keeping starter item) and adds items.
  def self.restore_pc_items(target_storage, items)
    return if !target_storage
    unless KEEP_STARTING_PC_ITEM
      if target_storage.respond_to?(:clear)
        target_storage.clear
      else
        begin
          target_storage.instance_variable_set(:@items, {})
        rescue; end
      end
    end
    items.each do |itm, qty|
      next if !itm || !qty || qty <= 0
      if target_storage.respond_to?(:add)
        target_storage.add(itm, qty)
      else
        # Emergency fallback if no API present
        h = (target_storage.instance_variable_get(:@items) rescue {}) || {}
        h[itm] = (h[itm] || 0) + qty
        begin
          target_storage.instance_variable_set(:@items, h)
        rescue; end
      end
    end
  end
end


#===============================================================================
#
#===============================================================================
class PokemonLoad_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands, show_continue, trainer, stats, map_id, cmd_new_game_plus = -1)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    @sprites["background"] = ColoredPlane.new(Color.new(248, 248, 248), @viewport)
    @sprites["cmdwindow"]  = Window_CommandPokemon.new(commands)
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_AdvancedTextPokemon.newWithSize(
      "", 0, Graphics.height - 64, Graphics.width, 64, @viewport)
    @sprites["infowindow"].letterbyletter = false
    @sprites["infowindow"].viewport = @viewport
    @sprites["infowindow"].visible = show_continue
    if show_continue
      time = pbGetTimeNow
      wday = time.wday
      day = [
        _INTL("Sunday"),
        _INTL("Monday"),
        _INTL("Tuesday"),
        _INTL("Wednesday"),
        _INTL("Thursday"),
        _INTL("Friday"),
        _INTL("Saturday")][wday]
      hour = (time.hour >= 24) ? time.hour - 24 : time.hour
      min = time.min
      # Times of day
      # Morning --> 04:00 - 09:59
      # Day --> 10:00 - 17:59
      # Night --> 18:00 - 3:59
      case hour
        when 4...10 then
          daymomt = "Morn"
        when 10...18 then
          daymomt = "Day" 
        else
          daymomt = "Nite"
      end
      digit = (min >= 10 ? nil : 0)
      @sprites["infowindow"].setText(_INTL("{1}<r>{2} {3}:{4}{5}", day, daymomt, hour, digit, min))
      # player window
      totalsec = stats&.play_time.to_i || 0
      @sprites["playerwindow"] = pbDisplayPlayerDataWindow(trainer, totalsec, map_id, @viewport, -1)
      @sprites["playerwindow"].visible = false
    end
  end

  def pbStartScene2
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartDeleteScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    @sprites["background"] = ColoredPlane.new(Color.new(248, 248, 248), @viewport)
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE)
        return @sprites["cmdwindow"].index
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbCloseScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def showPlayerWindow(show = true)
    @sprites["cmdwindow"].visible    = !show
    @sprites["infowindow"].visible   = !show
    @sprites["playerwindow"].visible = show
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    if SaveData.exists?
      @save_data = load_save_file(SaveData::FILE_PATH)
    else
      @save_data = {}
    end
  end

  # @param file_path [String] file to load save data from
  # @return [Hash] save data
  def load_save_file(file_path)
    save_data = SaveData.read_from_file(file_path)
    unless SaveData.valid?(save_data)
      if File.file?(file_path + ".bak")
        pbMessage(_INTL("The save file is corrupt. A backup will be loaded."))
        save_data = load_save_file(file_path + ".bak")
      else
        self.prompt_save_deletion
        return {}
      end
    end
    return save_data
  end

  # Called if all save data is invalid.
  # Prompts the player to delete the save files.
  def prompt_save_deletion
    pbMessage(_INTL("The save file is corrupt, or is incompatible with this game.") + "\1")
    exit unless pbConfirmMessageSerious(
      _INTL("Do you want to delete the save file and start anew?")
    )
    self.delete_save_data
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new
  end

  def pbStartDeleteScreen
    @scene.pbStartDeleteScene
    @scene.pbStartScene2
    if SaveData.exists?
      if pbConfirmMessageSerious(_INTL("Delete all saved data?"))
        pbMessage(_INTL("Once data has been deleted, there is no way to recover it.") + "\1")
        if pbConfirmMessageSerious(_INTL("Delete the saved data anyway?"))
          pbMessage(_INTL("Deleting all data. Don't turn off the power.") + "\\wtnp[0]")
          self.delete_save_data
        end
      end
    else
      pbMessage(_INTL("No save file was found."))
    end
    @scene.pbEndScene
    $scene = pbCallTitle
  end

  def delete_save_data
    begin
      SaveData.delete_file
      pbMessage(_INTL("The saved data was deleted."))
    rescue SystemCallError
      pbMessage(_INTL("All saved data could not be deleted."))
    end
  end

  def pbStartLoadScreen
    if $DEBUG && !FileTest.exist?("Game.rgssad") && Settings::SKIP_CONTINUE_SCREEN
      if @save_data.empty?
        Game.start_new
      else
        Game.load(@save_data)
      end
      return
    end
    pbBGMPlay("Continue Screen")
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_mystery_gift = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continue")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("Mystery Gift")
      end
    end
    commands[cmd_new_game = commands.length]  = _INTL("New Game")
    # --- NEW GAME PLUS (only if unlocked on this save) ---
if show_continue &&
   @save_data[:player] &&
   @save_data[:player].respond_to?(:new_game_plus_unlocked) &&
   @save_data[:player].new_game_plus_unlocked
  commands[cmd_new_game_plus = commands.length] = _INTL("New Game +")
end
    commands[cmd_options = commands.length]   = _INTL("Options")
    commands[cmd_language = commands.length]  = _INTL("Language") if Settings::LANGUAGES.length >= 2
    commands[cmd_debug = commands.length]     = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length]      = _INTL("Quit Game")
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        confirm = false
        @scene.showPlayerWindow
        loop do
          Graphics.update
          Input.update
          if Input.trigger?(Input::USE)
            confirm = true
            break
          elsif Input.trigger?(Input::BACK)
            break
          end
        end
        if confirm
          @scene.pbEndScene
          pbBGMFade(0.8)
          Game.load(@save_data)
          # Auto-connect immediately on Continue. The daily-wheel popup this can
          # trigger now draws on a viewport above every other UI layer (see
          # Scene_DailyWheel's z=100000 in 007_NetworkTokens.rb), so it's no
          # longer at risk of rendering invisibly behind/beneath other windows.
          begin
            if NetworkAuth.auto_connect(silent: true)
              system("start \"\" msedge --user-data-dir=\"%LOCALAPPDATA%\\EojChatData\" --app=\"http://#{NetworkClient::HOST}:5052?name=#{NetworkAuth.username}\" --window-size=320,580 --window-position=1270,80")
            end
          rescue => e
            puts "[AutoConnect] #{e.message}"
          end
          return
        end
        @scene.showPlayerWindow(false)
      when cmd_new_game
        @scene.pbEndScene
        pbBGMFade(0.8)
        $PokemonSystem.instant_battle_prob = 200
        Game.start_new
        return
      when cmd_new_game_plus
  # Optional: ask for confirmation
  if pbConfirmMessage(_INTL("Start New Game+?\nAll PC Pokémon Storage will carry over."))
    # --- grab old PC Pokémon + PC Items BEFORE new game ---
    old_storage  = (@save_data[:pokemon_storage] || @save_data[:storage_system] || @save_data[:storage]) rescue nil
    old_pg       = @save_data[:pokemon_global] rescue nil
    old_pc_items = nil
    if old_pg && old_pg.respond_to?(:pcItemStorage)
      old_pc_items = old_pg.pcItemStorage
    else
      # fallback key some packs use
      old_pc_items = @save_data[:pc_item_storage] rescue nil
    end

    boxes_copy     = old_storage ? Marshal.load(Marshal.dump(old_storage)) : nil
    pc_items_array = NGPlus.extract_pc_items(old_pc_items)

    @scene.pbEndScene
    pbBGMFade(0.8)
    Game.start_new

    # Restore PC Pokémon
    $PokemonStorage = boxes_copy if boxes_copy

    # Restore PC Item Storage (clear then add; avoids Metadata starter overwriting)
    NGPlus.restore_pc_items($PokemonGlobal.pcItemStorage, pc_items_array)

    return
  end
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_debug
        pbFadeOutIn { pbDebugMenu(false) }
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end
end
