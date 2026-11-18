// Scheduler trace for debugging (hooks in recomp/stadium1/us.toml call stadium_trace).
// Printed only when STADIUM_TRACE is set. arg = the game's task struct (5580.h
// UnkStruct80001380: unk_1C state @0x1C, unk_1E @0x1E, OSTask @0x20 -> type first).
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include "recomp.h"

static uint16_t half(uint8_t* rdram, uint32_t addr) {
    return *reinterpret_cast<uint16_t*>(rdram + (((addr - 0x80000000u)) ^ 2));
}

// trace.txt, fully buffered (stderr is unbuffered and slows the game down enough
// to change its timing); flushed by stadium_trace_flush (hang dump) and at exit.
static FILE* trace_file() {
    static FILE* f = [] {
        FILE* out = nullptr;
        fopen_s(&out, "trace.txt", "w");
        if (out) setvbuf(out, nullptr, _IOFBF, 1 << 20);
        return out;
    }();
    return f;
}

extern "C" void stadium_trace_flush() {
    if (getenv("STADIUM_TRACE") && trace_file()) fflush(trace_file());
}

static double trace_time() {
    static auto t0 = std::chrono::steady_clock::now();
    double t = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    // flush about once a second (test runs end with the process being killed)
    static double last_flush = 0;
    if (t - last_flush > 1.0 && trace_file()) { last_flush = t; fflush(trace_file()); }
    return t;
}

// free-form line into trace.txt (same timeline as the scheduler events)
extern "C" void stadium_trace_line(const char* text) {
    static const bool on = getenv("STADIUM_TRACE") != nullptr;
    if (!on || !trace_file()) return;
    fprintf(trace_file(), "%8.3f %s\n", trace_time(), text);
}

extern "C" void stadium_trace(uint8_t* rdram, const char* what, uint32_t task, uint32_t extra) {
    static const bool on = getenv("STADIUM_TRACE") != nullptr;
    if (!on) return;
    FILE* out = trace_file();
    if (!out) return;
    double t = trace_time();
    if (task >= 0x80000000u && task < 0x80800000u) {
        uint32_t type = *reinterpret_cast<uint32_t*>(rdram + (task + 0x20 - 0x80000000u));
        if (type == 2) return;   // audio: too frequent
        fprintf(out, "%8.3f %-8s task %08X type %u state %u 1E %u extra %08X\n", t, what, task, type,
                half(rdram, task + 0x1C), half(rdram, task + 0x1E), extra);
    } else {
        fprintf(out, "%8.3f %-8s %08X %08X\n", t, what, task, extra);
    }
}

// Pokémon model/animation loader (19840.c), hooks in us.toml.
// "req": a = unk_func_80019600* (s16 type @0, s16 id @2, s16* ids @0xC for type 2)
// "get": a = BinArchive*, b = file index (func_80019204)
// "geo": a = anim entry list (func_80019420, called once per anim set loaded)
extern "C" void stadium_trace_loader(uint8_t* rdram, const char* what, uint32_t a, uint32_t b) {
    static const bool on = getenv("STADIUM_TRACE") != nullptr;
    if (!on || !trace_file()) return;
    char line[256];
    int n = snprintf(line, sizeof(line), "loader %s %08X %08X", what, a, b);
    if (a >= 0x80000000u && a < 0x80800000u && what[0] == 'r') {
        uint32_t w0 = *reinterpret_cast<uint32_t*>(rdram + (a - 0x80000000u));
        n += snprintf(line + n, sizeof(line) - n, " type %d id %d", (int16_t)(w0 >> 16), (int16_t)(w0 & 0xFFFF));
        if ((w0 >> 16) == 2) {
            uint32_t ids = *reinterpret_cast<uint32_t*>(rdram + (a + 0xC - 0x80000000u));
            n += snprintf(line + n, sizeof(line) - n, " ids");
            for (int i = 0; i < 24 && ids >= 0x80000000u && ids < 0x80800000u && n < 230; i++) {
                int16_t id = (int16_t)half(rdram, ids + 2 * i);
                n += snprintf(line + n, sizeof(line) - n, " %d", id);
                if (id == -1) break;
            }
        }
    }
    stadium_trace_line(line);
}
