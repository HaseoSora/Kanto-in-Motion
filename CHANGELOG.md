# v1.4.0 — Gen 1 HD public release

- Promotes the confirmed-good Gen1 HD v39 code and asset baseline into the public release line.
- Updates the manifest/package version from 1.3.7 to 1.4.0.
- Ships HD animated Pokémon #001–151, 1920×950 time-of-day battle backgrounds, restored 165-move Gen 1 animations/SFX, Modern UI/HUD controls, shiny effects, shadows, and trainer/title presentation.
- Includes the confirmed desktop/mobile Battle Art 1.11.x and PotatoVoxel compatibility paths, including 100%-neutral 3D sizing, HUD/QOL anchors, move-animation projection, mobile ownership guards, and trainer handling.
- Includes the final v38/v39 fixes for KRBA full-screen BG/FG planes, Battle Art party-ball coloring, PotatoVoxel PC player scale, and name-independent caught-icon placement in 3D-BTL OFF battles.
- Public release scope is Gen 1 only; Gen 2 support and the legacy generation-selection battle-art pipeline are not included.

# Gen1 HD v39 — Potato PC neutral size + flat caught-icon anchor

- Desktop PotatoVoxel player Pokemon now use an internal `0.80` authored baseline, matching the approved near-card calibration used by Battle Art PC.
- `3D PKMN SIZE = 100%` is the neutral desktop PotatoVoxel reference; the control now scales both staged Potato Pokemon on desktop without changing the enemy at 100%.
- PotatoVoxel Android/iOS keeps the confirmed v34 player `0.66` and mobile enemy-size calibration unchanged.
- BACK SPRITES/pinned and full staged-card Potato player paths use the same desktop player baseline.
- Desktop `3D-BTL = OFF` caught/Pokedex pixels are now decoded from Quality of Life's name-dependent source anchor and replayed at KIM's fixed enemy-HUD `+8/+9` anchor.
- The flat caught-icon fix is shared by Battle Art and PotatoVoxel fallback battles, so short names no longer shift the icon.
- v38 KRBA fullscreen BG/FG, attack anchors, Battle Art party-ball coloring, HUD geometry, and all mobile paths remain unchanged.

# Gen1 HD v38 — KRBA fullscreen anchors / BG-FG / desktop QOL / Battle Art balls

- Restores KIM 1.3.7's live KRBA wide-session handoff for the current HD
  1920×950 battle background system.
- Restores full-window `drawWideBack` / `drawWideFront`, preventing move BG/FG
  planes from being confined to the native Gen 1 battle surface.
- Restores species-aware player/enemy KRBA effect anchors from the actual HD
  battler metrics.
- Restores KRBA battler USER/TARGET transforms on KIM's final-resolution 2D
  Pokémon while preserving the newer contact-shadow system.
- Restores Battle Art final-window `drawBattleArtScreenBack/Front` fallback for
  Thundershock/Thunder/Thunderbolt/Flash-style screen planes.
- Desktop Battle Art QOL EXP/caught overlays now prefer KIM's actual visible HUD
  geometry while BATTLE SYSTEM is ON, mirroring the confirmed mobile ownership
  model.
- Restores the original 1.3.7 Battle Art `ICONS_DRAMATIC` Poké Ball Colorfix
  path so battle-entry party balls remain colored under the 3D HUD bake.
- Keeps v35/v37 sizing, v31 enemy HUD inset, v36 attack assets, mobile fixes and
  PotatoVoxel compatibility unchanged.

# Gen1 HD v37 — PC Battle Art size + desktop QOL anchors

- Restores the original KIM 1.3.7 `battle_art_desktop_hud_geometry.lua`.
- Restores the original KIM 1.3.7 `battle_art_desktop_qol_overlay_alignment.lua`.
- Adapts the desktop HUD geometry to the current v31 enemy visible-left inset
  (logical X=6 instead of the original X=2).
- EXP and level-up burst primitives re-anchor to the live player HUD at
  `+41 * hudScale`.
- Already-caught icon pixels are decoded relative to QOL's name-dependent
  source position and redrawn at a fixed KIM enemy-band `+8/+9` anchor.
- Adds a desktop-only 0.80 KIM player-card baseline in Battle Art.
  `3D PKMN SIZE = 100%` remains the neutral user adjustment, and
  `PLAYER PKMN SIZE` still fine-tunes only the player afterward.
- v36 move animations and all mobile paths are preserved.

# Gen1 HD v36 — restore integrated move animations

- Restores KIM 1.3.7's integrated KRBA / Pokémon Essentials move-animation code and `MOVE ANIMATIONS` toggle.
- Restores all 165 Gen 1 move definitions from the original `data/gen1_anims.lua`.
- Installs the user's scanner-remediated animation/SFX package into KIM's original `assets/animations/` and `assets/sfx/` paths.
- Battle Art 1.11 now opts into KIM animations again while keeping v35's confirmed-good 100%-neutral sizing/HUD behavior.
- PotatoVoxel again opts into KIM animations and restores the original live `AnimPlayer` binding, semantic battler transforms and final-window KRBA projection while preserving current camera/trainer/mobile/HUD fixes.
- No removed Battle Art generation sprite packs or legacy Gen 6 Battle Art backgrounds are restored.

# Gen1 HD v35 — Battle Art neutral 100% calibration

- Changes `3D PKMN SIZE` default from 75% to 100%.
- Bakes the former 75% Battle Art calibration into KIM as an internal `0.75` baseline multiplier.
- Therefore new 100% produces the same preferred Battle Art size that the old 75% setting produced.
- User values now behave intuitively around that baseline: 75% is actually 25% smaller, 125% is actually 25% larger.
- `PLAYER PKMN SIZE` remains a separate player-only multiplier after the scene-wide Battle Art size.
- At v35, PotatoVoxel did not yet consume `battle3dPokemonSize`; Potato sizing, HUD/QOL anchors, trainers, Modern UI and desktop/mobile Potato behavior were unchanged at that stage. v39 later extends the 100%-neutral control to desktop PotatoVoxel.

# Gen1 HD v34 — direct PotatoVoxel mobile player scale

- Removes the ineffective `POTATO MOBILE PLAYER SIZE` option from the visible pinned-player path.
- Applies a direct Android/iOS player multiplier of 0.66 at both `_kantoInMotionPotatoPinnedBackNative` and `_kantoInMotionStagedBattleSprite`.
- This is ~29% larger than v32/v33's effective 0.51 player result and ~10% larger than v31's 0.60 baseline.
- Keeps `POTATO MOBILE ENEMY SIZE = 85%` and the user-confirmed-good enemy presentation unchanged.
- No Battle Art, HUD, QOL, trainer, camera, Modern UI, or desktop changes.

# Gen1 HD v33 — PotatoVoxel mobile player/enemy size split

- Splits v32's shared Potato mobile size control into separate player and enemy settings.
- Enemy default remains 85%, preserving the user-confirmed-good v32 enemy size.
- Player default becomes 95%; combined with the existing 0.60 mobile player compensation this yields an effective 0.57 instead of v32's 0.51.
- Covers staged 3D cards and the pinned player path.
- Desktop PotatoVoxel and all Battle Art/KIM HUD/QOL/trainer behavior remain unchanged.

# Gen1 HD v32 — PotatoVoxel mobile Pokemon size control

- Adds `POTATO MOBILE PKMN SIZE` (50%-125%, 5% steps, default 85%).
- Applies only on Android/iOS; desktop PotatoVoxel sizing is unchanged.
- Applies one final shared multiplier to both KIM player and enemy Pokemon so species-relative scale remains intact.
- Player retains the established mobile 0.60 compensation and PLAYER PKMN SIZE multiplier before the new shared Potato factor.
- Enemy now receives the same user-visible Potato mobile size control instead of bypassing mobile scale compensation.
- Covers both staged Potato 3D cards and the final-resolution pinned player path.
- No Battle Art, trainer, HUD, QOL anchor, Modern UI, camera, or desktop changes.

# Gen1 HD v31 — global enemy HUD left inset

- Moves KIM's shared enemy HP/status band visible-left anchor from logical X=2 to X=6.
- This shifts the complete enemy HUD right by 4 HUD pixels in normal KIM, Battle Art, and PotatoVoxel because all three consume `battleHudGeometry()`.
- Enemy party Pokeballs and the restored QOL already-caught icon continue to follow the same geometry automatically.
- Player HUD, EXP bar, Pokémon sizing/placement, Modern UI, trainer behavior, HUD color/invert, and external mods are unchanged.

# Gen1 HD v30 — restore original KIM 1.3.7 mobile QOL anchor system

- Restores `lib/mobile_qol_exp_reconstruction.lua` directly from the user's known-good pre-cleanup KIM 1.3.7.
- Installs it after the Battle Art 1.11 mobile stage-only bridge and passes the current stage-active callback plus KIM's live `battleHudGeometry`.
- EXP fill and burst are rebased to KIM's player HUD band instead of Battle Art/QOL source coordinates.
- Already-caught RED/GREY/GEN2 pixels are decoded from QOL's source cluster and redrawn at a fixed KIM enemy-band-local anchor, preserving alignment for short species names.
- Covers Battle Art mobile 3D-BTL ON and the original flat/mobile fallback behavior without modifying Quality of Life.
- No Pokemon-size, trainer-size, Modern UI, HUD-color, PotatoVoxel, or desktop changes.

# Gen1 HD v29 — Battle Art mobile enemy-size calibration

- Keeps the user-confirmed-good Battle Art mobile player/back KIM card at 80% physical preparation.
- Raises only the Battle Art mobile enemy/front KIM card from 80% to 95% physical preparation.
- Leaves v28 KIM-owned HP/status/EXP HUD behavior unchanged, including KIM HUD COLOR / INVERTED.
- No PotatoVoxel, trainer-size, Modern UI, camera, or desktop changes.

# Gen1 HD v28 — Battle Art mobile size + KIM HUD ownership

- Raises Battle Art Android/iOS physical KIM card preparation from 60% to 80% for both front/enemy and back/player after v27 tested too small.
- Restores the original KIM 1.3.7 mobile Battle Art ownership model: Battle Art owns only the 3D stage/camera/effects; KIM owns the final HP/status/EXP HUD.
- Re-enables Battle Art `snapHUDs` suppression only on the active mobile KIM stage-only path to avoid a duplicate source HUD.
- Restores direct `mobileBattleArtStageOnly` handling in KIM HUD activation, safe native HUD capture, battle flags, dialog geometry and final HUD composition instead of depending solely on the generic external-stage predicate.
- Removes the v27 Battle-Art-owned-HUD bypass. KIM `drawBattleHud` is again authoritative, including `HUD COLOR = INVERTED`, HUD size and HUD opacity.
- Modern UI remains lower-panel-only for Battle Art. No PotatoVoxel or trainer-size changes.

# Gen1 HD v27 — Battle Art mobile enemy + HP HUD

- Battle Art Android/iOS enemy/front KIM texture is physically prepared at 60%, the same authoritative seam that v26 proved effective for the player/back card.
- The accepted desktop enemy `1.25x` correction is now desktop-only; mobile uses the neutral enemy factor after physical preparation.
- Restores Battle Art HP/status/EXP ownership by no longer disabling `OverworldBattle.snapHUDs` and no longer claiming `battle.presentation.suppress_native.v1` for the HUD.
- KIM's mobile status-HUD suppression and replacement `drawBattleHud` are bypassed while the Battle Art mobile hybrid owns HUD, preventing both disappearance and duplicates.
- Modern UI still owns only the lower command/move/message panel.
- No PotatoVoxel or trainer-size changes in this build.

# Gen1 HD v26 — mobile render-path correction

- Battle Art Android/iOS player/back HD frames are physically prepared at 60% before Battle Art computes card metrics/world geometry; removes the ineffective mobile `presentationScale` workaround.
- PotatoVoxel Android/iOS KIM player art is multiplied by 0.60 at both authoritative KIM exports: `_kantoInMotionStagedBattleSprite` and `_kantoInMotionPotatoPinnedBackNative`.
- Raises mobile KIM trainer scale to 0.95 for normal/path-backed and Potato pinned trainer paths; desktop stays 1.0.
- Adds a Battle Art 1.11 mobile stage-only bridge adapted from the user's original pre-cleanup KIM 1.3.7 architecture: disables Battle Art snapped HUD/panels while active, lets Modern UI own text/panels, and routes Battle Art into KIM's final mobile HUD/Modern compositor.
- Retains the v23 render.hud graphics-stack boundary guard and v22 trainer animation seam.
- No Battle Art or PotatoVoxel files are modified.

# Gen1 HD v25 — mobile anchor + scale correction

- Fixes the reason v24 did not visibly shrink Battle Art HD Pokemon: replaces the compatibility module's cached `love.system` test with KIM's runtime `_kantoInMotionNativeMobileHost()` detector.
- Battle Art Android/iOS KIM cards now actually receive the existing 0.50 final `presentationScale` compensation.
- Battle Art player card gets a mobile-only +right placement correction via stable `tex.ax = baseAx - 20`; enemy/world/camera geometry is untouched.
- PotatoVoxel mobile pinned KIM player shift increases from +32 to +56 logical px.
- Normal KIM mobile selected trainer changes from 0.65 to 0.80 after v24 proved 65% too small; desktop remains 1x and Potato pinned trainer remains 0.85.
- Retains v22 animated-trainer seam and v23 Battle Art TouchControls stack guard.

# Gen1 HD v24 — mobile Battle Art/Potato/KIM sizing split

- Battle Art 1.11 Android/iOS: applies a final 0.50 world-card scale compensation to KIM HD Pokemon only. Desktop Battle Art sizing is unchanged.
- Normal KIM mobile trainer: adds a generic live-trainer scale flag so the raw animated 80x80 frame finally uses the intended 0.65 scale with 3D-BTL OFF.
- PotatoVoxel mobile trainer: raises the pinned selected trainer from 0.65 to 0.85 after v23 proved 65% was too small.
- PotatoVoxel mobile player: shifts the final-resolution pinned KIM Pokemon +32 logical px right instead of +16.
- Keeps v22 trainer animation, v23 Battle Art graphics-stack guard, Potato camera, enemy placement, desktop geometry and external mod files unchanged.

# Gen1 HD v23 — Android/iOS Potato/Battle Art fixes

- Mobile PotatoVoxel: moves the final-resolution pinned KIM player sprite 16 logical pixels right to correct the left-heavy placement shown at 2048x945.
- Mobile trainer: KIM's selected 80x80 player-trainer frames now resolve at 0.65x on Android/iOS only; desktop remains at the confirmed v22 1x scale. The same rule covers PotatoVoxel's raw animated frame and Battle Art's selected trainer path.
- Battle Art 1.11 mobile: adds a render.hud graphics-stack boundary guard adapted from the user's original pre-cleanup KIM mobile implementation. It unwinds leaked LOVE states and rebinds GameViewport before/after HUD composition, immediately before TouchControls.
- Fixes the v22 local ordering bug where `mobilePinnedTrainer` was referenced before its declaration.
- No external Battle Art or PotatoVoxel files are modified.

# Gen1 HD v22 — original Potato pinned-trainer animation seam

- Compared directly against the user's uploaded original pre-cleanup KIM v1.3.7.
- Found why v18-v21 could not animate the visible trainer: PotatoVoxel BACK SPRITES skips the player texture provider entirely (`OverworldBattle.textures` does not request the player card while `backPinned()` is true).
- Restores KIM's original native `drawPicsLayer` live trainer-frame substitution for the Potato pinned trainer.
- Keeps v17's correct size by adding a dedicated `_kantoInMotionPotatoPinnedTrainerScaleActive` guard and returning 1x from `BattleState.resolveBattleScale` only while that raw 80x80 trainer frame is being drawn.
- Does not change the existing pinned Pokemon scale seam.
- Restores the original pre-cleanup desktop/mobile trainer-ownership policy from `potato_voxel_compat.lua`.
- RED / redplayer.png remains the default PLAYER TRAINER; Potato camera behavior is unchanged.

# Gen1 HD v17 — restore exact working Potato trainer capture

- Found the actual trainer-size regression by diffing against the previous confirmed-working PotatoVoxel KIM build.
- v14 had started replacing `battle.playerBackPic` with the raw 80x80 animated trainer frame inside KIM's `drawPicsLayer` wrapper.
- PotatoVoxel's `sideTexture` invokes that wrapped `drawPicsLayer` during its trainer capture, so the replacement bypassed KIM's path-based `battle_sprite_scales` registration and produced the giant trainer.
- Cooperative external stages now leave `playerBackPic` untouched during that capture. KIM still selects the requested trainer earlier at `player.sprite`; Potato then captures it through its own native trainer path exactly as the known-good build did.
- Removes the ineffective `POTATO TRAINER SIZE` workaround from v16.
- Normal KIM trainer animation remains enabled because the raw-frame substitution is still used when no cooperative external stage owns the battle.
- `RED / redplayer.png` remains the default trainer and the v12 Potato camera pullback remains unchanged.

# Gen1 HD v16 — PotatoVoxel trainer scale fix

- Fixes the remaining oversized/cropped KIM trainer in PotatoVoxel 1.9.6 by explicitly building the 3D intro card from KIM's selected trainer frame instead of relying on Potato's unchanged 1.9.6 trainer capture scale.
- Adds `POTATO TRAINER SIZE` (50%-100% in 5% steps), default 65%.
- The option scales only the selected KIM trainer artwork inside Potato's normal 160x144 logical world card; the card anchor/camera/scene remain Potato-owned.
- `trainer=true` preserves the correct back-facing orientation and prevents player-side mirror.
- `DEFAULT / ROM` still falls back to PotatoVoxel/Gen1Recomp's native trainer.
- Normal KIM trainer sizing, the accepted Potato camera pullback, HD Pokemon cards, Battle Art compatibility and 2D behavior are unchanged.

# Gen1 HD v15 — PotatoVoxel native trainer capture restore

- Fixes the oversized/cropped selected trainer in PotatoVoxel.
- Keeps KIM's early `player.sprite` trainer selection, so `PLAYER TRAINER` still chooses the identity before `BattleState.playerBackPic` is cached.
- Removes KIM's late/prebuilt Potato trainer-card return. PotatoVoxel now captures the selected KIM trainer through its own `OverworldBattle.sideTexture`, restoring Potato's native trainer scale, intro slide, trainer flag and anchor semantics.
- Keeps true-alpha capture active for the selected KIM trainer.
- `RED` / `redplayer.png` remains the default KIM trainer.
- Keeps the accepted Potato camera pullback and HD Pokemon-card quality unchanged.

# Gen1 HD v14 — restore selected KIM trainer system

- Restores the user's 13 supplied 400x80 / five-frame animated player-trainer sheets.
- Restores `PLAYER TRAINER` to KIM's Battle menu with `RED` / `redplayer.png` as the default selection.
- Recreates KIM's generated 80x80 first-frame assets for Gen1Recomp's `player.sprite` seam and registers them at native 1x battle-pic scale, preventing the huge/cropped trainer seen in v13.
- Restores KIM's staged trainer-card and raw trainer-frame exports so PotatoVoxel uses the exact KIM selection and animation state rather than its own trainer asset path.
- Removes the temporary Potato-only `assets/battle/kim_red_trainer.png` workaround.
- Keeps the accepted v12 Potato camera pullback, v11 high-resolution Pokemon cards, and later Battle Art/HD fixes unchanged.

# Gen1 HD v13 — restore proven PotatoVoxel trainer hook

- Restores the earlier confirmed-working trainer architecture: KIM now replaces the player battle trainer at Gen1Recomp's `player.sprite` seam before `BattleState.playerBackPic` is created.
- Adds `assets/battle/kim_red_trainer.png`, a 40x56 first frame derived from KIM's existing animated Red title atlas. It is not a restored Battle Art trainer asset.
- Restores `_kantoInMotionExternalStageAllowsKimTrainer` so PotatoVoxel can explicitly request KIM's trainer identity without KIM taking over the 3D scene.
- Leaves the v12 `POTATO CAMERA` behavior unchanged.
- Keeps the v11 high-resolution Potato Pokemon cards and all accepted Battle Art/2D fixes unchanged.

# Gen1 HD v12 — PotatoVoxel camera pullback / trainer provider fix

- Added `POTATO CAMERA` (100%-150%, 5% steps, default 115%) to widen PotatoVoxel's staged-battle framing from KIM at runtime without modifying PotatoVoxel on disk.
- Wraps PotatoVoxel `BattleCam.frameH`, so its own camera eye/focus, orbit, pitch, zoom, arena pins and shadow framing remain internally consistent.
- Fixes the remaining vanilla trainer intro by servicing `showPlayerBack` immediately whenever PotatoVoxel calls KIM's texture provider, instead of requiring the later `stageLive()` predicate.
- Uses KIM's bundled animated `assets/title/red_title.png` directly for that intro; no removed Battle Art trainer assets are restored.
- Keeps the v11 high-resolution Potato card backing, v10 sizing, v9 Battle Art shadow fix and all accepted title/battle sizing unchanged.

# Gen1 HD v11 — PotatoVoxel HD texture / trainer fix

- Fixes heavily pixelated KIM HD enemy Pokemon on PotatoVoxel 1.9.6 by using high-resolution backing cards while preserving the same 160x144 logical world-card geometry.
- Uses linear/aniso filtering only on the Potato 3D card texture; KIM's source sheets and normal 2D presentation remain unchanged.
- Replaces Potato's vanilla player-trainer intro card with KIM's existing animated Red title atlas; no removed Battle Art trainer assets are restored.
- Reasserts the KIM texture provider on `battle.started` to avoid late provider replacement.
- Keeps the v10 Potato sizing calibration, v9 Battle Art shadow fix, v8 3D sizing/borderless title fix, and 60% physical HD sprite sheets.

# Gen1 HD v10 — PotatoVoxel 1.9.6 HD-card scale / trainer fix

- Fixes oversized KIM HD Pokemon in PotatoVoxel 1.9.6 by restoring the direct-card minimum scale from 0.5 to 0.1. The current Gen-1 HD metadata uses displayScale values down to about 0.15, so the v9 clamp was enlarging almost every species.
- Restores PotatoVoxel's accepted player semantics: `PLAYER PKMN SIZE = 100%` is 1.00x in PotatoVoxel rather than inheriting KIM's standalone-2D 1.15x baseline.
- Suppresses only the temporary vanilla player-trainer 3D billboard while KIM `BATTLE SPRITES` is ON. The old external trainer asset collection remains removed; native intro/Pokeball timing is unchanged.
- Turning KIM `BATTLE SPRITES` OFF returns the entire trainer/Pokemon presentation to PotatoVoxel/native.
- Keeps v9 Battle Art shadow fix and all v8/v6 title/sizing fixes unchanged.

# Gen1 HD v9 — Battle Art HD-card self-shadow fix

- Fixes the diagonal/diamond shadow-map pattern visible across KIM HD Pokemon cards with Battle Art 1.11 `3D-BTL = ON`.
- KIM HD Pokemon continue to cast Battle Art's real alpha-shaped shadow onto the 3D ground.
- Only shadow-map receiving is bypassed for KIM's visible HD cards, preventing their own caster silhouette from being projected back across the sprite.
- Keeps Battle Art diffuse lighting, day/night tint, depth, 3D camera and all environment shadows.
- Keeps the v8 3D Pokemon sizing and borderless title-screen fixes unchanged.
- KIM's adjustable 2D Pokemon shadow quality/opacity system remains unchanged for `3D-BTL = OFF`.

# Gen1 HD v8 — Battle Art 3D size / borderless title fix

- Added `3D PKMN SIZE`, 50%-125% in 5% steps, default 75%, applied only while Battle Art owns a live 3D-BTL stage.
- Removed KIM's extra 2D-only 1.15x player baseline from Battle Art's 3D world-card path. `PLAYER PKMN SIZE = 100%` is now the neutral 3D card baseline, while KIM's 2D renderer keeps the accepted larger 100% calibration.
- Prevented repeated Battle Art texture reads from compounding `presentationScale` on the same card table.
- Kept the existing enemy HD-front relative correction and placed the new 3D global scale above it.
- Normalized title Pokemon physical size for large/borderless desktop viewports by capping only the Pokemon actor's final viewport scale to the accepted 800px-high test reference. Red, the logo and the native title layout continue to use the normal viewport scale.
- Existing HD assets, title size control, Battle Art MOD MENU entry, 2D Pokemon shadows and time-of-day backgrounds are unchanged.

# Gen1 HD v7 — Battle Art 1.11 compatibility restored

- Restores Battle Art 1.11.0 as an optional cooperative 3D-BTL scene owner without bundling any Battle Art generation assets or Gen6 backgrounds.
- KIM HD Pokemon #001-151 now feed Battle Art through its MODDED/external image path while Battle Art retains the 3D arena, camera, HUD, effects and shadow map.
- KIM per-species HD displayScale and PLAYER PKMN SIZE are applied to Battle Art world cards; 100% retains the accepted v5/v6 baseline.
- Forces only the live Battle Art ownership/view/placement reads required for KIM HD sprites; the user's saved Battle Art settings are not overwritten.
- Restores BATTLE ART to KIM's centralized MOD MENU and opens Battle Art 1.11's own categorized option pages.
- Bundled Battle Art sprite/background assets remain removed from KIM.

# Gen1 HD v6 — smaller adjustable title Pokemon

- Adds `TITLE PKMN SIZE` to Kanto in Motion's main menu, 50%-125% in 5% steps.
- New default is 75% for the HD Pokemon title art.
- Keeps the title Pokemon centered and bottom-anchored in the existing 56x56 title slot while scaling, so it does not float upward or collide with Red.
- Red, the custom Gen1Recomp++ logo, battle sprite sizing, battle shadows, and HD battle backgrounds are unchanged.

# Gen1 HD v5 — player 100% baseline recalibration

- `PLAYER PKMN SIZE = 100%` now equals the previous accepted `115%` visual size.
- Keeps the physically 60%-sized HD sprite sheets unchanged.
- Applies the new 1.15x baseline consistently to fullscreen, staged/external, and fallback player battle-sprite paths.
- Enemy sizing is unchanged.
- The upgraded adjustable Pokemon shadow system is unchanged and continues to follow the final player sprite size automatically.

# Gen 1 HD test-scale restoration

- Restores the exact species-relative HD sizing path from the last accepted sample test build while keeping the installed sprite sheets physically reduced to 60%.
- PLAYER PKMN SIZE remains 50%–200% in 5% steps with 100% as the accepted baseline.
- Restores Shadow Test v2 PKMN SHADOWS quality and 50%–150% (10% steps) opacity controls.
- HD battle-background scaling no longer shrinks Pokemon; arena anchors and battler pixel scale are independent again.

# Gen 1 HD integration follow-up

- Restored the accepted HD sprite-test player calibration: physically 60%-converted sprite sheets remain unchanged, while `PLAYER PKMN SIZE = 100%` now matches the previously approved 115% test appearance.
- Restored `PLAYER PKMN SIZE` default to 100% and kept its 50%–200% / 5% ladder live in the battle menu.
- Made the compact KIM battle menu tolerant of older numeric saved size values so the size row remains readable/adjustable after upgrading.
- Kept the accepted Shadow Test v2 system: `SHADOWS` OFF/LOW/MEDIUM/HIGH/ULTRA, `SHADOW OPACITY` 50%–150%, size-aware contact shadows on both battlers, and Rattata's +25% footprint correction.


## Gen 1 HD rebuild follow-up

- Rebuilt all #001-151 HD battle sprite sheets at 60% of the supplied GIF frame dimensions to match the accepted test scale and reduce installed asset size.
- Restored the tested Pokémon contact-shadow controls: **PKMN SHADOWS = OFF/LOW/MEDIUM/HIGH/ULTRA** and **SHADOW OPACITY = 50%-150%**. MEDIUM/100% is the default; 100% matches the accepted Shadow Test v2 strength, and Rattata keeps the 25% larger shadow footprint from that test.
- Time-of-day environmental shadows remain baked into the authored full-background sunrise/day/sunset/night images; caves and fixed locations stay static.
# Changelog

## v1.3.7 — Gen 1 HD working rebuild

- Restricted the working build to Gen 1 / Red / Blue / Yellow.
- Disabled Gen 2 support for now.
- Removed legacy generation-based Battle Art sprite assets and legacy Gen6/Battle Art arena assets.
- Removed bundled move-animation artwork/SFX for now.
- Removed custom Trainer Card player/Gym Leader portraits while keeping animated badges.
- Added a new GIF-to-sprite-sheet HD Pokémon importer targeting Dex #001–151 by default.
- Converted 696 supplied Gen 1 GIF variants into validated sprite-sheet PNGs and generated timing metadata for all 151 species.
- Added 72 supplied 1920×950 HD battle backgrounds.
- Added **HD BATTLE BACKGROUNDS** ON/OFF to the KIM Battle menu.
- Added location-aware sunrise/day/sunset/night full-background switching using Gen1Recomp's live game clock.
- Kept caves/fixed locations static and cached the selected arena for the duration of each battle.
- Retained shiny encounter sparkle/audio, Modern UI, HUD controls, animated badges, Poké Ball fixes, and PotatoVoxel compatibility hooks.
