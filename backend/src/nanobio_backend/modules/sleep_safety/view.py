import hashlib
import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.config import Settings
from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import (
    SleepSafetyContact,
    SleepSafetyDispatch,
    SleepSafetyEvent,
    SleepSafetyPreference,
    SleepSafetySession,
    SleepSafetyVerificationChallenge,
    User,
    now_utc,
)
from nanobio_backend.modules.sleep_safety import query, validate
from nanobio_backend.services.sleep_safety_provider import (
    ProviderResult,
    ProviderStatus,
    send_message,
    terminal_failure,
)

VERIFICATION_MESSAGE = (
    "Mã xác minh người liên hệ an toàn NanoBio của bạn là {code}. Mã có hiệu lực trong 10 phút."
)
VOICE_MESSAGE = (
    "NanoBio đang gửi cảnh báo an toàn giấc ngủ. "
    "Vui lòng kiểm tra tình trạng của người thân ngay khi có thể."
)
SMS_MESSAGE = (
    "NanoBio phát hiện một tình huống âm thanh cần chú ý trong phiên giám sát giấc ngủ "
    "và người dùng chưa xác nhận an toàn. Vui lòng liên hệ hoặc kiểm tra người thân."
)


@dataclass(frozen=True)
class DispatchSnapshot:
    event_id: str
    user_id: UUID
    contact_id: UUID
    priority: int
    channel: str
    idempotency_key: str


def runtime_config(settings: Settings) -> dict[str, object]:
    provider_token = settings.sleep_safety_provider_token
    callback_secret = settings.sleep_safety_provider_webhook_secret
    provider_configured = bool(
        settings.sleep_safety_provider_base_url
        and provider_token
        and provider_token.get_secret_value().strip()
    )
    enabled = settings.sleep_safety_enabled and provider_configured
    return {
        "enabled": enabled,
        "provider": "generic_http" if provider_configured else None,
        "verification_enabled": enabled,
        "dispatch_enabled": enabled,
        "webhook_configured": bool(
            callback_secret
            and callback_secret.get_secret_value().strip()
            and settings.public_api_base_url
        ),
        "event_freshness_seconds": settings.sleep_safety_event_freshness_seconds,
        "max_dispatches_per_hour": settings.sleep_safety_max_dispatches_per_hour,
    }


def sync_preference(db: Session, user: User, *, values: dict[str, object]) -> dict[str, object]:
    with atomic(db):
        preference = db.get(SleepSafetyPreference, user.id)
        if preference is None:
            preference = SleepSafetyPreference(user_id=user.id)
            db.add(preference)
        for field, value in values.items():
            setattr(preference, field, value)
        preference.selected_weekdays = sorted(set(preference.selected_weekdays))
        return {"saved": True}


def sync_session(
    db: Session, user: User, *, session_id: str, values: dict[str, object]
) -> dict[str, object]:
    normalized_id = session_id.strip()
    if not normalized_id or len(normalized_id) > 160:
        raise ApiError(422, "INVALID_SESSION_ID", "Mã phiên giám sát chưa hợp lệ.")
    with atomic(db):
        session = db.get(SleepSafetySession, normalized_id)
        if session is not None and session.user_id != user.id:
            raise ApiError(
                409, "SESSION_OWNERSHIP_CONFLICT", "Phiên giám sát không thuộc tài khoản này."
            )
        if session is None:
            session = SleepSafetySession(id=normalized_id, user_id=user.id)
            db.add(session)
        for field, value in values.items():
            setattr(session, field, value)
        return {"id": session.id, "saved": True}


def sync_event(
    db: Session,
    user: User,
    *,
    event_id: str,
    values: dict[str, object],
) -> dict[str, object]:
    normalized_id = event_id.strip()
    if not normalized_id or len(normalized_id) > 160:
        raise ApiError(422, "INVALID_EVENT_ID", "Mã sự kiện chưa hợp lệ.")
    session_id = str(values["session_id"])
    with atomic(db):
        session = db.get(SleepSafetySession, session_id)
        if session is None or session.user_id != user.id:
            raise ApiError(409, "SESSION_NOT_FOUND", "Phiên giám sát chưa sẵn sàng để đồng bộ.")
        event = db.get(SleepSafetyEvent, normalized_id)
        if event is not None and event.user_id != user.id:
            raise ApiError(409, "EVENT_OWNERSHIP_CONFLICT", "Sự kiện không thuộc tài khoản này.")
        if event is None:
            event = SleepSafetyEvent(
                id=normalized_id, user_id=user.id, detected_at=datetime.now(UTC)
            )
            db.add(event)
        for field, value in values.items():
            setattr(event, field, value)
        return {"id": event.id, "saved": True}


def list_history(
    db: Session, user: User, *, limit: int, before: datetime | None
) -> dict[str, list[dict[str, object]]]:
    sessions_stmt = select(SleepSafetySession).where(SleepSafetySession.user_id == user.id)
    events_stmt = select(SleepSafetyEvent).where(SleepSafetyEvent.user_id == user.id)
    if before is not None:
        sessions_stmt = sessions_stmt.where(SleepSafetySession.started_at < before)
        events_stmt = events_stmt.where(SleepSafetyEvent.detected_at < before)
    sessions = list(
        db.scalars(sessions_stmt.order_by(SleepSafetySession.started_at.desc()).limit(limit))
    )
    events = list(
        db.scalars(events_stmt.order_by(SleepSafetyEvent.detected_at.desc()).limit(limit))
    )
    return {
        "sessions": [
            {
                "id": row.id,
                "started_at": row.started_at.isoformat(),
                "ended_at": row.ended_at.isoformat() if row.ended_at else None,
                "scheduled_window_start": (
                    row.scheduled_window_start.isoformat() if row.scheduled_window_start else None
                ),
                "scheduled_window_end": (
                    row.scheduled_window_end.isoformat() if row.scheduled_window_end else None
                ),
                "sensitivity": row.sensitivity,
                "calibration_noise_floor": row.calibration_noise_floor,
                "status": row.status,
                "start_source": row.start_source,
                "stop_reason": row.stop_reason,
                "platform": row.platform,
                "app_version": row.app_version,
                "created_at": row.created_at.isoformat(),
                "updated_at": row.updated_at.isoformat(),
            }
            for row in sessions
        ],
        "events": [
            {
                "id": row.id,
                "session_id": row.session_id,
                "detected_at": row.detected_at.isoformat(),
                "event_type": row.event_type,
                "severity": row.severity,
                "confidence": row.confidence,
                "relative_energy": row.relative_energy,
                "baseline_delta": row.baseline_delta,
                "repetition_count": row.repetition_count,
                "state": row.state,
                "response": row.response,
                "response_at": row.response_at.isoformat() if row.response_at else None,
                "escalation_required": row.escalation_required,
                "escalation_status": row.escalation_status,
                "created_at": row.created_at.isoformat(),
                "updated_at": row.updated_at.isoformat(),
            }
            for row in events
        ],
    }


def upsert_contact(
    db: Session,
    user: User,
    *,
    contact_id: UUID | None,
    name: str,
    relationship: str,
    phone_e164: str,
    priority: int,
    allow_phone_fallback: bool,
    allow_unverified_voice_alert: bool,
) -> dict[str, object]:
    phone = validate.normalize_contact_phone(phone_e164)
    with atomic(db):
        contact = (
            query.get_contact(db, user.id, contact_id, active_only=False) if contact_id else None
        )
        if contact_id and contact is None:
            raise ApiError(404, "CONTACT_NOT_FOUND", "Không tìm thấy người liên hệ.")
        if contact is None:
            contact = SleepSafetyContact(
                user_id=user.id, name=name, phone=phone, relation=relationship
            )
            db.add(contact)
        elif contact.phone != phone:
            contact.phone = phone
            contact.verification_status = "pending"
            contact.verified_at = None
        contact.name = name.strip()
        contact.relation = relationship.strip()
        contact.priority = priority
        contact.sort_order = priority
        contact.active = True
        contact.allow_phone_fallback = allow_phone_fallback
        contact.allow_unverified_voice_alert = allow_unverified_voice_alert
        contact.updated_at = now_utc()
        db.flush()
        return _contact_view(contact)


def _contact_view(contact: SleepSafetyContact) -> dict[str, object]:
    return {
        "id": str(contact.id),
        "user_id": str(contact.user_id),
        "name": contact.name,
        "relationship": contact.relation,
        "phone_e164": contact.phone,
        "priority": contact.priority,
        "active": contact.active,
        "allow_phone_fallback": contact.allow_phone_fallback,
        "verification_status": contact.verification_status,
        "verified_at": contact.verified_at.isoformat() if contact.verified_at else None,
        "allow_unverified_voice_alert": contact.allow_unverified_voice_alert,
        "created_at": contact.created_at.isoformat() if contact.created_at else None,
        "updated_at": contact.updated_at.isoformat() if contact.updated_at else None,
    }


def list_contact_views(db: Session, user: User) -> list[dict[str, object]]:
    contacts = query.list_contacts(db, user.id)
    db.commit()
    return [_contact_view(row) for row in contacts]


def delete_contact(db: Session, user: User, contact_id: UUID) -> bool:
    with atomic(db):
        contact = query.get_contact(db, user.id, contact_id, active_only=False)
        if contact is None:
            return False
        db.delete(contact)
    return True


def request_or_confirm_verification(
    db: Session,
    user: User,
    *,
    action: str,
    contact_id: UUID,
    code: str | None,
    settings: Settings,
    callback_url: str | None,
) -> dict[str, object]:
    if not settings.sleep_safety_enabled:
        raise ApiError(503, "SLEEP_SAFETY_DISABLED", "Tính năng an toàn giấc ngủ chưa được bật.")
    contact = query.get_contact(db, user.id, contact_id)
    db.commit()
    if contact is None:
        raise ApiError(404, "CONTACT_NOT_FOUND", "Không tìm thấy người liên hệ.")
    if action == "request":
        now = now_utc()
        with atomic(db):
            recent = query.recent_challenge_count(
                db, user.id, contact_id, now - timedelta(minutes=10)
            )
            if recent >= 3:
                raise ApiError(
                    429, "VERIFICATION_RATE_LIMITED", "Bạn đã yêu cầu mã xác minh quá nhiều lần."
                )
            code_value = f"{secrets.randbelow(1_000_000):06d}"
            ttl = max(120, min(settings.sleep_safety_verification_ttl_seconds, 1800))
            expires = now + timedelta(seconds=ttl)
            challenge = SleepSafetyVerificationChallenge(
                user_id=user.id,
                contact_id=contact_id,
                code_hash=hashlib.sha256(code_value.encode()).hexdigest(),
                expires_at=expires,
                status="pending",
            )
            db.add(challenge)
            db.flush()
            challenge_id = challenge.id
        provider = send_message(
            base_url=settings.sleep_safety_provider_base_url,
            token=settings.sleep_safety_provider_token.get_secret_value()
            if settings.sleep_safety_provider_token
            else None,
            channel="verification",
            to=contact.phone,
            message=VERIFICATION_MESSAGE.format(code=code_value),
            idempotency_key=f"verify-{challenge_id}",
            callback_url=callback_url,
            callback_token=(
                settings.sleep_safety_provider_webhook_secret.get_secret_value()
                if settings.sleep_safety_provider_webhook_secret
                else None
            ),
        )
        if terminal_failure(provider.status):
            with atomic(db):
                row = db.get(SleepSafetyVerificationChallenge, challenge_id)
                if row is not None:
                    row.status = "locked"
            raise ApiError(502, "VERIFICATION_PROVIDER_FAILED", "Chưa thể gửi mã xác minh lúc này.")
        return {"accepted": True, "expires_at": expires.isoformat()}
    if action != "confirm":
        raise ApiError(422, "UNSUPPORTED_ACTION", "Thao tác xác minh chưa được hỗ trợ.")
    if not validate.validate_code(code):
        raise ApiError(422, "VERIFICATION_CODE_INVALID", "Mã xác minh chưa hợp lệ.")
    failure: ApiError | None = None
    verified = False
    with atomic(db):
        challenge_row = query.active_challenge(db, user.id, contact_id)
        if challenge_row is None:
            raise ApiError(410, "VERIFICATION_CHALLENGE_MISSING", "Mã xác minh đã hết hạn.")
        expires = challenge_row.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=UTC)
        if expires <= now_utc():
            challenge_row.status = "expired"
            failure = ApiError(410, "VERIFICATION_CODE_EXPIRED", "Mã xác minh đã hết hạn.")
        elif challenge_row.attempt_count >= 5:
            challenge_row.status = "locked"
            failure = ApiError(
                429, "VERIFICATION_ATTEMPT_LIMIT", "Bạn đã nhập sai mã quá nhiều lần."
            )
        else:
            actual_hash = hashlib.sha256((code or "").encode()).hexdigest()
            if not secrets.compare_digest(actual_hash, challenge_row.code_hash):
                challenge_row.attempt_count += 1
                if challenge_row.attempt_count >= 5:
                    challenge_row.status = "locked"
                failure = ApiError(400, "VERIFICATION_CODE_INVALID", "Mã xác minh chưa đúng.")
            else:
                challenge_row.status = "verified"
                contact.verification_status = "verified"
                contact.verified_at = now_utc()
                verified = True
    if failure is not None:
        raise failure
    if not verified:
        raise ApiError(500, "INTERNAL_SERVER_ERROR", "Đã xảy ra lỗi hệ thống.")
    return {"verified": True}


def _persist_dispatch(
    db: Session,
    *,
    event_id: str,
    user_id: UUID,
    contact: SleepSafetyContact,
    channel: str,
    idempotency_key: str,
    result: ProviderResult,
) -> None:
    status = "noAnswer" if result.status == "no_answer" else result.status
    with atomic(db):
        existing = db.scalar(
            select(SleepSafetyDispatch)
            .where(
                SleepSafetyDispatch.user_id == user_id,
                SleepSafetyDispatch.idempotency_key == idempotency_key,
                SleepSafetyDispatch.contact_id == contact.id,
                SleepSafetyDispatch.channel == channel,
            )
            .with_for_update()
        )
        if existing is None:
            db.add(
                SleepSafetyDispatch(
                    event_id=event_id,
                    user_id=user_id,
                    contact_id=contact.id,
                    priority=contact.priority,
                    channel=channel,
                    provider="generic_http",
                    provider_external_id=result.external_id or None,
                    status=status,
                    idempotency_key=idempotency_key,
                )
            )


def _send_dispatch(
    db: Session,
    settings: Settings,
    *,
    event_id: str,
    user_id: UUID,
    contact: SleepSafetyContact,
    channel: str,
    idempotency_key: str,
    callback_url: str | None,
) -> ProviderStatus:
    provider = send_message(
        base_url=settings.sleep_safety_provider_base_url,
        token=settings.sleep_safety_provider_token.get_secret_value()
        if settings.sleep_safety_provider_token
        else None,
        channel=channel,  # type: ignore[arg-type]
        to=contact.phone,
        message=VOICE_MESSAGE if channel == "voice" else SMS_MESSAGE,
        idempotency_key=f"{idempotency_key}-{contact.id}-{channel}",
        callback_url=callback_url,
        callback_token=(
            settings.sleep_safety_provider_webhook_secret.get_secret_value()
            if settings.sleep_safety_provider_webhook_secret
            else None
        ),
    )
    _persist_dispatch(
        db,
        event_id=event_id,
        user_id=user_id,
        contact=contact,
        channel=channel,
        idempotency_key=idempotency_key,
        result=provider,
    )
    return provider.status


def dispatch_event(
    db: Session,
    user: User,
    *,
    event_id: str,
    idempotency_key: str,
    settings: Settings,
    callback_url: str | None,
) -> dict[str, object]:
    if not settings.sleep_safety_enabled:
        raise ApiError(503, "SLEEP_SAFETY_DISABLED", "Tính năng an toàn giấc ngủ chưa được bật.")
    now = now_utc()
    event = query.get_event(db, user.id, event_id)
    existing = query.existing_dispatches(db, user.id, idempotency_key)
    if existing:
        db.commit()
        return {"accepted": True, "reused": True, "attempts": len(existing)}
    if not query.paid_access(db, user.id, now):
        db.commit()
        raise ApiError(403, "PAID_ACCESS_REQUIRED", "Tính năng này cần gói thành viên phù hợp.")
    if event is None:
        db.commit()
        raise ApiError(409, "EVENT_NOT_ELIGIBLE", "Sự kiện chưa đủ điều kiện gửi thông báo.")
    detected = (
        event.detected_at if event.detected_at.tzinfo else event.detected_at.replace(tzinfo=UTC)
    )
    age = (now - detected).total_seconds()
    if (
        not event.escalation_required
        or event.response != "noResponse"
        or age < 0
        or age > max(60, settings.sleep_safety_event_freshness_seconds)
    ):
        db.commit()
        raise ApiError(409, "EVENT_NOT_ELIGIBLE", "Sự kiện chưa đủ điều kiện gửi thông báo.")
    recent = query.distinct_recent_dispatch_count(db, user.id, now - timedelta(hours=1))
    if recent >= settings.sleep_safety_max_dispatches_per_hour:
        db.commit()
        raise ApiError(
            429, "DISPATCH_RATE_LIMITED", "Bạn đã gửi quá nhiều cảnh báo trong thời gian ngắn."
        )
    contacts = [
        contact
        for contact in query.list_contacts(db, user.id)
        if 1 <= contact.priority <= 3
        and (contact.verification_status == "verified" or contact.allow_unverified_voice_alert)
    ]
    contacts.sort(key=lambda contact: contact.priority)
    db.commit()
    if not contacts:
        raise ApiError(409, "ELIGIBLE_CONTACT_REQUIRED", "Cần có người liên hệ đủ điều kiện trước.")
    for contact in contacts:
        voice = _send_dispatch(
            db,
            settings,
            event_id=event.id,
            user_id=user.id,
            contact=contact,
            channel="voice",
            idempotency_key=idempotency_key,
            callback_url=callback_url,
        )
        if not terminal_failure(voice):
            return {
                "accepted": True,
                "reused": False,
                "priority": contact.priority,
                "channel": "voice",
            }
        if contact.verification_status != "verified":
            continue
        sms = _send_dispatch(
            db,
            settings,
            event_id=event.id,
            user_id=user.id,
            contact=contact,
            channel="sms",
            idempotency_key=idempotency_key,
            callback_url=callback_url,
        )
        if not terminal_failure(sms):
            return {
                "accepted": True,
                "reused": False,
                "priority": contact.priority,
                "channel": "sms",
            }
    raise ApiError(502, "ALL_CONTACTS_FAILED", "Chưa thể gửi cảnh báo đến người liên hệ.")


def process_provider_webhook(
    db: Session,
    settings: Settings,
    *,
    external_id: str,
    provider_status: object,
    callback_token: str | None,
    callback_url: str | None,
) -> dict[str, object]:
    secret = settings.sleep_safety_provider_webhook_secret
    if secret is None or not secrets.compare_digest(
        callback_token or "", secret.get_secret_value()
    ):
        raise ApiError(401, "INVALID_CALLBACK_TOKEN", "Thông tin xác thực callback chưa hợp lệ.")
    if not external_id:
        raise ApiError(400, "PROVIDER_ID_REQUIRED", "Thiếu mã phản hồi từ nhà cung cấp.")
    from nanobio_backend.services.sleep_safety_provider import normalize_status

    status = normalize_status(provider_status)
    with atomic(db):
        dispatch = db.scalar(
            select(SleepSafetyDispatch)
            .where(SleepSafetyDispatch.provider_external_id == external_id)
            .with_for_update()
        )
        if dispatch is None:
            return {"accepted": True, "ignored": True}
        dispatch.status = "noAnswer" if status == "no_answer" else status
        snapshot = DispatchSnapshot(
            event_id=dispatch.event_id,
            user_id=dispatch.user_id,
            contact_id=dispatch.contact_id,
            priority=dispatch.priority,
            channel=dispatch.channel,
            idempotency_key=dispatch.idempotency_key,
        )
    if not terminal_failure(status):
        return {"accepted": True, "continued": False}
    # Continue the source-defined cascade after a provider callback reports a terminal failure.
    event_id = snapshot.event_id
    user_id = snapshot.user_id
    start_priority = snapshot.priority
    contacts = query.list_contacts(db, user_id, after_priority=start_priority)
    same = query.get_contact(db, user_id, snapshot.contact_id)
    db.commit()
    if (
        snapshot.channel == "voice"
        and same
        and same.verification_status == "verified"
        and not query.already_attempted(db, snapshot.idempotency_key, same.id, "sms")
    ):
        db.commit()
        result = _send_dispatch(
            db,
            settings,
            event_id=event_id,
            user_id=user_id,
            contact=same,
            channel="sms",
            idempotency_key=snapshot.idempotency_key,
            callback_url=callback_url,
        )
        if not terminal_failure(result):
            return {"accepted": True, "continued": True}
    for contact in contacts:
        if not (1 <= contact.priority <= 3) or not (
            contact.verification_status == "verified" or contact.allow_unverified_voice_alert
        ):
            continue
        if not query.already_attempted(db, snapshot.idempotency_key, contact.id, "voice"):
            db.commit()
            voice = _send_dispatch(
                db,
                settings,
                event_id=event_id,
                user_id=user_id,
                contact=contact,
                channel="voice",
                idempotency_key=snapshot.idempotency_key,
                callback_url=callback_url,
            )
            if not terminal_failure(voice):
                return {"accepted": True, "continued": True}
        if contact.verification_status == "verified" and not query.already_attempted(
            db, snapshot.idempotency_key, contact.id, "sms"
        ):
            db.commit()
            sms = _send_dispatch(
                db,
                settings,
                event_id=event_id,
                user_id=user_id,
                contact=contact,
                channel="sms",
                idempotency_key=snapshot.idempotency_key,
                callback_url=callback_url,
            )
            if not terminal_failure(sms):
                return {"accepted": True, "continued": True}
    return {"accepted": True, "continued": False}
