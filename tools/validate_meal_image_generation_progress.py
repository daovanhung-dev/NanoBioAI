#!/usr/bin/env python3
"""Validate per-recipe generated meal-image progress and asset linkage."""

from __future__ import annotations

import hashlib
import json
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/data/nabi_3000_mon_viet_moi.json"
MANIFEST = ROOT / "docs/meal_catalog/image_generation_progress_v1.json"
ASSET_DIR = "assets/images/meals/catalog_v1"
ALLOWED_STATUSES = {"not_started", "generated_needs_review", "verified", "rejected"}
IMAGE_STATUSES_WITH_FILES = {"generated_needs_review", "verified"}


class ValidationError(Exception):
    """Raised when catalog, progress, or generated assets disagree."""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def main() -> int:
    try:
        source_bytes = SOURCE.read_bytes()
        source = json.loads(source_bytes)
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        recipes = source["recipes"]
        records = manifest["items"]

        require(len(recipes) == 3000, f"expected 3000 source recipes, got {len(recipes)}")
        require(manifest.get("source_catalog") == SOURCE.relative_to(ROOT).as_posix(), "source catalog path mismatch")
        require(manifest.get("source_catalog_sha256") == hashlib.sha256(source_bytes).hexdigest(), "source catalog hash mismatch")
        require(len(records) == len(recipes), f"manifest has {len(records)} records for {len(recipes)} recipes")
        require(manifest.get("asset_directory") == ASSET_DIR, "asset directory mismatch")
        pubspec_assets = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        require(
            "    - assets/images/meals/catalog_v1/" in pubspec_assets,
            "catalog image directory is not bundled by pubspec",
        )

        source_by_code = {recipe["code"]: recipe for recipe in recipes}
        require(len(source_by_code) == len(recipes), "source recipe codes are not unique")
        counts = {status: 0 for status in ALLOWED_STATUSES}
        content_hashes: dict[str, str] = {}
        referenced_paths: set[str] = set()

        for record in records:
            code = record.get("code")
            require(code in source_by_code, f"unknown recipe code in manifest: {code}")
            source_recipe = source_by_code[code]
            require(record.get("meal_name") == source_recipe.get("meal_name"), f"meal name mismatch for {code}")
            require(record.get("source_hash") == source_recipe.get("source_hash"), f"source hash mismatch for {code}")
            status = record.get("status")
            require(status in ALLOWED_STATUSES, f"invalid image status for {code}: {status}")
            counts[status] += 1

            target_rel = f"{ASSET_DIR}/{code}.png"
            target = ROOT / target_rel
            image_path = record.get("image_asset_path")
            image_hash = record.get("image_sha256")

            if status in IMAGE_STATUSES_WITH_FILES:
                require(image_path == target_rel, f"image path must be code-keyed for {code}")
                require(target.is_file() and target.stat().st_size > 0, f"image file missing or empty for {code}: {target_rel}")
                actual_hash = sha256(target)
                require(image_hash == actual_hash, f"image hash mismatch for {code}")
                require(actual_hash not in content_hashes, f"duplicate image bytes for {code} and {content_hashes.get(actual_hash)}")
                content_hashes[actual_hash] = code
                referenced_paths.add(target_rel)
                require(isinstance(record.get("visual_review"), str) and record["visual_review"].strip(), f"visual review note missing for {code}")
                with target.open("rb") as stream:
                    header = stream.read(24)
                require(header[:8] == b"\x89PNG\r\n\x1a\n", f"invalid PNG signature for {code}")
                width, height = struct.unpack(">II", header[16:24])
                require(width > 0 and height > 0, f"invalid PNG dimensions for {code}")
            else:
                require(image_path is None and image_hash is None, f"non-final status has image path/hash for {code}")

        require(records == sorted(records, key=lambda item: list(source_by_code).index(item["code"])), "manifest order differs from source catalog")
        require(manifest.get("counts") == {
            "total": len(records),
            "verified": counts["verified"],
            "generated_needs_review": counts["generated_needs_review"],
            "rejected": counts["rejected"],
            "not_started": counts["not_started"],
        }, "manifest counts do not match per-item statuses")

        image_dir = ROOT / ASSET_DIR
        extras = [
            path.relative_to(ROOT).as_posix()
            for path in image_dir.iterdir()
            if path.is_file() and path.suffix.lower() in {".png", ".webp", ".jpg", ".jpeg"}
            and path.relative_to(ROOT).as_posix() not in referenced_paths
        ]
        require(not extras, "untracked image files in catalog asset directory: " + ", ".join(extras[:10]))

        print(
            "PASS: "
            f"{counts['verified']} verified, "
            f"{counts['generated_needs_review']} generated awaiting review, "
            f"{counts['rejected']} rejected, "
            f"{counts['not_started']} not started; "
            f"{len(content_hashes)} unique code-keyed PNG assets."
        )
        return 0
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError, ValidationError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
