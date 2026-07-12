# NOTE: "Graphics/UI/statuses.png" also contains icons for being fainted and for
#       having Pokérus, in that order, at the bottom of the graphic.
#       "Graphics/UI/Battle/icon_statuses.png" also contains an icon for bad
#       poisoning (toxic), at the bottom of the graphic.
#       Both graphics automatically handle varying numbers of defined statuses,
#       as long as their extra icons remain at the bottom of them.
module GameData
  class Status
    attr_reader :id
    attr_reader :real_name
    attr_reader :animation
    attr_reader :icon_position   # Where this status's icon is within statuses.png

    DATA = {}

    ICON_SIZE = [32, 14]

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:name]          || "Unnamed"
      @animation     = hash[:animation]
      @icon_position = hash[:icon_position] || 0
    end

    # @return [String] the translated name of this status condition
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::Status.register({
  :id            => :NONE,
  :name          => _INTL("None")
})

GameData::Status.register({
  :id            => :SLEEP,
  :name          => _INTL("Sleep"),
  :animation     => "Sleep",
  :icon_position => 0
})

GameData::Status.register({
  :id            => :POISON,
  :name          => _INTL("Poison"),
  :animation     => "Poison",
  :icon_position => 1
})

GameData::Status.register({
  :id            => :BURN,
  :name          => _INTL("Burn"),
  :animation     => "Burn",
  :icon_position => 2
})

GameData::Status.register({
  :id            => :PARALYSIS,
  :name          => _INTL("Paralysis"),
  :animation     => "Paralysis",
  :icon_position => 3
})

GameData::Status.register({
  :id            => :FROZEN,
  :name          => _INTL("Frozen"),
  :animation     => "Frozen",
  :icon_position => 4
})


#-------------------------------------------------------------------------------
# Drowsy
#-------------------------------------------------------------------------------
# This status has the following effects:
#  -The user has a 33% chance to be unable to act each turn. 66% in Snow/Hail.
#  -The user takes 33% more damage while Drowsy.
#  -Drowziness may end naturally after 2-3 turns.
#  -Drowsiness may end early if a move with the "ElectrocuteUser" flag is used on or by the user.
#  -Is applied/blocked/healed/reduced in duration by the same things that interact with the Sleep status.
#-------------------------------------------------------------------------------
GameData::Status.register({
  :id            => :DROWSY,
  :name          => _INTL("Drowsy"),
  :animation     => "Drowsy",
  :icon_position => 5
})

#-------------------------------------------------------------------------------
# Frostbite
#-------------------------------------------------------------------------------
# This has the following effects:
#  -The user takes damage at the end of each round equal to 1/16th their max HP.
#  -Damage dealt by the user's special attacks is halved.
#  -Frostbite may end early if a move with the "ThawsUser" flag is used on or by the user.
#  -Is applied/blocked/healed by the same things that interact with the Frozen status.
#-------------------------------------------------------------------------------

GameData::Status.register({
  :id            => :FROSTBITE,
  :name          => _INTL("Frostbite"),
  :animation     => "Frostbite",
  :icon_position => 6
})