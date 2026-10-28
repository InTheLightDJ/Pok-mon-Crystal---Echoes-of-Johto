#==============================================================================
# Pokémon Pinball (GBC) - sound. The game's own audio engine keeps running
# (the game reads its state, e.g. to wait for a cry), but its sound chip
# writes go nowhere: the songs, sound effects, cries and Pikachu's voice play
# from OGGs rendered offline from that same engine
# (Pinball-mod/tools/record_audio.rb + apu.py):
#   Audio/BGM/Pinball/MUSIC_*.ogg   songs (with LOOPSTART / LOOPLENGTH)
#   Audio/SE/Pinball/SFX_XX.ogg     sound effects (id in hex)
#   Audio/SE/Pinball/CRY_NNN.ogg    cries (dex number)
#   Audio/SE/Pinball/PIKACHU_N.ogg  the two Pikachu voice clips
# Hooked routines (always called through Machine#run_key, see HOOKABLE in
# recompile_gbc.py): PlaySong, PlaySoundEffect, PlayCry, PlayPikachuSoundClip.
#==============================================================================
module PinballGBC
  # [song bank, id] => file (constants/song_constants.asm)
  SONGS = {
    [0x0f, 1] => "MUSIC_RED_FIELD", [0x0f, 2] => "MUSIC_CATCH_EM_RED", [0x0f, 3] => "MUSIC_HURRY_UP_RED",
    [0x0f, 4] => "MUSIC_POKEDEX", [0x0f, 5] => "MUSIC_GASTLY_GRAVEYARD", [0x0f, 6] => "MUSIC_HAUNTER_GRAVEYARD",
    [0x0f, 7] => "MUSIC_GENGAR_GRAVEYARD",
    [0x10, 1] => "MUSIC_BLUE_FIELD", [0x10, 2] => "MUSIC_CATCH_EM_BLUE", [0x10, 3] => "MUSIC_HURRY_UP_BLUE",
    [0x10, 4] => "MUSIC_HI_SCORE", [0x10, 5] => "MUSIC_GAME_OVER",
    [0x11, 1] => "MUSIC_WHACK_DIGLETT", [0x11, 2] => "MUSIC_WHACK_DUGTRIO", [0x11, 3] => "MUSIC_SEEL_STAGE",
    [0x11, 4] => "MUSIC_TITLE_SCREEN",
    [0x12, 1] => "MUSIC_MEWTWO_STAGE", [0x12, 2] => "MUSIC_OPTIONS", [0x12, 3] => "MUSIC_FIELD_SELECT",
    [0x12, 4] => "MUSIC_MEOWTH_STAGE",
    [0x13, 1] => "MUSIC_END_CREDITS", [0x13, 2] => "MUSIC_NAME_ENTRY"
  }

  # WRAM bank 1 variables (index into Machine#wram)
  W_CURRENT_SONG_BANK = 0x1000 + (0xd85b - 0xd000)
  W_SFX_TIMER         = 0x1000 + (0xd800 - 0xd000)
  W_DEAD              = 0x1000 + (0xdead - 0xd000)

  KEY_PLAY_SONG   = 0x0490
  KEY_PLAY_SFX    = 0x04af
  KEY_PLAY_CRY    = 0x04ef
  KEY_PIKACHU_PCM = (0x14 << 16) | 0x4000

  module Sound
    module_function

    def install(m)
      m.hooks[KEY_PLAY_SONG] = lambda do |mm|
        song = SONGS[[mm.wram[W_CURRENT_SONG_BANK], mm.e]]
        r = mm.send(:f_00_0490)
        song ? bgm(song) : stop
        r
      end
      m.hooks[KEY_PLAY_SFX] = lambda do |mm|
        # the engine skips it while another one with a duration is running
        accepted = mm.wram[W_DEAD] == 0 && (mm.wram[W_SFX_TIMER] == 0 || mm.d != 0)
        id = mm.e
        r = mm.send(:f_00_04af)
        se(format("SFX_%02X", id)) if accepted
        r
      end
      m.hooks[KEY_PLAY_CRY] = lambda do |mm|
        id = mm.e
        r = mm.send(:f_00_04ef)
        se(format("CRY_%03d", id)) if id.between?(1, 151)
        r
      end
      m.hooks[KEY_PIKACHU_PCM] = lambda do |mm|
        se("PIKACHU_#{mm.a & 1}")
        mm.send(:f_14_4000)
      end
    end

    def bgm(name)
      return if name == @current
      @current = name
      pbBGMPlay("Pinball/" + name)
    rescue StandardError
      nil
    end

    def stop
      @current = nil
      pbBGMStop rescue nil
    end

    def se(name)
      pbSEPlay("Pinball/" + name)
    rescue StandardError
      nil
    end
  end
end
