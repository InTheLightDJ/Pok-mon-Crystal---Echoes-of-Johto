// libultra routines the game calls that N64ModernRuntime doesn't implement.
// N64Recomp renames libultra functions to <name>_recomp and expects the runtime
// (or the host) to provide them.
//
#include <cstdint>
#include "recomp.h"

namespace {
    inline void ret(recomp_context* ctx, int32_t v) { ctx->r2 = (gpr)v; }
}

extern "C" {

// Controller pak / Transfer Pak access: transfer_pak.cpp

// --- 64DD / PI io ------------------------------------------------------------
// LEOCmd* osLeoDiskInit(void): no disk drive
void osLeoDiskInit_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; ret(ctx, 0); }
// s32 osEPiWriteIo(OSPiHandle*, u32 devAddr, u32 data)
void osEPiWriteIo_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; ret(ctx, 0); }

// --- CPU / RDP registers (nothing to do on PC) ---------------------------------
void __osSetSR_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; (void)ctx; }
void __osSetCause_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; (void)ctx; }
void __osSetCount_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; (void)ctx; }
void __osSetCompare_recomp(uint8_t* rdram, recomp_context* ctx) { (void)rdram; (void)ctx; }
// void osDpGetCounters(u32* counters): 4 counters
void osDpGetCounters_recomp(uint8_t* rdram, recomp_context* ctx) {
    for (int i = 0; i < 4; i++) MEM_W(i * 4, ctx->r4) = 0;
}

}
