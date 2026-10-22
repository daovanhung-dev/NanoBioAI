from dataclasses import dataclass
from typing import Literal

import httpx

ProviderStatus = Literal["submitted", "delivered", "answered", "failed", "no_answer"]


@dataclass(frozen=True)
class ProviderResult:
    external_id: str
    status: ProviderStatus


def normalize_status(value: object) -> ProviderStatus:
    normalized = str(value or "").strip().lower()
    if normalized in {"delivered", "answered", "failed", "no_answer", "noanswer"}:
        return "no_answer" if normalized == "noanswer" else normalized  # type: ignore[return-value]
    return "submitted"


def terminal_failure(status: ProviderStatus) -> bool:
    return status in {"failed", "no_answer"}


def send_message(
    *,
    base_url: str | None,
    token: str | None,
    channel: Literal["sms", "voice", "verification"],
    to: str,
    message: str,
    idempotency_key: str,
    callback_url: str | None = None,
    callback_token: str | None = None,
) -> ProviderResult:
    if not base_url or not token:
        return ProviderResult("", "failed")
    endpoint = "sms" if channel == "verification" else channel
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.post(
                f"{base_url.rstrip('/')}/{endpoint}",
                headers={"authorization": f"Bearer {token}", "content-type": "application/json"},
                json={
                    "to": to,
                    "message": message,
                    "idempotency_key": idempotency_key,
                    "callback_url": callback_url,
                    "callback_token": callback_token,
                    "metadata": {"channel": channel, "source": "nanobio_sleep_safety"},
                },
            )
            if not response.is_success:
                return ProviderResult("", "failed")
            data = response.json()
            if not isinstance(data, dict):
                return ProviderResult("", "submitted")
            return ProviderResult(str(data.get("id") or ""), normalize_status(data.get("status")))
    except (httpx.HTTPError, ValueError):
        return ProviderResult("", "failed")
