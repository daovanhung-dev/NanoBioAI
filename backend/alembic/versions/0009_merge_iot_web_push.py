"""Merge the deployed IoT and local web-push migration branches.

Revision ID: 0009_merge_iot_web_push
Revises: 0008_web_push, 0008_iot_devices
Create Date: 2026-11-17
"""

revision = "0009_merge_iot_web_push"
down_revision = ("0008_web_push", "0008_iot_devices")
branch_labels = None
depends_on = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
