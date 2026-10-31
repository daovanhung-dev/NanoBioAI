"""Add sale, wellness, schedule reward, and admin reporting tables.

Revision ID: 0005_business_domains
Revises: 0004_sleep_safety_sync
Create Date: 2026-10-30
"""

from alembic import op

from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.base import Base

revision = "0005_business_domains"
down_revision = "0004_sleep_safety_sync"
branch_labels = None
depends_on = None

_TABLES = {
    "sale_profiles",
    "sale_payout_profiles",
    "payment_events",
    "commission_records",
    "sale_point_adjustments",
    "sale_point_conversions",
    "wellness_reward_wallets",
    "wellness_point_ledgers",
    "wellness_point_allocations",
    "wellness_reward_offers",
    "wellness_reward_codes",
    "wellness_reward_redemptions",
    "wellness_redemption_allocation_usages",
    "wellness_rank_accounts",
    "wellness_rank_experience_ledger",
    "schedule_reward_eligibilities",
    "schedule_completion_attempts",
    "schedule_completion_proofs",
    "admin_reconciliation_runs",
    "admin_reconciliation_discrepancies",
    "report_exports",
    "system_config_versions",
}


def upgrade() -> None:
    bind = op.get_bind()
    tables = [table for table in Base.metadata.sorted_tables if table.name in _TABLES]
    Base.metadata.create_all(bind=bind, tables=tables, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    tables = [table for table in reversed(Base.metadata.sorted_tables) if table.name in _TABLES]
    Base.metadata.drop_all(bind=bind, tables=tables, checkfirst=True)
