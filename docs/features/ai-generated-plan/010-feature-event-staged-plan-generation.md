Commit de xuat: feat(ai): tao lich theo su kien va cho duyet mon rieng

# Tạo lịch theo sự kiện, lưu nháp theo ngày và duyệt món riêng

> Runtime update 2026-10-30: this note originally described local inference.
> Current Flutter runtime sends plan-generation prompts through the
> authenticated NanoBio backend; local text-model inference is removed. Guests
> can finish onboarding without an AI-generated initial plan, and AI requires
> sign-in. Deterministic catalog filtering/validation remains on-device and is
> not an AI fallback.

## Mục tiêu

Tạo lịch 7 ngày bằng AI backend theo từng ngày. Người dùng thấy tiến độ theo từng sự kiện đã được ghi vào nháp; mỗi ngày chỉ xuất hiện trong lịch chính sau khi toàn bộ sự kiện của ngày hợp lệ. Nếu bộ lọc cá nhân không còn món cho một suất, Nabi yêu cầu backend đề xuất món riêng ở trạng thái chờ duyệt.

## Kiểm tra danh mục trước khi tạo

- Trước AI và quota thành viên, kiểm tra nhãn buổi và loại bữa của mọi món đang hoạt động, đủ điều kiện cho lịch wellness. Nhãn thiếu, mơ hồ hoặc không được hỗ trợ làm dừng yêu cầu.
- Giữ bộ lọc cá nhân hiện có. Dùng hết món độc nhất trong đúng loại suất trước khi lặp lại; không mượn món từ loại suất khác.
- Nếu một loại suất không còn món sau lọc, gửi cho AI yêu cầu món riêng với danh sách ứng viên rỗng. Không chọn lại món đã bị lọc.

## Món riêng chờ duyệt

- AI phải trả về đúng cấu trúc: loại bữa, tên, mô tả, nguyên liệu, khẩu phần và các bước chế biến. Mã catalog, dinh dưỡng hoặc tuyên bố sức khỏe không được chấp nhận.
- Bản đề xuất được lưu trong staging theo yêu cầu, không ghi vào catalog. Màn hình nêu nguyên liệu/cách làm và cảnh báo dinh dưỡng, dị ứng chưa được xác minh.
- Yêu cầu tạm dừng cho tới khi người dùng chọn **Duyệt món** hoặc **Tạo món khác**. Tạo lại cập nhật đề xuất trong cùng yêu cầu; sự kiện không bị nhân đôi.
- Sau khi được duyệt, món tổng hợp chỉ dùng trong yêu cầu đó. Bản ghi lịch giữ `catalogCode` rỗng và `nutritionStatus=not_assessed`; trường số dinh dưỡng không hiển thị như dữ kiện đã xác minh.

## Staging sự kiện và tiến độ

- AI tạo danh sách món và bài tập theo từng ngày; các routine như thức dậy, uống nước và ngủ do ứng dụng dựng từ sở thích thời gian.
- Sau khi xác thực timeline ngày, lưu các sự kiện vào staging theo giờ tăng dần với mã ổn định, ngày, giờ, tên và trạng thái. Tiến độ được phát sau mỗi sự kiện.
- Chỉ gọi giao dịch ghi ngày vào lịch chính khi toàn bộ sự kiện của ngày hợp lệ và không còn món chờ duyệt. Request ID và event ID ổn định giúp tiếp tục sau gián đoạn mà không tạo trùng.
- Phần trăm bằng số sự kiện đã lưu/được chấp nhận chia tổng sự kiện thực tế, bao gồm điều chỉnh giờ và ngủ trưa nếu có; giá trị được chặn trong khoảng 0–100. Món chờ duyệt chưa tính hoàn tất.
- Panel dùng chung cho onboarding và tạo thêm lịch, giữ các ngày đã có sự kiện, nhóm theo **Ngày thứ 1–7**, sắp theo giờ và tự cuộn tới cuối danh sách. Danh sách món còn lại sau lọc vẫn hiển thị bên dưới.

## Quota và nguồn tạo

- Kiểm tra nhãn catalog trước khi kiểm tra quota thành viên. Quota chỉ được commit sau khi yêu cầu hoàn tất và lịch đã lưu.
- Giữ trạng thái nguồn tạo hiện có; kế hoạch có thành phần fallback cục bộ không commit quota AI theo quy tắc trước đó.
- Không gọi dịch vụ AI từ xa; các lời gọi đề xuất và tạo lịch đi qua AI service cục bộ hiện tại.

## Kiểm chứng và giới hạn

- Regression lịch và prefilter: 32 test pass; có ca sai nhãn dừng trước quota, món riêng dừng trước khi lưu ngày, từ chối/tạo lại/duyệt, staging sự kiện và resume.
- Panel onboarding và hoàn tất onboarding: 11 widget/unit test pass, gồm tiến độ theo sự kiện và bố cục hẹp.
- Test cấu trúc món riêng: 2 test pass; một test xác nhận schema chính xác, một test từ chối trường thừa và kiểm tra retry.
- `flutter build apk --debug` thành công.
- `dart analyze` trên các file runtime/test liên quan: PASS, không còn issue sau khi thêm ngoặc nhọn cho nhánh lỗi staging. `dart format --set-exit-if-changed` và `git diff --check` PASS. `flutter devices` chỉ thấy Linux/Chrome; DTD không có app Flutter đang mở nên chưa kiểm tra hot reload hoặc inference Qwen trực tiếp.
- Toàn bộ `test/services/ai/ai_service_test.dart` còn hai lỗi trong test chat timeout/fallback cũ; cả hai phát sinh từ `AIChatService` và ngoài phạm vi thay đổi lịch trình. Các test món riêng mới trong cùng file đã pass.

## Tài liệu liên quan

- Lọc món trước tạo lịch: `docs/features/ai-generated-plan/009-feature-local-meal-catalog-prefilter.md`.
- Worklog: `docs/worklog/2026-10-19/001-worklog-generated-plan-event-staging.md`.
