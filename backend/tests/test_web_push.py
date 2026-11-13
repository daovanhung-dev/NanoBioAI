from datetime import UTC, datetime, timedelta

from pydantic import SecretStr

from nanobio_backend.core.config import Settings
from nanobio_backend.main import create_app

_SUBSCRIPTION = {
    "endpoint": "https://fcm.googleapis.com/fcm/send/example-token",
    "keys": {"p256dh": "A" * 65, "auth": "B" * 24},
    "timezone": "Asia/Ho_Chi_Minh",
}


def test_web_push_config_is_public_but_requires_server_private_key(runtime) -> None:
    client, _, _ = runtime
    unavailable = client.get("/api/v1/web-push/config")
    assert unavailable.status_code == 200
    assert unavailable.json()["data"] == {"enabled": False, "public_key": None}

    app = create_app(
        Settings(
            web_push_vapid_public_key="public-key",
            web_push_vapid_private_key=SecretStr("private-key"),
        ),
        session_factory=runtime[1],
    )
    from fastapi.testclient import TestClient

    with TestClient(app) as configured_client:
        configured = configured_client.get("/api/v1/web-push/config")
    assert configured.json()["data"] == {
        "enabled": True,
        "public_key": "public-key",
    }


def test_guest_can_register_replace_and_delete_only_with_capability(runtime) -> None:
    client, _, _ = runtime
    created = client.post("/api/v1/web-push/subscriptions", json=_SUBSCRIPTION)
    assert created.status_code == 201
    data = created.json()["data"]
    subscription_id = data["subscription_id"]
    capability = data["capability"]

    scheduled_at = (datetime.now(UTC) + timedelta(hours=1)).isoformat()
    reminders = client.put(
        f"/api/v1/web-push/subscriptions/{subscription_id}/reminders",
        headers={"X-Guest-Capability": capability},
        json={
            "timezone": "Asia/Ho_Chi_Minh",
            "reminders": [
                {
                    "reminder_id": "31001",
                    "category": "schedule",
                    "scheduled_at": scheduled_at,
                },
                {
                    "reminder_id": "31002",
                    "category": "medication",
                    "daily_minute": 480,
                },
            ],
        },
    )
    assert reminders.status_code == 200
    assert reminders.json()["data"]["reminder_count"] == 2

    wrong_capability = client.delete(
        f"/api/v1/web-push/subscriptions/{subscription_id}",
        headers={"X-Guest-Capability": "wrong-capability"},
    )
    assert wrong_capability.status_code == 404

    deleted = client.delete(
        f"/api/v1/web-push/subscriptions/{subscription_id}",
        headers={"X-Guest-Capability": capability},
    )
    assert deleted.status_code == 200
    assert deleted.json()["data"]["deleted"] is True


def test_web_push_rejects_private_endpoints_and_unapproved_payload_fields(runtime) -> None:
    client, _, _ = runtime
    unsafe_endpoint = {
        **_SUBSCRIPTION,
        "endpoint": "https://127.0.0.1/private",
    }
    assert client.post("/api/v1/web-push/subscriptions", json=unsafe_endpoint).status_code == 422

    created = client.post("/api/v1/web-push/subscriptions", json=_SUBSCRIPTION)
    data = created.json()["data"]
    response = client.put(
        f"/api/v1/web-push/subscriptions/{data['subscription_id']}/reminders",
        headers={"X-Guest-Capability": data["capability"]},
        json={
            "timezone": "Asia/Ho_Chi_Minh",
            "reminders": [
                {
                    "reminder_id": "1",
                    "category": "medication",
                    "daily_minute": 480,
                    "title": "Thuốc A",
                }
            ],
        },
    )
    assert response.status_code == 422


def test_web_push_cors_allows_guest_capability_header(runtime) -> None:
    client, _, _ = runtime
    response = client.options(
        "/api/v1/web-push/subscriptions/00000000-0000-0000-0000-000000000000/reminders",
        headers={
            "Origin": "https://example.test",
            "Access-Control-Request-Method": "PUT",
            "Access-Control-Request-Headers": "content-type,x-guest-capability",
        },
    )
    assert response.status_code == 200
    assert "x-guest-capability" in response.headers["access-control-allow-headers"].lower()
