from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ContactUpsertRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    name: str = Field(min_length=2, max_length=120)
    relationship: str = Field(min_length=1, max_length=80)
    phone_e164: str = Field(min_length=1, max_length=32)
    priority: int = Field(ge=1, le=3)
    allow_phone_fallback: bool = True
    allow_unverified_voice_alert: bool = False


class VerificationRequest(BaseModel):
    action: str
    contact_id: UUID
    code: str | None = Field(default=None, max_length=6)


class DispatchRequest(BaseModel):
    event_id: str = Field(min_length=1, max_length=160)
    idempotency_key: str = Field(min_length=8, max_length=160)


class SleepSafetyPreferenceSync(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)

    enabled: bool
    sensitivity: Literal["low", "balanced", "high"]
    schedule_enabled: bool
    schedule_start_minutes: int = Field(ge=0, le=1439)
    schedule_end_minutes: int = Field(ge=0, le=1439)
    timezone: str = Field(min_length=1, max_length=64)
    selected_weekdays: list[int] = Field(min_length=1, max_length=7)
    calibration_required: bool
    calibration_noise_floor: float | None = Field(default=None, ge=0)
    calibration_updated_at: datetime | None = None
    cooldown_seconds: int = Field(ge=30, le=900)
    consent_version: str = Field(min_length=1, max_length=80)
    updated_at: datetime

    @field_validator("selected_weekdays")
    @classmethod
    def validate_weekdays(cls, values: list[int]) -> list[int]:
        if len(set(values)) != len(values) or any(day < 1 or day > 7 for day in values):
            raise ValueError("Selected weekdays must be unique ISO weekdays.")
        return values


class SleepSafetySessionSync(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)

    started_at: datetime
    ended_at: datetime | None = None
    scheduled_window_start: datetime | None = None
    scheduled_window_end: datetime | None = None
    sensitivity: Literal["low", "balanced", "high"]
    calibration_noise_floor: float | None = Field(default=None, ge=0)
    status: Literal[
        "idle",
        "arming",
        "calibrating",
        "monitoring",
        "alerting",
        "escalating",
        "stopped",
        "failed",
    ]
    start_source: Literal["manual", "scheduled_reminder"]
    stop_reason: str | None = Field(default=None, max_length=80)
    platform: str = Field(min_length=1, max_length=40)
    app_version: str = Field(min_length=1, max_length=64)
    created_at: datetime
    updated_at: datetime


class SleepSafetyEventSync(BaseModel):
    model_config = ConfigDict(extra="ignore", str_strip_whitespace=True)

    session_id: str = Field(min_length=1, max_length=160)
    detected_at: datetime
    event_type: Literal[
        "suddenLoudSound",
        "strongImpact",
        "abnormalShout",
        "abnormalScream",
        "repeatedSuspiciousPattern",
        "unknownHighEnergyEvent",
    ]
    severity: Literal["attention", "high"]
    confidence: float = Field(ge=0, le=1)
    relative_energy: float = Field(ge=0)
    baseline_delta: float = Field(ge=0)
    repetition_count: int = Field(ge=1)
    state: str = Field(min_length=1, max_length=40)
    response: Literal["none", "ok", "needHelp", "noResponse"]
    response_at: datetime | None = None
    escalation_required: bool
    escalation_status: Literal["notRequired", "pending", "dispatching", "accepted", "failed"]
    created_at: datetime
    updated_at: datetime
