# Kanto in Motion v1.3.7

v1.3.7 is a major compatibility update centered on **PotatoVoxel PC/mobile support** and cleaner ownership handoffs between Kanto in Motion and external presentation mods.

## Highlights

- Added confirmed **PotatoVoxel compatibility on desktop and mobile**. PotatoVoxel keeps the 3D arena/camera while KIM can provide animated battlers, KRBA move animations, HP/status HUD, Modern Battle UI, and compatible overlays.
- Fixed **Typed Move Colors + Modern Battle UI** with PotatoVoxel so only one move selector is shown while KIM still uses Typed Move Colors' colors/effectiveness information.
- Restored **Quality of Life EXP and already-caught indicators** on the PotatoVoxel path, including mobile portrait/landscape handling and correct desktop placement for short Pokémon names.
- Fixed the **mobile trainer intro** when `BATTLE SYSTEM = OFF` + `MODERN BATTLE UI = OFF`, including the PotatoVoxel pinned/BACK SPRITES path.
- Fixed **mobile portrait player-Pokémon placement** when KIM sprites are used with PotatoVoxel.
- Added KIM's **shiny encounter sparkle and audio** to PotatoVoxel battles on both desktop and mobile.
- Included the **Useful Bag compatibility fix** so KIM suppresses the duplicate standalone bag presenter while Useful Bag keeps ownership of its pockets, sorting, capacity, controls, callbacks, and inventory behavior.
- All compatibility work remains **KIM-side**: PotatoVoxel, Typed Move Colors, Quality of Life, Useful Bag, Battle Art, and other external packages are not modified or bundled.

## Packages

- **Kanto-in-Motion-v1.3.7-Full-Assets.zip**
- **Kanto-in-Motion-v1.3.7-No-Pokemon-Assets.zip**

Install **one** package only. Replace the previous Kanto in Motion package instead of layering older test patches underneath it.

---

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
