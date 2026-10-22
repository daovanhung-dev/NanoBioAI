from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AccountCreateRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    phone: str = Field(min_length=1, max_length=32)
    full_name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=8, max_length=128)
    email: str | None = Field(default=None, max_length=320)
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)


class MembershipGrantRequest(BaseModel):
    user_id: str
    plan_code: str
    starts_at: datetime
    ends_at: datetime | None = None
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)
    preserve_existing_paid_plan: bool = False


class MembershipAdjustmentRequest(BaseModel):
    user_id: str
    subscription_id: str
    operation: str
    expected_ends_at: datetime | None
    days: int | None = None
    ends_at: datetime | None = None
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)


class EarlyAccessLeadStatusRequest(BaseModel):
    status: str
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)


class BulkMembershipGrantRequest(BaseModel):
    scope: str
    plan_code: str
    starts_at: datetime
    ends_at: datetime | None = None
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)


class BulkProvisionAccount(BaseModel):
    phone: str
    full_name: str = Field(min_length=2, max_length=120)
    email: str | None = None


class BulkProvisionRequest(BaseModel):
    accounts: list[BulkProvisionAccount] = Field(min_length=1, max_length=100)
    plan_code: str
    duration_months: int
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)


class BulkProvisionPreviewRequest(BulkProvisionRequest):
    mode: str = "preview"


class BulkProvisionExecuteRequest(BulkProvisionRequest):
    mode: str = "execute"
    password: str = Field(min_length=8, max_length=128)
    preview_fingerprint: str = Field(min_length=64, max_length=64)
    confirmation: str = Field(min_length=1, max_length=80)


class UserProfileUpdateRequest(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=120)
    gender: str | None = None
    birth_year: int | None = Field(default=None, ge=1900, le=2100)
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)
