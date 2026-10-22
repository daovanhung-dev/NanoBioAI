import json
from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4, uuid5

from nanobio_backend.core.responses import ApiError
from nanobio_backend.modules.cloud_sync.contract import (
    BOOLEAN_COLUMNS,
    CLOUD_COLUMNS,
    JSON_COLUMNS,
    PUSH_TABLES,
    USER_PROFILE_COLUMNS,
)


def validate_snapshot(source: dict[str, object], user_id: UUID) -> dict[str, dict[str, Any]]:
    if len(json.dumps(source, ensure_ascii=False, default=str).encode("utf-8")) > 10_000_000:
        raise ApiError(413, "SNAPSHOT_TOO_LARGE", "Dữ liệu đồng bộ vượt quá giới hạn.")
    user_data = source.get("user", {})
    tables = source.get("tables", {})
    if not isinstance(user_data, dict) or not isinstance(tables, dict):
        raise ApiError(422, "INVALID_SNAPSHOT", "Dữ liệu đồng bộ chưa đúng định dạng.")
    unknown_tables = set(tables) - PUSH_TABLES
    if unknown_tables:
        raise ApiError(422, "UNSUPPORTED_SNAPSHOT_TABLE", "Bảng dữ liệu đồng bộ chưa được hỗ trợ.")

    clean_user: dict[str, Any] = {}
    for key, value in user_data.items():
        if key not in USER_PROFILE_COLUMNS or value is None:
            continue
        if key == "birth_year":
            try:
                year = int(value)
            except (TypeError, ValueError) as exc:
                raise ApiError(422, "INVALID_SNAPSHOT_PROFILE", "Năm sinh chưa hợp lệ.") from exc
            if not 1900 <= year <= 2100:
                raise ApiError(422, "INVALID_SNAPSHOT_PROFILE", "Năm sinh chưa hợp lệ.")
            clean_user[key] = year
            continue
        if not isinstance(value, str):
            raise ApiError(422, "INVALID_SNAPSHOT_PROFILE", "Thông tin hồ sơ chưa hợp lệ.")
        normalized = value.strip()
        if not normalized:
            continue
        maximum = 120 if key == "full_name" else 2048 if key == "avatar_url" else 32
        if len(normalized) > maximum:
            raise ApiError(422, "INVALID_SNAPSHOT_PROFILE", "Thông tin hồ sơ vượt giới hạn.")
        clean_user[key] = normalized
    clean_tables: dict[str, list[dict[str, Any]]] = {}
    row_count = 0
    id_map: dict[str, str] = {}
    pending_rows: dict[str, list[dict[str, Any]]] = {}
    for table in sorted(PUSH_TABLES):
        rows = tables.get(table, [])
        if not isinstance(rows, list):
            raise ApiError(422, "INVALID_SNAPSHOT", "Danh sách dữ liệu đồng bộ chưa hợp lệ.")
        if len(rows) > 10_000:
            raise ApiError(413, "SNAPSHOT_TOO_LARGE", "Một nhóm dữ liệu vượt quá giới hạn.")
        row_count += len(rows)
        if row_count > 50_000:
            raise ApiError(413, "SNAPSHOT_TOO_LARGE", "Dữ liệu đồng bộ vượt quá giới hạn.")
        pending: list[dict[str, Any]] = []
        allowed = CLOUD_COLUMNS[table]
        for source_row in rows:
            if not isinstance(source_row, dict):
                raise ApiError(422, "INVALID_SNAPSHOT", "Bản ghi đồng bộ chưa hợp lệ.")
            clean = {key: value for key, value in source_row.items() if key in allowed}
            old_id = (
                clean.get("request_id")
                if table == "personal_schedule_ai_requests"
                else clean.get("id")
            )
            if table == "personal_schedule_ai_requests":
                clean["request_id"] = _stable_id(user_id, table, old_id)
            else:
                clean["id"] = _stable_id(user_id, table, old_id)
            if isinstance(old_id, str) and old_id:
                id_map.setdefault(old_id, str(clean.get("id", clean.get("request_id"))))
            clean["user_id"] = str(user_id)
            for key, value in list(clean.items()):
                clean[key] = _normalize_value(key, value)
            pending.append(clean)
        pending_rows[table] = pending

    for table, rows in pending_rows.items():
        for row in rows:
            if "source_id" in row and isinstance(row["source_id"], str):
                row["source_id"] = id_map.get(row["source_id"], row["source_id"])
        clean_tables[table] = rows
    return {"user": clean_user, "tables": clean_tables}


def _stable_id(user_id: UUID, table: str, raw: object) -> str:
    try:
        return str(UUID(str(raw)))
    except (ValueError, TypeError, AttributeError):
        normalized = str(raw).strip() if raw is not None else ""
        return str(uuid5(user_id, f"{table}:{normalized}")) if normalized else str(uuid4())


def _normalize_value(key: str, value: Any) -> Any:
    if value is None:
        return None
    if key in BOOLEAN_COLUMNS:
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return value != 0
        return str(value).strip().casefold() in {"true", "1"}
    if key in JSON_COLUMNS and isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    if isinstance(value, datetime):
        return value.astimezone(UTC).isoformat()
    return value
