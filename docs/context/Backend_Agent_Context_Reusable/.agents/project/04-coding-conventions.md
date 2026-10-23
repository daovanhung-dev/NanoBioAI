# Coding Rules — Python Backend

## Style

- UTF-8, LF, final newline, no trailing spaces, Python indent 4.
- `snake_case` modules/functions/variables; `PascalCase` classes/Pydantic; `UPPER_SNAKE_CASE` constants.
- Type hints trên public APIs và nontrivial helpers; `mypy --strict` cho new code; tránh `Any` lan rộng.
- Ruff `E,F,I,B,UP,SIM`; line-length 100; double quotes; import sort tự động nhưng không sửa file ngoài scope.
- Constructor/DI rõ ràng; không tạo hidden global mutable state; lazy settings/factories được kiểm soát.
- Nếu SQL viết bằng text(), luôn đặt named parameters và type-safe outputs; không lắp chuỗi SQL từ input.
- Một function giải quyết một trách nhiệm. Chỉ tách abstractions khi mang lại lợi ích thực, tránh `ServiceFactoryManager` không cần thiết.

## Module 4-layer convention

| File | Allowed | Forbidden |
|---|---|---|
| `models.py` | Pydantic fields, validators pure, serialization | DB lookup, external calls |
| `validate.py` | named pure special business-format checks | SQL, time-dependent calls, `ApiError` HTTP effects |
| `query.py` | SQL constants/query functions, query results | `commit`, HTTP response, auth decisions |
| `view.py` | orchestration, authZ, errors, transactions | defining raw request schema, concatenating unsafe SQL |
| `api/v1.py` | route/DI/body/header/query binding | core business flow, DB SQL |

- Shared pure validations nằm ở `app/utils/validate.py`; giữ module-specific tại module trừ khi thực sự reuse.
- `models.py` là tên canonical cho dự án mới; không trộn `model.py` hoặc `schema.py` tùy từng module.
- Không invent rule email domain, password format, case-folding name, status defaults nếu contract không có.

## Comments, errors và naming

- Module/service docstrings mô tả intent/side effects/contract; comment chỉ cho logic khó hiểu hoặc business reason.
- Nếu team giữ API header: `# API POST /api/v1/example` ngay trên handler; không gắn cho helper.
- Không dùng catch-all `except Exception` sâu trong domain để giấu bug; chỉ error boundary xử lý lỗi không xác định.
- Không dùng `assert` làm user validation, không bỏ qua exception, không log password/token/raw email/body mặc định.
- APIs mới tuân `contracts` trong repo mới; tránh hardcode business-code prefix `DESIGN_` từ Study2Work.

## PR hygiene

- Diff tối thiểu, độc lập; không sửa whitespace toàn repo; tests cập nhật theo feature.
- Schema/API breaking change phải có rollout, migration/backward compatibility/documentation.
- Không commit generated caches (`__pycache__`, `.venv`, `.pytest_cache`, `.mypy_cache`), credentials, `.env`, DB dumps, log sensitive.
