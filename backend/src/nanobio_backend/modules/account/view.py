import shutil
from pathlib import Path
from typing import Any

from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import User


def account_view(user: User) -> dict[str, Any]:
    return {
        "id": str(user.id),
        "phone": user.phone,
        "full_name": user.full_name,
        "membership_tier": user.membership_tier,
    }


def delete_account(db: Session, user: User, upload_root: Path) -> None:
    owner_dir = upload_root / str(user.id)
    quarantine = owner_dir.with_name(f"{owner_dir.name}.deleting")
    try:
        if quarantine.exists():
            shutil.rmtree(quarantine)
        if owner_dir.exists():
            owner_dir.rename(quarantine)
    except OSError as exc:
        raise ApiError(
            503, "ACCOUNT_DELETION_UNAVAILABLE", "Chưa thể xóa tài khoản lúc này."
        ) from exc
    try:
        with atomic(db):
            db.delete(user)
    except Exception:
        if quarantine.exists() and not owner_dir.exists():
            quarantine.rename(owner_dir)
        raise
    try:
        if quarantine.exists():
            shutil.rmtree(quarantine)
    except OSError:
        # Keep failed cleanup quarantined: it is outside the public user path.
        pass
