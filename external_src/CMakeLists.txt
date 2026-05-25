cmake_minimum_required(VERSION 3.20)
project(nam_max_externals CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(APPLE AND NOT CMAKE_OSX_ARCHITECTURES)
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "" FORCE)
endif()

# ─── Platform define (Max SDK convention) ─────────────────────────────
# The Max SDK headers branch on #ifdef MAC_VERSION / #ifdef WIN_VERSION —
# i.e. they test whether the macro is *defined*, not its value. We must
# define exactly ONE of them based on the host platform. Passing
# WIN_VERSION=0 on macOS would still satisfy #ifdef WIN_VERSION and pull
# in <malloc.h> / <windows.h>, which don't exist there.
if(APPLE)
    add_compile_definitions(MAC_VERSION)
elseif(WIN32)
    add_compile_definitions(WIN_VERSION)
endif()

# ─── Paths ────────────────────────────────────────────────────────────

set(MAX_SDK "${CMAKE_CURRENT_SOURCE_DIR}/max-sdk")
if(NOT EXISTS "${MAX_SDK}/source")
    message(FATAL_ERROR
        "max-sdk not found at ${MAX_SDK}. "
        "See external_src/thirdparty/README.md for submodule setup."
    )
endif()

set(MAX_INCLUDES "${MAX_SDK}/source/c74support/max-includes")
set(MSP_INCLUDES "${MAX_SDK}/source/c74support/msp-includes")

# Output .mxo bundles directly next to NAM.amxd so Max's default search (same
# directory as the patcher being loaded) resolves them. PLAN §3 originally
# specified m4l/externals/ but Max for Live does NOT auto-search a sub-dir of
# the .amxd's parent; the externals must be co-located.
set(EXTERNALS_OUT "${CMAKE_CURRENT_SOURCE_DIR}/../m4l")
file(MAKE_DIRECTORY "${EXTERNALS_OUT}")

# ─── Eigen vectorization escape hatch (PLAN.md §3) ────────────────────

option(NAM_DISABLE_EIGEN_VECTORIZE
    "Disable Eigen vectorization (escape hatch for alignment crashes inside Max allocator)"
    OFF)

# ─── NAM core thirdparty detection ────────────────────────────────────
# If the submodule has been fetched, wire it in for nam~. The other
# externals (namtone~, namgate_*) will get it in M6 when they need it.

set(NAM_CORE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/NeuralAmpModelerCore")
set(NAM_CORE_HEADER "${NAM_CORE_DIR}/NAM/dsp.h")
if(EXISTS "${NAM_CORE_HEADER}")
    set(NAM_CORE_AVAILABLE TRUE)
    message(STATUS "NAM core found at ${NAM_CORE_DIR} — enabling full nam~ inference")

    # Glob NAM core .cpp sources (inlined into the external rather than
    # building a separate static library, to keep the CMake surface minimal).
    file(GLOB_RECURSE NAM_CORE_SOURCES "${NAM_CORE_DIR}/NAM/*.cpp")

else()
    set(NAM_CORE_AVAILABLE FALSE)
    message(STATUS "NAM core NOT found — nam~ will build as passthrough fallback")
    set(NAM_CORE_SOURCES "")
endif()

# ─── Eigen detection ──────────────────────────────────────────────────
# Look first at the top-level thirdparty/eigen clone, then fall back to NAM
# core's bundled copy at Dependencies/eigen.

set(EIGEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/eigen")
if(EXISTS "${EIGEN_DIR}/Eigen/Dense")
    set(EIGEN_AVAILABLE TRUE)
    message(STATUS "Eigen found at ${EIGEN_DIR}")
elseif(NAM_CORE_AVAILABLE AND EXISTS "${NAM_CORE_DIR}/Dependencies/eigen/Eigen/Dense")
    set(EIGEN_DIR "${NAM_CORE_DIR}/Dependencies/eigen")
    set(EIGEN_AVAILABLE TRUE)
    message(STATUS "Eigen found (bundled in NAM core) at ${EIGEN_DIR}")
else()
    set(EIGEN_AVAILABLE FALSE)
    message(STATUS "Eigen NOT found — NAM core build will fail without Eigen headers")
    set(EIGEN_DIR "")
endif()

# ─── NAM plugin source detection (for tone stack only) ───────────────
# BasicNamToneStack is NOT shipped in NAM core — it only lives in the
# NeuralAmpModelerPlugin source tree. We vendor the plugin under thirdparty/
# and pull just ToneStack.{h,cpp} from it for namtone~. The plugin uses its
# own AudioDSPTools submodule at NeuralAmpModelerPlugin/AudioDSPTools/, which
# git submodule must have populated.

set(NAM_PLUGIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/NeuralAmpModelerPlugin")
set(NAM_PLUGIN_TONESTACK_H "${NAM_PLUGIN_DIR}/NeuralAmpModeler/ToneStack.h")
set(NAM_PLUGIN_ADT_DSP_H   "${NAM_PLUGIN_DIR}/AudioDSPTools/dsp/dsp.h")
if(EXISTS "${NAM_PLUGIN_TONESTACK_H}" AND EXISTS "${NAM_PLUGIN_ADT_DSP_H}")
    set(NAM_PLUGIN_TONESTACK_AVAILABLE TRUE)
    set(NAM_PLUGIN_TONESTACK_SOURCES
        "${NAM_PLUGIN_DIR}/NeuralAmpModeler/ToneStack.cpp"
        "${NAM_PLUGIN_DIR}/AudioDSPTools/dsp/RecursiveLinearFilter.cpp"
        "${NAM_PLUGIN_DIR}/AudioDSPTools/dsp/dsp.cpp"
    )
    message(STATUS "NAM plugin tone stack found at ${NAM_PLUGIN_DIR}/NeuralAmpModeler/ToneStack.h")
else()
    set(NAM_PLUGIN_TONESTACK_AVAILABLE FALSE)
    set(NAM_PLUGIN_TONESTACK_SOURCES "")
    message(STATUS "NAM plugin tone stack NOT found — namtone~ will build as passthrough stub")
endif()

# ─── AudioDSPTools detection (bundled inside NAM core) ────────────────
# NAM core's Dependencies/AudioDSPTools provides NoiseGate, ImpulseResponse,
# RecursiveLinearFilter, etc. These used to live under NAM/ directly but
# were factored out into a sub-library. namgate_trigger~ uses NoiseGate.

set(AUDIODSPTOOLS_DIR "")
set(AUDIODSPTOOLS_AVAILABLE FALSE)
set(AUDIODSPTOOLS_SOURCES "")
if(NAM_CORE_AVAILABLE AND EXISTS "${NAM_CORE_DIR}/Dependencies/AudioDSPTools/dsp/dsp.h")
    set(AUDIODSPTOOLS_DIR "${NAM_CORE_DIR}/Dependencies/AudioDSPTools")
    set(AUDIODSPTOOLS_AVAILABLE TRUE)
    # Only pick the sources we actually need for the noise gate. Globbing the
    # whole dsp/ folder pulls in ImpulseResponse / RecursiveLinearFilter /
    # wav.cpp, which depend on Eigen and stb_image and would force us to add
    # those include paths to namgate_trigger~ unnecessarily.
    set(AUDIODSPTOOLS_SOURCES
        "${AUDIODSPTOOLS_DIR}/dsp/dsp.cpp"
        "${AUDIODSPTOOLS_DIR}/dsp/NoiseGate.cpp"
    )
    message(STATUS "AudioDSPTools found at ${AUDIODSPTOOLS_DIR}")
endif()

# ─── nlohmann_json detection ──────────────────────────────────────────
# Top-level clone first; fall back to NAM core's bundled Dependencies/nlohmann.

set(JSON_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/nlohmann_json")
if(EXISTS "${JSON_DIR}/include/nlohmann/json.hpp" OR EXISTS "${JSON_DIR}/json.hpp")
    set(JSON_AVAILABLE TRUE)
    message(STATUS "nlohmann_json found at ${JSON_DIR}")
elseif(NAM_CORE_AVAILABLE AND EXISTS "${NAM_CORE_DIR}/Dependencies/nlohmann/json.hpp")
    # NAM core's headers do `#include "json.hpp"` (direct, not nested under
    # nlohmann/), so the include path must point at Dependencies/nlohmann/
    # rather than Dependencies/.
    set(JSON_DIR "${NAM_CORE_DIR}/Dependencies/nlohmann")
    set(JSON_AVAILABLE TRUE)
    message(STATUS "nlohmann_json found (bundled in NAM core) at ${JSON_DIR}")
else()
    set(JSON_AVAILABLE FALSE)
    message(STATUS "nlohmann_json NOT found — NAM core may fail to compile")
    set(JSON_DIR "")
endif()

# ─── Helper: define a Max external target ─────────────────────────────
#
# CMake disallows '~' as a character in target names (newer policy). Translate
# any tilde to '_tilde' for the internal target name, but keep OUTPUT_NAME set
# to the original symbol so the produced bundle is still `nam~.mxo` etc. —
# Max looks up externals by output filename, so as long as the .mxo lands with
# the right name, the patcher will resolve it.

function(add_max_external NAME SRC)
    string(REPLACE "~" "_tilde" TARGET_NAME "${NAME}")
    add_library(${TARGET_NAME} MODULE ${SRC})
    target_include_directories(${TARGET_NAME} PRIVATE
        "${MAX_INCLUDES}"
        "${MSP_INCLUDES}"
    )
    if(NAM_DISABLE_EIGEN_VECTORIZE)
        target_compile_definitions(${TARGET_NAME} PRIVATE
            EIGEN_MAX_ALIGN_BYTES=0
            EIGEN_DONT_VECTORIZE
        )
    endif()

    if(APPLE)
        set_target_properties(${TARGET_NAME} PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "mxo"
            OUTPUT_NAME "${NAME}"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
        )
        target_link_libraries(${TARGET_NAME} PRIVATE
            "-framework CoreFoundation"
        )
        target_link_options(${TARGET_NAME} PRIVATE
            "-Wl,-undefined,dynamic_lookup"
        )
    elseif(WIN32)
        set_target_properties(${TARGET_NAME} PROPERTIES
            SUFFIX ".mxe64"
            OUTPUT_NAME "${NAME}"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
        )
        target_link_libraries(${TARGET_NAME} PRIVATE
            "${MAX_INCLUDES}/x64/MaxAPI.lib"
            "${MSP_INCLUDES}/x64/MaxAudio.lib"
        )
    endif()
endfunction()

# ─── nam~ — with optional NAM core integration ────────────────────────
# When NAM_CORE_AVAILABLE, compile NAM core sources directly into the
# external (avoids a separate static lib and simplifies the build graph).

if(NAM_CORE_AVAILABLE)
    # Internal target name is nam_tilde (CMake disallows '~' in target names);
    # OUTPUT_NAME ensures the produced bundle is still nam~.mxo.
    add_library(nam_tilde MODULE "nam~.cpp" ${NAM_CORE_SOURCES})
    target_include_directories(nam_tilde PRIVATE
        "${MAX_INCLUDES}"
        "${MSP_INCLUDES}"
        "${NAM_CORE_DIR}"         # makes <NAM/dsp.h> resolvable
    )
    if(EIGEN_AVAILABLE)
        target_include_directories(nam_tilde PRIVATE "${EIGEN_DIR}")
    endif()
    if(JSON_AVAILABLE)
        if(EXISTS "${JSON_DIR}/include")
            target_include_directories(nam_tilde PRIVATE "${JSON_DIR}/include")
        else()
            target_include_directories(nam_tilde PRIVATE "${JSON_DIR}")
        endif()
    endif()
    target_compile_definitions(nam_tilde PRIVATE NAM_CORE_AVAILABLE=1)
    if(NAM_DISABLE_EIGEN_VECTORIZE)
        target_compile_definitions(nam_tilde PRIVATE
            EIGEN_MAX_ALIGN_BYTES=0
            EIGEN_DONT_VECTORIZE
        )
    endif()
    if(APPLE)
        set_target_properties(nam_tilde PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "mxo"
            OUTPUT_NAME "nam~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
        )
        target_link_libraries(nam_tilde PRIVATE
            "-framework CoreFoundation"
        )
        target_link_options(nam_tilde PRIVATE
            "-Wl,-undefined,dynamic_lookup"
        )
    elseif(WIN32)
        set_target_properties(nam_tilde PROPERTIES
            SUFFIX ".mxe64"
            OUTPUT_NAME "nam~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
        )
        target_link_libraries(nam_tilde PRIVATE
            "${MAX_INCLUDES}/x64/MaxAPI.lib"
            "${MSP_INCLUDES}/x64/MaxAudio.lib"
        )
    endif()
else()
    # Passthrough fallback: no NAM core sources, NAM_CORE_AVAILABLE defaults to 0
    # via the __has_include guard in nam~.cpp.
    add_max_external("nam~" "nam~.cpp")
endif()

# ─── HISSTools thirdparty detection ───────────────────────────────────
# If the submodule has been fetched, wire it in for irconv~.
# The convolution engine lives entirely in HIRT_Multichannel_Convolution/ and
# HISSTools_FFT/ — we glob all .cpp files from those two directories.

set(HISSTOOLS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/HISSTools_Library")
set(HISSTOOLS_HEADER "${HISSTOOLS_DIR}/HIRT_Multichannel_Convolution/MonoConvolve.h")
if(EXISTS "${HISSTOOLS_HEADER}")
    set(HISSTOOLS_AVAILABLE TRUE)
    message(STATUS "HISSTools found at ${HISSTOOLS_DIR} — enabling irconv~ partitioned convolution")

    # HIRT_Multichannel_Convolution has the partitioned-convolution engine
    # (MonoConvolve, PartitionedConvolve, TimeDomainConvolve, Convolver,
    # NToMonoConvolve). HISSTools_FFT/HISSTools_FFT.cpp provides the FFT
    # wrappers (hisstools_rfft, hisstools_rifft, hisstools_create_setup,
    # hisstools_destroy_setup) that the convolution engine calls into —
    # leaving them out produces a .mxo with undefined symbols and Live
    # rejects it at load with a "bundle '' couldn't be loaded" error.
    file(GLOB HISSTOOLS_CONV_SOURCES
        "${HISSTOOLS_DIR}/HIRT_Multichannel_Convolution/*.cpp"
        "${HISSTOOLS_DIR}/HISSTools_FFT/*.cpp"
    )
else()
    set(HISSTOOLS_AVAILABLE FALSE)
    message(STATUS "HISSTools NOT found — irconv~ will build as passthrough fallback")
    set(HISSTOOLS_CONV_SOURCES "")
endif()

# ─── irconv~ — with optional HISSTools integration ────────────────────

if(HISSTOOLS_AVAILABLE)
    # Internal target irconv_tilde; output bundle is irconv~.mxo.
    add_library(irconv_tilde MODULE "irconv~.cpp" ${HISSTOOLS_CONV_SOURCES})
    target_include_directories(irconv_tilde PRIVATE
        "${MAX_INCLUDES}"
        "${MSP_INCLUDES}"
        "${HISSTOOLS_DIR}"          # makes HIRT_Multichannel_Convolution/<...>.h resolvable
    )
    target_compile_definitions(irconv_tilde PRIVATE
        HISSTOOLS_AVAILABLE=1
    )
    if(APPLE)
        set_target_properties(irconv_tilde PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "mxo"
            OUTPUT_NAME "irconv~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
        )
        target_link_libraries(irconv_tilde PRIVATE
            "-framework CoreFoundation"
            "-framework Accelerate"
        )
        target_link_options(irconv_tilde PRIVATE
            "-Wl,-undefined,dynamic_lookup"
        )
    elseif(WIN32)
        set_target_properties(irconv_tilde PROPERTIES
            SUFFIX ".mxe64"
            OUTPUT_NAME "irconv~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
        )
        target_link_libraries(irconv_tilde PRIVATE
            "${MAX_INCLUDES}/x64/MaxAPI.lib"
            "${MSP_INCLUDES}/x64/MaxAudio.lib"
        )
    endif()
else()
    # Passthrough fallback: no HISSTools sources, HISSTOOLS_AVAILABLE defaults to 0
    # via the __has_include guard in irconv~.cpp.
    add_max_external("irconv~" "irconv~.cpp")
endif()

# ─── M6 externals — NAM core integration where applicable ─────────────
#
# namgate_gain~ does not depend on NAM core (it just multiplies an envelope
# signal into the audio path), so it always uses the basic add_max_external.
#
# namtone~ wraps dsp::tone_stack::BasicNamToneStack; namgate_trigger~ wraps
# dsp::noise_gate::Trigger. When NAM_CORE_AVAILABLE, compile NAM core sources
# into them and add the include paths, mirroring the pattern used for nam~.
# When unavailable, fall back to the basic target so the build still produces
# a passthrough external (the .cpp files have __has_include guards).

function(add_nam_core_external NAME SRC)
    if(NAM_CORE_AVAILABLE)
        # Internal target derives from NAME with '~' → '_tilde'; OUTPUT_NAME
        # keeps the produced bundle named with the tilde.
        string(REPLACE "~" "_tilde" TARGET_NAME "${NAME}")
        add_library(${TARGET_NAME} MODULE ${SRC} ${NAM_CORE_SOURCES})
        target_include_directories(${TARGET_NAME} PRIVATE
            "${MAX_INCLUDES}"
            "${MSP_INCLUDES}"
            "${NAM_CORE_DIR}"
        )
        if(EIGEN_AVAILABLE)
            target_include_directories(${TARGET_NAME} PRIVATE "${EIGEN_DIR}")
        endif()
        if(JSON_AVAILABLE)
            if(EXISTS "${JSON_DIR}/include")
                target_include_directories(${TARGET_NAME} PRIVATE "${JSON_DIR}/include")
            else()
                target_include_directories(${TARGET_NAME} PRIVATE "${JSON_DIR}")
            endif()
        endif()
        target_compile_definitions(${TARGET_NAME} PRIVATE NAM_CORE_AVAILABLE=1)
        if(NAM_DISABLE_EIGEN_VECTORIZE)
            target_compile_definitions(${TARGET_NAME} PRIVATE
                EIGEN_MAX_ALIGN_BYTES=0
                EIGEN_DONT_VECTORIZE
            )
        endif()
        if(APPLE)
            set_target_properties(${TARGET_NAME} PROPERTIES
                BUNDLE TRUE
                BUNDLE_EXTENSION "mxo"
                OUTPUT_NAME "${NAME}"
                LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
                XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
            )
            target_link_libraries(${TARGET_NAME} PRIVATE
                "-framework CoreFoundation"
            )
            target_link_options(${TARGET_NAME} PRIVATE
                "-Wl,-undefined,dynamic_lookup"
            )
        elseif(WIN32)
            set_target_properties(${TARGET_NAME} PROPERTIES
                SUFFIX ".mxe64"
                OUTPUT_NAME "${NAME}"
                LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
                RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            )
            target_link_libraries(${TARGET_NAME} PRIVATE
                "${MAX_INCLUDES}/x64/MaxAPI.lib"
                "${MSP_INCLUDES}/x64/MaxAudio.lib"
            )
        endif()
    else()
        add_max_external(${NAME} ${SRC})
    endif()
endfunction()

# namtone~ — wraps dsp::tone_stack::BasicNamToneStack from
# NeuralAmpModelerPlugin/NeuralAmpModeler/ToneStack.{h,cpp}. The tone-stack
# class needs dsp::DSP (AudioDSPTools/dsp/dsp.cpp) and the Peaking / LowShelf /
# HighShelf biquad family (RecursiveLinearFilter.cpp). Includes resolve via:
#   #include <NeuralAmpModeler/ToneStack.h>   (with NAM_PLUGIN_DIR on -I)
# ToneStack.h has a relative include of "../AudioDSPTools/dsp/dsp.h", so the
# plugin's AudioDSPTools submodule must be populated (git submodule update).
if(NAM_PLUGIN_TONESTACK_AVAILABLE)
    add_library(namtone_tilde MODULE namtone~.cpp ${NAM_PLUGIN_TONESTACK_SOURCES})
    target_include_directories(namtone_tilde PRIVATE
        "${MAX_INCLUDES}"
        "${MSP_INCLUDES}"
        "${NAM_PLUGIN_DIR}"
    )
    target_compile_definitions(namtone_tilde PRIVATE NAM_TONESTACK_AVAILABLE=1)
    if(APPLE)
        set_target_properties(namtone_tilde PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "mxo"
            OUTPUT_NAME "namtone~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
        )
        target_link_libraries(namtone_tilde PRIVATE
            "-framework CoreFoundation"
        )
        target_link_options(namtone_tilde PRIVATE
            "-Wl,-undefined,dynamic_lookup"
        )
    elseif(WIN32)
        set_target_properties(namtone_tilde PROPERTIES
            SUFFIX ".mxe64"
            OUTPUT_NAME "namtone~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
        )
        target_link_libraries(namtone_tilde PRIVATE
            "${MAX_INCLUDES}/x64/MaxAPI.lib"
            "${MSP_INCLUDES}/x64/MaxAudio.lib"
        )
    endif()
else()
    add_max_external("namtone~" namtone~.cpp)
endif()

# namgate_trigger~ — uses dsp::noise_gate::Trigger from AudioDSPTools (NAM
# core's bundled sub-library at Dependencies/AudioDSPTools/dsp/NoiseGate.h).
# When AudioDSPTools is present, compile NoiseGate.cpp + dsp.cpp into the
# external and add Dependencies/AudioDSPTools to the include path.
if(AUDIODSPTOOLS_AVAILABLE)
    add_library(namgate_trigger_tilde MODULE namgate_trigger~.cpp ${AUDIODSPTOOLS_SOURCES})
    target_include_directories(namgate_trigger_tilde PRIVATE
        "${MAX_INCLUDES}"
        "${MSP_INCLUDES}"
        "${AUDIODSPTOOLS_DIR}"
    )
    target_compile_definitions(namgate_trigger_tilde PRIVATE NAM_CORE_AVAILABLE=1)
    if(APPLE)
        set_target_properties(namgate_trigger_tilde PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "mxo"
            OUTPUT_NAME "namgate_trigger~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            XCODE_ATTRIBUTE_MACH_O_TYPE "mh_bundle"
        )
        target_link_libraries(namgate_trigger_tilde PRIVATE
            "-framework CoreFoundation"
        )
        target_link_options(namgate_trigger_tilde PRIVATE
            "-Wl,-undefined,dynamic_lookup"
        )
    elseif(WIN32)
        set_target_properties(namgate_trigger_tilde PROPERTIES
            SUFFIX ".mxe64"
            OUTPUT_NAME "namgate_trigger~"
            LIBRARY_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
            RUNTIME_OUTPUT_DIRECTORY "${EXTERNALS_OUT}"
        )
        target_link_libraries(namgate_trigger_tilde PRIVATE
            "${MAX_INCLUDES}/x64/MaxAPI.lib"
            "${MSP_INCLUDES}/x64/MaxAudio.lib"
        )
    endif()
else()
    add_max_external("namgate_trigger~" namgate_trigger~.cpp)
endif()

add_max_external(namgate_gain~           namgate_gain~.cpp)
