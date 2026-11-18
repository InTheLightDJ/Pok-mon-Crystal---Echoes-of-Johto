// Kids Club PVP: "Who's the Best?" raced against other players (Echoes of Johto online).
//
// Everyone plays on their own machine: 1P plus three COMs. The COM slots stand for the
// other players (their real win counts and names); COMs' own wins don't count. The
// Echoes of Johto launcher (Plugins/Pokemon Stadium/004_PVP.rb) relays to the server
// (ServerStuff/handlers/stadium_pvp.js), which keeps everyone in step:
//   lobby   choosing the PVP box joins/opens a party (announced); on "Who wants to play?"
//           the other players' pills light up as they join. Only the host (first player)
//           can press Ready; that closes joining and moves everyone else's game on (their
//           COM level / number-of-wins screens are passed for them).
//   round 1 the roulette lands on the party's seeded game on every machine.
//   later   nobody picks until all have finished the round; then the player with the
//           fewest wins picks (the server says who) and everyone's cursor follows.
//   always  minigame instruction screens are skipped (Start pressed for you).
//
// Link with the launcher: two text files in STADIUM_PVP_DIR.
//   pvp_out.txt (appended): enter / start / level L / done ROUND WINS GAME / pick ROUND GAME / leave
//   pvp_in.txt (rewritten): phase, host, seed, target, level, round, selector, pick, slot K W NAME
//
// Game side (fragment2 = Kids Club data, fragment39 = its menus; relocated at run time,
// found with stadium_fragment_addr):
//   D_8780FA30[4] 0 = human, 1 = COM   D_8780FA38 COM level   D_8780FA3A wins to win
//   D_8780FA40[4] wins                 D_8780FA48 who picks the next game (-1 = roulette)
//   D_82508B00[4] menu pads (u16 +4 = pressed)   D_8250A288 menu cursors (+2 lobby row,
//   +6 game)   D_8250A292 game the COM picker heads for (-1 none)
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <string>
#include <array>
#include "recomp.h"
#include "stadium.h"

extern "C" uint32_t stadium_fragment_addr(uint32_t link_addr);
extern "C" void func_8001F1E8(uint8_t* rdram, recomp_context* ctx);   // print text (x, y, fmt, ...)
extern "C" void func_878013D4(uint8_t* rdram, recomp_context* ctx);   // text width (font, str)
extern "C" void func_8001EBE0(uint8_t* rdram, recomp_context* ctx);   // text size, letter spacing

namespace {
    constexpr uint32_t L_HUMAN = 0x8780FA30, L_LEVEL = 0x8780FA38, L_TARGET = 0x8780FA3A,
                       L_WINS = 0x8780FA40, L_PICKER = 0x8780FA48;
    // u8[4] per slot, set by the win counter (func_87802F00): won this round / its trophy
    // animation (1 = still to show; the results screen waits for every 1 to finish)
    constexpr uint32_t L_WON = 0x8780FC50, L_TROPHY = 0x8780FDFC;
    constexpr uint32_t L_PADS = 0x82508B00, L_CURSORS = 0x8250A288, L_AI_PICK = 0x8250A292;
    constexpr uint16_t BTN_A = 0x8000;

    bool active = false;          // a PVP match is on (the PVP box was chosen)
    bool test_mode = getenv("STADIUM_PVP") != nullptr;
    int last_done = 0;            // rounds reported finished
    int playing = 0;              // round being played (set when its game is chosen)
    int picked_round = 0;         // my pick reported for this round
    int playing_game = -1;        // that round's game (0-8, the grid order)
    int wait_round = 0;           // round whose picker we're waiting for, since when
    std::chrono::steady_clock::time_point wait_since{};
    constexpr auto WAIT_MAX = std::chrono::seconds(20);   // then pick here: never hang
    bool start_sent = false, level_sent = false;
    bool final_pick = false;      // next func_878001E8(9) is the roulette's final pick

    struct Remote { bool present = false; int wins = 0; std::string name; };
    struct State {
        bool have = false;        // the server has answered
        std::string phase;
        bool host = true;
        uint32_t seed = 0;
        int target = 0, level = -1, round = 0, selector = -1, pick = -1;
        std::array<Remote, 4> slots{};
    } st;
    std::chrono::steady_clock::time_point last_read{};

    std::filesystem::path dir() {
        const char* d = getenv("STADIUM_PVP_DIR");
        return d ? std::filesystem::path(d) : std::filesystem::path();
    }

    void send(const std::string& line) {
        auto d = dir();
        if (d.empty()) return;
        std::ofstream f(d / "pvp_out.txt", std::ios::app);
        f << line << "\n";
        fprintf(stderr, "[pvp] -> %s\n", line.c_str());
    }

    void read_in(bool force = false) {
        auto now = std::chrono::steady_clock::now();
        if (!force && now - last_read < std::chrono::milliseconds(200)) return;
        last_read = now;
        auto d = dir();
        if (d.empty()) return;
        std::ifstream f(d / "pvp_in.txt");
        if (!f) return;
        State next;
        next.have = true;
        std::string line;
        while (std::getline(f, line)) {
            char word[64] = {}, name[64] = {};
            unsigned u; int a, b;
            if (sscanf(line.c_str(), "phase %63s", word) == 1) next.phase = word;
            else if (sscanf(line.c_str(), "host %d", &a) == 1) next.host = a != 0;
            else if (sscanf(line.c_str(), "seed %u", &u) == 1) next.seed = u;
            else if (sscanf(line.c_str(), "target %d", &a) == 1) next.target = a;
            else if (sscanf(line.c_str(), "level %d", &a) == 1) next.level = a;
            else if (sscanf(line.c_str(), "round %d", &a) == 1) next.round = a;
            else if (sscanf(line.c_str(), "selector %d", &a) == 1) next.selector = a;
            else if (sscanf(line.c_str(), "pick %d", &a) == 1) next.pick = a;
            else if (sscanf(line.c_str(), "slot %d %d %63[^\n]", &a, &b, name) >= 2 && a >= 1 && a <= 3) {
                next.slots[a].present = true; next.slots[a].wins = b; next.slots[a].name = name;
            }
        }
        if (!next.phase.empty()) st = next;
    }

    uint32_t xorshift(uint32_t& s) { s ^= s << 13; s ^= s >> 17; s ^= s << 5; return s; }

    // round 1's game: from a seeded shuffle of the 9 games
    int seeded_game() {
        uint32_t s = st.seed ^ 0x9E3779B9u;
        if (s == 0) s = 1;
        int order[9];
        for (int i = 0; i < 9; i++) order[i] = i;
        for (int i = 8; i > 0; i--) { int j = int(xorshift(s) % uint32_t(i + 1)); std::swap(order[i], order[j]); }
        return order[0];
    }

    int16_t* H(uint8_t* rdram, uint32_t link) {
        uint32_t a = stadium_fragment_addr(link);
        return a ? reinterpret_cast<int16_t*>(rdram + ((a ^ 2) - 0x80000000u)) : nullptr;
    }
    uint16_t* pad_pressed(uint8_t* rdram, int pad) { return reinterpret_cast<uint16_t*>(H(rdram, L_PADS + 0xC * pad + 4)); }

    bool online() { return st.have; }
    bool waiting_for_host() { return online() && !st.host && st.phase == "lobby"; }
    bool started() { return online() && st.phase != "lobby"; }

    uint8_t* B(uint8_t* rdram, uint32_t link) {
        uint32_t a = stadium_fragment_addr(link);
        return a ? rdram + ((a ^ 3) - 0x80000000u) : nullptr;
    }

    // the other players stand in the COM slots: their wins (and 0 for real COMs). A COM
    // that won here doesn't score, so its "won / show the new trophy" flags go too (else
    // the results screen waits for a trophy that isn't there).
    void write_wins(uint8_t* rdram) {
        if (!online()) return;
        for (int s = 1; s <= 3; s++) {
            if (int16_t* w = H(rdram, L_WINS + 2 * s)) *w = int16_t(st.slots[s].present ? st.slots[s].wins : 0);
            if (uint8_t* won = B(rdram, L_WON + s)) *won = 0;
            if (uint8_t* tr = B(rdram, L_TROPHY + s)) *tr = 0;
        }
        if (st.target > 0) if (int16_t* t = H(rdram, L_TARGET)) *t = int16_t(st.target);
    }

    // in the games, every slot but 1P is played by the COM AI (the others are on their machines)
    void others_are_coms(uint8_t* rdram) {
        if (int16_t* h = H(rdram, L_HUMAN)) *h = 0;
        for (int s = 1; s <= 3; s++) if (int16_t* h = H(rdram, L_HUMAN + 2 * s)) *h = 1;
    }
}

void stadium::pvp_begin() {
    if (active) return;
    active = true;
    last_done = playing = picked_round = 0;
    start_sent = level_sent = false;
    st = State{};
    auto d = dir();
    if (!d.empty() && !test_mode) { std::error_code ec; std::filesystem::remove(d / "pvp_in.txt", ec); }
    send("enter");
}

void stadium::pvp_end() {
    if (!active) return;
    active = false;
    send("leave");
}

bool stadium::pvp_active() { return active; }

// "Who wants to play?" (fragment39 func_825032BC entry, every frame)
void stadium::pvp_lobby(uint8_t* rdram) {
    if (!active) return;
    read_in();
    // pills: 1P is in; the other players light up their slots as they join
    if (int16_t* h = H(rdram, L_HUMAN)) *h = 0;
    for (int s = 1; s <= 3; s++)
        if (int16_t* h = H(rdram, L_HUMAN + 2 * s)) *h = (online() && st.slots[s].present) ? 0 : 1;
    uint16_t* a = pad_pressed(rdram, 0);
    int16_t* row = H(rdram, L_CURSORS + 2);
    if (!a || !row) return;
    if (waiting_for_host()) {
        *a &= ~BTN_A;                          // only the host can start
    } else if (started() && !st.host) {
        *row = 1; *a |= BTN_A;                 // the host started: Ready for me too
    } else if (*row == 1 && (*a & BTN_A) && !start_sent) {
        start_sent = true;                     // I'm the host (or offline): start
        send("start");
    }
}

// COM level / number-of-wins screens (states 4 / 3): passed for the joiners (the host's
// level and the party's target are used); the wins screen for everyone (target is fixed)
void stadium::pvp_setup_screen(uint8_t* rdram, int which) {
    if (!active || !online()) return;
    read_in();
    uint16_t* a = pad_pressed(rdram, 0);
    if (!a) return;
    if (which == 3 || !st.host) *a |= BTN_A;
}

// us.toml: func_87802F00 before 0x87802F20 (a slot won a game) - nothing to do now
extern "C" void stadium_pvp_win(uint8_t* rdram, uint32_t slot_addr, int32_t slot) { (void)rdram; (void)slot_addr; (void)slot; }

// us.toml: func_87802F4C entry ("someone reached the target?", after each game): the
// others' wins (and the party's target) go in, mine goes out with "round finished".
extern "C" void stadium_pvp_sync(uint8_t* rdram) {
    if (!active) return;
    read_in();
    write_wins(rdram);
    if (playing > last_done) {
        int16_t* mine = H(rdram, L_WINS);
        last_done = playing;
        send("done " + std::to_string(playing) + " " + std::to_string(mine ? *mine : 0) + " " + std::to_string(playing_game));
    }
}

// us.toml: fragment39 func_82503F00 entry (a1 = roulette countdown): round 1's roulette
extern "C" void stadium_pvp_roulette(uint8_t* rdram, int32_t t) {
    if (!active && t > 0 && test_mode) stadium::pvp_begin();
    if (!active) return;
    others_are_coms(rdram);
    if (online() && st.host && !level_sent) {
        if (int16_t* lv = H(rdram, L_LEVEL)) { level_sent = true; send("level " + std::to_string(*lv)); }
    } else if (online() && !st.host && st.level >= 0) {
        if (int16_t* lv = H(rdram, L_LEVEL)) *lv = int16_t(st.level);
    }
    if (t == 0) { final_pick = true; read_in(true); }
}

// us.toml: fragment2 func_878001E8 entry (random 0..n-1). Returns -1 = not replaced.
extern "C" int32_t stadium_pvp_random(int32_t n) {
    if (!final_pick || n != 9) return -1;
    final_pick = false;
    if (!active || !online()) return -1;
    int g = seeded_game();
    fprintf(stderr, "[pvp] round 1: game %d (seed %u)\n", g, st.seed);
    return g;
}

// us.toml: fragment39 func_8250416C entry (choosing a game, every frame). From round 2 the
// picker comes from the server, once everyone has finished; the others follow their pick.
extern "C" void stadium_pvp_choose(uint8_t* rdram) {
    if (!active || !online()) return;
    read_in();
    others_are_coms(rdram);
    int16_t* picker = H(rdram, L_PICKER);
    int16_t* ai = H(rdram, L_AI_PICK);
    if (!picker || !ai || *picker < 0) return;      // -1: round 1's roulette
    int next = last_done + 1;
    static int16_t game_picker = 0;                 // who the game itself chose (shown on screen)
    if (wait_round != next) { wait_round = next; wait_since = std::chrono::steady_clock::now(); game_picker = *picker; }
    bool known = st.round == next && st.selector >= 0;
    if (!known && std::chrono::steady_clock::now() - wait_since > WAIT_MAX) {
        // no word from the server: carry on as the game would (its own picker - me, or a
        // COM that then picks by itself) rather than wait forever
        static int warned = 0;
        if (warned != next) { warned = next; fprintf(stderr, "[pvp] round %d: no picker from the server, the game's own (%d) picks\n", next, game_picker); }
        *picker = game_picker;
        if (game_picker == 0) *ai = -1;
        else if (*ai < 0) {                         // a COM picks: it needs a game to head for
            int g = int(std::chrono::steady_clock::now().time_since_epoch().count() % 9);
            if (g == playing_game) g = (g + 1) % 9;
            *ai = int16_t(g);
        }
        return;
    }
    if (st.round == next && st.selector == 0) {
        *picker = 0; *ai = -1;                      // my turn to pick
    } else if (st.round == next && st.selector > 0) {
        *picker = int16_t(st.selector);             // their pick, when it comes
        *ai = int16_t(st.pick >= 0 ? st.pick : -1);
    } else {
        *picker = 1; *ai = -1;                      // waiting for everyone to finish
    }
}

// us.toml: fragment39 func_825042A4 entry (a game was chosen, every frame until it starts)
extern "C" void stadium_pvp_chosen(uint8_t* rdram) {
    if (!active) return;
    int round = last_done + 1;
    if (playing == round) return;
    playing = round;
    int16_t* game = H(rdram, L_CURSORS + 6);
    playing_game = game ? *game : -1;
    if (online() && round > 1 && st.selector == 0 && game && picked_round != round) {
        picked_round = round;
        send("pick " + std::to_string(round) + " " + std::to_string(*game));
    }
}

// us.toml: before each minigame's instruction-screen Start check: Start "pressed".
extern "C" uint32_t stadium_pvp_skip_tutorial(uint32_t buttons) {
    return active ? (buttons | 0x1000) : buttons;
}

// us.toml: fragment2 func_87804AD0 (the Who's the Best scoreboard) before 0x87804E80, after
// it printed the win counts under the 1P / COM pills: the other players' names above
// their pills. s6 = the board's x offset; colour is the counts' (white).
extern "C" void stadium_pvp_names(uint8_t* rdram, recomp_context* ctx) {
    if (!active || !online()) return;
    constexpr uint32_t NAMES = 0x80702000;   // 4 x 16 bytes, free memory (see kidsclub.cpp)
    int32_t x0 = (int32_t)ctx->r22;
    recomp_context saved = *ctx;
    // the counts use spacing -2 (digits); letters need normal spacing
    ctx->r4 = 2; ctx->r5 = 0;
    func_8001EBE0(rdram, ctx);
    *ctx = saved;
    for (int s = 1; s <= 3; s++) {
        if (!st.slots[s].present || st.slots[s].name.empty()) continue;
        std::string n;
        for (char c : st.slots[s].name) if (c >= 32 && c < 127) n += c;
        if (n.size() > 8) n.resize(8);
        uint32_t str = NAMES + 16u * uint32_t(s);
        for (size_t i = 0; i <= n.size(); i++)
            rdram[((str + uint32_t(i)) ^ 3) - 0x80000000u] = i < n.size() ? uint8_t(n[i]) : 0;
        ctx->r4 = 0; ctx->r5 = (gpr)(int32_t)str;
        func_878013D4(rdram, ctx);
        int32_t w = (int32_t)ctx->r2;
        if (w <= 0 || w > 200) w = int32_t(n.size()) * 6;
        ctx->r4 = (gpr)(s * 0x36 + x0 + 0x50 - w / 2);
        ctx->r5 = 0xB0;
        ctx->r6 = (gpr)(int32_t)str;
        func_8001F1E8(rdram, ctx);
        *ctx = saved;
    }
}
