#!/usr/bin/env python3
"""Import remote Stitch image references into deterministic local files.

The importer is intentionally conservative:
- only HTTPS URLs from the allowlisted Stitch image host are accepted;
- responses must be successful images with recognized magic bytes;
- every file receives content/provenance hashes and dimensions;
- imported files remain reference-only until their license is verified.

The generated JSON is deterministic for identical HTML and responses. Generate it
outside the repository when repository text files must be changed via apply_patch.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import struct
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ALLOWED_SOURCE_HOSTS = {"lh3.googleusercontent.com"}
MAX_DOWNLOAD_BYTES = 25 * 1024 * 1024
URL_PATTERN = re.compile(r"https://[^\s\"'<>\\)]+")
TAG_PATTERN = re.compile(r"<(?P<tag>img|div)\b(?P<attrs>[^>]*)>", re.IGNORECASE)
ATTRIBUTE_PATTERN = re.compile(
    r"(?P<name>[A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?P<quote>['\"])(?P<value>.*?)(?P=quote)",
    re.DOTALL,
)


@dataclass(frozen=True)
class Reference:
    surface: str
    ordinal: int
    source_html: Path
    source_html_sha256: str
    url: str
    kind: str
    alt_text: str


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_text(value: str) -> str:
    return sha256_bytes(value.encode("utf-8"))


def slugify(value: str, fallback: str = "image") -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_value.lower()).strip("-")
    return (slug or fallback)[:48].rstrip("-")


def parse_attributes(raw: str) -> dict[str, str]:
    return {
        match.group("name").lower(): html.unescape(match.group("value"))
        for match in ATTRIBUTE_PATTERN.finditer(raw)
    }


def iter_references(source_root: Path) -> Iterable[Reference]:
    for html_path in sorted(source_root.glob("*/code.html")):
        source_bytes = html_path.read_bytes()
        source_text = source_bytes.decode("utf-8")
        source_hash = sha256_bytes(source_bytes)
        found: list[tuple[str, str, str]] = []

        for tag_match in TAG_PATTERN.finditer(source_text):
            tag = tag_match.group("tag").lower()
            attrs = parse_attributes(tag_match.group("attrs"))
            alt_text = attrs.get("data-alt") or attrs.get("alt") or ""

            if tag == "img" and attrs.get("src", "").startswith("https://"):
                found.append((attrs["src"], "img", alt_text))

            style = attrs.get("style", "")
            for url in URL_PATTERN.findall(style):
                found.append((html.unescape(url), "css-background", alt_text))

        for ordinal, (url, kind, alt_text) in enumerate(found, start=1):
            parsed = urllib.parse.urlparse(url)
            if parsed.scheme != "https" or parsed.hostname not in ALLOWED_SOURCE_HOSTS:
                continue
            yield Reference(
                surface=html_path.parent.name,
                ordinal=ordinal,
                source_html=html_path,
                source_html_sha256=source_hash,
                url=url,
                kind=kind,
                alt_text=alt_text.strip(),
            )


def jpeg_dimensions(data: bytes) -> tuple[int, int] | None:
    index = 2
    while index + 9 < len(data):
        if data[index] != 0xFF:
            index += 1
            continue
        marker = data[index + 1]
        index += 2
        if marker in {0xD8, 0xD9}:
            continue
        if index + 2 > len(data):
            return None
        segment_length = int.from_bytes(data[index : index + 2], "big")
        if segment_length < 2 or index + segment_length > len(data):
            return None
        if marker in {
            0xC0,
            0xC1,
            0xC2,
            0xC3,
            0xC5,
            0xC6,
            0xC7,
            0xC9,
            0xCA,
            0xCB,
            0xCD,
            0xCE,
            0xCF,
        }:
            height = int.from_bytes(data[index + 3 : index + 5], "big")
            width = int.from_bytes(data[index + 5 : index + 7], "big")
            return width, height
        index += segment_length
    return None


def detect_image(data: bytes) -> tuple[str, str, int, int] | None:
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        width, height = struct.unpack(">II", data[16:24])
        return "png", "image/png", width, height
    if data.startswith(b"\xff\xd8\xff"):
        dimensions = jpeg_dimensions(data)
        if dimensions:
            return "jpg", "image/jpeg", dimensions[0], dimensions[1]
    if data[:6] in {b"GIF87a", b"GIF89a"} and len(data) >= 10:
        width, height = struct.unpack("<HH", data[6:10])
        return "gif", "image/gif", width, height
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP" and len(data) >= 30:
        chunk = data[12:16]
        if chunk == b"VP8X":
            width = 1 + int.from_bytes(data[24:27], "little")
            height = 1 + int.from_bytes(data[27:30], "little")
            return "webp", "image/webp", width, height
        if chunk == b"VP8L" and len(data) >= 25 and data[20] == 0x2F:
            bits = int.from_bytes(data[21:25], "little")
            width = (bits & 0x3FFF) + 1
            height = ((bits >> 14) & 0x3FFF) + 1
            return "webp", "image/webp", width, height
        frame = data.find(b"\x9d\x01\x2a", 20, 40)
        if frame >= 0 and frame + 7 <= len(data):
            width = int.from_bytes(data[frame + 3 : frame + 5], "little") & 0x3FFF
            height = int.from_bytes(data[frame + 5 : frame + 7], "little") & 0x3FFF
            return "webp", "image/webp", width, height
    return None


def download(reference: Reference, retries: int, timeout: float) -> dict[str, object]:
    last_error = "download failed"
    for attempt in range(retries + 1):
        try:
            request = urllib.request.Request(
                reference.url,
                headers={
                    "Accept": "image/*",
                    "User-Agent": "NanoBio-Stitch-Asset-Importer/1.0",
                },
            )
            with urllib.request.urlopen(request, timeout=timeout) as response:
                status = int(response.status)
                final_url = response.geturl()
                final_parsed = urllib.parse.urlparse(final_url)
                content_type = response.headers.get_content_type().lower()
                if status != 200:
                    raise ValueError(f"unexpected HTTP status {status}")
                if (
                    final_parsed.scheme != "https"
                    or final_parsed.hostname not in ALLOWED_SOURCE_HOSTS
                ):
                    raise ValueError("redirected outside the HTTPS image allowlist")
                if not content_type.startswith("image/"):
                    raise ValueError(f"unexpected MIME type {content_type}")
                content_length = response.headers.get("Content-Length")
                if content_length and int(content_length) > MAX_DOWNLOAD_BYTES:
                    raise ValueError("response exceeds maximum allowed size")
                data = response.read(MAX_DOWNLOAD_BYTES + 1)
                if len(data) > MAX_DOWNLOAD_BYTES:
                    raise ValueError("response exceeds maximum allowed size")
                detected = detect_image(data)
                if not detected:
                    raise ValueError("unrecognized image magic bytes or dimensions")
                extension, detected_mime, width, height = detected
                if content_type != detected_mime:
                    raise ValueError(
                        f"response MIME {content_type} does not match {detected_mime} magic bytes"
                    )
                return {
                    "ok": True,
                    "http_status": status,
                    "final_url": final_url,
                    "response_mime": content_type,
                    "detected_mime": detected_mime,
                    "extension": extension,
                    "width": width,
                    "height": height,
                    "byte_size": len(data),
                    "content_sha256": sha256_bytes(data),
                    "data": data,
                }
        except (OSError, ValueError, urllib.error.URLError) as error:
            last_error = f"{type(error).__name__}: {error}"
            if attempt < retries:
                time.sleep(0.5 * (attempt + 1))
    return {"ok": False, "error": last_error}


def relative_posix(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def build_manifest(
    source_root: Path,
    output_root: Path,
    repository_root: Path,
    retries: int,
    timeout: float,
) -> dict[str, object]:
    references = list(iter_references(source_root))
    records: list[dict[str, object]] = []
    seen_content: dict[str, str] = {}

    for reference in references:
        result = download(reference, retries=retries, timeout=timeout)
        base = {
            "id": f"stitch.{reference.surface}.{reference.ordinal:02d}",
            "surface": reference.surface,
            "ordinal": reference.ordinal,
            "source_html": relative_posix(reference.source_html, repository_root),
            "source_html_sha256": reference.source_html_sha256,
            "source_url": reference.url,
            "source_url_sha256": sha256_text(reference.url),
            "reference_kind": reference.kind,
            "alt_text": reference.alt_text,
            "license_status": "unverified",
            "runtime_eligible": False,
            "runtime_fallback": "bundled-local-asset-or-data-driven-placeholder",
        }
        if not result["ok"]:
            records.append({**base, "status": "failed", "error": result["error"]})
            continue

        result.pop("ok")
        extension = str(result.pop("extension"))
        if result.get("final_url") == reference.url:
            result.pop("final_url")
        url_hash = sha256_text(reference.url)[:10]
        alt_slug = slugify(reference.alt_text)
        file_name = f"{reference.ordinal:02d}-{alt_slug}-{url_hash}.{extension}"
        output_path = output_root / reference.surface / file_name
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(result.pop("data"))
        content_hash = str(result["content_sha256"])
        duplicate_of = seen_content.get(content_hash)
        local_path = relative_posix(output_path, repository_root)
        if duplicate_of is None:
            seen_content[content_hash] = local_path

        record = {
            **base,
            "status": "downloaded",
            "local_path": local_path,
            **result,
        }
        if duplicate_of:
            record["duplicate_content_of"] = duplicate_of
        records.append(record)

    failures = sum(1 for record in records if record["status"] == "failed")
    return {
        "schema_version": 1,
        "source_root": relative_posix(source_root, repository_root),
        "output_root": relative_posix(output_root, repository_root),
        "policy": {
            "network_use": "import-time-only",
            "hotlinking": "forbidden",
            "default_license_status": "unverified",
            "runtime_use": "forbidden-until-license-verified",
            "fallback": "Use an existing bundled Nabi/domain asset, user initials, runtime data, or a neutral local placeholder.",
            "personal_data": "Never copy prototype names, health values, financial values, avatars, or QR payloads into production runtime data.",
        },
        "stats": {
            "references": len(references),
            "downloaded": len(records) - failures,
            "failed": failures,
            "unique_content": len(seen_content),
        },
        "assets": records,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-root",
        type=Path,
        default=Path("docs/refactor/stitch_nanobio_design_system"),
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path("assets/images/stitch"),
    )
    parser.add_argument("--manifest-output", type=Path, required=True)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--timeout", type=float, default=30.0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repository_root = Path.cwd().resolve()
    source_root = args.source_root.resolve()
    output_root = args.output_root.resolve()
    if repository_root not in source_root.parents:
        raise SystemExit("source root must be inside the repository")
    if repository_root not in output_root.parents:
        raise SystemExit("output root must be inside the repository")

    manifest = build_manifest(
        source_root=source_root,
        output_root=output_root,
        repository_root=repository_root,
        retries=max(args.retries, 0),
        timeout=max(args.timeout, 1.0),
    )
    args.manifest_output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest_output.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest["stats"], ensure_ascii=False))
    return 0 if manifest["stats"]["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
