import hashlib
import json
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import (
    AdminAuditEvent,
    EarlyAccessLead,
    IdempotencyRecord,
    ManualPaymentEvent,
    MembershipSubscription,
    User,
)


def payload_hash(payload: dict[str, Any]) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


def find_idempotency(
    db: Session, *, actor_id: UUID, operation: str, key: str
) -> IdempotencyRecord | None:
    return db.scalar(
        select(IdempotencyRecord).where(
            IdempotencyRecord.actor_id == actor_id,
            IdempotencyRecord.operation == operation,
            IdempotencyRecord.idempotency_key == key,
        )
    )


def add_idempotency(
    db: Session, *, actor_id: UUID, operation: str, key: str, digest: str, result: dict[str, Any]
) -> None:
    db.add(
        IdempotencyRecord(
            actor_id=actor_id,
            operation=operation,
            idempotency_key=key,
            request_hash=digest,
            response_data=result,
        )
    )


def add_audit(
    db: Session,
    *,
    actor_id: UUID,
    action: str,
    target_user_id: UUID | None,
    reason: str,
    idempotency_key: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> None:
    db.add(
        AdminAuditEvent(
            actor_id=actor_id,
            action=action,
            target_user_id=target_user_id,
            reason=reason,
            idempotency_key=idempotency_key,
            metadata_json=metadata or {},
        )
    )


def current_membership(db: Session, user_id: UUID, now: datetime) -> MembershipSubscription | None:
    return db.scalar(
        select(MembershipSubscription)
        .where(
            MembershipSubscription.user_id == user_id,
            MembershipSubscription.status.in_(["trialing", "active", "past_due"]),
            MembershipSubscription.starts_at <= now,
            (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
        )
        .order_by(MembershipSubscription.created_at.desc())
        .with_for_update()
    )


def get_user_for_update(db: Session, user_id: UUID) -> User | None:
    return db.scalar(select(User).where(User.id == user_id).with_for_update())


def search_users(db: Session, term: str, limit: int) -> list[User]:
    statement = select(User)
    if term:
        pattern = f"%{term}%"
        statement = statement.where(
            or_(
                User.full_name.ilike(pattern),
                User.phone.ilike(pattern),
                User.email.ilike(pattern),
            )
        )
    return list(db.scalars(statement.order_by(User.created_at.desc()).limit(limit)).all())


def search_current_memberships(
    db: Session, user_ids: list[UUID], now: datetime
) -> list[MembershipSubscription]:
    if not user_ids:
        return []
    return list(
        db.scalars(
            select(MembershipSubscription)
            .where(
                MembershipSubscription.user_id.in_(user_ids),
                MembershipSubscription.plan_code.in_(["plus", "family_plus"]),
                MembershipSubscription.status.in_(["trialing", "active"]),
                MembershipSubscription.starts_at <= now,
                (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
            )
            .order_by(
                MembershipSubscription.user_id,
                MembershipSubscription.plan_code.desc(),
                MembershipSubscription.starts_at.desc(),
            )
        ).all()
    )


def search_early_access_leads(
    db: Session, *, term: str, offset: int, limit: int
) -> tuple[int, list[EarlyAccessLead]]:
    pattern = f"%{term.strip()}%"
    where = or_(EarlyAccessLead.full_name.ilike(pattern), EarlyAccessLead.phone.ilike(pattern))
    total = int(db.scalar(select(func.count()).select_from(EarlyAccessLead).where(where)) or 0)
    rows = list(
        db.scalars(
            select(EarlyAccessLead)
            .where(where)
            .order_by(EarlyAccessLead.created_at.desc())
            .offset(offset)
            .limit(limit)
        ).all()
    )
    return total, rows


def payment_review_count(db: Session) -> int:
    return int(
        db.scalar(
            select(func.count())
            .select_from(ManualPaymentEvent)
            .where(ManualPaymentEvent.status == "pending_review")
        )
        or 0
    )
