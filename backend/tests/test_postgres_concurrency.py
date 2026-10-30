"""Optional PostgreSQL integration coverage for row-lock concurrency."""

import os
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4

import pytest
from argon2 import PasswordHasher
from pydantic import SecretStr
from sqlalchemy import create_engine, select
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from nanobio_backend.core.config import Settings
from nanobio_backend.core.responses import ApiError
from nanobio_backend.core.uow import atomic
from nanobio_backend.db import models  # noqa: F401
from nanobio_backend.db.base import Base
from nanobio_backend.db.models import ManualPaymentEvent, RateLimitBucket, User
from nanobio_backend.modules.auth.view import consume_rate_limit
from nanobio_backend.modules.payments.view import create_manual_membership_payment


@pytest.mark.skipif(
    not os.getenv("NANOBIO_TEST_DATABASE_URL"),
    reason="NANOBIO_TEST_DATABASE_URL must point to an isolated disposable PostgreSQL database",
)
def test_concurrent_open_payment_requests_serialize_on_owner_row() -> None:
    database_url = os.environ["NANOBIO_TEST_DATABASE_URL"]
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
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, expire_on_commit=False)
    user_id = uuid4()
    settings = Settings(
        database_url=database_url,
        membership_payment_prices_json=('{"currency":"VND","prices":{"plus":{"monthly":1000}}}'),
        membership_payment_bank_json=SecretStr(
            '{"bank_code":"TST","bank_name":"Test Bank","bank_bin":"999999",'
            '"bank_account_number":"12345678","bank_account_name":"TEST",'
            '"bank_account_display_name":"Test Account"}'
        ),
    )
    with factory() as db:
        db.add(
            User(
                id=user_id,
                phone=f"+849{uuid4().int % 100_000_000:08d}",
                full_name="Concurrency Test",
                password_hash=PasswordHasher().hash("unused"),
            )
        )
        db.commit()

    def create_request(index: int) -> str:
        try:
            with factory() as db:
                user = db.get(User, user_id)
                assert user is not None
                create_manual_membership_payment(
                    db,
                    user,
                    settings,
                    plan_code="plus",
                    billing_cycle="monthly",
                    idempotency_key=f"parallel-request-{index}",
                    payer_full_name="Concurrency Test",
                )
            return "created"
        except ApiError as exc:
            return exc.business_code

    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            outcomes = list(pool.map(create_request, (1, 2)))
        assert sorted(outcomes) == ["MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN", "created"]
        with factory() as db:
            rows = db.scalars(
                select(ManualPaymentEvent).where(ManualPaymentEvent.user_id == user_id)
            ).all()
            assert len(rows) == 1
    finally:
        with factory() as db:
            user = db.get(User, user_id)
            if user is not None:
                db.delete(user)
                db.commit()
        Base.metadata.drop_all(engine)
        engine.dispose()


@pytest.mark.skipif(
    not os.getenv("NANOBIO_TEST_DATABASE_URL"),
    reason="NANOBIO_TEST_DATABASE_URL must point to an isolated disposable PostgreSQL database",
)
def test_concurrent_ai_rate_limit_requests_do_not_lose_bucket_updates() -> None:
    database_url = os.environ["NANOBIO_TEST_DATABASE_URL"]
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
    engine = create_engine(database_url, pool_size=8, max_overflow=0)
    Base.metadata.create_all(engine)
    factory = sessionmaker(bind=engine, expire_on_commit=False)
    scope = f"ai-generate-test-{uuid4()}"
    subject_hash = uuid4().hex

    def consume_request() -> bool:
        with factory() as db, atomic(db):
            return consume_rate_limit(
                db,
                scope=scope,
                subject_hash=subject_hash,
                limit=6,
                window_seconds=3600,
            )

    try:
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(lambda _: consume_request(), range(12)))
        assert results.count(False) == 6
        assert results.count(True) == 6
        with factory() as db:
            bucket = db.scalar(
                select(RateLimitBucket).where(
                    RateLimitBucket.scope == scope,
                    RateLimitBucket.subject_hash == subject_hash,
                )
            )
            assert bucket is not None
            assert bucket.hits == 12
            db.delete(bucket)
            db.commit()
    finally:
        Base.metadata.drop_all(engine)
        engine.dispose()
