from datetime import datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import (
    MembershipSubscription,
    SleepSafetyContact,
    SleepSafetyDispatch,
    SleepSafetyEvent,
    SleepSafetyVerificationChallenge,
)


def get_contact(
    db: Session, user_id: UUID, contact_id: UUID, *, active_only: bool = True
) -> SleepSafetyContact | None:
    statement = select(SleepSafetyContact).where(
        SleepSafetyContact.id == contact_id, SleepSafetyContact.user_id == user_id
    )
    if active_only:
        statement = statement.where(SleepSafetyContact.active.is_(True))
    return db.scalar(statement.with_for_update())


def recent_challenge_count(db: Session, user_id: UUID, contact_id: UUID, since: datetime) -> int:
    return int(
        db.scalar(
            select(func.count(SleepSafetyVerificationChallenge.id)).where(
                SleepSafetyVerificationChallenge.user_id == user_id,
                SleepSafetyVerificationChallenge.contact_id == contact_id,
                SleepSafetyVerificationChallenge.created_at >= since,
            )
        )
        or 0
    )


def active_challenge(
    db: Session, user_id: UUID, contact_id: UUID
) -> SleepSafetyVerificationChallenge | None:
    return db.scalar(
        select(SleepSafetyVerificationChallenge)
        .where(
            SleepSafetyVerificationChallenge.user_id == user_id,
            SleepSafetyVerificationChallenge.contact_id == contact_id,
            SleepSafetyVerificationChallenge.status == "pending",
        )
        .order_by(SleepSafetyVerificationChallenge.created_at.desc())
        .limit(1)
        .with_for_update()
    )


def paid_access(db: Session, user_id: UUID, now: datetime) -> bool:
    return (
        db.scalar(
            select(MembershipSubscription.id)
            .where(
                MembershipSubscription.user_id == user_id,
                MembershipSubscription.plan_code.in_(["plus", "family_plus"]),
                MembershipSubscription.status.in_(["trialing", "active", "past_due"]),
                MembershipSubscription.starts_at <= now,
                (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
            )
            .limit(1)
        )
        is not None
    )


def get_event(db: Session, user_id: UUID, event_id: UUID) -> SleepSafetyEvent | None:
    return db.scalar(
        select(SleepSafetyEvent).where(
            SleepSafetyEvent.id == event_id, SleepSafetyEvent.user_id == user_id
        )
    )


def list_contacts(
    db: Session, user_id: UUID, *, after_priority: int | None = None
) -> list[SleepSafetyContact]:
    statement = select(SleepSafetyContact).where(
        SleepSafetyContact.user_id == user_id, SleepSafetyContact.active.is_(True)
    )
    if after_priority is not None:
        statement = statement.where(SleepSafetyContact.priority > after_priority)
    return list(db.scalars(statement.order_by(SleepSafetyContact.priority.asc())).all())


def existing_dispatches(
    db: Session, user_id: UUID, idempotency_key: str
) -> list[SleepSafetyDispatch]:
    return list(
        db.scalars(
            select(SleepSafetyDispatch).where(
                SleepSafetyDispatch.user_id == user_id,
                SleepSafetyDispatch.idempotency_key == idempotency_key,
            )
        ).all()
    )


def distinct_recent_dispatch_count(db: Session, user_id: UUID, since: datetime) -> int:
    return int(
        db.scalar(
            select(func.count(func.distinct(SleepSafetyDispatch.idempotency_key))).where(
                SleepSafetyDispatch.user_id == user_id,
                SleepSafetyDispatch.created_at >= since,
            )
        )
        or 0
    )


def already_attempted(db: Session, idempotency_key: str, contact_id: UUID, channel: str) -> bool:
    return (
        db.scalar(
            select(SleepSafetyDispatch.id).where(
                SleepSafetyDispatch.idempotency_key == idempotency_key,
                SleepSafetyDispatch.contact_id == contact_id,
                SleepSafetyDispatch.channel == channel,
            )
        )
        is not None
    )
