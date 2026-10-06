#!/usr/bin/env python3
"""Refresh the source-backed UI inventory from the current Dart tree.

The inventory is intentionally heuristic: it identifies UI-owned Dart files
and reports source markers, but it is not a visual or runtime certification.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
INVENTORY = ROOT / ".codex/design/inventory"
AUDIT_CSV = INVENTORY / "ui_source_audit.csv"
STATUS_CSV = INVENTORY / "coding_implementation_status.csv"

AUDIT_COLUMNS = [
    "path", "group", "kind", "archetype", "loc", "classes", "enums",
    "role", "widget_bases", "imports_count", "features",
    "animation_controller", "animated_container", "animated_switcher",
    "animated_opacity", "animated_scale", "animated_size",
    "tween_animation_builder", "hero", "fade_transition",
    "slide_transition", "scale_transition", "rotation_transition",
    "show_dialog", "bottom_sheet", "haptic", "system_sound",
    "audio_package", "raw_duration", "raw_color", "colors_direct",
    "app_motion", "ticker", "semantics", "media_query", "text_scale",
    "repaint_boundary", "image_asset", "nabi", "refresh_indicator",
    "dismissible", "implicit_animation",
]
STATUS_COLUMNS = [
    "path", "group", "kind", "implementation_status", "evidence",
    "runtime_certification",
]
SURFACE_STATUS_COLUMNS = [
    "surface_id", "name", "source_classification", "redesign_status",
    "verification_status", "evidence", "remaining",
]

MARKERS = {
    "animation_controller": r"\bAnimationController\s*\(",
    "animated_container": r"\bAnimatedContainer\s*\(",
    "animated_switcher": r"\bAnimatedSwitcher\s*\(",
    "animated_opacity": r"\bAnimatedOpacity\s*\(",
    "animated_scale": r"\bAnimatedScale\s*\(",
    "animated_size": r"\bAnimatedSize\s*\(",
    "tween_animation_builder": r"\bTweenAnimationBuilder\s*<",
    "hero": r"\bHero\s*\(",
    "fade_transition": r"\bFadeTransition\s*\(",
    "slide_transition": r"\bSlideTransition\s*\(",
    "scale_transition": r"\bScaleTransition\s*\(",
    "rotation_transition": r"\bRotationTransition\s*\(",
    "show_dialog": r"\bshow(?:General)?Dialog\s*<|\bshowDialog\s*\(",
    "bottom_sheet": r"\bshow(?:Modal)?BottomSheet\s*\(",
    "haptic": r"\bHapticFeedback\.",
    "system_sound": r"\bSystemSound\.play\s*\(",
    "audio_package": r"package:(?:audioplayers|just_audio|flutter_tts)/",
    "raw_duration": r"\bDuration\s*\(",
    "raw_color": r"\bColor\s*\(\s*0x|\bColor\.from(?:ARGB|RGBO)\s*\(",
    "colors_direct": r"\bColors\.",
    "app_motion": r"\bAppMotion|\bAppViewMotion|\bMotionFoundation|\bAppDirectionalSwitcher",
    "ticker": r"\bTickerProviderStateMixin\b|\bSingleTickerProviderStateMixin\b",
    "semantics": r"\bSemantics\s*\(",
    "media_query": r"\bMediaQuery\.(?:of|maybeOf|sizeOf|textScalerOf)\s*\(",
    "text_scale": r"\bTextScaler\b|\btextScaleFactor\b",
    "repaint_boundary": r"\bRepaintBoundary\s*\(",
    "image_asset": r"\b(?:Image\.asset|AssetImage)\s*\(",
    "nabi": r"\bNabi[A-Z]\w*|\bnabi\w*",
    "refresh_indicator": r"\bRefreshIndicator\s*\(",
    "dismissible": r"\bDismissible\s*\(",
    "implicit_animation": r"\b(?:AnimatedAlign|AnimatedPadding|AnimatedPositioned|AnimatedRotation|AnimatedCrossFade|AnimatedPhysicalModel)\s*\(",
}

GROUP_ARCHETYPES = {
    "01_foundation_shell": "Application foundation and shared presentation",
    "02_splash_onboarding": "Progressive onboarding and authentication",
    "03_dashboard_menu": "Dashboard and primary navigation",
    "04_ai_chat_voice": "AI conversation and voice interaction",
    "05_meal_nutrition": "Meal planning and nutrition",
    "06_schedule_proof": "Schedule, activity and proof surfaces",
    "07_health_tracking": "Health tracking and care states",
    "08_features_care": "Feature discovery and contextual care",
    "09_auth_profile_settings": "Profile, preferences and settings",
    "10_v2_v3_membership": "Membership, V2 and V3 experiences",
    "11_sale_admin": "Operational, Sale and Admin workspaces",
    "12_nabi_global": "Nabi shared experience and presentation",
}


def read_rows(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    with path.open(newline="", encoding="utf-8") as handle:
        return {row["path"]: row for row in csv.DictReader(handle)}


def included(path: Path, previous: set[str]) -> bool:
    rel = path.relative_to(ROOT).as_posix()
    parts = path.parts
    return (
        rel in previous
        or "/presentation/" in rel
        or rel.startswith("lib/app/")
        or rel.startswith("lib/core/theme/")
        or ("/router/" in rel and ("app_versions" in parts or rel.startswith("lib/app/router/")))
    )


def group_for(rel: str) -> str:
    if rel.startswith(("lib/app/", "lib/core/theme/")) or "/app/" in rel and "app_versions" in rel:
        return "01_foundation_shell"
    if "app_versions/admin/" in rel or "sale_referral/presentation/" in rel:
        return "11_sale_admin"
    if "app_versions/v2/" in rel or "app_versions/v3/" in rel:
        return "10_v2_v3_membership"
    if "features/nabi/" in rel:
        return "12_nabi_global"
    if any(part in rel for part in ("features/onboarding/", "features/splash/", "features/auth/")):
        return "02_splash_onboarding"
    if "features/dashboard/" in rel:
        return "03_dashboard_menu"
    if any(part in rel for part in ("features/ai_chat/", "features/ai_voice/")):
        return "04_ai_chat_voice"
    if any(part in rel for part in ("features/meal_plan/", "features/nutrition/")):
        return "05_meal_nutrition"
    if any(part in rel for part in ("features/lifestyle_schedule/", "features/fitness_training/", "features/today_tasks/")):
        return "06_schedule_proof"
    if any(part in rel for part in ("features/sleep_tracking/", "features/stress_tracking/", "features/body_metrics/", "features/water_tracking/", "features/weekly_summary/", "features/health_check_in/")):
        return "07_health_tracking"
    if any(part in rel for part in ("features/features_hub/", "features/quick_care/", "features/gentle_care_mode/", "features/personal_goals/", "features/other/")):
        return "08_features_care"
    if any(part in rel for part in ("features/profile/", "features/settings/", "features/notification_care/")):
        return "09_auth_profile_settings"
    return "01_foundation_shell"


def kind_for(path: Path, previous: dict[str, dict[str, str]]) -> str:
    rel = path.relative_to(ROOT).as_posix()
    if rel in previous:
        return previous[rel].get("kind", "presentation_support")
    if "/router/" in rel or rel.endswith("_routes.dart"):
        return "router"
    if "/theme/" in rel:
        return "token" if any(x in path.stem for x in ("color", "spacing", "radius", "shadow", "duration", "motion")) else "theme"
    if "/primitives/" in rel:
        return "primitive"
    if "/controllers/" in rel:
        return "controller"
    if "/pages/" in rel or path.stem.endswith("_page"):
        return "page"
    if "/widgets/" in rel or path.stem.endswith("_widget"):
        return "widget"
    return "presentation_support"


def feature_flags(text: str) -> str:
    checks = {
        "animation_controller": r"\bAnimationController\s*\(",
        "animated_container": r"\bAnimatedContainer\s*\(",
        "animated_switcher": r"\bAnimatedSwitcher\s*\(",
        "animated_opacity": r"\bAnimatedOpacity\s*\(",
        "animated_scale": r"\bAnimatedScale\s*\(",
        "animated_size": r"\bAnimatedSize\s*\(",
        "tween_animation_builder": r"\bTweenAnimationBuilder\s*<",
        "hero": r"\bHero\s*\(",
        "fade_transition": r"\bFadeTransition\s*\(",
        "slide_transition": r"\bSlideTransition\s*\(",
        "scale_transition": r"\bScaleTransition\s*\(",
        "rotation_transition": r"\bRotationTransition\s*\(",
        "show_dialog": r"\bshow(?:General)?Dialog\s*<|\bshowDialog\s*\(",
        "bottom_sheet": r"\bshow(?:Modal)?BottomSheet\s*\(",
        "haptic": r"\bHapticFeedback\.",
        "system_sound": r"\bSystemSound\.play\s*\(",
        "audio_package": r"package:(?:audioplayers|just_audio|flutter_tts)/",
        "raw_duration": r"\bDuration\s*\(",
        "raw_color": r"\bColor\s*\(\s*0x|\bColor\.from(?:ARGB|RGBO)\s*\(",
        "colors_direct": r"\bColors\.",
        "app_motion": r"\bAppMotion|\bAppViewMotion|\bMotionFoundation|\bAppDirectionalSwitcher",
        "ticker": r"\bTickerProviderStateMixin\b|\bSingleTickerProviderStateMixin\b",
        "semantics": r"\bSemantics\s*\(",
        "media_query": r"\bMediaQuery\.(?:of|maybeOf|sizeOf|textScalerOf)\s*\(",
        "text_scale": r"\bTextScaler\b|\btextScaleFactor\b",
        "repaint_boundary": r"\bRepaintBoundary\s*\(",
        "image_asset": r"\b(?:Image\.asset|AssetImage)\s*\(",
        "nabi": r"\bNabi[A-Z]\w*|\bnabi\w*",
        "refresh_indicator": r"\bRefreshIndicator\s*\(",
        "dismissible": r"\bDismissible\s*\(",
        "implicit_animation": r"\b(?:AnimatedAlign|AnimatedPadding|AnimatedPositioned|AnimatedRotation|AnimatedCrossFade|AnimatedPhysicalModel)\s*\(",
    }
    return "|".join(name for name, pattern in checks.items() if re.search(pattern, text))


def audit_row(path: Path, previous: dict[str, dict[str, str]]) -> dict[str, str]:
    rel = path.relative_to(ROOT).as_posix()
    text = path.read_text(encoding="utf-8", errors="replace")
    group = group_for(rel)
    names = re.findall(r"^\s*(?:abstract\s+)?(?:sealed\s+|base\s+|final\s+)?(?:class|mixin|extension|enum)\s+(\w+)", text, re.M)
    enums = re.findall(r"^\s*enum\s+(\w+)", text, re.M)
    classes = [name for name in names if name not in enums]
    widgets = re.findall(r"extends\s+(?:Consumer)?(?:Stateful)?Widget\b|extends\s+StatelessWidget\b|extends\s+ConsumerWidget\b", text)
    kind = kind_for(path, previous)
    row = {column: "" for column in AUDIT_COLUMNS}
    row.update({
        "path": rel,
        "group": group,
        "kind": kind,
        "archetype": GROUP_ARCHETYPES[group],
        "loc": str(len(text.splitlines())),
        "classes": "|".join(classes),
        "enums": "|".join(enums),
        "role": " / ".join(classes[:4]) or path.stem,
        "widget_bases": "|".join(sorted(set(re.findall(r"extends\s+([\w<>]+Widget)\b", text)))),
        "imports_count": str(len(re.findall(r"^import\s+", text, re.M))),
        "features": feature_flags(text),
    })
    for field, pattern in MARKERS.items():
        row[field] = str(len(re.findall(pattern, text)))
    return row


def write_csv(path: Path, columns: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def refresh_surface_status() -> int:
    registry = ROOT / ".codex/design/13_SCREEN_REGISTRY.md"
    status_path = INVENTORY / "SURFACE_IMPLEMENTATION_STATUS.csv"
    previous: dict[str, dict[str, str]] = {}
    if status_path.exists():
        with status_path.open(newline="", encoding="utf-8") as handle:
            previous = {row["surface_id"]: row for row in csv.DictReader(handle)}
    entries = re.findall(
        r"^- \*\*([A-Z0-9-]+) — (.+?)\*\* · `([^`]+)` · (.+)$",
        registry.read_text(encoding="utf-8"), re.M,
    )
    direct = {
        "V1-04": "direct_redesign_applied",
        "V1-07": "direct_redesign_applied",
        "V1-10": "direct_redesign_applied",
        "V1-13": "direct_redesign_applied",
        "V1-25": "direct_redesign_applied",
        "V1-26": "direct_redesign_applied",
        "V1-X12": "shared_gate_migrated",
        "V1-X13": "shared_shell_migrated",
        "V1-X14": "direct_redesign_applied",
        "V1-X15": "shared_shell_migrated",
        "V1-X16": "direct_redesign_applied",
        "V1-X17": "semantic_token_migrated",
    }
    rows = []
    for surface_id, name, classification, source in entries:
        old = previous.get(surface_id, {})
        implementation = direct.get(surface_id, old.get("redesign_status", "shared_foundation_applied"))
        evidence = old.get(
            "evidence",
            "Shared Blue Wellness semantic colors, Material component defaults, spacing/shape/motion and surface roles are updated; per-surface rendered evidence is not yet recorded.",
        )
        remaining = old.get(
            "remaining",
            "Verify this surface's applicable loading/empty/error/ready/locked states, light/dark contrast, responsive widths and text scales; record rendered evidence.",
        )
        verification = old.get(
            "verification_status",
            "shared_theme_suite_passed;surface_render_pending",
        )
        if surface_id == "V1-04":
            evidence = (
                "Dashboard summary cards now use MedicalSurfaceCard and the score ring scales with text size; "
                "dashboard widget suite passed at 320 dp/text scale 1.6. Full-page/device rendering remains pending."
            )
            remaining = (
                "Render dashboard loading/error/ready and action sheets across light/dark, reduced motion, "
                "320/360/412/600+ widths and 1.0/1.3/1.6 text scale; record Xiaomi profile evidence."
            )
        rows.append({
            "surface_id": surface_id,
            "name": name,
            "source_classification": classification,
            "redesign_status": implementation,
            "verification_status": verification,
            "evidence": evidence,
            "remaining": remaining,
        })
    write_csv(status_path, SURFACE_STATUS_COLUMNS, rows)
    return len(rows)


def refresh_context_manifest(source_count: int, surface_count: int) -> int:
    manifest = ROOT / ".codex/design/CONTEXT_MANIFEST.md"
    previous_paths = re.findall(
        r"^\| `([^`]+)` \|",
        manifest.read_text(encoding="utf-8") if manifest.exists() else "",
        re.M,
    )
    required_paths = [
        ".codex/design/README.md",
        ".codex/design/00_NABI_KINETIC_AURA_MASTER_DESIGN.md",
        ".codex/design/02_COLOR_LIGHT_DEPTH_SYSTEM.md",
        ".codex/design/03_MOTION_SYSTEM.md",
        ".codex/design/05_SOUND_HAPTIC_SYSTEM.md",
        ".codex/design/12_UI_FILE_DESIGN_MATRIX.md",
        ".codex/design/13_SCREEN_REGISTRY.md",
        ".codex/design/14_ROUTE_MATRIX.md",
        ".codex/design/15_CODING_PLAN.md",
        ".codex/design/16_ACCEPTANCE_CHECKLIST.md",
        ".codex/design/17_THEME_MIGRATION_MAP.md",
        ".codex/design/21_CODING_IMPLEMENTATION_STATUS.md",
        ".codex/design/21_ADMIN_DESIGN_SYSTEM.md",
        ".codex/design/22_SALE_DESIGN_SYSTEM.md",
        ".codex/design/inventory/COVERAGE_REPORT.md",
        ".codex/design/inventory/DESIGN_TOKEN_MAPPING.md",
        ".codex/design/inventory/SOURCE_DRIFT_NOTES.md",
        ".codex/design/inventory/ui_source_audit.csv",
        ".codex/design/inventory/coding_implementation_status.csv",
        ".codex/design/inventory/SURFACE_IMPLEMENTATION_STATUS.csv",
        "tools/refresh_ui_design_inventory.py",
        "design.md",
    ]
    paths = list(dict.fromkeys(previous_paths + required_paths))
    paths.extend(
        path.relative_to(ROOT).as_posix()
        for path in sorted((ROOT / ".codex/design/screens").glob("*.md"))
    )
    rows = []
    for rel in dict.fromkeys(paths):
        path = ROOT / rel
        if not path.is_file() or path == manifest:
            continue
        content = path.read_bytes()
        rows.append((rel, len(content), hashlib.sha256(content).hexdigest()))
    header = (
        "# Canonical Design Control Manifest\n\n"
        f"Generated for the current Blue Wellness source snapshot on {__import__('datetime').date.today().isoformat()}. "
        f"Tracks selected canonical documents, {surface_count} screen/surface specs, and {source_count} UI source files; hashes do not prove render or QA acceptance.\n\n"
        "| File | Bytes | SHA-256 |\n|---|---:|---|\n"
    )
    body = "".join(f"| `{rel}` | {size} | `{digest}` |\n" for rel, size, digest in rows)
    manifest.write_text(header + body, encoding="utf-8")
    return len(rows)


def main() -> int:
    old_audit = read_rows(AUDIT_CSV)
    old_status = read_rows(STATUS_CSV)
    prior_paths = set(old_audit)
    sources = sorted(path for path in LIB.rglob("*.dart") if included(path, prior_paths))
    audit = [audit_row(path, old_audit) for path in sources]
    status: list[dict[str, str]] = []
    for row in audit:
        prior = old_status.get(row["path"])
        if prior:
            status.append({
                "path": row["path"], "group": row["group"], "kind": row["kind"],
                "implementation_status": prior.get("implementation_status", ""),
                "evidence": prior.get("evidence", ""),
                "runtime_certification": prior.get("runtime_certification", ""),
            })
        else:
            status.append({
                "path": row["path"], "group": row["group"], "kind": row["kind"],
                "implementation_status": "source_inventory_added",
                "evidence": "Discovered by current-source inventory refresh; visual redesign review is pending.",
                "runtime_certification": "pending_flutter_device_validation",
            })
    INVENTORY.mkdir(parents=True, exist_ok=True)
    write_csv(AUDIT_CSV, AUDIT_COLUMNS, audit)
    write_csv(STATUS_CSV, STATUS_COLUMNS, status)
    (INVENTORY / "ui_source_audit.json").write_text(
        json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    surface_count = refresh_surface_status()
    manifest_count = refresh_context_manifest(len(audit), surface_count)
    print(f"Refreshed {len(audit)} UI-owned Dart source rows from {len(sources)} files.")
    print(f"Added {len(set(r['path'] for r in audit) - prior_paths)} files; runtime certification remains separate.")
    print(f"Tracked {surface_count} current screen/surface specs; rendered acceptance remains separate.")
    print(f"Refreshed {manifest_count} canonical design manifest hashes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
