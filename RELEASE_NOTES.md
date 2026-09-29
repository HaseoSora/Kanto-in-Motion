# Kanto in Motion v1.6.0

v1.6.0 is a major presentation, compatibility, and distribution update.

## Highlights

- **Slim KIM core + one-time HD Asset Manager** — large HD Pokémon battle sprites and HD battle backgrounds now live in the separate Kanto-in-Motion-Assets release and are cached persistently after install.
- **Expanded Gen 2 Modern UI** — Modern UI now covers the title/main menu and the complete NEW GAME setup flow, including Crystal gender choice, clock setup, Oak/Elm dialogue, player-name selection, naming keyboard, and final intro text.
- **Modern UI master gating** — turning MODERN UI off restores native G/S/C presentation; MENU UI, DIALOGUE UI, POKEMON SCREENS, and battle presentation remain per-surface controls while Modern UI is on.
- **Gen 2 Start Menu cleanup** — removes the stray MAPA row without leaving a hidden cursor target.
- **Dex Radar 1.2.0 compatibility** — KIM can present the unmodified Dex Radar mod through Modern UI on both Gen 1 and Gen 2 while Dex Radar retains all encounter/input/state logic.
- **Gen 1 BATTLE BG MODE** — AUTO / FULLSCREEN / NATIVE FIT supports KIM HD arenas with either HD battlers or stock/native battler coordinates.
- **Gen 1 battle corrections** — improved widened-field trainer placement, restored native trainer size, corrected enemy move-side animation ownership, and fixed lingering animation BG/FG planes.
- **FR/LG fallback/stability** — missing HD battle art now falls back to native sprites; BATTLE SPRITES OFF yields directly to the native FR/LG provider.
- Keeps Battle Art, PotatoVoxel, HGSS_SPRITES, Typed Move Colors, Useful Bag, Advanced Box System, translations, and other existing compatibility paths.

## Updating

Install **Kanto-in-Motion-v1.6.0.zip** normally. If the HD battle pack is not already cached, KIM's Asset Manager will offer the one-time download on first launch.

Users upgrading from v1.5.x or earlier will need to download the external HD asset pack once as part of the transition to the new slim architecture. After that first v1.6.0 asset install, the pack remains in persistent cache and normal KIM updates no longer redownload it.

## Asset pack

The external HD pack is hosted at **HaseoSora/Kanto-in-Motion-Assets**. The normal KIM package still includes all small battle-support assets, trainer art, UI assets, icons, move-animation resources, and code required to start safely with or without the optional HD pack.

## Notes

The internal mod ID remains `animated_menu_pokemon`, so compatible settings continue to carry forward.
