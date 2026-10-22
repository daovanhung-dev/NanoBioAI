from typing import Any
from uuid import uuid4

from fastapi import Request
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(
        self,
        status_code: int,
        business_code: str,
        message: str,
        *,
        meta: dict[str, Any] | None = None,
    ) -> None:
        self.status_code = status_code
        self.business_code = business_code
        self.message = message
        self.meta = meta or {}


def success_response(
    request: Request,
    data: Any,
    *,
    business_code: str = "RESOURCE_RETRIEVED",
    message: str = "OK",
    status_code: int = 200,
    meta: dict[str, Any] | None = None,
) -> JSONResponse:
    trace_id = getattr(request.state, "trace_id", str(uuid4()))
    return JSONResponse(
        status_code=status_code,
        headers={"X-Trace-Id": trace_id},
        content={
            "success": True,
            "businessCode": business_code,
            "message": message,
            "data": data,
            "meta": meta or {},
            "traceId": trace_id,
        },
    )


def error_payload(request: Request, error: ApiError) -> dict[str, Any]:
    return {
        "success": False,
        "businessCode": error.business_code,
        "message": error.message,
        "data": None,
        "meta": error.meta,
        "traceId": getattr(request.state, "trace_id", str(uuid4())),
    }
