# Kanto in Motion v1.1.4

Kanto in Motion v1.1.4 focuses on classic Gen1 UI sprite compatibility, Start-menu presentation, and safer compatibility with mods that do not integrate with the centralized Mod Menu.

## Classic Gen1 UI sprite fixes

- Fixed animated Pokédex portraits when **INTEGRATED MODERN UI = OFF**.
- Fixed Pokémon STATUS/Summary so the selected Gen 2/3/4/5 animated sprite is shown instead of the native Gen1 portrait.
- Oversized animated portraits are now fitted into the stock **56×56** portrait area. Large species such as Charizard no longer overflow the classic Pokédex/STATUS layout.
- Smaller sprites are not enlarged.
- Native Gen1 art remains the safe fallback when compatible animated artwork is unavailable.

## Start Menu Party View

- Fixed the optional **START MENU PARTY VIEW** panel so it draws a complete theme background behind the party list instead of leaving the rows floating over the overworld.

## Mod Menu compatibility fallback

- Kanto in Motion no longer removes every mod-added OPTIONS or Start-menu row unconditionally.
- Mods already recognized and represented by the centralized **MOD MENU** continue to use the centralized presentation.
- Legacy or unknown mods that cannot be represented safely in MOD MENU keep their own authored OPTIONS or Start-menu rows, preventing settings from becoming inaccessible.

## Retained from v1.1.3

- Redesigned Trainer Card with Gym Leader art and animated earned badges.
- Giovanni silhouette update.
- SAVE summary/background fixes.
- Official/unmodified Useful Bag presentation compatibility.
- Animated Trainer Card badge artwork credit to **xpixelpriorx**: https://www.deviantart.com/xpixelpriorx

## Local animated-art workflow

Public Kanto in Motion packages remain asset-light. Gen 2-5 animated Pokémon atlases and title artwork are imported locally with `tools/import_assets.py`. The importer supports compatible Battle Art animated metadata/artwork, and Kanto in Motion falls back safely to Gen1Recomp's native artwork when local assets are absent.
