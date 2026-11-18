// Kids Club menu: a third box, "PVP", under "Pick a game." and "Who's the best?".
//
// The menu (fragment39) builds its boxes from a pool of 14 panels, all in use; the PVP box
// is a 15th panel in otherwise unused memory (EXTRA, top 2 MB of the 8 MB expansion RAM,
// which the game's heap never reaches). It's made with the game's own func_8250182C(1, 2,
// box geo) - box index 2, so it sits under the other two and the cursor hand / highlight
// formulas just work - and chained after "Who's the best?" so it flips in and out with them.
// Its flip animation is run here (the game's loop only walks its pool).
// Picture: the "Who's the best?" art with the text replaced by "PVP" (drawn here into a
// copy, PVP_TEX). Choosing it = Who's the Best, with the online PVP link (pvp.cpp) armed.
//
// us.toml hooks: func_825024C4 (menu set-up) before 0x825027E8 -> stadium_kc_setup,
// func_825017F0 (pool alloc) -> stadium_kc_alloc, func_82501ED0 (panel animation) ->
// stadium_kc_update, func_82500020 (box draw) -> stadium_kc_draw, Memmap_GetSegmentVaddr ->
// stadium_kc_segment, func_825032BC / func_82503020 (menu states) -> stadium_kc_state.
// Instruction patches in func_82503020 make the cursor wrap at 3 boxes instead of 2.
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cmath>
#include <algorithm>
#include "recomp.h"
#include "stadium.h"

extern "C" uint32_t stadium_fragment_addr(uint32_t link_addr);
extern "C" void func_8250182C(uint8_t* rdram, recomp_context* ctx);

namespace {
    constexpr uint32_t EXTRA     = 0x80700000;   // the PVP panel (0x1A4 bytes)
    constexpr uint32_t PVP_TEX   = 0x80701000;   // 300 x 80 RGBA16 box art copy
    constexpr uint32_t PANEL_SIZE = 0x1A4;
    constexpr int TEX_W = 300, TEX_H = 80;
    constexpr uint32_t WTB_ART   = 0x03017700;   // "Who's the best?" art (segment 3)
    constexpr uint32_t IDX2_ART  = 0x0308B290;   // what the box table yields for index 2
    // fragment39 / fragment2 link addresses
    constexpr uint32_t L_BOXES   = 0x8250A228;   // D_8250A228[2]: the two main boxes
    constexpr uint32_t L_BOX_GEO = 0x8250A274;   // D_8250A274: their geo
    constexpr uint32_t L_MODE    = 0x8780FA2A;   // D_8780FA2A: 0 pick a game, 1 who's the best
    constexpr uint32_t CUR_OBJ   = 0x8006F09C;   // D_8006F09C: object being drawn

    bool made = false;           // PVP panel exists (this menu set-up)
    bool alloc_extra = false;    // the next pool alloc returns EXTRA
    bool tex_ready = false;
    int draw_calls = 0;          // segment lookups left for the PVP panel's draw
    bool armed = false;          // PVP chosen; the link starts with the roulette

    uint32_t& W(uint8_t* rdram, uint32_t a) { return *reinterpret_cast<uint32_t*>(rdram + (a - 0x80000000u)); }
    int16_t& H(uint8_t* rdram, uint32_t a) { return *reinterpret_cast<int16_t*>(rdram + ((a ^ 2) - 0x80000000u)); }
    uint8_t& B(uint8_t* rdram, uint32_t a) { return *reinterpret_cast<uint8_t*>(rdram + ((a ^ 3) - 0x80000000u)); }
    uint16_t px_get(uint8_t* rdram, uint32_t base, int x, int y) { return uint16_t(H(rdram, base + 2 * (y * TEX_W + x))); }
    void px_set(uint8_t* rdram, uint32_t base, int x, int y, uint16_t v) { H(rdram, base + 2 * (y * TEX_W + x)) = int16_t(v); }
    uint16_t rgba(int r, int g, int b) { return uint16_t(((r >> 3) << 11) | ((g >> 3) << 6) | ((b >> 3) << 1) | 1); }

    // ---- "PVP" lettering: rounded strokes (capsules / arcs), same look as the art's text ----
    float seg_dist(float px, float py, float ax, float ay, float bx, float by) {
        float vx = bx - ax, vy = by - ay, wx = px - ax, wy = py - ay;
        float t = std::clamp((wx * vx + wy * vy) / (vx * vx + vy * vy), 0.0f, 1.0f);
        float dx = wx - t * vx, dy = wy - t * vy;
        return std::sqrt(dx * dx + dy * dy);
    }
    // distance from a glyph's centre lines; letter box 0..LW x 0..LH
    constexpr float LH = 44, LW = 30, R = 6.0f;   // height, width, stroke half-width
    float glyph_P(float x, float y) {
        float d = seg_dist(x, y, R, R, R, LH - R);                         // stem
        d = std::min(d, seg_dist(x, y, R, R, LW - 13, R));                 // top
        d = std::min(d, seg_dist(x, y, R, 25, LW - 13, 25));               // middle
        float cx = LW - 13, cy = (R + 25) / 2, rr = (25 - R) / 2;          // bowl
        if (x >= cx) d = std::min(d, std::fabs(std::hypot(x - cx, y - cy) - rr));
        return d;
    }
    float glyph_V(float x, float y) {
        return std::min(seg_dist(x, y, R, R, LW / 2, LH - R), seg_dist(x, y, LW - R, R, LW / 2, LH - R));
    }

    void make_texture(uint8_t* rdram, uint32_t art) {
        // copy, then wipe the old text with plain background from the right half
        for (int y = 0; y < TEX_H; y++)
            for (int x = 0; x < TEX_W; x++) px_set(rdram, PVP_TEX, x, y, px_get(rdram, art, x, y));
        for (int y = 3; y < TEX_H - 4; y++)
            for (int x = 3; x < 140; x++) px_set(rdram, PVP_TEX, x, y, px_get(rdram, art, x + 150, y));
        // letters
        const float ox[3] = { 14, 14 + LW + 5, 14 + 2 * (LW + 5) };
        const float oy = (TEX_H - LH) / 2;
        for (int y = 0; y < TEX_H; y++) {
            for (int x = 0; x < 140; x++) {
                float d = 1e9f, ds = 1e9f;
                for (int k = 0; k < 3; k++) {
                    float lx = x - ox[k], ly = y - oy;
                    auto g = (k == 1) ? glyph_V : glyph_P;
                    d = std::min(d, g(lx, ly) - R);
                    ds = std::min(ds, g(lx - 2.5f, ly - 2.5f) - R);   // drop shadow
                }
                if (d <= 0) {
                    // fill: white at the top to salmon at the bottom, a lighter rim inside the outline
                    float t = std::clamp((y - oy) / LH, 0.0f, 1.0f);
                    int r = 255, g = int(250 - 130 * t), b = int(245 - 150 * t);
                    if (d > -1.5f) { g = std::min(255, g + 40); b = std::min(255, b + 40); }
                    px_set(rdram, PVP_TEX, x, y, rgba(r, g, b));
                } else if (d <= 2.0f) {
                    px_set(rdram, PVP_TEX, x, y, rgba(40, 18, 14));        // outline
                } else if (ds <= 2.0f) {
                    px_set(rdram, PVP_TEX, x, y, rgba(28, 12, 10));        // shadow
                }
            }
        }
        tex_ready = true;
    }
}

// set-up: called where func_825024C4 has made and chained the menu's panels
extern "C" void stadium_kc_setup(uint8_t* rdram, recomp_context* ctx) {
    made = false;
    tex_ready = false;
    uint32_t boxes = stadium_fragment_addr(L_BOXES), geo = stadium_fragment_addr(L_BOX_GEO);
    if (!boxes || !geo) return;
    std::memset(rdram + (EXTRA - 0x80000000u), 0, PANEL_SIZE);
    recomp_context saved = *ctx;
    ctx->r4 = 1;                                   // type 1: a main box
    ctx->r5 = 2;                                   // index 2: under the other two
    ctx->r6 = (gpr)(int32_t)W(rdram, geo);
    alloc_extra = true;
    func_8250182C(rdram, ctx);
    alloc_extra = false;
    uint32_t got = (uint32_t)ctx->r2;
    *ctx = saved;
    if (got != EXTRA) return;
    uint32_t who = W(rdram, boxes + 4);            // D_8250A228[1]
    if (who) W(rdram, who + 0x34) = EXTRA;         // ->unk_34: flips together with it
    made = true;
}

// pool alloc (func_825017F0 entry): 1 = returned EXTRA
extern "C" int stadium_kc_alloc(recomp_context* ctx) {
    if (!alloc_extra) return 0;
    ctx->r2 = (gpr)(int32_t)EXTRA;
    return 1;
}

// panel animation (func_82501ED0 entry): the flip states, as the game does for its pool
extern "C" void stadium_kc_update(uint8_t* rdram) {
    if (!made) return;
    uint16_t state = uint16_t(H(rdram, EXTRA + 2));
    int16_t& timer = H(rdram, EXTRA + 8);
    int16_t& rot = H(rdram, EXTRA + 0x3C + 0x1E);
    uint8_t& flags = B(rdram, EXTRA + 0x3C + 0x01);
    switch (state) {
        case 1:
            timer--;
            rot = int16_t((((10 - timer) << 14) / 10) - 0x4000);
            if (timer <= 0) { rot = 0; H(rdram, EXTRA + 2) = 2; timer = 0; }
            break;
        case 3:
            timer--;
            rot = int16_t(((10 - timer) << 14) / 10);
            if (timer <= 0) { H(rdram, EXTRA + 2) = 4; timer = 0; rot = 0x4000; flags &= ~1; }
            break;
        case 7:
            timer--;
            rot = int16_t(0x4000 - (((10 - timer) << 14) / 10));
            if (timer <= 0) { H(rdram, EXTRA + 2) = 2; timer = 0; rot = 0; }
            break;
        case 8:
            timer--;
            rot = int16_t(((10 - timer) * -0x4000) / 10);
            if (timer <= 0) { rot = -0x4000; H(rdram, EXTRA + 2) = 0; timer = 0; flags &= ~1; }
            break;
        default:
            break;
    }
}

// box draw callback (func_82500020 entry, a0 = draw phase): is it the PVP panel?
extern "C" void stadium_kc_draw(uint8_t* rdram, int32_t phase) {
    if (!made || phase != 5) return;
    uint32_t obj = W(rdram, CUR_OBJ);
    if (obj == EXTRA + 0x3C || obj == EXTRA) draw_calls = 2;
}

// Memmap_GetSegmentVaddr entry: the PVP panel's art -> the PVP copy. 1 = answered (r2 set)
extern "C" int stadium_kc_segment(uint8_t* rdram, recomp_context* ctx) {
    if (draw_calls <= 0) return 0;
    draw_calls--;
    if ((uint32_t)ctx->r4 != IDX2_ART) return 0;
    if (!tex_ready) {
        uint32_t seg3 = W(rdram, 0x800A5870 + 8 * 3);        // gSegments[3].vaddr
        if (!seg3) return 0;
        make_texture(rdram, seg3 + (WTB_ART & 0x00FFFFFF));
    }
    ctx->r2 = (gpr)(int32_t)PVP_TEX;
    return 1;
}

// menu states (every frame): 0 = main menu (func_82503020): not PVP (left it);
// 1 = "Who wants to play?" (func_825032BC): mode 2 (the PVP box) -> Who's the Best (1) and
// the PVP party is joined right away (announced while everyone's in the lobby);
// 4 / 3 = COM level / number of wins (func_82503574 / func_825039AC)
extern "C" void stadium_kc_state(uint8_t* rdram, int32_t which) {
    if (which == 0) {
        armed = false;
        stadium::pvp_end();
        return;
    }
    if (which == 1) {
        uint32_t mode = stadium_fragment_addr(L_MODE);
        if (mode && H(rdram, mode) == 2) {
            H(rdram, mode) = 1;
            armed = true;
            fprintf(stderr, "[kidsclub] PVP chosen\n");
            stadium::pvp_begin();
        }
        stadium::pvp_lobby(rdram);
        return;
    }
    stadium::pvp_setup_screen(rdram, which);
}

bool stadium::kidsclub_pvp_armed() { return armed; }
