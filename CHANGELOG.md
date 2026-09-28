# Changelog

## v1.5.3

- Added a dedicated Gen 2 UI SETTINGS submenu inside KANTO IN MOTION.
- Added applicable Gen 1 UI customization parity for G/S/C: themes, frame controls, density, UI scale, font scale, font selection, dialogue scale, layout, panel/text opacity, Start Menu controls, minimal UI, and per-surface toggles.
- Changed Gen 2's default Modern UI font from the forced pixel font to the normal scalable font; PIXEL ART FONT can still be enabled manually.
- Added Gen 2 UI SCALE with 100% calibrated to a cleaner Gen 1-like footprint.
- Replaced the Gen 2 MENU SPRITES ON/OFF behavior with KIM HD / VANILLA source selection.
- Added native G/S/C sprite fallback for menu/Party/Pokédex presentation so vanilla sprites remain visible when KIM HD menu sprites are not selected.
- Kept menu sprite source, UI sprite animation, HD icons, and battle sprites independently configurable.
- Moved Gen 2 Modern Battle UI size/opacity/text/layout/info controls into UI SETTINGS.
- Added RESET TO DEFAULT to the Gen 2 UI SETTINGS submenu.
- Preserved native Gen 2 gameplay/battle state ownership and the native HP/status HUD.

## v1.5.2

- Added integrated Modern UI presentation for Gold / Silver / Crystal.
- Added Gen 2 Modern UI coverage for battle dialogue/commands/moves, Start Menu, Party, Pokédex, Pack, PokéGear, Trainer Card, Save, Options, KIM settings, shops, common dialogue, choice prompts, and supported level-up/stat messages.
- Added Gen 2 UI themes matching KIM's Gen 1 Modern UI palettes.
- Added Gen 2 BATTLE UI SIZE, BATTLE UI OPACITY, BATTLE TEXT SIZE, MOVE LAYOUT, and MOVE INFO controls.
- Integrated the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter into KIM's Gen 2 Pokédex presentation.
- Improved Gen 2 menu/dialog readability, spacing, shop presentation, save/quit prompts, and option submenu presentation.
- Removed Gen 1 title-animation settings from the Gen 2 settings page.
- Preserved native Gen 2 battle logic, HP/status HUD, trainers, backgrounds, move animations, save logic, shop logic, and option logic underneath KIM's presentation layer.

## v1.5.1

- Added Pokémon shadows to Gold / Silver / Crystal.
- Added Pokémon shadows to FireRed / LeafGreen.
- Added PKMN SHADOWS and SHADOW OPACITY settings to G/S/C and FR/LG.
- FR/LG shadows now follow Pokémon during send-out/slide movement.
- Restored the missing `data/hd_pokemon_national.lua` metadata file for clean-install Gen 2 HD sprite support.
- Preserved v1.5.0 mobile/desktop rendering and compatibility behavior.

## v1.5.0

- Added Gold / Silver / Crystal support.
- Added FireRed / LeafGreen support.
- Added HD animated Pokémon through #251 in G/S/C and #386 in FR/LG.
- Added HD Pokémon icons #001–386 across all supported games.
- Added the POKEMON ICONS setting.
- Added final-resolution G/S/C and FR/LG icon/menu rendering.
- Added FR/LG HD battle Pokémon, menu/Pokédex/Summary previews, and HD battle-background support.
- Fixed FR/LG mobile duplicate HUD/menu rendering, portrait/landscape placement, SCREEN POS, and menu Pokémon alignment.
- Improved HGSS_SPRITES compatibility while preserving existing Gen 1 Battle Art and PotatoVoxel support.
