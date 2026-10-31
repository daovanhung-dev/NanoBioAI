#!/usr/bin/env python3
"""Check release sources use the self-hosted API rather than hosted SDKs."""

from __future__ import annotations

from pathlib import Path
import re
import sys


FORBIDDEN_PATTERNS = {
    "hosted SDK": re.compile(r"supabase_flutter|@supabase/supabase-js", re.IGNORECASE),
    "hosted URL/key": re.compile(
        r"SUPABASE_(?:URL|ANON_KEY|SERVICE_ROLE_KEY)|supabase\.co", re.IGNORECASE
    ),
    "hosted client call": re.compile(r"Supabase\.instance|createClient\s*\(", re.IGNORECASE),
}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    checked: list[Path] = []
    for base in (root / "lib", root / "admin-web/src", root / ".github/workflows"):
        if base.is_file():
            checked.append(base)
        elif base.exists():
            checked.extend(
                path
                for path in base.rglob("*")
                if path.is_file() and path.suffix.lower() in {".dart", ".ts", ".tsx", ".js", ".jsx", ".json", ".yml", ".yaml"}
            )

    failures: list[str] = []
    for path in checked:
        try:
            source = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for label, pattern in FORBIDDEN_PATTERNS.items():
            if pattern.search(source):
                failures.append(f"{path.relative_to(root)} still contains {label}")

    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    pubspec_lock = (root / "pubspec.lock").read_text(encoding="utf-8")
    admin_manifest = (root / "admin-web/package.json").read_text(encoding="utf-8")
    admin_lock = (root / "admin-web/package-lock.json").read_text(encoding="utf-8")
    if "supabase_flutter" in pubspec or "supabase_flutter" in pubspec_lock:
        failures.append("Flutter dependency manifests still include supabase_flutter")
    if "@supabase/supabase-js" in admin_manifest or "@supabase/supabase-js" in admin_lock:
        failures.append("Admin Web dependency manifests still include @supabase/supabase-js")

    flutter_config = (root / "assets/config/auth.env").read_text(encoding="utf-8")
    web_config = (root / "admin-web/.env.example").read_text(encoding="utf-8")
    expected = "https://42.118.174.147"
    if expected not in flutter_config or expected not in web_config:
        failures.append("Flutter and Admin Web must default to the self-hosted HTTPS API")
    if (root / "supabase/config.toml").exists():
        failures.append("Supabase CLI project config remains in the active repository root")
    if not (root / "docs/archive/legacy-supabase/project/config.toml").exists():
        failures.append("The legacy project config is missing from the read-only archive")

    if failures:
        print("FAIL self-hosted runtime audit")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"PASS self-hosted runtime audit: {len(checked)} runtime/build source files checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
