#===============================================================================
# Pokémon Performance Contest — state and global data.
# Stored inside $PokemonGlobal so it persists with saves automatically.
#===============================================================================

class PokemonGlobalMetadata
  attr_accessor :contestState
end

EventHandlers.add(:on_load, :migrate_contest_state, proc {
  $PokemonGlobal.contestState ||= PokemonContestState.new
})

#===============================================================================
# PokemonContestState — tracks the active contest session and helpers.
#===============================================================================
class PokemonContestState
  attr_accessor :in_progress
  attr_accessor :category    # :COOL / :BEAUTY / :CUTE / :SMART / :TOUGH
  attr_accessor :rank        # 0=Normal, 1=Super, 2=Hyper, 3=Master

  CATEGORIES = [:COOL, :BEAUTY, :CUTE, :SMART, :TOUGH]

  CATEGORY_NAMES = {
    :COOL   => _INTL("Cool"),
    :BEAUTY => _INTL("Beauty"),
    :CUTE   => _INTL("Cute"),
    :SMART  => _INTL("Smart"),
    :TOUGH  => _INTL("Tough")
  }

  RANK_NAMES = [
    _INTL("Normal"),
    _INTL("Super"),
    _INTL("Hyper"),
    _INTL("Master")
  ]

  # Maps [category][rank] => ribbon ID symbol.
  RIBBONS = {
    :COOL   => [:JOHTOCOOL,   :JOHTOCOOLSUPER,   :JOHTOCOOLHYPER,   :JOHTOCOOLMASTER],
    :BEAUTY => [:JOHTOBEAUTY, :JOHTOBEAUTYSUPER, :JOHTOBEAUTYHYPER, :JOHTOBEAUTYMASTER],
    :CUTE   => [:JOHTOCUTE,   :JOHTOCUTESUPER,   :JOHTOCUTEHYPER,   :JOHTOCUTEMASTER],
    :SMART  => [:JOHTOSMART,  :JOHTOSMARTSUPER,  :JOHTOSMARTHYPER,  :JOHTOSMARTMASTER],
    :TOUGH  => [:JOHTOTOUGH,  :JOHTOTOUGHSUPER,  :JOHTOTOUGHHYPER,  :JOHTOTOUGHMASTER]
  }

  # Stat accessor name on a Pokemon object for each category.
  CONDITION_STAT = {
    :COOL   => :cool,
    :BEAUTY => :beauty,
    :CUTE   => :cute,
    :SMART  => :smart,
    :TOUGH  => :tough
  }

  def initialize
    @in_progress = false
    @category    = nil
    @rank        = 0
  end

  def in_progress?
    return @in_progress == true
  end

  def start(category, rank)
    @in_progress = true
    @category    = category
    @rank        = rank
  end

  def finish
    @in_progress = false
  end

  # Returns the ribbon ID for a given category + rank, or nil.
  def ribbon_for(category, rank)
    list = RIBBONS[category]
    return list ? list[rank] : nil
  end

  # Returns true if pkmn has already won the required prior-rank ribbon.
  # Normal rank (0) is always available.
  def eligible?(pkmn, category, rank)
    return true if rank == 0
    prev = ribbon_for(category, rank - 1)
    return prev && pkmn.hasRibbon?(prev)
  end

  # Returns the condition stat value on pkmn for a given category.
  def condition(pkmn, category)
    stat = CONDITION_STAT[category]
    return stat ? pkmn.send(stat).to_i : 0
  end
end

# Lazy-init accessor — mirrors pbBugContestState pattern.
def pbContestState
  $PokemonGlobal.contestState ||= PokemonContestState.new
end
