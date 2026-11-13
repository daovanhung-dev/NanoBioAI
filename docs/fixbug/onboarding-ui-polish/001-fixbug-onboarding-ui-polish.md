Commit de xuat: fix(onboarding): lam sach va rut gon onboarding

# Fix - Làm sạch nền và rút gọn onboarding

## Hiện tượng

- Nền onboarding còn họa tiết lá, vệt nước và các mảng tròn trang trí.
- Màn chọn cỡ chữ có nhiều nội dung giới thiệu cạnh tranh với phần xem trước và lựa chọn.
- Bước lịch sinh hoạt trình bày nhiều mốc cùng lúc thay vì hỏi lần lượt.
- Bước đồng ý có phần giải thích dài trên màn chính.

## Thay đổi

- Nền ambient dùng màu nền semantic thuần; hero entry bỏ các orb và nét vẽ lá/nước. Giữ Nabi, gradient hero và nội dung thao tác.
- Màn cỡ chữ chỉ còn tiêu đề ngắn, một câu xem trước cập nhật theo cỡ chữ, các lựa chọn và CTA “Tiếp tục”.
- Bước lịch sinh hoạt hỏi bảy câu theo thứ tự thức dậy, bữa sáng, bữa phụ sáng, bữa trưa, bữa phụ chiều, bữa tối và giờ ngủ; hoàn tất ngày thường rồi lặp lại cuối tuần. Mỗi câu có nút chọn giờ riêng và CTA “Tiếp tục”. Sau 14 câu, người dùng có thể mở các giờ ngủ trưa, tập luyện và bận tùy chọn. Nút quay lại đi về câu trước trước khi quay về bước onboarding trước.
- Bước đồng ý trình bày tóm tắt lưu trữ, sử dụng AI và lưu ý sức khỏe; chi tiết kỹ thuật nằm trong vùng mở rộng. Consent gate và điều kiện tiếp tục được giữ nguyên.
- Không đổi API, schema, persistence hoặc quy tắc xác nhận hồ sơ.

## Kiểm chứng

- `flutter analyze` trên 9 file Dart nguồn và test mới: PASS, không có issue.
- `flutter test --no-pub --reporter expanded test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS, 5 widget tests.
- `dart format` trên các file Dart đã sửa: PASS.
- Android visual/device smoke chưa chạy; kết quả là Flutter Linux widget-test evidence.

## Giới hạn

- Supabase sandbox, RLS, consent/audit production evidence và M01 device acceptance vẫn chưa được xác minh.
- M01 implementation progress không thay đổi.

## Bổ sung minh họa màn chọn cỡ chữ — 2026-11-13

- Tái sử dụng ảnh Nabi guide theo asset bundle đang bật, căn giữa phía trên preview; không thêm chữ hoặc nền trang trí.
- Ảnh có kích thước 112 dp ở màn thường, giảm xuống 88 dp khi viewport hẹp/thấp.
- Widget test xác nhận ảnh và preview cùng hiển thị, lựa chọn chữ vẫn hoạt động, và không phát sinh lỗi layout ở 390×844 / 320×640.

## Bổ sung Step 7 hỏi đủ dữ liệu lịch sinh hoạt — 2026-11-13

- Trước đây Step 7 chỉ hỏi 7 giờ chính cho mỗi hồ sơ; ngủ trưa, hai khung tập và giờ bận nằm trong phần mở rộng nên người dùng có thể bỏ qua các trường đang được lưu.
- Luồng mới hỏi lần lượt giờ thức dậy, 5 giờ ăn, giờ ngủ, ngủ trưa Có/Không và khung giờ nếu Có, hai khung tập, giờ bận Có/Không và khung giờ nếu Có. Hỏi đủ cho ngày thường và cuối tuần.
- Mỗi câu có minh họa Nabi; khung thời gian có nút chọn riêng cho giờ bắt đầu và kết thúc. Back quay lại câu trước và giữ câu trả lời.
- Giữ nguyên `DailyRoutinePreferences`, validator, xác nhận routine và persistence; không thay schema/API.
- Focused widget suite tăng lên 7 test; targeted analyzer và formatter pass. Android visual/device smoke chưa chạy.
