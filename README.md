# Kanto in Motion v1.4.1 — Gen 1 HD release

Kanto in Motion is an animated Pokémon presentation and battle overhaul for **Gen1Recomp Pokémon Red / Blue / Yellow**.

This release is **Gen 1 only**. Gen 2 support is intentionally not included in v1.4.1 while the HD battle pipeline remains Gen1-specific.

## v1.4.1 highlights

- Added confirmed **Gen1Recomp 0.3.1 compatibility** and widened KIM's declared engine range to **>= 0.2.24 and < 0.3.9**.
- Added a KIM-side **HGSS_SPRITES battle hard block**: when **BATTLE SYSTEM = ON**, HGSS battle hooks are bypassed so they cannot resize or replace KIM/Battle Art trainers and battlers.
- HGSS overworld, menu, icon, and player-overworld presentation remains available; turning **BATTLE SYSTEM = OFF** releases battle ownership back to HGSS.
- Preserves the existing confirmed **Battle Art** and **PotatoVoxel** desktop/mobile compatibility paths.

## What is included

- HD animated Pokémon for **National Dex #001–151**, physically reduced to **60% of the supplied GIF dimensions** for the accepted in-game scale and a smaller asset footprint.
- Front and back animation support, normal and shiny, including supplied gender variants.
- New **1920×950 HD battle backgrounds**.
- **HD BATTLE BACKGROUNDS** ON/OFF option in the Kanto in Motion Battle menu.
- Location-aware sunrise / day / sunset / night full-background switching using Gen1Recomp's live game time.
- Static cave/fixed-location routing where time-of-day scene changes do not make sense.
- Integrated Modern UI and KIM battle HUD controls.
- Shiny encounter sparkle and `shiny.wav` cue.
- Animated Trainer Card badges.
- Poké Ball presentation/target fixes.
- Desktop/mobile PotatoVoxel compatibility hooks.

## Not included in v1.4.1

- Gen 2 game support.
- Pokémon #152–251 battle support.
- Legacy Battle Art generation sprite packs and their generation-selection battle code.
- Legacy Gen 6 / Battle Art battle backgrounds.
- Custom Trainer Card player and Gym Leader portraits. Animated badges remain.


## HD Pokémon importer

The source GIF pack is converted to sprite-sheet PNGs plus Lua animation metadata with:

```text
python tools/import_hd_pokemon.py "Pokemon HD 1-151.zip" --target <Kanto-in-Motion-folder>
```

The importer defaults to **Dex 001–151** and **60% frame scale**. Use `--scale` only for development/testing; the packaged Gen 1 assets are authored at 60%. It creates:

```text
assets/battle/hd-pokemon/front/normal/
assets/battle/hd-pokemon/front/shiny/
assets/battle/hd-pokemon/back/normal/
assets/battle/hd-pokemon/back/shiny/
data/hd_pokemon_sprites.lua
```

Existing valid sprite sheets are reused automatically; use `--force` to rebuild them. `--max-dex` exists for future development, but this release is intentionally Gen 1 only.

## Time-of-day battle backgrounds

The first implementation uses **complete image swaps**, not blending. Authored scenes can provide:

```text
<scene>_sunrise.png
<scene>_day.png
<scene>_sunset.png
<scene>_night.png
```

KIM reads Gen1Recomp's live game/time-of-day state, so when the game's clock is synced to the PC/mobile device, the selected battle background follows that same time source.

Caves and fixed locations use static authored backgrounds. This avoids applying a moving outdoor-shadow system to places where sunlight direction should not change.

The background is selected when the battle begins and cached for that battle, so the arena does not switch variants halfway through a fight.

## Battle menu highlights

- **BATTLE SYSTEM** — KIM battle presentation master switch.
- **MODERN BATTLE UI** — KIM command/move/message presentation.
- **BATTLE SPRITES** — new HD animated Pokémon ON/OFF.
- **MOVE ANIMATIONS** — integrated Kanto Rework / Pokémon Essentials-style effects for all 165 Gen 1 moves; ON by default.
- **PKMN SHADOWS** — OFF / LOW / MEDIUM / HIGH / ULTRA contact-shadow quality. LOW uses one ellipse; MEDIUM/HIGH/ULTRA add progressively smoother feather layers.
- **SHADOW OPACITY** — 50%–150% in 10% steps; 100% is the calibrated default reference.
- **HD BATTLE BACKGROUNDS** — new 1920×950 arena system ON/OFF.
- **SHINY ODDS** — native or configurable KIM shiny odds.
- **PLAYER PKMN SIZE** — 50%–200% in 5% steps. Default **100%**. 100% is KIM's calibrated neutral HD player size.
- **3D PKMN SIZE** — 50%–125% in 5% steps. Default **100%**. 100% is the calibrated neutral reference for Battle Art and desktop PotatoVoxel; `PLAYER PKMN SIZE` still fine-tunes only the player.
- **POTATO CAMERA** — desktop/mobile PotatoVoxel camera pullback control.
- **POTATO MOBILE ENEMY SIZE** — Android/iOS PotatoVoxel enemy-size fine tuning; default **85%**.
- **HUD SCALE / SIZE / OPACITY** — KIM HP/status HUD controls.
- **BATTLE UI SIZE / OPACITY / TEXT SIZE** — Modern Battle UI controls.
- **MOVE LAYOUT / MOVE INFO** — battle move-menu presentation.

## Repository layout

- `main.lua` — KIM options, animated Pokémon provider, battle presentation, title/menu integration, and compatibility hooks.
- `data/hd_pokemon_sprites.lua` — generated metadata for the HD Gen 1 sprite sheets.
- `data/hd_battle_backgrounds.lua` — location/time background router and authored battler anchors.
- `assets/battle/hd-pokemon/` — generated HD Pokémon sprite sheets.
- `assets/battle/backgrounds/hd/` — 1920×950 HD battle backgrounds.
- `tools/import_hd_pokemon.py` — GIF → sprite-sheet importer.
- `lib/integrated_krba.lua` / `lib/krba_essentials_player*.lua` — integrated Gen 1 move-animation bridge.
- `data/gen1_anims.lua` — 165-move animation data used by the integrated player.
- `assets/animations/` / `assets/sfx/` — scanner-remediated move artwork and SFX.
- `lib/modern_ui_integrated*.lua` — integrated Gen1 Modern UI presentation.
- `lib/shiny_encounter_fx*.lua` — shiny sparkle/audio presentation.
- `assets/trainer_card/badges/` — retained animated Trainer Card badges.

The internal mod ID remains `animated_menu_pokemon` so compatible Kanto in Motion settings can carry forward.

## HD player size baseline

`PLAYER PKMN SIZE = 100%` is KIM's calibrated neutral HD player size. The 50%–200% setting scales relative to that baseline. The HD sprite-sheet files remain physically reduced to 60% for package-size savings.

## HD title-screen Pokemon size

The Red/Blue title screen now has **TITLE PKMN SIZE** from **50% to 125%** in 5% steps. The default is **75%** for the new HD Pokemon art. Scaling keeps the Pokemon centered in its existing title slot and bottom-anchored beside Red; the trainer and custom logo are not resized.

### Battle Art 1.11 compatibility

Battle Art 1.11.x is supported as an optional external 3D-BTL scene owner. KIM does not ship Battle Art generation sprite/background assets. On desktop, Battle Art owns the staged 3D world while KIM supplies the Gen 1 HD animated Pokemon and integrates its HUD/QOL geometry and Modern lower battle UI. On mobile, KIM uses the confirmed stage-only handoff: Battle Art owns the world/camera/effects while KIM owns the final HUD and Modern lower panel. Battle Art's categorized settings remain available through KIM's centralized MOD MENU.

## Development history (pre-release v8–v39)

The sections below preserve the iterative v8–v39 development history. Values described inside an older entry reflect that build at the time; the current v1.4.1 settings documented above are authoritative.

## Gen1 HD v8 — Battle Art 3D size + borderless title normalization

- Added **3D PKMN SIZE** (50%–125%, default **75%**) for Battle Art 3D-BTL scenes only.
- `PLAYER PKMN SIZE` still adjusts only the player; in 3D it now multiplies the neutral Battle Art card baseline instead of inheriting KIM's extra 2D 1.15x calibration.
- The 3D size control does not change KIM's accepted 3D-BTL OFF / HD-background sizing.
- Title-screen Pokemon keep the same maximum physical size as the previously accepted 800px-high window when a larger borderless desktop viewport is used. **TITLE PKMN SIZE** still works normally and remains 75% by default.
- Battle Art 1.11 continues to own the 3D camera, lighting, terrain and 3D shadow map; KIM only supplies/normalizes the HD Pokemon cards.

## Gen1 HD v9 — Battle Art HD-card shadow fix

When Battle Art 1.11 owns **3D-BTL**, KIM's HD Pokemon cards now **cast but do not receive** Battle Art's scene shadow map. This removes the diagonal/diamond self-shadow pattern that could appear across high-resolution Pokemon art while preserving the real alpha-shaped shadow on the 3D terrain.

This does not disable Battle Art lighting: world/day-night tint, diffuse lighting, depth and camera placement remain active. Battle Art's terrain/building/vegetation shadows are unchanged. KIM's adjustable 2D Pokemon contact-shadow system remains unchanged for **3D-BTL OFF**.

## Gen1 HD v10 — PotatoVoxel 1.9.6 sizing / trainer handoff

- Restores PotatoVoxel's accepted HD-card scale floor so KIM's per-species `displayScale` values below 0.5 are honored instead of being forced up to 0.5.
- `PLAYER PKMN SIZE = 100%` again means PotatoVoxel's neutral 1.00x player-card baseline; KIM's newer standalone-2D 1.15x rebaseline is removed only from the PotatoVoxel path.
- While **BATTLE SPRITES = ON**, the temporary vanilla Gen-1 player-trainer billboard is hidden during PotatoVoxel's 3D intro because the old Battle Art-derived trainer asset collection is no longer bundled. Intro/send-out timing and Pokeball mechanics remain native. Turning **BATTLE SPRITES = OFF** restores PotatoVoxel's fully native trainer path.
- No PotatoVoxel files are modified.

## Gen1 HD v11 — PotatoVoxel HD card + trainer fix

- PotatoVoxel 1.9.6 now receives KIM HD Pokemon through a high-resolution 3D card texture (6x logical resolution on desktop, 4x on mobile) instead of first rasterizing the Pokemon into a 160x144 nearest-filtered card. World size and anchors are unchanged; only texture detail is increased.
- KIM's own animated Red title-trainer atlas is reused for the PotatoVoxel send-out intro. The removed Battle Art trainer collection remains removed.
- KIM reasserts its PotatoVoxel texture provider at battle start so a later Potato/feature registration cannot silently restore vanilla trainer/Pokemon cards.

## Gen1 HD v12 — PotatoVoxel camera + trainer

- Added **POTATO CAMERA** to KIM's Battle settings: **100%–150%** in 5% steps, default **115%**. Higher values show more of the PotatoVoxel arena. This is a runtime wrapper around PotatoVoxel's public battle-camera module; no PotatoVoxel file or saved setting is changed.
- PotatoVoxel's own orbit/pitch/zoom controls still work on top of the KIM pullback.
- Fixed the player intro trainer path again: KIM now supplies its bundled animated Red title atlas directly from the PotatoVoxel texture-provider seam, without waiting for the live-stage predicate that could be late on the first trainer frame.
- The removed Battle Art trainer asset collection remains removed.

## Gen1 HD v13 — PotatoVoxel trainer early-hook restore

The previous working PotatoVoxel trainer fix depended on KIM replacing the player trainer at Gen1Recomp's **`player.sprite` hook**, before `BattleState.playerBackPic` was created. v11/v12 tried to replace the trainer later at PotatoVoxel's 3D texture-provider stage, which can be too late for the intro frame.

v13 restores that early ownership seam. The replacement is a **KIM-owned 40×56 Red frame derived from the already bundled animated title-screen Red atlas**; no removed Battle Art trainer collection is restored. PotatoVoxel still owns the battle scene/camera and captures the trainer through its own native path. The v12 camera pullback is unchanged.

## Gen1 HD v14 — restored KIM player-trainer system

- Restored the supplied **13 animated player-trainer atlases** as KIM-owned battle assets.
- **PLAYER TRAINER** is back in the Battle menu, with **RED (`redplayer.png`) as the default**.
- Choices: Red, Default/ROM, Gen 1-5, Ash, Gary, and the supplied Ash/Misty/Brock/Bulma/Gary front variants.
- The global **ANIMATION** toggle controls the selected trainer: ON follows the five-frame intro progression; OFF holds frame 1.
- PotatoVoxel now consumes KIM's selected trainer resolver directly. There are no PotatoVoxel-specific trainer assets/settings.
- The temporary `kim_red_trainer.png` workaround from v13 was removed.

## Gen1 HD v15 — PotatoVoxel trainer sizing/crop fix

PotatoVoxel now captures the selected KIM **PLAYER TRAINER** through PotatoVoxel's own native `sideTexture` trainer path. KIM still selects the trainer early through `player.sprite`, but it no longer bypasses PotatoVoxel with a finished 160x144 trainer card.

This restores PotatoVoxel's trainer-specific 1x capture, intro slide, anchor and billboard sizing, fixing the oversized/cropped trainer shown in v14. The trainer identity still comes entirely from KIM, with **RED / `redplayer.png` as the default**. No duplicate PotatoVoxel trainer assets or settings were added.

## Gen1 HD v16 — PotatoVoxel trainer scale fix

PotatoVoxel 1.9.6 continued to display KIM's selected 80×80 trainer too large even through its native trainer capture. KIM now builds only the PotatoVoxel intro trainer billboard from the **currently selected KIM PLAYER TRAINER** and exposes **POTATO TRAINER SIZE** from **50%–100%** in 5% steps.

The default is **65%**. This setting affects only the trainer during a PotatoVoxel 3D battle; normal KIM trainer presentation is unchanged. `DEFAULT / ROM` still falls back to PotatoVoxel/Gen1Recomp's native trainer. No duplicate trainer assets are added.

## Gen1 HD v17 — PotatoVoxel trainer regression fix

The reason v15/v16 produced no visible change was found by comparing this rebuild against the previous confirmed-working PotatoVoxel implementation.

KIM's v14 trainer restore added a late animated-frame swap inside `BattleState:drawPicsLayer`. PotatoVoxel's own `sideTexture` calls that function while capturing the intro trainer. The late swap replaced KIM's correctly registered path-based trainer with a raw 80×80 `Image`, bypassing Gen1Recomp's **1× battle trainer scale**. That is why every later Potato-only scale attempt was operating on the wrong layer.

v17 restores the old desktop contract:

1. KIM's `player.sprite` hook selects the current **PLAYER TRAINER** (`RED / redplayer.png` by default).
2. The registered first-frame path stays in `battle.playerBackPic`.
3. PotatoVoxel captures that path itself through its native `sideTexture`.
4. KIM does not replace it with the raw 80×80 animation frame during Potato's capture.

Normal KIM battles still use the animated selected trainer. The accepted **POTATO CAMERA = 115%** behavior is unchanged.

## Gen1 HD v22 — restore the original PotatoVoxel pinned trainer animation seam

The user's original pre-cleanup KIM v1.3.7 confirmed the missing architecture: animated PLAYER TRAINER frames are selected from the native `drawPicsLayer` path via `battleTrainerFrameForBattle()`. PotatoVoxel's **BACK SPRITES** mode intentionally skips the player texture provider, which is why the v18-v21 provider-side animation attempts could never change the visible trainer.

v22 starts from the confirmed-correct-size v17 implementation and restores that original live trainer-frame substitution specifically for PotatoVoxel's pinned player slot. A new trainer-only scale guard forces the raw 80x80 animation frame to **1x**, matching the registered static trainer path that made v17 the correct size.

Result: the same KIM trainer selection and original `picOffset("back")` five-frame progression can animate again without restoring the oversized 2x trainer.

## Gen1 HD v23 — first Android/iOS pass after v22 desktop baseline

- **PotatoVoxel mobile pinned player X:** shifts only KIM's final-resolution pinned player back sprite 16 logical pixels to the right while KIM owns the battle presentation. Desktop, enemy placement, camera geometry, and PotatoVoxel files are untouched.
- **Mobile PLAYER TRAINER size:** KIM's restored 80×80 trainer frames use a mobile-only **65% logical scale** while desktop keeps the confirmed-good v22 1× size. This applies to both PotatoVoxel and Battle Art trainer intro paths and preserves the selected trainer animation.
- **Battle Art 1.11 mobile stack guard:** restores the proven pre-cleanup KIM top-level graphics-state repair at `render.hud` entry/exit so leaked Battle Art pushes cannot accumulate into `TouchControls.lua:927: Maximum stack depth reached`.
- Corrects v22's mobile trainer branch ordering so `mobilePinnedTrainer` is resolved before the animated Potato trainer ownership test.

## Gen1 HD v24 — mobile size/position split

This pass separates the mobile presentation paths that v23 incorrectly treated as one scale:

- **Battle Art 3D-BTL Pokémon:** Android/iOS HD world cards receive a 0.50 mobile projection compensation. Desktop keeps the confirmed 3D sizing and the existing `3D PKMN SIZE` / `PLAYER PKMN SIZE` controls.
- **Normal KIM / 3D-BTL OFF trainer:** the live raw trainer frame is now explicitly identified during `drawPicsLayer`, so the intended 0.65 mobile scale actually applies.
- **PotatoVoxel trainer:** increased from v23's 0.65 to **0.85** on mobile only. Desktop remains 1.0.
- **PotatoVoxel pinned player position:** increased from +16 to **+32 logical pixels right** on the mobile KIM path.
- The v23 Battle Art `render.hud` graphics-stack guard is retained unchanged.

## Gen1 HD v25 — mobile anchor + scale correction

- **Battle Art mobile Pokémon size:** v24's 0.50 compensation was not taking effect because the 1.11 bridge cached `love.system` mobile detection at module load. The bridge now uses KIM's proven `_kantoInMotionNativeMobileHost()` detector dynamically, so the 0.50 Android/iOS world-card compensation actually reaches `presentationScale`.
- **Battle Art mobile player position:** shifts only KIM's player world card to the right by 20 card pixels through Battle Art's `tex.ax` anchor metadata. Enemy/camera/terrain and desktop remain unchanged.
- **PotatoVoxel mobile player position:** increases the pinned KIM player shift from +32 to **+56 logical pixels right**.
- **Normal KIM / 3D-BTL OFF trainer:** changes mobile size from v24's too-small 0.65 to **0.80**. Potato's separate pinned-trainer value remains 0.85.
- Keeps the v23 Battle Art graphics-stack guard and v22 trainer animation architecture unchanged.

## Gen1 HD v26 — mobile render-path correction

- **Battle Art mobile player Pokémon size:** stops relying on `presentationScale` for the Android back card. KIM now prepares only the player/back HD frame at **60% physical dimensions before Battle Art measures it**, so the 3D card is unavoidably smaller. Enemy/front art and desktop are unchanged.
- **PotatoVoxel mobile player Pokémon size:** applies the same **0.60 mobile multiplier at KIM's actual sprite exports** for both the staged 3D card and final-resolution pinned-back renderer. This replaces ineffective late geometry compensation.
- **Mobile trainer size:** raises normal KIM, Battle Art, and Potato pinned trainer paths to **95%** after 80-85% tested too small. Desktop remains 100%.
- **Battle Art Modern UI:** restores the pre-cleanup mobile **stage-only** ownership model for Battle Art 1.11. Battle Art keeps world/camera/effects; KIM owns the final mobile HUD and Modern lower dialog/command panel. Battle Art's snapped HUD and its own frosted panel are suppressed only while this mobile KIM path is active.
- The v23 graphics-stack guard remains installed.

## Gen1 HD v27 — Battle Art mobile enemy + HP HUD only

This pass intentionally touches **Battle Art only**.

- **Enemy Pokémon size:** v26 proved that physically preparing the KIM texture is the seam Battle Art 1.11 actually honors on Android. v27 applies the same 60% physical preparation to the enemy/front card and removes the desktop-only 1.25 enemy enlargement on mobile. The enemy therefore renders at roughly 48% of its v26 apparent size. Desktop remains unchanged.
- **HP/status HUD:** restores Battle Art's own HP/status/EXP ownership. The v26 stage-only bridge had disabled `snapHUDs` and claimed the HUD suppression surface, which removed the HP blocks while Modern UI still drew the lower command panel.
- **Modern UI lower panel:** unchanged and remains KIM-owned.
- PotatoVoxel, trainer sizing, Battle Art player/back sizing, camera, and desktop behavior are unchanged from v26.

## Gen1 HD v28 — Battle Art mobile size + KIM HUD color ownership

This build remains **Battle Art only**.

- **Pokémon size:** v27's 60% physical preparation made both sides too small. Mobile Battle Art KIM front/back cards now prepare at **80% physical size**. Desktop remains unchanged.
- **HUD ownership:** restored the architecture from the user's original KIM 1.3.7. Battle Art owns the 3D stage/camera/effects, but **KIM owns the visible HP/status/EXP HUD**.
- **HUD COLOR = INVERTED:** the final HUD is again drawn through KIM's own HUD shader, so the user's KIM `HUD COLOR` setting is authoritative. Battle Art's HUD color setting is not used for the visible HUD.
- **Battle Art source HUD:** `snapHUDs` is suppressed only while the mobile KIM stage-only path is active, preventing duplicate source HUD furniture.
- **Modern UI:** still owns the lower command/move/message panel.
- PotatoVoxel and trainer sizing are unchanged.

## Gen1 HD v29 — Battle Art mobile enemy-size calibration

This is a **Battle Art-only** calibration on top of v28.

- Player/back Pokémon remains **80% physical preparation** on Android/iOS — this size was confirmed good.
- Enemy/front Pokémon increases from **80% to 95% physical preparation** on Android/iOS.
- The restored KIM HP/status/EXP HUD ownership from v28 is unchanged, including **HUD COLOR = INVERTED**, HUD size, and HUD opacity.
- Modern UI lower-panel ownership is unchanged.
- PotatoVoxel, trainer sizing, camera, and desktop behavior are untouched.

## Gen1 HD v30 — restore original KIM 1.3.7 mobile QOL anchors

This Battle Art-only patch restores the **actual anchor/reconstruction system from the user's original working KIM 1.3.7**: `lib/mobile_qol_exp_reconstruction.lua`.

The module does not guess final coordinates. It recognizes Quality of Life's source EXP/caught-icon rectangle primitives after `BattleState:draw()`, resolves KIM's live `battleHudGeometry`, and remaps them to the current HUD bands:

- EXP main fill → `playerBandY + 41 * hudScale`
- EXP burst pixels → the same player EXP origin
- already-caught icon → fixed enemy-band-local anchor (`+8` HUD pixels for RED/GREY, `+9` for GEN2)
- portrait and landscape use the same live KIM HUD geometry
- HUD SIZE / HUD SCALE changes remain attached automatically
- short Pokémon names do not shift the final caught icon because the destination anchor is band-relative

Quality of Life and Battle Art remain unmodified. Battle Art Pokémon sizing and the v28/v29 KIM HUD ownership are unchanged.

## Gen1 HD v31 — global enemy HUD left inset

The enemy HP/status HUD was too close to the left edge in **all KIM HUD paths**, not just Battle Art:

- normal KIM / 3D-BTL OFF
- Battle Art
- PotatoVoxel

The shared `battleHudGeometry()` anchor previously placed the first visible enemy-HUD pixel at logical **X=2**. v31 moves that shared visible anchor to logical **X=6**, shifting the complete enemy HUD right by **4 HUD pixels**.

Because the change is made at KIM's common HUD geometry contract, the enemy party-ball layer and restored Quality of Life already-caught icon anchor follow the HUD automatically. The player HUD, Pokémon positions, Modern UI, EXP bar, HUD size/opacity/color, and desktop/mobile scaling are otherwise unchanged.

## Gen1 HD v32 — PotatoVoxel mobile Pokémon size

Battle Art remains unchanged from the confirmed-good v29/v30/v31 baseline.

Adds **POTATO MOBILE PKMN SIZE** for Android/iOS PotatoVoxel:

- range: **50%–125%**
- step: **5%**
- default: **85%**
- scales **both player and enemy Pokémon together**
- applies after KIM's species `displayScale` and player `PLAYER PKMN SIZE`
- applies to both Potato's staged 3D cards and pinned/back-sprite path
- desktop PotatoVoxel remains unchanged

At the default 85%, the current mobile player path becomes 15% smaller than v31, and the enemy receives the same shared 85% final multiplier instead of staying at its previous full mobile size.

## Gen1 HD v33 — PotatoVoxel mobile player/enemy size split

v32's enemy size is preserved, but its player size was too small because the new 85% shared multiplier stacked on top of the existing 0.60 mobile player compensation.

v33 splits the setting:

- **POTATO MOBILE PLAYER SIZE** — 50%-125%, default **95%**
- **POTATO MOBILE ENEMY SIZE** — 50%-125%, default **85%**

The enemy therefore stays exactly at the current v32 default. The player rises from an effective `0.60 × 0.85 = 0.51` to `0.60 × 0.95 = 0.57`, placing it between v31's too-large 0.60 and v32's too-small 0.51.

Battle Art, KIM HUD/QOL anchors, trainer sizing, camera, and desktop behavior are unchanged.

## Gen1 HD v34 — direct PotatoVoxel mobile player scale

v33's player-size option produced no visible change because the value was not reliably reaching PotatoVoxel's final pinned player render.

v34 removes the extra player option from that path and applies the player correction directly at KIM's two authoritative Potato sprite exports:

- pinned/final-resolution player → **0.66 mobile factor**
- staged 3D player card → **0.66 mobile factor**
- enemy remains at the confirmed-good **85%** v32/v33 value

This makes the player about **29% larger than the v32/v33 result** and about **10% larger than the old v31 0.60 mobile baseline**, targeting the Battle Art mobile silhouette that was already approved.

Battle Art, KIM HUD/QOL anchors, enemy HUD inset, trainer sizing, Modern UI, Potato camera and desktop behavior are unchanged.

## Gen1 HD v35 — Battle Art 100% is now the calibrated neutral size

`3D PKMN SIZE` is now a user adjustment instead of part of KIM's author calibration.

The Battle Art size the project was tuned around was the old **75%** setting. v35 bakes that `0.75` factor into KIM's Battle Art bridge and changes the option default/neutral point to **100%**.

So:

- **100%** = KIM's preferred calibrated Battle Art size
- **75%** = 25% smaller than KIM's preferred size
- **125%** = 25% larger than KIM's preferred size

This means setting `3D PKMN SIZE = 100%` now gives the same visual baseline that previously required 75%, while users remain free to scale both Battle Art Pokémon around that baseline.

`PLAYER PKMN SIZE` remains a separate player-only adjustment after the Battle Art baseline. At v35, PotatoVoxel did not yet consume `3D PKMN SIZE`; v39 later extends the same 100%-neutral control to desktop PotatoVoxel while mobile keeps its separately calibrated sizing.

## Gen1 HD v36 — move animations restored

KIM's original **1.3.7 Kanto Rework / Pokémon Essentials move-animation system** is restored.

- Restores **MOVE ANIMATIONS** (ON/OFF, default ON).
- Restores the original `integrated_krba.lua`, desktop/mobile Essentials players, and the complete 165-move `data/gen1_anims.lua`.
- Restores the remediated animation/SFX archive under KIM's original `assets/animations/` and `assets/sfx/` paths.
- Battle Art 1.11 and PotatoVoxel are opted back into KIM's independent move-animation lane.
- PotatoVoxel uses the original 1.3.7 live-AnimPlayer binding/final projection architecture while preserving the current HD-card, trainer, camera, mobile and HUD fixes.
- Battle Art continues using the confirmed-good v35 sizing/HUD baseline; `3D PKMN SIZE = 100%` remains neutral.
- No legacy Battle Art generation sprite packs or removed Gen 6 arena assets are restored.

## Gen1 HD v37 — PC Battle Art player calibration + original desktop QOL anchors

This restores the two desktop-only compatibility modules from the user's
known-good KIM 1.3.7:

- `lib/battle_art_desktop_hud_geometry.lua`
- `lib/battle_art_desktop_qol_overlay_alignment.lua`

The desktop QOL bridge recognizes Quality of Life's original EXP/caught
rectangle primitives on Battle Art's `dramaticShapeShot`, then remaps them to
Battle Art's live snapped KIM HUD bands:

- EXP → player HUD row `+41 * hudScale`
- level-up EXP burst → follows the same player-HUD anchor
- caught icon → fixed enemy-band-local `+8/+9` anchor
- short Pokémon names no longer move the final caught icon
- HUD SCALE / HUD SIZE follow Battle Art's live `snapRects`
- v31's enemy visible-left inset (`X=6`) is preserved

PC Battle Art player sizing is also recalibrated independently from the
user-facing `3D PKMN SIZE` option. `3D PKMN SIZE = 100%` remains neutral;
KIM applies a desktop-only `0.80` authored baseline to the near/player card
before `PLAYER PKMN SIZE`.

Mobile Battle Art, PotatoVoxel, restored move animations, Modern UI and the
mobile QOL reconstruction are unchanged.

## Gen1 HD v38 — restore 1.3.7 attack anchors, full-screen BG/FG, caught icon and Battle Art party balls

This restores the presentation seams that existed in KIM 1.3.7 but were lost
while the new HD battle/background stack was being rebuilt.

### Move animation / BG/FG
- Restores `_kantoInMotionKrsWideActive`.
- Restores the live KRBA session into KIM's final-resolution HD battle canvas.
- `drawWideBack()` now runs behind the HD Pokémon and `drawWideFront()` runs in
  front, using the current 1920×950 arena transform.
- Restores species-aware USER/TARGET anchors from KIM's actual HD battler
  centers.
- Restores KRBA battler picture transforms on the final-resolution KIM sprites.
- Restores Battle Art's final-window screen-plane fallback:
  `drawBattleArtScreenBack/Front` (plus the mobile variants).

This fixes effects such as Thundershock whose background/foreground timing
planes must be full-screen and screen-fixed rather than projected into the 3D
world or drawn into the old 160×96 battle surface.

### Desktop QOL anchors
While KIM BATTLE SYSTEM is ON, desktop Battle Art QOL EXP/caught pixels now
target KIM's actual `battleHudGeometry`, matching the already-confirmed mobile
ownership model. With KIM BATTLE SYSTEM OFF, the module still falls back to
Battle Art's native `snapRects`.

### Party Poké Balls
Restores the exact KIM 1.3.7 Battle Art Colorfix path, including the
`ICONS_DRAMATIC` ink-safe palette and `dramaticShapeShot` party-row branch.
This restores colored party balls during the Battle Art 3D-BTL battle intro.

v35/v37 Battle Art sizing, the v31 enemy HUD inset, HD backgrounds, shadows,
Modern UI, mobile fixes, PotatoVoxel compatibility and v36 scanner-remediated
move assets are preserved.

## Gen1 HD v39 — Potato PC neutral sizing + 3D-BTL-OFF caught icon

Desktop PotatoVoxel now uses the same neutral-sizing idea as the approved Battle Art PC path. The near/player Pokemon receives an internal **0.80** authored baseline, while **3D PKMN SIZE = 100%** remains the user neutral point. The 3D-size control now also adjusts desktop PotatoVoxel staged Pokemon; at 100% the enemy keeps its previous size. PotatoVoxel mobile keeps its separately tuned player/enemy calibration unchanged.

For **3D-BTL OFF**, KIM no longer nudges Quality of Life's caught icon by a fixed X offset. It decodes the icon relative to QOL's name-dependent source position and redraws it at the same fixed enemy-HUD **+8/+9** anchor used by the working 3D paths. This shared flat-battle fix covers Battle Art and PotatoVoxel fallback battles.
