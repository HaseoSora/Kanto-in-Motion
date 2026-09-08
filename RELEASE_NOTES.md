# Kanto in Motion v1.3.5

v1.3.5 focuses on battle UI ownership, Modern UI polish, mobile readability, and external settings compatibility.

## Highlights

- Added **MODERN BATTLE UI** directly to KIM's Battle settings. Turn it OFF to let vanilla or another battle UI mod own commands, moves, and battle dialogue while keeping KIM's battle system, animated sprites, shiny effects, move animations, and HUD available.
- **BATTLE SYSTEM remains ON by default.** Users who intentionally turn it OFF now get a clean compatibility handoff, including releasing KIM's move-animation takeover.
- Refined **BATTLE UI OPACITY**: only the panel background fades now; the pixel frame, borders, dividers, text, and selected controls remain fully opaque.
- Improved large **Pixel Art Font** battle layouts so selectors and MOVE INFO stay aligned and visible at larger text sizes.
- Restored the established **mobile battle-dialog position** for both 3D-BTL ON and OFF.
- Improved **mobile PP text readability and selection inversion**, including bright Typed Move Colors tiles.
- Added **Weather FX Modern UI compatibility** for its custom settings screens, source help text, and live overworld preview while adjusting weather options.
- External compatibility mods remain optional and unmodified.

## Packages

- **Kanto-in-Motion-v1.3.5-Full-Assets.zip** — includes the animated Pokémon/title payload used by the full KIM presentation.
- **Kanto-in-Motion-v1.3.5-No-Pokemon-Assets.zip** — code/UI/battle assets only; compatible Pokémon animation assets can be populated locally with `tools/import_assets.py`.

Install **one** package only. When upgrading, replace the previous Kanto in Motion package rather than layering old test patches underneath it.
