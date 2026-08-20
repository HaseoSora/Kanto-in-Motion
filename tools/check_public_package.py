#!/usr/bin/env python3
"""Fail if locally generated/user-supplied sprite assets slipped into a public tree."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
forbidden = []
for p in (root / "assets" / "battle" / "front-animated").rglob("*") if (root / "assets" / "battle" / "front-animated").exists() else []:
    if p.is_file(): forbidden.append(p)
for p in (root / "assets" / "title").rglob("*") if (root / "assets" / "title").exists() else []:
    if p.is_file(): forbidden.append(p)
for name in [*(f"animated_menu_sprites_gen{g}.lua" for g in (2,3,4,5)), "title_player_red.lua"]:
    p = root / "data" / name
    if p.is_file(): forbidden.append(p)
if forbidden:
    print("Public-package check FAILED. Remove locally imported/generated files:")
    for p in forbidden: print(" -", p.relative_to(root))
    sys.exit(1)
print("Public-package check OK: no local Pokemon-derived sprite/title payloads found.")
