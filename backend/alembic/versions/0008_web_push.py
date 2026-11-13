"""Store browser push subscriptions and reminder schedules.

Revision ID: 0008_web_push
Revises: 0007_admin_username
Create Date: 2026-11-13
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect

revision = "0008_web_push"
down_revision = "0007_admin_username"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    tables = set(inspect(bind).get_table_names())
    if "web_push_subscriptions" not in tables:
        op.create_table(
            "web_push_subscriptions",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("guest_capability_hash", sa.String(length=64), nullable=False),
            sa.Column("endpoint", sa.String(length=2048), nullable=False),
            sa.Column("endpoint_hash", sa.String(length=64), nullable=False),
            sa.Column("p256dh_key", sa.String(length=256), nullable=False),
            sa.Column("auth_key", sa.String(length=128), nullable=False),
            sa.Column("timezone", sa.String(length=64), nullable=False),
            sa.Column("is_active", sa.Boolean(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("guest_capability_hash"),
            sa.UniqueConstraint("endpoint_hash"),
        )
    if "web_push_reminders" not in tables:
        op.create_table(
            "web_push_reminders",
            sa.Column("id", sa.Uuid(), nullable=False),
            sa.Column("subscription_id", sa.Uuid(), nullable=False),
            sa.Column("reminder_key", sa.String(length=96), nullable=False),
            sa.Column("category", sa.String(length=32), nullable=False),
            sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("daily_minute", sa.Integer(), nullable=True),
            sa.Column("last_sent_on", sa.Date(), nullable=True),
            sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("is_active", sa.Boolean(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
            sa.CheckConstraint(
                "(scheduled_at is not null and daily_minute is null) or "
                "(scheduled_at is null and daily_minute is not null)",
                name="ck_web_push_reminder_schedule_kind",
            ),
            sa.CheckConstraint(
                "daily_minute is null or daily_minute between 0 and 1439",
                name="ck_web_push_daily_minute",
            ),
            sa.ForeignKeyConstraint(
                ["subscription_id"], ["web_push_subscriptions.id"], ondelete="CASCADE"
            ),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("subscription_id", "reminder_key", name="uq_web_push_reminder_key"),
        )
    indexes = {index["name"] for index in inspect(bind).get_indexes("web_push_reminders")}
    if "ix_web_push_reminders_due" not in indexes:
        op.create_index(
            "ix_web_push_reminders_due",
            "web_push_reminders",
            ["is_active", "scheduled_at"],
        )
    if "ix_web_push_reminders_subscription_id" not in indexes:
        op.create_index(
            "ix_web_push_reminders_subscription_id",
            "web_push_reminders",
            ["subscription_id"],
        )


def downgrade() -> None:
    bind = op.get_bind()
    tables = set(inspect(bind).get_table_names())
    if "web_push_reminders" in tables:
        indexes = {index["name"] for index in inspect(bind).get_indexes("web_push_reminders")}
        if "ix_web_push_reminders_subscription_id" in indexes:
            op.drop_index("ix_web_push_reminders_subscription_id", table_name="web_push_reminders")
        if "ix_web_push_reminders_due" in indexes:
            op.drop_index("ix_web_push_reminders_due", table_name="web_push_reminders")
        op.drop_table("web_push_reminders")
    if "web_push_subscriptions" in tables:
        op.drop_table("web_push_subscriptions")
