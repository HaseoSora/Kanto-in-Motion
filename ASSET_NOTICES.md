# Asset notices

Kanto in Motion v1.3.3 is packaged in two variants.

## No Pokémon Assets package

`Kanto-in-Motion-v1.3.3-No-Pokemon-Assets.zip` excludes locally imported/generated Pokémon front/back/title artwork and the generated sprite metadata that directly depends on those payloads.

Excluded from that package:

- `assets/battle/front-animated/`
- `assets/battle/back-animated/`
- `assets/title/`
- `data/animated_menu_sprites_gen2.lua` through `data/animated_menu_sprites_gen5.lua`
- `data/animated_battle_sprites_gen2_shiny.lua` through `data/animated_battle_sprites_gen5_shiny.lua`
- `data/animated_battle_backs_gen3.lua`
- `data/title_player_red.lua`

The no-assets package keeps KIM's source code, Modern UI assets, integrated KRS battle backgrounds, integrated move-animation effects/audio, trainer presentation assets, shiny encounter cue, metadata that is not itself Pokémon artwork, and the local import workflow.

Players can populate compatible local animated assets with `tools/import_assets.py` or their established local sprite-import workflow.

## Full Assets package

`Kanto-in-Motion-v1.3.3-Full-Assets.zip` contains the animated Pokémon/title payloads present in the maintainer's working release build.

Redistribution of third-party or Pokémon-derived artwork is separate from Kanto in Motion's own source-code permissions. Anyone redistributing the Full Assets package is responsible for ensuring they have the necessary rights or permission for included artwork.

## KRS battle backgrounds

`assets/battle/backgrounds/krs/` contains the integrated Kanto Rework Suite battle-background set used by **ARENA FILL = KRS**.

Credit: **Faendra**  
https://github.com/Faendra/kanto-rework-suite

## Battle trainer selector assets

`assets/battle/player-trainers/` contains static PLAYER TRAINER choices. `assets/battle/player-trainers-animated/` contains the supplied five-frame Battle Art player-trainer atlases, and `assets/battle/player-trainers-frames/` contains generated first-frame helpers used when global ANIMATION is OFF.

Credit for the Battle Art integration lineage: **absol89**  
https://github.com/absol89/DramaticShapeVoxelMod

Kanto in Motion does not claim ownership of those trainer images.

## Integrated Modern UI assets

`assets/pixel_frame1.png`, `assets/pixel_frame2.png`, and `assets/pixel_frame3.png` come from the customized Gen1 Modern UI build used by this project.

Original project credit: **ArmstrongThomas**  
https://github.com/ArmstrongThomas/gen1-modern-ui

## Trainer Card presentation assets

The animated earned-badge artwork under the Trainer Card presentation is credited to **xpixelpriorx**:

https://www.deviantart.com/xpixelpriorx

Kanto in Motion does not claim ownership of this artwork.

## Shiny encounter presentation assets

v1.3.3 includes:

- `assets/effects/shiny_sparkle.png`
- `assets/sfx/shiny.wav`

These supplied assets are used only for the one-shot shiny encounter sparkle/audio cue. Kanto in Motion does not claim ownership of them.

## Trademark / affiliation notice

Pokémon and related characters, names, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
