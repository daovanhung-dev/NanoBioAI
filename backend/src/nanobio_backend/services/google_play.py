import json
from datetime import UTC, datetime, timedelta
from urllib.parse import quote

import httpx
import jwt

GOOGLE_PLAY_PACKAGE_NAME = "com.nanobioai.app"
PRODUCT_PLANS = {
    "nanobio_plus_monthly": "plus",
    "nanobio_plus_yearly": "plus",
    "nanobio_family_plus_monthly": "family_plus",
    "nanobio_family_plus_yearly": "family_plus",
}


class GooglePlayProviderError(Exception):
    """Safe provider failure; never carries provider response content."""


def _access_token(service_account_json: str) -> str:
    try:
        credentials = json.loads(service_account_json)
        email = credentials["client_email"]
        private_key = credentials["private_key"]
        token_uri = credentials.get("token_uri", "https://oauth2.googleapis.com/token")
        now = datetime.now(UTC)
        assertion = jwt.encode(
            {
                "iss": email,
                "scope": "https://www.googleapis.com/auth/androidpublisher",
                "aud": token_uri,
                "iat": now,
                "exp": now + timedelta(minutes=55),
            },
            private_key,
            algorithm="RS256",
            headers={"kid": credentials.get("private_key_id")},
        )
    except (ValueError, KeyError, TypeError) as exc:
        raise GooglePlayProviderError("provider_configuration_invalid") from exc
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.post(
                token_uri,
                data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "assertion": assertion,
                },
            )
            response.raise_for_status()
            payload = response.json()
            token = payload.get("access_token") if isinstance(payload, dict) else None
            if not isinstance(token, str) or not token:
                raise GooglePlayProviderError("provider_token_missing")
            return token
    except (httpx.HTTPError, ValueError) as exc:
        raise GooglePlayProviderError("provider_auth_failed") from exc


def verify_subscription(
    service_account_json: str, package_name: str, product_id: str, purchase_token: str
) -> dict[str, str | None]:
    token = _access_token(service_account_json)
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package_name, safe='')}/purchases/subscriptionsv2/tokens/"
        f"{quote(purchase_token, safe='')}"
    )
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.get(url, headers={"Authorization": f"Bearer {token}"})
            response.raise_for_status()
            payload = response.json()
    except (httpx.HTTPError, ValueError) as exc:
        raise GooglePlayProviderError("provider_verification_failed") from exc
    if not isinstance(payload, dict):
        raise GooglePlayProviderError("provider_response_invalid")
    line_items = payload.get("lineItems")
    first = (
        line_items[0]
        if isinstance(line_items, list) and line_items and isinstance(line_items[0], dict)
        else {}
    )
    return {
        "subscription_state": str(payload.get("subscriptionState", "")),
        "product_id": str(first.get("productId", "")) or None,
        "order_id": str(payload.get("latestOrderId", "")) or None,
        "start_time": str(payload.get("startTime", "")) or None,
        "expiry_time": str(first.get("expiryTime", "")) or None,
        "acknowledgement_state": str(payload.get("acknowledgementState", "")),
    }


def purchase_state(state: str) -> str:
    normalized = state.strip().upper()
    if normalized in {"SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"}:
        return "verified"
    if normalized in {"SUBSCRIPTION_STATE_PENDING", "SUBSCRIPTION_STATE_PAUSED"}:
        return "pending"
    if "EXPIRED" in normalized:
        return "expired"
    if "CANCELED" in normalized:
        return "canceled"
    if "REVOKED" in normalized:
        return "revoked"
    if "REFUND" in normalized:
        return "refunded"
    return "rejected"


def parse_provider_time(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        result = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    return result if result.tzinfo else result.replace(tzinfo=UTC)
