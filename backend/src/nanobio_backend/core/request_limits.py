from __future__ import annotations

from uuid import uuid4

from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Message, Receive, Scope, Send

AI_GENERATE_MAX_REQUEST_BYTES = 16 * 1024
FOOD_SCAN_MAX_REQUEST_BYTES = 12 * 1024 * 1024


class AiGenerateRequestLimitMiddleware:
    """Bounds the buffered request body for the AI generation endpoint only."""

    def __init__(self, app: ASGIApp, *, path: str, max_bytes: int) -> None:
        self.app = app
        self.path = path
        self.max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if (
            scope["type"] != "http"
            or scope.get("method") != "POST"
            or scope.get("path") != self.path
        ):
            await self.app(scope, receive, send)
            return

        content_length = self._content_length(scope)
        if content_length is not None and content_length > self.max_bytes:
            await self._too_large(scope, receive, send)
            return

        messages: list[Message] = []
        body_size = 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            if message["type"] != "http.request":
                continue
            body_size += len(message.get("body", b""))
            if body_size > self.max_bytes:
                await self._too_large(scope, receive, send)
                return
            messages.append(message)
            if not message.get("more_body", False):
                break

        message_index = 0

        async def replay_receive() -> Message:
            nonlocal message_index
            if message_index < len(messages):
                message = messages[message_index]
                message_index += 1
                return message
            return await receive()

        await self.app(scope, replay_receive, send)

    @staticmethod
    def _content_length(scope: Scope) -> int | None:
        raw_length = next(
            (value for key, value in scope.get("headers", []) if key.lower() == b"content-length"),
            None,
        )
        if raw_length is None:
            return None
        try:
            return int(raw_length)
        except ValueError:
            return None

    async def _too_large(self, scope: Scope, receive: Receive, send: Send) -> None:
        state = scope.get("state")
        trace_id = state.get("trace_id") if isinstance(state, dict) else None
        if not isinstance(trace_id, str):
            trace_id = str(uuid4())
        response = JSONResponse(
            status_code=413,
            headers={"X-Trace-Id": trace_id},
            content={
                "success": False,
                "businessCode": "REQUEST_TOO_LARGE",
                "message": "Nội dung gửi đến vượt quá giới hạn an toàn.",
                "data": None,
                "meta": {},
                "traceId": trace_id,
            },
        )
        await response(scope, receive, send)
