from datetime import UTC, datetime
from typing import Any

from sqlalchemy.orm import Session

from nanobio_backend.db.models import User
from nanobio_backend.modules.membership.query import list_active


def get_my_membership(db: Session, user: User) -> dict[str, Any]:
    rows = list_active(db, user)
    now = datetime.now(UTC)
    plan = rows[0].plan_code if rows else "free"
    return {
        "user_id": str(user.id),
        "is_anonymous": False,
        "product_access": plan,
        "membership_plan": plan,
        "product_access_status": "active" if rows else "free",
        "sale_status": user.sale_status,
        "onboarding_status": user.onboarding_status,
        "updated_at": user.updated_at.isoformat(),
        "active_entitlements": [
            {
                "plan_code": row.plan_code,
                "source": row.source,
                "status": row.status,
                "starts_at": row.starts_at.isoformat(),
                "ends_at": row.ends_at.isoformat() if row.ends_at else None,
            }
            for row in rows
        ],
        "server_time": now.isoformat(),
    }
