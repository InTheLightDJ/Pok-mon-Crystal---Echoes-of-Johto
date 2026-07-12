#===============================================================================
# Evolution screen
#===============================================================================
class PokemonEvolutionScene
  def self.pbDuplicatePokemon(pkmn, new_species)
    new_pkmn = pkmn.clone
    new_pkmn.species   = new_species
    new_pkmn.name      = nil
    new_pkmn.markings  = []
    new_pkmn.poke_ball = :POKEBALL
    new_pkmn.item      = nil
    new_pkmn.clearAllRibbons
    new_pkmn.calc_stats
    new_pkmn.heal
    # Add duplicate Pokémon to party
    $player.party.push(new_pkmn)
    # See and own duplicate Pokémon
    $player.pokedex.register(new_pkmn)
    $player.pokedex.set_owned(new_species)
  end

  def pbStartScreen(pokemon, newspecies)
    @pokemon = pokemon
    @newspecies = newspecies
    @sprites = {}
    @bgviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @bgviewport.z = 99999
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @msgviewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @msgviewport.z = 99999
    addBackgroundOrColoredPlane(@sprites, "background", "evolution_bg",
                                Color.new(248, 248, 248), @bgviewport)
    rsprite1 = PokemonSprite.new(@viewport)
    rsprite1.setOffset(PictureOrigin::CENTER)
    rsprite1.setPokemonBitmap(@pokemon, false)
    rsprite1.x = Graphics.width / 2
    rsprite1.y = (Graphics.height - 64) / 2
    rsprite2 = PokemonSprite.new(@viewport)
    rsprite2.setOffset(PictureOrigin::CENTER)
    rsprite2.setPokemonBitmapSpecies(@pokemon, @newspecies, false)
    rsprite2.x       = rsprite1.x
    rsprite2.y       = rsprite1.y
    rsprite2.visible = false
    @sprites["rsprite1"] = rsprite1
    @sprites["rsprite2"] = rsprite2
    @sprites["msgwindow"] = pbCreateMessageWindow(@msgviewport)
    @sprites["bubble"] = IconSprite.new(0, 0, @viewport)
    @sprites["bubble"].setBitmap("Graphics/UI/Evolution/Evolution_bubble")
    @sprites["bubble"].src_rect.set(0, 0, Graphics.width, Graphics.height)
    @sprites["bubble"].visible = false
    set_up_animation
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def set_up_animation
    sprite = PictureEx.new(0)
    sprite.setVisible(0, true)
    # Make sprite turn dark
    sprite.setTone(0, Tone.new(-150, -150, -150, 255))
    sprite2 = PictureEx.new(0)
    sprite2.setVisible(0, false)
    # Make sprite turn dark
    sprite2.setTone(0, Tone.new(-150, -150, -150, 255))
    total_duration = 9 * 20   # 9 seconds
    duration = 15
    zoom_duration = 2
    loop do
      # Hide prevo sprite, unhide evo sprite
      sprite.setVisible(duration, false)
      sprite2.setVisible(duration, true)
      duration += zoom_duration
      # If animation has played for long enough, end it now while the evo sprite is unhide
      break if duration >= total_duration
      # Unhide prevo sprite, hide evo sprite
      sprite.setVisible(duration, true)
      sprite2.setVisible(duration, false)
      duration += zoom_duration
    end
    sprite2.setTone(duration, Tone.new(0, 0, 0, 0))
    @picture1 = sprite
    @picture2 = sprite2
  end

  # Opens the evolution screen
  def pbEvolution(cancancel = true)
    pbBGMStop
    pbMessageDisplay(@sprites["msgwindow"], "\\se[]" + _INTL("What?") + "\1") { pbUpdate }
    pbPlayDecisionSE
    @pokemon.play_cry
    @sprites["msgwindow"].text = _INTL("{1} is evolving!", @pokemon.name)
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      pbUpdate
      break if System.uptime - timer_start >= 1
    end
    pbBGMPlay("Evolution")
    canceled = false
    timer_start = System.uptime
    loop do
      @picture1.update
      setPictureSprite(@sprites["rsprite1"], @picture1)
      @picture2.update
      setPictureSprite(@sprites["rsprite2"], @picture2)
      Graphics.update
      Input.update
      pbUpdate(true)
      if Input.trigger?(Input::BACK) && cancancel
        pbBGMStop
        pbPlayCancelSE
        canceled = true
        break
      end
      break if !@picture1.running? && !@picture2.running?
    end
    pbFlashInOut(canceled)
    if canceled
      $stats.evolutions_cancelled += 1
      pbMessageDisplay(@sprites["msgwindow"],
                       _INTL("Huh? {1} stopped evolving!", @pokemon.name)) { pbUpdate }
    else
      # Bubble Animation
      @sprites["bubble"].visible = true
      loop do
        Graphics.update
        pbUpdate
        @sprites["bubble"].src_rect.x += Graphics.width
        break if @sprites["bubble"].src_rect.x >= 41 * Graphics.width
      end
      @sprites["bubble"].visible = false
      pbEvolutionSuccess
    end
  end

  def pbFlashInOut(canceled)
    @bgviewport.rect.y      = 0
    @bgviewport.rect.height = Graphics.height
    @sprites["background"].oy = 0
    if canceled
      @sprites["rsprite1"].visible     = true
      @sprites["rsprite1"].zoom_x      = 1.0
      @sprites["rsprite1"].zoom_y      = 1.0
      @sprites["rsprite1"].tone        = Tone.new(0, 0, 0, 0)
      @sprites["rsprite2"].visible     = false
    else
      @sprites["rsprite1"].visible     = false
      @sprites["rsprite2"].visible     = true
      @sprites["rsprite2"].zoom_x      = 1.0
      @sprites["rsprite2"].zoom_y      = 1.0
      @sprites["rsprite2"].tone        = Tone.new(0, 0, 0, 0)
    end
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate(true)
      break if System.uptime - timer_start >= 0.25
    end
  end

  def pbEvolutionSuccess
    $stats.evolution_count += 1
    # Play cry of evolved species
    cry_time = GameData::Species.cry_length(@newspecies, @pokemon.form)
    Pokemon.play_cry(@newspecies, @pokemon.form)
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      break if System.uptime - timer_start >= cry_time
    end
    pbBGMStop
    # Success jingle/message
    pbMEPlay("Evolution success")
    newspeciesname = GameData::Species.get(@newspecies).name
    pbMessageDisplay(@sprites["msgwindow"],
                     "\\se[]" + _INTL("Congratulations! Your {1} evolved into {2}!",
                                      @pokemon.name, newspeciesname) + "\\wt[80]") { pbUpdate }
    @sprites["msgwindow"].text = ""
    # Check for consumed item and check if Pokémon should be duplicated
    pbEvolutionMethodAfterEvolution
    # Modify Pokémon to make it evolved
    was_fainted = @pokemon.fainted?
    @pokemon.species = @newspecies
    @pokemon.hp = 0 if was_fainted
    @pokemon.calc_stats
    @pokemon.ready_to_evolve = false
    # See and own evolved species
    was_owned = $player.owned?(@newspecies)
    $player.pokedex.register(@pokemon)
    $player.pokedex.set_owned(@newspecies)
    moves_to_learn = []
    movelist = @pokemon.getMoveList
    movelist.each do |i|
      next if i[0] != 0 && i[0] != @pokemon.level   # 0 is "learn upon evolution"
      moves_to_learn.push(i[1])
    end
    # Show Pokédex entry for new species if it hasn't been owned before
    if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && !was_owned &&
       $player.has_pokedex && $player.pokedex.species_in_unlocked_dex?(@pokemon.species)
      pbMessageDisplay(@sprites["msgwindow"],
                       _INTL("{1}'s data was added to the Pokédex.", newspeciesname)) { pbUpdate }
      $player.pokedex.register_last_seen(@pokemon)
      pbFadeOutIn do
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbDexEntry(@pokemon.species)
        @sprites["msgwindow"].text = "" if moves_to_learn.length > 0
        pbEndScreen(false) if moves_to_learn.length == 0
      end
    end
    # Learn moves upon evolution for evolved species
    moves_to_learn.each do |move|
      pbLearnMove(@pokemon, move, true) { pbUpdate }
    end
  end

  def pbEvolutionMethodAfterEvolution
    @pokemon.action_after_evolution(@newspecies)
  end

  def pbUpdate(animating = false)
    if animating      # Pokémon shouldn't animate during the evolution animation
      @sprites["background"].update
      @sprites["msgwindow"].update
    else
      pbUpdateSpriteHash(@sprites)
    end
  end

  # Closes the evolution screen.
  def pbEndScreen(need_fade_out = true)
    pbDisposeMessageWindow(@sprites["msgwindow"]) if @sprites["msgwindow"]
    if need_fade_out
      pbFadeOutAndHide(@sprites) { pbUpdate }
    end
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    @bgviewport.dispose
    @msgviewport.dispose
  end
end
