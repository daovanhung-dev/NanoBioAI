Commit de xuat: feat(onboarding): hien thi tien do tao lich AI

# Tiến độ tạo lịch AI trong onboarding

## Mục tiêu

Cho người dùng biết lịch AI đã hoàn thiện đến đâu và ngày nào đã được lưu trong lúc onboarding tạo lịch 7 ngày.

## Luồng hiện tại

1. Từ màn Review, onboarding mở `AIGeneratingPage` kèm panel tiến độ riêng của onboarding.
2. `GeneratedPlanService` báo tiến độ sau khi `saveGeneratedPlanDay` hoàn tất thành công. Số phần trăm là số ngày đã lưu chia cho tổng số ngày, làm tròn đến số nguyên gần nhất.
3. Panel hiển thị phần trăm, số ngày đã lưu và chip có nhãn như `Ngày thứ nhất`, `Ngày thứ hai`. Ngày chưa được lưu không xuất hiện trong danh sách.
4. Khi tiếp tục một request bị gián đoạn, service báo các ngày hoàn chỉnh đã lưu trước đó, rồi cập nhật tiếp sau mỗi ngày mới.

## Ranh giới dữ liệu

- Tiến độ phản ánh ngày đã xác nhận lưu, không phải thời gian chờ, số lượt gọi AI hay dữ liệu mới chỉ nằm trong staging.
- Ngày đã lưu trước đó chỉ được tính khi request khớp người dùng, loại tác nhân và số ngày; số bữa và hoạt động phải tương ứng với các ngày đầy đủ.
- Callback chỉ cập nhật state onboarding. Widget dùng state hiện có và không gọi repository, SQLite hoặc API.

## Kiểm chứng

- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart`: PASS.
- `flutter analyze` trên 10 file nguồn/test thuộc flow: PASS, không có issue.
- `dart format --set-exit-if-changed` ban đầu phát hiện hai file cần format; đã format lại và test/analyze sau đó đều PASS.
- `flutter run --debug --no-pub -d chrome` khởi chạy được và hot reload PASS. Chrome báo không tải được asset `.env`; không thực hiện request AI/backend thật và không coi đây là xác nhận runtime tạo lịch.
- Chưa kiểm chứng render trên thiết bị Android. Không cài đè package ứng dụng chính; Android Gradle hiện không khai báo QA flavor/suffix.

## Tài liệu liên quan

- UI contract: `.codex/design/screens/onb-10-review-step.md`.
- Worklog: `docs/worklog/2026-10-13/010-worklog-onboarding-plan-progress.md`.
