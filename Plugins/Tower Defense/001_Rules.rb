#==============================================================================
# Pokémon Tower Defense - the rules (no graphics: 003_Scene.rb draws them)
#
# Script call: pbTowerDefense  (title screen, then the game)
#
# A random track crosses a COLS x ROWS field (bigger than the screen, which
# scrolls) from the left edge to the right one. Wild Pokémon walk it; the
# player's towers shoot them with balls of their type (Weakness / Resistance
# from the type chart). A Pokémon that reaches the end costs a life (a boss:
# BOSS_LEAK lives).
#
#   tower        BUY_COST (or its own :cost); its stats per stage are in
#                TOWERS. Evolving costs
#                EVOLVE_COST[stage] points AND needs EXP_NEED[stage] EXP
#                (a knock out: 1 EXP, 2 if the Pokémon was evolved); the EXP
#                starts again from 0 after evolving
#   selling      SELL_RATE of everything paid for it
#   a knock out  1 point (2 for an evolved Pokémon, BOSS_POINTS for a boss)
#   a round won  ROUND_BONUS + the round's number points; towers get
#                TOWER_REGEN HP back and ROUND_EXP EXP
#   Pidgey line  blows a Gust one way (picked when it's built): the
#                Pokémon it hits (up to :carry) take half damage and are
#                blown back :push tiles along the track
#   Pichu line   its hits may stun (:stun chance, :stun_time seconds)
#   Paras line   no shots: slows every Pokémon within :range (x :slow)
#   Mew          2000; towers in its range get x MEW_HP HP and fire
#                MEW_SPEED times as often (Mews don't stack)
#   Mewtwo       2000; a strong shooter that won't stand in a Mew's range
#                (and a Mew can't be built with a Mewtwo in its range)
#   HP           round 1: 1 (every hit knocks out); then its Pokémon card's HP (TCG card data) x hp_scale(round): it
#                grows fast early and slower later
#   round 1      Rattata only; every round after adds a new species, every
#                EVOLVE_EVERY rounds one of them evolves
#   a shiny      1 in SHINY_CHANCE wild Pokémon: 3x as fast; knocking it out
#                gives a life and SHINY_POINTS points
#   every BOSS_EVERY rounds: bosses (1, +1 every BOSS_MORE_EVERY rounds): a
#                legendary or a fully evolved Pokémon with round / 2 x its
#                card's HP. They attack towers next to the track
#                (up to BOSS_DAMAGE); a tower's HP is its card's HP x TOWER_HP.
#   every SPECIAL_EVERY rounds: a special boss (SPECIAL_BOSSES) that doesn't
#                attack towers but drains points: each new track tile it
#                reaches takes SPECIAL_DRAIN x that tile's number. Gusts
#                blow it all the way back.
#   items        ITEMS: Potion, Spikes, Poison Bomb, X Attack, X Defend,
#                Exp. Share (every kill gives every tower EXP, a round)
#
# Positions are in tiles (x, y: tile centres are whole numbers + 0.5); time
# in seconds. The game's data (species, cards, sprites) comes through
# TowerDefense::Dex so the rules also run outside the game.
#==============================================================================
module TowerDefense
  COLS = 16
  ROWS = 12
  PATH_LENGTH = 36..52        # track tiles

  START_POINTS = 30
  START_LIVES  = 10
  BUY_COST     = 20
  EVOLVE_COST  = [50, 150]   # basic -> stage 1, stage 1 -> stage 2
  EXP_NEED     = [25, 100]    # EXP for those
  SELL_RATE    = 0.75
  TOWER_HP     = 2            # a tower's HP: its card's HP x this
  SHOT_SPEED   = 8.0          # tiles a second
  ROUND_BONUS  = 10           # + the round's number
  TOWER_REGEN  = 10           # HP towers get back after a round
  ROUND_EXP    = 3            # EXP every tower gets after a round
  GUST_SPEED   = 5.0          # tiles a second
  POISON_TIME  = 4.0          # seconds a tower's poison lasts
  DRAIN_RANGE  = 1.5          # Mega Drain heals towers this close

  # each tower line: its Pokémon, its balls' type and its stats per stage
  #   cost (if not BUY_COST), gust (Pidgey: see above)
  #   dmg a hit, delay (seconds between shots), range (tiles), poison (damage
  #   a second for POISON_TIME; chance = how often), drain (heals itself and
  #   towers in DRAIN_RANGE by half the damage), type (balls of another type),
  #   stun (chance) / stun_time, slow (speed x this for slow_time; no shots),
  #   boost (Mew)
  TOWERS = {
    :BULBASAUR => { :line => [:BULBASAUR, :IVYSAUR, :VENUSAUR], :type => :GRASS, :stats => [
      { :dmg => 10, :delay => 0.8, :range => 2.2 },
      { :dmg => 20, :delay => 0.8, :range => 2.2 },
      { :dmg => 60, :delay => 1.3, :range => 3.2, :poison => 20 }    # slow, poisons
    ] },
    :CHARMANDER => { :line => [:CHARMANDER, :CHARMELEON, :CHARIZARD], :type => :FIRE, :stats => [
      { :dmg => 10, :delay => 0.8, :range => 2.2 },
      { :dmg => 20, :delay => 0.8, :range => 2.2 },
      { :dmg => 35, :delay => 0.4, :range => 3.2 }                   # fast, less a hit
    ] },
    :SQUIRTLE => { :line => [:SQUIRTLE, :WARTORTLE, :BLASTOISE], :type => :WATER, :stats => [
      { :dmg => 10, :delay => 0.8, :range => 2.2 },
      { :dmg => 20, :delay => 0.8, :range => 2.2 },
      { :dmg => 100, :delay => 1.4, :range => 4.2 }                  # slow, the longest reach
    ] },
    :WEEDLE => { :line => [:WEEDLE, :KAKUNA, :BEEDRILL], :type => :BUG, :cost => 10, :stats => [
      { :dmg => 6,  :delay => 0.45, :range => 1.5 },
      { :dmg => 12, :delay => 0.45, :range => 1.5 },
      { :dmg => 30, :delay => 0.3,  :range => 1.5, :poison => 15, :chance => 0.25 }   # swift, 1 tile
    ] },
    :CATERPIE => { :line => [:CATERPIE, :METAPOD, :BUTTERFREE], :type => :BUG, :cost => 10, :stats => [
      { :dmg => 10, :delay => 0.8, :range => 2.2 },
      { :dmg => 20, :delay => 0.8, :range => 2.2 },
      { :dmg => 80, :delay => 1.4, :range => 1.5, :drain => true, :type => :GRASS }  # Mega Drain
    ] },
    # Gust: one way only, half damage, blows up to :carry Pokémon :push tiles back
    :PIDGEY => { :line => [:PIDGEY, :PIDGEOTTO, :PIDGEOT], :type => :FLYING, :gust => true, :stats => [
      { :dmg => 10, :delay => 3.0, :range => 3.0, :push => 1, :carry => 3 },
      { :dmg => 20, :delay => 2.8, :range => 3.5, :push => 2, :carry => 4 },
      { :dmg => 50, :delay => 2.5, :range => 4.0, :push => 3, :carry => 5 }
    ] },
    :PICHU => { :line => [:PICHU, :PIKACHU, :RAICHU], :type => :ELECTRIC, :stats => [
      { :dmg => 8,  :delay => 0.7, :range => 2.2, :stun => 0.15, :stun_time => 0.8 },
      { :dmg => 18, :delay => 0.7, :range => 2.2, :stun => 0.25, :stun_time => 1.0 },
      { :dmg => 45, :delay => 0.9, :range => 3.2, :stun => 0.40, :stun_time => 1.2 }
    ] },
    # Stun Spore: slows everything next to it
    :PARAS => { :line => [:PARAS, :PARASECT], :type => :BUG, :stats => [
      { :dmg => 0, :delay => 0.25, :range => 1.5, :slow => 0.6, :slow_time => 2.0 },
      { :dmg => 0, :delay => 0.25, :range => 1.5, :slow => 0.4, :slow_time => 3.0 }
    ] },
    # the legendary tower: boosts the towers around it
    :MEW => { :line => [:MEW], :type => :PSYCHIC, :cost => 2000, :stats => [
      { :dmg => 30, :delay => 1.0, :range => 2.5, :boost => true }
    ] },
    :MEWTWO => { :line => [:MEWTWO], :type => :PSYCHIC, :cost => 2000, :rival => :MEW, :stats => [
      { :dmg => 120, :delay => 0.8, :range => 3.0 }
    ] }
  }
  MEW_HP    = 1.5               # boosted towers' HP x this
  MEW_SPEED = 1.35              # and they fire this many times as often
  DIRS = [[0, 1], [-1, 0], [1, 0], [0, -1]]   # by facing: down, left, right, up

  FIRST_SPECIES = :RATTATA
  # basic Pokémon that may join the waves (only ones with a card, a follower
  # sprite and a species in this game are used)
  WILD_SPECIES = [
    :PIDGEY, :SPEAROW, :CATERPIE, :WEEDLE, :EKANS, :SANDSHREW, :NIDORANfE, :NIDORANmA,
    :ZUBAT, :ODDISH, :PARAS, :VENONAT, :DIGLETT, :MEOWTH, :PSYDUCK, :MANKEY,
    :GROWLITHE, :POLIWAG, :ABRA, :MACHOP, :BELLSPROUT, :TENTACOOL, :GEODUDE,
    :PONYTA, :SLOWPOKE, :MAGNEMITE, :DODUO, :SEEL, :GRIMER, :SHELLDER, :GASTLY,
    :DROWZEE, :KRABBY, :VOLTORB, :EXEGGCUTE, :CUBONE, :KOFFING, :RHYHORN,
    :HORSEA, :GOLDEEN, :STARYU, :MAGIKARP, :DRATINI, :SENTRET, :HOOTHOOT,
    :LEDYBA, :SPINARAK, :MAREEP, :HOPPIP, :WOOPER, :PINECO, :SNUBBULL, :TEDDIURSA,
    :SLUGMA, :SWINUB, :HOUNDOUR, :PHANPY, :LARVITAR, :NATU, :SUNKERN
  ]
  LEGENDARIES = [
    :ARTICUNO, :ZAPDOS, :MOLTRES, :MEWTWO, :MEW, :RAIKOU, :ENTEI, :SUICUNE, :LUGIA, :HOOH,
    :CELEBI, :REGIROCK, :REGICE, :REGISTEEL, :LATIAS, :LATIOS, :KYOGRE, :GROUDON,
    :RAYQUAZA, :JIRACHI, :DEOXYS
  ]
  WAVE_SIZE    = 4             # Pokémon in a round: this + 2 a round (40 at most)
  SPAWN_GAP    = 1.3           # seconds between them (shorter every round)
  EVOLVE_EVERY = 5
  # HP x (1 + HP_STEP x (round - 1)) ^ HP_POWER: round 10 about x2, round 20
  # about x3.4, round 40 about x7 (it used to be x1.15 every round)
  HP_STEP      = 0.06
  HP_POWER     = 1.6
  SHINY_CHANCE = 100
  SHINY_SPEED  = 3.0
  SHINY_POINTS = 10
  BOSS_EVERY   = 10
  BOSS_MORE_EVERY = 50         # one more boss on a boss round every 50 rounds
  BOSS_DAMAGE  = 80            # a hit on a tower from round 30 on (like a stage 3
                               # tower); 20 + 2 a round before that
  BOSS_ATTACK_DELAY = 2.2
  BOSS_LEAK    = 5
  BOSS_SPEED   = 0.6           # x its normal speed
  BOSS_POINTS  = 10
  SPECIAL_EVERY  = 25
  SPECIAL_BOSSES = [:GENGAR, :MUK, :CROBAT, :SNORLAX]
  SPECIAL_HP     = 2            # x a boss's HP
  SPECIAL_DRAIN  = 0.5          # points drained on track tile n: n x this
  SPECIAL_POINTS = 50

  # what the shop sells: price and what it does
  ITEMS = {
    :POTION      => { :price => 5 },    # a tower gets POTION_HEAL HP back
    :SPIKES      => { :price => 8 },    # on the track for SPIKES_TIME s
    :POISON_BOMB => { :price => 10 },   # goes off after BOMB_TIME s
    :X_ATTACK    => { :price => 15 },   # towers do x X_ATTACK damage this round
    :X_DEFEND    => { :price => 10 },   # bosses do half damage to towers this round
    :EXP_SHARE   => { :price => 5000 }  # every knock out gives EXP to every tower this round
  }
  POTION_HEAL     = 50
  SPIKES_TIME     = 10.0
  SPIKES_DAMAGE   = 0.25        # of a Pokémon's max HP (a boss: SPIKES_BOSS)
  SPIKES_BOSS     = 0.05
  BOMB_TIME       = 5.0
  BOMB_RADIUS     = 1.6
  BOMB_POISON     = 0.06        # of the max HP a second, for BOMB_POISON_TIME
  BOMB_POISON_TIME = 6.0
  X_ATTACK        = 1.5

  module_function

  def hp_scale(round); (1 + HP_STEP * (round - 1))**HP_POWER; end
  def cost(key); TOWERS[key][:cost] || BUY_COST; end

  #----------------------------------------------------------------------------
  class Enemy
    attr_reader :species, :max_hp, :speed, :types, :boss, :shiny, :special
    attr_accessor :hp, :dist, :attack_cd, :id, :poison_time, :poison_dps, :poison_src, :tile, :spiked, :blown,
                  :stun_time, :slow_time, :slow, :furthest

    # boss: true, or :special (the point drainer)
    def initialize(species, hp, speed, types, boss = false, shiny = false)
      @species, @max_hp, @hp, @speed, @types, @boss, @shiny = species, hp, hp.to_f, speed, types, !!boss, shiny
      @special = boss == :special
      @stun_time = @slow_time = 0.0
      @slow = 1.0
      @furthest = 0      # the furthest route tile it reached (special bosses drain on new ones)
      @dist = 0.0
      @attack_cd = BOSS_ATTACK_DELAY
      @poison_time = 0.0
      @poison_dps = 0.0
      @blown = 0.0      # tiles still to be blown back
      @spiked = {}
    end

    def alive?;    @hp > 0;          end
    def poisoned?; @poison_time > 0; end
    def stunned?;  @stun_time > 0;   end
    def slowed?;   @slow_time > 0;   end
    def evolved?;  !Dex.basic?(@species); end
    def points
      return SPECIAL_POINTS if @special
      return BOSS_POINTS if @boss
      return SHINY_POINTS if @shiny
      evolved? ? 2 : 1
    end
    def exp; evolved? || @boss ? 2 : 1; end
  end

  class Tower
    attr_reader :key, :col, :row
    attr_accessor :stage, :hp, :cooldown, :paid, :facing, :id, :exp, :boosted

    def initialize(key, col, row, facing = 0)
      @key, @col, @row = key, col, row
      @stage = 0
      @cooldown = 0.0
      @paid = TowerDefense.cost(key)
      @exp = 0
      @facing = facing   # 0 down, 1 left, 2 right, 3 up (follower sprite rows)
    end

    def gust?;  TOWERS[@key][:gust]; end
    def aura?;  !stats[:slow].nil?;  end     # Paras: slows, no shots
    def boost?; stats[:boost];       end     # Mew
    def last_stage?; @stage >= TOWERS[@key][:line].size - 1; end

    def species; TOWERS[@key][:line][@stage];  end
    def stats;   TOWERS[@key][:stats][@stage]; end
    def type;    stats[:type] || TOWERS[@key][:type]; end
    def damage;  stats[:dmg];   end
    def delay;   @boosted ? stats[:delay] / MEW_SPEED : stats[:delay]; end
    def range;   stats[:range]; end
    def max_hp;  (Dex.card_hp(species) * TOWER_HP * (@boosted ? MEW_HP : 1)).round; end
    def x; @col + 0.5; end
    def y; @row + 0.5; end
    def evolve_cost; last_stage? ? nil : EVOLVE_COST[@stage]; end   # nil at the last stage
    def exp_need;    last_stage? ? nil : EXP_NEED[@stage];    end
    def exp_ready?;  exp_need && @exp >= exp_need; end
    def sell_price;  (@paid * SELL_RATE).floor; end
  end

  class Shot
    attr_reader :target, :damage, :type, :from
    attr_accessor :x, :y

    def initialize(from, target, damage)
      @from, @target, @damage = from, target, damage
      @x, @y = from.x, from.y - 0.3
      @type = from.type
    end
  end

  # a Pidgey's Gust: flies straight from the tower; carried: Pokémon it hit
  Gust = Struct.new(:from, :x, :y, :dx, :dy, :left, :damage, :carried)

  # spikes on a track tile / a poison bomb on any tile
  Trap = Struct.new(:kind, :col, :row, :time, :id) do
    def x; col + 0.5; end
    def y; row + 0.5; end
  end

  #----------------------------------------------------------------------------
  # the game: map, money, waves, everything moving
  #----------------------------------------------------------------------------
  class Game
    attr_reader :path, :enemies, :towers, :shots, :events, :pool, :queue, :traps, :gusts
    attr_accessor :points, :lives, :round, :state, :x_attack, :x_defend, :exp_share

    def initialize(rng = Random.new)
      @rng = rng
      @path = TowerDefense.make_path(@rng)
      @path_set = @path.to_h { |c| [c, true] }
      @enemies, @towers, @shots, @events, @traps, @gusts = [], [], [], [], [], []
      @queue = []          # [species, boss?] still to come this round
      @spawn_cd = 0.0
      @points, @lives, @round = START_POINTS, START_LIVES, 0
      @state = :build      # :build (between rounds), :wave, :over
      @pool = [FIRST_SPECIES]
      @next_id = 0
      @x_attack = @x_defend = @exp_share = false   # for this round (or the next, bought between rounds)
    end

    #--- the track -------------------------------------------------------------
    # the walk: one tile before the first track tile, the track, one tile after
    def route
      @route ||= begin
        first, last = @path.first, @path.last
        [[first[0] - 1, first[1]]] + @path + [[last[0] + 1, last[1]]]
      end
    end

    def route_length; route.size - 1; end

    # [x, y, facing] at distance d along the walk (tile centres)
    def position(d)
      d = d.clamp(0.0, route_length.to_f)
      i = [d.floor, route_length - 1].min
      a, b = route[i], route[i + 1]
      t = d - i
      x = a[0] + (b[0] - a[0]) * t + 0.5
      y = a[1] + (b[1] - a[1]) * t + 0.5
      facing = b[0] > a[0] ? 2 : b[0] < a[0] ? 1 : b[1] > a[1] ? 0 : 3
      [x, y, facing]
    end

    # the track tile an enemy is on (nil before / after the field)
    def tile_at(d)
      c = route[d.round.clamp(0, route_length)]
      @path_set[c] ? c : nil
    end

    def on_field?(c, r); c.between?(0, COLS - 1) && r.between?(0, ROWS - 1); end
    def path?(c, r); @path_set[[c, r]]; end
    def tower_at(c, r); @towers.find { |t| t.col == c && t.row == r }; end
    def trap_at(c, r); @traps.find { |t| t.col == c && t.row == r }; end
    def buildable?(c, r)
      on_field?(c, r) && !path?(c, r) && !tower_at(c, r) && !trap_at(c, r)
    end

    #--- the player ------------------------------------------------------------
    # facing: which way a Gust tower blows (0 down, 1 left, 2 right, 3 up)
    def buy(key, c, r, facing = 0)
      return :blocked unless buildable?(c, r)
      price = TowerDefense.cost(key)
      return :rival if rival_near?(key, c, r)
      return :no_points if @points < price
      t = Tower.new(key, c, r, facing)
      t.id = (@next_id += 1)
      t.hp = t.max_hp
      @points -= price
      @towers << t
      refresh_boosts
      :ok
    end

    def evolve(tower)
      cost = tower.evolve_cost
      return :max if cost.nil?
      return :no_exp unless tower.exp_ready?
      return :no_points if @points < cost
      @points -= cost
      tower.stage += 1
      tower.paid += cost
      tower.exp = 0
      tower.hp = tower.max_hp
      refresh_boosts
      :ok
    end

    def sell(tower)
      @points += tower.sell_price
      @towers.delete(tower)
      @shots.reject! { |s| s.from.equal?(tower) }
      @gusts.reject! { |g| g.from.equal?(tower) }
      refresh_boosts
      tower.sell_price
    end

    # Mewtwo can't be built in a Mew's range, nor a Mew with a Mewtwo in its range
    def rival_near?(key, c, r)
      x, y = c + 0.5, r + 0.5
      if key == :MEWTWO
        @towers.any? { |m| m.key == :MEW && (m.x - x)**2 + (m.y - y)**2 <= m.range**2 }
      elsif key == :MEW
        range = TOWERS[:MEW][:stats][0][:range]
        @towers.any? { |m| m.key == :MEWTWO && (m.x - x)**2 + (m.y - y)**2 <= range**2 }
      else
        false
      end
    end

    # Mew: the towers in its range get more HP (and the HP that comes with
    # it) and fire faster
    def refresh_boosts
      mews = @towers.select(&:boost?)
      @towers.each do |t|
        now = t.key != :MEWTWO && mews.any? { |m| !m.equal?(t) && (m.x - t.x)**2 + (m.y - t.y)**2 <= m.range**2 }
        next if now == !!t.boosted
        before = t.max_hp
        t.boosted = now
        t.hp = now ? t.hp + (t.max_hp - before) : [t.hp, t.max_hp].min
      end
    end

    # item: ITEMS key; at: a tower (Potion) or [col, row] (Spikes, Poison Bomb)
    def use_item(item, at = nil)
      price = ITEMS[item][:price]
      return :no_points if @points < price
      case item
      when :POTION
        return :blocked unless at.is_a?(Tower) && at.hp < at.max_hp
        at.hp = [at.hp + POTION_HEAL, at.max_hp].min
      when :SPIKES
        return :blocked unless path?(*at) && !trap_at(*at)
        @traps << Trap.new(:spikes, at[0], at[1], SPIKES_TIME, (@next_id += 1))
      when :POISON_BOMB
        return :blocked unless on_field?(*at) && !tower_at(*at) && !trap_at(*at)
        @traps << Trap.new(:bomb, at[0], at[1], BOMB_TIME, (@next_id += 1))
      when :X_ATTACK
        return :blocked if @x_attack
        @x_attack = true
      when :X_DEFEND
        return :blocked if @x_defend
        @x_defend = true
      when :EXP_SHARE
        return :blocked if @exp_share
        @exp_share = true
      end
      @points -= price
      @events << [:item, item, at]
      :ok
    end

    #--- rounds ----------------------------------------------------------------
    def boss_round?(r = @round); r > 0 && r % BOSS_EVERY == 0; end
    def boss_count(r = @round); boss_round?(r) ? 1 + r / BOSS_MORE_EVERY : 0; end
    def boss_damage; [20 + 2 * @round, BOSS_DAMAGE].min; end
    def special_round?(r = @round); r > 0 && r % SPECIAL_EVERY == 0; end

    def start_round
      return false unless @state == :build
      @round += 1
      grow_pool if @round > 1
      count = [WAVE_SIZE + @round * 2, 40].min
      @queue = Array.new(count) { [@round == 1 ? FIRST_SPECIES : @pool.sample(random: @rng), false] }
      boss_count.times { @queue << [boss_species, true] }
      @queue << [special_species, :special] if special_round?
      @spawn_cd = 0.0
      @state = :wave
      @events << [:round_start, @round]
      true
    end

    # a new species each round; every EVOLVE_EVERY rounds one of them evolves
    def grow_pool
      fresh = WILD_SPECIES.select { |s| Dex.usable?(s) } - @pool
      @pool << fresh.sample(random: @rng) unless fresh.empty?
      return unless (@round - 1) % EVOLVE_EVERY == 0
      can = @pool.select { |s| Dex.evolution(s) }
      return if can.empty?
      s = can.sample(random: @rng)
      evo = Dex.evolution(s)
      @pool[@pool.index(s)] = evo
      @events << [:pool_evolved, s, evo]
    end

    # a legendary or a fully evolved Pokémon of this game's waves
    def boss_species
      legends = LEGENDARIES.select { |s| Dex.usable?(s) }
      return legends.sample(random: @rng) if !legends.empty? && @rng.rand(2) == 0
      finals = @pool.map { |s| s = Dex.evolution(s) while Dex.evolution(s); s }.reject { |s| Dex.basic?(s) }
      return finals.sample(random: @rng) unless finals.empty?
      legends.empty? ? @pool.sample(random: @rng) : legends.sample(random: @rng)
    end

    def special_species
      can = SPECIAL_BOSSES.select { |s| Dex.usable?(s) }
      can.empty? ? boss_species : can.sample(random: @rng)
    end

    # boss: false, true or :special
    def spawn(species, boss)
      base = Dex.card_hp(species)
      shiny = !boss && @rng.rand(SHINY_CHANCE) == 0
      hp = if boss
             base * [@round / 2, 1].max * (boss == :special ? SPECIAL_HP : 1)
           else
             [((base * TowerDefense.hp_scale(@round)) / 10.0).round * 10, 10].max
           end
      hp = 1 if @round == 1 && !boss   # round 1: every hit knocks out
      speed = Dex.walk_speed(species) * (boss ? BOSS_SPEED : shiny ? SHINY_SPEED : 1)
      e = Enemy.new(species, hp, speed, Dex.types(species), boss, shiny)
      e.id = (@next_id += 1)
      @enemies << e
      @events << [e.special ? :special_appears : :boss_appears, e] if boss
      @events << [:shiny_appears, e] if shiny
      e
    end

    #--- one step of dt seconds --------------------------------------------------
    def update(dt)
      return if @state != :wave
      # spawns
      @spawn_cd -= dt
      if @spawn_cd <= 0 && !@queue.empty?
        species, boss = @queue.shift
        spawn(species, boss)
        @spawn_cd = @queue.first && @queue.first[1] ? 2.0 : [SPAWN_GAP - 0.03 * @round, 0.45].max
      end
      update_traps(dt)
      # walking (and stepping on spikes)
      @enemies.each do |e|
        if e.blown > 0
          back = [GUST_SPEED * dt, e.blown].min
          e.blown -= back
          e.dist = [e.dist - back, 0.0].max
        elsif e.stunned?
          e.stun_time -= dt
        else
          e.dist += e.speed * dt * (e.slowed? ? e.slow : 1)
        end
        if e.slowed?
          e.slow_time -= dt
          e.slow = 1.0 unless e.slowed?
        end
        drain_points(e) if e.special
        if e.dist >= route_length
          e.hp = 0
          @lives -= e.boss ? BOSS_LEAK : 1
          @events << [:leak, e]
          next
        end
        tile = tile_at(e.dist)
        next if tile == e.tile
        e.tile = tile
        spikes = tile && @traps.find { |t| t.kind == :spikes && t.col == tile[0] && t.row == tile[1] }
        next if !spikes || e.spiked[spikes.id]
        e.spiked[spikes.id] = true
        hurt(e, (e.max_hp * (e.boss ? SPIKES_BOSS : SPIKES_DAMAGE)).ceil, nil)
        @events << [:spiked, e]
      end
      # poison
      @enemies.each do |e|
        next unless e.alive? && e.poisoned?
        e.poison_time -= dt
        hurt(e, e.poison_dps * dt, e.poison_src)
      end
      # bosses hit towers next to the track
      @enemies.each { |e| boss_attack(e, dt) if e.boss && !e.special && e.alive? }
      # towers fire
      @towers.each do |t|
        t.cooldown -= dt
        if t.aura?
          next if t.cooldown > 0
          t.cooldown = t.delay
          slow_around(t)
          next
        end
        if t.gust?
          next if t.cooldown > 0 || !gust_target?(t)
          dx, dy = DIRS[t.facing]
          @gusts << Gust.new(t, t.x, t.y, dx, dy, t.range, ((t.damage * (@x_attack ? X_ATTACK : 1)) / 2.0).round, [])
          t.cooldown = t.delay
          @events << [:gust, t]
          next
        end
        target = target_for(t)
        next unless target
        tx, ty, = position(target.dist)
        t.facing = (tx - t.x).abs > (ty - t.y).abs ? (tx > t.x ? 2 : 1) : (ty > t.y ? 0 : 3)
        next if t.cooldown > 0
        @shots << Shot.new(t, target, (t.damage * (@x_attack ? X_ATTACK : 1)).round)
        t.cooldown = t.delay
        @events << [:shoot, t]
      end
      # shots fly to their target (gone if it is)
      @shots.reject! do |s|
        next true unless s.target.alive?
        tx, ty, = position(s.target.dist)
        dx, dy = tx - s.x, ty - s.y
        len = Math.sqrt(dx * dx + dy * dy)
        step = SHOT_SPEED * dt
        if len <= step
          hit(s)
          true
        else
          s.x += dx / len * step
          s.y += dy / len * step
          false
        end
      end
      update_gusts(dt)
      @enemies.reject! { |e| !e.alive? }
      if @lives <= 0
        @lives = 0
        @state = :over
        @events << [:game_over, @round]
      elsif @queue.empty? && @enemies.empty?
        @state = :build
        bonus = ROUND_BONUS + @round
        @points += bonus
        @towers.each do |t|
          t.hp = [t.hp + TOWER_REGEN, t.max_hp].min
          t.exp += ROUND_EXP if t.exp_need
        end
        @x_attack = @x_defend = @exp_share = false
        @traps.reject! { |t| t.kind == :spikes }
        @shots.clear
        @gusts.clear
        @events << [:round_clear, @round, bonus]
      end
    end

    # spikes wear off, bombs go off
    def update_traps(dt)
      @traps.reject! do |t|
        t.time -= dt
        next false if t.time > 0
        if t.kind == :bomb
          hits = @enemies.select do |e|
            x, y, = position(e.dist)
            e.alive? && e.dist > 0.3 && (x - t.x)**2 + (y - t.y)**2 <= BOMB_RADIUS**2
          end
          hits.each { |e| poison(e, e.max_hp * BOMB_POISON, BOMB_POISON_TIME, nil) }
          @events << [:bomb, t, hits.size]
        end
        true
      end
    end

    # a special boss on a track tile it never reached before drains points
    def drain_points(e)
      idx = e.dist.floor
      return if idx <= e.furthest
      amount = ((e.furthest + 1)..idx).sum { |k| (k * SPECIAL_DRAIN).ceil }
      e.furthest = idx
      amount = [amount, @points].min
      return if amount <= 0
      @points -= amount
      @events << [:drained, e, amount]
    end

    # Paras: everything next to it is slowed
    def slow_around(t)
      st = t.stats
      @enemies.each do |e|
        next unless e.alive? && e.dist > 0.3
        x, y, = position(e.dist)
        next if (x - t.x)**2 + (y - t.y)**2 > t.range**2
        @events << [:slowed, e] unless e.slowed?
        e.slow = e.slowed? ? [e.slow, st[:slow]].min : st[:slow]
        e.slow_time = [e.slow_time, st[:slow_time]].max
      end
    end

    # a Pokémon in the Gust's line
    def gust_target?(t)
      dx, dy = DIRS[t.facing]
      @enemies.any? do |e|
        next false unless e.alive? && e.dist > 0.5
        x, y, = position(e.dist)
        along = (x - t.x) * dx + (y - t.y) * dy
        side = (x - t.x) * dy - (y - t.y) * dx
        along > 0.3 && along <= t.range && side.abs < 0.6
      end
    end

    # Gusts fly straight; each Pokémon they touch (up to :carry) takes the
    # damage once and is blown :push tiles back along the track
    def update_gusts(dt)
      @gusts.reject! do |g|
        step = GUST_SPEED * dt
        g.x += g.dx * step
        g.y += g.dy * step
        g.left -= step
        st = g.from.stats
        @enemies.each do |e|
          break if g.carried.size >= st[:carry]
          next unless e.alive? && e.dist > 0.3 && !g.carried.include?(e)
          x, y, = position(e.dist)
          next if (x - g.x)**2 + (y - g.y)**2 > 0.6**2
          g.carried << e
          # bosses only budge 1 tile; the special boss is meant to be blown back
          e.blown = [e.blown, e.boss && !e.special ? 1 : st[:push]].max
          mult = Dex.effectiveness(g.from.type, e.types)
          dmg = (g.damage * mult).round
          @events << [:hit, e, dmg, mult]
          hurt(e, dmg, @towers.include?(g.from) ? g.from : nil)
        end
        g.left <= 0
      end
    end

    # the enemy furthest along the track in range
    def target_for(t)
      best = nil
      r2 = t.range**2
      @enemies.each do |e|
        next unless e.alive? && e.dist > 0.5
        x, y, = position(e.dist)
        next if (x - t.x)**2 + (y - t.y)**2 > r2
        best = e if best.nil? || e.dist > best.dist
      end
      best
    end

    def hit(s)
      e = s.target
      t = s.from
      mult = Dex.effectiveness(s.type, e.types)
      dmg = (s.damage * mult).round
      st = t.stats
      @events << [:hit, e, dmg, mult]
      if st[:poison] && (st[:chance].nil? || @rng.rand < st[:chance])
        poison(e, st[:poison] * (@x_attack ? X_ATTACK : 1), POISON_TIME, t)
      end
      drain(t, dmg) if st[:drain]
      if st[:stun] && @rng.rand < st[:stun]
        @events << [:stunned, e] unless e.stunned?
        e.stun_time = [e.stun_time, e.boss ? st[:stun_time] / 2 : st[:stun_time]].max   # bosses: half as long
      end
      hurt(e, dmg, t)
    end

    def poison(e, dps, time, src)
      return unless e.alive?
      @events << [:poisoned, e] unless e.poisoned?
      e.poison_dps = e.poisoned? ? [e.poison_dps, dps].max : dps
      e.poison_time = [e.poison_time, time].max
      e.poison_src = src if src || !e.poison_src
    end

    # Mega Drain: the tower and the towers around it get half the damage back
    def drain(t, dmg)
      heal = dmg / 2
      return if heal <= 0
      @towers.each do |o|
        next if (o.x - t.x)**2 + (o.y - t.y)**2 > DRAIN_RANGE**2 || o.hp >= o.max_hp
        o.hp = [o.hp + heal, o.max_hp].min
        @events << [:healed, o, heal]
      end
    end

    # damage from anything; a knock out gives points, EXP to the tower (src)
    def hurt(e, dmg, src)
      return unless e.alive?
      e.hp = [e.hp - dmg, 0].max
      return if e.alive?
      @points += e.points
      if @exp_share
        @towers.each { |t| t.exp += e.exp if t.exp_need }
      elsif src && @towers.include?(src) && src.exp_need
        src.exp += e.exp
      end
      @lives += 1 if e.shiny
      @events << [:knock_out, e, e.points]
    end

    def boss_attack(e, dt)
      e.attack_cd -= dt
      return if e.attack_cd > 0
      tile = tile_at(e.dist) or return
      near = @towers.select { |t| (t.col - tile[0]).abs <= 1 && (t.row - tile[1]).abs <= 1 }
      return if near.empty?
      t = near.min_by(&:hp)
      dmg = @x_defend ? boss_damage / 2 : boss_damage
      t.hp -= dmg
      e.attack_cd = BOSS_ATTACK_DELAY
      @events << [:boss_attack, e, t, dmg]
      return if t.hp > 0
      @towers.delete(t)
      @shots.reject! { |s| s.from.equal?(t) }
      @gusts.reject! { |g| g.from.equal?(t) }
      refresh_boosts
      @events << [:tower_down, t]
    end
  end

  #----------------------------------------------------------------------------
  # a random track: from the left edge to the right one, PATH_LENGTH tiles,
  # never touching itself (so it reads as one road)
  #----------------------------------------------------------------------------
  def self.make_path(rng = Random.new)
    200.times do
      start = [0, rng.rand(1..ROWS - 2)]
      path = grow_path([start], rng, [0])
      return path if path
    end
    # fallback: a fixed snake (down, across, up, across, ...)
    path = []
    c = 0
    down = true
    while c < COLS
      path << [c, down ? 1 : ROWS - 2]
      if c % 4 == 3 && c < COLS - 1
        rows = (2..ROWS - 2).to_a
        rows.reverse! unless down
        rows.each { |r| path << [c, r] }
        down = !down
      end
      c += 1
    end
    path.uniq
  end

  # tries: [steps tried so far] for the whole search (gives up after 3000)
  def self.grow_path(path, rng, tries)
    return nil if (tries[0] += 1) > 3000
    c, r = path.last
    if c == COLS - 1
      return PATH_LENGTH.cover?(path.size) ? path : nil
    end
    return nil if path.size >= PATH_LENGTH.max
    # too far from the right edge to make it in time
    return nil if path.size + (COLS - 1 - c) > PATH_LENGTH.max
    moves = [[1, 0], [0, 1], [0, -1], [-1, 0]].shuffle(random: rng)
    moves.sort_by! { |dc, _| dc > 0 ? rng.rand(2) : rng.rand(1..3) }   # some forward pull
    moves.each do |dc, dr|
      n = [c + dc, r + dr]
      next unless n[0].between?(0, COLS - 1) && n[1].between?(0, ROWS - 1)
      next if path.include?(n)
      # not next to any earlier tile (only to the one it comes from)
      next if path[0...-1].any? { |p| (p[0] - n[0]).abs + (p[1] - n[1]).abs == 1 }
      next if n[0] == 0 && path.size > 1                       # leave the left edge
      next if n[0] == COLS - 1 && path.size + 1 < PATH_LENGTH.min   # too short yet
      res = grow_path(path + [n], rng, tries)
      return res if res
    end
    nil
  end
end
