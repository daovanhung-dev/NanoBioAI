#!/usr/bin/env python3
"""List up to N recent worklogs matching exact primary_task_type.

Stdlib only; selecting paths is NOT evidence those files have been read.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / ".agents" / "worklog"
VALID = {"coding", "fix", "docs", "test", "refactor", "operations"}


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--type", required=True, choices=sorted(VALID))
    p.add_argument("--limit", type=int, default=3)
    args = p.parse_args()
    if args.limit < 1:
        p.error("--limit must be positive")
    found: list[Path] = []
    for file in LOGS.glob("????-??-??/*.md"):
        raw = file.read_text(encoding="utf-8", errors="replace")
        match = re.search(r'^primary_task_type:\s*["\']?([\w-]+)', raw, re.M)
        if match and match.group(1) == args.type:
            found.append(file)
    found.sort(key=lambda x: (-int(x.parent.name.replace("-", "")), str(x)))
    selected = found[: args.limit]
    print(f"task_type={args.type} found={len(found)} selected={len(selected)}")
    for f in selected:
        print(f.relative_to(ROOT))
    if len(selected) < args.limit:
        print(f"shortage={args.limit - len(selected)}")

if __name__ == "__main__":
    main()
