#!/usr/bin/env python3
"""Validate the Stitch surface registry and imported asset manifest offline."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from import_assets import detect_image, iter_references


EXPECTED_SURFACES = 76
EXPECTED_ASSETS = 90
ROW_PATTERN = re.compile(
    r"^\| (ST-\d{3}) \| `([^`]+)`[^|]*\| (page|component|state|placeholder) \|",
    re.MULTILINE,
)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    repository_root = Path.cwd().resolve()
    source_root = repository_root / "docs/refactor/stitch_nanobio_design_system"
    registry_path = source_root / "IMPLEMENTATION_REGISTRY.md"
    manifest_path = repository_root / "assets/config/stitch/manifest.json"
    image_root = repository_root / "assets/images/stitch"
    errors: list[str] = []

    source_surfaces = {
        path.parent.name
        for path in source_root.glob("*/code.html")
        if (path.parent / "screen.png").is_file()
    }
    html_only = {
        path.parent.name
        for path in source_root.glob("*/code.html")
        if not (path.parent / "screen.png").is_file()
    }
    png_only = {
        path.parent.name
        for path in source_root.glob("*/screen.png")
        if not (path.parent / "code.html").is_file()
    }
    if len(source_surfaces) != EXPECTED_SURFACES:
        fail(errors, f"expected {EXPECTED_SURFACES} source pairs, got {len(source_surfaces)}")
    if html_only:
        fail(errors, f"HTML without PNG: {sorted(html_only)}")
    if png_only:
        fail(errors, f"PNG without HTML: {sorted(png_only)}")

    registry_text = registry_path.read_text(encoding="utf-8")
    registry_rows = ROW_PATTERN.findall(registry_text)
    registry_ids = [row[0] for row in registry_rows]
    registry_surfaces = [row[1] for row in registry_rows]
    expected_ids = [f"ST-{index:03d}" for index in range(1, EXPECTED_SURFACES + 1)]
    if len(registry_rows) != EXPECTED_SURFACES:
        fail(errors, f"expected {EXPECTED_SURFACES} registry rows, got {len(registry_rows)}")
    if registry_ids != expected_ids:
        fail(errors, "registry IDs are not the exact sequential ST-001..ST-076 set")
    if len(set(registry_surfaces)) != len(registry_surfaces):
        fail(errors, "registry contains duplicate surface folders")
    missing_registry = source_surfaces - set(registry_surfaces)
    extra_registry = set(registry_surfaces) - source_surfaces
    if missing_registry:
        fail(errors, f"source surfaces missing from registry: {sorted(missing_registry)}")
    if extra_registry:
        fail(errors, f"registry surfaces missing from source: {sorted(extra_registry)}")
    for surface in registry_surfaces:
        html_evidence = f"](./{surface}/code.html)"
        png_evidence = f"](./{surface}/screen.png)"
        if html_evidence not in registry_text or png_evidence not in registry_text:
            fail(errors, f"registry evidence links missing: {surface}")

    extracted = list(iter_references(source_root))
    if len(extracted) != EXPECTED_ASSETS:
        fail(errors, f"expected {EXPECTED_ASSETS} HTML image references, got {len(extracted)}")
    extracted_by_id = {
        f"stitch.{reference.surface}.{reference.ordinal:02d}": reference
        for reference in extracted
    }

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assets = manifest.get("assets", [])
    if len(assets) != EXPECTED_ASSETS:
        fail(errors, f"expected {EXPECTED_ASSETS} manifest assets, got {len(assets)}")
    if manifest.get("stats", {}).get("failed") != 0:
        fail(errors, "manifest reports failed downloads")

    manifest_paths: set[str] = set()
    manifest_ids: set[str] = set()
    for asset in assets:
        asset_id = asset.get("id", "")
        if asset_id in manifest_ids:
            fail(errors, f"duplicate manifest id: {asset_id}")
        manifest_ids.add(asset_id)
        reference = extracted_by_id.get(asset_id)
        if reference is None:
            fail(errors, f"manifest id not present in HTML extraction: {asset_id}")
            continue
        if asset.get("source_url") != reference.url:
            fail(errors, f"source URL mismatch: {asset_id}")
        if asset.get("source_html_sha256") != reference.source_html_sha256:
            fail(errors, f"source HTML hash mismatch: {asset_id}")
        if asset.get("license_status") != "unverified":
            fail(errors, f"unexpected license status: {asset_id}")
        if asset.get("runtime_eligible") is not False:
            fail(errors, f"unverified asset is runtime eligible: {asset_id}")
        if asset.get("status") != "downloaded":
            fail(errors, f"asset not downloaded: {asset_id}")
            continue

        local_path = str(asset.get("local_path", ""))
        manifest_paths.add(local_path)
        path = repository_root / local_path
        if not path.is_file():
            fail(errors, f"local asset missing: {local_path}")
            continue
        data = path.read_bytes()
        if len(data) != asset.get("byte_size"):
            fail(errors, f"byte size mismatch: {local_path}")
        if sha256_bytes(data) != asset.get("content_sha256"):
            fail(errors, f"content hash mismatch: {local_path}")
        detected = detect_image(data)
        if detected is None:
            fail(errors, f"invalid image magic/dimensions: {local_path}")
        else:
            _, mime, width, height = detected
            if (mime, width, height) != (
                asset.get("detected_mime"),
                asset.get("width"),
                asset.get("height"),
            ):
                fail(errors, f"image metadata mismatch: {local_path}")

    missing_manifest_ids = set(extracted_by_id) - manifest_ids
    if missing_manifest_ids:
        fail(errors, f"HTML references missing from manifest: {sorted(missing_manifest_ids)}")
    local_paths = {
        path.resolve().relative_to(repository_root).as_posix()
        for path in image_root.rglob("*")
        if path.is_file()
    }
    if local_paths != manifest_paths:
        missing_files = manifest_paths - local_paths
        extra_files = local_paths - manifest_paths
        if missing_files:
            fail(errors, f"manifest paths missing locally: {sorted(missing_files)}")
        if extra_files:
            fail(errors, f"unmanifested local assets: {sorted(extra_files)}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(
        "PASS: "
        f"{len(source_surfaces)} surface pairs, "
        f"{len(registry_surfaces)} registry rows, "
        f"{len(assets)} verified local asset records"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
