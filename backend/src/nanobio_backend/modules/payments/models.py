from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class MembershipPaymentCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    plan_code: str = Field(min_length=1, max_length=32)
    billing_cycle: str = Field(min_length=1, max_length=16)
    idempotency_key: str = Field(min_length=8, max_length=160)
    payer_full_name: str = Field(min_length=1, max_length=120)

    @field_validator("plan_code", "billing_cycle", "idempotency_key", "payer_full_name")
    @classmethod
    def trim_values(cls, value: str) -> str:
        return value.strip()


class AdminPaymentReviewRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    decision: Literal["approve", "reject"]
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)
    transfer_verified: bool = False


class AdminPaymentReversalRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    decision: Literal["refund", "cancel", "chargeback"]
    reason: str = Field(min_length=2, max_length=500)
    idempotency_key: str = Field(min_length=8, max_length=160)
