// Prints the exception and a symbolized stack to stderr (and crash.txt) on a crash.
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <DbgHelp.h>
#include <TlHelp32.h>
#include <cstdio>
#include <cstdlib>
#include <mutex>

#pragma comment(lib, "dbghelp.lib")

static void print_line(FILE* out, const char* fmt, DWORD64 addr) {
    HANDLE proc = GetCurrentProcess();
    char buf[sizeof(SYMBOL_INFO) + 256] = {};
    SYMBOL_INFO* sym = reinterpret_cast<SYMBOL_INFO*>(buf);
    sym->SizeOfStruct = sizeof(SYMBOL_INFO);
    sym->MaxNameLen = 255;
    DWORD64 disp = 0;
    IMAGEHLP_LINE64 line{ sizeof(IMAGEHLP_LINE64) };
    DWORD ldisp = 0;
    const char* name = SymFromAddr(proc, addr, &disp, sym) ? sym->Name : "?";
    if (SymGetLineFromAddr64(proc, addr, &ldisp, &line)) {
        fprintf(out, fmt, addr, name, (unsigned long long)disp);
        fprintf(out, "   %s:%lu\n", line.FileName, line.LineNumber);
    } else {
        fprintf(out, fmt, addr, name, (unsigned long long)disp);
        fprintf(out, "\n");
    }
}

static void dump_rdram();

static LONG WINAPI on_crash(EXCEPTION_POINTERS* ep) {
    static std::mutex m;
    std::lock_guard lock(m);
    HANDLE proc = GetCurrentProcess();
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
    SymInitialize(proc, nullptr, TRUE);

    FILE* files[2] = { stderr, nullptr };
    fopen_s(&files[1], "crash.txt", "w");
    for (FILE* out : files) {
        if (!out) continue;
        auto* er = ep->ExceptionRecord;
        fprintf(out, "\n=== crash: exception 0x%08lX at %p, thread %lu", er->ExceptionCode, er->ExceptionAddress, GetCurrentThreadId());
        if (er->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && er->NumberParameters >= 2) {
            fprintf(out, " (%s 0x%llX)", er->ExceptionInformation[0] ? "write" : "read", (unsigned long long)er->ExceptionInformation[1]);
        }
        fprintf(out, "\n");

        CONTEXT ctx = *ep->ContextRecord;
        STACKFRAME64 frame{};
        frame.AddrPC.Offset = ctx.Rip;    frame.AddrPC.Mode = AddrModeFlat;
        frame.AddrFrame.Offset = ctx.Rbp; frame.AddrFrame.Mode = AddrModeFlat;
        frame.AddrStack.Offset = ctx.Rsp; frame.AddrStack.Mode = AddrModeFlat;
        for (int i = 0; i < 40; i++) {
            if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, proc, GetCurrentThread(), &frame, &ctx, nullptr,
                             SymFunctionTableAccess64, SymGetModuleBase64, nullptr) || frame.AddrPC.Offset == 0) break;
            print_line(out, "  %016llX %s+0x%llX", frame.AddrPC.Offset);
        }
        fflush(out);
    }
    if (files[1]) fclose(files[1]);
    dump_rdram();
    return EXCEPTION_EXECUTE_HANDLER;
}

// Set by main.cpp's on_init callback: the game's RDRAM (for rdram.bin dumps).
extern uint8_t* g_rdram;
uint8_t* g_rdram = nullptr;

// RDRAM 0x80000000-0x80800000 in N64 byte order -> rdram.bin
static void dump_rdram() {
    if (g_rdram) fprintf(stderr, "[crash] rdram base %p\n", g_rdram);
    if (!g_rdram) return;
    FILE* out = nullptr;
    fopen_s(&out, "rdram.bin", "wb");
    if (!out) return;
    static uint8_t buf[0x800000];
    for (size_t i = 0; i < sizeof(buf); i++) buf[i] = g_rdram[i ^ 3];
    fwrite(buf, 1, sizeof(buf), out);
    fclose(out);
}

// Stack of every thread in the process (debugging hangs): STADIUM_DUMP_AT=<seconds>
// writes threads.txt (and rdram.bin) that many seconds after start.
extern "C" void stadium_trace_flush();

static void dump_all_threads() {
    stadium_trace_flush();
    dump_rdram();
    HANDLE proc = GetCurrentProcess();
    SymSetOptions(SYMOPT_LOAD_LINES | SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS);
    SymInitialize(proc, nullptr, TRUE);
    FILE* out = nullptr;
    fopen_s(&out, "threads.txt", "w");
    if (!out) return;
    DWORD self = GetCurrentThreadId();
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    THREADENTRY32 te{ sizeof(te) };
    for (BOOL ok = Thread32First(snap, &te); ok; ok = Thread32Next(snap, &te)) {
        if (te.th32OwnerProcessID != GetCurrentProcessId() || te.th32ThreadID == self) continue;
        HANDLE th = OpenThread(THREAD_ALL_ACCESS, FALSE, te.th32ThreadID);
        if (!th) continue;
        SuspendThread(th);
        CONTEXT ctx{};
        ctx.ContextFlags = CONTEXT_FULL;
        if (GetThreadContext(th, &ctx)) {
            fprintf(out, "=== thread %lu\n", te.th32ThreadID);
            STACKFRAME64 frame{};
            frame.AddrPC.Offset = ctx.Rip;    frame.AddrPC.Mode = AddrModeFlat;
            frame.AddrFrame.Offset = ctx.Rbp; frame.AddrFrame.Mode = AddrModeFlat;
            frame.AddrStack.Offset = ctx.Rsp; frame.AddrStack.Mode = AddrModeFlat;
            for (int i = 0; i < 30; i++) {
                if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, proc, th, &frame, &ctx, nullptr,
                                 SymFunctionTableAccess64, SymGetModuleBase64, nullptr) || frame.AddrPC.Offset == 0) break;
                print_line(out, "  %016llX %s+0x%llX", frame.AddrPC.Offset);
            }
        }
        ResumeThread(th);
        CloseHandle(th);
    }
    CloseHandle(snap);
    fclose(out);
}

void install_crash_handler() {
    SetUnhandledExceptionFilter(on_crash);
    if (const char* at = getenv("STADIUM_DUMP_AT")) {
        int secs = atoi(at);
        CreateThread(nullptr, 0, [](LPVOID p) -> DWORD {
            Sleep((DWORD)(uintptr_t)p * 1000);
            dump_all_threads();
            return 0;
        }, (LPVOID)(uintptr_t)secs, 0, nullptr);
    }
}
