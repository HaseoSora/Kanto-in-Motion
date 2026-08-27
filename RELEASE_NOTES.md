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
