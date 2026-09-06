# Kanto in Motion — Known Differences from Vanilla

Kanto in Motion is a presentation mod. It does not intentionally change battle mechanics, Pokémon data, encounter logic, save progression, or link-relevant gameplay state.

## Deliberate presentation differences

- Gen 1 supported UI screens may display selected Gen 2-5 animated front artwork instead of original static Gen 1 art.
- Gen 2 supported presentation surfaces may display Kanto in Motion animated front artwork while the native Gen 2 UI or Gen2 Clean UI remains the interface owner.
- On Gen 1, the customized integrated Modern UI may replace supported vanilla menus and information screens.
- On Gen 2, Kanto in Motion's bundled Modern UI is intentionally suppressed.
- Red/Blue title Pokémon may use animated Gen 2-5 artwork and rotate through all 151 Kanto species.
- Title Pokémon randomization avoids the 24 most recently shown species whenever possible.
- Missing optional artwork intentionally falls back rather than changing gameplay.

## Gen 1 Modern UI preference

The Gen 1 integrated Modern UI defaults ON, but the player's manual Gen 1 ON/OFF choice is saved. Gen 2 never enables Kanto in Motion's bundled Modern UI and does not overwrite the saved Gen 1 preference.

## Gameplay / link behavior

None intentionally. The manifest declares `affects_link: false`.
