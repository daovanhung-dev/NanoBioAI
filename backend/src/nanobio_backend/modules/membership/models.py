from pydantic import BaseModel


class MembershipSummary(BaseModel):
    user_id: str
    membership_plan: str
    product_access_status: str
    active_entitlements: list[dict[str, str | None]]
