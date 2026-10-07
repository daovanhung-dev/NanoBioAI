Commit de xuat: docs(worklog): ghi nhan gallery NanoBio tu dien thoai that

# Worklog - Gallery NanoBio bằng điện thoại thật

## Thời gian

- Ngày: 2026-10-07
- Bắt đầu: 08:30
- Kết thúc: 08:55
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding/test/docs.
- Module chính: `admin-web` / landing NanoBio / gallery.
- Yêu cầu gốc: chụp sáu màn hình từ app đang cài trên Xiaomi 220333QPG, giữ nguyên dữ liệu; chỉ đưa ảnh không có thông tin định danh hoặc số liệu sức khỏe lên website.

## Đã làm

- Dùng app đã cài trên điện thoại Android 11, kích thước màn hình 720×1650. Không xóa dữ liệu, cài lại, đăng nhập/đăng xuất, hoàn tất onboarding, tạo dữ liệu mẫu hoặc bấm nút thử đồng bộ.
- Giữ Wi-Fi bật và dữ liệu di động tắt theo điều chỉnh của người dùng; cuối phiên xác nhận Wi-Fi bật, dữ liệu di động tắt, chế độ máy bay tắt. Đưa điện thoại về launcher.
- Mở sáu route yêu cầu. Chỉ màn Nabi Care không có thông tin cá nhân hay chỉ số sức khỏe; ảnh này được dùng. Năm ảnh còn lại được giữ nguyên vì màn tương ứng hiển thị thông tin tài khoản hoặc dữ liệu/tiến độ sức khỏe.
- Thay ảnh card cũ bằng ảnh Nabi Care 720×1650, cập nhật key và tiêu đề card, sửa lời giới thiệu để nói rõ gallery kết hợp ảnh chụp từ app và giao diện thiết kế có sẵn.
- Đặt ảnh gallery ở chế độ `object-fit: contain` và canh giữa để thấy trọn ảnh.
- Kiểm tra local demo trên desktop và viewport 390×844: menu mobile mở/đóng được; carousel tiến/lùi; cả sáu ảnh tải sau khi carousel đưa từng card vào vùng hiển thị; ảnh dùng `object-fit: contain`. Ảnh Nabi Care có kích thước nguồn 720×1650.
- Các thay đổi đồng thời trong `data.ts` và `landing.html` được giữ nguyên. Cập nhật renderer trong `website-controller.ts` để dùng schema `WebsitePerson` hiện tại (nhóm, initials, nhãn và URL nguồn) và lọc đội ngũ dự án cho lưới tương ứng. Cập nhật các assertion trong `App.test.tsx` theo nội dung hero/trạng thái tính năng hiện tại.
- Giữ nguyên file không liên quan `docs/prompts/prompt.md` đang untracked.

## File code/docs đã sửa

- `admin-web/src/assets/nanobio/gallery-nabi-care.png` - thêm - ảnh chụp Nabi Care từ điện thoại.
- `admin-web/src/assets/nanobio/gallery-features.png` - xóa - được thay bằng ảnh Nabi Care có tên file tương ứng.
- `admin-web/src/pages/nanobio/assets.ts` - sửa - ánh xạ asset Nabi Care.
- `admin-web/src/pages/nanobio/data.ts` - sửa - đổi card gallery sang Nabi Care; giữ nguyên chỉnh sửa đồng thời về hồ sơ người đồng hành.
- `admin-web/src/pages/nanobio/landing.html` - sửa - mô tả đúng nguồn ảnh đang có; giữ nguyên chỉnh sửa đồng thời về hero/điều hướng.
- `admin-web/src/pages/nanobio/styles.css` - sửa - hiển thị ảnh gallery trọn khung.
- `admin-web/src/pages/nanobio/website-controller.ts` - sửa - tương thích renderer với schema người đồng hành đang có trong `data.ts`.
- `admin-web/src/App.test.tsx` - sửa - đồng bộ assertion với nội dung hiện tại của landing.
- `docs/worklog/2026-10-07/006-worklog-nanobio-gallery-real-device.md` - thêm - ghi nhận kết quả và giới hạn.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/task-skills/coding.md`

## Commands

- `npm test` - PASS (61/61) sau khi đồng bộ renderer và assertion với các thay đổi nội dung đồng thời.
- `npm run typecheck` - PASS.
- `npm run build` - PASS; Vite hiện cảnh báo chunk JavaScript lớn hơn 500 kB.
- `git diff --check` - PASS.
- Chrome desktop/mobile QA - PASS cho gallery, nguồn ảnh đã tải, `object-fit: contain`, menu mobile và điều hướng carousel. Ảnh Nabi Care hiển thị trọn trong card ở viewport 390×844.
- ADB - PASS: thiết bị 720×1650; cuối phiên Wi-Fi bật, mobile data tắt, airplane mode tắt.

## Lỗi/Rủi ro

- Đã fix: ảnh gallery mới được đặt trọn trong khung; ảnh Nabi Care được thay và gắn đúng tiêu đề. Renderer tương thích schema người đồng hành mới; kiểm tra cuối test/typecheck/build đều xanh.
- Chưa fix: năm màn còn lại không được đưa lên website do chứa thông tin tài khoản hoặc số liệu/tiến độ sức khỏe. Giữ asset cũ đúng theo tiêu chí riêng tư.
- Khi app dùng Wi-Fi, màn Dashboard đã báo có đồng bộ đang chờ; không bấm thử lại. Không xác minh trạng thái đồng bộ nền.

## Tỷ lệ hoàn thành

- Hoàn thành: thay một ảnh an toàn, cập nhật mapping/tiêu đề/mô tả/CSS; đồng bộ renderer với schema hiện hành; test, typecheck, build và kiểm tra desktop/mobile đều hoàn tất.
- Giới hạn có chủ đích: năm ảnh còn lại được giữ nguyên do tiêu chí dữ liệu; gallery hiện có một ảnh chụp trực tiếp từ app và năm giao diện thiết kế có sẵn.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - chỉ ảnh không có dữ liệu định danh hoặc sức khỏe được đưa vào website.
- Mức độ hoàn thành task: hoàn thành phần an toàn; gallery chỉ thay được 1/6 ảnh.
- Bằng chứng kiểm chứng: ảnh 720×1650 từ điện thoại; quan sát route trên máy; desktop và viewport 390×844; trạng thái mạng cuối phiên; kết quả npm và diff-check.
- Điểm tốn token/chưa tối ưu: cold-start mỗi route trên điện thoại mất khoảng 15–40 giây.
- Cách tối ưu cho phiên sau: lấy từng ảnh sau khi route render xong và kiểm tra trước khi sao chép vào asset.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
