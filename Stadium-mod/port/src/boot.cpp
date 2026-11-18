// Quick boot: when the game is started from Echoes of Johto it should land on the
// Menu Select screen (Battle Now! / POKeMON Stadium / Gallery / Options) at once.
//
// The game's own flow (29BA0.c Game_Thread):
//   STATE_N64_LOGO_INTRO: fragment35 = N64 logo + setup (save data, Game Pak scan,
//                         sound/options) -> kept, it lasts ~1 s and the rest needs it
//                         then func_800290E4(0x12) = the intro movie -> skipped
//   STATE_TITLE_SCREEN:   fragment36, waits for Start -> Start is pressed for the player
//   STATE_MENU_SELECT:    where the player gets control.
// Leaving through the title keeps the game's own bookkeeping (memory pool states,
// "came from the title" flag of the menu) exactly as on a normal start.
//
// Off with --intro on the command line.
#include <cstdint>
#include <atomic>
#include "stadium.h"

namespace {
    std::atomic<bool> quick_boot{ true };
    std::atomic<bool> title_passed{ false };
    constexpr uint32_t gCurrentGameState = 0x80075668;
    constexpr int32_t STATE_TITLE_SCREEN = 2;
}

extern uint8_t* g_rdram;   // crash.cpp, set at init

void stadium::set_quick_boot(bool on) { quick_boot = on; }

// us.toml hook at func_800290E4 (play a demo/movie by id): 0x12 is the boot intro.
extern "C" int stadium_skip_demo(uint32_t id) {
    return quick_boot && !title_passed && id == 0x12;
}

// us.toml hook at fragment57 func_82D06D0C (Menu Select, arg1 = came from the title):
// coming from the title it first shows the "Game Pak Check" screen and waits for A.
// On the quick boot's first arrival that screen is left out (arg1 -> 0).
extern "C" int stadium_skip_gbcheck(void) {
    static std::atomic<bool> done{ false };
    if (!quick_boot || done.exchange(true)) return 0;
    return 1;
}

// us.toml hook at Game_DoCopyProtection (called with each new game state).
// GB Tower (0x26) plays the Game Boy cart's game itself; the cart the Echoes of Johto
// launcher plugs in only carries the player's Pokémon (not a playable save), so the
// tower is closed: choosing it goes back to Area Select (0x10).
extern "C" int32_t stadium_filter_state(int32_t state) {
    constexpr int32_t STATE_GB_TOWER = 0x26, STATE_AREA_SELECT = 0x10;
    if (state == STATE_GB_TOWER) return STATE_AREA_SELECT;
    return state;
}

// Called each input poll: true while Start should be held for player 1.
bool stadium::quick_boot_press_start() {
    if (!quick_boot || title_passed || !g_rdram) return false;
    int32_t state = *reinterpret_cast<const int32_t*>(g_rdram + (gCurrentGameState - 0x80000000u));
    static int polls = 0;
    static bool seen_title = false;
    if (state == STATE_TITLE_SCREEN) {
        seen_title = true;
        // the title ignores Start for its first 30 frames and acts on a fresh press:
        // pulse it (4 polls down, 4 up) until the game moves on
        return (polls++ / 4) % 2 == 0;
    }
    if (seen_title) title_passed = true;   // left the title: hand control to the player
    return false;
}
