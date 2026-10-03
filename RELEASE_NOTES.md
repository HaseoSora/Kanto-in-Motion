# Kanto in Motion v1.6.3

v1.6.3 is a focused Gold / Silver / Crystal compatibility and Modern UI polish release.

## Highlights

- **Gen 2 Battle Art HD presentation** — KIM HD Pokémon now use higher-resolution 4x battler cards in Battle Art Voxel Gen2 2.1.x, reducing visible enlargement pixelation in the 3D scene.
- **Gen 2 Battle Art shadows** — KIM HD battlers use KIM-owned, camera-aligned contact shadows anchored to Battle Art's shared battler-foot plane. `PKMN SHADOWS` and `SHADOW OPACITY` continue to control the result.
- **Native G/S/C HUD placement in Battle Art** — the real Gen 2 enemy/player HP/status HUD is preserved and repositioned to the outer edges of the live widescreen 3D battlefield instead of sitting over the centered native battle area.
- **Crystal CONTINUE compatibility** — resuming a Crystal save after Battle Art's voxel-cache preload now returns to the native CONTINUE action correctly.
- **Gen 2 arrow rendering** — navigation arrows, scroll indicators, dialogue/battle continue prompts, clock arrows, and similar controls are drawn directly by KIM so unsupported font glyphs no longer appear as square boxes.
- **Responsive menu hints** — long footer/control hints now fit their available Modern UI panels more safely on mobile and when font scaling is increased.
- **Pack text cleanup** — Crystal `<NEXT>` markers are converted to description line breaks instead of being shown literally.
- **Start Menu text cleanup** — the Pokémon entry description now reads **Party POKéMON status** instead of exposing `<PK><MN>` control tokens.
- **Selection alignment** — affected Gen 2 Start Menu, Pack/CANCEL, and related list highlights now center their text vertically in the selection bar.

## Compatibility notes

Battle Art itself is not modified. KIM continues to preserve native Gold/Silver/Crystal battle logic, HP/status/EXP state, party-ball timing, caught-state behavior, trainers, and move timing underneath the presentation changes.

The v1.6.0 persistent external HD asset-cache architecture is unchanged. Existing healthy HD asset installs do **not** need to be downloaded again for v1.6.3.
