# Kanto in Motion v1.3.1

v1.3.1 is a compatibility and stability update built from the fixes confirmed after v1.3.0. It keeps Kanto in Motion as the owner of its standalone 2D battle presentation and shiny identity while cleanly separating desktop and mobile behavior when the current unmodified Battle Art 1.10.0 is installed.

## Battle Art 1.10.0 compatibility

- Added an explicit desktop/mobile compatibility split so mobile renderer fixes no longer alter the Windows 3D-BTL path.
- **Windows + 3D-BTL:** fixed the player back-sprite clipping that appeared when opening the Modern move selector.
- **Android/iOS + 3D-BTL:** Battle Art owns only the 3D stage; KIM owns HP/status/party balls and Modern UI owns the lower battle UI.
- Repaired the mobile graphics-state boundary that could overflow the LÖVE stack before touch controls were drawn.
- Restored Battle Art 1.10.0 settings access from KIM's mobile **MODS MENU**.
- Battle Art itself remains optional and unmodified.

## Mobile battle/UI compatibility

- Restored the confirmed Typed Move Colors + Modern UI layering, including suppression of the obsolete native Gen 1 dialog behind the Modern move UI.
- Restored Quality of Life EXP placement using KIM's accepted mobile HUD geometry, including portrait and the 3D-BTL-OFF fullscreen path.
- Preserved the independent party-ball capture/composite path so **HUD COLOR = INVERTED** does not invert Poké Ball outlines or change HUD resolution.
- Retained the accepted mobile portrait/landscape Battle Art/KIM composition and stable animated sprite bridge.

## Shiny ownership

- KIM now owns shiny odds and shiny DVs end-to-end on both desktop and mobile.
- Compatible Wilds / Overworld Wild Spawns uses KIM's shiny identity to select its own shiny overworld artwork.
- The same DVs carry into battle and capture, keeping visible overworld shinies shiny.
- The public Battle Art 1.10.0 no longer needs the older custom `shinyBridge` API used by the maintainer's private Battle Art builds.

## Retained from v1.3.0

- Standalone Gen 1 Battle System with KRS/GEN6/WHITE/OFF arena choices.
- Integrated Kanto Rework move animations and Pokéball Colorfix behavior.
- Gen 2/3/4/5 animated fronts, Gen 3/5 animated backs, animated trainer presentation, and configurable player Pokémon size.
- Configurable shiny odds and one-cycle shiny encounter sparkle/audio.
- Live Modern UI/vanilla ownership switching.
- Gen 2 presentation support and stock Gen2 Clean UI 0.4.1 compatibility.
- Open compatibility registry for cooperating battle/UI mods.

## Compatibility

- Gen1Recomp mod API: **2**
- Declared Gen1Recomp range: **>=0.2.24 <0.3.0**
- Compatibility reconstruction traced against Gen1Recomp **0.2.45** source behavior.
- Games: Red / Blue / Yellow and Gold / Silver / Crystal.
- Battle Art: current unmodified **1.10.0** supported as an optional external renderer.
- Quality of Life, Typed Move Colors, Wilds / Overworld Wild Spawns, Useful Bag, and Gen2 Clean UI remain external compatibility mods and are not redistributed by KIM.

## Release packages

Install **one** package:

- `Kanto-in-Motion-v1.3.1-Full-Assets.zip` — includes the animated Pokémon/title payloads present in the maintainer's working release build.
- `Kanto-in-Motion-v1.3.1-No-Pokemon-Assets.zip` — excludes locally imported Pokémon front/back/title artwork and associated generated sprite metadata; use `tools/import_assets.py` for local artwork.

## Upgrade notes

Replace v1.3.0 (or the v11-v28 test-patch stack) with one complete v1.3.1 package. The internal mod ID remains `animated_menu_pokemon`, so compatible saved KIM options carry forward. Do not install both package variants.

## Credits

- **Battle Art / DramaticShapeVoxelMod — absol89:** https://github.com/absol89/DramaticShapeVoxelMod
- **Kanto Rework Battle Anims + KRS backgrounds — Faendra:** https://github.com/Faendra/kanto-rework-suite
- **Pokéball Colorfix — keberos:** https://github.com/keberos/pokeball-colorfix
- **Gen1 Modern UI — ArmstrongThomas:** https://github.com/ArmstrongThomas/gen1-modern-ui
- **Animated Trainer Card badges — xpixelpriorx:** https://www.deviantart.com/xpixelpriorx
- **Gen 9 Move Animation Project — KRLW890 and contributors:** see `THIRD_PARTY_NOTICES.md` for upstream details.

Kanto in Motion is an unofficial fan-made Gen1Recomp mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.
