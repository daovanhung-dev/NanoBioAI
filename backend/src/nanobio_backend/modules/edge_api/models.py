from pydantic import BaseModel, ConfigDict, Field


class EarlyAccessRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="ignore")

    phone: str = Field(min_length=1, max_length=32)
    full_name: str = Field(min_length=1, max_length=120)
    age: int = Field(ge=18, le=120)
    gender: str
    address: str = Field(min_length=1, max_length=512)
    privacy_consent: bool
    landing_path: str | None = Field(default=None, max_length=512)
    utm_source: str | None = Field(default=None, max_length=200)
    utm_medium: str | None = Field(default=None, max_length=200)
    utm_campaign: str | None = Field(default=None, max_length=200)


class AiReportRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    message_id: str = Field(min_length=1, max_length=160)
    message_role: str = Field(min_length=1, max_length=32)
    reason_code: str = Field(min_length=1, max_length=32)
    message_snapshot: str = Field(min_length=1, max_length=4000)
    app_version: str = Field(min_length=1, max_length=64)
    note: str | None = Field(default=None, max_length=500)
    installation_id: str | None = Field(default=None, max_length=128)


class FoodEvidenceRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    ingredients: list[str] = Field(min_length=1, max_length=30)


class GooglePlayVerifyRequest(BaseModel):
    package_name: str = Field(min_length=1, max_length=160)
    product_id: str = Field(min_length=1, max_length=160)
    purchase_token: str = Field(min_length=1, max_length=4096)
