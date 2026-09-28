# Kanto in Motion v1.5.3

v1.5.3 is the **Gen 2 UI parity** update for Kanto in Motion's Gold / Silver / Crystal Modern UI.

## Highlights

- Added a dedicated **UI SETTINGS** submenu inside KANTO IN MOTION for Gen 2.
- Brought over the applicable Gen 1 Modern UI customization controls, including theme, frame style, density, UI scale, font scale, opacity, layout, Start Menu, minimal-UI, and per-surface controls.
- Added **PIXEL ART FONT** as an option instead of forcing the pixel font; the normal scalable font is now the Gen 2 default.
- Added **UI SCALE** with 100% calibrated to a cleaner Gen 1-like footprint.
- Added independent **MENU SPRITES: KIM HD / VANILLA** selection.
- Added native Gen 2 sprite fallback so disabling KIM menu artwork no longer leaves blank Pokémon preview areas.
- Kept menu sprite source, sprite animation, HD icons, and battle sprites independently configurable.
- Grouped Gen 2 Modern Battle UI presentation controls under UI SETTINGS.
- Preserved native G/S/C HP/status HUD, battle logic, trainers, backgrounds, move animations, scripts, shops, save logic, option logic, and state transitions.

## Updating

Replace the previous Kanto in Motion code with v1.5.3. The internal mod ID remains `animated_menu_pokemon`, so compatible saved settings can carry forward.

This release package is **code-only** because the large existing KIM art payload was not part of the development upload. Keep the asset folders from your existing full KIM installation when applying this package.
