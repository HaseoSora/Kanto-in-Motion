# Gen 2 support

Kanto in Motion v1.3.3 retains the Gen 2 support introduced in v1.2.0 for Gold, Silver, and Crystal on the Gen1Recomp 0.2.x architecture.

## UI ownership

- Gen 1: Kanto in Motion may install its integrated customized Modern UI according to the saved Gen 1 preference.
- Gen 2: Kanto in Motion's bundled Modern UI is always suppressed.
- With stock Gen2 Clean UI 0.4.1 installed, Clean UI remains the UI owner and Kanto in Motion supplies compatible animated portraits.
- Without Gen2 Clean UI, Gen1Recomp's native Gen 2 UI remains the UI owner.

## Battle submenu

The v1.3.3 standalone **KANTO IN MOTION → BATTLE** system is currently Gen 1-only. Gen 2 keeps its established native/source-owned battle presentation.

## Current validation

- Gen 2 mod targeting/load compatibility: implemented for the declared `>=0.2.24 <0.3.0` range.
- Stock Gen2 Clean UI animated Status/Summary: confirmed working in real testing.
- Party/Pokédex/Evolution portrait bridges: implemented; additional in-game coverage testing remains welcome.
