from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import ApiError, success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.account import view
from nanobio_backend.modules.account.models import DeleteAccountRequest

router = APIRouter()


@router.get("/account/me")
def get_me(request: Request, user: User = Depends(current_user)) -> Any:
    return success_response(
        request,
        view.account_view(user),
    )


@router.delete("/account")
def delete_account(
    payload: DeleteAccountRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    if not payload.confirm:
        raise ApiError(400, "CONFIRMATION_REQUIRED", "Vui lòng xác nhận xóa tài khoản.")
    view.delete_account(db, user, request.app.state.settings.upload_root)
    return success_response(
        request, {"deleted": True}, business_code="ACCOUNT_DELETED", message="Đã xóa tài khoản."
    )
