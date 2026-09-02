# Kanto in Motion v1.3.2

**Kanto in Motion** is an animated Pokémon presentation and battle overhaul for Gen1Recomp. It supports **Pokémon Red / Blue / Yellow** and retains the Gen 2 presentation support introduced in v1.2.0 for **Gold / Silver / Crystal**.

The internal mod ID remains `animated_menu_pokemon`, so existing Kanto in Motion settings can carry forward when upgrading.

## v1.3.2 compatibility & stability update

v1.3.2 is the corrected stable release built from the final v7 test tree. It fixes the clean-install packaging problem found after v1.3.1 and preserves the PC/mobile Battle Art 1.10.0 behavior that was re-tested separately.

- **Full Assets is self-contained again.** The animated Pokémon front/back/title payloads and their generated metadata are included in the Full Assets ZIP instead of depending on files left behind by an older layered test install.
- **PC + 3D-BTL:** keeps the confirmed player-back/world-card presentation and restores Battle Art's mouse camera steering.
- **Mobile + 3D-BTL:** reverts to the confirmed v20/v25 stage-only ownership model rather than the experimental v3-v6 camera/ownership overrides. Battle Art owns the 3D stage, KIM owns its HUD/sprite compatibility layers, Modern UI owns the lower battle panel, and touch controls remain engine-owned.
- **Animated 3D battlers are anchored** to stable frame metrics so idle/move animation frames do not make the whole Pokémon sway around the battlefield.
- Restores the stable mobile move-animation handoff confirmed after testing moves such as Growl, Leer, and Peck.
- Keeps the previously confirmed **Typed Move Colors + Modern UI**, **Quality of Life EXP**, party Poké Ball/HUD, mobile Battle Art MODS MENU, PC FIGHT-menu clipping, and KIM-owned shiny/Wilds compatibility fixes.
- Battle Art 1.10.0, Quality of Life, Typed Move Colors, and Wilds remain external/unmodified packages.
- Compatibility work remains targeted at Gen1Recomp 0.2.x with the declared `>=0.2.24 <0.3.0` manifest range.

All v1.3.0/v1.3.1 features remain included, including the standalone Gen 1 Battle System, KRS backgrounds, integrated Kanto Rework animations, Pokéball Colorfix behavior, animated battle sprites/trainers, configurable shiny odds, Gen 2 presentation support, and the open compatibility registry.

## Animated Pokémon features

- Animated **Gen 2, Gen 3, Gen 4, or Gen 5** front-sprite support.
- **Gen 5** is selected by default.
- Animated Pokémon on supported Summary/Status, Pokédex, Party, evolution, title, and Gen 1 battle surfaces.
- Red/Blue title pool includes all **151 Kanto Pokémon** and avoids recently displayed species when possible.
- Adjustable title cycle speed: **NORMAL**, **SLOW**, or **SLOWER**.
- Optional animated Red title trainer: forward → reverse → pause → repeat.
- Missing artwork fails open to a supported fallback instead of breaking the screen.

## Gen 1 UI behavior

Kanto in Motion includes the customized **Gen1 Modern UI** build used by this project.

**INTEGRATED MODERN UI** is available on Gen 1:

- New/default install: **ON**.
- The saved preference is remembered across launches.
- Switching ON or OFF now takes effect live on both desktop and mobile; a game restart is not required for the ownership handoff.
- OFF yields the relevant presentation surfaces back to vanilla Gen1Recomp.

The integrated UI covers supported responsive menus, Party, Summary, Pokédex, Bag, PC, Trainer Card, dialogue, battle Items/Pokémon flow, nickname flow, level-up stats, and the centralized Mod Menu.

## Gen 2 UI behavior

On Gen 2, Kanto in Motion's bundled Modern UI remains intentionally **OFF**. Gen 2 uses its own UI/state implementation.

Kanto in Motion supplies animated Pokémon presentation while yielding interface ownership to:

- Gen1Recomp's native Gen 2 UI, or
- the original/unmodified **Gen2 Clean UI 0.4.1** when installed.

Animated Status/Summary has been confirmed in real Gen 2 testing. Party, Pokédex, and Evolution compatibility bridges are also included.

## Kanto in Motion settings

Open **KANTO IN MOTION** from the mod settings screen. Gen 1 also exposes a **BATTLE → OPEN** submenu.

### Main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| MENU SPRITES | ON / OFF | ON | Enables KIM's animated Pokémon presentation on supported menu/status surfaces. |
| INTEGRATED MODERN UI | ON / OFF | ON | **Gen 1 only.** Chooses KIM's integrated Modern UI or vanilla UI. Ownership swaps live without restarting. |
| SPRITE GEN | GEN 2 / GEN 3 / GEN 4 / GEN 5 | GEN 5 | Selects the animated front-sprite generation used by KIM menu/title presentation and by battle **FRONT SET = SAME AS MENU**. |
| ANIMATION | ON / OFF | ON | Enables animated sprite playback. Also controls supported animated player-trainer intros; OFF holds them on their first frame. |
| TITLE SCREEN | ON / OFF | ON | Enables KIM's animated Red/Blue title-screen Pokémon presentation. |
| TITLE TRAINER | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Selects KIM's animated Red title trainer or Gen1Recomp's original title trainer. |
| TITLE CYCLE SPEED | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly title-screen Pokémon change. |

## KANTO IN MOTION → BATTLE settings

The Battle submenu is currently **Gen 1 only**. These are the current v1.3.2 settings and their behavior.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | ON | Master switch for KIM's Gen 1 battle presentation. OFF yields battle presentation to vanilla Gen1Recomp or another compatible battle owner. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's animated Pokémon battle sprites. Turning it off disables KIM's animated battler replacement without enabling voxel rendering. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves Gen 1 DVs alone; the other choices deliberately roll KIM's shiny DV pattern. The stored DVs keep captured Pokémon shiny. Compatible Overworld Wild Spawns/Wilds Pokémon use the same identity. |
| **MOVE ANIMATIONS** | ON / OFF | ON | ON uses the integrated Kanto Rework / Pokémon Essentials-style animation set for all 165 Gen 1 moves. OFF falls back to Gen1Recomp's native move animations. |
| **FRONT SET** | SAME AS MENU / GEN 2 / GEN 3 / GEN 4 / GEN 5 | SAME AS MENU | Chooses the animated opponent/front sprite collection. SAME AS MENU follows **SPRITE GEN**. |
| **BACK SET** | GEN 5 / GEN 3 / ROM | GEN 5 | Chooses the player-side battle sprite source. Gen 3 and Gen 5 use animated backs; ROM keeps the game's original back sprite. |
| **PLAYER TRAINER** | DEFAULT / ROM, PNG, GEN 1–5, ASH, GARY, RED, ASH FRONT, MISTY FRONT, BROCK FRONT, BULMA FRONT, GARY FRONT, BOY, LASS, HILBERT | DEFAULT / ROM | Chooses the player trainer shown during the battle intro/send-out. When a five-frame atlas exists, the global **ANIMATION** setting controls whether it animates. Static-only choices remain static. DEFAULT / ROM yields to the game or another trainer provider. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 125% | Scales only the player-side Pokémon around its normal KIM battle anchor. Enemy size is independent. |
| **HUD SCALE** | OG / SCALED | OG | Battle Art-style HUD scale. OG uses the normal window-fit integer scale; SCALED uses the one-rung-smaller compact HUD. Compatible Quality of Life EXP placement follows the selected HUD geometry. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales only the integrated Modern UI's battle command, move, and message text. It does not resize the lower panel, HP/status HUD, or Quality of Life EXP bar. When Modern UI is OFF, vanilla text remains vanilla-owned. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move grid. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy beside the move list. OFF gives move names the full panel width. |
| **ARENA FILL** | OFF / WHITE / KRS / GEN6 | KRS | Chooses the battle arena. KRS uses Kanto Rework Suite location/time backgrounds and authored stance anchors. GEN6 uses KIM's previous flat Gen 6 arena set. WHITE is a plain field; OFF leaves the normal source background path. |
| **BG Y-OFFSET** | 0 PX–400 PX in 20 PX steps | 140 PX | Applies to the GEN6 arena source and chooses how far down into the source image the top crop begins. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses Battle Art-style HP/status glyph treatment. COLOR uses dark glyphs; INVERTED uses light glyphs with a dark pixel shadow. HP gauge health colors remain green/yellow/red. |

The Battle submenu also includes **RESET TO DEFAULT**, which restores only the Battle settings above to their defaults.

### Typed Move Colors compatibility

When the external **Typed Move Colors** mod is installed, KIM's Modern move tiles reuse that mod's own effectiveness calculation instead of duplicating its type chart. Its MOVE EFFECT option remains authoritative. KIM mirrors the resulting effectiveness symbols inside its move tiles while leaving the external mod unmodified.

### Overworld Wild Spawns / Wilds shiny compatibility

When compatible `overworld_wild_spawns` / Wilds is installed, KIM assigns the persistent shiny identity before the visible spawn is created. Wilds continues to own spawning, movement, sizing, water handling, and the actual overworld art; it simply selects its own shiny sprite for a shiny spawn. The same DVs are carried into battle, Safari encounters, and direct overworld catches.

### Quality of Life compatibility

KIM does not modify Quality of Life. Its battle EXP/caught overlays remain source-owned. KIM only supplies the geometry needed to keep those overlays aligned with KIM's battle HUD, including the mobile portrait EXP-bar correction.

## Credits and acknowledgements

Kanto in Motion includes or adapts work from several community projects. Credit for those original projects belongs to their authors.

- **Battle Art / DramaticShapeVoxelMod — absol89**  
  https://github.com/absol89/DramaticShapeVoxelMod  
  KIM's standalone Battle System adapts selected Battle Art 2D battle/HUD geometry, trainer presentation, and compatibility behavior while deliberately omitting the voxel/world renderer.

- **Kanto Rework Battle Anims + KRS battle backgrounds — Faendra**  
  https://github.com/Faendra/kanto-rework-suite  
  KIM integrates the Kanto Rework battle-animation data/bridge lineage and KRS battle-background routing used by the v1.3.2 arena.

- **Pokéball Colorfix — keberos**  
  https://github.com/keberos/pokeball-colorfix  
  KIM integrates the Gen 1 Poké Ball palette/presentation fixes required by its standalone battle path.

- **Gen1 Modern UI — ArmstrongThomas**  
  https://github.com/ArmstrongThomas/gen1-modern-ui  
  KIM includes a heavily customized integrated build derived from the Gen1 Modern UI foundation.

- **Animated Trainer Card badges — xpixelpriorx**  
  https://www.deviantart.com/xpixelpriorx  
  The animated earned-badge artwork used by KIM's Trainer Card presentation is credited to xpixelpriorx.

- **Gen 9 Move Animation Project — KRLW890 and contributors**  
  https://www.eeveeexpo.com/resources/1480/  
  The Pokémon Essentials `PkmnAnimations.rxdata` animation data used by the integrated Kanto Rework animation conversion identifies this project as its upstream source. See `THIRD_PARTY_NOTICES.md` for details.

Kanto in Motion does **not** claim ownership of third-party or Pokémon-derived artwork. See `THIRD_PARTY_NOTICES.md` and `ASSET_NOTICES.md` before redistributing the Full Assets package.

## External compatibility mods are not bundled

The following integrations are compatibility-only in v1.3.2. Their packages are **not copied, modified, or redistributed by Kanto in Motion**:

- Quality of Life
- Typed Move Colors
- Overworld Wild Spawns / Wilds of Kanto
- Gen2 Clean UI
- Useful Bag
- other UI/battle mods using KIM's compatibility API

## Compatibility

- Gen1Recomp mod API: **2**
- Games: **Gen 1 + Gen 2**
- Gen 1 carts: **Red / Blue / Yellow**
- Gen 2 carts: **Gold / Silver / Crystal**
- Declared engine range: **>= 0.2.24 and < 0.3.0**
- Integrated Gen1 Modern UI: customized project build
- Gen2 Clean UI: original/unmodified **0.4.1** supported
- Battle Art: **not required at runtime**
- Link-relevant gameplay data: unchanged (`affects_link: false`)

### Open UI / battle compatibility API

Kanto in Motion exposes an opt-in compatibility registry so UI and battle mods can coordinate ownership without requiring KIM-specific file patches.

A cooperating battle mod can register through `animated_menu_pokemon`'s public `kantoInMotionCompatibility` export and choose:

- `modernUi = "native"` — source battle mod owns its complete battle UI.
- `modernUi = "lower"` — source keeps world/battlers/effects/HP/status/EXP; KIM Modern UI owns only dialogue, commands, and moves.
- `modernUi = "full"` — compatible standard battle state opts into the complete Modern battle presenter.

Scene-owning battle mods make KIM's standalone battle scene yield by default. A source can explicitly opt into KIM sprites and/or KIM animations through the compatibility registration.

A cooperating UI mod can claim only the presenter families it replaces (`battle`, `dialogue`, `pokemon`, `menus`, `manager`, `title`, `all`, or exact presenter-kind names). Invalid or failing registrations are fail-open so the native/source presentation remains visible.

Because Kanto in Motion uses `engine_internals` for UI/battle integration, large Gen1Recomp internal refactors may require an update even when the manifest range still accepts the engine.

## Release packages

v1.3.2 is provided in two ZIPs. Install **one**, not both.

### Full Assets

`Kanto-in-Motion-v1.3.2-Full-Assets.zip`

Includes the animated Pokémon/title payloads present in the maintainer's working release build, along with the integrated battle/background/UI assets used by KIM.

### No Pokémon Assets

`Kanto-in-Motion-v1.3.2-No-Pokemon-Assets.zip`

Excludes the locally imported Pokémon front/back/title artwork and associated generated sprite metadata where required. The runtime code remains intact and `tools/import_assets.py` can populate compatible local sprite assets.

See `ASSET_NOTICES.md` for the exact packaging boundary.

## Installation

1. Download **one** v1.3.2 ZIP: Full Assets or No Pokémon Assets.
2. Import the ZIP through Gen1Recomp's Mods interface.
3. If using No Pokémon Assets, populate compatible local sprite art using `tools/import_assets.py` or your established local asset workflow.
4. Enable Kanto in Motion.
5. Do not enable a separate Gen1 Modern UI / Gen1 Clean UI at the same time as KIM's integrated Gen 1 UI unless you intentionally disable/yield the overlapping presenter.

### Upgrading from v1.3.1

Replace the previous Kanto in Motion package with one complete v1.3.2 package. The internal ID remains `animated_menu_pokemon`, so compatible saved KIM options carry forward. Do not layer the old v28 or v1.3.1 v2-v7 test patches underneath v1.3.2; their final confirmed changes are already included.

If upgrading from the older **Animated Menu Pokémon** package, remove/disable that package first because it shares the same internal mod ID.

## Repository layout

- `main.lua` — generation detection, options, animated sprite provider, battle presentation, compatibility hooks, title animation, and UI bootstrap.
- `lib/modern_ui_integrated*.lua` — customized Gen1 Modern UI integration and platform presenters.
- `lib/integrated_krba.lua` / `lib/krba_essentials_player.lua` — integrated Kanto Rework / Pokémon Essentials animation bridge.
- `lib/integrated_pokeball_colorfix.lua` / `lib/pokeball_target_fix.lua` — integrated Poké Ball presentation and fullscreen catch-target compatibility.
- `lib/shiny_encounter_fx.lua` — one-shot shiny sparkle/audio presentation.
- `lib/overworld_wild_shiny_bridge.lua` — KIM-side Wilds/Overworld Wild Spawns shiny identity bridge.
- `data/krs_battle_backgrounds.lua` — KRS background routing and stance metadata.
- `assets/battle/backgrounds/krs/` — KRS battle background assets used by the KRS arena choice.
- `tools/import_assets.py` — local animated-asset importer.
- `THIRD_PARTY_NOTICES.md` / `ASSET_NOTICES.md` — attribution and redistribution notes.
- `CHANGELOG.md` / `RELEASE_NOTES.md` — public release summary plus retained development history.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.** AI assistance was used for code generation and modification, debugging, documentation, and release preparation. The project maintainer directs the project, chooses which changes to keep, and performs the in-game testing used to determine what is released.

## Trademark / affiliation notice

Pokémon and related names, characters, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
