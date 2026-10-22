from typing import Any

from nanobio_backend.core.responses import ApiError


def parse_payment_configuration(settings: Any) -> tuple[dict[str, Any], dict[str, str]]:
    import json

    if not settings.membership_payment_prices_json or not settings.membership_payment_bank_json:
        raise ApiError(
            503,
            "MEMBERSHIP_PAYMENT_NOT_CONFIGURED",
            "Thanh toán chuyển khoản chưa được cấu hình.",
        )
    try:
        prices = json.loads(settings.membership_payment_prices_json)
        bank = json.loads(settings.membership_payment_bank_json.get_secret_value())
    except (ValueError, TypeError) as exc:
        raise ApiError(
            503,
            "MEMBERSHIP_PAYMENT_NOT_CONFIGURED",
            "Thanh toán chuyển khoản chưa được cấu hình.",
        ) from exc
    if not isinstance(prices, dict) or not isinstance(bank, dict):
        raise ApiError(503, "MEMBERSHIP_PAYMENT_NOT_CONFIGURED", "Thanh toán chưa được cấu hình.")
    required = {
        "bank_code",
        "bank_name",
        "bank_bin",
        "bank_account_number",
        "bank_account_name",
        "bank_account_display_name",
    }
    normalized_bank = {key: str(bank.get(key, "")).strip() for key in required}
    if (
        not all(normalized_bank.values())
        or len(normalized_bank["bank_bin"]) != 6
        or not normalized_bank["bank_bin"].isdigit()
        or not normalized_bank["bank_account_number"].isdigit()
        or not 4 <= len(normalized_bank["bank_account_number"]) <= 32
    ):
        raise ApiError(503, "MEMBERSHIP_PAYMENT_NOT_CONFIGURED", "Thanh toán chưa được cấu hình.")
    return prices, normalized_bank
