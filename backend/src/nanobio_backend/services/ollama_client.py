from __future__ import annotations

import json
import logging
import time
from collections.abc import Callable, Iterator, Sequence
from dataclasses import dataclass
from typing import Literal, NotRequired, TypedDict

import httpx

from nanobio_backend.core.config import Settings

MAX_PROVIDER_RESPONSE_BYTES = 64 * 1024
TRUNCATION_RETRY_NUM_PREDICT = 2048
MIN_RETRY_REMAINING_SECONDS = 30

logger = logging.getLogger("nanobio.ai")


class OllamaChatMessage(TypedDict):
    role: Literal["system", "user", "assistant"]
    content: str
    images: NotRequired[list[str]]


SafeDoneReason = Literal["stop", "length", "other"]


@dataclass(frozen=True)
class OllamaChatResult:
    text: str | None
    complete: bool
    input_tokens: int | None
    output_tokens: int | None
    done_reason: SafeDoneReason | None
    retry_count: int
    latency_ms: int


@dataclass(frozen=True)
class _ParsedOllamaResponse:
    text: str | None
    complete: bool
    input_tokens: int | None
    output_tokens: int | None
    done_reason: SafeDoneReason | None


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
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._settings = settings
        self._transport_factory = transport_factory
        self._clock = clock

    def generate(
        self,
        messages: Sequence[OllamaChatMessage],
        *,
        trace_id: str | None = None,
        model: str | None = None,
        response_format: str | dict[str, object] | None = None,
        generation_options: dict[str, int | float] | None = None,
    ) -> OllamaChatResult:
        started_at = self._clock()
        deadline = started_at + self._settings.ollama_total_timeout_seconds
        parsed: _ParsedOllamaResponse | None = None
        retry_count = 0

        try:
            parsed = self._request(
                messages,
                num_predict=self._settings.ollama_num_predict,
                time_budget=self._remaining_seconds(deadline),
                deadline=deadline,
                model=model,
                response_format=response_format,
                generation_options=generation_options,
            )
            if self._clock() >= deadline:
                raise OllamaTimeoutError

            if parsed.done_reason == "length" and self._retry_is_allowed(parsed, deadline):
                retry_count = 1
                parsed = self._request(
                    messages,
                    num_predict=TRUNCATION_RETRY_NUM_PREDICT,
                    time_budget=self._remaining_seconds(deadline),
                    deadline=deadline,
                    model=model,
                    response_format=response_format,
                    generation_options=generation_options,
                )
                if self._clock() >= deadline:
                    raise OllamaTimeoutError

            latency_ms = max(0, round((self._clock() - started_at) * 1000))
            result = OllamaChatResult(
                text=parsed.text if parsed.complete else None,
                complete=parsed.complete,
                input_tokens=parsed.input_tokens,
                output_tokens=parsed.output_tokens,
                done_reason=parsed.done_reason,
                retry_count=retry_count,
                latency_ms=latency_ms,
            )
            self._log_metrics(
                trace_id,
                status="complete" if result.complete else "truncated",
                done_reason=result.done_reason,
                input_tokens=result.input_tokens,
                output_tokens=result.output_tokens,
                latency_ms=result.latency_ms,
                retry_count=retry_count,
            )
            return result
        except OllamaProviderError as exc:
            status = _safe_error_status(exc)
            latency_ms = max(0, round((self._clock() - started_at) * 1000))
            self._log_metrics(
                trace_id,
                status=status,
                done_reason=parsed.done_reason if parsed else None,
                input_tokens=parsed.input_tokens if parsed else None,
                output_tokens=parsed.output_tokens if parsed else None,
                latency_ms=latency_ms,
                retry_count=retry_count,
            )
            raise

    def stream(
        self,
        messages: Sequence[OllamaChatMessage],
        *,
        trace_id: str | None = None,
        model: str | None = None,
        response_format: str | dict[str, object] | None = None,
        generation_options: dict[str, int | float] | None = None,
    ) -> Iterator[str]:
        started_at = self._clock()
        deadline = started_at + self._settings.ollama_total_timeout_seconds
        payload: dict[str, object] = {
            "model": model or self._settings.ollama_model,
            "messages": list(messages),
            "stream": True,
            "keep_alive": "30s",
            "options": {
                "num_ctx": self._settings.ollama_num_ctx,
                "num_predict": self._settings.ollama_num_predict,
                **(generation_options or {}),
            },
        }
        if response_format is not None:
            payload["format"] = response_format
        budget = self._remaining_seconds(deadline)
        timeout = httpx.Timeout(
            connect=min(self._settings.ollama_connect_timeout_seconds, budget),
            read=min(self._settings.ollama_read_timeout_seconds, budget),
            write=budget,
            pool=budget,
        )
        transport = self._transport_factory() if self._transport_factory else None
        total_bytes = 0
        input_tokens: int | None = None
        output_tokens: int | None = None
        done_reason: SafeDoneReason | None = None
        emitted_text = False

        try:
            with (
                httpx.Client(
                    base_url=self._settings.ollama_base_url,
                    timeout=timeout,
                    transport=transport,
                ) as client,
                client.stream("POST", "/api/chat", json=payload) as response,
            ):
                if response.status_code >= 400:
                    response_body = _read_bounded_response(
                        response, deadline=deadline, clock=self._clock
                    )
                    decoded = _decode_response(response_body)
                    if _is_context_limit_error(decoded):
                        raise OllamaContextLimitError
                    if response.status_code in {404, 429} or response.status_code >= 500:
                        raise OllamaUnavailableError
                    raise OllamaInvalidResponseError

                for line in response.iter_lines():
                    if self._clock() >= deadline:
                        raise OllamaTimeoutError
                    if not line:
                        continue
                    line_size = len(line.encode("utf-8"))
                    total_bytes += line_size
                    if total_bytes > MAX_PROVIDER_RESPONSE_BYTES:
                        raise OllamaInvalidResponseError
                    try:
                        event = json.loads(line)
                    except (json.JSONDecodeError, TypeError) as exc:
                        raise OllamaInvalidResponseError from exc
                    if not isinstance(event, dict):
                        raise OllamaInvalidResponseError
                    message = event.get("message")
                    content = message.get("content") if isinstance(message, dict) else None
                    if isinstance(content, str) and content:
                        emitted_text = True
                        yield content
                    input_tokens = (
                        _non_negative_integer(event.get("prompt_eval_count")) or input_tokens
                    )
                    output_tokens = _non_negative_integer(event.get("eval_count")) or output_tokens
                    if event.get("done") is True:
                        done_reason = _safe_done_reason(event.get("done_reason"))
                        if done_reason == "length":
                            raise OllamaContextLimitError
                        if not emitted_text:
                            raise OllamaInvalidResponseError
                        latency_ms = max(0, round((self._clock() - started_at) * 1000))
                        self._log_metrics(
                            trace_id,
                            status="complete",
                            done_reason=done_reason,
                            input_tokens=input_tokens,
                            output_tokens=output_tokens,
                            latency_ms=latency_ms,
                            retry_count=0,
                        )
                        return
            raise OllamaInvalidResponseError
        except httpx.TimeoutException as exc:
            error: OllamaProviderError = OllamaTimeoutError()
            raise error from exc
        except httpx.RequestError as exc:
            error = OllamaUnavailableError()
            raise error from exc
        except OllamaProviderError as exc:
            latency_ms = max(0, round((self._clock() - started_at) * 1000))
            self._log_metrics(
                trace_id,
                status=_safe_error_status(exc),
                done_reason=done_reason,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                latency_ms=latency_ms,
                retry_count=0,
            )
            raise

    def _retry_is_allowed(self, response: _ParsedOllamaResponse, deadline: float) -> bool:
        prompt_tokens = response.input_tokens
        return (
            self._settings.ollama_truncation_retry_enabled
            and self._settings.ollama_num_ctx == 4096
            and prompt_tokens is not None
            and prompt_tokens + TRUNCATION_RETRY_NUM_PREDICT <= self._settings.ollama_num_ctx
            and deadline - self._clock() >= MIN_RETRY_REMAINING_SECONDS
        )

    def _remaining_seconds(self, deadline: float) -> float:
        remaining = deadline - self._clock()
        if remaining <= 0:
            raise OllamaTimeoutError
        return remaining

    def _request(
        self,
        messages: Sequence[OllamaChatMessage],
        *,
        num_predict: int,
        time_budget: float,
        deadline: float,
        model: str | None,
        response_format: str | dict[str, object] | None,
        generation_options: dict[str, int | float] | None,
    ) -> _ParsedOllamaResponse:
        payload = {
            "model": model or self._settings.ollama_model,
            "messages": list(messages),
            "stream": False,
            "keep_alive": "30s",
            "options": {
                "num_ctx": self._settings.ollama_num_ctx,
                "num_predict": num_predict,
                **(generation_options or {}),
            },
        }
        if response_format is not None:
            payload["format"] = response_format
        connect_timeout = min(self._settings.ollama_connect_timeout_seconds, time_budget)
        read_timeout = min(
            self._settings.ollama_read_timeout_seconds,
            max(0.05, time_budget - connect_timeout),
        )
        timeout = httpx.Timeout(
            connect=connect_timeout,
            read=read_timeout,
            write=min(connect_timeout, time_budget),
            pool=min(connect_timeout, time_budget),
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
                response_body = _read_bounded_response(
                    response,
                    deadline=deadline,
                    clock=self._clock,
                )
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
        done_reason = _safe_done_reason(decoded.get("done_reason"))
        input_tokens = _non_negative_integer(decoded.get("prompt_eval_count"))
        output_tokens = _non_negative_integer(decoded.get("eval_count"))

        if done_reason == "length":
            return _ParsedOllamaResponse(
                text=None,
                complete=False,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                done_reason="length",
            )

        if decoded.get("done") is not True or not isinstance(content, str) or not content.strip():
            raise OllamaInvalidResponseError

        return _ParsedOllamaResponse(
            text=content.strip(),
            complete=True,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            done_reason=done_reason,
        )

    @staticmethod
    def _log_metrics(
        trace_id: str | None,
        *,
        status: str,
        done_reason: SafeDoneReason | None,
        input_tokens: int | None,
        output_tokens: int | None,
        latency_ms: int,
        retry_count: int,
    ) -> None:
        if trace_id is None:
            return
        logger.info(
            "AI inference trace_id=%s status=%s done_reason=%s prompt_tokens=%s "
            "output_tokens=%s latency_ms=%d retry_count=%d",
            trace_id,
            status,
            done_reason,
            input_tokens,
            output_tokens,
            latency_ms,
            retry_count,
        )


def _safe_error_status(error: OllamaProviderError) -> str:
    if isinstance(error, OllamaTimeoutError):
        return "timeout"
    if isinstance(error, OllamaUnavailableError):
        return "unavailable"
    if isinstance(error, OllamaContextLimitError):
        return "context_limit"
    return "provider_failure"


def _safe_done_reason(value: object) -> SafeDoneReason | None:
    if value == "stop":
        return "stop"
    if value == "length":
        return "length"
    if value is None:
        return None
    return "other"


def _read_bounded_response(
    response: httpx.Response,
    *,
    deadline: float,
    clock: Callable[[], float],
) -> bytes:
    chunks: list[bytes] = []
    total = 0
    for chunk in response.iter_bytes():
        if clock() >= deadline:
            raise OllamaTimeoutError
        total += len(chunk)
        if total > MAX_PROVIDER_RESPONSE_BYTES:
            raise OllamaInvalidResponseError
        chunks.append(chunk)
    if clock() >= deadline:
        raise OllamaTimeoutError
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
