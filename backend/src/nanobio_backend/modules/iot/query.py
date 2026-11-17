from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from nanobio_backend.db.models import (
    CloudSnapshot,
    IotDevice,
    IotDeviceConsent,
    IotDeviceCredential,
    IotDeviceSession,
    IotPairingSession,
)


def get_pairing_by_token(
    db: Session, token_hash: str, *, for_update: bool = False
) -> IotPairingSession | None:
    statement = select(IotPairingSession).where(IotPairingSession.token_hash == token_hash)
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def get_pairing_for_owner(
    db: Session, pairing_id: UUID, owner_id: UUID
) -> IotPairingSession | None:
    return db.scalar(
        select(IotPairingSession).where(
            IotPairingSession.id == pairing_id,
            IotPairingSession.owner_id == owner_id,
        )
    )


def get_device(db: Session, device_id: str, *, for_update: bool = False) -> IotDevice | None:
    statement = select(IotDevice).where(IotDevice.id == device_id)
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def get_owned_device(
    db: Session, device_id: str, owner_id: UUID, *, for_update: bool = False
) -> IotDevice | None:
    statement = select(IotDevice).where(
        IotDevice.id == device_id,
        IotDevice.owner_id == owner_id,
        IotDevice.unbound_at.is_(None),
    )
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def list_devices(db: Session, owner_id: UUID) -> list[IotDevice]:
    return list(
        db.scalars(
            select(IotDevice)
            .where(IotDevice.owner_id == owner_id, IotDevice.unbound_at.is_(None))
            .order_by(IotDevice.created_at.desc(), IotDevice.id)
        )
    )


def get_credentials(
    db: Session, device_id: str, *, for_update: bool = False
) -> IotDeviceCredential | None:
    statement = select(IotDeviceCredential).where(IotDeviceCredential.device_id == device_id)
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def get_credentials_by_access(db: Session, access_hash: str) -> IotDeviceCredential | None:
    return db.scalar(
        select(IotDeviceCredential).where(IotDeviceCredential.access_token_hash == access_hash)
    )


def get_credentials_by_refresh(
    db: Session, refresh_hash: str, *, for_update: bool = False
) -> IotDeviceCredential | None:
    statement = select(IotDeviceCredential).where(
        IotDeviceCredential.refresh_token_hash == refresh_hash
    )
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def get_consent(db: Session, device_id: str) -> IotDeviceConsent | None:
    return db.get(IotDeviceConsent, device_id)


def get_session(
    db: Session, device_id: str, *, for_update: bool = False
) -> IotDeviceSession | None:
    statement = select(IotDeviceSession).where(IotDeviceSession.device_id == device_id)
    if for_update:
        statement = statement.with_for_update()
    return db.scalar(statement)


def get_mobile_snapshot(db: Session, owner_id: UUID) -> CloudSnapshot | None:
    return db.scalar(
        select(CloudSnapshot).where(
            CloudSnapshot.user_id == owner_id,
            CloudSnapshot.snapshot_type == "mobile-v1",
        )
    )
