# Kanto in Motion v1.6.1

v1.6.1 is a focused compatibility and stability update following v1.6.0.

## Highlights

- **Gen 1 Android/mobile battle stability** — protects KIM's battle draw boundaries from graphics-state leaks that could eventually trigger `Maximum stack depth reached`.
- **Built-in controller support on Android handhelds** — the Modern battle dialogue/command panel no longer disappears just because virtual TouchControls are hidden. This was validated on the Retroid Pocket 6.
- **Oak's Lab rival presentation** — restores KIM's Gary front trainer artwork at the corrected scale and prevents the native rival from appearing a second time at the battle outro.
- **Expanded Gen 1 Modern UI** — adds supported NEW GAME dialogue/choice/naming presentation and the initial `WHICH PC?` menu while preserving native game state and callbacks.
- **iOS Battle Art orientation compatibility** — adds a world-only correction for the affected Apple/Metal renderer so Battle Art's 3D battlefield can be corrected without flipping KIM's HUD, Modern UI, or touch controls.

## iOS testing note

The iOS Battle Art compatibility path is included based on the current Battle Art implementation and its Apple/Metal renderer handling. It has not been locally hardware-tested by the Kanto in Motion maintainer, so iPhone/iPad users are encouraged to report results, especially when using Battle Art.

## v1.6.0 asset system

The slim-core asset system introduced in v1.6.0 is unchanged. Large HD battle sprites/backgrounds remain in the persistent KIM cache after their one-time Asset Manager download and do not need to be downloaded again for normal KIM code updates.
