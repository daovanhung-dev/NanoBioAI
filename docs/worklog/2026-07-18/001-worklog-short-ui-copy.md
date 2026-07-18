# Worklog — rút gọn copy hiển thị toàn dự án

## Thông tin

| Trường | Giá trị |
|---|---|
| Ngày | 2026-07-18 (`Asia/Saigon`) |
| Workflow | coding |
| Module | V1, V2, V3, Admin, Sale/referral, shared UI/catalog |
| Nguồn | Plan "Rút gọn copy hiển thị toàn dự án NanoBio" do người dùng cung cấp |

## Kết quả

- Rút gọn copy production-facing ở Dashboard, Features Hub, Nutrition, Lifestyle Schedule, Onboarding, Auth, Settings/Profile, AI Chat, Admin, Sale/referral, shared coming-soon shell và M20-M29 catalog.
- Giữ tiếng Việt/Nabitone, giảm câu dài, giảm lặp "Nabi/mình/nhé", tránh thuật ngữ nội bộ trong message người dùng nhìn thấy.
- Sale participation hiển thị tóm tắt ngắn; điều lệ đầy đủ vẫn mở được bằng "Xem điều lệ đầy đủ" và tiếp tục dùng `SaleTerms.currentVersion`.
- M20-M29 chỉ rút gọn catalog/placeholder; không thêm form, API, AI, persistence, notification hoặc nghiệp vụ mới.
- Rút gọn fallback/error copy dài trong loading AI, quota tạo lịch, auth backend, AI config và schedule horizon.
- Thêm contract test bắt production-owned UI literal dài hơn 100 ký tự, trừ SaleTerms đầy đủ và các dòng không phải copy hiển thị.

## Verification evidence

- `dart format` cho toàn bộ file Dart đã sửa → PASS.
- `flutter analyze` → PASS, `No issues found`.
- `git diff --check` → PASS; chỉ có warning CRLF dự kiến trên một số file touched.
- Targeted copy/UI tests → PASS:
  - `test/contracts/vietnamese_ui_contract_test.dart`
  - `test/core/localization/app_localization_config_test.dart`
  - `test/features/features_hub/features_hub_page_test.dart`
  - `test/app_versions/v2/features/health_modules/presentation/health_module_access_page_test.dart`
  - `test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`
  - `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart`
  - `test/app_versions/v1/features/body_metrics/body_metrics_page_test.dart`
  - `test/app_versions/v2/features/health_scoring/presentation/health_score_habits_page_test.dart`
  - `test/app_versions/v3/features/advanced_tracking/presentation/advanced_tracking_page_test.dart`
  - `test/app_versions/v3/features/familyplus/presentation/familyplus_page_test.dart`
  - `test/sale_referral/presentation/sale_shell_page_test.dart`
  - `test/app_versions/admin/features/wellness_rewards/admin_wellness_rewards_test.dart`
  - `test/app_versions/v2/features/payments/membership_payment_test.dart`
  - `test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart`
  - `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`
  - `test/app_versions/v1/features/settings/guest_account_access_card_test.dart`
  - `test/app_versions/v1/features/splash/splash_route_decision_test.dart`
  - `test/app_versions/admin/admin_controller_test.dart`
  - `test/app_versions/v3/features/familyplus/providers/familyplus_providers_test.dart`
  - `test/services/supabase/auth/supabase_auth_error_translator_test.dart`
  - `test/features/lifestyle_schedule/data/schedule_horizon_local_datasource_test.dart`
  - `test/shared/health_features/health_feature_catalog_test.dart`
  - `test/shared/widgets/vietnamese_ui_text_test.dart`
- Manual static scan `rg -n -P "'[^']{101,}'" lib --glob "!lib/l10n/app_localizations*.dart"` → không còn long single-quoted production UI literal ngoài regex/import/internal prompt/SaleTerms đầy đủ.
- Full `flutter test` trên tree hiện tại → FAIL với 5 baseline failures ngoài phạm vi copy:
  - `test/app_versions/v2/features/auth/auth_controller_sync_failure_test.dart`: Riverpod provider bị modify trong lúc provider init; expected sync reason `authGateRefresh` không xuất hiện.
  - `test/architecture_version_boundary_test.dart`: v1 dashboard đang import later/sale layer.
  - `test/architecture_version_boundary_test.dart`: v2 auth pages đang import v3/sale layer.
  - `test/architecture_version_boundary_test.dart`: unified entrypoint boundary expectation fail.
  - `test/core/theme/medical_design_system_contract_test.dart`: `schedule_proof_gallery_page.dart` còn dùng raw `Scaffold`.

## Blocker và việc còn lại

- `flutter devices` không phát hiện điện thoại thật; chỉ có Windows, Chrome và Edge. Không thể chạy real-device smoke/screenshot trong phiên này.
- Các full-suite failures còn lại thuộc auth sync behavior, architecture boundary và medical scaffold contract; không sửa trong task rút gọn copy để tránh mở rộng phạm vi.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — copy rút ngắn theo nhóm UI chính, giữ hành vi và có contract chống tái diễn.
- Mức độ hoàn thành task: hoàn thành phần code/copy/test; real-device screenshot bị block do không có thiết bị thật.
- Bằng chứng kiểm chứng: analyzer sạch, targeted tests pass, full suite current run phân loại rõ baseline failures.
- Điểm tốn token/chưa tối ưu: full suite có baseline failures kéo dài thời gian; lần sau nên đọc baseline failure note trước khi rerun full.
- Cách tối ưu cho phiên sau: chuẩn bị thiết bị thật được ADB nhận diện và auth/runtime config trước khi yêu cầu smoke bằng ảnh.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
