# Kanto in Motion

**Kanto in Motion** adds animated Pokémon presentation to Gen1Recomp's menus, Pokédex, evolution sequence, and Red/Blue title screen.

It is the public-release continuation of **Animated Menu Pokémon 0.1.26**. The internal mod ID remains `animated_menu_pokemon` so existing settings and compatible Gen1 Modern UI integrations can continue to identify the mod.

> **Asset-free public release:** this repository intentionally contains no Pokémon-derived sprite atlases. Players import compatible animated sprite assets into their own local installation with the included `tools/import_assets.py` utility.

## Features

- Animated **Gen 2, Gen 3, Gen 4, or Gen 5** front-sprite support.
- **Gen 5** selected by default.
- Animated Pokémon on the stock **Summary/Status** screen.
- Animated Pokémon on stock **Pokédex entry** screens.
- Optional **Gen1 Modern UI** integration for Party, Summary, Pokédex list preview, Pokédex entry, and evolution presentation.
- Animated **evolution sequence** using the selected sprite generation for both the old and evolved Pokémon.
- Red/Blue title-screen Pokémon can use the selected animated sprite generation.
- Title-screen pool expanded to **all 151 Kanto Pokémon**.
- Random title selection avoids the **24 most recently displayed species** whenever possible.
- Adjustable title cycle speed: **NORMAL**, **SLOW**, or **SLOWER**.
- Optional locally imported animated **Red trainer** title presentation: forward → reverse → 5-second pause → repeat.
- Optional locally imported custom **Gen1Recomp++** title logo while retaining the stock **Red Version** subtitle.
- Balanced title rendering designed to retain pixel-art detail on high-resolution displays.
- Missing imported artwork falls back safely to Gen1Recomp's normal Gen 1 sprite instead of breaking the screen.

## Standalone asset setup

Kanto in Motion has **no runtime Battle Art dependency**. Once compatible sprite assets have been imported into your local copy, Kanto in Motion runs by itself.

The public repository cannot include the Pokémon-derived sprite artwork, so use the included importer with a compatible source folder or ZIP that you already possess. The importer currently recognizes:

- packages using the common Battle Art animated-front layout (`animated_battle_sprites_gen2.lua` through `gen5` plus `assets/battle/front-animated/`), and
- older full Animated Menu Pokémon / Kanto in Motion packages using `animated_menu_sprites_gen*.lua`.

Example with a ZIP:

```bash
python tools/import_assets.py "path/to/compatible-sprite-source.zip"
```

Example with an extracted folder:

```bash
python tools/import_assets.py "path/to/compatible-sprite-source"
```

The importer copies only into **your local Kanto in Motion installation**. It does not download anything and does not modify the source package.

### Related projects

- **Battle Art / DramaticShapeVoxelMod:** https://github.com/absol89/DramaticShapeVoxelMod  
  Kanto in Motion does **not** require Battle Art at runtime. However, if a user already has a compatible Battle Art package locally, its animated front-sprite layout can be used as an import source.
- **Gen1 Modern UI:** https://github.com/ArmstrongThomas/gen1-modern-ui  
  Modern UI is optional. When installed, compatible builds can display Kanto in Motion sprites in additional Party, Summary, Pokédex, and evolution UI views.

### Optional title extras

If you have a legacy Animated Menu Pokémon / Kanto in Motion package containing the custom animated Red title asset and Gen1Recomp++ title logo, you can import those too:

```bash
python tools/import_assets.py "path/to/compatible-sprite-source.zip" \
  --title-source "path/to/Animated-Menu-Pokemon-0.1.26.zip"
```

Locally imported files are covered by `.gitignore` and should **not** be committed to a public fork or attached to a public release.

## Options

Settings are available under **OPTIONS → KANTO IN MOTION** (or through a compatible centralized Mod Menu).

| Setting | Choices | Default |
| --- | --- | --- |
| Menu Sprites | ON / OFF | ON |
| Sprite Gen | GEN 2 / GEN 3 / GEN 4 / GEN 5 | GEN 5 |
| Animation | ON / OFF | ON |
| Title Screen | ON / OFF | ON |
| Title Cycle Speed | NORMAL / SLOW / SLOWER | SLOW |

Turning **Animation** off keeps the selected sprite generation but holds a single frame.

## Title-screen extras

The public repository does **not** include Pokémon-derived title artwork. The animated title Pokémon use the same locally imported Gen 2-5 sprite library as the menu and Pokédex features.

The custom animated Red/title-logo extras activate only when those files have also been imported locally. Pokémon Yellow's special Pikachu title composition is left unchanged.

## Gen1 Modern UI integration

Gen1 Modern UI is optional. Kanto in Motion exports its selected animated artwork through the legacy internal ID `animated_menu_pokemon`, allowing compatible Modern UI builds to use the same sprites in Party, Summary, Pokédex, and evolution screens.

Older Modern UI builds may still display the legacy label **ANIMATED MENU PKMN**. That label is cosmetic.

## Compatibility

- Gen1Recomp mod API: **2**
- Game target: **Gen 1**
- Declared engine range: **>= 0.1.98 and < 2.0.0**
- Gen1 Modern UI: optional
- Battle Art: **not required at runtime**
- Link-relevant gameplay data: unchanged (`affects_link: false`)

Because the mod uses `engine_internals` to integrate with existing UI states, large Gen1Recomp UI refactors can require a compatibility update even when the manifest range still accepts the engine.

## Installation

1. Download the GitHub release ZIP.
2. Import/extract it as a Gen1Recomp mod.
3. Run `tools/import_assets.py` once against a compatible local sprite source.
4. Enable Kanto in Motion and choose your sprite generation/settings.

Without locally imported Gen 2-5 assets, the mod still loads safely and leaves Gen1Recomp's normal Gen 1 artwork in place.

### Upgrading from Animated Menu Pokémon 0.1.26

Remove or disable the old Animated Menu Pokémon package before enabling Kanto in Motion. Do not enable both at the same time because they share the same internal mod ID.

The internal ID intentionally remains `animated_menu_pokemon` so existing option values and compatible Modern UI integrations remain compatible.

## Publishing / development

This repository is prepared around the Gen1Recomp publishing rules:

- `manifest.json` includes a semver version, description, game/profile metadata, link declaration, and `github: "HaseoSora/Kanto-in-Motion"`.
- `DIFFERENCES.md` documents deliberate vanilla divergences.
- `.github/workflows/release.yml` is generated from Gen1Recomp's `modkit` release workflow.
- Public source/release archives contain no locally imported Pokémon sprite/title payloads.
- `tools/check_public_package.py` can be run before publishing to catch accidentally included local payloads.

Recommended pre-release checks from a Gen1Recomp source tree:

```bash
python tools/modkit.py validate /path/to/animated_menu_pokemon --strict
python tools/modkit.py lint /path/to/animated_menu_pokemon
```

The Gen1Recomp publishing guide is available at:
https://github.com/bryanthaboi/gen1recomp/wiki/Guide-Publishing

## Repository layout

- `main.lua` — menu, Pokédex, evolution, title-screen animation, and Modern UI export integration.
- `manifest.json` — Gen1Recomp metadata and GitHub update identity.
- `tools/import_assets.py` — local-only animated asset importer.
- `tools/check_public_package.py` — public-tree safety check.
- `DIFFERENCES.md` — deliberate differences from vanilla.
- `ASSET_NOTICES.md` — asset/publication policy.
- `CHANGELOG.md` — release history.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.** AI assistance was used for code generation and modification, debugging, documentation, and release preparation. The project maintainer directs the project, chooses which changes to keep, and performs the in-game testing used to determine what is released.

Pokémon artwork that a player chooses to import is **not included in this public repository or release**, and this disclosure does not claim ownership of third-party artwork.

## Trademark / affiliation notice

Pokémon and related names/characters are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
