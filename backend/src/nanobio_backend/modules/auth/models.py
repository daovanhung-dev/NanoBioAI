from pydantic import BaseModel, ConfigDict, Field


class PhoneSignupRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    phone: str = Field(min_length=1, max_length=32)
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=120)
    referral_code: str | None = Field(default=None, max_length=32)
    device_fingerprint: str | None = Field(default=None, max_length=256)


class LoginRequest(BaseModel):
    phone: str = Field(min_length=1, max_length=32)
    password: str = Field(min_length=1, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=32, max_length=256)


class ChangePasswordRequest(BaseModel):
    new_password: str = Field(min_length=8, max_length=128)


class TokenPair(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: str
    user: dict[str, object]
