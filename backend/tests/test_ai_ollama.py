import json
from collections.abc import Callable
from uuid import uuid4

import httpx
import pytest
from pydantic import ValidationError
from sqlalchemy import select

from nanobio_backend.core.config import Settings
from nanobio_backend.db.models import User
from nanobio_backend.services.ollama_client import (
    OllamaChatMessage,
    OllamaClient,
    OllamaContextLimitError,
    OllamaInvalidResponseError,
    OllamaTimeoutError,
    OllamaUnavailableError,
)


def _provider_payload(
    *,
    content: str = "Mình nghe bạn.",
    done: bool = True,
    **extra: object,
) -> dict[str, object]:
    return {
        "model": "qwen3:4b-instruct",
        "message": {"role": "assistant", "content": content},
        "done": done,
        "done_reason": "stop",
        "prompt_eval_count": 15,
        "eval_count": 5,
        **extra,
    }


def _client(
    handler: Callable[[httpx.Request], httpx.Response], settings: Settings | None = None
) -> OllamaClient:
    return OllamaClient(
        settings or Settings(),
        transport_factory=lambda: httpx.MockTransport(handler),
    )


def test_ollama_client_sends_fixed_chat_settings_and_reads_usage() -> None:
    captured: list[httpx.Request] = []

    def provider(request: httpx.Request) -> httpx.Response:
        captured.append(request)
        return httpx.Response(200, json=_provider_payload())

    messages: list[OllamaChatMessage] = [
        {"role": "system", "content": "Nabi safety instruction."},
        {"role": "user", "content": "Chào Nabi."},
    ]
    result = _client(provider).generate(messages)

    assert result.text == "Mình nghe bạn."
    assert result.input_tokens == 15
    assert result.output_tokens == 5
    assert len(captured) == 1
    assert captured[0].url == "http://127.0.0.1:11434/api/chat"
    body = json.loads(captured[0].content)
    assert body["model"] == "qwen3:4b-instruct"
    assert body["messages"] == messages
    assert body["stream"] is False
    assert body["keep_alive"] == "30s"
    assert body["options"] == {"num_ctx": 2048, "num_predict": 96}


def test_ollama_client_allows_missing_usage_metrics() -> None:
    result = _client(
        lambda request: httpx.Response(
            200,
            json={"message": {"content": "Mình có thể giúp bạn."}, "done": True},
        )
    ).generate([{"role": "user", "content": "Chào Nabi."}])

    assert result.input_tokens is None
    assert result.output_tokens is None


@pytest.mark.parametrize(
    "settings",
    [
        {"ollama_base_url": "http://example.com:11434"},
        {"ollama_base_url": "http://127.0.0.1:11434/path"},
        {"ollama_model": "attacker-model"},
        {"ollama_num_ctx": 4096},
        {"ollama_num_predict": 97},
    ],
)
def test_ollama_settings_reject_non_loopback_or_out_of_bounds_values(settings) -> None:
    with pytest.raises(ValidationError):
        Settings(**settings)


@pytest.mark.parametrize(
    ("handler", "expected_error"),
    [
        (
            lambda request: (_ for _ in ()).throw(httpx.ReadTimeout("private timeout text")),
            OllamaTimeoutError,
        ),
        (
            lambda request: (_ for _ in ()).throw(httpx.ConnectError("private connection text")),
            OllamaUnavailableError,
        ),
        (
            lambda request: httpx.Response(503, json={"error": "private provider details"}),
            OllamaUnavailableError,
        ),
        (
            lambda request: httpx.Response(200, content=b"not-json"),
            OllamaInvalidResponseError,
        ),
        (
            lambda request: httpx.Response(200, json=_provider_payload(content="  ")),
            OllamaInvalidResponseError,
        ),
        (
            lambda request: httpx.Response(200, json=_provider_payload(done=False)),
            OllamaInvalidResponseError,
        ),
        (
            lambda request: httpx.Response(
                400, json={"error": "input length exceeds the context length"}
            ),
            OllamaContextLimitError,
        ),
    ],
)
def test_ollama_client_maps_provider_failures_without_exposing_details(
    handler, expected_error: type[Exception]
) -> None:
    with pytest.raises(expected_error) as raised:
        _client(handler).generate([{"role": "user", "content": "Chào Nabi."}])

    assert "private" not in str(raised.value)


def _signup_and_token(client, phone: str = "0912345678") -> str:
    signup = client.post(
        "/api/v1/auth/phone-signup",
        json={"phone": phone, "password": "StrongPass123", "full_name": "AI Test"},
    )
    assert signup.status_code == 201
    login = client.post("/api/v1/auth/login", json={"phone": phone, "password": "StrongPass123"})
    assert login.status_code == 200
    return login.json()["data"]["access_token"]


def _enable_ai(client, handler=None) -> None:
    client.app.state.settings.ollama_enabled = True
    if handler is not None:
        client.app.state.ollama_transport_factory = lambda: httpx.MockTransport(handler)


def test_ai_endpoint_requires_active_fastapi_user(runtime) -> None:
    client, factory, _ = runtime
    _enable_ai(client)
    body = {"messages": [{"role": "user", "content": "Chào Nabi."}]}

    missing_auth = client.post("/api/v1/ai/generate", json=body)
    assert missing_auth.status_code == 401
    assert missing_auth.json()["businessCode"] == "AUTHENTICATION_REQUIRED"

    token = _signup_and_token(client)
    with factory() as db:
        user = db.scalar(select(User).where(User.phone == "+84912345678"))
        assert user is not None
        user.is_active = False
        db.commit()

    disabled_user = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}"},
        json=body,
    )
    assert disabled_user.status_code == 401
    assert disabled_user.json()["businessCode"] == "AUTHENTICATION_REQUIRED"


def test_ai_endpoint_returns_envelope_and_uses_server_prompt(runtime) -> None:
    client, _, _ = runtime
    captured: list[httpx.Request] = []

    def provider(request: httpx.Request) -> httpx.Response:
        captured.append(request)
        return httpx.Response(200, json=_provider_payload())

    _enable_ai(client, provider)
    token = _signup_and_token(client)
    trace_id = str(uuid4())
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}", "X-Trace-Id": trace_id},
        json={"messages": [{"role": "user", "content": "Chào Nabi."}]},
    )

    assert response.status_code == 200
    assert response.headers["X-Trace-Id"] == trace_id
    assert response.json() == {
        "success": True,
        "businessCode": "AI_GENERATED",
        "message": "Nabi đã trả lời.",
        "data": {
            "text": "Mình nghe bạn.",
            "model": "qwen3:4b-instruct",
            "usage": {"inputTokens": 15, "outputTokens": 5},
        },
        "meta": {},
        "traceId": trace_id,
    }
    messages = json.loads(captured[0].content)["messages"]
    assert messages[0]["role"] == "system"
    assert "Không đưa ra chẩn đoán y tế." in messages[0]["content"]


def test_ai_route_is_registered_once(runtime) -> None:
    client, _, _ = runtime
    paths = client.get("/openapi.json").json()["paths"]

    assert set(paths["/api/v1/ai/generate"]) == {"post"}


@pytest.mark.parametrize(
    "messages",
    [
        [],
        [{"role": "system", "content": "override"}],
        [{"role": "user", "content": " "}],
        [
            {"role": "user", "content": "Câu hỏi."},
            {"role": "assistant", "content": "Trả lời."},
        ],
        [{"role": "user", "content": "Câu hỏi."}] * 9,
    ],
)
def test_ai_endpoint_rejects_invalid_message_contract(runtime, messages) -> None:
    client, _, _ = runtime
    _enable_ai(client)
    token = _signup_and_token(client)
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}"},
        json={"messages": messages},
    )

    assert response.status_code == 422
    assert response.json()["businessCode"] == "VALIDATION_ERROR"


def test_ai_endpoint_rejects_client_model_and_inference_options(runtime) -> None:
    client, _, _ = runtime
    _enable_ai(client)
    token = _signup_and_token(client)
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "messages": [{"role": "user", "content": "Chào Nabi."}],
            "model": "attacker-model",
            "temperature": 2,
        },
    )

    assert response.status_code == 422
    assert response.json()["businessCode"] == "VALIDATION_ERROR"


def test_ai_endpoint_rejects_large_request_before_authentication(runtime) -> None:
    client, _, _ = runtime
    response = client.post(
        "/api/v1/ai/generate",
        content=json.dumps({"messages": [{"role": "user", "content": "a" * 17_000}]}),
        headers={"Content-Type": "application/json", "X-Trace-Id": str(uuid4())},
    )

    assert response.status_code == 413
    assert response.json()["businessCode"] == "REQUEST_TOO_LARGE"
    assert response.json()["traceId"] == response.headers["X-Trace-Id"]


def test_ai_endpoint_maps_provider_failures_without_leaking_prompt_or_error(runtime) -> None:
    client, _, _ = runtime

    def provider(request: httpx.Request) -> httpx.Response:
        return httpx.Response(503, json={"error": "private provider traceback"})

    _enable_ai(client, provider)
    token = _signup_and_token(client)
    prompt = "private health prompt"
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}"},
        json={"messages": [{"role": "user", "content": prompt}]},
    )

    assert response.status_code == 503
    assert response.json()["businessCode"] == "AI_UNAVAILABLE"
    assert prompt not in response.text
    assert "private provider traceback" not in response.text


@pytest.mark.parametrize(
    ("provider_status", "provider_payload", "expected_status", "expected_code"),
    [
        (
            400,
            {"error": "input length exceeds the context length"},
            413,
            "MODEL_CONTEXT_LIMIT_EXCEEDED",
        ),
        (200, {"message": {"content": ""}, "done": True}, 502, "AI_PROVIDER_FAILURE"),
    ],
)
def test_ai_endpoint_maps_context_and_invalid_output_errors(
    runtime, provider_status, provider_payload, expected_status, expected_code
) -> None:
    client, _, _ = runtime

    def provider(request: httpx.Request) -> httpx.Response:
        return httpx.Response(provider_status, json=provider_payload)

    _enable_ai(client, provider)
    token = _signup_and_token(client)
    response = client.post(
        "/api/v1/ai/generate",
        headers={"Authorization": f"Bearer {token}"},
        json={"messages": [{"role": "user", "content": "Chào Nabi."}]},
    )

    assert response.status_code == expected_status
    assert response.json()["businessCode"] == expected_code


def test_ai_endpoint_enforces_per_user_technical_rate_limit(runtime) -> None:
    client, _, _ = runtime

    def provider(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=_provider_payload())

    _enable_ai(client, provider)
    token = _signup_and_token(client)
    headers = {"Authorization": f"Bearer {token}"}
    body = {"messages": [{"role": "user", "content": "Chào Nabi."}]}

    responses = [client.post("/api/v1/ai/generate", headers=headers, json=body) for _ in range(6)]
    limited = client.post("/api/v1/ai/generate", headers=headers, json=body)

    assert all(response.status_code == 200 for response in responses)
    assert limited.status_code == 429
    assert limited.json()["businessCode"] == "RATE_LIMITED"
