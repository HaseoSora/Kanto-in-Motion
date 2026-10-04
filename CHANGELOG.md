# Changelog

## v1.6.5

- Added cooperative 1025Dex battle-sprite routing on Game3: KIM HD animated art owns National Dex #001–386 while #387–1025 use 1025Dex battler art when available.
- Prevented duplicate KIM + 1025Dex battler layers by keeping KIM as the outer `frontPic/backPic` presentation provider.
- Added KIM-managed floor/platform grounding for 1025Dex fallback battlers, including the confirmed opponent/front downward grounding adjustment.
- Added KIM ground-contact shadows to 1025Dex fallback battlers while leaving 1025Dex art ownership unchanged.
- Moved Gen 2 Modern UI mobile up/down scroll arrows into a dedicated right-side gutter so they do not overlap option values.
- Made the Game3 **KIM ASSETS** Start Menu entry conditional: it appears only while the shared HD pack is missing/incomplete and hides automatically when the cache is healthy.
- Kept the external HD asset-cache format unchanged; normal updates reuse existing healthy assets.
