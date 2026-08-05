# NanoBio Dashboard Blue Wellness — Delivery Manifest

## Phạm vi

- Chuyển semantic brand palette từ xanh lá sang xanh dương.
- Tối ưu Dashboard V1 theo hướng tối giản, ưu tiên việc cần làm hôm nay.
- Giữ nguyên provider/controller/repository, persistence, quota, access và route behavior.

## Thành phần chính

- `dashboard_page.dart` được rút từ 2.241 xuống 284 dòng và chỉ giữ orchestration.
- Widget mới: Dashboard composition, overview, sections, loading/error/sync states.
- Palette Blue Wellness với primary `#2F6FED`, primary dark `#1746A2`.
- Thêm widget/static contract tests cho narrow screen và text scale 130%.
- Cập nhật feature note, checklist và worklog ngày 2026-08-04.

## Validation trong môi trường đóng gói

- Static validator: PASS, 740 Dart files, 0 blocking findings.
- Import path, delimiter, semantic token và architecture-boundary scans: PASS.
- Flutter format/analyze/test/build: chưa chạy vì container không có Flutter/Dart SDK.
- Input snapshot thiếu thư mục `assets`, nên validator ghi nhận 57 cảnh báo asset path có sẵn từ đầu vào.

## File không đóng gói

- `.env` và runtime auth config nhạy cảm.
- Gradle/Kotlin cache, local SDK path, IDE state, logs, nested archive và generated ephemeral/build directories.

## File cần được loại bỏ khi áp dụng dạng patch

- `test/core/theme/green_wellness_contract_test.dart`
