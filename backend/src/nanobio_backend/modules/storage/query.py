from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import FileObject


def get_owned_file(db: Session, owner_id: UUID, bucket: str, file_id: UUID) -> FileObject | None:
    return db.scalar(
        select(FileObject).where(
            FileObject.id == file_id,
            FileObject.owner_id == owner_id,
            FileObject.bucket == bucket,
        )
    )
