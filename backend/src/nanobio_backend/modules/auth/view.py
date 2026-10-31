import hashlib
import hmac
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from fastapi import Request
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.security import (
    create_access_token,
    hash_password,
    hash_refresh_token,
    make_refresh_token,
    verify_password,
)
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import RateLimitBucket, RefreshSession, User, now_utc
from nanobio_backend.modules.auth import query, validate
from nanobio_backend.services.health_subjects import ensure_self_subject


def _subject_hash(request: Request, value: str) -> str:
    key = request.app.state.settings.rate_limit_hmac_key
    if key is None or len(key.get_secret_value()) < 32:
        raise ApiError(503, "AUTH_NOT_CONFIGURED", "Dịch vụ đăng nhập chưa được cấu hình.")
    return hmac.new(key.get_secret_value().encode(), value.encode(), hashlib.sha256).hexdigest()


def consume_rate_limit(
    db: Session, *, scope: str, subject_hash: str, limit: int, window_seconds: int
) -> bool:
    now = now_utc()
    epoch = int(now.timestamp())
    start = datetime.fromtimestamp(epoch - epoch % window_seconds, UTC)
    bind = db.get_bind()
    dialect = bind.dialect.name
    if dialect == "postgresql":
        statement: Any = pg_insert(RateLimitBucket).values(
            scope=scope, subject_hash=subject_hash, window_start=start, hits=1
        )
        statement = statement.on_conflict_do_update(
            index_elements=["scope", "subject_hash", "window_start"],
            set_={"hits": RateLimitBucket.hits + 1},
        ).returning(RateLimitBucket.hits)
        hits = db.scalar(statement)
    elif dialect == "sqlite":
        statement = sqlite_insert(RateLimitBucket).values(
            scope=scope, subject_hash=subject_hash, window_start=start, hits=1
        )
        statement = statement.on_conflict_do_update(
            index_elements=["scope", "subject_hash", "window_start"],
            set_={"hits": RateLimitBucket.hits + 1},
        ).returning(RateLimitBucket.hits)
        hits = db.scalar(statement)
    else:
        row = query.rate_bucket(db, scope, subject_hash, start)
        if row is None:
            row = RateLimitBucket(
                scope=scope, subject_hash=subject_hash, window_start=start, hits=1
            )
            db.add(row)
            db.flush()
            hits = row.hits
        else:
            row.hits += 1
            hits = row.hits
    db.flush()
    return int(hits or 0) > limit


def _issue_pair(
    request: Request, db: Session, user: User, *, family_id: UUID | None = None
) -> tuple[dict[str, object], RefreshSession]:
    raw_refresh = make_refresh_token()
    family = family_id or uuid4()
    settings = request.app.state.settings
    refresh = query.add_refresh(
        db,
        user_id=user.id,
        token_hash=hash_refresh_token(raw_refresh),
        family_id=family,
        expires_at=now_utc() + timedelta(days=settings.refresh_token_days),
    )
    return (
        {
            "access_token": create_access_token(request, user.id),
            "token_type": "bearer",
            "expires_in": settings.access_token_minutes * 60,
            "refresh_token": raw_refresh,
            "must_change_password": user.force_password_change,
            "user": {
                "id": str(user.id),
                "phone": user.phone,
                "email": user.email,
                "username": user.username,
                "full_name": user.full_name,
                "roles": sorted(user.admin_roles),
            },
        },
        refresh,
    )


def sign_up(
    request: Request,
    db: Session,
    *,
    phone: str,
    password: str,
    full_name: str,
    referral_code: str | None,
    device_fingerprint: str | None,
    client_ip: str,
) -> dict[str, object]:
    normalized_phone = validate.normalize_vietnam_phone(phone)
    normalized_referral = validate.validate_referral(referral_code, device_fingerprint)
    try:
        with atomic(db):
            if consume_rate_limit(
                db,
                scope="phone-signup",
                subject_hash=_subject_hash(request, client_ip),
                limit=10,
                window_seconds=3600,
            ):
                raise ApiError(
                    429, "RATE_LIMITED", "Bạn đã gửi quá nhiều yêu cầu. Hãy thử lại sau."
                )
            if query.get_user_by_phone(db, normalized_phone) is not None:
                raise ApiError(409, "PHONE_EXISTS", "Số điện thoại này đã có tài khoản.")
            user = User(
                phone=normalized_phone,
                password_hash=hash_password(password),
                full_name=full_name.strip(),
            )
            db.add(user)
            db.flush()
            ensure_self_subject(db, user)
            if normalized_referral:
                referral = query.find_referral(db, normalized_referral)
                if referral is None:
                    raise ApiError(400, "REFERRAL_CODE_INVALID", "Mã giới thiệu chưa hợp lệ.")
                fingerprint = hashlib.sha256((device_fingerprint or "").encode()).hexdigest()
                query.link_referral(
                    db,
                    referrer_id=referral.user_id,
                    referred_id=user.id,
                    fingerprint_hash=fingerprint,
                )
            pair, _ = _issue_pair(request, db, user)
            return pair
    except IntegrityError as exc:
        raise ApiError(409, "PHONE_EXISTS", "Số điện thoại này đã có tài khoản.") from exc


def login(
    request: Request,
    db: Session,
    *,
    phone: str | None,
    email: str | None,
    username: str | None,
    password: str,
    client_ip: str,
) -> dict[str, object]:
    if username is not None:
        identifier_kind = "username"
        normalized_username = validate.normalize_username(username)
        normalized_identifier = normalized_username
    elif email is not None:
        identifier_kind = "email"
        normalized_email = email.strip().lower()
        normalized_identifier = normalized_email
    elif phone is not None:
        identifier_kind = "phone"
        normalized_phone = validate.normalize_vietnam_phone(phone)
        normalized_identifier = normalized_phone
    else:
        raise ApiError(422, "LOGIN_IDENTIFIER_REQUIRED", "Hãy nhập thông tin đăng nhập.")
    with atomic(db):
        if consume_rate_limit(
            db,
            scope="account-login",
            subject_hash=_subject_hash(request, client_ip),
            limit=20,
            window_seconds=900,
        ):
            raise ApiError(429, "RATE_LIMITED", "Bạn đã thử đăng nhập quá nhiều lần.")
        if identifier_kind == "username":
            user = query.get_user_by_username(db, normalized_identifier)
        elif identifier_kind == "email":
            user = query.get_user_by_email(db, normalized_identifier)
        else:
            user = query.get_user_by_phone(db, normalized_identifier)
        if (
            user is None
            or not user.is_active
            or user.admin_status != "active"
            or not verify_password(user.password_hash, password)
        ):
            raise ApiError(401, "INVALID_CREDENTIALS", "Thông tin đăng nhập chưa đúng.")
        pair, _ = _issue_pair(request, db, user)
        return pair


def rotate_refresh(request: Request, db: Session, raw_token: str) -> dict[str, object]:
    try:
        with atomic(db):
            row = query.get_refresh_for_update(db, hash_refresh_token(raw_token))
            now = now_utc()
            expires_at = (
                row.expires_at
                if row and row.expires_at.tzinfo
                else (row.expires_at.replace(tzinfo=UTC) if row else now)
            )
            if row is None or row.revoked_at is not None or expires_at <= now:
                raise ApiError(401, "REFRESH_TOKEN_INVALID", "Phiên đăng nhập đã hết hạn.")
            user = query.get_user(db, row.user_id)
            if user is None or not user.is_active:
                raise ApiError(401, "REFRESH_TOKEN_INVALID", "Phiên đăng nhập đã hết hạn.")
            row.revoked_at = now
            pair, replacement = _issue_pair(request, db, user, family_id=row.family_id)
            row.replaced_by_id = replacement.id
            return pair
    except IntegrityError as exc:
        raise ApiError(409, "REFRESH_TOKEN_REPLAYED", "Phiên đăng nhập đã được làm mới.") from exc


def change_password(
    request: Request, db: Session, user: User, new_password: str
) -> dict[str, object]:
    with atomic(db):
        user.password_hash = hash_password(new_password)
        user.force_password_change = False
        user.updated_at = now_utc()
        db.query(RefreshSession).filter(
            RefreshSession.user_id == user.id,
            RefreshSession.revoked_at.is_(None),
        ).update({RefreshSession.revoked_at: now_utc()}, synchronize_session=False)
        pair, _ = _issue_pair(request, db, user)
        return pair


def logout(db: Session, user: User, raw_refresh_token: str) -> None:
    with atomic(db):
        row = query.revoke_refresh_for_user(db, user.id, hash_refresh_token(raw_refresh_token))
        if row is not None:
            row.revoked_at = now_utc()
