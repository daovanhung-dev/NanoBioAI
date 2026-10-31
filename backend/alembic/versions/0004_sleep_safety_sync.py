"""Add server-owned sleep safety sync records.

Revision ID: 0004_sleep_safety_sync
Revises: 0003_usage_quota
Create Date: 2026-10-30
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

from nanobio_backend.db.models import SleepSafetyPreference, SleepSafetySession

revision = "0004_sleep_safety_sync"
down_revision = "0003_usage_quota"
branch_labels = None
depends_on = None


def _columns(table_name: str) -> dict[str, dict[str, object]]:
    return {column["name"]: column for column in sa.inspect(op.get_bind()).get_columns(table_name)}


def _foreign_keys(table_name: str) -> list[dict[str, object]]:
    return sa.inspect(op.get_bind()).get_foreign_keys(table_name)


def _drop_event_dispatch_foreign_key() -> None:
    for foreign_key in _foreign_keys("sleep_safety_dispatches"):
        if (
            foreign_key.get("constrained_columns") == ["event_id"]
            and foreign_key.get("referred_table") == "sleep_safety_events"
            and foreign_key.get("name")
        ):
            op.drop_constraint(foreign_key["name"], "sleep_safety_dispatches", type_="foreignkey")


def _add_event_column(column: sa.Column[object], *, server_default: str | None = None) -> None:
    if column.name in _columns("sleep_safety_events"):
        return
    if server_default is not None:
        column = column._copy()
        column.server_default = sa.text(server_default)
    op.add_column("sleep_safety_events", column)
    if server_default is not None:
        op.alter_column("sleep_safety_events", column.name, server_default=None)


def _add_contact_column(column: sa.Column[object], *, server_default: str) -> None:
    if column.name in _columns("sleep_safety_contacts"):
        return
    column = column._copy()
    column.server_default = sa.text(server_default)
    op.add_column("sleep_safety_contacts", column)
    op.alter_column("sleep_safety_contacts", column.name, server_default=None)


def upgrade() -> None:
    bind = op.get_bind()
    SleepSafetyPreference.__table__.create(bind=bind, checkfirst=True)
    SleepSafetySession.__table__.create(bind=bind, checkfirst=True)

    _add_contact_column(
        sa.Column("allow_phone_fallback", sa.Boolean(), nullable=False), server_default="true"
    )
    _add_contact_column(
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        server_default="CURRENT_TIMESTAMP",
    )

    event_columns = _columns("sleep_safety_events")
    event_id_type = event_columns["id"]["type"]
    dispatch_event_id_type = _columns("sleep_safety_dispatches")["event_id"]["type"]
    event_id_is_string = isinstance(event_id_type, sa.String)
    dispatch_id_is_string = isinstance(dispatch_event_id_type, sa.String)
    if not event_id_is_string or not dispatch_id_is_string:
        _drop_event_dispatch_foreign_key()
    if not event_id_is_string:
        op.alter_column(
            "sleep_safety_events",
            "id",
            existing_type=event_id_type,
            type_=sa.String(length=160),
            existing_nullable=False,
            postgresql_using="id::text",
        )
    if not dispatch_id_is_string:
        op.alter_column(
            "sleep_safety_dispatches",
            "event_id",
            existing_type=dispatch_event_id_type,
            type_=sa.String(length=160),
            existing_nullable=False,
            postgresql_using="event_id::text",
        )

    _add_event_column(sa.Column("session_id", sa.String(length=160), nullable=True))
    _add_event_column(
        sa.Column("event_type", sa.String(length=48), nullable=False),
        server_default="'unknownHighEnergyEvent'",
    )
    _add_event_column(
        sa.Column("severity", sa.String(length=16), nullable=False), server_default="'attention'"
    )
    _add_event_column(sa.Column("confidence", sa.Float(), nullable=False), server_default="0")
    _add_event_column(sa.Column("relative_energy", sa.Float(), nullable=False), server_default="0")
    _add_event_column(sa.Column("baseline_delta", sa.Float(), nullable=False), server_default="0")
    _add_event_column(
        sa.Column("repetition_count", sa.Integer(), nullable=False), server_default="1"
    )
    _add_event_column(
        sa.Column("state", sa.String(length=40), nullable=False), server_default="'detected'"
    )
    _add_event_column(sa.Column("response_at", sa.DateTime(timezone=True), nullable=True))
    _add_event_column(
        sa.Column("escalation_status", sa.String(length=24), nullable=False),
        server_default="'notRequired'",
    )
    _add_event_column(
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        server_default="CURRENT_TIMESTAMP",
    )
    _add_event_column(
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        server_default="CURRENT_TIMESTAMP",
    )

    if not any(
        foreign_key.get("constrained_columns") == ["event_id"]
        and foreign_key.get("referred_table") == "sleep_safety_events"
        for foreign_key in _foreign_keys("sleep_safety_dispatches")
    ):
        op.create_foreign_key(
            "sleep_safety_dispatches_event_id_fkey",
            "sleep_safety_dispatches",
            "sleep_safety_events",
            ["event_id"],
            ["id"],
            ondelete="CASCADE",
        )

    if not any(
        foreign_key.get("name") == "fk_sleep_event_session_owner"
        for foreign_key in _foreign_keys("sleep_safety_events")
    ):
        op.create_foreign_key(
            "fk_sleep_event_session_owner",
            "sleep_safety_events",
            "sleep_safety_sessions",
            ["session_id", "user_id"],
            ["id", "user_id"],
            ondelete="CASCADE",
        )


def downgrade() -> None:
    for foreign_key in _foreign_keys("sleep_safety_events"):
        if foreign_key.get("name") == "fk_sleep_event_session_owner":
            op.drop_constraint(foreign_key["name"], "sleep_safety_events", type_="foreignkey")

    for column in (
        "updated_at",
        "created_at",
        "escalation_status",
        "response_at",
        "state",
        "repetition_count",
        "baseline_delta",
        "relative_energy",
        "confidence",
        "severity",
        "event_type",
        "session_id",
    ):
        if column in _columns("sleep_safety_events"):
            op.drop_column("sleep_safety_events", column)

    _drop_event_dispatch_foreign_key()
    if isinstance(_columns("sleep_safety_dispatches")["event_id"]["type"], sa.String):
        op.alter_column(
            "sleep_safety_dispatches",
            "event_id",
            existing_type=sa.String(length=160),
            type_=postgresql.UUID(as_uuid=True),
            existing_nullable=False,
            postgresql_using="event_id::uuid",
        )
    if isinstance(_columns("sleep_safety_events")["id"]["type"], sa.String):
        op.alter_column(
            "sleep_safety_events",
            "id",
            existing_type=sa.String(length=160),
            type_=postgresql.UUID(as_uuid=True),
            existing_nullable=False,
            postgresql_using="id::uuid",
        )
    op.create_foreign_key(
        "sleep_safety_dispatches_event_id_fkey",
        "sleep_safety_dispatches",
        "sleep_safety_events",
        ["event_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_table("sleep_safety_sessions")
    op.drop_table("sleep_safety_preferences")
    if "updated_at" in _columns("sleep_safety_contacts"):
        op.drop_column("sleep_safety_contacts", "updated_at")
    if "allow_phone_fallback" in _columns("sleep_safety_contacts"):
        op.drop_column("sleep_safety_contacts", "allow_phone_fallback")
