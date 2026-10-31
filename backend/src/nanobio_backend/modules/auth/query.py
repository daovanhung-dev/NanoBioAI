from datetime import datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import (
    AdminUserRole,
    RateLimitBucket,
    ReferralCode,
    ReferralRelationship,
    RefreshSession,
    User,
)


def get_user_by_phone(db: Session, phone: str) -> User | None:
    return db.scalar(select(User).where(User.phone == phone))


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(func.lower(User.email) == email.strip().lower()))


def get_user_by_username(db: Session, username: str) -> User | None:
    return db.scalar(select(User).where(func.lower(User.username) == username.strip().lower()))


def get_user(db: Session, user_id: UUID) -> User | None:
    return db.get(User, user_id)


def get_refresh_for_update(db: Session, token_hash: str) -> RefreshSession | None:
    statement = (
        select(RefreshSession).where(RefreshSession.token_hash == token_hash).with_for_update()
    )
    return db.scalar(statement)


def revoke_refresh_for_user(db: Session, user_id: UUID, token_hash: str) -> RefreshSession | None:
    return db.scalar(
        select(RefreshSession)
        .where(
            RefreshSession.user_id == user_id,
            RefreshSession.token_hash == token_hash,
            RefreshSession.revoked_at.is_(None),
        )
        .with_for_update()
    )


def add_refresh(
    db: Session,
    *,
    user_id: UUID,
    token_hash: str,
    family_id: UUID,
    expires_at: datetime,
) -> RefreshSession:
    row = RefreshSession(
        user_id=user_id,
        token_hash=token_hash,
        family_id=family_id,
        expires_at=expires_at,
    )
    db.add(row)
    db.flush()
    return row


def find_referral(db: Session, code: str) -> ReferralCode | None:
    return db.scalar(
        select(ReferralCode).where(ReferralCode.code == code, ReferralCode.is_active.is_(True))
    )


def link_referral(
    db: Session, *, referrer_id: UUID, referred_id: UUID, fingerprint_hash: str
) -> None:
    db.add(
        ReferralRelationship(
            referrer_id=referrer_id,
            referred_id=referred_id,
            device_fingerprint_hash=fingerprint_hash,
        )
    )


def grant_role(db: Session, user_id: UUID, role_code: str) -> None:
    db.add(AdminUserRole(user_id=user_id, role_code=role_code))


def rate_bucket(
    db: Session, scope: str, subject_hash: str, window_start: datetime
) -> RateLimitBucket | None:
    statement = (
        select(RateLimitBucket)
        .where(
            RateLimitBucket.scope == scope,
            RateLimitBucket.subject_hash == subject_hash,
            RateLimitBucket.window_start == window_start,
        )
        .with_for_update()
    )
    return db.scalar(statement)
