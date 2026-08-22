# Kanto in Motion v1.1.1

Kanto in Motion v1.1.1 is a focused compatibility patch for the integrated Modern UI introduced in v1.1.0.

## SAVE screen fix

- Fixed the Gen1Recomp 0.2.13 SAVE confirmation flow reverting to the classic Gen 1 UI and splitting its menu, save summary, dialogue, and YES/NO windows across widescreen displays.
- The integrated Modern UI now recognizes Gen1Recomp's anonymous `PrintSaveScreenText` panel and presents the SAVE flow as one coherent Modern UI composition.
- START → SAVE → confirmation → YES/NO → saving/saved messages now remain visually consistent with the integrated Modern UI.
- The actual save logic, save data, confirmation behavior, and timing are unchanged; this patch only fixes presentation.


## Settings navigation fix

- Restored Kanto in Motion's animation/title settings in the centralized Mod Menu.
- `KANTO IN MOTION` now provides separate **KANTO SETTINGS** and **MODERN UI SETTINGS** entries.
- Opening **MODERN UI SETTINGS** no longer makes Kanto in Motion's own controls appear to be missing.

## Included from v1.1.0

All v1.1.0 features remain intact, including the integrated customized Gen1 Modern UI, Crimson and Crimson Glass themes, configurable integrated-UI toggle, Gen 3 UI-overhaul yielding, animated menu/Pokédex/evolution presentation, and the default battle-UI configuration.

## Credits

The integrated Modern UI foundation was created by **ArmstrongThomas**:
https://github.com/ArmstrongThomas/gen1-modern-ui

See `THIRD_PARTY_NOTICES.md` for attribution details.

# Kanto in Motion v1.1.0

Kanto in Motion v1.1.0 integrates the project's customized Gen1 Modern UI build directly into the mod, adds the Crimson theme family, and updates the default battle-UI configuration.

## Integrated Modern UI

- Customized **Gen1 Modern UI 0.9.12 – Central Mod Menu + Title Start** is integrated directly into Kanto in Motion.
- A separate `gen1_modern_ui` install should not be enabled alongside this release.
- Kanto in Motion's animated sprite provider is shared directly with supported Party, Summary, Pokédex, evolution, and related Modern UI surfaces.

## New themes

- **Crimson** — Gen1 Modern layout with a saturated crimson pixel border/accent and a deep blackish-red backdrop and panels.
- **Crimson Glass** — the same crimson palette with translucent black-red backdrop and panel layers so the game world remains visible beneath the UI.

## Default battle UI settings

New installs default to:

- **MODERN BATTLE UI = ON**
- **BATTLE UI SCOPE = ITEMS + POKEMON**
- **LEAVE 3D BATTLES ALONE = OFF**

With these settings, supported Items/Pokemon battle flows can use Modern UI even during detected 3D/voxel battles, while the 3D arena, camera, Pokemon placement, attack animations, FIGHT command, and move-selection presentation remain with the existing 3D battle presentation. See the README for the full explanation of the 3D-battle compatibility switch.

## Modern UI credit

The Gen1 Modern UI foundation was created by **ArmstrongThomas**:
https://github.com/ArmstrongThomas/gen1-modern-ui

Kanto in Motion uses a project-customized integrated build; see `THIRD_PARTY_NOTICES.md` for attribution details.


# Kanto in Motion v1.0.0

First public release of **Kanto in Motion**, continuing the Animated Menu Pokémon project under its new name.

## Highlights

- Gen 2-5 animated front-sprite presentation for menus, Pokédex, evolution, and Red/Blue title Pokémon.
- All-151 randomized Kanto title pool with recent-history repeat avoidance.
- Adjustable title cycle speed.
- Optional Gen1 Modern UI integration.
- Standalone local-import workflow through `tools/import_assets.py`; no special Battle Art build is required at runtime.
- Safe vanilla fallback when no compatible artwork has been imported.
- Publishing-ready repository metadata for `HaseoSora/Kanto-in-Motion`.
- Public source/release archives intentionally contain no Pokémon-derived sprite/title payloads.
- README includes an AI development disclosure.

The internal ID remains `animated_menu_pokemon` for compatibility with prior settings and integrations.
