# Kanto in Motion v1.3.4

v1.3.4 focuses on battle presentation customization, PC/mobile stability, and compatibility with external UI, localization, and storage mods.

## Highlights

- Improved **battle system stability across PC and mobile**, including more consistent animated battler handoff and rendering behavior.
- Added **BATTLE UI SIZE** (60%–100%) and **BATTLE UI OPACITY** (25%–100%) controls for the lower command, move, and message panel.
- Added **HUD SIZE** (60%–100%) and **HUD OPACITY** (25%–100%) controls for the battle HP/status HUD.
- Updated compatible **Quality of Life EXP and already-caught overlays** so they stay aligned with resized HUD geometry on desktop and mobile, including portrait and landscape layouts.
- Removed the extra lower-field void-cover filler when **3D-BTL is OFF** and KIM's own 2D battle system is active.
- Added **Spanish translation compatibility** for the Modern UI Poké Mart path without modifying the Spanish translation mod. Shop detection no longer depends on English BUY/SELL/QUIT labels.
- Added **Advanced Box System compatibility** without modifying Advanced Box System. Its Pokémon browser can use KIM's animated front-sprite presentation for the selected Pokémon preview.
- External compatibility mods remain optional and unmodified.

## Packages

- **Kanto-in-Motion-v1.3.4-Full-Assets.zip** — includes the animated Pokémon/title payload used by the full KIM presentation.
- **Kanto-in-Motion-v1.3.4-No-Pokemon-Assets.zip** — code/UI/battle assets only; compatible Pokémon animation assets can be populated locally with `tools/import_assets.py`.

Install **one** package only. When upgrading, replace the previous Kanto in Motion package rather than layering old test patches underneath it.
