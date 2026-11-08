#!/usr/bin/env bash
# Builds Conker's Bad Fur Day: Recompiled for the PS5, directly in the conker-ps5 WSL distro (tools/run.sh, no
# container). Run tools/setup-source.sh first (patches, and the game code generated from the ROM).
#   ./build.sh radv        RADV, the payload SDK fork and the title converter (once; built already in this distro)
#   ./build.sh configure   host tools + CMake configure (build-ps5/conker)
#   ./build.sh [build]     compile and link eboot.bin (after configure)
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# The PacBrew sysroot (SDL2, FreeType...): downloaded into .deps/ by tools/setup-pacbrew.sh unless PACBREW is set.
: "${PACBREW:=$("$root/tools/setup-pacbrew.sh")}"
export PACBREW
sdk="$root/radv/mihawk-vulkan-review/.deps/native/ps5-payload-sdk"
env="export PS5_PAYLOAD_SDK=$sdk RADV_ROOT=$root/radv/mihawk-vulkan-review PACBREW=$PACBREW PS5_HOST_TOOLS=$root/build-host/file_to_c;"
case ${1:-build} in
radv)
    WORKDIR="$root/radv/mihawk-vulkan-review" "$root/tools/run.sh" "
        bash tools/setup-native-dependencies.sh && bash tools/build-radv.sh release &&
        n=tooling/native && z=.deps/native/zlib/root/usr && mkdir -p build/host &&
        clang++-18 -std=c++20 -O2 -I \$z/include \$n/native_app_builder.cpp \$n/self_container.cpp \
            \$n/elf_object.cpp \$n/sce_module_writer.cpp \$z/lib/libz.a -o build/host/ps5-native-tool &&
        bash tools/rebuild-libc.sh" ;;
configure)
    # file_to_c runs on this machine during the build (shader blobs, fonts). CBFD-Recompiled's CMake project is
    # host/ in its tree, and needs the recompiled game code (RecompiledFuncs/) there already.
    "$root/tools/run.sh" "$env
        cmake -S src-upstream/tools/rt64/src/tools/file_to_c -B build-host/file_to_c -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null &&
        cmake --build build-host/file_to_c >/dev/null &&
        cmake -S src-upstream/host -B build-ps5/conker -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCMAKE_TOOLCHAIN_FILE=$root/cmake/ps5-toolchain.cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5" ;;
build)
    "$root/tools/run.sh" "$env cmake --build build-ps5/conker --target ConkerRecomp -- -k 0" ;;
*)
    echo "usage: $0 [radv|configure|build]" >&2; exit 2 ;;
esac
