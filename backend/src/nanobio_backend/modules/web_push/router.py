from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Request
from sqlalchemy.orm import Session

from nanobio_backend.core.config import Settings
from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.modules.web_push import view
from nanobio_backend.modules.web_push.models import (
    PushSubscriptionInput,
    WebPushReminderBatch,
)

router = APIRouter()


@router.get("/config")
def get_config(request: Request) -> Any:
    settings: Settings = request.app.state.settings
    return success_response(
        request,
        view.get_public_config(settings),
        business_code="WEB_PUSH_CONFIG",
    )


@router.post("/subscriptions", status_code=201)
def create_subscription(
    payload: PushSubscriptionInput,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    result = view.create_subscription(db, payload)
    return success_response(
        request,
        result,
        business_code="WEB_PUSH_SUBSCRIPTION_CREATED",
        status_code=201,
    )


@router.put("/subscriptions/{subscription_id}/reminders")
def put_reminders(
    subscription_id: UUID,
    payload: WebPushReminderBatch,
    request: Request,
    capability: str = Header(alias="X-Guest-Capability"),
    db: Session = Depends(get_db),
) -> Any:
    result = view.replace_reminders(db, subscription_id, capability, payload)
    return success_response(request, result, business_code="WEB_PUSH_REMINDERS_SAVED")


@router.delete("/subscriptions/{subscription_id}")
def remove_subscription(
    subscription_id: UUID,
    request: Request,
    capability: str = Header(alias="X-Guest-Capability"),
    db: Session = Depends(get_db),
) -> Any:
    view.delete_subscription(db, subscription_id, capability)
    return success_response(
        request,
        {"deleted": True},
        business_code="WEB_PUSH_SUBSCRIPTION_DELETED",
    )
