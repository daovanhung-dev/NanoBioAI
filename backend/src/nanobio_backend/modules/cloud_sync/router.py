from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.cloud_sync import view
from nanobio_backend.modules.cloud_sync.models import SnapshotPutRequest

router = APIRouter()


@router.get("/snapshot")
def get_snapshot(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.read_snapshot(db, user.id),
        business_code="CLOUD_SNAPSHOT_RETRIEVED",
    )


@router.put("/snapshot")
def put_snapshot(
    payload: SnapshotPutRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.write_snapshot(db, user, payload.snapshot, payload.expected_revision)
    return success_response(request, result, business_code="CLOUD_SNAPSHOT_SAVED")
