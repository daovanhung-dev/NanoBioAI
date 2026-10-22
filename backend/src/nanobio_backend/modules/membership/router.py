from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.membership.view import get_my_membership

router = APIRouter()


@router.get("/me")
def membership_me(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        get_my_membership(db, user),
        business_code="MEMBERSHIP_ACCESS_RETRIEVED",
    )
