# Kanto in Motion v1.4.2

**Kanto in Motion (KIM)** is an animated Pokémon presentation and battle overhaul for **Gen1Recomp Pokémon Red / Blue / Yellow**.

v1.4.2 is currently a **Gen 1 release**. Pokémon #001–151 have full KIM battle-side support. Gen 2 game support and Pokémon #152–251 battle support are not included in this release.

The internal mod ID remains `animated_menu_pokemon`, so compatible Kanto in Motion settings can carry forward when updating.

## v1.4.2 highlights

- Uses the broader Gen1Recomp manifest range:
  - `0.0.0-dev || >=0.1.69 <3.0.0`
  - This prevents ordinary Gen1Recomp minor-version bumps from automatically marking KIM incompatible just because the manifest ended at a specific `0.x` release.
- Retains the v1.4.1 **HGSS_SPRITES battle hard block**:
  - With **KIM → BATTLE SYSTEM = ON**, HGSS battle-side hooks are bypassed.
  - HGSS can no longer resize or replace KIM/Battle Art trainers or Pokémon during battle.
  - HGSS overworld, menu, icon, and player-overworld features remain available.
  - With **BATTLE SYSTEM = OFF**, HGSS battle behavior is allowed again.
- Retains confirmed **Battle Art** and **PotatoVoxel** compatibility on desktop and mobile.
- Keeps the Gen 1 HD battle system introduced in v1.4.0, including animated Pokémon, HD battle backgrounds, move animations, Modern Battle UI, shiny effects, and battle customization.

> The broad manifest range controls whether Gen1Recomp allows KIM to load. KIM uses `engine_internals`, so a future major engine refactor can still require a compatibility update even if the manifest accepts that version.

## Main features

### HD animated Pokémon

- HD animated Pokémon for **#001–151**.
- Animated front and back battle sprites.
- Normal and shiny variants.
- Available male/female variants are supported by the imported sprite data.
- KIM's packaged HD sheets are physically reduced from the supplied source animations for a more appropriate in-game size and smaller package footprint.
- Missing or unsupported art falls back safely rather than intentionally breaking the battle.

### HD battle backgrounds

KIM includes **1920×950 HD battle backgrounds** with location-aware routing.

Supported authored scenes can use:

- Sunrise
- Day
- Sunset
- Night

Outdoor scenes use Gen1Recomp's live game time. Caves and fixed indoor locations can use static backgrounds where time-of-day switching would not make sense.

The background is selected when the battle begins and remains stable for that battle.

### Gen 1 move animations

KIM includes the integrated Kanto Rework / Pokémon Essentials-style animation path for **all 165 Gen 1 moves**.

`MOVE ANIMATIONS = ON` is the default.

Compatible external 3D battle scenes such as Battle Art and PotatoVoxel can still use KIM's animation provider without KIM replacing their 3D world/camera.

### Shiny Pokémon

- Configurable shiny odds from the native **1/8192** through **ALWAYS**.
- Shiny identity is stored through the Pokémon's DVs so caught shinies stay shiny.
- One-cycle shiny sparkle animation.
- Shiny audio cue.
- Compatible overworld wild-spawn integrations can preserve the same shiny identity between the overworld encounter, battle, and capture.

### Modern UI

KIM contains its customized integrated Gen 1 Modern UI.

It covers supported:

- Dialogue
- Party
- Summary
- Pokédex
- Bag
- PC
- Trainer Card
- Battle Items / Pokémon flow
- Nickname flow
- Level-up stats
- Battle command / move / message presentation
- Centralized mod settings presentation

`INTEGRATED MODERN UI` defaults **ON** and remembers the player's saved choice.

---

# Kanto in Motion settings

Open **KANTO IN MOTION** from Gen1Recomp's mod settings.

The main KIM menu contains the general presentation options. The **BATTLE → OPEN** entry opens the Gen 1 Battle submenu.

## Main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | **ON** | Enables KIM's animated Pokémon presentation on supported non-battle menu/status surfaces. Turning this OFF disables KIM's animated menu Pokémon without disabling the rest of KIM. |
| **INTEGRATED MODERN UI** | ON / OFF | **ON** | Enables KIM's customized Gen 1 Modern UI. OFF yields supported UI surfaces back to vanilla Gen1Recomp or another compatible UI owner. The saved choice is remembered across launches. |
| **ANIMATION** | ON / OFF | **ON** | Master animation preference for supported KIM presentation. It controls animated Pokémon/menu presentation and supported five-frame player-trainer battle intros. OFF holds supported animated trainer art on its first frame. |
| **BATTLE** | OPEN | — | Opens KIM's dedicated Gen 1 Battle settings submenu. |
| **TITLE SCREEN** | ON / OFF | **ON** | Enables KIM's animated Red/Blue title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | **ANIMATED** | Chooses KIM's animated Red title trainer or Gen1Recomp's original Gen 1 title trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | **SLOW** | Controls how quickly the title-screen Pokémon changes to another species. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | **75%** | Scales only the cycling Pokémon on the Red/Blue title screen. The trainer and custom logo are not resized. 75% is the default calibrated for the current HD Pokémon art. |

## KANTO IN MOTION → BATTLE settings

The Battle submenu is **Gen 1 only**.

### Battle ownership and presentation

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | **ON** | Master switch for KIM-owned battle presentation. ON is the normal KIM experience. OFF yields KIM's standalone battle scene/HUD ownership to vanilla or another battle mod. Cooperative external scenes can still honor individual KIM features such as **BATTLE SPRITES** and **MOVE ANIMATIONS**. When HGSS_SPRITES is installed, ON also activates KIM's HGSS battle hard block so HGSS cannot alter KIM/Battle Art battle sprites or scaling. |
| **MODERN BATTLE UI** | ON / OFF | **ON** | Controls KIM's integrated battle command, move-selection, message, and supported battle-menu layer. OFF keeps the rest of KIM's battle system available—animated battlers, shiny effects, move animations, HUD, etc.—while yielding the lower battle UI/dialog layer to vanilla or another compatible battle UI. |
| **BATTLE SPRITES** | ON / OFF | **ON** | Enables KIM's HD animated Pokémon during battle. Compatible cooperative external scenes such as PotatoVoxel can honor this setting independently even when **BATTLE SYSTEM** is OFF. |
| **MOVE ANIMATIONS** | ON / OFF | **ON** | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animations for all 165 Gen 1 moves. Battle Art 3D-BTL and PotatoVoxel can use this provider while retaining their own scene/camera. OFF falls back to the currently active battle provider's native animation path. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | **ON** | Enables KIM's 1920×950 location-aware HD arena backgrounds. Supported outdoor scenes use sunrise/day/sunset/night variants; caves and fixed interiors use static authored scenes. OFF keeps KIM's other battle features but yields arena/background art to the game or another scene owner. |

### Pokémon appearance

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | **MEDIUM** | Controls KIM's ground-contact shadow quality for animated battle Pokémon. LOW uses the cheapest single-ellipse path; MEDIUM/HIGH/ULTRA add progressively smoother feathering. Battle Art's 3D world keeps its own scene-shadow system. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | **100%** | Changes the darkness of KIM's contact shadows without changing Pokémon size or position. 100% is the calibrated reference. |
| **SHINY ODDS** | NATIVE 1/8192 / 1/4096 / 1/2048 / 1/1024 / 1/512 / 1/256 / 1/128 / 1/64 / 1/32 / 1/16 / 1/8 / 1/4 / 1/2 / ALWAYS | **NATIVE 1/8192** | Controls wild shiny generation. NATIVE leaves Gen 1 DVs untouched. Other choices deliberately roll KIM's shiny DV pattern at the selected odds. Because the DVs are stored on the Pokémon, a captured shiny remains shiny. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | **100%** | Fine-tunes only the player-side Pokémon. 100% is KIM's calibrated neutral HD player size. Enemy size is not changed by this setting. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | **100%** | Scales KIM Pokémon used in compatible staged 3D battles. 100% is the calibrated neutral reference for **Battle Art** and desktop **PotatoVoxel**. `PLAYER PKMN SIZE` still applies afterward as a player-only adjustment. PotatoVoxel mobile keeps its separate mobile calibration. |

### Player trainer

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / ASH FRONT / MISTY FRONT / BROCK FRONT / BULMA FRONT / GARY FRONT | **RED** | Chooses the player trainer shown during battle intro/send-out. RED uses KIM's `redplayer.png` and is the default. When the selected asset has a five-frame atlas, **ANIMATION = ON** plays the intro progression and OFF holds frame 1. Compatible scenes such as PotatoVoxel use the same KIM selection. DEFAULT / ROM yields trainer identity to the game or another trainer provider. |

### PotatoVoxel settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **POTATO CAMERA** | 100%–150% in 5% steps | **115%** | PotatoVoxel staged battles only. Higher values pull the camera farther back so more of the arena is visible. KIM applies this without modifying PotatoVoxel's files or saved settings. PotatoVoxel's own interactive camera controls still work on top of the KIM baseline. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | **85%** | Android/iOS PotatoVoxel only. Fine-tunes the KIM enemy Pokémon size for the mobile staged-battle path. 85% is the calibrated default. |

### Battle HUD

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **HUD SCALE** | OG / SCALED | **OG** | Chooses the main HP/status HUD scale preset. OG uses the normal window-fit rung; SCALED uses one rung smaller. **HUD SIZE** can fine-tune either preset. |
| **HUD SIZE** | 60%–100% in 5% steps | **100%** | Fine-tunes KIM's enemy/player HP/status HUD after the OG/SCALED preset. Compatible Quality of Life EXP/caught overlays follow KIM's exported HUD geometry. |
| **HUD OPACITY** | 25%–100% in 5% steps | **100%** | Changes KIM's enemy/player HP/status HUD opacity, including its party Poké Ball layer. This does not fade the lower command/message panel. |
| **HUD COLOR** | COLOR / INVERTED | **COLOR** | Chooses the HP/status glyph treatment. COLOR uses the normal dark-glyph presentation. INVERTED uses light glyphs with a dark pixel shadow while keeping HP gauge colors green/yellow/red. |

### Modern Battle UI

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | **100%** | Adjusts the lower command/move/message panel while keeping it bottom-anchored. Desktop layouts can reserve more vertical room for larger text; mobile keeps its authored battle-dialog footprint at 100%. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | **100%** | Changes only the lower panel **background** opacity. The pixel frame, borders, dividers, text, and selected controls remain fully opaque for readability. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | **150%** | Scales the integrated Modern UI's battle command, move, and message text. It does not change HUD size or panel opacity. When **MODERN BATTLE UI = OFF**, the active source UI owns its own text rendering. |
| **MOVE LAYOUT** | GRID / VERTICAL | **GRID** | GRID shows the four moves in a 2×2 layout. VERTICAL lists the four moves from top to bottom. |
| **MOVE INFO** | ON / OFF | **OFF** | Shows the selected move's type, PP, power, and accuracy beside the move list. OFF gives the move names the full panel width. |

### Reset Battle settings

The Battle submenu includes:

**RESET TO DEFAULT → RESET**

This restores the KIM Battle submenu options to their defined defaults without resetting the unrelated main-menu settings.

---

## Battle Art compatibility

**Battle Art is optional and is not bundled with Kanto in Motion.**

KIM supports the current Battle Art 1.11.x-style cooperative battle path on desktop and mobile.

With Battle Art's 3D battle mode active:

- Battle Art owns the 3D world, camera, terrain, and scene presentation.
- KIM can supply the HD animated Pokémon.
- KIM can supply integrated move animations.
- KIM can provide its Modern lower battle UI and battle HUD integration.
- `3D PKMN SIZE = 100%` is KIM's neutral Battle Art reference.
- `PLAYER PKMN SIZE` remains a separate player-only fine adjustment.
- Mobile uses KIM's separate confirmed mobile preparation/calibration path.

KIM does **not** bundle Battle Art's assets.

## PotatoVoxel compatibility

PotatoVoxel is optional and is not bundled with KIM.

KIM can cooperate with PotatoVoxel on desktop and mobile while PotatoVoxel retains ownership of its voxel arena/camera.

Supported KIM features include:

- HD animated battlers
- Selected player trainer
- Integrated move animations
- Modern Battle UI
- KIM HUD geometry
- Shiny encounter presentation
- Quality of Life EXP/caught overlay alignment where compatible
- KIM's Potato camera pullback
- Separate mobile enemy-size calibration

The confirmed desktop neutral `3D PKMN SIZE = 100%` baseline is preserved internally; the user-facing size control is intended for preference adjustments rather than correcting a broken baseline.

## HGSS_SPRITES compatibility

KIM contains a **KIM-side HGSS battle hard block**.

When:

```text
KIM → BATTLE SYSTEM = ON
```

KIM bypasses HGSS_SPRITES' Gen 1 battle-side hooks so HGSS cannot interfere with:

- KIM/Battle Art trainer sizing
- Pokémon battle sizing
- KIM battle sprite ownership
- Battle trainer replacement
- Battle scale resolution
- Battle Art trainer handoff

HGSS remains free to provide its:

- Overworld player/NPC presentation
- Overworld Pokémon-related presentation
- Menu/icon presentation
- Other non-battle features

When:

```text
KIM → BATTLE SYSTEM = OFF
```

KIM releases battle ownership and HGSS's normal battle behavior is allowed again.

No HGSS files are modified by this compatibility layer.

## Typed Move Colors compatibility

When **Typed Move Colors** is installed, KIM's Modern move menu can reuse the external mod's own effectiveness result rather than maintaining a separate competing calculation.

KIM mirrors the compatible effectiveness symbol inside its move presentation while leaving Typed Move Colors itself unmodified.

## Quality of Life compatibility

KIM does not modify Quality of Life.

Compatible EXP and already-caught overlays remain source-owned. KIM exports the battle/HUD geometry needed to keep those overlays aligned with KIM presentation where supported.

## Overworld Wild Spawns / Wilds compatibility

Compatible overworld wild-spawn mods remain the owners of spawning, movement, water behavior, and overworld art.

KIM can provide the shiny identity so a visible shiny overworld Pokémon keeps the same shiny state when entering battle or being captured.

## Useful Bag compatibility

KIM preserves Useful Bag's inventory behavior while preventing competing duplicate presentation on supported Modern UI paths.

Useful Bag itself is not bundled or modified.

## Spanish translation compatibility

KIM's Modern UI recognizes the Gen 1 Poké Mart through stable menu behavior rather than depending only on English `BUY / SELL / QUIT` labels.

This allows compatible translated shop text to remain translation-owned.

## Advanced Box System compatibility

Advanced Box System keeps ownership of box/storage behavior.

On supported screens KIM can provide animated Pokémon presentation for the selected Pokémon preview without taking over the storage logic.

## Weather FX compatibility

KIM recognizes compatible Weather FX settings screens inside the Modern UI manager while Weather FX remains the owner of its settings and weather behavior.

---

## Compatibility

- **Gen1Recomp mod API:** 2
- **Declared Gen1Recomp range:** `0.0.0-dev || >=0.1.69 <3.0.0`
- **Games in v1.4.2:** Pokémon Red / Blue / Yellow
- **Full battle Pokémon support:** #001–151
- **Gen 2 game support:** not included in the current release
- **Battle Art:** optional external compatibility mod
- **PotatoVoxel:** optional external compatibility mod
- **HGSS_SPRITES:** supported through KIM's battle hard-block behavior
- **Link-relevant gameplay data:** unchanged (`affects_link: false`)

Because KIM uses Gen1Recomp's `engine_internals` permission for its battle/UI integration, a sufficiently large future engine refactor may still require a KIM update even though the broader manifest range allows the mod to load.

## Installation

1. Download the current Kanto in Motion release ZIP.
2. Import/install it through Gen1Recomp's Mods interface.
3. Enable **Kanto in Motion**.
4. Open **KANTO IN MOTION** in the mod settings to configure its presentation.
5. Use **BATTLE → OPEN** for battle-specific options.

### Updating from an older Kanto in Motion

Replace the older Kanto in Motion package with the new release rather than layering old test patches underneath it.

The internal ID remains:

```text
animated_menu_pokemon
```

so compatible saved KIM settings can carry forward.

If upgrading from the old **Animated Menu Pokémon** project, remove/disable the old package first because it uses the same internal mod ID.

---

## HD Pokémon asset source

Animated Pokémon battle sprites:

- **Source:** Battle Sprites Reloded
- **Creator:** JDChaos
- **Original thread:** https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/
- Used for front/back, normal/shiny, and available male/female variants.

## Credits and acknowledgements

Kanto in Motion includes, integrates, or adapts work from several community projects. Credit for the original work belongs to its respective authors.

- **Gen1 Modern UI — ArmstrongThomas**  
  https://github.com/ArmstrongThomas/gen1-modern-ui  
  KIM's integrated Gen 1 Modern UI is a heavily customized project build derived from this foundation.

- **Kanto Rework Battle Animations / Kanto Rework Suite — Faendra**  
  https://github.com/Faendra/kanto-rework-suite  
  KIM's integrated Gen 1 move-animation bridge and related animation lineage derive from this work.

- **Pokéball Colorfix — keberos**  
  https://github.com/keberos/pokeball-colorfix  
  KIM integrates the Gen 1 Poké Ball presentation behavior needed by its battle path.

- **Animated Trainer Card badges — xpixelpriorx**  
  Animated earned-badge artwork used by KIM's Trainer Card presentation.

- **Gen 9 Move Animation Project — KRLW890 and contributors**  
  https://www.eeveeexpo.com/resources/1480/  
  Upstream animation-data lineage used by the Kanto Rework / Pokémon Essentials conversion.

- **Animated Pokémon battle sprites — JDChaos / Battle Sprites Reloded**  
  https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/  
  Used for KIM's HD front/back, normal/shiny, and available male/female battle animations.

**Battle Art and PotatoVoxel are optional compatibility targets and are not bundled with Kanto in Motion.**

See `THIRD_PARTY_NOTICES.md` and `ASSET_NOTICES.md` for additional attribution and redistribution information.

## Repository layout

- `main.lua` — KIM settings, battle ownership, animated Pokémon provider, title/menu integration, and compatibility hooks.
- `lib/modern_ui_integrated*.lua` — customized Gen 1 Modern UI presentation.
- `lib/integrated_krba.lua` / `lib/krba_essentials_player*.lua` — integrated Gen 1 move-animation bridge.
- `lib/battle_art_111_compat.lua` — Battle Art cooperative compatibility.
- `lib/potato_voxel_compat.lua` — PotatoVoxel cooperative compatibility.
- `lib/hgss_battle_hard_block.lua` — KIM-side HGSS battle ownership isolation.
- `lib/shiny_encounter_fx*.lua` — shiny encounter sparkle/audio presentation.
- `data/hd_pokemon_sprites.lua` — generated HD Gen 1 Pokémon animation metadata.
- `data/hd_battle_backgrounds.lua` — HD battle-background routing and authored anchors.
- `data/gen1_anims.lua` — integrated Gen 1 move-animation data.
- `assets/battle/hd-pokemon/` — HD Pokémon sprite sheets.
- `assets/battle/backgrounds/hd/` — HD battle background art.
- `assets/animations/` / `assets/sfx/` — integrated move-animation art and sound.
- `assets/trainer_card/badges/` — animated Trainer Card badge art.
- `tools/import_hd_pokemon.py` — HD GIF-to-sprite-sheet importer.
- `THIRD_PARTY_NOTICES.md` / `ASSET_NOTICES.md` — attribution and redistribution notes.
- `CHANGELOG.md` / `RELEASE_NOTES.md` — release history and release-specific changes.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.**

AI assistance has been used for code generation and modification, debugging, documentation, compatibility work, and release preparation. The project maintainer directs the project, decides which changes are retained, and performs the in-game testing used to determine what is released.

## Trademark / affiliation notice

Pokémon and related names, characters, and artwork are trademarks and copyrights of their respective owners.

Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
