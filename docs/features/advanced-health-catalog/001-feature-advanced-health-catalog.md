Commit đề xuất: feat(features-hub): thêm danh mục sức khỏe nâng cao M20-M29

# Feature — Danh mục sức khỏe nâng cao M20–M29

## Metadata

| Field | Value |
|---|---|
| BD | `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md` (`BD-BIOAI-ADVANCED-HEALTH-001`) |
| BD status | `Draft - UI catalog shell approved` |
| Phạm vi | UI catalog, access-aware route và shared development placeholder |
| Không phải | DD hoặc implementation nghiệp vụ sức khỏe M20–M29 |

## Kết quả

- Danh mục chức năng hiển thị thêm đúng 10 card M20–M29, tách khỏi nhóm công cụ hiện có.
- M20–M22 có nhãn Miễn phí; M23–M29 có nhãn Plus; mọi card có nhãn Đang phát triển.
- Route dùng module ID để mở một shared access page, không tạo 10 page nghiệp vụ giả.
- Guest được chuyển tới đăng nhập; Free mở M20–M22 thấy trang đang phát triển; Free mở M23–M29 được chuyển tới nâng cấp; Plus/FamilyPlus mở mọi module thấy trang đang phát triển.
- Unknown module, access loading/error và route guard có safe state; không lộ lỗi kỹ thuật cho người dùng.

## Danh mục

| Module | Tên hiển thị | Minimum access | UC |
|---|---|---|---|
| M20 `BLOOD_PRESSURE_TRACKING` | Nhật ký huyết áp | Free | UC-25 |
| M21 `HEART_OXYGEN_TRACKING` | Nhịp tim & SpO₂ | Free | UC-26 |
| M22 `MEDICATION_ADHERENCE` | Lịch dùng thuốc | Free | UC-27 |
| M23 `GLUCOSE_TRACKING` | Theo dõi đường huyết | Plus | UC-28 |
| M24 `SYMPTOM_PAIN_JOURNAL` | Nhật ký triệu chứng & cơn đau | Plus | UC-29 |
| M25 `WOMENS_CYCLE_HEALTH` | Chu kỳ & sức khỏe nữ | Plus | UC-30 |
| M26 `RESPIRATORY_ALLERGY_TRACKING` | Hô hấp & dị ứng | Plus | UC-31 |
| M27 `LAB_RESULT_TRACKING` | Xét nghiệm & chỉ số y khoa | Plus | UC-32 |
| M28 `PREVENTIVE_CARE` | Lịch chăm sóc dự phòng | Plus | UC-33 |
| M29 `AI_HEALTH_TRENDS` | Báo cáo xu hướng sức khỏe AI | Plus | UC-34 |

## Luồng hoạt động

1. Người dùng mở Features Hub; catalog hiện đủ 10 mục với tier badge và development badge.
2. Người dùng chọn card; app điều hướng tới `/v2/health-modules/:moduleId`.
3. Route thuộc protected v2 prefix và access page đọc effective access hiện hành.
4. Access resolver trả một trong bốn kết quả:
   - Guest/anonymous: chuyển tới đăng nhập.
   - Free + M20–M22: hiển thị shared coming-soon page.
   - Free + M23–M29: chuyển tới lựa chọn nâng cấp.
   - Plus/FamilyPlus + M20–M29: hiển thị shared coming-soon page.
5. Module ID không hợp lệ hoặc chưa kiểm tra được access hiển thị safe support state; không mặc định cấp quyền.

## Dữ liệu và side effect

- Catalog dùng constant metadata, không chứa health record hoặc production sample data.
- Placeholder không có form, không đọc/ghi health data vào SQLite/Supabase, không gọi module health API/AI, không commit quota, không lên lịch notification và không xin quyền thiết bị; effective-access lookup phục vụ gate vẫn được phép.
- Tier badge và coming-soon page không tạo entitlement; access vẫn đến từ effective-access contract.
- DD completeness và business coding progress của M20–M29 vẫn là 0%.

## UI/UX

- Giữ nhóm công cụ hiện tại riêng với nhóm “Theo dõi chuyên sâu đang phát triển”.
- Grid responsive theo chiều rộng, có thể về một cột trên màn hình hẹp để tránh overflow.
- Card có semantic meaning qua title/badge/icon; tier không được truyền đạt chỉ bằng màu.
- Copy tiếng Việt theo Nabitone, không hứa hẹn chẩn đoán hoặc điều trị.
- Coming-soon page mô tả capability tương lai và luôn giữ ranh giới tham khảo sức khỏe.

## Traceability

| Requirement | Implementation behavior | Test evidence cần có |
|---|---|---|
| AHF-BR-001 / AHF-AC-001 | Catalog đúng 10 module/tier/order | Catalog contract + Features Hub widget test |
| AHF-BR-002 / AHF-AC-002,004 | Access resolver và protected dynamic route | Resolver unit test + router/access-page widget test |
| AHF-BR-003 / AHF-AC-003 | Placeholder chỉ hiển thị UI, không có module health/AI side effect; access lookup được phép | Architecture/static contract review |
| AHF-BR-004 | Effective access quyết định destination, không dựa vào badge | Resolver matrix test |
| AHF-BR-005 | Checklist giữ DD/business coding ở 0% | Targeted docs `rg` check |
| AHF-BR-006 / AHF-AC-005 | Safe Vietnamese copy và responsive UI | Widget copy/overflow test |

## Files liên quan

- `lib/shared/health_features/health_feature_catalog.dart` — registry M20–M29 dùng chung cho UI và access.
- `lib/core/constants/routes/health_module_route_paths.dart` — dynamic route contract.
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` — render catalog section/card.
- `lib/app_versions/v2/features/health_modules/` — access resolver và shared coming-soon/support page.
- `lib/app_versions/v2/router/v2_router.dart` — protected route và redirect integration.
- `test/features/features_hub/`, `test/shared/health_features/`, `test/app_versions/v2/features/health_modules/`, `test/app_versions/v2/router/` — focused contract/widget/router tests.

## Kiểm chứng cần chạy

- `dart format --set-exit-if-changed <touched Dart files>`.
- `flutter analyze <touched source and test paths>`.
- `flutter test test/shared/health_features test/features/features_hub test/app_versions/v2/features/health_modules test/app_versions/v2/router`.
- Targeted `rg` xác nhận M20–M29, tier 3 Free/7 Plus, dynamic route và không có health persistence/API/AI call trong placeholder slice.
- Docs checks: `.codex/tools/validate_codex_integrity.ps1` và `git diff --check`.

Kết quả command phải được ghi trong worklog của phiên tích hợp. Tài liệu này không tự claim PASS trước khi command hoàn tất.

## Rủi ro và gate tiếp theo

- Catalog preview không được biến thành form hoặc sample data trước DD.
- Không tạo 10 DD folder trong thay đổi UI shell này.
- Mỗi module chỉ được bắt đầu business coding sau khi DD tương ứng Approved, các AHF-Q liên quan được chốt và privacy/clinical/test contract đầy đủ.
- Device/OCR/AI, FamilyPlus health sharing, notification và Supabase data path vẫn là phase sau, phải theo dependency M06/M07/M09/M10/M11/M19 trong BD.
