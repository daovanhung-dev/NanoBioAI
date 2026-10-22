from functools import lru_cache
from pathlib import Path

from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "development"
    app_name: str = "NanoBioAI Backend"
    api_v1_prefix: str = "/api/v1"
    database_url: str = "postgresql+psycopg://nanobio@127.0.0.1:5432/nanobio"
    jwt_secret_key: SecretStr | None = None
    jwt_issuer: str = "nanobio-backend"
    jwt_audience: str = "nanobio-clients"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    cors_allowed_origins: list[str] = []
    upload_root: Path = Path("/var/lib/nanobio-backend/uploads")
    max_upload_bytes: int = 10 * 1024 * 1024
    rate_limit_hmac_key: SecretStr | None = None
    early_access_phone_hmac_key: SecretStr | None = None
    early_access_apk_download_url: str | None = None
    membership_payment_prices_json: str | None = None
    membership_payment_bank_json: SecretStr | None = None
    nin_api_key: SecretStr | None = None
    usda_api_key: SecretStr | None = None
    google_play_package_name: str | None = None
    google_play_service_account_json: SecretStr | None = None
    sleep_safety_provider_base_url: str | None = None
    sleep_safety_provider_token: SecretStr | None = None
    sleep_safety_provider_webhook_secret: SecretStr | None = None
    public_api_base_url: str | None = None
    sleep_safety_enabled: bool = False
    sleep_safety_max_dispatches_per_hour: int = 3
    sleep_safety_event_freshness_seconds: int = 600
    sleep_safety_verification_ttl_seconds: int = 600

    @field_validator("cors_allowed_origins", mode="before")
    @classmethod
    def split_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [part.strip() for part in value.split(",") if part.strip()]
        return value

    @field_validator("access_token_minutes", "refresh_token_days", "max_upload_bytes")
    @classmethod
    def positive_values(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("must be greater than zero")
        return value


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
