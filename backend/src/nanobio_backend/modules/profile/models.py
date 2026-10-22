from pydantic import BaseModel, ConfigDict, Field, field_validator


class ProfileUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str | None = Field(default=None, min_length=2, max_length=120)
    gender: str | None = Field(default=None, max_length=24)
    birth_year: int | None = Field(default=None, ge=1900, le=2100)
    avatar_url: str | None = Field(default=None, max_length=2048)

    @field_validator("full_name")
    @classmethod
    def clean_name(cls, value: str | None) -> str | None:
        if value is not None and not value.strip():
            raise ValueError("full_name cannot be blank")
        return value.strip() if value else value
