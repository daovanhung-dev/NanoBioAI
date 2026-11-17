import hashlib
import json
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from uuid import UUID, uuid4

from sqlalchemy import select
from starlette.websockets import WebSocketDisconnect

from nanobio_backend.db.models import (
    CloudSnapshot,
    IotDevice,
    IotDeviceConsent,
    IotDeviceCredential,
    IotDeviceSession,
    IotPairingSession,
    User,
)


def _signup(client, phone: str) -> tuple[dict[str, str], dict[str, str]]:
    response = client.post(
        "/api/v1/auth/phone-signup",
        json={"phone": phone, "password": "StrongPass123", "full_name": "Nabi Test"},
    )
    assert response.status_code == 201
    data = response.json()["data"]
    return data, {"Authorization": f"Bearer {data['access_token']}"}


def _pair_device(client, headers: dict[str, str], *, device_id: str) -> tuple[str, str, str]:
    pairing = client.post("/api/v1/iot/pairing-sessions", headers=headers)
    assert pairing.status_code == 201
    pair_data = pairing.json()["data"]
    claim = client.post(
        "/api/v1/iot/devices/claim",
        json={"device_id": device_id, "pairing_token": pair_data["pairing_token"]},
    )
    assert claim.status_code == 200
    device = claim.json()["data"]
    return device["access_token"], device["refresh_token"], pair_data["pairing_session_id"]


def _login_device(client, *, device_id: str, phone: str, password: str = "StrongPass123"):
    return client.post(
        "/api/v1/iot/devices/credentials/login",
        json={
            "device_id": device_id,
            "identifier_type": "phone",
            "identifier": phone,
            "password": password,
        },
    )


def test_device_account_login_issues_only_device_scoped_tokens(runtime):
    client, factory, _ = runtime
    account, headers = _signup(client, "0912345670")
    device_id = "10123456789abcdef0123456789abcde"

    response = _login_device(client, device_id=device_id, phone="0912345670")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["device_id"] == device_id
    assert data["protocol_version"] == 3
    assert len(data["access_token"]) >= 32
    assert len(data["refresh_token"]) >= 32
    assert "password" not in data
    with factory() as db:
        user = db.get(User, UUID(account["user"]["id"]))
        device = db.get(IotDevice, device_id)
        credentials = db.get(IotDeviceCredential, device_id)
        assert user is not None and user.password_hash != "StrongPass123"
        assert device is not None and str(device.owner_id) == account["user"]["id"]
        assert credentials is not None
        assert credentials.access_token_hash == hashlib.sha256(
            data["access_token"].encode()
        ).hexdigest()
        assert credentials.refresh_token_hash == hashlib.sha256(
            data["refresh_token"].encode()
        ).hexdigest()

    listed = client.get("/api/v1/iot/devices", headers=headers)
    assert listed.status_code == 200
    assert listed.json()["data"][0]["device_id"] == device_id


def test_device_account_login_rejects_bad_credentials_and_limits_retries(runtime):
    client, factory, _ = runtime
    _signup(client, "0912345671")
    device_id = "20123456789abcdef0123456789abcde"

    for attempt in range(10):
        response = _login_device(
            client,
            device_id=device_id,
            phone="0912345671",
            password="WrongPass123",
        )
        assert response.status_code == 401, attempt
        assert response.json()["businessCode"] == "INVALID_CREDENTIALS"

    limited = _login_device(
        client,
        device_id=device_id,
        phone="0912345671",
        password="WrongPass123",
    )
    assert limited.status_code == 429
    assert limited.json()["businessCode"] == "RATE_LIMITED"
    with factory() as db:
        assert db.get(IotDevice, device_id) is None


def test_device_account_login_enforces_owner_and_resets_unbound_device(runtime):
    client, factory, _ = runtime
    _, owner_headers = _signup(client, "0912345672")
    other_account, _other_headers = _signup(client, "0912345673")
    device_id = "30123456789abcdef0123456789abcde"

    initial = _login_device(client, device_id=device_id, phone="0912345672")
    assert initial.status_code == 200
    foreign = _login_device(client, device_id=device_id, phone="0912345673")
    assert foreign.status_code == 409
    assert foreign.json()["businessCode"] == "DEVICE_ALREADY_CLAIMED"

    with factory() as db:
        device = db.get(IotDevice, device_id)
        assert device is not None
        db.add(
            IotDeviceConsent(
                device_id=device_id,
                identity=True,
                profile_goals=True,
                sensitive_health=False,
                recent_tracking=False,
            )
        )
        db.add(
            IotDeviceSession(
                device_id=device_id,
                connection_id="a" * 32,
                connected_at=datetime.now(UTC),
                last_seen_at=datetime.now(UTC),
                lease_expires_at=datetime.now(UTC) + timedelta(seconds=45),
            )
        )
        db.commit()

    # The current owner can reauthenticate; the old live lease is replaced.
    renewed = _login_device(client, device_id=device_id, phone="0912345672")
    assert renewed.status_code == 200
    with factory() as db:
        assert db.get(IotDeviceSession, device_id) is None
        consent = db.get(IotDeviceConsent, device_id)
        assert consent is not None and consent.identity is True

    # An explicit unbind permits the new account to claim it and resets consent.
    unbound = client.delete(f"/api/v1/iot/devices/{device_id}", headers=owner_headers)
    assert unbound.status_code == 200
    rebound = _login_device(client, device_id=device_id, phone="0912345673")
    assert rebound.status_code == 200
    with factory() as db:
        device = db.get(IotDevice, device_id)
        consent = db.get(IotDeviceConsent, device_id)
        assert device is not None and str(device.owner_id) == other_account["user"]["id"]
        assert consent is None


def test_pairing_claim_hashes_token_and_rejects_reuse_or_second_owner(runtime):
    client, factory, _ = runtime
    _, owner_headers = _signup(client, "0912345678")
    _, other_headers = _signup(client, "0912345679")
    device_id = "0123456789abcdef0123456789abcdef"

    pairing = client.post("/api/v1/iot/pairing-sessions", headers=owner_headers)
    assert pairing.status_code == 201
    pair_data = pairing.json()["data"]
    assert pair_data["expires_in"] == 120
    assert len(pair_data["pairing_token"]) >= 32

    claim = client.post(
        "/api/v1/iot/devices/claim",
        json={"device_id": device_id, "pairing_token": pair_data["pairing_token"]},
    )
    assert claim.status_code == 200
    credential = claim.json()["data"]
    assert credential["protocol_version"] == 3
    assert credential["access_expires_in"] == 900
    assert credential["websocket_url"] == "wss://nanobio.s2w.click/api/v1/iot/ws"

    with factory() as db:
        pairing_row = db.scalar(
            select(IotPairingSession).where(
                IotPairingSession.id == UUID(pair_data["pairing_session_id"])
            )
        )
        stored = db.get(IotDeviceCredential, device_id)
        device = db.get(IotDevice, device_id)
        assert pairing_row is not None
        assert (
            pairing_row.token_hash
            == hashlib.sha256(pair_data["pairing_token"].encode()).hexdigest()
        )
        assert stored is not None
        assert (
            stored.access_token_hash
            == hashlib.sha256(credential["access_token"].encode()).hexdigest()
        )
        assert (
            stored.refresh_token_hash
            == hashlib.sha256(credential["refresh_token"].encode()).hexdigest()
        )
        assert device is not None and device.owner_id is not None

    reused = client.post(
        "/api/v1/iot/devices/claim",
        json={
            "device_id": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "pairing_token": pair_data["pairing_token"],
        },
    )
    assert reused.status_code == 401

    other_pairing = client.post("/api/v1/iot/pairing-sessions", headers=other_headers).json()[
        "data"
    ]
    duplicate = client.post(
        "/api/v1/iot/devices/claim",
        json={"device_id": device_id, "pairing_token": other_pairing["pairing_token"]},
    )
    assert duplicate.status_code == 409

    extra_identity = client.post(
        "/api/v1/iot/devices/claim",
        json={
            "device_id": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "pairing_token": other_pairing["pairing_token"],
            "user_id": "owner-selected-by-client",
        },
    )
    assert extra_identity.status_code == 422

    status = client.get(
        f"/api/v1/iot/pairing-sessions/{pair_data['pairing_session_id']}",
        headers=owner_headers,
    )
    assert status.status_code == 200
    assert status.json()["data"]["status"] == "claimed"
    assert "pairing_token" not in status.json()["data"]


def test_expired_pairing_token_cannot_claim(runtime):
    client, factory, _ = runtime
    _, headers = _signup(client, "0912345680")
    pairing = client.post("/api/v1/iot/pairing-sessions", headers=headers).json()["data"]
    with factory() as db:
        row = db.scalar(
            select(IotPairingSession).where(
                IotPairingSession.id == UUID(pairing["pairing_session_id"])
            )
        )
        assert row is not None
        row.expires_at = datetime.now(UTC) - timedelta(seconds=1)
        db.commit()

    response = client.post(
        "/api/v1/iot/devices/claim",
        json={
            "device_id": "cccccccccccccccccccccccccccccccc",
            "pairing_token": pairing["pairing_token"],
        },
    )
    assert response.status_code == 401


def test_same_owner_can_reprovision_without_resetting_consent(runtime):
    client, factory, _ = runtime
    _, headers = _signup(client, "0912345689")
    device_id = "abababababababababababababababab"
    old_access, _, _ = _pair_device(client, headers, device_id=device_id)
    consent = client.put(
        f"/api/v1/iot/devices/{device_id}/consents",
        headers=headers,
        json={
            "identity": True,
            "profile_goals": True,
            "sensitive_health": False,
            "recent_tracking": False,
        },
    )
    assert consent.status_code == 200

    pairing = client.post("/api/v1/iot/pairing-sessions", headers=headers).json()["data"]
    reprovisioned = client.post(
        "/api/v1/iot/devices/claim",
        json={"device_id": device_id, "pairing_token": pairing["pairing_token"]},
    )
    assert reprovisioned.status_code == 200
    assert reprovisioned.json()["data"]["access_token"] != old_access
    listed = client.get("/api/v1/iot/devices", headers=headers).json()["data"]
    assert listed[0]["consent"]["identity"] is True
    assert listed[0]["consent"]["profile_goals"] is True

    with factory() as db:
        credentials = db.get(IotDeviceCredential, device_id)
        assert credentials is not None
        assert credentials.access_token_hash != hashlib.sha256(old_access.encode()).hexdigest()


def test_device_credentials_rotate_and_owner_scoped_operations(runtime):
    client, _, _ = runtime
    _, owner_headers = _signup(client, "0912345681")
    _, other_headers = _signup(client, "0912345682")
    device_id = "dddddddddddddddddddddddddddddddd"
    access, refresh, _ = _pair_device(client, owner_headers, device_id=device_id)

    listed = client.get("/api/v1/iot/devices", headers=owner_headers)
    assert listed.status_code == 200
    assert listed.json()["data"][0]["consent"] == {
        "identity": False,
        "profile_goals": False,
        "sensitive_health": False,
        "recent_tracking": False,
    }
    assert client.get("/api/v1/iot/devices", headers=other_headers).json()["data"] == []

    foreign_rename = client.patch(
        f"/api/v1/iot/devices/{device_id}",
        headers=other_headers,
        json={"name": "Không thuộc tài khoản"},
    )
    assert foreign_rename.status_code == 404
    foreign_unbind = client.delete(f"/api/v1/iot/devices/{device_id}", headers=other_headers)
    assert foreign_unbind.status_code == 404

    consent = client.put(
        f"/api/v1/iot/devices/{device_id}/consents",
        headers=owner_headers,
        json={
            "identity": True,
            "profile_goals": False,
            "sensitive_health": True,
            "recent_tracking": False,
        },
    )
    assert consent.status_code == 200
    assert consent.json()["data"]["sensitive_health"] is True
    assert (
        client.post(
            f"/api/v1/iot/devices/{device_id}/sensitive-unlock",
            headers=owner_headers,
            json={"confirm": True},
        ).status_code
        == 409
    )

    rotation = client.post(
        "/api/v1/iot/devices/credentials/refresh",
        json={"device_id": device_id, "refresh_token": refresh},
    )
    assert rotation.status_code == 200
    rotated = rotation.json()["data"]
    assert rotated["access_token"] != access
    replay = client.post(
        "/api/v1/iot/devices/credentials/refresh",
        json={"device_id": device_id, "refresh_token": refresh},
    )
    assert replay.status_code == 401

    unbound = client.delete(f"/api/v1/iot/devices/{device_id}", headers=owner_headers)
    assert unbound.status_code == 200
    assert unbound.json()["data"]["credentials_revoked"] is True
    assert client.get("/api/v1/iot/devices", headers=owner_headers).json()["data"] == []
    refresh_after_unbind = client.post(
        "/api/v1/iot/devices/credentials/refresh",
        json={"device_id": device_id, "refresh_token": rotated["refresh_token"]},
    )
    assert refresh_after_unbind.status_code == 401


def test_single_websocket_lease_and_voice_exchange_stays_in_memory(runtime, monkeypatch):
    from nanobio_backend.modules.iot import voice

    client, factory, settings = runtime
    _, owner_headers = _signup(client, "0912345683")
    device_id = "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    access, _, _ = _pair_device(client, owner_headers, device_id=device_id)
    client.app.state.settings = settings.model_copy(update={"ollama_enabled": True})

    observed_messages: list[dict[str, str]] = []

    async def transcribe(_settings, _packets):
        return "Tôi muốn hỏi về sức khỏe."

    async def synthesize(_settings, text):
        assert text == "Nabi trả lời."
        return [b"\xf8\xff\xfe"]

    class FakeOllamaClient:
        def __init__(self, _settings):
            pass

        def generate(self, messages, **_kwargs):
            observed_messages.extend(messages)
            return SimpleNamespace(text="Nabi trả lời.", complete=True)

    monkeypatch.setattr(voice, "transcribe_audio", transcribe)
    monkeypatch.setattr(voice, "synthesize_audio", synthesize)
    monkeypatch.setattr(voice, "OllamaClient", FakeOllamaClient)

    ws_headers = {"Authorization": f"Bearer {access}", "Protocol-Version": "3"}
    with client.websocket_connect("/api/v1/iot/ws", headers=ws_headers) as websocket:
        hello = json.loads(websocket.receive_text())
        assert hello["type"] == "hello"
        assert hello["audio_params"]["sample_rate"] == 24_000

        conflict = None
        try:
            with client.websocket_connect("/api/v1/iot/ws", headers=ws_headers):
                pass
        except WebSocketDisconnect as error:
            conflict = error
        assert conflict is not None and conflict.code == 4409

        unlock_missing_confirmation = client.post(
            f"/api/v1/iot/devices/{device_id}/sensitive-unlock",
            headers=owner_headers,
            json={"confirm": False},
        )
        assert unlock_missing_confirmation.status_code == 422

        websocket.send_text(json.dumps({"type": "listen", "state": "start", "mode": "manual"}))
        websocket.send_bytes(b"\x00\x00\x00\x03abc")
        websocket.send_text(json.dumps({"type": "listen", "state": "stop"}))
        stt = json.loads(websocket.receive_text())
        tts_start = json.loads(websocket.receive_text())
        tts_sentence = json.loads(websocket.receive_text())
        audio_frame = websocket.receive_bytes()
        tts_stop = json.loads(websocket.receive_text())

        assert stt["type"] == "stt"
        assert tts_start["state"] == "start"
        assert tts_sentence["text"] == "Nabi trả lời."
        assert audio_frame == b"\x00\x00\x00\x03\xf8\xff\xfe"
        assert tts_stop["state"] == "stop"
        assert all(
            "Tôi muốn hỏi" not in str(item)
            for item in observed_messages
            if item["role"] == "system"
        )

        unlock = client.post(
            f"/api/v1/iot/devices/{device_id}/sensitive-unlock",
            headers=owner_headers,
            json={"confirm": True},
        )
        assert unlock.status_code == 200
        assert unlock.json()["data"]["expires_in"] == 300

    with factory() as db:
        assert db.get(IotDeviceSession, device_id) is None
        transcript_rows = [
            row for row in db.scalars(select(CloudSnapshot)) if "Tôi muốn hỏi" in str(row.payload)
        ]
        assert transcript_rows == []


def test_personal_context_honors_per_device_consent_unlock_and_owner(runtime):
    from nanobio_backend.modules.iot.view import build_personal_context

    client, factory, _ = runtime
    owner, owner_headers = _signup(client, "0912345684")
    other, _ = _signup(client, "0912345685")
    device_id = "ffffffffffffffffffffffffffffffff"
    _pair_device(client, owner_headers, device_id=device_id)
    client.put(
        f"/api/v1/iot/devices/{device_id}/consents",
        headers=owner_headers,
        json={
            "identity": True,
            "profile_goals": True,
            "sensitive_health": True,
            "recent_tracking": True,
        },
    )

    now = datetime.now(UTC)
    owner_id = UUID(owner["user"]["id"])
    other_id = UUID(other["user"]["id"])
    with factory() as db:
        owner_user = db.get(User, owner_id)
        other_user = db.get(User, other_id)
        assert owner_user is not None and other_user is not None
        owner_user.gender = "female"
        owner_user.birth_year = 1992
        db.add_all(
            [
                CloudSnapshot(
                    user_id=owner_id,
                    snapshot_type="mobile-v1",
                    revision=1,
                    updated_at=now,
                    payload={
                        "user": {},
                        "tables": {
                            "health_goals": [{"goal_name": "Đi bộ đều"}],
                            "health_conditions": [
                                {"condition_name": "Hồ sơ riêng của A", "severity_level": "low"}
                            ],
                            "health_tracking_logs": [{"log_date": "2026-11-02", "weight_kg": 62.0}],
                        },
                    },
                ),
                CloudSnapshot(
                    user_id=other_id,
                    snapshot_type="mobile-v1",
                    revision=1,
                    updated_at=now,
                    payload={
                        "user": {},
                        "tables": {
                            "health_conditions": [{"condition_name": "Không được rò của B"}]
                        },
                    },
                ),
            ]
        )
        db.add(
            IotDeviceSession(
                device_id=device_id,
                connection_id=uuid4().hex,
                connected_at=now,
                last_seen_at=now,
                lease_expires_at=now + timedelta(seconds=45),
                sensitive_unlocked_until=now + timedelta(minutes=5),
            )
        )
        db.commit()
        device = db.get(IotDevice, device_id)
        assert device is not None
        connection_id = db.get(IotDeviceSession, device_id).connection_id
        assert connection_id is not None
        context, limitations = build_personal_context(
            db,
            owner_id=device.owner_id,
            device_id=device_id,
            connection_id=connection_id,
            now=now,
        )
        assert "Hồ sơ riêng của A" in context
        assert "Không được rò của B" not in context
        assert "Đi bộ đều" in context
        assert limitations == []

        consent = db.get(IotDeviceConsent, device_id)
        assert consent is not None
        consent.sensitive_health = False
        db.commit()
        context_without_sensitive_consent, _ = build_personal_context(
            db,
            owner_id=device.owner_id,
            device_id=device_id,
            connection_id=connection_id,
            now=now,
        )
        assert "Hồ sơ riêng của A" not in context_without_sensitive_consent
