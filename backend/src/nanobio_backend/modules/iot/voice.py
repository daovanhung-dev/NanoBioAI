from __future__ import annotations

import asyncio
import base64
import hashlib
import hmac
import json
import logging
import struct
from collections.abc import Sequence
from contextlib import suppress
from datetime import UTC, datetime, timedelta
from typing import Any, Literal, TypedDict
from uuid import uuid4

import httpx
from fastapi import WebSocket, WebSocketDisconnect
from fastapi.concurrency import run_in_threadpool
from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session

from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import IotDevice, IotDeviceCredential, IotDeviceSession
from nanobio_backend.modules.auth.view import consume_rate_limit
from nanobio_backend.modules.iot.view import build_personal_context
from nanobio_backend.services.ollama_client import (
    OllamaClient,
    OllamaContextLimitError,
    OllamaInvalidResponseError,
    OllamaTimeoutError,
    OllamaUnavailableError,
)

logger = logging.getLogger("nanobio.iot.voice")


class VoiceHistoryMessage(TypedDict):
    role: Literal["user", "assistant"]
    content: str


MAX_AUDIO_SECONDS = 60
MAX_AUDIO_FRAMES = 1_024
MAX_OPUS_FRAME_BYTES = 2_048
SESSION_LEASE_SECONDS = 45
SESSION_HEARTBEAT_SECONDS = 10
MAX_TURN_TEXT_CHARS = 2_000
MAX_HISTORY_MESSAGES = 12
INPUT_SAMPLE_RATE = 16_000
OUTPUT_SAMPLE_RATE = 24_000


def _hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def _active_token(db: Session, token: str) -> tuple[str, Any] | None:
    credentials = db.scalar(
        select(IotDeviceCredential).where(IotDeviceCredential.access_token_hash == _hash(token))
    )
    if credentials is None or credentials.revoked_at is not None:
        return None
    now = datetime.now(UTC)
    expires = _utc(credentials.access_expires_at)
    if expires is None or expires <= now:
        return None
    device = db.get(IotDevice, credentials.device_id)
    if device is None or device.owner_id is None or device.unbound_at is not None:
        return None
    return device.id, device.owner_id


def _acquire_session(factory: Any, device_id: str, connection_id: str) -> bool:
    with factory() as db:
        dialect = db.get_bind().dialect.name
        values = {"device_id": device_id}
        statement: Any
        if dialect == "postgresql":
            statement = (
                pg_insert(IotDeviceSession)
                .values(**values)
                .on_conflict_do_nothing(index_elements=["device_id"])
            )
        elif dialect == "sqlite":
            statement = (
                sqlite_insert(IotDeviceSession)
                .values(**values)
                .on_conflict_do_nothing(index_elements=["device_id"])
            )
        else:
            if db.get(IotDeviceSession, device_id) is None:
                db.add(IotDeviceSession(device_id=device_id))
                db.flush()
            statement = None
        if statement is not None:
            db.execute(statement)
            db.flush()
        row = db.scalar(
            select(IotDeviceSession)
            .where(IotDeviceSession.device_id == device_id)
            .with_for_update()
        )
        now = datetime.now(UTC)
        if row is None:
            db.rollback()
            return False
        current_expiry = _utc(row.lease_expires_at)
        if row.connection_id is not None and current_expiry is not None and current_expiry > now:
            db.rollback()
            return False
        row.connection_id = connection_id
        row.connected_at = now
        row.last_seen_at = now
        row.lease_expires_at = now + timedelta(seconds=SESSION_LEASE_SECONDS)
        row.sensitive_unlocked_until = None
        db.commit()
        return True


def _touch_session(factory: Any, device_id: str, connection_id: str) -> bool:
    with factory() as db:
        with atomic(db):
            row = db.scalar(
                select(IotDeviceSession)
                .where(
                    IotDeviceSession.device_id == device_id,
                    IotDeviceSession.connection_id == connection_id,
                )
                .with_for_update()
            )
            device = db.get(IotDevice, device_id)
            credentials = db.get(IotDeviceCredential, device_id)
            if (
                row is None
                or device is None
                or device.owner_id is None
                or device.unbound_at is not None
                or credentials is None
                or credentials.revoked_at is not None
            ):
                return False
            now = datetime.now(UTC)
            row.last_seen_at = now
            row.lease_expires_at = now + timedelta(seconds=SESSION_LEASE_SECONDS)
        return True


def _release_session(factory: Any, device_id: str, connection_id: str) -> None:
    with factory() as db:
        db.execute(
            delete(IotDeviceSession).where(
                IotDeviceSession.device_id == device_id,
                IotDeviceSession.connection_id == connection_id,
            )
        )
        db.commit()


def _parse_v3_opus_frame(frame: bytes) -> bytes | None:
    if len(frame) < 5 or len(frame) > MAX_OPUS_FRAME_BYTES + 4:
        return None
    frame_type, reserved, payload_size = struct.unpack("!BBH", frame[:4])
    if frame_type != 0 or reserved != 0 or payload_size != len(frame) - 4:
        return None
    return frame[4:]


def _wrap_v3_opus_frame(packet: bytes) -> bytes:
    if not packet or len(packet) > MAX_OPUS_FRAME_BYTES:
        raise ValueError("opus_packet_invalid")
    return struct.pack("!BBH", 0, 0, len(packet)) + packet


async def _call_speech_worker(
    settings: Any, path: str, payload: dict[str, object], *, timeout_seconds: float
) -> dict[str, Any]:
    token = settings.iot_speech_worker_token
    secret = token.get_secret_value() if token is not None else ""
    if len(secret) < 32:
        raise RuntimeError("speech_worker_not_configured")
    async with httpx.AsyncClient(
        base_url=settings.iot_speech_worker_url,
        timeout=httpx.Timeout(timeout_seconds, connect=2.0),
        trust_env=False,
    ) as client:
        response = await client.post(
            path,
            json=payload,
            headers={"X-Nabi-Worker-Token": secret},
        )
    if response.status_code != 200:
        raise RuntimeError("speech_worker_unavailable")
    data = response.json()
    if not isinstance(data, dict):
        raise RuntimeError("speech_worker_invalid_response")
    return data


async def transcribe_audio(settings: Any, packets: Sequence[bytes]) -> str:
    encoded = [base64.b64encode(packet).decode("ascii") for packet in packets]
    response = await _call_speech_worker(
        settings,
        "/v1/transcribe",
        {"frames": encoded},
        timeout_seconds=90,
    )
    transcript = response.get("text")
    if not isinstance(transcript, str):
        raise RuntimeError("speech_worker_invalid_response")
    return " ".join(transcript.split())[:MAX_TURN_TEXT_CHARS]


async def synthesize_audio(settings: Any, text: str) -> list[bytes]:
    response = await _call_speech_worker(
        settings,
        "/v1/synthesize",
        {"text": text[:MAX_TURN_TEXT_CHARS]},
        timeout_seconds=60,
    )
    if response.get("sample_rate") != OUTPUT_SAMPLE_RATE:
        raise RuntimeError("speech_worker_invalid_response")
    values = response.get("frames")
    if (
        not isinstance(values, list)
        or not values
        or len(values) > OUTPUT_SAMPLE_RATE * 30 // 1_440 + 1
    ):
        raise RuntimeError("speech_worker_invalid_response")
    try:
        packets = [
            base64.b64decode(value, validate=True) for value in values if isinstance(value, str)
        ]
    except (ValueError, TypeError) as exc:
        raise RuntimeError("speech_worker_invalid_response") from exc
    if len(packets) != len(values) or any(
        not value or len(value) > MAX_OPUS_FRAME_BYTES for value in packets
    ):
        raise RuntimeError("speech_worker_invalid_response")
    return packets


def _consume_voice_rate_limit(factory: Any, settings: Any, owner_id: Any) -> None:
    key = settings.rate_limit_hmac_key
    if key is None or len(key.get_secret_value()) < 32:
        raise RuntimeError("voice_rate_limit_not_configured")
    subject = hmac.new(
        key.get_secret_value().encode("utf-8"),
        str(owner_id).encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    with factory() as db, atomic(db):
        limited = consume_rate_limit(
            db,
            scope="nabi-iot-voice",
            subject_hash=subject,
            limit=20,
            window_seconds=60,
        )
        if limited:
            raise RuntimeError("voice_rate_limited")


def _load_voice_context(
    factory: Any,
    settings: Any,
    *,
    owner_id: Any,
    device_id: str,
    connection_id: str,
) -> tuple[str, list[str]]:
    with factory() as db:
        return build_personal_context(
            db,
            owner_id=owner_id,
            device_id=device_id,
            connection_id=connection_id,
            snapshot_max_age_days=settings.iot_snapshot_max_age_days,
        )


def _system_prompt(context: str, limitations: Sequence[str]) -> str:
    allowed_context = context or "Không có dữ liệu cá nhân được cho phép trong phiên này."
    limit_text = (
        "\n".join(f"- {item}" for item in limitations) or "- Không có giới hạn dữ liệu bổ sung."
    )
    return (
        "Bạn là Nabi, trợ lý sức khỏe nói tiếng Việt, ấm áp và không phán xét. "
        "Bạn chỉ đưa thông tin chung, không chẩn đoán, không thay thế bác sĩ, "
        "không tự tạo kết quả xét nghiệm, thuốc, dị ứng hoặc chỉ số. Nếu thiếu dữ liệu "
        "hoặc dữ liệu không còn mới, hãy nói rõ giới hạn đó khi người dùng hỏi về "
        "sức khỏe cá nhân. "
        "Với dấu hiệu cấp cứu, khuyên người dùng liên hệ dịch vụ cấp cứu hoặc nhân viên y tế.\n"
        "Ngữ cảnh cá nhân được đồng ý cho thiết bị này:\n"
        f"{allowed_context}\n"
        "Giới hạn hiện tại:\n"
        f"{limit_text}"
    )


async def _send_json(websocket: WebSocket, message: dict[str, object]) -> None:
    await websocket.send_text(json.dumps(message, ensure_ascii=False, separators=(",", ":")))


async def _send_error(websocket: WebSocket, session_id: str, message: str) -> None:
    await _send_json(
        websocket,
        {"session_id": session_id, "type": "alert", "status": "error", "message": message},
    )


async def _answer_turn(
    websocket: WebSocket,
    *,
    factory: Any,
    settings: Any,
    owner_id: Any,
    device_id: str,
    connection_id: str,
    session_id: str,
    packets: Sequence[bytes],
    history: list[VoiceHistoryMessage],
) -> None:
    if not packets:
        await _send_error(websocket, session_id, "Nabi chưa nhận được âm thanh trong lượt này.")
        return
    try:
        transcript = await transcribe_audio(settings, packets)
    except Exception:
        await _send_error(websocket, session_id, "Nabi chưa nghe rõ. Bạn thử nói lại nhé.")
        return
    if not transcript:
        await _send_error(websocket, session_id, "Nabi chưa nghe rõ. Bạn thử nói lại nhé.")
        return

    try:
        _consume_voice_rate_limit(factory, settings, owner_id)
    except Exception:
        await _send_error(websocket, session_id, "Nabi đang bận. Bạn thử lại sau nhé.")
        return
    if not settings.ollama_enabled:
        await _send_error(websocket, session_id, "Trợ lý AI hiện chưa sẵn sàng trên máy chủ.")
        return

    try:
        context, limitations = _load_voice_context(
            factory,
            settings,
            owner_id=owner_id,
            device_id=device_id,
            connection_id=connection_id,
        )
    except Exception:
        await _send_error(websocket, session_id, "Nabi chưa thể mở ngữ cảnh cá nhân lúc này.")
        return

    from nanobio_backend.services.ollama_client import OllamaChatMessage

    messages: list[OllamaChatMessage] = [
        {"role": "system", "content": _system_prompt(context, limitations)}
    ]
    for item in history[-MAX_HISTORY_MESSAGES:]:
        messages.append({"role": item["role"], "content": item["content"]})
    messages.append({"role": "user", "content": transcript})
    try:
        result = await run_in_threadpool(
            OllamaClient(settings).generate,
            messages,
            model=settings.ollama_model,
            generation_options={"num_predict": min(settings.ollama_num_predict, 512)},
        )
        answer = result.text.strip() if result.complete and result.text else ""
        if not answer:
            await _send_error(
                websocket, session_id, "Nabi chưa thể trả lời trọn vẹn. Bạn thử hỏi lại nhé."
            )
            return
    except (
        OllamaTimeoutError,
        OllamaUnavailableError,
        OllamaContextLimitError,
        OllamaInvalidResponseError,
    ):
        await _send_error(
            websocket, session_id, "Nabi chưa thể trả lời lúc này. Bạn thử lại sau nhé."
        )
        return
    except Exception:
        await _send_error(
            websocket, session_id, "Nabi chưa thể trả lời lúc này. Bạn thử lại sau nhé."
        )
        return

    try:
        output_packets = await synthesize_audio(settings, answer)
    except Exception:
        await _send_error(
            websocket, session_id, "Nabi chưa thể tạo tiếng nói lúc này. Bạn thử lại nhé."
        )
        return

    await _send_json(websocket, {"session_id": session_id, "type": "stt", "text": transcript})
    await _send_json(websocket, {"session_id": session_id, "type": "tts", "state": "start"})
    await _send_json(
        websocket,
        {"session_id": session_id, "type": "tts", "state": "sentence_start", "text": answer},
    )
    for packet in output_packets:
        await websocket.send_bytes(_wrap_v3_opus_frame(packet))
    await _send_json(websocket, {"session_id": session_id, "type": "tts", "state": "stop"})

    history.extend(
        (
            {"role": "user", "content": transcript[:MAX_TURN_TEXT_CHARS]},
            {"role": "assistant", "content": answer[:MAX_TURN_TEXT_CHARS]},
        )
    )
    if len(history) > MAX_HISTORY_MESSAGES:
        del history[: len(history) - MAX_HISTORY_MESSAGES]


async def _maintain_session(
    websocket: WebSocket, factory: Any, device_id: str, connection_id: str
) -> None:
    try:
        while True:
            await asyncio.sleep(SESSION_HEARTBEAT_SECONDS)
            if not _touch_session(factory, device_id, connection_id):
                await websocket.close(code=4401, reason="device_unbound")
                return
    except (asyncio.CancelledError, RuntimeError, WebSocketDisconnect):
        return


async def serve_voice_websocket(websocket: WebSocket) -> None:
    authorization = websocket.headers.get("authorization", "")
    scheme, _, token = authorization.partition(" ")
    if scheme.casefold() != "bearer" or not token:
        await websocket.close(code=4401, reason="unauthorized")
        return
    if websocket.headers.get("protocol-version") != "3":
        await websocket.close(code=4400, reason="protocol_version_required")
        return

    factory = websocket.app.state.session_factory
    with factory() as db:
        authenticated = _active_token(db, token)
        db.rollback()
    if authenticated is None:
        await websocket.close(code=4401, reason="unauthorized")
        return
    device_id, owner_id = authenticated
    connection_id = uuid4().hex
    if not _acquire_session(factory, device_id, connection_id):
        await websocket.close(code=4409, reason="device_already_connected")
        return

    await websocket.accept()
    session_id = uuid4().hex
    history: list[VoiceHistoryMessage] = []
    audio_packets: list[bytes] = []
    listening = False
    audio_bytes = 0
    over_limit = False
    heartbeat = asyncio.create_task(_maintain_session(websocket, factory, device_id, connection_id))
    try:
        await _send_json(
            websocket,
            {
                "type": "hello",
                "transport": "websocket",
                "session_id": session_id,
                "audio_params": {
                    "format": "opus",
                    "sample_rate": OUTPUT_SAMPLE_RATE,
                    "channels": 1,
                    "frame_duration": 60,
                },
            },
        )
        while True:
            message = await websocket.receive()
            if message["type"] == "websocket.disconnect":
                return
            raw_text = message.get("text")
            if raw_text is not None:
                if len(raw_text) > 4_096:
                    await websocket.close(code=4400, reason="message_too_large")
                    return
                try:
                    body = json.loads(raw_text)
                except (json.JSONDecodeError, TypeError):
                    continue
                if not isinstance(body, dict):
                    continue
                kind = body.get("type")
                state = body.get("state")
                if kind == "hello":
                    continue
                if kind == "abort":
                    listening = False
                    over_limit = False
                    audio_packets.clear()
                    audio_bytes = 0
                    continue
                if kind == "nabi.control":
                    action = body.get("action")
                    request_id = body.get("request_id")
                    if action not in {"listen.start", "listen.stop"} or not isinstance(
                        request_id, str
                    ):
                        continue
                    await _send_json(
                        websocket,
                        {
                            "type": "nabi.control_ack",
                            "request_id": request_id[:64],
                            "action": action,
                            "status": "accepted",
                        },
                    )
                    state = "start" if action == "listen.start" else "stop"
                    kind = "listen"
                if kind != "listen":
                    continue
                if state == "start":
                    listening = True
                    over_limit = False
                    audio_packets.clear()
                    audio_bytes = 0
                    continue
                if state == "stop" and listening:
                    listening = False
                    if over_limit:
                        audio_packets.clear()
                        audio_bytes = 0
                        await _send_error(
                            websocket, session_id, "Lượt nghe vượt quá giới hạn 60 giây."
                        )
                        continue
                    packets = tuple(audio_packets)
                    audio_packets.clear()
                    audio_bytes = 0
                    await _answer_turn(
                        websocket,
                        factory=factory,
                        settings=websocket.app.state.settings,
                        owner_id=owner_id,
                        device_id=device_id,
                        connection_id=connection_id,
                        session_id=session_id,
                        packets=packets,
                        history=history,
                    )
                continue

            frame = message.get("bytes")
            if frame is None or not listening or over_limit:
                continue
            packet = _parse_v3_opus_frame(frame)
            if packet is None:
                continue
            audio_bytes += len(packet)
            if len(audio_packets) >= MAX_AUDIO_FRAMES or audio_bytes > 1_500_000:
                over_limit = True
                audio_packets.clear()
                audio_bytes = 0
                continue
            audio_packets.append(packet)
    except WebSocketDisconnect:
        pass
    except Exception as exc:
        logger.warning("voice session ended (%s)", type(exc).__name__)
        with suppress(RuntimeError):
            await websocket.close(code=1011, reason="voice_session_error")
    finally:
        heartbeat.cancel()
        await heartbeat
        _release_session(factory, device_id, connection_id)
