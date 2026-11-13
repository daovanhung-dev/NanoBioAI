from datetime import datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

_ALLOWED_CATEGORIES = {
    "schedule",
    "health_checkin",
    "goal_review",
    "profile_review",
    "water",
    "medication",
    "sleep_safety",
}


class PushKeys(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    p256dh: str = Field(min_length=32, max_length=256)
    auth: str = Field(min_length=16, max_length=128)


class PushSubscriptionInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    endpoint: str = Field(min_length=20, max_length=2048)
    keys: PushKeys
    timezone: str = Field(default="Asia/Ho_Chi_Minh", min_length=1, max_length=64)

    @field_validator("timezone")
    @classmethod
    def known_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ValueError("Unknown IANA timezone") from exc
        return value


class WebPushReminderInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    reminder_id: str = Field(min_length=1, max_length=96)
    category: str = Field(min_length=1, max_length=32)
    scheduled_at: datetime | None = None
    daily_minute: int | None = Field(default=None, ge=0, le=1439)

    @field_validator("category")
    @classmethod
    def allowed_category(cls, value: str) -> str:
        if value not in _ALLOWED_CATEGORIES:
            raise ValueError("Unsupported reminder category")
        return value

    @field_validator("scheduled_at")
    @classmethod
    def timezone_aware(cls, value: datetime | None) -> datetime | None:
        if value is not None and (value.tzinfo is None or value.utcoffset() is None):
            raise ValueError("scheduled_at must include a timezone")
        return value

    @model_validator(mode="after")
    def exactly_one_schedule_kind(self) -> "WebPushReminderInput":
        if (self.scheduled_at is None) == (self.daily_minute is None):
            raise ValueError("Provide either scheduled_at or daily_minute")
        return self


class WebPushReminderBatch(BaseModel):
    model_config = ConfigDict(extra="forbid")

    timezone: str = Field(min_length=1, max_length=64)
    reminders: list[WebPushReminderInput] = Field(max_length=512)

    @field_validator("timezone")
    @classmethod
    def known_timezone(cls, value: str) -> str:
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ValueError("Unknown IANA timezone") from exc
        return value

    @model_validator(mode="after")
    def unique_reminder_ids(self) -> "WebPushReminderBatch":
        keys = [item.reminder_id for item in self.reminders]
        if len(keys) != len(set(keys)):
            raise ValueError("Reminder ids must be unique")
        return self
