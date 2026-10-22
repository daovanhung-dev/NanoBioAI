from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.profile import view
from nanobio_backend.modules.profile.models import ProfileUpdateRequest

router = APIRouter()


@router.get("/me")
def get_profile(request: Request, user: User = Depends(current_user)) -> Any:
    return success_response(request, view.profile_view(user), business_code="PROFILE_RETRIEVED")


@router.patch("/me")
def patch_profile(
    payload: ProfileUpdateRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.update_profile(db, user, payload.model_dump(exclude_unset=True))
    return success_response(request, result, business_code="PROFILE_UPDATED")
