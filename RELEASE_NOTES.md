# Kanto in Motion v1.5.0

v1.5.0 is the multi-generation HD update.

## Highlights

- Added Kanto in Motion support for **Gold / Silver / Crystal** and **FireRed / LeafGreen** alongside the existing Red / Blue / Yellow implementation.
- Added HD animated Pokémon support through **#251 in G/S/C** and **#386 in FR/LG**.
- Added **HD Pokémon icons #001–386** across R/B/Y, G/S/C, and FR/LG with a live `POKEMON ICONS` toggle.
- Added final-resolution G/S/C and FR/LG icon rendering to avoid native-canvas pixelation.
- Added HD animated G/S/C battle Pokémon while keeping the native Gen 2 HUD, trainers, commands, backgrounds, and move animations.
- Added FR/LG HD battle Pokémon, menu/Pokédex/Summary previews, and optional HD battle backgrounds while preserving the native FR/LG UI and move-animation engine.
- Fixed FR/LG mobile portrait/landscape rendering, duplicate battle HUD/menu presentation, `SCREEN POS` alignment, and menu Pokémon placement.
- Improved HGSS_SPRITES compatibility so KIM can own its icon and Gen 1 battle paths without HGSS overriding them.
- Preserves the existing Gen 1 Battle Art and PotatoVoxel compatibility paths.

## Updating

Replace your previous Kanto in Motion package with v1.5.0.

The internal mod ID remains `animated_menu_pokemon`, so existing KIM settings can carry forward.
