#===============================================================================
# Jackpot Machines - Game Corner slot machines with a jackpot kept on the
# server (handlers/jackpot.js). Every Coin bet on a machine goes into its
# jackpot (starts at 500, up to 99,999), and every player builds up the same
# jackpot. Red 777 wins all of it. A spin always costs SPIN_COST Coins and
# plays all 5 lines. Only one player can use a machine at a time, and after
# leaving a machine a player can't use it again for 24 hours (the server keeps
# that list), so the machines need the player to be online.
#
#   Script:   pbJackpotMachine(1)      machines 1-10, each with its own jackpot
#
#   1, 2    Poké Balls      3 in a row wins that item (1: after a jackpot,
#                           Master Balls are on the reels for BONUS_SPINS spins,
#                           and 3 balls on a diagonal give one free spin with
#                           Master Balls on the reels)
#   3, 4    healing items   (Blue 777 = 777 Coins and 777 more in the jackpot,
#                           Red 777 = the jackpot;
#   5       Berries          nothing else pays Coins)
#   6       Apricorns
#   7, 8    Triple Triad packs, TCG Booster Packs (7: Colosseum, Evolution,
#           Mystery, Laboratory; 8: Genesis, Revelation, Discovery) and a
#           random TM. The rest of the reels are TCG duel cards: 9 weak Basic
#           Pokémon (CARD_SLOTS, picked at random each time the machine opens)
#           and one holo (HOLO_SLOT: one more weak card, the same on all 3
#           reels, its holo tier rolled like a booster pack's); 3 of the same
#           card wins that card. The hardest: one of each card a reel, hard
#           reel slipping, and a prize line can still slip away (PRIZE_DODGE).
#   9, 10   the regular machine's icons and payouts, but Red 777 wins the
#           jackpot. 10 has hard reel slipping.
#
# 7s: one Red 7 and one Blue 7 on each reel (the regular machine has 3, 2 and 1
# Red 7s and 2-3 Blue 7s), and a Red 777 line slips away RED7_DODGE of the
# time: about 1 in 8,000 spins, so a jackpot can build up to 99,999 (that's
# about 5,000 spins after a win).
#
# Uses the Game Corner machine (Data/Scripts/017_Minigames/
# 003_Minigame_SlotMachine.rb) for the screen, betting and reels, so the Slot
# Machine Auto Play plugin works here too (pbMain is its own: one press bets
# SPIN_COST Coins on all lines). Reel icons come from the item icons
# (and the TCG pack art), fitted into the reel's 32x32 cells when the machine
# opens.
#===============================================================================
module JackpotMachines
  JACKPOT_START = 500
  JACKPOT_MAX   = 99_999
  SPIN_COST     = 20      # Coins a spin, all 5 lines
  BLUE_777      = 777     # Coins, and the same again goes into the jackpot
  RED7_DODGE    = 0.75
  PRIZE_DODGE   = 0.4     # machines 7 and 8
  PING_EVERY    = 60      # seconds; keeps the machine locked while playing
  BONUS_SPINS   = 10      # spins with the bonus icons after a jackpot

  # icons on the regular machine's sheet (Graphics/UI/Slot Machine/images)
  BASE_ICONS = { CHERRY: 0, BALL: 1, STARYU: 2, PIKACHU: 3, SQUIRTLE: 4,
                 RED7: 5, BLUE7: 6, REPLAY: 7 }
  RED7  = BASE_ICONS[:RED7]
  BLUE7 = BASE_ICONS[:BLUE7]

  TCG_PACKS = {
    TCG_CLASSIC: %i[COLOSSEUM_NEUTRAL COLOSSEUM_GRASS COLOSSEUM_FIRE COLOSSEUM_WATER
                    COLOSSEUM_LIGHTNING COLOSSEUM_FIGHTING COLOSSEUM_TRAINER
                    EVOLUTION_NEUTRAL EVOLUTION_GRASS EVOLUTION_NEUTRAL_FIRE_ENERGY
                    EVOLUTION_WATER EVOLUTION_FIGHTING EVOLUTION_PSYCHIC EVOLUTION_TRAINER
                    MYSTERY_NEUTRAL MYSTERY_GRASS_COLORLESS MYSTERY_WATER_COLORLESS
                    MYSTERY_LIGHTNING_COLORLESS MYSTERY_FIGHTING_COLORLESS MYSTERY_TRAINER_COLORLESS
                    LABORATORY_MOSTLY_NEUTRAL LABORATORY_GRASS LABORATORY_WATER
                    LABORATORY_PSYCHIC LABORATORY_TRAINER],
    TCG_NEW:     %i[GENESIS REVELATION DISCOVERY]
  }
  TCG_ART = { TCG_CLASSIC: "colosseum", TCG_NEW: "genesis" }
  CARD_SLOTS = %i[CARD1 CARD2 CARD3 CARD4 CARD5 CARD6 CARD7 CARD8 CARD9]
  HOLO_SLOT  = :HOLO
  WEAK_HP    = 40      # the cards on the reels: Basic Pokémon with this HP or less

  # reel: icon => how many of it on each 22-icon reel
  # bonus: icon => how many of the reel's other icons (not 7s) it replaces on
  #        each reel for BONUS_SPINS spins after a jackpot (no message)
  MACHINES = {
    1  => { reel: { POKEBALL: 7, GREATBALL: 5, ULTRABALL: 3, QUICKBALL: 2, DUSKBALL: 2,
                    NETBALL: 1, BLUE7: 1, RED7: 1 },
            bonus: { MASTERBALL: 3 } },
    2  => { reel: { LEVELBALL: 4, LUREBALL: 3, MOONBALL: 3, FRIENDBALL: 3, LOVEBALL: 3,
                    HEAVYBALL: 2, FASTBALL: 2, BLUE7: 1, RED7: 1 } },
    3  => { reel: { POTION: 7, SUPERPOTION: 4, FULLHEAL: 3, SODAPOP: 3, REVIVE: 2,
                    FRESHWATER: 1, BLUE7: 1, RED7: 1 } },
    4  => { reel: { FRESHWATER: 5, LEMONADE: 3, MOOMOOMILK: 3, ENERGYROOT: 3, REVIVALHERB: 2,
                    MAXPOTION: 2, FULLHEAL: 1, MAXREVIVE: 1, BLUE7: 1, RED7: 1 } },
    5  => { reel: { ORANBERRY: 6, PECHABERRY: 3, CHESTOBERRY: 3, CHERIBERRY: 3, RAWSTBERRY: 2,
                    SITRUSBERRY: 2, LUMBERRY: 1, BLUE7: 1, RED7: 1 } },
    6  => { reel: { REDAPRICORN: 4, BLUEAPRICORN: 3, YELLOWAPRICORN: 3, GREENAPRICORN: 3,
                    PINKAPRICORN: 3, WHITEAPRICORN: 2, BLACKAPRICORN: 2, BLUE7: 1, RED7: 1 } },
    7  => { difficulty: 2, dodge: PRIZE_DODGE,
            reel: { BOOSTERPACK: 3, TM: 3, TCG_CLASSIC: 3, LEGENDPACK: 1, BLUE7: 1, RED7: 1,
                    **CARD_SLOTS.to_h { |c| [c, 1] }, HOLO: 1 } },
    8  => { difficulty: 2, dodge: PRIZE_DODGE,
            reel: { BOOSTERPACK: 3, TM: 3, TCG_NEW: 3, LEGENDPACK: 1, BLUE7: 1, RED7: 1,
                    **CARD_SLOTS.to_h { |c| [c, 1] }, HOLO: 1 } },
    9  => { regular: true },
    10 => { regular: true, difficulty: 2 }
  }

  # the reel sheet: the regular icons, then this machine's own. cards: card
  # slot symbol => TCG card id (a holo's sparkle moves, see animate)
  class Sheet
    attr_reader :bitmap, :symbols

    def initialize(symbols, cards = {})
      @symbols = BASE_ICONS.keys + [:GREEN7] + (symbols - BASE_ICONS.keys)
      @cards = cards
      base = AnimatedBitmap.new("Graphics/UI/Slot Machine/images")
      @bitmap = Bitmap.new(32 * @symbols.size, 32)
      @bitmap.blt(0, 0, base.bitmap, Rect.new(0, 0, base.width, 32))
      base.dispose
      @symbols.each_with_index do |sym, i|
        next if i < 9
        if @cards[sym]
          draw_card(i, @cards[sym], 0)
        else
          file = JackpotMachines.icon_file(sym)
          JackpotMachines.draw_fitted(@bitmap, i * 32, file) if file
        end
      end
    end

    # a card's picture (64x48) at half size, with its holo sparkle frame
    def draw_card(i, id, tick)
      gfx = TCG::CARDS[id][:gfx].to_s
      @bitmap.clear_rect(i * 32, 0, 32, 32)
      dst = Rect.new(i * 32, 4, 32, 24)
      pic = (RPG::Cache.load_bitmap(TCG::GFX + "Cards/", gfx.split("*", 2)[0]) rescue nil)
      @bitmap.stretch_blt(dst, pic, Rect.new(0, 0, pic.width, pic.height)) if pic
      sheet_name = TCG.holo_sheet(gfx) or return
      sheet = (RPG::Cache.load_bitmap(TCG::GFX + "UI/", sheet_name) rescue nil) or return
      frames = sheet.width / 64
      @bitmap.stretch_blt(dst, sheet, Rect.new((tick % frames) * 64, 0, 64, 48)) if frames > 0
    end

    # moves the holo cards' sparkles on (the reels draw from this sheet)
    def animate
      return unless defined?(TCG) && TCG.respond_to?(:holo_tick)
      tick = TCG.holo_tick
      return if tick == @tick
      @tick = tick
      @cards.each { |sym, id| draw_card(index(sym), id, tick) if TCG.holo?(id) && index(sym) }
    end

    def index(sym); @symbols.index(sym); end
    def height;     32;                  end
    def dispose;    @bitmap.dispose;     end
  end

  module_function

  def machine(n);  MACHINES[n];             end
  def regular?(n); !!MACHINES[n][:regular]; end

  def icon_file(sym)
    case sym
    when :BLANK, HOLO_SLOT, *CARD_SLOTS then nil   # cards: Sheet#draw_card
    when :TM               then "Graphics/Items/machine_NORMAL"
    when *TCG_ART.keys     then "Graphics/Plugins/Pokemon TCG/Boosters/#{TCG_ART[sym]}"
    else                        GameData::Item.icon_filename(sym)
    end
  end

  # draws the picture's non-transparent part into the 32x32 cell at x,
  # shrunk to fit 30x30 if it's bigger
  def draw_fitted(dest, x, file)
    src = AnimatedBitmap.new(file)
    bmp = src.bitmap
    x0, y0, x1, y1 = bmp.width, bmp.height, -1, -1
    bmp.height.times do |py|
      bmp.width.times do |px|
        next if bmp.get_pixel(px, py).alpha == 0
        x0 = px if px < x0
        x1 = px if px > x1
        y0 = py if py < y0
        y1 = py if py > y1
      end
    end
    if x1 >= 0
      w = x1 - x0 + 1
      h = y1 - y0 + 1
      scale = [1.0, 30.0 / w, 30.0 / h].min
      dw = (w * scale).round
      dh = (h * scale).round
      dest.stretch_blt(Rect.new(x + (32 - dw) / 2, (32 - dh) / 2, dw, dh), bmp, Rect.new(x0, y0, w, h))
    end
    src.dispose
  end

  # the 3 reels as icon symbols; the same every time for a machine
  def strips(n)
    if regular?(n)
      # the regular reels with one Red 7 and one Blue 7 each (the other Red 7s
      # become Squirtles, the other Blue 7s Staryus)
      return SlotMachineReel::ICONS_SETS.map do |set|
        red = set.index(RED7)
        blue = set.index(BLUE7)
        set.each_with_index.map do |icon, i|
          next BASE_ICONS[:SQUIRTLE] if icon == RED7 && i != red
          next BASE_ICONS[:STARYU] if icon == BLUE7 && i != blue
          icon
        end.map { |icon| BASE_ICONS.key(icon) }
      end
    end
    pool = MACHINES[n][:reel].flat_map { |sym, count| [sym] * count }
    (1..3).map { |r| pool.shuffle(random: Random.new(n * 10 + r)) }
  end

  # the reels during the bonus spins after a jackpot (nil: no bonus)
  def bonus_strips(n)
    bonus = MACHINES[n][:bonus] or return nil
    strips(n).each_with_index.map do |strip, r|
      strip = strip.dup
      rng = Random.new(n * 10 + r + 100)
      bonus.each do |sym, count|
        spots = strip.each_index.reject { |i| [:RED7, :BLUE7].include?(strip[i]) || bonus.key?(strip[i]) }
        spots.sample(count, random: rng).each { |i| strip[i] = sym }
      end
      strip
    end
  end

  # what one line pays: [:jackpot], [:coins, n], [:replay], [:prize, sym] or nil
  def line_prize(n, syms)
    return [:jackpot] if syms.all?(:RED7)
    return [:coins, BLUE_777] if syms.all?(:BLUE7)
    if regular?(n)
      return [:coins, 90] if syms.all? { |s| [:RED7, :BLUE7].include?(s) }
      return [:replay] if syms.all?(:REPLAY)
      three = { BALL: 40, STARYU: 8, PIKACHU: 15, SQUIRTLE: 15 }
      return [:coins, three[syms[0]]] if three[syms[0]] && syms.uniq.size == 1
      if syms[0] == :CHERRY
        return [:coins, 10] if syms[1] == :CHERRY && syms[2] == :CHERRY
        return [:coins, 4]  if syms[1] == :CHERRY
        return [:coins, 2]
      end
      return nil
    end
    return nil unless syms.uniq.size == 1
    return nil if syms[0] == :BLANK || BASE_ICONS.key?(syms[0])
    [:prize, syms[0]]
  end

  def prize_name(sym)
    case sym
    when :TM               then _INTL("Random TM")
    when :TCG_CLASSIC      then _INTL("TCG Pack (classic)")
    when :TCG_NEW          then _INTL("TCG Pack (new)")
    else                        GameData::Item.get(sym).name
    end
  end

  def random_tm
    tms = []
    # this game's TMs are FieldUse = TR in items.txt, so not is_TM?
    GameData::Item.each { |item| tms << item.id if item.is_machine? && item.id.to_s.start_with?("TM") }
    unowned = tms.reject { |id| $bag.has?(id) }
    (unowned.empty? ? tms : unowned).sample
  end

  # weak Basic Pokémon cards for the reels (no legendary / special cards)
  def weak_cards
    return [] unless defined?(TCG::CARD_ORDER)
    TCG::CARD_ORDER.select do |id|
      h = TCG::CARDS[id]
      next false unless h[:type].to_s.start_with?("TYPE_PKMN") && h[:stage] == "BASIC"
      next false if h[:hp].to_i > WEAK_HP
      next false if TCG.respond_to?(:reserved_card?) && TCG.reserved_card?(id)
      pbResolveBitmap(TCG::GFX + "Cards/" + h[:gfx].to_s)
    end
  end

  # the cards on machine n's reels this time: card slot symbol => card id
  def pick_cards(n)
    return {} if regular?(n)
    syms = MACHINES[n][:reel].keys & (CARD_SLOTS + [HOLO_SLOT])
    pool = weak_cards
    return {} if syms.empty? || pool.size < syms.size
    picks = pool.sample(syms.size)
    cards = syms.zip(picks).to_h
    cards[HOLO_SLOT] = TCG.holo_id(cards[HOLO_SLOT], TCG.roll_holo_tier) if cards[HOLO_SLOT]
    cards
  end

  def card_name(id)
    name = TCG.card_name(TCG.base_id(id))
    tier = TCG.holo_tier(id)
    tier ? _INTL("{1} Holo {2}", TCG.holo_name(tier), name) : name
  end

  def tcg_pack(sym)
    return nil unless defined?(TCG::BOOSTER_PACKS)
    TCG_PACKS[sym].select { |p| TCG::BOOSTER_PACKS[p] }.sample
  end

  #-----------------------------------------------------------------------------
  # server
  #-----------------------------------------------------------------------------
  def online?
    defined?(NetworkAuth) && NetworkAuth.logged_in? && NetworkClient.connected?
  end

  # sends msg and waits for the reply event for the same machine
  def request(msg, reply, frames = 300)
    got = nil
    cb = NetworkClient.on(reply) { |d| got = d if d['machine'].to_i == msg[:machine] }
    NetworkClient.send_msg(msg)
    frames.times do
      break if got
      Graphics.update
      Input.update
      NetworkClient.update
    end
    got
  ensure
    NetworkClient.remove(reply, cb) if cb
  end

  def open(n);         request({ action: 'jackpot_open', machine: n }, 'jackpot_open');                 end
  def add(n, coins);   NetworkClient.send_msg({ action: 'jackpot_add', machine: n, coins: coins });      end
  def ping(n);         NetworkClient.send_msg({ action: 'jackpot_ping', machine: n });                   end
  def close(n);        NetworkClient.send_msg({ action: 'jackpot_close', machine: n });                  end

  # the jackpot's Coins, or nil if the server didn't pay it
  def win(n)
    3.times do
      d = request({ action: 'jackpot_win', machine: n }, 'jackpot_won')
      return (d['ok'] ? d['amount'].to_i : nil) if d
    end
    nil
  end
end

#===============================================================================
# a reel showing a machine's own icons
#===============================================================================
class JackpotMachineReel < SlotMachineReel
  def initialize(x, y, reel_num, difficulty, strip, sheet)
    super(x, y, reel_num, difficulty)
    @images.dispose
    @images = sheet
    self.strip = strip
    @index = rand(@reel.length)
    update
  end

  # swaps the reel's icons (same length, so the position stays)
  def strip=(syms)
    @reel = syms.map { |sym| @images.index(sym) }
    @original_reel = @reel.dup
  end
end

#===============================================================================
# the jackpot shown above the reels (over the Voltorbs)
#===============================================================================
class JackpotBanner < BitmapSprite
  WIDTH  = 176
  HEIGHT = 26

  def initialize(x, y, viewport)
    super(WIDTH, HEIGHT, viewport)
    self.x = x
    self.y = y
    @numbers = AnimatedBitmap.new("Graphics/UI/Slot Machine/numbers")
    @value = nil
  end

  def value=(v)
    v = v.to_i.clamp(0, JackpotMachines::JACKPOT_MAX)
    @flash_at = System.uptime if @value && v != @value
    @value = v
    refresh
  end

  def refresh
    b = self.bitmap
    b.clear
    b.fill_rect(0, 0, WIDTH, HEIGHT, Color.new(248, 208, 64))
    b.fill_rect(2, 2, WIDTH - 4, HEIGHT - 4, Color.new(56, 16, 24))
    pbSetSmallFont(b)
    b.font.color = Color.new(248, 208, 64)
    b.draw_text(8, 2, 80, HEIGHT - 4, _INTL("JACKPOT"))
    5.times do |i|
      digit = (@value / (10**i)) % 10
      b.blt(WIDTH - 8 - (16 * (i + 1)), 5, @numbers.bitmap, Rect.new(digit * 16, 0, 16, 16))
    end
  end

  # flashes white for a moment when the jackpot changes; blink: keep flashing
  def update(blink = false)
    super()
    lit = blink ? (System.uptime * 8).to_i.even? : (@flash_at && System.uptime - @flash_at < 0.3)
    self.color = lit ? Color.new(255, 255, 255, 160) : Color.new(0, 0, 0, 0)
  end

  def dispose
    @numbers.dispose
    super
  end
end

#===============================================================================
# the machine's scene
#===============================================================================
class JackpotMachineScene < SlotMachineScene
  attr_reader :won_packs

  def initialize(machine, jackpot)
    @machine = machine
    @jackpot = jackpot
    @won_packs = []
  end

  def jackpot=(v)
    @jackpot = v
    @sprites["jackpot"].value = v if @sprites && @sprites["jackpot"]
  end

  def update
    super
    @sheet&.animate
    NetworkClient.update
    if System.uptime - (@last_ping || 0) >= JackpotMachines::PING_EVERY
      @last_ping = System.uptime
      JackpotMachines.ping(@machine)
    end
  end

  # the regular machine's pbStartScene with this machine's reels and the jackpot
  def pbStartScene
    info = JackpotMachines.machine(@machine)
    difficulty = info[:difficulty] || 1
    strips = JackpotMachines.strips(@machine)
    @bonus_strips = JackpotMachines.bonus_strips(@machine)
    @bonus_spins = 0
    @cards = JackpotMachines.pick_cards(@machine)
    @sheet = JackpotMachines::Sheet.new((strips + (@bonus_strips || [])).flatten.uniq, @cards)
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites, "bg", "Slot Machine/bg", @viewport)
    [80, 144, 208].each_with_index do |x, i|
      @sprites["reel#{i + 1}"] = JackpotMachineReel.new(x, 64, i + 1, difficulty, strips[i], @sheet)
    end
    (1..3).each do |i|
      @sprites["button#{i}"] = IconSprite.new(88 + (64 * (i - 1)), 168, @viewport)
      @sprites["button#{i}"].setBitmap("Graphics/UI/Slot Machine/button")
      @sprites["button#{i}"].visible = false
    end
    (1..5).each do |i|
      y = [106, 74, 138, 42, 42][i - 1]
      @sprites["row#{i}"] = IconSprite.new(52, y, @viewport)
      @sprites["row#{i}"].setBitmap(sprintf("Graphics/UI/Slot Machine/line%1d%s",
                                            1 + (i / 2), (i >= 4) ? ((i == 4) ? "a" : "b") : ""))
      @sprites["row#{i}"].visible = false
    end
    @sprites["jackpot"] = JackpotBanner.new(72, 33, @viewport)
    @sprites["jackpot"].value = @jackpot
    @sprites["light1"] = IconSprite.new(0, 10, @viewport)
    @sprites["light1"].setBitmap("Graphics/UI/Slot Machine/lights")
    @sprites["light1"].visible = false
    @sprites["light2"] = IconSprite.new(512, 384, @viewport)
    @sprites["light2"].setBitmap("Graphics/UI/Slot Machine/lights")
    @sprites["light2"].mirror = true
    @sprites["light2"].visible = false
    @sprites["window1"] = IconSprite.new(0, 192, @viewport)
    @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/insert"))
    @sprites["window1"].src_rect.set(0, 0, Graphics.width, 96)
    @sprites["window2"] = IconSprite.new(0, 192, @viewport)
    @sprites["credit"] = SlotMachineScore.new(64, 16, $player.coins)
    @sprites["payout"] = SlotMachineScore.new(176, 16, 0)
    @wager = 0
    @green7_spins = 0
    @last_ping = System.uptime
    @jackpot_cb = NetworkClient.on('jackpot_update') do |d|
      self.jackpot = d['jackpot'].to_i if d['machine'].to_i == @machine
    end
    update
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    NetworkClient.remove('jackpot_update', @jackpot_cb) if @jackpot_cb
    super
    @sheet&.dispose
  end

  # the regular machine's pbMain, but one press of Down (or A) bets SPIN_COST
  # Coins on all 5 lines, and no Green 7 bonus
  def pbMain
    cost = JackpotMachines::SPIN_COST
    loop do
      Graphics.update
      Input.update
      update
      @sprites["window1"].bitmap&.clear
      @sprites["window2"].bitmap&.clear
      if @sprites["credit"].score == Settings::MAX_COINS
        pbMessage(_INTL("You've got {1} Coins.", Settings::MAX_COINS.to_s_formatted))
        break
      elsif !@replay && !@free_spin && @sprites["credit"].score < cost
        pbMessage(_INTL("A spin costs {1} Coins.
You don't have enough Coins to keep playing!", cost))
        break
      end
      break if !wait_for_bet(cost)
      spin_reels
      # the regular machine's special events: Red 7, Red 7, then not a 7
      if active_lines.any? { |_, s| s[0] == :RED7 && s[1] == :RED7 && ![:RED7, :BLUE7].include?(s[2]) } && rand(2) == 0
        rand(2) == 0 ? pbSpecialEvent1 : pbSpecialEvent2
      end
      @gameEnd = true
      pbPayout
      (1..3).each { |i| @sprites["button#{i}"].visible = false }
      (1..5).each { |i| @sprites["row#{i}"].visible = false }
      @gameEnd = false
    end
    old_coins = $player.coins
    $player.coins = @sprites["credit"].score
    if $player.coins > old_coins
      $stats.coins_won += $player.coins - old_coins
    elsif $player.coins < old_coins
      $stats.coins_lost += old_coins - $player.coins
    end
  end

  # false if the player leaves
  def wait_for_bet(cost)
    @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/insert"))
    timer_start = System.uptime
    loop do
      if @replay || @free_spin
        @wager = 3
        break
      end
      frame = ((System.uptime - timer_start) / 0.4).to_i
      @sprites["window1"].src_rect.set(Graphics.width * (frame % 2), 0, Graphics.width, 96)
      Graphics.update
      Input.update
      update
      if Input.trigger?(Input::DOWN) || Input.trigger?(Input::USE)
        pbSEPlay("Slots coin")
        @sprites["credit"].score -= cost
        @wager = 3
        break
      elsif Input.trigger?(Input::L) || Input.trigger?(Input::R)
        pbShowPayoutGuide
      elsif Input.trigger?(Input::BACK)
        return false
      end
    end
    (1..5).each { |i| @sprites["row#{i}"].visible = true }
    true
  end

  def spin_reels
    # the bonus icons come and go while the reels spin
    if @bonus_strips && @bonus_on != (@bonus_spins > 0 || @free_spin)
      @bonus_on = @bonus_spins > 0 || @free_spin
      strips = @bonus_on ? @bonus_strips : JackpotMachines.strips(@machine)
      (1..3).each { |i| @sprites["reel#{i}"].strip = strips[i - 1] }
    end
    (1..3).each { |i| @sprites["reel#{i}"].startSpinning }
    @gameRunning = true
    @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/stop"))
    timer_start = System.uptime
    loop do
      frame = ((System.uptime - timer_start) / 0.25).to_i
      @sprites["window1"].src_rect.set(Graphics.width * (frame % 4), 0, Graphics.width, 96)
      Graphics.update
      Input.update
      update
      if Input.trigger?(Input::USE)
        pbSEPlay("Slots stop")
        reel = (1..3).find { |i| @sprites["reel#{i}"].spinning? }
        if reel
          @sprites["reel#{reel}"].stopSpinning(@replay)
          @sprites["button#{reel}"].visible = true
        end
      end
      break if !@sprites["reel3"].spinning?
    end
    @gameRunning = false
    @sprites["window1"].bitmap&.clear
  end

  # the 5 lines: [row number (1-5), [left, middle, right] icon symbols]
  def active_lines
    reels = (1..3).map { |i| @sprites["reel#{i}"].showing.map { |icon| @sheet.symbols[icon] } }
    lines = [[1, [reels[0][1], reels[1][1], reels[2][1]]],
             [2, [reels[0][0], reels[1][0], reels[2][0]]],
             [3, [reels[0][2], reels[1][2], reels[2][2]]],
             [4, [reels[0][0], reels[1][1], reels[2][2]]],
             [5, [reels[0][2], reels[1][1], reels[2][0]]]]
    lines
  end

  # a winning Red 777 (or on machines 7-8 any prize) can slip one more icon
  def dodge
    info = JackpotMachines.machine(@machine)
    prizes = active_lines.map { |_, syms| JackpotMachines.line_prize(@machine, syms) }
    chance = 0
    chance = info[:dodge] if info[:dodge] && prizes.any? { |p| p && p[0] == :prize }
    chance = [chance, JackpotMachines::RED7_DODGE].max if prizes.any? { |p| p && p[0] == :jackpot }
    return if chance <= 0 || rand >= chance
    @sprites["reel3"].slowExtraSpin(1)
    loop do
      Graphics.update
      Input.update
      update
      break unless @sprites["reel3"].spinning?
    end
    pbSEPlay("Slots stop")
  end

  def pbPayout
    free_bonus = @free_spin
    free = @replay || free_bonus
    @replay = false
    @free_spin = false
    JackpotMachines.add(@machine, JackpotMachines::SPIN_COST) unless free
    dodge
    lines = active_lines
    won_rows = []
    coins = 0
    jackpot = false
    sevens = false
    prizes = []
    lines.each do |row, syms|
      prize = JackpotMachines.line_prize(@machine, syms) or next
      won_rows << row
      case prize[0]
      when :jackpot then jackpot = true
      when :coins
        coins += prize[1]
        sevens = true if syms.all? { |s| [:RED7, :BLUE7].include?(s) }
        JackpotMachines.add(@machine, JackpotMachines::BLUE_777) if syms.all?(:BLUE7)
      when :replay then @replay = true
      when :prize
        prizes << prize[1]
        # 3 balls on a diagonal: one free spin with the bonus icons (no message)
        @free_spin = true if @bonus_strips && !free_bonus && [4, 5].include?(row)
      end
    end
    @bonus_spins -= 1 if @bonus_on && @bonus_spins > 0 && !free_bonus
    if won_rows.empty?
      lose_animation
      @wager = 0
      return
    end
    amount = jackpot ? JackpotMachines.win(@machine) : nil
    self.jackpot = JackpotMachines::JACKPOT_START if amount
    @bonus_spins = JackpotMachines::BONUS_SPINS if amount && @bonus_strips
    refresh_bug_shop if JackpotMachines.regular?(@machine) && (jackpot || (sevens && coins >= JackpotMachines::BLUE_777))
    pbMEPlay((jackpot || sevens) ? "Slots big win" : "Slots win")
    win_animation(won_rows, jackpot ? 2 : (sevens ? 1 : 0), jackpot ? 5.0 : 3.0)
    if jackpot
      if amount
        pbMessage(_INTL("JACKPOT!!!\nYou won {1} Coins!", amount.to_s_formatted))
        coins += amount
      else
        pbMessage(_INTL("JACKPOT!!!\nBut the machine lost its link to the server, so it couldn't pay out..."))
      end
    end
    with_auto_advance { prizes.each { |sym| give_prize(sym) } }
    count_payout(coins) if coins > 0
    @wager = 0
  end

  # in auto play (A held, Slot Machine Auto Play plugin) holding A gets
  # through the prize messages too
  def with_auto_advance(&block)
    return yield unless defined?(SlotAutoPlay) && respond_to?(:slot_auto_active?, true) && slot_auto_active?
    SlotAutoPlay.advancing(&block)
  end

  def give_prize(sym)
    case sym
    when :TM
      pbReceiveItem(JackpotMachines.random_tm)
    when *JackpotMachines::CARD_SLOTS, JackpotMachines::HOLO_SLOT
      id = @cards[sym] or return
      TCG.add_card(id)
      pbMEPlay("Item get")
      pbMessage(_INTL("You won a TCG card:\n{1}!", JackpotMachines.card_name(id)))
    when *JackpotMachines::TCG_PACKS.keys
      pack = JackpotMachines.tcg_pack(sym) or return
      @won_packs << pack
      pbMEPlay("Item get")
      pbMessage(_INTL("You won a TCG Booster Pack!\nYou'll open it when you leave the machine."))
    else
      pbReceiveItem(sym)
    end
  end

  def refresh_bug_shop
    return if !$player.respond_to?(:bugshop_purchases) || $player.bugshop_purchases == {}
    %i[MASTERBALL ABILITYPATCH PPMAX SACREDASH THUNDERSTONE FIRESTONE WATERSTONE
       LEAFSTONE MOONSTONE KINGSROCK METALCOAT LINKINGCORD].each { |i| $player.bugshop_purchases.delete(i) }
    pbMessage(_INTL("The Bug Shop has been refreshed! You can now buy everything again."))
  end

  # the regular machine's win animation; bonus 1 = "bonus", 2 = "big bonus"
  def win_animation(won_rows, bonus, seconds)
    timer_start = System.uptime
    loop do
      frame = ((System.uptime - timer_start) / 0.125).to_i
      @sprites["window2"].bitmap&.clear
      @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/win"))
      @sprites["window1"].src_rect.set(Graphics.width * (frame % 4), 0, Graphics.width, 96)
      if bonus > 0
        @sprites["window2"].setBitmap(_INTL("Graphics/UI/Slot Machine/bonus"))
        @sprites["window2"].src_rect.set(Graphics.width * (bonus - 1), 0, Graphics.width, 96)
      end
      @sprites["light1"].visible = true
      @sprites["light1"].src_rect.set(0, 178 * (frame % 4), Graphics.width, 178)
      @sprites["light2"].visible = true
      @sprites["light2"].src_rect.set(0, 178 * (frame % 4), Graphics.width, 178)
      (1..5).each { |i| @sprites["row#{i}"].visible = won_rows.include?(i) && frame.even? }
      Graphics.update
      Input.update
      update
      @sprites["jackpot"].update(bonus == 2)
      break if System.uptime - timer_start >= seconds
    end
    @sprites["jackpot"].update
    @sprites["light1"].visible = false
    @sprites["light2"].visible = false
    @sprites["window1"].src_rect.set(0, 0, 152, 208)
  end

  def lose_animation
    timer_start = System.uptime
    loop do
      frame = ((System.uptime - timer_start) / 0.25).to_i
      @sprites["window2"].bitmap&.clear
      @sprites["window1"].setBitmap(_INTL("Graphics/UI/Slot Machine/lose"))
      @sprites["window1"].src_rect.set(Graphics.width * (frame % 2), 0, Graphics.width, 96)
      Graphics.update
      Input.update
      update
      break if System.uptime - timer_start >= 2.0
    end
  end

  # counts the Coins into the credit, faster for big wins (A skips)
  def count_payout(coins)
    @sprites["payout"].score = coins
    step = [coins / 90, 1].max
    loop do
      break if @sprites["payout"].score <= 0
      Graphics.update
      Input.update
      update
      n = [step, @sprites["payout"].score].min
      @sprites["payout"].score -= n
      @sprites["credit"].score += n
      if Input.trigger?(Input::USE) || @sprites["credit"].score == Settings::MAX_COINS
        @sprites["credit"].score += @sprites["payout"].score
        @sprites["payout"].score = 0
      end
    end
    timer_start = System.uptime
    loop do
      Graphics.update
      Input.update
      update
      break if System.uptime - timer_start >= 0.5
    end
  end

  # Q / W: this machine's prizes
  def pbShowPayoutGuide
    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = 100000
    spr = BitmapSprite.new(Graphics.width, Graphics.height, vp)
    bmp = spr.bitmap
    bmp.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    bmp.font.bold  = true
    bmp.font.size  = 20
    bmp.font.color = Color.new(255, 220, 0)
    bmp.draw_text(0, 4, Graphics.width, 26, _INTL("JACKPOT MACHINE {1}", @machine), 1)
    rows = [[%i[RED7 RED7 RED7], _INTL("Red 777"), @jackpot.to_s_formatted],
            [%i[BLUE7 BLUE7 BLUE7], _INTL("Blue 777"), JackpotMachines::BLUE_777.to_s]]
    if JackpotMachines.regular?(@machine)
      rows += [[%i[RED7 BLUE7 RED7], _INTL("Mixed 7s"), "90"],
               [%i[BALL BALL BALL], _INTL("Poké Ball × 3"), "40"],
               [%i[PIKACHU PIKACHU PIKACHU], _INTL("Pikachu × 3"), "15"],
               [%i[SQUIRTLE SQUIRTLE SQUIRTLE], _INTL("Squirtle × 3"), "15"],
               [%i[CHERRY CHERRY CHERRY], _INTL("Cherry × 3"), "10"],
               [%i[STARYU STARYU STARYU], _INTL("Staryu × 3"), "8"],
               [[:CHERRY, :CHERRY, nil], _INTL("Cherry L + C"), "4"],
               [[:CHERRY, nil, nil], _INTL("Cherry L only"), "2"],
               [%i[REPLAY REPLAY REPLAY], _INTL("Replay"), _INTL("FREE")]]
    else
      prizes = JackpotMachines.machine(@machine)[:reel].keys - %i[RED7 BLUE7 BLANK]
      prizes -= JackpotMachines::CARD_SLOTS[1..]   # the cards share one row
      prizes.each do |sym|
        next unless @sheet.index(sym)
        label = case sym
                when JackpotMachines::CARD_SLOTS[0]  then _INTL("Same card × 3")
                when JackpotMachines::HOLO_SLOT      then JackpotMachines.card_name(@cards[sym])
                else                                      JackpotMachines.prize_name(sym)
                end
        rows << [[sym] * 3, label, _INTL("PRIZE")]
      end
    end
    row_h = 22
    y_start = 34
    rows.each_with_index do |(syms, label, value), i|
      y = y_start + i * row_h
      syms.each_with_index do |sym, j|
        next unless sym
        bmp.stretch_blt(Rect.new(4 + j * 20, y + 1, 20, 20), @sheet.bitmap, Rect.new(@sheet.index(sym) * 32, 0, 32, 32))
      end
      bmp.font.bold  = false
      bmp.font.size  = 14
      bmp.font.color = Color.new(210, 210, 210)
      bmp.draw_text(72, y + 2, 160, 18, label)
      bmp.font.bold  = true
      bmp.font.color = Color.new(255, 200, 50)
      bmp.draw_text(232, y + 2, Graphics.width - 236, 18, value, 2)
    end
    bmp.font.bold  = false
    bmp.font.size  = 11
    bmp.font.color = Color.new(140, 140, 110)
    note = JackpotMachines.regular?(@machine) ? _INTL("Every Coin bet goes into the jackpot") :
                                                _INTL("3 in a row wins that prize. Every Coin bet goes into the jackpot")
    bmp.draw_text(0, Graphics.height - 34, Graphics.width, 14, note, 1)
    bmp.font.size  = 13
    bmp.font.color = Color.new(100, 100, 100)
    bmp.draw_text(0, Graphics.height - 18, Graphics.width, 16, _INTL("Q / W  —  Close"), 1)
    loop do
      Graphics.update
      Input.update
      NetworkClient.update
      break if Input.trigger?(Input::L) || Input.trigger?(Input::R) || Input.trigger?(Input::BACK)
    end
    spr.dispose
    vp.dispose
  end
end

#===============================================================================
#
#===============================================================================
def pbJackpotMachine(machine = 1)
  machine = machine.to_i
  if !JackpotMachines.machine(machine)
    pbMessage(_INTL("This machine is out of order."))
  elsif !$bag.has?(:COINCASE)
    pbMessage(_INTL("It's a Jackpot Machine."))
  elsif $player.coins < JackpotMachines::SPIN_COST
    pbMessage(_INTL("A spin costs {1} Coins.
You don't have enough Coins to play!", JackpotMachines::SPIN_COST))
  elsif $player.coins == Settings::MAX_COINS
    pbMessage(_INTL("Your Coin Case is full!"))
  elsif !JackpotMachines.online?
    pbMessage(_INTL("The machine's screen says \"OFFLINE\".\nIts jackpot is kept on the server, so you need to be online."))
  else
    d = JackpotMachines.open(machine)
    if !d
      pbMessage(_INTL("The machine couldn't reach the server."))
    elsif !d['ok'] && d['reason'] == 'cooldown'
      hours = (d['wait_ms'].to_i / 3_600_000.0).ceil
      pbMessage(_INTL("You played this machine recently. Give the other players a shot at its jackpot!
Come back in {1} hour(s).", hours))
    elsif !d['ok']
      pbMessage(_INTL("Someone else is playing this machine right now."))
    else
      scene = JackpotMachineScene.new(machine, d['jackpot'].to_i)
      begin
        pbFadeOutIn do
          scene.pbStartScene
          scene.pbMain
          scene.pbEndScene
        end
      ensure
        JackpotMachines.close(machine)
      end
      scene.won_packs.each_with_index { |pack, i| pbTCGOpenBooster(pack, i > 0) }
    end
  end
end
