# Kanto in Motion v1.4.0

**Kanto in Motion** is an animated Pokémon presentation and battle overhaul for Gen1Recomp. v1.4.0 focuses on **Pokémon Red / Blue / Yellow** and introduces a new Gen 1 HD battle presentation for Pokémon #001–151.

The internal mod ID remains `animated_menu_pokemon`, so compatible Kanto in Motion settings can carry forward when upgrading.

## v1.4.0 highlights

- Added **HD animated Pokémon #001–151** with front/back, normal/shiny, and available male/female variants.
- Added new **1920×950 HD battle backgrounds** with location-aware sunrise, day, sunset, and night variants plus static cave/interior scenes.
- Added **HD BATTLE BACKGROUNDS** as a live Battle setting.
- Restored KIM's integrated **move animations for all 165 Gen 1 moves**, including fullscreen background/foreground effects and move SFX.
- Added configurable **Pokémon ground shadows** with quality and opacity controls.
- Updated the Red/Blue title screen for the HD Pokémon artwork and added **TITLE PKMN SIZE**.
- Added **3D PKMN SIZE** for compatible staged 3D battles, with **100%** as KIM's calibrated neutral reference.
- Added **POTATO CAMERA** and **POTATO MOBILE ENEMY SIZE** controls for PotatoVoxel.
- Updated desktop/mobile **Battle Art 1.11.x** and **PotatoVoxel** compatibility for HD Pokémon, move animations, trainer handoff, Modern Battle UI, HUD/QOL alignment, shiny presentation, and 3D-BTL ON/OFF behavior.
- Corrected Quality of Life **EXP/already-caught overlay alignment**, including the fixed name-independent caught-icon position used by the current battle paths.
- Retains KIM's configurable shiny odds, one-shot shiny sparkle/audio, Poké Ball presentation fixes, animated player trainers, Modern UI, and animated Trainer Card badges.

## HD animated Pokémon

- HD animated battle sprites for **National Dex #001–151**.
- Front and back animations.
- Normal and shiny variants.
- Available male/female variants are supported when present in the source artwork.
- The packaged sprite sheets are generated at **60% of the supplied GIF dimensions** for KIM's accepted in-game scale and a smaller package footprint.
- `PLAYER PKMN SIZE = 100%` is the calibrated neutral player size for the HD artwork.
- `3D PKMN SIZE = 100%` is the calibrated neutral staged-battle reference for Battle Art and desktop PotatoVoxel.

## HD battle backgrounds

KIM includes a new **1920×950** Gen 1 battle-background set.

- Outdoor and selected authored scenes can switch between **sunrise / day / sunset / night** using Gen1Recomp's live game time.
- Caves and fixed interiors use static authored scenes where time-of-day changes do not make sense.
- The background is selected when battle begins and stays fixed for that battle.
- Turning **HD BATTLE BACKGROUNDS = OFF** keeps KIM's other battle features active while yielding arena art to the game or another compatible scene owner.

## Gen 1 UI behavior

Kanto in Motion includes the customized **Gen1 Modern UI** build used by this project.

**INTEGRATED MODERN UI** is available on Gen 1:

- New/default install: **ON**.
- The saved preference is remembered across launches.
- Switching ON or OFF takes effect live; a restart is not required for the ownership handoff.
- OFF yields the relevant presentation surfaces back to vanilla Gen1Recomp.

The integrated UI covers supported responsive menus, Party, Summary, Pokédex, Bag, PC, Trainer Card, dialogue, battle Items/Pokémon flow, nickname flow, level-up stats, and the centralized Mod Menu.

## Kanto in Motion settings

Open **KANTO IN MOTION** from the mod settings screen. Gen 1 also exposes a **BATTLE → OPEN** submenu.

### Main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's animated Pokémon presentation on supported menu/status surfaces. |
| **INTEGRATED MODERN UI** | ON / OFF | ON | Chooses KIM's integrated Gen 1 Modern UI or vanilla UI. The saved choice is remembered across launches. |
| **ANIMATION** | ON / OFF | ON | Enables animated sprite playback. Supported animated player-trainer intros also follow this setting; OFF holds them on their first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's animated Red/Blue title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Selects KIM's animated Red title trainer or Gen1Recomp's original title-screen trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly the title-screen Pokémon changes. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales only the cycling HD Pokémon on the Red/Blue title screen. Red and the custom logo are unchanged. |

## KANTO IN MOTION → BATTLE settings

The Battle submenu is **Gen 1 only**.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | **ON** | Master switch for KIM-owned battle scene/HUD presentation. OFF yields those layers to vanilla or another battle mod. Compatible external 3D scenes can still honor the separate **BATTLE SPRITES** and **MOVE ANIMATIONS** choices. |
| **MODERN BATTLE UI** | ON / OFF | ON | Controls KIM's battle command/move/dialog layer. OFF keeps KIM's other enabled battle features available while yielding the lower battle UI/dialog to vanilla or another compatible UI. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's HD animated battle Pokémon. Compatible external scenes such as PotatoVoxel can honor this independently of the main KIM battle scene. |
| **MOVE ANIMATIONS** | ON / OFF | ON | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animation set for all **165 Gen 1 moves**. Battle Art and PotatoVoxel can use these animations in compatible 3D scenes. OFF falls back to the active battle provider's native move animation path. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls KIM's ground-contact shadow quality. LOW uses the lightest single-ellipse path; higher settings add progressively softer feather layers. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts Pokémon shadow darkness without changing Pokémon size or position. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves Gen 1 DVs untouched; other choices roll KIM's shiny DV pattern. Stored DVs keep a captured Pokémon shiny. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's new 1920×950 location-aware HD backgrounds. Timed scenes use sunrise/day/sunset/night variants; caves and fixed interiors remain static. OFF yields arena art while keeping the rest of KIM available. |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / ASH FRONT / MISTY FRONT / BROCK FRONT / BULMA FRONT / GARY FRONT | RED | Chooses the player trainer shown during battle intro/send-out. **ANIMATION** controls five-frame trainer atlases. DEFAULT / ROM yields to the game or another trainer provider. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the player-side Pokémon. **100%** is KIM's calibrated neutral HD player size. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | 100% | Scales Pokémon in compatible staged 3D battles. **100%** is KIM's calibrated neutral reference for Battle Art and desktop PotatoVoxel. **PLAYER PKMN SIZE** still fine-tunes only the player afterward. PotatoVoxel mobile keeps its separately calibrated mobile sizing. |
| **POTATO CAMERA** | 100%–150% in 5% steps | 115% | PotatoVoxel staged battles only. Higher values show more of the arena with a farther/wider camera without modifying PotatoVoxel. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | 85% | Android/iOS PotatoVoxel only. Fine-tunes KIM's enemy Pokémon size while preserving the separately calibrated mobile player path. |
| **HUD SCALE** | OG / SCALED | OG | Selects the HP/status HUD scale preset. OG follows the normal window-fit rung; SCALED uses one rung smaller. |
| **HUD SIZE** | 60%–100% in 5% steps | 100% | Fine-tunes KIM's enemy/player HP/status HUD size after the OG/SCALED preset. Compatible EXP/caught overlays follow the same geometry. |
| **HUD OPACITY** | 25%–100% in 5% steps | 100% | Adjusts the opacity of KIM's HP/status HUD, including its party Poké Ball layer. It does not fade the lower command/message panel. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Adjusts the lower command/move/message panel footprint while keeping it bottom-anchored. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Fades only the lower battle panel background. Frame, borders, dividers, text, and selected controls remain fully opaque. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales only Modern UI's lower battle command, move, and message text. HUD and panel sizing remain independent. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move grid. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy beside the move list. OFF gives move names the full panel width. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses the HP/status glyph treatment. INVERTED uses light glyphs with a dark pixel shadow while preserving green/yellow/red HP gauge colors. |

The Battle submenu also includes **RESET TO DEFAULT**, which restores the Battle settings to their defined defaults.

## Battle Art 1.11.x compatibility

Battle Art is supported as an **optional external 3D-BTL scene owner** and is not bundled with Kanto in Motion.

- KIM can provide its HD animated Pokémon, integrated move animations, trainer selection, shiny presentation, HUD/QOL geometry, and Modern lower battle UI while Battle Art owns the staged 3D world/camera/effects.
- `3D PKMN SIZE = 100%` is KIM's neutral staged-battle reference.
- `PLAYER PKMN SIZE` remains a separate player-only adjustment.
- Desktop and mobile use platform-specific compatibility paths to keep HUD, party Poké Balls, full-screen move BG/FG effects, EXP/caught overlays, and lower UI aligned.

## PotatoVoxel compatibility

PotatoVoxel is supported as an **optional external 3D battle scene** and is not bundled with Kanto in Motion.

- KIM can provide HD animated Pokémon, integrated move animations, trainer presentation, shiny effects, HUD/QOL geometry, and Modern lower battle UI while PotatoVoxel retains its 3D arena/camera.
- **POTATO CAMERA** controls the KIM-side camera pullback without modifying PotatoVoxel.
- Desktop uses `3D PKMN SIZE = 100%` as the neutral staged reference.
- Android/iOS keeps separately calibrated mobile sizing, with **POTATO MOBILE ENEMY SIZE** available for enemy fine-tuning.

## Other compatibility

### Typed Move Colors

When the external **Typed Move Colors** mod is installed, KIM's Modern move tiles can reuse that mod's effectiveness presentation while leaving the external mod unmodified. KIM prevents duplicate move-menu presentation on compatible battle paths.

### Quality of Life

KIM does not modify Quality of Life. Its battle EXP and already-caught overlays remain source-owned. KIM supplies the geometry needed to keep those overlays aligned with KIM, Battle Art, and PotatoVoxel battle HUD paths on desktop/mobile.

### Useful Bag

KIM keeps Useful Bag's inventory behavior while preventing its duplicate standalone bag presenter from overlapping KIM's integrated Modern UI.

### Spanish translation

KIM does not modify the external Spanish translation mod. Modern UI identifies supported Gen 1 menu flows by stable structure where possible so translated labels/dialogue remain translation-owned.

### Advanced Box System

KIM does not modify Advanced Box System. On supported screens KIM can provide animated Pokémon presentation while Advanced Box System continues to own storage operations, list state, and input.

### Weather FX

KIM does not modify Weather FX. Its custom settings screens can be presented through KIM's Modern UI while Weather FX continues to own its values, callbacks, help text, and live overworld weather behavior.

## Credits and acknowledgements

Kanto in Motion includes or adapts work from several community projects. Credit for those original projects belongs to their authors.

### Animated Pokémon battle sprites

**Source:** Battle Sprites Reloded  
**Creator:** JDChaos  
**Original thread:** https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/  
Used for front/back, normal/shiny, and available male/female variants.

### Kanto Rework Battle Anims / Kanto Rework Suite — Faendra

https://github.com/Faendra/kanto-rework-suite  
KIM integrates the Kanto Rework battle-animation lineage used by the current Gen 1 move-animation bridge.

### Pokéball Colorfix — keberos

https://github.com/keberos/pokeball-colorfix  
KIM integrates the Gen 1 Poké Ball palette/presentation fixes required by its battle path.

### Gen1 Modern UI — ArmstrongThomas

https://github.com/ArmstrongThomas/gen1-modern-ui  
KIM includes a heavily customized integrated build derived from the Gen1 Modern UI foundation.

### Animated Trainer Card badges — xpixelpriorx

https://www.deviantart.com/xpixelpriorx  
The animated earned-badge artwork used by KIM's Trainer Card presentation is credited to xpixelpriorx.

### Gen 9 Move Animation Project — KRLW890 and contributors

https://www.eeveeexpo.com/resources/1480/  
The Pokémon Essentials animation data used by the integrated Kanto Rework animation conversion identifies this project as an upstream source. See `THIRD_PARTY_NOTICES.md` for details.

Kanto in Motion does **not** claim ownership of third-party or Pokémon-derived artwork. See `THIRD_PARTY_NOTICES.md` and `ASSET_NOTICES.md` before redistributing included assets.

## External compatibility mods are not bundled

The following integrations are compatibility-only. Their packages are **not copied, modified, or redistributed by Kanto in Motion**:

- Battle Art
- PotatoVoxel
- Quality of Life
- Typed Move Colors
- HGSS Sprites
- Overworld Wild Spawns / Wilds of Kanto
- Useful Bag
- Spanish translation (`recomp-spanish`)
- Advanced Box System
- Weather FX
- other UI/battle mods using KIM's compatibility API

## Compatibility

- Gen1Recomp mod API: **2**
- Games: **Gen 1**
- Carts: **Red / Blue / Yellow**
- Declared engine range: **>= 0.2.24 and < 0.3.0**
- Integrated Gen1 Modern UI: customized project build
- Battle Art / PotatoVoxel: optional external compatibility; not required at runtime
- Link-relevant gameplay data: unchanged (`affects_link: false`)

Because Kanto in Motion uses `engine_internals` for UI/battle integration, large Gen1Recomp internal refactors may require a KIM update even when the manifest range still accepts the engine.

## Installation

1. Download `Kanto-in-Motion-v1.4.0.zip`.
2. Import the ZIP through Gen1Recomp's Mods interface.
3. Enable Kanto in Motion.
4. Do not enable a separate Gen1 Modern UI / Gen1 Clean UI at the same time as KIM's integrated Gen 1 UI unless you intentionally disable/yield the overlapping presenter.

### Upgrading from an earlier Kanto in Motion release

Replace the previous Kanto in Motion package with the complete v1.4.0 package. The internal ID remains `animated_menu_pokemon`, so compatible saved KIM options can carry forward.

If upgrading from the older **Animated Menu Pokémon** package, remove/disable that package first because it shares the same internal mod ID.

## Repository layout

- `main.lua` — options, animated sprite provider, battle presentation, compatibility hooks, title animation, and UI bootstrap.
- `data/hd_pokemon_sprites.lua` — generated metadata for the HD Gen 1 sprite sheets.
- `data/hd_battle_backgrounds.lua` — location/time background routing and authored battler anchors.
- `assets/battle/hd-pokemon/` — HD Gen 1 Pokémon sprite sheets.
- `assets/battle/backgrounds/hd/` — 1920×950 HD battle backgrounds.
- `lib/modern_ui_integrated*.lua` — customized Gen1 Modern UI integration and platform presenters.
- `lib/integrated_krba.lua` / `lib/krba_essentials_player*.lua` — integrated Gen 1 move-animation bridge.
- `data/gen1_anims.lua` — Gen 1 move-animation data.
- `lib/integrated_pokeball_colorfix.lua` / `lib/pokeball_target_fix.lua` — integrated Poké Ball presentation and catch-target compatibility.
- `lib/shiny_encounter_fx*.lua` — one-shot shiny sparkle/audio presentation.
- `lib/potato_voxel_compat.lua` — PotatoVoxel compatibility layer.
- `tools/import_hd_pokemon.py` — HD GIF → sprite-sheet importer.
- `THIRD_PARTY_NOTICES.md` / `ASSET_NOTICES.md` — attribution and redistribution notes.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.** AI assistance was used for code generation and modification, debugging, documentation, and release preparation. The project maintainer directs the project, chooses which changes to keep, and performs the in-game testing used to determine what is released.

## Trademark / affiliation notice

Pokémon and related names, characters, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
