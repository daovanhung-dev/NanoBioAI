Commit de xuat: docs(worklog): ghi nhan rut gon noi dung landing NanoBio

# Worklog - Rút gọn nội dung landing NanoBio

## Thời gian

- Ngày: 2026-10-07
- Bắt đầu: khoảng 09:35
- Kết thúc: 09:50
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding/test/docs.
- Module chính: `admin-web` / landing NanoBio.
- Yêu cầu gốc: giảm chữ cho người mới tìm hiểu ứng dụng Android; giữ route, nội dung pháp lý, trạng thái tính năng, CTA và luồng tương tác.

## Đã làm

- Rút hero về một thông điệp, mô tả ngắn và CTA tải Android; gộp phần lợi ích thành ba ý dễ quét.
- Rút gọn mô tả tính năng, gallery, CTA, metadata và footer; giữ nhãn trạng thái tính năng hiện hành.
- Gộp đội ngũ và nguồn chuyên môn thành dải năm hồ sơ, mỗi hồ sơ có tên, vai trò và liên kết nguồn; giữ lời làm rõ hồ sơ chuyên gia không đồng nghĩa bảo chứng ứng dụng.
- Rút hướng dẫn Android còn ba bước và FAQ còn bốn câu về giới hạn y khoa, số điện thoại/dữ liệu, ưu đãi Plus và nền tảng.
- Đo cùng cách đếm nội dung hiển thị: khoảng 1.295 từ trước và 714 từ sau, giảm xấp xỉ 44,9%. Phần modal, nội dung đồng ý, lưu ý y khoa và hướng dẫn an toàn không tính vào mục tiêu rút gọn.
- Kiểm tra ở desktop 1440×1000 và mobile 390×844: không có tràn ngang; hồ sơ, gallery, CTA và menu hiển thị; carousel cuộn được; modal mở, focus vào trường điện thoại và đóng được mà không gửi biểu mẫu.
- Giữ nguyên route, asset, API, kiểu dữ liệu và tương tác hiện có. Không sửa trang quyền riêng tư, consent, hoặc phần giải thích dữ liệu trong modal.

## File code/docs đã sửa

- `admin-web/src/pages/nanobio/landing.html` - rút gọn copy landing, tiêu đề và metadata.
- `admin-web/src/pages/nanobio/data.ts` - rút gọn nội dung tính năng và FAQ; giữ số mục FAQ ở bốn.
- `admin-web/src/pages/nanobio/website-controller.ts` - hiển thị hồ sơ đội ngũ/chuyên môn trong một dải gọn có liên kết nguồn.
- `admin-web/src/pages/nanobio/styles.css` - thêm kiểu responsive cho hồ sơ và điều chỉnh CTA gọn trên mobile.
- `admin-web/src/pages/NanoBioLandingPage.tsx` - rút gọn meta description động.
- `admin-web/src/App.test.tsx` - đồng bộ kỳ vọng tiêu đề landing.
- `admin-web/src/pages/nanobio/website-controller.test.ts` - kiểm tra hồ sơ nguồn, FAQ và ba bước cài đặt.
- `.codex/history/LEARNED_SKILLS.md`, `.codex/history/RISK_HISTORY.md`, `.codex/history/WORKLOG_INDEX.md`, `.codex/task-skills/README.md`, `.codex/task-skills/coding.md` - làm mới chỉ mục và lịch sử sinh tự động.
- `docs/worklog/2026-10-07/007-worklog-nanobio-landing-copy-trim.md` - ghi nhận thay đổi và kiểm chứng.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ui-nami.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `npm test`: PASS - 10 test files, 63 tests.
- `npm run typecheck`: PASS.
- `npm run build`: PASS - Vite build; còn cảnh báo chunk JavaScript 705.48 kB vượt ngưỡng 500 kB.
- `git diff --check`: PASS.
- Chrome local QA: PASS - desktop 1440×1000, mobile 390×844; menu keyboard, điều hướng section, carousel, hồ sơ và modal CTA được kiểm tra.
- Đếm copy hiển thị: PASS - giảm xấp xỉ 44,9% theo cách đếm đã dùng ở bản trước.

## Lỗi/Rủi ro

- Đã fix: phần giới thiệu dài và các mục đội ngũ/FAQ được rút gọn theo phạm vi.
- Chưa fix: không có lỗi thuộc phạm vi copy.
- Cần kiểm tra tiếp: cảnh báo bundle JavaScript lớn hơn 500 kB tồn tại sau build; không thuộc phạm vi nội dung landing.

## Tỷ lệ hoàn thành

- Hoàn thành: rút gọn nội dung, kiểm tra desktop/mobile, CTA, menu, carousel, test, typecheck và build.
- Đang dở: không.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đạt mức giảm chữ yêu cầu, giữ thông tin an toàn và nguồn hồ sơ.
- Mức độ hoàn thành task: hoàn tất theo phạm vi đã duyệt.
- Bằng chứng kiểm chứng: 63 test pass, typecheck pass, build pass, browser render desktop/mobile, modal focus/close và carousel cuộn được.
- Điểm tốn token/chưa tối ưu: lớp tiện ích trình duyệt làm các lệnh cuộn chung mơ hồ; điều hướng theo phần tử có định danh đã xác nhận được giao diện.
- Cách tối ưu cho phiên sau: dùng locator trong Shadow DOM và chờ trạng thái smooth-scroll/reveal ổn định trước khi chụp.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
