from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime
from urllib.parse import urlsplit
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.config import Settings
from nanobio_backend.core.responses import ApiError
from nanobio_backend.db.models import WebPushReminder, WebPushSubscription
from nanobio_backend.modules.web_push.models import (
    PushSubscriptionInput,
    WebPushReminderBatch,
)

_PUSH_HOST_SUFFIXES = (
    ".push.services.mozilla.com",
    ".push.apple.com",
    ".fcm.googleapis.com",
    ".notify.windows.com",
)
_PUSH_HOSTS = {"fcm.googleapis.com", "push.services.mozilla.com"}


def get_public_config(settings: Settings) -> dict[str, object]:
    public_key = settings.web_push_vapid_public_key
    private_key = settings.web_push_vapid_private_key
    return {
        "enabled": bool(public_key and private_key),
        "public_key": public_key if public_key and private_key else None,
    }


def create_subscription(
    db: Session,
    payload: PushSubscriptionInput,
) -> dict[str, str]:
    _validate_endpoint(payload.endpoint)
    endpoint_hash = _sha256(payload.endpoint)
    capability = secrets.token_urlsafe(32)
    now = datetime.now(UTC)
    subscription = db.scalar(
        select(WebPushSubscription).where(WebPushSubscription.endpoint_hash == endpoint_hash)
    )
    if subscription is None:
        subscription = WebPushSubscription(
            guest_capability_hash=_sha256(capability),
            endpoint=payload.endpoint,
            endpoint_hash=endpoint_hash,
            p256dh_key=payload.keys.p256dh,
            auth_key=payload.keys.auth,
            timezone=payload.timezone,
            is_active=True,
            created_at=now,
            updated_at=now,
        )
        db.add(subscription)
    else:
        subscription.guest_capability_hash = _sha256(capability)
        subscription.p256dh_key = payload.keys.p256dh
        subscription.auth_key = payload.keys.auth
        subscription.timezone = payload.timezone
        subscription.is_active = True
        subscription.updated_at = now
    db.flush()
    return {"subscription_id": str(subscription.id), "capability": capability}


def replace_reminders(
    db: Session,
    subscription_id: UUID,
    capability: str,
    payload: WebPushReminderBatch,
) -> dict[str, int]:
    subscription = _owned_subscription(db, subscription_id, capability)
    now = datetime.now(UTC)
    subscription.timezone = payload.timezone
    subscription.updated_at = now
    db.query(WebPushReminder).filter(WebPushReminder.subscription_id == subscription.id).delete(
        synchronize_session=False
    )
    for item in payload.reminders:
        scheduled_at = item.scheduled_at.astimezone(UTC) if item.scheduled_at else None
        if scheduled_at is not None and scheduled_at > now:
            db.add(
                WebPushReminder(
                    subscription_id=subscription.id,
                    reminder_key=item.reminder_id,
                    category=item.category,
                    scheduled_at=scheduled_at,
                    daily_minute=None,
                    is_active=True,
                    created_at=now,
                    updated_at=now,
                )
            )
        elif item.daily_minute is not None:
            db.add(
                WebPushReminder(
                    subscription_id=subscription.id,
                    reminder_key=item.reminder_id,
                    category=item.category,
                    scheduled_at=None,
                    daily_minute=item.daily_minute,
                    is_active=True,
                    created_at=now,
                    updated_at=now,
                )
            )
    db.flush()
    return {"reminder_count": len(payload.reminders)}


def delete_subscription(
    db: Session,
    subscription_id: UUID,
    capability: str,
) -> None:
    subscription = _owned_subscription(db, subscription_id, capability)
    db.delete(subscription)


def due_reminders(db: Session, now: datetime) -> list[tuple[WebPushSubscription, WebPushReminder]]:
    rows = db.execute(
        select(WebPushSubscription, WebPushReminder)
        .join(WebPushReminder, WebPushReminder.subscription_id == WebPushSubscription.id)
        .where(WebPushSubscription.is_active.is_(True), WebPushReminder.is_active.is_(True))
        .execution_options(yield_per=250)
    )
    due: list[tuple[WebPushSubscription, WebPushReminder]] = []
    for subscription, reminder in rows:
        if reminder.daily_minute is not None:
            local_now = now.astimezone(ZoneInfo(subscription.timezone))
            last_sent_day = reminder.last_sent_on
            if (
                local_now.hour * 60 + local_now.minute >= reminder.daily_minute
                and last_sent_day != local_now.date()
            ):
                due.append((subscription, reminder))
            continue
        scheduled_at = _as_utc(reminder.scheduled_at)
        if scheduled_at is not None and scheduled_at <= now and reminder.sent_at is None:
            due.append((subscription, reminder))
    return due


def mark_reminder_sent(
    db: Session,
    reminder: WebPushReminder,
    timezone_name: str,
    now: datetime,
) -> None:
    if reminder.daily_minute is not None:
        local_day = now.astimezone(ZoneInfo(timezone_name)).date()
        reminder.last_sent_on = local_day
    else:
        reminder.sent_at = now
        reminder.is_active = False
    reminder.updated_at = now
    db.commit()


def mark_subscription_gone(db: Session, subscription: WebPushSubscription) -> None:
    subscription.is_active = False
    subscription.updated_at = datetime.now(UTC)
    db.query(WebPushReminder).filter(WebPushReminder.subscription_id == subscription.id).update(
        {WebPushReminder.is_active: False}, synchronize_session=False
    )
    db.commit()


def _owned_subscription(
    db: Session,
    subscription_id: UUID,
    capability: str,
) -> WebPushSubscription:
    normalized = capability.strip()
    if not normalized or len(normalized) > 128:
        raise ApiError(401, "WEB_PUSH_CAPABILITY_REQUIRED", "Phiên thông báo không hợp lệ.")
    subscription = db.get(WebPushSubscription, subscription_id)
    if subscription is None or not secrets.compare_digest(
        subscription.guest_capability_hash,
        _sha256(normalized),
    ):
        raise ApiError(404, "WEB_PUSH_SUBSCRIPTION_NOT_FOUND", "Không tìm thấy đăng ký thông báo.")
    return subscription


def _validate_endpoint(endpoint: str) -> None:
    try:
        parsed = urlsplit(endpoint)
        host = (parsed.hostname or "").lower().rstrip(".")
        port = parsed.port
    except ValueError as exc:
        raise ApiError(422, "INVALID_PUSH_ENDPOINT", "Địa chỉ thông báo chưa hợp lệ.") from exc

    known_host = host in _PUSH_HOSTS or any(host.endswith(suffix) for suffix in _PUSH_HOST_SUFFIXES)
    if (
        parsed.scheme != "https"
        or not host
        or parsed.username is not None
        or parsed.password is not None
        or parsed.fragment
        or (port not in (None, 443))
        or not known_host
    ):
        raise ApiError(422, "INVALID_PUSH_ENDPOINT", "Địa chỉ thông báo chưa hợp lệ.")


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)
