#===============================================================================
# Pokémon Performance Contest Scene
# Call from an NPC event: pbStartContest(:BEAUTY, 0)
#   category : :COOL / :BEAUTY / :CUTE / :SMART / :TOUGH
#   rank     : 0=Normal  1=Super  2=Hyper  3=Master
#===============================================================================

#-------------------------------------------------------------------------------
# NPC pool data
#-------------------------------------------------------------------------------
module ContestNPCData
  NAMES = ["Lara","Kent","Mia","Beau","Suki","Hiro","Faye","Ned","Clem","Taro", "Kurt", 
"James", "Jessie", "sara", "Alyssa", "Smoke", "Rocket"]

  SPECIES = {
    :COOL   => [:ARCANINE,   :RAICHU,    :GYARADOS,  :SCYTHER,   :DRAGONAIR,
                :SNEASEL,    :RAPIDASH,  :FLAREON,   :JOLTEON,   :AERODACTYL,
                :CHARIZARD,  :TYPHLOSION,:FERALIGATR,:HERACROSS, :HOUNDOOM],
    :BEAUTY => [:VAPOREON,   :LAPRAS,    :NINETALES, :DEWGONG,   :MISDREAVUS,
                :CLEFABLE,   :ESPEON,    :TOGETIC,   :BELLOSSOM, :STARMIE,
                :CORSOLA,    :MANTINE,   :LANTURN,   :AZUMARILL, :BLISSEY],
    :CUTE   => [:JIGGLYPUFF, :CLEFAIRY,  :MARILL,    :TOGEPI,    :SNUBBULL,
                :PIKACHU,    :CLEFFA,    :IGGLYBUFF, :TEDDIURSA, :AIPOM,
                :MEOWTH,     :CHANSEY,   :EEVEE,     :CHIKORITA, :PHANPY],
    :SMART  => [:ALAKAZAM,   :GENGAR,    :ESPEON,    :SLOWBRO,   :XATU,
                :HYPNO,      :UMBREON,   :SLOWKING,  :STARMIE,   :PORYGON2,
                :MRMIME,     :NATU,      :JYNX,      :EXEGGUTOR, :GIRAFARIG],
    :TOUGH  => [:MACHAMP,    :GOLEM,     :SNORLAX,   :URSARING,  :STEELIX,
                :TYRANITAR,  :PRIMEAPE,  :HITMONLEE, :HITMONCHAN,:HITMONTOP,
                :RHYDON,     :NIDOKING,  :TAUROS,    :MILTANK,   :PINSIR]
  }

  # NORMAL appears twice so it is disliked roughly 2x as often as any other type.
  DISLIKE_TYPE_POOL = [
    :NORMAL, :NORMAL,
    :FIRE, :WATER, :GRASS, :ELECTRIC, :ICE, :FIGHTING,
    :POISON, :GROUND, :FLYING, :PSYCHIC, :BUG, :ROCK,
    :GHOST, :DRAGON, :DARK, :STEEL
  ].freeze

  # Pick up to `count` moves with contest data, preferring the right category.
  # min_appeal: skip moves whose effective appeal for `category` is below this.
  # max_twos:   keep at most this many moves with effective appeal == 2.
  def self.pick_moves(species, category, count = 4, min_appeal: 0, max_twos: nil)
    species_data = GameData::Species.try_get(species)
    return [] if !species_data

    candidates = []
    species_data.moves.each do |entry|
      move_id = entry[1]
      next if !ContestData.has_contest_data?(move_id)
      eff = ContestData.type_for(move_id) == category ? ContestData.appeal_for(move_id) : 1
      next if eff < min_appeal
      candidates.push([move_id, eff]) unless candidates.any? { |m, _| m == move_id }
    end

    candidates.sort_by! { |_, eff| -eff }

    if max_twos
      twos = 0
      candidates.select! do |_, eff|
        eff != 2 || (twos += 1) <= max_twos
      end
    end

    result = candidates.map { |m, _| m }[0, count]

    if min_appeal == 0
      [:TACKLE, :SCRATCH, :POUND, :GROWL].each do |m|
        break if result.length >= count
        result.push(m) unless result.include?(m)
      end
    end

    result.push(:TACKLE) if result.empty?
    return result[0, count]
  end
end

#-------------------------------------------------------------------------------
# Entry point — call from map event
#-------------------------------------------------------------------------------
def pbStartContest(category, rank, music = nil)
  cat_name  = PokemonContestState::CATEGORY_NAMES[category]  || category.to_s
  rank_name = PokemonContestState::RANK_NAMES[rank]           || "Normal"

  # Party pick
  chosen_pkmn = nil
  pbFadeOutIn do
    scene  = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    screen.pbStartScene(_INTL("Choose a Pokémon for the {1} Contest!", cat_name), false)
    idx = screen.pbChoosePokemon
    screen.pbEndScene
    chosen_pkmn = (idx >= 0) ? $player.party[idx] : nil
  end
  return if !chosen_pkmn || chosen_pkmn.egg?

  # Rank eligibility
  if rank > 0 && !pbContestState.eligible?(chosen_pkmn, category, rank)
    pbMessage(_INTL("{1} hasn't won the {2} {3} Rank contest yet!",
                    chosen_pkmn.name, cat_name, PokemonContestState::RANK_NAMES[rank - 1]))
    return
  end

  # Build NPC contestants — count and move quality scale with rank
  npc_count  = rank >= 1 ? 5 : 4
  min_appeal = rank >= 2 ? 2 : 0
  max_twos   = rank >= 3 ? 1 : nil

  name_pool    = ContestNPCData::NAMES.shuffle
  species_pool = (ContestNPCData::SPECIES[category] || ContestNPCData::SPECIES[:TOUGH]).dup
  contestants  = []
  npc_count.times do
    name    = name_pool.shift || "Trainer"
    species = species_pool[rand(species_pool.length)]
    level   = 20 + rank * 10
    pkmn    = Pokemon.new(species, level)
    moves   = ContestNPCData.pick_moves(species, category, 4,
                                        min_appeal: min_appeal, max_twos: max_twos)
    moves.each_with_index do |m, i|
      pkmn.moves[i] = Pokemon::Move.new(m) rescue nil
    end
    pkmn.calc_stats
    contestants.push({ :name => name, :pkmn => pkmn })
  end

  # Run the contest
  saved_bgm = music ? $game_system.playing_bgm : nil
  pbBGMPlay(music) if music
  pbContestState.start(category, rank)
  scene = PokemonContestScene.new(chosen_pkmn, category, rank, contestants)
  won   = scene.pbContestMain
  pbContestState.finish
  $game_system.bgm_play(saved_bgm) if saved_bgm

  if won
    ribbon = pbContestState.ribbon_for(category, rank)
    if ribbon && !chosen_pkmn.hasRibbon?(ribbon)
      chosen_pkmn.giveRibbon(ribbon)
      rname = GameData::Ribbon.try_get(ribbon) ? GameData::Ribbon.get(ribbon).name : ribbon.to_s
      pbMessage(_INTL("{1} won the {2} {3} Contest!\nIt received the {4}!",
                      chosen_pkmn.name, rank_name, cat_name, rname))
    end
    # Trigger contest-condition evolution (Beauty → Milotic, etc.)
    # trigger_event_evolution checks the relevant stat and handles the animation.
    chosen_pkmn.trigger_event_evolution(category)
  else
    pbMessage(_INTL("{1} didn't place first this time.\nKeep training!", chosen_pkmn.name))
  end
  return won
end

#===============================================================================
# Minimal proxies so PBAnimationPlayerX can run inside the contest viewport
#===============================================================================
class ContestSceneProxy
  attr_reader :viewport, :sprites
  def initialize(viewport, sprites_hash)
    @viewport = viewport
    @sprites  = sprites_hash
  end
end

class ContestBattlerProxy
  attr_reader :index, :pokemon
  def initialize(idx = 0)
    @index   = idx
    @pokemon = nil
  end
end

#===============================================================================
# Heart particle — Gen 2 pixel art style, floats upward with sine drift
#===============================================================================
class ContestHeart
  HEART_PIXELS = [
    [1,0],[2,0],[4,0],[5,0],
    [0,1],[1,1],[2,1],[3,1],[4,1],[5,1],[6,1],
    [0,2],[1,2],[2,2],[3,2],[4,2],[5,2],[6,2],
    [1,3],[2,3],[3,3],[4,3],[5,3],
    [2,4],[3,4],[4,4],
    [3,5]
  ]
  PINK = Color.new(255, 153, 204)

  def initialize(viewport, x, y)
    @ox       = x.to_f
    @x        = x.to_f
    @y        = y.to_f
    @frame    = 0
    @lifetime = 35
    bmp = Bitmap.new(8, 8)
    HEART_PIXELS.each { |px, py| bmp.set_pixel(px, py, PINK) }
    @sprite        = Sprite.new(viewport)
    @sprite.bitmap = bmp
    @sprite.x      = @x.to_i
    @sprite.y      = @y.to_i
    @sprite.z      = 50
  end

  def update
    @frame += 1
    @y     -= 1.2
    @x      = @ox + Math.sin(@frame * 0.35) * 2.5
    @sprite.x = @x.to_i
    @sprite.y = @y.to_i
    if @frame > 20
      alpha = 255.0 * (@lifetime - @frame) / (@lifetime - 20)
      @sprite.opacity = [[alpha.to_i, 0].max, 255].min
    end
  end

  def done?
    return @frame >= @lifetime
  end

  def dispose
    @sprite.bitmap.dispose rescue nil
    @sprite.dispose rescue nil
  end
end

#===============================================================================
# Contest scene class
#===============================================================================
class PokemonContestScene
  TOTAL_ROUNDS = 5
  HEART_BAR_X  = 120   # x-start of heart bar (fits on 320-wide screen)
  HEART_BAR_W  = 180   # pixel width for the bar
  MAX_HEARTS   = 20    # theoretical max: 4 hearts/round × 5 rounds
  HEART_SEGS   = 10    # discrete segments (Gen 2 style)
  ROW_H        = 32    # px per contestant row
  ROWS_START_Y = 48    # first row top — leaves 46px for the two-line header

  def initialize(player_pkmn, category, rank, npc_list)
    @category = category
    @rank     = rank
    # Build contestant list: player first, then NPCs
    @contestants = [{
      :name      => $player.name,
      :pkmn      => player_pkmn,
      :hearts    => 0,
      :last_move => nil,
      :jammed    => 0,
      :player    => true
    }]
    npc_list.each do |npc|
      @contestants.push({
        :name      => npc[:name],
        :pkmn      => npc[:pkmn],
        :hearts    => 0,
        :last_move => nil,
        :jammed    => 0,
        :player    => false
      })
    end
    @round         = 0
    @chosen_moves  = Array.new(@contestants.length, nil)
    @disliked_type = ContestNPCData::DISLIKE_TYPE_POOL.sample
    @viewport      = nil
    @sprites       = {}
  end

  def pbContestMain
    pbStartScene
    type_name = GameData::Type.try_get(@disliked_type)&.name || @disliked_type.to_s.capitalize
    pbShowMessage(_INTL("Today's judges dislike {1}-type moves! (-1 appeal)", type_name), 2.2)
    TOTAL_ROUNDS.times do |i|
      @round = i + 1
      pbDoRound
    end
    top4, advanced = pbShowResults
    pbEndScene
    return false unless advanced
    return pbRunBattleRound(top4)
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  def pbStartScene
    @viewport      = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z    = 9999

    bg = Sprite.new(@viewport)
    bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    bg.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(20, 20, 55))
    bg.z = 0
    @sprites["bg"] = bg

    hud = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(hud.bitmap)
    hud.z = 10
    @sprites["hud"] = hud

    msg = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(msg.bitmap)
    msg.z = 20
    @sprites["msg"] = msg

    Graphics.update
    Input.update
  end

  def pbEndScene
    @sprites.each_value { |s| s.dispose rescue nil }
    @sprites.clear
    @viewport.dispose rescue nil
    @viewport = nil
  end

  # ── One round ──────────────────────────────────────────────────────────────
  def pbDoRound
    pbUpdateHUD
    pbShowMessage(_INTL("Round {1}! Choose your move!", @round))

    # Everyone picks a move
    @contestants.each_with_index do |c, i|
      @chosen_moves[i] = c[:player] ? pbPlayerChooseMove(c[:pkmn]) : pbAIChooseMove(c[:pkmn])
    end

    # Perform in speed order (fastest first)
    order = []
    @contestants.each_index { |i| order.push(i) }
    order.sort! { |a, b| @contestants[b][:pkmn].speed <=> @contestants[a][:pkmn].speed }

    order.each_with_index do |ci, performer_idx|
      c    = @contestants[ci]
      move = @chosen_moves[ci]
      next if !move

      appeal = pbCalcAppeal(move, c[:last_move], apply_dislike: c[:player])

      # Absorb any jam from previous performer
      appeal = [appeal - c[:jammed], 0].max
      c[:jammed] = 0

      c[:hearts]    += appeal
      c[:last_move]  = move.id

      # Pass jam to next performer in order
      jam = ContestData.jam_for(move.id)
      if jam > 0 && performer_idx + 1 < order.length
        @contestants[order[performer_idx + 1]][:jammed] += jam
      end

      # Animate Pokémon performing + hearts/bar fill
      pbAnimatePerformer(ci, c[:pkmn], appeal, move)

      mname = (move.name rescue move.id.to_s)
      pbShowMessage(_INTL("{1} used {2}!  +{3} hearts", c[:name], mname, appeal), 0.8)
    end

    @sprites["msg"].bitmap.clear
  end

  # ── Player move selection ──────────────────────────────────────────────────
  def pbPlayerChooseMove(pkmn)
    moves   = pkmn.moves.select { |m| m }
    return moves[0] if moves.empty?
    sel = 0
    loop do
      pbDrawMoveMenu(moves, sel)
      Graphics.update
      Input.update
      if Input.repeat?(Input::UP)
        sel = (sel - 1 + moves.length) % moves.length
        pbPlayCursorSE
      elsif Input.repeat?(Input::DOWN)
        sel = (sel + 1) % moves.length
        pbPlayCursorSE
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        @sprites["msg"].bitmap.clear
        return moves[sel]
      end
    end
  end

  def pbDrawMoveMenu(moves, sel)
    bmp    = @sprites["msg"].bitmap
    bmp.clear
    menu_y = Graphics.height - 108
    bmp.fill_rect(0, menu_y - 2, Graphics.width, 110, Color.new(10, 10, 40, 220))
    bmp.font.size = 15
    moves.each_with_index do |move, i|
      row_y  = menu_y + 4 + i * 25
      active = (i == sel)
      appeal    = pbMoveAppeal(move)
      move_data = GameData::Move.try_get(move.id)
      disliked  = @disliked_type && move_data && move_data.type == @disliked_type
      net       = disliked ? [appeal - 1, 0].max : appeal
      stars     = net >= 4 ? "****" : net >= 3 ? "***" : net >= 2 ? "**" : net >= 1 ? "*" : "-"
      ct        = ContestData.type_for(move.id)
      mismatch  = ct && ct != @category
      bmp.font.color = mismatch ? Color.new(140, 140, 140) :
                       active   ? Color.new(255, 255, 100) : Color.new(220, 220, 220)
      prefix = active ? "> " : "  "
      bmp.draw_text(6, row_y, 168, 22, "#{prefix}#{move.name rescue move.id.to_s}")
      bmp.font.color = Color.new(255, 210, 50)
      bmp.draw_text(176, row_y, 62, 22, stars)
      bmp.font.color = disliked ? Color.new(255, 110, 80) : Color.new(160, 160, 160)
      bmp.draw_text(240, row_y, 78, 22, net > 0 ? "+#{net} <3" : "---")
    end
  end

  # ── AI move selection ──────────────────────────────────────────────────────
  def pbAIChooseMove(pkmn)
    moves   = pkmn.moves.select { |m| m }
    return moves[0] if moves.empty?
    weights = moves.map { |m| [pbMoveAppeal(m), 1].max }
    total   = weights.inject(0) { |s, w| s + w }
    roll    = rand(total)
    cumul   = 0
    moves.each_with_index do |m, i|
      cumul += weights[i]
      return m if roll < cumul
    end
    return moves.last
  end

  # ── Appeal / jam helpers ───────────────────────────────────────────────────
  def pbCalcAppeal(move, last_move_id, apply_dislike: false)
    base = pbMoveAppeal(move)
    base = [base, 1].max
    base = (base / 2.0).floor if last_move_id && last_move_id == move.id
    if apply_dislike && @disliked_type
      move_data = GameData::Move.try_get(move.id)
      base -= 1 if move_data && move_data.type == @disliked_type
    end
    return [base, 0].max
  end

  def pbMoveAppeal(move)
    ct = ContestData.type_for(move.id)
    return (ct == @category) ? ContestData.appeal_for(move.id) : 1
  end

  # ── Performer animation — back sprite slides in, uses battle animation ──
  def pbAnimatePerformer(ci, pkmn, appeal, move = nil)
    c      = @contestants[ci]
    target = c[:hearts]

    # ── Build back sprite (nil when contest effects off) ─────────────────
    # PokemonSprite sets ox=bw/2, oy=bh/2 (centre origin), so sprite.x/y
    # is the visual centre of the sprite.
    pk_sprite = nil
    battle_x  = Battle::Scene::PLAYER_BASE_X   # centre-x = 80
    battle_y  = 0
    off_x     = -80                            # start off-screen left

    if $PokemonSystem.contestanimations.to_i != 1
      pk_sprite = PokemonSprite.new(@viewport)
      pk_sprite.setPokemonBitmap(pkmn, true)   # back sprite
      pk_sprite.z = 30
      bh       = pk_sprite.bitmap ? pk_sprite.bitmap.height : 64
      # With oy=bh/2: setting y = base - bh/2 puts the bottom at PLAYER_BASE_Y
      battle_y = (Settings::SCREEN_HEIGHT - 80) - bh / 2
      pk_sprite.x = off_x
      pk_sprite.y = battle_y
    end

    # ── Phase 1: slide in from left (12 frames, ease-out) ────────────────
    if pk_sprite
      12.times do |f|
        t    = (f + 1).to_f / 12
        ease = t * (2.0 - t)
        pk_sprite.x = (off_x + (battle_x - off_x) * ease).to_i
        Graphics.update
        Input.update
      end
      pk_sprite.x = battle_x
    end

    # ── Phase 2: play the real battle move animation ──────────────────────
    pbContestPlayMoveAnimation(move.id, pk_sprite) if pk_sprite && move

    # ── Phase 3: hearts fly + bar fills (25 frames) ──────────────────────
    hearts = []
    if appeal > 0
      row_y = ROWS_START_Y + ci * ROW_H
      [[appeal, 4].min, 1].max.times do
        hearts.push(ContestHeart.new(@viewport, HEART_BAR_X + rand(HEART_BAR_W - 8), row_y + 11))
      end
    end

    25.times do |f|
      if appeal > 0
        progress   = (f + 1).to_f / 25
        c[:hearts] = (target - appeal) + (appeal * progress).round
        c[:hearts] = [c[:hearts], target].min
      end
      hearts.each { |h| h.update }
      pbUpdateHUD
      Graphics.update
      Input.update
    end
    hearts.each { |h| h.dispose }
    c[:hearts] = target

    # ── Phase 4: slide back out left (12 frames, ease-in) ────────────────
    if pk_sprite
      12.times do |f|
        t    = (f + 1).to_f / 12
        ease = t * t
        pk_sprite.x = (battle_x + (off_x - battle_x) * ease).to_i
        Graphics.update
        Input.update
      end
      pk_sprite.dispose
    end
  end

  # ── Plays the move's battle animation centred on pk_sprite ───────────────
  def pbContestPlayMoveAnimation(move_id, pk_sprite)
    animations = pbLoadBattleAnimations
    return if !animations
    move2anim = pbLoadMoveToAnim
    return if !move2anim || !move2anim[0]

    # Look up player-side animation for this move
    real_data = GameData::Move.try_get(move_id)
    real_id   = real_data ? real_data.id : move_id
    anim_id   = move2anim[0][real_id]

    # Fall back to a type-appropriate default move
    if !anim_id && real_data
      type_defaults = {
        :NORMAL   => :TACKLE,       :FIRE    => :EMBER,
        :WATER    => :WATERGUN,     :ELECTRIC => :THUNDERSHOCK,
        :GRASS    => :MEGADRAIN,    :ICE     => :ICEBEAM,
        :FIGHTING => :MACHPUNCH,    :POISON  => :SLUDGE,
        :GROUND   => :MUDSLAP,      :FLYING  => :GUST,
        :PSYCHIC  => :CONFUSION,    :BUG     => :TWINEEDLE,
        :ROCK     => :ROCKTHROW,    :GHOST   => :SHADOWBALL,
        :DRAGON   => :DRAGONRAGE,   :DARK    => :DARKPULSE,
        :STEEL    => :IRONHEAD
      }
      fallback    = type_defaults[real_data.type] || :TACKLE
      fb_data     = GameData::Move.try_get(fallback)
      anim_id     = move2anim[0][fb_data.id] if fb_data
    end

    # Last resort: Tackle
    if !anim_id
      tackle = GameData::Move.try_get(:TACKLE)
      anim_id = move2anim[0][tackle.id] if tackle
    end

    return if !anim_id
    animation = animations[anim_id]
    return if !animation

    # Scene proxy — PBAnimationPlayerX looks up sprites["pokemon_0"]
    scene_proxy = ContestSceneProxy.new(@viewport, { "pokemon_0" => pk_sprite })
    user_proxy  = ContestBattlerProxy.new(0)

    # "Target" sits in the upper-right where the opponent would be
    target_x = Graphics.width * 3 / 4
    target_y  = 80

    anim_player = PBAnimationPlayerX.new(animation, user_proxy, nil, scene_proxy)
    # Keep pk_sprite's bitmap untouched; animation particles draw on top of it
    anim_player.discard_user_and_target_sprites
    anim_player.set_target_origin(target_x, target_y)
    anim_player.setLineTransform(
      Battle::Scene::FOCUSUSER_X,   Battle::Scene::FOCUSUSER_Y,
      Battle::Scene::FOCUSTARGET_X, Battle::Scene::FOCUSTARGET_Y,
      pk_sprite.x, pk_sprite.y,
      target_x, target_y
    )
    anim_player.start
    loop do
      anim_player.update
      Graphics.update
      Input.update
      break if anim_player.animDone?
    end
    anim_player.dispose
  rescue
    # If the animation data is missing or broken, skip silently
  end

  # ── HUD ───────────────────────────────────────────────────────────────────
  def pbUpdateHUD
    bmp = @sprites["hud"].bitmap
    bmp.clear
    bmp.font.size = 16

    # Header bar (two lines: title + disliked type)
    bmp.fill_rect(0, 0, Graphics.width, 46, Color.new(0, 0, 0, 180))
    cat_name  = PokemonContestState::CATEGORY_NAMES[@category] || @category.to_s
    rank_name = PokemonContestState::RANK_NAMES[@rank]          || ""
    bmp.font.size  = 14
    bmp.font.color = Color.new(255, 230, 80)
    bmp.draw_text(0, 3, Graphics.width, 20,
                  "#{rank_name} #{cat_name} Contest -- Round #{@round} / #{TOTAL_ROUNDS}", 1)
    if @disliked_type
      type_name = GameData::Type.try_get(@disliked_type)&.name || @disliked_type.to_s.capitalize
      bmp.font.size  = 12
      bmp.font.color = Color.new(255, 110, 80)
      bmp.draw_text(0, 24, Graphics.width, 16, "Judges dislike #{type_name}-type! (-1 appeal)", 1)
    end

    # Contestant rows
    @contestants.each_with_index do |c, i|
      row_y      = ROWS_START_Y + i * ROW_H
      cur_hearts = c[:hearts]

      # Row background
      bg_col = c[:player] ? Color.new(30, 30, 90, 200) : Color.new(30, 30, 30, 180)
      bmp.fill_rect(2, row_y, Graphics.width - 4, ROW_H - 2, bg_col)

      # Name + Pokémon name (left column)
      bmp.font.color = c[:player] ? Color.new(140, 195, 255) : Color.new(220, 220, 220)
      bmp.font.size  = 12
      bmp.draw_text(6, row_y + 2, 110, 14, c[:name])
      bmp.font.color = Color.new(170, 170, 170)
      bmp.font.size  = 11
      bmp.draw_text(6, row_y + 17, 110, 13, c[:pkmn].name)

      # Heart bar (right column, vertically centred in row)
      bar_y = row_y + 11
      seg_w = HEART_BAR_W / HEART_SEGS
      ratio = cur_hearts.to_f / MAX_HEARTS
      fill_n = [[( ratio * HEART_SEGS).ceil, 0].max, HEART_SEGS].min
      HEART_SEGS.times do |s|
        col = s < fill_n ? Color.new(215, 55, 55) : Color.new(70, 20, 20)
        bmp.fill_rect(HEART_BAR_X + s * seg_w + 1, bar_y, seg_w - 2, 8, col)
      end
      bmp.fill_rect(HEART_BAR_X,               bar_y - 1,  HEART_BAR_W, 1,  Color.new(0, 0, 0, 200))
      bmp.fill_rect(HEART_BAR_X,               bar_y + 8,  HEART_BAR_W, 1,  Color.new(0, 0, 0, 200))
      bmp.fill_rect(HEART_BAR_X,               bar_y - 1,  1,           10, Color.new(0, 0, 0, 200))
      bmp.fill_rect(HEART_BAR_X + HEART_BAR_W, bar_y - 1,  1,           10, Color.new(0, 0, 0, 200))

      # Heart count (right of bar)
      bmp.font.size  = 12
      bmp.font.color = Color.new(255, 190, 190)
      bmp.draw_text(HEART_BAR_X + HEART_BAR_W + 4, bar_y - 2, 34, 14, "#{cur_hearts}")
    end

    Graphics.update
  end

  # ── Message display ────────────────────────────────────────────────────────
  def pbShowMessage(text, wait = 1.4)
    bmp = @sprites["msg"].bitmap
    bmp.clear
    bmp.fill_rect(0, Graphics.height - 48, Graphics.width, 48, Color.new(0, 0, 0, 200))
    bmp.font.color = Color.new(255, 255, 255)
    bmp.font.size  = 16
    bmp.draw_text(4, Graphics.height - 38, Graphics.width - 8, 24, text, 1)
    Graphics.update
    pbWait(wait) if wait > 0
  end

  # ── Results screen ─────────────────────────────────────────────────────────
  # Top 4 by hearts advance to the Battle Round (see pbRunBattleRound) instead
  # of the appeal score alone deciding the winner. Returns [top4, advanced].
  def pbShowResults
    sorted    = @contestants.sort_by { |c| -c[:hearts] }
    player_pos = 1
    sorted.each_with_index { |c, i| player_pos = i + 1 if c[:player] }
    advanced = (player_pos <= 4)

    # Overlay results on the HUD
    bmp = @sprites["hud"].bitmap
    bmp.fill_rect(0, 40, Graphics.width, 260, Color.new(0, 0, 0, 210))

    bmp.font.size  = 18
    bmp.font.color = Color.new(255, 240, 80)
    bmp.draw_text(0, 50, Graphics.width, 26, "Contest Results!", 1)

    suffixes = ["st", "nd", "rd", "th"]
    sorted.each_with_index do |c, i|
      row_y  = 82 + i * 27
      suffix = suffixes[[i, 3].min]
      color  = c[:player] ? Color.new(140, 210, 255) : Color.new(200, 200, 200)
      bmp.font.size  = 14
      bmp.font.color = color
      bmp.draw_text(40, row_y, Graphics.width - 80, 20,
                    "#{i + 1}#{suffix}  #{c[:name]}  (#{c[:pkmn].name})   #{c[:hearts]} hearts")
    end

    result_y = 82 + sorted.length * 27 + 8
    bmp.font.size  = 16
    bmp.font.color = advanced ? Color.new(80, 255, 120) : Color.new(255, 110, 110)
    result_text = advanced ? "Top 4! On to the Battle Round!" :
                        "You placed #{player_pos}#{suffixes[[player_pos - 1, 3].min]}."
    bmp.draw_text(0, result_y, Graphics.width, 24, result_text, 1)

    @sprites["msg"].bitmap.clear
    Graphics.update
    pbWait(0.5)

    loop do
      Graphics.update
      Input.update
      break if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
    end

    return sorted[0, 4], advanced
  end

  # ── Battle Round (Phase 2) ──────────────────────────────────────────────────
  # The top 4 are randomly paired into two 1v1 matches. The player only ever
  # plays their own match — the other match is never actually simulated; if
  # the player wins, their final opponent is picked at random from that other
  # pair, exactly as if that match had already happened.
  def pbRunBattleRound(top4)
    pool  = top4.shuffle
    pair1 = [pool[0], pool[1]]
    pair2 = [pool[2], pool[3]]

    player_pair = pair1.any? { |c| c[:player] } ? pair1 : pair2
    other_pair  = player_pair.equal?(pair1) ? pair2 : pair1
    player_c    = player_pair.find { |c| c[:player] }
    opponent1   = player_pair.find { |c| !c[:player] }

    pbMessage(_INTL("The Battle Round begins!\n{1} will face {2}!", player_c[:name], opponent1[:name]))
    unless pbRunContestBattle(player_c[:pkmn], opponent1[:pkmn], opponent1[:name])
      pbMessage(_INTL("{1} was defeated by {2} in the Battle Round.", player_c[:pkmn].name, opponent1[:name]))
      return false
    end

    finalist = other_pair.sample
    pbMessage(_INTL("{1} advances to the Final, facing {2}!", player_c[:name], finalist[:name]))
    if pbRunContestBattle(player_c[:pkmn], finalist[:pkmn], finalist[:name])
      pbMessage(_INTL("{1} defeated {2} and is the Contest winner!", player_c[:pkmn].name, finalist[:name]))
      return true
    else
      pbMessage(_INTL("{1} was defeated by {2} in the Final. So close!", player_c[:pkmn].name, finalist[:name]))
      return false
    end
  end

  # A single, self-contained 1v1 battle using ONLY the two contest Pokémon
  # (deep copies — the real party/NPC Pokémon are never touched), both fully
  # healed and the opponent's level bumped to match the player's. The
  # opponent keeps the moveset it used during the appeal rounds.
  def pbRunContestBattle(player_pkmn, opp_pkmn, opp_name)
    p_copy = Marshal.load(Marshal.dump(player_pkmn))
    o_copy = Marshal.load(Marshal.dump(opp_pkmn))
    o_copy.level = p_copy.level
    o_copy.calc_stats
    p_copy.heal
    o_copy.heal

    trainer_type      = :POKEMONTRAINER_1  # generic trainer sprite/type for the Battle Round opponent
    opp_trainer       = NPCTrainer.new(opp_name, trainer_type)
    opp_trainer.party = [o_copy]

    scene  = BattleCreationHelperMethods.create_battle_scene
    battle = Battle.new(scene, [p_copy], opp_trainer.party, [$player], [opp_trainer])
    battle.party1starts   = [0]
    battle.party2starts   = [0]
    battle.ally_items     = []
    battle.items          = []
    battle.internalBattle = true
    battle.expGain        = true
    battle.moneyGain      = false

    setBattleRule("single")
    BattleCreationHelperMethods.prepare_battle(battle)
    $game_temp.clear_battle_rules

    bgm = pbGetTrainerBattleBGM([opp_trainer]) rescue nil
    outcome = Battle::Outcome::UNDECIDED
    pbBattleAnimation(bgm, 1, [opp_trainer]) do
      pbSceneStandby { outcome = battle.pbStartBattle }
    end
    return outcome == Battle::Outcome::WIN
  end
end
