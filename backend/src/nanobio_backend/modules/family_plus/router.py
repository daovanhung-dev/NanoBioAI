from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.family_plus import view
from nanobio_backend.modules.family_plus.models import (
    FamilyGroupUpsertRequest,
    FamilyMemberRemoveRequest,
    FamilyMemberUpsertRequest,
)

router = APIRouter()


@router.get("/context")
def get_context(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request, view.get_context(db, user), business_code="FAMILYPLUS_CONTEXT_RETRIEVED"
    )


@router.put("/group")
def upsert_group(
    payload: FamilyGroupUpsertRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.upsert_group(
        db,
        user,
        display_name=payload.display_name,
        idempotency_key=payload.idempotency_key,
    )
    return success_response(request, result, business_code="FAMILYPLUS_GROUP_UPDATED")


@router.put("/members")
def upsert_member(
    payload: FamilyMemberUpsertRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.upsert_member(
        db,
        user,
        subject_id=payload.subject_id,
        display_name=payload.display_name,
        role=payload.role,
        can_view=payload.can_view,
        can_edit=payload.can_edit,
        idempotency_key=payload.idempotency_key,
    )
    return success_response(request, result, business_code="FAMILYPLUS_MEMBER_UPDATED")


@router.delete("/members/{member_id}")
def remove_member(
    member_id: UUID,
    payload: FamilyMemberRemoveRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.remove_member(
        db, user, member_id=member_id, idempotency_key=payload.idempotency_key
    )
    return success_response(request, result, business_code="FAMILYPLUS_MEMBER_REMOVED")
