# Pokémon TCG for Pokémon Essentials v21.1

A port of the Game Boy **Pokémon Trading Card Game** (from the
[pret/poketcg](https://github.com/pret/poketcg) disassembly) as a drop-in
Essentials plugin. Duels follow the original rules engine card for card,
and the computer opponents use the original AI, including its quirks and
bugs (documented in the code with `ORIGINAL BUG`).

The plugin does **not** change any of your game's scripts. You set up your
own NPCs, gyms and rewards with the script calls below.

## Install

1. Copy `Plugins/Pokemon TCG/` into your game's `Plugins/` folder.
2. Copy `Graphics/Plugins/Pokemon TCG/` (card art, duelist portraits, UI)
   into your game's `Graphics/Plugins/` folder.
3. Start the game in debug mode once so Essentials compiles the plugin.

Saving works automatically: the collection, decks and win records are
stored in the save file (`$PokemonGlobal`).

## Quick test (debug mode)

Debug menu entries:

| Entry | What it does |
|---|---|
| Pokémon TCG test duel | Pick your deck and an opponent deck, then duel |
| Pokémon TCG give cards | Give a starter deck or open a booster pack |
| Pokémon TCG decks | The deck selection screen |
| Pokémon TCG card album | Browse the collection |

## Script calls

Use these in event **Script** commands, or in **Conditional Branch → Script**
for the `?` ones.

### Duels

```ruby
pbTCGDuel("Ronald", :IM_RONALD_DECK)
```

`pbTCGDuel(name, opponent_deck, player_deck = nil, prizes: 6, id: nil,
reward: nil, portrait: nil, ai: nil)` returns `true` if the player won.

- `opponent_deck` / `player_deck`: a deck name (list below) or an array of
  60 card IDs.
- `player_deck`: leave it `nil` to use the player's active deck.
- `prizes:` number of prize cards (default 6).
- `id:` any name you like. The win is recorded so you can check
  `pbTCGBeaten?(id)` later.
- `reward:` given only on a win: a booster pack, a card, or an array of them.
- `portrait:` an image from `Graphics/Plugins/Pokemon TCG/Duelists`, shown
  before the duel (`"ronald"`, `"imakuni"`, `"murray"`…).
- `ai:` which original deck's AI to use. This lets a custom card list play
  like a boss deck, e.g. `ai: :LEGENDARY_ZAPDOS_DECK`.

Example: a gym leader you must beat once, who gives a booster pack:

```ruby
if pbTCGDuel("Leader Nikki", :FLOWER_POWER_DECK, id: :gym_grass,
             reward: :LABORATORY_GRASS, portrait: "nikki", medal: :grass)
  pbMessage("Nikki: Take good care of that medal!")
end
```

`medal: :grass` gives the Grass Medal on a win (see Medals below).

Then gate a door with **Conditional Branch → Script:** `pbTCGBeaten?(:gym_grass)`.

Every duel also sets **switch 113** ON for a win and OFF for a loss
(`TCG::RESULT_SWITCH` in `080_API.rb`). When the call is too long for a
Conditional Branch, put it in a Script command and branch on the switch:

```
@>Script: pbTCGDuel("Courtney", :LEGENDARY_MOLTRES_DECK,
 :  :      id: :courtney, reward: [:RANDOM_BOOSTER, :RANDOM_ENERGY_PACK],
 :  :      portrait: "courtney", ability: :PREVENTION)
@>Conditional Branch: Switch [0113] == ON     # won
 : Else                                        # lost
```

### Random duelist

```ruby
pbTCGRandomDuel
```

A duelist named "Trainer" with the `question` portrait. Each duel picks a random
premade deck (not the unnamed ones or the 30-card starter extras), and a win
gives one random Colosseum, Evolution or Mystery pack (`:RANDOM_CLASSIC_BOOSTER`).
Any `pbTCGDuel` option still works, e.g. `pbTCGRandomDuel(id: :random_trainer)`.
Defined in `080b_RandomDuel.rb`.

### Shadow Darkness deck

```ruby
pbTCGDuel("Name", :SHADOW_DARKNESS_DECK)
```

A premade Darkness deck (not in the original, `001g_DarknessDeck.rb`): 2 Darkness
Shadow Lugia, Larvitar/Pupitar/Tyranitar, Eevee/Umbreon, Poochyena/Mightyena,
Sneasel, Absol and Sableye, 12 Trainers the AI can play, 24 Darkness + 2 Double
Colorless Energy. The random duelist can pick it too. Not in the deck tables
below (`tools/deck_types.rb` only reads the original decks).

### Card menu (Pokégear)

The Pokégear gets a card game tab: a GSC-style Pokégear (`:pokegear_menu_gsc`)
gets a tab using its `cards` icon and background, and the stock v21
Pokégear gets a "Card Game" entry when `Graphics/UI/Pokegear/icon_cards.png`
exists. Press A there for the original game's card options:

| Option | Screen |
|---|---|
| Deck | The original deck selection: 4 deck slots, the hand icon on the dueling deck, Modify deck / Select deck / Change name / Cancel, START lists a deck's cards |
| Modify deck | The original deck build screen: LEFT/RIGHT pick a card type, DOWN goes to the list, then RIGHT adds and LEFT removes a card ("in deck/owned"), A shows the card, START shows the whole deck, B opens Confirm / Modify / Name / Save / Dismantle / Cancel |
| Card | The original "PLAYER's Cards" screen: your collection by card type (A shows the card page) |
| Card Album | The album, set by set |
| Glossary | The Pokémon Card Glossary |

`pbTCGMenu` opens the same menu from an event or a PC.

### Giving cards and decks

```ruby
pbTCGGiveDeck(:CHARMANDER_AND_FRIENDS_DECK)   # starter deck: cards + saved deck
pbTCGGiveCard(:PIKACHU_LV12)                  # one card
pbTCGGiveCard(:DOUBLE_COLORLESS_ENERGY, 2)    # two copies
pbTCGOpenBooster(:COLOSSEUM_NEUTRAL)          # open a pack, shows each card
```

Card IDs are the keys of `TCG::CARDS` in `001_CardData.rb`, for example
`:CHARIZARD`, `:MEWTWO_LV53`, `:GUST_OF_WIND`.

### Menus

```ruby
pbTCGMenu          # Deck / Card / Card Album / Glossary
pbTCGDeckMenu      # the deck selection screen
pbTCGEditDeck      # the deck build screen for a new deck (pbTCGEditDeck(0) edits deck 1)
pbTCGCardAlbum     # card album
pbTCGShowCard(:PIKACHU_LV12)   # one card's page
```

### Conditions

```ruby
pbTCGBeaten?(:gym_grass)   # won at least once against that id
pbTCGWins(:gym_grass)      # number of wins
pbTCGHasCard?(:CHARIZARD)  # owns at least one (pbTCGHasCard?(:x, 4) for 4)
pbTCGCardCount(:CHARIZARD)
pbTCGHasDeck?              # has an active saved deck
```

### Medals (trainer card)

The Club Masters' 8 medals, drawn as in the original's medal box, are a
3rd badge page on the trainer card. On the badge pages, R goes Johto badges
→ Kanto badges → Medals and L goes back. The Medals page only appears while
switch 107 is ON (`MEDAL_SWITCH` in `089f_TrainerCardMedals.rb`, `nil` =
always). Like the original, a medal you haven't won isn't drawn. The top of
that page shows "Cards" (how many different cards you own) instead of Money,
and the PvP win streak (below) instead of the Server Tokens.

| Medal | Club | Original Master |
|---|---|---|
| `:grass` | Grass | Nikki |
| `:science` | Science | Rick |
| `:fire` | Fire | Ken |
| `:water` | Water | Amy |
| `:lightning` | Lightning | Isaac |
| `:psychic` | Psychic | Murray |
| `:rock` | Rock | Gene |
| `:fighting` | Fighting | Mitch |

```ruby
pbTCGGiveMedal(:grass)               # "<player> won the Grass Medal!" + Badge get ME
pbTCGGiveMedal(:grass, show: false)  # silently
pbTCGRemoveMedal(:grass)
pbTCGHasMedal?(:grass)               # Conditional Branch → Script
pbTCGMedalCount                      # 0-8, e.g. pbTCGMedalCount >= 8
pbTCGDuel("Nikki", :FLOWER_POWER_DECK, id: :gym_grass, medal: :grass)   # given on a win
```

A medal can also be named `"Grass"`, `:grass_medal` or by number `1`-`8` in
the order above. The debug menu has "Pokémon TCG medals" to toggle them.

### PvP win streak and the Prize Counter

The server counts each player's online card duels won in a row
(`ServerStuff/handlers/tcg_prizes.js`). A PvP win adds 1 when both games
agree on who won. Any loss sets it back to 0, and so does leaving or
disconnecting from a duel that has started. Online AI duels (InTheLight)
count only while the streak is under 5 (`AI_STREAK_CAP`). The streak shows
on the trainer card's Medals page and under bragged cards in the chat.

The Prize Counter trades wins out of the streak for cards. Put an NPC down
with **Script:** `pbTCGPrizeCounter` (online only). Its clerk is Jennifer's
portrait (`CLERK` in `089s_PrizeCounter.rb`). Every player sees the same
9 prizes. A claimed prize gets a new card straight away, and they all
change at the server's midnight.

| Wins | Prize |
|---|---|
| 1 | a Base set Basic Pokémon |
| 3 | a Base/Neo Basic Pokémon, holo |
| 5 | any Base set card, holo (Imakuni too) |
| 10 | any Base/Neo card, holo |
| 20 | any card, holo |
| 25 | a legendary |
| 30 | a legendary, holo |
| 40 | Shadow Lugia |
| 50 | Shadow Lugia, holo |

"Base set" means the original game's cards (Colosseum, Evolution, Mystery,
Laboratory, Promo). There are no legendaries or Shadow Lugia below 25. A
holo prize's hidden PSA grade is 9 or 10. Rebuild the card pools after
changing cards with `tools/ruby/bin/ruby.exe tools/prizes/make_prize_cards.rb`
(from PokeTCG-mod).

```ruby
pbTCGPrizeCounter   # the counter
pbTCGWinStreak      # the streak the server last sent (Conditional Branch: pbTCGWinStreak >= 10)
```

The **PSA+1** ability (`pbTCGGiveAbility(:PSA_PLUS)`) makes every new holo's
hidden grade 1 higher, up to 10, while it's in the ability slot. That covers
packs, the shop, the trader, prizes and Card Slots. Cards bought on the Player
Market keep their grade. It does nothing in duels.

### More abilities

Give one with `pbTCGGiveAbility(:NAME)`; the player picks which one is in the
slot from the card game menu's "Ability" option. An NPC can duel with one:
`pbTCGDuel(..., ability: :SPIKES)`.

| Call | Name | What it does |
|---|---|---|
| `pbTCGGiveAbility(:TOKEN)` | Token | Pulling one of the 4 rarest holos (Grey & White, Black & Yellow, Black & Purple, Black & Red) from a booster pack, or winning one at the Card Slots, gives 1 Server Token. Not a duel ability. The server caps it at 10 tokens a day per player. |
| `pbTCGGiveAbility(:EIGHT_START)` | 8 Start | Start each duel with 8 cards in your hand. |
| `pbTCGGiveAbility(:HOLO_BOOST)` | Holo Boost | Your holo cards' attacks do 10 more damage for each Energy attached beyond the attack's cost. Attacks that already add damage per Energy (Hydro Pump, Water Gun, Energy Cannon...) only get what Holo Boost adds over that. |
| `pbTCGGiveAbility(:SPIKES)` | Spikes | Each time an opponent's Pokémon becomes the Active Pokémon (retreat, switch, knock-out replacement; not the first one), it takes 10 damage. It never knocks one out. |
| `pbTCGGiveAbility(:RESTORE)` | Restore | When one of your Pokémon is Knocked Out, 1 of its Energy cards goes to your hand (Double Colorless first). |
| `pbTCGGiveAbility(:POTION)` | Potion Plus | Your Potion, Super Potion and Hyper Potion heal 10 more damage. |
| `pbTCGGiveAbility(:STURDY)` | Sturdy | An opponent's attack can't knock out your Pokémon from full HP; it keeps 10 HP. |
| `pbTCGGiveAbility(:SLOTS)` | Slow Slots | The Card Slots reels spin a little slower (8.4 cards a second instead of 9.9). Not a duel ability. |
| `pbTCGGiveAbility(:REWARD)` | Double Reward | A duel's booster pack rewards are given twice (card rewards once). Not a duel ability. |
| `pbTCGGiveAbility(:PSA)` | PSA Shield | Duels don't wear your holo cards' PSA grades down or break them. Not a duel ability. |
| `pbTCGGiveAbility(:ONE_HKO)` | 1HKO | Every attack that does damage knocks out the Defending Pokémon, for both players (Sturdy still holds). |
| `pbTCGGiveAbility(:KNOCKOFF)` | Knock Off | Each time an attack damages a Pokémon, 1 of its Energy cards is discarded, for both players. |

### World Rankings

Each different card the player has ever owned adds 1 point to their World
Rankings score; extra copies don't count, and losing a card doesn't take the
point away. Like the Pokédex counts, the total is sent to the server at login
(`card_sync`, with the game's `dex_sync`), so cards found offline count the
next time the player logs in. It's also sent right away for each new card
found while online. Code: `089g_RankingCards.rb` here, plus
`handlers/leaderboard.js` and `db/database.js` (`tcg_cards`) in ServerStuff.

## Deck rules (same as the original)

- Exactly 60 cards and at least one Basic Pokémon (Clefairy Doll and
  Mysterious Fossil don't count).
- At most 4 cards with the same name. Basic Energy is unlimited; Double
  Colorless Energy counts.
- 4 deck slots. Cards in a saved deck count as in use for the other decks.
  The only deck can't be dismantled.

## Premade decks

Use these with `pbTCGDuel` and `pbTCGGiveDeck`. In the original game, the
Rock Club uses Fighting Pokémon and the Science Club mostly uses Grass
Pokémon (poison), so both are listed under those types.

### Decks by type

Each row lists every deck with at least 5 Pokémon of that type, with the
most of that type first. The number is how many of that type's Pokémon the
deck has, followed by the deck's original owner. Rock Club decks are under
Fighting.

| Type | Decks, most Pokémon of that type first |
|---|---|
| Grass | `:POISON_DECK` 27 (Erik), `:FLOWER_POWER_DECK` 25 (Nikki), `:FLOWER_GARDEN_DECK` 21 (Kristin), `:LOVELY_NIDORAN_DECK` 21 (David), `:GRASS_AND_PSYCHIC_DECK` 14 (Aaron), `:WONDERS_OF_SCIENCE_DECK` 14 (Rick), `:BULBASAUR_AND_FRIENDS_DECK` 13 (Starter), `:INVINCIBLE_RONALD_DECK` 9 (Ronald), `:ETCETERA_DECK` 8 (Brittany), `:NAP_TIME_DECK` 8 (Daniel), `:BOOM_BOOM_SELFDESTRUCT_DECK` 7 (Nicholas), `:FLYIN_POKEMON_DECK` 7 (Joseph), `:GHOST_DECK` 7 (Robert), `:KALEIDOSCOPE_DECK` 5 (Heather) |
| Fire | `:LEGENDARY_MOLTRES_DECK` 21 (Courtney), `:FLAMETHROWER_DECK` 16 (Adam), `:LIGHTNING_AND_FIRE_DECK` 12 (Aaron), `:RESHUFFLE_DECK` 12 (Jonathan), `:CHARMANDER_AND_FRIENDS_DECK` 10 (Starter), `:FIRE_CHARGE_DECK` 9 (Ken), `:IM_RONALD_DECK` 9 (Ronald), `:LEGENDARY_DRAGONITE_DECK` 7 (Rod), `:ANGER_DECK` 5 (John), `:BLISTERING_POKEMON_DECK` 5 (Andrew) |
| Water | `:SOUND_OF_THE_WAVES_DECK` 24 (Joshua), `:GO_GO_RAIN_DANCE_DECK` 23 (Amy), `:WATERFRONT_POKEMON_DECK` 17 (Sara), `:PRACTICE_PLAYER_DECK` 16 (Player), `:LEGENDARY_ARTICUNO_DECK` 15 (Jack), `:WATER_AND_FIGHTING_DECK` 13 (Aaron), `:SQUIRTLE_AND_FRIENDS_DECK` 12 (Starter), `:IM_RONALD_DECK` 10 (Ronald), `:BULBASAUR_AND_FRIENDS_DECK` 9 (Starter), `:EXCAVATION_DECK` 9 (Ryan), `:IMAKUNI_DECK` 7 (Imakuni?), `:LEGENDARY_DRAGONITE_DECK` 7 (Rod), `:LONELY_FRIENDS_DECK` 7 (Amanda) |
| Lightning | `:POWER_GENERATOR_DECK` 20 (Brandon), `:LEGENDARY_ZAPDOS_DECK` 17 (Steve), `:ZAPPING_SELFDESTRUCT_DECK` 17 (Isaac), `:PIKACHU_DECK` 16 (Jennifer), `:LIGHTNING_AND_FIRE_DECK` 11 (Aaron), `:BOOM_BOOM_SELFDESTRUCT_DECK` 8 (Nicholas), `:SAMS_NORMAL_DECK` 8 (Sam), `:SAMS_PRACTICE_DECK` 8 (Sam), `:CHARMANDER_AND_FRIENDS_DECK` 7 (Starter) |
| Fighting | `:ROCK_CRUSHER_DECK` 21 (Gene), `:FIRST_STRIKE_DECK` 20 (Mitch), `:HARD_POKEMON_DECK` 20 (Matthew), `:EXCAVATION_DECK` 18 (Ryan), `:BLISTERING_POKEMON_DECK` 16 (Andrew), `:SAMS_NORMAL_DECK` 16 (Sam), `:SAMS_PRACTICE_DECK` 16 (Sam), `:MUSCLES_FOR_BRAINS_DECK` 13 (Chris), `:WATER_AND_FIGHTING_DECK` 13 (Aaron), `:LOVE_TO_BATTLE_DECK` 12 (Jessica), `:HEATED_BATTLE_DECK` 11 (Michael), `:BOOM_BOOM_SELFDESTRUCT_DECK` 9 (Nicholas), `:CHARMANDER_AND_FRIENDS_DECK` 5 (Starter), `:IM_RONALD_DECK` 5 (Ronald), `:INVINCIBLE_RONALD_DECK` 5 (Ronald), `:SQUIRTLE_AND_FRIENDS_DECK` 5 (Starter) |
| Psychic | `:STRANGE_POWER_DECK` 19 (Stephanie), `:IMAKUNI_DECK` 14 (Imakuni?), `:GHOST_DECK` 12 (Robert), `:GRASS_AND_PSYCHIC_DECK` 11 (Aaron), `:STRANGE_PSYSHOCK_DECK` 11 (Murray), `:PRACTICE_PLAYER_DECK` 10 (Player), `:NAP_TIME_DECK` 8 (Daniel), `:SQUIRTLE_AND_FRIENDS_DECK` 6 (Starter) |
| Colorless | `:FLYIN_POKEMON_DECK` 16 (Joseph), `:LEGENDARY_RONALD_DECK` 15 (Ronald), `:RESHUFFLE_DECK` 15 (Jonathan), `:ANGER_DECK` 13 (John), `:KALEIDOSCOPE_DECK` 12 (Heather), `:LEGENDARY_DRAGONITE_DECK` 11 (Rod), `:POWERFUL_RONALD_DECK` 10 (Ronald), `:FIRE_CHARGE_DECK` 9 (Ken), `:LOVE_TO_BATTLE_DECK` 9 (Jessica), `:MUSCLES_FOR_BRAINS_DECK` 9 (Chris), `:LONELY_FRIENDS_DECK` 8 (Amanda), `:STRANGE_PSYSHOCK_DECK` 8 (Murray), `:NAP_TIME_DECK` 7 (Daniel), `:SAMS_NORMAL_DECK` 7 (Sam), `:SAMS_PRACTICE_DECK` 7 (Sam), `:GHOST_DECK` 6 (Robert), `:LOVELY_NIDORAN_DECK` 6 (David), `:BULBASAUR_AND_FRIENDS_DECK` 5 (Starter), `:LEGENDARY_ARTICUNO_DECK` 5 (Jack), `:PRACTICE_PLAYER_DECK` 5 (Player) |

### All decks

These show how many of the 60 cards are Pokémon of each type and how many
are each Energy, most first (DCE = Double Colorless Energy). The rest are
Trainers. "Starter extra" decks are the 30 bonus cards the original game
adds to your collection along with the starter you pick; they aren't
decks of their own. Regenerate both tables with `tools/deck_types.rb`.

Club masters and the Grand Masters (Legendary decks, Ronald's decks) use their
own AI turn logic and boss setup, exactly as in the original.

## Booster packs

`:COLOSSEUM_NEUTRAL, :COLOSSEUM_GRASS, :COLOSSEUM_FIRE, :COLOSSEUM_WATER,
:COLOSSEUM_LIGHTNING, :COLOSSEUM_FIGHTING, :COLOSSEUM_TRAINER,
:EVOLUTION_NEUTRAL, :EVOLUTION_GRASS, :EVOLUTION_NEUTRAL_FIRE_ENERGY,
:EVOLUTION_WATER, :EVOLUTION_FIGHTING, :EVOLUTION_PSYCHIC, :EVOLUTION_TRAINER,
:MYSTERY_NEUTRAL, :MYSTERY_GRASS_COLORLESS, :MYSTERY_WATER_COLORLESS,
:MYSTERY_LIGHTNING_COLORLESS, :MYSTERY_FIGHTING_COLORLESS,
:MYSTERY_TRAINER_COLORLESS, :LABORATORY_MOSTLY_NEUTRAL, :LABORATORY_GRASS,
:LABORATORY_WATER, :LABORATORY_PSYCHIC, :LABORATORY_TRAINER,
:ENERGY_LIGHTNING_FIRE, :ENERGY_WATER_FIGHTING, :ENERGY_GRASS_PSYCHIC,
:RANDOM_ENERGIES`

`:ENERGY_DARKNESS_METAL` (not in the original) holds 5 Darkness and 5 Metal
Energy. The original's packs give only its 6 Energy types; the Neo packs
(Genesis, Revelation, Discovery, Destiny) give Darkness and Metal too.

Packs are generated with the original algorithm: 1 rare, 3 uncommons and
5–6 commons per set, weighted by the pack's card-type chances.

`:GENESIS` (not in the original, art `Boosters/genesis.png`, set up in
`086b_GenesisPack.rb`) holds the promo cards no other pack has: 1 card from
`TCG::GENESIS_PROMOS` (every promo except Imakuni?), a Ditto, 1 random
common card and 7 random basic Energy cards.

Random packs (not in the original): `:RANDOM_BOOSTER` is one of the 25
packs in the first list above or `:GENESIS`, and `:RANDOM_ENERGY_PACK` is
one of the 4 Energy packs or `:ENERGY_DARKNESS_METAL`. Use them anywhere a
pack key goes; the pack is picked each time it's given (lists in
`TCG::RANDOM_PACKS`, `080_API.rb`):

```ruby
pbTCGDuel("Grinder", :FIRE_CHARGE_DECK, reward: :RANDOM_BOOSTER)
pbTCGDuel("Grinder", :FIRE_CHARGE_DECK, reward: [:RANDOM_BOOSTER, :RANDOM_ENERGY_PACK])
pbTCGOpenBooster(:RANDOM_ENERGY_PACK)
```

`DESTINY(card, rate)` (art `Boosters/destiny.png`, `086c_DestinyPack.rb`) is
a pack with a chosen rare drop, for grind trainers:

```ruby
pbTCGDuel("Grinder", :FIRE_CHARGE_DECK, reward: DESTINY(:ABRA))       # Abra 1 in 50
pbTCGDuel("Grinder", :FIRE_CHARGE_DECK, reward: DESTINY[:ABRA, 100])  # 1 in 100
pbTCGOpenBooster(DESTINY("Mewtwo", 20))                               # open one now
```

The card is a card ID or name (a name with several versions picks one at
random); the rate defaults to 50. A pack has 4 common and 2 uncommon
Pokémon, the rare slot (the chosen card at 1/rate, otherwise a random rare
Pokémon), and 3 Energy cards (1 in 10 is a Double Colorless Energy). The
Pokémon come from every original non-promo Pokémon except Stage 2 Pokémon
and the legendaries (Articuno, Zapdos, Moltres, Mewtwo, Mew); those, and the
custom cards, only come out as the chosen card; change `TCG.destiny_pokemon` for your own list.

## Music

Duels play `TCG::DUEL_BGM` (default "Simple and Clean" at 150% pitch), the
result screen plays `WIN_BGM` ("Islands") or `LOSS_BGM` ("GSC 123 The End"),
and the map music comes back after the duel and its rewards. Change the
`[file, volume, pitch]` entries at the top of `080_API.rb`; `nil` keeps the
current music.

## Speed-up scripts

If your game has a speed-up script that uses `SPEEDUP_STAGES` and
`$GameSpeed` (Q to change speed), duels and card screens run at that
speed too. With its "Only Battles" option, a duel counts as a battle: it
starts at the Battle Speed setting, Q changes the speed during the duel,
and normal speed comes back afterwards. Without such a script nothing
changes.

## Not included

- Sam's scripted tutorial duel (`:SAMS_PRACTICE_DECK` plays as a normal deck).
- Link/2-player duels, the card printer, Challenge Machine, and the
  overworld clubs. Build those with your own maps and events.

## Files

| File | Contents |
|---|---|
| `001_CardData.rb`, `040_EffectTable.rb`, `046_*`, `085_*`, `086_*` | Generated data (cards, decks, effects, deck AI lists, boosters) |
| `010`–`034` | Duel engine (turns, attacks, status, knock-outs) |
| `041`–`062` | Card effects |
| `070`–`072` | Duel screen, player input, simple test AI |
| `080`–`081` | Script calls, debug menu |
| `087`–`089f` | Collection, deck rules, deck build screen, album, boosters, Pokégear menu, save screen line, trainer card medals |
| `090`–`099e` | Original AI (turn logic, attacks, energy, retreat, trainers, powers, per-deck logic) |

## Credits

- pret, for the poketcg disassembly this is ported from.
- InTheLight, for the Essentials port.
- Pokémon and the Pokémon TCG belong to Nintendo, Creatures Inc., GAME FREAK
  and The Pokémon Company. This is a non-commercial fan project.

<!-- CARD LIST (generated by PokeTCG-mod/tools/card_list.rb) -->

## Card list

Every card in the game, Pokémon in Pokédex order (HP, then attacks with their base damage;
Pokémon Powers marked "Power:"). Each card's line ends with the script call that gives it;
add a count for more copies, e.g. `pbTCGGiveCard(:BULBASAUR, 3)`.
Regenerate with `PokeTCG-mod/tools/card_list.rb`.

### Base cards (230)

```
Bulbasaur 40hp            pbTCGGiveCard(:BULBASAUR)
  Leech Seed 20
Ivysaur 60hp              pbTCGGiveCard(:IVYSAUR)
  Vine Whip 30   Poisonpowder 20
Venusaur 100hp            pbTCGGiveCard(:VENUSAUR_LV64)
  Power: Solar Power   Mega Drain 40
Venusaur 100hp            pbTCGGiveCard(:VENUSAUR_LV67)
  Power: Energy Trans   Solarbeam 60
Charmander 50hp           pbTCGGiveCard(:CHARMANDER)
  Scratch 10   Ember 30
Charmeleon 80hp           pbTCGGiveCard(:CHARMELEON)
  Slash 30   Flamethrower 50
Charizard 120hp           pbTCGGiveCard(:CHARIZARD)
  Power: Energy Burn   Fire Spin 100
Squirtle 40hp             pbTCGGiveCard(:SQUIRTLE)
  Bubble 10   Withdraw
Wartortle 70hp            pbTCGGiveCard(:WARTORTLE)
  Withdraw   Bite 40
Blastoise 100hp           pbTCGGiveCard(:BLASTOISE)
  Power: Rain Dance   Hydro Pump 40
Caterpie 40hp             pbTCGGiveCard(:CATERPIE)
  String Shot 10
Metapod 70hp              pbTCGGiveCard(:METAPOD)
  Stiffen   Stun Spore 20
Butterfree 70hp           pbTCGGiveCard(:BUTTERFREE)
  Whirlwind 20   Mega Drain 40
Weedle 40hp               pbTCGGiveCard(:WEEDLE)
  Poison Sting 10
Kakuna 80hp               pbTCGGiveCard(:KAKUNA)
  Stiffen   Poisonpowder 20
Beedrill 80hp             pbTCGGiveCard(:BEEDRILL)
  Twineedle 30   Poison Sting 40
Pidgey 40hp               pbTCGGiveCard(:PIDGEY)
  Whirlwind 10
Pidgeotto 60hp            pbTCGGiveCard(:PIDGEOTTO)
  Whirlwind 20   Mirror Move
Pidgeot 80hp              pbTCGGiveCard(:PIDGEOT_LV38)
  Slicing Wind   Gale 20
Pidgeot 80hp              pbTCGGiveCard(:PIDGEOT_LV40)
  Wing Attack 20   Hurricane 30
Rattata 30hp              pbTCGGiveCard(:RATTATA)
  Bite 20
Raticate 60hp             pbTCGGiveCard(:RATICATE)
  Bite 20   Super Fang
Spearow 50hp              pbTCGGiveCard(:SPEAROW)
  Peck 10   Mirror Move
Fearow 70hp               pbTCGGiveCard(:FEAROW)
  Agility 20   Drill Peck 40
Ekans 40hp                pbTCGGiveCard(:EKANS)
  Spit Poison   Wrap 20
Arbok 60hp                pbTCGGiveCard(:ARBOK)
  Terror Strike 10   Poison Fang 20
Pikachu 40hp              pbTCGGiveCard(:PIKACHU_LV12)
  Gnaw 10   Thunder Jolt 30
Pikachu 50hp              pbTCGGiveCard(:PIKACHU_LV14)
  Spark 20
Pikachu 60hp              pbTCGGiveCard(:PIKACHU_LV16)
  Growl   Thundershock 20
Pikachu 60hp              pbTCGGiveCard(:PIKACHU_ALT_LV16)
  Growl   Thundershock 20
Flying Pikachu 40hp       pbTCGGiveCard(:FLYING_PIKACHU)
  Thundershock 10   Fly 30
Surfing Pikachu 50hp      pbTCGGiveCard(:SURFING_PIKACHU_LV13)
  Surf 30
Surfing Pikachu 50hp      pbTCGGiveCard(:SURFING_PIKACHU_ALT_LV13)
  Surf 30
Raichu 80hp               pbTCGGiveCard(:RAICHU_LV40)
  Agility 20   Thunder 60
Raichu 90hp               pbTCGGiveCard(:RAICHU_LV45)
  Gigashock 30
Sandshrew 40hp            pbTCGGiveCard(:SANDSHREW)
  Sand-attack 10
Sandslash 70hp            pbTCGGiveCard(:SANDSLASH)
  Slash 20   Fury Swipes 20
Nidoran♀ 60hp             pbTCGGiveCard(:NIDORANF)
  Fury Swipes 10   Call for Family
Nidorina 70hp             pbTCGGiveCard(:NIDORINA)
  Supersonic   Double Kick 30
Nidoqueen 90hp            pbTCGGiveCard(:NIDOQUEEN)
  Boyfriends 20   Mega Punch 50
Nidoran♂ 40hp             pbTCGGiveCard(:NIDORANM)
  Horn Hazard 30
Nidorino 60hp             pbTCGGiveCard(:NIDORINO)
  Double Kick 30   Horn Drill 50
Nidoking 90hp             pbTCGGiveCard(:NIDOKING)
  Thrash 30   Toxic 20
Clefairy 40hp             pbTCGGiveCard(:CLEFAIRY)
  Sing   Metronome
Clefable 70hp             pbTCGGiveCard(:CLEFABLE)
  Metronome   Minimize
Vulpix 50hp               pbTCGGiveCard(:VULPIX)
  Confuse Ray 10
Ninetails 80hp            pbTCGGiveCard(:NINETALES_LV32)
  Lure   Fire Blast 80
Ninetails 80hp            pbTCGGiveCard(:NINETALES_LV35)
  Mix-Up   Dancing Embers 10
Jigglypuff 50hp           pbTCGGiveCard(:JIGGLYPUFF_LV12)
  First Aid   Double-edge 40
Jigglypuff 50hp           pbTCGGiveCard(:JIGGLYPUFF_LV13)
  Friendship Song   Expand 10
Jigglypuff 60hp           pbTCGGiveCard(:JIGGLYPUFF_LV14)
  Lullaby   Pound 20
Wigglytuff 80hp           pbTCGGiveCard(:WIGGLYTUFF)
  Lullaby   Do the Wave 10
Zubat 40hp                pbTCGGiveCard(:ZUBAT)
  Supersonic   Leech Life 10
Golbat 60hp               pbTCGGiveCard(:GOLBAT)
  Wing Attack 30   Leech Life 20
Oddish 50hp               pbTCGGiveCard(:ODDISH)
  Stun Spore 10   Sprout
Gloom 60hp                pbTCGGiveCard(:GLOOM)
  Poisonpowder   Foul Odor 20
Vileplume 80hp            pbTCGGiveCard(:VILEPLUME)
  Power: Heal   Petal Dance 40
Paras 40hp                pbTCGGiveCard(:PARAS)
  Scratch 20   Spore
Parasect 60hp             pbTCGGiveCard(:PARASECT)
  Spore   Slash 30
Venonat 40hp              pbTCGGiveCard(:VENONAT)
  Stun Spore 10   Leech Life 10
Venomoth 70hp             pbTCGGiveCard(:VENOMOTH)
  Power: Shift   Venom Powder 10
Diglett 30hp              pbTCGGiveCard(:DIGLETT)
  Dig 10   Mud Slap 30
Dugtrio 70hp              pbTCGGiveCard(:DUGTRIO)
  Slash 40   Earthquake 70
Meowth 50hp               pbTCGGiveCard(:MEOWTH_LV14)
  Cat Punch
Meowth 50hp               pbTCGGiveCard(:MEOWTH_LV15)
  Pay Day 10
Persian 70hp              pbTCGGiveCard(:PERSIAN)
  Scratch 20   Pounce 30
Psyduck 50hp              pbTCGGiveCard(:PSYDUCK)
  Headache   Fury Swipes 10
Golduck 70hp              pbTCGGiveCard(:GOLDUCK)
  Psyshock 10   Hyper Beam 20
Mankey 30hp               pbTCGGiveCard(:MANKEY)
  Power: Peek   Scratch 10
Primeape 70hp             pbTCGGiveCard(:PRIMEAPE)
  Fury Swipes 20   Tantrum 50
Growlithe 60hp            pbTCGGiveCard(:GROWLITHE)
  Flare 20
Arcanine 70hp             pbTCGGiveCard(:ARCANINE_LV34)
  Quick Attack 10   Flames of Rage 40
Arcanine 100hp            pbTCGGiveCard(:ARCANINE_LV45)
  Flamethrower 50   Take Down 80
Poliwag 40hp              pbTCGGiveCard(:POLIWAG)
  Water Gun 10
Poliwhirl 60hp            pbTCGGiveCard(:POLIWHIRL)
  Amnesia   Doubleslap 30
Poliwrath 90hp            pbTCGGiveCard(:POLIWRATH)
  Water Gun 30   Whirlpool 40
Abra 30hp                 pbTCGGiveCard(:ABRA)
  Psyshock 10
Kadabra 60hp              pbTCGGiveCard(:KADABRA)
  Recover   Super Psy 50
Alakazam 80hp             pbTCGGiveCard(:ALAKAZAM)
  Power: Damage Swap   Confuse Ray 30
Machop 50hp               pbTCGGiveCard(:MACHOP)
  Low Kick 20
Machoke 80hp              pbTCGGiveCard(:MACHOKE)
  Karate Chop 50   Submission 60
Machamp 100hp             pbTCGGiveCard(:MACHAMP)
  Power: Strikes Back   Seismic Toss 60
Bellsprout 40hp           pbTCGGiveCard(:BELLSPROUT)
  Vine Whip 10   Call for Family
Weepinbell 70hp           pbTCGGiveCard(:WEEPINBELL)
  Poisonpowder 10   Razor Leaf 30
Victreebel 80hp           pbTCGGiveCard(:VICTREEBEL)
  Lure   Acid 20
Tentacool 30hp            pbTCGGiveCard(:TENTACOOL)
  Power: Cowardice   Acid 10
Tentacruel 60hp           pbTCGGiveCard(:TENTACRUEL)
  Supersonic   Jellyfish Sting 10
Geodude 50hp              pbTCGGiveCard(:GEODUDE)
  Stone Barrage 10
Graveler 60hp             pbTCGGiveCard(:GRAVELER)
  Harden   Rock Throw 40
Golem 80hp                pbTCGGiveCard(:GOLEM)
  Avalanche 60   Selfdestruct 100
Ponyta 40hp               pbTCGGiveCard(:PONYTA)
  Smash Kick 20   Flame Tail 30
Rapidash 70hp             pbTCGGiveCard(:RAPIDASH)
  Stomp 20   Agility 30
Slowpoke 40hp             pbTCGGiveCard(:SLOWPOKE_LV9)
  Headbutt 10   Amnesia
Slowpoke 50hp             pbTCGGiveCard(:SLOWPOKE_LV18)
  Spacing Out   Scavenge
Slowbro 60hp              pbTCGGiveCard(:SLOWBRO)
  Power: Strange Behavior   Psyshock 20
Magnemite 40hp            pbTCGGiveCard(:MAGNEMITE_LV13)
  Thunder Wave 10   Selfdestruct 40
Magnemite 40hp            pbTCGGiveCard(:MAGNEMITE_LV15)
  Tackle 10   Magnetic Storm
Magneton 60hp             pbTCGGiveCard(:MAGNETON_LV28)
  Thunder Wave 30   Selfdestruct 80
Magneton 80hp             pbTCGGiveCard(:MAGNETON_LV35)
  Sonicboom 20   Selfdestruct 100
Farfetch'd 50hp           pbTCGGiveCard(:FARFETCHD)
  Leek Slap 30   Pot Smash 30
Doduo 50hp                pbTCGGiveCard(:DODUO)
  Fury Attack 10
Dodrio 70hp               pbTCGGiveCard(:DODRIO)
  Power: Retreat Aid   Rage 10
Seel 60hp                 pbTCGGiveCard(:SEEL)
  Headbutt 10
Dewgong 80hp              pbTCGGiveCard(:DEWGONG)
  Aurora Beam 50   Ice Beam 30
Grimer 50hp               pbTCGGiveCard(:GRIMER)
  Nasty Goo 10   Minimize
Muk 70hp                  pbTCGGiveCard(:MUK)
  Power: Toxic Gas   Sludge 30
Shellder 30hp             pbTCGGiveCard(:SHELLDER)
  Supersonic   Hide in Shell
Cloyster 50hp             pbTCGGiveCard(:CLOYSTER)
  Clamp 30   Spike Cannon 30
Gastly 30hp               pbTCGGiveCard(:GASTLY_LV8)
  Sleeping Gas   Destiny Bond
Gastly 50hp               pbTCGGiveCard(:GASTLY_LV17)
  Lick 10   Energy Conversion
Haunter 50hp              pbTCGGiveCard(:HAUNTER_LV17)
  Power: Transparency   Nightmare 10
Haunter 60hp              pbTCGGiveCard(:HAUNTER_LV22)
  Hypnosis   Dream Eater 50
Gengar 80hp               pbTCGGiveCard(:GENGAR)
  Power: Curse   Dark Mind 30
Onix 90hp                 pbTCGGiveCard(:ONIX)
  Rock Throw 10   Harden
Drowzee 50hp              pbTCGGiveCard(:DROWZEE)
  Pound 10   Confuse Ray 10
Hypno 90hp                pbTCGGiveCard(:HYPNO)
  Prophecy   Dark Mind 30
Krabby 50hp               pbTCGGiveCard(:KRABBY)
  Call for Family   Irongrip 20
Kingler 60hp              pbTCGGiveCard(:KINGLER)
  Flail 10   Crabhammer 40
Voltorb 40hp              pbTCGGiveCard(:VOLTORB)
  Tackle 10
Electrode 70hp            pbTCGGiveCard(:ELECTRODE_LV35)
  Sonicboom 30   Energy Spike
Electrode 90hp            pbTCGGiveCard(:ELECTRODE_LV42)
  Tackle 20   Chain Lightning 20
Exeggcute 50hp            pbTCGGiveCard(:EXEGGCUTE)
  Hypnosis   Leech Seed 20
Exeggutor 80hp            pbTCGGiveCard(:EXEGGUTOR)
  Teleport   Big Eggsplosion 20
Cubone 40hp               pbTCGGiveCard(:CUBONE)
  Snivel   Rage 10
Marowak 60hp              pbTCGGiveCard(:MAROWAK_LV26)
  Bonemerang 30   Call for Friend
Marowak 70hp              pbTCGGiveCard(:MAROWAK_LV32)
  Bone Attack 10   Wail
Hitmonlee 60hp            pbTCGGiveCard(:HITMONLEE)
  Stretch Kick   High Jump Kick 50
Hitmonchan 70hp           pbTCGGiveCard(:HITMONCHAN)
  Jab 20   Special Punch 40
Lickitung 90hp            pbTCGGiveCard(:LICKITUNG)
  Tongue Wrap 10   Supersonic
Koffing 50hp              pbTCGGiveCard(:KOFFING)
  Foul Gas 10
Weezing 60hp              pbTCGGiveCard(:WEEZING)
  Smog 20   Selfdestruct 60
Rhyhorn 70hp              pbTCGGiveCard(:RHYHORN)
  Leer   Horn Attack 30
Rhydon 100hp              pbTCGGiveCard(:RHYDON)
  Horn Attack 30   Ram 50
Chansey 120hp             pbTCGGiveCard(:CHANSEY)
  Scrunch   Double-edge 80
Tangela 50hp              pbTCGGiveCard(:TANGELA_LV8)
  Bind 20   Poisonpowder 20
Tangela 50hp              pbTCGGiveCard(:TANGELA_LV12)
  Stun Spore 10   Poison Whip 10
Kangaskhan 90hp           pbTCGGiveCard(:KANGASKHAN)
  Fetch   Comet Punch 20
Horsea 40hp               pbTCGGiveCard(:HORSEA)
  Smokescreen 10
Seadra 60hp               pbTCGGiveCard(:SEADRA)
  Water Gun 20   Agility 20
Goldeen 40hp              pbTCGGiveCard(:GOLDEEN)
  Horn Attack 10
Seaking 70hp              pbTCGGiveCard(:SEAKING)
  Horn Attack 10   Waterfall 30
Staryu 40hp               pbTCGGiveCard(:STARYU)
  Slap 20
Starmie 60hp              pbTCGGiveCard(:STARMIE)
  Recover   Star Freeze 20
Mr. Mime 40hp             pbTCGGiveCard(:MR_MIME)
  Power: Invisible Wall   Meditate 10
Scyther 70hp              pbTCGGiveCard(:SCYTHER)
  Swords Dance   Slash 30
Jynx 70hp                 pbTCGGiveCard(:JYNX)
  Doubleslap 10   Meditate 20
Electabuzz 60hp           pbTCGGiveCard(:ELECTABUZZ_LV20)
  Light Screen   Quick Attack 10
Electabuzz 70hp           pbTCGGiveCard(:ELECTABUZZ_LV35)
  Thundershock 10   Thunderpunch 30
Magmar 50hp               pbTCGGiveCard(:MAGMAR_LV24)
  Fire Punch 30   Flamethrower 50
Magmar 70hp               pbTCGGiveCard(:MAGMAR_LV31)
  Smokescreen 10   Smog 20
Pinsir 60hp               pbTCGGiveCard(:PINSIR)
  Irongrip 20   Guillotine 50
Tauros 60hp               pbTCGGiveCard(:TAUROS)
  Stomp 20   Rampage 20
Magikarp 30hp             pbTCGGiveCard(:MAGIKARP)
  Tackle 10   Flail 10
Gyarados 100hp            pbTCGGiveCard(:GYARADOS)
  Dragon Rage 50   Bubblebeam 40
Lapras 80hp               pbTCGGiveCard(:LAPRAS)
  Water Gun 10   Confuse Ray 10
Ditto 50hp                pbTCGGiveCard(:DITTO)
  Pound 10   Morph
Eevee 50hp                pbTCGGiveCard(:EEVEE)
  Tail Wag   Quick Attack 10
Vaporeon 60hp             pbTCGGiveCard(:VAPOREON_LV29)
  Focus Energy   Bite 30
Vaporeon 80hp             pbTCGGiveCard(:VAPOREON_LV42)
  Quick Attack 10   Water Gun 30
Jolteon 60hp              pbTCGGiveCard(:JOLTEON_LV24)
  Double Kick 20   Stun Needle 30
Jolteon 70hp              pbTCGGiveCard(:JOLTEON_LV29)
  Quick Attack 10   Pin Missile 20
Flareon 60hp              pbTCGGiveCard(:FLAREON_LV22)
  Bite 30   Rage 10
Flareon 70hp              pbTCGGiveCard(:FLAREON_LV28)
  Quick Attack 10   Flamethrower 60
Porygon 30hp              pbTCGGiveCard(:PORYGON)
  Conversion 1   Conversion 2
Omanyte 40hp              pbTCGGiveCard(:OMANYTE)
  Power: Clairvoyance   Water Gun 10
Omastar 70hp              pbTCGGiveCard(:OMASTAR)
  Water Gun 20   Spike Cannon 30
Kabuto 30hp               pbTCGGiveCard(:KABUTO)
  Power: Kabuto Armor   Scratch 10
Kabutops 60hp             pbTCGGiveCard(:KABUTOPS)
  Sharp Sickle 30   Absorb 40
Aerodactyl 60hp           pbTCGGiveCard(:AERODACTYL)
  Power: Prehistoric Power   Wing Attack 30
Snorlax 90hp              pbTCGGiveCard(:SNORLAX)
  Power: Thick Skinned   Body Slam 30
Articuno 70hp             pbTCGGiveCard(:ARTICUNO_LV35)
  Freeze Dry 30   Blizzard 50
Articuno 100hp            pbTCGGiveCard(:ARTICUNO_LV37)
  Power: Quickfreeze   Ice Breath
Zapdos 80hp               pbTCGGiveCard(:ZAPDOS_LV40)
  Thunderstorm 40
Zapdos 90hp               pbTCGGiveCard(:ZAPDOS_LV64)
  Thunder 60   Thunderbolt 100
Zapdos 100hp              pbTCGGiveCard(:ZAPDOS_LV68)
  Power: Peal of Thunder   Big Thunder
Moltres 70hp              pbTCGGiveCard(:MOLTRES_LV35)
  Wildfire   Dive Bomb 80
Moltres 100hp             pbTCGGiveCard(:MOLTRES_LV37)
  Power: Firegiver   Dive Bomb 70
Dratini 40hp              pbTCGGiveCard(:DRATINI)
  Pound 10
Dragonair 80hp            pbTCGGiveCard(:DRAGONAIR)
  Slam 30   Hyper Beam 20
Dragonite 100hp           pbTCGGiveCard(:DRAGONITE_LV41)
  Power: Healing Wind   Slam 30
Dragonite 100hp           pbTCGGiveCard(:DRAGONITE_LV45)
  Power: Step In   Slam 40
Mewtwo 60hp               pbTCGGiveCard(:MEWTWO_LV53)
  Psychic 10   Barrier
Mewtwo 70hp               pbTCGGiveCard(:MEWTWO_LV60)
  Energy Absorption   Psyburn 40
Mewtwo 70hp               pbTCGGiveCard(:MEWTWO_ALT_LV60)
  Energy Absorption   Psyburn 40
Mew 40hp                  pbTCGGiveCard(:MEW_LV8)
  Power: Neutralizing Shield   Psyshock 10
Mew 50hp                  pbTCGGiveCard(:MEW_LV15)
  Mystery Attack
Mew 50hp                  pbTCGGiveCard(:MEW_LV23)
  Psywave 10   Devolution Beam

Trainers / Energy:
Grass Energy              pbTCGGiveCard(:GRASS_ENERGY)
Fire Energy               pbTCGGiveCard(:FIRE_ENERGY)
Water Energy              pbTCGGiveCard(:WATER_ENERGY)
Lightning Energy          pbTCGGiveCard(:LIGHTNING_ENERGY)
Fighting Energy           pbTCGGiveCard(:FIGHTING_ENERGY)
Psychic Energy            pbTCGGiveCard(:PSYCHIC_ENERGY)
Double Colorless Energy   pbTCGGiveCard(:DOUBLE_COLORLESS_ENERGY)
Professor Oak             pbTCGGiveCard(:PROFESSOR_OAK)
Imposter Professor Oak    pbTCGGiveCard(:IMPOSTER_PROFESSOR_OAK)
Bill                      pbTCGGiveCard(:BILL)
Mr.Fuji                   pbTCGGiveCard(:MR_FUJI)
Lass                      pbTCGGiveCard(:LASS)
Imakuni?                  pbTCGGiveCard(:IMAKUNI_CARD)
Pokémon Trader            pbTCGGiveCard(:POKEMON_TRADER)
Pokémon Breeder           pbTCGGiveCard(:POKEMON_BREEDER)
Clefairy Doll             pbTCGGiveCard(:CLEFAIRY_DOLL)
Mysterious Fossil         pbTCGGiveCard(:MYSTERIOUS_FOSSIL)
Energy Retrieval          pbTCGGiveCard(:ENERGY_RETRIEVAL)
Super Energy Retrieval    pbTCGGiveCard(:SUPER_ENERGY_RETRIEVAL)
Energy Search             pbTCGGiveCard(:ENERGY_SEARCH)
Energy Removal            pbTCGGiveCard(:ENERGY_REMOVAL)
Super Energy Removal      pbTCGGiveCard(:SUPER_ENERGY_REMOVAL)
Switch                    pbTCGGiveCard(:SWITCH)
Pokémon Center            pbTCGGiveCard(:POKEMON_CENTER)
Poké Ball                 pbTCGGiveCard(:POKE_BALL)
Scoop Up                  pbTCGGiveCard(:SCOOP_UP)
Computer Search           pbTCGGiveCard(:COMPUTER_SEARCH)
Pokédex                   pbTCGGiveCard(:POKEDEX)
PlusPower                 pbTCGGiveCard(:PLUSPOWER)
Defender                  pbTCGGiveCard(:DEFENDER)
Item Finder               pbTCGGiveCard(:ITEM_FINDER)
Gust of Wind              pbTCGGiveCard(:GUST_OF_WIND)
Devolution Spray          pbTCGGiveCard(:DEVOLUTION_SPRAY)
Potion                    pbTCGGiveCard(:POTION)
Super Potion              pbTCGGiveCard(:SUPER_POTION)
Full Heal                 pbTCGGiveCard(:FULL_HEAL)
Revive                    pbTCGGiveCard(:REVIVE)
Maintenance               pbTCGGiveCard(:MAINTENANCE)
Pokémon Flute             pbTCGGiveCard(:POKEMON_FLUTE)
Gambler                   pbTCGGiveCard(:GAMBLER)
Recycle                   pbTCGGiveCard(:RECYCLE)
Darkness Energy           pbTCGGiveCard(:DARKNESS_ENERGY)
Metal Energy              pbTCGGiveCard(:METAL_ENERGY)
```

### Neo cards (232)

```
Bulbasaur 50hp            pbTCGGiveCard(:BULBASAUR_NEO)
  Tackle 10   Poison Seed 10
Ivysaur 60hp              pbTCGGiveCard(:IVYSAUR_NEO)
  Strange Scent   Razor Leaf 30
Venusaur 100hp            pbTCGGiveCard(:VENUSAUR_NEO)
  Power: Harvest Bounty   Body Slam 40
Charmander 50hp           pbTCGGiveCard(:CHARMANDER_NEO)
  Tail Rap 10   Flare 20
Charmeleon 70hp           pbTCGGiveCard(:CHARMELEON_NEO)
  Fire Claws 30   Bonfire
Shining Charizard 100hp   pbTCGGiveCard(:SHINING_CHARIZARD)
  White-hot Flame 100
Charizard 110hp           pbTCGGiveCard(:CHARIZARD_NEO)
  Power: Crystal Type   Fireblast 40   Dragon Tail 50
Squirtle 40hp             pbTCGGiveCard(:SQUIRTLE_NEO)
  Headbutt 10   Bubblebeam 20
Wartortle 80hp            pbTCGGiveCard(:WARTORTLE_NEO)
  Doubleslap 10   Giant Wave 40
Blastoise 100hp           pbTCGGiveCard(:BLASTOISE_NEO)
  Power: Jet Stream   Energy Cannon 40
Pikachu 30hp              pbTCGGiveCard(:PIKACHU_LV8)
  Thundershock 10   Agility 20
Pikachu 50hp              pbTCGGiveCard(:PIKACHU_LV13)
  Quick Attack 10   Agility 20
Raichu 80hp               pbTCGGiveCard(:RAICHU_LV32)
  Thundershock 20   Lightning Strike 40
Raichu 80hp               pbTCGGiveCard(:RAICHU_LV42)
  Plasma 10   Shock Bolt 60
Shining Raichu 70hp       pbTCGGiveCard(:SHINING_RAICHU)
  Thundersquall 40
Clefairy 50hp             pbTCGGiveCard(:CLEFAIRY_NEO)
  Doubleslap 10   Squaredance
Clefable 70hp             pbTCGGiveCard(:CLEFABLE_NEO)
  Power: Moonlight   Doubleslap 20
Vulpix 50hp               pbTCGGiveCard(:VULPIX_NEO)
  Ember 30
Ninetails 80hp            pbTCGGiveCard(:NINETALES_NEO)
  Mislead   Ethereal Flame 30
Jigglypuff 50hp           pbTCGGiveCard(:JIGGLYPUFF)
  Nap   Lullaby 10
Light Wigglytuff 80hp     pbTCGGiveCard(:LIGHT_WIGGLYTUFF)
  Evolution Song   Body Slam 20
Zubat 40hp                pbTCGGiveCard(:ZUBAT_NEO)
  Bite 10   Poison Spray
Golbat 60hp               pbTCGGiveCard(:GOLBAT_NEO)
  Screech   Poison Bite 10
Oddish 40hp               pbTCGGiveCard(:ODDISH_NEO)
  Hide   Absorb 20
Gloom 60hp                pbTCGGiveCard(:GLOOM_NEO)
  Strange Powder 20   Sticky Nectar 20
Vileplume 80hp            pbTCGGiveCard(:VILEPLUME_NEO)
  Power: Heal   Petal Dance 40
Growlithe 50hp            pbTCGGiveCard(:GROWLITHE_NEO)
  Bite 20
Light Arcanine 100hp      pbTCGGiveCard(:LIGHT_ARCANINE)
  Power: Drive Off   Gentle Flames 50
Poliwag 40hp              pbTCGGiveCard(:POLIWAG_NEO)
  Rollout 10   Hypnosis
Poliwhirl 70hp            pbTCGGiveCard(:POLIWHIRL_NEO)
  Belly Drum   Water Gun 30
Poliwrath 90hp            pbTCGGiveCard(:POLIWRATH_NEO)
  Corkscrew Punch 30   Submission 70
Abra 40hp                 pbTCGGiveCard(:ABRA_NEO)
  Scratch 10   Confuse Ray
Kadabra 70hp              pbTCGGiveCard(:KADABRA_NEO)
  Energy Recall   Confuse Ray 20
Alakazam 100hp            pbTCGGiveCard(:ALAKAZAM_NEO)
  Psymimic   Syncroblast 80
Machop 40hp               pbTCGGiveCard(:MACHOP_NEO)
  Chop 10   Punch 20
Machoke 80hp              pbTCGGiveCard(:MACHOKE_NEO)
  Focus Energy   Mega Punch 40
Machamp 90hp              pbTCGGiveCard(:MACHAMP_NEO)
  Seething Anger 20   Fling 50
Ponyta 40hp               pbTCGGiveCard(:PONYTA_NEO)
  Singe   Smash Kick 20
Rapidash 70hp             pbTCGGiveCard(:RAPIDASH_NEO)
  Overrun 20   Flame Tail 40
Slowpoke 50hp             pbTCGGiveCard(:SLOWPOKE)
  Fishing Tail   Bite 20
Slowbro 80hp              pbTCGGiveCard(:SLOWBRO_NEO)
  Power: Dense Body   Energy Cannon 30
Magnemite 40hp            pbTCGGiveCard(:MAGNEMITE)
  Attract   Tackle 20
Magneton 70hp             pbTCGGiveCard(:MAGNETON)
  Bounce Off 20   Magnetic Wave 30
Gastly 40hp               pbTCGGiveCard(:GASTLY)
  Nightmare 10
Dark Haunter 50hp         pbTCGGiveCard(:DARK_HAUNTER)
  Call Back   Surround 20
Dark Gengar 70hp          pbTCGGiveCard(:DARK_GENGAR)
  Power: Deep Sleep   Pull In 30
Onix 60hp                 pbTCGGiveCard(:ONIX_NEO)
  Screech   Rage 10
Voltorb 50hp              pbTCGGiveCard(:VOLTORB_NEO)
  Rollout 10   Thundershock 20
Electrode 70hp            pbTCGGiveCard(:ELECTRODE)
  Power: Super Dynamo   Swift 30
Hitmonlee 60hp            pbTCGGiveCard(:HITMONLEE_NEO)
  One-Two Kick 20   Heel Drop 60
Hitmonchan 60hp           pbTCGGiveCard(:HITMONCHAN_NEO)
  Dodge   Supersonic Jab 40
Rhyhorn 60hp              pbTCGGiveCard(:RHYHORN_NEO)
  Horn Attack 10   Retaliate 10
Rhydon 90hp               pbTCGGiveCard(:RHYDON_NEO)
  Stomp 30   Giant Tail 100
Chansey 100hp             pbTCGGiveCard(:CHANSEY_NEO)
  Rollout 10   Double-edge 40
Horsea 40hp               pbTCGGiveCard(:HORSEA_NEO)
  Bubble 10
Seadra 70hp               pbTCGGiveCard(:SEADRA_NEO)
  Wave Splash 20   Water Bullet 30
Scyther 60hp              pbTCGGiveCard(:SCYTHER_NEO)
  Agility 10   Sharp Sickle 40
Jynx 60hp                 pbTCGGiveCard(:JYNX_NEO)
  Meditate 10   Confuse Ray 20
Electabuzz 70hp           pbTCGGiveCard(:ELECTABUZZ)
  Punch 20   Swift 30
Magmar 70hp               pbTCGGiveCard(:MAGMAR_NEO)
  Tail Slap 20   Magma Punch 40
Shining Magikarp 30hp     pbTCGGiveCard(:SHINING_MAGIKARP)
  Gold Scale   Dragon Bond
Shining Gyarados 100hp    pbTCGGiveCard(:SHINING_GYARADOS)
  Outrage 30   Devastate 50
Eevee 50hp                pbTCGGiveCard(:EEVEE_NEO)
  Power: Energy Evolution   Smash Kick 10
Light Vaporeon 80hp       pbTCGGiveCard(:LIGHT_VAPOREON)
  Wash Away   Hypnoshower 30
Light Jolteon 70hp        pbTCGGiveCard(:LIGHT_JOLTEON)
  Pulse Guard   Thunder Needle 20
Flareon 70hp              pbTCGGiveCard(:FLAREON_NEO)
  Quick Attack 10   Flamethrower 60
Porygon 50hp              pbTCGGiveCard(:PORYGON_NEO)
  Sharpen 20
Omanyte 60hp              pbTCGGiveCard(:OMANYTE_NEO)
  Water of Evolution   Drag Off 20
Dark Omastar 70hp         pbTCGGiveCard(:DARK_OMASTAR)
  Prehistoric Water   Dark Tentacle 30
Kabuto 50hp               pbTCGGiveCard(:KABUTO_NEO)
  Power: Thick Shell   Scratch 30
Kabutops 90hp             pbTCGGiveCard(:KABUTOPS_NEO)
  Slash 20   Hydrocutter 40
Shining Kabutops 80hp     pbTCGGiveCard(:SHINING_KABUTOPS)
  Lightning Cut 30   Water Slash 50
Aerodactyl 60hp           pbTCGGiveCard(:AERODACTYL_NEO)
  Power: Prehistoric Memory   Fly 30
Snorlax 80hp              pbTCGGiveCard(:SNORLAX_NEO)
  Power: Lolling About   Continuous Tumble 30
Articuno 80hp             pbTCGGiveCard(:ARTICUNO)
  Power: Water Immunity   Freeze Solid 10   Ice Cyclone 50
Zapdos 80hp               pbTCGGiveCard(:ZAPDOS)
  Power: Anti-Lightning   Plasma 10   Lightning Storm 60
Moltres 80hp              pbTCGGiveCard(:MOLTRES_NEO)
  Power: Fire Immunity   Collect Fire 10   Burning Tail 60
Dratini 40hp              pbTCGGiveCard(:DRATINI_NEO)
  Dragon Smash 40
Light Dragonair 80hp      pbTCGGiveCard(:LIGHT_DRAGONAIR)
  Healing Light   Protective Wave 20
Dragonite 100hp           pbTCGGiveCard(:DRAGONITE)
  Power: Tailwind   Dragon Tail 40
Mewtwo 70hp               pbTCGGiveCard(:MEWTWO)
  Hypnosis   Psychic 20
Shining Mewtwo 70hp       pbTCGGiveCard(:SHINING_MEWTWO)
  Reflect Shield   Psyburst 40
Mew 50hp                  pbTCGGiveCard(:MEW)
  Super Psywave
Shining Mew 50hp          pbTCGGiveCard(:SHINING_MEW)
  Flash Search   Mystic Fire 20
Chikorita 60hp            pbTCGGiveCard(:CHIKORITA_LV8)
  Tackle 10   Razor Leaf 20
Chikorita 70hp            pbTCGGiveCard(:CHIKORITA_LV13)
  Mini Drain 10
Bayleef 70hp              pbTCGGiveCard(:BAYLEEF_LV22)
  Poisonpowder 20   Pollen Shield 30
Bayleef 70hp              pbTCGGiveCard(:BAYLEEF_LV28)
  Soothing Scent 10   Razor Leaf 50
Meganium 100hp            pbTCGGiveCard(:MEGANIUM_LV40)
  Power: Wild Growth   Soothing Scent 40
Meganium 100hp            pbTCGGiveCard(:MEGANIUM_LV46)
  Power: Herbal Scent   Body Slam 40
Cyndaquil 40hp            pbTCGGiveCard(:CYNDAQUIL_LV9)
  Leer   Swift 20
Cyndaquil 50hp            pbTCGGiveCard(:CYNDAQUIL_LV14)
  Tackle 10   Ember 30
Quilava 60hp              pbTCGGiveCard(:QUILAVA)
  Ember 30   Fire Wind 20
Dark Quilava 60hp         pbTCGGiveCard(:DARK_QUILAVA)
  Incinerate   Rushing Magma 20
Typhlosion 100hp          pbTCGGiveCard(:TYPHLOSION)
  Power: Fire Boost   Flame Wheel 80
Dark Typhlosion 80hp      pbTCGGiveCard(:DARK_TYPHLOSION)
  Claw Swipe 20   Rushing Flames 40
Totodile 40hp             pbTCGGiveCard(:TOTODILE_LV6)
  Bite 10   Rage 10
Totodile 50hp             pbTCGGiveCard(:TOTODILE_LV11)
  Water Gun 10
Croconaw 80hp             pbTCGGiveCard(:CROCONAW_LV26)
  Tackle 20   Take Down 40
Croconaw 70hp             pbTCGGiveCard(:CROCONAW_LV20)
  Screech   Jaw Clamp 30
Feraligatr 100hp          pbTCGGiveCard(:FERALIGATR_LV42)
  Power: Berserk   Chomp 50
Feraligatr 120hp          pbTCGGiveCard(:FERALIGATR_LV50)
  Power: Major Tsunami   Rending Jaws 70
Sentret 50hp              pbTCGGiveCard(:SENTRET)
  Scout   Tackle 20
Furret 60hp               pbTCGGiveCard(:FURRET)
  Quick Attack 20   Slam 30
Hoothoot 50hp             pbTCGGiveCard(:HOOTHOOT)
  Hypnosis   Peck 20
Noctowl 60hp              pbTCGGiveCard(:NOCTOWL)
  Power: Glaring Gaze   Wing Attack 30
Shining Noctowl 60hp      pbTCGGiveCard(:SHINING_NOCTOWL)
  Flashing Eyes 30
Ledyba 40hp               pbTCGGiveCard(:LEDYBA)
  Supersonic   Comet Punch 10
Ledian 60hp               pbTCGGiveCard(:LEDIAN)
  Baton Pass 30
Spinarak 40hp             pbTCGGiveCard(:SPINARAK)
  Scary Face   String Shot 10
Ariados 60hp              pbTCGGiveCard(:ARIADOS)
  Spider Web   Poison Bite 20
Crobat 90hp               pbTCGGiveCard(:CROBAT_LV38)
  Triggered Poison 20   Cross Attack 20
Crobat 80hp               pbTCGGiveCard(:CROBAT_LV44)
  Power: Crystal Type   Poison Flame 20   Squared Attack 20
Chinchou 50hp             pbTCGGiveCard(:CHINCHOU_LV7)
  Positive Ion 10   Negative Ion 10
Chinchou 50hp             pbTCGGiveCard(:CHINCHOU_LV12)
  Float   Headbutt 20
Lanturn 80hp              pbTCGGiveCard(:LANTURN_LV35)
  Lightning Ball 20   Conduction 30
Lanturn 70hp              pbTCGGiveCard(:LANTURN_LV25)
  Power: Hydroelectric Power   Floodlight 20
Pichu 30hp                pbTCGGiveCard(:PICHU)
  Zzzap
Cleffa 30hp               pbTCGGiveCard(:CLEFFA)
  Eeeeeeek
Igglybuff 30hp            pbTCGGiveCard(:IGGLYBUFF)
  Power: Gaze
Togepi 40hp               pbTCGGiveCard(:TOGEPI_LV12)
  Minor Errand-Running   Pound 10
Togepi 40hp               pbTCGGiveCard(:TOGEPI_LV7)
  Charm   Spike Ball Tackle 20
Light Togetic 60hp        pbTCGGiveCard(:LIGHT_TOGETIC)
  Power: Gift   Sweet Kiss 30
Togetic 60hp              pbTCGGiveCard(:TOGETIC)
  Super Metronome   Fly 30
Natu 30hp                 pbTCGGiveCard(:NATU)
  Peck 10   Telekinesis
Xatu 80hp                 pbTCGGiveCard(:XATU)
  Prophecy   Confuse Ray 30
Mareep 50hp               pbTCGGiveCard(:MAREEP_LV11)
  Thunder Jolt 30
Mareep 40hp               pbTCGGiveCard(:MAREEP_LV6)
  Static Electricity   Thundershock 20
Dark Flaaffy 60hp         pbTCGGiveCard(:DARK_FLAAFFY)
  High Voltage 10   Stun Wave 30
Flaaffy 60hp              pbTCGGiveCard(:FLAAFFY)
  Discharge 30   Electric Current 20
Ampharos 80hp             pbTCGGiveCard(:AMPHAROS)
  Gigaspark 40
Dark Ampharos 70hp        pbTCGGiveCard(:DARK_AMPHAROS)
  Power: Conductivity   Shock Bolt 50
Bellossom 70hp            pbTCGGiveCard(:BELLOSSOM)
  Sweet Nectar   Flower Dance 30
Marill 40hp               pbTCGGiveCard(:MARILL_LV12)
  Bubble 10   Tail Slap 20
Marill 40hp               pbTCGGiveCard(:MARILL_LV7)
  Defense Curl   Bubble Bomb 30
Azumarill 70hp            pbTCGGiveCard(:AZUMARILL)
  Tackle 20   Bubble Shower 30
Light Azumarill 80hp      pbTCGGiveCard(:LIGHT_AZUMARILL)
  Bubble 10   Bubble Jump 30
Sudowoodo 60hp            pbTCGGiveCard(:SUDOWOODO)
  Flail 10   Rock Throw 30
Politoed 110hp            pbTCGGiveCard(:POLITOED)
  Frog Hop 30   Energy Splash 70
Hoppip 30hp               pbTCGGiveCard(:HOPPIP)
  Rolling Tackle 20
Skiploom 60hp             pbTCGGiveCard(:SKIPLOOM)
  Poisonpowder 10   Stun Spore 10
Jumpluff 70hp             pbTCGGiveCard(:JUMPLUFF)
  Sleep Powder 20   Leech Seed 20
Aipom 40hp                pbTCGGiveCard(:AIPOM)
  Grab   Tail Punch 20
Sunkern 40hp              pbTCGGiveCard(:SUNKERN)
  Growth   Mega Drain 30
Sunflora 70hp             pbTCGGiveCard(:SUNFLORA)
  Petal Dance 30
Yanma 60hp                pbTCGGiveCard(:YANMA)
  Shockwave   Swift 30
Wooper 50hp               pbTCGGiveCard(:WOOPER)
  Slime   Tail Slap 20
Quagsire 70hp             pbTCGGiveCard(:QUAGSIRE)
  Surf 30   Earthquake 60
Dark Espeon 60hp          pbTCGGiveCard(:DARK_ESPEON)
  Gouge 10   Psysplash
Espeon 80hp               pbTCGGiveCard(:ESPEON)
  Bite 20   Psychic 30
Umbreon 80hp              pbTCGGiveCard(:UMBREON)
  Bite 20   Feint Attack 30
Murkrow 40hp              pbTCGGiveCard(:MURKROW)
  Call for Family   Flock Attack 10
Slowking 80hp             pbTCGGiveCard(:SLOWKING)
  Power: Mind Games   Mind Blast 20
Misdreavus 50hp           pbTCGGiveCard(:MISDREAVUS)
  Night Eyes   Perish Song
Unown [A] 40hp            pbTCGGiveCard(:UNOWN_A)
  Power: [Anger]   Hidden Power 10
Unown [J] 40hp            pbTCGGiveCard(:UNOWN_J)
  Power: [Join]   Hidden Power 10
Wobbuffet 90hp            pbTCGGiveCard(:WOBBUFFET)
  Counter
Girafarig 60hp            pbTCGGiveCard(:GIRAFARIG)
  Agility 10   Psybeam 20
Pineco 40hp               pbTCGGiveCard(:PINECO)
  Burst 40
Forretress 70hp           pbTCGGiveCard(:FORRETRESS)
  Power: Exoskeleton   Shell Rupture   Double Spin 40
Dunsparce 30hp            pbTCGGiveCard(:DUNSPARCE)
  Glare 10
Gligar 50hp               pbTCGGiveCard(:GLIGAR)
  Stun Poison 10
Shining Steelix 90hp      pbTCGGiveCard(:SHINING_STEELIX)
  Crushing Earth 80
Steelix 110hp             pbTCGGiveCard(:STEELIX)
  Tackle 20   Tail Crush 30
Snubbull 50hp             pbTCGGiveCard(:SNUBBULL)
  Roar   Lick 10
Granbull 70hp             pbTCGGiveCard(:GRANBULL)
  Tackle 20   Raging Charge 10
Qwilfish 60hp             pbTCGGiveCard(:QWILFISH)
  Stun Needle 20
Scizor 100hp              pbTCGGiveCard(:SCIZOR)
  Power: Honeycomb Defender   Accelerate 30   Pound Down 40
Shuckle 50hp              pbTCGGiveCard(:SHUCKLE)
  Withdraw   Wrap 20
Heracross 60hp            pbTCGGiveCard(:HERACROSS)
  Power: Final Blow   Megahorn 60
Sneasel 60hp              pbTCGGiveCard(:SNEASEL)
  Fury Swipes 10   Beat Up 20
Teddiursa 40hp            pbTCGGiveCard(:TEDDIURSA)
  Surprise Attack 20   Rage 10
Ursaring 80hp             pbTCGGiveCard(:URSARING)
  Headpress 20   Double Lariat 40
Slugma 50hp               pbTCGGiveCard(:SLUGMA)
  Combustion 30
Magcargo 80hp             pbTCGGiveCard(:MAGCARGO)
  Power: Streaming Mantle   Crushing Lava 40
Swinub 40hp               pbTCGGiveCard(:SWINUB)
  Tackle 10   Take Down 30
Piloswine 80hp            pbTCGGiveCard(:PILOSWINE)
  Freeze 10   Blizzard 30
Corsola 60hp              pbTCGGiveCard(:CORSOLA)
  Tackle 20   Spike Cannon 20
Remoraid 40hp             pbTCGGiveCard(:REMORAID)
  Sharpshooting
Octillery 80hp            pbTCGGiveCard(:OCTILLERY)
  Power: Suction Cups   Smokescreen 40
Delibird 60hp             pbTCGGiveCard(:DELIBIRD)
  Present
Mantine 60hp              pbTCGGiveCard(:MANTINE)
  Undulate 20
Skarmory 60hp             pbTCGGiveCard(:SKARMORY)
  Claw 20   Steel Wing 30
Houndour 50hp             pbTCGGiveCard(:HOUNDOUR_LV8)
  Smog 10   Collect Fire 20
Houndour 50hp             pbTCGGiveCard(:HOUNDOUR_LV13)
  Singe   Flare 20
Dark Houndoom 60hp        pbTCGGiveCard(:DARK_HOUNDOOM)
  Eerie Howl   Dark Fire 30
Kingdra 110hp             pbTCGGiveCard(:KINGDRA_LV48)
  Power: Crystal Type   Aquabomb 40   Dual Burn 60
Kingdra 90hp              pbTCGGiveCard(:KINGDRA_LV40)
  Agility 30   Dragon Tornado 50
Phanpy 40hp               pbTCGGiveCard(:PHANPY_LV13)
  Flail 10   Rollout 20
Phanpy 40hp               pbTCGGiveCard(:PHANPY_LV8)
  Tackle 10   Endure
Donphan 70hp              pbTCGGiveCard(:DONPHAN)
  Flail 10   Rapid Spin 50
Dark Donphan 60hp         pbTCGGiveCard(:DARK_DONPHAN)
  Tusk Toss   Giant Tusk 50
Dark Porygon2 60hp        pbTCGGiveCard(:DARK_PORYGON2)
  Power: Spatial Distortion   Curve Attack 20
Stantler 60hp             pbTCGGiveCard(:STANTLER)
  Stomp 20   Mystifying Horns 20
Smeargle 50hp             pbTCGGiveCard(:SMEARGLE)
  Sketch
Tyrogue 30hp              pbTCGGiveCard(:TYROGUE)
  Smash Punch 30
Hitmontop 60hp            pbTCGGiveCard(:HITMONTOP)
  Detect   Triple Kick 30
Smoochum 30hp             pbTCGGiveCard(:SMOOCHUM)
  Psykiss
Elekid 30hp               pbTCGGiveCard(:ELEKID)
  Power: Playful Punch
Magby 30hp                pbTCGGiveCard(:MAGBY)
  Sputter 10
Miltank 70hp              pbTCGGiveCard(:MILTANK)
  Milk Drink   Body Slam 20
Blissey 120hp             pbTCGGiveCard(:BLISSEY)
  Power: Softboiled   Body Slam 30
Raikou 80hp               pbTCGGiveCard(:RAIKOU)
  Power: Lightning Burst   Lightning Tackle 50
Entei 80hp                pbTCGGiveCard(:ENTEI_LV40)
  Power: Bolt   Protective Flame 50
Entei 80hp                pbTCGGiveCard(:ENTEI_LV30)
  Power: Howl   Searing Flames 60
Suicune 70hp              pbTCGGiveCard(:SUICUNE)
  Power: Crystal Body   Aurora Wave 30
Larvitar 40hp             pbTCGGiveCard(:LARVITAR)
  Leer   Rock Throw 20
Pupitar 70hp              pbTCGGiveCard(:PUPITAR)
  Skull Bash 20   Dust Devil
Shining Tyranitar 80hp    pbTCGGiveCard(:SHINING_TYRANITAR)
  Mountain Crush 30   Destructive Fire 50
Tyranitar 100hp           pbTCGGiveCard(:TYRANITAR)
  Slam 30   Trample 50
Lugia 80hp                pbTCGGiveCard(:LUGIA_LV35)
  Power: Crystal Type   Psychic 10   Steam Blast 50
Lugia 90hp                pbTCGGiveCard(:LUGIA_LV45)
  Elemental Blast 90
Shadow Lugia 300hp        pbTCGGiveCard(:SHADOW_LUGIA)
  Shadow Storm 100
Ho-Oh 90hp                pbTCGGiveCard(:HO_OH)
  Stoke   Dive Bomb 90
Ho-Oh 80hp                pbTCGGiveCard(:HO_OH_LV45)
  Power: Crystal Type   Holy Flame 20   Scalding Steam 40
Shining Celebi 50hp       pbTCGGiveCard(:SHINING_CELEBI)
  Healing Water   Miracle Leaf 10
Celebi 50hp               pbTCGGiveCard(:CELEBI)
  Power: Time Travel   Psychic Damage
Celebi 60hp               pbTCGGiveCard(:CELEBI_LV30)
  Power: Crystal Type   Empathic Healing   Mind Bend 20

Trainers / Energy:
Master Ball               pbTCGGiveCard(:MASTER_BALL)
New Pokédex               pbTCGGiveCard(:NEW_POKEDEX)
Potion                    pbTCGGiveCard(:POTION_NEO)
Team Rocket's Evil Deeds  pbTCGGiveCard(:TEAM_ROCKET_S_EVIL_DEEDS)
Energy Ark                pbTCGGiveCard(:ENERGY_ARK)
Energy Removal 2          pbTCGGiveCard(:ENERGY_REMOVAL_2)
Fossil Egg                pbTCGGiveCard(:FOSSIL_EGG)
Professor Elm             pbTCGGiveCard(:PROFESSOR_ELM)
Ruin Wall                 pbTCGGiveCard(:RUIN_WALL)
Super Scoop Up            pbTCGGiveCard(:SUPER_SCOOP_UP)
Mail from Bill            pbTCGGiveCard(:MAIL_FROM_BILL)
PokéGear                  pbTCGGiveCard(:POKEGEAR)
Hyper Potion              pbTCGGiveCard(:HYPER_POTION)
Pokémon Nurse             pbTCGGiveCard(:POKEMON_NURSE)
```

### Gen 3 (Advanced) cards (133)

```
Treecko 40hp              pbTCGGiveCard(:TREECKO)
  Poison Breath
Grovyle 80hp              pbTCGGiveCard(:GROVYLE)
  Power: Natural Cure   Slash 20
Sceptile 100hp            pbTCGGiveCard(:SCEPTILE)
  Power: Green Essence   Razor Leaf 30   Swift 60
Torchic 40hp              pbTCGGiveCard(:TORCHIC)
  Peck 10   Fireworks 30
Combusken 80hp            pbTCGGiveCard(:COMBUSKEN)
  Searing Flame 10   Firebreathing 30
Blaziken 100hp            pbTCGGiveCard(:BLAZIKEN)
  Power: Firestarter   Fire Stream 50
Mudkip 50hp               pbTCGGiveCard(:MUDKIP)
  Pound 10   Fury Swipes 10
Marshtomp 70hp            pbTCGGiveCard(:MARSHTOMP)
  Super Hypno Wave 10   Surf 50
Swampert 110hp            pbTCGGiveCard(:SWAMPERT)
  Power: Water Call   Hypno Splash 50
Poochyena 50hp            pbTCGGiveCard(:POOCHYENA)
  Knock Off   Rear Kick 20
Mightyena 70hp            pbTCGGiveCard(:MIGHTYENA)
  Seek Out   Pull Away 30
Zigzagoon 40hp            pbTCGGiveCard(:ZIGZAGOON)
  Gnaw 10   Body Slam 10
Linoone 70hp              pbTCGGiveCard(:LINOONE)
  Sniff Out   Fury Swipes 20
Wurmple 50hp              pbTCGGiveCard(:WURMPLE)
  Signs of Evolution   Poison Barb
Silcoon 80hp              pbTCGGiveCard(:SILCOON)
  Ram 10   Advanced Armor
Beautifly 80hp            pbTCGGiveCard(:BEAUTIFLY)
  Power: Withering Dust   Stun Spore 20   Parallel Gain 50
Cascoon 70hp              pbTCGGiveCard(:CASCOON)
  Power: Hard Cocoon   Poison Thread
Dustox 90hp               pbTCGGiveCard(:DUSTOX)
  Power: Protective Dust   Toxic   Gust 50
Lotad 50hp                pbTCGGiveCard(:LOTAD)
  Rain Splash 10   Aqua Wave 20
Lombre 70hp               pbTCGGiveCard(:LOMBRE)
  Power: Natural Cure   Blot 20
Ludicolo 100hp            pbTCGGiveCard(:LUDICOLO)
  Power: Swing Dance   Circular Steps 10
Seedot 40hp               pbTCGGiveCard(:SEEDOT)
  Tackle 10
Nuzleaf 70hp              pbTCGGiveCard(:NUZLEAF)
  Pound 20   Plunder 30
Shiftry 120hp             pbTCGGiveCard(:SHIFTRY)
  Power: Fan Away   Light Touch Throw 80
Taillow 40hp              pbTCGGiveCard(:TAILLOW)
  Peck 10   Wing Attack 20
Swellow 70hp              pbTCGGiveCard(:SWELLOW)
  Mid-air Crush   Nosedive 40
Wingull 40hp              pbTCGGiveCard(:WINGULL)
  Surprise Attack 20
Pelipper 70hp             pbTCGGiveCard(:PELIPPER)
  Water Gun 30
Ralts 50hp                pbTCGGiveCard(:RALTS)
  Pound 10   Link Blast 40
Kirlia 80hp               pbTCGGiveCard(:KIRLIA)
  Telekinesis
Gardevoir 100hp           pbTCGGiveCard(:GARDEVOIR)
  Power: Psy Shadow   Energy Burst 10
Surskit 40hp              pbTCGGiveCard(:SURSKIT)
  Super Hypno Wave 10
Masquerain 70hp           pbTCGGiveCard(:MASQUERAIN)
  Sweet Scent   Quick Attack 30
Shroomish 40hp            pbTCGGiveCard(:SHROOMISH)
  Growth Spurt   Poisonpowder 10
Breloom 80hp              pbTCGGiveCard(:BRELOOM)
  Power Blow 10   Body Slam 40
Slakoth 40hp              pbTCGGiveCard(:SLAKOTH)
  Lazy Punch 10
Vigoroth 70hp             pbTCGGiveCard(:VIGOROTH)
  Focus Energy   Slash 40
Slaking 120hp             pbTCGGiveCard(:SLAKING)
  Power: Lazy   Critical Move 100
Nincada 50hp              pbTCGGiveCard(:NINCADA)
  Leech Life 10
Ninjask 70hp              pbTCGGiveCard(:NINJASK)
  Supersonic 10   Sonic Wing 30
Shedinja 50hp             pbTCGGiveCard(:SHEDINJA)
  Power: Empty Shell   Extra Curse
Whismur 50hp              pbTCGGiveCard(:WHISMUR)
  Supersonic   Pound 10
Loudred 70hp              pbTCGGiveCard(:LOUDRED)
  Surprise 20   Bass Control
Exploud 120hp             pbTCGGiveCard(:EXPLOUD)
  Body Slam 30   Mega Throw 60
Makuhita 50hp             pbTCGGiveCard(:MAKUHITA)
  Thrust 10   Rising Lunge 20
Hariyama 90hp             pbTCGGiveCard(:HARIYAMA)
  Super Slap Push 20   Mega Throw 40
Nosepass 70hp             pbTCGGiveCard(:NOSEPASS)
  Collect   Wide Laser
Skitty 50hp               pbTCGGiveCard(:SKITTY)
  Tail Whip   Tackle 20
Delcatty 70hp             pbTCGGiveCard(:DELCATTY)
  Power: Energy Draw   Max Energy Source 10
Sableye 60hp              pbTCGGiveCard(:SABLEYE)
  Power: Night Vision   Limitation
Mawile 60hp               pbTCGGiveCard(:MAWILE)
  Call for Family   Pull Away 20
Aron 40hp                 pbTCGGiveCard(:ARON)
  Teary Eyes   Ram 20
Lairon 80hp               pbTCGGiveCard(:LAIRON)
  Tackle 20   Iron Head 30
Aggron 110hp              pbTCGGiveCard(:AGGRON)
  Power: Terraforming   Mix-Up 70
Meditite 50hp             pbTCGGiveCard(:MEDITITE)
  Kick 10   Pure Power
Medicham 80hp             pbTCGGiveCard(:MEDICHAM)
  Steady Punch 20   Power Heal 10
Electrike 50hp            pbTCGGiveCard(:ELECTRIKE)
  High Voltage   Gnaw 20
Manectric 70hp            pbTCGGiveCard(:MANECTRIC)
  Thundershock 20   Gigashock 40
Plusle 50hp               pbTCGGiveCard(:PLUSLE)
  Cheer On   Extra Circuit
Minun 50hp                pbTCGGiveCard(:MINUN)
  Cheer On   Special Circuit
Volbeat 60hp              pbTCGGiveCard(:VOLBEAT)
  Confuse Ray   Double-edge 30
Illumise 60hp             pbTCGGiveCard(:ILLUMISE)
  Collect   Tackle 20
Roselia 60hp              pbTCGGiveCard(:ROSELIA)
  Power: Thick Skin   Speed Growth   Sleep Powder 10
Gulpin 50hp               pbTCGGiveCard(:GULPIN)
  Amnesia   Sludge Toss 40
Swalot 80hp               pbTCGGiveCard(:SWALOT)
  Blot 20   Poison Breath 40
Carvanha 50hp             pbTCGGiveCard(:CARVANHA)
  Sharp Fin 10   Rage 10
Sharpedo 70hp             pbTCGGiveCard(:SHARPEDO)
  Rage 10   Aqua Slash 60
Wailmer 80hp              pbTCGGiveCard(:WAILMER)
  Rollout 20   Super Hypno Wave 30
Wailord 120hp             pbTCGGiveCard(:WAILORD)
  Take Down 50   Surf 70
Numel 50hp                pbTCGGiveCard(:NUMEL)
  Singe   Flare 20
Camerupt 90hp             pbTCGGiveCard(:CAMERUPT)
  Lava Burn 20   Fire Spin 100
Torkoal 80hp              pbTCGGiveCard(:TORKOAL)
  Power Generation   Scorching Smoke
Spoink 50hp               pbTCGGiveCard(:SPOINK)
  Psywave 10   Ram 20
Grumpig 80hp              pbTCGGiveCard(:GRUMPIG)
  Power: Carefree   Hypnoblast 20   Extra Ball 50
Spinda 60hp               pbTCGGiveCard(:SPINDA)
  The Hula-la   Flail 10
Trapinch 50hp             pbTCGGiveCard(:TRAPINCH)
  Pebble Throw   Double Pinchers 20
Vibrava 80hp              pbTCGGiveCard(:VIBRAVA)
  Quick Charge   Dragon Spark
Flygon 100hp              pbTCGGiveCard(:FLYGON)
  Power: Sand Guard   Air Slash 60
Cacnea 50hp               pbTCGGiveCard(:CACNEA)
  Call for Family   Rising Lunge 10
Cacturne 80hp             pbTCGGiveCard(:CACTURNE)
  Dark Bind 10   Poison Barb 40
Swablu 40hp               pbTCGGiveCard(:SWABLU)
  Power: Fluff   Peck 10
Altaria 70hp              pbTCGGiveCard(:ALTARIA)
  Double Wing Attack 20   Dive 50
Zangoose 70hp             pbTCGGiveCard(:ZANGOOSE)
  Extra Claws 10   Quick Attack 20
Seviper 80hp              pbTCGGiveCard(:SEVIPER)
  Deadly Poison 10   Extra Poison 20
Lunatone 60hp             pbTCGGiveCard(:LUNATONE)
  Power: Sol Shade   Moon Guidance   Psyshock 10
Solrock 70hp              pbTCGGiveCard(:SOLROCK)
  Power: Solar Eclipse   Solar Blast 40
Barboach 50hp             pbTCGGiveCard(:BARBOACH)
  Waterfall 10   Flail 10
Whiscash 80hp             pbTCGGiveCard(:WHISCASH)
  Pebble Hurl 20   Earthquake 60
Corphish 50hp             pbTCGGiveCard(:CORPHISH)
  Beat 10   Toxic Grip
Crawdaunt 80hp            pbTCGGiveCard(:CRAWDAUNT)
  Power: Power Pinchers   Guillotine 50
Baltoy 50hp               pbTCGGiveCard(:BALTOY)
  Headbutt 10   Mud Slap 20
Claydol 80hp              pbTCGGiveCard(:CLAYDOL)
  Hyper Beam 20   Ram 50
Lileep 80hp               pbTCGGiveCard(:LILEEP)
  Tender Tentacles 20   Confuse Ray 20
Cradily 100hp             pbTCGGiveCard(:CRADILY)
  Power: Super Suction Cups   Lure Poison   Spiral Drain 50
Anorith 80hp              pbTCGGiveCard(:ANORITH)
  Fast Evolution   Pierce 30
Armaldo 120hp             pbTCGGiveCard(:ARMALDO)
  Rock Blast   Mach Claw 60
Feebas 30hp               pbTCGGiveCard(:FEEBAS)
  Tackle 10   Ascension
Milotic 100hp             pbTCGGiveCard(:MILOTIC)
  Power: Healing Shower   Distorted Wave 80
Castform 60hp             pbTCGGiveCard(:CASTFORM)
  Extra Ball 20
Kecleon 60hp              pbTCGGiveCard(:KECLEON)
  Power: Energy Variation   Double Scratch 20
Shuppet 40hp              pbTCGGiveCard(:SHUPPET)
  Ascension   Tackle 20
Banette 70hp              pbTCGGiveCard(:BANETTE)
  Grudge 20   Bench Manipulation 40
Duskull 50hp              pbTCGGiveCard(:DUSKULL)
  Surprise Attack 30
Dusclops 80hp             pbTCGGiveCard(:DUSCLOPS)
  Dark Mind 20   Mysterious Light 50
Tropius 80hp              pbTCGGiveCard(:TROPIUS)
  Fruition   Gust 20
Chimecho 70hp             pbTCGGiveCard(:CHIMECHO)
  Resonate   Healing Sound
Absol 70hp                pbTCGGiveCard(:ABSOL)
  Quick Attack 10   Feint Attack
Snorunt 50hp              pbTCGGiveCard(:SNORUNT)
  Ice Breath   Tackle 20
Glalie 80hp               pbTCGGiveCard(:GLALIE)
  Powder Snow 20   Double-edge 60
Spheal 40hp               pbTCGGiveCard(:SPHEAL)
  Defense Curl   Aurora Beam 20
Sealeo 70hp               pbTCGGiveCard(:SEALEO)
  Ice Beam 20
Walrein 120hp             pbTCGGiveCard(:WALREIN)
  Power Blow 10   Hydro Reverse 50
Clamperl 40hp             pbTCGGiveCard(:CLAMPERL)
  Power: Exoskeleton   Bubble 20
Huntail 80hp              pbTCGGiveCard(:HUNTAIL)
  Bite 20   Dark Splash 40
Gorebyss 70hp             pbTCGGiveCard(:GOREBYSS)
  Stun Needle 10   Mystic Water 20
Relicanth 70hp            pbTCGGiveCard(:RELICANTH)
  Power: Aqua Lift   Knock Away 20
Luvdisc 60hp              pbTCGGiveCard(:LUVDISC)
  Call for Friend   Strange Scale 20
Bagon 50hp                pbTCGGiveCard(:BAGON)
  Singe   Doubleslap 10
Shelgon 70hp              pbTCGGiveCard(:SHELGON)
  Power: Energy Guard   Rollout 20
Salamence 120hp           pbTCGGiveCard(:SALAMENCE)
  Power: Dragon Wind   Dragon Claw 60
Beldum 50hp               pbTCGGiveCard(:BELDUM)
  Power: Levitate   Tackle 10
Metang 80hp               pbTCGGiveCard(:METANG)
  Power: Clear Body   Extra Comet Punch 30
Metagross 100hp           pbTCGGiveCard(:METAGROSS)
  Power: Super Connectivity   Link Blast 70
Regirock 80hp             pbTCGGiveCard(:REGIROCK)
  Power: Clear Body   Rock Slide 40
Regice 80hp               pbTCGGiveCard(:REGICE)
  Power: Clear Body   Icy Wind 40
Registeel 80hp            pbTCGGiveCard(:REGISTEEL)
  Power: Clear Body   Hyper Beam 30
Latias 80hp               pbTCGGiveCard(:LATIAS)
  Miraculous Light 10   Mist Ball 80
Latios 90hp               pbTCGGiveCard(:LATIOS)
  Energy Draw 10   Luster Purge 120
Kyogre 80hp               pbTCGGiveCard(:KYOGRE)
  Scary Face   Hydro Pump 40
Groudon 100hp             pbTCGGiveCard(:GROUDON)
  Linear Attack   Pulverize 50
Rayquaza 80hp             pbTCGGiveCard(:RAYQUAZA)
  Fly 10   Dragon Claw 30
Jirachi 50hp              pbTCGGiveCard(:JIRACHI)
  The Third Eye   Psywave 10
Deoxys 70hp               pbTCGGiveCard(:DEOXYS)
  Link Blast 40
```
