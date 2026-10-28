#==============================================================================
# Pokemon TCG - constants. Mirrors src/constants/duel_constants.asm and
# card_data_constants.asm from the pret/poketcg disassembly.
#==============================================================================
module TCG
  MAX_BENCH_POKEMON     = 5
  MAX_PLAY_AREA_POKEMON = 6
  MAX_PRIZES            = 9   # the original has 6 (more than 6 uses the 3-column layouts)
  MAX_HP                = 120
  STARTING_HAND_SIZE    = 7
  DECK_SIZE             = 60
  MAX_NUM_SAME_NAME_CARDS = 4

  TAILS = 0
  HEADS = 1

  # wDuelFinished
  DUEL_NOT_FINISHED = 0
  TURN_PLAYER_WON   = 1
  TURN_PLAYER_LOST  = 2
  TURN_PLAYER_TIED  = 3

  # wDuelResult
  DUEL_WIN  = 0
  DUEL_LOSS = 1

  # card locations (DUELVARS_CARD_LOCATIONS)
  CARD_LOCATION_DECK         = 0x00
  CARD_LOCATION_HAND         = 0x01
  CARD_LOCATION_DISCARD_PILE = 0x02
  CARD_LOCATION_PRIZE        = 0x08
  CARD_LOCATION_ARENA        = 0x10
  CARD_LOCATION_BENCH_1      = 0x11
  CARD_LOCATION_PLAY_AREA    = 0x10   # flag (bit 4)
  CARD_LOCATION_JUST_DRAWN   = 0x40   # flag (bit 6)

  PLAY_AREA_ARENA   = 0
  PLAY_AREA_BENCH_1 = 1

  # duelist types
  DUELIST_TYPE_PLAYER   = 0x00
  DUELIST_TYPE_LINK_OPP = 0x01
  DUELIST_TYPE_AI_OPP   = 0x80

  # status conditions (two nibbles)
  NO_STATUS       = 0x00
  CONFUSED        = 0x01
  ASLEEP          = 0x02
  PARALYZED       = 0x03
  POISONED        = 0x80
  DOUBLE_POISONED = 0xc0
  CNF_SLP_PRZ     = 0x0f
  PSN_DBLPSN      = 0xf0
  PSN_DAMAGE      = 10
  DBLPSN_DAMAGE   = 20

  # substatus 1 (checked on defending Pokemon)
  SUBSTATUS1_AGILITY                 = 0x0c
  SUBSTATUS1_FLY                     = 0x0d
  SUBSTATUS1_PREVENT_LESS_THAN_40    = 0x0e
  SUBSTATUS1_NO_DAMAGE_STIFFEN       = 0x0f
  SUBSTATUS1_NO_DAMAGE_WITHDRAW      = 0x10
  SUBSTATUS1_NO_DAMAGE_HIDE_IN_SHELL = 0x11
  SUBSTATUS1_REDUCE_BY_20            = 0x13
  SUBSTATUS1_BARRIER                 = 0x14
  SUBSTATUS1_HALVE_DAMAGE            = 0x15
  SUBSTATUS1_DESTINY_BOND            = 0x16
  SUBSTATUS1_NO_DAMAGE_SCRUNCH       = 0x17
  SUBSTATUS1_NEXT_TURN_DOUBLE_DAMAGE = 0x19
  SUBSTATUS1_REDUCE_BY_10            = 0x1e

  # substatus 2 (checked on attacking Pokemon)
  SUBSTATUS2_SMOKESCREEN  = 0x01
  SUBSTATUS2_SAND_ATTACK  = 0x02
  SUBSTATUS2_REDUCE_BY_20 = 0x03
  SUBSTATUS2_AMNESIA      = 0x04
  SUBSTATUS2_TAIL_WAG     = 0x05
  SUBSTATUS2_LEER         = 0x06
  SUBSTATUS2_POUNCE       = 0x07
  SUBSTATUS2_CONVERSION2  = 0x08
  SUBSTATUS2_ACID         = 0x09
  SUBSTATUS2_BONE_ATTACK  = 0x0b
  SUBSTATUS2_GROWL        = 0x12

  SUBSTATUS3_THIS_TURN_DOUBLE_DAMAGE = 0x01
  SUBSTATUS3_HEADACHE                = 0x02

  # arena card flags
  USED_PKMN_POWER_THIS_TURN = 0x20
  USED_LEEK_SLAP_THIS_DUEL  = 0x40
  CAN_EVOLVE_THIS_TURN      = 0x80

  LAST_TURN_EFFECT_NONE           = 0
  LAST_TURN_EFFECT_DISCARD_ENERGY = 1
  LAST_TURN_EFFECT_AMNESIA        = 2

  HAS_CHANGED_COLOR = 0x80

  # wDamageEffectiveness
  WEAKNESS   = 1
  RESISTANCE = 2

  # wNoDamageOrEffect
  NO_DAMAGE_OR_EFFECT_AGILITY      = 1
  NO_DAMAGE_OR_EFFECT_BARRIER      = 2
  NO_DAMAGE_OR_EFFECT_FLY          = 3
  NO_DAMAGE_OR_EFFECT_TRANSPARENCY = 4
  NO_DAMAGE_OR_EFFECT_NSHIELD      = 5

  # wEffectFailed
  EFFECT_FAILED_NO_EFFECT    = 1
  EFFECT_FAILED_UNSUCCESSFUL = 2

  # card colors (generic type constants)
  FIRE = 0; GRASS = 1; LIGHTNING = 2; WATER = 3; FIGHTING = 4; PSYCHIC = 5
  COLORLESS = 6
  NUM_COLORED_TYPES = 6
  COLOR_NAMES = { "FIRE" => FIRE, "GRASS" => GRASS, "LIGHTNING" => LIGHTNING,
                  "WATER" => WATER, "FIGHTING" => FIGHTING, "PSYCHIC" => PSYCHIC,
                  "COLORLESS" => COLORLESS }

  # card type byte (CARD_DATA_TYPE)
  TYPE_ENERGY                  = 0x08
  TYPE_ENERGY_DOUBLE_COLORLESS = 0x0e
  TYPE_TRAINER                 = 0x10
  TYPE_NAMES = {
    "TYPE_PKMN_FIRE" => 0x00, "TYPE_PKMN_GRASS" => 0x01, "TYPE_PKMN_LIGHTNING" => 0x02,
    "TYPE_PKMN_WATER" => 0x03, "TYPE_PKMN_FIGHTING" => 0x04, "TYPE_PKMN_PSYCHIC" => 0x05,
    "TYPE_PKMN_COLORLESS" => 0x06, "TYPE_PKMN_UNUSED" => 0x07,
    "TYPE_ENERGY_FIRE" => 0x08, "TYPE_ENERGY_GRASS" => 0x09, "TYPE_ENERGY_LIGHTNING" => 0x0a,
    "TYPE_ENERGY_WATER" => 0x0b, "TYPE_ENERGY_FIGHTING" => 0x0c, "TYPE_ENERGY_PSYCHIC" => 0x0d,
    "TYPE_ENERGY_DOUBLE_COLORLESS" => 0x0e, "TYPE_ENERGY_UNUSED" => 0x0f,
    "TYPE_TRAINER" => 0x10, "TYPE_TRAINER_UNUSED" => 0x11
  }

  # stages
  BASIC  = 0
  STAGE1 = 1
  STAGE2 = 2
  STAGE2_WITHOUT_STAGE1 = 3
  STAGE_NAMES = { "BASIC" => 0, "STAGE1" => 1, "STAGE2" => 2, "STAGE2_WITHOUT_STAGE1" => 3 }

  # weakness / resistance bits
  WR_BITS = { "FIRE" => 0x80, "GRASS" => 0x40, "LIGHTNING" => 0x20,
              "WATER" => 0x10, "FIGHTING" => 0x08, "PSYCHIC" => 0x04 }
  # TranslateColorToWR: color index -> WR bit
  COLOR_TO_WR = [0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x00, 0x00]

  # attack categories
  DAMAGE_NORMAL = 0
  DAMAGE_PLUS   = 1
  DAMAGE_MINUS  = 2
  DAMAGE_X      = 3
  POKEMON_POWER = 4
  RESIDUAL      = 0x80

  UNABLE_RETREAT = 0x64
end
