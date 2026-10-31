from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

QuotaFeature = Literal["ai_chat_message", "personal_schedule_generation"]


class QuotaRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    feature_key: QuotaFeature
    request_id: str = Field(min_length=1, max_length=160)
    requested_at: datetime | None = None
