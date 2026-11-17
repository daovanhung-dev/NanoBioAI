"""Add owner-bound Nabi IoT devices, credentials, consent and session leases.

Revision ID: 0008_iot_devices
Revises: 0007_admin_username
Create Date: 2026-11-02
"""

from alembic import op

from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.base import Base

revision = "0008_iot_devices"
down_revision = "0007_admin_username"
branch_labels = None
depends_on = None


IOT_TABLES = [
    Base.metadata.tables[name]
    for name in (
        "iot_devices",
        "iot_pairing_sessions",
        "iot_device_credentials",
        "iot_device_consents",
        "iot_device_sessions",
    )
]


def upgrade() -> None:
    # The repository's initial migration builds current metadata dynamically.
    # checkfirst keeps this forward migration safe on databases where those
    # tables were already created by that initial migration.
    Base.metadata.create_all(bind=op.get_bind(), tables=IOT_TABLES, checkfirst=True)


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind(), tables=list(reversed(IOT_TABLES)), checkfirst=True)
