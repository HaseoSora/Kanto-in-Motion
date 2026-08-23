# Kanto in Motion

**Kanto in Motion** combines animated Pokémon presentation with the customized **Gen1 Modern UI 0.9.12** build used by this project, so the animation features and Modern UI install as one mod.

It is the public-release continuation of **Animated Menu Pokémon 0.1.26**. The internal mod ID remains `animated_menu_pokemon` so existing settings and compatible Gen1 Modern UI integrations can continue to identify the mod.

> **Local battle/title sprite workflow:** this repository intentionally contains no imported Gen 2-5 Pokémon battle-sprite atlases or custom title artwork. Players import those compatible assets into their own local installation with the included `tools/import_assets.py` utility. Kanto in Motion v1.1.3 does include the small Trainer Card presentation assets used by its new Gym Leader / badge display; see the credits and `ASSET_NOTICES.md`.

## Features

- Animated **Gen 2, Gen 3, Gen 4, or Gen 5** front-sprite support.
- **Gen 5** selected by default.
- Animated Pokémon on the stock **Summary/Status** screen.
- Animated Pokémon on stock **Pokédex entry** screens.
- Integrated customized **Gen1 Modern UI 0.9.12** presentation for responsive menus, Party, Summary, Pokédex, Bag, PC, Trainer Card, dialogue, battle Items/Pokémon flow, nickname flow, level-up stats, and the centralized Mod Menu.
- Animated **evolution sequence** using the selected sprite generation for both the old and evolved Pokémon.
- Red/Blue title-screen Pokémon can use the selected animated sprite generation.
- Title-screen pool expanded to **all 151 Kanto Pokémon**.
- Random title selection avoids the **24 most recently displayed species** whenever possible.
- Adjustable title cycle speed: **NORMAL**, **SLOW**, or **SLOWER**.
- Each newly selected title-screen Pokémon has a **30% chance** to use its shiny artwork when compatible shiny assets are available.
- Optional locally imported animated **Red trainer** title presentation: forward → reverse → 5-second pause → repeat.
- Optional locally imported custom **Gen1Recomp++** title logo while retaining the stock **Red Version** subtitle.
- Balanced title rendering designed to retain pixel-art detail on high-resolution displays.
- Missing imported artwork falls back safely to Gen1Recomp's normal Gen 1 sprite instead of breaking the screen.
- Trainer Card refresh: custom player portrait, Gym Leader silhouettes/portraits for unearned slots, and animated earned-badge icons.
- Built-in compatibility with the official **Useful Bag** mod so its inventory behavior remains active while Kanto in Motion's Modern UI owns the visual Bag presentation instead of showing two menus at once.

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
- **Gen1 Modern UI — original project by [ArmstrongThomas](https://github.com/ArmstrongThomas/gen1-modern-ui/commits?author=ArmstrongThomas):** https://github.com/ArmstrongThomas/gen1-modern-ui  
  Kanto in Motion v1.1.0 integrates the project's customized local **Gen1 Modern UI 0.9.12** build. The Modern UI foundation and original project are credited to **ArmstrongThomas**; visit the repository above for the original project and history.

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

## Integrated Gen1 Modern UI

Kanto in Motion v1.1.0 includes the customized **Gen1 Modern UI 0.9.12 – Central Mod Menu + Title Start** build used by this project. A separate `gen1_modern_ui` install is no longer required and should not be enabled alongside this version.

> **Using a third-party UI overhaul?** Set **INTEGRATED MODERN UI = OFF** in **KANTO SETTINGS** and restart the game before using another full interface replacement. Kanto in Motion's animation provider and title-screen features remain active with the integrated UI disabled. Recognized overhauls such as **Colosseum Inspired UI Overhaul** and the Gen 3 UI overhaul are also detected automatically so Kanto in Motion can yield UI ownership. Compatible third-party screens that use Gen1Recomp's resolved Pokémon sprite pipeline can still receive Kanto in Motion's animated Party/Summary and Pokédex art.

The integrated UI consumes Kanto in Motion's animated sprite provider directly, so the selected Gen 2/3/4/5 animation source is shared across Party, Summary/Status, Pokédex, Pokédex entry, evolution, and other supported Modern UI surfaces. The customized battle Items/Pokémon scope, nickname flow, enlarged level-up-stat card, centralized Mod Menu, and title/start Mod Menu changes are retained.

### Crimson themes

The integrated theme selector also includes **Crimson** and **Crimson Glass**. Crimson keeps the Gen1 Modern layout but replaces the blue chrome with a saturated crimson pixel border/accent and a blackish-red backdrop. Crimson Glass uses the same palette with translucent backdrop and panel layers so the world can remain visible behind the UI.

### Default battle UI settings

Kanto in Motion ships with the customized Modern UI battle settings set to:

- **MODERN BATTLE UI = ON**
- **BATTLE UI SCOPE = ITEMS + POKEMON**
- **LEAVE 3D BATTLES ALONE = OFF**

With these defaults, ordinary FIGHT/move selection stays with the game's existing battle presentation, while supported in-battle **Items/Bag** and **Pokemon/Party** flows use Modern UI. The same scoped integration can also cover supported battle child screens such as level-up stats, caught-Pokedex pages, nickname prompts, evolution, and move learning.

#### What does LEAVE 3D BATTLES ALONE do?

This setting is a compatibility switch for Battle Art/voxel and other detected 3D battle presentations:

- **ON** — Modern UI completely backs out of detected 3D battles. The 3D battle mod/native battle presentation keeps control of the battle UI and its child screens. Use this if another 3D battle mod has UI conflicts with Modern UI.
- **OFF** — Modern UI is allowed to participate in detected 3D battles, but only according to **BATTLE UI SCOPE**. With the default **ITEMS + POKEMON** scope, the 3D arena, camera, Pokemon placement, attack animations, FIGHT command, and move-selection presentation are left alone; Modern UI handles the supported Items/Pokemon and related child flows instead. If **BATTLE UI SCOPE** is changed to **FULL**, Modern UI may also replace more of the battle HUD/menu/text overlay while the actual 3D arena and animations remain owned by the 3D battle mod.

The default is **OFF** because Kanto in Motion is configured to let its Modern UI Items/Pokemon presentation work during 3D battles without replacing the 3D scene itself.

### Modern UI credit

The Gen1 Modern UI foundation was created by **[ArmstrongThomas](https://github.com/ArmstrongThomas/gen1-modern-ui/commits?author=ArmstrongThomas)**. Kanto in Motion's integrated version is based on the customized local build used by this project. Original repository:

https://github.com/ArmstrongThomas/gen1-modern-ui

See `THIRD_PARTY_NOTICES.md` for additional attribution and redistribution notes.

### Trainer Card animated badge credit

The animated Trainer Card badge artwork included with Kanto in Motion v1.1.3 is credited to **xpixelpriorx**. Their DeviantArt page is:

https://www.deviantart.com/xpixelpriorx

These badge animations are used for the earned-badge presentation on the Trainer Card.

## Compatibility

- Gen1Recomp mod API: **2**
- Game target: **Gen 1**
- Declared engine range: **>= 0.1.98 and < 2.0.0**
- Gen1 Modern UI: **integrated customized 0.9.12 build**; do not enable the standalone Modern UI mod at the same time
- Battle Art: **not required at runtime**
- Useful Bag: **official/unmodified releases supported**; when Integrated Modern UI is active, Kanto in Motion yields Useful Bag's duplicate standalone bag renderer while preserving its pockets, sorting, capacity, inputs, and item callbacks.
- Link-relevant gameplay data: unchanged (`affects_link: false`)

Because the mod uses `engine_internals` to integrate with existing UI states, large Gen1Recomp UI refactors can require a compatibility update even when the manifest range still accepts the engine.

## Installation

1. Download the GitHub release ZIP.
2. Import/extract it as a Gen1Recomp mod.
3. Run `tools/import_assets.py` once against a compatible local sprite source.
4. Disable/remove any separate `gen1_modern_ui` install, then enable Kanto in Motion and choose your animation/UI settings.

Without locally imported Gen 2-5 assets, the mod still loads safely and leaves Gen1Recomp's normal Gen 1 artwork in place.

### Upgrading from Animated Menu Pokémon 0.1.26

Remove or disable the old Animated Menu Pokémon package before enabling Kanto in Motion. Do not enable both at the same time because they share the same internal mod ID.

The internal ID intentionally remains `animated_menu_pokemon` so existing option values and compatible Modern UI integrations remain compatible.

## Publishing / development

This repository is prepared around the Gen1Recomp publishing rules:

- `manifest.json` includes a semver version, description, game/profile metadata, link declaration, and `github: "HaseoSora/Kanto-in-Motion"`.
- `DIFFERENCES.md` documents deliberate vanilla divergences.
- `.github/workflows/release.yml` is generated from Gen1Recomp's `modkit` release workflow.
- Public source/release archives contain no locally imported Gen 2-5 battle-sprite atlases or custom title payloads. The v1.1.3 Trainer Card presentation assets are intentional release assets and are documented in `ASSET_NOTICES.md`.
- `tools/check_public_package.py` can be run before publishing to catch accidentally included local payloads.

Recommended pre-release checks from a Gen1Recomp source tree:

```bash
python tools/modkit.py validate /path/to/animated_menu_pokemon --strict
python tools/modkit.py lint /path/to/animated_menu_pokemon
```

The Gen1Recomp publishing guide is available at:
https://github.com/bryanthaboi/gen1recomp/wiki/Guide-Publishing

## Repository layout

- `main.lua` — animated sprite provider, stock-screen animation hooks, title-screen animation, and integrated UI bootstrap.
- `lib/modern_ui_integrated.lua` — customized Gen1 Modern UI 0.9.12 integration.
- `assets/pixel_frame*.png` — Modern UI pixel-frame assets from the customized UI build.
- `manifest.json` — Gen1Recomp metadata and GitHub update identity.
- `tools/import_assets.py` — local-only animated asset importer.
- `tools/check_public_package.py` — public-tree safety check.
- `DIFFERENCES.md` — deliberate differences from vanilla.
- `ASSET_NOTICES.md` — asset/publication policy.
- `CHANGELOG.md` — release history.

## AI development disclosure

**Kanto in Motion was developed and packaged with substantial assistance from OpenAI ChatGPT.** AI assistance was used for code generation and modification, debugging, documentation, and release preparation. The project maintainer directs the project, chooses which changes to keep, and performs the in-game testing used to determine what is released.

Locally imported Gen 2-5 battle/title artwork is **not included in this public repository or release**. Kanto in Motion v1.1.3 intentionally includes its small Trainer Card presentation set, including animated badge artwork credited to **xpixelpriorx**; this disclosure does not claim ownership of third-party artwork.

## Trademark / affiliation notice

Pokémon and related names/characters are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.

### Save screen compatibility

Gen1Recomp 0.2.13 changed the Gen 1 SAVE flow so the Start menu leaves an anonymous `PrintSaveScreenText` panel on the UI stack underneath the confirmation prompt. Kanto in Motion v1.1.1 recognizes that panel and presents it through the integrated Modern UI, preventing the native Start menu, save-info panel, dialogue box, and YES/NO box from being independently stretched or split across widescreen displays. The underlying Gen1Recomp save logic and timing remain unchanged; only presentation is replaced.

### Settings layout

Under the centralized **MOD MENU**, choose **KANTO IN MOTION** to access two separate settings pages:

- **KANTO SETTINGS** — menu sprites, integrated Modern UI toggle, sprite generation, animation, title-screen animation, and title-cycle speed.
- **MODERN UI SETTINGS** — themes, framing, scale, battle UI scope, 3D-battle behavior, navigation, and other Modern UI presentation options.

This separation keeps Kanto in Motion's animation controls visible while retaining the full integrated Modern UI configuration.

