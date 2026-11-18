// Pokémon Stadium (native PC port) - host program.
// Usage: Stadium1.exe [path\to\baserom.z64]
//   The ROM is checked against the known hash, then stored in the config folder
//   by librecomp, so later starts don't need the path.
#include <cstdio>
#include <cinttypes>
#include <filesystem>
#include <string>
#include <vector>
#include <span>
#include <cstring>

#define SDL_MAIN_HANDLED
#include "SDL.h"
#include "SDL_syswm.h"

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <timeapi.h>
#include <ShlObj.h>

#include "ultramodern/ultra64.h"
#include "ultramodern/ultramodern.hpp"
#include "librecomp/game.hpp"
#include "librecomp/rsp.hpp"
#include "stadium.h"

#if defined(STADIUM1)
static const char* window_title = "Pokemon Stadium";
static const std::u8string game_id = u8"stadium1.n64.us.1.0";
static const char* config_dir_name = "EchoesOfJohto-Stadium1";
static recomp::GameEntry make_entry();
#endif

extern "C" void recomp_entrypoint(uint8_t* rdram, recomp_context* ctx);
gpr get_entrypoint_address();

// Direct hardware access (no libultra call): the game reads the cartridge ROM
// through the PI bus (0xB0000000+, copy checks in the main code and several
// fragments) and peeks at hardware registers (0xA4000000+, e.g. PI_STATUS before
// those reads). Recompiled code turns an address A into rdram + (A - 0x80000000),
// so those land in the 4 GB rdram reservation past the 512 MB of RAM. Make them
// real memory: zeroed registers ("idle"), and the ROM in RDRAM word order.
extern uint8_t* g_rdram;   // crash.cpp (debug dumps)

static void map_hardware_windows(uint8_t* rdram, recomp_context*) {
    g_rdram = rdram;
    auto expose = [&](uint32_t offset, size_t size) -> uint8_t* {
        DWORD old;
        if (!VirtualProtect(rdram + offset, size, PAGE_READWRITE, &old)) {
            fprintf(stderr, "map_hardware_windows: VirtualProtect 0x%08X failed (%lu)\n", offset, GetLastError());
            return nullptr;
        }
        return rdram + offset;
    };
    expose(0x24000000, 0x00900000);                    // 0xA4000000-0xA48FFFFF: SP/DP/VI/AI/PI/RI/SI regs
    std::span<const uint8_t> rom = recomp::get_rom();
    if (uint8_t* dst = expose(0x30000000, rom.size())) { // 0xB0000000: cartridge ROM
        for (size_t i = 0; i + 4 <= rom.size(); i += 4) {
            uint32_t w = (uint32_t(rom[i]) << 24) | (uint32_t(rom[i + 1]) << 16) | (uint32_t(rom[i + 2]) << 8) | rom[i + 3];
            memcpy(dst + i, &w, 4);
        }
    }
}

#if defined(STADIUM1)
static recomp::GameEntry make_entry() {
    recomp::GameEntry e{};
    e.rom_hash = 0x6E46EACF8F27011DULL;     // XXH3-64 of the US 1.0 z64 (md5 ed1378bc...)
    e.internal_name = "POKEMON STADIUM";
    e.display_name = "Pokemon Stadium";
    e.game_id = game_id;
    e.mod_game_id = "";                   // no mod support
    // FlashRAM is the real chip, but the boot code also probes SRAM (rsp.c func_80000628)
    // and EEPROM: AllowAll lets every probe through instead of exiting.
    e.save_type = recomp::SaveType::AllowAll;
    e.is_enabled = true;
    e.has_compressed_code = false;
    e.entrypoint_address = get_entrypoint_address();
    e.entrypoint = recomp_entrypoint;
    e.on_init_callback = map_hardware_windows;
    return e;
}
#endif

static void message_box(const char* msg) {
    fprintf(stderr, "%s\n", msg);
    MessageBoxA(nullptr, msg, window_title, MB_OK | MB_ICONERROR);
}

static ultramodern::gfx_callbacks_t::gfx_data_t create_gfx() {
    SDL_SetHint(SDL_HINT_WINDOWS_DPI_AWARENESS, "permonitorv2");
    SDL_SetHint(SDL_HINT_GAMECONTROLLER_USE_BUTTON_LABELS, "0");
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    // Test runs (tools/shot_port.ps1 sets STADIUM_INPUT): don't take focus from the user.
    if (getenv("STADIUM_INPUT")) SDL_SetHint(SDL_HINT_WINDOW_NO_ACTIVATION_WHEN_SHOWN, "1");
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) != 0) {
        message_box(SDL_GetError());
        ultramodern::error_handling::quick_exit(__FILE__, __LINE__, __FUNCTION__);
    }
    return {};
}

static SDL_Window* window = nullptr;

static ultramodern::renderer::WindowHandle create_window(ultramodern::gfx_callbacks_t::gfx_data_t) {
    // Test runs (STADIUM_INPUT set by tools/shot_port.ps1) open the window off-screen
    // so it doesn't cover what the user is doing; screenshots still work (PrintWindow).
    int pos = getenv("STADIUM_INPUT") ? -4000 : SDL_WINDOWPOS_CENTERED;
    window = SDL_CreateWindow(window_title, pos, pos, 1280, 960, SDL_WINDOW_RESIZABLE);
    if (window == nullptr) {
        message_box(SDL_GetError());
        ultramodern::error_handling::quick_exit(__FILE__, __LINE__, __FUNCTION__);
    }
    SDL_SysWMinfo wm;
    SDL_VERSION(&wm.version);
    SDL_GetWindowWMInfo(window, &wm);
    return ultramodern::renderer::WindowHandle{ wm.info.win.window, GetCurrentThreadId() };
}

static void update_gfx(void*) {
    stadium::handle_events();
}

extern RspUcodeFunc aspMain;
extern RspUcodeFunc njpgdspMain;

static RspUcodeFunc* get_rsp_microcode(const OSTask* task) {
    switch (task->t.type) {
        case M_AUDTASK:   return aspMain;
        case M_NJPEGTASK: return njpgdspMain;
        default:
            fprintf(stderr, "Unknown RSP task type: %" PRIu32 "\n", task->t.type);
            return nullptr;
    }
}

std::filesystem::path stadium::config_folder() {
    PWSTR appdata = nullptr;
    std::filesystem::path p;
    if (SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &appdata) == S_OK) {
        p = std::filesystem::path(appdata) / config_dir_name;
    } else {
        p = std::filesystem::current_path() / config_dir_name;
    }
    CoTaskMemFree(appdata);
    std::filesystem::create_directories(p);
    return p;
}

static const char* rom_error_text(recomp::RomValidationError e) {
    switch (e) {
        case recomp::RomValidationError::FailedToOpen:     return "Could not open the ROM file.";
        case recomp::RomValidationError::NotARom:          return "That file is not an N64 ROM.";
        case recomp::RomValidationError::IncorrectRom:     return "That is a different game's ROM.";
        case recomp::RomValidationError::IncorrectVersion: return "Wrong version of the ROM (need the USA 1.0 release).";
        case recomp::RomValidationError::NotYet:           return "This game is not supported yet.";
        default:                                           return "The ROM could not be used.";
    }
}

void install_crash_handler();

int main(int argc, char** argv) {
    install_crash_handler();
    setvbuf(stdout, nullptr, _IONBF, 0);
    setvbuf(stderr, nullptr, _IONBF, 0);
    timeBeginPeriod(1);
    SetConsoleOutputCP(CP_UTF8);
    SDL_setenv("SDL_AUDIODRIVER", "wasapi", true);

    recomp::register_config_path(stadium::config_folder());
    recomp::register_game(make_entry());
    stadium::register_overlays();
    stadium::init_audio();

    // Options: --intro = normal start (N64 logo, intro movie, title) instead of
    // going straight to Menu Select. Anything else = a ROM path.
    const char* rom_arg = nullptr;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--intro") == 0) stadium::set_quick_boot(false);
        else if (strncmp(argv[i], "--", 2) != 0) rom_arg = argv[i];
    }

    // ROM: the path given on the command line, else the copy stored from an earlier start.
    if (rom_arg) {
        auto err = recomp::select_rom(std::filesystem::u8path(rom_arg), game_id);
        if (err != recomp::RomValidationError::Good) {
            message_box(rom_error_text(err));
            return 1;
        }
    }
    recomp::check_all_stored_roms();
    if (!recomp::is_rom_valid(game_id)) {
        message_box("No ROM yet: start it once with the ROM path, e.g.  Stadium1.exe baserom.z64");
        return 1;
    }

    recomp::Configuration cfg{};
    cfg.argc = argc;
    cfg.argv = argv;
    cfg.project_version = recomp::Version{ 0, 1, 0 };
    cfg.rsp_callbacks.get_rsp_microcode = get_rsp_microcode;
    cfg.renderer_callbacks.create_render_context = stadium::create_render_context;
    cfg.gfx_callbacks.create_gfx = create_gfx;
    cfg.gfx_callbacks.create_window = create_window;
    cfg.gfx_callbacks.update_gfx = update_gfx;
    cfg.audio_callbacks.queue_samples = stadium::queue_samples;
    cfg.audio_callbacks.get_frames_remaining = stadium::get_frames_remaining;
    cfg.audio_callbacks.set_frequency = stadium::set_frequency;
    cfg.input_callbacks.poll_input = stadium::poll_input;
    cfg.input_callbacks.get_input = stadium::get_input;
    cfg.input_callbacks.set_rumble = stadium::set_rumble;
    cfg.input_callbacks.get_connected_device_info = stadium::get_connected_device_info;
    cfg.error_handling_callbacks.message_box = message_box;

    // No launcher menu: the game starts as soon as the runtime is up.
    recomp::start_game(game_id, "");
    recomp::start(cfg);

    timeEndPeriod(1);
    return 0;
}
