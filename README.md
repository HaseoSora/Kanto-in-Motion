# Kanto in Motion

**Kanto in Motion** adds animated Pokémon presentation to Gen1Recomp and now supports both **Gen 1** and **Gen 2** games.

The internal mod ID remains `animated_menu_pokemon`, preserving compatibility with existing Kanto in Motion / Animated Menu Pokémon settings and integrations.

## v1.2.0 highlights

- **Gen 1:** Red, Blue, and Yellow support is retained.
- **Gen 2:** Gold, Silver, and Crystal are now supported on Gen1Recomp 0.2.24.
- Gen 1 keeps Kanto in Motion's integrated customized **Gen1 Modern UI 0.9.12**.
- The Gen 1 Modern UI preference defaults **ON**, but if a player turns it **OFF**, that choice is remembered on future Gen 1 launches.
- On Gen 2, Kanto in Motion's bundled Modern UI is automatically suppressed. The normal Gen 2 UI or an installed **stock Gen2 Clean UI 0.4.1** remains the UI owner.
- Stock Gen2 Clean UI does **not** need to be modified for Kanto in Motion.
- Kanto in Motion can feed live animated Pokémon portraits into stock Gen2 Clean UI. Animated **Status/Summary** has been confirmed in real Gen 2 testing; compatibility hooks are also included for Party, Pokédex, and Evolution presentation.
- The Gen 1 Poké Mart BUY/SELL flow is recognized by the integrated Modern UI instead of falling back to the original Gen 1 shop presentation.

## Animated Pokémon features

- Animated **Gen 2, Gen 3, Gen 4, or Gen 5** front-sprite support.
- **Gen 5** selected by default.
- Animated Pokémon on supported Summary/Status, Pokédex, Party, and evolution presentation surfaces.
- Red/Blue title-screen Pokémon can use the selected animated sprite generation.
- Red/Blue title pool includes all **151 Kanto Pokémon**.
- Random title selection avoids the **24 most recently displayed species** whenever possible.
- Adjustable title cycle speed: **NORMAL**, **SLOW**, or **SLOWER**.
- Optional animated Red title presentation: forward → reverse → 5-second pause → repeat.
- Missing imported artwork falls back safely instead of breaking the screen.

## Gen 1 UI behavior

Kanto in Motion includes the customized **Gen1 Modern UI 0.9.12** build used by this project.

On Gen 1 only, **INTEGRATED MODERN UI** is available in Kanto in Motion settings:

- New/default install: **ON**
- If manually changed to **OFF**, the setting remains OFF on later Gen 1 launches.
- Launching a Gen 2 game does not overwrite the saved Gen 1 preference.
- Returning to Gen 1 restores the player's saved Gen 1 choice.

The integrated UI covers supported responsive menus, Party, Summary, Pokédex, Bag, PC, Trainer Card, dialogue, battle Items/Pokémon flow, nickname flow, level-up stats, and the centralized Mod Menu.

### Gen 1 Poké Mart fix

v1.2.0 recognizes Gen1Recomp's custom `ShopMenu` draw path so the Poké Mart BUY/SELL flow can remain in Modern UI instead of unexpectedly exposing the original Gen 1 UI.

## Gen 2 UI behavior

On Gen 2, Kanto in Motion's bundled Modern UI is always **OFF**. This is intentional because Gen 2 uses a separate UI/state implementation.

Kanto in Motion continues to provide animated Pokémon presentation while yielding interface ownership to:

- Gen1Recomp's native Gen 2 UI, or
- the original/unmodified **Gen2 Clean UI 0.4.1** when installed.

The Gen2 Clean UI compatibility is implemented entirely from the Kanto in Motion side; users do **not** need a modified Clean UI package.

Animated Status/Summary is confirmed working in Gold/Crystal testing. Party, Pokédex, and Evolution bridges are included but should still be treated as screen-by-screen compatibility until each flow has been exercised in-game.

## Options

Settings are available under **OPTIONS → KANTO IN MOTION** or through a compatible centralized Mod Menu.

| Setting | Choices | Default | Notes |
| --- | --- | --- | --- |
| Menu Sprites | ON / OFF | ON | Both generations |
| Integrated Modern UI | ON / OFF | ON | **Gen 1 only**; saved preference |
| Sprite Gen | GEN 2 / GEN 3 / GEN 4 / GEN 5 | GEN 5 | Both generations |
| Animation | ON / OFF | ON | Both generations |
| Title Screen | ON / OFF | ON | Gen 1 title support |
| Title Cycle Speed | NORMAL / SLOW / SLOWER | SLOW | Gen 1 title support |

Turning **Animation** off keeps the selected sprite generation but holds a single frame.

## Two release packages

v1.2.0 is provided in two ZIPs. Install **one or the other**, not both.

### Full Assets

`Kanto-in-Motion-v1.2.0-Full-Assets.zip`

Includes the animated Pokémon/title assets present in the maintainer's release build, so no local asset import is required for those included sets.

### No Pokémon Assets

`Kanto-in-Motion-v1.2.0-No-Pokemon-Assets.zip`

Contains the mod code, integrated UI, Trainer Card presentation assets, and importer, but excludes locally imported Pokémon battle/title payloads.

Import compatible assets with:

```bash
python tools/import_assets.py "path/to/compatible-sprite-source.zip"
```

or:

```bash
python tools/import_assets.py "path/to/compatible-sprite-source"
```

## Trainer Card credit

The animated Trainer Card badge artwork is credited to **xpixelpriorx**:

https://www.deviantart.com/xpixelpriorx

Thank you to xpixelpriorx for the animated badge artwork used by Kanto in Motion's earned-badge presentation.

## Modern UI credit

The Gen1 Modern UI foundation was created by **ArmstrongThomas**:

https://github.com/ArmstrongThomas/gen1-modern-ui

Kanto in Motion integrates the customized local 0.9.12-based build used by this project. See `THIRD_PARTY_NOTICES.md` for additional attribution and redistribution notes.

## Compatibility

- Gen1Recomp mod API: **2**
- Games: **Gen 1 + Gen 2**
- Gen 1 carts: **Red / Blue / Yellow**
- Gen 2 carts: **Gold / Silver / Crystal**
- Tested engine target for this release: **Gen1Recomp 0.2.24**
- Declared engine range: **>= 0.2.24 and < 0.3.0**
- Gen1 Modern UI: integrated customized **0.9.12** build
- Gen2 Clean UI: original/unmodified **0.4.1** supported
- Battle Art: **not required at runtime**
- Useful Bag: official/unmodified releases supported on the Gen 1 integrated-UI path
- Link-relevant gameplay data: unchanged (`affects_link: false`)

Because Kanto in Motion uses `engine_internals` for UI integration, large Gen1Recomp UI refactors may require an update even when the manifest version range still accepts the engine.

## Installation

1. Download **one** v1.2.0 ZIP: Full Assets or No Pokémon Assets.
2. Import/extract it as a Gen1Recomp mod.
3. If using the no-assets package, run `tools/import_assets.py` against a compatible local sprite source.
4. Enable Kanto in Motion.
5. Gen 1 uses the player's saved Gen 1 Modern UI preference.
6. Gen 2 automatically suppresses Kanto in Motion's Modern UI and uses the native Gen 2 UI or stock Gen2 Clean UI.

Do not enable a separate `gen1_modern_ui` or `gen1_clean_ui` alongside Kanto in Motion's Gen 1 integrated UI.

### Upgrading from older Kanto in Motion

Replace the older Kanto in Motion package with v1.2.0. The internal ID remains `animated_menu_pokemon`, so compatible saved mod options can carry forward.

If upgrading from **Animated Menu Pokémon 0.1.26**, remove/disable the old package before enabling Kanto in Motion because they share the same internal mod ID.

## Repository layout

- `main.lua` — generation detection, animated sprite provider, stock-screen hooks, title animation, Gen2 compatibility bridges, and UI bootstrap.
- `lib/modern_ui_integrated.lua` — customized Gen1 Modern UI integration.
- `lib/modern_ui_gen2.lua` — retained Gen2 compatibility support code; bundled Modern UI ownership remains suppressed on Gen2 in v1.2.0.
- `assets/pixel_frame*.png` — integrated Modern UI frame assets.
- `assets/trainer_card/` — Trainer Card presentation assets.
- `tools/import_assets.py` — local animated-asset importer.
- `manifest.json` — Gen1Recomp metadata.
- `DIFFERENCES.md` — deliberate presentation differences.
- `ASSET_NOTICES.md` — asset and redistribution notes.
- `CHANGELOG.md` — release history.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.** AI assistance was used for code generation and modification, debugging, documentation, and release preparation. The project maintainer directs the project, chooses which changes to keep, and performs the in-game testing used to determine what is released.

## Trademark / affiliation notice

Pokémon and related names, characters, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
