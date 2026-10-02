# Changelog

## v1.6.2

- Added HD Asset Manager removal/re-download support for the persistent external HD Pokémon/background cache. Removed assets can be downloaded again immediately or later; KIM does not force a new download after removal.
- Added Gen1Recomp portable-mode Asset Manager support using the engine's binary-safe downloader and native temporary-file handoff while keeping final assets in portable-aware `mod.cache`.
- Added a native FireRed/LeafGreen **KIM ASSETS** Start Menu entry for downloading, removing, and re-downloading the shared HD pack.
- Fixed Android/iOS FR/LG asset downloads by reopening the engine-owned temporary ZIP through Gen1Recomp's native save-directory helper before extraction.
- Corrected FR/LG installed-pack controls to **A = REMOVE / B = CLOSE**, with a second **A** confirmation before deletion.
- Fixed Gold/Silver/Crystal mobile lookup of downloaded National Dex #152–251 HD assets so the external pack is actually used after a successful download.
- Fixed FR/LG in-battle Party/Summary presentation so KIM's battle compositor no longer overwrites final-resolution HD menu Pokémon/icons while a full-screen Game3 menu owns the frame.
- Added a KIM-side FR/LG provider-cycle guard for GameShark when **BATTLE SPRITES = OFF**, preventing recursive native-sprite delegation without changing GameShark.
- Fixed the Gen 2 Modern Start Menu at larger UI scales/densities so the selected native row always remains visible, including **MODS** and **QUIT**.
- Reworked the iOS/LÖVE 12 Battle Art orientation bridge at the final world handoff. The correction follows Battle Art's live 3D world directly, uses Battle Art-compatible canvas handling, and leaves KIM HUD/UI/touch layers unflipped.

## v1.6.1

- Hardened Gen 1 Android/mobile battle rendering against graphics-state leaks that could accumulate into `Maximum stack depth reached`.
- Decoupled the Gen 1 Modern battle dialog/command layout from virtual TouchControls visibility so controller-equipped Android devices keep the lower battle UI with touch controls hidden.
- Restored the first Oak's Lab rival intro using KIM's packaged `garyfrontplayer` art at the corrected mobile scale and suppressed the duplicate native rival image during the outro.
- Expanded Gen 1 NEW GAME Modern UI coverage while keeping Oak's native intro artwork/timing and source game state ownership intact.
- Added KIM Modern UI presentation for the initial Gen 1 `WHICH PC?` menu while preserving native PC rows, callbacks, Player PC, and Bill's PC behavior.
- Added a narrowly scoped iOS Battle Art world-orientation compatibility bridge for the affected Apple/Metal renderer, based on Battle Art's current world-canvas correction strategy. KIM HUD/UI layers remain unflipped.
- Preserved native presentation when Modern UI or the applicable per-surface setting is disabled.
- Gen 2/Crystal and Gen 3/FireRed-LeafGreen battle paths remain unchanged by the Gen 1 mobile fixes.

## v1.6.0

- Split large HD battle artwork from the normal KIM ZIP and added the in-game HD Asset Manager with persistent caching.
- Moved the large HD battle asset pack to persistent external cache so users download it once on v1.6.0 and reuse it across future KIM updates.
- Expanded Gen 2 Modern UI to the title/main menu and complete NEW GAME setup flow.
- Fixed Gen 2 Modern UI master/per-surface gating and removed the stray MAPA Start Menu row.
- Added presentation-only Dex Radar 1.2.0 compatibility on Gen 1 and Gen 2 without modifying Dex Radar.
- Added Gen 1 BATTLE BG MODE with AUTO / FULLSCREEN / NATIVE FIT framing for HD or vanilla battlers.
- Corrected Gen 1 widened-field trainer placement/size, enemy move-side animation ownership, and lingering KRBA BG/FG planes.
- Improved FR/LG missing-HD fallback and BATTLE SPRITES OFF stability.
- Restored the small local battle-support/trainer assets required by the slim core.

## v1.5.0

- Added Gold / Silver / Crystal and FireRed / LeafGreen support paths.
- Added HD animated Pokémon support through #251 in G/S/C and #386 in FR/LG.
- Added HD Pokémon icons #001–386 across all supported games.
- Added `POKEMON ICONS` ON/OFF control.
- Added G/S/C native-battle HD Pokémon integration.
- Added FR/LG HD battles, menu/Pokédex/Summary previews, and HD battle-background support.
- Added final-resolution G/S/C and FR/LG menu rendering.
- Fixed FR/LG mobile duplicate HUD/menu rendering, portrait/landscape placement, `SCREEN POS`, and menu Pokémon alignment.
- Improved HGSS_SPRITES icon ownership and Gen 1 battle isolation.
- Preserved existing Gen 1 Battle Art and PotatoVoxel compatibility.

## v1.4.1

- Added Gen1Recomp 0.3.1 compatibility.
- Added HGSS_SPRITES Gen 1 battle hard block.
- Preserved Battle Art and PotatoVoxel compatibility.

## v1.4.0

- Public Gen 1 HD battle release.
- Added the Gen 1 HD animated Pokémon battle pipeline and HD battle backgrounds.
