from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class ScheduleEligibilityItem(BaseModel):
    schedule_item_id: UUID
    schedule_date: str
    start_time: str
    title: str
    source_type: str
    source_id: str | None = None


class RegisterEligibilityRequest(BaseModel):
    request_id: str = Field(min_length=1, max_length=160)
    items: list[ScheduleEligibilityItem] = Field(min_length=1, max_length=70)
    idempotency_key: str = Field(min_length=8, max_length=160)


class BeginCompletionRequest(BaseModel):
    schedule_item_id: UUID
    idempotency_key: str = Field(min_length=8, max_length=160)


class FinalizeCompletionRequest(BaseModel):
    storage_path: str = Field(min_length=1, max_length=512)
    idempotency_key: str = Field(min_length=8, max_length=160)


class UndoCompletionRequest(BaseModel):
    schedule_item_id: UUID
    idempotency_key: str = Field(min_length=8, max_length=160)


class HealthCheckinRequest(BaseModel):
    item: dict[str, Any]
    action_type: str = Field(min_length=1, max_length=32)
    checkin: dict[str, Any] = Field(default_factory=dict)
    idempotency_key: str = Field(min_length=8, max_length=160)


class UndoHealthCheckinRequest(BaseModel):
    schedule_item_id: UUID
    idempotency_key: str = Field(min_length=8, max_length=160)
