# Database, Queries, Transactions & Migrations

## Session / unit of work

- Baseline: SQLAlchemy 2.x **synchronous** Engine + `sessionmaker(autoflush=False, expire_on_commit=False)`.
- `get_db()` tạo 1 Session per request, đóng ở `finally`.
- `query.py` dùng Session từ caller; `execute_query/query_one/query_many` **không gọi commit**.
- `view.py`/use-case chịu trách nhiệm `commit()` sau khi toàn bộ business invariants thỏa; `rollback()` khi lỗi. Có thể dùng `with db.begin():` theo convention thống nhất.
- Không giữ transaction lâu trong lúc gọi provider HTTP, xử lý AI hoặc upload; cân nhắc outbox/saga khi cross-system cần độ bền.
- `pool_pre_ping`, pool sizing, statement timeout, connection disposal theo môi trường. Không tự áp `search_path` nếu driver/pooler không hỗ trợ; xác minh schema thực tế.

## SQL

```python
# query.py — chỉ ví dụ, không phải schema thật của project
from sqlalchemy import text
from sqlalchemy.orm import Session

def get_widget_by_id(db: Session, widget_id: int):
    result = db.execute(
        text("SELECT id, name FROM widgets WHERE id = :widget_id"),
        {"widget_id": widget_id},
    )
    row = result.mappings().first()
    return dict(row) if row is not None else None
```

- SQL bind values; **không** f-string user input vào SQL text. For sort/column/table names use explicit allowlist / SQLAlchemy identifiers (không thể param identifiers).
- DB constraints: PK/FK/unique/check/NOT NULL/index; don't rely on Pydantic for persistence integrity.
- Truy vấn theo tenant/owner nếu app có tenancy; phải được enforce ngay SQL/transaction; audit các route.
- Tối ưu sau khi đo: EXPLAIN ANALYZE, índices theo predicate+join, keyset pagination nếu cần, tránh N+1, không select `*` dữ liệu nhạy cảm.

## Migration protocol (cho repo mới)

1. Mỗi schema change cần migration versioned và reviewable trong `migrations/versions/`.
2. Thử migrate DB disposable **từ rỗng**; với DB chứa data thử upgrade + backup/rollback/restore plan.
3. Destructive change dùng expand -> backfill -> contract, tránh drop columns đang chạy.
4. Không tự chạy migration trên production; xác nhận backup, rollout plan và owner.
5. Seed/test data tách khỏi migration schema; tuyệt đối không đưa credential thực vào seed.
6. Contract schema live chỉ VERIFIED sau khi query metadata/migrations (authorized, read-only), không suy luận từ DDL file.

## Transaction & concurrency

- Unique conflict: app precheck giúp UX nhưng unique index là nguồn bảo vệ thực; map race `IntegrityError` -> 409 có kiểm soát.
- Multi-step writes atomic trong cùng DB transaction.
- Refresh token rotation dùng conditional update/row lock hoặc compare-and-swap + insert dưới cùng transaction; có test concurrent replay.
- Khi cần distributed idempotency, đảm bảo database uniqueness + atomic state transition.

## SQLAlchemy sync vs async

Nếu `SYNC`: dùng `def` route handlers hoặc chạy blocking work trong threadpool có quản lý. Nếu `ASYNC`: async driver, AsyncSession, await I/O xuyên suốt, và ghi ADR. Không `await` query của sync Session và không trực tiếp block event loop trong `async def`.
