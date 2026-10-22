from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import ApiError, success_response
from nanobio_backend.core.security import current_user, require_admin
from nanobio_backend.db.models import User
from nanobio_backend.modules.admin import view
from nanobio_backend.modules.admin.models import (
    AccountCreateRequest,
    BulkMembershipGrantRequest,
    BulkProvisionExecuteRequest,
    BulkProvisionPreviewRequest,
    EarlyAccessLeadStatusRequest,
    MembershipAdjustmentRequest,
    MembershipGrantRequest,
    UserProfileUpdateRequest,
)
from nanobio_backend.modules.auth.validate import normalize_vietnam_phone
from nanobio_backend.modules.payments import view as payments_view
from nanobio_backend.modules.payments.models import AdminPaymentReviewRequest

router = APIRouter()


@router.get("/session")
def admin_session(request: Request, actor: User = Depends(current_user)) -> Any:
    require_admin(actor)
    return success_response(
        request,
        {"user_id": str(actor.id), "roles": sorted(actor.admin_roles)},
        business_code="ADMIN_SESSION_RETRIEVED",
    )


@router.get("/users/search")
def search_users(
    request: Request,
    q: str = Query(default="", max_length=120),
    limit: int = Query(default=50, ge=1, le=100),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor)
    data = view.search_users(db, term=q, limit=limit)
    return success_response(
        request, data, business_code="USERS_RETRIEVED", meta={"count": len(data)}
    )


@router.post("/accounts", status_code=201)
def create_account(
    payload: AccountCreateRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    result = view.create_account(db, actor, payload.model_dump())
    return success_response(request, result, business_code="ACCOUNT_CREATED", status_code=201)


@router.post("/memberships/grant")
def grant_membership(
    payload: MembershipGrantRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    result = view.grant_membership(db, actor, payload.model_dump())
    return success_response(request, result, business_code="MEMBERSHIP_UPDATED")


@router.post("/memberships/adjust-period")
def adjust_membership(
    payload: MembershipAdjustmentRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    result = view.adjust_membership(db, actor, payload.model_dump())
    return success_response(request, result, business_code="MEMBERSHIP_PERIOD_UPDATED")


@router.post("/memberships/bulk-grant")
def grant_membership_bulk(
    payload: BulkMembershipGrantRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    result = view.grant_membership_bulk(db, actor, payload.model_dump())
    return success_response(request, result, business_code="MEMBERSHIP_BULK_UPDATED")


@router.post("/accounts/bulk-provision/preview")
def preview_bulk_accounts(
    payload: BulkProvisionPreviewRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    if payload.mode != "preview":
        raise ApiError(422, "INVALID_MODE", "Chế độ xem trước chưa hợp lệ.")
    if payload.plan_code not in {"plus", "family_plus"} or payload.duration_months not in {
        1,
        3,
        6,
        12,
    }:
        raise ApiError(422, "INVALID_BULK_PLAN", "Gói hoặc thời hạn cấp chưa hợp lệ.")
    accounts = [row.model_dump() for row in payload.accounts]
    seen: set[str] = set()
    for row in accounts:
        normalized_phone = normalize_vietnam_phone(row["phone"])
        if normalized_phone in seen:
            raise ApiError(422, "DUPLICATE_PHONE", "Danh sách có số điện thoại bị trùng.")
        seen.add(normalized_phone)
        row["phone"] = normalized_phone
    preview = view.bulk_provision_preview(
        db, accounts=accounts, plan_code=payload.plan_code, duration_months=payload.duration_months
    )
    public_rows = [
        {"index": row["index"], "status": row["status"], "current_plan": row["current_plan"]}
        for row in preview["candidates"]
    ]
    return success_response(
        request,
        {
            "fingerprint": preview["fingerprint"],
            "candidate_count": preview["candidate_count"],
            "rows": public_rows,
        },
        business_code="BULK_PROVISION_PREVIEWED",
    )


@router.post("/accounts/bulk-provision")
def execute_bulk_accounts(
    payload: BulkProvisionExecuteRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    if payload.mode != "execute":
        raise ApiError(422, "INVALID_MODE", "Chế độ tạo tài khoản chưa hợp lệ.")
    data = payload.model_dump()
    data["accounts"] = [row.model_dump() for row in payload.accounts]
    result = view.bulk_provision_execute(db, actor, data)
    return success_response(request, result, business_code="BULK_PROVISION_COMPLETED")


@router.get("/users/{user_id}")
def get_user_details(
    user_id: UUID,
    request: Request,
    reason: str = Query(min_length=2, max_length=500),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor)
    return success_response(
        request,
        view.get_user_details(db, actor, user_id, reason),
        business_code="USER_DETAILS_RETRIEVED",
    )


@router.patch("/users/{user_id}/profile")
def update_user_profile(
    user_id: UUID,
    payload: UserProfileUpdateRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor)
    data = payload.model_dump(exclude_unset=True)
    return success_response(
        request,
        view.update_user_profile(db, actor, user_id, data),
        business_code="USER_PROFILE_UPDATED",
    )


@router.post("/users/{user_id}/password-reset")
def reset_user_password(
    user_id: UUID,
    request: Request,
    reason: str = Query(min_length=2, max_length=500),
    idempotency_key: str = Query(min_length=8, max_length=160),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin")
    result = view.reset_user_password(db, actor, user_id, reason, idempotency_key)
    return success_response(request, result, business_code="MEMBER_PASSWORD_RESET")


@router.get("/audit-events")
def audit_events(
    request: Request,
    limit: int = Query(default=100, ge=1, le=100),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor)
    return success_response(
        request, view.list_audit(db, limit=limit), business_code="AUDIT_EVENTS_RETRIEVED"
    )


@router.get("/payments/review-alert")
def payment_review_alert(
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin", "finance_admin")
    return success_response(
        request,
        {"pending_review_count": view.payment_review_count(db)},
        business_code="PAYMENT_REVIEW_ALERT_RETRIEVED",
    )


@router.get("/payments")
def list_payments(
    request: Request,
    q: str = Query(default="", max_length=120),
    limit: int = Query(default=50, ge=1, le=100),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin", "finance_admin")
    data = payments_view.list_manual_payments_for_admin(db, term=q, limit=limit)
    return success_response(
        request, data, business_code="PAYMENTS_RETRIEVED", meta={"count": len(data)}
    )


@router.post("/payments/{payment_id}/review")
def review_payment(
    payment_id: UUID,
    payload: AdminPaymentReviewRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin", "finance_admin")
    result = payments_view.review_manual_membership_payment(
        db,
        actor,
        payment_id,
        decision=payload.decision,
        reason=payload.reason,
        idempotency_key=payload.idempotency_key,
        transfer_verified=payload.transfer_verified,
    )
    return success_response(request, result, business_code="PAYMENT_REVIEWED")


@router.get("/early-access/leads")
def early_access_leads(
    request: Request,
    q: str = Query(default="", max_length=120),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=25, ge=1, le=100),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin", "support_admin", "operations_admin")
    return success_response(
        request,
        view.list_early_access_leads(db, term=q, page=page, page_size=page_size),
        business_code="LEADS_RETRIEVED",
    )


@router.patch("/early-access/leads/{lead_id}")
def update_early_access_lead(
    lead_id: UUID,
    payload: EarlyAccessLeadStatusRequest,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor, "super_admin", "support_admin", "operations_admin")
    result = view.update_lead_status(db, actor, lead_id, payload.model_dump())
    return success_response(request, result, business_code="LEAD_STATUS_UPDATED")
