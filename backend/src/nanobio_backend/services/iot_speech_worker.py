"""Loopback-only STT/TTS worker for Nabi ESP voice sessions.

The service keeps audio and recognized text in process memory only. It does
not write temporary audio files or log request content.
"""

# mypy: disable-error-code="import-not-found,import-untyped"
from __future__ import annotations

import base64
import logging
import os
import secrets
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path
from threading import Lock
from typing import Annotated

import numpy as np
from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, ConfigDict, Field

logger = logging.getLogger("nanobio.iot.speech_worker")
logging.getLogger("faster_whisper").setLevel(logging.WARNING)
logging.getLogger("piper").setLevel(logging.WARNING)

MAX_REQUEST_BYTES = 2_000_000
MAX_RESPONSE_SECONDS = 30
INPUT_RATE = 16_000
OUTPUT_RATE = 24_000
FRAME_SAMPLES = 1_440

_model_lock = Lock()
_transcribe_lock = Lock()
_synthesize_lock = Lock()
_whisper_model = None
_piper_voice = None


class TranscribeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    frames: list[Annotated[str, Field(max_length=2_732)]] = Field(min_length=1, max_length=1_024)


class SynthesizeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)
    text: str = Field(min_length=1, max_length=2_000)


class SynthesizeResponse(BaseModel):
    sample_rate: int
    frames: list[str]


def _worker_token() -> str:
    return os.environ.get("IOT_SPEECH_WORKER_TOKEN", "")


def _verify_worker_token(
    token: str | None = Header(default=None, alias="X-Nabi-Worker-Token"),
) -> None:
    expected = _worker_token()
    if len(expected) < 32:
        raise HTTPException(status_code=503, detail="worker_not_configured")
    if token is None or not secrets.compare_digest(token, expected):
        raise HTTPException(status_code=401, detail="unauthorized")


def _load_models() -> None:
    global _whisper_model, _piper_voice
    if _whisper_model is not None and _piper_voice is not None:
        return
    with _model_lock:
        if _whisper_model is not None and _piper_voice is not None:
            return
        from faster_whisper import WhisperModel
        from piper import PiperVoice

        cache_dir = Path(os.environ.get("IOT_MODEL_CACHE", "/var/lib/nanobio-iot/models"))
        cache_dir.mkdir(parents=True, exist_ok=True)
        whisper_name = os.environ.get("IOT_WHISPER_MODEL", "small")
        voice_path = Path(
            os.environ.get(
                "IOT_PIPER_VOICE",
                str(cache_dir / "vi_VN-vais1000-medium.onnx"),
            )
        )
        if not voice_path.is_file():
            raise FileNotFoundError("configured Piper voice is not installed")
        logger.info("loading speech models")
        _whisper_model = WhisperModel(
            whisper_name,
            device="cpu",
            compute_type="int8",
            download_root=str(cache_dir),
        )
        _piper_voice = PiperVoice.load(str(voice_path), use_cuda=False)
        logger.info("speech models ready")


@asynccontextmanager
async def _lifespan(_: FastAPI) -> AsyncIterator[None]:
    try:
        import asyncio

        await asyncio.to_thread(_load_models)
    except Exception as exc:
        logger.error("speech model initialization failed (%s)", type(exc).__name__)
        raise
    yield


app = FastAPI(title="NanoBio Nabi Speech Worker", lifespan=_lifespan)


@app.get("/health")
def health(_: None = Depends(_verify_worker_token)) -> dict[str, str]:
    if _whisper_model is None or _piper_voice is None:
        raise HTTPException(status_code=503, detail="not_ready")
    return {"status": "ready"}


@app.post("/v1/transcribe")
def transcribe(
    payload: TranscribeRequest,
    _: None = Depends(_verify_worker_token),
) -> dict[str, str]:
    try:
        import opuslib

        _load_models()
        decoder = opuslib.Decoder(INPUT_RATE, 1)
        pcm_parts: list[bytes] = []
        total_bytes = 0
        for encoded in payload.frames:
            frame = base64.b64decode(encoded, validate=True)
            total_bytes += len(frame)
            if not frame or len(frame) > 2_048 or total_bytes > MAX_REQUEST_BYTES:
                raise ValueError("audio_limit")
            pcm_parts.append(decoder.decode(frame, frame_size=5_760, decode_fec=False))
        pcm16 = np.frombuffer(b"".join(pcm_parts), dtype="<i2")
        if pcm16.size == 0 or pcm16.size > INPUT_RATE * 60:
            raise ValueError("audio_limit")
        audio = pcm16.astype(np.float32) / 32_768.0
        assert _whisper_model is not None
        with _transcribe_lock:
            segments, _ = _whisper_model.transcribe(
                audio,
                language="vi",
                beam_size=1,
                condition_on_previous_text=False,
                vad_filter=True,
            )
            transcript = " ".join(segment.text.strip() for segment in segments).strip()
        return {"text": transcript[:2_000]}
    except (ValueError, TypeError) as exc:
        raise HTTPException(status_code=422, detail="invalid_audio") from exc
    except Exception as exc:
        logger.warning("transcription failed (%s)", type(exc).__name__)
        raise HTTPException(status_code=503, detail="stt_unavailable") from exc


@app.post("/v1/synthesize", response_model=SynthesizeResponse)
def synthesize(
    payload: SynthesizeRequest,
    _: None = Depends(_verify_worker_token),
) -> SynthesizeResponse:
    try:
        import opuslib

        _load_models()
        assert _piper_voice is not None
        with _synthesize_lock:
            chunks = list(_piper_voice.synthesize(payload.text))
        pcm_parts = [chunk.audio_int16_bytes for chunk in chunks]
        source = np.frombuffer(b"".join(pcm_parts), dtype="<i2")
        source_rate = int(_piper_voice.config.sample_rate)
        if source.size == 0 or source_rate <= 0:
            raise ValueError("empty_audio")
        target_size = round(source.size * OUTPUT_RATE / source_rate)
        positions = np.arange(target_size, dtype=np.float64) * source_rate / OUTPUT_RATE
        resampled = np.interp(
            positions,
            np.arange(source.size, dtype=np.float64),
            source.astype(np.float32),
        )
        if resampled.size > OUTPUT_RATE * MAX_RESPONSE_SECONDS:
            raise ValueError("response_limit")
        pcm24 = np.clip(resampled, -32_768, 32_767).astype("<i2")
        encoder = opuslib.Encoder(OUTPUT_RATE, 1, opuslib.APPLICATION_AUDIO)
        encoder.bitrate = 24_000
        frames: list[str] = []
        for offset in range(0, pcm24.size, FRAME_SAMPLES):
            chunk = np.zeros(FRAME_SAMPLES, dtype="<i2")
            available = min(FRAME_SAMPLES, pcm24.size - offset)
            chunk[:available] = pcm24[offset : offset + available]
            packet = encoder.encode(chunk.tobytes(), FRAME_SAMPLES)
            frames.append(base64.b64encode(packet).decode("ascii"))
        if not frames:
            raise ValueError("empty_audio")
        return SynthesizeResponse(sample_rate=OUTPUT_RATE, frames=frames)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail="speech_limit") from exc
    except Exception as exc:
        logger.warning("speech synthesis failed (%s)", type(exc).__name__)
        raise HTTPException(status_code=503, detail="tts_unavailable") from exc
