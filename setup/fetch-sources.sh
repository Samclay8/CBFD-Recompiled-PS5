#!/usr/bin/env bash
# Downloads every source the PS5 build needs, at pinned commits, next to this repository. Run as the build user
# inside the Linux distro, from a clone of this repository. Safe to re-run: existing checkouts are kept.
#
#   src-upstream/    Conker's Bad Fur Day: Recompiled V0.1.6 and its submodules
#   radv/            Mihawk's PS5_Vulkan, PS5_Mesa (that one commit only) and PS5_PayloadSDK
#                    (./build.sh radv builds them; the PacBrew sysroot is fetched by tools/setup-pacbrew.sh)
#
# On the author's machine the RADV port was already built for the DK64 port (~/dk64-ps5/radv): it's moved here
# instead of being fetched and built again, with a link left behind.
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
dk64="$HOME/dk64-ps5"

cbfd_url=https://github.com/sciaschi/CBFD-Recompiled
cbfd_commit=85d8c3bc617e2d8311f5f978b832006797bc8ac7    # tag V0.1.6

clone() { # url dir commit
    if [[ ! -d $2/.git ]]; then
        echo "clone: $1"
        git clone -q "$1" "$2"
    fi
    git -C "$2" checkout -q "$3"
}

# One commit only, no history (for Mesa, whose full history is about 650 MB).
fetch_commit() { # url dir commit
    if [[ ! -d $2/.git ]]; then
        echo "fetch: $1 @ ${3:0:12}"
        git init -q "$2"
        git -C "$2" remote add origin "$1"
    fi
    git -C "$2" cat-file -e "$3^{commit}" 2>/dev/null || git -C "$2" fetch -q --depth 1 origin "$3"
    git -C "$2" checkout -q "$3"
}

move_built() { # from to
    if [[ -d $1 && ! -L $1 && ! -e $2 ]]; then
        mkdir -p "$(dirname "$2")"
        mv "$1" "$2"
        ln -s "$2" "$1"
        echo "moved: $1 -> $2 (link left behind)"
    fi
}
move_built "$dk64/radv" "$root/radv"
move_built "$dk64/.deps/pacbrew" "$root/.deps/pacbrew"

# Mihawk's RADV port at the commits Marice's and the DK64 port pin (folder names as PS5_Vulkan's scripts expect).
mkdir -p "$root/radv"
clone https://github.com/mihawk-99/PS5_Vulkan "$root/radv/mihawk-vulkan-review" 5b5e4fc2d80fdb67a4f61ba9e6a8a424026bb8a5
clone https://github.com/mihawk-99/PS5_PayloadSDK "$root/radv/mihawk-sdk-review" b83202be73e930050e00de0f1b4d9ec46c0391bf
fetch_commit https://github.com/mihawk-99/PS5_Mesa "$root/radv/mihawk-mesa-review" 7b59ef27c1b09b9671bc4153c41940c3155c3af2
ln -sfn mihawk-sdk-review "$root/radv/PS5_PayloadSDK"
ln -sfn mihawk-mesa-review "$root/radv/PS5_Mesa"

# CBFD-Recompiled and its submodules (the decompilation's tools too: its own build.sh --decomp uses them).
clone "$cbfd_url" "$root/src-upstream" "$cbfd_commit"
git -C "$root/src-upstream" submodule update -q --init --recursive --jobs 8

echo "--- sources ready"
for d in src-upstream radv/mihawk-vulkan-review radv/mihawk-sdk-review radv/mihawk-mesa-review; do
    printf '%-34s %s\n' "$d" "$(git -C "$root/$d" log -1 --format='%h %cs %s' | cut -c1-70)"
done
git -C "$root/src-upstream" submodule status | cut -c1-100
echo "next: tools/setup-source.sh <your ROM>"
