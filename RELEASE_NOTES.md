# Kanto in Motion v1.3.0

v1.3.0 is the public release built from the internal v8.6.x battle/presentation development line. It is a major feature update over v1.2.0 while retaining the Gen 2 support introduced in that release.

## Major additions

- Standalone Gen 1 **BATTLE SYSTEM** with Battle Art-style fullscreen 2D composition and no voxel-renderer requirement.
- **KRS** location/time battle backgrounds and authored battler stance positions, plus GEN6/WHITE/OFF arena choices.
- Integrated **Kanto Rework Battle Animations** for all 165 Gen 1 moves, with native animation fallback.
- Integrated **Pokéball Colorfix** presentation behavior and fullscreen/mobile catch-target corrections.
- Animated front/back battle sprite selection, player Pokémon scaling, Battle Art-style HUD scaling/color, and selectable player trainer art/animation.
- Persistent configurable **SHINY ODDS**, shiny DV retention through capture, and a synchronized one-cycle sparkle/audio cue for shiny player and enemy battlers.
- Growl and Roar use the attacking Pokémon's species cry while the integrated animation player owns the move.
- Live Modern UI ↔ vanilla ownership switching on desktop and mobile without restarting.
- Mobile portrait/landscape fixes for battle composition, Poké Ball visibility/targeting, text sizing, trainer placement, and Quality of Life EXP alignment.
- KIM-side Typed Move Colors effectiveness indicators inside the Modern move selector, without modifying Typed Move Colors.
- KIM-side Overworld Wild Spawns/Wilds shiny identity bridge, using Wilds' own shiny overworld assets and preserving the same DVs into battle/catch.
- Extensive battle setting controls documented in `README.md` under **KANTO IN MOTION → BATTLE**.

## Credits added for the public release

- Battle Art / DramaticShapeVoxelMod — **absol89** — https://github.com/absol89/DramaticShapeVoxelMod
- Kanto Rework Battle Anims and KRS battle backgrounds — **Faendra** — https://github.com/Faendra/kanto-rework-suite
- Pokéball Colorfix — **keberos** — https://github.com/keberos/pokeball-colorfix
- Gen1 Modern UI — **ArmstrongThomas** — https://github.com/ArmstrongThomas/gen1-modern-ui
- Animated Trainer Card badges — **xpixelpriorx** — https://www.deviantart.com/xpixelpriorx
- Gen 9 Move Animation Project upstream animation data — **KRLW890 and contributors** — https://www.eeveeexpo.com/resources/1480/

See `THIRD_PARTY_NOTICES.md` and `ASSET_NOTICES.md` for attribution and redistribution details.

## Release packages

- `Kanto-in-Motion-v1.3.0-Full-Assets.zip`
- `Kanto-in-Motion-v1.3.0-No-Pokemon-Assets.zip`

Install only one package variant. The internal mod ID remains `animated_menu_pokemon`, so compatible saved KIM settings can carry forward from v1.2.0.

---

# Internal development history

## v8.6.66

This is a small Kanto in Motion-side presentation refinement for the Typed Move Colors compatibility added in v8.6.65. The effectiveness glyphs in KIM's integrated Modern move tiles now use a shared inset from the lower-right corner. The double-up symbol is anchored using the width of both arrows, preventing its right arrow from crowding or crossing the tile edge. No Typed Move Colors files or effectiveness logic are modified.

The v8.6.65 overworld shiny runtime bridge is unchanged and remains preserved.

## v8.6.65

This build fixes two external-mod compatibility regressions entirely from **Kanto in Motion**. The uploaded Typed Move Colors and Wilds/Overworld Wild Spawns packages remain unchanged.

When KIM's integrated Modern UI owns the battle move menu, it still suppresses Typed Move Colors' detached selector to avoid two overlapping move grids. KIM now retains Typed's own live `effectIndicator` helper during that render pass and redraws the same effectiveness symbol on KIM's move tile. This deliberately does not duplicate Typed's type chart: its **MOVE EFFECT** option, current enemy types, merged chart, immunity rules, fixed-damage/Super Fang handling, OHKO behavior, and content-mod changes remain the source of truth.

The Wilds shiny compatibility has also been replaced with a direct runtime integration. v8.6.64 attempted to proxy `mod.find` on the public Wilds handle, but Gen1Recomp does not guarantee that public handle is the same private mod context used inside Wilds' `battle_art_shiny_bridge.lua`. v8.6.65 instead works through Wilds' documented exported logic/render/library objects. KIM assigns the persistent DVs to the spawn record before entity construction, enables Wilds' own shiny runtime variant, refreshes any already-live entities once, and queues those same DVs before contact/Safari battle creation. Wilds continues to render its own shiny overworld art and own all spawning/movement behavior; no Wilds files or assets are copied into KIM.

All v8.6.64 and earlier UI, mobile, Quality of Life XP, Poké Ball, Growl/Roar, and shiny encounter fixes are preserved.

## v8.6.64

Adds a **KIM-side Wilds of Kanto shiny bridge** without changing the uploaded Wilds package. Wilds 2.1.8+shiny.1 already contains shiny overworld sheets and a persistent-DV bridge intended for Battle Art. When Battle Art is absent, Kanto in Motion now supplies that small runtime contract so Wilds can assign the shiny identity before it creates the visible overworld entity.

The overworld mod remains the renderer: its selected GSC/follower/HGSS/water sprite path resolves the shiny variant from its own assets. KIM only supplies the DV/shiny identity using the existing **SHINY ODDS** setting. When that visible Pokémon starts a normal or Safari battle, KIM consumes the prepared identity and copies the exact DVs onto the battle Pokémon, preventing an overworld shiny from becoming normal (or vice versa). Wilds' existing direct-catch path already carries those same DVs into the caught Pokémon.

Real Battle Art remains authoritative if installed; KIM's proxy is only returned when Wilds asks for Battle Art's shiny bridge and no real Battle Art handle exists. All v8.6.63 and earlier fixes are preserved.

## v8.6.63

Fixes the **Quality of Life XP bar on Android/iOS portrait only** without modifying Quality of Life. KIM's portrait Battle Lite intentionally relocates the player HP/status band inside the contained battlefield, while QOL's Battle Art-compatible path still derives EXP Y from the shared `dramaticShapeShot.ly`. KIM now translates only QOL's EXP fill and level-up burst to the real player HUD band plus the native Gen 1 EXP-row offset. Landscape and desktop keep their existing coordinates, including the prior SCALED-HUD compatibility.

## v8.6.62

Fixes **BATTLE TEXT SIZE** on Android/iOS when Kanto in Motion's integrated Modern battle UI owns the lower panel. The mobile proxy state can omit the Battle Lite marker on the draw tick used to choose typography, so the presenter now also reads KIM's game-level fullscreen ownership flag. Text size changes remain typography-only: the tuned mobile command/message panel rectangle and TouchControls layout are unchanged.

## v8.6.61

This test restores the original Gen 1 special audio behavior for **Growl** (and Roar) while Kanto in Motion's integrated KRBA move animations are active. Gen1Recomp normally routes those two moves to the attacking Pokémon's species cry instead of an ordinary move SFX, but KRBA owns its own animation timing and was bypassing that engine sound callback.

The KRBA bridge now resolves the BattleState that owns the active animation, identifies whether the player or enemy is the attacker, and plays that battler's species cry on the move's sound timing. On engines that expose `Sound.playMoveCry`, the move-specific Growl/Roar tempo modifier is retained; a normal `Sound.playCry` fallback keeps the feature compatible with older supported engine builds. No Pokémon cry files are copied into KIM, so the active engine/cry-replacement registry remains the source of the sound.

All v8.6.60 mobile Poké Ball visibility/targeting and prior shiny/UI fixes are unchanged.

## v8.6.60

This test fixes the mobile-only Poké Ball disappearance seen after v8.6.59. On Android/iOS, Kanto in Motion can place the fullscreen enemy outside Gen1Recomp's original 160x144 battle rectangle. The v8.6.59 target correction was valid, but translating the native Poké Ball inside that fixed-size scratch canvas could move every ball frame beyond the canvas edge before it reached the screen.

Mobile catch frames now use a temporary transparent padded native canvas sized around the active retarget offset. KIM subtracts that padding again when the layer is composited, so ordinary native pixels stay in the same position while the Poké Ball toss, opening/poof, shakes, and resting-ball frames remain visible all the way to the real fullscreen enemy target. The desktop catch path is unchanged.

The player/enemy shiny sparkle and synced `shiny.wav` behavior from v8.6.59 is preserved.

## v8.6.59

This test fixes the two follow-up battle presentation issues found after v8.6.58. The shiny encounter presenter now follows both battler sides, so a shiny Pokémon on the player's side receives the same one-cycle sparkle and `shiny.wav` cue when it finishes being sent out. The effect remains one-shot for that appearance and does not replay merely because a move or a failed catch temporarily hides the battler.

Wild catch throws are also retargeted to Kanto in Motion's real fullscreen enemy sprite rather than the old native 160×144 enemy slot. The correction is blended into the toss from zero at the player's launch point to full correction at impact, then retained for the remaining catch-chain animation and caught resting ball. Trainer BLOCKBALL behavior and unrelated battle animations are not retargeted.

The supplied shiny assets remain `assets/effects/shiny_sparkle.png` and `assets/sfx/shiny.wav`; there are no `(1)` filenames.

## v8.6.58

### Shiny encounter effect

This build adds the supplied shiny encounter presentation to Kanto in Motion. When a shiny enemy Pokemon first appears, KIM now plays the provided sparkle animation directly over that battler for one full cycle and triggers the supplied audio cue at the same time.

The animation is read as a 6x6 atlas with 89x75 cells and uses the first 35 populated frames, ignoring the final blank cell. Its timing is locked to the supplied WAV duration (~0.7683 seconds), giving an effective playback rate of about 45.56 FPS so the sparkle cycle and audio begin and finish together. It is rendered in the same fullscreen battle world as KIM's animated battlers, so it follows the encountered shiny cleanly on both desktop and mobile.

No shiny odds, capture persistence, UI ownership, trainer layout, or ordinary move-animation logic changed in this build.

## v8.6.57

### Mobile live Modern UI / Vanilla UI switching

This build removes the remaining restart requirement when changing `INTEGRATED MODERN UI` on mobile. Kanto in Motion now installs the correct Gen1 platform presenter at startup even when the saved option is OFF, but the presenter remains completely dormant until the option is enabled.

As a result, Android/iOS can switch **Vanilla -> Modern UI** and **Modern UI -> Vanilla** during the same game session. The v8.6.56 fail-open ownership gates still ensure that OFF releases rendering, suppression, touch/pointer remapping, and presenter ownership back to the native UI. Desktop also gains the same cold-start OFF -> ON behavior.

No sprite, animation, battle background, audio, or gameplay assets were changed.

## v8.6.56

Fixes the OFF-side ownership handoff introduced by the platform-split Modern UI work. With **INTEGRATED MODERN UI = OFF**, desktop and landscape Battle Lite now leave Gen1Recomp's actual lower command/move/message strip intact, while portrait continues using its established safe-position native redraw. If Modern UI was already loaded, switching it OFF in-session now makes its presentation/suppression/input hooks fail open to vanilla immediately. KIM still owns the fullscreen battlefield and Battle Art-style HP/status HUD whenever **BATTLE SYSTEM = ON**.

## v8.6.29

**PLAYER TRAINER** now prefers the matching Battle Art-style animated trainer atlas when one exists. The existing global **ANIMATION** option is the only motion switch: ON plays the trainer intro animation; OFF freezes the selected trainer on its first frame. Static-only trainer choices fall back automatically without adding a second trainer-animation setting.

Animated sets included from the supplied Battle Art 1.9.8 package: GEN 1-5, Ash, Gary, Red, Ash Front, Misty Front, Brock Front, Bulma Front, and Gary Front. PNG, Boy, Lass, and Hilbert remain static-only.

## v8.6.28

Adds a real **PLAYER TRAINER** battle selector using the same static choices as the supplied Battle Art package: ROM/default, PNG, Gen 1-5, Ash, Gary, Boy, Lass, and Hilbert. The selector affects the actual player trainer shown during the Gen 1 battle intro/send-out while leaving Battle Art and other registered scene owners in control of their own trainer presentation.

Portrait touch battles now use a three-part vertical layout: contained battlefield first, then the player-side HP/status band, then the native command/dialogue area. The player trainer is isolated from the general native overlay and redrawn once, fixing the doubled trainer seen in v8.6.27. Landscape behavior is intentionally unchanged.

## v8.6.27

Makes mobile SCREEN POS authoritative for the fullscreen battle and title presentation. KRS/GEN6, battlers, trainer/send-out overlays and HUD follow the movable TouchSkin viewport; SCALED HUD size uses physical pixels; and KIM's title trainer/Pokemon/logo follow Gen1Recomp's actual title rectangle without exposing the stock wordmark underneath.

## 8.6.26
- Mobile touch battles now automatically yield the base battle command/message UI while on-screen controls are visible; Modern UI resumes when touch controls are hidden.
- KRS/GEN6 portrait touch layouts now contain the landscape arena to the TouchSkin game viewport width instead of cover-cropping a tall portrait area. Battler scale/anchors and KRBA anchors follow the contained stage.
- The fullscreen compositor preserves only the native bottom 48-row battle strip on touch layouts, while KIM still owns the arena and Battle Art-style HP/status HUD.

## v8.6.25

This test build fixes cross-generation sprite presentation rather than changing the **SAME AS MENU** setting behavior. Gen 2/3/4 atlases use very different fixed frame canvases from Gen 5; KIM now maps each animation's fixed visible union into that species' Gen 5 visual envelope. The selected generation therefore changes the sprite style/animation without also changing apparent scale, centering, or battle ground geometry. Gen 5 itself is left untouched.

It also adds **TITLE TRAINER = ANIMATED / ORIGINAL GEN 1** so the custom animated Red can be switched back to Gen1Recomp's original title trainer independently of the selected Pokémon sprite generation.

## v8.6.24
Fixes the mobile KRS/GEN6 battle layout on Gen1Recomp 0.2.38 Android/iOS high-DPI windows. KIM now renders its fullscreen worldOverride at the physical framebuffer/playfield size expected by Gen1Recomp instead of allocating a much smaller logical-unit canvas. TouchSkin-reserved playfields are honored, while Modern UI remains in window-space and keeps the established lower-panel layout.

## v8.6.23
Adds an open, opt-in compatibility API for other UI and battle mods. Cooperative battle mods can request native, lower-panel hybrid, or full Modern UI routing; cooperative UI mods can claim only the presenter families they replace. External battle scene owners make Battle Lite yield its scene/HUD and block KIM sprite/KRBA injection unless explicitly opted in. Also improves KRS enemy right-edge clearance at 4:3 without changing 3:2/16:10/16:9 placement, and keeps KRBA targeting on the shifted enemy.

## v8.6.22
- **BATTLE UI MODE** has been removed. Battle presentation is now selected automatically using the established KRS/GEN6/Battle Art compatibility paths. Existing saves that still contain the retired setting continue to load normally.

## v8.6.21
Battle Art/voxel hybrid battles now use Kanto in Motion's BATTLE TEXT SIZE setting for the Modern lower command/move/message text. Battle Art's HP/status/EXP HUD and lower-panel geometry are unchanged.

## v8.6.20
Battle Art integration now preserves Battle Art's HP/status/EXP HUD while Modern UI replaces only the lower battle command, move, and message surface, matching the KRS/GEN6 ownership split.

## v8.6.19 test changes
- Full shiny ground-plane audit for the bundled animated battle sets: 1,792 compatible normal/shiny front/back pairs checked, with 772 non-zero transparent-bottom differences corrected.
- Corrections are variant-relative, so naturally floating species keep the same authored height as their normal counterparts rather than being forced to the floor.
- GEN6 attack alignment from v8.6.18 remains based on each battler's actual final rendered center.

# Kanto in Motion v1.2.1 TEST — v8.6.17

- Fixes Gen 2 animated Pokédex lookup for Farfetch'd and Mr. Mime by translating the engine's legacy internal species IDs to Kanto in Motion's imported sprite-table keys.
- The fix is applied at the shared sprite resolver, so Summary/Evolution/other animated consumers benefit automatically if they receive the same legacy IDs.
- Battle presentation remains identical to v8.6.16.

# Kanto in Motion v1.2.1 TEST — Battle Lite Gen1 v8.6.16

- Moves KRS and GEN6 to one Battle Art-style fullscreen compositor.
- Removes the complete native 160x144 battle UI canvas before final fullscreen composition, then rebuilds only transparent native trainer/fallback pieces.
- Enables KRBA wide battle effects on GEN6 as well as KRS.
- Makes GEN6 use the exact same accepted 3 px side / 3 px bottom Modern lower-panel geometry as KRS.

# Kanto in Motion v8.6.15 TEST — KRS white-canvas leak fix

- Fixes the large white native battle-surface block seen during Ember and other KRBA attacks.
- The fix targets white canvas clears on the active 160x144 Gen1 source surface instead of suppressing KRBA effects.
- Existing UI and Ember targeting fixes remain unchanged.

# Kanto in Motion v8.6.12 — KRS Flash Fix

- Removes the duplicate full-window native white hit flash while KRBA is rendering a move.
- Preserves KRBA-authored flashes/planes and all v8.6.11 Ember targeting/UI fixes.

# Kanto in Motion v8.0 Battle Lite test

This test restores the accepted large bottom Modern battle panel while keeping Battle Art-style HP/status and Quality of Life EXP presentation independent. `BATTLE TEXT SIZE` is typography-only. A new `MOVE LAYOUT` option selects either a full-width 2x2 GRID with MOVE INFO on the right, or a VERTICAL four-move list.

# Kanto in Motion v1.2.1 TEST — Battle Lite Gen1 v7.8

- Modern UI now owns the lower battle command/move/message panel while Kanto in Motion Battle Lite is active.
- Battle Art-style HP/status bands remain untouched.
- Quality of Life EXP and caught/Pokedex overlays remain source-owned and use the existing Battle Art geometry compatibility.
- v7.7 battlefield placement, 125% battler baseline and 140 PX GEN6 crop default are unchanged.
- Modern UI battle ownership is state-scoped to Kanto in Motion's own Battle Lite state so other battle systems are not claimed automatically.

# Kanto in Motion v1.2.1 TEST — Battle Lite Gen1 v7.7

- New fullscreen battler baseline: player default 125%; enemy independent 125% baseline.
- New GEN6 background crop default: BG Y-OFFSET 140 PX.
- Keeps v7.6 battler positions and QOL SCALED XP alignment.
- Keeps native-resolution final sprite drawing and Pokeball Colorfix compatibility.

# Kanto in Motion v1.2.0

Kanto in Motion v1.2.0 is the first release that targets both Gen 1 and Gen 2 in Gen1Recomp.

## Gen 2 support

- Added `gen2` targeting for Gen1Recomp 0.2.24.
- Added Gold / Silver / Crystal generation-aware startup behavior.
- Kanto in Motion's bundled Modern UI is automatically suppressed on Gen 2 so it does not fight the separate Gen 2 UI implementation.
- Kanto in Motion's animated Pokémon provider remains active on Gen 2.
- Added compatibility with the **original, unmodified Gen2 Clean UI 0.4.1**.
- Added live animated portrait bridging for stock Gen2 Clean UI without requiring a patched Clean UI package.
- Animated Gen 2 Status/Summary presentation is confirmed working in real testing.
- Compatibility hooks are included for Party, Pokédex, and Evolution portrait surfaces; those remain subject to screen-by-screen in-game validation.

## Gen 1 Modern UI preference

- `INTEGRATED MODERN UI` is a **Gen 1-only** preference.
- It defaults ON for new installs.
- If the user turns it OFF in Gen 1, that preference is remembered on later Gen 1 launches.
- Launching Gen 2 does not overwrite the saved Gen 1 preference.
- Returning to Gen 1 restores the saved Gen 1 choice.

## Gen 1 Poké Mart fix

- Fixed Poké Mart BUY/SELL presentation falling back to the original Gen 1 UI.
- Gen1Recomp's custom `ShopMenu` draw override is now recognized as a supported Modern UI screen path.
- The fix is presentation-only and does not change shop logic, inventory, prices, or callbacks.

## Retained features

- Gen 2 / Gen 3 / Gen 4 / Gen 5 animated Pokémon front sprites.
- Gen 5 default sprite source.
- Animated Summary/Status, Pokédex, evolution, and supported menu portraits.
- Red/Blue all-151 title Pokémon rotation.
- Optional animated Red/title artwork.
- Customized integrated Gen1 Modern UI 0.9.12.
- Trainer Card presentation with animated earned badges.
- Useful Bag compatibility on the Gen 1 integrated-UI path.
- Safe fallback when optional/imported artwork is missing.

## Release archives

- **Kanto-in-Motion-v1.2.0-Full-Assets.zip** — includes the animated Pokémon/title payloads present in this release build.
- **Kanto-in-Motion-v1.2.0-No-Pokemon-Assets.zip** — excludes imported Pokémon/title payloads and keeps the local `tools/import_assets.py` workflow.

Install only one package.

## Credits

Animated Trainer Card badge artwork: **xpixelpriorx**  
https://www.deviantart.com/xpixelpriorx

Gen1 Modern UI foundation: **ArmstrongThomas**  
https://github.com/ArmstrongThomas/gen1-modern-ui

## v8.1 lower-panel routing fix

- The Kanto in Motion battle presenter now keys the Modern lower-panel path off the persistent BattleState ownership flag, not only the short-lived render.hud game flag.
- Battle dialogue and FIGHT / POKEMON / ITEM / RUN now stay in the full-width bottom panel.
- BATTLE TEXT SIZE changes only typography.
- MOVE LAYOUT = GRID uses 2x2 moves on the left with MOVE INFO on the right; MOVE LAYOUT = VERTICAL uses four stacked move rows. Both layouts use the same full-width bottom panel.

### v8.6.27 mobile viewport/title placement fix
This pass makes Kanto in Motion follow Gen1Recomp's renderer placement instead of independently centering custom surfaces. On mobile, battle stage content and HUD now move together with screen placement, SCALED HUD sizing is based on physical pixels, and portrait trainer intros stay inside the contained battlefield. The HD title trainer, Pokemon, and logo now follow the native title rect and no longer reveal the stock wordmark when SCREEN POS is moved.
