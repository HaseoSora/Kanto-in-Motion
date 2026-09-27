# Kanto in Motion v1.5.0

Kanto in Motion is an HD animated Pokémon presentation and battle overhaul for **Gen1Recomp**.

v1.5.0 expands Kanto in Motion into a multi-generation release with support for:

- **Pokémon Red / Blue / Yellow**
- **Pokémon Gold / Silver / Crystal**
- **Pokémon FireRed / LeafGreen**

The internal mod ID remains `animated_menu_pokemon`, so existing Kanto in Motion settings can carry forward.

## v1.5.0 highlights

- Added full Kanto in Motion support paths for **Gold / Silver / Crystal** and **FireRed / LeafGreen**.
- Added HD animated Pokémon support through:
  - **#001–151** in Red / Blue / Yellow
  - **#001–251** in Gold / Silver / Crystal
  - **#001–386** in FireRed / LeafGreen
- Added **HD Rescaled Pokémon icons #001–386** across all three game families.
- Added the live **POKEMON ICONS** ON/OFF setting.
- Gold / Silver / Crystal now keep their native battle UI, trainers, commands, backgrounds, and move-animation system while KIM supplies HD animated Pokémon.
- FireRed / LeafGreen keep their native Game3 UI, HUD, command menus, and move-animation system while KIM supplies HD animated Pokémon and optional HD battle backgrounds.
- FireRed / LeafGreen menu Pokémon, Pokédex previews, party icons, and battle presentation now render correctly at final resolution on desktop and mobile.
- Fixed FireRed / LeafGreen mobile portrait/landscape placement, duplicate battle HUD/menu rendering, and **SCREEN POS** alignment.
- KIM now protects its Gen 1 icon presentation from **HGSS_SPRITES** while `POKEMON ICONS = ON`; turning the option OFF yields icon ownership back to the game or compatible icon mods.
- Preserves the existing Gen 1 Battle Art and PotatoVoxel compatibility paths.

## Game support

### Red / Blue / Yellow

Gen 1 uses Kanto in Motion's complete presentation stack:

- HD animated front/back Pokémon
- normal and shiny battle presentation
- integrated Modern Battle UI
- KIM HP/status HUD
- integrated move animations
- HD location/time-aware battle backgrounds
- shiny encounter presentation
- player trainer selection
- title-screen animation
- HD menu Pokémon and Pokémon icons
- Battle Art and PotatoVoxel compatibility

### Gold / Silver / Crystal

Gen 2 keeps the native Gen1Recomp G/S/C systems and uses KIM only for supported Pokémon presentation:

- HD animated Pokémon through National Dex **#251**
- native Gen 2 battle HUD, trainers, commands, backgrounds, and move animations
- HD Pokémon on the Summary screen
- HD Pokémon in the Pokédex
- HD Pokémon icons in party/storage/native icon slots
- desktop and mobile support

### FireRed / LeafGreen

FR/LG uses Gen1Recomp's Game3 systems and keeps the native FR/LG interface:

- HD animated Pokémon through National Dex **#386**
- HD animated battle Pokémon
- HD Summary/Pokédex/scripted Pokémon previews
- HD party/storage/menu icons
- optional location-aware HD battle backgrounds
- native FR/LG HUD, battle commands, dialogs, and move animations
- final-resolution HD rendering to avoid low-resolution canvas pixelation
- desktop and mobile portrait/landscape support
- mobile **SCREEN POS** support

## Pokémon icon system

Kanto in Motion includes the HD Rescaled Pokémon icon set for **National Dex #001–386**.

- **Red / Blue / Yellow:** KIM's established menu-icon path.
- **Gold / Silver / Crystal:** icons are replayed at final resolution so they are not magnified from the native 16×16 canvas.
- **FireRed / LeafGreen:** icons are replayed at final resolution and aligned to the native Game3/OAM menu geometry.
- Icons use a subtle two-frame one-pixel bounce when `ANIMATION = ON`.
- `POKEMON ICONS = OFF` restores the game's native icons or yields to another compatible icon provider.
- Matching shiny menu-icon slots are reserved; until separate shiny icon art is authored, shiny Pokémon fall back to the normal HD menu icon.

## Settings

The settings shown depend on the game currently running.

### Red / Blue / Yellow — presentation

| Setting | Description |
|---|---|
| **MENU SPRITES** | Enables KIM animated Pokémon on supported menu/presentation screens. |
| **POKEMON ICONS** | Uses KIM HD Pokémon icons in party and other icon slots. OFF yields to the game or a compatible icon mod such as HGSS_SPRITES. |
| **ANIMATION** | Enables KIM Pokémon/trainer animation. OFF holds supported animated art on its first frame. |
| **INTEGRATED MODERN UI** | Enables KIM's integrated Gen 1 Modern UI. The choice is remembered across launches. |
| **TITLE SCREEN** | Enables KIM's animated Gen 1 title-screen presentation. |
| **TITLE TRAINER** | Chooses KIM's animated Red or Gen1Recomp's original title trainer. |
| **TITLE CYCLE SPEED** | Sets the title-screen Pokémon cycle speed: NORMAL / SLOW / SLOWER. |
| **TITLE PKMN SIZE** | Scales only the cycling title-screen Pokémon. Default: **75%**. |

### Red / Blue / Yellow — battle

| Setting | Description |
|---|---|
| **BATTLE SYSTEM** | Master switch for KIM-owned battle scene/HUD presentation. OFF yields those layers to vanilla or another battle provider. |
| **MODERN BATTLE UI** | Uses KIM's command, move, and message presentation while leaving the rest of the KIM battle system available. |
| **BATTLE SPRITES** | Enables KIM animated battle Pokémon. Cooperative 3D providers can honor this independently. |
| **MOVE ANIMATIONS** | Enables KIM's integrated move-animation system for all 165 Gen 1 moves. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA ground-contact shadow quality. |
| **SHADOW OPACITY** | Adjusts Pokémon shadow darkness. Default: **100%**. |
| **SHINY ODDS** | Uses native 1/8192 odds or a selectable KIM shiny encounter rate. |
| **HD BATTLE BACKGROUNDS** | Uses KIM's location-aware HD battle backgrounds with supported sunrise/day/sunset/night variants. |
| **PLAYER TRAINER** | Chooses the player trainer used during battle intro/send-out. `DEFAULT / ROM` yields to the game/provider. |
| **PLAYER PKMN SIZE** | Scales only the player Pokémon. **100%** is KIM's calibrated neutral HD size. |
| **3D PKMN SIZE** | Scales Pokémon used by compatible 3D battle providers. **100%** is the calibrated neutral reference. |
| **POTATO CAMERA** | Controls PotatoVoxel battle-camera pullback. |
| **POTATO MOBILE ENEMY SIZE** | Fine-tunes PotatoVoxel enemy size on Android/iOS. Default: **85%**. |
| **HUD SCALE** | Chooses the KIM HP/status HUD scale style. |
| **HUD SIZE** | Scales the KIM HP/status HUD. |
| **HUD OPACITY** | Adjusts the KIM HUD background opacity. |
| **HUD COLOR** | COLOR keeps the normal HUD; INVERTED changes the HUD glyph treatment while preserving HP gauge colors. |
| **BATTLE UI SIZE** | Scales the lower Modern Battle UI panel. |
| **BATTLE UI OPACITY** | Adjusts the lower battle-panel background opacity. |
| **BATTLE TEXT SIZE** | Scales battle command/move/message text independently of panel and HUD size. |
| **MOVE LAYOUT** | GRID uses a 2×2 move layout; VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | Shows type, PP, power, and accuracy for the selected move. |

### Gold / Silver / Crystal

| Setting | Description |
|---|---|
| **POKEMON ICONS** | Uses KIM HD Pokémon icons in native G/S/C icon slots. OFF restores the game or another icon mod's icons. |
| **ANIMATION** | Animates KIM Pokémon on supported G/S/C presentation screens. |
| **BATTLE SPRITES** | Uses KIM HD animated Pokémon in native Gen 2 battles while keeping the native HUD, trainers, commands, backgrounds, and move animations. |
| **SUMMARY SPRITES** | Uses KIM HD animated Pokémon on the G/S/C Summary screen. |
| **POKEDEX SPRITES** | Uses KIM HD animated Pokémon in the G/S/C Pokédex. |

### FireRed / LeafGreen

| Setting | Description |
|---|---|
| **MENU SPRITES** | Uses KIM animated Pokémon on supported FR/LG presentation screens. |
| **POKEMON ICONS** | Uses KIM HD Pokémon icons in party, storage, Pokédex, and other native icon slots. OFF restores native icons. |
| **ANIMATION** | Animates KIM Pokémon. OFF holds supported animated Pokémon on the first frame. |
| **BATTLE SPRITES** | Uses KIM animated Pokémon in FR/LG battles while keeping the native FR/LG HUD, commands, dialogs, and move animations. |
| **HD BATTLE BACKGROUNDS** | Uses KIM's location-aware HD Kanto battle backgrounds in FR/LG. OFF restores the native FR/LG arena. |

## Mobile behavior

Kanto in Motion includes separate presentation handling where Gen1Recomp's mobile composition differs from desktop.

- Gen 1 keeps its established desktop/mobile battle compatibility paths.
- Gold / Silver / Crystal use the native mobile G/S/C UI with KIM Pokémon presentation layered into the live screen.
- FireRed / LeafGreen use the native Game3 menu and battle geometry, with KIM HD art replayed at final resolution.
- FR/LG portrait and landscape honor Gen1Recomp's **SCREEN POS** placement.
- FR/LG battle presentation uses one authoritative mobile HUD/menu path to prevent duplicate battle UI.

## HGSS_SPRITES compatibility

When Kanto in Motion is used with **HGSS_SPRITES**:

- In Gen 1, `BATTLE SYSTEM = ON` bypasses HGSS battle-side hooks so HGSS cannot resize or replace KIM/Battle Art battle presentation.
- HGSS overworld/player/menu behavior remains available where it does not conflict with KIM ownership.
- `POKEMON ICONS = ON` keeps KIM in control of the Pokémon icon path.
- `POKEMON ICONS = OFF` yields icon presentation back to HGSS or the native game.

## Optional compatibility

Kanto in Motion contains compatibility paths for optional external mods including:

- Battle Art
- PotatoVoxel
- Typed Move Colors
- Useful Bag
- Advanced Box System
- HGSS_SPRITES
- Poké Ball Colorfix behavior integrated into KIM
- supported translation/UI compatibility paths

External mod packages are not bundled unless explicitly stated.

## Installation

Install Kanto in Motion in Gen1Recomp's mod folder and enable it from the mod menu.

When updating from an older KIM release, replace the previous Kanto in Motion package. The internal mod ID is unchanged, so saved KIM settings can carry forward.

## Asset credits

- **Animated Pokémon battle sprites — Battle Sprites Reloded**
  - Creator: **JDChaos**
  - Original thread: https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/
  - Used for front/back, normal/shiny, and available male/female variants.

- **HD Rescaled Pokémon Icons — LockeGriss and contributors**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/

- **Charizard and Cyndaquil-family icon edits — HaseoSora**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/#comment-2173491

- **Animated Trainer Card badges — xpixelpriorx**
  - https://www.deviantart.com/xpixelpriorx

- **Gen1 Modern UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen1-modern-ui

- **Kanto Rework Suite / battle-animation lineage — Faendra**
  - https://github.com/Faendra/kanto-rework-suite

- **Poké Ball Colorfix — keberos**
  - https://github.com/keberos/pokeball-colorfix

## Notes

- Kanto in Motion is an unofficial fan-made mod.
- Pokémon and related names, characters, and artwork are trademarks/copyrights of their respective owners.
- Kanto in Motion is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
