# Backend Agent Router — MANDATORY ENTRY

Dành cho AI coding agent làm việc trong **repository backend hiện tại**. Đừng tự mặc định đây là Study2Work.

## 0. Session preflight (bắt buộc, không bypass)

1. Đọc `AGENTS.md` (file này) -> `.agents/AGENTS.md` -> `.agents/context-map.md`.
2. Phân loại và ghi ngắn:
   ```yaml
   primary_task_type: coding | fix | docs | test | refactor | operations
   affected_modules: []
   cross_module_contracts: []
   requirement_source: "path / user request / ticket"
   ```
3. Chạy `python3 scripts/select_worklogs.py --type <primary_task_type> --limit 3`; **đọc thực sự** các log được chọn; nếu chưa có log thì ghi `shortage`, không bịa.
4. Đọc `.agents/project/INDEX.md`, rồi chỉ các file context liên quan đến task.
5. Trước sửa code, đọc source + tests + config + schema/migrations có liên quan trong repo hiện tại.

## 1. Source-of-truth order

1. Yêu cầu mới nhất của user, đã làm rõ business behavior và acceptance criteria.
2. Canonical API/domain contract **đã phê duyệt của dự án mới**.
3. Current implementation + verified runnable tests + executable config/schema.
4. Context `.agents/` của **dự án mới**.
5. Template/best practice chung.

Phải tách `EXPECTED_BEHAVIOR` vs `CURRENT_BEHAVIOR`. Khi lệch: ghi `DISCREPANCY`, không âm thầm thay contract hoặc khẳng định source là chuẩn.

## 2. Coding rules — MUST

- `app/main.py` compose FastAPI; router chỉ parse/request/DI; business ở `view.py`; parameterized SQL ở `query.py`; Pydantic contract ở `models.py`; `validate.py` chỉ chứa pure special rules.
- Các helper `core/` là infrastructure shared; helper `utils/` chỉ pure/reusable; external integration ở `services/`.
- Không tự sáng tác field/table/endpoint/role/business rule/HTTP status. Thiếu evidence: đề xuất rõ `ASSUMPTION` và ưu tiên yêu cầu/contract trước coding.
- Truy dấu: caller -> callee -> DB/external side effect -> response -> tests trước khi sửa một function có ảnh hưởng.
- Mọi truy vấn DB bind parameters. Không nối SQL từ request. Identifier động chỉ từ allowlist hoặc SQLAlchemy constructs an toàn.
- Session thuộc request/unit of work; **một owner của commit/rollback** trong use case. Helpers không commit.
- Thực thi authentication/authorization phía server; không dựa vào ẩn nút trên UI. Không ghi log secret/PII/sensitive bodies.
- Giữ nhất quán `success, businessCode, message, data, meta, traceId`; propagate `X-Trace-Id`; không rò internal exceptions.
- Thêm regression/happy-path/negative tests đúng mức; không sửa test chỉ để hợp thức hóa bug.
- Smallest necessary diff, không refactor scope khác; không thêm dependency khi chưa có lý do, license/safety review.
- API-facing handler có header comment ngắn `# API <method> <path>` ngay trước function nếu team đã chọn convention; comments theo *current behavior*, không tự sửa DD bằng comment.

## 3. Output contract của mỗi task

```text
SCOPE: ...
EVIDENCE_READ: ...
EXPECTED_BEHAVIOR: ...
CURRENT_BEHAVIOR: ...
CHANGE: ...
TESTS_RUN: <lệnh + pass/fail/not-run>
DISCREPANCIES/BLOCKERS: ...
CONTEXT_UPDATED: ...
HANDOFF: ...
```

Tạo/cập nhật `.agents/worklog/YYYY-MM-DD/<task-slug>.md`, bám `.agents/worklog/TEMPLATE.md`.

## 4. Finish gate

- Focused tests -> broader affected suite -> linter/formatter/type checker -> check security/schema/contract -> context validator.
- Không tuyên bố `VERIFIED` nếu chưa chạy kiểm tra hoặc không có bằng chứng quan sát được.
- Với changes ở architecture/schema/API/auth/dependency, cập nhật đúng page `.agents/project/` hoặc `.agents/modules/` cùng PR.
- Chạy `python3 scripts/validate_agent_context.py` sau khi chỉnh context.
- Không tự deploy, chạy migration production, xóa dữ liệu, rotation secret hay thay settings production nếu chưa được ủy quyền cụ thể.
