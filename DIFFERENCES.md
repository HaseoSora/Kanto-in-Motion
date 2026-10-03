# Kanto in Motion v1.6.4 scope

Compared with v1.6.3, v1.6.4 focuses on Emerald presentation compatibility and responsive large-font UI behavior.

- Suppresses Emerald's native alternate 2D front-sprite frame when KIM owns the HD/3D battler presentation, replacing the visual cry beat with a small hop while keeping native audio/timing.
- Presents Emerald's opening starter Pokémon through KIM's animated HD final-resolution path instead of a low-resolution Game3-scaled copy.
- Repairs the Gen 2 CONTINUE save-summary layout so the TIME row and footer remain separated on smaller windows.
- Caps general Modern UI font scaling at 200% and makes affected title/settings/list layouts adapt row spacing, fitting, scrolling, descriptions, and footer hints to large fonts.
- Keeps affected selection bars vertically centered around enlarged text.
- Recalibrates BATTLE UI SIZE so 100% is the new neutral value with the former 95% physical footprint.

The persistent external HD asset cache remains in place, and normal KIM code updates do not require users to redownload an already-installed healthy pack.
