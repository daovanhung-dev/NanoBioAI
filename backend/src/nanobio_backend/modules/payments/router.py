from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.payments import view
from nanobio_backend.modules.payments.models import MembershipPaymentCreateRequest

router = APIRouter()


@router.post("/membership-requests", status_code=201)
def create_membership_request(
    payload: MembershipPaymentCreateRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.create_manual_membership_payment(
        db,
        user,
        request.app.state.settings,
        plan_code=payload.plan_code,
        billing_cycle=payload.billing_cycle,
        idempotency_key=payload.idempotency_key,
        payer_full_name=payload.payer_full_name,
    )
    return success_response(
        request,
        result,
        business_code="MEMBERSHIP_PAYMENT_REQUEST_CREATED",
        status_code=201,
    )


@router.get("/membership-requests/me")
def get_membership_request(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.get_manual_membership_payment(db, user),
        business_code="MEMBERSHIP_PAYMENT_REQUEST_RETRIEVED",
    )


@router.post("/membership-requests/{payment_id}/confirm")
def confirm_membership_request(
    payment_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.confirm_manual_membership_payment(db, user, payment_id)
    return success_response(request, result, business_code="PAYMENT_TRANSFER_CONFIRMED")


@router.post("/membership-requests/{payment_id}/cancel")
def cancel_membership_request(
    payment_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.cancel_manual_membership_payment(db, user, payment_id)
    return success_response(request, result, business_code="PAYMENT_REQUEST_CANCELED")
