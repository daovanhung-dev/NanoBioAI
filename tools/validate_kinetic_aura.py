#!/usr/bin/env python3
"""Static validation for the Nabi Kinetic Aura refactor.

This checker intentionally does not replace ``flutter analyze``. It provides a
portable guard for environments where Flutter/Dart executables are unavailable.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

OPEN_TO_CLOSE = {"(": ")", "[": "]", "{": "}"}
CLOSERS = set(OPEN_TO_CLOSE.values())


def strip_dart_non_code(text: str) -> str:
    out: list[str] = []
    i = 0
    n = len(text)
    state = "code"
    quote = ""
    raw = False
    triple = False
    block_depth = 0

    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""

        if state == "code":
            if c == "/" and nxt == "/":
                state = "line_comment"
                out.extend("  ")
                i += 2
                continue
            if c == "/" and nxt == "*":
                state = "block_comment"
                block_depth = 1
                out.extend("  ")
                i += 2
                continue
            raw_prefix = c in {"r", "R"} and nxt in {"'", '"'}
            if raw_prefix:
                raw = True
                quote = nxt
                triple = text[i + 1 : i + 4] in {"'''", '\"\"\"'}
                state = "string"
                out.append(" ")
                out.append(" ")
                i += 2
                if triple:
                    out.extend("  ")
                    i += 2
                continue
            if c in {"'", '"'}:
                raw = False
                quote = c
                triple = text[i : i + 3] in {"'''", '\"\"\"'}
                state = "string"
                out.append(" ")
                i += 1
                if triple:
                    out.extend("  ")
                    i += 2
                continue
            out.append(c)
            i += 1
            continue

        if state == "line_comment":
            if c == "\n":
                state = "code"
                out.append("\n")
            else:
                out.append(" ")
            i += 1
            continue

        if state == "block_comment":
            if c == "/" and nxt == "*":
                block_depth += 1
                out.extend("  ")
                i += 2
                continue
            if c == "*" and nxt == "/":
                block_depth -= 1
                out.extend("  ")
                i += 2
                if block_depth == 0:
                    state = "code"
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue

        if state == "string":
            if triple:
                if text[i : i + 3] == quote * 3:
                    out.extend("   ")
                    i += 3
                    state = "code"
                    triple = False
                    continue
            else:
                if c == quote:
                    out.append(" ")
                    i += 1
                    state = "code"
                    continue
                if c == "\\" and not raw and i + 1 < n:
                    out.extend("  ")
                    i += 2
                    continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue

    return "".join(out)


def validate_delimiters(path: Path) -> list[str]:
    code = strip_dart_non_code(path.read_text(encoding="utf-8", errors="replace"))
    stack: list[tuple[str, int]] = []
    errors: list[str] = []
    for index, char in enumerate(code):
        if char in OPEN_TO_CLOSE:
            stack.append((char, index))
        elif char in CLOSERS:
            if not stack:
                errors.append(f"{path.relative_to(ROOT)}: unexpected {char}")
                continue
            opener, opener_index = stack.pop()
            if OPEN_TO_CLOSE[opener] != char:
                errors.append(
                    f"{path.relative_to(ROOT)}: {opener} at {opener_index} "
                    f"closed by {char} at {index}"
                )
    for opener, index in stack:
        errors.append(f"{path.relative_to(ROOT)}: unclosed {opener} at {index}")
    return errors


def validate_package_imports(path: Path) -> list[str]:
    text = strip_dart_non_code(
        path.read_text(encoding="utf-8", errors="replace")
    )
    errors: list[str] = []
    pattern = re.compile(r"(?:import|export)\s+'package:nano_app/([^']+)'\s*;")
    for relative in pattern.findall(text):
        target = LIB / relative
        if not target.exists():
            errors.append(
                f"{path.relative_to(ROOT)}: missing package import {relative}"
            )
    return errors



def validate_relative_imports(path: Path) -> list[str]:
    text = strip_dart_non_code(
        path.read_text(encoding="utf-8", errors="replace")
    )
    errors: list[str] = []
    pattern = re.compile(r"(?:import|export|part)\s+'([^']+)'\s*;")
    for reference in pattern.findall(text):
        if reference.startswith(("dart:", "package:")):
            continue
        target = (path.parent / reference).resolve()
        if not target.exists():
            errors.append(
                f"{path.relative_to(ROOT)}: missing relative reference {reference}"
            )
    return errors

def validate_feedback_boundaries() -> list[str]:
    errors: list[str] = []
    allowed_haptic = ROOT / "lib/core/feedback/app_haptic_adapter.dart"
    allowed_sound = ROOT / "lib/core/feedback/app_sound_adapter.dart"
    for path in LIB.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="replace")
        if "HapticFeedback." in text and path != allowed_haptic:
            errors.append(
                f"{path.relative_to(ROOT)}: direct HapticFeedback call outside adapter"
            )
        if "SystemSound.play" in text and path != allowed_sound:
            errors.append(
                f"{path.relative_to(ROOT)}: direct SystemSound call outside adapter"
            )
    return errors


def validate_design_matrix() -> list[str]:
    matrix = ROOT / ".codex/design/inventory/ui_source_audit.csv"
    if not matrix.exists():
        return ["Missing .codex/design/inventory/ui_source_audit.csv"]
    with matrix.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    existing_paths = {
        str(path.relative_to(ROOT)).replace("\\", "/")
        for path in LIB.rglob("*.dart")
    }
    missing = [row.get("path", "") for row in rows if row.get("path") not in existing_paths]
    return [f"Design inventory references missing file: {item}" for item in missing]


def main() -> int:
    dart_files = sorted(LIB.rglob("*.dart"))
    kinetic_markers = (
        "AppFeedbackService",
        "AppMotionScope",
        "AppDirectionalSwitcher",
        "appExperiencePreferencesProvider",
        "MotionFoundation",
    )
    structural_files = [
        path
        for path in dart_files
        if "lib/core/feedback/" in path.as_posix()
        or "lib/core/motion/" in path.as_posix()
        or any(
            marker in path.read_text(encoding="utf-8", errors="replace")
            for marker in kinetic_markers
        )
    ]

    touched_manifest = (
        ROOT / ".codex/design/inventory/coding_touched_files.txt"
    )
    touched_files: list[Path] = []
    if touched_manifest.exists():
        for raw_path in touched_manifest.read_text(encoding="utf-8").splitlines():
            relative = raw_path.strip()
            if not relative:
                continue
            candidate = ROOT / relative
            if candidate.exists() and candidate.suffix == ".dart":
                touched_files.append(candidate)

    delimiter_files = sorted(set(structural_files + touched_files))
    errors: list[str] = []
    # The portable checker validates every changed Dart file listed by the
    # implementation manifest plus every file that owns Kinetic Aura structure.
    for path in delimiter_files:
        errors.extend(validate_delimiters(path))
    for path in dart_files:
        errors.extend(validate_package_imports(path))
        errors.extend(validate_relative_imports(path))
    errors.extend(validate_feedback_boundaries())
    errors.extend(validate_design_matrix())

    if errors:
        print("Nabi Kinetic Aura static validation: FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Nabi Kinetic Aura static validation: PASS")
    print(f"- Dart imports checked: {len(dart_files)}")
    print(f"- Kinetic structural files checked: {len(structural_files)}")
    print(f"- Changed/structural Dart files checked: {len(delimiter_files)}")
    print("- Package and relative imports resolved")
    print("- Delimiters balanced")
    print("- Haptic and sound calls isolated behind adapters")
    return 0


if __name__ == "__main__":
    sys.exit(main())
