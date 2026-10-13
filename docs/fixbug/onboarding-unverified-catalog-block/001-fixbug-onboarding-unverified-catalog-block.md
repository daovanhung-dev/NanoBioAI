Commit de xuat: fix(ai): truyền số lần dùng mã vào prompt tạo lịch

# Fixbug: lỗi tạo lịch khi catalog chưa đủ dữ liệu xác minh

## Cập nhật bằng chứng thiết bị 2026-10-13

Kết luận cũ bên dưới mô tả trạng thái app trước lần tái hiện có request AI. Nó không giải thích lỗi của lần chạy hiện tại: request đã gọi AI và ghi các chunk vào staging. Chẩn đoán hiện tại:

- Lượt tạo trước dừng với `exercise_code_reuse_limit`. Prompt bài tập chỉ nhận các mã đã dùng, còn normalizer giới hạn một mã tối đa hai lần khi còn lựa chọn ít được dùng hơn. `AIService._usedCodes()` đã làm mất số lần dùng khi chuyển map thành danh sách mã.
- Prompt bài tập đã được sửa để nhận số lần dùng và yêu cầu ưu tiên mã ít dùng, không lặp quá giới hạn khi còn lựa chọn khác. Lượt tiếp theo vượt qua các chunk bài tập đến ngày 5 nhưng dừng tại `meal:6` với mã chung `invalid_generation`; phiên bản khi đó chưa lưu mã lỗi validator thực đơn cụ thể.
- Prompt thực đơn sau đó cũng được sửa để truyền số lần dùng, nêu rõ giới hạn lặp và ngày chunk. Prompt version v5 tạo lại toàn bộ staging để không trộn đầu ra cũ/mới.
- Lần chạy v5 trên Xiaomi `220333QPG` hoàn tất: request `succeeded`, 7 ngày (2026-10-13 đến 2026-10-19), 35 bữa, 14 bài tập, 77 mục lịch. SQLite có 35 dòng `meal_plans`, 77 dòng `lifestyle_schedule_items`; staging trống. Dashboard mở lịch hôm nay.
- Mã nguồn Edge Function `nabi-ai-generate` đang hoạt động là version 13 và trùng với source local đã kiểm tra; không cần sửa hoặc deploy backend cho lỗi này.

Các mã lỗi FormatException thực đơn hiện được lưu dưới dạng mã ổn định như `meal_code_reuse_limit`, không lưu phản hồi AI hay nội dung sức khỏe.

## Kết luận trước lần tái hiện mới (đã bị bằng chứng runtime thay thế)

Với hồ sơ `in_progress` hiện có trên Xiaomi, đường tạo lịch bị chặn ở bộ lọc ứng viên trước khi gọi AI. Kiểm tra SQLite chỉ lấy số lượng cho thấy catalog có 163 món đang hoạt động nhưng không món nào có dinh dưỡng hoặc metadata ràng buộc ở trạng thái đã xác minh. Catalog bài tập có 40 dòng, trong đó 16 dòng đang hoạt động và không dòng đang hoạt động nào có trạng thái `condition_reviewed`.

Hồ sơ lưu trên máy có ràng buộc sức khỏe và mục tiêu cần dữ liệu dinh dưỡng đã xác minh. Theo logic hiện tại, món chưa có metadata xác minh và bài tập chưa được rà soát không đủ điều kiện cho hồ sơ này. Đây là chặn an toàn do dữ liệu thiếu, không phải bằng chứng lỗi từ AI, backend hay transaction SQLite. Không thể sửa đúng bằng cách bỏ bộ lọc hoặc đánh dấu dữ liệu chưa được rà soát thành an toàn.

## Thay đổi của chẩn đoán ban đầu

- Ghi giai đoạn, loại lỗi, mã lỗi và stack trace đã lọc tại điểm lỗi của `GeneratedPlanService`, `OnboardingController` và `ReviewStep`.
- Ghi số lượng catalog đang hoạt động và số ứng viên sau lọc theo loại bữa/bài vận động; không ghi hồ sơ, tên món/bài, prompt, phản hồi AI hay định danh.
- Phân loại lỗi thiếu ứng viên bằng mã `schedule_candidates_unavailable`.
- Ánh xạ `OnboardingInitialPlanException` sang thông báo cho biết hồ sơ đã lưu nhưng lịch chưa tạo; giữ thông báo an toàn cụ thể khi bộ lọc không có ứng viên.
- Bổ sung kiểm tra hồi quy cho giai đoạn/mã lỗi/log stack, thông báo onboarding và việc không đánh dấu hoàn tất khi thiếu ứng viên.

## Bằng chứng thiết bị của chẩn đoán ban đầu

- Xiaomi `220333QPG`, serial `12b304f9`: bản debug từ source build và khởi chạy thành công. Một lần hot reload báo thành công nhưng kết nối Flutter bị mất sau đó; lần `flutter run` cuối đã build/cài và mở lại source hiện tại.
- Sau khi mở app, màn hình là trang bắt đầu onboarding. Hồ sơ SQLite vẫn ở `in_progress`, nhưng `OnboardingController.build()` khởi tạo state trống và app không khôi phục bước Review sau khi tiến trình bị dừng.
- Không bấm tạo lịch trong lượt này vì không còn state biểu mẫu đang dở để gửi nguyên trạng; không tạo request AI và không tiêu thụ quota.
- Kết luận về bộ lọc dựa trên số liệu tổng hợp từ SQLite trên máy và mã selector/service. Không có trace runtime mới cho lần tạo trong ảnh và không có đối chiếu log backend.
- Không ghi giá trị hồ sơ hay dữ liệu định danh vào tài liệu.

## Kiểm chứng của chẩn đoán ban đầu

- `flutter test test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/review_step_error_message_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS.
- `flutter analyze` trên các file nguồn và test đã sửa: PASS, không có vấn đề.
- `flutter run -d 12b304f9 --debug`: build và cài bản debug PASS; app mở được trên Xiaomi.
- Hot reload qua Dart Tooling Daemon: PASS; lần chạy đầu không có runtime error khi truy vấn. Sau reload, kết nối thiết bị bị mất rồi được khôi phục bằng một lần build mới.
- Tạo lịch trên thiết bị: CHƯA THỰC HIỆN; cần catalog có bằng chứng phù hợp và state onboarding được khôi phục trước khi tái hiện bằng hồ sơ hiện có.

## Việc cần làm được ghi nhận ở lượt cũ

1. Bổ sung bằng chứng khẩu phần/nguyên liệu/dinh dưỡng cho các món, giữ `null` hoặc `unknown` khi nguồn không hỗ trợ kết luận.
2. Rà soát dị ứng và ràng buộc sức khỏe cho món trước khi bật khả năng chọn.
3. Hoàn tất rà soát an toàn cho bài tập đang hoạt động; không tự duyệt các bản ghi đang chờ.
4. Khôi phục hồ sơ onboarding đang `in_progress` vào Review sau khi mở lại app, rồi chạy một lần trên thiết bị và xác nhận kết quả lưu.
