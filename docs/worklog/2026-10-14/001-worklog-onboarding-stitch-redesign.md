Commit de xuat: feat(onboarding): redesign onboarding theo Stitch Blue Wellness

# Worklog - Tái thiết kế onboarding theo Stitch Blue Wellness

## Thời gian

- Ngày: 2026-10-14
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M01 `ONBOARDING_PROFILE` / onboarding UI
- Yêu cầu: dùng bộ Stitch trong `docs/refactor/stitch_nanobioai_onboarding_blue_wellness` làm tham chiếu, thiết kế lại toàn bộ màn onboarding đang hoạt động, dùng tài sản/copy của ứng dụng, giữ nguyên luồng và nghiệp vụ.

## Đã làm

- Tái thiết kế trang vào, cổng cỡ chữ, Welcome và 8 bước trong `OnboardingPage` theo cùng ngôn ngữ Blue Wellness: nền sáng thoáng, xanh biển và xanh lá, bề mặt bo góc, nét lá/nước và hình Nabi từ asset local.
- Xây lại khung bước dùng chung với tiến độ 9 phần, nhãn ngữ cảnh, Nabi, vùng nội dung cuộn và CTA cố định.
- Sắp xếp lại thông tin cơ bản, mục tiêu, điều kiện sức khỏe, nhịp sống, thông tin bổ sung, timeline ngày thường/cuối tuần, đồng ý và xem lại hồ sơ; giữ nguyên provider, khóa dữ liệu, validation, lưu hồ sơ, sửa từng phần và callback hiện có.
- Bổ sung minh họa vector theo từng mục tiêu, cùng màu điểm nhấn luân phiên xanh biển/xanh lá; thêm các cảnh vector thiên nhiên cho giấc ngủ, vận động và nước uống.
- Dùng motion chung theo hướng tiến/lùi, reveal nhẹ và trạng thái lựa chọn; `AppMotionScope`/`MediaQuery.disableAnimations` đưa component về trạng thái cuối khi bật Reduce Motion.
- Dùng dữ liệu giả lập trên thiết bị để rà flow đến trang xem lại. Không xác nhận CTA tạo lộ trình nên không lưu hồ sơ hay gọi dịch vụ AI.
- Điều chỉnh lưới mục tiêu và cặp chiều cao/cân nặng theo bề rộng 320 dp; đổi các biểu tượng emoji còn lại ở thông tin giới tính/tình trạng sức khỏe sang icon vector.
- Căn giữa viên logo trang vào, rút gọn nhãn Nabi bị cắt ở màn mục tiêu và xem lại, và thay nhãn lặp trong ghi chú Nabi bằng biểu tượng lá.
- Rà cỡ chữ hệ thống 1.3 trên cả chín bước: nội dung dài vẫn cuộn được, CTA ghim còn hiển thị. Tiêu đề accordion thông tin bổ sung được phép xuống tối đa hai dòng.
- Phát hiện hàng nhãn trên cổng cỡ chữ bị tràn ở 360 dp; đổi sang `Wrap`. Dựng preview tạm cả 9 bước ở dark mode/text scale 1.3; sửa nút chọn giờ timeline để nhãn dài xuống dòng trên màn hẹp.
- Dựng preview riêng cho cổng cỡ chữ ở theme sáng/text scale 1.3 và theme tối/text scale chuẩn. Các harness và ảnh preview đều được xóa sau khi kiểm tra.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/pages/` - trang vào, cổng cỡ chữ và khung điều hướng onboarding.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/` - Welcome và chín bước, khung bước, component chung, motion, cảnh Nabi/thiên nhiên, nút timeline thích ứng.
- `test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart` và `onboarding_entry_overlap_test.dart` - kiểm tra route, motion và hình học bố cục hiện hành.
- `docs/refactor/stitch_nanobioai_onboarding_blue_wellness/` - bản Stitch nguồn dùng để đối chiếu.
- `docs/worklog/2026-10-14/001-worklog-onboarding-stitch-redesign.md` - worklog phiên triển khai và QA.

## Bằng chứng kiểm tra

- `dart format lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart`: PASS.
- `flutter analyze` cho 16 file onboarding đã sửa: PASS, không có issue.
- Focused onboarding widget tests: PASS, 6 tests; xác nhận motion/route, bố cục Entry ở chữ lớn, catalog asset Nabi và asset team của màn consent.
- Preview tạm ở viewport 360x825 dp: cổng cỡ chữ sáng với text scale 1.3 và tối với text scale chuẩn: PASS; chín bước ở dark mode/text scale 1.3: PASS sau khi sửa tràn nút timeline. Harness và ảnh preview đã được xóa sau khi xem.
- `flutter analyze lib/app_versions/v1/features/onboarding/presentation`: PASS, không có issue.
- `git diff --check`: PASS.
- Dart MCP `hot_reload`: PASS. `get_runtime_errors`: không có lỗi runtime.
- QA trực quan trên Xiaomi 220333QPG, 720x1650 px (360x825 dp): đã xem Entry, Welcome, Basic Info, Goals, Conditions, Lifestyle, Extras, Daily Routine, Consent và Review; nội dung dài cuộn dưới CTA cố định.
- QA chữ lớn ở system font scale 1.3: đã xem Entry và cả chín bước; tiêu đề/lưới xuống dòng, nội dung cuộn, CTA ghim vẫn thao tác được. Khôi phục `font_scale` về giá trị ban đầu 0.86.
- Mở bàn phím tại trường họ tên trên thiết bị với system font scale 1.3: CTA tiếp tục vẫn nằm phía trên bàn phím, phần form còn cuộn được; đóng bàn phím và khôi phục scale 0.86, không sửa nội dung trường.
- Cổng cỡ chữ không xuất hiện trên thiết bị do tùy chọn hiển thị đã được cấu hình; đã có preview cô lập ở viewport điện thoại.
- Chưa rà toàn bộ flow onboarding ở dark mode trên thiết bị; preview widget tối đã rà đủ chín bước ở text scale 1.3.

## Tài liệu liên quan

- `docs/refactor/stitch_nanobioai_onboarding_blue_wellness/`
- `.codex/design/README.md`
- `.codex/design/15_CODING_PLAN.md`
- `.codex/domains/onboarding.md`

## Lỗi/Rủi ro

- Test toàn thư mục onboarding trước đó bị chặn ở `onboarding_guest_retry_identity_test.dart` và `onboarding_local_datasource_test.dart` vì host thiếu `libsqlite3.so`.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các backticked path cũ trong hai file history/task-skill không liên quan tới onboarding; không sửa ngoài phạm vi.
- Chưa xác minh trực quan toàn bộ flow onboarding ở dark mode trên thiết bị; widget preview tối đã chạy đủ chín bước.
- QA dừng ở trang Review; không gửi dữ liệu sức khỏe, không lưu hồ sơ và không gọi AI.

## Tỷ lệ hoàn thành

- Hoàn thành: tái thiết kế mã nguồn các màn onboarding đang chạy, kiểm tra tĩnh, kiểm tra route, preview cổng cỡ chữ và rà toàn flow trên thiết bị ở sáng/cỡ chữ lớn.
- Còn thiếu bằng chứng trực quan: dark mode trên thiết bị thật; toàn bộ chín bước đã có widget preview dark ở cỡ chữ lớn.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - giữ nguyên hợp đồng dữ liệu/điều hướng, dùng theme semantic và tài sản cục bộ, bố cục cuộn được và có CTA ổn định.
- Mức độ hoàn thành task: hoàn tất triển khai; dark mode toàn flow chưa có ảnh xác minh trên thiết bị.
- Bằng chứng: analyzer, focused widget tests, preview đủ chín bước dark ở cỡ chữ lớn, preview cổng cỡ chữ sáng/tối, hot reload, kiểm tra runtime, diff whitespace và ảnh chụp nhiều bước trên thiết bị thật.
- Điểm tốn thời gian: điều khiển nhiều bước trên thiết bị qua ADB cần lặp lại thao tác khi animation chuyển trang chưa kết thúc.
- Cách tối ưu phiên sau: dùng Flutter driver với khóa bước/CTA để đi flow và chụp từng trạng thái; cấu hình fixture riêng cho text gate và dark theme.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
