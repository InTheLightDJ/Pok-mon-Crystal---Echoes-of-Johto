#==============================================================================
# Pokémon Tower Defense - title screen and the script call
#
#   pbTowerDefense   title screen (Play / Rankings / How to Play / Exit);
#                    returns the best round of this visit (0 = none played).
#                    In an NPC event: Script command  pbTowerDefense
#   pbTowerDefenseBest   the best round ever (kept in the save)
#
# Online: a monthly server board of each player's best round (server:
# handlers/towerdefense.js); when a month ends its top 5 get 50/40/30/20/10
# Server Tokens. A game tells the server it started (td_start) and, when it
# ends, the round it reached (td_result).
#==============================================================================
class PokemonGlobalMetadata
  attr_writer :td_best
  def td_best; @td_best || 0; end
end

module TowerDefense
  TITLE_MUSIC = "GSC 046 Goldenrod Game Corner"

  module_function

  def best; $PokemonGlobal ? $PokemonGlobal.td_best : 0; end

  def online?
    defined?(NetworkAuth) && defined?(NetworkClient) && NetworkAuth.logged_in?
  rescue StandardError
    false
  end

  def net_send(msg)
    NetworkClient.send_msg(msg) if online?
  rescue StandardError
    nil
  end

  # a finished game's round: true if it's a new best
  def record(round)
    return false unless $PokemonGlobal && round > $PokemonGlobal.td_best
    $PokemonGlobal.td_best = round
    true
  end

  def how_to_play
    pbMessage(_INTL("Wild Pokémon walk the track from the left. Each one that reaches the right side costs a life. Lose all {1} and it's game over.", START_LIVES))
    pbMessage(_INTL("Build Bulbasaur, Charmander, Squirtle, Pidgey, Pichu or Paras towers on the grass for {1} points, Weedle or Caterpie for {2}. They throw balls of their type at Pokémon in range: Weakness does double, Resistance half.",
                    BUY_COST, TowerDefense.cost(:WEEDLE)))
    pbMessage(_INTL("Pidgey only blows one way, picked when you build it. Its Gust does half damage, but blows the Pokémon it hits back down the track: further, and more of them, as it evolves."))
    pbMessage(_INTL("Pichu's shots can stun a Pokémon for a moment (more often as it evolves). Paras doesn't attack: it slows every Pokémon next to it."))
    pbMessage(_INTL("Mew costs {1} points, but every tower in its range gets more HP and fires faster. Mewtwo costs {2} and hits very hard from 3 tiles away, but it won't stand anywhere near a Mew.",
                    TowerDefense.cost(:MEW), TowerDefense.cost(:MEWTWO)))
    pbMessage(_INTL("A knocked out Pokémon gives 1 point (2 if it's evolved), and every round won gives {1} plus the round's number. The tower that knocked it out gets as much EXP. After a round every tower gets {2} HP and {3} EXP.",
                    ROUND_BONUS, TOWER_REGEN, ROUND_EXP))
    pbMessage(_INTL("A tower with {1} EXP can evolve for {2} points, and with {3} more EXP for {4}. Evolved towers hit harder, and the last forms reach further. Selling gives back 3/4 of what you paid.",
                    EXP_NEED[0], EVOLVE_COST[0], EXP_NEED[1], EVOLVE_COST[1]))
    pbMessage(_INTL("Venusaur poisons, Charizard fires fast, Blastoise reaches furthest, Beedrill stings fast up close and Butterfree's Mega Drain heals the towers around it."))
    pbMessage(_INTL("Items: Potions heal a tower, Spikes on the track hurt every Pokémon that steps on them, Poison Bombs poison everything nearby when they go off, and X Attack, X Defend and the Exp. Share (every knock out trains every tower) last a whole round."))
    pbMessage(_INTL("Each round brings a new kind of Pokémon, and every {1} rounds one kind evolves. Look out for shiny Pokémon: they're fast, but knocking one out gives a life!", EVOLVE_EVERY))
    pbMessage(_INTL("Every {1} rounds a legendary or fully evolved boss comes. It attacks towers next to the track as it walks by, so think about where you build! A boss that gets through costs {2} lives.", BOSS_EVERY, BOSS_LEAK))
    pbMessage(_INTL("Every {1} rounds a special boss drains your points as it walks, more the further it gets. Pidgey's Gust can blow it all the way back!", SPECIAL_EVERY))
    pbMessage(_INTL("Online, your best round each month goes on the server's Rankings. When the month ends, the top 5 win 50, 40, 30, 20 and 10 Server Tokens!"))
    pbMessage(_INTL("Controls: arrows move (push past the edge to scroll), C builds, upgrades or uses items, A starts the next round (or changes the speed), B opens the menu."))
  end

  #----------------------------------------------------------------------------
  class Title
    STARTERS = [:BULBASAUR, :CHARMANDER, :SQUIRTLE]

    def main
      @choices = TowerDefense.online? ? [:play, :ranking, :help, :exit] : [:play, :help, :exit]
      start_board
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99_999   # above the pbFadeOutIn black layer (99999, made earlier)
      @bg = Sprite.new(@viewport)
      @bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @text = Sprite.new(@viewport)
      @text.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @text.z = 10
      @mons = STARTERS.each_with_index.map do |k, i|
        s = Sprite.new(@viewport)
        s.bitmap = Bitmap.new(Dex.sprite(k))
        s.ox = s.bitmap.width / 8
        s.oy = s.bitmap.height / 4
        s.x = Graphics.width / 2 + (i - 1) * 64
        s.y = 156
        s.z = 5
        s.zoom_x = s.zoom_y = 1.5
        s
      end
      @walker = Sprite.new(@viewport)
      @walker.bitmap = Bitmap.new(Dex.sprite(FIRST_SPECIES))
      @walker.ox = @walker.bitmap.width / 8
      @walker.oy = @walker.bitmap.height / 4
      @walker.z = 5
      @walker_x = -20.0
      @index = 0
      @best_now = 0
      draw_bg
      pbBGMPlay(TITLE_MUSIC)
      loop do
        Graphics.update
        Input.update
        update_board
        animate
        draw_text
        if Input.repeat?(Input::UP)
          @index = (@index - 1) % @choices.size; pbSEPlay("GUI sel cursor")
        elsif Input.repeat?(Input::DOWN)
          @index = (@index + 1) % @choices.size; pbSEPlay("GUI sel cursor")
        elsif Input.trigger?(Input::USE)
          pbSEPlay("GUI sel decision")
          case @choices[@index]
          when :play
            round = 0
            pbFadeOutIn do
              @viewport.visible = false
              TowerDefense.net_send({ action: "td_start" })
              round = Scene.new.main
            ensure
              @viewport.visible = true
            end
            TowerDefense.net_send({ action: "td_result", round: round }) if round > 0
            @best_now = [@best_now, round].max
            pbBGMPlay(TITLE_MUSIC)
          when :ranking then show_ranking
          when :help then TowerDefense.how_to_play
          when :exit then break
          end
        elsif Input.trigger?(Input::BACK)
          break
        end
      end
      @best_now
    ensure
      NetworkClient.remove("td_board", @board_cb) if @board_cb
      [@bg, @text, @walker, *@mons].compact.each { |s| s.bitmap&.dispose; s.dispose }
      @viewport&.dispose
    end

    #--- the server's monthly board (online only) ---
    def start_board
      return unless TowerDefense.online?
      @board_cb = NetworkClient.on("td_board") { |d| @board = d }
      TowerDefense.net_send({ action: "td_board" })
    rescue StandardError
      @board_cb = nil
    end

    def update_board
      NetworkClient.update if @board_cb
    rescue StandardError
      nil
    end

    def show_ranking
      unless @board
        TowerDefense.net_send({ action: "td_board" })
        180.times do
          Graphics.update
          update_board
          break if @board
        end
      end
      return pbMessage(_INTL("The rankings couldn't be loaded. Try again in a moment.")) unless @board
      days = [((@board["season_ends"].to_i - Time.now.to_i) / 86_400.0).ceil, 0].max
      prizes = Array(@board["prizes"]).join("/")
      top = Array(@board["top"])
      text = _INTL("This month's best rounds (ends in {1} days). The top 5 win {2} Server Tokens.", days, prizes)
      lines = top.each_with_index.map { |(name, round), i| _INTL("\#{1} {2} - round {3}", i + 1, name, round) }
      lines = [_INTL("No one has played yet this month!")] if lines.empty?
      pbMessage(text)
      lines.each_slice(2) { |pair| pbMessage(pair.join("\n")) }
      me = @board["me"]
      pbMessage(me ? _INTL("You're \#{1} this month (round {2}).", me[0], me[1]) : _INTL("You haven't played this month yet."))
    end

    def animate
      tick = Graphics.frame_count
      @mons.each_with_index do |s, i|
        fw, fh = s.bitmap.width / 4, s.bitmap.height / 4
        s.src_rect.set(((tick / 12) + i) % 4 * fw, 0, fw, fh)
      end
      @walker_x += 0.8
      @walker_x = -20.0 if @walker_x > Graphics.width + 20
      fw, fh = @walker.bitmap.width / 4, @walker.bitmap.height / 4
      @walker.src_rect.set((tick / 8) % 4 * fw, 2 * fh, fw, fh)
      @walker.x = @walker_x
      @walker.y = 214
    end

    def draw_bg
      b = @bg.bitmap
      b.fill_rect(0, 0, b.width, b.height, Color.new(40, 48, 88))
      12.times { |i| b.fill_rect(0, i * 8, b.width, 8, Color.new(40 + i * 4, 48 + i * 3, 88 + i * 2)) }
      b.fill_rect(0, 176, b.width, b.height - 176, Color.new(104, 184, 72))
      b.fill_rect(0, 196, b.width, 32, Color.new(224, 192, 128))
      b.fill_rect(0, 196, b.width, 3, Color.new(176, 136, 80))
      b.fill_rect(0, 225, b.width, 3, Color.new(176, 136, 80))
      rng = Random.new(1)
      40.times { b.fill_rect(rng.rand(b.width), rng.rand(90), 2, 2, Color.new(248, 248, 220)) }
    end

    def draw_text
      b = @text.bitmap
      b.clear
      white  = Color.new(248, 248, 248)
      shadow = Color.new(40, 40, 56)
      gold   = Color.new(248, 208, 64)
      pbSetSystemFont(b)
      b.font.size = 36
      pbDrawTextPositions(b, [[_INTL("Pokémon"), Graphics.width / 2, 16, :center, gold, shadow]])
      pbDrawTextPositions(b, [[_INTL("Tower Defense"), Graphics.width / 2, 48, :center, white, shadow]])
      pbSetSystemFont(b)
      names = { :play => _INTL("Play"), :ranking => _INTL("Rankings"), :help => _INTL("How to Play"), :exit => _INTL("Exit") }
      labels = @choices.map { |c| names[c] }
      labels.each_with_index do |l, i|
        y = Graphics.height - 8 - (labels.size - i) * 16
        col = i == @index ? gold : white
        pbDrawTextPositions(b, [[(i == @index ? "> " : "") + l, Graphics.width / 2, y, :center, col, shadow]])
      end
      pbSetSmallFont(b)
      pbDrawTextPositions(b, [[_INTL("Best round: {1}", TowerDefense.best), Graphics.width - 6, Graphics.height - 16, :right, white, shadow]])
      if @board && (me = @board["me"])
        pbDrawTextPositions(b, [[_INTL("This month: \#{1}", me[0]), Graphics.width - 6, Graphics.height - 30, :right, gold, shadow]])
      end
    end
  end
end

def pbTowerDefense
  bgm = $game_system&.playing_bgm
  best = 0
  pbFadeOutIn { best = TowerDefense::Title.new.main }
  bgm ? $game_system.bgm_play(bgm) : pbBGMStop
  best
end

def pbTowerDefenseBest; TowerDefense.best; end

MenuHandlers.add(:debug_menu, :tower_defense, {
  "name"        => _INTL("Pokémon Tower Defense"),
  "parent"      => :main,
  "description" => _INTL("Play the Tower Defense minigame."),
  "always_show" => true,
  "effect"      => proc { pbTowerDefense }
})
