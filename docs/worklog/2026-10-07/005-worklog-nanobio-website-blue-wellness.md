Commit de xuat: docs(worklog): ghi nhan phien nanobio-website-blue-wellness

# Worklog - Đổi màu website NanoBio sang Blue Wellness

## Thời gian

- Ngày: 2026-10-07
- Bắt đầu: khoảng 07:40
- Kết thúc: 07:54
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: landing page và trang quyền riêng tư NanoBio
- Yêu cầu gốc: đồng bộ màu website công khai NanoBio với bảng màu Blue Wellness mặc định của app; giữ xanh lá cho sức khỏe/thành công, không thay đổi bố cục, nội dung, asset, tương tác, API, kiểu dữ liệu hoặc khu Admin Web.

## Đã làm

- Đổi nhận diện landing sang xanh biển: logo/điều hướng, liên kết, CTA, focus ring, bề mặt nhấn, các section ưu đãi và modal đăng ký.
- Dùng các token app `#285CC5`, `#1C478F`, `#3971D3`, `#E7EEFC`, `#F4F7FB`, `#14243A`; đưa bề mặt và chữ phụ cũ ngả xanh lá về xanh nhạt/trung tính.
- Giữ `#16845C` / `#0F6648` cho Health Score, trạng thái hoàn thành và thông báo thành công; giữ lỗi đỏ và vai trò cảnh báo màu hổ phách. Tối màu chữ cảnh báo nhẹ từ `#9A6710` sang `#98630D` để nâng tương phản.
- Đồng bộ nền, chữ, liên kết, đường viền và bóng đổ của trang quyền riêng tư.
- Kiểm tra trực quan landing và privacy trên desktop và viewport mobile 390×844; menu mobile mở đúng, modal CTA hiển thị, trường điện thoại có focus ring xanh. Nội dung và trạng thái sức khỏe/thành công giữ nguyên.
- Đo tương phản các cặp màu đại diện: chữ chính/nền 14.55:1, chữ phụ/nền 5.56:1, xanh chính/nền trắng 6.13:1, chữ trắng trên xanh CTA 6.13:1, chữ trắng trên nền xanh section 8.95:1, xanh sức khỏe/trắng 4.68:1, cảnh báo hổ phách/nền cảnh báo 4.66:1.

## File code/docs đã sửa

- `admin-web/src/pages/nanobio/styles.css` - thay màu giao diện landing bằng Blue Wellness và giữ màu xanh lá cho trạng thái sức khỏe/thành công.
- `admin-web/src/pages/nanobio/privacy.css` - đồng bộ màu nền, chữ, liên kết, đường viền và bóng đổ.
- `docs/worklog/2026-10-07/005-worklog-nanobio-website-blue-wellness.md` - ghi nhận phạm vi, thay đổi và kiểm chứng.

## Tài liệu liên quan

- `.codex/design/02_COLOR_LIGHT_DEPTH_SYSTEM.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ui-nami.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `npm test`: PASS - 9 test files, 61 tests; dùng Node cục bộ trong PATH của lệnh.
- `npm run typecheck`: PASS.
- `npm run build`: PASS - Vite build; còn cảnh báo bundle JavaScript 708.61 kB vượt ngưỡng 500 kB.
- `git diff --check`: PASS.
- Browser QA tại local dev: PASS - landing/privacy desktop và mobile; menu mobile, modal CTA và focus ring được kiểm tra trực quan.
- Tính tương phản WCAG cho các cặp màu đại diện: PASS - các cặp chữ/nền chính được đo đều đạt 4.5:1 trở lên; các cặp trạng thái sức khỏe và cảnh báo cũng đạt ngưỡng này.

## Lỗi/Rủi ro

- Đã fix: màu thương hiệu xanh lá cũ trên website công khai được thay bằng xanh Blue Wellness; các bề mặt xanh nhạt cũ được chuyển sang xanh biển/trung tính.
- Chưa fix: không có lỗi thuộc phạm vi đổi màu.
- Cần kiểm tra tiếp: cảnh báo bundle JavaScript lớn hơn 500 kB đã được build báo lại, không thuộc phạm vi thay màu.

## Tỷ lệ hoàn thành

- Hoàn thành: cập nhật CSS landing/privacy, kiểm tra responsive, menu, CTA modal, focus ring, trạng thái sức khỏe/thành công, tương phản, test, typecheck và build.
- Đang dở: không.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - thay đổi giới hạn ở hai stylesheet công khai; token màu bám design system và giữ nguyên vai trò sức khỏe/thành công.
- Mức độ hoàn thành task: hoàn tất theo phạm vi đã duyệt.
- Bằng chứng kiểm chứng: 61 test pass, typecheck pass, build pass, browser render desktop/mobile và phép đo tương phản đại diện.
- Điểm tốn token/chưa tối ưu: browser automation cần chờ animation/reveal khi chụp giao diện.
- Cách tối ưu cho phiên sau: chờ trạng thái reveal ổn định trước khi chụp và gom kiểm tra responsive theo route.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
