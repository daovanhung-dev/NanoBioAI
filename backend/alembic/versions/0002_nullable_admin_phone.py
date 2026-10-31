"""Allow email-only imported administrator accounts.

Revision ID: 0002_nullable_admin_phone
Revises: 0001_initial
Create Date: 2026-10-30
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

revision = "0002_nullable_admin_phone"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    columns = {column["name"]: column for column in inspect(bind).get_columns("users")}
    phone = columns.get("phone")
    if phone is not None and not phone["nullable"]:
        op.alter_column(
            "users",
            "phone",
            existing_type=sa.String(length=16),
            nullable=True,
        )
    if "app_access_mode" not in columns:
        op.add_column(
            "users",
            sa.Column(
                "app_access_mode", sa.String(length=16), nullable=False, server_default="user"
            ),
        )
    if "admin_status" not in columns:
        op.add_column(
            "users",
            sa.Column(
                "admin_status", sa.String(length=24), nullable=False, server_default="active"
            ),
        )


def downgrade() -> None:
    columns = {column["name"] for column in inspect(op.get_bind()).get_columns("users")}
    if "admin_status" in columns:
        op.drop_column("users", "admin_status")
    if "app_access_mode" in columns:
        op.drop_column("users", "app_access_mode")
    if "phone" in columns:
        op.alter_column(
            "users",
            "phone",
            existing_type=sa.String(length=16),
            nullable=False,
        )
