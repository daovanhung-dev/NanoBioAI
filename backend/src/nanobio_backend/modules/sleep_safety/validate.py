from nanobio_backend.modules.auth.validate import normalize_vietnam_phone


def validate_code(code: str | None) -> bool:
    return code is not None and len(code) == 6 and code.isascii() and code.isdigit()


def normalize_contact_phone(value: str) -> str:
    return normalize_vietnam_phone(value)
