Commit de xuat: docs(worklog): ghi nhan preview tro ly ESP cua Nabi

# Worklog - Nabi ESP assistant trong Feature Hub

## Thoi gian

- Ngay: 2026-10-23
- Bat dau: tiếp nối phiên triển khai; thời điểm bắt đầu không được ghi riêng
- Ket thuc: 2026-10-23 14:00 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Pham vi

- Loai task: Flutter UI, route, widget test, DD và design registry
- Module chinh: `lib/app_versions/v1/features/features_hub/` và tính năng mới `nabi_esp_assistant`
- Yeu cau goc: thêm “Nabi - Siêu trợ lý AI” vào Feature Hub, chuẩn bị luồng Android để AI local trên điện thoại điều khiển ESP OSTB 3ST, kèm tài liệu và nghiệm thu

## Da lam

- Thêm tile Android trong nhóm “Sắp ra mắt”, route và trang preview riêng. iOS không hiện tile; không thêm quota hoặc yêu cầu đăng nhập cho tính năng ESP.
- Trang mô tả model GGUF, Whisper, TTS ngoại tuyến, mạng LAN/Bluetooth và yêu cầu nạp firmware/phân vùng XiaoZhi qua USB. Nút “Kết nối Nabi” đang khóa; chưa bật hotspot, BLE, audio hay server.
- Tạo DD trạng thái Draft và tài liệu feature; ghi rõ phạm vi dữ liệu, giới hạn, điều kiện firmware và quyền Guest/Free đã được yêu cầu.
- Đăng ký screen/route vào design matrix, screen registry, route matrix, acceptance/implementation inventory và làm mới manifest nguồn UI.
- Sửa tên semantic color theo API theme thực tế.
- Dùng `TargetPlatformVariant` cho kiểm thử Android/iOS và cuộn tới nút trong `ListView` trước khi assert; lần chạy đầu phát hiện lỗi override/finder và đã được sửa.
- Không thay đổi firmware, không ghi flash và không xác nhận kiểm thử trên phần cứng.

## File code/docs da sua

- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` - thêm tile preview Android-only.
- `lib/app_versions/v1/features/nabi_esp_assistant/presentation/pages/nabi_esp_assistant_page.dart` - tạo trang giới thiệu với nút kết nối disabled và trạng thái chờ review.
- `lib/app_versions/v1/router/v1_route_paths.dart`, `lib/app_versions/v1/router/v1_router.dart` - đăng ký đường dẫn preview.
- `test/features/features_hub/features_hub_page_test.dart` - kiểm tra tile/route Android, nút disabled và ẩn trên iOS.
- `docs/DD/nabi_esp_assistant/` và `docs/features/nabi_esp_assistant/` - tạo DD Draft và tài liệu feature.
- `.codex/design/` - đăng ký bề mặt V1-X18, route và cập nhật inventory/manifest.
- `docs/DD/README.md`, `docs/checklist/checklist_create_DD.md`, `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - cập nhật chỉ mục và checklist.
- `docs/worklog/2026-10-23/004-worklog-nabi-esp-assistant.md` - ghi nhận phiên.

## Tai lieu lien quan

- Quy tắc release gate trong `.codex/design/15_CODING_PLAN.md`: module nghiệp vụ mới giữ dạng placeholder tới khi có Tech, QA và Privacy review. Các phê duyệt này chưa có trong context hiện tại.
- Hồ sơ thiết bị: `iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`; thiết bị vẫn cần firmware và partition XiaoZhi tương thích nạp qua USB trước khi app có thể kết nối.
- Kế hoạch và quyết định sản phẩm chi tiết: `docs/DD/nabi_esp_assistant/Overall.md`.

## Commands

- `dart format --set-exit-if-changed ...`: PASS; năm file Dart không còn thay đổi format.
- `dart analyze ...`: PASS; `No issues found!`.
- `flutter test --no-pub test/features/features_hub/features_hub_page_test.dart`: PASS; 12 tests.
- `mcp__dart_mcp_server__dtd listDtdUris/connect/listConnectedApps`: DTD tìm thấy, nhưng không có Flutter app đang chạy để hot reload/restart.
- `python3 tools/refresh_ui_design_inventory.py`: PASS; 274 source rows, 95 surface specs, 126 canonical hashes.
- Kiểm tra liên kết Markdown cục bộ trong 11 file DD/feature/design liên quan: PASS.
- `pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS; cập nhật 19 history/task-skill files.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và path stale trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`; không báo path mới từ DD/feature vừa tạo.
- `git diff --check`: PASS.

## Loi/Rui ro

- Da fix: lỗi analyzer do tên màu semantic không tồn tại và test platform override chưa import `foundation`.
- Chua fix: Tech/QA/Privacy review chưa được ghi nhận, nên theo release gate luồng kết nối vẫn là preview.
- Can kiem tra tiep: sau các review, triển khai và nghiệm thu Android hotspot/foreground service, BLE provisioning, auth/token, Whisper/Opus/TTS, điều khiển listening và firmware trên OSTB thực.
- Thiết bị OSTB 3ST hiện có firmware demo LCD và partition app `factory` 1 MB; không có bằng chứng phần cứng nào được tạo trong phiên này.

## Ty le hoan thanh

- Hoan thanh: preview UI/route, test source, DD và design registry.
- Dang do: kết nối end-to-end và nghiệm thu thiết bị chưa triển khai vì release gate chưa qua.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - trang không giả lập trạng thái đã kết nối, tài liệu giữ các giới hạn và bằng chứng rõ ràng.
- Muc do hoan thanh task: phần preview và chuẩn bị tài liệu hoàn thành; tính năng kết nối theo kế hoạch vẫn chưa sẵn sàng dùng.
- Bang chung kiem chung: formatter, analyzer, 12 widget tests, route/tile source, design inventory, local-link check và diff check.
- Diem ton token/chua toi uu: lần đầu chạy test bị kéo dài do Flutter kiểm tra/tải lại package cache.
- Cach toi uu cho phien sau: tái sử dụng package cache hiện có và chạy lại đúng test mục tiêu sau khi môi trường ổn định.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md` và `.codex/task-skills/docs-context.md`.
