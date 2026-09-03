#!/usr/bin/env python3
"""Local asset importer for Kanto in Motion.

Public Kanto in Motion releases intentionally do not ship Pokemon-derived
sprite artwork. This tool copies compatible animation atlases/metadata from a
user-supplied folder or ZIP into the local mod installation. It recognizes the
common Battle Art animated-front layout as well as legacy Kanto in Motion /
Animated Menu Pokemon layouts; no provider-enabled or custom Battle Art build
is required at runtime.

Nothing is downloaded and no source file is modified.
"""
from __future__ import annotations

import argparse
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

GENERATIONS = ("gen2", "gen3", "gen4", "gen5")


def find_root(base: Path) -> Path:
    """Find the extracted directory that contains manifest.json/main.lua."""
    if (base / "manifest.json").is_file() or (base / "main.lua").is_file():
        return base
    candidates = []
    for p in base.rglob("manifest.json"):
        if p.parent.is_dir():
            candidates.append(p.parent)
    if len(candidates) == 1:
        return candidates[0]
    if candidates:
        # Prefer a root that also has the expected animated sprite data.
        for c in candidates:
            if any((c / "data" / f"animated_battle_sprites_{g}.lua").is_file() for g in GENERATIONS):
                return c
            if any((c / "data" / f"animated_menu_sprites_{g}.lua").is_file() for g in GENERATIONS):
                return c
        return candidates[0]
    return base


def open_source(path: Path):
    if path.is_dir():
        return find_root(path), None
    if not path.is_file():
        raise FileNotFoundError(path)
    if not zipfile.is_zipfile(path):
        raise ValueError(f"Not a directory or ZIP archive: {path}")
    tmp = tempfile.TemporaryDirectory(prefix="kanto-in-motion-import-")
    with zipfile.ZipFile(path) as zf:
        zf.extractall(tmp.name)
    return find_root(Path(tmp.name)), tmp


def copy_file(src: Path, dst: Path) -> bool:
    if not src.is_file():
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return True


def copy_tree(src: Path, dst: Path) -> int:
    if not src.is_dir():
        return 0
    count = 0
    for p in src.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(src)
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, out)
        count += 1
    return count


def detect_kind(root: Path) -> str:
    if any((root / "data" / f"animated_battle_sprites_{g}.lua").is_file() for g in GENERATIONS):
        return "battle_art"
    if any((root / "data" / f"animated_menu_sprites_{g}.lua").is_file() for g in GENERATIONS):
        return "legacy_kim"
    return "unknown"


def import_sprite_sets(root: Path, target: Path, kind: str) -> tuple[int, list[str]]:
    copied = 0
    notes: list[str] = []
    for gen in GENERATIONS:
        if kind == "battle_art":
            meta = root / "data" / f"animated_battle_sprites_{gen}.lua"
            shiny_meta = root / "data" / f"animated_battle_sprites_{gen}_shiny.lua"
        else:
            meta = root / "data" / f"animated_menu_sprites_{gen}.lua"
            shiny_meta = root / "data" / f"animated_menu_sprites_{gen}_shiny.lua"
        if copy_file(meta, target / "data" / f"animated_menu_sprites_{gen}.lua"):
            copied += 1
        else:
            notes.append(f"missing metadata: {meta.name}")
        # Shiny atlases can have different frame grids from their normal
        # counterparts. Copy dedicated shiny metadata when the source has it.
        if copy_file(shiny_meta, target / "data" / f"animated_menu_sprites_{gen}_shiny.lua"):
            copied += 1

        src_assets = root / "assets" / "battle" / "front-animated" / gen
        dst_assets = target / "assets" / "battle" / "front-animated" / gen
        n = copy_tree(src_assets, dst_assets)
        copied += n
        if n == 0:
            notes.append(f"missing sprite folder: assets/battle/front-animated/{gen}")
    return copied, notes


def import_title_extras(root: Path, target: Path) -> tuple[int, list[str]]:
    copied = 0
    notes: list[str] = []
    title_data = root / "data" / "title_player_red.lua"
    if copy_file(title_data, target / "data" / "title_player_red.lua"):
        copied += 1
    else:
        notes.append("no title-player metadata found")

    for name in ("red_title.png", "gen1recomppp_logo.png"):
        if copy_file(root / "assets" / "title" / name, target / "assets" / "title" / name):
            copied += 1
        else:
            notes.append(f"no title asset found: {name}")
    return copied, notes


def clean_generated(target: Path) -> None:
    shutil.rmtree(target / "assets" / "battle" / "front-animated", ignore_errors=True)
    shutil.rmtree(target / "assets" / "title", ignore_errors=True)
    for gen in GENERATIONS:
        for suffix in ("", "_shiny"):
            try:
                (target / "data" / f"animated_menu_sprites_{gen}{suffix}.lua").unlink()
            except FileNotFoundError:
                pass
    try:
        (target / "data" / "title_player_red.lua").unlink()
    except FileNotFoundError:
        pass


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Import local animated sprite assets into Kanto in Motion."
    )
    ap.add_argument("source", type=Path,
                    help="compatible animated-sprite source folder or ZIP")
    ap.add_argument("--target", type=Path,
                    default=Path(__file__).resolve().parents[1],
                    help="Kanto in Motion mod folder (default: parent of this tools folder)")
    ap.add_argument("--title-source", type=Path,
                    help="Optional legacy Kanto in Motion/Animated Menu Pokemon folder or ZIP for Red/logo title extras")
    ap.add_argument("--clean", action="store_true",
                    help="Remove previously imported/generated assets before importing")
    args = ap.parse_args()

    target = args.target.resolve()
    if not (target / "manifest.json").is_file():
        ap.error(f"target does not look like a Kanto in Motion mod folder: {target}")
    if args.clean:
        clean_generated(target)

    tmps = []
    try:
        root, tmp = open_source(args.source.resolve())
        if tmp: tmps.append(tmp)
        kind = detect_kind(root)
        if kind == "unknown":
            raise RuntimeError(
                "source does not contain compatible animated_menu_sprites_* or animated_battle_sprites_* data"
            )
        copied, notes = import_sprite_sets(root, target, kind)
        print(f"Sprite source: {kind} ({root})")
        print(f"Copied {copied} sprite/metadata files.")

        title_root = None
        if args.title_source:
            title_root, tmp2 = open_source(args.title_source.resolve())
            if tmp2: tmps.append(tmp2)
        elif kind == "legacy_kim":
            title_root = root

        if title_root:
            n, title_notes = import_title_extras(title_root, target)
            copied += n
            print(f"Copied {n} title-extra files.")
            notes.extend(title_notes)
        else:
            notes.append(
                "The selected sprite source does not include Kanto in Motion's custom title Red/logo files; "
                "use --title-source with your own compatible legacy package if you want those extras."
            )

        if notes:
            print("\nNotes:")
            for note in notes:
                print(f"  - {note}")

        print("\nImport complete.")
        print("Keep these generated files local; .gitignore is configured so they are not published.")
        return 0
    finally:
        for tmp in tmps:
            tmp.cleanup()


if __name__ == "__main__":
    raise SystemExit(main())
