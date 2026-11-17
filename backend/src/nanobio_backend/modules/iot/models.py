from typing import Literal, Self

from pydantic import BaseModel, ConfigDict, Field, SecretStr, model_validator


class PairingSessionCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")


class DeviceClaimRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    device_id: str = Field(pattern=r"^[a-f0-9]{32}$")
    pairing_token: str = Field(min_length=32, max_length=160)
    name: str | None = Field(default=None, min_length=1, max_length=80)


class DeviceCredentialRefreshRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    device_id: str = Field(pattern=r"^[a-f0-9]{32}$")
    refresh_token: str = Field(min_length=32, max_length=160)


class DeviceCredentialLoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    device_id: str = Field(pattern=r"^[a-f0-9]{32}$")
    identifier_type: Literal["phone", "email", "username"]
    identifier: str = Field(min_length=3, max_length=320)
    password: SecretStr = Field(min_length=1, max_length=128)


class DeviceRenameRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    name: str = Field(min_length=1, max_length=80)


class DeviceConsentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    identity: bool = False
    profile_goals: bool = False
    sensitive_health: bool = False
    recent_tracking: bool = False


class SensitiveUnlockRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    confirm: bool

    @model_validator(mode="after")
    def require_confirmation(self) -> Self:
        if not self.confirm:
            raise ValueError("User confirmation is required.")
        return self


class PairingSessionResponse(BaseModel):
    pairing_session_id: str
    pairing_token: str
    expires_at: str
    expires_in: int


class PairingSessionStatusResponse(BaseModel):
    pairing_session_id: str
    status: str
    expires_at: str
    device_id: str | None
    device_name: str | None


class DeviceConsentResponse(BaseModel):
    identity: bool
    profile_goals: bool
    sensitive_health: bool
    recent_tracking: bool
