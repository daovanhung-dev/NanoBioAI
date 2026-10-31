import re

from nanobio_backend.core.responses import ApiError

_VIET_PHONE = re.compile(r"^[+\d\s().-]+$")
_USERNAME = re.compile(r"^[a-z0-9][a-z0-9._-]{2,31}$", re.IGNORECASE)


def normalize_vietnam_phone(value: str) -> str:
    trimmed = value.strip()
    if not _VIET_PHONE.fullmatch(trimmed):
        raise ApiError(422, "INVALID_PHONE", "Số điện thoại chưa hợp lệ.")
    digits = re.sub(r"\D", "", trimmed)
    if digits.startswith("0084"):
        local = digits[4:]
    elif digits.startswith("84"):
        local = digits[2:]
    elif digits.startswith("0"):
        local = digits[1:]
    else:
        local = ""
    if not re.fullmatch(r"\d{9}", local):
        raise ApiError(422, "INVALID_PHONE", "Số điện thoại chưa hợp lệ.")
    return f"+84{local}"


def normalize_username(value: str) -> str:
    normalized = value.strip().lower()
    if not _USERNAME.fullmatch(normalized):
        raise ApiError(422, "INVALID_USERNAME", "Tên đăng nhập chưa hợp lệ.")
    return normalized


def validate_referral(code: str | None, fingerprint: str | None) -> str | None:
    normalized = code.strip().upper() if code and code.strip() else None
    if normalized and not fingerprint:
        raise ApiError(422, "REFERRAL_DEVICE_MISSING", "Thiếu thông tin thiết bị.")
    return normalized
