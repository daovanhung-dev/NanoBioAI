from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import HealthSubject, User


def ensure_self_subject(db: Session, user: User) -> HealthSubject:
    subject = db.scalar(
        select(HealthSubject).where(
            HealthSubject.owner_user_id == user.id,
            HealthSubject.subject_type == "self",
        )
    )
    if subject is None:
        subject = HealthSubject(
            owner_user_id=user.id,
            linked_user_id=user.id,
            subject_type="self",
            display_name=user.full_name,
            relationship="self",
        )
        db.add(subject)
        db.flush()
    return subject
