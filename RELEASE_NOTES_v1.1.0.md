# Kanto in Motion v1.1.0

Kanto in Motion v1.1.0 integrates the project's customized Gen1 Modern UI build directly into the mod, adds the Crimson theme family, and updates the default battle-UI configuration.

## Integrated Modern UI

- Customized **Gen1 Modern UI 0.9.12 – Central Mod Menu + Title Start** is integrated directly into Kanto in Motion.
- **INTEGRATED MODERN UI = ON** is the default. Turn it OFF and restart when another full UI overhaul should own presentation.
- If **Gen 3 Inspired UI Overhaul** (`gen3_battle_ui`) is active, Kanto in Motion automatically yields its bundled Modern UI while keeping Kanto in Motion's animation/title features active.
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
