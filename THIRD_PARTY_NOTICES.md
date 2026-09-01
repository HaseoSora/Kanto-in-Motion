# Third-party notices

Kanto in Motion v1.3.1 includes, adapts, or redistributes portions of third-party community work. Attribution does not imply endorsement and does not transfer ownership of the original work to Kanto in Motion.

## Battle Art / DramaticShapeVoxelMod

**Author / project credit:** absol89  
https://github.com/absol89/DramaticShapeVoxelMod

Kanto in Motion's standalone Gen 1 Battle System adapts selected Battle Art 2D presentation behavior, including battle-stage/HUD geometry, source-canvas composition concepts, trainer presentation assets/behavior, and compatibility approaches used by the maintainer's Battle Art integration lineage.

Kanto in Motion deliberately does **not** include Battle Art's voxel overworld renderer, 3D world mesh, 3D battle camera, voxel geometry, or depth-of-field pipeline.

The optional static and animated player-trainer assets under `assets/battle/player-trainers*` were carried over from the Battle Art package supplied for this integration. Kanto in Motion does not claim ownership of those trainer images.

## Kanto Rework Battle Anims / Kanto Rework Suite backgrounds

**Author / project credit:** Faendra  
https://github.com/Faendra/kanto-rework-suite

Kanto in Motion integrates the Kanto Rework battle-animation lineage used for the Gen 1 move-animation bridge and the KRS battle-background/routing data used by the v1.3.1 KRS arena choice.

The integrated animation player has been adapted for KIM's standalone fullscreen 2D battle layout, mobile composition, player/enemy targeting, and KIM sprite geometry. Kanto Rework Suite itself is not required at runtime for these integrated components.

## Gen 9 Move Animation Project

**Project lead / resource credit:** KRLW890 and contributors  
https://www.eeveeexpo.com/resources/1480/

`data/gen1_anims.lua` is generated from the `PkmnAnimations.rxdata` supplied through the Kanto Rework Battle Animations integration. That data identifies the **Gen 9 Move Animation Project** as its upstream animation source and retains the Pokémon Essentials 512×384 animation design space.

The Gen 9 project is itself a successor to earlier community animation work. Consult the upstream resource for its complete contributor and source credits when redistributing derived animation data/assets.

## Pokéball Colorfix

**Author / project credit:** keberos  
https://github.com/keberos/pokeball-colorfix

Kanto in Motion integrates the Gen 1 Poké Ball palette/presentation fixes needed by its standalone battle path. KIM additionally contains its own fullscreen/mobile target-position compatibility so the native catch animation remains visible and lands on KIM's fullscreen enemy battler.

The standalone Pokéball Colorfix mod is not bundled as a separate mod and should not be enabled on top of KIM's integrated copy.

## Gen1 Modern UI

**Original project / author credit:** ArmstrongThomas  
https://github.com/ArmstrongThomas/gen1-modern-ui

Kanto in Motion integrates the customized Gen1 Modern UI-based build used by this project. The integrated copy was adapted to run under Kanto in Motion's existing `animated_menu_pokemon` identity, consume KIM's animated sprite provider, share battle ownership with KIM's standalone Battle System, and support the project's desktop/mobile presentation changes.

Credit for the Gen1 Modern UI foundation belongs to ArmstrongThomas. Confirm applicable upstream permissions/licensing before redistributing integrated source/assets.

## Trainer Card animated badge artwork

The animated badge artwork included with Kanto in Motion's Trainer Card presentation is credited to **xpixelpriorx**.

Creator page: https://www.deviantart.com/xpixelpriorx

Kanto in Motion does not claim ownership of this third-party artwork.

## Pokémon-derived animated artwork

The **Full Assets** package contains locally imported/generated Pokémon battle/title artwork used by the maintainer's working release build. Source notes are retained in the applicable asset folders, including Pokémon Database and Bulbagarden archive references where used by the import workflow.

The **No Pokémon Assets** package removes those locally imported Pokémon front/back/title payloads. Kanto in Motion does not claim ownership of Pokémon-derived artwork.

## Shiny encounter presentation assets

v1.3.1 includes the supplied:

- `assets/effects/shiny_sparkle.png`
- `assets/sfx/shiny.wav`

These are used only for the one-shot shiny encounter cue. Kanto in Motion does not claim ownership of these supplied assets.

## Compatibility-only external mods

Kanto in Motion contains compatibility code for several external mods but does **not** copy, patch, or redistribute their packages. This includes Quality of Life, Typed Move Colors, Overworld Wild Spawns / Wilds of Kanto, Gen2 Clean UI, Useful Bag, and other mods using KIM's public compatibility interfaces.
