from datetime import datetime
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import ApiError, success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.sleep_safety import view
from nanobio_backend.modules.sleep_safety.models import (
    ContactUpsertRequest,
    DispatchRequest,
    SleepSafetyEventSync,
    SleepSafetyPreferenceSync,
    SleepSafetySessionSync,
    VerificationRequest,
)

router = APIRouter()


class ProviderWebhookRequest(BaseModel):
    id: str | None = Field(default=None, max_length=160)
    provider_external_id: str | None = Field(default=None, max_length=160)
    status: str = Field(min_length=1, max_length=40)


def _callback_url(request: Request) -> str | None:
    root = request.app.state.settings.public_api_base_url
    if not root:
        return None
    return f"{root.rstrip('/')}/api/v1/webhooks/sleep-safety/generic_http"


@router.get("/sleep-safety/runtime-config")
def get_runtime_config(request: Request, user: User = Depends(current_user)) -> Any:
    return success_response(
        request,
        view.runtime_config(request.app.state.settings),
        business_code="SLEEP_SAFETY_CONFIG_RETRIEVED",
    )


@router.get("/sleep-safety/history")
def list_sleep_safety_history(
    request: Request,
    limit: int = Query(default=100, ge=1, le=200),
    before: datetime | None = None,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    data = view.list_history(db, user, limit=limit, before=before)
    return success_response(
        request,
        data,
        business_code="SLEEP_SAFETY_HISTORY_RETRIEVED",
        meta={"session_count": len(data["sessions"]), "event_count": len(data["events"])},
    )


@router.put("/sleep-safety/preferences")
def sync_preferences(
    payload: SleepSafetyPreferenceSync,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.sync_preference(db, user, values=payload.model_dump()),
        business_code="SLEEP_SAFETY_PREFERENCES_SYNCED",
    )


@router.put("/sleep-safety/sessions/{session_id}")
def sync_session(
    session_id: str,
    payload: SleepSafetySessionSync,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.sync_session(db, user, session_id=session_id, values=payload.model_dump()),
        business_code="SLEEP_SAFETY_SESSION_SYNCED",
    )


@router.put("/sleep-safety/events/{event_id}")
def sync_event(
    event_id: str,
    payload: SleepSafetyEventSync,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.sync_event(db, user, event_id=event_id, values=payload.model_dump()),
        business_code="SLEEP_SAFETY_EVENT_SYNCED",
    )


@router.get("/sleep-safety/contacts")
def list_contacts(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request, view.list_contact_views(db, user), business_code="CONTACTS_RETRIEVED"
    )


@router.post("/sleep-safety/contacts", status_code=201)
def create_contact(
    payload: ContactUpsertRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.upsert_contact(
        db,
        user,
        contact_id=None,
        name=payload.name,
        relationship=payload.relationship,
        phone_e164=payload.phone_e164,
        priority=payload.priority,
        allow_phone_fallback=payload.allow_phone_fallback,
        allow_unverified_voice_alert=payload.allow_unverified_voice_alert,
    )
    return success_response(request, result, business_code="CONTACT_CREATED", status_code=201)


@router.put("/sleep-safety/contacts/{contact_id}")
def update_contact(
    contact_id: UUID,
    payload: ContactUpsertRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.upsert_contact(
        db,
        user,
        contact_id=contact_id,
        name=payload.name,
        relationship=payload.relationship,
        phone_e164=payload.phone_e164,
        priority=payload.priority,
        allow_phone_fallback=payload.allow_phone_fallback,
        allow_unverified_voice_alert=payload.allow_unverified_voice_alert,
    )
    return success_response(request, result, business_code="CONTACT_UPDATED")


@router.delete("/sleep-safety/contacts/{contact_id}")
def delete_contact(
    contact_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    deleted = view.delete_contact(db, user, contact_id)
    return success_response(request, {"deleted": deleted}, business_code="CONTACT_DELETED")


@router.post("/sleep-safety/contacts/verification")
def contact_verification(
    payload: VerificationRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.request_or_confirm_verification(
        db,
        user,
        action=payload.action,
        contact_id=payload.contact_id,
        code=payload.code,
        settings=request.app.state.settings,
        callback_url=_callback_url(request),
    )
    return success_response(request, result, business_code="CONTACT_VERIFICATION_UPDATED")


@router.post("/sleep-safety/dispatch")
def dispatch_sleep_safety(
    payload: DispatchRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    result = view.dispatch_event(
        db,
        user,
        event_id=payload.event_id,
        idempotency_key=payload.idempotency_key,
        settings=request.app.state.settings,
        callback_url=_callback_url(request),
    )
    return success_response(
        request, result, business_code="SLEEP_SAFETY_DISPATCH_ACCEPTED", status_code=202
    )


@router.post("/webhooks/sleep-safety/{provider}")
def sleep_safety_webhook(
    provider: str,
    payload: ProviderWebhookRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    if provider != "generic_http":
        raise ApiError(404, "WEBHOOK_PROVIDER_NOT_FOUND", "Không tìm thấy nhà cung cấp.")
    external_id = (payload.id or payload.provider_external_id or "").strip()
    result = view.process_provider_webhook(
        db,
        request.app.state.settings,
        external_id=external_id,
        provider_status=payload.status,
        callback_token=request.headers.get("x-sleep-safety-token"),
        callback_url=_callback_url(request),
    )
    return success_response(request, result, business_code="SLEEP_SAFETY_CALLBACK_ACCEPTED")
