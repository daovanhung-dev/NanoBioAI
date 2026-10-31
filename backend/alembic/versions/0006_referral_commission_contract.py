"""Complete payment and referral commission persistence.

Revision ID: 0006_referral_commission_contract
Revises: 0005_business_domains
Create Date: 2026-10-30
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect, text

from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.business_models import CommissionRate

revision = "0006_referral_comm"
down_revision = "0005_business_domains"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    if "list_price_cents" not in {
        column["name"] for column in inspector.get_columns("payment_events")
    }:
        op.add_column(
            "payment_events",
            sa.Column("list_price_cents", sa.Integer(), nullable=True),
        )

    if "status" not in {
        column["name"] for column in inspector.get_columns("referral_relationships")
    }:
        op.add_column(
            "referral_relationships",
            sa.Column(
                "status",
                sa.String(length=24),
                nullable=False,
                server_default="active",
            ),
        )

    CommissionRate.__table__.create(bind=bind, checkfirst=True)
    if bind.dialect.name == "sqlite":
        bind.execute(
            text(
                "INSERT OR IGNORE INTO commission_rates "
                "(code, rate, is_active, created_at, updated_at) "
                "VALUES ('direct_referral', 0.1000, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
            )
        )
    else:
        bind.execute(
            text(
                "INSERT INTO commission_rates "
                "(code, rate, is_active, created_at, updated_at) "
                "VALUES ('direct_referral', 0.1000, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) "
                "ON CONFLICT (code) DO NOTHING"
            )
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    if "commission_rates" in inspector.get_table_names():
        op.drop_table("commission_rates")

    payment_columns = {column["name"] for column in inspector.get_columns("payment_events")}
    referral_columns = {
        column["name"] for column in inspector.get_columns("referral_relationships")
    }
    if bind.dialect.name == "sqlite":
        with op.batch_alter_table("payment_events") as batch:
            if "list_price_cents" in payment_columns:
                batch.drop_column("list_price_cents")
        with op.batch_alter_table("referral_relationships") as batch:
            if "status" in referral_columns:
                batch.drop_column("status")
    else:
        if "list_price_cents" in payment_columns:
            op.drop_column("payment_events", "list_price_cents")
        if "status" in referral_columns:
            op.drop_column("referral_relationships", "status")
