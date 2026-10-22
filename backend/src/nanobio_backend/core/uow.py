from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy.orm import Session


@contextmanager
def atomic(db: Session) -> Generator[None, None, None]:
    """Commit one use case even when an auth dependency performed a prior read."""
    try:
        yield
        db.commit()
    except Exception:
        db.rollback()
        raise
