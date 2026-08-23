# Kanto in Motion — Known Differences from Vanilla

Kanto in Motion is a presentation mod. It does not intentionally change battle mechanics, Pokémon data, encounter logic, save progression, or link-relevant gameplay state.

## Deliberate presentation differences

- Summary/Status and Pokédex entry screens may display locally imported animated Gen 2-5 front artwork instead of the original Gen 1 static front sprite.
- Compatible Gen1 Modern UI screens may use the same Kanto in Motion animated artwork for Party, Summary, Pokédex, and evolution presentation.
- Evolution sequences may show the selected animated sprite generation for the old and evolved Pokémon while retaining Gen1Recomp's evolution flow.
- The Red/Blue title-screen Pokémon pool may use animated Gen 2-5 artwork and expands the rotating species pool to all 151 Kanto Pokémon.
- Title Pokémon randomization avoids the 24 most recently shown species whenever possible.
- Title cycle timing can be changed between NORMAL, SLOW, and SLOWER.
- On stock Gen1 Pokédex and STATUS/Summary screens, oversized animated portraits are fitted within the classic 56×56 portrait area rather than overflowing the UI.
- When locally supplied, Red's title sprite can animate forward and backward with a five-second pause between loops.
- When locally supplied, the title screen can use the custom Gen1Recomp++ Pokémon logo while retaining the Red Version subtitle.
- Missing locally imported artwork intentionally falls back to Gen1Recomp's vanilla art rather than changing gameplay.

## Gameplay / link behavior

None intentionally. The manifest declares `affects_link: false`.

## Integrated customized Gen1 Modern UI

- Kanto in Motion v1.1.0 presents supported Gen 1 menus and information screens through the project's customized Gen1 Modern UI 0.9.11 layer instead of requiring that UI as a separate mod.
- The engine continues to own gameplay state, callbacks, input, evolution/capture logic, and battle state; the integrated UI primarily changes presentation and menu organization.
