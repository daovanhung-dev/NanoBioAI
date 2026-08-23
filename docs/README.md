# Tài liệu NanoBioAI / Nabi

Đây là điểm bắt đầu cho toàn bộ tài liệu của dự án. Tài liệu hiện hành phải
mô tả đúng source tại commit được ghi trong
[báo cáo source-truth](audit/SOURCE_TRUTH_AUDIT.md); Git history giữ lại nội
dung cũ khi cần đối chiếu theo thời điểm.

## Thứ tự nguồn tin cậy

Khi hai nguồn mâu thuẫn, dùng thứ tự sau:

1. Code reachable từ `lib/main.dart`, router được compose và wiring provider.
2. SQLite schema/migration trong `lib/core/storage/localdb/`, Supabase SQL
   nguồn `01`–`06`, Edge Function và cấu hình platform thực thi.
3. `pubspec.yaml`, `pubspec.lock`, manifest/build config và catalog asset.
4. Assertion thực thi trong test; comment và fixture prose không ghi đè code.
5. README, BD, DD, checklist, thiết kế, audit và tài liệu lịch sử.

`docs/supabase/config.sql` là file sinh từ SQL `01`–`06`, không sửa trực tiếp.
Code tồn tại nhưng không reachable từ runtime được ghi `Source-only`, không
được mô tả như tính năng người dùng đang sử dụng.

## Ba trục trạng thái

Mỗi capability hiện hành dùng ba trục độc lập:

| Trục | Giá trị |
| --- | --- |
| Lifecycle | `Current`, `Historical`, `Generated`, `Reference`, `Source`, `Binary` |
| Implementation | `Implemented`, `Partial`, `Placeholder`, `Source-only`, `Absent`, `N/A` |
| Verification | `Static-verified`, `Runtime-unverified`, `Sandbox-unverified`, `Historical` |

`Implemented` chỉ nói source và wiring hiện có. Nó không đồng nghĩa thiết bị,
staging hay production đã được kiểm chứng. Khi chưa có bằng chứng Flutter hoặc
Supabase sandbox, tài liệu phải giữ trạng thái `Runtime-unverified` hoặc
`Sandbox-unverified`.

## Bản đồ tài liệu

| Nhóm | Vai trò | Cách sử dụng |
| --- | --- | --- |
| `BD/`, `DD/` | Traceability theo module | Giữ ID, nhưng trạng thái triển khai phải dẫn tới source hiện hành. |
| `supabase/` | Source SQL local/sandbox và hướng dẫn rebuild | `01`–`06` là nguồn; `90`–`94` là validation; `config.sql` là generated. |
| `checklist/` | Trạng thái hiện hành hoặc baseline có nhãn | Checklist cũ phải ghi `Historical`/`Superseded`. |
| `audit/` | Báo cáo và manifest source-truth | Dùng để chứng minh coverage và các ngoại lệ có lý do. |
| `worklog/`, `features/`, `fixbug/` | Lịch sử thay đổi | Không viết lại sự kiện cũ theo kiến trúc mới. |
| `issues/`, `todo/`, `test/` | Evidence theo baseline | Kết quả cũ được giữ; summary hiện hành phải ghi baseline/resolution. |
| `refactor/`, `ui/`, `note/`, `prompts/` | Reference/design input | Không phải bằng chứng runtime nếu thiếu mapping tới source. |

Tài liệu root, `.codex/`, README trong source và comment kỹ thuật cũng thuộc
phạm vi source-truth. Ảnh, font, âm thanh và HTML export được kiểm kê/path-check
thay vì diễn giải như mô tả hành vi.

## Runtime hiện hành

- Chỉ có một entrypoint: `lib/main.dart`.
- User app dùng router hợp nhất V1, V2 và V3; Admin là surface riêng được chọn
  sau khi backend xác nhận quyền; Sale/referral là trục độc lập trong user app.
- Supabase là tùy chọn cho guest bootstrap; chức năng cloud/auth cần backend
  hợp lệ.
- AI gọi Gemini REST qua Dio; dự án không khai báo Gemini Dart SDK.
- SQLite hiện ở `DatabaseVersion.currentVersion = 20`.
- Onboarding runtime có 9 bước.

Chi tiết từng capability và bằng chứng file nằm trong
[báo cáo audit](audit/SOURCE_TRUTH_AUDIT.md) và
[manifest máy đọc được](audit/source_truth_manifest.json).

## Validation

Lệnh mặc định chỉ đọc:

```bash
python3 tools/validate_docs_source_truth.py
```

Chỉ dùng chế độ ghi sau khi đã review xong toàn bộ diff:

```bash
python3 tools/validate_docs_source_truth.py --write-manifest
```

Một lần PASS chứng minh manifest, path, link và static contract khớp workspace;
không thay thế Flutter/device test hoặc Supabase sandbox verification.
