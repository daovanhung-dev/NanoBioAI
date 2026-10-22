from nanobio_backend.core.responses import ApiError


def validate_paid_plan(plan_code: str) -> str:
    normalized = plan_code.strip().casefold()
    if normalized not in {"plus", "family_plus"}:
        raise ApiError(422, "INVALID_MEMBERSHIP_PLAN", "Gói thành viên chưa hợp lệ.")
    return normalized
