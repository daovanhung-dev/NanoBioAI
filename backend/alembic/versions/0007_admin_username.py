"""Add a case-insensitive username login alias.

Revision ID: 0007_admin_username
Revises: 0006_referral_comm
Create Date: 2026-10-31
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect, text

revision = "0007_admin_username"
down_revision = "0006_referral_comm"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    columns = {column["name"] for column in inspect(bind).get_columns("users")}
    if "username" not in columns:
        op.add_column("users", sa.Column("username", sa.String(length=32), nullable=True))

    if bind.dialect.name == "sqlite":
        indexes = {
            row[0]
            for row in bind.execute(
                text("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'users'")
            )
        }
    elif bind.dialect.name == "postgresql":
        indexes = {
            row[0]
            for row in bind.execute(
                text("""
                    SELECT indexname FROM pg_indexes
                    WHERE schemaname = current_schema() AND tablename = 'users'
                """)
            )
        }
    else:
        indexes = {index["name"] for index in inspect(bind).get_indexes("users")}
    if "uq_users_username_lower" not in indexes:
        op.create_index(
            "uq_users_username_lower",
            "users",
            [sa.text("lower(username)")],
            unique=True,
        )


def downgrade() -> None:
    bind = op.get_bind()
    indexes = {index["name"] for index in inspect(bind).get_indexes("users")}
    if "uq_users_username_lower" in indexes:
        op.drop_index("uq_users_username_lower", table_name="users")
    columns = {column["name"] for column in inspect(bind).get_columns("users")}
    if "username" in columns:
        op.drop_column("users", "username")
