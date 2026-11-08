#!/usr/bin/env bash
# Assembles the title folder dist/PPSA64065 from the build: eboot, home screen files, the system libc module and
# CBFD-Recompiled's assets (fonts, icons, controller database). No ROM: the player's own dump goes in by hand.
# The folder is then copied to the Windows project folder (/mnt/conker/dist) for Sam to copy to the PS5.
#   tools/package.sh
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
title=PPSA64065
build="$root/build-ps5/conker"
src="$root/src-upstream"
radv="$root/radv/mihawk-vulkan-review"
app="$root/dist/$title"

rm -rf -- "$app"
mkdir -p "$app/sce_sys" "$app/sce_module"
cp "$build/ConkerRecomp" "$app/eboot.bin"
cp "$root/sce_sys/param.json" "$app/sce_sys/"
# Home screen icon (512x512), made by tools/make-art.py when there is art; without it, the launcher's thumbnail.
if [[ -f $root/build-art/icon0.png ]]; then
    cp "$root/build-art/icon0.png" "$app/sce_sys/icon0.png"
else
    python3 -I - "$src/host/assets/thumbnail.png" "$app/sce_sys/icon0.png" <<'PY'
import sys
from PIL import Image
Image.open(sys.argv[1]).convert("RGB").resize((512, 512), Image.LANCZOS).save(sys.argv[2], optimize=True)
PY
fi
# Home screen background (pic0) and start-up splash (pic1), when made (tools/make-art.py, tools/make-backgrounds.py).
if [[ -f $root/sce_sys/pic0.dds && -f $root/sce_sys/pic1.dds ]]; then
    cp "$root"/sce_sys/{pic0.dds,pic1.dds} "$app/sce_sys/"
fi
cp "$radv/runtime/libc.prx" "$app/sce_module/libc.prx"
# RecompFrontend reads its assets from <program path>/assets, /app0 on the PS5 (CBFD's controller database is
# among them, assets/controllerdb.txt).
cp -r "$src/host/assets" "$app/assets"
# The ROM screen's picture and logo (tools/make-art.py; frontend.cpp fades the logo in over the picture).
for art in rom-screen.png rom-logo.png; do
    if [[ -f $root/build-art/$art ]]; then
        cp "$root/build-art/$art" "$app/assets/"
    fi
done
# The licences: the title is a GPL-3.0 combined work (LICENSES.txt lists its parts and carries CBFD-Recompiled's
# MIT notice).
cp "$root/LICENSE" "$app/LICENSE-GPL-3.0.txt"
cp "$root/LICENSES.txt" "$app/LICENSES.txt"

# Never ship anything derived from a ROM other than the compiled game code itself.
if find "$app" -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' | grep -q .; then
    echo "package.sh: a ROM file ended up in $app" >&2; exit 2
fi
echo "package.sh: $app ($(du -sh "$app" | cut -f1))"

if [[ -d /mnt/conker/dist ]]; then
    rm -rf -- "/mnt/conker/dist/$title"
    cp -r "$app" "/mnt/conker/dist/$title"
    echo "package.sh: copied to the project folder: dist/$title"
fi
