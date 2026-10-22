from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ContactUpsertRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    name: str = Field(min_length=2, max_length=120)
    relationship: str = Field(min_length=1, max_length=80)
    phone_e164: str = Field(min_length=1, max_length=32)
    priority: int = Field(ge=1, le=3)
    allow_unverified_voice_alert: bool = False


class VerificationRequest(BaseModel):
    action: str
    contact_id: UUID
    code: str | None = Field(default=None, max_length=6)


class DispatchRequest(BaseModel):
    event_id: UUID
    idempotency_key: str = Field(min_length=8, max_length=160)
