// RT64 renderer context (adapted from Zelda64Recomp's rt64_render_context.cpp,
// without texture packs / UI hooks).
#include <memory>
#include <cstring>
#include <algorithm>
#include <chrono>

#define HLSL_CPU
#include "hle/rt64_application.h"

#include "ultramodern/ultramodern.hpp"
#include "ultramodern/config.hpp"
#include "stadium.h"

static uint8_t DMEM[0x1000];
static uint8_t IMEM[0x1000];

unsigned int MI_INTR_REG = 0;
unsigned int DPC_START_REG = 0;
unsigned int DPC_END_REG = 0;
unsigned int DPC_CURRENT_REG = 0;
unsigned int DPC_STATUS_REG = 0;
unsigned int DPC_CLOCK_REG = 0;
unsigned int DPC_BUFBUSY_REG = 0;
unsigned int DPC_PIPEBUSY_REG = 0;
unsigned int DPC_TMEM_REG = 0;

static void dummy_check_interrupts() {}

static RT64::UserConfiguration::AspectRatio to_rt64(ultramodern::renderer::AspectRatio o) {
    switch (o) {
        case ultramodern::renderer::AspectRatio::Expand: return RT64::UserConfiguration::AspectRatio::Expand;
        case ultramodern::renderer::AspectRatio::Manual: return RT64::UserConfiguration::AspectRatio::Manual;
        default:                                          return RT64::UserConfiguration::AspectRatio::Original;
    }
}
static RT64::UserConfiguration::Antialiasing to_rt64(ultramodern::renderer::Antialiasing o) {
    switch (o) {
        case ultramodern::renderer::Antialiasing::MSAA2X: return RT64::UserConfiguration::Antialiasing::MSAA2X;
        case ultramodern::renderer::Antialiasing::MSAA4X: return RT64::UserConfiguration::Antialiasing::MSAA4X;
        case ultramodern::renderer::Antialiasing::MSAA8X: return RT64::UserConfiguration::Antialiasing::MSAA8X;
        default:                                           return RT64::UserConfiguration::Antialiasing::None;
    }
}
static RT64::UserConfiguration::RefreshRate to_rt64(ultramodern::renderer::RefreshRate o) {
    switch (o) {
        case ultramodern::renderer::RefreshRate::Display: return RT64::UserConfiguration::RefreshRate::Display;
        case ultramodern::renderer::RefreshRate::Manual:  return RT64::UserConfiguration::RefreshRate::Manual;
        default:                                           return RT64::UserConfiguration::RefreshRate::Original;
    }
}

static void set_user_config(RT64::Application* app, const ultramodern::renderer::GraphicsConfig& c) {
    switch (c.res_option) {
        default:
        case ultramodern::renderer::Resolution::Auto:
            app->userConfig.resolution = RT64::UserConfiguration::Resolution::WindowIntegerScale;
            app->userConfig.downsampleMultiplier = 1;
            break;
        case ultramodern::renderer::Resolution::Original:
            app->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
            app->userConfig.resolutionMultiplier = std::max(c.ds_option, 1);
            app->userConfig.downsampleMultiplier = std::max(c.ds_option, 1);
            break;
        case ultramodern::renderer::Resolution::Original2x:
            app->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
            app->userConfig.resolutionMultiplier = 2.0 * std::max(c.ds_option, 1);
            app->userConfig.downsampleMultiplier = std::max(c.ds_option, 1);
            break;
    }
    // Stadium is a 4:3 game: keep the HUD/menus at their original ratio.
    app->userConfig.extAspectRatio = RT64::UserConfiguration::AspectRatio::Original;
    app->userConfig.aspectRatio = to_rt64(c.ar_option);
    app->userConfig.antialiasing = to_rt64(c.msaa_option);
    app->userConfig.refreshRate = to_rt64(c.rr_option);
    app->userConfig.refreshRateTarget = c.rr_manual_value;
    app->userConfig.displayBuffering = RT64::UserConfiguration::DisplayBuffering::Triple;
    // Stadium's menus draw panels as many scaled texture rectangles side by side;
    // upscaled, their edges leave hairline gaps (lines across the panels). Draw 2D
    // rectangles on the original pixel grid instead.
    app->userConfig.upscale2D = RT64::UserConfiguration::Upscale2D::Original;
    if (getenv("STADIUM_RES1X")) {   // debugging: native resolution
        app->userConfig.resolution = RT64::UserConfiguration::Resolution::Manual;
        app->userConfig.resolutionMultiplier = 1;
        app->userConfig.downsampleMultiplier = 1;
    }
}

static ultramodern::renderer::SetupResult map_setup_result(RT64::Application::SetupResult r) {
    switch (r) {
        case RT64::Application::SetupResult::Success:                 return ultramodern::renderer::SetupResult::Success;
        case RT64::Application::SetupResult::DynamicLibrariesNotFound: return ultramodern::renderer::SetupResult::DynamicLibrariesNotFound;
        case RT64::Application::SetupResult::InvalidGraphicsAPI:      return ultramodern::renderer::SetupResult::InvalidGraphicsAPI;
        case RT64::Application::SetupResult::GraphicsAPINotFound:     return ultramodern::renderer::SetupResult::GraphicsAPINotFound;
        default:                                                      return ultramodern::renderer::SetupResult::GraphicsDeviceNotFound;
    }
}

static ultramodern::renderer::GraphicsApi map_graphics_api(RT64::UserConfiguration::GraphicsAPI api) {
    switch (api) {
        case RT64::UserConfiguration::GraphicsAPI::D3D12:  return ultramodern::renderer::GraphicsApi::D3D12;
        case RT64::UserConfiguration::GraphicsAPI::Vulkan: return ultramodern::renderer::GraphicsApi::Vulkan;
        case RT64::UserConfiguration::GraphicsAPI::Metal:  return ultramodern::renderer::GraphicsApi::Metal;
        default:                                            return ultramodern::renderer::GraphicsApi::Auto;
    }
}

extern "C" void stadium_trace_line(const char* text);

namespace {
class RT64Context final : public ultramodern::renderer::RendererContext {
public:
    RT64Context(uint8_t* rdram, ultramodern::renderer::WindowHandle window_handle, bool debug) {
        static unsigned char dummy_rom_header[0x40];
        RT64::Application::Core core{};
        core.window = window_handle.window;
        core.checkInterrupts = dummy_check_interrupts;
        core.HEADER = dummy_rom_header;
        core.RDRAM = rdram;
        core.DMEM = DMEM;
        core.IMEM = IMEM;
        core.MI_INTR_REG = &MI_INTR_REG;
        core.DPC_START_REG = &DPC_START_REG;
        core.DPC_END_REG = &DPC_END_REG;
        core.DPC_CURRENT_REG = &DPC_CURRENT_REG;
        core.DPC_STATUS_REG = &DPC_STATUS_REG;
        core.DPC_CLOCK_REG = &DPC_CLOCK_REG;
        core.DPC_BUFBUSY_REG = &DPC_BUFBUSY_REG;
        core.DPC_PIPEBUSY_REG = &DPC_PIPEBUSY_REG;
        core.DPC_TMEM_REG = &DPC_TMEM_REG;

        ultramodern::renderer::ViRegs* vi = ultramodern::renderer::get_vi_regs();
        core.VI_STATUS_REG = &vi->VI_STATUS_REG;
        core.VI_ORIGIN_REG = &vi->VI_ORIGIN_REG;
        core.VI_WIDTH_REG = &vi->VI_WIDTH_REG;
        core.VI_INTR_REG = &vi->VI_INTR_REG;
        core.VI_V_CURRENT_LINE_REG = &vi->VI_V_CURRENT_LINE_REG;
        core.VI_TIMING_REG = &vi->VI_TIMING_REG;
        core.VI_V_SYNC_REG = &vi->VI_V_SYNC_REG;
        core.VI_H_SYNC_REG = &vi->VI_H_SYNC_REG;
        core.VI_LEAP_REG = &vi->VI_LEAP_REG;
        core.VI_H_START_REG = &vi->VI_H_START_REG;
        core.VI_V_START_REG = &vi->VI_V_START_REG;
        core.VI_V_BURST_REG = &vi->VI_V_BURST_REG;
        core.VI_X_SCALE_REG = &vi->VI_X_SCALE_REG;
        core.VI_Y_SCALE_REG = &vi->VI_Y_SCALE_REG;

        RT64::ApplicationConfiguration app_config;
        app_config.useConfigurationFile = false;
        app = std::make_unique<RT64::Application>(core, app_config);

        auto& cfg = ultramodern::renderer::get_graphics_config();
        set_user_config(app.get(), cfg);
        app->userConfig.developerMode = debug;
        app->enhancementConfig.textureLOD.scale = true;
        switch (cfg.api_option) {
            case ultramodern::renderer::GraphicsApi::D3D12:  app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::D3D12; break;
            case ultramodern::renderer::GraphicsApi::Vulkan: app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::Vulkan; break;
            default:                                         app->userConfig.graphicsAPI = RT64::UserConfiguration::GraphicsAPI::Automatic; break;
        }

        setup_result = map_setup_result(app->setup(window_handle.thread_id));
        chosen_api = map_graphics_api(app->chosenGraphicsAPI);
        if (setup_result != ultramodern::renderer::SetupResult::Success) {
            app = nullptr;
            return;
        }
        app->setFullScreen(cfg.wm_option == ultramodern::renderer::WindowMode::Fullscreen);
    }

    ~RT64Context() override = default;

    bool valid() override { return static_cast<bool>(app); }

    bool update_config(const ultramodern::renderer::GraphicsConfig& old_c, const ultramodern::renderer::GraphicsConfig& new_c) override {
        if (old_c == new_c) return false;
        if (new_c.wm_option != old_c.wm_option) {
            app->setFullScreen(new_c.wm_option == ultramodern::renderer::WindowMode::Fullscreen);
        }
        set_user_config(app.get(), new_c);
        app->updateUserConfig(true);
        if (new_c.msaa_option != old_c.msaa_option) app->updateMultisampling();
        return true;
    }

    void enable_instant_present() override {
        app->enhancementConfig.presentation.mode = RT64::EnhancementConfiguration::Presentation::Mode::PresentEarly;
        app->updateEnhancementConfig();
    }

    void send_dl(const OSTask* task) override {
        // log every new graphics microcode (text/data address) the game uses
        static uint32_t last_ucode = 0;
        if (task->t.ucode != last_ucode) {
            last_ucode = task->t.ucode;
            fprintf(stderr, "[gfx] microcode text 0x%08X data 0x%08X (size 0x%X)\n",
                    (uint32_t)task->t.ucode, (uint32_t)task->t.ucode_data, (uint32_t)task->t.ucode_size);
        }
        static uint32_t dl_count = 0;
        static auto window_start = std::chrono::steady_clock::now();
        dl_count++;
        if (std::chrono::steady_clock::now() - window_start > std::chrono::seconds(5)) {
            char line[96];
            snprintf(line, sizeof(line), "dl %u display lists in the last 5 s (last 0x%08X)", dl_count, (uint32_t)task->t.data_ptr);
            stadium_trace_line(line);
            dl_count = 0;
            window_start = std::chrono::steady_clock::now();
        }
        app->state->rsp->reset();
        app->interpreter->loadUCodeGBI(task->t.ucode & 0x3FFFFFF, task->t.ucode_data & 0x3FFFFFF, true);
        app->processDisplayLists(app->core.RDRAM, task->t.data_ptr & 0x3FFFFFF, 0, true);
    }

    // Used by the runtime when a frame is shown without a display list (e.g. a
    // software-drawn framebuffer). RT64 picks the framebuffer up from VI_ORIGIN.
    void send_dummy_workload(uint32_t) override {}

    void update_screen() override {
        // log VI register changes (what the game asks to display)
        ultramodern::renderer::ViRegs* vi = ultramodern::renderer::get_vi_regs();
        static uint32_t last[6] = {};
        uint32_t now[6] = { vi->VI_STATUS_REG, vi->VI_WIDTH_REG, vi->VI_X_SCALE_REG, vi->VI_Y_SCALE_REG, vi->VI_H_START_REG, vi->VI_ORIGIN_REG };
        if (memcmp(now, last, sizeof(now)) != 0) {
            memcpy(last, now, sizeof(now));
            char line[160];
            snprintf(line, sizeof(line), "vi status %08X width %u xscale %08X yscale %08X hstart %08X origin %08X",
                     now[0], now[1], now[2], now[3], now[4], now[5]);
            stadium_trace_line(line);
        }
        app->updateScreen();
    }

    void shutdown() override {
        if (app) app->end();
    }

    uint32_t get_display_framerate() const override {
        return app->presentQueue->ext.sharedResources->swapChainRate;
    }

    float get_resolution_scale() const override {
        constexpr int reference_height = 240;
        switch (app->userConfig.resolution) {
            case RT64::UserConfiguration::Resolution::WindowIntegerScale:
                if (app->sharedQueueResources->swapChainHeight > 0) {
                    return std::max(float((app->sharedQueueResources->swapChainHeight + reference_height - 1) / reference_height), 1.0f);
                }
                return 1.0f;
            case RT64::UserConfiguration::Resolution::Manual:
                return float(app->userConfig.resolutionMultiplier);
            default:
                return 1.0f;
        }
    }

private:
    std::unique_ptr<RT64::Application> app;
};
}

std::unique_ptr<ultramodern::renderer::RendererContext> stadium::create_render_context(
    uint8_t* rdram, ultramodern::renderer::WindowHandle window_handle, bool developer_mode) {
    return std::make_unique<RT64Context>(rdram, window_handle, developer_mode);
}
