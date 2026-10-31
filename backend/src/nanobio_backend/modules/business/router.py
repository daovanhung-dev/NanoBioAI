from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user, require_admin
from nanobio_backend.db.models import User
from nanobio_backend.modules.business import view
from nanobio_backend.modules.business.models import (
    BusinessAdminMutation,
    ReferralAttachRequest,
    SaleConversionRequest,
    SaleParticipationRequest,
    SalePayoutProfileRequest,
    WellnessRedemptionRequest,
)

router = APIRouter()


@router.get("/sale/me")
def sale_state(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    return success_response(
        request, view.get_sale_state(db, user), business_code="SALE_STATE_RETRIEVED"
    )


@router.post("/sale/participation")
def request_sale_participation(
    payload: SaleParticipationRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.request_sale_participation(db, user, payload),
        business_code="SALE_PARTICIPATION_REQUESTED",
    )


@router.post("/sale/referrals/attach")
def attach_referral(
    payload: ReferralAttachRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request, view.attach_referral(db, user, payload), business_code="REFERRAL_ATTACHED"
    )


@router.get("/sale/payout-profile")
def sale_payout_profile(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    return success_response(
        request, view.get_payout_profile(db, user), business_code="SALE_PAYOUT_PROFILE_RETRIEVED"
    )


@router.put("/sale/payout-profile")
def update_sale_payout_profile(
    payload: SalePayoutProfileRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.upsert_payout_profile(db, user, payload),
        business_code="SALE_PAYOUT_PROFILE_UPDATED",
    )


@router.get("/sale/dashboard")
def sale_dashboard(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    return success_response(
        request, view.get_sale_dashboard(db, user), business_code="SALE_DASHBOARD_RETRIEVED"
    )


@router.get("/sale/customers")
def sale_customers(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    data = view.get_sale_customers(db, user)
    return success_response(
        request, data, business_code="SALE_CUSTOMERS_RETRIEVED", meta={"count": len(data)}
    )


@router.get("/sale/point-ledger")
def sale_point_ledger(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    data = view.get_sale_point_ledger(db, user)
    return success_response(
        request, data, business_code="SALE_LEDGER_RETRIEVED", meta={"count": len(data)}
    )


@router.get("/sale/conversions")
def sale_conversions(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    data = view.get_sale_conversions(db, user)
    return success_response(
        request, data, business_code="SALE_CONVERSIONS_RETRIEVED", meta={"count": len(data)}
    )


@router.post("/sale/conversions")
def create_sale_conversion(
    payload: SaleConversionRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.request_sale_conversion(db, user, payload),
        business_code="SALE_CONVERSION_REQUESTED",
    )


@router.get("/wellness/rewards/summary")
def wellness_reward_summary(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    return success_response(
        request,
        view.get_wellness_reward_summary(db, user),
        business_code="WELLNESS_SUMMARY_RETRIEVED",
    )


@router.get("/wellness/rewards/history")
def wellness_point_history(
    request: Request,
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    data = view.list_wellness_point_history(db, user, limit)
    return success_response(
        request, data, business_code="WELLNESS_HISTORY_RETRIEVED", meta={"count": len(data)}
    )


@router.get("/wellness/rewards/offers")
def wellness_offers(
    request: Request,
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    data = view.list_wellness_offers(db, user, limit)
    return success_response(
        request, data, business_code="WELLNESS_OFFERS_RETRIEVED", meta={"count": len(data)}
    )


@router.get("/wellness/rewards/redemptions")
def wellness_redemptions(
    request: Request,
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    data = view.list_wellness_redemptions(db, user, limit)
    return success_response(
        request, data, business_code="WELLNESS_REDEMPTIONS_RETRIEVED", meta={"count": len(data)}
    )


@router.post("/wellness/rewards/redemptions")
def redeem_wellness_offer(
    payload: WellnessRedemptionRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.redeem_wellness_offer(db, user, payload),
        business_code="WELLNESS_REWARD_REDEEMED",
    )


@router.get("/wellness/rewards/redemptions/{redemption_id}/code")
def wellness_reward_code(
    redemption_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.get_wellness_reward_code(db, user, redemption_id),
        business_code="WELLNESS_REWARD_CODE_RETRIEVED",
    )


@router.get("/wellness/rank/summary")
def wellness_rank_summary(
    request: Request, user: User = Depends(current_user), db: Session = Depends(get_db)
) -> Any:
    return success_response(
        request, view.get_wellness_rank_summary(db, user), business_code="WELLNESS_RANK_RETRIEVED"
    )


@router.get("/admin/dashboard")
def business_dashboard(
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
    from_date: str | None = Query(default=None, alias="from"),
    to_date: str | None = Query(default=None, alias="to"),
) -> Any:
    require_admin(actor)
    return success_response(
        request,
        view.get_admin_dashboard(db, from_date, to_date),
        business_code="ADMIN_DASHBOARD_RETRIEVED",
    )


@router.get("/admin/business/{section}")
def admin_business_list(
    section: str,
    request: Request,
    q: str = Query(default="", max_length=120),
    limit: int = Query(default=100, ge=1, le=200),
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    role_scope = {
        "sales": ("super_admin", "operations_admin"),
        "sale-conversions": ("super_admin", "finance_admin"),
        "wellness-rewards": ("super_admin", "content_admin"),
        "reconciliation": ("super_admin", "finance_admin", "operations_admin"),
        "plans": ("super_admin", "operations_admin"),
        "config": ("super_admin", "operations_admin"),
        "reports": ("super_admin", "operations_admin"),
        "report-exports": ("super_admin", "operations_admin"),
    }
    require_admin(actor, *role_scope.get(section, ("super_admin",)))
    data = view.admin_list_business_items(db, section, q, limit)
    return success_response(
        request, data, business_code="ADMIN_BUSINESS_ITEMS_RETRIEVED", meta={"count": len(data)}
    )


@router.post("/admin/business/{section}")
def admin_business_mutation(
    section: str,
    payload: BusinessAdminMutation,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    require_admin(actor)
    result = view.admin_mutate_business_item(db, actor, section, payload)
    result.setdefault("success", True)
    result.setdefault("message", "Đã cập nhật dữ liệu quản trị.")
    return success_response(request, result, business_code="ADMIN_BUSINESS_ITEM_UPDATED")
