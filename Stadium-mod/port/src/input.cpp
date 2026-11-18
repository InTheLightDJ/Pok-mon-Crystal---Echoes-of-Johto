// Input: keyboard (player 1) + SDL game controllers (players 1-4).
// Keyboard: arrows or WASD = stick, X/Space = A, C/Backspace = B, Enter = Start,
//           Z/LShift = Z, Q/E = L/R, IJKL = C-buttons, TFGH = D-pad, F11 = fullscreen.
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdlib>
#include <string>
#include <vector>
#include <atomic>
#include <mutex>
#include <cmath>
#include "SDL.h"
#include "ultramodern/ultra64.h"
#include "ultramodern/ultramodern.hpp"
#include "stadium.h"

// N64 button bits (libultra os_cont.h)
enum : uint16_t {
    N_A = 0x8000, N_B = 0x4000, N_Z = 0x2000, N_START = 0x1000,
    N_DU = 0x0800, N_DD = 0x0400, N_DL = 0x0200, N_DR = 0x0100,
    N_L = 0x0020, N_R = 0x0010,
    N_CU = 0x0008, N_CD = 0x0004, N_CL = 0x0002, N_CR = 0x0001,
};

struct PadState { uint16_t buttons = 0; float x = 0, y = 0; bool connected = false; };

static std::mutex state_mutex;
static std::array<PadState, 4> pads;
static std::array<SDL_GameController*, 4> controllers{};

static void open_controllers() {
    for (auto& c : controllers) { if (c) SDL_GameControllerClose(c); c = nullptr; }
    int slot = 0;
    for (int i = 0; i < SDL_NumJoysticks() && slot < 4; i++) {
        if (SDL_IsGameController(i)) controllers[slot++] = SDL_GameControllerOpen(i);
    }
}

void stadium::handle_events() {
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        switch (e.type) {
            case SDL_QUIT:
                ultramodern::quit();
                break;
            case SDL_CONTROLLERDEVICEADDED:
            case SDL_CONTROLLERDEVICEREMOVED:
                open_controllers();
                break;
            case SDL_KEYDOWN:
                if (e.key.keysym.scancode == SDL_SCANCODE_F11 || (e.key.keysym.scancode == SDL_SCANCODE_RETURN && (e.key.keysym.mod & KMOD_ALT))) {
                    auto cfg = ultramodern::renderer::get_graphics_config();
                    cfg.wm_option = cfg.wm_option == ultramodern::renderer::WindowMode::Fullscreen
                        ? ultramodern::renderer::WindowMode::Windowed : ultramodern::renderer::WindowMode::Fullscreen;
                    ultramodern::renderer::set_graphics_config(cfg);
                }
                break;
        }
    }
}

static float axis(SDL_GameController* c, SDL_GameControllerAxis a) {
    float v = SDL_GameControllerGetAxis(c, a) / 32767.0f;
    if (std::fabs(v) < 0.15f) return 0.0f;
    return std::clamp(v, -1.0f, 1.0f);
}

// Scripted input for testing (no OS key injection): STADIUM_INPUT="32:start,40:a,43:left"
// = seconds since start : button, each held 150 ms on player 1.
// Buttons: a b z start l r up down left right (d-pad) su sd sl sr (stick) cu cd cl cr.
namespace {
    struct ScriptedPress { double at; uint16_t buttons; float x, y; };
    std::vector<ScriptedPress> script;
    std::chrono::steady_clock::time_point script_start = std::chrono::steady_clock::now();

    void load_script() {
        static bool loaded = false;
        if (loaded) return;
        loaded = true;
        const char* s = getenv("STADIUM_INPUT");
        if (!s) return;
        std::string all(s);
        size_t pos = 0;
        while (pos < all.size()) {
            size_t comma = all.find(',', pos);
            std::string item = all.substr(pos, comma == std::string::npos ? std::string::npos : comma - pos);
            pos = comma == std::string::npos ? all.size() : comma + 1;
            size_t colon = item.find(':');
            if (colon == std::string::npos) continue;
            ScriptedPress p{ atof(item.substr(0, colon).c_str()), 0, 0, 0 };
            std::string b = item.substr(colon + 1);
            if (b == "a") p.buttons = N_A; else if (b == "b") p.buttons = N_B;
            else if (b == "z") p.buttons = N_Z; else if (b == "start") p.buttons = N_START;
            else if (b == "l") p.buttons = N_L; else if (b == "r") p.buttons = N_R;
            else if (b == "up") p.buttons = N_DU; else if (b == "down") p.buttons = N_DD;
            else if (b == "left") p.buttons = N_DL; else if (b == "right") p.buttons = N_DR;
            else if (b == "cu") p.buttons = N_CU; else if (b == "cd") p.buttons = N_CD;
            else if (b == "cl") p.buttons = N_CL; else if (b == "cr") p.buttons = N_CR;
            else if (b == "su") p.y = 1; else if (b == "sd") p.y = -1;
            else if (b == "sl") p.x = -1; else if (b == "sr") p.x = 1;
            else continue;
            script.push_back(p);
        }
        fprintf(stderr, "[input] %zu scripted presses from STADIUM_INPUT\n", script.size());
    }

    void apply_script(PadState& p1) {
        load_script();
        double now = std::chrono::duration<double>(std::chrono::steady_clock::now() - script_start).count();
        for (const auto& s : script) {
            if (now >= s.at && now < s.at + 0.15) {
                static double last_logged = -1;
                if (last_logged != s.at) { last_logged = s.at; fprintf(stderr, "[input] %.2fs: 0x%04X\n", now, s.buttons); }
                p1.buttons |= s.buttons;
                if (s.x != 0) p1.x = s.x;
                if (s.y != 0) p1.y = s.y;
            }
        }
    }
}

void stadium::poll_input() {
    std::array<PadState, 4> next{};

    // keyboard -> player 1
    const Uint8* k = SDL_GetKeyboardState(nullptr);
    PadState& p1 = next[0];
    p1.connected = true;
    // Keyboard layout:  Z = A, X = B, Enter = Start, WASD = D-pad, arrows = C buttons,
    // Q / E = L / R, Left Shift = Z trigger. Analog stick: hold the left mouse button in
    // the window; the stick tilts toward the cursor (from the window's center).
    if (k[SDL_SCANCODE_Z]) p1.buttons |= N_A;
    if (k[SDL_SCANCODE_X]) p1.buttons |= N_B;
    if (k[SDL_SCANCODE_LSHIFT] || k[SDL_SCANCODE_RSHIFT]) p1.buttons |= N_Z;
    if (k[SDL_SCANCODE_RETURN] || k[SDL_SCANCODE_KP_ENTER]) p1.buttons |= N_START;
    if (k[SDL_SCANCODE_Q]) p1.buttons |= N_L;
    if (k[SDL_SCANCODE_E]) p1.buttons |= N_R;
    if (k[SDL_SCANCODE_UP]) p1.buttons |= N_CU;
    if (k[SDL_SCANCODE_DOWN]) p1.buttons |= N_CD;
    if (k[SDL_SCANCODE_LEFT]) p1.buttons |= N_CL;
    if (k[SDL_SCANCODE_RIGHT]) p1.buttons |= N_CR;
    if (k[SDL_SCANCODE_W]) p1.buttons |= N_DU;
    if (k[SDL_SCANCODE_S]) p1.buttons |= N_DD;
    if (k[SDL_SCANCODE_A]) p1.buttons |= N_DL;
    if (k[SDL_SCANCODE_D]) p1.buttons |= N_DR;
    if (SDL_Window* w = SDL_GetMouseFocus()) {
        int mx, my, ww, wh;
        Uint32 mb = SDL_GetMouseState(&mx, &my);
        SDL_GetWindowSize(w, &ww, &wh);
        if ((mb & SDL_BUTTON_LMASK) && ww > 0 && wh > 0) {
            // full tilt a quarter of the window height from the center
            float range = wh / 4.0f;
            float dx = (mx - ww / 2.0f) / range, dy = (wh / 2.0f - my) / range;
            float len = std::sqrt(dx * dx + dy * dy);
            if (len > 0.08f) {
                if (len > 1.0f) { dx /= len; dy /= len; }
                p1.x = dx; p1.y = dy;
            }
        }
    }
    apply_script(p1);
    if (stadium::quick_boot_press_start()) p1.buttons |= N_START;

    for (int i = 0; i < 4; i++) {
        SDL_GameController* c = controllers[i];
        if (!c) continue;
        PadState& p = next[i];
        p.connected = true;
        auto b = [&](SDL_GameControllerButton btn) { return SDL_GameControllerGetButton(c, btn) != 0; };
        if (b(SDL_CONTROLLER_BUTTON_A)) p.buttons |= N_A;
        if (b(SDL_CONTROLLER_BUTTON_B) || b(SDL_CONTROLLER_BUTTON_X)) p.buttons |= N_B;
        if (b(SDL_CONTROLLER_BUTTON_START)) p.buttons |= N_START;
        if (b(SDL_CONTROLLER_BUTTON_LEFTSHOULDER)) p.buttons |= N_L;
        if (b(SDL_CONTROLLER_BUTTON_RIGHTSHOULDER)) p.buttons |= N_R;
        if (axis(c, SDL_CONTROLLER_AXIS_TRIGGERLEFT) > 0.5f) p.buttons |= N_Z;
        if (axis(c, SDL_CONTROLLER_AXIS_TRIGGERRIGHT) > 0.5f) p.buttons |= N_R;
        if (b(SDL_CONTROLLER_BUTTON_DPAD_UP)) p.buttons |= N_DU;
        if (b(SDL_CONTROLLER_BUTTON_DPAD_DOWN)) p.buttons |= N_DD;
        if (b(SDL_CONTROLLER_BUTTON_DPAD_LEFT)) p.buttons |= N_DL;
        if (b(SDL_CONTROLLER_BUTTON_DPAD_RIGHT)) p.buttons |= N_DR;
        float rx = axis(c, SDL_CONTROLLER_AXIS_RIGHTX), ry = axis(c, SDL_CONTROLLER_AXIS_RIGHTY);
        if (ry < -0.5f) p.buttons |= N_CU;
        if (ry > 0.5f) p.buttons |= N_CD;
        if (rx < -0.5f) p.buttons |= N_CL;
        if (rx > 0.5f) p.buttons |= N_CR;
        if (b(SDL_CONTROLLER_BUTTON_Y)) p.buttons |= N_CL;
        float lx = axis(c, SDL_CONTROLLER_AXIS_LEFTX), ly = axis(c, SDL_CONTROLLER_AXIS_LEFTY);
        if (lx != 0.0f || ly != 0.0f) { p.x = lx; p.y = -ly; }
    }

    std::lock_guard lock(state_mutex);
    pads = next;
}

bool stadium::get_input(int n, uint16_t* buttons, float* x, float* y) {
    if (n < 0 || n >= 4) return false;
    std::lock_guard lock(state_mutex);
    if (!pads[n].connected) return false;
    *buttons = pads[n].buttons;
    *x = pads[n].x;
    *y = pads[n].y;
    return true;
}

void stadium::set_rumble(int n, bool rumble) {
    if (n >= 0 && n < 4 && controllers[n]) {
        SDL_GameControllerRumble(controllers[n], rumble ? 0xFFFF : 0, rumble ? 0xFFFF : 0, rumble ? 1000 : 0);
    }
}

ultramodern::input::connected_device_info_t stadium::get_connected_device_info(int n) {
    // Player 1 is always plugged in (keyboard); others when a controller is there.
    bool on = n == 0 || (n > 0 && n < 4 && controllers[n] != nullptr);
    return { on ? ultramodern::input::Device::Controller : ultramodern::input::Device::None,
             transfer_pak_present(n) ? ultramodern::input::Pak::TransferPak : ultramodern::input::Pak::None };
}
