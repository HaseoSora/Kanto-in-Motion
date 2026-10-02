# Kanto in Motion v1.6.2

v1.6.2 is a compatibility and asset-management update across Red/Blue/Yellow, Gold/Silver/Crystal, and FireRed/LeafGreen.

## Highlights

- **HD Asset Manager maintenance** — installed HD Pokémon/background assets can now be removed from KIM's persistent cache and downloaded again later. This gives users a built-in recovery path for corrupted assets and an easy way to reclaim storage.
- **Portable mode support** — the Asset Manager now works with Gen1Recomp portable mode while keeping final assets in the same persistent `mod.cache` architecture.
- **FireRed/LeafGreen Asset Manager** — FR/LG now exposes **KIM ASSETS** directly in its native Start Menu on desktop and mobile. Android/iOS uses an engine-owned temporary ZIP handoff so FR/LG can download and install the pack itself instead of relying on another game to populate the shared cache.
- **Gold/Silver/Crystal mobile asset use** — downloaded HD Pokémon assets, including Johto National Dex #152–251, now resolve correctly on mobile.
- **FR/LG in-battle Party/Summary fix** — opening a full-screen Party/Summary menu during battle no longer lets KIM's battle compositor overwrite the final-resolution HD menu Pokémon/icons.
- **FR/LG + GameShark stability** — KIM now prevents a provider-wrapper recursion when **BATTLE SPRITES = OFF**. The GameShark mod is not modified.
- **Gen 2 Start Menu visibility** — the Modern UI keeps the selected native row visible at larger UI scales/densities, including the bottom **MODS** and **QUIT** rows.
- **iOS Battle Art orientation compatibility** — the world-only correction now follows Battle Art's live 3D battlefield at the final world handoff and includes an iOS/LÖVE 12 fallback. KIM's HUD, Modern UI, and touch controls remain unflipped.

## iOS testing note

The strengthened iOS Battle Art compatibility path is included for community validation because the Kanto in Motion maintainer does not have local iPhone/iPad hardware for direct testing. If Battle Art still renders upside down, include screenshots and the Gen1Recomp log when reporting it.

## Existing HD asset installs

The v1.6.0 persistent asset-cache architecture is unchanged. If the HD pack is already installed and healthy, updating KIM to v1.6.2 does **not** require downloading it again.
