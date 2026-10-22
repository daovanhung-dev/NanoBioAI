"""Initial NanoBio backend schema for source-backed contracts.

Revision ID: 0001_initial
Revises:
Create Date: 2026-10-22
"""

from alembic import op

from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.base import Base

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    Base.metadata.create_all(bind=op.get_bind())


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind())
