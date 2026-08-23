# Source Truth Audit — NanoBioAI / Nabi

| Thuộc tính | Giá trị |
| --- | --- |
| Baseline commit | `25018e82cfd120d4b26b81c010bcda95b1ae9f0e` |
| Baseline date | 2026-08-24, `Asia/Ho_Chi_Minh` |
| Chính sách | Code reachable và executable schema/config là nguồn tin cậy cao nhất |
| Mức hoàn tất | 100% static traceability |
| Runtime/device | `Runtime-unverified` trong môi trường audit |
| Supabase local/sandbox | `Sandbox-unverified` nếu không có execution evidence |

## Phạm vi và phương pháp

Baseline ban đầu gồm 5.076 file tracked: 889 file dưới `docs/`, 713 file dưới
`lib/`, 239 file dưới `test/` và 2.773 asset. Audit thực hiện theo hai mức:

- Semantic/contract review cho source, config, SQL, test, Markdown, text và
  README/comment authored.
- Inventory, path, declaration và provenance review cho binary asset, ảnh,
  HTML export và generated output.

Mọi file workspace được ghi đúng một lần trong
[`source_truth_manifest.json`](source_truth_manifest.json). Digest phát hiện
manifest cũ; lifecycle và evidence tách tài liệu hiện hành khỏi lịch sử.

## Source snapshot đã khóa

| Nhóm | Source evidence | Kết luận code-derived |
| --- | --- | --- |
| Bootstrap | `lib/main.dart`, `lib/app/bio_ai_app.dart` | Một entrypoint; Supabase optional; post-launch sync/catalog/notification chạy bất đồng bộ. |
| Router/surface | V1/V2/V3/Admin router và app-surface controller | User router compose V1+V2+V3; Admin chọn theo backend access; Sale là trục độc lập. |
| Package | `pubspec.yaml`, `pubspec.lock` | Dart `^3.9.2`; phân biệt constraint với resolved version. |
| AI | Gemini REST client, app env và AI services | Không có Gemini SDK dependency; model/config lấy từ source runtime. |
| Local data | database version/service/migration manager | SQLite version 20; migration và sync contract là nguồn. |
| Supabase | SQL `01`–`06`, Edge Function, Flutter service/RPC literals | SQL đánh số là nguồn; `config.sql` generated; production readiness chưa được suy diễn. |
| Native | Android/iOS config | Android `com.nanobioai.app`; iOS vẫn `com.example.nanoApp`; deep link `nanobio://auth/callback`. |
| Onboarding | catalog/constants và router | `totalSteps = 9`; tài liệu 7/8 bước là stale. |
| Asset/localization | `pubspec.yaml`, ARB và catalog | ARB là localization source; generated Dart và binary được parity-check. |

## Reconciliation ledger

| Finding | Hành động hiện hành | Trạng thái |
| --- | --- | --- |
| Root system document mô tả auth/bootstrap/onboarding cũ | Viết lại theo unified runtime và source path hiện hành. | Resolved trong đợt audit |
| `.codex` ghi Gemini SDK `0.4.7` | Thay bằng Gemini REST/Dio và model/config source. | Resolved trong đợt audit |
| README V2/V3 dùng blanket `planned`/`placeholder` | Chuyển sang status theo capability và reachability. | Resolved trong đợt audit |
| DD `Approved/docs complete` bị hiểu thành runtime complete | Tách implementation và verification; thêm source evidence. | Resolved trong đợt audit |
| M20–M29 | Chỉ catalog/access-aware placeholder được ghi nhận. | `Placeholder`, runtime business `Absent` |
| M30 checklist ghi coding 0% dù source đã có nhiều tầng | Ghi `Partial`, liệt kê source hiện có và wiring/acceptance chưa xác minh. | Resolved trong đợt audit |
| Worklog index 123 trong khi corpus đã lớn hơn | Sửa generator, tạo worklog mới và refresh deterministic. | Resolved khi history check PASS |
| Generator hard-code file Supabase đã xóa | Dùng validation `90`–`94`/README hiện hành và Python cross-platform. | Resolved khi generator check PASS |
| `test/docs` trỏ tới chín file Supabase legacy | Map assertion sang SQL `01`–`06` và validation `90`–`94`. | Resolved tĩnh; Flutter test unverified |
| Audit/test/issue summary cũ dễ bị đọc như trạng thái HEAD | Giữ dữ liệu baseline, thêm Historical/Superseded/Resolved marker. | Resolved trong đợt audit |
| Meal catalog source fingerprint lệch | Chỉ cập nhật fingerprint sau khi row/ID/image/source parity được xác minh. | Phải PASS static validator |
| Green/Blue UI validator có findings code baseline | Không sửa runtime trong task docs; tài liệu không được tuyên bố runtime PASS. | Open source finding, documented |

## Quy tắc BD/DD code-absolute

BD/DD giữ module ID và traceability nhưng không phải bằng chứng triển khai. Mỗi
module phải công bố:

- `Implementation`: `Implemented`, `Partial`, `Placeholder`, `Source-only` hoặc
  `Absent` dựa trên reachable source.
- `Verification`: static, runtime và sandbox evidence độc lập.
- Source evidence cụ thể; source-only class không được nâng lên implemented.
- Phần không tồn tại trong code được mô tả là `Absent`, không dùng ngôn ngữ cho
  thấy người dùng hiện có capability đó.

## Lịch sử và generated artifacts

- Không đổi tên hoặc viết lại nội dung sự kiện của worklog/fixbug/test evidence,
  kể cả các sequence number lịch sử bị trùng.
- Broken path trong lịch sử/reference chỉ được giữ khi manifest có exception và
  lý do; tài liệu hiện hành không được có broken link.
- `docs/supabase/config.sql`, `.codex/history/`, `.codex/task-skills/` và
  localization Dart là generated; phải sửa nguồn/generator trước rồi sinh lại.

## Acceptance

| Gate | Kết quả |
| --- | --- |
| Source-truth manifest, digest, link/path và core contract | Chạy ở cuối phiên |
| Supabase runtime contract | Chạy ở cuối phiên |
| Supabase generated config parity | Chạy ở cuối phiên |
| Meal sync/catalog và Kinetic Aura static validation | Chạy ở cuối phiên |
| Worklog/history deterministic check | Chạy ở cuối phiên |
| `git diff --check` | Chạy ở cuối phiên |
| Flutter/Dart/PowerShell | `UNVERIFIED` nếu tool không có |
| Device/Supabase sandbox | `UNVERIFIED`; không được ghi PASS |

Kết quả cuối cùng và command evidence được ghi trong worklog của phiên. Audit
không thay đổi public Dart API, hành vi runtime, schema hay RPC.
