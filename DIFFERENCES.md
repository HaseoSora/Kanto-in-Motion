# Kanto in Motion v1.6.2 scope

Compared with v1.6.1, v1.6.2 is a multi-generation compatibility and asset-management update.

- Adds removal and later re-download of KIM's cached external HD Pokémon/background pack.
- Adds HD Asset Manager support for Gen1Recomp portable mode without changing the persistent `mod.cache` architecture.
- Gives FireRed/LeafGreen its own native **KIM ASSETS** Start Menu entry and fixes Android/iOS FR/LG asset downloading.
- Fixes Gold/Silver/Crystal mobile use of already-downloaded external HD Pokémon assets, including National Dex #152–251.
- Keeps FR/LG HD party/menu Pokémon visible when the Party/Summary screen is opened during battle.
- Adds a KIM-side FR/LG compatibility guard for GameShark when **BATTLE SPRITES = OFF**; GameShark itself is not modified.
- Fixes the Gen 2 Modern Start Menu so bottom rows such as **MODS** and **QUIT** stay visible/selectable at larger UI scales/densities.
- Strengthens the iOS Battle Art world-orientation bridge while keeping KIM HUD/UI/touch layers outside the correction.

The v1.6.0 persistent external HD asset cache remains in place, and normal KIM code updates do not require users to redownload an already-installed pack.
