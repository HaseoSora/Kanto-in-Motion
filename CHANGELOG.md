# Changelog

## 1.1.0

- Added **INTEGRATED MODERN UI** (default **ON**) so Kanto in Motion's bundled Modern UI can be disabled without disabling animated sprites, evolution art, or title-screen features.
- Added compatibility yielding for **Gen 3 Inspired UI Overhaul** (`gen3_battle_ui`): when that mod is active, Kanto in Motion automatically suppresses its bundled Modern UI layer.
- Added `gen3_battle_ui` as an optional dependency to guarantee load order for automatic detection without making it required.
- Documented that changing the integrated-UI switch requires a restart because UI hooks are installed at startup.
- Integrated the project's customized **Gen1 Modern UI 0.9.12 – Central Mod Menu + Title Start** build directly into Kanto in Motion.
- Added **Crimson** and **Crimson Glass** themes to the integrated Modern UI.
- Set the new-install Modern UI battle defaults to **MODERN BATTLE UI = ON**, **BATTLE UI SCOPE = ITEMS + POKEMON**, and **LEAVE 3D BATTLES ALONE = OFF**.
- Expanded the README with a detailed explanation of **LEAVE 3D BATTLES ALONE** and how it interacts with 3D/voxel battles and BATTLE UI SCOPE.
- Unified Kanto in Motion and Modern UI settings under the `animated_menu_pokemon` mod identity.
- Integrated UI consumes Kanto in Motion's animated sprite provider directly for supported Party, Summary, Pokédex, evolution, and related views.
- Retained the customized Modern UI battle Items/Pokémon flow, nickname, level-up-stat, centralized Mod Menu, and title/start Mod Menu behavior.
- Added explicit ArmstrongThomas / Gen1 Modern UI credit and upstream repository link.
- Standalone `gen1_modern_ui` and `gen1_clean_ui` are declared conflicts to avoid duplicate UI ownership.
- Public package remains free of Pokémon-derived sprite/title payloads.

## 1.0.0

- Renamed the public project from Animated Menu Pokémon to **Kanto in Motion**.
- Preserved internal mod ID `animated_menu_pokemon` for compatibility.
- Added Gen 2 / Gen 3 / Gen 4 / Gen 5 animated menu-sprite generation selection.
- Added stock Summary and Pokédex entry integration.
- Added optional Gen1 Modern UI integration through Kanto in Motion's exported sprite interface.
- Added animated evolution artwork support.
- Added all-151 Red/Blue title Pokémon cycling with a 24-species recent-history exclusion.
- Added NORMAL / SLOW / SLOWER title cycle settings.
- Retained optional animated Red title presentation and custom Gen1Recomp++ title logo when those assets are supplied locally.
- Added local-only `tools/import_assets.py` workflow so Kanto in Motion has no runtime Battle Art dependency and can remain standalone after local asset import.
- Added `DIFFERENCES.md`, public-package safety checks, GitHub repository metadata, and Gen1Recomp release workflow support.
- Removed Pokémon-derived sprite/title payloads from the public source/release tree.
- Added an AI development disclosure to the README.
