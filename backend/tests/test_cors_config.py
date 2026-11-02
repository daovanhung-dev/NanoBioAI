import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from nanobio_backend.core.config import Settings
from nanobio_backend.main import create_app

ADMIN_WEB_ORIGIN = "https://daovanhung-dev.github.io"


def test_env_example_allows_the_exact_admin_web_origin() -> None:
    env_example = Path(__file__).parents[1] / ".env.example"
    values = {
        line.split("=", 1)[0]: line.split("=", 1)[1]
        for line in env_example.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#") and "=" in line
    }

    origins = json.loads(values["CORS_ALLOWED_ORIGINS"])

    assert ADMIN_WEB_ORIGIN in origins
    assert "*" not in origins


@pytest.mark.parametrize(
    ("origin", "expected_status", "expected_allow_origin"),
    [
        (ADMIN_WEB_ORIGIN, 200, ADMIN_WEB_ORIGIN),
        ("https://unlisted.example", 400, None),
    ],
)
def test_cors_preflight_uses_an_exact_origin_allowlist(
    db_factory,
    origin: str,
    expected_status: int,
    expected_allow_origin: str | None,
) -> None:
    app = create_app(
        Settings(cors_allowed_origins=[ADMIN_WEB_ORIGIN]),
        session_factory=db_factory,
    )
    with TestClient(app) as client:
        response = client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": origin,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )

    assert response.status_code == expected_status
    assert response.headers.get("access-control-allow-origin") == expected_allow_origin
