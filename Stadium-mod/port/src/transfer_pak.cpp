// Game Boy Transfer Pak emulation (controller pak address space, libultra osGbpak*).
//
// The game talks to the pak through __osContRamRead/__osContRamWrite: 32-byte blocks at
// pak addresses (block number = address >> 5):
//   0x8000-0x8FFF  power        write 0x84 = on, 0xFE = off; reads 0x84 when on
//   0xA000-0xAFFF  bank         which 16 KB window of the GB address space 0xC000 shows (0-3)
//   0xB000-0xBFFF  status/mode  write bit 0 = cartridge access mode; read: 0x80 cart in,
//                               0x08 | 0x01 access mode on, 0x04 once after a mode change
//   0xC000-0xFFFF  cartridge    GB address bank * 0x4000 + (address - 0xC000)
// The cartridge side is a GB cart: ROM, a memory bank controller (ROM only / MBC1 / MBC2 /
// MBC3 / MBC5, what the Pokémon carts use) and battery RAM.
//
// Player N's pak: <dir>/pN.gb (ROM) and <dir>/pN.sav (save RAM), dir = STADIUM_TPAK_DIR or
// <config folder>/tpak. No ROM file -> no pak in that port. The save is written back when
// the pak is powered off / leaves access mode, and at exit.
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <vector>
#include "recomp.h"
#include "stadium.h"

extern "C" void stadium_trace_line(const char*);
static void tpak_trace(const char* op, int ch, uint16_t addr, const uint8_t* data) {
    char line[160];
    int n = snprintf(line, sizeof(line), "tpak %s ch %d addr %04X", op, ch, addr);
    for (int i = 0; i < 8 && data; i++) n += snprintf(line + n, sizeof(line) - n, " %02X", data[i]);
    stadium_trace_line(line);
}

namespace {
    constexpr int32_t PFS_ERR_NOPACK = 1;
    constexpr size_t BLOCKSIZE = 32;

    struct Cart {
        std::vector<uint8_t> rom;
        std::vector<uint8_t> ram;
        std::filesystem::path save_path;
        int mbc = 0;            // 0 none, 1 MBC1, 2 MBC2, 3 MBC3, 5 MBC5
        bool ram_enabled = false;
        uint32_t rom_bank = 1;
        uint32_t ram_bank = 0;  // MBC3: 0x08-0x0C select an RTC register
        bool mbc1_mode = false;
        bool dirty = false;

        uint8_t read(uint16_t a) const {
            if (a < 0x4000) return a < rom.size() ? rom[a] : 0xFF;
            if (a < 0x8000) {
                size_t off = size_t(rom_bank) * 0x4000 + (a - 0x4000);
                return off < rom.size() ? rom[off % rom.size()] : 0xFF;
            }
            if (a >= 0xA000 && a < 0xC000) {
                if (!ram_enabled) return 0xFF;
                if (mbc == 3 && ram_bank >= 0x08) return 0;   // RTC registers: stopped clock
                if (mbc == 2) return ram.empty() ? 0xFF : (ram[(a - 0xA000) & 0x1FF] | 0xF0);
                size_t off = size_t(ram_bank & 0x0F) * 0x2000 + (a - 0xA000);
                return off < ram.size() ? ram[off] : 0xFF;
            }
            return 0xFF;
        }

        void write(uint16_t a, uint8_t v) {
            if (a < 0x8000) { write_mbc(a, v); return; }
            if (a >= 0xA000 && a < 0xC000 && ram_enabled) {
                if (mbc == 3 && ram_bank >= 0x08) return;
                size_t off = mbc == 2 ? ((a - 0xA000) & 0x1FF) : size_t(ram_bank & 0x0F) * 0x2000 + (a - 0xA000);
                if (off < ram.size() && ram[off] != v) { ram[off] = v; dirty = true; }
            }
        }

        void write_mbc(uint16_t a, uint8_t v) {
            switch (mbc) {
            case 1:
                if (a < 0x2000) ram_enabled = (v & 0x0F) == 0x0A;
                else if (a < 0x4000) { rom_bank = (rom_bank & 0x60) | (v & 0x1F); if ((rom_bank & 0x1F) == 0) rom_bank++; }
                else if (a < 0x6000) {
                    if (mbc1_mode) ram_bank = v & 3;
                    else rom_bank = (rom_bank & 0x1F) | ((v & 3) << 5);
                }
                else mbc1_mode = v & 1;
                break;
            case 2:
                if (a < 0x4000) {
                    if (a & 0x100) { rom_bank = v & 0x0F; if (rom_bank == 0) rom_bank = 1; }
                    else ram_enabled = (v & 0x0F) == 0x0A;
                }
                break;
            case 3:
                if (a < 0x2000) ram_enabled = (v & 0x0F) == 0x0A;
                else if (a < 0x4000) { rom_bank = v & 0x7F; if (rom_bank == 0) rom_bank = 1; }
                else if (a < 0x6000) ram_bank = v;
                break;   // 0x6000-0x7FFF: RTC latch, nothing to do
            case 5:
                if (a < 0x2000) ram_enabled = (v & 0x0F) == 0x0A;
                else if (a < 0x3000) rom_bank = (rom_bank & 0x100) | v;
                else if (a < 0x4000) rom_bank = (rom_bank & 0xFF) | ((v & 1) << 8);
                else if (a < 0x6000) ram_bank = v & 0x0F;
                break;
            default:
                break;
            }
        }

        void save() {
            if (!dirty || ram.empty() || save_path.empty()) return;
            std::ofstream f(save_path, std::ios::binary);
            f.write(reinterpret_cast<const char*>(ram.data()), std::streamsize(ram.size()));
            dirty = false;
        }
    };

    struct Pak {
        bool present = false;
        bool powered = false;
        bool access_mode = false;
        bool mode_changed = false;
        uint8_t bank = 0;
        Cart cart;
    };

    std::recursive_mutex mutex;
    std::array<Pak, 4> paks;
    bool loaded = false;

    std::filesystem::path pak_dir() {
        if (const char* dir = getenv("STADIUM_TPAK_DIR")) return dir;
        return stadium::config_folder() / "tpak";
    }

    std::vector<uint8_t> read_file(const std::filesystem::path& p) {
        std::ifstream f(p, std::ios::binary);
        if (!f) return {};
        return std::vector<uint8_t>((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    }

    void load_cart(Cart& c, const std::filesystem::path& rom_path) {
        c.rom = read_file(rom_path);
        if (c.rom.size() < 0x150) { c.rom.clear(); return; }
        uint8_t type = c.rom[0x147];
        if (type >= 0x01 && type <= 0x03) c.mbc = 1;
        else if (type == 0x05 || type == 0x06) c.mbc = 2;
        else if (type >= 0x0F && type <= 0x13) c.mbc = 3;
        else if (type >= 0x19 && type <= 0x1E) c.mbc = 5;
        size_t ram_size = 0;
        switch (c.rom[0x149]) {
            case 1: ram_size = 0x800; break;
            case 2: ram_size = 0x2000; break;
            case 3: ram_size = 0x8000; break;
            case 4: ram_size = 0x20000; break;
            case 5: ram_size = 0x10000; break;
        }
        if (c.mbc == 2) ram_size = 0x200;
        c.ram.assign(ram_size, 0xFF);
        c.save_path = std::filesystem::path(rom_path).replace_extension(".sav");
        std::vector<uint8_t> save = read_file(c.save_path);
        for (size_t i = 0; i < save.size() && i < c.ram.size(); i++) c.ram[i] = save[i];
    }

    void save_all() {
        std::lock_guard lock(mutex);
        for (Pak& p : paks) if (p.present) p.cart.save();
    }

    void ensure_loaded() {
        if (loaded) return;
        loaded = true;
        std::filesystem::path dir = pak_dir();
        for (int i = 0; i < 4; i++) {
            std::filesystem::path rom = dir / ("p" + std::to_string(i + 1) + ".gb");
            std::error_code ec;
            if (!std::filesystem::exists(rom, ec)) continue;
            load_cart(paks[i].cart, rom);
            paks[i].present = !paks[i].cart.rom.empty();
            if (paks[i].present) {
                char title[17] = {};
                for (int k = 0; k < 16; k++) { char ch = (char)paks[i].cart.rom[0x134 + k]; title[k] = (ch >= 32 && ch < 127) ? ch : 0; }
                fprintf(stderr, "[tpak] player %d: \"%s\" MBC%d, %zu KB ROM, %zu KB save\n", i + 1, title,
                        paks[i].cart.mbc, paks[i].cart.rom.size() / 1024, paks[i].cart.ram.size() / 1024);
            }
        }
        atexit(save_all);
    }

    Pak* pak_for(int channel) {
        std::lock_guard lock(mutex);
        ensure_loaded();
        if (channel < 0 || channel >= 4 || !paks[channel].present) return nullptr;
        return &paks[channel];
    }

    uint8_t pak_read(Pak& p, uint16_t addr) {
        switch (addr >> 12) {
        case 0x8: return p.powered ? 0x84 : 0x00;
        case 0xA: return p.bank;
        case 0xB: {
            if (!p.powered) return 0x00;
            uint8_t s = p.access_mode ? 0x89 : 0x80;
            if (p.mode_changed) s |= 0x04;
            return s;
        }
        case 0xC: case 0xD: case 0xE: case 0xF:
            if (!p.powered || !p.access_mode) return 0x00;
            return p.cart.read(uint16_t(p.bank * 0x4000 + (addr - 0xC000)));
        default: return 0x00;
        }
    }

    void pak_write(Pak& p, uint16_t addr, uint8_t v, bool last_of_block) {
        switch (addr >> 12) {
        case 0x8:
            if (!last_of_block) return;
            if (v == 0x84) p.powered = true;
            else if (v == 0xFE) { p.powered = false; p.access_mode = false; p.cart.save(); }
            break;
        case 0xA:
            if (last_of_block) p.bank = v & 3;
            break;
        case 0xB:
            if (last_of_block) {
                bool on = v & 1;
                if (on != p.access_mode) p.mode_changed = true;
                p.access_mode = on;
                if (!on) p.cart.save();
            }
            break;
        case 0xC: case 0xD: case 0xE: case 0xF:
            if (p.powered && p.access_mode) p.cart.write(uint16_t(p.bank * 0x4000 + (addr - 0xC000)), v);
            break;
        default: break;
        }
    }
}

bool stadium::transfer_pak_present(int channel) { return pak_for(channel) != nullptr; }

extern "C" {

// s32 __osContRamRead(OSMesgQueue* mq, int channel, u16 address, u8* buffer)
void __osContRamRead_recomp(uint8_t* rdram, recomp_context* ctx) {
    Pak* p = pak_for((int)ctx->r5);
    if (!p) { ctx->r2 = PFS_ERR_NOPACK; return; }
    std::lock_guard lock(mutex);
    uint16_t addr = uint16_t((ctx->r6 & 0x7FF) << 5);
    uint8_t got[BLOCKSIZE];
    for (size_t i = 0; i < BLOCKSIZE; i++) { got[i] = pak_read(*p, uint16_t(addr + i)); MEM_B(i, ctx->r7) = (int8_t)got[i]; }
    tpak_trace("rd", (int)ctx->r5, addr, got);
    if ((addr >> 12) == 0xB) p->mode_changed = false;   // the reset flag is reported once
    ctx->r2 = 0;
}

// s32 __osContRamWrite(OSMesgQueue* mq, int channel, u16 address, u8* buffer, int force)
void __osContRamWrite_recomp(uint8_t* rdram, recomp_context* ctx) {
    Pak* p = pak_for((int)ctx->r5);
    if (!p) { ctx->r2 = PFS_ERR_NOPACK; return; }
    std::lock_guard lock(mutex);
    uint16_t addr = uint16_t((ctx->r6 & 0x7FF) << 5);
    { uint8_t d[8]; for (int i = 0; i < 8; i++) d[i] = (uint8_t)MEM_B(i, ctx->r7); tpak_trace("wr", (int)ctx->r5, addr, d); }
    for (size_t i = 0; i < BLOCKSIZE; i++) {
        pak_write(*p, uint16_t(addr + i), (uint8_t)MEM_B(i, ctx->r7), i == BLOCKSIZE - 1);
    }
    ctx->r2 = 0;
}

// s32 __osPfsGetStatus(OSMesgQueue* mq, int channel)
void __osPfsGetStatus_recomp(uint8_t* rdram, recomp_context* ctx) {
    (void)rdram;
    ctx->r2 = pak_for((int)ctx->r5) ? 0 : PFS_ERR_NOPACK;
}

// s32 osPfsIsPlug(OSMesgQueue* mq, u8* bitpattern)
void osPfsIsPlug_recomp(uint8_t* rdram, recomp_context* ctx) {
    uint8_t bits = 0;
    for (int i = 0; i < 4; i++) if (pak_for(i)) bits |= uint8_t(1 << i);
    MEM_B(0, ctx->r5) = (int8_t)bits;
    ctx->r2 = 0;
}

}
