### v8.6.63 mobile portrait QOL XP checks

- Android/iOS portrait with Quality of Life **XP BAR = ON**: confirm the XP bar sits on the player HP/status band in the same relative row it uses in landscape.
- Check both **HUD SCALE = OG** and **HUD SCALE = SCALED** in portrait. The XP fill and level-up burst should stay attached to the player band.
- Rotate/switch to landscape and confirm the already-correct XP-bar position is unchanged.
- Confirm QOL's caught/Pokedex indicator remains unchanged; Kanto in Motion does not modify any Quality of Life file.
- Recheck mobile Battle Text Size, Growl/Roar cries, one catch animation, and one shiny cue.

### v8.6.62 mobile Battle Text Size checks

- Android/iOS with **INTEGRATED MODERN UI = ON**: enter a KRS/GEN6 KIM battle and change **BATTLE TEXT SIZE** between 100%, 150%, 250%, and 400%. Command labels, move names/PP, and battle messages should visibly resize without restarting.
- Check both portrait and landscape; the lower panel itself should remain at the established mobile size/position while only typography changes.
- Switch Modern UI OFF and back ON live; returning to Modern should immediately use the currently selected text size.
- Recheck Growl/Roar cries, one catch animation, and one shiny cue to confirm v8.6.61/v8.6.60/v8.6.59 behavior is unchanged.

### v8.6.61 Growl / cry-audio checks

- Have the player's Pokémon use **GROWL** and confirm the move plays that Pokémon's own cry once at the start of the KRBA Growl animation.
- Have an enemy Pokémon use **GROWL** and confirm the enemy's own cry is used instead.
- If available, test two different species back-to-back to confirm the sound follows the actual attacker rather than the player/enemy side or a cached species.
- Spot-check **ROAR** for the same attacker-cry behavior.
- Confirm the Growl visual animation and Attack-stat reduction still occur normally.
- Recheck one mobile catch and one player/enemy shiny cue to ensure v8.6.60/v8.6.59 behavior is unchanged.

### v8.6.60 mobile Poké Ball visibility checks

- Android/iOS landscape: throw Poké Ball / Great Ball / Ultra Ball at a wild Pokémon and confirm the ball is visible from launch through opening/poof, shake sequence, and final caught/resting state.
- Android/iOS portrait: repeat and confirm the padded native catch layer follows the contained battlefield and SCREEN POS without clipping.
- Confirm the ball still finishes at the fullscreen enemy battler rather than the old 160x144 enemy slot.
- Confirm ordinary move animations, trainer BLOCKBALL, player send-out poof, and desktop catch presentation are unchanged.
- Recheck one player shiny and one enemy shiny to confirm v8.6.59 one-shot sparkle/audio behavior remains intact.

## v8.6.29 animated battle-trainer test focus

1. Set **PLAYER TRAINER = GEN 5** and **ANIMATION = ON**. Start a battle; the trainer should play through the five authored intro poses while sliding off-screen, with only one trainer visible.
2. Set **ANIMATION = OFF** without changing PLAYER TRAINER. Start another battle; the same Gen 5 trainer should remain on frame 1 instead of switching to different static artwork.
3. Spot-check GEN 1, ASH, GARY, RED, and one `... FRONT` choice with ANIMATION ON.
4. Check BOY/LASS/HILBERT/PNG; these should remain static because no animated atlas is present for them in the supplied Battle Art package.
5. Recheck portrait stacking and landscape from v8.6.28.

## v8.6.28 portrait + battle trainer test focus

1. Android portrait: enter a wild battle and verify only **one** player trainer appears during the intro.
2. In **KANTO IN MOTION -> BATTLE -> PLAYER TRAINER**, cycle ROM/default and several named choices (for example GEN 1, GEN 5, ASH, GARY). Confirm the actual battle-intro trainer changes while the title-screen trainer setting remains independent.
3. Portrait: once Pokemon are settled, confirm the player/Charizard-side HP HUD sits below the contained battlefield instead of covering the lower-right Pokemon.
4. Open the command menu and move menu; the native mobile command/dialogue area should sit below the player HUD, leaving the battlefield unobstructed.
5. Recheck mobile landscape; its accepted v8.6.27 layout should be unchanged.
6. Recheck SCREEN POS CENTER/UPPER/TOP and HUD SCALE OG/SCALED in portrait to ensure the whole stack follows the same viewport.

## v8.6.27 mobile viewport/title test focus

- Portrait and landscape SCREEN POS changes should move KRS/GEN6, battlers, trainer/send-out overlay, HUD, and title presentation together.
- `HUD SCALE = SCALED` should remain readable on high-DPI Android rather than collapsing to a tiny 1x HUD.
- Title trainer/Pokemon/logo should follow CENTER/UPPER/TOP without revealing the original Pokemon wordmark behind them.

## 8.6.26
- Mobile touch battles now automatically yield the base battle command/message UI while on-screen controls are visible; Modern UI resumes when touch controls are hidden.
- KRS/GEN6 portrait touch layouts now contain the landscape arena to the TouchSkin game viewport width instead of cover-cropping a tall portrait area. Battler scale/anchors and KRBA anchors follow the contained stage.
- The fullscreen compositor preserves only the native bottom 48-row battle strip on touch layouts, while KIM still owns the arena and Battle Art-style HP/status HUD.

## v8.6.25 cross-generation sprite test focus

1. Set **FRONT SET = SAME AS MENU**.
2. Switch **SPRITE GEN** through GEN 2, GEN 3, GEN 4, and GEN 5 with the same species visible.
3. Check Pokédex/Summary/title and a KRS or GEN6 battle. The art style and animation should change, but the Pokémon should remain in a comparable visual envelope instead of becoming very large/small or shifting off its battle plane.
4. Check a shiny in a non-Gen5 set if available; it should share the normalized placement without receiving a second Y correction.
5. Set **TITLE TRAINER = ORIGINAL GEN 1** and confirm the native title trainer is visible while the selected animated title Pokémon remains active; switch back to ANIMATED and confirm KIM's animated Red returns.
6. Recheck Android high-DPI KRS/GEN6 fullscreen presentation from v8.6.24.

## v8.6.24 mobile high-DPI test focus
- Android 0.2.38 landscape: KRS and GEN6 battlefields should fill the engine's active playfield instead of appearing as a small image in the upper-left.
- Android 0.2.38 portrait: the battlefield should scale to the available playfield; HP/status and Modern lower UI should stay aligned and touch controls should remain the final overlay.
- If a TouchSkin with a reserved screen viewport is enabled, KIM should fill that reserved viewport rather than the entire phone framebuffer.
- Re-check KRS 4:3 enemy clearance and GEN6 KRBA targeting; both still use the same final arena geometry as v8.6.23.

## v8.6.23 compatibility test
- New third-party battle-owner registry defaults scene-owning mods to KIM Battle Lite arena/HUD bypass.
- `modernUi = lower` reuses the Battle Art-style Modern lower-panel ownership split.
- KIM battle sprites and KRBA are disabled for registered scene owners unless that source explicitly opts in.
- Third-party full UI owners can claim Battle/Dialogue/Pokemon/etc. presenter families so Modern UI yields before native suppression.
- 4:3 KRS: enemy battlers move 72 px left for safer right-edge clearance, with KRBA enemy targeting following the same anchor. 3:2 and wider placement should remain unchanged.

## v8.6.22 test focus
- Confirm the **BATTLE UI MODE** row is gone from Modern UI settings.
- Confirm KRS and GEN6 still use the Modern lower command/move/message panel.
- Confirm Battle Art still keeps its own HP/status/EXP HUD while using the Modern lower panel and Kanto in Motion Battle Text Size.

## v8.6.21 Battle Art text sizing

- In detected Battle Art/voxel battles, Modern UI's lower command/move/message text now uses Kanto in Motion's `BATTLE TEXT SIZE` value exactly like KRS/GEN6.
- Battle Art's HP/status/EXP HUD fonts and the lower-panel geometry are not scaled by this option.

## v8.6.20 Battle Art lower UI test
Test a Battle Art voxel battle with MODERN BATTLE UI enabled and LEAVE 3D BATTLES ALONE disabled. Confirm the Modern command/move/message strip appears, Battle Art HP/status/EXP remain visible, and the voxel scene/attack animations are unchanged.

## v8.6.19 test focus
- KRS: compare any available shiny encounter against the same normal species. Their visible ground/hover plane should match even when the shiny atlas has a larger transparent canvas.
- Especially re-check Rattata (Gen 5 front/back and Gen 3 front) as the original regression case.
- GEN6: re-check Ember/Slash/Growl/Peck/Thunderbolt alignment; v8.6.19 keeps the v8.6.18 actual-battler-center targeting while adding the generalized shiny ground correction.

# v8.6.17 Gen 2 sprite test

1. Open the Gen 2 Pokédex and view a seen Farfetch'd entry. It should use the animated front sprite from `farfetchd.png`.
2. View a seen Mr. Mime entry. It should use the animated front sprite from `mr-mime.png`.
3. Spot-check another normal species to confirm existing animated Pokédex sprites are unchanged.

# v8.6.16 test focus

1. On KRS, test Slash, Ember, Growl, Rage, and an enemy attack such as Peck. No giant white 160x144-derived block should appear.
2. Switch ARENA FILL to GEN6 and use Ember/Slash/Growl. KRBA effects should now be visible instead of missing.
3. Confirm GEN6 lower command/move/message UI matches KRS width/height and keeps the 3 px left/right/bottom inset.
4. Confirm the trainer/send-out intro still appears; settled high-resolution battlers should remain single-copy.

# v8.6.15 test focus

Test Slash as the no-flash control, then Ember, Growl, Rage, and enemy Peck. The KRS arena should remain visible throughout; no 160x144 white paper block should cover the center of the screen.

# v8.6.13 test focus

Test Ember first, then Thunderbolt and an enemy move that previously flashed white. Slash should remain unchanged. The unwanted extra full-screen native white blink should be gone while KRBA's own authored effects remain.

# v8.6.12 test focus

Use Ember and several other attacks that previously produced the white-screen flash. The attack artwork should remain, but the extra 85% white full-window blink should be gone.

# v8.5 test focus

## Shiny encounters and capture

1. Open KANTO IN MOTION -> BATTLE and set `SHINY ODDS` to `ALWAYS` for the first test.
2. Enter a normal wild battle. The opponent should use the selected generation's shiny front atlas when one is imported.
3. Catch that Pokemon. Its canonical shiny DVs should be retained by the normal Gen1 capture flow.
4. Open Party/Summary: Kanto in Motion should still resolve the shiny animated front from the caught Pokemon's DVs.
5. Send the caught Pokemon into battle. A shiny back atlas is used when the selected BACK SET has one; otherwise the normal back art is the safe fallback.
6. Restore a preferred rarity afterward (default `NATIVE 1/8192`).

## Pokeball send-out visual

The v8.4 timing gates remain, but v8.5 stops replacing the native player/enemy pic with a transparent settled-battle placeholder while `sendingOut` / `enemySendingOut` is active. Verify the trainer throw now shows the native Pokeball/release visuals, the Pokemon is not visible early, and the fullscreen native-resolution battler takes over after the send-out phase ends.

# v8.4 test focus

## Pokéball send-out timing

Start a normal battle and watch the player's opening send-out sequence. The expected order is:

1. Trainer back sprite is visible.
2. Trainer throws the Pokéball.
3. Player Pokémon stays hidden while the ball travels.
4. Pokémon first becomes visible at the native ball-release/pop-out point and follows the engine's grow/send-out effect.

The Pokémon should no longer be visible before the throw, disappear during the ball animation, then reappear. Enemy send-out/hide states use the same native visibility gates.

# v8.3 test focus

- Keeps the v8.2 full-width/full-height lower battle panel footprint.
- Raises the entire Modern battle panel so it sits directly below the player back sprite instead of at the physical bottom edge.
- Fixes `A  continue` to measure its live font width/height and remain inset inside the bottom-right border at every text scale.
- Extends `BATTLE TEXT SIZE` from 100% through 400% in 25% steps above 200%.
- Removes the `AA` option and its arena supersampling path; the Gen 6 arena now draws directly at final window resolution.
- Battlefield, Battle Art HP/status HUD, QOL EXP/caught indicator, Pokeball Colorfix compatibility, battler scale/anchors, and GRID/VERTICAL move layouts are otherwise unchanged.

# v8.2 test focus

Verify dialogue, FIGHT/POKEMON/ITEM/RUN, GRID moves, and VERTICAL moves all occupy the same wide bottom panel matching the v7.8 reference. No arena, battler, HP/XP, QOL, or Pokeball geometry changed.

# v8.0 test focus

Check that the command menu and battle messages use the same large bottom footprint as v7.8, changing `BATTLE TEXT SIZE` changes only the font, GRID shows 2x2 moves on the left with MOVE INFO on the right, and VERTICAL shows move slots 1-4 top-to-bottom. HP/EXP/Pokeball overlays and battlefield geometry should remain unchanged.

# v7.9 — Modern lower panel isolation + battle text size + Typed Move Colors compatibility

- Fixes Modern UI enemy/player HP cards appearing behind Kanto in Motion's Battle Art-style HP HUD. KIM's `dramaticShapeShot` compatibility geometry no longer makes Modern UI choose its generic scene-HUD mode; KIM-owned battles always use the lower-panel-only presenter.
- Adds **BATTLE TEXT SIZE** = 100% / 125% / 150% / 175% / 200%, default **150%**. It scales only Modern UI's battle command, move and message typography; Battle Art HP/status and QOL EXP stay unchanged.
- Adds runtime compatibility for `typed_move_colors`: while KIM Modern battle UI owns the lower panel, Typed's detached battle cursor/grid yields so there is only one 2x2 move-navigation owner. Typed settings/colors are still mirrored into KIM move cells and Typed remains untouched outside KIM-owned battle phases. No Typed Move Colors files are modified.

# v7.8 — Modern UI lower battle panel

This pass leaves the accepted v7.7 battlefield/HUD geometry alone. The integrated Modern UI now replaces only the vanilla lower command/move/message box while Kanto in Motion Battle Lite owns the battle. HP/status/EXP presentation remains Kanto/source-owned.

**Expected ownership in battle:**
- Kanto in Motion: GEN6 arena + animated battlers + Battle Art-style HP/status bands
- Quality of Life (when installed): EXP/caught overlays using the existing Battle Art geometry seam
- Modern UI: FIGHT / POKEMON / ITEM / RUN, move selection, battle messages
- Native BattleState: mechanics, input callbacks, attack timing, send-out/faint/capture state

# v7.7 — 125% battler baseline + 140 PX arena default

This pass keeps the v7.6 battler anchors but increases the final fullscreen draw size by 25% for both sides. `PLAYER PKMN SIZE` now defaults to **125%**; the enemy uses a matching independent 125% baseline. `BG Y-OFFSET` now defaults to **140 PX**. Existing saved settings are not forcibly overwritten; use **RESET TO DEFAULT** to adopt the new defaults.

# v7.6 — lower battlers + SCALED QOL XP alignment

- Keeps v7.5 native-resolution 4x-at-1080p sprite rendering and does not reintroduce the low-resolution proxy.
- Lowers the player battle anchor from logical Y 96 to 110 so large backs such as Charizard sit much closer to the dialogue box.
- Lowers the enemy anchor from logical Y 56 to 65 so foes sit lower on the Gen 6 field without changing their size.
- Fixes Quality of Life's XP bar in `HUD SCALE = SCALED` from Kanto in Motion only. QOL's Battle Art compatibility uses a shared `dramaticShapeShot.ly`, while Battle Art's scaled player band has an additional 56-pixel vertical offset. KIM now applies that missing offset only to QOL's player-side EXP primitives on the fullscreen world canvas.
- QOL's caught/Pokedex indicator remains on the enemy-band origin. Quality of Life itself is not modified.
- Pokeball Colorfix remains unmodified.

# v7.5 — Battle Art sprite size + HUD SCALE

- Keeps v7.5 native-resolution animated battle sprite rendering, but increases the final fullscreen sprite rung (4x at a 1920x1080 / 6x battle stage) so small species no longer look miniature.
- `PLAYER PKMN SIZE` still multiplies only the player-side final draw in 5% steps.
- `HUD SCALE` now follows Battle Art 1.9.8 `OverworldBattle.snapRects`: `OG` uses the full window-fit integer rung and `SCALED` uses exactly one rung smaller.
- No Quality of Life or Pokeball Colorfix files are modified.

# v7.4 focused test

## v7.4 fullscreen sprite/HUD-band correction

- Fullscreen animated battlers are drawn from the native atlas frame directly into the final window-resolution arena.
- The old 56px intermediate proxy is bypassed in fullscreen battles, preventing detail loss before enlargement.
- `PLAYER PKMN SIZE` is applied at the final native-resolution player draw.
- Opponent size is independent of `HUD SCALE`.
- The entire 48-row enemy/player Battle Art HUD bands are captured and snapped; the original source HUD band is suppressed so Pokeball Colorfix does not leave a second zone-coloured party-ball row in the middle.
- `quality_of_life.zip` and `pokeball-colorfix.zip` are not modified.

# v7.4 compatibility/scale test

- `PLAYER PKMN SIZE` now multiplies the actual `BattleState.resolveBattleScale` player-card path; the 50%-200% / 5% ladder no longer relies on changing replacement Canvas dimensions.
- Imported animated opponent fronts use a 0.75x standalone baseline so OG HUD mode does not make opponents read as oversized desktop sprites. ROM/static fronts keep the engine's normal scale.
- Kanto in Motion now publishes a Battle Art-compatible `battle.dramaticShapeShot` while it owns a fullscreen Gen1 battle. Quality of Life already consumes this contract for its XP bar and Pokedex/caught indicator, so those overlays can follow KIM without any QOL patch.
- The snapped Battle Art HUD and exported compatibility geometry now share one player/enemy HUD-band transform in both `HUD SCALE = OG` and `SCALED`.
- The same compatibility contract is exposed to other Battle-Art-aware battle add-ons, including Pokeball/effect mods; no external mod files are modified.

# Kanto in Motion Battle Lite — Gen1 test v7.2

This pass keeps the **Battle Art 1.9.8-style 2D/native BattleState composition** from v6 and ports the requested Battle Art controls without loading voxel battle code.

## Gen1 BATTLE submenu

- **BATTLE SYSTEM:** ON / OFF
- **BATTLE SPRITES:** ON / OFF
- **FRONT SET:** SAME AS MENU / GEN2 / GEN3 / GEN4 / GEN5
- **BACK SET:** GEN5 / GEN3 / ROM
- **PLAYER PKMN SIZE:** 50%..200% in 5% steps — default 125%
- **RESET TO DEFAULT:** restores all BATTLE submenu options to their defined defaults
- **HUD SCALE:** OG / SCALED — **default OG**
- **AA:** OFF / 2X / 4X
- **ARENA FILL:** OFF / WHITE / GEN6
- **BG Y-OFFSET:** 0..400 PX in 20 PX steps — default 140 PX
- **HUD COLOR:** COLOR / INVERTED

There is no Battle Art / Modern HP selector. Kanto in Motion's battle system always uses the Battle Art-style HP/status treatment when it owns the battle.

## Battle Art-derived behavior

### HUD SCALE

This follows Battle Art 1.9.8's `OverworldBattle.snapRects` rule:

- **OG** uses the normal integer window-fit scale for both enemy and player status blocks.
- **SCALED** uses Battle Art's compact one-integer-rung-smaller HUD.

Kanto in Motion defaults this row to **OG** as requested.

### AA

The Battle Art ladder is retained: **OFF / 2X / 4X**. The no-voxel build applies supersampling to the full-window arena plate and folds it back to the display resolution. Driver texture-size limits are respected. Pokemon and the native Gen 1 UI remain nearest-neighbour pixel art rather than being blurred by arena AA.

### PLAYER PKMN SIZE

Battle Art 1.9.8 exposes `PLAYER PKMN SIZE` as `BattleArt.playerPokemonScaleSetting` in `BattleArt.lua`. Kanto in Motion mirrors that player-only scale behavior, expanded from Battle Art's original 10% ladder to 5% steps: 50%, 55%, 60% ... 195%, 200%. The default is now 125%.

### ARENA FILL / BG Y-OFFSET

The no-voxel subset is:

- **OFF** — native battle field/paper behavior.
- **WHITE** — full-window white arena.
- **GEN6** — full-window routed Gen 6 Kanto plate.

`BG Y-OFFSET` uses Battle Art's 0..400 source-pixel crop ladder and defaults to **140 PX**. `PNG` and Stadium `BLUE` are intentionally omitted because those are separate Battle Art/provider features rather than part of this standalone no-voxel package.

## Shiny battle Pokemon

v7.1 uses Battle Art 1.9.8's Gen 1 DV rule directly. A Pokemon is shiny when Defense, Speed and Special DVs are 10 and Attack DV is 2, 3, 6, 7, 10, 11, 14 or 15. An explicit `mon.shiny = true` from another compatible engine/mod is also accepted.

When a shiny is detected, Kanto in Motion routes to the selected generation's shiny animated metadata/assets. If that generation/side has no shiny record, the normal animated record remains the fallback.

## No voxel battle code

This build still does **not** load Battle Art's Voxel3D, VoxelScene, BattleScene, mesh streaming, 3D camera/orbit, terrain extrusion, depth-of-field, world collision or billboard renderer.

## First test

1. Disable Battle Art itself.
2. Set **BATTLE SYSTEM = ON**.
3. Set **HUD SCALE = OG**.
4. Start with **AA = OFF** and **PLAYER PKMN SIZE = 125%**.
5. Set **ARENA FILL = GEN6**, **BG Y-OFFSET = 140 PX**.
6. Enter a battle and verify player/enemy placement, bottom battle menu, and edge HUD.
7. Adjust **PLAYER PKMN SIZE** until the player back sprite is where you want it.
8. Try **AA = 2X/4X** and compare only the arena/background smoothness.
9. Test a known shiny-DV Pokemon and confirm the shiny animated atlas is used.

## v8.1 lower-panel routing fix

- The Kanto in Motion battle presenter now keys the Modern lower-panel path off the persistent BattleState ownership flag, not only the short-lived render.hud game flag.
- Battle dialogue and FIGHT / POKEMON / ITEM / RUN now stay in the full-width bottom panel.
- BATTLE TEXT SIZE changes only typography.
- MOVE LAYOUT = GRID uses 2x2 moves on the left with MOVE INFO on the right; MOVE LAYOUT = VERTICAL uses four stacked move rows. Both layouts use the same full-width bottom panel.


### v8.5 targeted compatibility
- SHINY ODDS are DV-backed and intended to persist through capture because they modify the actual wild Pokemon's DVs, not only its battle sprite selection.
- During `sendingOut` / `enemySendingOut`, KIM no longer substitutes the Pokemon proxy into the native pics path. This leaves the native Pokeball throw/open sprite path intact.
- When `battle.animPlayer._krs` is active, KIM converts only additive/subtractive blend requests to alpha while capturing KRBA's transparent intermediate animation layer. Slash/ordinary alpha moves are unchanged; Ember's additive particles should survive the fullscreen composite.

### v8.6.27 mobile checks
- Portrait: test SCREEN POS CENTER / UPPER / TOP and confirm KRS/GEN6 field, battlers, KRBA effects, trainer intro, HP HUD, and native command/message strip move together.
- Landscape: test HUD SCALE OG and SCALED with touch controls visible; SCALED should be one physical integer rung smaller rather than collapsing to a tiny 1x HUD.
- Title: test SCREEN POS CENTER / UPPER / TOP and confirm the animated trainer, cycling Pokemon, and KIM logo remain attached to the native title composition with no stock Pokemon logo visible underneath.

### v8.6.59 shiny/player + catch-target checks
- Start with a known shiny player Pokémon: after the player send-out completes, the 35-frame sparkle and `shiny.wav` should play once over the player's battler.
- Encounter a shiny opponent: the same effect should still play once over the enemy battler.
- If a failed Poké Ball catch hides then restores a shiny enemy, the shiny cue should not replay simply because SHOWPIC made it visible again.
- Throw a Poké Ball in a wild battle with KRS and GEN6 arena fills: the toss should leave from the normal player-side origin and finish on the actual enemy Pokémon instead of the old native 160x144 target. POOF, shakes, and the caught resting ball should remain aligned with that corrected endpoint.
- Trainer-battle BLOCKBALL and ordinary POOF/send-out effects should remain unchanged.

