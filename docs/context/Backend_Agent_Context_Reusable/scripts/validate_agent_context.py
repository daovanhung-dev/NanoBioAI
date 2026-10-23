#!/usr/bin/env python3
"""Validate reusable context structure, local relative Markdown links & placeholders.

This does NOT validate FastAPI source, security, database, or tests.
"""
from __future__ import annotations
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "AGENTS.md", ".agents/AGENTS.md", ".agents/context-map.md",
    ".agents/project/INDEX.md", ".agents/project/01-product-context.md",
    ".agents/project/02-architecture.md", ".agents/project/03-technology.md",
    ".agents/project/04-coding-conventions.md", ".agents/project/05-api-contract.md",
    ".agents/project/06-validation.md", ".agents/project/07-database.md",
    ".agents/project/08-auth-security.md", ".agents/project/09-error-observability.md",
    ".agents/project/10-testing.md", ".agents/project/11-devops-operations.md",
    ".agents/project/12-task-workflows.md", ".agents/project/13-decisions.md",
    ".agents/modules/README.md", ".agents/modules/TEMPLATE.md",
    ".agents/worklog/README.md", ".agents/worklog/TEMPLATE.md",
]

def main() -> int:
    failures = []
    for path in REQUIRED:
        if not (ROOT / path).is_file():
            failures.append(f"MISSING {path}")
    # Check only explicit relative markdown links. HTTP links and placeholders skipped.
    for md in ROOT.rglob("*.md"):
        content = md.read_text(encoding="utf-8")
        for link in re.findall(r"\]\(([^)]+)\)", content):
            link = link.split("#", 1)[0]
            if not link or "://" in link or link.startswith(("#", "mailto:")):
                continue
            if not (md.parent / link).exists():
                failures.append(f"BROKEN LINK {md.relative_to(ROOT)}: {link}")
    if failures:
        print("\n".join(failures))
        print(f"FAIL: {len(failures)} problems")
        return 1
    print(f"PASS: agent context structure ({len(REQUIRED)} required files), Markdown local links")
    print("NOTE: project TODO placeholders are intentionally unfilled; runtime not verified")
    return 0

if __name__ == "__main__":
    sys.exit(main())
