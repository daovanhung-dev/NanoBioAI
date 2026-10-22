from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import CloudSnapshot, User, now_utc
from nanobio_backend.modules.cloud_sync import query
from nanobio_backend.modules.cloud_sync.validate import validate_snapshot


def read_snapshot(db: Session, user_id: UUID) -> dict[str, Any]:
    stored = query.get_mobile_snapshot(db, user_id)
    if stored is None:
        return {"revision": 0, "user": None, "tables": {}}
    return {"revision": stored.revision, **stored.payload}


def write_snapshot(
    db: Session,
    user: User,
    source: dict[str, object],
    expected_revision: int | None,
) -> dict[str, Any]:
    clean = validate_snapshot(source, user.id)
    profile = clean["user"]
    if "gender" in profile and profile["gender"] not in {
        "male",
        "female",
        "other",
        "prefer_not_to_say",
    }:
        raise ApiError(422, "INVALID_GENDER", "Giá trị giới tính chưa hợp lệ.")
    if "onboarding_status" in profile:
        state = profile["onboarding_status"]
        if state not in {"completed", "in_progress", "pending"}:
            profile.pop("onboarding_status")
            profile.pop("onboarding_completed_at", None)
    with atomic(db):
        db.scalar(select(User).where(User.id == user.id).with_for_update())
        stored = query.get_mobile_snapshot(db, user.id)
        current_revision = stored.revision if stored is not None else 0
        if expected_revision is not None and expected_revision != current_revision:
            raise ApiError(
                409,
                "SNAPSHOT_REVISION_CONFLICT",
                "Dữ liệu đã được cập nhật trên thiết bị khác. Hãy tải lại trước khi đồng bộ.",
                meta={"current_revision": current_revision},
            )
        for key in ("full_name", "avatar_url", "gender", "birth_year"):
            if key in profile and profile[key] is not None:
                setattr(user, key, profile[key])
        if profile.get("onboarding_status") in {"completed", "in_progress"}:
            user.onboarding_status = str(profile["onboarding_status"])
            if user.onboarding_status == "completed":
                from datetime import UTC, datetime

                user.onboarding_completed_at = datetime.now(UTC)
        if stored is None:
            stored = CloudSnapshot(
                user_id=user.id,
                snapshot_type="mobile-v1",
                payload=clean,
                revision=1,
            )
            db.add(stored)
        else:
            stored.payload = clean
            stored.revision = current_revision + 1
            stored.updated_at = now_utc()
    return {"revision": stored.revision, "user": clean["user"], "tables": clean["tables"]}
