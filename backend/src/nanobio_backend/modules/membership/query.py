from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import MembershipSubscription, User


def list_active(db: Session, user: User) -> list[MembershipSubscription]:
    from datetime import UTC, datetime

    now = datetime.now(UTC)
    return list(
        db.scalars(
            select(MembershipSubscription)
            .where(
                MembershipSubscription.user_id == user.id,
                MembershipSubscription.status.in_(["active", "trialing", "past_due"]),
                MembershipSubscription.starts_at <= now,
                (MembershipSubscription.ends_at.is_(None) | (MembershipSubscription.ends_at > now)),
            )
            .order_by(MembershipSubscription.created_at.desc())
        ).all()
    )
