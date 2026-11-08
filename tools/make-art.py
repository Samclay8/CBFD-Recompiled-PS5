#!/usr/bin/env python3
"""Makes the title's art from Sam's background picture (art/background-source.webp in the project folder):

  background.png   3840x2160, the home screen's background (sce_sys/pic0.dds)
  splash.png       3840x2160, the splash while the title starts (sce_sys/pic1.dds): the picture, with the logo
                   over the open sky at the top middle when one is given
  rom-screen.png   1920x1080, the ROM screen's background (assets/rom-screen.png, frontend.cpp)
  icon0.png        512x512, the home screen icon (sce_sys/icon0.png), when a logo is given: a full-height square
                   from the picture's left (the trench, the bee and the poo, Sam's choice of four, 2026-11-08)
                   with the logo across its top

The picture is cropped to 16:9 from the middle and scaled up. tools/make-backgrounds.py then turns background.png
and splash.png into the console's DDS files.

Needs Pillow (the DK64 tree's venv has it: ~/dk64-ps5/.venv/bin/python):
    python tools/make-art.py <background picture> <out dir> [<logo png, transparent>]
"""
import sys
from pathlib import Path

from PIL import Image

WIDTH, HEIGHT = 3840, 2160
# The logo's box on the splash, as fractions of the picture: centred, in the top band of open sky.
LOGO_MAX_WIDTH = 0.42
LOGO_MAX_HEIGHT = 0.30
LOGO_TOP = 0.05
# The icon: a square as tall as the picture, centred this far across it, with the logo across its top.
ICON = 512
ICON_CENTRE_X = 0.22
ICON_LOGO_WIDTH = 0.94
ICON_LOGO_TOP = 0.04


def crop_16_9(image: Image.Image) -> Image.Image:
    w, h = image.size
    if w * 9 > h * 16:      # too wide: trim the sides
        new_w = h * 16 // 9
        left = (w - new_w) // 2
        return image.crop((left, 0, left + new_w, h))
    new_h = w * 9 // 16     # too tall: trim top and bottom
    top = (h - new_h) // 2
    return image.crop((0, top, w, top + new_h))


def main() -> None:
    if len(sys.argv) not in (3, 4):
        raise SystemExit("usage: make-art.py <background picture> <out dir> [<logo png>]")
    source, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)

    picture = crop_16_9(Image.open(source).convert("RGB"))
    print(f"{source.name}: {picture.size[0]}x{picture.size[1]} after the 16:9 crop")
    background = picture.resize((WIDTH, HEIGHT), Image.LANCZOS)
    background.save(out / "background.png", optimize=True)

    names = ["background.png", "splash.png", "rom-screen.png"]
    splash = background.convert("RGBA")
    if len(sys.argv) == 4:
        source_logo = Image.open(sys.argv[3]).convert("RGBA")
        source_logo = source_logo.crop(source_logo.getchannel("A").getbbox())
        scale = min(WIDTH * LOGO_MAX_WIDTH / source_logo.size[0], HEIGHT * LOGO_MAX_HEIGHT / source_logo.size[1])
        logo = source_logo.resize((round(source_logo.size[0] * scale), round(source_logo.size[1] * scale)), Image.LANCZOS)
        splash.alpha_composite(logo, ((WIDTH - logo.size[0]) // 2, round(HEIGHT * LOGO_TOP)))

        left = min(max(round(WIDTH * ICON_CENTRE_X - HEIGHT / 2), 0), WIDTH - HEIGHT)
        icon = background.crop((left, 0, left + HEIGHT, HEIGHT)).resize((ICON, ICON), Image.LANCZOS).convert("RGBA")
        scale = ICON * ICON_LOGO_WIDTH / source_logo.size[0]
        logo = source_logo.resize((round(source_logo.size[0] * scale), round(source_logo.size[1] * scale)), Image.LANCZOS)
        icon.alpha_composite(logo, ((ICON - logo.size[0]) // 2, round(ICON * ICON_LOGO_TOP)))
        icon.convert("RGB").save(out / "icon0.png", optimize=True)
        names.append("icon0.png")

        # The logo alone, transparent, for the ROM screen (assets/rom-logo.png), which fades it in over its picture
        # (frontend.cpp). At most 1700 px wide: about the width it's shown at on the 4K screen.
        rom_logo = source_logo
        if rom_logo.size[0] > 1700:
            rom_logo = rom_logo.resize((1700, round(rom_logo.size[1] * 1700 / rom_logo.size[0])), Image.LANCZOS)
        rom_logo.save(out / "rom-logo.png", optimize=True)
        names.append("rom-logo.png")
    splash.convert("RGB").save(out / "splash.png", optimize=True)

    background.resize((1920, 1080), Image.LANCZOS).save(out / "rom-screen.png", optimize=True)
    for name in names:
        print(f"wrote {out / name}")


if __name__ == "__main__":
    main()
