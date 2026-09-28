# Kanto in Motion v1.5.2

**Kanto in Motion** is an HD animated Pokémon presentation and battle overhaul for **Gen1Recomp**.

It supports:

- **Pokémon Red / Blue / Yellow** — National Dex #001–151
- **Pokémon Gold / Silver / Crystal** — National Dex #001–251
- **Pokémon FireRed / LeafGreen** — National Dex #001–386

The internal mod ID remains `animated_menu_pokemon`, so compatible Kanto in Motion settings can carry forward when updating.

## What’s new in v1.5.2

v1.5.2 brings Kanto in Motion’s **Modern UI to Gold / Silver / Crystal** while keeping Gen 2 gameplay logic native.

- Added a **MODERN UI** master setting for G/S/C.
- Added Modern UI presentation for Gen 2 battle dialogue, command selection, and move selection while retaining the native Gen 2 HP/status HUD, battle logic, trainers, backgrounds, and move animations.
- Added Modern UI presentation for the **Start Menu, Party, Pokédex, Pack, PokéGear, Trainer Card, Save Menu, Options Menu, and Kanto in Motion settings**.
- Added Modern UI presentation for common Gen 2 dialogue and choice flows, including **NPC dialogue, PokéCenter prompts, Poké Mart buy/sell screens, item/field text, phone text, level-up/stat messages, and supported YES/NO prompts**.
- Added Gen 2 **UI THEME**, **BATTLE UI SIZE**, **BATTLE UI OPACITY**, **BATTLE TEXT SIZE**, **MOVE LAYOUT**, and **MOVE INFO** settings.
- Added a KIM-styled Gen 2 Pokédex presentation based on the **Gen2 Clean UI 0.4.1 Pokédex adapter/presenter**.
- Improved Gen 2 menu readability with larger fonts and responsive final-window rendering.
- Removed Gen 1 title-animation controls from the Gen 2 settings menu.
- Keeps the v1.5.1 G/S/C and FR/LG Pokémon shadows, HD sprite fixes, HD icons, and all existing multi-generation compatibility work.

## Main features

### Red / Blue / Yellow

- HD animated front/back Pokémon
- Normal and shiny battle presentation
- Integrated Modern UI
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
- Integrated KIM **Modern UI** for menus, dialogue, shops, save/options, Pokédex, Party, and supported battle UI surfaces
- Native Gen 2 battle logic, HP/status HUD, trainers, backgrounds, and move animations
- Modern UI themes shared with KIM’s Gen 1 presentation
- HD animated battle Pokémon
- HD Summary-screen Pokémon
- HD Pokédex Pokémon
- HD Pokémon icons
- Pokémon shadows
- Final-window rendering for crisp HD menus and Pokémon art

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

Open **KANTO IN MOTION** from the mod settings screen. On **Red / Blue / Yellow**, the Gen 1 battle-specific controls are grouped under **BATTLE → OPEN**.

### Red / Blue / Yellow — main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's animated Pokémon presentation on supported menu, Summary/Status, Pokédex, Party, evolution, and other presentation surfaces. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in party and other native icon slots. OFF yields icon presentation to the game or another compatible icon provider such as HGSS_SPRITES. |
| **INTEGRATED MODERN UI** | ON / OFF | ON | Enables KIM's customized Gen 1 Modern UI presentation. |
| **ANIMATION** | ON / OFF | ON | Enables animated Pokémon playback and supported animated trainer presentation. OFF holds supported animated art on its first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's animated title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Chooses KIM's animated Red title trainer or Gen1Recomp's original title trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly the title-screen Pokémon changes. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales only the cycling title-screen Pokémon. Red and the custom logo are unchanged. |

### Red / Blue / Yellow — BATTLE settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | ON | Master switch for KIM's Gen 1 battle scene/HUD presentation. OFF yields those layers to vanilla Gen1Recomp or another compatible battle owner. |
| **MODERN BATTLE UI** | ON / OFF | ON | Uses KIM's integrated command, move-selection, and battle-message presentation. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's HD animated battle Pokémon. Compatible external battle scenes can honor this setting independently. |
| **MOVE ANIMATIONS** | ON / OFF | ON | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animations for all 165 Gen 1 moves. OFF falls back to the active battle provider's native move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality. Higher levels add progressively softer feathering. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts shadow darkness without changing Pokémon size or position. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves the normal DV behavior intact. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD battle backgrounds. |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / front-sprite choices | RED | Chooses the player trainer shown during battle intro/send-out. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the player-side Pokémon. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | 100% | Scales Pokémon in compatible staged 3D battles. 100% is KIM's neutral reference. |
| **POTATO CAMERA** | 100%–150% in 5% steps | 115% | PotatoVoxel only. Higher values pull the camera farther back. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | 85% | Mobile PotatoVoxel only. Fine-tunes enemy Pokémon size. |
| **HUD SCALE** | OG / SCALED | OG | Chooses the HP/status HUD scale preset. |
| **HUD SIZE** | 60%–100% in 5% steps | 100% | Fine-tunes the enemy/player HP/status HUD size. |
| **HUD OPACITY** | 25%–100% in 5% steps | 100% | Adjusts HP/status HUD opacity. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Changes the footprint of the lower command/move/message panel. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts the lower panel background opacity. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales Modern UI battle command, move, and message text. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move layout. VERTICAL lists moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses the HP/status glyph treatment. |

### Gold / Silver / Crystal settings

Gold / Silver / Crystal retain their native gameplay and battle logic. KIM's Modern UI is a presentation layer: the native Gen 2 HP/status HUD, trainers, battle timing, backgrounds, move animations, scripts, shops, save logic, option logic, and state transitions remain authoritative underneath it.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's HD animated Pokémon on supported Gen 2 menu, Summary/Status, Pokédex, evolution, and presentation surfaces. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in native G/S/C icon slots. OFF restores the game or another compatible icon provider. |
| **ANIMATION** | ON / OFF | ON | Enables animated KIM Pokémon on supported G/S/C presentation and battle surfaces. OFF holds supported artwork on the first frame. |
| **MODERN UI** | ON / OFF | ON | Master switch for KIM's Gen 2 Modern UI across menus, Party, Pokédex, Pack, PokéGear, Trainer Card, Save, Options/KIM settings, dialogue, shops, choices, level-up messages, and supported battle UI surfaces. OFF yields those presentation surfaces to the native game. |
| **MODERN BATTLE UI** | ON / OFF | ON | Replaces the native lower battle dialogue, command menu, and move menu with KIM Modern UI while keeping the native Gen 2 HP/status HUD, battle logic, trainers, backgrounds, and move animations. |
| **UI THEME** | GEN1 MODERN / CLASSIC MONO / CRIMSON / CRIMSON GLASS / MODERN GLASS / POCKET GREEN / MIDNIGHT / MIDNIGHT GLASS / FROST / LIGHT / DARK | GEN1 MODERN | Chooses the palette used across the Gen 2 Modern UI. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Adjusts the Gen 2 Modern lower battle panel footprint while keeping it bottom-anchored. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts only the Gen 2 Modern lower battle panel background opacity. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales Gen 2 Modern battle command, move, and message text independently of the native HP/status HUD. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move selector. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected Gen 2 move's type, PP, power, and accuracy beside the move list. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in native G/S/C battles while retaining native Gen 2 battle logic and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts Gen 2 battle shadow darkness without changing Pokémon size or position. |

#### Gen 2 Modern UI coverage

With **MODERN UI = ON**, KIM currently presents:

- Start Menu
- Party and Pokémon status/details
- Gen2 Clean UI-based Pokédex list and entry presentation
- Pack
- PokéGear, including native map/phone data presented through the KIM theme
- Trainer Card
- Save Menu
- native Options categories and submenus
- Kanto in Motion's own settings and Battle submenu
- common NPC / field / phone dialogue
- YES/NO prompts and scripted choice menus
- Poké Mart buy/sell/quantity/confirmation presentation
- supported level-up/stat and battle prompt presentation
- battle commands, move selection, and battle messages when **MODERN BATTLE UI = ON**

### FireRed / LeafGreen settings

FireRed / LeafGreen keep Gen1Recomp's native Game3 UI, HUD, commands, dialogs, and move-animation system while KIM supplies HD Pokémon presentation.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Uses KIM animated Pokémon on supported FR/LG menu, Summary, Pokédex, and scripted presentation screens. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM HD Pokémon icons in party, storage, Pokédex, and other native icon slots. OFF restores the game's native icons. |
| **ANIMATION** | ON / OFF | ON | Enables animated KIM Pokémon. OFF holds supported animated Pokémon on the first frame. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in FR/LG battles while keeping the native FR/LG HUD, commands, dialogs, and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. Shadows follow battlers during send-out/slide movement. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts FR/LG battle shadow darkness without changing Pokémon size or position. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD Kanto battle backgrounds while preserving FR/LG's native battler/HUD geometry. OFF restores the native FR/LG battle background. |

## Mobile support

- R/B/Y keeps its established desktop/mobile KIM battle paths.
- G/S/C keeps KIM's final-resolution HD Pokémon/menu rendering architecture and native Gen 2 gameplay state beneath the Modern UI presentation.
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

External compatibility mod packages are not bundled. v1.5.2 directly vendors only the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter pieces used by KIM's Gen 2 Pokédex presentation; the separate Gen2 Clean UI mod is not required for that Pokédex presentation.

## Installation

Replace the previous Kanto in Motion package with **v1.5.2** and enable it from Gen1Recomp's mod menu.

Existing KIM settings can carry forward because the internal mod ID is unchanged.

If you are updating a full-assets installation with the **CODE-ONLY** package, keep your existing KIM asset folders and replace the code/documentation files with the v1.5.2 package contents.

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

- **Gen2 Clean UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen2-clean-ui
  - v1.5.2 vendors the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter used by KIM's Gen 2 Pokédex presentation.

- **Kanto Rework Suite — Faendra**
  - https://github.com/Faendra/kanto-rework-suite

- **Poké Ball Colorfix — keberos**
  - https://github.com/keberos/pokeball-colorfix

## Disclaimer

Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
