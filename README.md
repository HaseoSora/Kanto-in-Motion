# Kanto in Motion v1.7.6

**Kanto in Motion** is an HD animated Pokémon presentation and battle overhaul for **Gen1Recomp**.

It supports:

- **Pokémon Red / Blue / Yellow** — National Dex #001–151
- **Pokémon Gold / Silver / Crystal** — National Dex #001–251
- **Pokémon FireRed / LeafGreen / Ruby / Sapphire / Emerald** — National Dex #001–386

The internal mod ID remains `animated_menu_pokemon`, so compatible Kanto in Motion settings can carry forward when updating.

## What’s new in v1.7.6

- **Gen 1:** BATTLE UI SIZE now supports up to **150%** (default 100%).
- **Gen 1:** Added per-setting descriptions to Kanto Settings, with readable wrapped text and concise help. Modern UI Settings footer presentation has also been revised.
- **Gen 1 evolution:** Improved the Modern UI evolution window and overworld presentation after battles, including handling of leftover battle HUD layers during evolution. Additional completion-stage behavior may vary by mod stack.
- **Gen 2:** Improved desktop Battle Art Gen 2 HUD and already-caught Poké Ball compatibility, including native icons in both 2D and 3D-BTL modes, QOL RED/GREY indicators, and HUD COLOR inversion.
- **Gen 2:** Improved Modern Battle UI layout clearance and Nidoran♀/Nidoran♂ gender-symbol rendering in battle dialogue.
- **Gen 2:** Refined Modern UI evolution window scaling and overworld presentation.
- **Gen 3:** Includes Ruby/Sapphire Modern Battle UI graphics-stack hardening and battle cursor fixes from the development line, plus evolution-window layout adjustments. Emerald Modern Battle UI stability remains under investigation.


## What’s new in v1.7.5

v1.7.5 focuses on **independent Start Menu customization across all three generations**, with additional Gen 1 Pokémon summary presentation improvements and Gen 2 Save Game/mobile UI refinements.

- **START MENU UI SIZE (Gen 1 / Gen 2 / Gen 3):** new independent 60%–200% control (default 100%) for sizing the in-game Start Menu panel, rows, and layout without changing other Modern UI screens.
- **START MENU TEXT SIZE (Gen 1 / Gen 2 / Gen 3):** new independent 60%–200% control (default 100%) for the Start Menu title, entries, and hints. Text is fitted to available space.
- **Gen 1 Pokémon Status/Summary:** reorganized the Pokémon artwork, name, level, HP, stats, and moves into a more readable structured layout inspired by Gen 2's information panel. The Party Menu remains unchanged.
- **Gen 2 Save Game presentation:** repaired missing rendering helpers that could leave the Modern Save Game panel blank and improved its mobile panel sizing behavior. The native save operation remains game-owned.
- **PC and mobile:** Start Menu layout and text customization work independently and are bounded by the available viewport.
- **Existing features retained:** includes the v1.7.4 Gen 2 battle layout and sprite fixes, OG/WIDE battle interface, and Gen 2/Gen 3 Pixel Frame alignment updates.

## What’s new in v1.7.4

v1.7.4 focuses on **Gen 2 battle presentation polish** and **Modern UI frame alignment across Gen 2 and Gen 3**, while retaining the prior multi-generation overhaul and compatibility work.

- **Gen 2 battle UI layout improvements:** refined the Gold/Silver/Crystal Modern battle panel arrangement for more consistent presentation across games and desktop/mobile displays.
- **OG / WIDE battle layout choice:** added **BATTLE UI MODE** under Gen 2 UI SETTINGS (OG/WIDE; default WIDE), for choosing classic-width or widescreen lower battle menus. Portrait retains its dedicated mobile arrangement.
- **Battle UI scaling and placement:** refined battle panel, text scaling, and placement to reduce overlaps with battlers and HP/status HUDs; Gen 2 BATTLE UI SIZE now ranges from 60% to 150% (default 100%).
- **HD Pokémon sprite presentation:** corrected Gen 2 battle paths that could fall back to vanilla sprites when HD sprites were enabled.
- **Crystal trainer presentation:** corrected the Crystal player battle-intro sprite selection so the appropriate native back sprite is used instead of unrelated front/menu artwork.
- **Pixel Frame 1–3 borders:** adjusted Gen 2 and Gen 3 Modern UI panel frame drawing so pixel-style borders extend around panel edges rather than sitting inside the content area.
- **Existing functionality retained:** Gen 1–3 Modern UI screens, external HD assets, Gen 2 Trainer Card and storage features, Gen 3 menus, and established compatibility bridges remain included.

## What’s new in v1.7.3

v1.7.3 is a focused compatibility and presentation-polish update for **Gen 1 menu Pokémon** and the **Gen 2 Trainer Card**. KIM continues to leave gameplay, save data, evolution rules, and third-party sprite logic with their original owners while coordinating presentation ownership cleanly.

- **Crystal Animated Sprites compatibility for Gen 1:** KIM now cooperates with **Crystal Animated Sprites with Shiny Visuals** on supported Gen 1 menu surfaces instead of overriding its artwork. Party, Pokédex, Summary/Status, PC, and evolution presentation can use the Crystal mod’s live artwork, including its animation/shiny handling where provided.
- **Gen 1 MENU SPRITES source selector:** the old Gen 1 `MENU SPRITES` ON/OFF toggle is now **KIM HD / VANILLA**, matching the source-selection approach used by later generations. `KIM HD` keeps KIM’s animated HD menu Pokémon; `VANILLA` yields those slots back to Gen1Recomp and compatible providers such as Crystal Animated Sprites. This remains independent from `POKEMON ICONS` and `BATTLE SPRITES`.
- **Safe migration from older settings:** existing Gen 1 installs that had the previous boolean `MENU SPRITES` disabled migrate to `VANILLA`; enabled installs remain on `KIM HD`.
- **Gen 2 Trainer Card player portrait fix:** page 1 now uses the ROM-derived **CHRIS/KRIS 56×56 trainer front sprite** instead of rebuilding the portrait from captured Trainer Card pixels. This removes the corrupted mobile portrait and the stray tile artifact that could appear beside the trainer on desktop.
- **Gen 2 Trainer Card mobile layout polish:** internal card scaling is capped to the real panel height on wide mobile displays so the lower Gym Leader row no longer collides with the footer.
- **Trainer Card draw hardening:** page 1 text/data and portrait rendering are isolated so a failed portrait load cannot blank the entire Trainer Card presentation.
- **Existing v1.7.2 work retained:** Johto/Kanto Gym Leader Trainer Card pages and animated badges, Fly-map region switching, Modern Gen 2 field-action submenus, and all prior Gen 1/Gen 2/Gen 3 Modern UI work remain included.

## What’s new in v1.7.2

v1.7.2 continues the **Gen 2 Modern UI expansion**, focusing on the Trainer Card, regional Fly map behavior, and presentation compatibility with field-action helper mods. KIM still leaves game progression, badge ownership, Fly destinations, field-move callbacks, and third-party mod logic to their original owners.

- **Expanded Gen 2 Trainer Card:** the card now uses its third page for the **Kanto Gym Leaders**, while page 2 remains the Johto Gym page.
- **Full Gym Leader battle sprites:** both Johto and Kanto Trainer Card pages use the larger generated battle-trainer sprites instead of the smaller native face crops. Outer white paper is removed transparently and the sprites use richer Crystal-style colour palettes for a closer match to the game’s coloured trainer artwork.
- **Animated Johto + Kanto badges:** Johto continues to use the native animated Gen 2 badge graphics. Earned Kanto badges now use KIM’s existing **Gen 1 Trainer Card animated badge sprite sheets**, including their full frame sequences rather than a static emblem.
- **Johto / Kanto Fly-map switching:** the Gen 2 Fly picker now supports **LEFT / RIGHT** region switching between Johto and Kanto when Kanto Fly destinations are available. The destination list and map update together while preserving Gen1Recomp’s visited-flypoint rules.
- **Modern Gen 2 field-action submenus:** generic Gen 2 menus used by compatible helper mods can now inherit KIM Modern UI presentation. This includes Quality of Life’s held-START field actions and water interaction choices such as **FLY / TELEPORT / FLASH / DIG**, Fishing Rod choices, **SURF**, and **CANCEL**. KIM does not modify the Quality of Life mod; its rows, callbacks, and behavior remain authoritative.
- **Existing v1.7.1 work retained:** Gen 2 PC/storage Modern UI, modern Gen 2/Gen 3 evolution presentation, the Gen 2 Party/Pokédex/Trainer Card improvements, HD icon fixes, battle-sprite tuning, and the full v1.7.0 Gen 3 Modern UI remain included.

## What’s new in v1.7.1

v1.7.1 is a focused **Gen 2 Modern UI and presentation-polish update**, with matching evolution presentation improvements carried into Gen 3. Native game logic, saves, inputs, battle rules, PC/storage behavior, evolution rules, and Pokédex state remain owned by Gen1Recomp; KIM changes supported presentation layers only.

- **Gen 2 Party overhaul:** the Modern Party screen is more compact and now shows the complete five-stat block — ATK, DEF, SPEED, SP.ATK and SP.DEF — with cleaner spacing and fallbacks for older/imported records whose cached display stats are incomplete.
- **Gen 2 Pokédex cleanup:** removes the unused EVO / MOVES tabs, keeping the native Gen 2 actions only. The AREA page now uses the game’s actual regional nest map and encounter markers instead of a text-only location list.
- **Gen 2 Start Menu MODS access:** restores the native `MODS` entry so the full Gen1Recomp Mod Manager remains reachable while KIM Modern UI is enabled.
- **Gen 2 Trainer Card upgrade:** reuses the native player and Gym Leader artwork inside KIM, removes the card-paper backgrounds, enlarges the Gym Leader portraits, preserves legitimate white sprite details, restores the native number markers, and shows the actual earned badge emblems at the far right of each leader row with a slower animation cycle.
- **Gen 2 PC / storage Modern UI:** the Pokémon Center PC chooser, Bill’s PC menu, and Bill’s PC Pokémon storage screens now use KIM’s floating Modern UI over the live overworld while the native PC/storage state and actions remain authoritative.
- **Modern evolution presentation:** Gen 2 evolution now opens as a floating Modern UI presentation over the overworld while keeping native timing, cancellation, cries, species changes, move learning, and callbacks. The same floating Modern evolution treatment is also applied to Gen 3 (FR/LG, R/S, Emerald).
- **Gen 2 battle sprite tuning:** adds species-specific presentation tuning for HD battlers whose animation cells contain unusual transparent space. Pidgeotto is enlarged and raised so its flying animation reads at the intended size and height.
- **Gen 2 HD icon reliability:** strengthens National-Dex icon resolution after evolution/imports, fixes procedural gender-symbol rendering in the Modern PC, and repairs the malformed PNG metadata that prevented the Quilava #156 and Typhlosion #157 HD menu icons from loading in stricter decoders.
- **Gen 2 save hardening:** impossible transient LÖVE userdata values are stripped from the live Gen 2 save table before serialization so presentation/cache objects cannot cause a save hard error.
- **Existing v1.7.0 work retained:** the expanded Gen 3 Modern UI, 1025Dex safeguards, external asset system, Battle Art/PotatoVoxel compatibility, Dex Radar integration, Unown/Deoxys form support, and prior Gen 1/Gen 2/mobile fixes remain included.

## What’s new in v1.7.0

v1.7.0 is the first release centered on Kanto in Motion's expanded **Gen 3 Modern UI** for FireRed/LeafGreen and Ruby/Sapphire/Emerald, with additional 1025Dex safety and compatibility work. Gen1Recomp still owns Game3 gameplay, battle rules, scripts, input, saves, and state; KIM replaces supported presentation layers only.

- **Gen 3 Modern UI expansion:** KIM now presents the Game3 main menu, Start Menu, Bag, Party, Summary/Status, Pokédex, Pokémon Storage/Pokébox, Options, Kanto in Motion settings, common dialogue/choices, naming screens, catch nickname flow, Trainer Card, and supported battle lower-panel surfaces through the active Modern UI theme.
- **Modern Trainer Card:** FireRed/LeafGreen and Hoenn Trainer Cards use KIM's theme/font/frame/scale/opacity presentation while preserving source-owned card data, badge/star logic, A/B controls, and front/back flip behavior. The card opens as a floating window over the live overworld like KIM's other Modern UI menus.
- **Modern Gen 3 naming:** the Pokémon/player naming keyboard, nickname prompt, action controls, gender symbols, HD preview icon path, and controller navigation are modernized while the native naming state remains authoritative.
- **Pokédex readability pass:** raw Game3 formatting tokens such as `{UNK_SPACER}` are sanitized from Modern UI output, and long Pokédex descriptions wrap/fit inside the description panel instead of being clipped.
- **Gen 3 main-menu polish:** the Modern main menu now supports round-robin vertical navigation, so UP from the first row wraps to the last row and DOWN from the last row wraps back to the first.
- **HD icon/storage polish:** final-resolution HD icon rendering is used across the expanded Gen 3 menu surfaces, including naming and storage, with corrected 1025Dex gender fallback in the Pokébox information panel.
- **1025Dex battle presentation bridge:** when 1025Dex is active, KIM keeps its own HD presentation for National Dex #001–386 and cooperates with the expanded provider for post-Gen3 species while preserving KIM grounding/shadow presentation where supported.
- **1025Dex disabled/removed safety:** saved post-Gen3 party Pokémon are quarantined only in the temporary battle-party copy when no compatible expanded-dex provider is active. They behave as unavailable/fainted for lead/switch selection instead of crashing on missing species data, while the real saved Pokémon remains untouched and becomes usable again when 1025Dex is restored.
- **Existing multi-generation work retained:** Gen 1, Gen 2, external HD asset caching, Unown/Deoxys form routing, Battle Art/PotatoVoxel compatibility, Dex Radar compatibility, mobile fixes, and all v1.6.x presentation work remain included.

## Older update notes

Release notes from **v1.6.6 and earlier** have been moved to [OLDER_UPDATE_NOTES.md](OLDER_UPDATE_NOTES.md) to keep this README focused on current releases.

## Main features

### Red / Blue / Yellow

- HD animated front/back Pokémon
- Normal and shiny battle presentation
- Integrated Modern UI, including supported NEW GAME dialogue/choices/naming and PC menus
- KIM HP/status HUD
- Integrated move animations
- HD location/time-aware battle backgrounds
- Pokémon shadows
- Shiny encounter presentation
- Player trainer selection
- Animated title-screen Pokémon
- HD Pokémon icons
- Native-fit HD background mode for vanilla/default battlers
- Battle Art and PotatoVoxel compatibility

### Gold / Silver / Crystal

- HD animated Pokémon through National Dex **#251**
- HD animated **Unown A-Z** form presentation, using each Pokémon's native Gen 2 form
- Integrated KIM **Modern UI** for menus, dialogue, shops, save/options, Pokédex, Party, and supported battle UI surfaces
- Native Gen 2 battle logic, HP/status HUD, trainers, backgrounds, and move animations
- Modern UI themes and applicable UI customization controls shared with KIM’s Gen 1 presentation
- HD animated battle Pokémon
- HD Summary-screen Pokémon
- HD Pokédex Pokémon
- HD Pokémon icons
- Pokémon shadows
- Full Modern UI title/main menu and NEW GAME setup flow
- Dex Radar 1.2.0 Modern UI compatibility
- Final-window rendering for crisp HD menus and Pokémon art
- Shared external HD cache use on desktop and mobile, including Johto #152–251

### FireRed / LeafGreen / Ruby / Sapphire / Emerald

- HD animated Pokémon through National Dex **#386**, with optional 1025Dex cooperation for post-Gen3 species
- HD animated **Unown A-Z + ! + ?** form presentation using native Gen 3 personality/form selection
- HD Deoxys form routing for Normal, Attack, Defense, and Speed forms where the source game/provider supplies those forms
- Integrated **Gen 3 Modern UI** for the main menu, Start Menu, Bag, Party, Summary/Status, Pokédex, Storage/Pokébox, Options/KIM settings, dialogue/choices, naming, Trainer Card, and supported battle UI surfaces
- Modern lower battle dialogue/command/move presentation while Game3 keeps the native HP/status HUD and battle logic
- Final-resolution HD menu Pokémon/icons to avoid enlarging low-resolution Game3 copies
- HD animated battle Pokémon, optional location-aware HD battle backgrounds, and Pokémon shadows
- Modern Pokédex description wrapping/token cleanup and modern catch/nickname flow
- Modern Trainer Card presentation that floats over the live overworld and preserves native card data/flip behavior
- Round-robin navigation on the Gen 3 Modern title/main menu
- Conditional **KIM ASSETS** Start Menu access when the shared external HD pack is missing or incomplete; the entry hides automatically once the cache is healthy
- Desktop and mobile presentation support, including FR/LG portrait/landscape handling and existing SCREEN POS behavior
- Optional **1025Dex** compatibility for post-Gen3 battle sprites, gender presentation, and safe handling of saved expanded species when the provider is later disabled or removed
- Emerald-specific suppression of the native alternate 2D cry/entrance battler frame when KIM owns battle presentation, with the KIM hop/cry timing preserved
- Final-resolution animated HD Emerald starter confirmation previews while the original starter scene, cursor, prompts, and game logic remain native

## HD Pokémon icons

Kanto in Motion includes HD Rescaled Pokémon icons for **National Dex #001–386**.

- R/B/Y uses KIM's established icon path.
- G/S/C renders the HD icons at final window resolution instead of magnifying the native 16×16 icon canvas.
- Gen 3 renders KIM HD icons at final window resolution across supported Party, Storage, Pokédex, naming, and related menu surfaces instead of enlarging the native Game3 icon canvas.
- `POKEMON ICONS = OFF` restores the native game icons or yields to a compatible icon provider.
- Icon animation follows the main `ANIMATION` setting.
- Separate shiny menu-icon artwork is not included yet; shiny Pokémon currently use the normal HD menu icon.

## Kanto in Motion settings

Open **KANTO IN MOTION** from the mod settings screen. On **Red / Blue / Yellow**, the Gen 1 battle-specific controls are grouped under **BATTLE → OPEN**. The HD Asset Manager can also remove an installed external pack and make it available for a later re-download.


### Red / Blue / Yellow — main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | KIM HD / VANILLA | KIM HD | Chooses KIM's HD animated menu Pokémon or yields supported Gen 1 menu Pokémon surfaces back to Gen1Recomp/compatible sprite providers such as Crystal Animated Sprites. Independent from POKEMON ICONS and BATTLE SPRITES. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in party and other native icon slots. OFF yields icon presentation to the game or another compatible icon provider such as HGSS_SPRITES. |
| **INTEGRATED MODERN UI** | ON / OFF | ON | Enables KIM's customized Gen 1 Modern UI presentation. |
| **START MENU UI SIZE** | 60%–200% | 100% | Resizes only the in-game Start Menu panel and layout independently of overall UI scale; bounded on mobile. |
| **START MENU TEXT SIZE** | 60%–200% | 100% | Resizes only Start Menu titles, entries, and hints independently of Start Menu UI Size and overall font scale. |
| **ANIMATION** | ON / OFF | ON | Enables animated Pokémon playback and supported animated trainer presentation. OFF holds supported animated art on its first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's animated title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Chooses KIM's animated Red title trainer or Gen1Recomp's original title trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly the title-screen Pokémon changes. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales only the cycling title-screen Pokémon. Red and the custom logo are unchanged. |
| **ASSET MANAGER** | OPEN | — | Opens the HD Asset Manager for downloading, removing, re-downloading, checking, or reusing the external HD battle asset pack. |

### Red / Blue / Yellow — BATTLE settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | ON | Master switch for KIM's Gen 1 battle scene/HUD presentation. OFF yields those layers to vanilla Gen1Recomp or another compatible battle owner. |
| **MODERN BATTLE UI** | ON / OFF | ON | Uses KIM's integrated command, move-selection, and battle-message presentation. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's HD animated battle Pokémon. Compatible external battle scenes can honor this setting independently. |
| **MOVE ANIMATIONS** | ON / OFF | ON | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animations for all 165 Gen 1 moves. OFF falls back to the active battle provider's native move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality. Higher levels add progressively softer feathering. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts shadow darkness without changing Pokémon size or position. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves the normal DV behavior intact. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD battle backgrounds. |
| **BATTLE BG MODE** | AUTO / FULLSCREEN / NATIVE FIT | AUTO | Controls how Gen 1 HD battle backgrounds are framed. AUTO keeps the full-screen KIM arena with KIM battle sprites, but switches to native-fit framing when BATTLE SPRITES is OFF. NATIVE FIT keeps vanilla/default battlers and native attack effects at their original 160×144 positions while showing the arena through a wider FR/LG-style 240×160 viewing window, with a calibrated vertical offset to align the HD pads to stock battlers. |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / front-sprite choices | RED | Chooses the player trainer shown during battle intro/send-out. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the player-side Pokémon. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | 100% | Scales Pokémon in compatible staged 3D battles. 100% is KIM's neutral reference. |
| **POTATO CAMERA** | 100%–150% in 5% steps | 115% | PotatoVoxel only. Higher values pull the camera farther back. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | 85% | Mobile PotatoVoxel only. Fine-tunes enemy Pokémon size. |
| **HUD SCALE** | OG / SCALED | OG | Chooses the HP/status HUD scale preset. |
| **HUD SIZE** | 60%–100% in 5% steps | 100% | Fine-tunes the enemy/player HP/status HUD size. |
| **HUD OPACITY** | 25%–100% in 5% steps | 100% | Adjusts HP/status HUD opacity. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Changes the footprint of the lower command/move/message panel. 100% is the calibrated neutral size and matches the physical footprint that 95% used in earlier releases. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts the lower panel background opacity. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales Modern UI battle command, move, and message text. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move layout. VERTICAL lists moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses the HP/status glyph treatment. |

### Gold / Silver / Crystal settings

Gold / Silver / Crystal retain their native gameplay and battle logic. KIM's Modern UI is a presentation layer: the native Gen 2 HP/status HUD, trainers, battle timing, backgrounds, move animations, scripts, shops, save logic, option logic, and state transitions remain authoritative underneath it.

#### Main Kanto in Motion settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | KIM HD / VANILLA | KIM HD | Chooses KIM's HD animated menu Pokémon or the native Gold/Silver/Crystal Pokémon artwork. This is independent from POKEMON ICONS and BATTLE SPRITES. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in native G/S/C icon slots. OFF restores the game or another compatible icon provider. |
| **ANIMATION** | ON / OFF | ON | Master animation control for supported KIM Pokémon/trainer presentation. OFF holds supported animated KIM artwork on its first frame. |
| **MODERN UI** | ON / OFF | ON | Master switch for KIM's Gen 2 Modern UI across the title/main menu, Start/menu screens, Party, Pokédex, Pack, PokéGear, Trainer Card, PC/storage, evolution, Save, Options/KIM settings, dialogue, shops, choices, level-up messages, and supported battle UI surfaces. OFF yields those presentation surfaces to the native game. |
| **UI SETTINGS** | OPEN | — | Opens the dedicated Gen 2 UI customization submenu described below. |
| **ASSET MANAGER** | OPEN | — | Opens the HD Asset Manager for downloading, removing, re-downloading, checking, or reusing the external HD battle asset pack. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in native G/S/C battles while retaining native Gen 2 battle logic and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts Gen 2 battle shadow darkness without changing Pokémon size or position. |

#### Gold / Silver / Crystal — UI SETTINGS

These controls are grouped under **KANTO IN MOTION → UI SETTINGS**. They mirror the applicable Gen 1 Modern UI customization options while keeping Gen 2 game/state ownership native.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **UI THEME** | GEN1 MODERN / CLASSIC MONO / CRIMSON / CRIMSON GLASS / MODERN GLASS / POCKET GREEN / MIDNIGHT / MIDNIGHT GLASS / FROST / LIGHT / DARK | GEN1 MODERN | Chooses the palette used across the Gen 2 Modern UI. |
| **UI FRAME STYLE** | THEME / PIXEL / SOFT / PLAIN | PIXEL | Chooses the Modern UI panel border treatment. |
| **PIXEL FRAME** | FRAME 1 / FRAME 2 / FRAME 3 | FRAME 2 | Selects the decorative PNG border surrounding Modern UI panels when UI FRAME STYLE is PIXEL. |
| **PIXEL FRAME SCALE** | 1X / 2X / 3X / 4X | 2X | Scales the pixel border artwork by a whole-number multiplier; the frame surrounds the panel rather than sitting inside its content area. |
| **UI DENSITY** | AUTO / COMPACT / COMFORTABLE | AUTO | Adjusts panel spacing and row height. |
| **UI SCALE** | AUTO; 75%–150% in 5% steps; 175%–400% in 25% steps | 100% | Scales Gen 2 Modern UI panels and control spacing. 100% is calibrated to the cleaner Gen 1-like footprint. |
| **FONT SCALE** | AUTO; 80%–200% in 5% steps | 100% | Scales Modern UI title, body, caption, value, and hint text independently of panel size. Settings/list layouts adapt their row and footer spacing to larger fonts. |
| **START MENU UI SIZE** | 60%–200% | 100% | Resizes only the in-game Start Menu panel and layout independently of overall UI scale; bounded on mobile. |
| **START MENU TEXT SIZE** | 60%–200% | 100% | Resizes only Start Menu titles, entries, and hints independently of Start Menu UI Size and overall font scale. |
| **PIXEL ART FONT** | ON / OFF | OFF | ON uses the Plain Pixel font. OFF uses the normal scalable system font, matching the cleaner Gen 1-style presentation. |
| **DIALOGUE TEXT SCALE** | INHERIT / 110% / 125% / 150% / 175% / 200% | INHERIT | Boosts dialogue, choices, quantities, and confirmation text separately from general font scale. |
| **LAYOUT STYLE** | ADAPTIVE / FLOATING / FULL SCREEN | ADAPTIVE | Chooses responsive/floating cards or a larger full-screen presentation. |
| **PANEL OPACITY** | 0%–100% in 5% steps | 100% | Adjusts panel-background opacity independently from text and borders. |
| **TEXT / LINE OPACITY** | 0%–100% in 5% steps | 100% | Adjusts text, labels, borders, dividers, and accent opacity. |
| **HIDE ORIGINAL UI** | ON / OFF | ON | Hides the native Gen 2 UI where KIM supplies the complete Modern UI presentation. |
| **START MENU FAST JUMP** | ON / OFF | ON | Lets left/right directional presses jump five rows in the Gen 2 Start Menu. |
| **SIDE MENU INSET** | 0 / 10 / 20 / 30 / 40 / 50 | 0 | Moves the floating Start Menu inward on wide displays. |
| **MINIMAL UI** | ON / OFF | OFF | Uses tighter spacing and less secondary detail. |
| **DIALOGUE UI** | ON / OFF | ON | Enables Modern UI for Gen 2 text boxes, choices, quantities, and confirmation prompts. |
| **MENU UI** | ON / OFF | ON | Enables Modern UI for the Gen 2 title/main menu, Start Menu, Pack, PokéGear, Save, and Options screens. |
| **POKEMON SCREENS** | ON / OFF | ON | Enables Modern UI for Party, Pokédex, Trainer Card, PC/storage, evolution, and supported Pokémon screens. |
| **MOD MANAGER UI** | ON / OFF | ON | Enables Modern UI presentation for Kanto in Motion's own settings screens. |
| **SPRITE ANIMATION** | ON / OFF | ON | Animates supported KIM menu/Party/Pokédex artwork without changing the selected MENU SPRITES source. |
| **MODERN BATTLE UI** | ON / OFF | ON | Replaces only the native lower battle dialogue/command/move surface; the native Gen 2 HP/status HUD and battle logic remain unchanged. |
| **BATTLE UI MODE** | OG / WIDE | WIDE | Selects the Gen 2 Modern lower battle-menu layout. OG uses the classic 160×144-width presentation; WIDE uses KIM’s 304×144 widescreen presentation. Portrait mode keeps its dedicated mobile layout. This does not change the native battle battlefield or HP/status HUD. |
| **BATTLE UI SIZE** | 60%–150% in 5% steps | 100% | Adjusts the Gen 2 Modern lower battle-panel footprint while keeping it bottom-anchored. 100% is the calibrated neutral size. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts only the Gen 2 Modern lower battle-panel background opacity. |
| **BATTLE TEXT SIZE** | 50%–200% in 25% steps | 100% | Scales Gen 2 Modern battle command, move, and message text independently of the native HP/status HUD. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move selector. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected Gen 2 move's type, PP, power, and accuracy beside the move list. |

The UI Settings submenu also includes **RESET TO DEFAULT** for restoring the Gen 2 Modern UI controls to their current defaults.

#### Gen 2 Modern UI coverage

With **MODERN UI = ON**, KIM currently presents:

- title/main menu (`CONTINUE`, `NEW GAME`, `OPTION`, `EXIT GAME`) over the animated Gen 2 title artwork
- Start Menu rows remain visible/scroll correctly at enlarged UI scales, including the bottom `MODS` / `QUIT` (return-to-title) entries
- complete NEW GAME setup presentation: Crystal gender selection, clock setup/confirmation, Oak/Elm speech dialogue, player-name preset selection, the Gen 2 naming keyboard, and the final shrink/intro dialogue
- Start Menu
- Party and Pokémon status/details
- Gen2 Clean UI-based Pokédex list and entry presentation
- Pack
- PokéGear, including native map/phone data presented through the KIM theme
- Trainer Card
- Pokémon Center PC chooser, Bill’s PC, and Bill’s PC Pokémon storage
- Pokémon evolution presentation over the live overworld
- Save Menu
- native Options categories and submenus
- Kanto in Motion's own settings and Battle submenu
- common NPC / field / phone dialogue
- YES/NO prompts and scripted choice menus
- Poké Mart buy/sell/quantity/confirmation presentation
- supported level-up/stat and battle prompt presentation
- battle commands, move selection, and battle messages when **MODERN BATTLE UI = ON**

### FireRed / LeafGreen / Ruby / Sapphire / Emerald settings

Gen 3 keeps **Game3 gameplay/state ownership native** while KIM supplies the optional Modern UI and HD presentation layers. Open **OPTIONS → KANTO IN MOTION**. Appearance controls are grouped under **UI SETTINGS**, and battle presentation controls are grouped under **BATTLE SETTINGS**.

#### Main Kanto in Motion settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MODERN UI** | ON / OFF | ON | Master switch for KIM's Gen 3 Modern UI presentation. OFF yields supported menus/dialogue/battle presentation back to native Game3. |
| **UI SETTINGS** | OPEN | — | Opens the Gen 3 Modern UI appearance/behavior controls listed below. |
| **MENU SPRITES** | ON / OFF | ON | Uses KIM animated Pokémon on supported Gen 3 menu, Summary, Pokédex, naming, and scripted presentation screens. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM HD-derived icons in supported Party, Storage/Pokébox, Pokédex, naming, and other Game3 icon slots. OFF restores the native game/provider icon path. |
| **ANIMATION** | ON / OFF | ON | Animates supported KIM Pokémon. OFF holds KIM artwork on the first frame. |
| **BATTLE SETTINGS** | OPEN | — | Opens the Gen 3 Modern Battle UI, HD battle art/background, and shadow controls listed below. |
| **KIM ASSETS** | START MENU entry when needed | — | Appears only while the shared external HD asset pack is missing/incomplete. Use it to download or recover the pack; it hides again once the cache validates. |

#### Gen 3 — UI SETTINGS

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **UI THEME** | GEN1 MODERN / CLASSIC MONO / CRIMSON / CRIMSON GLASS / MODERN GLASS / POCKET GREEN / MIDNIGHT / MIDNIGHT GLASS / FROST / LIGHT / DARK | GEN1 MODERN | Chooses the palette used across Gen 3 Modern UI. |
| **UI SCALE** | AUTO; 75%–150% in 5% steps; 175%–400% in 25% steps | 100% | Scales non-battle Modern UI panels/control spacing. Battle UI has its own size control. |
| **FONT SCALE** | AUTO; 80%–200% in 5% steps | 100% | Scales Modern UI text independently of panel size. |
| **START MENU UI SIZE** | 60%–200% | 100% | Resizes only the in-game Start Menu panel and layout independently of overall UI scale; bounded on mobile. |
| **START MENU TEXT SIZE** | 60%–200% | 100% | Resizes only Start Menu titles, entries, and hints independently of Start Menu UI Size and overall font scale. |
| **PIXEL ART FONT** | ON / OFF | OFF | Uses the Plain Pixel font where available; OFF uses the normal scalable system font. |
| **UI FRAME STYLE** | THEME / PIXEL / SOFT / PLAIN | PIXEL | Chooses the Modern UI panel border treatment. |
| **PIXEL FRAME** | FRAME 1 / FRAME 2 / FRAME 3 | FRAME 2 | Selects the decorative PNG border surrounding Modern UI panels when UI FRAME STYLE is PIXEL. |
| **PIXEL FRAME SCALE** | 1X / 2X / 3X / 4X | 2X | Scales the pixel border artwork by a whole-number multiplier; the frame surrounds the panel rather than sitting inside its content area. |
| **UI DENSITY** | AUTO / COMPACT / COMFORTABLE | AUTO | Adjusts panel spacing and row height. |
| **LAYOUT STYLE** | ADAPTIVE / FLOATING / FULL SCREEN | ADAPTIVE | Chooses adaptive/floating cards or a larger full-screen presentation where supported. |
| **PANEL OPACITY** | 0%–100% in 5% steps | 100% | Adjusts panel-background opacity independently from text and borders. |
| **TEXT / LINE OPACITY** | 0%–100% in 5% steps | 100% | Adjusts text, labels, borders, dividers, and accent opacity. |
| **MINIMAL UI** | ON / OFF | OFF | Uses tighter spacing and less secondary detail. |
| **HIDE ORIGINAL UI** | ON / OFF | ON | Hides native Game3 menu pixels where KIM supplies a complete Modern UI replacement. |
| **MENU UI** | ON / OFF | ON | Enables Modern UI for supported Gen 3 menu screens such as Start, Bag, Options, main menu, naming, and Trainer Card. |
| **POKEMON SCREENS** | ON / OFF | ON | Enables Modern UI for Party, Summary/Status, Pokédex, Storage/Pokébox, and supported Pokémon screens. |
| **MOD MANAGER UI** | ON / OFF | ON | Enables Modern UI presentation for Kanto in Motion's own settings screens. |
| **START MENU FAST JUMP** | ON / OFF | ON | Lets left/right directional presses jump five rows in the Gen 3 Start Menu. |
| **SIDE MENU INSET** | 0 / 10 / 20 / 30 / 40 / 50 | 50 | Moves the floating Start Menu between the right edge and KIM's centered Gen 3 position. |
| **DIALOGUE UI** | ON / OFF | ON | Enables Modern UI for supported Gen 3 dialogue, choices, quantities, confirmations, and catch/nickname prompts. |
| **DIALOGUE UI SCALE** | 50% / 75% / 100% / 125% / 150% / 175% / 200% | 100% | Scales the Modern dialogue/choice panel footprint independently from text size. |
| **DIALOGUE TEXT SCALE** | INHERIT / 110% / 125% / 150% / 175% / 200% | INHERIT | Boosts supported dialogue and confirmation text separately from general font scale. |

The Gen 3 UI Settings page includes **RESET TO DEFAULT** for restoring the controls in that section.

#### Gen 3 — BATTLE SETTINGS

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MODERN BATTLE UI** | ON / OFF | ON | Replaces the lower Game3 battle dialogue/command/move surface while keeping the native HP/status HUD, battle state, and move logic. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Adjusts the Modern lower battle-panel footprint while keeping it bottom-anchored. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts only the Modern lower battle-panel background opacity. |
| **BATTLE TEXT SIZE** | 50% / 75% / 100% / 125% / 150% / 175% / 200% | 100% | Scales Gen 3 Modern battle command, move, and message text independently of the native HP/status HUD. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move selector; VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | ON | Shows the selected move's type, PP, power, and accuracy beside the move list. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM animated Pokémon for National Dex #001–386 in supported Game3 battles. Compatible expanded-dex providers can supply post-Gen3 species. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's supported location-aware HD Game3 battle backgrounds while keeping native battler/HUD geometry aligned. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls KIM ground-contact shadow quality for supported HD battle Pokémon. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts battle-shadow darkness without changing Pokémon size or position. |

The Gen 3 Battle Settings page also includes **RESET TO DEFAULT**.

#### Gen 3 Modern UI coverage

With **MODERN UI = ON**, KIM currently presents the supported Gen 3 main/title menu layer, Start Menu, Bag, Party, Summary/Status, Pokédex, Storage/Pokébox, native Options plus KIM settings, common dialogue/choices/confirmations, nickname/name-entry keyboard, caught-Pokémon nickname flow, Trainer Card, Pokémon evolution, and lower battle dialogue/command/move surfaces. Game3 remains authoritative for game logic, menu state, scripts, saving, battle state, and input semantics.

The optional **1025Dex** bridge remains conditional: when the provider is active, its post-Gen3 species can participate normally; if the provider is disabled or removed while those Pokémon remain in a save, KIM temporarily marks only those battle-copy slots unavailable so they cannot become an invalid lead/switch target. The original saved Pokémon data is not deleted or permanently fainted.

## Mobile support

- R/B/Y keeps separate desktop/mobile KIM battle presentation paths with graphics-state protection on Android/iOS.
- On controller-equipped Android handhelds, the Gen 1 Modern battle lower UI remains available even when Gen1Recomp's virtual TouchControls are hidden.
- The first Oak's Lab rival battle uses KIM's corrected Gary front presentation without duplicating the native rival at the outro.
- Battle Art on the affected iOS Apple/Metal/LÖVE 12 path receives a world-only orientation correction at the final Battle Art world handoff; KIM HUD/UI/touch layers are intentionally left unflipped. This compatibility path is awaiting broader community hardware validation.
- G/S/C keeps KIM's final-resolution HD Pokémon/menu rendering architecture and native Gen 2 gameplay state beneath the Modern UI presentation. v1.6.2 also fixes mobile lookup of downloaded Johto (#152–251) HD assets from the shared cache.
- FR/LG uses the native Game3 geometry with KIM HD art rendered at final resolution. Full-screen Party/Summary menus opened during battle temporarily own the frame so their HD menu Pokémon/icons are not overwritten by the battle compositor.
- FR/LG portrait and landscape honor Gen1Recomp's **SCREEN POS** setting.
- FR/LG uses a single mobile battle presentation path to avoid duplicate HUD/menu rendering.

## HGSS_SPRITES compatibility

When Kanto in Motion is used with **HGSS_SPRITES**:

- In Gen 1, `BATTLE SYSTEM = ON` blocks HGSS battle-side hooks from replacing or rescaling KIM/Battle Art battle presentation.
- HGSS overworld/player presentation remains available where it does not conflict with KIM ownership.
- `POKEMON ICONS = ON` keeps KIM in control of Pokémon icons.
- `POKEMON ICONS = OFF` yields icon presentation back to HGSS or the native game.

## Dex Radar compatibility

Kanto in Motion includes presentation-only compatibility for **Dex Radar 1.2.0** on both Gen 1 and Gen 2. Dex Radar remains completely unmodified and continues to own encounter collection, rates, levels, cursor/input, hotkeys, and closing behavior.

- **MODERN UI ON + MENU UI ON:** KIM presents the Dex Radar screen with the active Modern UI theme, font, frame, opacity, scale, density, and layout settings.
- **MODERN UI OFF** (or **MENU UI OFF**): Dex Radar keeps its original native presentation.
- The `D.RADAR` row injected by Dex Radar is retained in KIM's Modern Start Menu on both generations.
- KIM uses its HD menu icons when `POKEMON ICONS` is enabled and falls back to Dex Radar/native icon art when it is disabled or unavailable.

No files in the Dex Radar mod are patched or replaced.

## Optional compatibility

Kanto in Motion includes compatibility paths for optional external mods such as:

- Battle Art — Gen 1 compatibility plus a Gen 2 Battle Art Voxel 2.1.x bridge. G/S/C KIM HD Pokémon use higher-resolution 4x battler cards, KIM-owned `PKMN SHADOWS` / `SHADOW OPACITY` contact shadows, and native G/S/C HP/status HUD placement at the outer edges of the 3D battlefield while Battle Art keeps the arena, camera, lighting, environment, and move effects.
- 1025Dex — Game3 battle-sprite compatibility keeps KIM HD animated art authoritative for National Dex #001–386 and delegates #387–1025 to 1025Dex. KIM manages the fallback battlers' final battle-floor anchoring and contact shadows so mixed-generation battles share one presentation plane. 1025Dex itself is not modified.
- PotatoVoxel
- Typed Move Colors
- Useful Bag
- Advanced Box System
- HGSS_SPRITES
- supported translation/UI mods

External compatibility mod packages are not bundled. v1.6.0 directly vendors only the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter pieces used by KIM's Gen 2 Pokédex presentation; the separate Gen2 Clean UI mod is not required for that Pokédex presentation.

## Installation

### Installation / first launch

1. Install **Kanto in Motion v1.7.6** and enable it in Gen1Recomp.
2. On Red/Blue/Yellow and Gold/Silver/Crystal, KIM opens the **HD ASSET MANAGER** when the external HD battle pack is not already cached. On FireRed/LeafGreen/Emerald, the native Start Menu shows **KIM ASSETS** only while the shared pack is missing or incomplete; healthy caches hide the entry automatically.
3. Choose **A — DOWNLOAD** to download the official asset ZIP once, or **B — USE VANILLA / LATER** to continue without it.
4. After a successful install, the HD assets remain in Gen1Recomp's installation-scoped KIM cache and are reused by later KIM code updates.

The internal mod ID remains `animated_menu_pokemon`, so compatible KIM settings continue to carry forward.

### Updating from v1.5.x or earlier

The v1.6.0 release moves the large HD battle asset pack out of the KIM mod folder and into Gen1Recomp's persistent KIM cache. Because Gen1Recomp replaces the old mod directory during a normal update, the old embedded HD battle assets are not carried forward automatically.

After updating to v1.6.0, KIM will offer the **one-time HD asset download** on first launch. Once that download finishes, the asset pack lives outside the KIM mod folder and is reused by future KIM updates, so normal updates after v1.6.0 no longer require downloading the large asset pack again.

As of **v1.6.6**, the asset system can also apply additive pack updates. `Kanto-in-Motion-Assets v1.1.0` adds the new Unown B-Z/!/? form artwork on top of the original v1.0.0 base pack. Existing healthy v1.0.0 installs download only the smaller v1.1.0 overlay; fresh installs automatically install the base pack and then the overlay.

### Downloadable HD battle assets

The large HD Pokémon battle sprite sheets and HD battle backgrounds are no longer stored inside the normal KIM release ZIP. KIM's small battle-support assets, trainer art, UI art, effects, move-animation resources, icons, and code remain packaged with the core mod.

The **HD ASSET MANAGER** downloads the official `HaseoSora/Kanto-in-Motion-Assets` release as one temporary ZIP, verifies `asset-pack.json`, extracts only its `assets/` payload into KIM's installation-scoped cache, and deletes the temporary ZIP after a successful install.

- **A — DOWNLOAD:** checks the official tagged asset release and starts the one-time ZIP download.
- **B — USE VANILLA / LATER:** continues without downloading; missing HD battle artwork falls back safely where supported.
- **B while downloading:** cancels the temporary ZIP download and continues without the HD pack.
- Extraction runs incrementally after the ZIP download completes.
- **R/B/Y + G/S/C:** **KANTO IN MOTION → ASSET MANAGER** reopens the installer at any time.
- **Game3 (FR/LG/Emerald):** **Start Menu → KIM ASSETS** appears only while the shared pack is missing or incomplete and opens the same manager for download/recovery.
- **R/B/Y + G/S/C installed pack:** press **B — REMOVE**, then confirm with **A — REMOVE** to delete KIM's cached HD Pokémon/background pack.
- Removing the pack is useful for reclaiming storage or repairing a corrupted cache.
- After removal, KIM does not force another download. Choose **A — DOWNLOAD AGAIN** immediately or reopen **ASSET MANAGER** later to reinstall the pack. Restarting Gen1Recomp after removing/reinstalling assets is recommended so any already-loaded artwork is refreshed.
- Existing cached assets are reused automatically; ordinary KIM code updates do not redownload the pack.
- **Portable mode is supported:** when `portable.txt` is active, KIM keeps Gen1Recomp's normal asynchronous ZIP downloader, then reopens the completed temporary ZIP through Gen1Recomp's native file helper for extraction. Final HD assets still live in portable-aware `mod.cache`, and the temporary ZIP is deleted after install/cancel/error. Normal installs keep the standard streamed temporary-ZIP path.
- **Game3 mobile download handoff:** Android/iOS FireRed/LeafGreen/Emerald uses the same engine-owned native temporary-ZIP handoff after Gen1Recomp's binary-safe downloader finishes, avoiding a Game3 mobile sandbox mismatch between the worker-owned save directory and the mod-visible filesystem. Desktop Game3 keeps the normal raw filesystem path.

KIM requires the **NETWORK** permission only for the optional HD asset download path.

## Credits

- **Animated Pokémon battle sprites — Battle Sprites Reloded**
  - Creator: **JDChaos**
  - https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/

- **HD Rescaled Pokémon Icons — LockeGriss and contributors**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/

- **Charizard and Cyndaquil-family icon edits — HaseoSora**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/#comment-2173491

- **Animated Trainer Card badges — xpixelpriorx**
  - https://www.deviantart.com/xpixelpriorx

- **Gen1 Modern UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen1-modern-ui

- **Gen2 Clean UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen2-clean-ui
  - v1.6.0 vendors the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter used by KIM's Gen 2 Pokédex presentation.

- **Kanto Rework Suite — Faendra**
  - https://github.com/Faendra/kanto-rework-suite

- **Poké Ball Colorfix — keberos**
  - https://github.com/keberos/pokeball-colorfix

- **Dex Radar — Zetto22**
  - https://github.com/Zetto22/dex_radar
  - Optional external mod; KIM provides presentation-only compatibility and does not modify Dex Radar.

## Disclaimer

Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.

### Slim-core asset split note
The downloadable HD pack contains only the large HD Pokémon battle sprite sheets and HD battle backgrounds. KIM's small battle-support assets (including selectable player trainer frames/animations) remain packaged with the core mod so battles can initialize safely before/without the HD pack.

### Gen 2 Battle Art compatibility

For **Battle Art Voxel Gen2 2.1.x**, KIM supplies higher-resolution 4x G/S/C HD battler cards to the 3D presentation and draws its own camera-aligned contact shadows for those KIM HD cards. `PKMN SHADOWS` controls shadow quality and `SHADOW OPACITY` controls darkness. The contact ellipse is anchored to Battle Art's shared battler-foot plane so it stays planted beneath the Pokémon while the camera moves.

When **3D-BTL** is active, KIM keeps the actual native G/S/C HP/status HUD. The live enemy and player HUD bands are captured during Battle Art's widescreen render pass and placed toward the outside-left and outside-right of the 3D battlefield rather than remaining over the centered 160×144 battle area. Native HP/status/EXP, party-ball timing, caught-state behavior, battle logic, trainers, and move timing remain source-owned.

Battle Art's arena, camera, lighting, world geometry, and move effects remain Battle Art-owned; KIM does not modify Battle Art files. Fully closing and restarting Gen1Recomp after replacing either compatibility mod is recommended so old Lua modules are not left resident in the launcher process.


### Independent Start Menu controls (Gen 1 / Gen 2 / Gen 3)

Each generation offers **START MENU UI SIZE** and **START MENU TEXT SIZE** (both 60%–200%, default 100%). Window sizing and typography are independent from each other and from the overall UI/font controls. These options affect the in-game Start Menu only, not Party, Bag, Summary, or other Modern UI panels. On smaller mobile screens the panel and text are constrained to the available space.

### Gen 2 native battle HP HUD color (v188 test)

- **HUD COLOR** (COLOR / INVERTED; default COLOR) changes the native Gen 2 battle HP frame and HP-label tile ink from black to light while preserving the colored health gauges. It does not affect the lower battle UI, Glass themes, sprites, or other screens.
