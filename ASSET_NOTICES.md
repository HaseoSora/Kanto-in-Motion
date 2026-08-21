# Asset Notices

The **public Kanto in Motion repository and release archive do not include Pokémon-derived sprite atlases, extracted game art, ROM images, patches, or locally imported title artwork**.

Kanto in Motion uses a local import workflow. A player may use `tools/import_assets.py` to copy compatible artwork/metadata from files they already possess into their own local Kanto in Motion installation.

Files produced by the local import workflow are intentionally covered by `.gitignore` and should not be committed or attached to public releases.

The following local paths are treated as generated/user-supplied state and are excluded from the public source package:

- `assets/battle/front-animated/`
- `assets/title/`
- `data/animated_menu_sprites_gen2.lua`
- `data/animated_menu_sprites_gen3.lua`
- `data/animated_menu_sprites_gen4.lua`
- `data/animated_menu_sprites_gen5.lua`
- `data/title_player_red.lua`

Kanto in Motion's source code does not grant rights to third-party or Pokémon artwork that a player chooses to import locally.

Pokémon and related characters, names, and artwork are trademarks and copyrights of their respective owners. Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.

## Integrated Modern UI assets

The `assets/pixel_frame1.png`, `assets/pixel_frame2.png`, and `assets/pixel_frame3.png` files come from the customized Gen1 Modern UI build used by this project. Original project credit: ArmstrongThomas — https://github.com/ArmstrongThomas/gen1-modern-ui. See `THIRD_PARTY_NOTICES.md`.
