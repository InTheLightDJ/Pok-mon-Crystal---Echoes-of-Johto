#==============================================================================
# Pokémon Pinball (GBC) - holiday boards
#
# On a holiday its table is drawn in that holiday's colours:
#   Halloween (Oct 31)                      Blue Field
#   Thanksgiving (US, 4th Thursday of Nov)  Red Field
#   Christmas (Dec 25)                      Red Field
#   Easter (Sunday)                         Blue Field
# The colours come from recoloured pictures of the whole table
# (Pinball-mod/table_art/<Holiday><red|blue>_full.png), turned into colours
# for each 8x8 map cell by Pinball-mod/tools (holiday_cells.rb ->
# make_holiday_boards.py -> holiday_cells.rb --pack) into
# Data/Pinball_GBC_Holidays.rxdata. Only the table's background changes
# (the ball, flippers and Pokémon are sprites and keep their colours; the
# billboard keeps the game's, its pictures change). Works in both views.
#==============================================================================
module PinballGBC
  HOLIDAY_FILE = "Data/Pinball_GBC_Holidays.rxdata"
  HOLIDAY_FIELD_STAGES = { 0 => 0, 1 => 0, 4 => 1, 5 => 1 }   # stage => field

  # one half of a holiday table: Screen#layer asks it for each map cell
  class HolidayBoard
    attr_reader :colors, :map

    def initialize(half, colors)
      @cells = half[:cells]       # cell * 8 + palette => colour set (-1: the game's)
      @global = half[:global]     # palette => colour set
      @colors = colors
      @map = 0x1800               # the Fields' BG map (the window's is $9c00)
    end

    def id(cell, pal)
      v = @cells[cell * 8 + pal]
      return v < 0 ? nil : v if v
      @global[pal]
    end
  end

  # tests / the debug menu: a holiday name (:christmas...) to use instead of
  # today's
  class << self
    attr_accessor :holiday_override
  end

  module_function

  def holiday_today(time = Time.now)
    return holiday_override if holiday_override
    m = time.month
    d = time.day
    return :halloween if m == 10 && d == 31
    return :christmas if m == 12 && d == 25
    return :thanksgiving if m == 11 && time.wday == 4 && (22..28).cover?(d)
    e = easter(time.year)
    return :easter if m == e[0] && d == e[1]
    nil
  end

  # [month, day] of Easter Sunday (anonymous Gregorian algorithm)
  def easter(y)
    a = y % 19
    b, c = y.divmod(100)
    d, e = b.divmod(4)
    g = (8 * b + 13) / 25
    h = (19 * a + b - d - g + 15) % 30
    i, k = c.divmod(4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    mm = (a + 11 * h + 22 * l) / 451
    month = (h + l - 7 * mm + 114) / 31
    day = ((h + l - 7 * mm + 114) % 31) + 1
    [month, day]
  end

  # today's holiday table: { field:, top: HolidayBoard, bottom: HolidayBoard }
  def holiday_boards
    name = holiday_today
    return nil unless name
    @holiday_data ||= Marshal.load(Zlib::Inflate.inflate(load_data(HOLIDAY_FILE)))
    t = @holiday_data[name.to_sym]
    return nil unless t
    colors = t[:sets].map { |set| set.map { |c| c && Color.new(*c) } }
    { field: t[:field], top: HolidayBoard.new(t[:top], colors), bottom: HolidayBoard.new(t[:bottom], colors) }
  rescue StandardError
    nil
  end

  # the half of the table that stage is, if today's holiday table is that field
  def holiday_half(boards, stage)
    return nil unless boards && HOLIDAY_FIELD_STAGES[stage] == boards[:field]
    stage.odd? ? boards[:bottom] : boards[:top]
  end

  class Screen
    attr_reader :recolor

    def recolor=(board)
      @recolor = board
    end
  end
end
