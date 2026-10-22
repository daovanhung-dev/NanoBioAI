from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from nanobio_backend.api.v1.router import router as api_v1_router
from nanobio_backend.core.config import Settings, get_settings
from nanobio_backend.core.database import create_session_factory
from nanobio_backend.core.middleware import TraceMiddleware, register_exception_handlers
from nanobio_backend.core.responses import ApiError


def create_app(
    settings: Settings | None = None,
    *,
    session_factory: sessionmaker[Session] | None = None,
    engine: Engine | None = None,
) -> FastAPI:
    resolved_settings = settings or get_settings()
    owned_engine = engine
    if session_factory is None:
        owned_engine, session_factory = create_session_factory(resolved_settings)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        yield
        if owned_engine is not None:
            owned_engine.dispose()

    app = FastAPI(title=resolved_settings.app_name, version="0.1.0", lifespan=lifespan)
    app.state.settings = resolved_settings
    app.state.session_factory = session_factory
    app.add_middleware(TraceMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=resolved_settings.cors_allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "X-Trace-Id", "Idempotency-Key"],
        expose_headers=["X-Trace-Id"],
    )
    register_exception_handlers(app)
    app.include_router(api_v1_router, prefix=resolved_settings.api_v1_prefix)

    @app.get("/health/live", tags=["health"])
    def live() -> dict[str, str]:
        return {"status": "live"}

    @app.get("/health/ready", tags=["health"])
    def ready() -> dict[str, str]:
        try:
            with session_factory() as session:
                session.execute(text("SELECT 1"))
        except Exception as exc:
            raise ApiError(503, "DEPENDENCY_UNAVAILABLE", "Cơ sở dữ liệu chưa sẵn sàng.") from exc
        return {"status": "ready", "database": "ready"}

    return app


app: Any = create_app()
