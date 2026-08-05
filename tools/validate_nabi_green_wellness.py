#!/usr/bin/env python3
"""Static validation for the NaBi Blue Wellness UI migration.

This checker is intentionally independent from Flutter/Dart so it can still
validate repository structure and token usage in constrained environments.
It does not replace `dart format`, `flutter analyze`, widget tests, or visual QA.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURE_ROOTS = (
    ROOT / "lib/app_versions",
    ROOT / "lib/features",
    ROOT / "lib/shared",
    ROOT / "lib/sale_referral",
)
DART_ROOTS = (ROOT / "lib", ROOT / "test")

OPAQUE_COLOR = re.compile(r"Color\(0x[0-9A-Fa-f]{8}\)")
NUMERIC_RADIUS = re.compile(r"BorderRadius\.circular\([0-9]")
NAMED_MATERIAL_COLOR = re.compile(
    r"Colors\.(?:white|black|grey|gray|red|orange|green|blue|purple|"
    r"teal|amber|yellow|pink|cyan|indigo|brown)(?:\b|\.)"
)
IMPORT = re.compile(r"^import\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
ASSET_ENTRY = re.compile(r"^\s*-\s+([^#\n]+?)\s*$")


@dataclass(frozen=True)
class Finding:
    code: str
    path: str
    detail: str


class DartBalanceChecker:
    _pairs = {")": "(", "]": "[", "}": "{"}
    _open = set(_pairs.values())

    @classmethod
    def check(cls, path: Path) -> str | None:
        source = path.read_text(encoding="utf-8", errors="replace")
        delimiters: list[tuple[str, int, int, bool]] = []
        contexts: list[dict[str, object]] = [{"mode": "code", "interpolation": False}]
        index = 0
        line = 1
        column = 1

        def advance(count: int = 1) -> None:
            nonlocal index, line, column
            for character in source[index : index + count]:
                if character == "\n":
                    line += 1
                    column = 1
                else:
                    column += 1
            index += count

        while index < len(source):
            char = source[index]
            next_char = source[index + 1] if index + 1 < len(source) else ""
            context = contexts[-1]
            mode = context["mode"]

            if mode == "line_comment":
                if char == "\n":
                    contexts.pop()
                advance()
                continue

            if mode == "block_comment":
                if char == "*" and next_char == "/":
                    contexts.pop()
                    advance(2)
                else:
                    advance()
                continue

            if mode == "string":
                quote = str(context["quote"])
                triple = bool(context["triple"])
                raw = bool(context["raw"])
                if not raw and char == "$" and next_char == "{":
                    delimiters.append(("{", line, column, True))
                    contexts.append({"mode": "code", "interpolation": True})
                    advance(2)
                    continue
                if not raw and char == "\\":
                    advance(2 if index + 1 < len(source) else 1)
                    continue
                if triple and source.startswith(quote * 3, index):
                    contexts.pop()
                    advance(3)
                    continue
                if not triple and char == quote:
                    contexts.pop()
                    advance()
                    continue
                advance()
                continue

            if char == "/" and next_char == "/":
                contexts.append({"mode": "line_comment"})
                advance(2)
                continue
            if char == "/" and next_char == "*":
                contexts.append({"mode": "block_comment"})
                advance(2)
                continue
            if char in "rR" and next_char in "'\"":
                quote = next_char
                triple = source.startswith(quote * 3, index + 1)
                contexts.append(
                    {"mode": "string", "quote": quote, "triple": triple, "raw": True}
                )
                advance(4 if triple else 2)
                continue
            if char in "'\"":
                triple = source.startswith(char * 3, index)
                contexts.append(
                    {"mode": "string", "quote": char, "triple": triple, "raw": False}
                )
                advance(3 if triple else 1)
                continue
            if char in cls._open:
                delimiters.append((char, line, column, False))
                advance()
                continue
            if char in cls._pairs:
                if not delimiters or delimiters[-1][0] != cls._pairs[char]:
                    return f"{line}:{column}: unexpected {char}"
                _, _, _, interpolation = delimiters.pop()
                advance()
                if interpolation:
                    if not contexts[-1].get("interpolation"):
                        return f"{line}:{column}: interpolation stack mismatch"
                    contexts.pop()
                continue
            advance()

        if len(contexts) != 1 or contexts[0]["mode"] != "code":
            return f"{line}:{column}: unclosed lexical context"
        if delimiters:
            token, token_line, token_column, _ = delimiters[-1]
            return f"{token_line}:{token_column}: unclosed {token}"
        return None


def dart_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.dart")) if root.exists() else []


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def validate_imports() -> list[Finding]:
    findings: list[Finding] = []
    for root in DART_ROOTS:
        for path in dart_files(root):
            source = path.read_text(encoding="utf-8", errors="replace")
            imports = IMPORT.findall(source)
            duplicates = sorted({item for item in imports if imports.count(item) > 1})
            for item in duplicates:
                findings.append(Finding("DUPLICATE_IMPORT", relative(path), item))
            for item in imports:
                if item.startswith("package:nano_app/"):
                    target = ROOT / "lib" / item.removeprefix("package:nano_app/")
                    if not target.exists():
                        findings.append(Finding("MISSING_IMPORT", relative(path), item))
                elif item.startswith("."):
                    target = (path.parent / item).resolve()
                    if not target.exists():
                        findings.append(Finding("MISSING_IMPORT", relative(path), item))
    return findings


def validate_dart_balance() -> list[Finding]:
    findings: list[Finding] = []
    for root in DART_ROOTS:
        for path in dart_files(root):
            error = DartBalanceChecker.check(path)
            if error:
                findings.append(Finding("DART_BALANCE", relative(path), error))
    return findings


def validate_feature_tokens() -> list[Finding]:
    findings: list[Finding] = []
    checks = (
        ("OPAQUE_COLOR", OPAQUE_COLOR),
        ("NAMED_MATERIAL_COLOR", NAMED_MATERIAL_COLOR),
        ("NUMERIC_RADIUS", NUMERIC_RADIUS),
    )
    for root in FEATURE_ROOTS:
        for path in dart_files(root):
            source = path.read_text(encoding="utf-8", errors="replace")
            for code, pattern in checks:
                for match in pattern.finditer(source):
                    line = source.count("\n", 0, match.start()) + 1
                    findings.append(
                        Finding(code, relative(path), f"line {line}: {match.group(0)}")
                    )
    return findings


def configured_asset_paths() -> list[Path]:
    pubspec = ROOT / "pubspec.yaml"
    if not pubspec.exists():
        return []
    lines = pubspec.read_text(encoding="utf-8", errors="replace").splitlines()
    inside_flutter = False
    inside_assets = False
    result: list[Path] = []
    for line in lines:
        if line.startswith("flutter:"):
            inside_flutter = True
            inside_assets = False
            continue
        if inside_flutter and line and not line.startswith(" "):
            inside_flutter = False
            inside_assets = False
        if not inside_flutter:
            continue
        if re.match(r"^\s{2}assets:\s*$", line):
            inside_assets = True
            continue
        if inside_assets:
            if re.match(r"^\s{2}\S", line):
                inside_assets = False
                continue
            match = ASSET_ENTRY.match(line)
            if match:
                result.append(ROOT / match.group(1).strip().strip("'\""))
    return result


def missing_assets() -> list[str]:
    return [relative(path) for path in configured_asset_paths() if not path.exists()]


def main() -> int:
    findings = [
        *validate_imports(),
        *validate_dart_balance(),
        *validate_feature_tokens(),
    ]
    assets = missing_assets()

    print("NaBi Blue Wellness static validation")
    print(f"- Dart files checked: {sum(len(dart_files(root)) for root in DART_ROOTS)}")
    print(f"- Blocking static findings: {len(findings)}")
    print(f"- Missing configured asset paths: {len(assets)}")

    for finding in findings:
        print(f"ERROR [{finding.code}] {finding.path}: {finding.detail}")
    for asset in assets:
        print(f"WARN  [MISSING_ASSET_PATH] {asset}")

    if findings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
