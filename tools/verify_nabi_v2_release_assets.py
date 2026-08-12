#!/usr/bin/env python3
"""Verify the Nabi v2 release contract and optional Flutter APK contents.

Run after ``generate_nabi_v2_assets.py validate``. This checker adds the
release-specific guarantees that the asset generator deliberately does not
own: the pubspec must bundle v2 only, all physical paths must be lowercase,
and an APK (when supplied) must contain v2 runtime files but no v1 package.
"""

from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STATIC_ROOT = ROOT / "assets/images/nabi_v2"
SPRITE_ROOT = ROOT / "assets/nabi_v2"
CATALOG_ROOT = ROOT / "assets/config/nabi_v2"


class ContractError(RuntimeError):
    """Raised when an immutable Nabi v2 release contract is broken."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def png_files(directory: Path) -> list[Path]:
    return sorted(path for path in directory.rglob("*.png") if path.is_file())


def verify_lowercase_paths() -> None:
    for root in (STATIC_ROOT, SPRITE_ROOT, CATALOG_ROOT):
        for path in root.rglob("*"):
            relative = path.relative_to(ROOT).as_posix()
            require(
                relative == relative.lower(),
                f"Nabi v2 physical path is not lowercase: {relative}",
            )


def verify_generated_contract() -> dict[str, int]:
    manifest = json.loads(
        (CATALOG_ROOT / "nabi_v2_asset_manifest.json").read_text(
            encoding="utf-8"
        )
    )
    static_assets = manifest["assets"]
    require(len(static_assets) == 84, "Expected 84 v2 static manifest assets")
    for asset in static_assets:
        relative = asset["path"]
        require(relative == relative.lower(), f"Static manifest path is not lowercase: {relative}")
        require((STATIC_ROOT / relative).is_file(), f"Missing static asset: {relative}")

    expression_map = json.loads(
        (CATALOG_ROOT / "nabi_v2_expression_map.json").read_text(
            encoding="utf-8"
        )
    )
    expressions = expression_map["expressions"]
    require(len(expressions) == 10, "Expected 10 Nabi v2 expressions")
    for expression in expressions:
        relative = expression["path"]
        require(relative == relative.lower(), f"Expression path is not lowercase: {relative}")
        require((SPRITE_ROOT / relative).is_file(), f"Missing expression: {relative}")

    motion_map = json.loads(
        (CATALOG_ROOT / "nabi_v2_motion_map.json").read_text(encoding="utf-8")
    )
    animations = motion_map["animations"]
    require(len(animations) == 30, "Expected 30 Nabi v2 animation sequences")
    for animation in animations:
        frame_directory = SPRITE_ROOT / animation["frames_path"]
        frames = sorted(frame_directory.glob("frame_*.png"))
        require(
            len(frames) == 30,
            f"Expected 30 frames for {animation['id']}, found {len(frames)}",
        )
        require(
            frames[0].name == "frame_0001.png" and frames[-1].name == "frame_0030.png",
            f"Unexpected frame naming for {animation['id']}",
        )

    effect_directories = [
        path
        for path in (SPRITE_ROOT / "03_effects/01_png_frames").iterdir()
        if path.is_dir()
    ]
    require(len(effect_directories) == 7, "Expected 7 Nabi v2 effect sequences")
    for directory in effect_directories:
        require(
            len(png_files(directory)) == 30,
            f"Expected 30 frames for effect {directory.name}",
        )

    require(
        len(png_files(SPRITE_ROOT / "02_spritesheets")) == 30,
        "Expected 30 character spritesheets",
    )
    require(
        len(png_files(SPRITE_ROOT / "03_effects/02_spritesheets")) == 7,
        "Expected 7 effect spritesheets",
    )
    require(
        len(png_files(SPRITE_ROOT / "07_previews")) >= 4,
        "Expected generated Nabi v2 contact sheets",
    )
    verify_lowercase_paths()
    return {
        "static": len(static_assets),
        "expressions": len(expressions),
        "frames": len(animations) * 30,
        "effects": len(effect_directories) * 30,
    }


def verify_pubspec() -> None:
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    required = (
        "    - assets/images/nabi_v2/",
        "    - assets/config/nabi_v2/",
        "    - assets/nabi_v2/01_character/01_static_expressions/",
        "    - assets/nabi_v2/01_character/02_30fps_frames/",
    )
    for entry in required:
        require(entry in pubspec, f"Missing v2 runtime asset declaration: {entry.strip()}")

    forbidden = (
        "    - assets/images/nabi/",
        "    - assets/config/nabi/",
        "    - assets/nabi/",
    )
    for entry in forbidden:
        require(entry not in pubspec, f"V1 asset bundle remains declared: {entry.strip()}")


def verify_apk(apk: Path, counts: dict[str, int]) -> None:
    require(apk.is_file(), f"APK does not exist: {apk}")
    with zipfile.ZipFile(apk) as archive:
        entries = archive.namelist()

    v2_static_prefix = "assets/flutter_assets/assets/images/nabi_v2/"
    v2_frame_prefix = (
        "assets/flutter_assets/assets/nabi_v2/01_character/02_30fps_frames/"
    )
    v1_prefixes = (
        "assets/flutter_assets/assets/images/nabi/",
        "assets/flutter_assets/assets/nabi/",
    )
    v2_static = [entry for entry in entries if entry.startswith(v2_static_prefix)]
    v2_frames = [entry for entry in entries if entry.startswith(v2_frame_prefix)]
    require(len(v2_static) == counts["static"], "APK has an incomplete v2 static bundle")
    require(len(v2_frames) == counts["frames"], "APK has an incomplete v2 frame bundle")
    for prefix in v1_prefixes:
        require(
            not any(entry.startswith(prefix) for entry in entries),
            f"APK still contains the v1 Nabi bundle: {prefix}",
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, help="Optional Flutter APK to inspect")
    args = parser.parse_args()
    try:
        counts = verify_generated_contract()
        verify_pubspec()
        if args.apk:
            verify_apk(args.apk.resolve(), counts)
    except (ContractError, KeyError, OSError, json.JSONDecodeError) as error:
        print(f"Nabi v2 release verification: FAIL\n- {error}", file=sys.stderr)
        return 1

    summary = ", ".join(f"{key}={value}" for key, value in counts.items())
    apk_suffix = " + APK" if args.apk else ""
    print(f"Nabi v2 release verification: PASS ({summary}{apk_suffix})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
