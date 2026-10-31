from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError, VerifyMismatchError
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import ApiError
from nanobio_backend.db.models import User

password_hasher = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=2)
bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password_hash: str, password: str) -> bool:
    try:
        return password_hasher.verify(password_hash, password)
    except (VerificationError, VerifyMismatchError):
        return False


def make_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_access_token(request: Request, subject: UUID) -> str:
    settings = request.app.state.settings
    secret = settings.jwt_secret_key.get_secret_value() if settings.jwt_secret_key else ""
    if len(secret) < 32:
        raise ApiError(503, "AUTH_NOT_CONFIGURED", "Dịch vụ đăng nhập chưa được cấu hình.")
    now = datetime.now(UTC)
    return jwt.encode(
        {
            "sub": str(subject),
            "iat": now,
            "exp": now + timedelta(minutes=settings.access_token_minutes),
            "iss": settings.jwt_issuer,
            "aud": settings.jwt_audience,
            "type": "access",
        },
        secret,
        algorithm="HS256",
    )


def decode_access_token(request: Request, token: str) -> UUID:
    settings = request.app.state.settings
    secret = settings.jwt_secret_key.get_secret_value() if settings.jwt_secret_key else ""
    if len(secret) < 32:
        raise ApiError(503, "AUTH_NOT_CONFIGURED", "Dịch vụ đăng nhập chưa được cấu hình.")
    try:
        payload = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
            options={"require": ["sub", "exp", "iat", "iss", "aud"]},
        )
        if payload.get("type") != "access":
            raise jwt.InvalidTokenError("wrong token type")
        return UUID(str(payload["sub"]))
    except (jwt.PyJWTError, ValueError, KeyError) as exc:
        raise ApiError(401, "AUTHENTICATION_REQUIRED", "Phiên đăng nhập không hợp lệ.") from exc


def authenticated_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise ApiError(401, "AUTHENTICATION_REQUIRED", "Vui lòng đăng nhập để tiếp tục.")
    user_id = decode_access_token(request, credentials.credentials)
    user = db.get(User, user_id)
    if user is None or not user.is_active or user.admin_status != "active":
        raise ApiError(401, "AUTHENTICATION_REQUIRED", "Phiên đăng nhập không hợp lệ.")
    db.commit()
    return user


def current_user(
    user: User = Depends(authenticated_user),
) -> User:
    if user.force_password_change:
        raise ApiError(
            403,
            "PASSWORD_CHANGE_REQUIRED",
            "Hãy đổi mật khẩu tạm trước khi tiếp tục.",
        )
    return user


def require_admin(user: User, *roles: str) -> None:
    allowed = set(roles) or {"super_admin", "support_admin", "operations_admin"}
    if not user.is_admin or not (user.admin_roles & allowed):
        raise ApiError(403, "ACCESS_DENIED", "Bạn không có quyền thực hiện thao tác này.")
