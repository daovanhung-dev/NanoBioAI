from __future__ import annotations

import json
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from typing import Literal, TypedDict

import httpx

from nanobio_backend.core.config import Settings

MAX_PROVIDER_RESPONSE_BYTES = 64 * 1024


class OllamaChatMessage(TypedDict):
    role: Literal["system", "user", "assistant"]
    content: str


@dataclass(frozen=True)
class OllamaChatResult:
    text: str
    input_tokens: int | None
    output_tokens: int | None


class OllamaProviderError(Exception):
    """Base class for safe, provider-independent Ollama failures."""


class OllamaTimeoutError(OllamaProviderError):
    pass


class OllamaUnavailableError(OllamaProviderError):
    pass


class OllamaContextLimitError(OllamaProviderError):
    pass


class OllamaInvalidResponseError(OllamaProviderError):
    pass


class OllamaClient:
    def __init__(
        self,
        settings: Settings,
        *,
        transport_factory: Callable[[], httpx.BaseTransport] | None = None,
    ) -> None:
        self._settings = settings
        self._transport_factory = transport_factory

    def generate(self, messages: Sequence[OllamaChatMessage]) -> OllamaChatResult:
        payload = {
            "model": self._settings.ollama_model,
            "messages": list(messages),
            "stream": False,
            "keep_alive": "30s",
            "options": {
                "num_ctx": self._settings.ollama_num_ctx,
                "num_predict": self._settings.ollama_num_predict,
            },
        }
        timeout = httpx.Timeout(
            connect=self._settings.ollama_connect_timeout_seconds,
            read=self._settings.ollama_read_timeout_seconds,
            write=self._settings.ollama_connect_timeout_seconds,
            pool=self._settings.ollama_connect_timeout_seconds,
        )
        transport = self._transport_factory() if self._transport_factory else None

        try:
            with (
                httpx.Client(
                    base_url=self._settings.ollama_base_url,
                    timeout=timeout,
                    transport=transport,
                ) as client,
                client.stream("POST", "/api/chat", json=payload) as response,
            ):
                response_body = _read_bounded_response(response)
                status_code = response.status_code
        except httpx.TimeoutException as exc:
            raise OllamaTimeoutError from exc
        except httpx.RequestError as exc:
            raise OllamaUnavailableError from exc

        decoded = _decode_response(response_body)
        if status_code >= 400:
            if _is_context_limit_error(decoded):
                raise OllamaContextLimitError
            if status_code in {404, 429} or status_code >= 500:
                raise OllamaUnavailableError
            raise OllamaInvalidResponseError

        if not isinstance(decoded, dict):
            raise OllamaInvalidResponseError
        message = decoded.get("message")
        content = message.get("content") if isinstance(message, dict) else None
        if (
            decoded.get("done") is not True
            or decoded.get("done_reason") == "length"
            or not isinstance(content, str)
            or not content.strip()
        ):
            raise OllamaInvalidResponseError

        return OllamaChatResult(
            text=content.strip(),
            input_tokens=_non_negative_integer(decoded.get("prompt_eval_count")),
            output_tokens=_non_negative_integer(decoded.get("eval_count")),
        )


def _read_bounded_response(response: httpx.Response) -> bytes:
    chunks: list[bytes] = []
    total = 0
    for chunk in response.iter_bytes():
        total += len(chunk)
        if total > MAX_PROVIDER_RESPONSE_BYTES:
            raise OllamaInvalidResponseError
        chunks.append(chunk)
    return b"".join(chunks)


def _decode_response(response_body: bytes) -> object:
    try:
        return json.loads(response_body)
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise OllamaInvalidResponseError from exc


def _is_context_limit_error(payload: object) -> bool:
    if not isinstance(payload, dict):
        return False
    error = payload.get("error")
    if not isinstance(error, str):
        return False
    normalized = error.casefold()
    return any(
        phrase in normalized
        for phrase in (
            "context length",
            "context window",
            "input length exceeds the context",
            "prompt is too long",
            "too many tokens",
        )
    )


def _non_negative_integer(value: object) -> int | None:
    if isinstance(value, int) and not isinstance(value, bool) and value >= 0:
        return value
    return None
