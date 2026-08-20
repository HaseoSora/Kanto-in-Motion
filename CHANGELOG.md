# Changelog

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
