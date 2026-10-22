#!/usr/bin/env python3
"""Check required backend context files and local Markdown links."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "AGENTS.md",
    ".agents/AGENTS.md",
    ".agents/context-map.md",
    ".agents/project/INDEX.md",
    *[
        f".agents/project/{i:02d}-{name}.md"
        for i, name in enumerate(
            [
                "product-context",
                "architecture",
                "technology",
                "coding-conventions",
                "api-contract",
                "validation",
                "database",
                "auth-security",
                "error-observability",
                "testing",
                "devops-operations",
                "task-workflows",
                "decisions",
            ],
            start=1,
        )
    ],
    ".agents/modules/README.md",
    ".agents/modules/TEMPLATE.md",
    ".agents/worklog/README.md",
    ".agents/worklog/TEMPLATE.md",
]


def main() -> int:
    issues: list[str] = []
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            issues.append(f"MISSING {relative}")
    for markdown in ROOT.rglob("*.md"):
        text = markdown.read_text(encoding="utf-8")
        for link in re.findall(r"\]\(([^)]+)\)", text):
            target = link.split("#", 1)[0]
            if not target or "://" in target or target.startswith(("#", "mailto:")):
                continue
            if not (markdown.parent / target).exists():
                issues.append(f"BROKEN LINK {markdown.relative_to(ROOT)}: {target}")
    if issues:
        print("\n".join(issues))
        print(f"FAIL: {len(issues)} context issues")
        return 1
    print(f"PASS: backend agent context ({len(REQUIRED)} required files), Markdown local links")
    return 0


if __name__ == "__main__":
    sys.exit(main())
