# Kanto in Motion v1.6.5

v1.6.5 focuses on **1025Dex battle compatibility**, **Game3 presentation consistency**, and a couple of UI/asset-menu polish fixes.

## Highlights

- **1025Dex split ownership** — with the optional 1025Dex mod present, KIM keeps its HD animated battle sprites for National Dex #001–386 and delegates #387–1025 to 1025Dex. The rule is applied independently to the player and opponent slots.
- **No duplicate battlers** — KIM remains the outer Game3 Pokémon-picture router, preventing KIM and 1025Dex from drawing the same battler on top of each other.
- **Unified battle-floor placement** — 1025Dex fallback battlers are presented through KIM's final battle plane so their visible sprites sit on the authored platform instead of floating above it. Opponent/front sprites include the confirmed grounding adjustment.
- **KIM shadows for post-Gen3 battlers** — 1025Dex fallback Pokémon use KIM's ground-contact shadow system and the existing shadow quality/opacity settings while 1025Dex continues to supply the art.
- **Gen 2 mobile arrow spacing** — Modern UI up/down scroll arrows reserve their own right-side gutter instead of overlapping option values.
- **Cleaner Game3 Start Menu** — **KIM ASSETS** is shown on FireRed/LeafGreen/Emerald only when the shared HD asset pack is missing or incomplete. A healthy cache hides the entry automatically.

## Compatibility notes

1025Dex is optional and is not modified by Kanto in Motion. When it is absent, normal KIM/Game3 behavior is unchanged.

The persistent external HD asset-cache format is unchanged. Existing healthy HD asset installs do **not** need to be downloaded again for v1.6.5.
