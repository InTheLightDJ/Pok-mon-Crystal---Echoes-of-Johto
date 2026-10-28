#==============================================================================
# Pokemon TCG - card data accessor (LoadCardDataToBuffer* equivalent).
# Converts the generated TCG::CARDS hashes into numeric fields that match the
# original card_data_struct, so engine code can be ported 1:1.
#==============================================================================
module TCG
  class Attack
    attr_reader :name, :desc, :damage, :category, :effect, :flags1, :flags2,
                :flags3, :param, :anim, :cost

    def initialize(h)
      @name     = h[:name]
      @desc     = h[:desc]
      @damage   = h[:damage]
      @category = 0
      h[:category].each do |c|
        @category |= (c == "RESIDUAL") ? RESIDUAL : TCG.const_get(c)
      end
      @effect = h[:effect]
      @flags1 = h[:flags1].map(&:to_sym)
      @flags2 = h[:flags2].map(&:to_sym)
      @flags3 = h[:flags3].map(&:to_sym)
      @param  = h[:param]
      @anim   = h[:anim]
      # energy cost as an array indexed by color (FIRE..COLORLESS)
      @cost = Array.new(7, 0)
      h[:cost].each { |color, n| @cost[COLOR_NAMES[color]] = n }
    end

    def pokemon_power?;  (@category & ~RESIDUAL) == POKEMON_POWER; end
    def residual?;       (@category & RESIDUAL) != 0;              end
    def base_category;   @category & ~RESIDUAL;                    end
    def flag?(f);        @flags1.include?(f) || @flags2.include?(f) || @flags3.include?(f); end
    def total_cost;      @cost.sum; end
  end

  class Card
    attr_reader :id, :name, :type, :gfx, :rarity, :sets, :hp, :stage, :preevo,
                :attacks, :retreat, :weakness, :resistance, :category, :dex,
                :level, :weight, :desc, :effect, :ai_info, :raw

    @@cache = {}

    def self.get(id)
      return @@cache[id] if @@cache[id]
      h = CARDS[id] or raise ArgumentError, "Unknown TCG card #{id.inspect}"
      @@cache[id] = Card.new(id, h)
    end

    def initialize(id, h)
      @id      = id
      @raw     = h
      @name    = h[:name]
      @type    = TYPE_NAMES[h[:type]]
      @gfx     = h[:gfx]
      @rarity  = h[:rarity]
      @sets    = h[:sets]
      @effect  = h[:effect]
      @desc    = h[:desc]
      if pokemon?
        @hp         = h[:hp]
        @stage      = STAGE_NAMES[h[:stage]]
        @preevo     = h[:preevo]
        @attacks    = h[:attacks].map { |a| Attack.new(a) }
        @retreat    = h[:retreat]
        @weakness   = h[:weakness].sum { |w| WR_BITS[w] || 0 }
        @resistance = h[:resistance].sum { |w| WR_BITS[w] || 0 }
        @category   = h[:category]
        @dex        = h[:dex]
        @level      = h[:level]
        @weight     = h[:weight]
        @ai_info    = h[:ai_info]
      elsif special_trainer_pokemon?
        # ConvertSpecialTrainerCardToPokemon: in play these act as a 10 HP
        # Colorless Basic with the "Discard" Pkmn Power and can't retreat
        # (it is still a Trainer card for every other check).
        @hp         = 10
        @stage      = BASIC
        @attacks    = [Attack.new(:cost => {}, :name => "Discard",
          :desc => "When it's your turn (before your attack), you may discard this card from play.",
          :damage => 0, :category => ["POKEMON_POWER"],
          :effect => "TrainerCardAsPokemonEffectCommands",
          :flags1 => [], :flags2 => [], :flags3 => [], :param => 0, :anim => "NONE")]
        @retreat    = UNABLE_RETREAT
        @weakness   = 0
        @resistance = 0
      end
      @attacks ||= []
    end

    def special_trainer_pokemon?; [:MYSTERIOUS_FOSSIL, :CLEFAIRY_DOLL].include?(@raw[:base] || @id); end   # holos too (011b)

    def pokemon?;  @type < TYPE_ENERGY; end
    def energy?;   @type >= TYPE_ENERGY && @type < TYPE_TRAINER; end
    def trainer?;  @type >= TYPE_TRAINER; end
    def basic_energy?; energy? && @type != TYPE_ENERGY_DOUBLE_COLORLESS; end
    # color of a Pokemon card / energy provided by an energy card
    def color
      return @type if pokemon?
      return @type - TYPE_ENERGY if energy?
      return COLORLESS if special_trainer_pokemon?
      nil
    end
    def basic?; pokemon? && @stage == BASIC; end
  end

  def self.card(id); Card.get(id); end
end
