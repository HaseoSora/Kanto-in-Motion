# Kanto in Motion v1.6.4

v1.6.4 focuses on **Emerald compatibility**, **large-font Modern UI responsiveness**, and a few presentation calibrations carried forward from community testing.

## Highlights

- **Emerald battle compatibility** — when KIM owns the HD/3D battler presentation, Emerald's native alternate 2D front-sprite frame is suppressed during the entrance/cry sequence so it no longer overlays the KIM Pokémon. The original cry/timing remains intact, with a small KIM-friendly hop providing the visual beat.
- **Emerald HD starter preview** — Treecko, Torchic, and Mudkip now use KIM's animated HD presentation at final window resolution on the opening starter confirmation screen while Emerald retains ownership of the surrounding scene and selection logic.
- **Gen 2 CONTINUE layout** — the save-summary card now keeps the TIME row, divider, and `A CONTINUE / B BACK` footer separated correctly on smaller layouts.
- **Font scale capped at 200%** — the general Modern UI font range now stops at 2×, including AUTO scaling.
- **Responsive extreme-font layouts** — title/main menu, Options, UI Settings, KIM settings, Pack/list rows, right-side values, descriptions, and footer/control hints now adapt their row spacing, fitting, and scrolling for small-panel/large-font combinations such as COMPACT + 75% UI + 200% font.
- **Selection-bar centering** — affected title/settings/list highlights use rendered font height so the text remains vertically centered at enlarged font sizes.
- **BATTLE UI SIZE recalibrated** — 100% remains the displayed/default value, but now renders at the former 95% physical footprint. Existing saved values are not rewritten.

## Compatibility notes

The persistent external HD asset-cache architecture is unchanged. Existing healthy HD asset installs do **not** need to be downloaded again for v1.6.4.

Emerald compatibility is implemented entirely on the KIM presentation side. Native Emerald battle timing, cry audio, starter-scene input/state, and surrounding Game3 UI remain source-owned.
