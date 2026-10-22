from typing import Any

from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import User


def update_profile(db: Session, user: User, values: dict[str, Any]) -> dict[str, Any]:
    allowed_gender = {"male", "female", "other", "prefer_not_to_say"}
    if "gender" in values and values["gender"] not in allowed_gender:
        raise ApiError(422, "INVALID_GENDER", "Giá trị giới tính chưa hợp lệ.")
    with atomic(db):
        for key, value in values.items():
            setattr(user, key, value)
    return profile_view(user)


def profile_view(user: User) -> dict[str, Any]:
    return {
        "id": str(user.id),
        "phone": user.phone,
        "email": user.email,
        "full_name": user.full_name,
        "avatar_url": user.avatar_url,
        "gender": user.gender,
        "birth_year": user.birth_year,
        "onboarding_status": user.onboarding_status,
        "onboarding_completed_at": (
            user.onboarding_completed_at.isoformat() if user.onboarding_completed_at else None
        ),
    }
