# Asset notices — Gen 1 HD rebuild

## HD Pokémon

`assets/battle/hd-pokemon/` contains sprite-sheet PNGs generated locally from the supplied **Pokémon HD 1–151** GIF pack with `tools/import_hd_pokemon.py`.

The generated package covers National Dex **#001–151 only** in this build. Kanto in Motion does not claim ownership of Pokémon-derived artwork. Anyone redistributing the artwork is responsible for having the necessary rights or permission.

## HD battle backgrounds

`assets/battle/backgrounds/hd/` contains the supplied 1920×950 HD battle-background set used by **HD BATTLE BACKGROUNDS**.

The current implementation uses complete sunrise/day/sunset/night variants where available and static scenes for caves/fixed locations.

## Trainer Card badges

The retained animated badge artwork is credited to **xpixelpriorx**:
https://www.deviantart.com/xpixelpriorx

Custom Trainer Card player/Gym Leader portraits are not included in this rebuild.

## Gen1 Modern UI assets

`assets/pixel_frame1.png`, `assets/pixel_frame2.png`, and `assets/pixel_frame3.png` come from the customized Gen1 Modern UI build used by this project.

Original project credit: **ArmstrongThomas**
https://github.com/ArmstrongThomas/gen1-modern-ui

## Poké Ball Colorfix

Integrated Poké Ball presentation fixes are credited to **keberos**:
https://github.com/keberos/pokeball-colorfix

## Shiny encounter assets

The build keeps:

- `assets/effects/shiny_sparkle.png`
- `assets/sfx/shiny.wav`

These are used only for KIM's one-shot shiny encounter cue. Kanto in Motion does not claim ownership of the supplied assets.

## Removed asset families

v1.4.1 does not ship the old generation-based Battle Art sprite folders, the old Gen 6/Battle Art arena pack, or custom Trainer Card player/Gym Leader portraits. The Gen 1 move-animation art/SFX have been restored from the scanner-remediated asset package.

## Trademark / affiliation notice

Pokémon and related characters, names, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.

## Restored move-animation assets

- `assets/animations/` — remediated Kanto Rework / Pokémon Essentials-style move effect art.
- `assets/sfx/` — remediated move SFX plus the retained KIM shiny cue.
- The two WAV false-positive byte signatures and all scanner similarity flags identified during remediation were addressed before reintegration.
