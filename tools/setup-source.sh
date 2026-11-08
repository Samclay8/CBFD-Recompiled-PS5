#!/usr/bin/env bash
# Prepares src-upstream/ for the PS5 build, once the sources are downloaded (/mnt/conker/setup/fetch-sources.sh:
# CBFD-Recompiled V0.1.6 and its submodules):
#   1. applies CBFD-Recompiled's own patches to its tools (recomp/*.patch, as its build.sh does) and commits each
#      as the submodule's HEAD, so this port's patches are against upstream as it builds itself
#   2. applies this port's patches/: conker.patch to CBFD-Recompiled's own tree, and <submodule path>.patch
#      (slashes as "__") to each submodule
#   3. given the ROM, generates the recompiled game code from it (tools/generate-game.sh)
#   tools/setup-source.sh "/mnt/conker/rom/Conker's Bad Fur Day (USA).z64"
#   tools/setup-source.sh            patches only, no game code
# Changes are made in src-upstream/ and written back to patches/ by tools/make-patches.sh.
# After this, never run CBFD-Recompiled's own build.sh in src-upstream: it resets submodules whose HEAD moved.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
rom=${1:-}

[[ -d $src/.git ]] || { echo "setup-source.sh: no $src; run setup/fetch-sources.sh first" >&2; exit 2; }

# CBFD-Recompiled's patch for each tool (its build.sh's apply_patch list).
upstream_patches=(
    "tools/N64Recomp recomp/n64recomp.patch"
    "tools/N64ModernRuntime recomp/n64modernruntime.patch"
    "tools/rt64 recomp/rt64.patch"
    "tools/RecompFrontend recomp/recompfrontend.patch"
    "tools/RecompFrontend/recompui/lib/RmlUi recomp/rmlui.patch"
)

if [[ ! -f $src/.port-setup ]]; then
    for entry in "${upstream_patches[@]}"; do
        read -r dir patch <<< "$entry"
        # Already applied (as CBFD-Recompiled's build.sh leaves it, or committed by an earlier run): commit as is.
        if ! git -C "$src/$dir" apply --reverse --check "$src/$patch" 2>/dev/null; then
            git -C "$src/$dir" apply --whitespace=nowarn "$src/$patch"
        fi
        if ! git -C "$src/$dir" diff --quiet HEAD || [[ -n $(git -C "$src/$dir" ls-files --others --exclude-standard) ]]; then
            # Only the files the patch names: build output in the submodule stays out.
            mapfile -t files < <(git -C "$src/$dir" apply --numstat "$src/$patch" | cut -f3)
            git -C "$src/$dir" add -A -- "${files[@]}"
            git -C "$src/$dir" -c user.name=conker-ps5 -c user.email=conker-ps5@localhost \
                commit -q -m "CBFD-Recompiled's $patch"
        fi
        echo "upstream: $patch in $dir (HEAD)"
    done

    for patch in "$root"/patches/*.patch; do
        [[ -e $patch ]] || continue
        name=$(basename "$patch" .patch)
        if [[ $name == conker ]]; then dir=$src; else dir="$src/${name//__//}"; fi
        git -C "$dir" apply --whitespace=nowarn "$patch"
        echo "applied $name"
    done
    touch "$src/.port-setup"
fi

[[ -z $rom ]] || "$root/tools/generate-game.sh" "$rom"
echo "setup-source.sh: sources ready; next: ./build.sh configure, ./build.sh"
