from uuid import UUID

from pydantic import BaseModel, Field


class SaleParticipationRequest(BaseModel):
    terms_version: str = Field(min_length=1, max_length=80)
    device_hash: str = Field(min_length=32, max_length=128)


class ReferralAttachRequest(BaseModel):
    referral_code: str = Field(min_length=4, max_length=32)
    device_hash: str = Field(min_length=32, max_length=128)


class SalePayoutProfileRequest(BaseModel):
    citizen_id: str = Field(min_length=9, max_length=64)
    bank_bin: str = Field(min_length=3, max_length=32)
    bank_name: str = Field(min_length=1, max_length=160)
    bank_account_number: str = Field(min_length=4, max_length=64)
    bank_account_name: str = Field(min_length=1, max_length=160)


class SaleConversionRequest(BaseModel):
    requested_point_cents: int = Field(gt=0)
    idempotency_key: str = Field(min_length=8, max_length=160)


class WellnessRedemptionRequest(BaseModel):
    offer_id: UUID
    idempotency_key: str = Field(min_length=8, max_length=160)


class BusinessAdminMutation(BaseModel):
    action: str = Field(min_length=1, max_length=40)
    target_id: str = Field(default="", max_length=160)
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)
    payload: dict[str, object] = Field(default_factory=dict)
