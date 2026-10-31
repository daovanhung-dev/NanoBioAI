#!/usr/bin/env python3
"""Fail fast when Flutter's Supabase contract drifts from local schema setup."""

from __future__ import annotations

from collections.abc import Iterable
from pathlib import Path
import re
import sys


FUNCTION_PATTERN = re.compile(
    r"create\s+or\s+replace\s+function\s+(?:public\.)?([a-z_][a-z0-9_]*)\s*\(",
    re.IGNORECASE,
)
TABLE_PATTERN = re.compile(
    r"create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?([a-z_][a-z0-9_]*)\b",
    re.IGNORECASE,
)
VIEW_PATTERN = re.compile(
    r"create\s+(?:or\s+replace\s+)?view\s+(?:public\.)?([a-z_][a-z0-9_]*)\b",
    re.IGNORECASE,
)
TRIGGER_PATTERN = re.compile(
    r"create\s+(?:constraint\s+)?trigger\s+([a-z_][a-z0-9_]*)\b",
    re.IGNORECASE,
)
PROCEDURE_PATTERN = re.compile(
    r"create\s+(?:or\s+replace\s+)?procedure\s+(?:public\.)?([a-z_][a-z0-9_]*)\s*\(",
    re.IGNORECASE,
)
POLICY_PATTERN = re.compile(r"create\s+policy\s+", re.IGNORECASE)
DIRECT_RPC_PATTERN = re.compile(
    r"\b(?:rpc|_rpc)\s*\(\s*['\"]([a-z][a-z0-9_]*)['\"]",
    re.IGNORECASE,
)
RPC_CONSTANT_PATTERN = re.compile(
    r"\b(?:static\s+)?const\s+(?:[A-Za-z0-9_<>?]+\s+)?\w*[Rr]pc\w*\s*=\s*['\"]([a-z][a-z0-9_]*)['\"]",
)
DIRECT_TABLE_PATTERN = re.compile(
    r"\.from\(\s*['\"]([a-z][a-z0-9_]*)['\"]",
    re.IGNORECASE,
)
STORAGE_BUCKET_PATTERN = re.compile(
    r"storage\s*\.from\(\s*['\"]([a-z][a-z0-9_-]*)['\"]",
    re.IGNORECASE,
)
STORAGE_CONSTANT_PATTERN = re.compile(
    r"(?:static\s+)?const\s+bucketName\s*=\s*['\"]([a-z][a-z0-9_-]*)['\"]",
    re.IGNORECASE,
)
RUNTIME_RPC_MANIFEST_PATTERN = re.compile(
    r"foreach\s+v_function_name\s+in\s+array\s+array\s*\["
    r"(?P<body>.*?)\]\s*loop",
    re.IGNORECASE | re.DOTALL,
)

BUILD_SYSTEM_SQL = Path("docs/supabase/01_build_system.sql")

REQUIRED_VIEWS = {"effective_user_access"}
REQUIRED_TRIGGERS = {
    "on_auth_user_created",
    "trg_membership_subscriptions_sync_user",
    "trg_payment_events_create_commission",
    "trg_schedule_completion_attempts_updated_at",
    "trg_wellness_point_ledgers_append_only",
}
REQUIRED_EDGE_FUNCTIONS = {"delete-account"}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def matches(pattern: re.Pattern[str], text: str) -> set[str]:
    return {match.group(1).lower() for match in pattern.finditer(text)}


def dart_sources(root: Path) -> Iterable[Path]:
    return root.joinpath("lib").rglob("*.dart")


def sync_tables(root: Path) -> set[str]:
    source = read(root / "lib/core/storage/localdb/sync/sync_outbox_schema.dart")
    block = re.search(
        r"genericIdUserOwnedTables\s*=\s*<String>\[(.*?)\];",
        source,
        re.DOTALL,
    )
    if block is None:
        raise RuntimeError("Could not read SyncOutboxSchema.genericIdUserOwnedTables")
    tables = set(re.findall(r"['\"]([a-z][a-z0-9_]*)['\"]", block.group(1)))
    tables.add("personal_schedule_ai_requests")
    tables.add("wellness_point_ledgers")
    return tables


def admin_dynamic_rpcs(root: Path) -> set[str]:
    source = read(
        root / "lib/app_versions/admin/features/admin_panel/data/datasources/"
        "admin_supabase_datasource.dart"
    )
    return set(re.findall(r"['\"](admin_[a-z0-9_]+)['\"]", source))


def fail_if_missing(kind: str, required: set[str], available: set[str]) -> list[str]:
    missing = sorted(required - available)
    if missing:
        return [f"{kind} missing from schema/setup: {', '.join(missing)}"]
    return []


def runtime_grant_manifest(build_system: str, functions: set[str]) -> set[str]:
    """Return the explicit runtime-RPC manifest from the build script.

    The manifest is intentionally separate from function declarations: a
    declared RPC is not necessarily callable by an authenticated Flutter user.
    """
    match = RUNTIME_RPC_MANIFEST_PATTERN.search(build_system)
    if match is None:
        raise RuntimeError("Could not locate the runtime RPC grant manifest")
    return {
        value
        for value in re.findall(r"['\"]([a-z][a-z0-9_]*)['\"]", match.group("body"))
        if value in functions
    }


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    build_system = read(root / BUILD_SYSTEM_SQL)
    functions = matches(FUNCTION_PATTERN, build_system)
    tables = matches(TABLE_PATTERN, build_system)
    views = matches(VIEW_PATTERN, build_system)
    triggers = matches(TRIGGER_PATTERN, build_system)
    procedures = matches(PROCEDURE_PATTERN, build_system)
    literal_policy_count = len(POLICY_PATTERN.findall(build_system))

    rpc_calls: set[str] = set()
    direct_tables: set[str] = set()
    storage_buckets: set[str] = set()
    for path in dart_sources(root):
        source = read(path)
        rpc_calls.update(matches(DIRECT_RPC_PATTERN, source))
        rpc_calls.update(matches(RPC_CONSTANT_PATTERN, source))
        direct_tables.update(matches(DIRECT_TABLE_PATTERN, source))
        storage_buckets.update(matches(STORAGE_BUCKET_PATTERN, source))
        storage_buckets.update(matches(STORAGE_CONSTANT_PATTERN, source))

    rpc_calls.update(admin_dynamic_rpcs(root))
    direct_tables.update(sync_tables(root))
    # Storage `.from` is also used for PostgREST tables. Keep only the two
    # buckets that are discovered from the storage client or its constant.
    storage_buckets.intersection_update(
        {"schedule-completion-proofs", "sale-payout-proofs"}
    )
    direct_tables.difference_update(storage_buckets)

    errors: list[str] = []
    errors.extend(fail_if_missing("RPC", rpc_calls, functions))
    errors.extend(fail_if_missing("table", direct_tables, tables | views))
    errors.extend(fail_if_missing("view", REQUIRED_VIEWS, views))
    errors.extend(fail_if_missing("trigger", REQUIRED_TRIGGERS, triggers))

    granted_rpc_manifest = runtime_grant_manifest(build_system, functions)
    errors.extend(
        fail_if_missing("runtime RPC grant", rpc_calls, granted_rpc_manifest)
    )
    for bucket in sorted(storage_buckets):
        if f"'{bucket}'" not in build_system:
            errors.append(f"Storage bucket missing from build system: {bucket}")

    toml = read(root / "supabase/config.toml")
    for function_name in sorted(REQUIRED_EDGE_FUNCTIONS):
        folder = root / "supabase/functions" / function_name
        if not folder.joinpath("index.ts").is_file():
            errors.append(f"Edge Function source missing: {function_name}")
        section = re.search(
            rf"^\[functions\.{re.escape(function_name)}\]\s*$(.*?)(?=^\[|\Z)",
            toml,
            re.MULTILINE | re.DOTALL,
        )
        if section is None or "verify_jwt = true" not in section.group(1):
            errors.append(f"Edge Function JWT config missing: {function_name}")

    if errors:
        print("FAIL Supabase runtime contract")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "PASS Supabase runtime contract: "
        f"build system declares {len(functions)} functions, {len(procedures)} procedures, "
        f"{len(tables)} tables, {len(views)} views, {len(triggers)} triggers and "
        f"{literal_policy_count} literal RLS policies; app uses {len(rpc_calls)} RPCs, "
        f"{len(direct_tables)} tables/views, {len(REQUIRED_TRIGGERS)} critical triggers, "
        f"{len(storage_buckets)} buckets and {len(REQUIRED_EDGE_FUNCTIONS)} Edge Function(s)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
