from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import (
    FamilyGroup,
    FamilyMember,
    HealthSubject,
    MembershipSubscription,
    User,
)


def lock_user(db: Session, user_id: UUID) -> User | None:
    return db.scalar(select(User).where(User.id == user_id).with_for_update())


def current_subscription(db: Session, user_id: UUID) -> MembershipSubscription | None:
    return db.scalar(
        select(MembershipSubscription)
        .where(
            MembershipSubscription.user_id == user_id,
            MembershipSubscription.plan_code == "family_plus",
            MembershipSubscription.status == "active",
            MembershipSubscription.ends_at.is_(None)
            | (MembershipSubscription.ends_at > func.now()),
        )
        .order_by(MembershipSubscription.starts_at.desc())
        .limit(1)
    )


def active_group(db: Session, user_id: UUID, *, lock: bool = False) -> FamilyGroup | None:
    statement = (
        select(FamilyGroup)
        .where(FamilyGroup.owner_user_id == user_id, FamilyGroup.status == "active")
        .order_by(FamilyGroup.created_at.desc())
        .limit(1)
    )
    if lock:
        statement = statement.with_for_update()
    return db.scalar(statement)


def self_subject(db: Session, user_id: UUID) -> HealthSubject | None:
    return db.scalar(
        select(HealthSubject).where(
            HealthSubject.owner_user_id == user_id,
            HealthSubject.subject_type == "self",
            HealthSubject.is_active.is_(True),
        )
    )


def list_group_members(db: Session, group_id: UUID) -> list[FamilyMember]:
    return list(
        db.scalars(
            select(FamilyMember)
            .where(FamilyMember.family_group_id == group_id)
            .order_by(FamilyMember.created_at.asc())
        ).all()
    )


def owned_active_subject(db: Session, user_id: UUID, subject_id: UUID) -> HealthSubject | None:
    return db.scalar(
        select(HealthSubject).where(
            HealthSubject.id == subject_id,
            HealthSubject.owner_user_id == user_id,
            HealthSubject.is_active.is_(True),
        )
    )


def member_by_subject(db: Session, group_id: UUID, subject_id: UUID) -> FamilyMember | None:
    return db.scalar(
        select(FamilyMember).where(
            FamilyMember.family_group_id == group_id,
            FamilyMember.subject_id == subject_id,
        )
    )


def active_member_count(db: Session, group_id: UUID) -> int:
    return int(
        db.scalar(
            select(func.count(FamilyMember.id)).where(
                FamilyMember.family_group_id == group_id,
                FamilyMember.status == "active",
            )
        )
        or 0
    )


def member_for_owner_update(db: Session, owner_id: UUID, member_id: UUID) -> FamilyMember | None:
    return db.scalar(
        select(FamilyMember)
        .join(FamilyGroup, FamilyGroup.id == FamilyMember.family_group_id)
        .where(
            FamilyMember.id == member_id,
            FamilyGroup.owner_user_id == owner_id,
            FamilyGroup.status == "active",
        )
        .with_for_update()
    )
