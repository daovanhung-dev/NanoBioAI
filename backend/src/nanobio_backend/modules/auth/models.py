from pydantic import BaseModel, ConfigDict, Field, model_validator


class PhoneSignupRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    phone: str = Field(min_length=1, max_length=32)
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=120)
    referral_code: str | None = Field(default=None, max_length=32)
    device_fingerprint: str | None = Field(default=None, max_length=256)


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    phone: str | None = Field(default=None, min_length=1, max_length=32)
    email: str | None = Field(default=None, min_length=3, max_length=320)
    password: str = Field(min_length=1, max_length=128)

    @model_validator(mode="after")
    def require_one_identifier(self) -> "LoginRequest":
        if bool(self.phone) == bool(self.email):
            raise ValueError("provide either phone or email")
        if self.email and "@" not in self.email:
            raise ValueError("email is invalid")
        return self


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
