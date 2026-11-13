"""Send generic, privacy preserving web push reminders."""

from __future__ import annotations

import json
import logging
from datetime import UTC, datetime

from pywebpush import WebPushException, webpush  # type: ignore[import-untyped]
from sqlalchemy.orm import Session

from nanobio_backend.core.config import get_settings
from nanobio_backend.core.database import create_session_factory
from nanobio_backend.modules.web_push import view

logger = logging.getLogger("nanobio.web_push")


def dispatch_due_reminders(db: Session, *, now: datetime | None = None) -> dict[str, int]:
    settings = get_settings()
    public_key = settings.web_push_vapid_public_key
    private_key = settings.web_push_vapid_private_key
    if not public_key or not private_key:
        return {"sent": 0, "failed": 0, "disabled": 0}

    current = now or datetime.now(UTC)
    result = {"sent": 0, "failed": 0, "disabled": 0}
    for subscription, reminder in view.due_reminders(db, current):
        try:
            webpush(
                subscription_info={
                    "endpoint": subscription.endpoint,
                    "keys": {
                        "p256dh": subscription.p256dh_key,
                        "auth": subscription.auth_key,
                    },
                },
                data=json.dumps(
                    {
                        "title": "NanoBio",
                        "body": "Bạn có một lời nhắc. Mở ứng dụng để xem.",
                        "url": "/sleep-tracking?source=scheduled_reminder"
                        if reminder.category == "sleep_safety"
                        else "/",
                    },
                    ensure_ascii=False,
                ),
                vapid_private_key=private_key.get_secret_value(),
                vapid_claims={"sub": settings.web_push_vapid_subject},
                ttl=600,
                timeout=8,
            )
            view.mark_reminder_sent(db, reminder, subscription.timezone, current)
            result["sent"] += 1
        except WebPushException as exc:
            status_code = exc.response.status_code if exc.response is not None else None
            if status_code in {404, 410}:
                view.mark_subscription_gone(db, subscription)
                result["disabled"] += 1
            else:
                logger.warning("Web push delivery failed (status=%s)", status_code)
                result["failed"] += 1
        except Exception as exc:
            logger.warning("Web push delivery failed (type=%s)", type(exc).__name__)
            result["failed"] += 1
            db.rollback()
        db.expire(reminder)
        db.expire(subscription)
    return result


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    settings = get_settings()
    _engine, factory = create_session_factory(settings)
    with factory() as db:
        result = dispatch_due_reminders(db)
    logger.info(
        "Web push worker complete: sent=%d failed=%d disabled=%d",
        result["sent"],
        result["failed"],
        result["disabled"],
    )


if __name__ == "__main__":
    main()
