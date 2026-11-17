import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.security import verify_password
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import (
    IotDevice,
    IotDeviceConsent,
    IotDeviceCredential,
    IotDeviceSession,
    IotPairingSession,
    User,
    now_utc,
)
from nanobio_backend.modules.auth import query as auth_query
from nanobio_backend.modules.auth import validate as auth_validate
from nanobio_backend.modules.auth.view import _subject_hash, consume_rate_limit
from nanobio_backend.modules.iot import query
from nanobio_backend.modules.iot.models import DeviceConsentRequest

PAIRING_TTL_SECONDS = 120
DEVICE_ACCESS_TTL_SECONDS = 15 * 60
DEVICE_REFRESH_TTL_DAYS = 90
SENSITIVE_UNLOCK_TTL_SECONDS = 5 * 60
SNAPSHOT_MAX_AGE_DAYS = 90


def _token_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _utc(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def _is_expired(value: datetime | None, now: datetime) -> bool:
    return value is None or _utc(value) <= now


def _issue_device_credentials(device: IotDevice, settings: Any) -> dict[str, Any]:
    now = now_utc()
    access_token = secrets.token_urlsafe(32)
    refresh_token = secrets.token_urlsafe(48)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "access_token_hash": _token_hash(access_token),
        "refresh_token_hash": _token_hash(refresh_token),
        "access_expires_at": now + timedelta(seconds=DEVICE_ACCESS_TTL_SECONDS),
        "refresh_expires_at": now + timedelta(days=DEVICE_REFRESH_TTL_DAYS),
        "access_expires_in": DEVICE_ACCESS_TTL_SECONDS,
        "device_id": device.id,
        "websocket_url": settings.iot_websocket_url,
        "protocol_version": 3,
    }


def create_pairing_session(db: Session, user: User) -> dict[str, Any]:
    token = secrets.token_urlsafe(32)
    expires = now_utc() + timedelta(seconds=PAIRING_TTL_SECONDS)
    row = IotPairingSession(
        id=uuid4(),
        owner_id=user.id,
        token_hash=_token_hash(token),
        expires_at=expires,
    )
    with atomic(db):
        db.add(row)
    return {
        "pairing_session_id": str(row.id),
        "pairing_token": token,
        "expires_at": expires.isoformat(),
        "expires_in": PAIRING_TTL_SECONDS,
    }


def authenticate_device(
    db: Session,
    request: Any,
    *,
    device_id: str,
    identifier_type: str,
    identifier: str,
    password: str,
    client_ip: str,
) -> dict[str, Any]:
    if identifier_type == "phone":
        normalized_identifier = auth_validate.normalize_vietnam_phone(identifier)
        user = auth_query.get_user_by_phone(db, normalized_identifier)
    elif identifier_type == "email":
        normalized_identifier = identifier.strip().lower()
        if "@" not in normalized_identifier:
            raise ApiError(422, "INVALID_EMAIL", "Email chưa hợp lệ.")
        user = auth_query.get_user_by_email(db, normalized_identifier)
    elif identifier_type == "username":
        normalized_identifier = auth_validate.normalize_username(identifier)
        user = auth_query.get_user_by_username(db, normalized_identifier)
    else:
        raise ApiError(422, "LOGIN_IDENTIFIER_REQUIRED", "Hãy nhập thông tin đăng nhập.")

    subject_hash = _subject_hash(
        request,
        f"{identifier_type}:{normalized_identifier}:{client_ip}",
    )
    # Commit the attempt counter separately so failed password checks cannot roll it back.
    with atomic(db):
        rate_limited = consume_rate_limit(
            db,
            scope="iot-device-auth",
            subject_hash=subject_hash,
            limit=10,
            window_seconds=900,
        )
    if rate_limited:
        raise ApiError(429, "RATE_LIMITED", "Bạn đã thử đăng nhập quá nhiều lần.")

    with atomic(db):
        if identifier_type == "phone":
            user = auth_query.get_user_by_phone(db, normalized_identifier)
        elif identifier_type == "email":
            user = auth_query.get_user_by_email(db, normalized_identifier)
        else:
            user = auth_query.get_user_by_username(db, normalized_identifier)
        if (
            user is None
            or not user.is_active
            or user.admin_status != "active"
            or user.force_password_change
            or not verify_password(user.password_hash, password)
        ):
            raise ApiError(401, "INVALID_CREDENTIALS", "Thông tin đăng nhập chưa đúng.")

        if db.get_bind().dialect.name == "postgresql":
            db.execute(select(func.pg_advisory_xact_lock(func.hashtext(device_id))))
        device = query.get_device(db, device_id, for_update=True)
        if (
            device is not None
            and device.owner_id is not None
            and device.unbound_at is None
            and device.owner_id != user.id
        ):
            raise ApiError(
                409,
                "DEVICE_ALREADY_CLAIMED",
                "Thiết bị đã được liên kết với tài khoản khác.",
            )

        now = now_utc()
        if device is None:
            device = IotDevice(
                id=device_id,
                owner_id=user.id,
                name=f"Nabi {device_id[-6:]}",
                created_at=now,
                updated_at=now,
            )
            db.add(device)
            db.flush()
        else:
            was_unbound = device.unbound_at is not None or device.owner_id is None
            device.owner_id = user.id
            device.unbound_at = None
            device.updated_at = now
            if was_unbound:
                consent = query.get_consent(db, device.id)
                if consent is not None:
                    db.delete(consent)
            # Reauthentication rotates the token and ends any previous WebSocket lease.
            session = query.get_session(db, device.id)
            if session is not None:
                db.delete(session)

        values = _issue_device_credentials(device, request.app.state.settings)
        credentials = query.get_credentials(db, device.id, for_update=True)
        if credentials is None:
            credentials = IotDeviceCredential(
                device_id=device.id,
                access_token_hash=values["access_token_hash"],
                access_expires_at=values["access_expires_at"],
                refresh_token_hash=values["refresh_token_hash"],
                refresh_expires_at=values["refresh_expires_at"],
                updated_at=now,
            )
            db.add(credentials)
        else:
            credentials.access_token_hash = values["access_token_hash"]
            credentials.access_expires_at = values["access_expires_at"]
            credentials.refresh_token_hash = values["refresh_token_hash"]
            credentials.refresh_expires_at = values["refresh_expires_at"]
            credentials.revoked_at = None
            credentials.updated_at = now

    return {
        key: value
        for key, value in values.items()
        if not key.endswith("_hash") and not key.endswith("_at")
    }


def get_pairing_session(db: Session, user: User, pairing_id: UUID) -> dict[str, Any]:
    row = query.get_pairing_for_owner(db, pairing_id, user.id)
    if row is None:
        raise ApiError(404, "PAIRING_SESSION_NOT_FOUND", "Phiên ghép thiết bị không còn tồn tại.")
    now = now_utc()
    if row.claimed_at is not None:
        status = "claimed"
    elif _is_expired(row.expires_at, now):
        status = "expired"
    else:
        status = "pending"
    device = query.get_device(db, row.device_id) if row.device_id else None
    return {
        "pairing_session_id": str(row.id),
        "status": status,
        "expires_at": _utc(row.expires_at).isoformat(),
        "device_id": row.device_id,
        "device_name": device.name if device else None,
    }


def claim_device(
    db: Session,
    request: Any,
    *,
    device_id: str,
    pairing_token: str,
    name: str | None,
) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        pairing = query.get_pairing_by_token(db, _token_hash(pairing_token), for_update=True)
        if (
            pairing is None
            or pairing.claimed_at is not None
            or _is_expired(pairing.expires_at, now)
        ):
            raise ApiError(
                401, "PAIRING_TOKEN_INVALID", "Mã ghép thiết bị đã hết hạn hoặc đã dùng."
            )

        if db.get_bind().dialect.name == "postgresql":
            db.execute(select(func.pg_advisory_xact_lock(func.hashtext(device_id))))

        device = query.get_device(db, device_id, for_update=True)
        if (
            device is not None
            and device.owner_id is not None
            and device.unbound_at is None
            and device.owner_id != pairing.owner_id
        ):
            raise ApiError(
                409, "DEVICE_ALREADY_CLAIMED", "Thiết bị đã được liên kết với tài khoản khác."
            )

        display_name = (name or f"Nabi {device_id[-6:]}").strip()
        if device is None:
            device = IotDevice(
                id=device_id,
                owner_id=pairing.owner_id,
                name=display_name,
                created_at=now,
                updated_at=now,
            )
            db.add(device)
            db.flush()
        else:
            was_unbound = device.unbound_at is not None or device.owner_id is None
            device.owner_id = pairing.owner_id
            device.name = display_name
            device.unbound_at = None
            device.updated_at = now
            if was_unbound:
                consent = query.get_consent(db, device.id)
                if consent is not None:
                    db.delete(consent)
            session = query.get_session(db, device.id)
            if session is not None:
                db.delete(session)

        values = _issue_device_credentials(device, request.app.state.settings)
        credentials = query.get_credentials(db, device.id, for_update=True)
        if credentials is None:
            credentials = IotDeviceCredential(
                device_id=device.id,
                access_token_hash=values["access_token_hash"],
                access_expires_at=values["access_expires_at"],
                refresh_token_hash=values["refresh_token_hash"],
                refresh_expires_at=values["refresh_expires_at"],
                updated_at=now,
            )
            db.add(credentials)
        else:
            credentials.access_token_hash = values["access_token_hash"]
            credentials.access_expires_at = values["access_expires_at"]
            credentials.refresh_token_hash = values["refresh_token_hash"]
            credentials.refresh_expires_at = values["refresh_expires_at"]
            credentials.revoked_at = None
            credentials.updated_at = now

        pairing.claimed_at = now
        pairing.device_id = device.id

    return {
        key: value
        for key, value in values.items()
        if not key.endswith("_hash") and not key.endswith("_at")
    }


def refresh_device_credentials(
    db: Session,
    request: Any,
    *,
    device_id: str,
    refresh_token: str,
) -> dict[str, Any]:
    now = now_utc()
    with atomic(db):
        credentials = query.get_credentials_by_refresh(
            db, _token_hash(refresh_token), for_update=True
        )
        if (
            credentials is None
            or credentials.device_id != device_id
            or credentials.revoked_at is not None
            or _is_expired(credentials.refresh_expires_at, now)
        ):
            raise ApiError(
                401, "DEVICE_CREDENTIAL_INVALID", "Thông tin kết nối của thiết bị đã hết hạn."
            )
        device = query.get_device(db, device_id, for_update=True)
        if device is None or device.owner_id is None or device.unbound_at is not None:
            credentials.revoked_at = now
            raise ApiError(
                401, "DEVICE_CREDENTIAL_INVALID", "Thiết bị chưa được liên kết với tài khoản."
            )

        values = _issue_device_credentials(device, request.app.state.settings)
        credentials.access_token_hash = values["access_token_hash"]
        credentials.access_expires_at = values["access_expires_at"]
        credentials.refresh_token_hash = values["refresh_token_hash"]
        credentials.refresh_expires_at = values["refresh_expires_at"]
        credentials.updated_at = now
    return {
        key: value
        for key, value in values.items()
        if not key.endswith("_hash") and not key.endswith("_at")
    }


def list_devices(db: Session, user: User) -> list[dict[str, Any]]:
    now = now_utc()
    result = []
    for device in query.list_devices(db, user.id):
        consent = query.get_consent(db, device.id)
        session = query.get_session(db, device.id)
        result.append(
            {
                "device_id": device.id,
                "name": device.name,
                "created_at": _utc(device.created_at).isoformat(),
                "connected": bool(session and not _is_expired(session.lease_expires_at, now)),
                "consent": {
                    "identity": consent.identity if consent else False,
                    "profile_goals": consent.profile_goals if consent else False,
                    "sensitive_health": consent.sensitive_health if consent else False,
                    "recent_tracking": consent.recent_tracking if consent else False,
                },
            }
        )
    return result


def rename_device(db: Session, user: User, device_id: str, name: str) -> dict[str, str]:
    with atomic(db):
        device = query.get_owned_device(db, device_id, user.id, for_update=True)
        if device is None:
            raise ApiError(404, "DEVICE_NOT_FOUND", "Không tìm thấy thiết bị trong tài khoản này.")
        device.name = name.strip()
        device.updated_at = now_utc()
    return {"device_id": device_id, "name": device.name}


def update_device_consent(
    db: Session, user: User, device_id: str, consent: DeviceConsentRequest
) -> dict[str, bool]:
    with atomic(db):
        device = query.get_owned_device(db, device_id, user.id, for_update=True)
        if device is None:
            raise ApiError(404, "DEVICE_NOT_FOUND", "Không tìm thấy thiết bị trong tài khoản này.")
        row = query.get_consent(db, device_id)
        if row is None:
            row = IotDeviceConsent(device_id=device_id, updated_at=now_utc())
            db.add(row)
        changed = any(
            getattr(row, field) != getattr(consent, field)
            for field in ("identity", "profile_goals", "sensitive_health", "recent_tracking")
        )
        row.identity = consent.identity
        row.profile_goals = consent.profile_goals
        row.sensitive_health = consent.sensitive_health
        row.recent_tracking = consent.recent_tracking
        row.updated_at = now_utc()
        if changed:
            session = query.get_session(db, device_id, for_update=True)
            if session is not None:
                session.sensitive_unlocked_until = None
    return {
        "identity": consent.identity,
        "profile_goals": consent.profile_goals,
        "sensitive_health": consent.sensitive_health,
        "recent_tracking": consent.recent_tracking,
    }


def unlock_sensitive_context(db: Session, user: User, device_id: str) -> dict[str, str | int]:
    now = now_utc()
    with atomic(db):
        device = query.get_owned_device(db, device_id, user.id, for_update=True)
        if device is None:
            raise ApiError(404, "DEVICE_NOT_FOUND", "Không tìm thấy thiết bị trong tài khoản này.")
        session = query.get_session(db, device_id, for_update=True)
        if (
            session is None
            or session.connection_id is None
            or _is_expired(session.lease_expires_at, now)
        ):
            raise ApiError(
                409, "DEVICE_NOT_CONNECTED", "Hãy kết nối thiết bị trước khi mở dữ liệu sức khỏe."
            )
        session.sensitive_unlocked_until = now + timedelta(seconds=SENSITIVE_UNLOCK_TTL_SECONDS)
        session.last_seen_at = now
        session.lease_expires_at = now + timedelta(seconds=45)
        expires = session.sensitive_unlocked_until
    return {"unlocked_until": expires.isoformat(), "expires_in": SENSITIVE_UNLOCK_TTL_SECONDS}


def unbind_device(db: Session, user: User, device_id: str) -> dict[str, bool]:
    now = now_utc()
    with atomic(db):
        device = query.get_owned_device(db, device_id, user.id, for_update=True)
        if device is None:
            raise ApiError(404, "DEVICE_NOT_FOUND", "Không tìm thấy thiết bị trong tài khoản này.")
        device.owner_id = None
        device.unbound_at = now
        device.updated_at = now
        credentials = query.get_credentials(db, device_id, for_update=True)
        if credentials is not None:
            credentials.revoked_at = now
        db.execute(delete(IotDeviceSession).where(IotDeviceSession.device_id == device_id))
        db.execute(delete(IotDeviceConsent).where(IotDeviceConsent.device_id == device_id))
    return {"unbound": True, "credentials_revoked": True}


def build_personal_context(
    db: Session,
    *,
    owner_id: UUID,
    device_id: str,
    connection_id: str,
    now: datetime | None = None,
    snapshot_max_age_days: int = SNAPSHOT_MAX_AGE_DAYS,
) -> tuple[str, list[str]]:
    current = now or now_utc()
    user = db.get(User, owner_id)
    device = query.get_owned_device(db, device_id, owner_id)
    if user is None or device is None:
        raise ApiError(
            401, "DEVICE_CREDENTIAL_INVALID", "Thiết bị chưa được liên kết với tài khoản."
        )

    consent = query.get_consent(db, device_id)
    lease = query.get_session(db, device_id)
    unlocked = bool(
        lease
        and lease.connection_id == connection_id
        and lease.sensitive_unlocked_until is not None
        and not _is_expired(lease.sensitive_unlocked_until, current)
    )
    snapshot = query.get_mobile_snapshot(db, owner_id)
    snapshot_fresh = bool(
        snapshot
        and timedelta(0)
        <= current - _utc(snapshot.updated_at)
        <= timedelta(days=snapshot_max_age_days)
    )
    payload: dict[str, Any] = (
        snapshot.payload if snapshot and isinstance(snapshot.payload, dict) else {}
    )
    raw_user = payload.get("user")
    snapshot_user: dict[str, Any] = raw_user if isinstance(raw_user, dict) else {}
    raw_tables = payload.get("tables")
    tables: dict[str, Any] = raw_tables if isinstance(raw_tables, dict) else {}
    facts: list[str] = []
    limitations: list[str] = []

    if consent and consent.identity and user.full_name.strip():
        facts.append(f"Tên người dùng: {_clean_text(user.full_name, 100)}")

    if consent and consent.profile_goals:
        gender = user.gender or snapshot_user.get("gender")
        birth_year = user.birth_year or snapshot_user.get("birth_year")
        if gender:
            facts.append(f"Giới tính do người dùng cung cấp: {_clean_text(gender, 32)}")
        if birth_year:
            facts.append(f"Năm sinh do người dùng cung cấp: {_clean_text(birth_year, 8)}")
        if snapshot_fresh:
            goals = _rows(tables, "health_goals", ("goal_name", "goal_code"), limit=5)
            goals += _rows(tables, "nutrition_goals", ("goal_name", "goal_code"), limit=5)
            if goals:
                facts.append("Mục tiêu đã ghi nhận: " + "; ".join(goals[:8]))
        else:
            limitations.append("Chưa có snapshot mục tiêu gần đây; không suy đoán mục tiêu.")

    sensitive_enabled = bool(consent and consent.sensitive_health)
    tracking_enabled = bool(consent and consent.recent_tracking)
    if (sensitive_enabled or tracking_enabled) and not unlocked:
        limitations.append("Dữ liệu sức khỏe nhạy cảm chưa được người dùng mở khóa trong ứng dụng.")
    elif unlocked and not snapshot_fresh:
        limitations.append(
            "Snapshot sức khỏe đã cũ hoặc chưa có; không xem dữ liệu cũ là hiện tại."
        )
    elif unlocked and snapshot_fresh:
        if sensitive_enabled:
            sensitive_tables: tuple[tuple[str, str, tuple[str, ...]], ...] = (
                ("health_conditions", "Tình trạng sức khỏe", ("condition_name", "severity_level")),
                ("food_allergies", "Dị ứng thực phẩm", ("allergy_name", "note")),
                (
                    "medical_treatments",
                    "Điều trị đã ghi nhận",
                    ("treatment_name", "medication_name", "note"),
                ),
                ("medication_records", "Thuốc đã ghi nhận", ("name", "usage_schedule", "note")),
                (
                    "food_restrictions",
                    "Hạn chế thực phẩm",
                    ("item_name", "restriction_type", "severity_level"),
                ),
                (
                    "lab_results",
                    "Kết quả xét nghiệm",
                    ("test_name", "value_text", "unit", "measured_at"),
                ),
                (
                    "health_symptoms",
                    "Triệu chứng đã ghi nhận",
                    ("symptom_type", "severity_level", "started_at", "note"),
                ),
            )
            for table_name, label, columns in sensitive_tables:
                rows = _rows(tables, table_name, columns, limit=4)
                if rows:
                    facts.append(f"{label}: " + "; ".join(rows))
        if tracking_enabled:
            tracking_tables: tuple[tuple[str, str, tuple[str, ...]], ...] = (
                (
                    "health_tracking_logs",
                    "Theo dõi gần đây",
                    (
                        "log_date",
                        "weight_kg",
                        "blood_pressure",
                        "blood_sugar",
                        "heart_rate_bpm",
                        "oxygen_saturation",
                        "sleep_hours",
                        "steps_count",
                    ),
                ),
                (
                    "health_profiles",
                    "Chỉ số hồ sơ",
                    ("height_cm", "weight_kg", "blood_pressure", "blood_sugar", "bmi"),
                ),
            )
            for table_name, label, columns in tracking_tables:
                rows = _rows(tables, table_name, columns, limit=3)
                if rows:
                    facts.append(f"{label}: " + "; ".join(rows))

    if not facts:
        limitations.append("Không có thông tin cá nhân được đồng ý sử dụng trong phiên này.")
    return "\n".join(facts), limitations


def _rows(tables: Any, table_name: str, columns: tuple[str, ...], *, limit: int) -> list[str]:
    raw = tables.get(table_name, []) if isinstance(tables, dict) else []
    if not isinstance(raw, list):
        return []
    output: list[str] = []
    for row in raw[-limit:]:
        if not isinstance(row, dict):
            continue
        parts = []
        for key in columns:
            value = row.get(key)
            if value is None or (
                isinstance(value, (dict, list, bool)) and not isinstance(value, bool)
            ):
                continue
            value_text = _clean_text(value, 140)
            if value_text:
                parts.append(f"{key}={value_text}")
        if parts:
            output.append(", ".join(parts))
    return output


def _clean_text(value: object, maximum: int) -> str:
    text = " ".join(str(value).split())
    return text[:maximum]
