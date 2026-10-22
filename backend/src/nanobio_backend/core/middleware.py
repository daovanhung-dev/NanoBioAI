import logging
from uuid import UUID, uuid4

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from nanobio_backend.core.responses import ApiError, error_payload

logger = logging.getLogger("nanobio.api")


class TraceMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        supplied = request.headers.get("X-Trace-Id", "")
        try:
            trace_id = str(UUID(supplied))
        except (ValueError, AttributeError):
            trace_id = str(uuid4())
        request.state.trace_id = trace_id
        response = await call_next(request)
        response.headers["X-Trace-Id"] = trace_id
        return response


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def api_error_handler(request: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            headers={"X-Trace-Id": request.state.trace_id},
            content=error_payload(request, exc),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        fields = [
            {"field": ".".join(str(part) for part in item["loc"]), "code": item["type"]}
            for item in exc.errors()
        ]
        error = ApiError(
            422, "VALIDATION_ERROR", "Dữ liệu đầu vào không hợp lệ.", meta={"fieldErrors": fields}
        )
        return JSONResponse(
            status_code=422,
            headers={"X-Trace-Id": request.state.trace_id},
            content=error_payload(request, error),
        )

    @app.exception_handler(Exception)
    async def unexpected_error_handler(request: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled request failure trace_id=%s", request.state.trace_id)
        error = ApiError(500, "INTERNAL_SERVER_ERROR", "Đã xảy ra lỗi hệ thống.")
        return JSONResponse(
            status_code=500,
            headers={"X-Trace-Id": request.state.trace_id},
            content=error_payload(request, error),
        )
