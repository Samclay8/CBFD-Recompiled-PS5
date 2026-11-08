#!/usr/bin/env bash
# Writes the PS5 changes in src-upstream to patches/: conker.patch for CBFD-Recompiled's own tree (tracked
# files) and one patch per changed submodule, named by its path with "/" as "__". Submodule patches are against
# the submodule with CBFD-Recompiled's own recomp/*.patch applied (committed as its HEAD by tools/setup-source.sh).
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
src="$root/src-upstream"
mkdir -p "$root/patches"
rm -f "$root"/patches/*.patch
git -C "$src" diff --ignore-submodules=all > "$root/patches/conker.patch"
# Tracked files only, as for the top level: build output (the recompiler's build/) stays out.
# A new file goes in after `git add -N` on it.
while read -r path; do
    # Not the decompilation's tools (conker/tools/*: splat, asm-processor...): the PS5 build doesn't use them,
    # and their checkout shows line-ending changes that aren't edits.
    [[ $path == conker/* ]] && continue
    diff=$(git -C "$src/$path" diff --binary --ignore-submodules=all HEAD)
    [[ -z $diff ]] || printf '%s\n' "$diff" > "$root/patches/${path//\//__}.patch"
done < <(git -C "$src" submodule foreach --quiet --recursive 'echo "$displaypath"')
[[ -s $root/patches/conker.patch ]] || rm "$root/patches/conker.patch"
ls -la "$root/patches"
