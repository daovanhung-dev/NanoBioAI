Commit đề xuất: fix(ai): tạo lịch bằng AI local trên Xiaomi

# Fixbug: AI local không tạo được lịch onboarding

## Phạm vi

- Luồng onboarding guest và tạo lịch cá nhân 7 ngày bằng Qwen3 0.6B Q4 trên Xiaomi.
- Yêu cầu 35 bữa, 14 bài tập và 77 sự kiện lịch được tạo, kiểm tra và lưu cục bộ.
- Không đăng nhập, không ghi fixture, hồ sơ hay lịch vào Supabase production.

## Lỗi đo được trên thiết bị

- Catalog SQLite v36 có 3.163 món; prefilter giữ 3.113 món cho request wellness tổng hợp.
- Prompt vừa context Qwen 2.048 token; trace cho thấy request đủ ngân sách, không bị từ chối do tràn context.
- Qwen trả về 5 mã món mỗi ngày, nhưng normalizer từ chối `meal_code_not_eligible`.
- Candidate enum trong prompt được tạo từ tập selectable chung. Một mã có thể nằm ngoài allowlist của slot đang tạo, dù normalizer vẫn fail-closed và dừng ngay.
- Inference trên Xiaomi kéo dài khoảng 120–145 giây cho bữa và 37–50 giây cho bài tập. Hai native thread tranh CPU với UI; Android từng ghi nhận một lần thoát `LOW_MEMORY` trước vòng chạy cuối.

## Sửa lỗi

- Giao candidate code cho từng slot bằng giao của shortlist với `eligibleCodesByType`; model không còn chọn được mã sai nhóm.
- Dùng schema JSON compact có ràng buộc slot, sau đó ghép mã model chọn vào slot eligible bằng matching. Nếu không có matching đầy đủ hoặc mã bị trùng, request tiếp tục fail-closed.
- Tính ngân sách compact output và token trên nội dung thực gửi, gồm wrapper prompt; không cắt bớt kiểm tra an toàn.
- Giới hạn native inference Android còn một worker để UI tiếp tục nhận input trong lúc Qwen suy luận.
- Bổ sung trace allowlist chỉ ghi metadata an toàn: context/token count, candidate count, duration, source và error code. Không ghi prompt, response, tên món hay hồ sơ sức khỏe.
- Không đổi API/schema công khai, quota, horizon, fallback policy hoặc allergy/avoid-food safety.

## Bằng chứng debug trên Xiaomi

- Thiết bị: Xiaomi `220333QPG`; RAM tổng xấp xỉ 3,77 GB; model Qwen3 0.6B Q4_K_M.
- Chạy guest synthetic qua onboarding UI thật bằng ADB, khi airplane mode bật và Wi-Fi tắt.
- 7/7 ngày vượt qua validate AI cho bữa và bài tập; trace không có fallback.
- SQLite request: `succeeded`, 7 ngày, 35 bữa, 14 bài tập, 77 schedule items, `generation_source=ai`, `actor_mode=initial_guest`, không có error và không còn staging.
- Cả 35/35 bữa và 77/77 schedule items có `ai_generated=1`; UI timeline tải được các mốc trong ngày và hiện 0/11 hoàn thành cho ngày được chọn.
- Sau khi giới hạn Android còn một thread, UI cập nhật tiến độ và không có ANR mới; exit-info các lần sau là stop/install do QA. Lần `LOW_MEMORY` được ghi nhận trước vòng chạy thành công.
- Guest profile là dữ liệu tổng hợp và chỉ lưu cục bộ. Không đăng nhập hoặc ghi Supabase.

## Kiểm thử và build

- 3 test regression cho compact JSON, allowlist từng slot và fail-closed candidate: PASS.
- 36 test request store, resume, service auth và meal normalizer: PASS.
- `dart analyze` các file AI/runtime/test liên quan: PASS; `git diff --check`: PASS.
- Debug APK build và QA trên Xiaomi: PASS.
- Full `flutter analyze --no-pub` chưa xanh: phần `iot/xiaozhi-esp32/phone_app` thiếu các package riêng và có một info `use_build_context_synchronously` ở dashboard ngoài phạm vi.

## Giới hạn release QA

- Release APK build thành công, nặng 649,3 MB; `apksigner` xác nhận chữ ký release hợp lệ.
- Xiaomi/MIUI hủy cài đặt cả release và debug bằng `INSTALL_FAILED_USER_RESTRICTED`. Logcat ghi `com.google.android.verifier` và MIUI `AdbInstallActivity`; trang system verifier trên máy hiển thị thời gian chờ 24 giờ cho ứng dụng từ nhà phát triển chưa xác minh.
- Android ghi rõ ADB install không nên bị ảnh hưởng bởi thời gian chờ và chưa hỗ trợ lệnh ADB để bỏ qua advanced-flow delay. Trên thiết bị này, MIUI/verifier vẫn từ chối các session ADB; không can thiệp/bypass cơ chế bảo vệ. Xem [Android developer verification FAQ](https://developer.android.com/developer-verification/guides/faq).
- Do release APK chưa cài được, luồng onboarding và tạo lịch bằng release chưa được nghiệm thu. APK build và chữ ký đã kiểm tra; release device acceptance còn mở.
- Tại thời điểm kết thúc QA, Xiaomi đang offline (`airplane_mode=1`, `wifi=0`) và app đã bị gỡ để thử release; fixture SQLite và model QA được giữ trong `/tmp` trên máy build.

## Trạng thái

- Lỗi tạo lịch AI local đã được sửa và debug acceptance đạt trên thiết bị thật.
- Release install/acceptance bị chặn bởi system verifier/MIUI trên thiết bị hiện tại; cần thiết bị cho phép ADB install hợp lệ hoặc một phương án phân phối được xác minh để tiếp tục phần QA release.
- Không hạ safety threshold và không dùng fallback để đánh dấu thành công.
