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
