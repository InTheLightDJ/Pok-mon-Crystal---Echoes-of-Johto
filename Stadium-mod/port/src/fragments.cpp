// Stadium fragments -> librecomp overlays.
// Called from hooks the recompiler puts into Memmap_SetFragmentMap / Memmap_ClearFragmentMemmap
// (recomp/stadium1/us.toml [[patches.hook]]).
//
// A fragment's id comes from its link address: id = ((vram & 0x0FF00000) >> 20) - 0x10
// (macros.h FRAGMENT_ID). One id can belong to two fragments (same link slot), so the
// size the game passes (header sizeInRam) picks between them.
//
// Jump tables: right after the 0x20-byte header some fragments (fragment31) have
// 8-byte "j target; nop" slots that other code calls by address; targets are link
// addresses, often in *other* fragments. Those aren't recompiled (N64Recomp can't
// resolve them), so each slot gets a thunk here that finds where the target's
// fragment is loaded now and calls it. Same for a header "j" whose target is a slot.
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <span>
#include <unordered_map>
#include <utility>
#include <vector>
#include "recomp.h"
#include "librecomp/overlays.hpp"
#include "librecomp/sections.h"
#include "librecomp/game.hpp"

// from recomp_overlays.inl (register_overlays.cpp)
namespace stadium { const SectionTableEntry* section_entries(size_t& count); }

namespace {
    // Everything loaded, oldest first. Several fragments can share an id and stay in
    // RAM together (an archive's id 0xEF: a battle loads many), and the game keeps
    // calling the older ones through pointers, so an entry only goes away when its
    // memory is reused by a new load or freed (Memmap_ClearFragmentMemmap: that
    // id's latest load). The latest entry of an id is the one the game's gFragments
    // table points at (link address -> current address).
    struct Loaded { uint32_t id; uint32_t ram; uint32_t size; uint32_t vram; std::vector<size_t> thunks; };
    std::recursive_mutex mutex;
    std::vector<Loaded> loaded;

    bool log_enabled() {
        static const bool on = getenv("STADIUM_LOG_FRAGMENTS") != nullptr;
        return on;
    }

    uint32_t fragment_id(uint32_t vram) { return ((vram & 0x0FF00000u) >> 20) - 0x10; }

    const SectionTableEntry* find_section(uint32_t id, uint32_t size_in_ram) {
        size_t count = 0;
        const SectionTableEntry* table = stadium::section_entries(count);
        const SectionTableEntry* best = nullptr;
        uint32_t best_diff = UINT32_MAX;
        for (size_t i = 0; i < count; i++) {
            uint32_t vram = table[i].ram_addr;
            if (vram < 0x81000000u || vram >= 0x90000000u) continue;
            if (table[i].rom_addr >= 0x02000000u) continue;   // hidden: only by hash (find_hidden)
            if (fragment_id(vram) != id) continue;
            // sizeInRam covers code + data + bss + relocation table; the section is code + data
            uint32_t diff = size_in_ram >= table[i].size ? size_in_ram - table[i].size : UINT32_MAX - 1;
            if (diff < best_diff) { best = &table[i]; best_diff = diff; }
        }
        return best;
    }

    // Hidden fragments (compressed in the ROM; tools/build_hidden_fragments.py): many share
    // a link slot (0x8FF00000) and even sizes, so they're recognised by a hash of their
    // unrelocated code+data, which is what's in RAM when Memmap_SetFragmentMap runs.
    struct HiddenFragment { uint64_t hash; uint32_t size; uint32_t rom; };
    constexpr HiddenFragment hidden_fragments[] = {
#if defined(STADIUM1)
#include "stadium1_hidden_fragments.inc"
#endif
        { 0, 0, 0 }
    };

    uint8_t ram_byte(const uint8_t* rdram, uint32_t addr) {
        return rdram[((addr - 0x80000000u) ^ 3)];
    }

    uint32_t ram_word(const uint8_t* rdram, uint32_t addr) {
        return *reinterpret_cast<const uint32_t*>(rdram + (addr - 0x80000000u));
    }

    const SectionTableEntry* section_by_rom(uint32_t rom) {
        size_t count = 0;
        const SectionTableEntry* table = stadium::section_entries(count);
        for (size_t i = 0; i < count; i++) {
            if (table[i].rom_addr == rom) return &table[i];
        }
        return nullptr;
    }

    const SectionTableEntry* find_hidden(const uint8_t* rdram, uint32_t ram) {
        uint32_t reloc_off = ram_word(rdram, ram + 0x14);
        if (reloc_off == 0 || reloc_off > 0x200000) return nullptr;
        bool any = false;
        for (const auto& h : hidden_fragments) any |= (h.size == reloc_off);
        if (!any) return nullptr;
        uint64_t hash = 0xCBF29CE484222325ULL;
        for (uint32_t i = 0; i < reloc_off; i++) {
            hash = (hash ^ ram_byte(rdram, ram + i)) * 0x100000001B3ULL;
        }
        for (const auto& h : hidden_fragments) {
            if (h.size == reloc_off && h.hash == hash) return section_by_rom(h.rom);
        }
        return nullptr;
    }

    bool section_has_func_at(const SectionTableEntry* sec, uint32_t offset) {
        for (size_t i = 0; i < sec->num_funcs; i++) {
            if (sec->funcs[i].offset == offset) return true;
        }
        return false;
    }

    uint32_t rom_word(std::span<const uint8_t> rom, uint32_t addr) {
        if (addr + 4 > rom.size()) return 0;
        return (uint32_t(rom[addr]) << 24) | (uint32_t(rom[addr + 1]) << 16) | (uint32_t(rom[addr + 2]) << 8) | rom[addr + 3];
    }

    // --- slot thunks -----------------------------------------------------------
    constexpr size_t max_thunks = 256;
    std::array<uint32_t, max_thunks> thunk_target{};   // link address each thunk jumps to
    std::array<bool, max_thunks> thunk_used{};

    // Where a link address (0x81000000-0x8FFFFFFF) is now, or 0 if its fragment isn't loaded.
    uint32_t current_address(uint32_t link) {
        std::lock_guard lock(mutex);
        uint32_t id = fragment_id(link);
        for (auto it = loaded.rbegin(); it != loaded.rend(); ++it) {
            if (it->id == id) return it->ram + (link - it->vram);
        }
        return 0;
    }

    template <size_t N>
    void thunk(uint8_t* rdram, recomp_context* ctx) {
        uint32_t link = thunk_target[N];
        uint32_t addr = (link >= 0x81000000u && link < 0x90000000u) ? current_address(link) : link;
        if (addr == 0) {
            fprintf(stderr, "[fragments] slot thunk %zu: target 0x%08X's fragment isn't loaded\n", N, link);
            return;
        }
        LOOKUP_FUNC(addr)(rdram, ctx);
    }

    template <size_t... I>
    constexpr std::array<recomp_func_t*, sizeof...(I)> make_thunks(std::index_sequence<I...>) {
        return { &thunk<I>... };
    }
    const auto thunks = make_thunks(std::make_index_sequence<max_thunks>{});

    size_t alloc_thunk(uint32_t target) {
        for (size_t i = 0; i < max_thunks; i++) {
            if (!thunk_used[i]) { thunk_used[i] = true; thunk_target[i] = target; return i; }
        }
        fprintf(stderr, "[fragments] out of slot thunks\n");
        return SIZE_MAX;
    }

    void forget(std::vector<Loaded>::iterator it) {
        unload_overlays((int32_t)it->ram, it->size);
        for (size_t i : it->thunks) thunk_used[i] = false;
        loaded.erase(it);
    }

    // Register thunks for the header jump (if it isn't a recompiled function) and
    // the jump table after the header. Reads the ROM: RAM isn't relocated yet here.
    void register_slots(Loaded& entry, uint32_t id, const SectionTableEntry* sec, uint32_t ram) {
        std::span<const uint8_t> rom = recomp::get_rom();
        auto& list = entry.thunks;
        auto add = [&](uint32_t offset, uint32_t target) {
            size_t t = alloc_thunk(target);
            if (t == SIZE_MAX) return;
            list.push_back(t);
            recomp::overlays::add_loaded_function((int32_t)(ram + offset), thunks[t]);
        };
        auto j_target = [&](uint32_t w) { return 0x80000000u | ((w & 0x3FFFFFFu) << 2); };

        size_t slots = 0;
        for (uint32_t off = 0x20; off + 8 <= sec->size; off += 8) {
            uint32_t w = rom_word(rom, sec->rom_addr + off);
            if ((w >> 26) != 2 || rom_word(rom, sec->rom_addr + off + 4) != 0 || section_has_func_at(sec, off)) break;
            add(off, j_target(w));
            slots++;
        }
        uint32_t head = rom_word(rom, sec->rom_addr);
        if ((head >> 26) == 2 && !section_has_func_at(sec, 0)) {
            add(0, j_target(head));
        }
        if (slots && log_enabled()) {
            fprintf(stderr, "[fragments] id 0x%X: %zu jump-table slots\n", id, slots);
        }
    }
}

extern "C" void stadium_fragment_loaded(uint8_t* rdram, uint32_t id, uint32_t ram, uint32_t size) {
    std::lock_guard lock(mutex);
    // whatever used this memory before is gone
    for (size_t i = loaded.size(); i-- > 0;) {
        const Loaded& e = loaded[i];
        if (e.ram < ram + size && ram < e.ram + e.size) forget(loaded.begin() + i);
    }
    const SectionTableEntry* sec = find_hidden(rdram, ram);
    if (sec == nullptr) sec = find_section(id, size);
    if (sec == nullptr) {
        // data-only fragments have no code section
        if (log_enabled()) fprintf(stderr, "[fragments] id 0x%X (ram 0x%08X size 0x%X): no code\n", id, ram, size);
        return;
    }
    if (log_enabled()) {
        fprintf(stderr, "[fragments] id 0x%X -> section vram 0x%08X rom 0x%X size 0x%X at ram 0x%08X (sizeInRam 0x%X)\n",
                id, sec->ram_addr, sec->rom_addr, sec->size, ram, size);
    }
    // (If the same section is still loaded elsewhere, librecomp keeps one address per
    // section for its relocations: the new copy takes over. Not seen so far.)
    load_overlays(sec->rom_addr, (int32_t)ram, sec->size);
    loaded.push_back({ id, ram, sec->size, sec->ram_addr, {} });
    register_slots(loaded.back(), id, sec, ram);
}

extern "C" void stadium_fragment_unloaded(uint8_t* rdram, uint32_t id) {
    (void)rdram;
    std::lock_guard lock(mutex);
    for (size_t i = loaded.size(); i-- > 0;) {
        if (loaded[i].id == id) { forget(loaded.begin() + i); break; }
    }
}

// Where a fragment's link address (0x8NNxxxxx: code, data or bss) is right now, or 0 if
// that fragment isn't loaded. Fragments are linked 1 MB apart; bss follows code + data.
extern "C" uint32_t stadium_fragment_addr(uint32_t link_addr) {
    std::lock_guard lock(mutex);
    for (size_t i = loaded.size(); i-- > 0;) {
        const Loaded& e = loaded[i];
        if (link_addr >= e.vram && link_addr < e.vram + 0x100000u) return e.ram + (link_addr - e.vram);
    }
    return 0;
}
