# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow the title's `contentVersion` in
`sce_sys/param.json`, and each release is tagged with it.

## [01.000.000] - 2026-11-09

First public release: Conker's Bad Fur Day: Recompiled V0.1.6 as a native PS5 title.

### Added
- Native title `PPSA64065`, "Conker's Bad Fur Day", rendering with RT64 through Vulkan on Mihawk's RADV port,
  output at 3840x2160 and interpolated to 60 fps.
- The game starts straight away: the ROM is imported from the title folder on the first start; settings, saves and
  mods are kept there. Without a usable ROM, a screen says where to put it, over the home screen picture with the
  logo fading in; Exit is selected only after a first press.
- The touchpad opens the menu, made for the console: PlayStation button prompts, Framerate as Original (30) or 60,
  and no PC-only options (window, mouse and gyro, keyboard, rumble motor and style); texture packs are switched in
  the Mods menu.
- Mods put in order with the controller (Triangle picks the selected one up, the D-pad moves it, Triangle puts it
  down) in place of dragging with a mouse, with a note under the list: where texture packs replace the same
  picture, the one higher in the list is used.
- Performance Overlay option (Graphics tab), in place of the PC version's Show FPS.
- Skip Cutscenes setting (General tab): Off (the default), Intro Only or All. Conker's Bad Fur Day: Recompiled's
  Skip Intro and Skip Any Cutscene mods, built in; either mod, if installed and on, does its own work instead.
- Texture packs and code mods from `mods/`. Old-format GLideN64 packs (such as Nikachu's AI Upscale) load after
  conversion with `tools/gliden64_to_rt64.py`, matched by their textures' CRCs.
- Home screen icon, background and start-up splash.
- `conker.log` in the title folder with the start-up steps, errors and crash reports; the previous session's log is
  kept as `conker.prev.log`.

### Changed
- The pause menu's background is the picture as it was, sharp and across the whole screen, without the game's
  blur: the blur's N64-resolution 4:3 copy, zoomed up to fill the screen, jumped in a frame after pausing.
