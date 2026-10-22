from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import CloudSnapshot


def get_mobile_snapshot(db: Session, user_id: UUID) -> CloudSnapshot | None:
    return db.scalar(
        select(CloudSnapshot).where(
            CloudSnapshot.user_id == user_id,
            CloudSnapshot.snapshot_type == "mobile-v1",
        )
    )
