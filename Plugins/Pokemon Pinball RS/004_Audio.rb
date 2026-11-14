#==============================================================================
# Pokémon Pinball RS - sound. The game's m4a sound engine isn't run: its
# entry points (m4aSongNumStart, MPlayStart, m4aMPlayStop / Continue, the
# fades, SetPokemonCryTone...) are native here and play OGGs rendered
# offline from the same song data by a model of that engine
# (Pinball-mod/tools/rs/m4a_render.py):
#   Audio/BGM/PinballRS/<song>.ogg   music (LOOPSTART / LOOPLENGTH when it loops)
#   Audio/SE/PinballRS/<song>.ogg    sound effects, jingles that don't loop
#   Audio/SE/PinballRS/cry_NNN.ogg   cries (the game's cry id)
# The music player structs the game reads (gMPlayInfo_BGM.status /
# songHeader, for pausing and resuming) are kept up to date.
# SONGS / CRIES come with the translated code (package_rs.py).
#==============================================================================
module PinballRS
  module Sound
    PAUSE = 0x80000000
    BGM_DIR = "PinballRS/"

    module_function

    def install(m)
      @m = m
      @bgm = nil          # [song index, started at (frames), looping]
      @bgm_pos = 0
      @volume = 256
      @cry = {}
      @cry_until = 0
      set_status(m.sym("gMPlayInfo_BGM"), 0, PAUSE)
    end

    def stop
      Audio.bgm_stop rescue nil
      Audio.me_stop rescue nil
      Audio.se_stop rescue nil
      @bgm = nil
    end

    def bgm_info = @m.sym("gMPlayInfo_BGM")

    def set_status(info, header, status)
      @m.w32(info, header)
      @m.w32(info + 4, status)
    end

    def song_header(n)
      @m.sym(SONGS[n][0])
    rescue StandardError
      0
    end

    # m4aSongNumStart: BGM player songs replace the music, the others are SEs
    def start(n)
      name, player, seconds, loops = SONGS[n]
      return unless name
      if player == 0
        @bgm = [n, @m.frames, loops, seconds]
        @bgm_pos = 0
        set_status(bgm_info, song_header(n), 1)
        if loops
          play_bgm(name, 0)
        else
          Audio.bgm_stop rescue nil
          se(name)
        end
      else
        se(name)
      end
    end

    def play_bgm(name, pos)
      vol = (100 * @volume / 256).to_i
      $game_system.bgm_play_internal2("Audio/BGM/" + BGM_DIR + name, vol, 100, pos)
    rescue StandardError
      nil
    end

    def se(name, volume = 100, pitch = 100)
      pbSEPlay(BGM_DIR + name, volume, pitch)
    rescue StandardError
      nil
    end

    def bgm_song = @bgm && @bgm[0]

    # a jingle on the BGM player has ended by now
    def update
      return unless @bgm && !@bgm[2]
      return if @m.frames - @bgm[1] < @bgm[3] * 60
      @bgm = nil
      set_status(bgm_info, @m.r32(bgm_info), PAUSE)
    end

    def pause_bgm
      return unless @bgm
      @bgm_pos = (Audio.bgm_pos rescue 0) if @bgm[2]
      Audio.bgm_stop rescue nil
      set_status(bgm_info, @m.r32(bgm_info), @m.r32(bgm_info + 4) | PAUSE)
    end

    def continue_bgm
      return unless @bgm
      play_bgm(SONGS[@bgm[0]][0], @bgm_pos) if @bgm[2]
      set_status(bgm_info, @m.r32(bgm_info), 1)
    end

    def stop_all
      pause_bgm
      Audio.se_stop rescue nil
    end

    def bgm_player?(mp) = mp == bgm_info

    def header_song(header)
      name = Machine::SYMS.key(header)
      SONGS.index { |s| s[0] == name }
    end

    def fade_out(frames)
      Audio.bgm_fade((frames * 1000 / 60).to_i) rescue nil
      @bgm_pos = (Audio.bgm_pos rescue 0) if @bgm && @bgm[2]
      set_status(bgm_info, @m.r32(bgm_info), PAUSE)
    end

    def volume(v)
      @volume = v
      # bgm_play with the same file only changes the volume
      $game_system.bgm_play_internal2("Audio/BGM/" + BGM_DIR + SONGS[@bgm[0]][0], (100 * v / 256).to_i, 100, 0) if @bgm && @bgm[2]
    rescue StandardError
      nil
    end

    # cries: SetPokemonCry* set the next cry's settings, SetPokemonCryTone plays it
    def cry_setting(k, v) = @cry[k] = v

    def cry(tone)
      id = CRY_BANKS.each_with_index.find { |b, _| tone >= @m.sym(b) && tone < @m.sym(b) + 128 * 12 }
      return unless id
      bank = id[1]
      n = bank * 128 + (tone - @m.sym(id[0])) / 12
      file = CRIES[n]
      return unless file
      vol = [[(@cry[:volume] || 120) * 100 / 127, 100].min, 10].max
      se(file, vol)
      @cry_until = @m.frames + ((CRY_SECONDS[n] || 1.0) * 60).to_i
    end

    def cry_playing? = @m.frames < @cry_until
  end

  CRY_BANKS = %w[gPokemonCryToneBank0 gPokemonCryToneBank1 gPokemonCryToneBank2 gPokemonCryToneBank3]

  class Machine
    def f_m4aSoundInit = nil
    def f_m4aSoundMain = nil
    def f_m4aSoundVSync = Sound.update
    def f_m4aSoundVSyncOn = nil
    def f_m4aSoundVSyncOff = nil
    def f_m4aSoundMode(*) = nil
    def f_m4aSongNumStart(n) = Sound.start(n)

    def f_m4aSongNumStartOrChange(n)
      Sound.start(n) unless Sound.bgm_song == n && r32(Sound.bgm_info + 4) & Sound::PAUSE == 0
    end

    def f_m4aSongNumStartOrContinue(n)
      if Sound.bgm_song == n
        Sound.continue_bgm
      else
        Sound.start(n)
      end
    end

    def f_m4aSongNumStop(n)
      Sound.pause_bgm if Sound.bgm_song == n
    end

    def f_m4aSongNumContinue(n)
      Sound.continue_bgm if Sound.bgm_song == n
    end

    def f_m4aMPlayAllStop = Sound.stop_all

    def f_m4aMPlayStop(mp)
      Sound.bgm_player?(mp) ? Sound.pause_bgm : (Audio.se_stop rescue nil)
    end

    def f_m4aMPlayContinue(mp)
      Sound.continue_bgm if Sound.bgm_player?(mp)
    end

    def f_MPlayContinue(mp) = f_m4aMPlayContinue(mp)
    def f_m4aMPlayAllContinue = Sound.continue_bgm

    def f_MPlayStart(mp, header)
      n = Sound.header_song(header)
      Sound.start(n) if n
    end

    def f_m4aMPlayFadeOut(mp, speed)
      Sound.fade_out(speed * 16) if Sound.bgm_player?(mp)
    end

    def f_MPlayFadeOut(mp, speed) = f_m4aMPlayFadeOut(mp, speed)

    def f_m4aMPlayFadeOutTemporarily(mp, speed)
      Sound.fade_out(speed * 16) if Sound.bgm_player?(mp)
    end

    def f_m4aMPlayFadeIn(mp, speed)
      Sound.continue_bgm if Sound.bgm_player?(mp)
    end

    def f_m4aMPlayVolumeControl(mp, bits, volume)
      Sound.volume(volume) if Sound.bgm_player?(mp)
    end

    def f_SetPokemonCryVolume(v) = Sound.cry_setting(:volume, v)
    def f_SetPokemonCryPanpot(v) = Sound.cry_setting(:pan, v)
    def f_SetPokemonCryTone(tone) = Sound.cry(tone)
    def f_IsPokemonCryPlaying(*) = Sound.cry_playing? ? 1 : 0
  end
end
