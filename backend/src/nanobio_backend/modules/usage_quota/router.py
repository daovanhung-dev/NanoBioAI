from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.usage_quota import view
from nanobio_backend.modules.usage_quota.models import QuotaRequest

router = APIRouter()


@router.post("/check")
def check_quota(
    payload: QuotaRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.check_quota(db, user, payload),
        business_code="USAGE_QUOTA_CHECKED",
    )


@router.post("/commit")
def commit_quota(
    payload: QuotaRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.commit_quota(db, user, payload),
        business_code="USAGE_QUOTA_COMMITTED",
    )
