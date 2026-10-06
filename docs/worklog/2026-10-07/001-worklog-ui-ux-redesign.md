# Worklog — NanoBioAI UI/UX redesign foundation

## Thời gian

- Ngày: 2026-10-07.
- Bắt đầu: Phiên tiếp nối công việc UI audit ngày 2026-10-06; không ghi riêng thời điểm bắt đầu.
- Kết thúc: Khoảng 00:08 +07.
- Múi giờ: Asia/Ho_Chi_Minh.

## Phạm vi

- Loại task: Flutter UI, theme, test và design inventory.
- Yêu cầu: triển khai tái thiết kế theo tình hình source thực tế, bao gồm các bề mặt V1/V2/V3/Admin/Sale, giữ nguyên route, auth, dữ liệu và nghiệp vụ; QA chỉ dùng profile staging; không phát hành production.
- Trạng thái: đã triển khai nền design system và các nhóm UI trọng tâm; inventory ghi nhận 8 direct redesign, 82 shared-foundation applications và 4 gate/shell/token migrations. Render acceptance cho cả 94 surface chưa hoàn tất.

## Đã làm

- Làm mới Blue Wellness light/dark semantic roles, neutral/status colors, radius, elevation, surface treatment và chuyển cảnh dùng chung; xanh lá giữ vai trò health/success accent.
- `MedicalSurfaceCard` đặt Material trong bề mặt trang trí và clip theo bo góc. Lượt test toàn repo đã bộc lộ cảnh báo Flutter về ripple của các `ListTile` lồng trong card; test body metrics và lịch ngủ sau khi sửa không còn assertion này.
- Làm mới thanh điều hướng V1, nền/card onboarding, trạng thái Notification Settings; chuẩn hóa shell và token cho nhóm Sleep Safety/M31, Fitness và một số shared widgets.
- Đồng bộ Dashboard summary cards với shared surface; score ring co giãn theo text scale. Widget test ở 320 dp / text scale 1.6 phát hiện và xác minh đã hết overflow.
- Admin workspace dùng semantic nền Blue Wellness nhưng giữ độ đậm thông tin cho tác vụ vận hành; không thay quyền hay luồng Admin.
- Thêm test responsive cho shared page shell qua 5 chiều rộng, 3 cỡ chữ và light/dark; thêm test lịch giám sát kiểm tra bố cục hẹp và payload lưu.
- Quét source thành 266 UI Dart rows và 94 screen/subsurface specs; bổ sung spec còn thiếu và sửa nhãn Sleep Tracking đang bị ghi stale thành coming-soon dù source route hiện hoạt động sau các gate auth/membership/rollout.
- Giữ `.codex/design/` là nguồn chuẩn, cập nhật trạng thái triển khai và root `design.md` làm trang dẫn. Không đổi API, model, auth, route hay schema.
- Không deploy, release, cài lại app, xóa local storage, bật/tắt preference, hay ghi dữ liệu QA/production.

## File code/test chính

- `lib/core/theme/` — semantic palette, Material themes, shape, shadow, gradient và motion tokens.
- `lib/core/theme/medical_ui.dart` — shared card/material ink, scaffold và medical presentation primitives.
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` — thanh điều hướng V1.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` — nền và panel onboarding.
- `lib/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart` — loading/error/retry và bố cục settings thông báo.
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/` cùng `presentation/widgets/` — M31/sleep shell, lịch, trạng thái và các shared surfaces.
- `lib/app_versions/v1/features/fitness_training/presentation/` và `lib/app_versions/v1/features/body_metrics/presentation/widgets/body_metrics_trend_card.dart` — áp dụng shell/semantic tokens.
- `lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart` — Dashboard dùng shared surface và score ring co giãn theo text scale.
- `lib/app_versions/admin/theme/admin_workspace_theme.dart`, `features/admin_panel/presentation/pages/admin_shell_page.dart` — nền semantic Admin; trang shell cũ đã được xác nhận không có caller.
- `test/core/theme/medical_responsive_layout_test.dart`, `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_schedule_page_test.dart` — responsive sweep và lịch giám sát.

## Tài liệu/inventory

- `.codex/design/README.md`, `13_SCREEN_REGISTRY.md`, `21_CODING_IMPLEMENTATION_STATUS.md`, nhóm `03_dashboard_health.md` và `07_health_tracking.md`.
- `.codex/design/screens/` — thêm spec cho check-in, review, Fitness, Notification Settings, Food Scan/history, settings và M31 sub-surfaces.
- `.codex/design/inventory/` — source audit, surface status, source drift, coverage và design token mapping.
- `tools/refresh_ui_design_inventory.py` — tạo lại snapshot từ 266 file source; script báo rõ đây là heuristic inventory, không phải render certification.
- `design.md` — liên kết tới `.codex/design/README.md`.

## Kiểm chứng

- `flutter analyze --no-pub`: PASS, no issues found.
- Các nhóm test trên source hiện tại: `test/core/theme` 58/58; `test/app_versions/admin` 62/62; sleep presentation 20/20; V1 settings 16/16; Fitness page 1/1; body-metrics page 3/3; Dashboard 6/6.
- `python3 tools/validate_kinetic_aura.py`: PASS; 887 imports, 82 structural files, 94 changed/structural Dart files.
- `python3 tools/refresh_ui_design_inventory.py`: PASS; 266 UI Dart rows, 94 surface specs, 125 design-manifest hashes.
- `git diff --check`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite flutter test --no-pub`: chưa hoàn tất; báo 1,251 pass và 81 failure, gồm nhiều source/route/copy contract assertions không khớp source hiện tại ở các nhóm khác nhau. Tiến trình đứng hơn ba phút tại `auth_controller_sync_failure_test.dart` và được ngắt; không ghi đây là full-suite pass.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL theo baseline repository vì thiếu `docs/audit/source_truth_manifest.json` và các path lịch sử cũ trong archived worklog/task-skill. Không tạo manifest khi việc reconcile toàn repo chưa hoàn thành.
- Xiaomi 220333QPG còn kết nối nhưng app process không chạy; launcher đang ở foreground. Không có Dart VM service để hot reload; không cài lại hoặc mở app để tránh khởi tạo/sửa local state. Screenshot trước đó là baseline, không phải render của source mới.
- Chưa có profile trace trước/sau trên cùng workload; `gfxinfo` baseline không đủ frame build/raster nodes.

## Còn lại

- Redesign trực tiếp và xác minh render cho đầy đủ 94 surface (gồm auth/onboarding, dashboard, meal/nutrition, AI, profile/settings, V2/V3, Sale/Admin, dialogs/sheets/states).
- Chạy lại full suite sau khi sửa các source-contract mismatches và điều tra test bị treo; giữ analyzer/test tuần tự.
- QA device/harness an toàn để chụp light/dark, reduced-motion, viewport 320/360/412/600+, text scale 1.0/1.3/1.6 và trạng thái có điều kiện.
- Đo profile frame build/raster, jank, rebuild và memory trên Xiaomi với cùng luồng và QA target.
- Không thực hiện production deploy/release trong redesign.
