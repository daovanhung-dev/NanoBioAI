from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, File, Request, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user, require_admin
from nanobio_backend.db.models import User
from nanobio_backend.modules.schedule_rewards import view
from nanobio_backend.modules.schedule_rewards.models import (
    BeginCompletionRequest,
    FinalizeCompletionRequest,
    HealthCheckinRequest,
    RegisterEligibilityRequest,
    UndoCompletionRequest,
    UndoHealthCheckinRequest,
)

router = APIRouter()


@router.post("/eligibilities")
def register_eligibilities(
    payload: RegisterEligibilityRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.register_eligibilities(db, user, payload),
        business_code="SCHEDULE_REWARDS_REGISTERED",
    )


@router.post("/completions/begin")
def begin_completion(
    payload: BeginCompletionRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.begin_completion(db, user, payload),
        business_code="SCHEDULE_COMPLETION_BEGUN",
    )


@router.post("/completions/{attempt_id}/proof", status_code=201)
def upload_proof(
    attempt_id: UUID,
    request: Request,
    file: UploadFile = File(...),
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.upload_proof(db, request, user, attempt_id, file)
    return success_response(
        request, result, business_code="SCHEDULE_PROOF_UPLOADED", status_code=201
    )


@router.get("/completions/{attempt_id}/proof")
def download_proof(
    attempt_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    return view.download_proof(db, request, user, attempt_id)


@router.get("/completions/{attempt_id}/proof/admin")
def download_proof_admin(
    attempt_id: UUID,
    request: Request,
    actor: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    require_admin(actor, "operations_admin")
    return view.download_proof_admin(db, request, attempt_id)


@router.post("/completions/{attempt_id}/finalize")
def finalize_completion(
    attempt_id: UUID,
    payload: FinalizeCompletionRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.finalize_completion(db, user, attempt_id, payload),
        business_code="SCHEDULE_COMPLETION_FINALIZED",
    )


@router.post("/completions/undo")
def undo_completion(
    payload: UndoCompletionRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.undo_completion(db, user, payload),
        business_code="SCHEDULE_COMPLETION_UNDONE",
    )


@router.post("/health-checkins")
def finalize_health_checkin(
    payload: HealthCheckinRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.finalize_health_checkin(db, user, payload),
        business_code="SCHEDULE_HEALTH_CHECKIN_FINALIZED",
    )


@router.post("/health-checkins/undo")
def undo_health_checkin(
    payload: UndoHealthCheckinRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.undo_health_checkin(db, user, payload),
        business_code="SCHEDULE_HEALTH_CHECKIN_UNDONE",
    )
