Commit đề xuất: docs(codex): tối ưu context và workflow cho NanoBio

# Worklog - Tối ưu context Codex cho NanoBio

## Thời gian
- Ngày: 2026-06-19
- Bắt đầu: Không xác định trong phiên Codex
- Kết thúc: 2026-06-19 09:21:52 +07:00
- Timezone: Asia/Saigon

## Phạm vi
- Loại task: docs
- Module chính: `.codex`
- Yêu cầu gốc: Sửa lại `.codex` cho phù hợp với dự án, ưu tiên tiết kiệm token, làm đúng workflow và cho kết quả tốt.

## Đã làm
- Rà snapshot thật từ `pubspec.yaml`, `database_version.dart`, source folders và test folders.
- Rút gọn core docs bắt buộc đọc để giảm token cho các phiên sau.
- Cập nhật routing module, playbook và prompt theo cấu trúc hiện tại của repo.
- Ghi rõ workflow worklog/docs ngắn gọn hơn nhưng vẫn giữ quy tắc đánh số, link docs và kiểm chứng.

## File code/docs đã sửa
- `.codex/README.md` - sửa - mô tả cách đọc context mặc định và snapshot stack hiện tại.
- `.codex/AGENTS.md` - sửa - cô đọng luật vận hành, kiến trúc, flow sản phẩm, validation.
- `.codex/PROJECT_MAP.md` - sửa - cập nhật source map, feature folders, routing và search commands.
- `.codex/DOCS_WORKFLOW.md` - sửa - rút gọn workflow docs/worklog và template bắt buộc.
- `.codex/TOKEN_SAVING_RULES.md` - sửa - thêm default read pack, budget theo loại task, điểm dừng đọc.
- `.codex/CHECKLIST.md` - sửa - checklist ngắn trước/trong/sau khi sửa.
- `.codex/playbooks/*.md` - sửa - chuẩn hóa playbook theo module thật và test folder hiện có.
- `.codex/prompts/*.md` - sửa - rút gọn prompt mẫu theo workflow mới.
- `docs/worklog/2026-06-19/001-worklog-codex-context-optimization.md` - tạo - ghi nhận phiên chỉnh `.codex`.

## Tài liệu liên quan
- Không phát sinh docs feature/fixbug/test/issue vì đây là tối ưu context nội bộ, không đổi hành vi app.

## Commands
- `Get-Content pubspec.yaml -Raw`: PASS - xác nhận dependency/version.
- `Get-Content lib\core\storage\localdb\database_version.dart -Raw`: PASS - xác nhận DB version 8.
- `Get-ChildItem lib\features -Directory`: PASS - xác nhận feature folders.
- `rg --files lib\features\dashboard ...`: PASS - xác nhận file/module liên quan.
- `git diff --check -- .codex docs\worklog\2026-06-19`: PASS - không có whitespace error; Git có cảnh báo line ending LF/CRLF trên Windows.
- `Get-Content .codex\AGENTS.md -Encoding UTF8`: PASS - kiểm tra đọc UTF-8.
- `flutter pub get`: SKIPPED - chỉ sửa docs `.codex`.
- `dart format --set-exit-if-changed .`: SKIPPED - chỉ sửa Markdown.
- `flutter analyze`: SKIPPED - chỉ sửa docs `.codex`.
- `flutter test`: SKIPPED - chỉ sửa docs `.codex`.

## Lỗi/Rủi ro
- Đã fix: giảm độ dài file bắt buộc đọc, đặc biệt `DOCS_WORKFLOW.md`.
- Chưa fix: worktree trước phiên đã có nhiều thay đổi ngoài phạm vi, gồm `.env`, code app và một số file docs cũ bị xóa; phiên này không xử lý các thay đổi đó.
- Cần kiểm tra tiếp: nếu muốn chuẩn hóa line ending toàn repo, nên làm trong task riêng để tránh trộn diff.
