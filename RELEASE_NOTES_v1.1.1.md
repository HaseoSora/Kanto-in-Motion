# Kanto in Motion v1.1.1

Kanto in Motion v1.1.1 is a focused compatibility patch for the integrated Modern UI introduced in v1.1.0.

## SAVE screen fix

- Fixed the Gen1Recomp 0.2.13 SAVE confirmation flow reverting to the classic Gen 1 UI and splitting its menu, save summary, dialogue, and YES/NO windows across widescreen displays.
- The integrated Modern UI now recognizes Gen1Recomp's anonymous `PrintSaveScreenText` panel and presents the SAVE flow as one coherent Modern UI composition.
- START → SAVE → confirmation → YES/NO → saving/saved messages now remain visually consistent with the integrated Modern UI.
- The actual save logic, save data, confirmation behavior, and timing are unchanged; this patch only fixes presentation.


## Settings navigation fix

- Restored Kanto in Motion's animation/title settings in the centralized Mod Menu.
- `KANTO IN MOTION` now provides separate **KANTO SETTINGS** and **MODERN UI SETTINGS** entries.
- Opening **MODERN UI SETTINGS** no longer makes Kanto in Motion's own controls appear to be missing.

## Included from v1.1.0

All v1.1.0 features remain intact, including the integrated customized Gen1 Modern UI, Crimson and Crimson Glass themes, configurable integrated-UI toggle, Gen 3 UI-overhaul yielding, animated menu/Pokédex/evolution presentation, and the default battle-UI configuration.

## Credits

The integrated Modern UI foundation was created by **ArmstrongThomas**:
https://github.com/ArmstrongThomas/gen1-modern-ui

See `THIRD_PARTY_NOTICES.md` for attribution details.
