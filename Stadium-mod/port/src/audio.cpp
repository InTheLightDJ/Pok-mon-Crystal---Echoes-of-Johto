// SDL audio output (same scheme as Zelda64Recomp: float stereo, resampled to the device rate).
#include <array>
#include <vector>
#include <cassert>
#include <stdexcept>
#include <algorithm>
#include "SDL.h"
#include "stadium.h"
#include <cstdlib>
extern "C" void stadium_trace_line(const char*);

static SDL_AudioCVT audio_convert;
static SDL_AudioDeviceID audio_device = 0;
static uint32_t sample_rate = 48000;
static uint32_t output_sample_rate = 48000;
constexpr uint32_t input_channels = 2;
static uint32_t output_channels = 2;
constexpr uint32_t duplicated_input_frames = 4;
static uint32_t discarded_output_frames;
constexpr uint32_t bytes_per_frame = input_channels * sizeof(float);

static void update_audio_converter() {
    if (SDL_BuildAudioCVT(&audio_convert, AUDIO_F32, input_channels, sample_rate, AUDIO_F32, output_channels, output_sample_rate) < 0) {
        throw std::runtime_error(SDL_GetError());
    }
    discarded_output_frames = duplicated_input_frames * output_sample_rate / sample_rate;
}

void stadium::init_audio() {
    SDL_InitSubSystem(SDL_INIT_AUDIO);
    SDL_AudioSpec want{};
    want.freq = 48000;
    want.format = AUDIO_F32;
    want.channels = (Uint8)output_channels;
    want.samples = 0x100;
    audio_device = SDL_OpenAudioDevice(nullptr, false, &want, nullptr, 0);
    if (audio_device == 0) {
        fprintf(stderr, "SDL audio: %s\n", SDL_GetError());
        return;
    }
    SDL_PauseAudioDevice(audio_device, 0);
    output_sample_rate = 48000;
    update_audio_converter();
}

void stadium::set_frequency(uint32_t freq) {
    sample_rate = freq;
    update_audio_converter();
}

void stadium::queue_samples(int16_t* audio_data, size_t sample_count) {
    {   // trace: peak level and sample count per ~5 s (STADIUM_TRACE)
        static int peak = 0; static size_t total_samples = 0, clipped = 0; static uint32_t last_ms = SDL_GetTicks();
        for (size_t i = 0; i < sample_count; i++) { int v = std::abs((int)audio_data[i]); peak = std::max(peak, v); if (v >= 32767) clipped++; }
        total_samples += sample_count;
        if (SDL_GetTicks() - last_ms > 5000) {
            char line[96];
            snprintf(line, sizeof(line), "audio peak %d samples %zu clipped %zu rate %u", peak, total_samples, clipped, sample_rate);
            stadium_trace_line(line);
            peak = 0; total_samples = 0; clipped = 0; last_ms = SDL_GetTicks();
        }
    }
    if (audio_device == 0) return;
    static std::vector<float> buf;
    static std::array<float, duplicated_input_frames * input_channels> carry{};

    size_t total = sample_count + duplicated_input_frames * input_channels;
    size_t need = std::max(total, size_t(total * audio_convert.len_mult));
    if (need > buf.size()) buf.resize(need);

    for (size_t i = 0; i < carry.size(); i++) buf[i] = carry[i];
    // 16-bit -> float; swap L/R (the address xor of the byte-swapped RDRAM)
    for (size_t i = 0; i < sample_count; i += input_channels) {
        buf[i + 0 + carry.size()] = audio_data[i + 1] * (0.5f / 32768.0f);
        buf[i + 1 + carry.size()] = audio_data[i + 0] * (0.5f / 32768.0f);
    }
    if (sample_count <= carry.size()) return;
    for (size_t i = 0; i < carry.size(); i++) carry[i] = buf[i + sample_count];

    audio_convert.buf = reinterpret_cast<Uint8*>(buf.data());
    audio_convert.len = int(total * sizeof(float));
    if (SDL_ConvertAudio(&audio_convert) < 0) return;

    uint64_t queued_us = uint64_t(SDL_GetQueuedAudioSize(audio_device)) / bytes_per_frame * 1000000 / sample_rate;
    uint32_t bytes = audio_convert.len_cvt - output_channels * discarded_output_frames * sizeof(float);
    float* samples = buf.data() + output_channels * discarded_output_frames / 2;
    // Too much queued: drop samples so latency doesn't build up.
    uint32_t skip = uint32_t(queued_us / 100000);
    if (skip != 0) {
        uint32_t ratio = 1u << std::min(skip, 4u);
        bytes /= ratio;
        for (size_t i = 0; i < bytes / (output_channels * sizeof(float)); i++) {
            samples[2 * i + 0] = samples[2 * ratio * i + 0];
            samples[2 * i + 1] = samples[2 * ratio * i + 1];
        }
    }
    SDL_QueueAudio(audio_device, samples, bytes);
}

size_t stadium::get_frames_remaining() {
    if (audio_device == 0) return 0;
    uint64_t queued = SDL_GetQueuedAudioSize(audio_device);
    queued = queued * 2 * sample_rate / output_sample_rate / output_channels;
    uint32_t frames_per_vi = sample_rate / 60;
    queued = queued > uint64_t(bytes_per_frame) * frames_per_vi ? queued - uint64_t(bytes_per_frame) * frames_per_vi : 0;
    return size_t(queued / bytes_per_frame);
}

// Used by the us.toml hook in the audio manager instead of reading AI_LEN_REG.
extern "C" uint32_t stadium_ai_len(void) {
    return ultramodern::get_remaining_audio_bytes();
}
