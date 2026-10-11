# Kanto in Motion — Older Update Notes

This file contains historical update notes from releases prior to **v1.7.0**. The main README now keeps only v1.7.0 and newer release notes so the current documentation is easier to browse.

## What’s new in v1.6.6

v1.6.6 expands Kanto in Motion's **Unown presentation** across Gen 2 and Gen 3 while keeping the large form artwork in the external Kanto-in-Motion-Assets pack.

- **Gold / Silver / Crystal Unown A-Z:** KIM now follows each individual Unown's native form and displays the matching HD animated letter in supported battle, Summary, and Pokédex presentation paths. The games remain authoritative for Ruins of Alph encounters, puzzle unlock groups, DVs, catches, and Unown form tracking; KIM only changes presentation.
- **Gen 3 Unown A-Z + ! / ?:** FireRed/LeafGreen/Emerald now route all 28 Gen 3 Unown forms to the matching KIM HD art. Gen 3 personality/form selection remains native, including the exclamation and question-mark forms.
- **Front/back + normal/shiny form parity:** each added form has matching front and back animated presentation with normal and shiny variants. Unown A continues to use KIM's existing National Dex #201 asset.
- **External Unown artwork:** the new B-Z/!/? sprite sheets are **not bundled in the KIM mod ZIP**. They live in `Kanto-in-Motion-Assets`, keeping the main KIM package small and consistent with the existing external-HD architecture.
- **Kanto-in-Motion-Assets v1.1.0 additive update:** existing healthy v1.0.0 asset installs only need the smaller v1.1.0 Unown overlay. Fresh installs automatically obtain the v1.0.0 base pack first and then apply v1.1.0.
- **Persistent cache retained:** normal KIM updates still reuse the external asset cache; the full base pack does not need to be downloaded again just to add the new Unown forms.

## What’s new in v1.6.5

v1.6.5 is a focused **Game3 compatibility and presentation-polish** update. The main addition is cooperative **1025Dex** battle-sprite support while keeping KIM's own HD artwork authoritative for the generations it already covers.

- **1025Dex species-source split:** when the optional 1025Dex mod is present and KIM **BATTLE SPRITES** are enabled, National Dex **#001–386** stay on KIM's HD animated battle-sprite path while **#387–1025** use 1025Dex's own battler art. KIM remains the outer presentation router so the same slot is not drawn by both providers.
- **1025Dex player/opponent parity:** the routing rule applies independently to both sides of the battle, preventing the duplicate player-sprite layering that could occur when 1025Dex reclaimed Game3's `frontPic/backPic` provider.
- **KIM grounding for 1025Dex battlers:** post-Gen3 fallback battlers use KIM-managed final placement so they sit on the authored battle floor instead of floating above the platform. Opponent/front fallback sprites receive the confirmed final downward grounding adjustment while player/back placement remains source-correct.
- **KIM shadows for 1025Dex battlers:** #387–1025 fallback sprites use KIM's existing ground-contact shadow system, including the current shadow quality/opacity settings, while 1025Dex continues to own the sprite art itself.
- **Gen 2 mobile arrow gutter:** right-side up/down scroll arrows in Modern UI option/settings screens are moved into a dedicated right gutter so they do not overlap right-column values on mobile layouts.
- **Conditional Game3 KIM ASSETS entry:** FireRed/LeafGreen/Emerald now show **KIM ASSETS** in the native Start Menu only when the shared external HD pack is missing or incomplete. Once the cache validates as healthy, the entry is hidden automatically.
- **No HD asset re-download required:** the persistent external HD asset-cache format is unchanged. Existing healthy asset installs are reused normally.

## What’s new in v1.6.4

v1.6.4 is a focused **Emerald compatibility and responsive-UI polish** update. It also includes a small Gen 2 title/CONTINUE layout repair and a neutral-size recalibration for KIM's Modern Battle UI.

- **Emerald battle presentation compatibility:** when KIM owns the HD/3D battler presentation, Emerald's native alternate 2D front-sprite frames no longer appear over the KIM Pokémon during the entrance/cry sequence. The original cry/timing is preserved and the visual entrance beat is replaced with a small KIM-friendly hop.
- **Emerald HD starter preview:** the opening starter confirmation screen now presents KIM's animated HD Pokémon at final window resolution instead of enlarging a low-resolution Game3 copy. The authored Emerald bag/circle/Poké Ball scene, cursor, text box, Yes/No prompt, and selection logic remain native.
- **Gen 2 CONTINUE card:** the opening save-summary card now reserves enough room for `PLAYER / BADGES / POKéDEX / TIME`, keeping the TIME row above the divider and the `A CONTINUE / B BACK` footer inside the card on smaller windows.
- **Responsive large-font menus:** general Modern UI **FONT SCALE** now tops out at **200%**. Settings, Options, KIM menus, title/main-menu rows, Pack/list rows, descriptions, values, and footer hints use font-aware row/column sizing and scrolling so combinations such as **COMPACT + 75% UI + 200% font** remain readable instead of stacking text into adjacent rows.
- **Large-font selection alignment:** title/main-menu and affected settings/list selection bars use the rendered font height for vertical centering, keeping highlighted text centered as font size increases.
- **Battle UI neutral calibration:** **BATTLE UI SIZE = 100%** remains the displayed/default value, but its physical footprint now matches the former **95%** size. Saved settings do not need to change; 100% is simply the new neutral reference.
- **No HD asset re-download required:** the persistent external HD asset-cache format is unchanged. Existing healthy asset installs are reused normally.

## What’s new in v1.6.3

v1.6.3 is a focused **Gold / Silver / Crystal** compatibility and Modern UI polish update, with the largest changes targeting **Battle Art Voxel Gen2 2.1.x** and responsive Gen 2 menu presentation.

- **Gen 2 Battle Art HD battlers:** KIM now feeds Battle Art higher-resolution 4x battler cards for G/S/C HD Pokémon, reducing the visible pixelation that occurred when the native-sized cards were enlarged in the 3D scene.
- **Gen 2 Battle Art shadows:** KIM HD battlers use KIM-owned, camera-aligned contact shadows on Battle Art's shared battle-floor plane. **PKMN SHADOWS** still controls quality and **SHADOW OPACITY** controls darkness, while Battle Art continues to own the arena, camera, lighting, move effects, and environment.
- **Gen 2 Battle Art native HUD placement:** the actual G/S/C enemy/player HP/status HUD is captured inside Battle Art's widescreen pass and placed at the outer-left / outer-right of the live 3D battlefield. Native names, levels, status, HP/EXP, party-ball timing, and caught-state behavior remain source-owned.
- **Crystal CONTINUE + Battle Art:** resuming a Crystal save after Battle Art's voxel-cache preload no longer re-enters the preload callback instead of the game's native CONTINUE action.
- **Pack description cleanup:** embedded Crystal `<NEXT>` control markers are now rendered as proper description line breaks instead of appearing as literal text.
- **Reliable arrows across Gen 2 Modern UI:** menu navigation arrows, scroll indicators, dialogue/battle continue prompts, clock arrows, and similar controls are now drawn by KIM instead of depending on unsupported font glyphs that could appear as square boxes.
- **Responsive control hints:** Pack, Trainer Card, Pokégear, Options, KIM Settings, Pokédex, Mart/dialog, Dex Radar, and related footer hints now fit their available panel width more safely on mobile and at larger font scales instead of running outside the card.
- **Gen 2 text-token cleanup:** the Start Menu Pokémon description now displays **Party POKéMON status** instead of exposing the internal `<PK><MN>` control tokens.
- **Selection-bar alignment:** affected Gen 2 list rows now vertically center their text within the highlight bar, including Start Menu and Pack/CANCEL-style rows. Pokégear and Pokémon Party retain their already-correct presentation.

## What’s new in v1.6.2

v1.6.2 is a multi-generation compatibility and asset-management update focused on the shared HD cache, FR/LG/Game3 presentation, Gen 2 menu behavior, and iOS Battle Art compatibility.

- **Remove and re-download HD assets:** the HD Asset Manager can now delete KIM's cached HD Pokémon/background pack, either to reclaim storage or recover from corrupted assets. After removal, users can download the pack again immediately or reopen the manager later.
- **Portable-mode Asset Manager:** Gen1Recomp portable mode is now supported. KIM uses Gen1Recomp's binary-safe download path and native temporary-file handoff, while final assets continue to live in portable-aware `mod.cache`.
- **FireRed/LeafGreen Asset Manager:** FR/LG gained a native **KIM ASSETS** Start Menu bridge on desktop and mobile so Game3 can populate the shared cache directly. As of v1.6.5, that entry is shown only while the pack is missing/incomplete and hides once the cache is healthy.
- **FR/LG mobile downloads:** Android/iOS FireRed/LeafGreen now reopens the completed ZIP through Gen1Recomp's engine-owned save-directory helper before extraction, fixing the Game3 mobile filesystem mismatch.
- **Gold/Silver/Crystal mobile HD assets:** downloaded Johto HD Pokémon assets, including National Dex #152–251, now resolve correctly from the shared cache on mobile.
- **FR/LG in-battle Party/Summary:** full-screen Party/Summary menus opened during battle keep KIM's final-resolution HD menu Pokémon/icons instead of being overwritten by the underlying battle compositor.
- **FR/LG + GameShark:** KIM prevents a native-sprite provider recursion when **BATTLE SPRITES = OFF**. This compatibility fix is entirely on the KIM side; GameShark is not modified.
- **Gen 2 Start Menu visibility:** larger UI scales/densities now keep the selected native row visible, including the bottom **MODS** and **QUIT** entries.
- **iOS + Battle Art:** the world-only orientation bridge now follows Battle Art's live 3D battlefield at the final world handoff and includes an iOS/LÖVE 12 fallback. KIM's HUD, Modern UI, and touch controls stay outside the flip. Community iPhone/iPad validation is still requested.

## What’s new in v1.6.1

v1.6.1 is a focused post-v1.6.0 compatibility and stability update, with most changes centered on Gen 1 mobile battles.

- **Android / mobile Gen 1 battle stability:** hardened KIM's battle rendering boundaries so failed presentation draws cannot leave unmatched LÖVE graphics-state pushes and later trigger `Maximum stack depth reached`.
- **Controller-equipped Android handhelds:** Modern battle dialogue, commands, move selection, and battle messages no longer depend on virtual TouchControls being visible. Devices such as the Retroid Pocket 6 can keep touch controls hidden while using the built-in controller without losing the lower battle UI.
- **Oak's Lab first rival battle:** restores KIM's packaged `garyfrontplayer` presentation at the corrected mobile scale and suppresses the duplicate native rival image during the battle outro.
- **Gen 1 NEW GAME Modern UI:** Oak's native intro artwork and timing remain source-owned, while the dialogue, choices, and naming child screens can use KIM Modern UI when **INTEGRATED MODERN UI** and the matching UI surface are enabled.
- **Gen 1 PC Modern UI:** the initial `WHICH PC?` menu can now use KIM Modern UI while retaining the native PC item list, callbacks, and Player PC / Bill's PC behavior.
- **iOS + Battle Art compatibility:** adds a narrowly scoped world-canvas orientation correction for the affected Apple/Metal renderer used by current Battle Art builds. Only Battle Art's 3D world is corrected; KIM's HUD, Modern battle UI, and touch controls remain upright. This path is included for community validation because the maintainer does not have iOS hardware for local testing.
- Turning Modern UI off continues to return supported surfaces to their native Gen 1 presentation.

## What’s new in v1.6.0

v1.6.0 is a major presentation, compatibility, and distribution update across all supported game families.

- **Slim core + one-time HD Asset Manager:** the large HD battle Pokémon and HD battle-background pack is now downloaded separately from the official `HaseoSora/Kanto-in-Motion-Assets` release, cached outside the mod folder, and reused by future KIM updates.
- **Expanded Gen 2 Modern UI:** the title/main menu, complete NEW GAME setup flow, dialogue/choices, naming screens, Start Menu and supported menus now use KIM Modern UI when **MODERN UI** is enabled.
- **Gen 2 UI gating fixed:** **MODERN UI** is the master presentation switch, while **MENU UI**, **DIALOGUE UI**, **POKEMON SCREENS**, and battle UI controls remain per-surface opt-outs. Turning Modern UI off restores native G/S/C presentation.
- **Gen 2 Start Menu cleanup:** removes the stray `MAPA` row without leaving a hidden selectable entry.
- **Dex Radar 1.2.0 compatibility:** KIM can present the unmodified Dex Radar mod through Modern UI on both Gen 1 and Gen 2 while leaving all Dex Radar logic untouched.
- **Gen 1 native-fit HD backgrounds:** new **BATTLE BG MODE** options let vanilla/default battlers use KIM HD backgrounds with stock battle coordinates while preserving the full-screen KIM arena for HD battle sprites.
- **Gen 1 battle fixes:** corrected trainer placement/size on the widened field, enemy attack-side ownership for moves such as Growl / Quick Attack / Fury Attack, and cleanup of lingering KRBA BG/FG timing planes.
- **FR/LG fallback and stability:** missing Johto/Hoenn HD battle art now falls back to native FR/LG sprites instead of disappearing, and the `BATTLE SPRITES = OFF` path yields cleanly back to the native provider.
- Preserves native gameplay/state ownership underneath KIM presentation layers in Gen 2 and FR/LG.
