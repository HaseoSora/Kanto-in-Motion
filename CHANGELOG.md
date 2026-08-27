# Changelog

## 1.2.0

- Added Gen 2 game targeting for Gold, Silver, and Crystal on the Gen1Recomp 0.2.24 architecture.
- Added generation-aware UI ownership: Gen 1 uses the saved Gen 1 Modern UI preference while Gen 2 automatically suppresses Kanto in Motion's bundled Modern UI.
- Restored the Gen 1 `INTEGRATED MODERN UI` toggle as a saved Gen 1-only preference; new installs default ON, and a manual OFF persists across later Gen 1 launches.
- Added compatibility with the original/unmodified Gen2 Clean UI 0.4.1.
- Added stock Gen2 Clean UI live animated portrait bridging without requiring Clean UI to be patched.
- Confirmed animated Gen 2 Status/Summary portraits in real Gold/Crystal testing.
- Added Gen 2 portrait compatibility hooks for Party, Pokédex, and Evolution presentation.
- Fixed Gen 1 Poké Mart BUY/SELL screens falling back to the original Gen 1 UI by recognizing Gen1Recomp's custom ShopMenu draw path.
- Preserved the v1.1.4 Trainer Card, animated badge, Useful Bag, stock Gen1 animated portrait, and centralized Mod Menu work.
- Added two release package variants: Full Assets and No Pokémon Assets.

## 1.1.4

- Fixed stock Gen1 Pokédex animated portraits when **INTEGRATED MODERN UI = OFF** and retained safe fallback to the native Gen1 sprite when animated art is unavailable.
- Fixed stock Gen1 Pokémon STATUS/Summary so the selected Gen 2/3/4/5 animated portrait is shown instead of falling back to the native Gen1 portrait.
- Constrained oversized animated portraits to the stock **56×56** Pokédex/STATUS portrait area without enlarging smaller sprites, preventing large species such as Charizard from overflowing the classic UI.
- Fixed the optional **START MENU PARTY VIEW** companion card so its full panel background is drawn instead of leaving party rows floating over the overworld.
- Added a compatibility fallback for legacy/unknown mods: mod-authored OPTIONS and Start-menu rows are preserved when Kanto in Motion cannot confidently represent that mod inside the centralized **MOD MENU**.

## 1.1.3

- Added the new Trainer Card presentation: custom player portrait, Gym Leader art for unearned badge slots, and looping animated earned-badge icons.
- Added the revised Giovanni silhouette used for the hidden eighth Gym Leader slot so it remains readable with the Crimson theme while preserving the secret-leader presentation.
- Added explicit credit to **xpixelpriorx** for the animated badge artwork.
- Fixed the in-game SAVE summary panel so its Modern UI card always has a complete theme-colored background.
- Added Modern UI background cleanup for the title CONTINUE summary and Battle Art precache/cache-loading transition screens so native UI does not show through.
- Added built-in compatibility with official/unmodified **Useful Bag** releases: Kanto in Motion suppresses Useful Bag's duplicate standalone bag presenter while preserving Useful Bag's pockets, sorting, capacity, controls, callbacks, and inventory behavior.
- Added Useful Bag as an optional dependency so presentation-hook ordering is deterministic when both mods are installed.

## 1.1.2

- Added independent resolved-sprite animation bridging for compatible third-party UI overhauls so Party/Summary and Pokédex front art can remain animated with Integrated Modern UI disabled.
- Added a portrait-provider integration path for Colosseum Inspired UI Overhaul compatibility builds.
- Added automatic Colosseum UI detection/yielding and documented that Integrated Modern UI should be disabled when using third-party full UI overhauls.
- Fixed Modern UI dialogue progression retaining and recomposing an already-consumed native TextBox line after manual CONT/page advances.

## 1.1.1

- Fixed the central Mod Menu `TYPED MOVE COLORS -> SETTINGS` entry so builds that use manifest option schemas open correctly instead of doing nothing. Authored Typed Move Colors settings screens are still preferred when present.
- Restored Kanto in Motion's own settings in the centralized Mod Menu. `KANTO IN MOTION` now opens separate `KANTO SETTINGS` and `MODERN UI SETTINGS` entries instead of routing directly into only the Modern UI option categories.
- Direct Mod Manager access now presents Kanto in Motion controls in a dedicated `KANTO IN MOTION` category, while the Modern UI child page remains focused on Modern UI settings.
- Fixed the Gen1Recomp 0.2.13 SAVE confirmation layout so the integrated Modern UI recognizes the anonymous save-info panel and keeps the Start menu, save summary, prompt, and YES/NO choice in one coherent widescreen-safe composition.
- The underlying Gen1Recomp save logic and timing are unchanged; this patch only replaces the broken split presentation.
- Reworked title-screen species selection into a shuffled 151-Pokémon rotation so every Kanto species is shown before the pool repeats.
- Improved Gen 2 / Gen 3 / Gen 4 / Gen 5 animation metadata and atlas-layout validation so incompatible frame layouts fall back safely instead of being sliced incorrectly.

## 1.1.0
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
