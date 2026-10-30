import hashlib
import hmac
import unicodedata
from typing import Any, cast

from fastapi import Request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db.models import AiContentReport, EarlyAccessLead, User
from nanobio_backend.modules.auth.validate import normalize_vietnam_phone
from nanobio_backend.modules.auth.view import consume_rate_limit
from nanobio_backend.modules.edge_api.models import (
    AiGenerateRequest,
    AiGenerateResponseData,
    AiReportRequest,
    EarlyAccessRequest,
    FoodEvidenceRequest,
    GooglePlayVerifyRequest,
)
from nanobio_backend.modules.payments.view import finalize_google_play_purchase
from nanobio_backend.services.food_evidence import lookup_food
from nanobio_backend.services.google_play import (
    GOOGLE_PLAY_PACKAGE_NAME,
    PRODUCT_PLANS,
    GooglePlayProviderError,
    verify_subscription,
)
from nanobio_backend.services.ollama_client import (
    OllamaChatMessage,
    OllamaClient,
    OllamaContextLimitError,
    OllamaInvalidResponseError,
    OllamaTimeoutError,
    OllamaUnavailableError,
)

_ALLOWED_GENDERS = {"male", "female", "other", "prefer_not_to_say"}
_EXPECTED_APK_URL = "https://github.com/daovanhung-dev/NanoBioAI/releases/download/nanobio-early-access-v1.0.1-build4/app-release.apk"
_NABI_AI_SYSTEM_INSTRUCTION = """Bạn là Nabi, trợ lý sức khỏe thông minh và thân thiện.

Vai trò:
- Tư vấn về dinh dưỡng, giấc ngủ, căng thẳng và lối sống lành mạnh.
- Đưa ra gợi ý cá nhân hóa dựa trên thông tin sức khỏe người dùng.
- Luôn lắng nghe, thấu hiểu và trả lời thực tế.

Phong cách:
- Luôn trả lời bằng tiếng Việt có dấu.
- Gọi người dùng là "bạn", tự xưng là "mình".
- Câu trả lời ngắn gọn, dễ hiểu, thường từ 2 đến 4 câu.
- Ưu tiên câu ngắn để phản hồi giọng nói bắt đầu nhanh.
- Không dùng markdown hoặc ký tự trang trí đặc biệt trong câu trả lời.
- Tránh thuật ngữ y khoa phức tạp khi không cần thiết.
- Có giọng thân thiện, ấm áp và chuyên nghiệp.

Nguyên tắc an toàn:
- Không đưa ra chẩn đoán y tế.
- Không thay thế bác sĩ hoặc chuyên gia điều trị.
- Khuyến khích gặp bác sĩ khi triệu chứng nghiêm trọng, kéo dài hoặc bất thường.
- Tập trung vào thói quen sinh hoạt, dinh dưỡng, vận động và nghỉ ngơi.
- Chỉ dùng token kỹ thuật phổ biến khi thật cần thiết, ví dụ AI, BMI, kcal hoặc ml.
"""


def generate_ai(
    payload: AiGenerateRequest,
    request: Request,
    user: User,
    db: Session,
) -> dict[str, Any]:
    settings = request.app.state.settings
    if not settings.ollama_enabled:
        raise ApiError(503, "FEATURE_NOT_ENABLED", "Tính năng này chưa được bật trên máy chủ.")

    rate_limit_key = settings.rate_limit_hmac_key
    if rate_limit_key is None or len(rate_limit_key.get_secret_value()) < 32:
        raise ApiError(503, "AI_NOT_CONFIGURED", "Dịch vụ AI chưa được cấu hình.")
    subject_hash = hmac.new(
        rate_limit_key.get_secret_value().encode(),
        str(user.id).encode(),
        hashlib.sha256,
    ).hexdigest()
    with atomic(db):
        if consume_rate_limit(
            db,
            scope="ai-generate",
            subject_hash=subject_hash,
            limit=settings.ollama_technical_requests_per_minute,
            window_seconds=60,
        ):
            raise ApiError(429, "RATE_LIMITED", "Bạn gửi yêu cầu hơi nhanh. Hãy thử lại sau.")

    messages: list[OllamaChatMessage] = [{"role": "system", "content": _NABI_AI_SYSTEM_INSTRUCTION}]
    for message in payload.messages:
        messages.append({"role": message.role, "content": message.content})
    transport_factory = cast(Any, getattr(request.app.state, "ollama_transport_factory", None))
    try:
        result = OllamaClient(settings, transport_factory=transport_factory).generate(messages)
    except OllamaContextLimitError as exc:
        raise ApiError(
            413,
            "MODEL_CONTEXT_LIMIT_EXCEEDED",
            "Nội dung vượt quá giới hạn xử lý của trợ lý.",
        ) from exc
    except OllamaTimeoutError as exc:
        raise ApiError(504, "AI_TIMEOUT", "Trợ lý phản hồi quá thời gian chờ.") from exc
    except OllamaUnavailableError as exc:
        raise ApiError(503, "AI_UNAVAILABLE", "Trợ lý tạm thời chưa sẵn sàng.") from exc
    except OllamaInvalidResponseError as exc:
        raise ApiError(
            502, "AI_PROVIDER_FAILURE", "Trợ lý chưa thể tạo câu trả lời hợp lệ."
        ) from exc

    return AiGenerateResponseData(
        text=result.text,
        model=settings.ollama_model,
        usage={
            "input_tokens": result.input_tokens,
            "output_tokens": result.output_tokens,
        },
    ).model_dump(by_alias=True)


def register_early_access(
    payload: EarlyAccessRequest, request: Request, db: Session
) -> dict[str, Any]:
    settings = request.app.state.settings
    origin = request.headers.get("origin")
    if not origin or origin not in settings.cors_allowed_origins:
        raise ApiError(403, "ORIGIN_NOT_ALLOWED", "Trang đăng ký hiện không khả dụng.")
    if payload.privacy_consent is not True:
        raise ApiError(422, "CONSENT_REQUIRED", "Bạn cần xác nhận đồng ý trước khi tiếp tục.")
    if payload.gender not in _ALLOWED_GENDERS:
        raise ApiError(422, "INVALID_GENDER", "Vui lòng chọn giới tính hợp lệ.")
    ip = request.client.host if request.client else ""
    rate_key = (
        settings.rate_limit_hmac_key.get_secret_value() if settings.rate_limit_hmac_key else ""
    )
    phone_key = (
        settings.early_access_phone_hmac_key.get_secret_value()
        if settings.early_access_phone_hmac_key
        else ""
    )
    if len(rate_key) < 32 or len(phone_key) < 32 or not ip:
        raise ApiError(
            503, "REGISTRATION_UNAVAILABLE", "Đăng ký tạm thời chưa khả dụng. Vui lòng thử lại sau."
        )
    phone = normalize_vietnam_phone(payload.phone)
    ip_hash = hmac.new(rate_key.encode(), ip.encode(), hashlib.sha256).hexdigest()
    phone_hash = hmac.new(phone_key.encode(), phone.encode(), hashlib.sha256).hexdigest()
    try:
        with atomic(db):
            if consume_rate_limit(
                db, scope="early-access", subject_hash=ip_hash, limit=10, window_seconds=3600
            ):
                raise ApiError(
                    429, "RATE_LIMITED", "Bạn gửi yêu cầu hơi nhanh. Vui lòng thử lại sau."
                )
            existing = db.scalar(
                select(EarlyAccessLead.id).where(EarlyAccessLead.phone_hash == phone_hash)
            )
            if existing is None:
                landing = payload.landing_path or "/"
                if not landing.startswith("/") or landing.startswith("//"):
                    landing = "/"
                safe_meta = {
                    "source": "nanobio_web",
                    "landing_path": landing,
                    "utm_source": payload.utm_source,
                    "utm_medium": payload.utm_medium,
                    "utm_campaign": payload.utm_campaign,
                    "referrer": _safe_referrer(request.headers.get("referer")),
                    "user_agent": (request.headers.get("user-agent") or "")[:512],
                }
                db.add(
                    EarlyAccessLead(
                        phone=phone,
                        phone_hash=phone_hash,
                        full_name=payload.full_name.strip(),
                        age=payload.age,
                        gender=payload.gender,
                        address=payload.address.strip(),
                        consent=True,
                        status="new",
                        promotion_code="EARLY_ACCESS_PLUS_30D",
                        metadata_json=safe_meta,
                    )
                )
                db.flush()
    except IntegrityError:
        # Concurrent duplicate submissions return the same public response.
        pass
    configured_url = settings.early_access_apk_download_url
    download_url = configured_url if configured_url == _EXPECTED_APK_URL else ""
    return {
        "download_url": download_url,
        "download_available": bool(download_url),
        "expires_at": None,
        "app_version": "1.0.1+4",
        "promotion_code": "EARLY_ACCESS_PLUS_30D",
        "vip_plan": "plus",
        "vip_duration_days": 30,
    }


def _safe_referrer(value: str | None) -> str | None:
    if not value or len(value) > 2048 or not value.startswith(("https://", "http://")):
        return None
    return value


def report_ai_content(payload: AiReportRequest, db: Session) -> dict[str, bool]:
    if payload.message_role not in {"assistant", "user"}:
        raise ApiError(422, "INVALID_MESSAGE_ROLE", "Vai trò nội dung báo cáo chưa hợp lệ.")
    with atomic(db):
        db.add(
            AiContentReport(
                message_id=payload.message_id,
                message_role=payload.message_role,
                reason_code=payload.reason_code,
                message_snapshot=payload.message_snapshot,
                app_version=payload.app_version,
                note=payload.note,
                installation_id=payload.installation_id,
            )
        )
    return {"received": True}


def food_evidence(
    payload: FoodEvidenceRequest, request: Request, user: User, db: Session
) -> dict[str, list[dict[str, Any]]]:
    clean: list[str] = []
    seen: set[str] = set()
    for ingredient in payload.ingredients:
        value = ingredient.strip()
        if not value or len(value) > 120:
            raise ApiError(422, "INVALID_INGREDIENT", "Tên thực phẩm chưa hợp lệ.")
        key = unicodedata.normalize("NFKC", value).casefold()
        if key not in seen:
            seen.add(key)
            clean.append(value)
    if not clean:
        raise ApiError(422, "INVALID_INGREDIENTS", "Cần có ít nhất một thực phẩm.")
    user_hash = hashlib.sha256(str(user.id).encode()).hexdigest()
    with atomic(db):
        if consume_rate_limit(
            db, scope="food-evidence", subject_hash=user_hash, limit=12, window_seconds=3600
        ):
            raise ApiError(429, "RATE_LIMITED", "Bạn đã tra cứu quá nhiều lần. Hãy thử lại sau.")
    api_key = request.app.state.settings.usda_api_key
    usda_key = api_key.get_secret_value() if api_key else None
    try:
        foods = [lookup_food(item, usda_key) for item in clean]
    except RuntimeError as exc:
        raise ApiError(
            503, "FOOD_SOURCE_UNAVAILABLE", "Nguồn dữ liệu thực phẩm tạm thời chưa khả dụng."
        ) from exc
    return {"foods": foods}


def verify_google_play_purchase(
    payload: GooglePlayVerifyRequest, request: Request, user: User, db: Session
) -> dict[str, str | None]:
    settings = request.app.state.settings
    if payload.package_name != GOOGLE_PLAY_PACKAGE_NAME:
        raise ApiError(400, "PACKAGE_MISMATCH", "Ứng dụng không khớp với giao dịch.")
    if payload.product_id not in PRODUCT_PLANS:
        raise ApiError(400, "INVALID_PRODUCT", "Gói đăng ký không hợp lệ.")
    if (
        settings.google_play_package_name != GOOGLE_PLAY_PACKAGE_NAME
        or settings.google_play_service_account_json is None
    ):
        raise ApiError(503, "PAYMENT_PROVIDER_UNAVAILABLE", "Chưa thể xác minh giao dịch lúc này.")
    try:
        snapshot = verify_subscription(
            settings.google_play_service_account_json.get_secret_value(),
            payload.package_name,
            payload.product_id,
            payload.purchase_token,
        )
        return finalize_google_play_purchase(
            db,
            user=user,
            package_name=payload.package_name,
            product_id=payload.product_id,
            purchase_token=payload.purchase_token,
            snapshot=snapshot,
        )
    except GooglePlayProviderError as exc:
        raise ApiError(
            502,
            "PURCHASE_VERIFICATION_PENDING",
            "Chưa thể xác minh giao dịch với Google Play. Bạn hãy thử lại sau.",
            meta={"retryable": True},
        ) from exc
