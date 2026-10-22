from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.auth import view
from nanobio_backend.modules.auth.models import (
    ChangePasswordRequest,
    LoginRequest,
    PhoneSignupRequest,
    RefreshRequest,
)

router = APIRouter()


def client_ip(request: Request) -> str:
    return request.client.host if request.client else "unknown"


@router.post("/phone-signup", status_code=201)
def phone_signup(
    payload: PhoneSignupRequest, request: Request, db: Session = Depends(get_db)
) -> Any:
    result = view.sign_up(
        request,
        db,
        phone=payload.phone,
        password=payload.password,
        full_name=payload.full_name,
        referral_code=payload.referral_code,
        device_fingerprint=payload.device_fingerprint,
        client_ip=client_ip(request),
    )
    return success_response(
        request,
        result,
        business_code="ACCOUNT_CREATED",
        message="Đã tạo tài khoản.",
        status_code=201,
    )


@router.post("/login")
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)) -> Any:
    result = view.login(request, db, payload.phone, payload.password, client_ip(request))
    return success_response(
        request, result, business_code="AUTHENTICATED", message="Đăng nhập thành công."
    )


@router.post("/refresh")
def refresh(payload: RefreshRequest, request: Request, db: Session = Depends(get_db)) -> Any:
    result = view.rotate_refresh(request, db, payload.refresh_token)
    return success_response(
        request, result, business_code="TOKEN_ROTATED", message="Phiên đăng nhập đã được làm mới."
    )


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    view.change_password(db, user, payload.new_password)
    return success_response(
        request,
        {"updated": True},
        business_code="PASSWORD_CHANGED",
        message="Đã cập nhật mật khẩu.",
    )


@router.post("/logout")
def logout(
    payload: RefreshRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    view.logout(db, user, payload.refresh_token)
    return success_response(request, {"logged_out": True}, business_code="SESSION_REVOKED")
