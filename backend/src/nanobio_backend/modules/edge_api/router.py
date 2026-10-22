from typing import Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import ApiError, success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.edge_api import view
from nanobio_backend.modules.edge_api.models import (
    AiReportRequest,
    EarlyAccessRequest,
    FoodEvidenceRequest,
    GooglePlayVerifyRequest,
)

router = APIRouter()


@router.post("/ai/generate")
def nabi_ai_generate(request: Request) -> Any:
    raise ApiError(503, "FEATURE_NOT_ENABLED", "Tính năng này chưa được bật trên máy chủ.")


@router.post("/food/scan/analyze")
def food_scan_analyze(request: Request) -> Any:
    raise ApiError(503, "FEATURE_NOT_ENABLED", "Tính năng này chưa được bật trên máy chủ.")


@router.post("/early-access")
def register_early_access(
    payload: EarlyAccessRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    result = view.register_early_access(payload, request, db)
    return success_response(
        request,
        result,
        business_code="EARLY_ACCESS_REGISTERED",
        message="Đã ghi nhận yêu cầu của bạn.",
    )


@router.post("/ai-content-reports", status_code=201)
def report_ai_content(
    payload: AiReportRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    result = view.report_ai_content(payload, db)
    return success_response(request, result, business_code="REPORT_RECEIVED", status_code=201)


@router.post("/food/evidence")
def food_evidence(
    payload: FoodEvidenceRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.food_evidence(payload, request, user, db)
    return success_response(request, result, business_code="FOOD_EVIDENCE_RETRIEVED")


@router.post("/payments/google-play/verify")
def verify_google_play_purchase(
    payload: GooglePlayVerifyRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.verify_google_play_purchase(payload, request, user, db)
    status = result["status"]
    if status == "verified":
        return success_response(
            request,
            result,
            business_code="PURCHASE_VERIFIED",
            message="Giao dịch đã được xác minh.",
        )
    if status == "pending":
        return success_response(
            request,
            result,
            business_code="PURCHASE_PENDING",
            message="Giao dịch đang chờ Google Play hoàn tất.",
            status_code=202,
            meta={"retryable": True},
        )
    raise ApiError(409, "PURCHASE_REJECTED", "Giao dịch chưa đủ điều kiện để cập nhật gói.")
