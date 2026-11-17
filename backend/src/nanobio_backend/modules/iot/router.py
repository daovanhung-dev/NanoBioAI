from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Request, WebSocket
from sqlalchemy.orm import Session

from nanobio_backend.core.database import get_db
from nanobio_backend.core.responses import success_response
from nanobio_backend.core.security import current_user
from nanobio_backend.db.models import User
from nanobio_backend.modules.iot import view
from nanobio_backend.modules.iot.models import (
    DeviceClaimRequest,
    DeviceConsentRequest,
    DeviceCredentialLoginRequest,
    DeviceCredentialRefreshRequest,
    DeviceRenameRequest,
    SensitiveUnlockRequest,
)
from nanobio_backend.modules.iot.voice import serve_voice_websocket

router = APIRouter()


@router.post("/devices/credentials/login")
def authenticate_device(
    payload: DeviceCredentialLoginRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.authenticate_device(
            db,
            request,
            device_id=payload.device_id,
            identifier_type=payload.identifier_type,
            identifier=payload.identifier,
            password=payload.password.get_secret_value(),
            client_ip=request.client.host if request.client else "unknown",
        ),
        business_code="IOT_DEVICE_AUTHENTICATED",
        message="Thiết bị đã đăng nhập.",
    )


@router.post("/pairing-sessions", status_code=201)
def create_pairing_session(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.create_pairing_session(db, user),
        business_code="IOT_PAIRING_SESSION_CREATED",
        message="Đã tạo phiên ghép thiết bị.",
        status_code=201,
    )


@router.get("/pairing-sessions/{pairing_id}")
def get_pairing_session(
    pairing_id: UUID,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.get_pairing_session(db, user, pairing_id),
        business_code="IOT_PAIRING_SESSION_RETRIEVED",
    )


@router.post("/devices/claim")
def claim_device(
    payload: DeviceClaimRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.claim_device(
            db,
            request,
            device_id=payload.device_id,
            pairing_token=payload.pairing_token,
            name=payload.name,
        ),
        business_code="IOT_DEVICE_CLAIMED",
        message="Thiết bị đã được liên kết.",
    )


@router.post("/devices/credentials/refresh")
def refresh_device_credentials(
    payload: DeviceCredentialRefreshRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.refresh_device_credentials(
            db,
            request,
            device_id=payload.device_id,
            refresh_token=payload.refresh_token,
        ),
        business_code="IOT_DEVICE_CREDENTIALS_ROTATED",
    )


@router.get("/devices")
def list_devices(
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.list_devices(db, user),
        business_code="IOT_DEVICES_RETRIEVED",
    )


@router.patch("/devices/{device_id}")
def rename_device(
    device_id: str,
    payload: DeviceRenameRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.rename_device(db, user, device_id, payload.name),
        business_code="IOT_DEVICE_RENAMED",
    )


@router.put("/devices/{device_id}/consents")
def update_device_consent(
    device_id: str,
    payload: DeviceConsentRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.update_device_consent(db, user, device_id, payload),
        business_code="IOT_DEVICE_CONSENT_UPDATED",
    )


@router.post("/devices/{device_id}/sensitive-unlock")
def unlock_sensitive_context(
    device_id: str,
    payload: SensitiveUnlockRequest,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    del payload
    return success_response(
        request,
        view.unlock_sensitive_context(db, user, device_id),
        business_code="IOT_SENSITIVE_CONTEXT_UNLOCKED",
        message="Dữ liệu sức khỏe đã mở trong 5 phút cho phiên Nabi đang kết nối.",
    )


@router.delete("/devices/{device_id}")
def unbind_device(
    device_id: str,
    request: Request,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> Any:
    return success_response(
        request,
        view.unbind_device(db, user, device_id),
        business_code="IOT_DEVICE_UNBOUND",
        message="Đã hủy liên kết và thu hồi thông tin kết nối.",
    )


@router.websocket("/ws")
async def voice_websocket(websocket: WebSocket) -> None:
    await serve_voice_websocket(websocket)
