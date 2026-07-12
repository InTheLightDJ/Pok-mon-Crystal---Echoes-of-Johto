#===============================================================================
#
#===============================================================================
class PokemonTrainerCard_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @trainercard_page = "front"
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["trainer"] = IconSprite.new(0, 0, @viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
    if !@sprites["trainer"].bitmap
      raise _INTL("No trainer front sprite exists for the player character, expected a file at {1}.",
                  "Graphics/Trainers/" + $player.trainer_type.to_s + ".png")
    end
    @sprites["trainer"].x = 200
    @sprites["trainer"].y = 17
    @sprites["trainer"].z = 2
    drawTrainerCardBadges
    drawTrainerCard(@trainercard_page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  #===============================================================================
  # Information for all trainer card pages
  #===============================================================================
  def drawTrainerCard(trainercard_page)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(0, 0, 0)
    shadowColor = Color.new(248, 248, 248)
    # Set background image
    if $player.female?
      @sprites["background"].setBitmap("Graphics/UI/Trainer Card/bg_f_#{trainercard_page}")
    else
      @sprites["background"].setBitmap("Graphics/UI/Trainer Card/bg_#{trainercard_page}")
    end
    if trainercard_page == "badges1"
      chain_count = ($game_temp.catch_combo ? $game_temp.catch_combo[0] : 0).to_s
      textPositions = [
        [_INTL("Name/"), 32, 32, :left, baseColor, shadowColor],
        [$player.name, 112, 32, :left, baseColor, shadowColor],
        [sprintf("%05d", $player.public_ID), 80, 65, :left, baseColor, shadowColor],
        [_INTL("Counter"), 32, 104, :left, baseColor, shadowColor],
        [chain_count, 222, 104, :right, baseColor, shadowColor]
      ]
    else
      textPositions = [
        [_INTL("Name/"), 32, 32, :left, baseColor, shadowColor],
        [$player.name, 112, 32, :left, baseColor, shadowColor],
        [sprintf("%05d", $player.public_ID), 80, 65, :left, baseColor, shadowColor],
        [_INTL("Money"), 32, 104, :left, baseColor, shadowColor],
        [_INTL("${1}", $player.money.to_s_formatted), 222, 104, :right, baseColor, shadowColor]
      ]
    end
    if defined?(NetworkClient) && NetworkClient.connected?
      textPositions << [_INTL("S-Tokens"), 32, 85, :left, baseColor, shadowColor]
      textPositions << [NetworkTokens.balance.to_s, 222, 85, :right, baseColor, shadowColor]
    end
    pbDrawTextPositions(overlay, textPositions)
    # Draw trainer card page-specific information
    drawTrainerCardFront if trainercard_page == "front"
    # Johto badges (1-8, indices 0-7) — visible on "badges" page
    8.times do |i|
      @sprites["badge#{i + 1}"].visible = (trainercard_page == "badges" && $player.badges[i])
    end
    # Kanto badges (9-16, indices 8-15) — visible on "badges1" page
    8.times do |i|
      @sprites["badge#{i + 9}"].visible = (trainercard_page == "badges1" && $player.badges[i + 8])
    end
  end

  #===============================================================================
  # Information for just the front trainer card page
  #===============================================================================
  def drawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    baseColor = Color.new(0, 0, 0)
    shadowColor = Color.new(248, 248, 248)
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = (hour > 0) ? _INTL("{1}h {2}m", hour, min) : _INTL("{1}m", min)
    # Texts for trainer card front page
    textPositions = [
      [_INTL("Pokédex"), 32, 165, :left, baseColor, shadowColor],
      [sprintf("%d/%d", $player.pokedex.owned_count, $player.pokedex.seen_count), 300, 165, :right, baseColor, shadowColor],
      [_INTL("Play Time"), 32, 198, :left, baseColor, shadowColor],
      [time, 302, 198, :right, baseColor, shadowColor],
      [_INTL("Bug Tokens"), 32, 230, :left, baseColor, shadowColor],
      [$player.Bug_Tokens.to_s_formatted, 302, 230, :right, baseColor, shadowColor],
      [_INTL("Badges →"), 192, 250, :left, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
  end

  #===============================================================================
  # Badges
  #===============================================================================
  def drawTrainerCardBadges
    x_cols = [20, 87, 154, 221]
    y_rows = [177, 225]
    xs = x_cols * 2
    ys = [y_rows[0]] * 4 + [y_rows[1]] * 4
    # Johto badges (badge1-badge8) using badge_1 through badge_8 sprites
    8.times do |i|
      key = "badge#{i + 1}"
      @sprites[key] = AnimatedSprite.create("Graphics/UI/Trainer Card/badge_#{i + 1}", 4, 5, @viewport)
      @sprites[key].x = xs[i]
      @sprites[key].y = ys[i]
      @sprites[key].play
    end
    # Kanto badges (badge9-badge16) reusing badge_1 through badge_8 sprites
    8.times do |i|
      key = "badge#{i + 9}"
      @sprites[key] = AnimatedSprite.create("Graphics/UI/Trainer Card/badge_#{i + 1}", 4, 5, @viewport)
      @sprites[key].x = xs[i]
      @sprites[key].y = ys[i]
      @sprites[key].play
    end
  end

  def pbTrainerCard
    @last_badge_page = "badges"
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::RIGHT) || Input.trigger?(Input::LEFT)
        pbPlayDecisionSE
        if @trainercard_page == "front"
          @trainercard_page = @last_badge_page
        else
          @trainercard_page = "front"
        end
        dorefresh = true
      elsif Input.trigger?(Input::L) || Input.trigger?(Input::R)
        if @trainercard_page == "badges" || @trainercard_page == "badges1"
          pbPlayDecisionSE
          @trainercard_page = @trainercard_page == "badges" ? "badges1" : "badges"
          @last_badge_page = @trainercard_page
          dorefresh = true
        end
      end
      drawTrainerCard(@trainercard_page) if dorefresh
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end
