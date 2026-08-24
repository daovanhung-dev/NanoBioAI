#!/usr/bin/env python3
"""Deterministically regenerate NanoBio worklog history and task skills."""

from __future__ import annotations

import argparse
import os
import re
import sys
import unicodedata
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


CANONICAL_TASKS = (
    ("coding", "Coding", ".codex/workflows/coding.md"),
    ("bugfix", "Direct bugfix", ".codex/workflows/bugfix.md"),
    ("fix-issues", "Fix documented issue", ".codex/workflows/fix-issues.md"),
    ("test", "Test and verification", ".codex/workflows/test.md"),
    ("find-issues", "Review and find issues", ".codex/workflows/find-issues.md"),
    ("create-issues", "Create issue docs", ".codex/workflows/create-issues.md"),
    ("create-todo", "Create todo docs", ".codex/workflows/create-todo.md"),
    ("docs-dd", "Design docs", ".codex/workflows/docs-dd.md"),
    ("docs-context", "Context and docs update", ".codex/workflows/docs-context.md"),
    ("refactor-scaffold", "Scaffold refactor", ".codex/workflows/refactor-scaffold.md"),
    ("supabase-schema", "Supabase schema and RLS", ".codex/workflows/supabase-schema.md"),
)

TASK_BY_KEY = {key: (title, workflow) for key, title, workflow in CANONICAL_TASKS}

LEGACY_ALIAS_MAP = {
    "coding-refactor": "refactor-scaffold",
    "coding-test-docs": "coding",
    "docs": "docs-context",
    "docs-coding": "supabase-schema",
    "docs-context-update": "docs-context",
    "feature": "coding",
    "feature-dashboard-ui-data-write-path": "coding",
    "fix": "bugfix",
    "fix-flow-d-li-u": "bugfix",
    "fix-flow-du-lieu": "bugfix",
    "fix-ui-copy": "bugfix",
    "review-audit-docs": "find-issues",
    "sua-docs-thiet-ke-lai-tai-lieu": "docs-dd",
    "unknown": "docs-context",
}

RISK_KEYWORDS = re.compile(
    r"chua-fix|can-kiem-tra-tiep|rui-ro|todo|fail|partial|timeout|manual|"
    r"q-0|blocked|needs-verification|skipped"
)


@dataclass(frozen=True)
class Entry:
    date: str
    task_type: str
    task_key: str
    module: str
    title: str
    path: str
    request: str


def ascii_slug(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.replace("đ", "d").replace("Đ", "D"))
    ascii_value = "".join(char for char in normalized if not unicodedata.combining(char))
    return re.sub(r"[^a-z0-9]+", "-", ascii_value.lower()).strip("-")


def strip_code(value: str) -> str:
    return re.sub(r"`([^`]+)`", r"\1", value).strip()


def heading(lines: list[str]) -> str:
    for line in lines:
        if line.startswith("# Worklog"):
            return line.removeprefix("# ").strip()
    return ""


def metadata_value(lines: list[str], labels: tuple[str, ...]) -> str:
    label_pattern = "|".join(re.escape(label) for label in labels)
    pattern = re.compile(rf"^-\s*(?:{label_pattern})\s*:\s*(.*)$", re.IGNORECASE)
    for line in lines:
        match = pattern.match(line.strip())
        if match:
            return strip_code(match.group(1))
    return ""


def canonical_task_key(task_type: str, module: str, title: str, path: str, request: str) -> str:
    type_slug = ascii_slug(task_type)
    if type_slug in TASK_BY_KEY:
        return type_slug
    if type_slug in LEGACY_ALIAS_MAP:
        return LEGACY_ALIAS_MAP[type_slug]
    combined = ascii_slug(" ".join((task_type, module, title, path, request)))
    routes = (
        (r"supabase|rls|schema|sql|database|membership|quota|familyplus|referral|commission", "supabase-schema"),
        (r"refactor|scaffold|cau-truc|version-boundary", "refactor-scaffold"),
        (r"fix-issues|todo-fix|fix-todo", "fix-issues"),
        (r"create-todo|tao-todo", "create-todo"),
        (r"create-issue|tao-issue", "create-issues"),
        (r"review|audit|bug-audit|find-issue|release-readiness", "find-issues"),
        (r"test|analyze|format|build|verify|kiem-thu|kiem-chung", "test"),
        (r"dd|bd|design-doc|thiet-ke|product-flow|document-map", "docs-dd"),
        (r"codex|context|docs|worklog|checklist|history|task-skill|map-tree", "docs-context"),
        (r"fix|bug|loi", "bugfix"),
        (r"coding|feature|implement|code|auth|dashboard|onboarding", "coding"),
    )
    for pattern, key in routes:
        if re.search(pattern, combined):
            return key
    return "docs-context"


def read_entries(root: Path) -> tuple[list[Entry], list[str]]:
    worklog_root = root / "docs/worklog"
    if not worklog_root.is_dir():
        raise RuntimeError("docs/worklog not found")
    entries: list[Entry] = []
    risk_lines: list[str] = []
    for file in sorted(worklog_root.rglob("*.md")):
        relative = file.relative_to(root).as_posix()
        text = file.read_text(encoding="utf-8")
        lines = text.splitlines()
        title = heading(lines) or file.stem
        parts = relative.split("/")
        fallback_date = parts[2] if len(parts) > 2 else "unknown"
        date = metadata_value(lines, ("Ngày", "Ngay", "Date")) or fallback_date
        task_type = metadata_value(lines, ("Loại task", "Loai task", "Task type")) or "unknown"
        module = metadata_value(lines, ("Module chính", "Module chinh", "Main module")) or "unknown"
        request = metadata_value(lines, ("Yêu cầu gốc", "Yeu cau goc", "Original request"))
        key = canonical_task_key(task_type, module, title, relative, request)
        entries.append(Entry(date, task_type, key, module, title, relative, request))
        for line in lines:
            clean = line.strip()
            if clean and RISK_KEYWORDS.search(ascii_slug(clean)):
                risk_lines.append(f"{relative} :: {clean}")
    return entries, risk_lines


def md_cell(value: str) -> str:
    return value.replace("|", r"\|").replace("\r", " ").replace("\n", " ").strip()


def md_inline(value: str) -> str:
    return value.replace("&", "&amp;").replace("[", "&#91;").replace("]", "&#93;")


def relative_link(from_file: str, to_file: str) -> str:
    return os.path.relpath(to_file, start=str(Path(from_file).parent)).replace(os.sep, "/")


def render_index(entries: list[Entry]) -> str:
    target = ".codex/history/WORKLOG_INDEX.md"
    lines = [
        "# Worklog Index",
        "",
        "Generated from all `docs/worklog/**/*.md` files.",
        "",
        f"- Total worklogs: {len(entries)}",
        "- Refresh commands: `python3 .codex/tools/update_worklog_learning.py --write` or `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`",
        "",
        "## Entries",
        "",
        "| Date | Type | Canonical task | Module | Worklog |",
        "| --- | --- | --- | --- | --- |",
    ]
    for entry in entries:
        lines.append(
            f"| {md_cell(entry.date)} | {md_cell(entry.task_type)} | {entry.task_key} | "
            f"{md_cell(entry.module)} | [{entry.title}]({relative_link(target, entry.path)}) |"
        )
    return "\n".join(lines) + "\n"


def render_learned_skills(entries: list[Entry]) -> str:
    type_counts = Counter(entry.task_key for entry in entries)
    module_counts = Counter(entry.module for entry in entries)
    lines = [
        "# Learned Skills",
        "",
        "Generated from the full worklog corpus. Read this after `.codex/AGENTS.md`.",
        "",
        "## Canonical Work Types Seen",
        "",
    ]
    for key, count in type_counts.most_common():
        lines.append(f"- {key} - {TASK_BY_KEY[key][0]}: {count} worklog(s)")
    lines.extend(["", "## Frequent Modules", ""])
    for module, count in module_counts.most_common(12):
        lines.append(f"- {module}: {count}")
    lines.extend(
        [
            "",
            "## Reusable Project Skills",
            "",
            "- Route every task through one workflow in `.codex/workflows/`, one generated task-skill in `.codex/task-skills/`, and one primary domain in `.codex/domains/`.",
            "- Treat reachable wiring as current behavior: one main, a composed user router, an Admin surface selected by backend access, and Sale/referral as an independent axis.",
            "- For AI work, use the current Gemini REST/Dio clients, validate/normalize output, avoid real network calls in tests, and keep safe fallback behavior.",
            "- For dashboard work, read real data through providers/repositories/datasources; do not add production mock data.",
            "- For DD work, preserve IDs but separate implementation status from runtime/sandbox verification and cite reachable source.",
            "- For issue/todo work, keep find issue, create issue, create todo, fix issue, and test as separate modes.",
            "- For Supabase work, treat `01_build_system.sql` and `02_seed_data.sql` as the local/sandbox source of truth, and keep sandbox/staging behavior unverified until execution evidence exists.",
            "",
            "## Command And Test Patterns",
            "",
            "- Prefer targeted tests before full quick check.",
            "- Docs-only tasks use source-truth/link checks and `git diff --check`; skip Flutter analyze/test unless Dart source or tests changed.",
            "- Native commands in `.codex/tool/*.ps1` must run through `Invoke-NativeCommand` so non-zero exit codes fail the script.",
            "- If Flutter/Dart tools are unavailable, record `UNVERIFIED`; never invent runtime evidence.",
            "",
            "## Post-Session Self Optimization",
            "",
            "- End every substantial session with a worklog self-review: output quality, task completion, verification strength, token efficiency, and next-session optimization.",
            "- After writing the worklog, run the deterministic history refresh so `.codex/history/` and `.codex/task-skills/` learn from the session.",
            "- Before starting a task, read the matching canonical `.codex/task-skills/<task-key>.md` after selecting the workflow.",
        ]
    )
    return "\n".join(lines) + "\n"


def render_open_risks(entries: list[Entry]) -> str:
    updated = max((entry.date for entry in entries if re.fullmatch(r"\d{4}-\d{2}-\d{2}", entry.date)), default="unknown")
    return "\n".join(
        [
            "# Open Risks",
            "",
            "Default risk register. This file contains only risks that are still open or need verification. Raw extracted history lives in `RISK_HISTORY.md`.",
            "",
            "## NB-RISK-001 Supabase sandbox/staging verification pending",
            "",
            "- Severity: P1",
            "- Status: Needs Verification",
            f"- Updated: {updated}",
            "- Evidence: `docs/supabase/README.md`; `docs/supabase/01_build_system.sql`; `docs/worklog/2026-06-21/002-worklog-supabase-database-draft.md`.",
            "- Impact: Membership, quota, FamilyPlus, sale/referral, payment, and RLS behavior cannot be treated as production-ready until SQL/RLS is executed outside docs.",
            "- Proposed handling: Run the build system and seed data scripts in Supabase local/sandbox, record RLS smoke results for at least two users and family scopes, then update this risk with evidence.",
            "- Owner/scope: Backend/Supabase implementation.",
        ]
    ) + "\n"


def render_risk_history(risk_lines: list[str]) -> str:
    lines = [
        "# Risk History",
        "",
        "Raw risk/failure/skip history extracted from worklogs. This file is not part of the default context pack unless exact history is needed.",
        "",
        "## Extracted Lines",
        "",
    ]
    lines.extend(f"- {md_inline(line)}" for line in risk_lines)
    return "\n".join(lines) + "\n"


def render_quality() -> str:
    return """# Session Quality Review

Use this checklist at the end of every substantial session before final response.

## Required Self-Review Questions

- Output quality: is the delivered artifact correct, coherent, scoped, and maintainable?
- Task completion: which requested items are complete, partial, skipped, or unverified?
- Verification strength: which commands or evidence prove completion, and what remains weak?
- Token efficiency: what context was unnecessary, what could be indexed, and which workflow/domain/task-skill should be read next time?
- Future optimization: should `.codex`, a workflow, a domain, or a task-skill be updated from this session?

## Worklog Section

Add this section to every new worklog:

```md
## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot/can cai thien - ly do
- Muc do hoan thanh task: ...
- Bang chung kiem chung: ...
- Diem ton token/chua toi uu: ...
- Cach toi uu cho phien sau: ...
- Task-skill can doc lan sau: `.codex/task-skills/<task-key>.md`
```
"""


def render_task_skill(key: str, title: str, workflow: str, entries: list[Entry]) -> str:
    target = f".codex/task-skills/{key}.md"
    selected = sorted((entry for entry in entries if entry.task_key == key), key=lambda item: (item.date, item.path))
    type_counts = Counter(entry.task_type for entry in selected)
    module_counts = Counter(entry.module for entry in selected)
    lines = [
        f"# Task Skill - {title}",
        "",
        f"- Canonical key: {key}",
        f"- Workflow: {workflow}",
        f"- Generated from {len(selected)} worklog(s).",
        "",
        "## When To Read",
        "",
    ]
    if selected:
        lines.extend(f"- Historical task type: {name} ({count})" for name, count in type_counts.most_common())
    else:
        lines.append(f"- Read this when the current request maps to {key}; no historical worklog has used this canonical key yet.")
    lines.extend(["", "## Common Modules", ""])
    if selected:
        lines.extend(f"- {name}: {count}" for name, count in module_counts.most_common(8))
    else:
        lines.append("- No historical module data yet.")
    lines.extend(["", "## Work Pattern", "", "- Start from the selected workflow, then this task skill, then one domain file."])
    if key == "coding":
        lines.extend(
            [
                "- Read `docs/checklist/checklist_complete_DD.md` first to identify code-derived module progress, blockers, and next step; then read `docs/checklist/checklist_task_coding.md` for prior-session notes.",
                "- Before coding from a DD module, state implementation and verification independently; DD completeness never proves runtime completion.",
                "- After coding, update current checklists and record upcoming work without rewriting historical evidence.",
            ]
        )
    lines.extend(
        [
            "- Prefer targeted source searches and focused tests over broad raw reads.",
            "- Record exact evidence in the worklog and add the self-review section.",
            "- Ask before expanding scope when product decisions are missing.",
            "",
            "## Token Optimization",
            "",
            "- Ask: how can this task use fewer tokens while producing equal or better work?",
            "- Read index/summary files before raw historical files.",
            "- Stop reading when root cause, target files, and validation path are clear.",
            "- Update this generated skill through the history refresh script, not by hand.",
            "",
            "## Source Worklogs",
            "",
        ]
    )
    if selected:
        for entry in selected[:12]:
            lines.append(f"- [{entry.title}]({relative_link(target, entry.path)}) - {entry.module}")
    else:
        lines.append("- None yet.")
    return "\n".join(lines) + "\n"


def render_task_readme(entries: list[Entry]) -> str:
    counts = Counter(entry.task_key for entry in entries)
    lines = [
        "# Task Skills",
        "",
        "Generated from canonical task keys. Read the file matching the selected workflow/task before opening raw worklogs.",
        "",
        "| Task key | Title | Workflow | Worklogs | File |",
        "| --- | --- | --- | ---: | --- |",
    ]
    for key, title, workflow in CANONICAL_TASKS:
        lines.append(f"| {key} | {title} | {workflow} | {counts[key]} | [{key}.md]({key}.md) |")
    lines.extend(["", "Legacy task keys are mapped in [LEGACY_TASK_KEY_MAP.md](LEGACY_TASK_KEY_MAP.md). Do not create new task-skill files outside the canonical key set."])
    return "\n".join(lines) + "\n"


def render_legacy_map() -> str:
    lines = [
        "# Legacy Task Key Map",
        "",
        "Old generated task keys are mapped to canonical task keys so old worklogs remain understandable without keeping noisy generated skill files.",
        "",
        "| Legacy key | Canonical key |",
        "| --- | --- |",
    ]
    lines.extend(f"| {key} | {LEGACY_ALIAS_MAP[key]} |" for key in sorted(LEGACY_ALIAS_MAP))
    return "\n".join(lines) + "\n"


def render_refresh() -> str:
    return """# History Refresh

Run this after any session creates or updates `docs/worklog/**`.

```bash
python3 .codex/tools/update_worklog_learning.py --write
python3 .codex/tools/update_worklog_learning.py --check
```

PowerShell compatibility wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Outputs:

- `WORKLOG_INDEX.md`: full worklog inventory with canonical task keys.
- `LEARNED_SKILLS.md`: reusable project skills and command patterns.
- `OPEN_RISKS.md`: compact active risk register only.
- `RISK_HISTORY.md`: raw extracted historical risk/failure lines.
- `SESSION_QUALITY_REVIEW.md`: self-review template for future sessions.
- `.codex/task-skills/*.md`: generated canonical task-specific skills.
- `HISTORY_REFRESH.md`: this instruction file.

After refresh, run `python3 tools/validate_docs_source_truth.py` and the
PowerShell integrity wrapper where available. Include generated history and
task-skill changes in the same docs/context diff.
"""


def build_outputs(root: Path) -> dict[Path, str]:
    entries, risk_lines = read_entries(root)
    outputs: dict[Path, str] = {
        root / ".codex/history/WORKLOG_INDEX.md": render_index(entries),
        root / ".codex/history/LEARNED_SKILLS.md": render_learned_skills(entries),
        root / ".codex/history/OPEN_RISKS.md": render_open_risks(entries),
        root / ".codex/history/RISK_HISTORY.md": render_risk_history(risk_lines),
        root / ".codex/history/SESSION_QUALITY_REVIEW.md": render_quality(),
        root / ".codex/history/HISTORY_REFRESH.md": render_refresh(),
        root / ".codex/task-skills/README.md": render_task_readme(entries),
        root / ".codex/task-skills/LEGACY_TASK_KEY_MAP.md": render_legacy_map(),
    }
    for key, title, workflow in CANONICAL_TASKS:
        outputs[root / f".codex/task-skills/{key}.md"] = render_task_skill(key, title, workflow, entries)
    return outputs


def write_outputs(outputs: dict[Path, str]) -> None:
    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Updated {len(outputs)} deterministic history/task-skill files.")


def check_outputs(outputs: dict[Path, str], root: Path) -> int:
    stale: list[str] = []
    for path, expected in outputs.items():
        actual = path.read_text(encoding="utf-8") if path.is_file() else None
        if actual != expected:
            stale.append(path.relative_to(root).as_posix())
    if stale:
        print("WORKLOG LEARNING CHECK FAILED")
        for path in stale:
            print(f"- stale or missing: {path}")
        return 1
    print(f"WORKLOG LEARNING CHECK PASSED: {len(outputs)} files")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[2])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = args.project_root.resolve()
    outputs = build_outputs(root)
    if args.write:
        write_outputs(outputs)
        return 0
    return check_outputs(outputs, root)


if __name__ == "__main__":
    sys.exit(main())
