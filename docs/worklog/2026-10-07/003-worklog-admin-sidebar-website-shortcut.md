Commit de xuat: feat(admin-web): keep website shortcut visible

# Worklog - Đưa lối tắt Website NanoBio lên footer sidebar

## Thời gian

- Ngày: 2026-10-07
- Bắt đầu: khoảng 00:48
- Kết thúc: 00:58
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding, test, phát hành Admin Web
- Module chính: sidebar Admin Web
- Yêu cầu gốc: đưa nút Website NanoBio ra footer cố định và phát hành qua GitHub Pages.

## Đã làm

- Chuyển liên kết `/nanobio` khỏi nav cuộn sang footer cố định, trước trạng thái phiên và đăng xuất.
- Tạo kiểu CTA và trạng thái focus bàn phím, active, hover.
- Thêm test cho số lượng liên kết, vị trí footer, focus, điều hướng và đóng drawer mobile.
- Push commit `9dda724c` lên `main`; workflow GitHub Pages chạy thành công và asset phát hành chứa nội dung/class mới.

## File code/docs đã sửa

- `admin-web/src/components/AdminShell.tsx` - chuyển liên kết website vào footer.
- `admin-web/src/styles.css` - kiểu CTA và focus-visible.
- `admin-web/src/components/AdminShell.test.tsx` - kiểm tra điều hướng và drawer.
- `docs/worklog/2026-10-07/003-worklog-admin-sidebar-website-shortcut.md` - ghi nhận phiên.

## Tài liệu liên quan

- `.github/workflows/deploy-admin-web.yml` - workflow Pages hiện có, không chỉnh sửa.

## Commands

- `npm test`, `npm run typecheck`, `npm run build`: không chạy được vì shell không có `npm`.
- Chạy Vitest bằng Node 24 trực tiếp: PASS - 7 file, 47 test.
- Chạy TypeScript `tsc --noEmit`: PASS.
- Chạy TypeScript `tsc -b`: PASS.
- Chạy Vite production build bằng biến cấu hình kiểm thử: PASS; có cảnh báo chunk JS lớn hơn 500 kB.
- `git diff --check`: PASS.
- GitHub Actions run `37507360468`: PASS; typecheck, test, deployment config, build và deploy.
- Kiểm tra Pages HTML/CSS/JS qua HTTPS: PASS - HTTP 200, artifact có `Website NanoBio` và `.website-cta`.
- CUA browser: chưa xác minh tương tác/render thật vì browser policy không tải được; component test xác nhận focus và luồng click.

## Lỗi/Rủi ro

- Đã fix: lối tắt trước đây nằm cuối vùng cuộn và không hiện trong khung sidebar ban đầu.
- Chưa fix: không có.
- Cần kiểm tra tiếp: xem giao diện trong phiên Chrome/Admin thực tế khi CUA/browser hoạt động trở lại.

## Tỷ lệ hoàn thành

- Hoàn thành: 95% - code, test và phát hành xong.
- Đang đo: xác minh trực quan và phím Enter trên trình duyệt đã đăng nhập.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - sửa đúng link đang có, không tạo mục trùng và có test cho drawer.
- Mức độ hoàn thành task: đã phát hành; còn thiếu browser QA trực tiếp.
- Bằng chứng kiểm chứng: 47 test, typecheck/build local, workflow Pages thành công, asset live chứa marker.
- Điểm tốn token/chưa tối ưu: runtime Node không nằm trong PATH; dùng binary Node cài sẵn để chạy lệnh tương đương.
- Cách tối ưu cho phiên sau: bổ sung Node/npm vào PATH chuẩn và kiểm tra Browser CUA trước khi bắt đầu QA giao diện.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
