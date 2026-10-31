from datetime import UTC, datetime, time, timedelta
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import case, select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import (
    UsageEvent,
    UsageQuotaCounter,
    UsageQuotaRule,
    User,
    now_utc,
)
from nanobio_backend.modules.membership.query import list_active
from nanobio_backend.modules.usage_quota.models import QuotaRequest


def check_quota(db: Session, user: User, payload: QuotaRequest) -> dict[str, Any]:
    return _evaluate(db, user, payload, commit=False)


def commit_quota(db: Session, user: User, payload: QuotaRequest) -> dict[str, Any]:
    with atomic(db):
        db.scalar(select(User.id).where(User.id == user.id).with_for_update())
        return _evaluate(db, user, payload, commit=True)


def _evaluate(db: Session, user: User, payload: QuotaRequest, *, commit: bool) -> dict[str, Any]:
    plan_code = _current_plan(db, user)
    rule = db.scalar(
        select(UsageQuotaRule)
        .where(
            UsageQuotaRule.plan_code == plan_code,
            UsageQuotaRule.feature_key == payload.feature_key,
            UsageQuotaRule.is_active.is_(True),
        )
        .order_by(
            case(
                (UsageQuotaRule.period_unit == "none", 0),
                (UsageQuotaRule.period_unit == "day", 1),
                (UsageQuotaRule.period_unit == "month", 2),
                (UsageQuotaRule.period_unit == "lifetime", 3),
                else_=4,
            )
        )
    )
    if rule is None or rule.period_unit == "none" or rule.max_count is None:
        period_key = "none"
        reset_at = None
        used_count = 0
        limit_count = None
    else:
        current = datetime.now(UTC)
        try:
            timezone = ZoneInfo(rule.reset_timezone or "Asia/Ho_Chi_Minh")
        except ZoneInfoNotFoundError as exc:
            raise ApiError(
                503, "QUOTA_CONFIGURATION_INVALID", "Quyền sử dụng chưa sẵn sàng."
            ) from exc
        local_now = current.astimezone(timezone)
        if rule.period_unit == "day":
            period_key = local_now.date().isoformat()
            next_local = datetime.combine(local_now.date() + timedelta(days=1), time.min, timezone)
            reset_at = next_local.astimezone(UTC)
        elif rule.period_unit == "month":
            period_key = local_now.strftime("%Y-%m")
            next_month = (local_now.year + (local_now.month == 12), local_now.month % 12 + 1)
            next_local = datetime(next_month[0], next_month[1], 1, tzinfo=timezone)
            reset_at = next_local.astimezone(UTC)
        elif rule.period_unit == "lifetime":
            period_key = "lifetime"
            reset_at = None
        else:
            raise ApiError(503, "QUOTA_CONFIGURATION_INVALID", "Quyền sử dụng chưa sẵn sàng.")
        counter = db.scalar(
            select(UsageQuotaCounter).where(
                UsageQuotaCounter.user_id == user.id,
                UsageQuotaCounter.feature_key == payload.feature_key,
                UsageQuotaCounter.period_key == period_key,
            )
        )
        used_count = counter.used_count if counter is not None else 0
        limit_count = rule.max_count

    prior_event = db.scalar(
        select(UsageEvent).where(
            UsageEvent.user_id == user.id,
            UsageEvent.feature_key == payload.feature_key,
            UsageEvent.idempotency_key == payload.request_id,
        )
    )
    if prior_event is not None:
        return _result(
            allowed=True,
            committed=True,
            used_count=used_count,
            limit_count=limit_count,
            reset_at=reset_at,
            reason_code=None,
        )

    allowed = limit_count is None or used_count + 1 <= limit_count
    if not allowed or not commit:
        return _result(
            allowed=allowed,
            committed=False,
            used_count=used_count,
            limit_count=limit_count,
            reset_at=reset_at,
            reason_code=None if allowed else "quota_exceeded",
        )

    now = now_utc()
    db.add(
        UsageEvent(
            user_id=user.id,
            feature_key=payload.feature_key,
            period_key=period_key,
            count_delta=1,
            idempotency_key=payload.request_id,
            event_source="trusted_backend",
            metadata_json={"plan_code": plan_code},
            created_at=now,
        )
    )
    if limit_count is not None:
        counter = db.scalar(
            select(UsageQuotaCounter)
            .where(
                UsageQuotaCounter.user_id == user.id,
                UsageQuotaCounter.feature_key == payload.feature_key,
                UsageQuotaCounter.period_key == period_key,
            )
            .with_for_update()
        )
        if counter is None:
            db.add(
                UsageQuotaCounter(
                    user_id=user.id,
                    feature_key=payload.feature_key,
                    period_key=period_key,
                    plan_code=plan_code,
                    used_count=1,
                    limit_count=limit_count,
                    reset_at=reset_at,
                    created_at=now,
                    updated_at=now,
                )
            )
            used_count = 1
        else:
            counter.used_count += 1
            counter.plan_code = plan_code
            counter.limit_count = limit_count
            counter.reset_at = reset_at
            counter.updated_at = now
            used_count = counter.used_count
    else:
        used_count = 0

    return _result(
        allowed=True,
        committed=True,
        used_count=used_count,
        limit_count=limit_count,
        reset_at=reset_at,
        reason_code=None,
    )


def _current_plan(db: Session, user: User) -> str:
    active = list_active(db, user)
    if not active:
        return "free"
    plan = active[0].plan_code.casefold()
    return plan if plan in {"plus", "family_plus"} else "free"


def _result(
    *,
    allowed: bool,
    committed: bool,
    used_count: int,
    limit_count: int | None,
    reset_at: datetime | None,
    reason_code: str | None,
) -> dict[str, Any]:
    return {
        "allowed": allowed,
        "committed": committed,
        "used_count": used_count,
        "limit_count": limit_count,
        "reset_at": reset_at.isoformat() if reset_at else None,
        "reason_code": reason_code,
    }
