#===============================================================================
# Pokémon Stadium launcher.  Event call:  pbPokemonStadium
#
# Starts the Pokémon Stadium PC port (Stadium-mod) at its Menu Select screen with
# the player's Pokémon on a Game Boy cart in player 1's Transfer Pak:
#   1. the party and PC (Gen 1-compatible Pokémon) are written into a Gen 1 save
#      (StadiumGen1.build_save) = the cart's battery save, <save folder>/Stadium/tpak/p1.sav
#   2. Stadium runs; this game waits (window kept alive, music paused)
#   3. afterwards the save is read back: Pokémon that weren't sent (e.g. a prize from
#      Gym Leader Castle) come over to the player's party / PC.
#
# The cart itself is a Pokémon Red/Blue/Yellow Game Boy image (the Transfer Pak needs
# the cartridge, Stadium checks which game it is): p1.gb in the same folder. If it's
# missing it's copied from one of CART_SOURCES.
#===============================================================================
module PokemonStadium
  # Stadium1.exe, relative to the game folder (first one found)
  EXE_PATHS = [
    "Stadium/Stadium1.exe",
    "../Stadium-mod/port/build/Release/Stadium1.exe"
  ]
  # where a Gen 1 cart image can be found if tpak/p1.gb isn't there yet
  CART_SOURCES = [
    "Stadium/cart.gb", "Stadium/cart.gbc",
    File.join(ENV["LOCALAPPDATA"].to_s, "EchoesOfJohto-Stadium1", "tpak", "p1.gb")
  ]

  module_function

  def game_dir
    return File.expand_path(".")
  end

  def exe_path
    EXE_PATHS.each do |p|
      full = File.expand_path(p, game_dir)
      return full if File.file?(full)
    end
    return nil
  end

  def base_dir
    dir = File.join(RTP.getSaveFolder, "Stadium")
    Dir.mkdir(dir) if !File.directory?(dir)
    return dir
  end

  def tpak_dir
    dir = File.join(base_dir, "tpak")
    Dir.mkdir(dir) if !File.directory?(dir)
    return dir
  end

  # an empty Transfer Pak folder: no cart plugged in
  def no_cart_dir
    dir = File.join(base_dir, "no_cart")
    Dir.mkdir(dir) if !File.directory?(dir)
    return dir
  end

  def ensure_cart(dir)
    cart = File.join(dir, "p1.gb")
    return true if File.file?(cart)
    CART_SOURCES.each do |src|
      full = File.expand_path(src, game_dir)
      next if !File.file?(full) || File.size(full) < 0x8000
      File.binwrite(cart, File.binread(full))
      return true
    end
    return false
  end

  # [party records, 12 box records arrays, number left behind]
  def collect
    left = 0
    convert = lambda do |pkmn|
      r = StadiumGen1.from_pokemon(pkmn)
      left += 1 if pkmn && !r
      r
    end
    party = $player.party.map { |p| convert.call(p) }.compact
    pc = []
    $PokemonStorage.maxBoxes.times do |b|
      $PokemonStorage.maxPokemon(b).times do |i|
        r = convert.call($PokemonStorage[b, i])
        pc << r if r
      end
    end
    # a Gen 1 save always has someone in the party
    party << pc.shift if party.empty? && !pc.empty?
    room = StadiumGen1::BOX_COUNT * StadiumGen1::BOX_SLOTS
    left += [pc.length - room, 0].max
    pc = pc.first(room)
    boxes = Array.new(StadiumGen1::BOX_COUNT) { |n| pc[n * StadiumGen1::BOX_SLOTS, StadiumGen1::BOX_SLOTS] || [] }
    return [party, boxes, left]
  end

  def run(exe, cart_dir)
    exe = exe.tr("/", "\\")
    # [path, argv0]: run that file directly (a plain string would be split at the
    # spaces in the path as a command line)
    pvp_dir = PokemonStadiumPVP.start
    begin
      pid = Process.spawn({ "STADIUM_TPAK_DIR" => cart_dir.tr("/", "\\"),
                            "STADIUM_PVP_DIR"  => pvp_dir.tr("/", "\\") }, [exe, exe],
                          :chdir => File.dirname(exe))
    rescue SystemCallError => e
      PokemonStadiumPVP.finish
      pbMessage(_INTL("Pokémon Stadium couldn't be started ({1}).", e.message))
      return false
    end
    # No Graphics.update while Stadium runs: with Echoes' window in the background it
    # can stall for minutes, and the PVP relay with it. (mkxp-z keeps the window alive
    # on its own thread.) Playing Stadium counts as activity for the AFK timer.
    loop do
      PokemonStadiumPVP.update
      NetworkIdleTimer.reset if defined?(NetworkIdleTimer)
      break if Process.waitpid(pid, Process::WNOHANG)
      sleep(0.05)
    end
    Graphics.update
    Input.update
    PokemonStadiumPVP.finish
    return true
  end

  def import_new(sav, prints)
    return [] if !File.file?(sav)
    left = Hash.new(0)
    prints.each { |fp| left[fp] += 1 }
    received = []
    StadiumGen1.read_save(File.binread(sav)).each do |r|
      fp = StadiumGen1.fingerprint(r[:bytes], r[:ot], r[:nick])
      if left[fp] > 0
        left[fp] -= 1
        next
      end
      received << StadiumGen1.to_pokemon(r)
    end
    return received
  end

  def play
    exe = exe_path
    if !exe
      pbMessage(_INTL("Pokémon Stadium isn't installed (Stadium/Stadium1.exe is missing)."))
      return false
    end
    dir = tpak_dir
    party, boxes, left = collect
    cart_dir = dir
    prints = []
    if party.empty?
      pbMessage(_INTL("None of your Pokémon can go to Pokémon Stadium. Only the original 151 can make the trip, so it'll be Rental Pokémon this time."))
      cart_dir = no_cart_dir
    elsif !ensure_cart(dir)
      pbMessage(_INTL("There's no Game Boy cartridge for the Transfer Pak, so your Pokémon will stay here. It'll be Rental Pokémon this time."))
      cart_dir = no_cart_dir
    else
      data, prints = StadiumGen1.build_save($player, party, boxes)
      File.binwrite(File.join(dir, "p1.sav"), data)
      if left > 0
        pbMessage(_INTL("{1} of your Pokémon can't make the trip. Only the original 151, in their usual forms, can go to Pokémon Stadium.", left))
      end
    end
    $game_system.bgm_memorize
    $game_system.bgs_memorize
    pbBGMStop
    pbBGSStop
    ran = run(exe, cart_dir)
    $game_system.bgm_restore
    $game_system.bgs_restore
    return false if !ran
    return true if cart_dir != dir
    import_new(File.join(dir, "p1.sav"), prints).each do |pkmn|
      $player.pokedex.register(pkmn)
      $player.pokedex.set_owned(pkmn.species)
      if $player.party_full?
        box = $PokemonStorage.pbStoreCaught(pkmn)
        pbMessage(_INTL("{1} came back from Pokémon Stadium and was sent to Box \"{2}\"!",
                        pkmn.name, $PokemonStorage[box].name))
      else
        $player.party << pkmn
        pbMessage(_INTL("{1} came back from Pokémon Stadium!", pkmn.name))
      end
    end
    return true
  end
end

def pbPokemonStadium
  return PokemonStadium.play
end
