#==============================================================================
# Card Slots - a Game Corner slot machine whose reels are Pokémon TCG cards
# (the card pictures from the Pokemon TCG plugin). 20 Coins a spin; the cards
# won go into the TCG collection.
#
# From an event: Script command `pbCardSlots`.
#
# Three reels, the middle row pays. "2 in a row" = any 2 of the 3 match
# (the left and right ones too); that card is won. 3 in a row = that card as
# a holo (tier rolled like a booster pack's holo) and the reels level up.
#
#   Lv 1  Basic Pokémon that evolve (no legendaries)      no spin limit
#   Lv 2  Stage 1 evolutions                               50 spins:
#         out of spins -> back to Lv 1
#   Lv 3  Stage 2 evolutions                               7 spins:
#         2 in a row resets the 7; out of spins -> back to Lv 1
#   Lv 4  Legendaries and Pokémon with no evolutions       10 spins:
#         2 in a row = 2 free spins (the counter doesn't go down for them);
#         3 in a row = 1 last free spin on reels of special cards (Dark,
#         Light, Shining, Crystal, Shadow Lugia), then back to Lv 1 win or
#         lose; out of spins -> back to Lv 1
# Special cards are on no other reels; they and the legendaries come only
# from here and from trades (Pokemon TCG 087b_ReservedCards.rb keeps them
# out of booster packs and the Card Shop).
# Each level picks REEL_CARDS cards for its reels when it starts. The level,
# its reels and the spins left are saved with the game.
#
#   A  spin / stop the next reel      B  leave (progress is kept)
#   Hold A: auto play. It keeps spinning and stops each reel at a random
#   moment, and closes the win boxes by itself; let go of A to stop.
#==============================================================================
module CardSlots
  COST       = 20
  SPIN_LIMITS = [nil, 50, 7, 10]  # spins at each level (nil: no limit)
  FREE_SPINS = 2
  REEL_CARDS = [6, 6, 7, 8]       # different cards on the reels at each level
  FINAL_CARDS = 8                 # different special cards on the last spin's reels
  SPEED      = 9.9                # cards per second while spinning
  STOP_DELAY = 0.4                # seconds before a reel can be stopped (after the start / the last stop)
  AUTO_HOLD  = 0.5                # seconds A is held before auto play starts
  AUTO_STOP  = 0.6                # auto play stops a reel STOP_DELAY + 0..AUTO_STOP seconds in
  AUTO_POPUP = 1.5                # seconds auto play shows a box before closing it
  LEVELS = [
    "Lv 1: Basic Pokémon",
    "Lv 2: Stage 1 evolutions",
    "Lv 3: Stage 2 evolutions",
    "Lv 4: Legendary & one-of-a-kind"
  ]
  FINAL_TITLE = "Final spin: special cards!"
  GFX = "Graphics/Plugins/Pokemon TCG/"

  module_function

  #----------------------------------------------------------------------------
  # card pools (normal cards, not holos)
  #----------------------------------------------------------------------------
  def base_name(card); card.name.sub(/\A(Flying|Surfing) /, ""); end

  # Lv 1: Basics that evolve (Baby Pokémon too; Flying / Surfing Pikachu count
  # as Pikachu). Lv 4: legendaries and Basics nothing evolves from. Special
  # cards (TCG.special_card?) only in the final pool (index 4).
  def pools
    @pools ||= begin
      cards = TCG::CARD_ORDER.map { |id| TCG.card(id) }.select(&:pokemon?)
      cards.reject! { |c| c.special_trainer_pokemon? }
      evolves = cards.map(&:preevo).compact.uniq
      special, cards = cards.partition { |c| TCG.special_card?(c.id) }
      lv4 = ->(c) { TCG.legendary_card_id?(c.id) || (c.basic? && !c.baby? && !evolves.include?(base_name(c))) }
      [cards.select { |c| c.basic? && !lv4.call(c) },
       cards.select { |c| c.stage == TCG::STAGE1 },
       cards.select { |c| c.stage == TCG::STAGE2 },
       cards.select { |c| lv4.call(c) },
       special].map { |l| l.map(&:id) }
    end
  end

  # cards with different names for a level's reels (pool 4: the final spin)
  def pick_reel_cards(level)
    pool = pools[level].shuffle
    n = level == 4 ? FINAL_CARDS : REEL_CARDS[level]
    picked = []
    pool.each do |id|
      break if picked.size >= n
      picked << id unless picked.any? { |p| TCG.card(p).name == TCG.card(id).name }
    end
    picked
  end

  #----------------------------------------------------------------------------
  # saved progress: { :level, :cards, :spins, :free, :last }
  #----------------------------------------------------------------------------
  def state
    s = $PokemonGlobal ? ($PokemonGlobal.card_slots ||= {}) : (@test_state ||= {})
    start_level(s, 0) if s[:level].nil? || !s[:cards].is_a?(Array) || s[:cards].empty?
    s[:spins] ||= SPIN_LIMITS[s[:level]] unless s[:last]   # saves from before a level had a limit
    s
  end

  def start_level(s, level)
    s[:level] = level
    s[:cards] = pick_reel_cards(level)
    s[:spins] = SPIN_LIMITS[level]
    s[:free]  = 0
    s[:last]  = false
    s
  end

  def coins; $player ? $player.coins : (@test_coins ||= 100); end
  def coins=(v); $player ? $player.coins = v : @test_coins = v; end

  # the next spin costs nothing (free spins, Lv 4's last spin)
  def free_spin?(s); s[:last] || s[:free].to_i > 0; end

  # pays for a spin; false if the player can't
  def pay(s)
    if s[:last]
      # the last spin after Lv 4's jackpot
    elsif s[:free].to_i > 0
      s[:free] -= 1
    else
      return false if coins < COST
      self.coins -= COST
      s[:spins] -= 1 if s[:spins]
    end
    true
  end

  # the middle row -> [:none | :two | :three, card id]
  def result(row)
    return [:three, row[1]] if row[0] == row[1] && row[1] == row[2]
    return [:two, row[1]] if row[0] == row[1] || row[1] == row[2]
    return [:two, row[0]] if row[0] == row[2]
    [:none, nil]
  end

  # applies a spin's result: gives the card, moves the level. Returns
  # [card given or nil, list of events] for the screen to show
  def settle(s, kind, card)
    events = []
    given = nil
    if kind == :two
      given = card
    elsif kind == :three
      given = TCG.holo_id(card, TCG.roll_holo_tier) || card
    end
    TCG.add_card(given) if given
    level = s[:level]
    if s[:last]
      start_level(s, 0)
      events << :reset_last
    elsif kind == :three && level < 3
      start_level(s, level + 1)
      events << :level_up
    elsif kind == :three
      s[:last] = true
      s[:free] = 0
      s[:cards] = pick_reel_cards(4)
      events << :last_spin
    elsif kind == :two && level == 2
      s[:spins] = SPIN_LIMITS[level]
      events << :spins_reset
    elsif kind == :two && level == 3
      s[:free] += FREE_SPINS
      events << :free_spins
    elsif s[:spins] && s[:spins] <= 0 && s[:free].to_i == 0
      start_level(s, 0)
      events << :reset_out
    end
    [given, events]
  end

  #============================================================================
  # the screen
  #============================================================================
  class Reel
    W = 64
    H = 48

    attr_reader :sprite

    def initialize(viewport, x, y, strip)
      @sprite = Sprite.new(viewport)
      @sprite.bitmap = Bitmap.new(W, H * 3)
      @sprite.x = x
      @sprite.y = y
      @strip = strip
      @pos = rand(strip.size).to_f
      @state = :still
      draw
    end

    def spinning?; @state != :still; end

    def start
      @state = :spinning
      @t = System.uptime
    end

    # stop on the next card or the one after (a little slip)
    def stop
      return unless @state == :spinning
      @target = @pos.ceil + rand(2)
      @state = :stopping
    end

    # true the frame it stops
    def update
      return false unless spinning?
      now = System.uptime
      @pos += (now - @t) * SPEED
      @t = now
      stopped = false
      if @state == :stopping && @pos >= @target
        @pos = @target.to_f
        @state = :still
        stopped = true
      end
      draw
      stopped
    end

    # the card in the middle row
    def middle; @strip[(@pos.floor - 1) % @strip.size]; end

    def draw
      bmp = @sprite.bitmap
      bmp.fill_rect(0, 0, W, H * 3, Color.new(248, 248, 240))
      base = @pos.floor
      frac = @pos - base
      (-1..2).each do |k|
        id = @strip[(base - k) % @strip.size]
        src = CardSlots.card_bitmap(id) or next
        bmp.blt(0, ((k + frac) * H).round, src, Rect.new(0, 0, W, H))
      end
    end

    def dispose
      @sprite.bitmap.dispose
      @sprite.dispose
    end
  end

  def card_bitmap(id)
    gfx = TCG.card(id).gfx.to_s.split("*", 2)[0]
    RPG::Cache.load_bitmap(GFX + "Cards/", gfx) rescue nil
  end

  class Scene
    REEL_X = [52, 128, 204]
    REEL_Y = 60
    WHITE  = Color.new(248, 248, 248)
    SHADOW = Color.new(40, 40, 40)
    GOLD   = Color.new(248, 216, 64)

    def initialize
      @state = CardSlots.state
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 200_000   # over the menus it may be opened from (the debug menu is 99_999)
      @bg = Sprite.new(@viewport)
      @bg.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @text = Sprite.new(@viewport)
      @text.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @text.z = 10
      @popup = Sprite.new(@viewport)
      @popup.bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @popup.z = 20
      build_reels
    end

    def build_reels
      @reels&.each(&:dispose)
      cards = @state[:cards]
      @reels = REEL_X.map do |x|
        strip = (cards + cards).shuffle
        Reel.new(@viewport, x, REEL_Y, strip)
      end
      @reels.each { |r| r.sprite.z = 5 }
      draw_bg
    end

    def dispose
      @reels.each(&:dispose)
      [@bg, @text, @popup].each { |s| s.bitmap.dispose; s.dispose }
      @viewport.dispose
    end

    #--------------------------------------------------------------------------
    def draw_bg
      b = @bg.bitmap
      lv = @state[:level]
      felt = [Color.new(24, 88, 56), Color.new(32, 64, 120), Color.new(104, 40, 120), Color.new(136, 96, 16)][lv]
      felt = Color.new(56, 16, 24) if @state[:last]
      b.fill_rect(0, 0, b.width, b.height, Color.new(16, 16, 24))
      b.fill_rect(8, 8, b.width - 16, b.height - 16, felt)
      # reel windows
      b.fill_rect(REEL_X[0] - 8, REEL_Y - 8, REEL_X[2] + Reel::W + 8 - (REEL_X[0] - 8), Reel::H * 3 + 16, Color.new(16, 16, 24))
      REEL_X.each { |x| b.fill_rect(x - 2, REEL_Y - 2, Reel::W + 4, Reel::H * 3 + 4, Color.new(200, 200, 200)) }
      # payline arrows
      y = REEL_Y + Reel::H + Reel::H / 2
      6.times do |i|
        b.fill_rect(REEL_X[0] - 20 + i, y - 6 + i, 1, 13 - 2 * i, Color.new(232, 48, 48))
        b.fill_rect(REEL_X[2] + Reel::W + 19 - i, y - 6 + i, 1, 13 - 2 * i, Color.new(232, 48, 48))
      end
      # level pips
      4.times do |i|
        c = i <= lv ? GOLD : Color.new(64, 64, 64)
        b.fill_rect(Graphics.width - 84 + i * 18, 14, 14, 10, c)
      end
    end

    def draw_text(hint)
      b = @text.bitmap
      b.clear
      pbSetSystemFont(b)
      s = @state
      lines = [[_INTL("CARD SLOTS"), 16, 6, :left, GOLD, SHADOW],
               [s[:last] ? _INTL(CardSlots::FINAL_TITLE) : _INTL(CardSlots::LEVELS[s[:level]]), 16, 30, :left, s[:last] ? GOLD : WHITE, SHADOW]]
      lines << [_INTL("Coins: {1}", CardSlots.coins), 16, 218, :left, WHITE, SHADOW]
      if s[:last]
        lines << [_INTL("LAST SPIN (free)"), Graphics.width - 16, 218, :right, GOLD, SHADOW]
      elsif s[:spins]
        t = s[:free].to_i > 0 ? _INTL("Spins: {1} +{2} free", s[:spins], s[:free]) : _INTL("Spins left: {1}", s[:spins])
        lines << [t, Graphics.width - 16, 218, :right, s[:spins] <= 3 ? Color.new(248, 120, 96) : WHITE, SHADOW]
      end
      lines << [hint, Graphics.width / 2, 248, :center, WHITE, SHADOW]
      pbDrawTextPositions(b, lines)
    end

    def idle_hint
      CardSlots.free_spin?(@state) ? _INTL("A: Free spin  Hold A: Auto  B: Leave") : _INTL("A: Spin ({1})  Hold A: Auto  B: Leave", CardSlots::COST)
    end

    #--------------------------------------------------------------------------
    def main
      loop do
        draw_text(idle_hint)
        frame
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          break
        elsif Input.trigger?(Input::USE) || auto?
          spin
        end
      end
    end

    def frame
      Graphics.update
      Input.update
      track_hold
      @reels.each(&:update)
    end

    # auto play: A held for AUTO_HOLD seconds. After a box that stopped it
    # (no coins), it waits for A to be let go.
    def track_hold
      if Input.press?(Input::USE)
        @held_since ||= System.uptime
      else
        @held_since = nil
        @auto_blocked = false
      end
    end

    def auto?
      @held_since && !@auto_blocked && System.uptime - @held_since >= AUTO_HOLD
    end

    def spin
      unless CardSlots.free_spin?(@state) || CardSlots.coins >= CardSlots::COST
        @auto_blocked = true
        popup([_INTL("You need {1} Coins to spin.", CardSlots::COST)])
        return
      end
      CardSlots.pay(@state)
      pbSEPlay("Slots coin")
      @reels.each(&:start)
      @reels.each_with_index do |r, i|
        draw_text(auto? ? _INTL("Auto play (let go of A to stop)") : _INTL("A: Stop reel {1}", i + 1))
        # a short wait, and A let go first: the press that started the spin
        # (or stopped the last reel) doesn't stop this one
        # Auto play stops it at a random moment in a short window.
        t = System.uptime
        auto_at = STOP_DELAY + rand * AUTO_STOP
        released = false
        loop do
          frame
          released ||= !Input.press?(Input::USE)
          break if released && System.uptime - t >= STOP_DELAY && Input.trigger?(Input::USE)
          break if auto? && System.uptime - t >= auto_at
        end
        r.stop
        until !r.spinning?
          stopped = false
          Input.update
          Graphics.update
          @reels.each { |x| stopped = true if x.update && x.equal?(r) }
          pbSEPlay("Slots stop") if stopped
        end
      end
      kind, card = CardSlots.result(@reels.map(&:middle))
      level = @state[:level]
      given, events = CardSlots.settle(@state, kind, card)
      show_result(kind, given, events, level)
      # auto play: a moment to see the reels before the next spin
      t = System.uptime
      frame while auto? && System.uptime - t < 0.4
    end

    def show_result(kind, given, events, level)
      if given
        pbMEPlay(kind == :three ? "Slots big win" : "Slots win")
        name = TCG.card(given).name
        if TCG.holo?(given)
          popup([_INTL("3 in a row!"), _INTL("You got a {1} Holo {2}!", TCG.holo_name(TCG.holo_tier(given)), name)], given)
        else
          popup([_INTL("2 in a row!"), _INTL("You got {1}!", name)], given)
        end
      end
      events.each do |ev|
        case ev
        when :level_up
          popup([_INTL("The reels level up!"), _INTL(CardSlots::LEVELS[@state[:level]])] +
                (@state[:spins] ? [_INTL("You have {1} spins.", @state[:spins])] : []))
          build_reels
        when :spins_reset  then popup([_INTL("Your spins are back to {1}!", @state[:spins])])
        when :free_spins   then popup([_INTL("+{1} free spins!", CardSlots::FREE_SPINS)])
        when :last_spin
          popup([_INTL("One last free spin!"), _INTL("The reels are special cards now."), _INTL("Then they go back to Lv 1.")])
          build_reels
        when :reset_last   then popup([_INTL("That was the last spin."), _INTL("The reels go back to Lv 1.")]); build_reels
        when :reset_out    then popup([_INTL("Out of spins!"), _INTL("The reels go back to Lv 1.")]); build_reels
        end
      end
    end

    # a box over the reels with text and (optionally) a card shown large;
    # A or B closes it (auto play: after AUTO_POPUP seconds)
    def popup(lines, card = nil)
      b = @popup.bitmap
      h = card ? 196 : 30 + 28 * lines.size
      y0 = (Graphics.height - h) / 2 - 10
      tick0 = -1
      t = System.uptime
      loop do
        tick = TCG.holo_tick
        if tick != tick0
          tick0 = tick
          b.clear
          b.fill_rect(24, y0, Graphics.width - 48, h, Color.new(16, 16, 24, 230))
          b.fill_rect(28, y0 + 4, Graphics.width - 56, h - 8, Color.new(48, 48, 72, 230))
          ty = y0 + 12
          if card
            draw_big_card(b, card, (Graphics.width - 128) / 2, y0 + 12, tick)
            ty = y0 + 116
          end
          pbSetSystemFont(b)
          pbDrawTextPositions(b, lines.each_with_index.map { |l, i| [l, Graphics.width / 2, ty + 26 * i, :center, i == 0 && card ? GOLD : WHITE, SHADOW] })
        end
        Graphics.update
        Input.update
        track_hold
        @reels.each(&:update)
        break if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        break if auto? && System.uptime - t >= AUTO_POPUP
      end
      pbPlayDecisionSE
      b.clear
    end

    def draw_big_card(b, card, x, y, tick)
      src = CardSlots.card_bitmap(card)
      b.stretch_blt(Rect.new(x, y, 128, 96), src, Rect.new(0, 0, src.width, src.height)) if src
      sheet_name = TCG.holo_sheet(TCG.card(card).gfx)
      return unless sheet_name
      sheet = (RPG::Cache.load_bitmap(GFX + "UI/", sheet_name) rescue nil) or return
      frames = sheet.width / 64
      b.stretch_blt(Rect.new(x, y, 128, 96), sheet, Rect.new((tick % frames) * 64, 0, 64, 48)) if frames > 0
    end
  end
end

class PokemonGlobalMetadata
  attr_accessor :card_slots
end

def pbCardSlots
  if !$bag.has?(:COINCASE)
    pbMessage(_INTL("It's a slot machine with Pokémon cards on its reels."))
    return
  end
  if $player.coins < CardSlots::COST && !CardSlots.free_spin?(CardSlots.state)
    pbMessage(_INTL("You need {1} Coins to play!", CardSlots::COST))
    return
  end
  pbFadeOutIn do
    scene = CardSlots::Scene.new
    begin
      scene.main
    ensure
      scene.dispose
    end
  end
end
