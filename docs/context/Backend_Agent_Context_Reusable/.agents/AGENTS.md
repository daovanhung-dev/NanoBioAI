# Agent Context Registry

**Bộ này là quy tắc khởi tạo; mọi trạng thái dự án sau đây phải được đo/ghi bằng nguồn mới.**

## Vocabulary

| State | Diễn giải |
|---|---|
| `VERIFIED` | Đã kiểm tra bằng source và lệnh thực chạy tương ứng. |
| `SOURCE_BACKED` | Đã đọc source; chưa mặc nhiên suy ra runtime/test pass. |
| `EXPECTED_BEHAVIOR` | Nguồn requirement/contract được duyệt. |
| `CURRENT_BEHAVIOR` | Hành vi chứng minh được bằng code/test/config. |
| `UNWIRED` | Code có nhưng không được import/compose/call. |
| `NOT_FOUND` | Không có nguồn hoặc artifact yêu cầu. |
| `DECLARED_NOT_RUNNABLE` | Có declaration nhưng không chạy được. |
| `DISCREPANCY` | Expected và Current không giống nhau. |
| `BLOCKED` | Thiếu dependency, quyền, source, hoặc tool để xác minh. |
| `ASSUMPTION` | Giả định tạm, phải ghi và cần confirm trước khi quyết định nguy hiểm. |

## Navigation

- `.agents/context-map.md` — các topic context và luồng nạp.
- `.agents/project/INDEX.md` — index scope backend.
- `.agents/modules/README.md` — quy ước module.
- `.agents/modules/TEMPLATE.md` — template module context.
- `.agents/worklog/README.md` — audit trail cho mỗi task.
- `prompts/` — prompt điều khiển agent, **không** phải source-of-truth cao hơn current repo.

## Contract boundary

Không đem SQL, roles, database schema, URL, JWT keys, business codes hoặc DD/UC/AC từ Study2Work sang dự án mới. API mới bắt đầu bằng **contract do dự án mới xác định**. Chỉ sao chép framework/conventions đã lựa chọn sau khi đối chiếu tình hình hiện tại.

## Design choices

Sync SQLAlchemy mặc định cho logic CRUD thông thường; nếu cần async end-to-end thì thống nhất session/driver/query/api async một cách chủ ý, **không trộn blocking DB trong async handler**. Theo dõi lựa chọn thay đổi trong `.agents/project/03-technology.md` và ADR.
