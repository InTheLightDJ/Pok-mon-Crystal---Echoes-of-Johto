#===============================================================================
# Battle Status Screen and Quick Poké Ball Button
#===============================================================================
# Battle Status Screen
#-------------------------------------------------------------------------------
# Several informations are shown in this screen like Name, Level, HP, status Condition,
# stats modifier, type, ability, held items, and battle states. But it will slightly
# different for the opponent's screen, some information like amount of HP, ability and 
# held items are hidden.
# Currently the opponent's held item can be identified with this situation:
# - Mega Evolve
# - Held Item removed (Consume, Knock Off, Incinerate)
# - Identified by Frisk ability
# - Identified by Covet and Thieft
# - Identified by Pickpocket
# - Identified by Switcheroo and Trick
# Currently the opponent's ability can be identified with this situation:
# - Showing in ability bar
# - Identified by Trace ability
#
#-------------------------------------------------------------------------------
# Battle State Variables
#-------------------------------------------------------------------------------
module Battle::BattleStateVariables
  WEATHER_EFFECTS = {
    :Sun                       => {desc: "Boosts Fire-type moves and weakens Water-type moves."},
    :Rain                      => {desc: "Boosts Water-type moves and weakens Fire-type moves."},
    :Sandstorm                 => {desc: "Boosts Sp. Def of Rock-type and damages non Rock/Ground/Steel."},
    :Snow                      => {desc: "Boosts Def of Ice-type and makes Blizzard more likely hit.", name: "Snow"},
    :Hail                      => {desc: "Damages non Ice-type and makes Blizzard more likely hit.", name: "Hail"},
    :Hailstorm                 => {desc: "Boosts Def of Ice-type and damages non Ice-type.", name: "Hailstorm"},
    :HarshSun                  => {desc: "Boosts Fire-type moves and negates Water-type moves."},
    :HeavyRain                 => {desc: "Boosts Water-type moves and negates Fire-type moves."},
    :StrongWinds               => {desc: "Weakens super effective moves againts Flying-type."},
    :ShadowSky                 => {desc: "Boosts Shadow moves and damages non Shadow Pokémon."},
  }

  TERRAIN = {
    :Electric                  => {desc: "Boosts Electric-type moves and immunes to sleep to grounded Pokémon.", name: "Electric Terrain"},
    :Grassy                    => {desc: "Boosts Grass-type moves and recovers HP to grounded Pokémon.", name: "Grassy Terrain"},
    :Misty                     => {desc: "Weakens Dragon-type moves and prevents status change to grounded Pokémon.", name: "Misty Terrain"},
    :Psychic                   => {desc: "Boosts Psychic-type moves and fails priority moves to grounded Pokémon.", name: "Psychic Terrain"},
  }

  FIELD_EFFECTS = {
    PBEffects::FairyLock       => {desc: "Prevents Pokémon from fleeing.", name: "Fairy Lock", turn: true},
    PBEffects::Gravity         => {desc: "Vulnerable to Ground-type moves and prevents certain moves.", name: "Gravity", turn: true},
    PBEffects::IonDeluge       => {desc: "Changes Normal-type moves to Electric-type moves.", name: "Ion Deluge"},
    PBEffects::MagicRoom       => {desc: "Pokémon's held item loses their effects.", name: "Magic Room", turn: true},
    PBEffects::MudSportField   => {desc: "Weakens Electric-type moves.", name: "Mud Sport", turn: true},
    PBEffects::TrickRoom       => {desc: "Makes slower Pokémon to move first", name: "Trick Room", turn: true},
    PBEffects::WaterSportField => {desc: "Weakens Fire-type moves.", name: "Water Sport", turn: true},
    PBEffects::WonderRoom      => {desc: "Makes Pokémon's Defense and Sp. Def stats swapped", name: "Wonder Room", turn: true}
  }

  POSITION_EFFECTS = {
    PBEffects::FutureSightCounter => {desc: "Takes damage when this effect ends.", name: "Future Sight", turn: true},
    PBEffects::HealingWish        => {desc: "Restores HP and Cures status conditions.", name: "Healing Wish"},
    PBEffects::LunarDance         => {desc: "Fully restores HP and Cures status conditions.", name: "Lunar Dance"},
    PBEffects::Wish               => {desc: "Restores half of it's HP.", name: "Wish", turn: true}
  }

  SIDE_EFFECTS = {
    PBEffects::AuroraVeil         => {desc: "Reduces damage from physical and special moves.", name: "Aurora Veil", turn: true},
    PBEffects::CraftyShield       => {desc: "Protected itself and its allies from status moves.", name: "Crafty Shield"},
    PBEffects::LightScreen        => {desc: "Reduces damage from special moves.", name: "Light Screen", turn: true},
    PBEffects::LuckyChant         => {desc: "Prevents foe from landing critical hits.", name: "Lucky Chant", turn: true},
    PBEffects::MatBlock           => {desc: "Protects itself and its allies from damaging moves.", name: "Mat Block"},
    PBEffects::Mist               => {desc: "Prevents any of its stats from lowering.", name: "Mist", turn: true},
    PBEffects::QuickGuard         => {desc: "Protects itself and its allies from priority moves.", name: "Quick Guard"},
    PBEffects::Rainbow            => {desc: "Doubles the probability of secondary effects occurring.", name: "Rainbow", turn: true}, # Fire Pledge + Water Pledge
    PBEffects::Reflect            => {desc: "Reduces damage from physical attacks.", name: "Reflect", turn: true},
    PBEffects::Safeguard          => {desc: "Prevents from all status conditions and confusion.", name: "Safe Guard", turn: true},
    PBEffects::SeaOfFire          => {desc: "Takes a bit of damage for each turn.", name: "Sea of Fire", turn: true}, # Grass Pledge + Fire Pledge
    PBEffects::Spikes             => {desc: "Takes a {1} of damage for each turn.", name: "Spikes"},
    PBEffects::StealthRock        => {desc: "Takes a damage based on its Rock-type effectiveness each turn.", name: "Pointed stones"},
    PBEffects::StickyWeb          => {desc: "Lowers Pokémon's Speed stat.", name: "Sticky Web"},
    PBEffects::Swamp              => {desc: "Halves Pokémon Speed stat.", name: "Swamp", turn: true}, # Water Pledge + Grass Pledge
    PBEffects::Tailwind           => {desc: "Doubles the Speed stat.", name: "Tailwind", turn: true},
    PBEffects::ToxicSpikes        => {desc: "{1} grounded Pokémon.", name: "Poison spikes"},
    PBEffects::WideGuard          => {desc: "Protects Pokémon from moves that can target multiple Pokémon.", name: "Wide Guard"}
  }

  BATTLER_EFFECTS = {
    PBEffects::AquaRing       => {desc: "Regains a bit of HP on every turn.", name: "Aqua Ring"},
    PBEffects::BanefulBunker  => {desc: "Protects and poisons any attacker that makes contact.", name: "Baneful Bunker"},
    PBEffects::Bide           => {desc: "Endures attacks and then strikes it back double.", name: "Bide", turn: true},
    PBEffects::Charge         => {desc: "Boosts the next Electric-type move it uses.", name: "Charge", turn: true},
    PBEffects::ChoiceBand     => {desc: "Boosts it's Attack stat but is only able to use a single move.", name: "Choice Band"},
    PBEffects::Confusion      => {desc: "Causes to sometimes failing to use a move and damaging itself.", name: "Confusion", turn: true},
    PBEffects::Curse          => {desc: "Takes a bit of damage for each turn.", name: "Curse"},
    PBEffects::DefenseCurl    => {desc: "Curls up to conceal weak spots.", name: "Defense Curl"},
    PBEffects::DestinyBond    => {desc: "Gets faint if the caster faints.", name: "Destiny Bond"},
    PBEffects::Disable        => {desc: "Prevents from using the move it last used.", name: "Disable", turn: true},
    PBEffects::Electrify      => {desc: "Changes the type of the next move into an Electric-type.", name: "Electrify"},
    PBEffects::Embargo        => {desc: "Prevents from using an item and its held item.", name: "Embargo", turn: true},
    PBEffects::Encore         => {desc: "Causes to keep using only the move it last used.", name: "Encore", turn: true},
    PBEffects::Endure         => {desc: "Endures any attack with at least 1 HP.", name: "Endure"},
    PBEffects::Flinch         => {desc: "Unable to use a move.", name: "Flinch"},
    PBEffects::FocusEnergy    => {desc: "Raises it's chance to land a critical hit.", name: "Focus Energy"},
    PBEffects::FollowMe       => {desc: "Draws attention and makes all targets take aim only at the user.", name: "Follow Me", turn: true},   # Order of use, lowest takes priority
    PBEffects::Foresight      => {desc: "Makes Ghost-type lose its immunity and easier to hit.", name: "Foresight"},
    PBEffects::GastroAcid     => {desc: "Negates the effect of the target's Ability.", name: "Gastro Acid"},
    PBEffects::Grudge         => {desc: "Depletes the PP of the foe's move that knocked it out.", name: "Grudge"},
    PBEffects::HealBlock      => {desc: "Prevents from any moves, Abilities, or held items that recover HP.", name: "Heal Block", turn: true},
    PBEffects::HelpingHand    => {desc: "Boosts its power move.", name: "Helping Hand"},
    PBEffects::HyperBeam      => {desc: "Skips turn after firing a Hyper Beam.", name: "Hyper Beam", turn: true},
    PBEffects::Illusion       => {desc: "Causes it to look like another Pokémon in the party.", name: "Illusion"},
    PBEffects::Imprison       => {desc: "Imprison disables others' moves known by self", name: "Imprison"},
    PBEffects::Ingrain        => {desc: "Restores a bit amount of its HP on every turn.", name: "Ingrain"},
    PBEffects::JawLock        => {desc: "Prevents switching out until either the target or the user faints.", name: "Jaw Lock"},   # Battler index
    PBEffects::LaserFocus     => {desc: "The next attack will always be a critical hit.", name: "Laser Focus", turn: true},
    PBEffects::LeechSeed      => {desc: "Loses some HP on every turn.", name: "Leech Seed"},
    PBEffects::LockOn         => {desc: "Ensures the next attack does not fail to hit the target.", name: "Lock-On", turn: true},
    PBEffects::MagicCoat      => {desc: "Reflects back certain status moves to the user.", name: "Magic Coat"},
    PBEffects::MagnetRise     => {desc: "Levitates to gain immunity from Ground-type moves.", name: "Magnet Rise", turn: true},
    PBEffects::MeanLook       => {desc: "Prevents it from switching out or fleeing.", name: "Mean Look"},   # Battler index
    PBEffects::MicleBerry     => {desc: "Raises the next attack accuracy.", name: "Micle Berry"},
    PBEffects::Minimize       => {desc: "Raises it's evassion, but takes double damage from certain moves.", name: "Minimize"},
    PBEffects::MiracleEye     => {desc: "Loses its immunity from Psychic-type move and easier to hit.", name: "Miracle Eye"},
    PBEffects::MudSport       => {desc: "Weakens Electric-type moves.", name: "Mud Sport"},
    PBEffects::Nightmare      => {desc: "Inflicts some damage every turn to a sleeping Pokémon.", name: "Nightmare"},
    PBEffects::NoRetreat      => {desc: "Raises all the stats but prevents it from fleeing.", name: "No Retreat"},
    PBEffects::Obstruct       => {desc: "Protects and lowers Def stat any attacker that makes contact.", name: "Obstruct"},
    PBEffects::Octolock       => {desc: "Prevents from switching out or fleeing.", name: "Octolock"},   # Battler index
    PBEffects::Outrage        => {desc: "Rampages for several turns until It then becomes confused.", name: "Outrage", turn: true},
    PBEffects::PerishSong     => {desc: "Faints after this effect ends.", name: "Perish Song", turn: true},
    PBEffects::Powder         => {desc: "Fails its Fire-type move and damages it.", name: "Powder"},
    PBEffects::PowerTrick     => {desc: "Attack and Defense stats are swapped.", name: "Power Trick"},
    PBEffects::Protect        => {desc: "Protects it from any damaging move.", name: "Protect"},
    PBEffects::Quash          => {desc: "Makes its move to go last.", name: "Quash", turn: true},
    PBEffects::Roost          => {desc: "Loses its Flying-type.", name: "Roost"},
    PBEffects::ShellTrap      => {desc: "Deals damage if it is hit by a physical move.", name: "Shell Trap"},
    PBEffects::SlowStart      => {desc: "Halves the Attack and Defense stats.", name: "Slow Start", turn: true},
    PBEffects::SmackDown      => {desc: "Makes it vulnerable to Ground-type moves.", name: "Smack Down"},
    PBEffects::Snatch         => {desc: "Steals the effects of any healing or stat-changing move.", name: "Snatch", turn: true},
    PBEffects::SpikyShield    => {desc: "Protects and deals to any attacker that makes contact.", name: "Spiky Shield"},
    PBEffects::Spotlight      => {desc: "Changes the target move to itself.", name: "Spotlight", turn: true},
    PBEffects::Stockpile      => {desc: "Charges up power and its defense.", name: "Stockpile", turn: true},
    PBEffects::Substitute     => {desc: "Creates a copy of itself as a decoy.", name: "Substitute", turn: true},
    PBEffects::TarShot        => {desc: "Makes it weak to Fire-type moves.", name: "Tar Shot"},
    PBEffects::Taunt          => {desc: "Causes to only use attack moves.", name: "Taunt", turn: true},
    PBEffects::Telekinesis    => {desc: "Makes it easier to hit.", name: "Telekinesis", turn: true},
    PBEffects::ThroatChop     => {desc: "Causes to cannot use sound-based moves.", name: "Throat Chop", turn: true},
    PBEffects::Torment        => {desc: "Makes it incapable of using the same move twice in a row.", name: "Torment"},
    PBEffects::Transform      => {desc: "Turns into a copy of the target Pokémon.", name: ""},
    PBEffects::Trapping       => {desc: "Prevents it from switching out or fleeing.", name: "Trapped", turn: true},
    PBEffects::Truant         => {desc: "Makes it loaf around and skip this round.", name: "Truant"},
    PBEffects::Uproar         => {desc: "Keeps on using Uproar and prevents all Pokémon from sleeping.", name: "Uproar", turn: true},
    PBEffects::WaterSport     => {desc: "Weakens Fire-type moves.", name: "Water Sport"},
    PBEffects::WeightChange   => {desc: "Reduces its weight to raises its Speed stat.", name: "Autotomize"},
    PBEffects::Yawn           => {desc: "Falling asleep when this effect ends.", name: "Yawn", turn: true},
    # New effects
    PBEffects::AllySwitch     => {desc: "Teleports and switches places with one of its allies.", name: "Ally Switch", default: false },
    PBEffects::DoubleShock    => {desc: "Loses its Electric-type.", name: "Double Shock"},
    PBEffects::GlaiveRush     => {desc: "Makes it cannot evade and receives double damage.", name: "Glaive Rush", turn: true },
    PBEffects::SaltCure       => {desc: "Takes damage every turn. Water and Steel-type take more.", name: "Salt Cure"},
    PBEffects::SilkTrap       => {desc: "Protects and lowers attacker's Speed that makes contact.", name: "Silk Trap"},
    PBEffects::Splinters      => {desc: "Takes a bit of damage for each turn.", name: "Splinters", turn: true},
    PBEffects::Syrupy         => {desc: "Causes it Speed stat to be lowered each turn.", name: "Syrupy", turn: true },
    PBEffects::BurningBulwark => {desc: "Protects and burns any attacker that makes contact.", name: "Burning Bulwark" }
  }

  def self.getWeatherDescription(weather)
    return WEATHER_EFFECTS[[:Snow,:Hailstorm][Settings::HAIL_WEATHER_TYPE-1]][:desc] if weather == :Hail && Settings::HAIL_WEATHER_TYPE > 0
    return WEATHER_EFFECTS[weather][:desc]
  end
  
  def self.getWeatherName(weather)
    return [_INTL("Snow"),_INTL("Hailstorm")][Settings::HAIL_WEATHER_TYPE - 1][:name] if weather == :Hail && Settings::HAIL_WEATHER_TYPE > 0
    return GameData::BattleWeather.get(weather).name
  end
end

#-------------------------------------------------------------------------------
# Window list of Battle states for Battle Status Screen
#-------------------------------------------------------------------------------
class Window_BattleStates < Window_CommandPokemon
  def self.newWithSize(commands, x, y, width, height, viewport = nil)
    ret = self.new(commands, width)
    ret.x = x
    ret.y = y
    ret.width = width
    ret.height = height
    ret.viewport = viewport
    ret.rowHeight = 16
    ret.windowskin = nil
    return ret
  end

  def drawItem(index, _count, rect)
    pbSetSystemFont(self.contents) if @starting
    @text_shift = 0 if !@text_shift || @lastindex != self.index
    @text_phase = 0 if !@text_phase
    @text_move_timer = System.uptime if !@text_move_timer
    @text_too_long = false if !@text_too_long || index == self.index
    rect = drawCursor(index, rect)
    states_data = @commands[index]
    text = states_data[0]
    duration = states_data[2] if states_data[2]
    # Split text for the running text
    rect_width = rect.width
    rect_width -= 40 if duration
    real_width = rect_width - 16
    if self.contents.text_size(text).width > rect_width # Check if this text is too long for the window
      @text_too_long = true if index == self.index
      cmdtext = ""
      text.chars.each_with_index{|char, i| 
        next if i < @text_shift && index == self.index  # skip letter for the running text
        break if  self.contents.text_size(cmdtext).width > real_width
        cmdtext += char
        # if this is the last letter, set as the last phase
        if i == text.chars.length - 1 && @text_shift > 0 && index == self.index
          @text_move_timer = System.uptime
          @text_phase = 2
        end
      }
      text = cmdtext
    end
    pbDrawShadowText(self.contents, rect.x, rect.y + (self.contents.text_offset_y || 0),
                    rect.width, rect.height, text, self.baseColor, self.shadowColor)
    # Duration text
    pbDrawShadowText(self.contents, rect.x + rect.width - 36, rect.y + (self.contents.text_offset_y || 0),
                    rect.width, rect.height, duration, self.baseColor, self.shadowColor) if duration
  end
end

#-------------------------------------------------------------------------------
# Added new attribute to track opponent's abilities and items
#-------------------------------------------------------------------------------
class Battle
  attr_accessor :seenAbilities   # Used to track opponent's pokemon abilities.
  attr_reader   :seenItems       # Used to track opponent's pokemon held items.
  attr_reader   :max_dur_weather # Used to track maximum duration current weather
  attr_reader   :max_dur_terrain # Used to track maximum duration current terrain

  alias battleState_initialize initialize
  def initialize(scene, p1, p2, player, opponent)
    battleState_initialize(scene, p1, p2, player, opponent)
    @seenAbilities = Array.new(@party2.length, false)
    @seenItems     = Array.new(@party2.length, false)
  end

  def setSeenBattlerAbility(battler)
    return if !opposes?(battler)
    @seen_abilities ||= []
    #@seenAbilities[battler.pokemonIndex] = value
    @seen_abilities[battler.index] = battler.ability
  end
  
  def getSeenBattlerAbility(battler)
    return true if !opposes?(battler)
    return @seenAbilities[battler.pokemonIndex]
  end

  def setSeenBattlerItem(*args)
    args.each{|battler|
      next if !opposes?(battler)
      #@seenItems[battler.pokemonIndex] = value
      @seenItems[battler.pokemonIndex] = battler.item
    }
  end
  
  def getSeenBattlerItem(battler)
    return true if !opposes?(battler)
    return @seenItems[battler.pokemonIndex]
  end

  alias battleState_pbShowAbilitySplash pbShowAbilitySplash
  def pbShowAbilitySplash(battler, delay = false, logTrigger = true)
    # Set battler ability as seen
    setSeenBattlerAbility(battler)
    # Set other battler ability as seen if the user has Trace ability
    if battler.hasActiveAbility?(:TRACE)
      allOtherSideBattlers(battler.index).each do |b|
        setSeenBattlerAbility(b)
        setSeenBattlerItem(b) if b.hasActiveItem?(:ABILITYSHIELD)
      end
    end
    # Set other battler ability as seen if the user has Trace ability
    if battler.hasActiveAbility?(:FRISK)
      allOtherSideBattlers(battler.index).each do |b|
        setSeenBattlerItem(b)
      end
    end
    battleState_pbShowAbilitySplash(battler, delay, logTrigger)
  end

  alias battleState_pbStartWeather pbStartWeather
  def pbStartWeather(user, newWeather, fixedDuration = false, showAnim = true)
    battleState_pbStartWeather(user, newWeather, fixedDuration, showAnim)
    @max_dur_weather = @field.weatherDuration
  end

  alias battleState_pbStartTerrain pbStartTerrain
  def pbStartTerrain(user, newTerrain, fixedDuration = true)
    battleState_pbStartTerrain(user, newTerrain, fixedDuration)
    @max_dur_terrain = @field.terrainDuration
  end

  alias battleState_pbMegaEvolve pbMegaEvolve
  def pbMegaEvolve(idxBattler)
    battleState_pbMegaEvolve(idxBattler)
    setSeenBattlerItem(@battlers[idxBattler])
  end
end

#-------------------------------------------------------------------------------
# Added displayed illusion's ability and Type, also to track opponent item
#-------------------------------------------------------------------------------
class Battle::Battler
  def displayAbility
    return @effects[PBEffects::Illusion].ability if @effects[PBEffects::Illusion]
    return self.ability
  end

  def displayTypes
    return @effects[PBEffects::Illusion].types if @effects[PBEffects::Illusion]
    return self.types
  end

  # alias battleState_pbConsumeItem pbConsumeItem
  # def pbConsumeItem(recoverable = true, symbiosis = true, belch = true)
  #   battleState_pbConsumeItem(recoverable, symbiosis, belch)
  #   @battle.setSeenBattlerItem(self)
  # end

  alias battleState_pbRemoveItem pbRemoveItem
  def pbRemoveItem(permanent = true)
    battleState_pbRemoveItem(permanent)
    @battle.setSeenBattlerItem(self)
  end
end

#-------------------------------------------------------------------------------
# Added Quick Poké Ball and Battle Status Screen functions and assets
#-------------------------------------------------------------------------------
class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
  alias oldinit initialize
  def initialize(viewport,z)
    oldinit(viewport,z)
    # Variable Declarations
    @battleStatePage = 0
    @battleStateIndex = 0
    $player.lastPokeballIndex = 0 if !$player.lastPokeballIndex
    @idxBattler = 0
    @battleStateWindowListIndex = -1
    @states_list = []
    # Battle Status Window
    @battleStatusmsgBox = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 0, 96, viewport)
    @battleStatusmsgBox.baseColor   = TEXT_BASE_COLOR
    @battleStatusmsgBox.shadowColor = TEXT_SHADOW_COLOR
    @battleStatusmsgBox.z = self.z + 1
    @battleStatusmsgBox.visible = false
    @battleStatusitemBox = Window_UnformattedTextPokemon.newWithSize("", 0, 138, 70, 70, viewport)
    @battleStatusitemBox.z = self.z + 1
    @battleStatusitemBox.visible = false
    @battleStateOverlay = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
    @battleStateOverlay.x = 0
    @battleStateOverlay.y = 0
    @battleStateOverlay.z = self.z + 1
    pbSetSystemFont(@battleStateOverlay.bitmap)
    addSprite("battleStateOverlay",@battleStateOverlay)
    @battleStateWindowList = Window_BattleStates.newWithSize([], -2, 160, Graphics.width, 100, viewport)
    @battleStateWindowList.z = self.z + 2
    addSprite("battleStateWindowList", @battleStateWindowList)
    pbSetSmallFont(@battleStateWindowList.contents)
    @battleStateOverlaySmall = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
    @battleStateOverlaySmall.x = 0
    @battleStateOverlaySmall.y = 0
    @battleStateOverlaySmall.z = self.z + 3
    pbSetSmallFont(@battleStateOverlaySmall.bitmap)
    addSprite("battleStateOverlaySmall",@battleStateOverlaySmall)
    @battleStateOverlaySmallDesc = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
    @battleStateOverlaySmallDesc.x = 0
    @battleStateOverlaySmallDesc.y = 0
    @battleStateOverlaySmallDesc.z = self.z + 3
    pbSetSmallFont(@battleStateOverlaySmallDesc.bitmap)
    addSprite("battleStateOverlaySmallDesc",@battleStateOverlaySmallDesc)
    @pkmniconsprite = PokemonIconSprite.new(nil, viewport)
    @pkmniconsprite.x = 10
    @pkmniconsprite.y = 0
    @pkmniconsprite.z = self.z + 4
    addSprite("pkmniconsprite", @pkmniconsprite)
    refresh
  end

  alias battleState_dispose dispose
  def dispose
    @battleStatusmsgBox&.dispose
    @battleStatusitemBox&.dispose
    battleState_dispose
  end

  alias battleState_refresh refresh
  def refresh
      @battleStatusmsgBox&.refresh
      @battleStateWindowList&.refresh
      @battleStatusitemBox&.refresh
      battleState_refresh
      pbRefreshShortcut
  end

  def changeIndexBattler(value=0)
    battler_list = []
    @battle.allSameSideBattlers.each{ |b| battler_list.push(b.index)}
    @battle.allOtherSideBattlers.each{|b| battler_list.push(b.index)}
    @battleStateIndex += value
    @battleStateIndex = battler_list.length - 1 if @battleStateIndex < 0
    @battleStateIndex = 0                       if @battleStateIndex > battler_list.length - 1
    @idxBattler = battler_list[@battleStateIndex]
    @states_list = getBattlerStatus(@battle.battlers[@idxBattler])
    @battleStateWindowList.index = 0
    @battleStateWindowListIndex = -1
    @battleStateWindowList.commands = @states_list
    pbRefreshShortcut
  end

  def changeIndexPokeball(value=0)
    max = $bag.pockets[3].length - 1
    $player.lastPokeballIndex += value
    $player.lastPokeballIndex = max if $player.lastPokeballIndex < 0
    $player.lastPokeballIndex = 0   if $player.lastPokeballIndex > max
    pbRefreshShortcut
  end

  def updateBattleStateDescription
    return if @battleStateWindowListIndex == @battleStateWindowList.index
    return if @states_list.empty?
    echoln @states_list[@battleStateWindowList.index][0]
    @battleStateOverlaySmallDesc.bitmap.clear
    desc = @states_list[@battleStateWindowList.index][1] if !@states_list.empty?
    drawTextEx(@battleStateOverlaySmallDesc.bitmap, 12, 254, Graphics.width, 3, desc,TEXT_BASE_COLOR,TEXT_SHADOW_COLOR,16)
    @battleStateWindowListIndex = @battleStateWindowList.index
  end

  def showbattleStatePage(page)
    @battleStatePage = page
    @battleStateIndex = 0
    @idxBattler = 0
    @battleStateWindowList.index = 0
    pbRefreshShortcut
  end

  def getBattlerStatus(battler)
    return if !battler
    states = []
    # Weather
    weather = @battle.field.weather
    if weather != :None
      name = Battle::BattleStateVariables.getWeatherName(weather)
      desc = Battle::BattleStateVariables.getWeatherDescription(weather)
      dur  = @battle.field.weatherDuration
      max_dur = @battle.max_dur_weather
      max_dur = 5 if !max_dur
      weather_data = [name, desc]
      weather_data.push(_INTL("{1}/{2}", dur, max_dur)) if dur > 0
      states.push(weather_data)
    end
    # Terrain
    terrain = @battle.field.terrain
    if terrain != :None
      data = Battle::BattleStateVariables::TERRAIN[terrain]
      name = data[:name]
      desc = data[:desc]
      dur  = @battle.field.terrainDuration
      max_dur = @battle.max_dur_terrain
      max_dur = 5 if !max_dur
      terrain_data = [name, desc]
      terrain_data.push(_INTL("{1}/{2}", dur, max_dur)) if dur > 0
      states.push(terrain_data)
    end
    [Battle::BattleStateVariables::FIELD_EFFECTS, Battle::BattleStateVariables::POSITION_EFFECTS,
     Battle::BattleStateVariables::SIDE_EFFECTS, Battle::BattleStateVariables::BATTLER_EFFECTS
    ].each do |state_var|
      state_var.each{|key, data|
        add = false
        dur = 0
        if data[:turn] && battler.effects[key] && battler.effects[key] > 0
          dur = battler.effects[key]
          add = true
        elsif !data[:turn] && battler.effects[key] == true
          add = true
        end
        if add
          name = data[:name]
          desc = data[:desc]
          # Dynamic descriptions
          desc = _INTL(desc,["bit","small amount","some amount"][battler.effects[key]-1]) if key == PBEffects::Spikes
          desc = _INTL(desc,["Poisons","Badly poisons"][battler.effects[key]-1]) if key == PBEffects::ToxicSpikes
          state_data = [name, desc]
          state_data.push(_INTL("{1}",dur)) if dur > 0
          states.push(state_data)
          echoln state_data
        end
      }
    end
    return states
  end

  def clearBattleStateScreen
    @battleStateOverlay.bitmap.clear
    @battleStateOverlaySmall.bitmap.clear
    @battleStateOverlaySmallDesc.bitmap.clear
    @battleStatusmsgBox.text = ""
  end

  def resetBattleStateScreen
    @battleStatePage = 0
    pbRefreshShortcut
    @pkmniconsprite.visible               = false
    @battleStateWindowList.visible        = false
    @battleStateWindowList.active         = false
    @battleStateOverlaySmallDesc.visible  = false
    @battleStatusmsgBox.visible           = false
    @battleStatusitemBox.visible          = false
  end

  def canSeeEnemyInfo?
    return $game_switches[74]   # Replace 74 with your chosen Switch ID
  end
  
  def pbRefreshShortcut(battle = nil)
    if battle # update battle informations
      @battle = battle
      changeIndexBattler
    end
    return if !@battle
    return if !@battleStateOverlay
    $player.lastPokeballIndex = $bag.pockets[3].length - 1 if $bag.pockets[3].length > 0 && 
                                                              $player.lastPokeballIndex > $bag.pockets[3].length - 1
    clearBattleStateScreen
    textPos = []
    smallText = []
    imagepos = []
    bg = []
    @pkmniconsprite.pokemon = nil
    case @battleStatePage
    when 0
      # Background
      rect_h = @mode < 3 && ($bag.pockets[3].length == 0 || !@battle.wildBattle?) ? 36 : 72
      bg.push(["Graphics/UI/Battle/battle_status_button", self.x + 10, self.y + 14, 0, 0, 48, rect_h])
      # Base text
      textPos.push([_INTL("Info"),self.x + 60, self.y + 26,0,TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      textPos.push([_INTL("Catch"),self.x + 60, self.y + 62,0,TEXT_BASE_COLOR,TEXT_SHADOW_COLOR]) if @mode < 3 && ($bag.pockets[3].length > 0 && @battle.wildBattle?)
    when 1 # Battle Status
      # Background
      bg.push(["Graphics/UI/Battle/battle_status_bg", 0, 0])
      # Pokémon informations
      pkmn = @battle.battlers[@idxBattler]
      @pkmniconsprite.pokemon = pkmn.displayPokemon
      # Pokemon Name
      textPos.push([pkmn.name, 46, 16, :left, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Pokemon Level
      textPos.push([_INTL("Λ{1}", pkmn.level.to_s), 308, 16, :right, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
      # Battle Stats
      acc = pkmn.stages[:ACCURACY]
      eva = pkmn.stages[:EVASION]
      if !@battle.opposes?(pkmn) || canSeeEnemyInfo?
  # Draw full stats
  # This already includes text like:
      smallText = [
        [_INTL("ATTACK        {1}", pkmn.pokemon.iv[:ATTACK]),  12,  84, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("DEFENSE       {1}", pkmn.pokemon.iv[:DEFENSE]), 12, 100, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SP. ATK        {1}", pkmn.pokemon.iv[:SPECIAL_ATTACK ]), 12, 116, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SP. DEF        {1}", pkmn.pokemon.iv[:SPECIAL_DEFENSE]), 12, 132, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SPEED          {1}", pkmn.pokemon.iv[:SPEED ]),   12, 148, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("HP        {1}", pkmn.pokemon.iv[:HP]),    180, 84, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("ACC       {1}", acc),    180,  100, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("EVA       {1}", eva),    180, 116, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
       # [_INTL("CRIT      {1}", :CRITICAL),   180, 116, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      ]
    else
      smallText = [
        [_INTL("ATTACK "),  12,  84, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("DEFENSE"), 12, 100, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SP. ATK"), 12, 116, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SP. DEF"), 12, 132, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("SPEED"),   12, 148, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("HP "),    180, 84, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("ACC       {1}", acc),    180,  100, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
        [_INTL("EVA       {1}", eva),    180, 116, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      ]
    end
      # Owner Name
      owner = @battle.pbGetOwnerFromBattlerIndex(@idxBattler)
      owner_name = owner ? _INTL("{1}'s",owner.name) : _INTL("Wild")
      smallText.push([owner_name, 46, 0, :left, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Battle Turn
      smallText.push([_INTL("Turn {1}",@battle.turnCount + 1), 306, 0, :right, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Gender
      if pkmn.displayGender < 2
        gender_text  = (pkmn.displayGender == 0) ? _INTL("♂") : _INTL("♀")
        base_color   = (pkmn.displayGender == 0) ? Color.blue : Color.red
        textPos.push([gender_text, 306, 34, :right, base_color, TEXT_SHADOW_COLOR])
      end
      # Types
      pkmn.displayTypes.each_with_index do |type, i|
        next if @battle.opposes?(@idxBattler) && !($player.pokedex.seen_form?(pkmn.displaySpecies, pkmn.displayGender, pkmn.displayForm) && $player.owned?(pkmn.displaySpecies)) && !canSeeEnemyInfo?
        type_number = GameData::Type.get(type).icon_position
        type_x = (pkmn.types.length == 1) ? 12 : 12 + (58 * i)
        imagepos.push(["Graphics/UI/types", type_x, 34, 0, type_number * 14, 64, 14])
      end
      
      # Pokemon Ability
      if !@battle.opposes?(pkmn) || canSeeEnemyInfo?
        abil_name = pkmn.displayAbility.name
      else
        abil_name = @battle.getSeenBattlerAbility(pkmn) ? pkmn.displayAbility.name : "???"
      end

      # Item
      if !@battle.opposes?(pkmn) || canSeeEnemyInfo?
        item_name = pkmn.item ? pkmn.item.name : "None"
      else
        item_name = @battle.getSeenBattlerItem(pkmn) ? (pkmn.item ? pkmn.item.name : "None") : "???"
      end

      smallText.push([item_name, 32, 66, :left, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Status
      status = -1
      if pkmn.fainted?
        status = GameData::Status.count - 1
      elsif pkmn.status != :NONE
        status = GameData::Status.get(pkmn.status).icon_position
      elsif pkmn.pokerusStage == 1
        status = GameData::Status.count
      end
      imagepos.push(["Graphics/UI/statuses", 170, 34, 0, status * 14, 64, 14]) if status >= 0
      # Shiny
      imagepos.push(["Graphics/UI/shiny", 204, 32]) if pkmn.shiny?
      # Mega
      if pkmn.mega?
        imagepos.push(["Graphics/UI/Battle/icon_mega", 222, 32])
      elsif pkmn.primal?
        filename = nil
        if pkmn.isSpecies?(:GROUDON)
          filename = "Graphics/UI/Battle/icon_primal_Groudon"
        elsif pkmn.isSpecies?(:KYOGRE)
          filename = "Graphics/UI/Battle/icon_primal_Kyogre"
        end
        imagepos.push([filename, 222, 32]) if filename
      end
      # HP
      hp_text = sprintf("% 3d /% 3d", pkmn.hp, pkmn.totalhp)
      textPos.push([hp_text, 308, 66, :right, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]) if !@battle.opposes?(pkmn) || canSeeEnemyInfo?
      # HP Bar
      w = pkmn.hp * 96 / pkmn.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2   # Round to the nearest 2 pixels
      hpzone = 0
      hpzone = 1 if pkmn.hp <= (pkmn.totalhp / 2).floor
      hpzone = 2 if pkmn.hp <= (pkmn.totalhp / 4).floor
      imagepos.push(["Graphics/UI/Battle/overlay_hp", 202, 56, 0, hpzone * 4, w, 4])
      # Battle Stats
      stats_idx = 0
      GameData::Stat.each_battle{|stat|
        stages = pkmn.stages[stat.id]
        up = (pkmn.stages[stat.id] > 0) ? 0 : 14
        stages.abs.times do |i|
          x  = 82 + i * 16
          x  += 132 if stat.type == :battle
          index = stats_idx >= 5 ? stats_idx - 5 : stats_idx
          y = 86 + index * 16
          imagepos.push(["Graphics/UI/Battle/battle_status_stat_arrow", x, y, up, 0, 14, 12])
        end
        stats_idx += 1
      }
      # Update Selected Battle Status
      updateBattleStateDescription
      @battleStatusmsgBox.width = Graphics.width + 28
      @battleStatusmsgBox.x     = -12
      @battleStatusmsgBox.y     = 162
    when 2 # Pokeball Menu
      # Background
      bg.push(["Graphics/UI/Battle/battle_status_pokeball_bg", 0, 134])
      @battleStatusmsgBox.width = Graphics.width
      @battleStatusmsgBox.x     = 0
      @battleStatusmsgBox.y     = 192
      pokeball = $bag.pockets[3][$player.lastPokeballIndex] # [:POKEBALL,11]
      # Item icon
      imagepos.push(["Graphics/Items/#{pokeball[0]}", 10, 152])
      # Item name
      textPos.push([GameData::Item.get(pokeball[0]).name, self.x + 70, self.y + 2, :left, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Item quantity
      textPos.push([_ISPRINTF("x {1: 3d}", pokeball[1]), self.x + 300, self.y + 2, :right, TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
      # Item desc
      desc = GameData::Item.get(pokeball[0]).description
      @battleStatusmsgBox.text = desc
    end
    pbDrawImagePositions(@battleStateOverlay.bitmap,bg)
    pbDrawTextPositions(@battleStateOverlay.bitmap,textPos)
    pbDrawTextPositions(@battleStateOverlaySmall.bitmap,smallText)
    pbDrawImagePositions(@battleStateOverlay.bitmap,imagepos)

    @pkmniconsprite.visible    = (@battleStatePage == 1)
    @battleStateWindowList.visible = (@battleStatePage == 1 && !@states_list.empty?)
    @battleStateWindowList.active  = (@battleStatePage == 1 && !@states_list.empty?)
    @battleStateOverlaySmallDesc.visible = (@battleStatePage == 1 && !@states_list.empty?)
    @battleStatusmsgBox.visible = (@battleStatePage > 0)
    @battleStatusitemBox.visible = (@battleStatePage == 2)
  end
end

module Battle::BattleStateVariables
  def self.getWeatherDescription(weather)
    # Special-cased Hail rebrand (Snow/Hailstorm)
    if weather == :Hail && Settings::HAIL_WEATHER_TYPE && Settings::HAIL_WEATHER_TYPE > 0
      key  = [:Snow, :Hailstorm][Settings::HAIL_WEATHER_TYPE - 1]
      data = WEATHER_EFFECTS[key]
      return _INTL(data[:desc]) if data && data[:desc]
    end
    data = WEATHER_EFFECTS[weather]
    return _INTL(data[:desc]) if data && data[:desc]
    bw = GameData::BattleWeather.try_get(weather)
    return bw ? bw.name : ""
  end

  def self.getWeatherName(weather)
    # Special-cased Hail rebrand (Snow/Hailstorm)
    if weather == :Hail && Settings::HAIL_WEATHER_TYPE && Settings::HAIL_WEATHER_TYPE > 0
      key  = [:Snow, :Hailstorm][Settings::HAIL_WEATHER_TYPE - 1]
      data = WEATHER_EFFECTS[key]
      # Prefer custom name if provided, else humanize the key
      return _INTL(data[:name]) if data && data[:name]
      return key.to_s
    end
    # Use custom name if present, else fall back to GameData
    data = WEATHER_EFFECTS[weather]
    return _INTL(data[:name]) if data && data[:name]
    bw = GameData::BattleWeather.try_get(weather)
    return bw ? bw.name : weather.to_s
  end
end