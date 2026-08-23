# Kanto in Motion v1.1.3

Kanto in Motion v1.1.3 expands the integrated Modern UI with a redesigned Trainer Card, fixes remaining background/overlay issues, and adds first-party presentation compatibility for the official Useful Bag mod.

## Trainer Card update

- The player portrait in the upper-right now uses the new 64×64 player artwork.
- Unearned badge slots show the matching Gym Leader in Kanto order: Brock, Misty, Lt. Surge, Erika, Koga, Sabrina, Blaine, and the hidden Giovanni silhouette.
- Earned slots replace the Gym Leader with a looping animated badge: Boulder, Cascade, Thunder, Rainbow, Soul, Marsh, Volcano, and Earth.
- Animated Trainer Card badges continue animating independently of the normal Pokémon sprite-animation setting.
- Animated badge artwork is credited to **xpixelpriorx**: https://www.deviantart.com/xpixelpriorx

## Modern UI fixes

- Fixed the SAVE summary card so it always has a complete background instead of exposing the world through the panel body.
- Added opaque transition backdrops for the title CONTINUE summary and Battle Art precache/cache-loading screens where native UI could otherwise show through.

## Useful Bag compatibility

- The official/unmodified Useful Bag can now be used directly with Kanto in Motion.
- When Kanto in Motion's Modern UI Bag presenter is active, Useful Bag's duplicate standalone fullscreen renderer yields automatically.
- Useful Bag still owns its pockets, sorting, capacity, item-use/toss callbacks, and input behavior. Only duplicate visual presentation is suppressed.

All v1.1.2 features remain included.

# Kanto in Motion v1.1.2

Kanto in Motion v1.1.2 improves compatibility with third-party UI overhauls and fixes dialogue presentation in the integrated Modern UI.

## Changes

- Kanto in Motion animations can remain active on compatible Party/Summary and Pokédex screens while **INTEGRATED MODERN UI = OFF**.
- Added a compatibility/provider path for **Colosseum Inspired UI Overhaul** and improved yielding to third-party full UI replacements.
- Fixed the integrated Modern UI occasionally repeating part of the previous NPC dialogue line after advancing text.
- Added README guidance recommending **INTEGRATED MODERN UI = OFF** when using third-party UI overhauls.

# Kanto in Motion v1.1.1

Kanto in Motion v1.1.1 fixes several UI and title-screen issues found after the v1.1.0 Modern UI integration.

## Changes

- Fixed the SAVE presentation on Gen1Recomp 0.2.13.
- Restored separate Kanto in Motion and Modern UI settings pages.
- Improved title-screen Pokémon randomization so all 151 Kanto species cycle in randomized order before repeats.
- Improved Gen 2-5 animated-sprite metadata/layout safety to prevent incorrectly sliced sprites.

All v1.1.0 features remain included.

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
