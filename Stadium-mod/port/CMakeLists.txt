# Pokémon Stadium native PC port (host program).
# Game code: build/stadium1/RecompiledFuncs (N64Recomp output) + build/stadium1/rsp (RSPRecomp).
# Runtime: tools/N64ModernRuntime (matches our N64Recomp), renderer: RT64 (from tools/Zelda64Recomp/lib/rt64).
#
#   cmake -S port -B port/build -G "Visual Studio 18 2026" -A x64 -T ClangCL
#   cmake --build port/build --config Release --target Stadium1
cmake_minimum_required(VERSION 3.20)
project(StadiumPort LANGUAGES C CXX)
set(CMAKE_C_STANDARD 17)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-everything")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-everything")
endif()
if (WIN32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
    add_compile_definitions(NOMINMAX)
endif()
if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
    cmake_policy(SET CMP0135 NEW)
endif()

# Release with debug info (symbols for the crash handler's stack traces)
add_compile_options($<$<CONFIG:Release>:/Zi>)
add_link_options($<$<CONFIG:Release>:/DEBUG>)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(MOD_ROOT ${CMAKE_SOURCE_DIR}/..)
set(RUNTIME ${MOD_ROOT}/tools/N64ModernRuntime)
set(RT64_DIR ${MOD_ROOT}/tools/Zelda64Recomp/lib/rt64)

set(RT64_STATIC TRUE)
add_compile_definitions(HLSL_CPU)
add_subdirectory(${RT64_DIR} ${CMAKE_BINARY_DIR}/rt64)
target_include_directories(rt64 PRIVATE ${CMAKE_BINARY_DIR}/rt64/src)

add_subdirectory(${RUNTIME} ${CMAKE_BINARY_DIR}/N64ModernRuntime)

# SDL2 (window, audio, controllers)
include(FetchContent)
set(SDL2_VERSION "2.30.3")
FetchContent_Declare(sdl2
    URL https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/SDL2-devel-${SDL2_VERSION}-VC.zip)
FetchContent_MakeAvailable(sdl2)

# One game = one RecompiledFuncs library + one exe.
function(add_stadium_game NAME GAME_DIR GAME_DEFINE)
    add_library(${NAME}Funcs STATIC)
    target_compile_options(${NAME}Funcs PRIVATE -fno-strict-aliasing -Wno-unused-variable -Wno-implicit-function-declaration)
    target_include_directories(${NAME}Funcs PRIVATE
        ${RUNTIME}/ultramodern/include ${RUNTIME}/librecomp/include ${RUNTIME}/N64Recomp/include)
    file(GLOB FUNC_SOURCES ${MOD_ROOT}/build/${GAME_DIR}/RecompiledFuncs/*.c ${MOD_ROOT}/build/${GAME_DIR}/RecompiledFuncs/lookup.cpp)
    target_sources(${NAME}Funcs PRIVATE ${FUNC_SOURCES})

    add_executable(${NAME}
        ${CMAKE_SOURCE_DIR}/src/main.cpp
        ${CMAKE_SOURCE_DIR}/src/render.cpp
        ${CMAKE_SOURCE_DIR}/src/input.cpp
        ${CMAKE_SOURCE_DIR}/src/audio.cpp
        ${CMAKE_SOURCE_DIR}/src/register_overlays.cpp
        ${CMAKE_SOURCE_DIR}/src/fragments.cpp
        ${CMAKE_SOURCE_DIR}/src/ultra_stubs.cpp
        ${CMAKE_SOURCE_DIR}/src/transfer_pak.cpp
        ${CMAKE_SOURCE_DIR}/src/boot.cpp
        ${CMAKE_SOURCE_DIR}/src/pvp.cpp
        ${CMAKE_SOURCE_DIR}/src/kidsclub.cpp
        ${CMAKE_SOURCE_DIR}/src/crash.cpp
        ${CMAKE_SOURCE_DIR}/src/trace.cpp
        ${MOD_ROOT}/build/${GAME_DIR}/rsp/aspMain.cpp
        ${MOD_ROOT}/build/${GAME_DIR}/rsp/njpgdspMain.cpp)
    target_compile_definitions(${NAME} PRIVATE ${GAME_DEFINE}
        RECOMP_FUNCS_DIR="${MOD_ROOT}/build/${GAME_DIR}/RecompiledFuncs")
    target_include_directories(${NAME} PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${MOD_ROOT}/build/${GAME_DIR}/RecompiledFuncs
        ${RUNTIME}/N64Recomp/include
        ${RT64_DIR}/src ${RT64_DIR}/src/rhi ${RT64_DIR}/src/render ${RT64_DIR}/src/contrib
        ${RT64_DIR}/src/contrib/hlslpp/include ${RT64_DIR}/src/contrib/dxc/inc
        ${sdl2_SOURCE_DIR}/include)
    target_compile_options(${NAME} PRIVATE -march=nehalem -fno-strict-aliasing -fms-extensions)
    target_link_directories(${NAME} PRIVATE ${sdl2_SOURCE_DIR}/lib/x64)
    target_link_libraries(${NAME} PRIVATE ${NAME}Funcs librecomp ultramodern rt64 SDL2 Winmm.lib)
    set_target_properties(${NAME} PROPERTIES LINK_FLAGS "/SUBSYSTEM:CONSOLE")
    add_custom_command(TARGET ${NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${sdl2_SOURCE_DIR}/lib/x64/SDL2.dll"
            "${RT64_DIR}/src/contrib/dxc/bin/x64/dxil.dll"
            "${RT64_DIR}/src/contrib/dxc/bin/x64/dxcompiler.dll"
            $<TARGET_FILE_DIR:${NAME}>)
endfunction()

add_stadium_game(Stadium1 stadium1 STADIUM1)
