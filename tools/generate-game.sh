#!/usr/bin/env bash
# Generates Conker's recompiled game code from the user's ROM, as CBFD-Recompiled's build.sh does it:
#   1. copy the ROM to conker/baserom.us.z64 and check it (recomp/unpack_rom.py)
#   2. build its N64Recomp, RSPRecomp and RecompModTool for this machine (tools/N64Recomp, patched)
#   3. run recomp/recompile.py: RecompiledFuncs/ (the game, its TLB pages and the audio microcode)
#   tools/generate-game.sh "/mnt/conker/rom/Conker's Bad Fur Day (USA).z64"
# Nothing generated here is ever published: it is code derived from the ROM.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
rom=${1:?usage: tools/generate-game.sh <US Conker ROM .z64>}
expected_sha1=4cbadd3c4e0729dec46af64ad018050eada4f47a

actual_sha1=$(sha1sum "$rom" | cut -d' ' -f1)
[[ $actual_sha1 == "$expected_sha1" ]] || {
    echo "generate-game.sh: $rom is not the US ROM (sha1 $actual_sha1)" >&2; exit 2; }

cd "$src"
cp "$rom" conker/baserom.us.z64
python3 -c "import sys; sys.path.insert(0, 'recomp'); import unpack_rom; unpack_rom.unpack(open('conker/baserom.us.z64', 'rb').read())"

if [[ ! -f tools/N64Recomp/build/build.ninja ]]; then
    cmake -S tools/N64Recomp -B tools/N64Recomp/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ >/dev/null
fi
cmake --build tools/N64Recomp/build --target N64RecompCLI RSPRecomp RecompModTool

python3 recomp/recompile.py
echo "generate-game.sh: $(ls RecompiledFuncs | wc -l) files in RecompiledFuncs/, $(du -sh RecompiledFuncs | cut -f1)"
