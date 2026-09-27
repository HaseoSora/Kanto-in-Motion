#!/usr/bin/env python3
"""Convert Kanto in Motion HD Pokemon GIFs into PNG sprite sheets + Lua metadata.

Expected input names:
  <dex>-front-n.gif, <dex>-front-s.gif, <dex>-back-n.gif, <dex>-back-s.gif
Optional gender suffixes:
  ...-m.gif / ...-f.gif

The converter preserves each GIF's timing but scales each animation frame to a
configurable presentation size before packing. Kanto in Motion defaults to 60% of
the supplied HD GIF dimensions so the sprites fit the 1920x950 arenas naturally
and the installed asset pack stays substantially smaller. Sprite sheets are
palette-quantized PNGs with transparency and remain directly sliceable by
LÖVE/Gen1Recomp.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import io
import math
import os
import re
import shutil
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image

# Gen 1 National Dex lookup only (001-151). Gen 2 import support is intentionally disabled in this build.
DEX_KEYS = [
    'BULBASAUR',
    'IVYSAUR',
    'VENUSAUR',
    'CHARMANDER',
    'CHARMELEON',
    'CHARIZARD',
    'SQUIRTLE',
    'WARTORTLE',
    'BLASTOISE',
    'CATERPIE',
    'METAPOD',
    'BUTTERFREE',
    'WEEDLE',
    'KAKUNA',
    'BEEDRILL',
    'PIDGEY',
    'PIDGEOTTO',
    'PIDGEOT',
    'RATTATA',
    'RATICATE',
    'SPEAROW',
    'FEAROW',
    'EKANS',
    'ARBOK',
    'PIKACHU',
    'RAICHU',
    'SANDSHREW',
    'SANDSLASH',
    'NIDORAN_F',
    'NIDORINA',
    'NIDOQUEEN',
    'NIDORAN_M',
    'NIDORINO',
    'NIDOKING',
    'CLEFAIRY',
    'CLEFABLE',
    'VULPIX',
    'NINETALES',
    'JIGGLYPUFF',
    'WIGGLYTUFF',
    'ZUBAT',
    'GOLBAT',
    'ODDISH',
    'GLOOM',
    'VILEPLUME',
    'PARAS',
    'PARASECT',
    'VENONAT',
    'VENOMOTH',
    'DIGLETT',
    'DUGTRIO',
    'MEOWTH',
    'PERSIAN',
    'PSYDUCK',
    'GOLDUCK',
    'MANKEY',
    'PRIMEAPE',
    'GROWLITHE',
    'ARCANINE',
    'POLIWAG',
    'POLIWHIRL',
    'POLIWRATH',
    'ABRA',
    'KADABRA',
    'ALAKAZAM',
    'MACHOP',
    'MACHOKE',
    'MACHAMP',
    'BELLSPROUT',
    'WEEPINBELL',
    'VICTREEBEL',
    'TENTACOOL',
    'TENTACRUEL',
    'GEODUDE',
    'GRAVELER',
    'GOLEM',
    'PONYTA',
    'RAPIDASH',
    'SLOWPOKE',
    'SLOWBRO',
    'MAGNEMITE',
    'MAGNETON',
    'FARFETCHD',
    'DODUO',
    'DODRIO',
    'SEEL',
    'DEWGONG',
    'GRIMER',
    'MUK',
    'SHELLDER',
    'CLOYSTER',
    'GASTLY',
    'HAUNTER',
    'GENGAR',
    'ONIX',
    'DROWZEE',
    'HYPNO',
    'KRABBY',
    'KINGLER',
    'VOLTORB',
    'ELECTRODE',
    'EXEGGCUTE',
    'EXEGGUTOR',
    'CUBONE',
    'MAROWAK',
    'HITMONLEE',
    'HITMONCHAN',
    'LICKITUNG',
    'KOFFING',
    'WEEZING',
    'RHYHORN',
    'RHYDON',
    'CHANSEY',
    'TANGELA',
    'KANGASKHAN',
    'HORSEA',
    'SEADRA',
    'GOLDEEN',
    'SEAKING',
    'STARYU',
    'STARMIE',
    'MR_MIME',
    'SCYTHER',
    'JYNX',
    'ELECTABUZZ',
    'MAGMAR',
    'PINSIR',
    'TAUROS',
    'MAGIKARP',
    'GYARADOS',
    'LAPRAS',
    'DITTO',
    'EEVEE',
    'VAPOREON',
    'JOLTEON',
    'FLAREON',
    'PORYGON',
    'OMANYTE',
    'OMASTAR',
    'KABUTO',
    'KABUTOPS',
    'AERODACTYL',
    'SNORLAX',
    'ARTICUNO',
    'ZAPDOS',
    'MOLTRES',
    'DRATINI',
    'DRAGONAIR',
    'DRAGONITE',
    'MEWTWO',
    'MEW',
]

# Numeric battle-size reference from the accepted pre-HD KIM battler set.
# These dimensions are calibration data only; no legacy battle artwork is bundled.
REFERENCE_BATTLE_SIZE = [
    (37, 38, 33, 38),  # 001 BULBASAUR
    (58, 51, 57, 45),  # 002 IVYSAUR
    (86, 71, 89, 63),  # 003 VENUSAUR
    (42, 42, 43, 44),  # 004 CHARMANDER
    (69, 56, 67, 60),  # 005 CHARMELEON
    (89, 91, 98, 83),  # 006 CHARIZARD
    (39, 43, 40, 45),  # 007 SQUIRTLE
    (61, 57, 57, 62),  # 008 WARTORTLE
    (69, 65, 66, 66),  # 009 BLASTOISE
    (36, 37, 38, 35),  # 010 CATERPIE
    (36, 38, 42, 43),  # 011 METAPOD
    (62, 57, 64, 57),  # 012 BUTTERFREE
    (37, 46, 43, 46),  # 013 WEEDLE
    (32, 40, 32, 40),  # 014 KAKUNA
    (74, 69, 76, 67),  # 015 BEEDRILL
    (43, 48, 45, 47),  # 016 PIDGEY
    (82, 116, 95, 96),  # 017 PIDGEOTTO
    (58, 68, 68, 66),  # 018 PIDGEOT
    (43, 43, 58, 42),  # 019 RATTATA
    (65, 51, 66, 52),  # 020 RATICATE
    (33, 39, 35, 40),  # 021 SPEAROW
    (82, 105, 79, 112),  # 022 FEAROW
    (59, 46, 57, 49),  # 023 EKANS
    (81, 74, 86, 72),  # 024 ARBOK
    (50, 46, 41, 47),  # 025 PIKACHU
    (74, 73, 76, 72),  # 026 RAICHU
    (35, 39, 41, 38),  # 027 SANDSHREW
    (59, 53, 57, 52),  # 028 SANDSLASH
    (36, 34, 33, 36),  # 029 NIDORAN_F
    (52, 47, 52, 44),  # 030 NIDORINA
    (76, 69, 85, 72),  # 031 NIDOQUEEN
    (37, 37, 37, 43),  # 032 NIDORAN_M
    (52, 56, 55, 55),  # 033 NIDORINO
    (86, 71, 89, 69),  # 034 NIDOKING
    (47, 42, 54, 43),  # 035 CLEFAIRY
    (55, 52, 55, 51),  # 036 CLEFABLE
    (59, 49, 61, 52),  # 037 VULPIX
    (76, 73, 76, 64),  # 038 NINETALES
    (49, 45, 46, 48),  # 039 JIGGLYPUFF
    (49, 82, 47, 83),  # 040 WIGGLYTUFF
    (53, 46, 49, 59),  # 041 ZUBAT
    (111, 83, 95, 84),  # 042 GOLBAT
    (38, 50, 41, 51),  # 043 ODDISH
    (51, 45, 49, 46),  # 044 GLOOM
    (56, 50, 56, 48),  # 045 VILEPLUME
    (48, 38, 48, 32),  # 046 PARAS
    (62, 63, 70, 52),  # 047 PARASECT
    (42, 53, 42, 52),  # 048 VENONAT
    (75, 74, 83, 73),  # 049 VENOMOTH
    (38, 31, 38, 32),  # 050 DIGLETT
    (52, 41, 52, 42),  # 051 DUGTRIO
    (48, 65, 58, 64),  # 052 MEOWTH
    (73, 62, 78, 56),  # 053 PERSIAN
    (38, 46, 37, 44),  # 054 PSYDUCK
    (60, 59, 55, 57),  # 055 GOLDUCK
    (66, 61, 62, 59),  # 056 MANKEY
    (66, 60, 72, 58),  # 057 PRIMEAPE
    (55, 52, 57, 57),  # 058 GROWLITHE
    (77, 69, 86, 69),  # 059 ARCANINE
    (54, 34, 55, 35),  # 060 POLIWAG
    (74, 55, 80, 57),  # 061 POLIWHIRL
    (81, 58, 74, 57),  # 062 POLIWRATH
    (63, 53, 71, 56),  # 063 ABRA
    (79, 60, 80, 66),  # 064 KADABRA
    (93, 70, 82, 67),  # 065 ALAKAZAM
    (51, 50, 53, 51),  # 066 MACHOP
    (60, 71, 61, 71),  # 067 MACHOKE
    (64, 76, 67, 76),  # 068 MACHAMP
    (41, 44, 45, 51),  # 069 BELLSPROUT
    (69, 51, 72, 54),  # 070 WEEPINBELL
    (65, 71, 69, 70),  # 071 VICTREEBEL
    (60, 71, 62, 76),  # 072 TENTACOOL
    (84, 84, 84, 85),  # 073 TENTACRUEL
    (61, 45, 58, 51),  # 074 GEODUDE
    (71, 44, 65, 43),  # 075 GRAVELER
    (72, 57, 69, 56),  # 076 GOLEM
    (57, 57, 59, 59),  # 077 PONYTA
    (74, 73, 76, 76),  # 078 RAPIDASH
    (64, 53, 68, 50),  # 079 SLOWPOKE
    (63, 60, 76, 58),  # 080 SLOWBRO
    (38, 32, 36, 31),  # 081 MAGNEMITE
    (68, 59, 73, 58),  # 082 MAGNETON
    (45, 48, 46, 50),  # 083 FARFETCHD
    (60, 53, 61, 56),  # 084 DODUO
    (70, 76, 72, 76),  # 085 DODRIO
    (62, 47, 60, 43),  # 086 SEEL
    (75, 74, 77, 88),  # 087 DEWGONG
    (73, 42, 70, 46),  # 088 GRIMER
    (94, 68, 100, 81),  # 089 MUK
    (42, 38, 48, 37),  # 090 SHELLDER
    (74, 65, 69, 68),  # 091 CLOYSTER
    (67, 75, 63, 78),  # 092 GASTLY
    (85, 70, 90, 71),  # 093 HAUNTER
    (79, 65, 73, 64),  # 094 GENGAR
    (74, 74, 98, 70),  # 095 ONIX
    (53, 58, 56, 56),  # 096 DROWZEE
    (66, 62, 65, 60),  # 097 HYPNO
    (55, 39, 55, 43),  # 098 KRABBY
    (82, 59, 83, 62),  # 099 KINGLER
    (46, 31, 47, 31),  # 100 VOLTORB
    (49, 52, 49, 52),  # 101 ELECTRODE
    (55, 44, 54, 40),  # 102 EXEGGCUTE
    (79, 73, 76, 70),  # 103 EXEGGUTOR
    (49, 43, 52, 41),  # 104 CUBONE
    (68, 59, 65, 53),  # 105 MAROWAK
    (68, 78, 62, 75),  # 106 HITMONLEE
    (34, 59, 46, 56),  # 107 HITMONCHAN
    (69, 52, 77, 53),  # 108 LICKITUNG
    (91, 59, 79, 64),  # 109 KOFFING
    (86, 67, 87, 68),  # 110 WEEZING
    (68, 54, 73, 54),  # 111 RHYHORN
    (78, 67, 85, 68),  # 112 RHYDON
    (61, 47, 67, 47),  # 113 CHANSEY
    (49, 42, 49, 42),  # 114 TANGELA
    (79, 61, 73, 66),  # 115 KANGASKHAN
    (34, 43, 39, 40),  # 116 HORSEA
    (58, 56, 64, 59),  # 117 SEADRA
    (75, 57, 75, 58),  # 118 GOLDEEN
    (74, 66, 96, 72),  # 119 SEAKING
    (57, 49, 55, 52),  # 120 STARYU
    (65, 59, 56, 56),  # 121 STARMIE
    (57, 53, 55, 51),  # 122 MR_MIME
    (55, 61, 69, 65),  # 123 SCYTHER
    (63, 60, 62, 60),  # 124 JYNX
    (71, 65, 71, 63),  # 125 ELECTABUZZ
    (73, 61, 70, 59),  # 126 MAGMAR
    (72, 62, 70, 61),  # 127 PINSIR
    (76, 59, 72, 54),  # 128 TAUROS
    (47, 63, 66, 58),  # 129 MAGIKARP
    (102, 84, 108, 82),  # 130 GYARADOS
    (68, 71, 76, 71),  # 131 LAPRAS
    (47, 32, 47, 32),  # 132 DITTO
    (49, 47, 49, 50),  # 133 EEVEE
    (50, 59, 50, 56),  # 134 VAPOREON
    (48, 49, 49, 48),  # 135 JOLTEON
    (66, 60, 70, 59),  # 136 FLAREON
    (56, 52, 62, 47),  # 137 PORYGON
    (43, 45, 48, 48),  # 138 OMANYTE
    (63, 60, 65, 63),  # 139 OMASTAR
    (39, 41, 38, 42),  # 140 KABUTO
    (65, 61, 67, 55),  # 141 KABUTOPS
    (93, 81, 91, 91),  # 142 AERODACTYL
    (75, 74, 75, 71),  # 143 SNORLAX
    (72, 81, 78, 87),  # 144 ARTICUNO
    (97, 71, 85, 73),  # 145 ZAPDOS
    (129, 98, 117, 79),  # 146 MOLTRES
    (44, 51, 47, 57),  # 147 DRATINI
    (65, 74, 64, 74),  # 148 DRAGONAIR
    (80, 82, 86, 81),  # 149 DRAGONITE
    (90, 69, 95, 70),  # 150 MEWTWO
    (78, 54, 60, 60),  # 151 MEW
]

NAME_RE = re.compile(
    r"^(?P<dex>\d+)-(?P<side>front|back)-(?P<color>[ns])(?:-(?P<gender>[fm]))?\.gif$",
    re.IGNORECASE,
)

@dataclass(frozen=True)
class SourceGif:
    source: Path
    member: str | None
    name: str

    def read_bytes(self) -> bytes:
        if self.member is None:
            return self.source.read_bytes()
        with zipfile.ZipFile(self.source) as zf:
            return zf.read(self.member)


def iter_source(path: Path) -> Iterable[SourceGif]:
    if path.is_dir():
        for p in sorted(path.rglob("*.gif")):
            yield SourceGif(p, None, p.name)
        return
    if not path.is_file() or not zipfile.is_zipfile(path):
        raise ValueError(f"Not a GIF folder or ZIP archive: {path}")
    with zipfile.ZipFile(path) as zf:
        for member in sorted(zf.namelist()):
            if member.lower().endswith(".gif"):
                yield SourceGif(path, member, Path(member).name)


def choose_grid(frame_count: int, width: int, height: int, max_texture: int) -> tuple[int, int]:
    max_cols = min(frame_count, max_texture // width)
    max_rows = max_texture // height
    if max_cols < 1 or max_rows < 1:
        raise ValueError(
            f"single frame {width}x{height} exceeds max texture size {max_texture}"
        )
    min_cols = max(1, math.ceil(frame_count / max_rows))
    if min_cols > max_cols:
        raise ValueError(
            f"{frame_count} frames of {width}x{height} cannot fit inside {max_texture}x{max_texture}"
        )
    best = None
    for cols in range(min_cols, max_cols + 1):
        rows = math.ceil(frame_count / cols)
        sw, sh = cols * width, rows * height
        if sw > max_texture or sh > max_texture:
            continue
        # Favor compact, roughly square sheets; tie-break toward fewer columns.
        score = (max(sw, sh), abs(sw - sh), sw * sh, cols)
        if best is None or score < best[0]:
            best = (score, cols, rows)
    if best is None:
        raise ValueError("no valid sprite-sheet grid found")
    return best[1], best[2]



def display_scale(dex: int, side: str, meta: dict) -> float:
    """Return the accepted HD sample-test visual scale for one frame.

    Sprite-sheet frames remain physically reduced to 60% for package size.
    This species-relative scale recreates the approved in-game silhouette size
    from the last test build. Player backs retain that test's independent 1.25
    battle-side baseline. Meowth keeps its explicitly approved sample override.
    """
    if not (1 <= dex <= len(REFERENCE_BATTLE_SIZE)):
        return 1.0
    fw, fh, bw, bh = REFERENCE_BATTLE_SIZE[dex - 1]
    w = max(1, int(meta["width"]))
    h = max(1, int(meta["height"]))
    if side == "front":
        value = min(fw / w, fh / h) * 1.15
        if dex == 52:
            value = 0.195811 * min(148 / w, 186 / h)
    else:
        value = min(bw / w, bh / h) * 1.15 * 1.25
        if dex == 52:
            value = 0.261789 * min(205 / w, 246 / h)
    return float(value)

def gif_to_sheet(data: bytes, out_path: Path, max_texture: int, scale: float = 0.60, compress_level: int = 6) -> dict:
    im = Image.open(io.BytesIO(data))
    frames = int(getattr(im, "n_frames", 1) or 1)
    source_width, source_height = im.size
    width = max(1, int(round(source_width * scale)))
    height = max(1, int(round(source_height * scale)))
    cols, rows = choose_grid(frames, width, height, max_texture)
    sheet = Image.new("RGBA", (cols * width, rows * height), (0, 0, 0, 0))
    durations: list[int] = []
    for i in range(frames):
        im.seek(i)
        frame = im.convert("RGBA")
        if frame.size != (width, height):
            frame = frame.resize((width, height), Image.Resampling.LANCZOS)
        x = (i % cols) * width
        y = (i // cols) * height
        sheet.alpha_composite(frame, (x, y))
        duration = int(im.info.get("duration") or 50)
        durations.append(max(1, duration))

    # GIF art is palette-oriented. FASTOCTREE preserves RGBA transparency while
    # avoiding the 4-8x size increase of raw RGBA PNG sprite sheets.
    sheet = sheet.quantize(
        colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # PNG optimizer passes are extremely expensive on these large atlases and
    # only save a few percent. Standard DEFLATE keeps conversion practical while
    # retaining the same pixels/palette.
    sheet.save(out_path, format="PNG", optimize=False, compress_level=compress_level)
    return {
        "width": width,
        "height": height,
        "columns": cols,
        "frames": frames,
        "durations": durations,
    }


def _convert_job(job: tuple, max_texture: int, scale: float, compress_level: int) -> tuple:
    dex, side, color, gender, item, out, rel = job
    data = item.read_bytes()
    meta = gif_to_sheet(data, out, max_texture, scale, compress_level)
    meta["image"] = rel.as_posix()
    meta["displayScale"] = display_scale(dex, side, meta)
    meta["hdTest"] = True
    return dex, side, color, gender, item.name, meta


def lua_record(image: str, meta: dict) -> str:
    durations = ",".join(str(v) for v in meta["durations"])
    return (
        "{ image = %r, width = %d, height = %d, columns = %d, frames = %d, durations = {%s}, displayScale = %.6f, hdTest = true }"
        % (
            image,
            meta["width"],
            meta["height"],
            meta["columns"],
            meta["frames"],
            durations,
            float(meta.get("displayScale", 1.0)),
        )
    ).replace("'", '"')


def write_metadata(path: Path, records: dict[int, dict]) -> None:
    lines = [
        "-- Generated by tools/import_hd_pokemon.py. Do not hand-edit.",
        "-- 60%-scale HD front/back animated Pokemon, normal + shiny.",
        "-- displayScale preserves the accepted HD sample-test battle sizing.",
        "return {",
    ]
    for dex in sorted(records):
        if not (1 <= dex <= len(DEX_KEYS)):
            continue
        key = DEX_KEYS[dex - 1]
        species = records[dex]
        lines.append(f"  {key} = {{")
        lines.append(f"    dex = {dex},")
        for side in ("front", "back"):
            side_rec = species.get(side)
            if not side_rec:
                continue
            lines.append(f"    {side} = {{")
            for color_name in ("normal", "shiny"):
                color_rec = side_rec.get(color_name)
                if not color_rec:
                    continue
                lines.append(f"      {color_name} = {{")
                for gender in ("default", "male", "female"):
                    rec = color_rec.get(gender)
                    if rec:
                        lines.append(f"        {gender} = {lua_record(rec['image'], rec)},")
                lines.append("      },")
            lines.append("    },")
        lines.append("  },")
    lines.append("}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def output_png_is_valid(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size <= 0:
        return False
    try:
        with Image.open(path) as im:
            im.verify()
        return True
    except Exception:
        try:
            path.unlink()
        except OSError:
            pass
        return False


def gif_metadata(data: bytes, image_path: str, max_texture: int, scale: float = 0.60) -> dict:
    im = Image.open(io.BytesIO(data))
    frame_count = int(getattr(im, "n_frames", 1) or 1)
    source_w, source_h = im.size
    w = max(1, int(round(source_w * scale)))
    h = max(1, int(round(source_h * scale)))
    cols, _ = choose_grid(frame_count, w, h, max_texture)
    durations = []
    for i in range(frame_count):
        im.seek(i)
        durations.append(max(1, int(im.info.get("duration") or 50)))
    return {
        "width": w, "height": h, "columns": cols, "frames": frame_count,
        "durations": durations, "image": image_path,
    }


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Convert Gen 1 HD Pokemon GIFs into Kanto in Motion sprite sheets."
    )
    ap.add_argument("sources", nargs="+", type=Path, help="GIF folders or ZIP archives")
    ap.add_argument(
        "--target",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Kanto in Motion mod folder (default: parent of tools folder)",
    )
    ap.add_argument("--clean", action="store_true", help="Remove existing HD sprite output first")
    ap.add_argument("--max-dex", type=int, default=151, help="Highest National Dex number to import (maximum/default: 151 / Gen 1)")
    ap.add_argument("--force", action="store_true", help="Rebuild sprite sheets even when a valid output PNG already exists")
    ap.add_argument("--metadata-only", action="store_true", help="Generate metadata without writing PNG sheets")
    ap.add_argument("--max-texture", type=int, default=8192, help="Maximum atlas dimension (default: 8192)")
    ap.add_argument("--scale", type=float, default=0.60, help="Frame-size multiplier before atlas packing (default: 0.60 / 60%%)")
    ap.add_argument("--workers", type=int, default=min(8, os.cpu_count() or 1), help="Parallel conversion workers (default: up to 8)")
    ap.add_argument("--compress-level", type=int, choices=range(0, 10), default=6, metavar="0-9", help="PNG compression level (default: 6; 9 is smaller but much slower)")
    args = ap.parse_args()

    if not (0.10 <= args.scale <= 1.00):
        ap.error("--scale must be between 0.10 and 1.00")

    target = args.target.resolve()
    if not (target / "manifest.json").is_file() and not args.metadata_only:
        ap.error(f"target does not look like a Kanto in Motion mod folder: {target}")

    asset_root = target / "assets" / "battle" / "hd-pokemon"
    metadata_path = target / "data" / "hd_pokemon_sprites.lua"
    if args.clean:
        shutil.rmtree(asset_root, ignore_errors=True)
        try:
            metadata_path.unlink()
        except FileNotFoundError:
            pass

    found: dict[tuple[int, str, str, str], SourceGif] = {}
    for source_path in args.sources:
        for item in iter_source(source_path.resolve()):
            m = NAME_RE.match(item.name)
            if not m:
                continue
            dex = int(m.group("dex"))
            if not (1 <= dex <= min(len(DEX_KEYS), args.max_dex)):
                continue
            side = m.group("side").lower()
            color = "normal" if m.group("color").lower() == "n" else "shiny"
            gender_raw = (m.group("gender") or "").lower()
            gender = "male" if gender_raw == "m" else "female" if gender_raw == "f" else "default"
            key = (dex, side, color, gender)
            if key in found:
                raise RuntimeError(f"duplicate asset for {key}: {found[key].name} and {item.name}")
            found[key] = item

    if not found:
        raise RuntimeError("no matching HD Pokemon GIFs found")

    records: dict[int, dict] = {}
    total = len(found)

    if args.metadata_only:
        for index, ((dex, side, color, gender), item) in enumerate(sorted(found.items()), 1):
            suffix = "" if gender == "default" else "-m" if gender == "male" else "-f"
            rel = Path("assets") / "battle" / "hd-pokemon" / side / color / f"{dex:03d}{suffix}.png"
            data = item.read_bytes()
            im = Image.open(io.BytesIO(data))
            frame_count = int(getattr(im, "n_frames", 1) or 1)
            source_w, source_h = im.size
            w = max(1, int(round(source_w * args.scale)))
            h = max(1, int(round(source_h * args.scale)))
            cols, _ = choose_grid(frame_count, w, h, args.max_texture)
            duration = max(1, int(im.info.get("duration") or 50))
            meta = {"width": w, "height": h, "columns": cols, "frames": frame_count, "durations": [duration] * frame_count, "image": rel.as_posix()}
            meta["displayScale"] = display_scale(dex, side, meta)
            meta["hdTest"] = True
            species = records.setdefault(dex, {})
            species.setdefault(side, {}).setdefault(color, {})[gender] = meta
            if index % 100 == 0 or index == total:
                print(f"[{index:4d}/{total}] metadata", flush=True)
    else:
        jobs = []
        reused = 0
        for (dex, side, color, gender), item in sorted(found.items()):
            suffix = "" if gender == "default" else "-m" if gender == "male" else "-f"
            rel = Path("assets") / "battle" / "hd-pokemon" / side / color / f"{dex:03d}{suffix}.png"
            out = target / rel
            if not args.force and output_png_is_valid(out):
                meta = gif_metadata(item.read_bytes(), rel.as_posix(), args.max_texture, args.scale)
                meta["displayScale"] = display_scale(dex, side, meta)
                meta["hdTest"] = True
                species = records.setdefault(dex, {})
                species.setdefault(side, {}).setdefault(color, {})[gender] = meta
                reused += 1
            else:
                jobs.append((dex, side, color, gender, item, out, rel))

        if reused:
            print(f"Reusing {reused} validated sprite sheets; converting {len(jobs)} remaining GIFs.", flush=True)

        workers = max(1, int(args.workers))
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [pool.submit(_convert_job, job, args.max_texture, args.scale, args.compress_level) for job in jobs]
            for index, fut in enumerate(concurrent.futures.as_completed(futures), 1):
                dex, side, color, gender, name, meta = fut.result()
                species = records.setdefault(dex, {})
                species.setdefault(side, {}).setdefault(color, {})[gender] = meta
                if index % 25 == 0 or index == len(jobs):
                    print(f"[{index:4d}/{len(jobs)}] {name}", flush=True)

    write_metadata(metadata_path, records)

    missing_core = []
    for dex in range(1, min(len(DEX_KEYS), args.max_dex) + 1):
        species = records.get(dex, {})
        for side in ("front", "back"):
            for color in ("normal", "shiny"):
                variants = species.get(side, {}).get(color, {})
                if not variants:
                    missing_core.append(f"{dex:03d} {side} {color}")
    print(f"\nGenerated metadata for {len(records)} species from {total} GIFs.")
    if missing_core:
        print(f"Warning: {len(missing_core)} required side/color groups are missing.")
        for item in missing_core[:20]:
            print("  -", item)
        if len(missing_core) > 20:
            print(f"  ... {len(missing_core)-20} more")
    else:
        print(f"Coverage: all {min(len(DEX_KEYS), args.max_dex)} active species have front/back normal+shiny groups.")
    print(f"Metadata: {metadata_path}")
    if not args.metadata_only:
        print(f"Sprites:  {asset_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
