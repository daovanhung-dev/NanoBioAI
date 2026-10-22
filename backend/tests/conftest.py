import os
from collections.abc import Iterator
from pathlib import Path
from tempfile import TemporaryDirectory

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr
from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from nanobio_backend.core.config import Settings
from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.base import Base
from nanobio_backend.main import create_app


@pytest.fixture
def db_factory() -> Iterator[sessionmaker[Session]]:
    database_url = os.getenv("NANOBIO_TEST_DATABASE_URL")
    if database_url:
        parsed_url = make_url(database_url)
        if (
            not parsed_url.drivername.startswith("postgresql")
            or parsed_url.host not in {"127.0.0.1", "localhost", "::1"}
            or "test" not in (parsed_url.database or "").casefold()
        ):
            pytest.fail(
                "NANOBIO_TEST_DATABASE_URL must be a disposable loopback PostgreSQL database "
                "whose name contains 'test'"
            )
        engine = create_engine(database_url, pool_size=5, max_overflow=0)
    else:
        engine = create_engine(
            "sqlite+pysqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
    yield factory
    try:
        Base.metadata.drop_all(engine)
    finally:
        engine.dispose()


@pytest.fixture
def runtime(db_factory: sessionmaker[Session]):
    with TemporaryDirectory() as temporary:
        settings = Settings(
            jwt_secret_key=SecretStr("test-only-signing-secret-32-characters-long"),
            rate_limit_hmac_key=SecretStr("test-only-rate-limit-secret-32-characters"),
            early_access_phone_hmac_key=SecretStr("test-only-phone-hmac-secret-32-characters"),
            upload_root=Path(temporary) / "uploads",
            cors_allowed_origins=["https://example.test"],
            google_play_package_name="com.nanobioai.app",
            google_play_service_account_json=SecretStr("{}"),
        )
        app = create_app(settings, session_factory=db_factory)
        with TestClient(app) as client:
            yield client, db_factory, settings
