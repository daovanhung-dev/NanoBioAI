from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, File, Request, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.storage import view

router = APIRouter()


@router.post("/{bucket}", status_code=201)
def upload_file(
    bucket: str,
    request: Request,
    file: UploadFile = File(...),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.create_file_object(bucket, request, file, user, db)
    return success_response(request, result, business_code="FILE_CREATED", status_code=201)


@router.get("/{bucket}/{file_id}")
def download_file(
    bucket: str,
    file_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    return view.get_file_response(bucket, file_id, request, user, db)


@router.delete("/{bucket}/{file_id}")
def delete_file(
    bucket: str,
    file_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    view.remove_file_object(bucket, file_id, request, user, db)
    return success_response(request, {"deleted": True}, business_code="FILE_DELETED")
