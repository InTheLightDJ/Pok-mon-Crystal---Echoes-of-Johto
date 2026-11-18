#pragma once
#include <cstdint>
#include <cstddef>
#include <memory>
#include <filesystem>
#include "ultramodern/ultramodern.hpp"
#include "ultramodern/renderer_context.hpp"
#include "ultramodern/input.hpp"

namespace stadium {
    void register_overlays();

    // main.cpp: %LOCALAPPDATA%\EchoesOfJohto-StadiumN (created on first use)
    std::filesystem::path config_folder();

    // transfer_pak.cpp: a Transfer Pak with a GB cart is in this controller port
    bool transfer_pak_present(int channel);

    // boot.cpp: start straight at Menu Select (default; --intro turns it off)
    void set_quick_boot(bool on);
    bool quick_boot_press_start();

    // pvp.cpp: Kids Club PVP (Who's the Best raced online through the launcher)
    void pvp_begin();
    void pvp_end();
    bool pvp_active();
    void pvp_lobby(uint8_t* rdram);                 // "Who wants to play?" each frame
    void pvp_setup_screen(uint8_t* rdram, int which); // COM level (4) / wins (3) screens

    // kidsclub.cpp: the Kids Club PVP box was chosen (Who's the Best with the online link)
    bool kidsclub_pvp_armed();

    // render.cpp (RT64)
    std::unique_ptr<ultramodern::renderer::RendererContext> create_render_context(
        uint8_t* rdram, ultramodern::renderer::WindowHandle window_handle, bool developer_mode);

    // input.cpp (SDL keyboard + game controllers)
    void handle_events();          // SDL event pump (gfx thread)
    void poll_input();
    bool get_input(int controller_num, uint16_t* buttons, float* x, float* y);
    void set_rumble(int controller_num, bool rumble);
    ultramodern::input::connected_device_info_t get_connected_device_info(int controller_num);

    // audio.cpp (SDL audio queue)
    void init_audio();
    void queue_samples(int16_t* audio_data, size_t sample_count);
    size_t get_frames_remaining();
    void set_frequency(uint32_t freq);
}
