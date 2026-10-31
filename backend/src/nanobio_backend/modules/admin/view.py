import calendar
import re
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.security import hash_password
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import (
    AdminAuditEvent,
    EarlyAccessLead,
    IdempotencyRecord,
    MembershipSubscription,
    RefreshSession,
    User,
    now_utc,
)
from nanobio_backend.modules.admin import query
from nanobio_backend.modules.auth import query as auth_query
from nanobio_backend.modules.auth.validate import normalize_vietnam_phone
from nanobio_backend.services.health_subjects import ensure_self_subject

MEMBERSHIP_PLANS = {"plus", "family_plus"}
LEAD_STATUSES = {"new", "contacted", "registered", "converted", "rejected"}
_EMAIL_PATTERN = re.compile(r"^[^\s@|]+@[^\s@|]+\.[^\s@|]+$", re.IGNORECASE)
_RESET_PASSWORD = "12345678"


def _idempotent_result(
    db: Session, *, actor: User, operation: str, key: str, payload: dict[str, Any]
) -> dict[str, Any] | None:
    existing = query.find_idempotency(db, actor_id=actor.id, operation=operation, key=key)
    if existing is None:
        return None
    if existing.request_hash != query.payload_hash(payload):
        raise ApiError(409, "IDEMPOTENCY_CONFLICT", "Mã yêu cầu đã được dùng cho nội dung khác.")
    return existing.response_data or {}


def create_account(db: Session, actor: User, payload: dict[str, Any]) -> dict[str, Any]:
    operation = "admin-create-account"
    with atomic(db):
        cached = _idempotent_result(
            db, actor=actor, operation=operation, key=payload["idempotency_key"], payload=payload
        )
        if cached is not None:
            return cached
        phone = normalize_vietnam_phone(payload["phone"])
        if db.scalar(select(User.id).where(User.phone == phone)) is not None:
            raise ApiError(409, "PHONE_EXISTS", "Số điện thoại này đã có tài khoản.")
        user = User(
            phone=phone,
            full_name=payload["full_name"].strip(),
            email=payload.get("email"),
            password_hash=hash_password(payload["password"]),
            force_password_change=True,
        )
        db.add(user)
        db.flush()
        ensure_self_subject(db, user)
        result = {"user_id": str(user.id), "created": True}
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user.id,
            reason=payload["reason"],
            idempotency_key=payload["idempotency_key"],
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=payload["idempotency_key"],
            digest=query.payload_hash(payload),
            result=result,
        )
        return result


def grant_membership(db: Session, actor: User, payload: dict[str, Any]) -> dict[str, Any]:
    operation = "admin-grant-membership"
    with atomic(db):
        cached = _idempotent_result(
            db, actor=actor, operation=operation, key=payload["idempotency_key"], payload=payload
        )
        if cached is not None:
            return cached
        try:
            user_id = UUID(str(payload["user_id"]))
        except ValueError as exc:
            raise ApiError(422, "INVALID_USER_ID", "Tài khoản được chọn chưa hợp lệ.") from exc
        if payload["plan_code"] not in MEMBERSHIP_PLANS:
            raise ApiError(422, "INVALID_PLAN", "Gói thành viên chưa hợp lệ.")
        user = query.get_user_for_update(db, user_id)
        if user is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        now = datetime.now(UTC)
        current = query.current_membership(db, user.id, now)
        if (
            payload["preserve_existing_paid_plan"]
            and current is not None
            and current.plan_code in MEMBERSHIP_PLANS
        ):
            result = {
                "status": "paid_plan_preserved",
                "user_id": str(user.id),
                "subscription_id": str(current.id),
            }
        else:
            starts_at = payload["starts_at"]
            ends_at = payload.get("ends_at")
            if starts_at.tzinfo is None:
                starts_at = starts_at.replace(tzinfo=UTC)
            if ends_at is not None and ends_at.tzinfo is None:
                ends_at = ends_at.replace(tzinfo=UTC)
            if ends_at is not None and ends_at <= starts_at:
                raise ApiError(422, "INVALID_PERIOD", "Thời hạn gói thành viên chưa hợp lệ.")
            subscription = MembershipSubscription(
                user_id=user.id,
                plan_code=payload["plan_code"],
                status="active",
                source="manual",
                starts_at=starts_at,
                ends_at=ends_at,
                created_by=actor.id,
                reason=payload["reason"],
            )
            db.add(subscription)
            user.membership_tier = payload["plan_code"]
            result = {
                "status": "granted",
                "user_id": str(user.id),
                "subscription_id": str(subscription.id),
            }
            db.flush()
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user.id,
            reason=payload["reason"],
            idempotency_key=payload["idempotency_key"],
            metadata={"plan_code": payload["plan_code"]},
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=payload["idempotency_key"],
            digest=query.payload_hash(payload),
            result=result,
        )
        return result


def adjust_membership(db: Session, actor: User, payload: dict[str, Any]) -> dict[str, Any]:
    operation = "admin-adjust-membership-period"
    with atomic(db):
        cached = _idempotent_result(
            db, actor=actor, operation=operation, key=payload["idempotency_key"], payload=payload
        )
        if cached is not None:
            return cached
        try:
            user_id = UUID(str(payload["user_id"]))
            subscription_id = UUID(str(payload["subscription_id"]))
        except ValueError as exc:
            raise ApiError(422, "INVALID_ID", "Gói thành viên được chọn chưa hợp lệ.") from exc
        subscription = db.scalar(
            select(MembershipSubscription)
            .where(
                MembershipSubscription.id == subscription_id,
                MembershipSubscription.user_id == user_id,
            )
            .with_for_update()
        )
        if subscription is None:
            raise ApiError(404, "SUBSCRIPTION_NOT_FOUND", "Không tìm thấy gói thành viên.")
        if subscription.source != "manual" or subscription.status not in {
            "trialing",
            "active",
            "past_due",
        }:
            raise ApiError(
                409, "SUBSCRIPTION_NOT_ADJUSTABLE", "Gói này không thể điều chỉnh thủ công."
            )
        expected = payload.get("expected_ends_at")
        actual = subscription.ends_at
        if expected is not None:
            expected_cmp = expected if expected.tzinfo else expected.replace(tzinfo=UTC)
            actual_cmp = actual if actual is None or actual.tzinfo else actual.replace(tzinfo=UTC)
            if actual_cmp is None or actual_cmp != expected_cmp:
                raise ApiError(
                    409,
                    "SUBSCRIPTION_CHANGED",
                    "Gói thành viên đã thay đổi. Hãy tải lại trước khi thử.",
                )
        current_end = subscription.ends_at
        if current_end is None:
            raise ApiError(
                409, "SUBSCRIPTION_NOT_ADJUSTABLE", "Gói không có ngày kết thúc để điều chỉnh."
            )
        if current_end.tzinfo is None:
            current_end = current_end.replace(tzinfo=UTC)
        op = payload["operation"]
        if op in {"add_days", "subtract_days"}:
            days = payload.get("days")
            if not isinstance(days, int) or days < 1 or days > 3650:
                raise ApiError(422, "INVALID_DAYS", "Số ngày điều chỉnh chưa hợp lệ.")
            delta = timedelta(days=days if op == "add_days" else -days)
            new_end = current_end + delta
        elif op == "set_end_at" and payload.get("ends_at") is not None:
            new_end = payload["ends_at"]
            if new_end.tzinfo is None:
                new_end = new_end.replace(tzinfo=UTC)
        else:
            raise ApiError(422, "INVALID_OPERATION", "Thao tác điều chỉnh chưa hợp lệ.")
        subscription.ends_at = new_end
        result = {
            "status": "updated",
            "subscription_id": str(subscription.id),
            "ends_at": new_end.isoformat(),
        }
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user_id,
            reason=payload["reason"],
            idempotency_key=payload["idempotency_key"],
            metadata={"operation": op},
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=payload["idempotency_key"],
            digest=query.payload_hash(payload),
            result=result,
        )
        return result


def list_audit(db: Session, *, limit: int = 100) -> list[dict[str, str | None]]:
    rows = db.scalars(
        select(AdminAuditEvent).order_by(AdminAuditEvent.created_at.desc()).limit(limit)
    ).all()
    return [
        {
            "id": str(row.id),
            "action": row.action,
            "actor_id": str(row.actor_id or ""),
            "target_user_id": str(row.target_user_id or ""),
            "reason": row.reason,
            "created_at": row.created_at.isoformat(),
        }
        for row in rows
    ]


def search_users(db: Session, *, term: str, limit: int) -> list[dict[str, Any]]:
    now = datetime.now(UTC)
    users = query.search_users(db, term.strip(), min(max(limit, 1), 100))
    memberships = query.search_current_memberships(db, [user.id for user in users], now)
    by_user: dict[UUID, MembershipSubscription] = {}
    for subscription in memberships:
        by_user.setdefault(subscription.user_id, subscription)
    result: list[dict[str, Any]] = []
    for user in users:
        membership = by_user.get(user.id)
        plan = membership.plan_code if membership else "free"
        subtitle = " - ".join(value for value in (user.email, plan, user.sale_status) if value)
        result.append(
            {
                "id": str(user.id),
                "title": user.full_name or user.email or str(user.id),
                "subtitle": subtitle,
                "status": user.admin_status,
                "section": "users",
                "created_at": user.created_at.isoformat(),
                "plan_code": plan,
                "subscription_id": str(membership.id) if membership else None,
                "membership_status": membership.status if membership else None,
                "membership_source": membership.source if membership else None,
                "membership_starts_at": membership.starts_at.isoformat() if membership else None,
                "membership_ends_at": membership.ends_at.isoformat()
                if membership and membership.ends_at
                else None,
            }
        )
    return result


def payment_review_count(db: Session) -> int:
    return query.payment_review_count(db)


def list_early_access_leads(db: Session, *, term: str, page: int, page_size: int) -> dict[str, Any]:
    size = min(max(page_size, 1), 100)
    current_page = max(page, 1)
    total, rows = query.search_early_access_leads(
        db, term=term, offset=(current_page - 1) * size, limit=size
    )
    data = [
        {
            "id": str(row.id),
            "phone_e164": row.phone,
            "phone_display": row.phone,
            "full_name": row.full_name,
            "age": row.age,
            "gender": row.gender,
            "address": row.address,
            "status": row.status,
            "created_at": row.created_at.isoformat(),
        }
        for row in rows
    ]
    return {"rows": data, "total": total, "page": current_page, "page_size": size}


def update_lead_status(
    db: Session, actor: User, lead_id: UUID, payload: dict[str, Any]
) -> dict[str, Any]:
    if payload["status"] not in LEAD_STATUSES:
        raise ApiError(422, "INVALID_STATUS", "Trạng thái hồ sơ chưa hợp lệ.")
    operation = "early_access_lead_status_updated"
    normalized_payload = {"lead_id": str(lead_id), "status": payload["status"]}
    key = payload["idempotency_key"]
    with atomic(db):
        cached = _idempotent_result(
            db,
            actor=actor,
            operation=operation,
            key=key,
            payload=normalized_payload,
        )
        if cached is not None:
            return cached
        lead = db.scalar(
            select(EarlyAccessLead).where(EarlyAccessLead.id == lead_id).with_for_update()
        )
        if lead is None:
            raise ApiError(404, "LEAD_NOT_FOUND", "Không tìm thấy hồ sơ.")
        old_status = lead.status
        lead.status = payload["status"]
        if lead.status in {"rejected", "converted"}:
            lead.closed_at = datetime.now(UTC)
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=None,
            reason=payload["reason"],
            idempotency_key=key,
            metadata={
                "lead_id": str(lead.id),
                "from_status": old_status,
                "to_status": lead.status,
            },
        )
        result = {"success": True, "message": "Đã cập nhật trạng thái hồ sơ."}
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=key,
            digest=query.payload_hash(normalized_payload),
            result=result,
        )
        return result


def grant_membership_bulk(db: Session, actor: User, payload: dict[str, Any]) -> dict[str, Any]:
    operation = "admin-grant-membership-bulk"
    if payload["scope"] != "all_registered" or payload["plan_code"] != "plus":
        raise ApiError(422, "INVALID_BULK_SCOPE", "Phạm vi cấp gói hàng loạt chưa hợp lệ.")
    if payload.get("ends_at") is not None:
        raise ApiError(422, "INVALID_PERIOD", "Cấp gói hàng loạt chỉ hỗ trợ gói vĩnh viễn.")
    with atomic(db):
        cached = _idempotent_result(
            db,
            actor=actor,
            operation=operation,
            key=payload["idempotency_key"],
            payload=payload,
        )
        if cached is not None:
            return cached
        starts_at = payload["starts_at"]
        if starts_at.tzinfo is None:
            starts_at = starts_at.replace(tzinfo=UTC)
        users = db.scalars(select(User).order_by(User.id).with_for_update()).all()
        granted = already = family = 0
        for user in users:
            current = query.current_membership(db, user.id, datetime.now(UTC))
            if current is not None and current.plan_code == "family_plus":
                family += 1
                already += 1
                continue
            if current is not None and current.plan_code == "plus" and current.ends_at is None:
                already += 1
                continue
            db.add(
                MembershipSubscription(
                    user_id=user.id,
                    plan_code="plus",
                    status="active",
                    source="manual",
                    starts_at=starts_at,
                    ends_at=None,
                    created_by=actor.id,
                    reason=payload["reason"],
                )
            )
            user.membership_tier = "plus"
            granted += 1
        result = {
            "batch_id": str(uuid4()),
            "plan_code": "plus",
            "starts_at": starts_at.isoformat(),
            "ends_at": None,
            "target_count": len(users),
            "granted_count": granted,
            "already_granted_count": already,
            "family_plus_count": family,
        }
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=None,
            reason=payload["reason"],
            idempotency_key=payload["idempotency_key"],
            metadata={"target_count": len(users), "granted_count": granted},
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=payload["idempotency_key"],
            digest=query.payload_hash(payload),
            result=result,
        )
        return result


def _add_months(value: datetime, months: int) -> datetime:
    target = value.month - 1 + months
    year = value.year + target // 12
    month = target % 12 + 1
    return value.replace(
        year=year, month=month, day=min(value.day, calendar.monthrange(year, month)[1])
    )


def _inspect_bulk(
    db: Session, accounts: list[dict[str, Any]], plan_code: str, duration_months: int
) -> dict[str, Any]:
    candidates: list[dict[str, Any]] = []
    for index, item in enumerate(accounts, start=1):
        phone = normalize_vietnam_phone(str(item["phone"]))
        user = auth_query.get_user_by_phone(db, phone)
        current = query.current_membership(db, user.id, datetime.now(UTC)) if user else None
        status = (
            "new"
            if user is None
            else "paid_preserved"
            if current is not None and current.plan_code in MEMBERSHIP_PLANS
            else "existing"
        )
        candidates.append(
            {
                "index": index,
                "phone": phone,
                "full_name": str(item["full_name"]).strip(),
                "email": item.get("email"),
                "status": status,
                "current_plan": current.plan_code
                if current
                else (user.membership_tier if user else None),
            }
        )
    fingerprint_source = {
        "accounts": [
            {"phone": row["phone"], "status": row["status"], "current_plan": row["current_plan"]}
            for row in candidates
        ],
        "plan_code": plan_code,
        "duration_months": duration_months,
    }
    return {
        "fingerprint": query.payload_hash(fingerprint_source),
        "candidate_count": len(candidates),
        "candidates": candidates,
    }


def bulk_provision_preview(
    db: Session, *, accounts: list[dict[str, Any]], plan_code: str, duration_months: int
) -> dict[str, Any]:
    return _inspect_bulk(db, accounts, plan_code, duration_months)


def bulk_provision_execute(db: Session, actor: User, payload: dict[str, Any]) -> dict[str, Any]:
    if payload["plan_code"] not in MEMBERSHIP_PLANS or payload["duration_months"] not in {
        1,
        3,
        6,
        12,
    }:
        raise ApiError(422, "INVALID_BULK_PLAN", "Gói hoặc thời hạn cấp chưa hợp lệ.")
    if len(payload["accounts"]) > 100:
        raise ApiError(422, "INVALID_BULK_ACCOUNTS", "Batch tối đa gồm 100 tài khoản.")
    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in payload["accounts"]:
        phone = normalize_vietnam_phone(str(row["phone"]))
        full_name = str(row["full_name"]).strip()
        email = str(row["email"]).strip().lower() if row.get("email") else None
        if (
            "|" in full_name
            or len(full_name) < 2
            or (email and not _EMAIL_PATTERN.fullmatch(email))
        ):
            raise ApiError(422, "INVALID_BULK_ACCOUNT", "Thông tin tài khoản chưa hợp lệ.")
        if phone in seen:
            raise ApiError(422, "DUPLICATE_PHONE", "Danh sách có số điện thoại bị trùng.")
        seen.add(phone)
        normalized.append({"phone": phone, "full_name": full_name, "email": email})
    plan_code = payload["plan_code"]
    duration = payload["duration_months"]
    preview_source = {"accounts": normalized, "plan_code": plan_code, "duration_months": duration}
    operation = "admin-provision-accounts-bulk"
    request_hash = query.payload_hash(
        {
            **preview_source,
            "reason": payload["reason"],
            "preview_fingerprint": payload["preview_fingerprint"],
        }
    )
    with atomic(db):
        previous = query.find_idempotency(
            db, actor_id=actor.id, operation=operation, key=payload["idempotency_key"]
        )
        if previous is not None:
            if previous.request_hash != request_hash:
                raise ApiError(
                    409, "IDEMPOTENCY_CONFLICT", "Mã yêu cầu đã được dùng cho nội dung khác."
                )
            return previous.response_data or {}
        preview = _inspect_bulk(db, normalized, plan_code, duration)
        if preview["fingerprint"] != payload["preview_fingerprint"]:
            raise ApiError(
                409, "PREVIEW_STALE", "Dữ liệu tài khoản đã thay đổi. Hãy tạo bản xem trước mới."
            )
        if payload["confirmation"] != f"TAO TAI KHOAN {preview['candidate_count']}":
            raise ApiError(400, "CONFIRMATION_INVALID", "Chuỗi xác nhận chưa đúng.")
        now = now_utc()
        ends_at = _add_months(now, duration)
        created = granted = skipped = 0
        for candidate in preview["candidates"]:
            user = auth_query.get_user_by_phone(db, candidate["phone"])
            if user is None:
                user = User(
                    phone=candidate["phone"],
                    full_name=candidate["full_name"],
                    email=candidate["email"],
                    password_hash=hash_password(payload["password"]),
                    force_password_change=True,
                )
                db.add(user)
                db.flush()
                ensure_self_subject(db, user)
                created += 1
            current = query.current_membership(db, user.id, now)
            if current is not None and current.plan_code in MEMBERSHIP_PLANS:
                skipped += 1
                continue
            db.add(
                MembershipSubscription(
                    user_id=user.id,
                    plan_code=plan_code,
                    status="active",
                    source="manual",
                    starts_at=now,
                    ends_at=ends_at,
                    created_by=actor.id,
                    reason=payload["reason"],
                )
            )
            user.membership_tier = plan_code
            granted += 1
        result = {
            "batch_id": str(uuid4()),
            "processed_count": len(normalized),
            "created_count": created,
            "granted_count": granted,
            "skipped_count": skipped,
        }
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=None,
            reason=payload["reason"],
            idempotency_key=payload["idempotency_key"],
            metadata={"processed_count": len(normalized), "created_count": created},
        )
        db.add(
            IdempotencyRecord(
                actor_id=actor.id,
                operation=operation,
                idempotency_key=payload["idempotency_key"],
                request_hash=request_hash,
                response_data=result,
            )
        )
        return result


def get_user_details(db: Session, actor: User, user_id: UUID, reason: str) -> dict[str, Any]:
    with atomic(db):
        user = query.get_user_for_update(db, user_id)
        if user is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        query.add_audit(
            db,
            actor_id=actor.id,
            action="admin_view_user_health",
            target_user_id=user.id,
            reason=reason,
            metadata={"scope": "self_health_and_current_membership"},
        )
        return {
            "user": {
                "id": str(user.id),
                "phone": user.phone,
                "full_name": user.full_name,
                "email": user.email,
                "gender": user.gender,
                "birth_year": user.birth_year,
                "membership_tier": user.membership_tier,
            },
            "health": {},
        }


def update_user_profile(
    db: Session, actor: User, user_id: UUID, payload: dict[str, Any]
) -> dict[str, Any]:
    changes = {key: payload[key] for key in ("full_name", "gender", "birth_year") if key in payload}
    if not changes:
        raise ApiError(422, "NO_PROFILE_CHANGES", "Chưa có thông tin cần cập nhật.")
    if changes.get("gender") not in {None, "male", "female", "other", "prefer_not_to_say"}:
        raise ApiError(422, "INVALID_GENDER", "Thông tin giới tính chưa hợp lệ.")
    operation = "admin_update_user_profile"
    idempotency_payload = {"user_id": str(user_id), "changes": changes}
    key = payload["idempotency_key"]
    with atomic(db):
        cached = _idempotent_result(
            db, actor=actor, operation=operation, key=key, payload=idempotency_payload
        )
        if cached is not None:
            return cached
        user = query.get_user_for_update(db, user_id)
        if user is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        for field, value in changes.items():
            setattr(user, field, value)
        result = {"changed_fields": list(changes)}
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user.id,
            reason=payload["reason"],
            idempotency_key=key,
            metadata={"changed_fields": list(changes)},
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=key,
            digest=query.payload_hash(idempotency_payload),
            result=result,
        )
        return result


def update_user_status(
    db: Session, actor: User, user_id: UUID, payload: dict[str, Any]
) -> dict[str, Any]:
    status = str(payload.get("status", ""))
    if status not in {"active", "suspended", "closed"}:
        raise ApiError(422, "INVALID_USER_STATUS", "Trạng thái tài khoản chưa hợp lệ.")
    operation = "admin_update_user_status"
    normalized_payload = {"user_id": str(user_id), "status": status}
    key = str(payload["idempotency_key"])
    with atomic(db):
        cached = _idempotent_result(
            db,
            actor=actor,
            operation=operation,
            key=key,
            payload=normalized_payload,
        )
        if cached is not None:
            return cached
        user = query.get_user_for_update(db, user_id)
        if user is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        user.admin_status = status
        user.is_active = status == "active"
        user.updated_at = now_utc()
        if status != "active":
            db.query(RefreshSession).filter(
                RefreshSession.user_id == user.id,
                RefreshSession.revoked_at.is_(None),
            ).update({RefreshSession.revoked_at: now_utc()}, synchronize_session=False)
        result = {"success": True, "message": "Đã cập nhật trạng thái tài khoản."}
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user.id,
            reason=str(payload["reason"]).strip(),
            idempotency_key=key,
            metadata={"status": status},
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=key,
            digest=query.payload_hash(normalized_payload),
            result=result,
        )
        return result


def reset_user_password(
    db: Session, actor: User, user_id: UUID, reason: str, idempotency_key: str
) -> dict[str, Any]:
    operation = "admin_reset_member_password"
    payload = {"user_id": str(user_id)}
    with atomic(db):
        cached = _idempotent_result(
            db, actor=actor, operation=operation, key=idempotency_key, payload=payload
        )
        if cached is not None:
            return {**cached, "reset_password": _RESET_PASSWORD}
        user = query.get_user_for_update(db, user_id)
        if user is None:
            raise ApiError(404, "USER_NOT_FOUND", "Không tìm thấy tài khoản.")
        user.password_hash = hash_password(_RESET_PASSWORD)
        user.force_password_change = True
        user.updated_at = now_utc()
        db.query(RefreshSession).filter(RefreshSession.user_id == user.id).update(
            {RefreshSession.revoked_at: now_utc()}, synchronize_session=False
        )
        result = {"reset_password": _RESET_PASSWORD, "must_change_password": True}
        query.add_audit(
            db,
            actor_id=actor.id,
            action=operation,
            target_user_id=user.id,
            reason=reason,
            idempotency_key=idempotency_key,
        )
        query.add_idempotency(
            db,
            actor_id=actor.id,
            operation=operation,
            key=idempotency_key,
            digest=query.payload_hash(payload),
            result=result,
        )
        return result
