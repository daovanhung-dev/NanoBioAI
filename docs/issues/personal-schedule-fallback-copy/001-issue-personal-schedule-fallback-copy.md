Commit de xuat: docs(issue): ghi nhan copy tao lai lich fallback chua ro

# Thông báo sau lịch fallback chưa nói rõ giới hạn tạo lại

## Tóm tắt

- Severity: low
- Khi một phần lịch dùng lựa chọn catalog dự phòng, thông báo thành công gợi ý đợi “dịch vụ” sẵn sàng rồi tạo lại để có lịch cá nhân hơn.
- Runtime hiện tại gọi AI trên thiết bị; sau khi lịch 7 ngày được thêm, nút tạo lại bị khóa cho tới khi lịch còn dưới hai ngày.

## Kỳ vọng và thực tế

- Kỳ vọng: thông báo giải thích lịch vừa tạo là gợi ý catalog cơ bản, hướng dẫn khắc phục tình trạng model trên thiết bị nếu phù hợp, và nói rõ khi nào người dùng có thể tạo lịch kế tiếp.
- Thực tế: copy nhắc “dịch vụ” mà không nói đây là model local; “có thể tạo lại” không nêu rằng thao tác ấy vẫn bị giới hạn bởi horizon 7 ngày vừa thêm.

## Cách tái hiện

1. Tạo lịch khi một chunk AI lỗi và service dùng local catalog fallback.
2. Đọc snackbar thành công.
3. Quan sát card lịch trình: sau khi horizon được làm mới, nút tạo bị khóa vì lịch mới còn trên một ngày.

## Bằng chứng

- `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart:171-179` chọn thông báo fallback.
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_regeneration_card.dart:20-25` khóa thao tác khi lịch còn ít nhất hai ngày.
- `lib/app_versions/v1/services/ai/ai_generation_result.dart:3-17` mô tả fallback catalog và provenance của lịch.
- `lib/app_versions/v1/services/ai/ai_service.dart:724-770` tạo lựa chọn exercise dự phòng từ catalog local.
- `lib/core/ai_local/local_ai_text_client.dart:22-34` chuyển yêu cầu sang `LocalAiRuntimeService` trên thiết bị.

## Ảnh hưởng

Người dùng có thể hiểu rằng cần chờ một dịch vụ mạng hoặc có thể tạo lại ngay sau khi model sẵn sàng, trong khi lịch mới vừa thêm vẫn còn hiệu lực và CTA đang khóa.

## Hướng sửa đề xuất

- Thay “dịch vụ” bằng hướng dẫn phù hợp với model AI trên thiết bị.
- Nói rõ lịch hiện tại vẫn được giữ và thời điểm tạo lịch kế tiếp; không hứa thao tác tạo lại khi CTA chưa khả dụng.

## Giới hạn xác minh

Rà soát source tĩnh; chưa tái hiện snackbar hoặc model fallback trên thiết bị.

