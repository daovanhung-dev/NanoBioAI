Commit de xuat: feat(ui): tich hop nen tang Stitch Green Wellness co rollout gate

# Feature - Stitch Green Wellness

## Trạng thái

Đây là mốc tích hợp nền tảng và các lát cắt UI an toàn của kế hoạch Stitch Green Wellness. Registry nguồn đã đủ `76/76`, nhưng chưa có bằng chứng golden/visual acceptance cho toàn bộ 76 surface và chưa đủ điều kiện để tuyên bố production-ready.

Các nghiệp vụ sức khỏe, AI, FamilyPlus chat, Sale mở rộng và health-hub chưa có DD `Approved` vẫn fail closed hoặc chỉ hiển thị catalog/placeholder. Runtime và DD đã duyệt luôn thắng dữ liệu mẫu trong Stitch.

## Nguồn chuẩn và invariants

- `screen.png` quyết định bố cục; `code.html` quyết định token và typography.
- DD, provider, repository, auth redirect, entitlement, quota, payment status, feature flag và dữ liệu runtime hiện hữu quyết định hành vi.
- Không nhúng HTML/WebView/Tailwind, không hotlink và không đưa dữ liệu mẫu Stitch vào production.
- Admin giữ workspace riêng; chỉ nhận typography, accessibility, dark-mode compatibility và semantic colors dùng trong workspace.
- NanoBio là product, Nabi là companion và Nami Care là hub điều hướng quyền lợi.

## Phần đã triển khai

### Registry và asset reference

- Lập registry `76/76` cặp `screen.png`/`code.html`, có loại surface, owner, route/state và acceptance record.
- Tạo importer/validator cùng manifest cho 90 asset URL từ HTML Stitch.
- Asset được tải về local để đối chiếu, không hotlink. Toàn bộ asset Stitch hiện có `license_status=unverified` và `runtime_eligible=false`; không được dùng trong production cho đến khi có bằng chứng license.
- Avatar, QR, health data, giao dịch và nội dung cá nhân tiếp tục lấy từ runtime thật hoặc fallback local an toàn.

### Green Wellness foundation

- Bổ sung semantic theme contract, `AppSemanticColors`, `AppTheme.lightTheme` và `AppTheme.darkTheme`.
- Chốt token chính: primary `#006A46`, accent `#14A36F`, CTA `#0F8E62 -> #32C789`, background `#F5FAF7`, text `#12352A`, mint `#EAF9F1`.
- Snapshot light/dark `ColorScheme` bằng literal để deterministic; presentation trọng yếu và shared medical primitives lấy màu từ context.
- Bundle Roboto 400/500/600/700 kèm OFL và kiểm tra hash.
- App V1/V2/V3, resolving shell và Admin theo setting theme hiện hữu. Admin dùng `AdminWorkspaceColors`/workspace theme riêng thay vì nhận diện Stitch của user app.

### Chính sách cutover

`STITCH_GREEN_UI_ENABLED` là cờ presentation, tách khỏi các cờ business:

| Build | Không truyền dart-define | Giá trị tường minh |
|---|---|---|
| Debug/Profile | Green mặc định | `false` quay về Blue; `true` giữ Green |
| Release | Green mặc định, để `flutter build apk` có cùng palette với `flutter run` | `false` là rollback Blue trong một release; `true` giữ Green |

Green là default presentation cho mọi build mode để đồng bộ palette; điều này không thay thế các visual/accessibility/behavior gate hay các phê duyệt liên quan. `STITCH_GREEN_UI_ENABLED=false` là đường rollback Blue tạm thời, chỉ có giá trị trong một release.

### Baseline và surface an toàn

- Sửa contract Flutter cho `isSelected`, auth fixture/back behavior, Sale message chỉ render một lần và AI failed-input chỉ còn ở UI draft.
- Thêm các route wellness an toàn: `/water-tracking`, `/weekly-summary`, `/personal-goals`, `/quick-care`, `/gentle-care`, `/nami-care` và route shell `/v3/familyplus` có effective-access gate.
- Nami Care chỉ điều hướng tới năng lực local/runtime đã được phép; không tạo chuyên gia, booking hoặc dữ liệu mẫu.
- Water Tracking yêu cầu người dùng tự chọn mục tiêu, ghi rõ không phải khuyến nghị y tế và lưu local theo ngày. Chưa có cloud merge khi DD tương ứng chưa duyệt.
- `/health-tracking` vẫn giữ alias hiện hữu; chưa đổi thành nhật ký sức khỏe riêng trước khi `DAILY_WELLNESS_JOURNAL` được duyệt.
- M20-M29 tiếp tục là catalog/development placeholder, không có form, persistence, device permission, OCR, API hoặc AI business flow mới.

## Gate chưa được mở

| Nhóm | Trạng thái hiện tại | Điều kiện để triển khai/mở rollout |
|---|---|---|
| Daily journal, reports, self-care, sleep, stress | Chưa có DD Approved | PO, Tech, QA và Clinical/Privacy duyệt DD đầy đủ |
| M20-M29, health hubs, OCR | Catalog/placeholder; manual fallback khi phù hợp | DD Approved, schema/RLS, capability/permission, clinical/source và privacy acceptance |
| AI coaching và AI memory | Không thêm model call/memory flow mới | Trusted backend gateway, typed context, safety policy, clinical review và privacy acceptance |
| FamilyPlus chat/E2EE | Chưa thêm `/v3/familyplus/chat` | DD Approved, crypto/key ceremony, RLS, retention, report/escrow evidence |
| Sale care CRM mở rộng | Chưa triển khai | DD Approved, least-privilege RPC, trusted aggregate và audit acceptance |
| Asset Stitch | Reference/golden only | License status được xác minh trước khi đặt `runtime_eligible=true` |

## Acceptance status

| Gate | Evidence hiện có | Trạng thái |
|---|---|---|
| Registry | Validator báo 76 pairs, 76 rows, 90 assets | Đạt source inventory |
| Theme contracts | Green/rollback, semantic dark components, Roboto hash và Admin dark tests | Đạt targeted tests |
| Baseline behavior | Auth/Sale/AI/router bundle targeted | Đạt targeted tests |
| Wellness route/water | Router, target, persistence và retry widget tests | Đạt targeted tests |
| Full analyzer/test suite | Cần chạy lại sau khi hợp nhất toàn bộ presentation migration | Chưa chốt |
| Debug APK | Cần build và smoke | Chưa chốt |
| 76-surface light/dark golden | Chưa có đủ 76/76 evidence tại các viewport yêu cầu | Chưa đạt |
| Accessibility/device/Supabase | Chưa có đầy đủ screen reader, real-device, sandbox/RLS/provider evidence | Chưa đạt |
| Clinical/privacy/license/store review | Phụ thuộc phê duyệt ngoài source | Chưa đạt |

## Điều kiện handoff

- Chạy formatter, full `flutter analyze`, full `flutter test`, architecture/integration suite và `flutter build apk --debug` sau khi merge tất cả lát cắt.
- Tạo golden light/dark ở 390×884 và adaptive checks 320/360/412/600+, gồm text scale, focus, reduced motion và không overflow.
- Release mặc định Green; xác minh `flutter build apk` cho cùng palette với `flutter run`. Giữ `--dart-define=STITCH_GREEN_UI_ENABLED=false` là rollback Blue trong một release; điều này không được xem là evidence gate đã đạt.
- Không claim production-ready trước clinical/privacy approval, store permission review, asset license check, Supabase/RLS acceptance và escrow key ceremony khi chat được triển khai.
