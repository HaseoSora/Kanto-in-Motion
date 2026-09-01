## 1.3.1

- Promoted the confirmed post-v1.3.0 compatibility work into the public **Kanto in Motion v1.3.1** release.
- Added explicit Windows vs Android/iOS Battle Art 1.10.0 behavior so platform-specific renderer fixes no longer bleed across platforms.
- Fixed PC 3D-BTL player back-sprite clipping while the Modern move selector is open.
- Restored the confirmed mobile Battle Art stage-only handoff, Modern UI/Typed Move Colors layering, Quality of Life EXP geometry, mobile Battle Art MODS MENU access, and graphics-stack safety.
- Preserved party-ball HUD-invert isolation and the stable mobile sprite/animation compositor.
- Made KIM the authoritative shiny odds/DV owner for Wilds overworld spawns, battle, and capture without depending on Battle Art's removed/private shiny bridge.
- Retains the v1.3.0 standalone battle system, KRS/KRBA/Pokéball integration, animated sprite/trainer features, Gen 2 support, and open compatibility API.

## v28 test — compatibility reconstruction from confirmed mobile fixes

- Rebuilt the mobile compatibility layer from the original user-confirmed checkpoints instead of stacking another renderer workaround.
- Restores the exact Battle Art MOD MENU v5 mobile presenter on top of the confirmed Typed-Move-Colors v4 layer; Battle Art 1.10 category rows now open through its own authored OptionsMenu callbacks.
- Reuses the confirmed v8.6.63 KIM player-HUD EXP geometry. With 3D-BTL ON, only Android/iOS portrait EXP pixels are moved to KIM's real player HUD row; 3D-BTL ON landscape is unchanged.
- Adapts that same EXP geometry to unmodified Battle Art 1.10 when 3D-BTL is OFF by redirecting only QOL's final EXP fill/burst pixels to KIM's existing flat battle canvas. It does not restore `dramaticShapeShot`, wrap `BattleState.draw`, or change Modern UI/native-dialog ownership.
- Keeps the confirmed v20 mobile stage-only/HUD boundary, v22 Windows move-menu clip fix, v24 KIM-owned shiny authority, and v25 mobile renderer restoration.
- `main.lua`, Windows Modern UI, Battle Art, Quality of Life, and Wilds are unchanged.

## v24 test — KIM-owned Wilds shiny authority

- Replaces the temporary v23 Battle Art `exports.shinyBridge` fallback. KIM no longer publishes, patches, or depends on any Battle Art shiny API.
- KIM now patches Wilds' already-loaded `battle_art_shiny_bridge` helper table directly through Wilds' exported cached module loader. Wilds' own `SpawnLogic` therefore receives KIM's shiny roll/DVs before it creates the spawn record on both desktop and mobile.
- Wilds continues to render its own packaged normal/shiny overworld sprites; KIM owns only shiny identity and persistent DVs.
- When that visible Pokémon starts a battle, Wilds' existing prepare/cancel calls now route straight to KIM, and KIM's `BattleState.newWild` wrapper consumes the exact same identity. Catch persistence remains DV-backed.
- Battle Art is now presentation-only for this feature: 3D-BTL can be ON or OFF without affecting shiny identity. No Battle Art or Wilds files are modified.
- Preserves the v22 PC 3D-BTL move-menu clip fix and the confirmed v20 mobile stage/UI handoff.

## v21 — Desktop v11 / Mobile v20 platform isolation

- Restores the confirmed-good v11 Windows/desktop Battle Art path while retaining the working v20 Android/iOS 3D-BTL UI handoff.
- Desktop uses the v11 Battle Art sprite bridge, Modern UI battle presenter, HUD capture semantics, KRBA compositor, and shiny overlay path.
- Android/iOS keep v20 stage-only ownership, pre/post `render.hud` stack cleanup, KIM HP/status/party-ball HUD, Modern UI lower battle panel, and normal Gen1Recomp TouchControls.
- Mobile-only KRBA/shiny no-push helpers remain available only through the Android/iOS Battle Art branch.
- No Battle Art files are modified. 3D-BTL OFF remains on KIM's established 2D path.

## v20 test - Mobile Battle Art UI handoff + HUD capture isolation

- Fixed a stage-only ownership bug exposed by the v19 screenshot: Battle Art is an external scene owner, so KIM's normal fullscreen `active` flag is false. v19 therefore cleared `_kantoInMotionBattleLite`, which caused the bundled Modern UI to intentionally stay out of its KIM lower-panel presenter even though KIM still owned the mobile 2D UI.
- Android/iOS + Battle Art 3D-BTL now keeps KIM's hybrid battle marker live while the native `BattleState` continues to own input. Modern UI receives the same lower command/move/message ownership contract used by KIM's fullscreen 2D battles, plus KIM's exact mobile dialog rectangle.
- KIM's private HP/status HUD capture now temporarily removes Battle Art's `dramaticShapeShot` marker before calling `BattleState:drawHUDs`. This bypasses Battle Art's HUD suppression/legacy Modern UI fallback only for the scratch capture, while preserving the v11 isolated true-color party-ball layer.
- Hardened that scratch capture against nested graphics-stack leaks: it records LOVE's entry stack depth and unwinds precisely back to that depth even when a protected HUD draw fails.
- Expanded the Gen1Recomp 0.2.45 `render.hud` boundary guard to clean both **entry and exit**. Any state left by Battle Art is repaired before UI drawing, and any state left by HUD composition is repaired again before `GameViewport.finish()`, so it cannot contaminate TouchControls or Battle Art's next frame.
- Included the confirmed v11 `integrated_pokeball_colorfix.lua` behavior unchanged so HUD Color Invert still cannot invert the party-ball outlines.
- The mobile Battle Art sprite bridge is intentionally unchanged in this test. If the Red/trainer rectangle survives after the UI handoff is corrected, it can be isolated separately without mixing another sprite-provider experiment into this build.
- Desktop and 3D-BTL OFF paths remain unchanged.

## v19 test - Mobile stage-only + pre-HUD boundary repair

- Based on the user-supplied Gen1Recomp 0.2.45 source, which confirms the mobile frame order is `Renderer:endFrame -> render.hud -> GameViewport.finish -> TouchControls:draw`.
- Keeps v18's Android/iOS Battle Art **stage-only** ownership split: Battle Art owns the voxel stage; KIM owns HP/status/party-ball HUD; Modern UI/vanilla own the lower battle UI.
- Restores the supported `love.graphics.getStackDepth()` repair at the **start of `render.hud`**, not at TouchControls. It runs only while KIM's mobile Battle Art stage-only path is active.
- After unwinding leaked states, KIM rebinds Gen1Recomp's real `GameViewport` target and neutral HUD draw state before Modern UI/KIM render.
- v18's snapped Battle Art HUD/frosted-panel suppression and stable mobile sprite bridge remain unchanged.
- Desktop and 3D-BTL OFF paths remain untouched.

## v18 test - Mobile Battle Art strict stage-only ownership

- Replaced the v15-v17 graphics-state repair experiments with a cleaner Android/iOS ownership split: while Battle Art 1.10.0 **3D-BTL = ON**, Battle Art supplies only the voxel stage/camera/lighting/shadows and KIM owns the 2D battle HUD.
- Disabled Battle Art's snapped HUD composite and frosted HUD-panel pass at runtime on mobile only. This mirrors Battle Art's own conservative iOS fallback and avoids the extra scratch-canvas path before TouchControls. Battle Art's files and saved settings are not modified.
- KIM now captures/renders its own HP/status/party-ball HUD over the mobile Battle Art stage, while Modern UI (or vanilla when Modern UI is OFF) continues to own the lower command/message surface.
- Returned mobile Battle Art sprite delegation to KIM's established stable-frame renderer instead of the experimental CPU atlas slicer, preventing corrupted rectangular player-sprite crops.
- Removes the v17 pre-HUD stack/canvas repair from the active mobile path. Desktop Battle Art and 3D-BTL OFF behavior are unchanged.

## v17 test - Mobile Battle Art GameViewport HUD-state restore

- Fixed the v16 mobile 3D-BTL regression where the crash was gone but Modern UI disappeared and KRBA effects could appear as raw rectangular surfaces.
- After unwinding Battle Art's leaked LOVE graphics stack, KIM now rebinds Gen1Recomp's `GameViewport` render target and restores neutral HUD canvas/transform/scissor/shader/depth/blend/color state before `render.hud` continues.
- The completed Battle Art stage is not cleared; Modern UI, KIM shiny/KRBA overlays, and the HP/status HUD render on top normally.
- Android/iOS + 3D-BTL only. Desktop and KIM 2D ownership paths are unchanged.

## v16 test - Mobile Battle Art pre-HUD boundary repair

- Repair Battle Art's leaked LOVE graphics states at the start of `render.hud` on Android/iOS while 3D-BTL is active.
- Restores Modern UI lower battle UI while retaining the mobile stack-overflow fix.
- Removes the v15 TouchControls-level repair wrapper.

## v15 test - mobile Battle Art TouchControls boundary repair

- Removed the invasive v14 graphics-function stack guard; KIM never replaces `love.graphics.push` / `pop`.
- Android/iOS now use LÖVE's supported `love.graphics.getStackDepth()` immediately before Gen1Recomp's original `TouchControls:draw()` while Battle Art 3D-BTL is active.
- Because Gen1Recomp has already completed `GameViewport.finish()` at this point, the expected stack depth is zero; any remaining states are leaked staged-battle states and are unwound before TouchControls performs its own push.
- Desktop and 3D-BTL OFF paths are unchanged. Preserves the v13 mobile CPU sprite bridge, v12 single-shiny guard, and v11 HUD/party-ball isolation.

## v13 test - mobile Battle Art platform split

- Split the Battle Art 1.10.0 sprite/provider path by platform instead of reusing the desktop GPU Canvas/readback bridge on Android/iOS.
- Android/iOS now slice KIM's selected animated/shiny front/back frames directly from the sprite atlas as CPU `ImageData` before handing them to Battle Art.
- Added mobile-only Battle Art shiny and KRBA fullscreen timing-plane compositors that restore graphics state explicitly and do not use `love.graphics.push()`/`pop()`, keeping KIM out of the graphics stack immediately before Gen1Recomp draws TouchControls.
- Desktop retains the confirmed v12 Canvas-based Battle Art integration unchanged.
- Preserves the v12 single-shiny ownership guard and the confirmed v11 HUD/party-ball isolation behavior.

## v12 test - mobile Battle Art graphics-stack + single shiny cue

- Fixed the Battle Art shiny overlay treating KIM's own 2D `dramaticShapeShot` compatibility record as a real voxel stage, which could draw the enemy shiny sparkle twice with 3D-BTL OFF.
- Battle Art's projected shiny overlay now runs only while Battle Art 3D-BTL is actually enabled and the published shot is a real external stage.
- Hardened KIM's Battle Art shiny and KRBA projected/fullscreen-plane draws so every graphics `push` is paired with a `pop` even if a mobile draw operation errors inside a protected compatibility call. This prevents swallowed render errors from accumulating graphics-stack depth until TouchControls fails.
- Preserves the confirmed v11 isolated Poké Ball invert layer and all v7-v9 Battle Art ownership/KRBA/Colorfix behavior.

## v11 test - isolated Poké Ball invert protection

- Reverts the v10 marker-palette/HUD-shader experiment that also changed the apparent HUD rendering.
- Restores the exact confirmed v9 HUD capture/shader path for names, levels, HP gauges and linework.
- Captures integrated Pokéball Colorfix party icons on a separate native 160x144 layer and composites them after HUD inversion, so their normal dark outlines/palette are preserved without changing HUD scale or resolution.

## Battle Art ownership / party-ball handoff (v9 test)

- Fixed integrated Pokeball Colorfix party-status balls when Battle Art 1.10.0 is installed but **3D-BTL = OFF**.
- KIM's fullscreen HUD capture now draws the true-color healthy/status/fainted party-ball row directly instead of inheriting Gen1Recomp's grayscale `balls.png` strip.
- Battle Art's existing 3D-BTL ON ink-safe party-ball palette is unchanged.
- No Battle Art or standalone Pokeball Colorfix files are modified.

## Battle Art KRBA fullscreen timing-plane compatibility (v7 test)

- Fixed the centered 160x96-scaled KRBA timing-plane rectangle in Battle Art 1.10.0 staged battles.
- Generalized the fix to every KRBA BG/FG timing plane instead of special-casing ThunderShock or `PRAS- Black BG.png`.
- Image and color planes are now composited against the actual viewport while Modern UI remains above them.

## 1.3.0

- Promoted the completed v8.6.x Battle Lite development line to the public **Kanto in Motion v1.3.0** release.
- Added the standalone Gen 1 Battle System with Battle Art-style fullscreen 2D composition, KRS/GEN6 arena choices, Battle Art-style HUD geometry, player trainer selection, animated front/back battlers, player-size controls, HUD color controls, and configurable lower-panel layouts.
- Integrated Kanto Rework Battle Animations for all 165 Gen 1 moves with native fallback, including Growl/Roar species-cry behavior.
- Integrated Pokéball Colorfix behavior and fixed fullscreen/mobile Poké Ball throw/open/shake/landing targeting.
- Added configurable persistent shiny odds, two-sided shiny encounter sparkle/audio, and preserved shiny DVs through battle/capture.
- Added live Modern UI/vanilla ownership switching on desktop and mobile without restart.
- Added mobile battle text-size, portrait layout, and Quality of Life EXP alignment fixes without modifying Quality of Life.
- Added Typed Move Colors effectiveness hints inside KIM's Modern move selector without modifying Typed Move Colors.
- Added Overworld Wild Spawns/Wilds shiny identity compatibility using Wilds' own shiny overworld assets without modifying Wilds.
- Added public-release README documentation for every **KANTO IN MOTION → BATTLE** option.
- Added/updated public attribution for Battle Art (absol89), Kanto Rework Battle Anims/KRS backgrounds (Faendra), Pokéball Colorfix (keberos), Gen1 Modern UI (ArmstrongThomas), animated badges (xpixelpriorx), and the Gen 9 Move Animation Project upstream data.
- Retains v1.2.0 Gen 2 support and all earlier menu/title/Trainer Card/compatibility work.

## v8.6.66 — effectiveness symbol spacing

- Adjusted Kanto in Motion's mirrored Typed Move Colors effectiveness glyph placement inside the integrated Modern battle move tiles.
- `↑`, `↓`, `○`, and `↑↑` now share a larger inset from the bottom-right tile edge instead of sitting against the corner.
- Fixed the `↑↑` geometry specifically: the old single-symbol center anchor could let the second arrow extend to or past the right tile border; the pair is now anchored by its complete rendered width.
- Effectiveness calculations, colors, move-tile layout, Typed Move Colors' **MOVE EFFECT** option, and all external-mod files remain unchanged.
- Preserves the confirmed v8.6.65 Wilds/Overworld Wild Spawns shiny bridge and all earlier fixes.

## v8.6.65 — Typed effectiveness hints + Wilds shiny runtime bridge

- Restored Typed Move Colors' move-effectiveness hints inside Kanto in Motion's integrated Modern battle move selectors without modifying `typed_move_colors`.
- KIM now calls Typed Move Colors' own live `effectIndicator` helper while KIM owns the lower battle panel, so the same `↑↑` super-effective, `↑` normal/damaging, `↓` resisted, and `○` ineffective/status result is preserved. Typed's **MOVE EFFECT** toggle, merged type chart, live enemy types, Conversion/type mods, fixed-damage/Super Fang behavior, and OHKO immunity handling remain authoritative.
- Reworked the v8.6.64 `overworld_wild_spawns` shiny compatibility. The earlier public-handle `mod.find` proxy could miss Wilds' private mod context in the real engine even though it passed an isolated mock test.
- KIM now uses Wilds' published `exports.logic`, `exports.render`, and `exports.lib` objects directly at runtime. New spawn records receive persistent KIM shiny DVs before Wilds creates the entity, and Wilds' own `AnimatedSprites.RUNTIME_SHINY_SUPPORT` is enabled so its packaged shiny overworld atlas is actually selected.
- Existing live Wilds entities created before the compatibility hook becomes ready are assigned identity once and refreshed in place; movement, spawn ownership, sprite assets, water handling, size, and behavior remain Wilds-owned.
- Contact and Safari battles are queued with the exact overworld DVs through KIM's prepared-identity path; direct overworld catches keep the same record DVs. Real Battle Art still takes priority if installed.
- Neither `typed_move_colors` nor `overworld_wild_spawns` is edited or repackaged. Preserves v8.6.64 and all earlier mobile/QoL/Poké Ball/cry/shiny-cue fixes.

## v8.6.64 — Wilds of Kanto overworld shiny identity bridge

- Added a Kanto in Motion-side compatibility bridge for `overworld_wild_spawns` / Wilds of Kanto 2.1.8+shiny.1; the Wilds package itself is not modified.
- Visible wild Pokémon now receive their shiny DV identity when the overworld spawn is created, using KIM's existing **SHINY ODDS** setting.
- Wilds continues to own rendering and uses its own bundled normal/shiny overworld sheets, sprite styles, movement, water presentation, and sizing.
- The exact overworld DVs are prepared into the native wild/Safari battle so a shiny visible in the overworld stays shiny in battle instead of being rerolled.
- Direct overworld catches also retain the same DVs/shiny state because Wilds already carries the spawn record into its catch path.
- If real Battle Art is installed, KIM does not shadow its published shiny bridge. Ordinary random encounters that do not originate from Wilds continue using KIM's existing shiny logic.
- Preserves v8.6.63 Quality of Life portrait EXP alignment and all earlier mobile/UI/Poké Ball/cry/shiny-cue fixes.

## v8.6.63 — mobile portrait Quality of Life XP alignment

- Fixed Quality of Life's Gen 1 XP bar being vertically misplaced only in Android/iOS portrait Battle Lite.
- Kanto in Motion now anchors QOL's EXP fill and level-up burst to the actual portrait player HUD band (`playerBandY + 41 HUD pixels`), matching the native Gen 1 EXP row inside the 48-row player HUD strip.
- Landscape/desktop geometry is mathematically unchanged; the existing SCALED-HUD correction is preserved by the same band-relative formula.
- Quality of Life is not modified. Its saved options, caught/Pokedex indicator, battle overlay code, and package remain source-owned.
- Preserves v8.6.62 mobile Battle Text Size, v8.6.61 Growl/Roar cries, v8.6.60 Poké Ball visibility/targeting, and v8.6.59 two-sided shiny cues.

## v8.6.62 — mobile Battle Text Size live scaling

- Fixed **BATTLE TEXT SIZE** being ignored by Kanto in Motion's Android/iOS Modern battle command, move, and message panels.
- Mobile normalized/proxy battle states can momentarily omit the native `_kantoInMotionBattleLite` marker; the lower-panel typography path now also accepts KIM's authoritative game-level fullscreen battle ownership flag.
- The selected 100%-400% value is therefore applied every frame on mobile just like desktop, without changing the accepted mobile panel footprint or TouchControls placement.
- Preserves v8.6.61 Growl/Roar attacker cries, v8.6.60 mobile Poké Ball visibility/targeting, and v8.6.59 two-sided shiny cues.

## v8.6.61 — Growl/Roar use the attacking Pokémon cry

- Fixed integrated KRBA ownership bypassing Gen1Recomp's special GROWL/ROAR cry-audio path.
- GROWL now plays the actual cry of the Pokémon using the move for both player and enemy battlers while preserving the imported visual animation and Attack-drop behavior.
- ROAR uses the same attacker-cry path, matching Gen 1's `IsCryMove` behavior.
- Uses `Sound.playMoveCry` when the engine exposes it so Growl/Roar retain their move-specific tempo shift; older compatible engines fall back to the normal species cry.
- No cry assets are bundled or replaced: the sound comes from the active Gen1Recomp cry registry, so cry-replacement mods remain compatible.
- Preserves the v8.6.60 mobile Poké Ball visibility/targeting fix and v8.6.59 two-sided shiny cue.

## v8.6.60 — mobile Poké Ball visibility fix

- Fixed Android/iOS catch animations disappearing after the v8.6.59 fullscreen enemy retarget. Mobile catch frames now render into a temporary padded native battle canvas sized around the active Poké Ball translation, so the toss/open/poof/shake/resting-ball graphics cannot be clipped by the stock 160x144 source bounds.
- The padded canvas is composited back with its padding subtracted, so all unaffected native battle pixels retain their existing positions.
- Desktop/Windows keeps the existing v8.6.59 catch path unchanged.
- Preserves the side-aware shiny sparkle/audio behavior from v8.6.59 and all Modern/Vanilla live UI ownership fixes.

## v8.6.59 — player shiny cue + Poké Ball target fix

- Shiny sparkle/audio is now side-aware: the same 35-frame, WAV-synced one-shot effect plays when the player's shiny Pokémon becomes visible after its send-out, not only for a shiny opponent.
- Enemy and player shiny effects keep independent appearance state, so each side can trigger once on its own send-out; temporary hide/show effects and failed-catch breakouts do not retrigger the shiny cue.
- Wild/Safari Poké Ball tosses now retarget from Gen1Recomp's stock 160x144 enemy slot to Kanto in Motion's actual final-resolution enemy battler center.
- The throw keeps its original launch point and progressively applies the correction across the toss; POOF/HIDEPIC/SHAKE/SHOWPIC and the caught resting ball retain the full endpoint correction so the native catch sequence stays internally aligned.
- Trainer-battle BLOCKBALL and ordinary move/send-out animations remain on their native paths.
- Preserves the v8.6.58 shiny assets/timing and all v8.6.57 Modern/Vanilla live ownership fixes.

## v8.6.58 — shiny encounter animation + audio

- Added a one-cycle shiny encounter effect that plays directly over the encountered shiny enemy Pokemon when it first appears.
- Uses the supplied 6x6 sprite sheet as a 35-frame overlay (89x75 per cell; the final blank cell is ignored).
- Plays the supplied `shiny.wav` once at the same time the sparkle animation begins; all 35 frames are time-locked to the WAV's ~0.7683 second duration so animation and audio finish together.
- The effect is rendered in Kanto in Motion's fullscreen battle world so it follows the shiny battler on desktop and mobile without affecting the existing HUD/UI ownership work.
- No shiny odds, DV persistence, KRBA move effects, battle backgrounds, or other gameplay logic changed.

## v8.6.57 — mobile live Modern/Vanilla ownership swap

- Gen1 now loads the selected platform Modern UI presenter even when `INTEGRATED MODERN UI` is saved OFF.
- The presenter stays dormant while OFF, so vanilla Gen1Recomp remains the presentation/input owner.
- Switching `INTEGRATED MODERN UI` ON can now claim the UI immediately on Android/iOS without restarting the game.
- Switching it OFF continues to release presenter, suppression, pointer, and input ownership immediately as added in v8.6.56.
- The same change also makes cold-start desktop sessions launched with Modern UI OFF capable of switching ON live.
- No battle art, sprite, animation, background, or gameplay assets changed.

## v8.6.56 — vanilla UI ownership handoff

- Fixed **INTEGRATED MODERN UI = OFF** on desktop/landscape Battle Lite: KIM now preserves Gen1Recomp's native bottom 48-row command/move/message strip instead of clearing the complete 160x144 battle UI source.
- Added a live master ownership gate to the integrated Modern UI presenters. Turning the setting OFF after the module has already loaded now releases native suppression, battle suppression requests, Modern input remapping, pointer ownership, and transient overlays immediately.
- KIM's fullscreen arena, animated battlers, KRBA effects, and Battle Art-style HP/status/EXP ownership are unchanged while **BATTLE SYSTEM = ON**. Portrait keeps its existing custom native-strip redraw path.

## v8.6.29 — animated battle trainers use global ANIMATION

- Upgraded **PLAYER TRAINER** so the trainer choice selects the trainer identity while the existing global **ANIMATION** toggle controls motion. `ANIMATION = ON` plays a five-frame intro atlas when that trainer has one; `ANIMATION = OFF` holds the same trainer on frame 1.
- Added the supplied Battle Art 1.9.8 animated player-trainer sets for GEN 1-5, Ash, Gary, Red, and Ash/Misty/Brock/Bulma/Gary front-facing variants. PNG, Boy, Lass, and Hilbert remain static-only because the supplied Battle Art package has no animated atlas for them.
- The animated intro follows Battle Art's authored SlideTrainerPicOffScreen progression instead of free-running on a timer, then clamps on the final pose.
- Keeps v8.6.28's single authoritative trainer capture and portrait HUD/dialogue stacking. External scene owners such as Battle Art still keep their own trainer renderer.

## v8.6.28 — portrait battle stack + player trainer selector

- Added **PLAYER TRAINER** to the Battle submenu with `DEFAULT / ROM`, `PNG`, `GEN 1`, `GEN 2`, `GEN 3`, `GEN 4`, `GEN 5`, `ASH`, `GARY`, `BOY`, `LASS`, and `HILBERT`. The choices mirror Battle Art's static `PLAYER ART` collection and affect the actual Gen 1 battle intro/send-out trainer, not the title-screen trainer.
- Custom battle trainers resolve through Gen1Recomp 0.2.38's public `player.sprite` hook and register native-1x battle-pic scale overrides, leaving ROM/default at the engine's original scale. External scene owners such as Battle Art continue to own their own trainer selection.
- Split the mobile native overlay capture so KIM suppresses the player trainer from the general transparent battle layer and redraws one authoritative trainer copy, preventing the doubled Red seen in portrait testing.
- Portrait touch battles now stack the player/Charizard-side HP band immediately below the contained battlefield instead of over the lower-right Pokemon. The native command/dialogue strip is placed below that player HUD.
- Landscape touch layout remains unchanged. Preserves v8.6.27 screen-position/title viewport fixes, v8.6.26 touch UI policy, and all earlier KRS/GEN6/KRBA compatibility work.

## v8.6.27 — mobile screen-position + title viewport fix

- KRS/GEN6, battlers, KRBA effects, trainer/send-out overlays, native mobile battle text, and KIM HP/status HUD now follow Gen1Recomp's movable TouchSkin/game viewport when SCREEN POS changes.
- `HUD SCALE = SCALED` now derives its integer rung from physical framebuffer pixels on high-DPI mobile displays.
- Title trainer, title Pokemon, and KIM Pokemon logo follow the renderer's actual title rectangle; the stock Pokemon wordmark is suppressed at the native source while KIM's title logo is active.

## 8.6.26
- Mobile touch battles now automatically yield the base battle command/message UI while on-screen controls are visible; Modern UI resumes when touch controls are hidden.
- KRS/GEN6 portrait touch layouts now contain the landscape arena to the TouchSkin game viewport width instead of cover-cropping a tall portrait area. Battler scale/anchors and KRBA anchors follow the contained stage.
- The fullscreen compositor preserves only the native bottom 48-row battle strip on touch layouts, while KIM still owns the arena and Battle Art-style HP/status HUD.

## v8.6.25 — cross-generation sprite geometry + title trainer selector

- Fixed the non-Gen5 visual-geometry problem when **SPRITE GEN** is changed while Battle **FRONT SET = SAME AS MENU**.
- Added generated animation-wide alpha bounds for Gen 2/3/4/5 normal and shiny atlases.
- Gen 2/3/4 front sprites (and Gen 3 back sprites) now render inside the corresponding species' Gen 5 visual envelope. This keeps apparent size, horizontal centering, and battle ground/target geometry stable while preserving each generation's authored animation motion.
- Gen 5 remains on the existing raw path so the known-good Gen 5 presentation is unchanged.
- Non-Gen5 normalized shiny sprites no longer also apply the older source-padding Y compensation; Gen 5 shiny ground alignment keeps the v8.6.19 correction table.
- The same normalized presentation is exposed through KIM's Modern UI, stock UI bridges, Clean UI bridge, Colosseum portrait provider, title Pokémon, native battle proxy, KRS/GEN6 direct battlers, and compatible resolved-sprite API.
- Added **TITLE TRAINER = ANIMATED / ORIGINAL GEN 1**. ORIGINAL yields the trainer portion of the title screen back to Gen1Recomp while keeping KIM's selected animated Pokémon/title presentation active.
- Preserves the v8.6.24 mobile high-DPI battle fix and v8.6.23 open compatibility API.

## v8.6.24 — Android/iOS high-DPI fullscreen battle fix
- Fixed KRS/GEN6 fullscreen worldOverride sizing on Android/iOS high-DPI displays. KIM now follows Gen1Recomp 0.2.38's renderer contract and sizes its `dpiscale=1` arena canvas from `love.graphics.getPixelDimensions()` instead of logical `getDimensions()`.
- The active TouchSkin playfield/cutout is honored before allocating the arena, so phone skins that reserve only part of the display no longer receive a full-window source cropped from the wrong origin.
- KRS footer handoff is converted back to LOVE/window units before Modern UI consumes it, preserving the accepted lower-panel geometry on both dpi=1 desktop and high-DPI mobile.
- No KRS/GEN6 art, battler anchors, KRBA targeting, Battle Art ownership, or v8.6.23 compatibility-registry behavior was changed.

## v8.6.23 — Open UI / battle compatibility registry
- Added a public `kantoInMotionCompatibility` registry so third-party UI and battle mods can declare presentation ownership without a hard-coded KIM patch.
- UI mods can claim exact presenter families (`battle`, `dialogue`, `pokemon`, `menus`, `manager`, `title`, `all`, or exact kinds); KIM Modern UI yields those visual surfaces while the independent animated-sprite provider remains available.
- Battle mods can select `native`, `lower`, or `full` Modern UI routing. `lower` is the Battle Art-style split: source world/battlers/effects/HP/status/EXP stay source-owned while KIM owns dialogue/commands/moves.
- Registered scene owners make Battle Lite yield its arena/HUD by default. KIM battle sprites and KRBA are opt-in through `allowKIMSprites` / `allowKIMAnimations`, preventing accidental double renderers.
- Existing Battle Art/voxel detection remains as a legacy fallback; KRS/GEN6 behavior is unchanged except for the narrow-aspect KRS enemy clearance below.
- KRS enemy placement now eases left only below 3:2, reaching a 72 px correction at 4:3 and narrower; 3:2, 16:10 and 16:9 keep the established position. KRBA uses the same shifted enemy anchor so attacks remain aligned.

## v8.6.22 — Battle UI Mode cleanup
- Removed the obsolete **BATTLE UI MODE** option from Modern UI settings.
- Made the established automatic routing permanent: KRS/GEN6 keep their hybrid lower-panel UI, detected Battle Art/voxel battles keep the source HP/status/EXP HUD with Modern lower UI, and ordinary eligible 2D battles keep the framed Modern presentation.
- Legacy saved `battleUiMode` values are ignored safely; no settings reset is required.

## v8.6.21

- Battle Art/voxel hybrid battles now apply Kanto in Motion's **BATTLE TEXT SIZE** setting to Modern UI's lower command, move, and message text, matching KRS and GEN6.
- The font multiplier remains typography-only: Battle Art's HP/status/EXP HUD and the accepted fixed lower-panel geometry are unchanged.

## v8.6.20
- Battle Art/voxel battles now use the same hybrid lower Modern UI ownership as KRS/GEN6: Modern UI owns command/move/message panels only; Battle Art keeps HP/status/EXP and the complete battle scene.

## v8.6.19
- Replaced the Rattata-only shiny battle-plane correction with a generated all-species alignment table. Every compatible bundled normal/shiny atlas pair is compared by transparent bottom padding so shiny variants share the normal variant's authored ground plane without flattening natural floating/bobbing motion.
- Audited 1,792 compatible normal/shiny side pairs across Gen 2/3/4/5 metadata; 772 pairs have a non-zero correction and are now compensated automatically in fullscreen battle rendering.
- Retains v8.6.18 GEN6 KRBA battler-centric targeting using actual rendered Pokemon centers, including selected player scale and shiny ground correction.

# v8.6.17 — Gen 2 Farfetch'd / Mr. Mime animated-sprite aliases

- Added shared sprite-key aliases for Gen 2 legacy species IDs: `FARFETCH_D` -> `FARFETCHD`, `MR__MIME` -> `MR_MIME`, and display-normalized `MRMIME` -> `MR_MIME`.
- Fixes animated sprite lookup for Farfetch'd and Mr. Mime in the Gen 2 Pokédex and any other Kanto in Motion screen using the shared sprite resolver.
- No KRS/GEN6 battle compositor, KRBA, UI geometry, shiny/capture, or sprite asset changes.

# v8.6.16 — Shared Battle Art-style fullscreen compositor

- KRS and GEN6 now use the same fullscreen layer-ownership model: KIM owns the arena continuously, the finished native 160x144 battle UI canvas is cleared before final composition, and only transparent trainer/send-out/native-fallback pieces are reconstructed from `drawPicsLayer` / `drawAnimLayer`.
- This removes the path that could scale Gen1's temporary white battle paper over the fullscreen arena.
- KRBA wide BG/particle/FG rendering now runs on both KRS and GEN6 instead of KRS only.
- GEN6 now uses the same accepted lower Modern UI geometry as KRS: 3 px side inset and 3 px bottom inset at 1920x1080, with the v8.6.5 top edge/height behavior.
- Corrected Ember targeting and existing shiny/capture behavior remain unchanged.

# v8.6.15 — KRS native-canvas white-clear fix

- Video analysis showed the white "flash" is the native 160x144 Gen1 battle surface itself, scaled over the KRS arena, not an authored KRBA flash.
- While KRS owns the arena, white clears of the active native battle UI canvas are now converted to transparent clears. The guard is canvas-specific, so KRBA/temp canvases keep their normal clear behavior.
- Keeps the accepted 3 px side/bottom panel inset and corrected Ember targeting.

# v8.6.13 — Active KRS flash-path fix

- Moved native `fx.flash` suppression onto the actual KRS `BattleState:draw` path.
- v8.6.12 had patched an older fullscreen helper that KRS battles never executed.
- KRBA-authored particles, BG/FG planes, and Ember targeting remain unchanged.
- Retains the accepted 3 px side / 3 px bottom Modern UI inset.

# v8.6.12 — KRBA fullscreen native-flash suppression

- Fixed the shared white-screen flash seen on Ember and other KRBA attacks. KIM was expanding Gen1Recomp `battle.fx.flash` into an 85% opaque full-window white rectangle even while KRBA already owned the move animation. The extra native flash is now suppressed only during active KRBA sessions.
- v8.6.11 Ember targeting and the accepted 3 px UI insets are unchanged.

# v8.5 — Shiny odds/capture persistence + send-out ball pass-through

- Added `SHINY ODDS` to the Gen1 BATTLE submenu: NATIVE 1/8192, 1/4096, 1/2048, 1/1024, 1/512, 1/256, 1/128, 1/64, 1/32, 1/16, 1/8, 1/4, 1/2, and ALWAYS.
- NATIVE leaves Gen1 DVs untouched and recognizes the canonical Gen2 shiny DV pattern naturally; custom odds roll when `BattleState.newWild` creates the wild Pokemon.
- Custom shiny encounters are encoded into the Pokemon's DVs, not just a temporary render flag, so catching the Pokemon preserves its shiny identity.
- Party/Summary/compatible UI sprite routing now checks the same DV-backed shiny rule, so a caught shiny continues using imported shiny art outside battle.
- During `sendingOut` / `enemySendingOut`, the native pics layer keeps a real/proxy battler sprite instead of KIM's transparent settled-battle placeholder. This preserves the engine's Pokeball throw/release visual path while the fullscreen sprite remains gated by native send-out timing.
- No arena, HP/EXP HUD, battle panel, text-size, move-layout, QOL, Pokeball Colorfix, or Typed Move Colors settings were changed.

# v8.4 — Native Pokéball send-out visibility sync

- Fixed the fullscreen player Pokémon appearing before the trainer's Pokéball throw reached the field, then disappearing and reappearing during the native release animation.
- Fullscreen battler drawing now mirrors Gen1Recomp/Battle Art visibility gates: `sendingOut`, `enemySendingOut`, `enemyHidden`, and `fxHidden()`.
- Player and enemy Pokémon remain hidden whenever the native battle state says their sprite should not yet be visible, then appear at the engine's real send-out/release timing.
- No battlefield, HUD, sprite-size, Modern UI panel, move-layout, QOL, Pokéball Colorfix, or Typed Move Colors settings were changed.

# v8.3 — Raised battle panel + large-screen text + AA removal

- Raised the full-width Modern battle panel to sit beneath the player back sprite while retaining the accepted v8.2 width/height.
- Made the `A  continue` prompt use measured font dimensions so it never hangs outside the bottom-right frame.
- Extended `BATTLE TEXT SIZE` to 400%.
- Removed the unused AA setting and supersampling code path.

# v8.2 — Live full-window lower panel fix

- Fixed Kanto in Motion Battle Lite lower UI still being clipped to Modern UI's internal 640x360 battle presenter.
- Dialogue, command menu, GRID moves, and VERTICAL moves now use the real full-window bottom footprint.
- GRID keeps 2x2 moves on the left and MOVE INFO on the right.
- BATTLE TEXT SIZE remains typography-only.

# Kanto in Motion v8.0 Battle Lite test

- Restored the larger v7.8 Modern battle command/message panel footprint at the bottom of the screen.
- `BATTLE TEXT SIZE` now changes only lower-panel typography; it no longer changes panel dimensions.
- Added `MOVE LAYOUT = GRID / VERTICAL` (default GRID).
- GRID uses a 2x2 move grid on the left with MOVE INFO on the right.
- VERTICAL lists move slots 1-4 top-to-bottom and keeps native vertical BattleState navigation.
- GRID remaps the classic vertical BattleState cursor to 2x2 navigation only while GRID is selected.
- Battle Art HP/status, Quality of Life EXP/caught geometry, Pokeball Colorfix geometry, battlefield placement and sprite scaling are unchanged.

## 1.2.1-TEST-BATTLE-LITE-GEN1-v7.9

- Isolated Modern UI to Kanto in Motion's lower battle command/move/message surface; Modern HP/status cards no longer render behind the Battle Art HUD.
- Added `BATTLE TEXT SIZE` (100%-200%, default 150%).
- Added `typed_move_colors` runtime compatibility for KIM's Modern battle panel without modifying Typed Move Colors.

# v7.8 — Modern UI lower battle panel

- Keeps the v7.7 battlefield, battler positions/sizes, Battle Art HP/status HUD, QOL SCALED-XP compatibility and Pokeball Colorfix HUD-band fix unchanged.
- Integrated Modern UI now replaces only the lower BattleState information surface: FIGHT / POKEMON / ITEM / RUN, move selection and battle messages.
- Modern UI does **not** draw replacement HP/status/EXP cards while Kanto in Motion's battle system is active.
- Native lower battle UI is suppressed only when the integrated Modern UI actually installed and Kanto in Motion owns the fullscreen Battle Lite state.
- `BATTLE SYSTEM = OFF` remains a real compatibility bypass for vanilla/other battle systems.

# v7.7 — 125% battler baseline + 140 PX arena default

- Keeps the v7.6 player/enemy field positions.
- Changes **PLAYER PKMN SIZE** default from 100% to **125%**.
- Raises the enemy fullscreen sprite baseline by the same **25%**, independently of the player-size option.
- Changes **BG Y-OFFSET** default from 100 PX to **140 PX**.
- `RESET TO DEFAULT` automatically follows these schema defaults.
- Keeps the v7.6 QOL SCALED XP-bar correction and the Pokeball Colorfix HUD-band compatibility unchanged.
- Native atlas frames are still scaled only once at final draw, preserving the crisp v7.4+ sprite path.

# v7.6 — lower battlers + SCALED QOL XP alignment

- Keeps v7.5 native-resolution 4x-at-1080p sprite rendering and does not reintroduce the low-resolution proxy.
- Lowers the player battle anchor from logical Y 96 to 110 so large backs such as Charizard sit much closer to the dialogue box.
- Lowers the enemy anchor from logical Y 56 to 65 so foes sit lower on the Gen 6 field without changing their size.
- Fixes Quality of Life's XP bar in `HUD SCALE = SCALED` from Kanto in Motion only. QOL's Battle Art compatibility uses a shared `dramaticShapeShot.ly`, while Battle Art's scaled player band has an additional 56-pixel vertical offset. KIM now applies that missing offset only to QOL's player-side EXP primitives on the fullscreen world canvas.
- QOL's caught/Pokedex indicator remains on the enemy-band origin. Quality of Life itself is not modified.
- Pokeball Colorfix remains unmodified.

# v7.5 — Battle Art sprite size + HUD SCALE

- Keeps v7.4 native-resolution animated battle sprite rendering, but increases the final fullscreen sprite rung (4x at a 1920x1080 / 6x battle stage) so small species no longer look miniature.
- `PLAYER PKMN SIZE` still multiplies only the player-side final draw in 5% steps.
- `HUD SCALE` now follows Battle Art 1.9.8 `OverworldBattle.snapRects`: `OG` uses the full window-fit integer rung and `SCALED` uses exactly one rung smaller.
- No Quality of Life or Pokeball Colorfix files are modified.

# v7.4 — native-resolution battle sprites + full HUD-band snap

- Fullscreen animated Pokemon are now drawn from their native atlas frame directly into the window-resolution arena, eliminating the destructive 56px intermediate proxy that caused heavy pixelation.
- PLAYER PKMN SIZE now scales the final native-resolution player sprite in 5% steps.
- Opponent sprites use the same Battle-Art-like native-resolution stage scale and are no longer tied to HUD SCALE.
- Suppresses the original 160x144 HUD band after capture so Pokeball Colorfix party rows do not leave a second zone-coloured copy in the center.
- Quality of Life and Pokeball Colorfix remain unmodified.

# 1.2.1-TEST-BATTLE-LITE-GEN1-v7.4

- Fixed `PLAYER PKMN SIZE` so it is applied at Gen1Recomp's real battle sprite scale seam.
- Reduced standalone imported opponent/front sprite baseline to 75% to better match Battle Art staging at desktop resolutions.
- Added Battle Art-compatible `dramaticShapeShot` publication for third-party battle overlay compatibility without editing those mods.
- Quality of Life XP bar and Pokedex/caught indicator can now use KIM's fullscreen HUD geometry directly.
- Unified OG/SCALED player HUD-band geometry with the exported compatibility coordinates.

# v1.2.1-TEST-BATTLE-LITE-GEN1-v7.2

- Added **RESET TO DEFAULT** at the bottom of the Gen1 BATTLE submenu. Selecting it restores every Kanto in Motion battle option to its schema default in one action.

- Expanded **PLAYER PKMN SIZE** to **50%..200% in 5% steps**: 50%, 55%, 60%, 65% ... 195%, 200%.
- Keeps **100% as the default**.
- Corrected the notes to reflect that Battle Art 1.9.8 defines `BattleArt.playerPokemonScaleSetting` in `BattleArt.lua`.

# v1.2.1-TEST-BATTLE-LITE-GEN1-v7

- Ported Battle Art-style **HUD SCALE** with **OG as the Kanto in Motion default** and SCALED as the compact alternative.
- Added **AA = OFF / 2X / 4X** using the Battle Art supersampling ladder for the full-window no-voxel arena plate.
- Added **PLAYER PKMN SIZE = 50%..200%** for the animated player-side battle sprite while keeping the native BattleState anchor authoritative.
- Expanded **ARENA FILL** to OFF / WHITE / GEN6 for the standalone no-voxel battle system.
- Added Battle Art **BG Y-OFFSET = 0..400 PX** in 20 PX steps, default 100 PX.
- Added Battle Art 1.9.8-style **Gen 1 DV shiny detection** and automatic routing to bundled shiny animated front/back collections.
- No voxel BattleScene, Voxel3D, mesh, camera or terrain code is loaded.

## 1.2.1-TEST-BATTLE-LITE-GEN1-v6

- Reworked standalone Gen1 battles to follow Battle Art 1.9.8's native BattleState composition instead of rebuilding Pokemon/menu layers in `render.hud`.
- Added Battle Art-style temporary OG-layout ownership: Kanto in Motion uses the original 160x144 battle coordinates while active and restores the user's previous battle-layout value afterward.
- Gen 6 Arena Fill now uses the renderer world-override seam; no voxel world or 3D battle renderer is loaded.
- The stock BattleState canvas is retained as a transparent overlay, so Pokemon, send-out/faint motion, move animations and the lower battle menu keep their native positioning and draw order.
- Suppresses only the full-frame opaque white battle-paper fill instead of clearing the entire UI canvas.
- Removed Kanto in Motion's separate Modern Battle UI battle row; the base battle commands/move list/messages now stay in the Battle Art/native bottom battle area.
- Modern UI remains available for supported child screens such as Bag, Party, nickname and evolution.
- Keeps the Battle Art-style edge-snapped HP/status HUD and COLOR / INVERTED contrast modes.
- Keeps **BATTLE SYSTEM = OFF** as the complete compatibility bypass.
- No voxel mesh, 3D camera, terrain, billboard, DOF or staged voxel battle code is included in the standalone path.

## 1.2.1-TEST-BATTLE-LITE-GEN1-v5

- Replaced v4's ineffective post-composite repaint with Battle Art 1.9.8-style source-canvas suppression.
- The active Gen1 BattleState now disables the native white letterbox while Battle Lite owns the fullscreen arena.
- `render.compose` clears the exact native `ctx.uiCanvas` before the engine can letterbox it into the final window, removing the centered white battle paper, duplicate tiny battlers, native XP strip, and other stock battle remnants at their source.
- Integrated Modern UI is allowed to inspect/capture the native source before that clear, then continues to draw commands/messages later in `render.hud`.
- Fullscreen Gen 6 arena, large animated battlers, Battle Art HP/status HUD, HUD COLOR, and BATTLE SYSTEM master bypass are otherwise unchanged.

## 1.2.1-TEST-BATTLE-LITE-GEN1-v4

- Removed the remaining centered native Gen1 battle-paper composite from the fullscreen Battle Lite path.
- Eliminates the white rectangle, duplicate tiny battlers, and stray native XP strip seen in the v3 1920x1080 test.
- Reuses the already-captured fullscreen battle scene after the stock renderer and before Modern UI, so no second sprite/animation capture is required.
- Keeps the v3 fullscreen Gen 6 arena, large animated battlers, Battle Art-style HP/status HUD, HUD COLOR option, and BATTLE SYSTEM master bypass unchanged.

# Changelog

## 1.2.1-TEST-BATTLE-LITE-GEN1-v3

- Replaced v2's forced native WIDE/FILL approach with a final-window Battle Lite compositor so the Gen 6 arena can truly cover a 16:9 window while the live battle layer is scaled coherently.
- Corrected the v2 battle-sprite clipping/placement failure that could leave only the Pokemon's feet visible.
- Added **BATTLE SYSTEM = ON / OFF** as a master compatibility switch. OFF yields battle presentation to vanilla or another battle-system mod.
- Removed the HP BARS selector. Kanto in Motion's Battle Lite now always uses the Battle Art-style native Gen 1 HP/status HUD when its battle system is enabled.
- Matched the edge-snapped HP/status block geometry directly to the supplied Battle Art Voxel Fork 1.9.8 implementation.
- Added **HUD COLOR = COLOR / INVERTED**. COLOR keeps black glyphs with a light shadow; INVERTED uses white glyphs with a dark shadow. Both retain bright green / amber / red HP gauges.
- Modern Battle UI remains responsible only for commands, move selection, and messages; it no longer supplies a competing HP/status card in the Battle Lite path.
- Gen2 behavior remains unchanged, and installed Battle Art still wins battle ownership.

## 1.2.1-TEST-BATTLE-LITE-GEN1-v2

- GEN6 Arena Fill now forces Gen1Recomp's native WIDE + FILL battle composition for a full-screen field.
- Replaces only the native wide battle paper with the routed Gen 6 arena backdrop; Pokemon are repositioned by the engine rather than stretched.
- Added **HP BARS = VANILLA / MODERN**. VANILLA is the default and preserves the native Gen 1 HP/status boxes.
- Modern Battle UI can continue to own battle commands, move selection, and messages while vanilla HP bars remain visible.
- Battle Art/voxel ownership and Gen2 behavior remain unchanged.

## 1.2.0

- Added Gen 2 game targeting for Gold, Silver, and Crystal on the Gen1Recomp 0.2.24 architecture.
- Added generation-aware UI ownership: Gen 1 uses the saved Gen 1 Modern UI preference while Gen 2 automatically suppresses Kanto in Motion's bundled Modern UI.
- Restored the Gen 1 `INTEGRATED MODERN UI` toggle as a saved Gen 1-only preference; new installs default ON, and a manual OFF persists across later Gen 1 launches.
- Added compatibility with the original/unmodified Gen2 Clean UI 0.4.1.
- Added stock Gen2 Clean UI live animated portrait bridging without requiring Clean UI to be patched.
- Confirmed animated Gen 2 Status/Summary portraits in real Gold/Crystal testing.
- Added Gen 2 portrait compatibility hooks for Party, Pokédex, and Evolution presentation.
- Fixed Gen 1 Poké Mart BUY/SELL screens falling back to the original Gen 1 UI by recognizing Gen1Recomp's custom ShopMenu draw path.
- Preserved the v1.1.4 Trainer Card, animated badge, Useful Bag, stock Gen1 animated portrait, and centralized Mod Menu work.
- Added two release package variants: Full Assets and No Pokémon Assets.

## 1.1.4

- Fixed stock Gen1 Pokédex animated portraits when **INTEGRATED MODERN UI = OFF** and retained safe fallback to the native Gen1 sprite when animated art is unavailable.
- Fixed stock Gen1 Pokémon STATUS/Summary so the selected Gen 2/3/4/5 animated portrait is shown instead of falling back to the native Gen1 portrait.
- Constrained oversized animated portraits to the stock **56×56** Pokédex/STATUS portrait area without enlarging smaller sprites, preventing large species such as Charizard from overflowing the classic UI.
- Fixed the optional **START MENU PARTY VIEW** companion card so its full panel background is drawn instead of leaving party rows floating over the overworld.
- Added a compatibility fallback for legacy/unknown mods: mod-authored OPTIONS and Start-menu rows are preserved when Kanto in Motion cannot confidently represent that mod inside the centralized **MOD MENU**.

## 1.1.3

- Added the new Trainer Card presentation: custom player portrait, Gym Leader art for unearned badge slots, and looping animated earned-badge icons.
- Added the revised Giovanni silhouette used for the hidden eighth Gym Leader slot so it remains readable with the Crimson theme while preserving the secret-leader presentation.
- Added explicit credit to **xpixelpriorx** for the animated badge artwork.
- Fixed the in-game SAVE summary panel so its Modern UI card always has a complete theme-colored background.
- Added Modern UI background cleanup for the title CONTINUE summary and Battle Art precache/cache-loading transition screens so native UI does not show through.
- Added built-in compatibility with official/unmodified **Useful Bag** releases: Kanto in Motion suppresses Useful Bag's duplicate standalone bag presenter while preserving Useful Bag's pockets, sorting, capacity, controls, callbacks, and inventory behavior.
- Added Useful Bag as an optional dependency so presentation-hook ordering is deterministic when both mods are installed.

## 1.1.2

- Added independent resolved-sprite animation bridging for compatible third-party UI overhauls so Party/Summary and Pokédex front art can remain animated with Integrated Modern UI disabled.
- Added a portrait-provider integration path for Colosseum Inspired UI Overhaul compatibility builds.
- Added automatic Colosseum UI detection/yielding and documented that Integrated Modern UI should be disabled when using third-party full UI overhauls.
- Fixed Modern UI dialogue progression retaining and recomposing an already-consumed native TextBox line after manual CONT/page advances.

## 1.1.1

- Fixed the central Mod Menu `TYPED MOVE COLORS -> SETTINGS` entry so builds that use manifest option schemas open correctly instead of doing nothing. Authored Typed Move Colors settings screens are still preferred when present.
- Restored Kanto in Motion's own settings in the centralized Mod Menu. `KANTO IN MOTION` now opens separate `KANTO SETTINGS` and `MODERN UI SETTINGS` entries instead of routing directly into only the Modern UI option categories.
- Direct Mod Manager access now presents Kanto in Motion controls in a dedicated `KANTO IN MOTION` category, while the Modern UI child page remains focused on Modern UI settings.
- Fixed the Gen1Recomp 0.2.13 SAVE confirmation layout so the integrated Modern UI recognizes the anonymous save-info panel and keeps the Start menu, save summary, prompt, and YES/NO choice in one coherent widescreen-safe composition.
- The underlying Gen1Recomp save logic and timing are unchanged; this patch only replaces the broken split presentation.
- Reworked title-screen species selection into a shuffled 151-Pokémon rotation so every Kanto species is shown before the pool repeats.
- Improved Gen 2 / Gen 3 / Gen 4 / Gen 5 animation metadata and atlas-layout validation so incompatible frame layouts fall back safely instead of being sliced incorrectly.

## 1.1.0
- Integrated the project's customized **Gen1 Modern UI 0.9.12 – Central Mod Menu + Title Start** build directly into Kanto in Motion.
- Added **Crimson** and **Crimson Glass** themes to the integrated Modern UI.
- Set the new-install Modern UI battle defaults to **MODERN BATTLE UI = ON**, **BATTLE UI SCOPE = ITEMS + POKEMON**, and **LEAVE 3D BATTLES ALONE = OFF**.
- Expanded the README with a detailed explanation of **LEAVE 3D BATTLES ALONE** and how it interacts with 3D/voxel battles and BATTLE UI SCOPE.
- Unified Kanto in Motion and Modern UI settings under the `animated_menu_pokemon` mod identity.
- Integrated UI consumes Kanto in Motion's animated sprite provider directly for supported Party, Summary, Pokédex, evolution, and related views.
- Retained the customized Modern UI battle Items/Pokémon flow, nickname, level-up-stat, centralized Mod Menu, and title/start Mod Menu behavior.
- Added explicit ArmstrongThomas / Gen1 Modern UI credit and upstream repository link.
- Standalone `gen1_modern_ui` and `gen1_clean_ui` are declared conflicts to avoid duplicate UI ownership.
- Public package remains free of Pokémon-derived sprite/title payloads.

## 1.0.0

- Renamed the public project from Animated Menu Pokémon to **Kanto in Motion**.
- Preserved internal mod ID `animated_menu_pokemon` for compatibility.
- Added Gen 2 / Gen 3 / Gen 4 / Gen 5 animated menu-sprite generation selection.
- Added stock Summary and Pokédex entry integration.
- Added optional Gen1 Modern UI integration through Kanto in Motion's exported sprite interface.
- Added animated evolution artwork support.
- Added all-151 Red/Blue title Pokémon cycling with a 24-species recent-history exclusion.
- Added NORMAL / SLOW / SLOWER title cycle settings.
- Retained optional animated Red title presentation and custom Gen1Recomp++ title logo when those assets are supplied locally.
- Added local-only `tools/import_assets.py` workflow so Kanto in Motion has no runtime Battle Art dependency and can remain standalone after local asset import.
- Added `DIFFERENCES.md`, public-package safety checks, GitHub repository metadata, and Gen1Recomp release workflow support.
- Removed Pokémon-derived sprite/title payloads from the public source/release tree.
- Added an AI development disclosure to the README.

## v8.1 lower-panel routing fix

- The Kanto in Motion battle presenter now keys the Modern lower-panel path off the persistent BattleState ownership flag, not only the short-lived render.hud game flag.
- Battle dialogue and FIGHT / POKEMON / ITEM / RUN now stay in the full-width bottom panel.
- BATTLE TEXT SIZE changes only typography.
- MOVE LAYOUT = GRID uses 2x2 moves on the left with MOVE INFO on the right; MOVE LAYOUT = VERTICAL uses four stacked move rows. Both layouts use the same full-width bottom panel.


## v8.5 test
- Added configurable wild SHINY ODDS using Battle Art's canonical Gen 2 DV shiny rule; custom odds write the shiny-compatible DV state onto the actual wild Pokemon so caught shinies remain shiny.
- Preserved the native Gen1Recomp player/enemy sprite path while `sendingOut` / `enemySendingOut` is active so the thrown Pokeball itself can render before KIM resumes fullscreen animated battlers.
- Added Kanto Rework Battle Animations compatibility for transparent fullscreen composition: additive/subtractive Essentials particles (notably Ember) are carried as alpha during KIM's scratch-layer capture, matching Battle Art's proven fix while leaving KRBA unmodified.

## v8.6.27
- Fixed Android/mobile battle viewport ownership when SCREEN POS is changed: the contained KRS/GEN6 stage, animated battlers, KRBA anchors, trainer/send-out overlay, native mobile battle strip, and KIM HP/status HUD now use one placement contract.
- Fixed Battle HUD SCALE = SCALED on high-DPI phones by deriving the HUD rung from physical framebuffer pixels before converting back to LOVE units.
- Fixed portrait trainer intro placement so the native trainer/send-out layer is fitted inside the same contained battle stage rather than the black area above it.
- Fixed the title-screen HD trainer, cycling Pokemon, and custom logo so they follow Gen1Recomp's actual renderer title rect for CENTER / UPPER / TOP and layout-mod viewports.
- Suppressed the stock Pokemon wordmark directly on the source title canvas while the KIM replacement logo is active, preventing the original title art from being revealed when the screen is moved.

### Battle Art mobile platform split test (v13)
- Android/iOS now use a dedicated Battle Art sprite bridge that slices KIM animation frames directly as CPU `ImageData`; the desktop Canvas/readback bridge is no longer used on mobile.
- Battle Art shiny and KRBA fullscreen timing-plane overlays use mobile no-stack compositors so KIM adds no graphics `push()` calls to the staged mobile battle before `TouchControls:draw()`.
- Desktop Battle Art behavior is unchanged.
- Preserves the v11 isolated Pokeball Colorfix HUD layer and v12 single-shiny ownership guard.

## v22 test — desktop Battle Art move-menu back-sprite clip
- Gen1Recomp 0.2.45's native move/Mimic menu row clip is bypassed only for desktop Battle Art 3D battles when KIM Modern UI owns the lower menu.
- Prevents a player BACK SPRITES battler left on Battle Art's 2D pic layer from being cut to Y=64/Y=56 when the replacement Modern move menu is open.
- Android/iOS v20 stage-only rendering is unchanged. No Battle Art files are modified.

## Mobile Battle Renderer Restore v25
- Restores the exact known-good Android/iOS Battle Art presentation modules from the v20 mobile chain after the desktop-baseline reconstruction replaced shared/mobile renderer files.
- Mobile now loads a dedicated stable Battle Art sprite bridge, shiny encounter renderer, and KRBA renderer; Windows continues using the current desktop files and retains the v22 3D-BTL move-menu clipping fix.
- Restores the v20 mobile Modern UI implementation and keeps the v20 stage-only/HUD-boundary/party-ball isolation files explicit.
- Keeps v24 KIM-owned Wilds shiny identity/DV authority. Battle Art remains a stage renderer only and is not consulted for shiny decisions.
- No Battle Art or Wilds archive is modified.
