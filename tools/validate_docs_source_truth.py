#!/usr/bin/env python3
"""Validate the repository-wide source/document truth inventory.

The default mode is read-only. Use ``--write-manifest`` deliberately after a
completed documentation reconciliation to refresh the reviewed workspace
snapshot. The manifest covers tracked files plus non-ignored files created in
the current worktree; the manifest file itself is represented without a
digest to avoid a self-referential hash.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path, PurePosixPath
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs/audit/source_truth_manifest.json"
MANIFEST_REL = MANIFEST_PATH.relative_to(ROOT).as_posix()
SCHEMA_VERSION = 1

DD_IMPLEMENTATION = {
    "admin_dashboard": "Implemented",
    "admin_operations": "Implemented",
    "advanced_tracking_goals": "Partial",
    "ai_chat": "Implemented",
    "audit_security": "Partial",
    "auth_profile_sync": "Implemented",
    "basic_health_calculators": "Partial",
    "dashboard_schedule": "Implemented",
    "familyplus": "Implemented",
    "health_score_habits": "Implemented",
    "membership_quota": "Implemented",
    "nabi_companion_notifications": "Source-only",
    "onboarding_profile": "Implemented",
    "payment_membership": "Implemented",
    "personal_schedule_ai": "Implemented",
    "reconciliation": "Partial",
    "referral_direct": "Implemented",
    "reporting": "Partial",
    "sale_points": "Implemented",
    "schedule_notifications": "Implemented",
}

LIFECYCLES = {"Current", "Historical", "Generated", "Reference", "Source", "Binary"}
IMPLEMENTATION_STATES = {
    "Implemented",
    "Partial",
    "Placeholder",
    "Source-only",
    "Absent",
    "N/A",
}
VERIFICATION_STATES = {
    "Static-verified",
    "Runtime-unverified",
    "Sandbox-unverified",
    "Historical",
}

BINARY_EXTENSIONS = {
    ".gif",
    ".ico",
    ".jpeg",
    ".jpg",
    ".png",
    ".ttf",
    ".wav",
    ".webp",
}

HISTORICAL_PREFIXES = (
    "docs/worklog/",
    "docs/features/",
    "docs/fixbug/",
    "docs/issues/",
    "docs/todo/",
    "docs/test/",
)

REFERENCE_PREFIXES = (
    "docs/refactor/",
    "docs/ui/",
    "docs/note/",
    "docs/prompts/",
    "docs/tasks/",
    "docs/logbug/",
    "assets/",
    "source/",
)

ROOT_HISTORICAL = {
    "CHANGED_FILES.md",
    "DELIVERY_MANIFEST_DASHBOARD_BLUE.md",
    "NABI_KINETIC_AURA_CODING_MANIFEST.md",
    "NanoBioAI_ai_chat_fix.patch",
    "PATCH_MANIFEST.md",
    "README for docs.md",
    "README_APPLY.md",
    "README_APPLY_FIX.txt",
    "UI_UX_REFRESH_MANIFEST.md",
    "VALIDATION_REPORT.md",
}

DOCS_ROOT_HISTORICAL = {
    "docs/AI_CHAT_API_FIX.md",
}

GENERATED_PATHS = {
    "lib/l10n/app_localizations.dart",
    "lib/l10n/app_localizations_vi.dart",
}

SUPABASE_SQL_SOURCES = {
    "docs/supabase/01_build_system.sql",
    "docs/supabase/02_seed_data.sql",
}

SOURCE_EXTENSIONS = {
    ".arb",
    ".cmake",
    ".cpp",
    ".dart",
    ".gradle",
    ".h",
    ".html",
    ".json",
    ".kt",
    ".kts",
    ".lock",
    ".pbxproj",
    ".plist",
    ".properties",
    ".ps1",
    ".py",
    ".sh",
    ".sql",
    ".storyboard",
    ".swift",
    ".toml",
    ".ts",
    ".xcconfig",
    ".xml",
    ".yaml",
    ".yml",
}

SOURCE_ROOTS = (
    "android/",
    "integration_test/",
    "ios/",
    "lib/",
    "linux/",
    "macos/",
    "supabase/",
    "test/",
    "test_driver/",
    "tools/",
    "web/",
    "windows/",
)

MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\((?P<target>[^)]+)\)")
FENCED_BLOCK = re.compile(r"(?ms)^\s*(```|~~~).*?^\s*\1\s*$")


def run_git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    return result.stdout.strip()


def workspace_paths() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    paths = [item.decode("utf-8") for item in result.stdout.split(b"\0") if item]
    return sorted(path for path in paths if (ROOT / path).is_file())


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def is_generated(path: str) -> bool:
    name = PurePosixPath(path).name
    return (
        path in GENERATED_PATHS
        or path.startswith(".codex/history/")
        or path.startswith(".codex/task-skills/")
        or name.startswith("generated_plugin_registrant")
        or name == "GeneratedPluginRegistrant.m"
        or path.endswith(".g.dart")
        or path.endswith(".freezed.dart")
        or (path.startswith("docs/") and path.endswith(".html"))
    )


def classify(path: str) -> str:
    suffix = PurePosixPath(path).suffix.lower()
    if suffix in BINARY_EXTENSIONS:
        return "Binary"
    if is_generated(path) or path == MANIFEST_REL:
        return "Generated"
    if path == "docs/audit/SOURCE_TRUTH_AUDIT.md":
        return "Current"
    if path in ROOT_HISTORICAL or path in DOCS_ROOT_HISTORICAL or path.startswith(HISTORICAL_PREFIXES):
        return "Historical"
    if path.startswith("docs/audit/"):
        return "Historical"
    if path.startswith("docs/DD/DD_Module_Template/"):
        return "Reference"
    if path.startswith("docs/DD/") and (
        "/history/" in path
        or "Implementation_Delta_" in PurePosixPath(path).name
        or "_Delta_" in PurePosixPath(path).name
    ):
        return "Historical"
    if path.startswith(REFERENCE_PREFIXES):
        return "Reference"
    if path.startswith("docs/supabase/") and suffix == ".sql":
        return "Source"
    if path.startswith(SOURCE_ROOTS) and suffix in SOURCE_EXTENSIONS:
        if suffix in {".md", ".txt"} or "README" in PurePosixPath(path).name.upper():
            return "Current"
        return "Source"
    if suffix in SOURCE_EXTENSIONS and not path.startswith(("docs/", ".codex/", ".agents/")):
        return "Source"
    return "Current"


def domain_for(path: str) -> str:
    parts = PurePosixPath(path).parts
    if path.startswith("lib/app_versions/v1/") or path.startswith("test/app_versions/v1/"):
        return "v1"
    if path.startswith("lib/app_versions/v2/") or path.startswith("test/app_versions/v2/"):
        return "v2"
    if path.startswith("lib/app_versions/v3/") or path.startswith("test/app_versions/v3/"):
        return "v3"
    if "/admin/" in f"/{path}" or path.startswith("lib/app_versions/admin/"):
        return "admin"
    if path.startswith(("lib/sale_referral/", "test/sale_referral/")):
        return "sale-referral"
    if "supabase" in parts or path.startswith("supabase/"):
        return "supabase"
    if "localdb" in parts or path.startswith("docs/DD/") and "sync" in path:
        return "storage-sync"
    if path.startswith(".codex/design/") or path.startswith(("docs/ui/", "docs/refactor/")):
        return "ui-design"
    if path.startswith("docs/DD/"):
        return parts[2] if len(parts) > 2 else "dd-index"
    if path.startswith("docs/BD/"):
        return parts[2] if len(parts) > 2 else "bd-index"
    if path.startswith("docs/"):
        return parts[1] if len(parts) > 1 else "docs"
    if path.startswith(".codex/"):
        return "agent-context"
    return parts[0] if parts else "root"


def evidence_for(path: str, lifecycle: str) -> list[str]:
    if lifecycle == "Source":
        return [path]
    if lifecycle == "Binary":
        return ["pubspec.yaml"] if path.startswith("assets/") else []
    if lifecycle == "Historical":
        return []
    if lifecycle == "Generated":
        if path.startswith((".codex/history/", ".codex/task-skills/")):
            return ["docs/worklog/"]
        if path.startswith("lib/l10n/"):
            return ["lib/l10n/app_vi.arb"]
        return []
    if path.startswith("docs/DD/"):
        module = PurePosixPath(path).parts[2] if len(PurePosixPath(path).parts) > 2 else ""
        module_roots = {
            "onboarding_profile": "lib/app_versions/v1/features/onboarding/",
            "personal_schedule_ai": "lib/app_versions/v1/services/ai/",
            "dashboard_schedule": "lib/app_versions/v1/features/dashboard/",
            "basic_health_calculators": "lib/app_versions/v1/features/body_metrics/",
            "auth_profile_sync": "lib/app_versions/v2/features/auth/",
            "membership_quota": "lib/app_versions/v2/features/usage_quota/",
            "ai_chat": "lib/app_versions/v1/features/ai_chat/",
            "health_score_habits": "lib/app_versions/v2/features/health_scoring/",
            "schedule_notifications": "lib/app_versions/v1/services/notifications/",
            "advanced_tracking_goals": "lib/app_versions/v3/features/advanced_tracking/",
            "familyplus": "lib/app_versions/v3/features/familyplus/",
            "referral_direct": "lib/sale_referral/",
            "payment_membership": "lib/app_versions/v2/features/payments/",
            "sale_points": "lib/sale_referral/",
            "admin_dashboard": "lib/app_versions/admin/",
            "admin_operations": "lib/app_versions/admin/",
            "reconciliation": "lib/app_versions/admin/",
            "reporting": "lib/app_versions/admin/",
            "audit_security": "lib/app_versions/admin/",
            "nabi_companion_notifications": "lib/features/nabi/",
        }
        return [module_roots.get(module, "lib/main.dart")]
    if path.startswith("docs/supabase/"):
        return ["docs/supabase/01_build_system.sql", "lib/services/supabase/"]
    if path.startswith(".codex/design/"):
        return ["lib/core/theme/", "lib/app_versions/v1/router/v1_router.dart"]
    if path.startswith("lib/") and PurePosixPath(path).suffix.lower() in {".md", ".txt"}:
        return [str(PurePosixPath(path).parent) + "/"]
    if path.startswith("supabase/functions/"):
        return [str(PurePosixPath(path).parent) + "/"]
    if path.startswith("docs/BD/advanced_health/"):
        return ["lib/app_versions/v2/features/health_modules/"]
    if path.startswith("docs/BD/"):
        return ["lib/main.dart", "lib/app_versions/v2/router/v2_router.dart"]
    if path.startswith("docs/checklist/"):
        return ["docs/DD/README.md", "lib/main.dart"]
    if path.startswith(".codex/"):
        return ["lib/main.dart", "pubspec.yaml"]
    return ["lib/main.dart", "pubspec.yaml"]


def explicit_implementation(path: str) -> str | None:
    if PurePosixPath(path).suffix.lower() not in {".md", ".txt"}:
        return None
    text = read_text(ROOT / path)
    if text is None:
        return None
    patterns = (
        r"(?im)^\s*\|\s*Implementation\s*\|\s*(Implemented|Partial|Placeholder|Source-only|Absent|N/A)(?:\s|\||;)",
        r"(?im)^\s*>?\s*\*\*Trạng thái implementation theo source:\*\*\s*(Implemented|Partial|Placeholder|Source-only|Absent|N/A)",
    )
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return match.group(1)
    return None


def implementation_for(path: str, lifecycle: str) -> str:
    if lifecycle not in {"Current", "Reference"}:
        return "N/A"
    explicit = explicit_implementation(path)
    if explicit is not None:
        return explicit
    if path.startswith("docs/BD/advanced_health/"):
        return "Placeholder"
    if path.startswith("docs/DD/"):
        parts = PurePosixPath(path).parts
        module = parts[2] if len(parts) > 2 else ""
        return DD_IMPLEMENTATION.get(module, "N/A")
    return "N/A"


def verification_for(path: str, lifecycle: str) -> str:
    if lifecycle == "Historical":
        return "Historical"
    if path.startswith("docs/supabase/") or "supabase" in path.lower():
        return "Sandbox-unverified"
    if lifecycle == "Reference":
        return "Runtime-unverified"
    return "Static-verified"


def review_for(lifecycle: str) -> str:
    return {
        "Current": "Semantic",
        "Historical": "Historical-context",
        "Generated": "Generated-parity",
        "Reference": "Inventory-reference",
        "Source": "Contract",
        "Binary": "Inventory",
    }[lifecycle]


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def strip_fenced_blocks(text: str) -> str:
    return FENCED_BLOCK.sub("", text)


def clean_link_target(raw: str) -> str | None:
    target = raw.strip()
    if not target:
        return None
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    elif re.search(r"\s+[\"']", target):
        target = re.split(r"\s+[\"']", target, maxsplit=1)[0]
    target = unquote(target.split("#", 1)[0].strip())
    if not target or target.startswith(("http://", "https://", "mailto:", "app://", "file://")):
        return None
    if any(token in target for token in ("{", "}", "*", "<", ">")):
        return None
    return target.replace("\\", "/")


def resolve_link(source: str, target: str, known: set[str]) -> str | None:
    source_parent = PurePosixPath(source).parent
    candidates: list[str] = []
    if target.startswith("/"):
        candidates.append(target.lstrip("/"))
    else:
        candidates.append(os.path.normpath((source_parent / target).as_posix()).replace("\\", "/"))
        if target.startswith(("docs/", ".codex/", ".agents/", "lib/", "test/", "assets/", "tools/")):
            candidates.append(os.path.normpath(target).replace("\\", "/"))
    for candidate in candidates:
        normalized = candidate.removeprefix("./")
        if normalized in known or any(path.startswith(normalized.rstrip("/") + "/") for path in known):
            return normalized
    return None


def missing_markdown_links(path: str, known: set[str]) -> list[str]:
    text = read_text(ROOT / path)
    if text is None:
        return []
    text = strip_fenced_blocks(text)
    missing: list[str] = []
    for match in MARKDOWN_LINK.finditer(text):
        target = clean_link_target(match.group("target"))
        if target is None:
            continue
        if resolve_link(path, target, known) is None:
            missing.append(target)
    return sorted(set(missing))


def kind_for(path: str) -> str:
    suffix = PurePosixPath(path).suffix.lower()
    if suffix == ".md":
        return "Markdown"
    if suffix in BINARY_EXTENSIONS:
        return "Binary asset"
    if not suffix:
        return "Extensionless"
    return suffix.removeprefix(".").upper()


def finding_and_action(lifecycle: str) -> tuple[str, str]:
    if lifecycle == "Historical":
        return (
            "Historical evidence; content is not interpreted as current runtime truth.",
            "Preserve event content and record explained legacy references in the manifest.",
        )
    if lifecycle == "Reference":
        return (
            "Reference/design input; runtime claims require separate reachable-source evidence.",
            "Inventory and path-check without promoting the artifact to implemented behavior.",
        )
    if lifecycle == "Generated":
        return (
            "Generated derivative; direct edits are not authoritative.",
            "Validate parity with its declared source or generator.",
        )
    if lifecycle == "Binary":
        return (
            "Binary/non-semantic artifact; behavior cannot be inferred from file contents.",
            "Inventory, hash and verify declaration/provenance paths.",
        )
    if lifecycle == "Source":
        return (
            "Executable/static contract source inventoried as authoritative evidence.",
            "Use this file as evidence; do not rewrite runtime behavior in the docs task.",
        )
    return (
        "Current authored artifact reviewed against declared source evidence.",
        "Keep claims aligned with reachable code/config and fail unexplained broken links.",
    )


def build_record(
    path: str,
    known: set[str],
    baseline_commit: str,
    baseline_paths: set[str],
) -> dict[str, object]:
    lifecycle = classify(path)
    target = ROOT / path
    finding, action = finding_and_action(lifecycle)
    record: dict[str, object] = {
        "path": path,
        "kind": kind_for(path),
        "lifecycle": lifecycle,
        "domain": domain_for(path),
        "baseline_commit": baseline_commit,
        "baseline_presence": "Tracked-at-baseline" if path in baseline_paths else "Session-created",
        "review": review_for(lifecycle),
        "implementation": implementation_for(path, lifecycle),
        "verification": verification_for(path, lifecycle),
        "evidence": evidence_for(path, lifecycle),
        "finding": finding,
        "action": action,
        "size_bytes": None if path == MANIFEST_REL else target.stat().st_size,
        "sha256": None if path == MANIFEST_REL else sha256(target),
    }
    if target.suffix.lower() == ".md":
        missing = missing_markdown_links(path, known)
        if missing and lifecycle in {"Historical", "Reference", "Generated"}:
            record["allowed_missing_references"] = [
                {
                    "target": item,
                    "reason": "Path is preserved as baseline/history/reference evidence and is not a current capability link.",
                }
                for item in missing
            ]
    return record


def write_manifest() -> None:
    baseline_commit = run_git("rev-parse", "HEAD")
    baseline_paths = set(run_git("ls-tree", "-r", "--name-only", baseline_commit).splitlines())
    paths = workspace_paths()
    if MANIFEST_REL not in paths:
        paths.append(MANIFEST_REL)
        paths.sort()
    known = set(paths)
    records = [
        build_record(path, known, baseline_commit, baseline_paths)
        for path in paths
        if (ROOT / path).is_file() or path == MANIFEST_REL
    ]
    counts = Counter(record["lifecycle"] for record in records)
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "baseline_commit": baseline_commit,
        "policy": {
            "runtime_truth": "Reachable code from lib/main.dart and executable data/config sources.",
            "historical_policy": "Preserve historical content; annotate lifecycle and explain missing baseline references.",
            "completion": "100% static traceability; runtime and sandbox evidence may remain explicitly unverified.",
        },
        "counts": {"files": len(records), "by_lifecycle": dict(sorted(counts.items()))},
        "records": records,
    }
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"WROTE {MANIFEST_REL}: {len(records)} files")


def validate_core_contracts(errors: list[str]) -> None:
    lib_mains = sorted(path for path in workspace_paths() if re.fullmatch(r"lib/main(?:_[^/]*)?\.dart", path))
    if lib_mains != ["lib/main.dart"]:
        errors.append(f"Expected exactly one lib entrypoint, found: {lib_mains}")

    required_fragments = {
        "lib/core/storage/localdb/database_version.dart": "currentVersion = 21",
        "lib/core/constants/onboarding_constants.dart": "totalSteps = 9",
        "lib/app_versions/v2/router/v2_router.dart": "...v1Routes",
        "lib/app/bio_ai_app.dart": "return const BioAIV2App",
        "pubspec.yaml": "sdk: ^3.9.2",
        "docs/supabase/02_seed_data.sql": "-- BEGIN GENERATED MEAL CATALOG",
        "lib/app_versions/v1/services/ai/gemini_rest_client.dart": ":generateContent",
        "lib/app_versions/v1/services/ai/ai_chat_service.dart": "gemini-3.1-flash-lite",
        "lib/app_versions/v1/services/ai/ai_service.dart": "gemini-3.1-flash-lite",
        "lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart": "gemini-2.5-flash",
        "lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart": "nabi-ai-generate",
        "android/app/build.gradle.kts": 'applicationId = "com.nanobioai.app"',
        "android/app/src/main/AndroidManifest.xml": 'android:scheme="nanobio" android:host="auth" android:pathPrefix="/callback"',
        "ios/Runner.xcodeproj/project.pbxproj": "PRODUCT_BUNDLE_IDENTIFIER = com.example.nanoApp;",
        "ios/Runner/Info.plist": "<string>nanobio</string>",
        "l10n.yaml": "template-arb-file: app_vi.arb",
        "pubspec.lock": 'dependency: "direct main"',
    }
    for relative, fragment in required_fragments.items():
        text = read_text(ROOT / relative)
        if text is None:
            errors.append(f"Required source is missing or non-UTF-8: {relative}")
        elif fragment not in text:
            errors.append(f"Source contract missing in {relative}: {fragment}")

    v2_router = read_text(ROOT / "lib/app_versions/v2/router/v2_router.dart") or ""
    for fragment in ("...v1Routes", "...v2Routes", "...v3Routes"):
        if fragment not in v2_router:
            errors.append(f"Unified router does not contain {fragment}")

    pubspec = read_text(ROOT / "pubspec.yaml") or ""
    if re.search(r"(?m)^\s*(google_generative_ai|gemini)\s*:", pubspec):
        errors.append("pubspec.yaml unexpectedly declares a Gemini SDK dependency")
    if not re.search(r"(?m)^\s*dio:\s*\^5\.9\.2\s*$", pubspec):
        errors.append("pubspec.yaml does not declare the reviewed Dio constraint ^5.9.2")

    pubspec_lock = read_text(ROOT / "pubspec.lock") or ""
    dio_lock = re.search(
        r"(?ms)^  dio:\n    dependency: \"direct main\".*?^    version: \"([^\"]+)\"",
        pubspec_lock,
    )
    if dio_lock is None or dio_lock.group(1) != "5.9.2":
        errors.append("pubspec.lock does not resolve direct Dio dependency to 5.9.2")
    if re.search(r"(?m)^  (google_generative_ai|gemini):\s*$", pubspec_lock):
        errors.append("pubspec.lock unexpectedly resolves a Gemini SDK package")

    workspace = set(workspace_paths())
    actual_supabase_sources = {
        path
        for path in workspace
        if path.startswith("docs/supabase/") and path.endswith(".sql")
    }
    missing_supabase = sorted(SUPABASE_SQL_SOURCES - actual_supabase_sources)
    if missing_supabase:
        errors.append(f"Supabase SQL source set is incomplete: {missing_supabase}")
    unexpected_supabase = sorted(actual_supabase_sources - SUPABASE_SQL_SOURCES)
    if unexpected_supabase:
        errors.append(f"Unexpected Supabase SQL sources: {unexpected_supabase}")

    required_assets = {
        "assets/data/meal_catalog_v1.json",
        "assets/config/nabi_v2/nabi_v2_asset_manifest.json",
        "lib/l10n/app_vi.arb",
        "lib/l10n/app_localizations.dart",
        "lib/l10n/app_localizations_vi.dart",
    }
    missing_assets = sorted(required_assets - workspace)
    if missing_assets:
        errors.append(f"Required asset/localization source is missing: {missing_assets}")
    for declaration in ("    - assets/", "    - assets/config/nabi_v2/", "    - assets/images/nabi_v2/"):
        if declaration not in pubspec:
            errors.append(f"pubspec asset declaration is missing: {declaration.strip()}")

    for canonical in (".codex/AGENTS.md", ".codex/README.md", "README.md", "SYSTEM_FEATURES_DOCUMENTATION.md"):
        text = read_text(ROOT / canonical) or ""
        if "Gemini SDK" in text:
            errors.append(f"Current canonical doc still claims a Gemini SDK: {canonical}")

    stale_supabase = re.compile(r"docs/supabase/[^\s)`'\"]+\.sql")
    for relative in workspace_paths():
        if not relative.startswith("test/docs/") or not relative.endswith(".dart"):
            continue
        text = read_text(ROOT / relative) or ""
        for match in stale_supabase.finditer(text):
            path = match.group(0)
            if path not in SUPABASE_SQL_SOURCES:
                errors.append(f"Stale Supabase contract path in {relative}: {path}")

    worklogs = [path for path in workspace_paths() if path.startswith("docs/worklog/") and path.endswith(".md")]
    index_text = read_text(ROOT / ".codex/history/WORKLOG_INDEX.md") or ""
    count_match = re.search(r"(?m)^- Total worklogs: (\d+)$", index_text)
    if not count_match:
        errors.append("WORKLOG_INDEX.md does not expose Total worklogs")
    elif int(count_match.group(1)) != len(worklogs):
        errors.append(
            f"WORKLOG_INDEX count is stale: index={count_match.group(1)}, workspace={len(worklogs)}"
        )

    read_only_checks = (
        ("worklog/history parity", [sys.executable, ".codex/tools/update_worklog_learning.py", "--check"]),
    )
    for label, command in read_only_checks:
        result = subprocess.run(
            command,
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
        )
        if result.returncode != 0:
            detail = result.stdout.strip().splitlines()
            errors.append(f"{label} failed: {detail[-1] if detail else 'no output'}")


def validate_manifest() -> int:
    errors: list[str] = []
    if not MANIFEST_PATH.is_file():
        print(f"SOURCE TRUTH VALIDATION FAILED\n- Missing {MANIFEST_REL}")
        return 1
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        print(f"SOURCE TRUTH VALIDATION FAILED\n- Invalid manifest: {exc}")
        return 1

    if manifest.get("schema_version") != SCHEMA_VERSION:
        errors.append(f"Unexpected manifest schema: {manifest.get('schema_version')}")
    baseline_commit = run_git("rev-parse", "HEAD")
    baseline_paths = set(run_git("ls-tree", "-r", "--name-only", baseline_commit).splitlines())
    if manifest.get("baseline_commit") != baseline_commit:
        errors.append("Manifest baseline_commit does not match HEAD")

    records = manifest.get("records")
    if not isinstance(records, list):
        errors.append("Manifest records must be a list")
        records = []

    expected = workspace_paths()
    if MANIFEST_REL not in expected:
        expected.append(MANIFEST_REL)
        expected.sort()
    actual = [record.get("path") for record in records if isinstance(record, dict)]
    duplicates = sorted(path for path, count in Counter(actual).items() if count > 1)
    if duplicates:
        errors.append(f"Duplicate manifest paths: {duplicates[:10]}")
    missing = sorted(set(expected) - set(actual))
    extra = sorted(set(actual) - set(expected))
    if missing:
        errors.append(f"Files absent from manifest ({len(missing)}): {missing[:10]}")
    if extra:
        errors.append(f"Manifest paths absent from workspace ({len(extra)}): {extra[:10]}")

    known = set(expected)
    for record in records:
        if not isinstance(record, dict):
            errors.append("Manifest contains a non-object record")
            continue
        path = record.get("path")
        if not isinstance(path, str):
            errors.append("Manifest record lacks a path")
            continue
        lifecycle = record.get("lifecycle")
        implementation = record.get("implementation")
        verification = record.get("verification")
        if lifecycle not in LIFECYCLES:
            errors.append(f"Invalid lifecycle for {path}: {lifecycle}")
        if implementation not in IMPLEMENTATION_STATES:
            errors.append(f"Invalid implementation state for {path}: {implementation}")
        if verification not in VERIFICATION_STATES:
            errors.append(f"Invalid verification state for {path}: {verification}")
        expected_metadata = {
            "kind": kind_for(path),
            "lifecycle": classify(path),
            "domain": domain_for(path),
            "baseline_commit": baseline_commit,
            "baseline_presence": "Tracked-at-baseline" if path in baseline_paths else "Session-created",
            "review": review_for(classify(path)),
            "implementation": implementation_for(path, classify(path)),
            "verification": verification_for(path, classify(path)),
            "evidence": evidence_for(path, classify(path)),
        }
        for field, expected_value in expected_metadata.items():
            if record.get(field) != expected_value:
                errors.append(
                    f"Manifest metadata is stale for {path}: {field}={record.get(field)!r}, expected {expected_value!r}"
                )
        if not isinstance(record.get("finding"), str) or not record.get("finding"):
            errors.append(f"Manifest finding is missing for {path}")
        if not isinstance(record.get("action"), str) or not record.get("action"):
            errors.append(f"Manifest action is missing for {path}")
        if path != MANIFEST_REL and path in known and (ROOT / path).is_file():
            expected_hash = record.get("sha256")
            if expected_hash != sha256(ROOT / path):
                errors.append(f"Manifest digest is stale: {path}")
        evidence = record.get("evidence", [])
        if lifecycle == "Current" and not evidence:
            errors.append(f"Current document lacks source evidence: {path}")
        for evidence_path in evidence if isinstance(evidence, list) else []:
            if not isinstance(evidence_path, str):
                errors.append(f"Invalid evidence value in {path}")
                continue
            if evidence_path.endswith(("/", "_")):
                if not any(item.startswith(evidence_path) for item in known):
                    errors.append(f"Evidence prefix does not exist for {path}: {evidence_path}")
            elif evidence_path not in known:
                errors.append(f"Evidence path does not exist for {path}: {evidence_path}")

        if path.endswith(".md") and path in known:
            missing_links = missing_markdown_links(path, known)
            allowed = {
                item.get("target")
                for item in record.get("allowed_missing_references", [])
                if isinstance(item, dict) and item.get("reason")
            }
            if record.get("allowed_missing_references") and lifecycle not in {
                "Historical",
                "Reference",
                "Generated",
            }:
                errors.append(f"Current/source artifact cannot exempt broken links: {path}")
            unexplained = sorted(set(missing_links) - allowed)
            if unexplained:
                errors.append(f"Unexplained broken links in {path}: {unexplained[:5]}")

    count_block = manifest.get("counts", {})
    if isinstance(count_block, dict) and count_block.get("files") != len(records):
        errors.append("Manifest counts.files does not equal record count")

    for required in ("docs/README.md", "docs/audit/SOURCE_TRUTH_AUDIT.md", MANIFEST_REL):
        if required not in known:
            errors.append(f"Required audit artifact is missing: {required}")

    validate_core_contracts(errors)

    if errors:
        print("SOURCE TRUTH VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    counts = Counter(record["lifecycle"] for record in records)
    print(
        "SOURCE TRUTH VALIDATION PASSED: "
        f"{len(records)} files; "
        + ", ".join(f"{key}={counts[key]}" for key in sorted(counts))
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help="Rewrite the reviewed workspace manifest before validating it.",
    )
    args = parser.parse_args()
    if args.write_manifest:
        write_manifest()
    return validate_manifest()


if __name__ == "__main__":
    sys.exit(main())
