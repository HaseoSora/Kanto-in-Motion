# Kanto in Motion v1.5.1

Kanto in Motion is an HD animated Pokémon presentation and battle overhaul for **Gen1Recomp**.

## Supported games

| Game | HD Pokémon support | Battle presentation |
|---|---:|---|
| **Red / Blue / Yellow** | #001–151 | Full KIM battle/UI system |
| **Gold / Silver / Crystal** | #001–251 | Native Gen 2 battle system + KIM HD Pokémon |
| **FireRed / LeafGreen** | #001–386 | Native FR/LG battle system + KIM HD Pokémon |

The internal mod ID remains `animated_menu_pokemon`, so existing Kanto in Motion settings can carry forward when updating.

## What’s new in v1.5.1

- Added **Pokémon shadows to Gold / Silver / Crystal**.
- Added **Pokémon shadows to FireRed / LeafGreen**.
- Added **PKMN SHADOWS** and **SHADOW OPACITY** settings to both game families.
- FR/LG shadows follow Pokémon during send-out and other slide movement instead of appearing at the destination first.
- Restored the missing `hd_pokemon_national.lua` metadata in the release package so Gen 2 Pokémon #152–251 use their HD sprites correctly on clean installs.
- Keeps all v1.5.0 desktop/mobile fixes and multi-generation support.

## Main features

### Red / Blue / Yellow

- HD animated front/back Pokémon
- Normal and shiny battle presentation
- Integrated Modern Battle UI
- KIM HP/status HUD
- Integrated move animations
- HD location/time-aware battle backgrounds
- Pokémon shadows
- Shiny encounter presentation
- Player trainer selection
- Animated title-screen Pokémon
- HD Pokémon icons
- Battle Art and PotatoVoxel compatibility

### Gold / Silver / Crystal

- HD animated Pokémon through National Dex **#251**
- Native Gen 2 HUD, trainers, commands, backgrounds, and move animations
- HD animated battle Pokémon
- HD Summary-screen Pokémon
- HD Pokédex Pokémon
- HD Pokémon icons
- Pokémon shadows
- Desktop and mobile support

### FireRed / LeafGreen

- HD animated Pokémon through National Dex **#386**
- Native FR/LG HUD, commands, dialogs, and move animations
- HD animated battle Pokémon
- HD Summary / Pokédex / scripted Pokémon previews
- HD party, storage, and menu icons
- Optional HD battle backgrounds
- Pokémon shadows
- Final-resolution HD rendering for cleaner menu and battle presentation
- Desktop and mobile portrait/landscape support
- Mobile **SCREEN POS** support

## HD Pokémon icons

Kanto in Motion includes HD Rescaled Pokémon icons for **National Dex #001–386**.

- R/B/Y uses KIM's established icon path.
- G/S/C renders the HD icons at final window resolution instead of magnifying the native 16×16 icon canvas.
- FR/LG renders the HD icons at final window resolution and aligns them to the native Game3/OAM menu geometry.
- `POKEMON ICONS = OFF` restores the native game icons or yields to a compatible icon provider.
- Icon animation follows the main `ANIMATION` setting.
- Separate shiny menu-icon artwork is not included yet; shiny Pokémon currently use the normal HD menu icon.

## Kanto in Motion settings

Open **KANTO IN MOTION** from the mod settings screen.  
On **Red / Blue / Yellow**, the Gen 1 battle-specific controls are grouped under **BATTLE → OPEN**.

### Red / Blue / Yellow — main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's animated Pokémon presentation on supported menu, Summary/Status, Pokédex, Party, evolution, and other presentation surfaces. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in party and other native icon slots. OFF yields icon presentation to the game or another compatible icon provider such as HGSS_SPRITES. |
| **INTEGRATED MODERN UI** | ON / OFF | ON | **Gen 1 only.** Enables KIM's customized integrated Modern UI. The saved preference is remembered across launches. |
| **ANIMATION** | ON / OFF | ON | Enables animated Pokémon playback and supported animated trainer presentation. OFF holds supported animated art on its first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's animated title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Chooses KIM's animated Red title trainer or Gen1Recomp's original title trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly the title-screen Pokémon changes. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales only the cycling title-screen Pokémon. Red and the custom logo are unchanged. |

### Red / Blue / Yellow — BATTLE settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | ON | Master switch for KIM's Gen 1 battle scene/HUD presentation. OFF yields those layers to vanilla Gen1Recomp or another compatible battle owner. |
| **MODERN BATTLE UI** | ON / OFF | ON | Uses KIM's integrated command, move-selection, and battle-message presentation. OFF keeps the rest of KIM's battle system available while yielding the lower UI/dialog layer. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's HD animated battle Pokémon. Compatible external battle scenes can honor this setting independently. |
| **MOVE ANIMATIONS** | ON / OFF | ON | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animations for all 165 Gen 1 moves. OFF falls back to the active battle provider's native move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality. LOW uses the lightest single-ellipse path; higher levels add progressively softer feathering. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts shadow darkness without changing Pokémon size or position. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves the normal DV behavior intact; the other choices deliberately roll KIM's shiny DV pattern. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware 1920×950 HD battle backgrounds. Supported outdoor scenes can switch between sunrise, day, sunset, and night; caves/fixed interiors remain static. |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / ASH FRONT / MISTY FRONT / BROCK FRONT / BULMA FRONT / GARY FRONT | RED | Chooses the player trainer shown during battle intro/send-out. DEFAULT / ROM yields to the game or another trainer provider. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the player-side Pokémon. **100%** is KIM's calibrated neutral HD player size. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | 100% | Scales Pokémon in compatible staged 3D battles. **100%** is KIM's calibrated neutral reference for Battle Art and desktop PotatoVoxel. |
| **POTATO CAMERA** | 100%–150% in 5% steps | 115% | PotatoVoxel only. Higher values pull the camera farther back to show more of the arena. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | 85% | Android/iOS PotatoVoxel only. Fine-tunes the enemy Pokémon size on mobile. |
| **HUD SCALE** | OG / SCALED | OG | Chooses the HP/status HUD scale preset. SCALED uses one smaller scale rung; HUD SIZE can fine-tune either preset. |
| **HUD SIZE** | 60%–100% in 5% steps | 100% | Fine-tunes the enemy/player HP/status HUD size. Compatible EXP/caught overlays follow the resized HUD geometry. |
| **HUD OPACITY** | 25%–100% in 5% steps | 100% | Adjusts the HP/status HUD opacity without changing its geometry. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Changes the footprint of the lower command/move/message panel while keeping it bottom-anchored. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts only the lower panel background opacity; borders, text, and controls remain readable. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales only Modern UI's command, move, and battle-message text. It does not resize the panel or HP/status HUD. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move layout. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy beside the move list. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses the HP/status glyph treatment. INVERTED uses light glyphs with a dark pixel shadow while preserving HP gauge colors. |

### Gold / Silver / Crystal settings

Gold / Silver / Crystal keep their native Gen 2 battle UI and battle logic. KIM supplies the HD Pokémon presentation on top of those systems.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's HD animated Pokémon on supported Gen 2 menu, Summary/Status, Pokédex, evolution, and presentation surfaces. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in native G/S/C icon slots. OFF restores the game or another compatible icon provider. |
| **ANIMATION** | ON / OFF | ON | Enables animated KIM Pokémon on supported G/S/C presentation and battle surfaces. OFF holds supported artwork on the first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's supported animated title presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Selects KIM's animated title trainer path or the original title trainer where supported by the active title screen. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls the KIM title Pokémon cycle timing on supported title presentation. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales the KIM title Pokémon presentation where supported. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in native G/S/C battles while retaining the native Gen 2 HUD, trainers, commands, backgrounds, and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts Gen 2 battle shadow darkness without changing Pokémon size or position. |

### FireRed / LeafGreen settings

FireRed / LeafGreen keep Gen1Recomp's native Game3 UI, HUD, commands, dialogs, and move-animation system while KIM supplies HD Pokémon presentation.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Uses KIM animated Pokémon on supported FR/LG menu, Summary, Pokédex, and scripted presentation screens. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM HD Pokémon icons in party, storage, Pokédex, and other native icon slots. OFF restores the game's native icons. |
| **ANIMATION** | ON / OFF | ON | Enables animated KIM Pokémon. OFF holds supported animated Pokémon on the first frame. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in FR/LG battles while keeping the native FR/LG HUD, commands, dialogs, and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. Shadows follow the battlers during send-out/slide movement. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts FR/LG battle shadow darkness without changing Pokémon size or position. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD Kanto battle backgrounds while preserving FR/LG's native battler/HUD geometry. OFF restores the native FR/LG battle background. |

## Mobile support

- R/B/Y keeps its established desktop/mobile KIM battle paths.
- G/S/C uses the native mobile Gen 2 UI with KIM HD Pokémon layered into the live screen.
- FR/LG uses the native Game3 geometry with KIM HD art rendered at final resolution.
- FR/LG portrait and landscape honor Gen1Recomp's **SCREEN POS** setting.
- FR/LG uses a single mobile battle presentation path to avoid duplicate HUD/menu rendering.

## HGSS_SPRITES compatibility

When Kanto in Motion is used with **HGSS_SPRITES**:

- In Gen 1, `BATTLE SYSTEM = ON` blocks HGSS battle-side hooks from replacing or rescaling KIM/Battle Art battle presentation.
- HGSS overworld/player presentation remains available where it does not conflict with KIM ownership.
- `POKEMON ICONS = ON` keeps KIM in control of Pokémon icons.
- `POKEMON ICONS = OFF` yields icon presentation back to HGSS or the native game.

## Optional compatibility

Kanto in Motion includes compatibility paths for optional external mods such as:

- Battle Art
- PotatoVoxel
- Typed Move Colors
- Useful Bag
- Advanced Box System
- HGSS_SPRITES
- supported translation/UI mods

External mod packages are not bundled.

## Installation

Replace the previous Kanto in Motion package with v1.5.1 and enable it from Gen1Recomp's mod menu.

Existing KIM settings can carry forward because the internal mod ID is unchanged.

## Credits

- **Animated Pokémon battle sprites — Battle Sprites Reloded**
  - Creator: **JDChaos**
  - https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/

- **HD Rescaled Pokémon Icons — LockeGriss and contributors**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/

- **Charizard and Cyndaquil-family icon edits — HaseoSora**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/#comment-2173491

- **Animated Trainer Card badges — xpixelpriorx**
  - https://www.deviantart.com/xpixelpriorx

- **Gen1 Modern UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen1-modern-ui

- **Kanto Rework Suite — Faendra**
  - https://github.com/Faendra/kanto-rework-suite

- **Poké Ball Colorfix — keberos**
  - https://github.com/keberos/pokeball-colorfix

## Disclaimer

Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
