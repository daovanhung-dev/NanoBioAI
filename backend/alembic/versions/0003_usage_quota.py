"""Add server-owned membership quota counters and rules.

Revision ID: 0003_usage_quota
Revises: 0002_nullable_admin_phone
Create Date: 2026-10-30
"""

from uuid import uuid4

from alembic import op
from sqlalchemy.dialects.postgresql import insert

from nanobio_backend.db.models import UsageEvent, UsageQuotaCounter, UsageQuotaRule, now_utc

revision = "0003_usage_quota"
down_revision = "0002_nullable_admin_phone"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    UsageQuotaRule.__table__.create(bind=bind, checkfirst=True)
    UsageQuotaCounter.__table__.create(bind=bind, checkfirst=True)
    UsageEvent.__table__.create(bind=bind, checkfirst=True)

    rows = (
        ("free", "ai_chat_message", "day", 3),
        ("free", "personal_schedule_generation", "month", 3),
        ("plus", "ai_chat_message", "none", None),
        ("plus", "personal_schedule_generation", "none", None),
        ("family_plus", "ai_chat_message", "none", None),
        ("family_plus", "personal_schedule_generation", "none", None),
    )
    table = UsageQuotaRule.__table__
    for plan_code, feature_key, period_unit, max_count in rows:
        stmt = insert(table).values(
            id=uuid4(),
            plan_code=plan_code,
            feature_key=feature_key,
            period_unit=period_unit,
            max_count=max_count,
            reset_timezone="Asia/Ho_Chi_Minh",
            is_active=True,
            created_at=now_utc(),
            updated_at=now_utc(),
        )
        bind.execute(
            stmt.on_conflict_do_update(
                index_elements=["plan_code", "feature_key", "period_unit"],
                set_={
                    "max_count": max_count,
                    "reset_timezone": "Asia/Ho_Chi_Minh",
                    "is_active": True,
                    "updated_at": now_utc(),
                },
            )
        )


def downgrade() -> None:
    bind = op.get_bind()
    UsageEvent.__table__.drop(bind=bind, checkfirst=True)
    UsageQuotaCounter.__table__.drop(bind=bind, checkfirst=True)
    UsageQuotaRule.__table__.drop(bind=bind, checkfirst=True)
