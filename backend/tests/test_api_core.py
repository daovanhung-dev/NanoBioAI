from datetime import UTC, datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

from argon2 import PasswordHasher
from pydantic import SecretStr
from sqlalchemy import select

from nanobio_backend.db.business_models import (
    CommissionRate,
    CommissionRecord,
    PaymentEvent,
    SalePointAdjustment,
    SalePointConversion,
    SaleProfile,
)
from nanobio_backend.db.models import (
    AdminUserRole,
    FamilyMember,
    HealthSubject,
    MembershipSubscription,
    ReferralRelationship,
    SleepSafetyPreference,
    UsageQuotaRule,
    User,
)


def _signup(client, phone="0912345678", name="Test Member", password="StrongPass123"):
    response = client.post(
        "/api/v1/auth/phone-signup",
        json={"phone": phone, "password": password, "full_name": name},
    )
    return response


def test_health_trace_and_real_database_probe(runtime):
    client, _, _ = runtime
    trace_id = str(uuid4())
    live = client.get("/health/live", headers={"X-Trace-Id": trace_id})
    assert live.status_code == 200
    assert live.headers["X-Trace-Id"] == trace_id
    ready = client.get("/health/ready")
    assert ready.status_code == 200
    assert ready.json() == {"status": "ready", "database": "ready"}


def test_phone_signup_login_and_refresh_rotation(runtime):
    client, _, _ = runtime
    created = _signup(client, phone="0084 912 345 678")
    assert created.status_code == 201
    assert created.json()["success"] is True
    assert created.json()["data"]["user"]["phone"] == "+84912345678"
    assert created.headers.get("X-Trace-Id") == created.json()["traceId"]

    login = client.post(
        "/api/v1/auth/login", json={"phone": "+84912345678", "password": "StrongPass123"}
    )
    assert login.status_code == 200
    original_refresh = login.json()["data"]["refresh_token"]
    rotated = client.post("/api/v1/auth/refresh", json={"refresh_token": original_refresh})
    assert rotated.status_code == 200
    replay = client.post("/api/v1/auth/refresh", json={"refresh_token": original_refresh})
    assert replay.status_code == 401
    assert replay.json()["data"] is None


def test_membership_access_is_server_derived_and_defaults_to_free(runtime):
    client, _, _ = runtime
    _signup(client)
    login = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]
    response = client.get(
        "/api/v1/membership/me",
        headers={"Authorization": f"Bearer {login['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["product_access"] == "free"
    assert response.json()["data"]["membership_plan"] == "free"


def test_usage_quota_check_commit_and_idempotency_are_server_owned(runtime):
    client, factory, _ = runtime
    _signup(client)
    with factory() as db:
        db.add(
            UsageQuotaRule(
                plan_code="free",
                feature_key="ai_chat_message",
                period_unit="day",
                max_count=3,
                reset_timezone="Asia/Ho_Chi_Minh",
                is_active=True,
            )
        )
        db.commit()
    login = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]
    headers = {"Authorization": f"Bearer {login['access_token']}"}
    check = client.post(
        "/api/v1/usage-quota/check",
        headers=headers,
        json={"feature_key": "ai_chat_message", "request_id": "chat-1"},
    )
    assert check.status_code == 200
    assert check.json()["data"]["allowed"] is True
    assert check.json()["data"]["limit_count"] == 3

    payload = {"feature_key": "ai_chat_message", "request_id": "chat-1"}
    first = client.post("/api/v1/usage-quota/commit", headers=headers, json=payload)
    repeated = client.post("/api/v1/usage-quota/commit", headers=headers, json=payload)
    assert first.json()["data"]["used_count"] == 1
    assert repeated.json()["data"]["used_count"] == 1

    for request_id in ("chat-2", "chat-3"):
        assert (
            client.post(
                "/api/v1/usage-quota/commit",
                headers=headers,
                json={"feature_key": "ai_chat_message", "request_id": request_id},
            ).json()["data"]["committed"]
            is True
        )
    exhausted = client.post(
        "/api/v1/usage-quota/check",
        headers=headers,
        json={"feature_key": "ai_chat_message", "request_id": "chat-4"},
    )
    assert exhausted.json()["data"]["allowed"] is False
    assert exhausted.json()["data"]["reason_code"] == "quota_exceeded"


def test_admin_can_login_with_email_without_a_phone_number(runtime):
    client, factory, _ = runtime
    with factory() as db:
        user = User(
            phone=None,
            email="admin@example.test",
            password_hash=PasswordHasher().hash("AdminPass123"),
            full_name="Test Admin",
        )
        user.roles.append(AdminUserRole(role_code="super_admin"))
        db.add(user)
        db.commit()

    login = client.post(
        "/api/v1/auth/login",
        json={"email": "ADMIN@example.test", "password": "AdminPass123"},
    )
    assert login.status_code == 200
    assert login.json()["data"]["user"]["email"] == "admin@example.test"
    token = login.json()["data"]["access_token"]
    session = client.get("/api/v1/admin/session", headers={"Authorization": f"Bearer {token}"})
    assert session.status_code == 200
    assert session.json()["data"]["roles"] == ["super_admin"]


def test_admin_username_login_is_case_insensitive_and_keeps_phone_login(runtime):
    client, factory, _ = runtime
    with factory() as db:
        user = User(
            phone="+84912345678",
            username="admin",
            email=None,
            password_hash=PasswordHasher().hash("InitPass456"),
            full_name="Test Admin",
        )
        user.roles.append(AdminUserRole(role_code="super_admin"))
        db.add(user)
        db.commit()

    username_login = client.post(
        "/api/v1/auth/login",
        json={"username": " ADMIN ", "password": "InitPass456"},
    )
    assert username_login.status_code == 200
    assert username_login.json()["data"]["user"]["username"] == "admin"

    phone_login = client.post(
        "/api/v1/auth/login",
        json={"phone": "0912345678", "password": "InitPass456"},
    )
    assert phone_login.status_code == 200


def test_login_requires_exactly_one_identifier(runtime):
    client, _, _ = runtime
    neither = client.post("/api/v1/auth/login", json={"password": "InitPass456"})
    multiple = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "phone": "0912345678", "password": "InitPass456"},
    )
    assert neither.status_code == 422
    assert multiple.status_code == 422


def test_admin_username_temporary_password_flow_requires_rotation(runtime):
    client, factory, _ = runtime
    with factory() as db:
        user = User(
            phone="+84912345678",
            username="admin",
            password_hash=PasswordHasher().hash("InitPass456"),
            full_name="Test Admin",
            force_password_change=True,
        )
        user.roles.append(AdminUserRole(role_code="super_admin"))
        db.add(user)
        db.commit()

    login = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "InitPass456"},
    )
    assert login.status_code == 200
    session = login.json()["data"]
    assert session["must_change_password"] is True
    headers = {"Authorization": f"Bearer {session['access_token']}"}

    denied = client.get("/api/v1/admin/session", headers=headers)
    assert denied.status_code == 403
    assert denied.json()["businessCode"] == "PASSWORD_CHANGE_REQUIRED"

    changed = client.post(
        "/api/v1/auth/change-password",
        headers=headers,
        json={"new_password": "PersonalPass456"},
    )
    assert changed.status_code == 200
    replacement = changed.json()["data"]
    assert replacement["must_change_password"] is False

    old_password = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "InitPass456"},
    )
    new_password = client.post(
        "/api/v1/auth/login",
        json={"username": "admin", "password": "PersonalPass456"},
    )
    assert old_password.status_code == 401
    assert new_password.status_code == 200
    allowed = client.get(
        "/api/v1/admin/session",
        headers={"Authorization": f"Bearer {new_password.json()['data']['access_token']}"},
    )
    assert allowed.status_code == 200


def test_auth_rejects_invalid_phone_and_duplicate_account(runtime):
    client, _, _ = runtime
    invalid = _signup(client, phone="123")
    assert invalid.status_code == 422
    assert invalid.json()["data"] is None
    assert _signup(client).status_code == 201
    duplicate = _signup(client)
    assert duplicate.status_code == 409
    assert duplicate.json()["businessCode"] == "PHONE_EXISTS"


def test_signup_rolls_back_account_when_referral_code_is_invalid(runtime):
    client, factory, _ = runtime
    response = client.post(
        "/api/v1/auth/phone-signup",
        json={
            "phone": "0912345678",
            "password": "StrongPass123",
            "full_name": "Test Member",
            "referral_code": "NOT-A-CODE",
            "device_fingerprint": "device-fingerprint-1",
        },
    )
    assert response.status_code == 400
    assert response.json()["data"] is None
    with factory() as db:
        assert db.scalar(select(User.id).where(User.phone == "+84912345678")) is None


def test_signup_rate_limit_is_applied_per_client_ip(runtime):
    client, _, _ = runtime
    responses = [
        _signup(client, phone=f"0910000{index:03d}", name=f"Member {index}") for index in range(10)
    ]
    limited = _signup(client, phone="0910000010", name="One Too Many")
    assert all(response.status_code == 201 for response in responses)
    assert limited.status_code == 429
    assert limited.json()["businessCode"] == "RATE_LIMITED"


def test_change_password_revokes_refresh_sessions(runtime):
    client, _, _ = runtime
    _signup(client)
    login = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]
    response = client.post(
        "/api/v1/auth/change-password",
        headers={"Authorization": f"Bearer {login['access_token']}"},
        json={"new_password": "ChangedPass456"},
    )
    assert response.status_code == 200
    replay = client.post("/api/v1/auth/refresh", json={"refresh_token": login["refresh_token"]})
    assert replay.status_code == 401
    new_login = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "ChangedPass456"}
    )
    assert new_login.status_code == 200


def test_temporary_password_session_is_locked_until_password_change(runtime):
    client, factory, _ = runtime
    created = _signup(client, password="12345678")
    assert created.status_code == 201
    with factory() as db:
        user = db.scalar(select(User).where(User.phone == "+84912345678"))
        user.force_password_change = True
        db.commit()

    login = client.post("/api/v1/auth/login", json={"phone": "0912345678", "password": "12345678"})
    assert login.status_code == 200
    original = login.json()["data"]
    assert original["must_change_password"] is True
    headers = {"Authorization": f"Bearer {original['access_token']}"}

    blocked = client.get("/api/v1/profile/me", headers=headers)
    assert blocked.status_code == 403
    assert blocked.json()["businessCode"] == "PASSWORD_CHANGE_REQUIRED"
    assert blocked.json()["data"] is None

    changed = client.post(
        "/api/v1/auth/change-password",
        headers=headers,
        json={"new_password": "PersonalPass456"},
    )
    assert changed.status_code == 200
    replacement = changed.json()["data"]
    assert replacement["must_change_password"] is False
    assert replacement["refresh_token"] != original["refresh_token"]

    profile = client.get(
        "/api/v1/profile/me",
        headers={"Authorization": f"Bearer {replacement['access_token']}"},
    )
    assert profile.status_code == 200
    replay = client.post("/api/v1/auth/refresh", json={"refresh_token": original["refresh_token"]})
    assert replay.status_code == 401


def test_admin_route_denies_member_and_grant_is_audited_and_idempotent(runtime):
    client, factory, _ = runtime
    _signup(client)
    member_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    denied = client.post(
        "/api/v1/admin/memberships/grant",
        headers={"Authorization": f"Bearer {member_token}"},
        json={
            "user_id": str(uuid4()),
            "plan_code": "plus",
            "starts_at": datetime.now(UTC).isoformat(),
            "ends_at": None,
            "reason": "support request",
            "idempotency_key": "denied-request-1",
        },
    )
    assert denied.status_code == 403

    with factory() as db:
        actor = db.scalar(select(User).where(User.phone == "+84912345678"))
        target = User(
            phone="+84910000111", full_name="Target", password_hash=PasswordHasher().hash("x")
        )
        db.add(target)
        db.flush()
        actor_id = actor.id
        target_id = target.id
        db.add(AdminUserRole(user_id=actor_id, role_code="super_admin"))
        db.commit()
    actor_token = client.post(
        "/api/v1/auth/login", json={"phone": "+84912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    searched = client.get(
        "/api/v1/admin/users/search?q=Target",
        headers={"Authorization": f"Bearer {actor_token}"},
    )
    assert searched.status_code == 200
    assert searched.json()["data"][0]["section"] == "users"
    assert searched.json()["data"][0]["title"] == "Target"
    payload = {
        "user_id": str(target_id),
        "plan_code": "plus",
        "starts_at": datetime.now(UTC).isoformat(),
        "ends_at": None,
        "reason": "Approved support request",
        "idempotency_key": "grant-test-0001",
    }
    headers = {"Authorization": f"Bearer {actor_token}"}
    first = client.post("/api/v1/admin/memberships/grant", headers=headers, json=payload)
    second = client.post("/api/v1/admin/memberships/grant", headers=headers, json=payload)
    assert first.status_code == second.status_code == 200, (
        first.status_code,
        first.json(),
        second.status_code,
        second.json(),
    )
    assert first.json()["data"] == second.json()["data"]
    with factory() as db:
        subscriptions = db.scalars(
            select(MembershipSubscription).where(MembershipSubscription.user_id == target_id)
        ).all()
        assert len(subscriptions) == 1


def test_ai_generation_is_disabled_by_default_and_food_scan_stays_disabled(runtime):
    client, _, _ = runtime
    _signup(client)
    access_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"messages": [{"role": "user", "content": "Chào Nabi."}]},
    )
    assert response.status_code == 503
    assert response.json()["businessCode"] == "FEATURE_NOT_ENABLED"
    assert response.json()["data"] is None

    food_scan = client.post(
        "/api/v1/food/scan/analyze",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "image_base64": "A" * 64,
            "mime_type": "image/jpeg",
            "prompt": "Nhận diện thực phẩm.",
        },
    )
    assert food_scan.status_code == 503
    assert food_scan.json()["businessCode"] == "FEATURE_NOT_ENABLED"


def test_google_play_provider_failure_is_safe_and_retryable(runtime, monkeypatch):
    from nanobio_backend.services.google_play import GooglePlayProviderError

    client, _, _ = runtime
    _signup(client)
    token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]

    def fail_provider(*args, **kwargs):
        raise GooglePlayProviderError("provider response contains private text")

    monkeypatch.setattr("nanobio_backend.modules.edge_api.view.verify_subscription", fail_provider)
    response = client.post(
        "/api/v1/payments/google-play/verify",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "package_name": "com.nanobioai.app",
            "product_id": "nanobio_plus_monthly",
            "purchase_token": "purchase-token-test",
        },
    )
    assert response.status_code == 502
    assert response.json()["businessCode"] == "PURCHASE_VERIFICATION_PENDING"
    assert "private text" not in response.text


def test_storage_upload_checks_file_signature_and_enforces_owner(runtime):
    client, factory, _ = runtime
    _signup(client)
    owner_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    bucket = "/api/v1/files/sale-payout-proofs"
    spoofed = client.post(
        bucket,
        headers=owner_headers,
        files={"file": ("proof.pdf", b"not a pdf", "application/pdf")},
    )
    assert spoofed.status_code == 422
    assert spoofed.json()["businessCode"] == "FILE_CONTENT_MISMATCH"

    uploaded = client.post(
        bucket,
        headers=owner_headers,
        files={"file": ("proof.pdf", b"%PDF-1.4\nproof", "application/pdf")},
    )
    assert uploaded.status_code == 201
    file_id = uploaded.json()["data"]["id"]
    second = _signup(client, phone="0912345679", name="Other Member")
    assert second.status_code == 201
    other_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345679", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    other_headers = {"Authorization": f"Bearer {other_token}"}
    denied = client.get(f"{bucket}/{file_id}", headers=other_headers)
    assert denied.status_code == 404
    downloaded = client.get(f"{bucket}/{file_id}", headers=owner_headers)
    assert downloaded.status_code == 200
    assert downloaded.content == b"%PDF-1.4\nproof"

    with factory() as db:
        owner = db.scalar(select(User).where(User.phone == "+84912345678"))
        reviewer = User(
            phone="+84910000113",
            full_name="Finance Reviewer",
            password_hash=PasswordHasher().hash("FinancePass123"),
        )
        db.add(reviewer)
        db.flush()
        db.add(AdminUserRole(user_id=reviewer.id, role_code="finance_admin"))
        db.add(SaleProfile(user_id=owner.id, status="active"))
        db.add(
            SalePointConversion(
                sale_user_id=owner.id,
                requested_point_cents=10000,
                point_to_money_rate=Decimal("1.0000"),
                money_amount_cents=10000,
                status="requested",
                metadata_json={"payment_proof_path": file_id},
            )
        )
        reviewer_phone = reviewer.phone
        db.commit()
    reviewer_token = client.post(
        "/api/v1/auth/login",
        json={"phone": reviewer_phone, "password": "FinancePass123"},
    ).json()["data"]["access_token"]
    admin_download = client.get(
        f"/api/v1/admin/files/sale-payout-proofs/{file_id}",
        headers={"Authorization": f"Bearer {reviewer_token}"},
    )
    assert admin_download.status_code == 200
    assert admin_download.content == b"%PDF-1.4\nproof"
    unprivileged_admin_download = client.get(
        f"/api/v1/admin/files/sale-payout-proofs/{file_id}", headers=other_headers
    )
    assert unprivileged_admin_download.status_code == 403
    deleted = client.delete(f"{bucket}/{file_id}", headers=owner_headers)
    assert deleted.status_code == 200


def test_sleep_safety_contacts_are_owner_scoped_and_disabled_by_default(runtime):
    client, _, _ = runtime
    _signup(client)
    owner_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    runtime_config = client.get("/api/v1/sleep-safety/runtime-config", headers=owner_headers)
    assert runtime_config.status_code == 200
    assert runtime_config.json()["data"]["enabled"] is False
    created = client.post(
        "/api/v1/sleep-safety/contacts",
        headers=owner_headers,
        json={
            "name": "Emergency Contact",
            "relationship": "family",
            "phone_e164": "+84912345679",
            "priority": 1,
        },
    )
    assert created.status_code == 201
    contact_id = created.json()["data"]["id"]
    _signup(client, phone="0912345679", name="Other Member")
    other_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345679", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    denied = client.delete(
        f"/api/v1/sleep-safety/contacts/{contact_id}",
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert denied.status_code == 200
    assert denied.json()["data"]["deleted"] is False
    owner_contacts = client.get("/api/v1/sleep-safety/contacts", headers=owner_headers)
    assert owner_contacts.json()["data"][0]["id"] == contact_id
    other_contacts = client.get(
        "/api/v1/sleep-safety/contacts",
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert other_contacts.json()["data"] == []
    verification = client.post(
        "/api/v1/sleep-safety/contacts/verification",
        headers=owner_headers,
        json={"action": "request", "contact_id": contact_id},
    )
    assert verification.status_code == 503
    assert verification.json()["businessCode"] == "SLEEP_SAFETY_DISABLED"


def test_sleep_safety_sync_is_owner_scoped_and_session_bound(runtime):
    client, factory, _ = runtime
    _signup(client)
    owner = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]
    owner_headers = {"Authorization": f"Bearer {owner['access_token']}"}
    owner_id = owner["user"]["id"]

    preference = client.put(
        "/api/v1/sleep-safety/preferences",
        headers=owner_headers,
        json={
            "user_id": str(uuid4()),
            "enabled": True,
            "sensitivity": "balanced",
            "schedule_enabled": False,
            "schedule_start_minutes": 1350,
            "schedule_end_minutes": 390,
            "timezone": "Asia/Ho_Chi_Minh",
            "selected_weekdays": [1, 2, 3, 4, 5, 6, 7],
            "calibration_required": True,
            "calibration_noise_floor": 0.02,
            "calibration_updated_at": "2026-10-30T10:00:00Z",
            "cooldown_seconds": 120,
            "consent_version": "sleep-safety-v1",
            "updated_at": "2026-10-30T10:00:00Z",
        },
    )
    assert preference.status_code == 200
    with factory() as db:
        stored_preference = db.get(SleepSafetyPreference, UUID(owner_id))
        assert stored_preference is not None
        assert stored_preference.user_id == UUID(owner_id)

    session_id = "local-sleep-session-1"
    session = client.put(
        f"/api/v1/sleep-safety/sessions/{session_id}",
        headers=owner_headers,
        json={
            "started_at": "2026-10-30T10:00:00Z",
            "sensitivity": "balanced",
            "status": "monitoring",
            "start_source": "manual",
            "platform": "android",
            "app_version": "1.0.0",
            "created_at": "2026-10-30T10:00:00Z",
            "updated_at": "2026-10-30T10:00:00Z",
        },
    )
    assert session.status_code == 200
    assert session.json()["data"]["id"] == session_id

    event_id = "local-sleep-event-1"
    event_payload = {
        "session_id": session_id,
        "detected_at": "2026-10-30T10:01:00Z",
        "event_type": "suddenLoudSound",
        "severity": "high",
        "confidence": 0.9,
        "relative_energy": 1.2,
        "baseline_delta": 0.8,
        "repetition_count": 1,
        "state": "detected",
        "response": "noResponse",
        "escalation_required": True,
        "escalation_status": "pending",
        "created_at": "2026-10-30T10:01:00Z",
        "updated_at": "2026-10-30T10:01:00Z",
    }
    event = client.put(
        f"/api/v1/sleep-safety/events/{event_id}",
        headers=owner_headers,
        json=event_payload,
    )
    assert event.status_code == 200
    history = client.get("/api/v1/sleep-safety/history", headers=owner_headers)
    assert history.status_code == 200
    assert history.json()["data"]["sessions"][0]["id"] == session_id
    assert history.json()["data"]["events"][0]["id"] == event_id

    _signup(client, phone="0912345679", name="Other Member")
    other = client.post(
        "/api/v1/auth/login", json={"phone": "0912345679", "password": "StrongPass123"}
    ).json()["data"]
    other_headers = {"Authorization": f"Bearer {other['access_token']}"}
    other_history = client.get("/api/v1/sleep-safety/history", headers=other_headers)
    assert other_history.status_code == 200
    assert other_history.json()["data"] == {"sessions": [], "events": []}
    denied = client.put(
        f"/api/v1/sleep-safety/events/{event_id}",
        headers=other_headers,
        json=event_payload,
    )
    assert denied.status_code == 409
    assert denied.json()["businessCode"] == "SESSION_NOT_FOUND"


def test_profile_membership_and_cloud_snapshot_are_user_scoped(runtime):
    client, _, _ = runtime
    _signup(client)
    login = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]
    headers = {"Authorization": f"Bearer {login['access_token']}"}
    membership = client.get("/api/v1/membership/me", headers=headers)
    assert membership.status_code == 200
    assert membership.json()["data"]["membership_plan"] == "free"

    saved = client.put(
        "/api/v1/cloud-sync/snapshot",
        headers=headers,
        json={
            "expected_revision": 0,
            "snapshot": {
                "user": {
                    "full_name": "Updated Member",
                    "phone": "+84999999999",
                    "membership_tier": "plus",
                },
                "tables": {
                    "health_goals": [
                        {
                            "id": "local-goal-1",
                            "user_id": "another-user",
                            "subject_id": "another-subject",
                            "goal_code": "hydration",
                            "goal_name": "Drink water",
                            "phone": "+84999999999",
                        }
                    ]
                },
            },
        },
    )
    assert saved.status_code == 200, saved.text
    assert saved.json()["data"]["revision"] == 1
    row = saved.json()["data"]["tables"]["health_goals"][0]
    assert row["user_id"] == login["user"]["id"]
    assert row["goal_code"] == "hydration"
    assert "phone" not in row and "subject_id" not in row
    profile = client.get("/api/v1/profile/me", headers=headers)
    assert profile.json()["data"]["full_name"] == "Updated Member"
    stale = client.put(
        "/api/v1/cloud-sync/snapshot",
        headers=headers,
        json={"expected_revision": 0, "snapshot": {"user": {}, "tables": {}}},
    )
    assert stale.status_code == 409
    assert stale.json()["businessCode"] == "SNAPSHOT_REVISION_CONFLICT"

    other = _signup(client, phone="0912345679", name="Other Member")
    assert other.status_code == 201
    second_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345679", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    other_snapshot = client.get(
        "/api/v1/cloud-sync/snapshot", headers={"Authorization": f"Bearer {second_token}"}
    ).json()["data"]
    assert other_snapshot == {"revision": 0, "user": None, "tables": {}}

    forbidden = client.put(
        "/api/v1/cloud-sync/snapshot",
        headers=headers,
        json={"snapshot": {"user": {}, "tables": {"wellness_point_ledgers": []}}},
    )
    assert forbidden.status_code == 422
    assert forbidden.json()["businessCode"] == "UNSUPPORTED_SNAPSHOT_TABLE"


def test_familyplus_group_member_and_owner_boundaries(runtime):
    client, factory, _ = runtime
    _signup(client)
    owner_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    path = "/api/v1/family-plus"
    denied = client.get(f"{path}/context", headers=owner_headers)
    assert denied.status_code == 403
    assert denied.json()["businessCode"] == "FAMILYPLUS_REQUIRED"

    _signup(client, phone="0912345679", name="Second Owner")
    second_token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345679", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    with factory() as db:
        owner = db.scalar(select(User).where(User.phone == "+84912345678"))
        second = db.scalar(select(User).where(User.phone == "+84912345679"))
        owner_self = db.scalar(
            select(HealthSubject).where(
                HealthSubject.owner_user_id == owner.id,
                HealthSubject.subject_type == "self",
            )
        )
        owner_subject = HealthSubject(
            owner_user_id=owner.id,
            subject_type="family_member",
            display_name="Child Profile",
            relationship="child",
        )
        db.add_all(
            [
                owner_subject,
                MembershipSubscription(
                    user_id=owner.id,
                    plan_code="family_plus",
                    status="active",
                    source="manual",
                    starts_at=datetime.now(UTC),
                ),
                MembershipSubscription(
                    user_id=second.id,
                    plan_code="family_plus",
                    status="active",
                    source="manual",
                    starts_at=datetime.now(UTC),
                ),
            ]
        )
        foreign_subject = HealthSubject(
            owner_user_id=second.id,
            subject_type="family_member",
            display_name="Foreign Profile",
            relationship="family",
        )
        db.add(foreign_subject)
        db.flush()
        owner_subject_id = owner_subject.id
        foreign_subject_id = foreign_subject.id
        owner_self_id = owner_self.id
        db.commit()

    group = client.put(
        f"{path}/group",
        headers=owner_headers,
        json={"display_name": "My Family", "idempotency_key": "family-group-001"},
    )
    assert group.status_code == 200
    assert group.json()["data"]["group"]["display_name"] == "My Family"
    repeated = client.put(
        f"{path}/group",
        headers=owner_headers,
        json={"display_name": "My Family", "idempotency_key": "family-group-001"},
    )
    assert repeated.status_code == 200
    assert repeated.json()["data"]["group"]["id"] == group.json()["data"]["group"]["id"]

    member_payload = {
        "subject_id": str(owner_subject_id),
        "display_name": "Child Profile",
        "role": "child",
        "can_view": True,
        "can_edit": False,
        "idempotency_key": "family-member-001",
    }
    member = client.put(f"{path}/members", headers=owner_headers, json=member_payload)
    assert member.status_code == 200, member.text
    member_id = member.json()["data"]["members"][0]["id"]
    assert member.json()["data"]["selected_subject_id"] == str(owner_self_id)
    forbidden_subject = client.put(
        f"{path}/members",
        headers=owner_headers,
        json={**member_payload, "subject_id": str(foreign_subject_id)},
    )
    assert forbidden_subject.status_code == 403
    assert forbidden_subject.json()["businessCode"] == "FAMILYPLUS_SUBJECT_NOT_ALLOWED"

    with factory() as db:
        group_row = db.scalar(
            select(FamilyMember.family_group_id).where(FamilyMember.id == UUID(member_id))
        )
        extra_subjects = [
            HealthSubject(
                owner_user_id=owner.id,
                subject_type="family_member",
                display_name=f"Family {index}",
            )
            for index in range(5)
        ]
        db.add_all(extra_subjects)
        db.flush()
        for subject in extra_subjects[:4]:
            db.add(
                FamilyMember(
                    family_group_id=group_row,
                    subject_id=subject.id,
                    display_name=subject.display_name,
                    status="active",
                )
            )
        capacity_subject_id = extra_subjects[4].id
        db.commit()
    over_limit = client.put(
        f"{path}/members",
        headers=owner_headers,
        json={**member_payload, "subject_id": str(capacity_subject_id)},
    )
    assert over_limit.status_code == 409
    assert over_limit.json()["businessCode"] == "FAMILYPLUS_MEMBER_LIMIT"

    foreign_remove = client.request(
        "DELETE",
        f"{path}/members/{member_id}",
        headers={"Authorization": f"Bearer {second_token}"},
        json={"idempotency_key": "family-remove-foreign"},
    )
    assert foreign_remove.status_code == 404
    removed = client.request(
        "DELETE",
        f"{path}/members/{member_id}",
        headers=owner_headers,
        json={"idempotency_key": "family-remove-owner"},
    )
    assert removed.status_code == 200
    assert removed.json()["data"]["members"][0]["status"] == "removed"
    with factory() as db:
        assert db.scalar(select(FamilyMember.id).where(FamilyMember.id == UUID(member_id)))


def test_manual_membership_payment_requires_server_configuration(runtime):
    client, _, _ = runtime
    _signup(client)
    token = client.post(
        "/api/v1/auth/login", json={"phone": "0912345678", "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    response = client.post(
        "/api/v1/payments/membership-requests",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "plan_code": "plus",
            "billing_cycle": "monthly",
            "idempotency_key": "payment-request-1",
            "payer_full_name": "Test Member",
        },
    )
    assert response.status_code == 503
    assert response.json()["businessCode"] == "MEMBERSHIP_PAYMENT_NOT_CONFIGURED"


def test_manual_membership_payment_idempotency_ownership_and_no_early_access(runtime):
    client, factory, settings = runtime
    _signup(client)
    with factory() as db:
        owner = db.scalar(select(User).where(User.phone == "+84912345678"))
        other = User(
            phone="+84910000112",
            full_name="Other",
            password_hash=PasswordHasher().hash("OtherPass123"),
        )
        db.add(other)
        db.flush()
        db.add(SaleProfile(user_id=other.id, status="active"))
        db.add(
            ReferralRelationship(
                referrer_id=other.id,
                referred_id=owner.id,
                device_fingerprint_hash="a" * 64,
                status="active",
            )
        )
        db.add(CommissionRate(code="direct_referral", rate=Decimal("0.1000"), is_active=True))
        owner_phone = owner.phone
        db.commit()
    settings.membership_payment_prices_json = (
        '{"currency":"VND","prices":{"plus":{"monthly":199000,"yearly":1990000},'
        '"family_plus":{"monthly":399000,"yearly":3990000}}}'
    )
    settings.membership_payment_bank_json = SecretStr(
        '{"bank_code":"TST","bank_name":"Test Bank","bank_bin":"999999",'
        '"bank_account_number":"12345678","bank_account_name":"TEST",'
        '"bank_account_display_name":"Test Account"}'
    )
    client.app.state.settings = settings
    owner_token = client.post(
        "/api/v1/auth/login", json={"phone": owner_phone, "password": "StrongPass123"}
    ).json()["data"]["access_token"]
    owner_headers = {"Authorization": f"Bearer {owner_token}"}
    payload = {
        "plan_code": "plus",
        "billing_cycle": "monthly",
        "idempotency_key": "payment-request-123",
        "payer_full_name": "Test Member",
    }
    created = client.post(
        "/api/v1/payments/membership-requests", headers=owner_headers, json=payload
    )
    replay = client.post(
        "/api/v1/payments/membership-requests", headers=owner_headers, json=payload
    )
    assert created.status_code == replay.status_code == 201
    assert created.json()["data"] == replay.json()["data"]
    assert created.json()["data"]["grants_access_before_approval"] is False
    payment_id = created.json()["data"]["payment_event_id"]
    another_open = client.post(
        "/api/v1/payments/membership-requests",
        headers=owner_headers,
        json={**payload, "idempotency_key": "payment-request-124"},
    )
    assert another_open.status_code == 409
    assert another_open.json()["businessCode"] == "MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN"

    other_token = client.post(
        "/api/v1/auth/login", json={"phone": "+84910000112", "password": "OtherPass123"}
    )
    assert other_token.status_code == 200
    denied = client.post(
        f"/api/v1/payments/membership-requests/{payment_id}/confirm",
        headers={"Authorization": f"Bearer {other_token.json()['data']['access_token']}"},
    )
    assert denied.status_code == 404
    confirmed = client.post(
        f"/api/v1/payments/membership-requests/{payment_id}/confirm", headers=owner_headers
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["data"]["status"] == "pending_review"
    denied_alert = client.get("/api/v1/admin/payments/review-alert", headers=owner_headers)
    assert denied_alert.status_code == 403
    with factory() as db:
        owner = db.scalar(select(User).where(User.phone == owner_phone))
        other = db.scalar(select(User).where(User.phone == "+84910000112"))
        db.add(AdminUserRole(user_id=owner.id, role_code="finance_admin"))
        db.add(AdminUserRole(user_id=other.id, role_code="finance_admin"))
        db.commit()
    payment_alert = client.get("/api/v1/admin/payments/review-alert", headers=owner_headers)
    assert payment_alert.status_code == 200
    assert payment_alert.json()["data"]["pending_review_count"] == 1
    listed = client.get(
        "/api/v1/admin/payments?q=NB",
        headers={"Authorization": f"Bearer {other_token.json()['data']['access_token']}"},
    )
    assert listed.status_code == 200
    assert listed.json()["data"][0]["id"] == payment_id
    assert listed.json()["data"][0]["title"].startswith("plus - 199000 VND")
    reviewer_headers = {"Authorization": f"Bearer {other_token.json()['data']['access_token']}"}
    review_path = f"/api/v1/admin/payments/{payment_id}/review"
    review_payload = {
        "decision": "approve",
        "reason": "Bank transfer reconciled",
        "idempotency_key": "payment-review-001",
        "transfer_verified": False,
    }
    self_review = client.post(review_path, headers=owner_headers, json=review_payload)
    assert self_review.status_code == 403
    not_reconciled = client.post(review_path, headers=reviewer_headers, json=review_payload)
    assert not_reconciled.status_code == 422
    assert not_reconciled.json()["businessCode"] == "PAYMENT_TRANSFER_RECONCILIATION_REQUIRED"
    approved = client.post(
        review_path,
        headers=reviewer_headers,
        json={**review_payload, "transfer_verified": True},
    )
    assert approved.status_code == 200, approved.text
    assert approved.json()["data"]["status"] == "succeeded"
    sale_dashboard = client.get("/api/v1/sale/dashboard", headers=reviewer_headers)
    assert sale_dashboard.status_code == 200
    assert sale_dashboard.json()["data"]["successful_payments"] == 1
    with factory() as db:
        payment_event = db.get(PaymentEvent, UUID(payment_id))
        assert payment_event is not None
        assert payment_event.status == "succeeded"
        commission = db.scalar(
            select(CommissionRecord).where(CommissionRecord.payment_event_id == UUID(payment_id))
        )
        assert commission is not None
        assert commission.receiver_user_id == other.id
        assert commission.amount_cents == 19900
        assert commission.available_at - payment_event.paid_at == timedelta(hours=24)
    replayed_review = client.post(
        review_path,
        headers=reviewer_headers,
        json={**review_payload, "transfer_verified": True},
    )
    assert replayed_review.status_code == 200
    assert replayed_review.json()["data"]["idempotent_replay"] is True
    membership = client.get("/api/v1/membership/me", headers=owner_headers)
    assert membership.json()["data"]["membership_plan"] == "plus"
    payment_alert = client.get("/api/v1/admin/payments/review-alert", headers=owner_headers)
    assert payment_alert.json()["data"]["pending_review_count"] == 0
    reversal_payload = {
        "decision": "refund",
        "reason": "Transfer reversed by bank",
        "idempotency_key": "payment-reversal-001",
    }
    reversed_payment = client.post(
        f"/api/v1/admin/payments/{payment_id}/reversal",
        headers=reviewer_headers,
        json=reversal_payload,
    )
    assert reversed_payment.status_code == 200, reversed_payment.text
    assert reversed_payment.json()["data"]["status"] == "refunded"
    replayed_reversal = client.post(
        f"/api/v1/admin/payments/{payment_id}/reversal",
        headers=reviewer_headers,
        json=reversal_payload,
    )
    assert replayed_reversal.status_code == 200
    assert replayed_reversal.json()["data"]["idempotent_replay"] is True
    sale_dashboard_after_reversal = client.get("/api/v1/sale/dashboard", headers=reviewer_headers)
    assert sale_dashboard_after_reversal.status_code == 200
    assert sale_dashboard_after_reversal.json()["data"]["successful_payments"] == 0
    with factory() as db:
        adjustments = db.scalars(
            select(SalePointAdjustment).where(
                SalePointAdjustment.idempotency_key.like("sale-reversal-%")
            )
        ).all()
        assert len(adjustments) == 1
        assert adjustments[0].sale_user_id == other.id
        assert adjustments[0].point_delta_cents == -19900
        assert adjustments[0].metadata_json["ledger_policy"] == (
            "negative_adjustment_without_overwriting_commission"
        )

    rejected_request = client.post(
        "/api/v1/payments/membership-requests",
        headers=owner_headers,
        json={**payload, "idempotency_key": "payment-request-125"},
    )
    assert rejected_request.status_code == 201
    rejected_id = rejected_request.json()["data"]["payment_event_id"]
    client.post(
        f"/api/v1/payments/membership-requests/{rejected_id}/confirm", headers=owner_headers
    )
    rejected = client.post(
        f"/api/v1/admin/payments/{rejected_id}/review",
        headers=reviewer_headers,
        json={
            "decision": "reject",
            "reason": "Transfer not found",
            "idempotency_key": "payment-review-002",
        },
    )
    assert rejected.status_code == 200
    assert rejected.json()["data"]["status"] == "failed"
    with factory() as db:
        subscriptions = db.scalars(
            select(MembershipSubscription).where(MembershipSubscription.user_id == owner.id)
        ).all()
        assert len(subscriptions) == 1
    canceled = client.post(
        f"/api/v1/payments/membership-requests/{payment_id}/cancel", headers=owner_headers
    )
    assert canceled.status_code == 409
