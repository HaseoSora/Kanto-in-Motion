# Kanto in Motion v1.3.6

v1.3.6 is a focused battle-animation and Pokédex Modern UI update built on the v1.3.5 release.

## Highlights

- Fixed **KRS / GEN6 attack-animation targeting** so effects use KIM's actual rendered battler positions instead of legacy wide-stage target coordinates.
- Target-local effects such as **Slash** and **Gust** now stay attached to the opponent, while travelling attacks follow the live attacker-to-target line.
- Effect anchors now follow the same species-aware center, scale, shake, and lunge transforms used by KIM's animated battlers.
- Fixed the **Pokédex entry submenu** so selecting a known Pokémon stays inside Modern UI instead of revealing the classic Pokédex.
- DATA / CRY / AREA / QUIT remain source-functional while being presented through Modern UI; Yellow's PRNT row is also supported.
- Pokédex submenu recognition does not depend on English labels, preserving localization compatibility.
- Retains all v1.3.5 battle UI ownership, opacity, font fitting, mobile dialog/PP, and Weather FX compatibility changes.

## Packages

- **Kanto-in-Motion-v1.3.6-Full-Assets.zip**
- **Kanto-in-Motion-v1.3.6-No-Pokemon-Assets.zip**

Install **one** package only. Replace the previous Kanto in Motion package rather than layering old test patches underneath it.

---

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
