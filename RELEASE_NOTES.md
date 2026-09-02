# Kanto in Motion v1.3.2

v1.3.2 is a stability/corrective release built from the final v7 test tree confirmed after v1.3.1.

## Highlights

- Fixed the **Full Assets clean-install package** so animated Pokémon menu/status/Pokédex/evolution/title assets and generated metadata are actually included.
- Finalized the **Battle Art 1.10.0 PC/mobile split**.
  - **PC:** retains the confirmed 3D-BTL player-back presentation and restored mouse camera steering.
  - **Android/iOS:** uses the confirmed v20/v25 stage-only mobile path rather than the experimental ownership/camera overrides.
- Fixed **3D-BTL animated battler anchoring** so animation frames do not make the whole Pokémon sway around the battlefield.
- Restored the stable **mobile move-animation handoff** after testing normal attacks and status moves.
- Retains the v1.3.1 fixes for **Modern UI + Typed Move Colors**, mobile **Quality of Life EXP**, Battle Art **MODS MENU** access, party Poké Ball/HUD presentation, PC FIGHT-menu clipping, and KIM-owned shiny/Wilds identity.
- Keeps Battle Art 1.10.0 and other compatibility mods external and unmodified.

## Packages

- **Kanto-in-Motion-v1.3.2-Full-Assets.zip** — self-contained animated Pokémon/title payload included.
- **Kanto-in-Motion-v1.3.2-No-Pokemon-Assets.zip** — code/UI/battle assets only; populate compatible Pokémon animation assets locally with `tools/import_assets.py`.

Install **one** package only. When upgrading, replace the old KIM package instead of layering the v1.3.1 test patches underneath it.

## Credits

- Battle Art / DramaticShapeVoxelMod — **absol89**
- Kanto Rework Battle Anims + KRS — **Faendra**
- Pokéball Colorfix — **keberos**
- Gen1 Modern UI foundation — **ArmstrongThomas**
- Animated Trainer Card badges — **xpixelpriorx** — https://www.deviantart.com/xpixelpriorx

See `THIRD_PARTY_NOTICES.md` and `ASSET_NOTICES.md` for complete attribution and redistribution notes.
