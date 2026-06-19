Commit đề xuất: docs(worklog): ghi nhận phiên release 1.0 bug audit

# Worklog - Release 1.0 bug audit

## Thời gian
- Ngày: 2026-06-19
- Bắt đầu: 20:30
- Kết thúc: 20:52
- Timezone: Asia/Saigon (+07:00)

## Phạm vi
- Loại task: review/audit/docs
- Module chính: toàn dự án, trọng tâm AI, Features Hub, route guard, onboarding logging, release checks
- Yêu cầu gốc: rà soát bug logic, UI/product, responsive, lag/chậm, tốn token AI; chỉ tạo bug docs trong `docs/issues`

## Đã làm
- Đọc context `.codex`, project map, docs workflow và playbook AI service.
- Chạy format dry-run, analyze và test theo kế hoạch, không tự sửa code.
- Audit các điểm nóng bằng `rg` và đọc code liên quan.
- Tạo 11 issue docs có bằng chứng cụ thể.

## File code/docs đã sửa
- `docs/issues/ai-chat-dotenv-uninitialized/001-issue-ai-chat-dotenv-uninitialized.md` - tạo - ghi bug crash AI chat khi dotenv chưa init.
- `docs/issues/ai-chat-unbounded-context-tokens/001-issue-ai-chat-unbounded-context-tokens.md` - tạo - ghi bug token/latency do chat session không giới hạn.
- `docs/issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md` - tạo - ghi bug log raw prompt/response AI.
- `docs/issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md` - tạo - ghi bug log snapshot dữ liệu onboarding.
- `docs/issues/features-hub-expansion-not-wired/001-issue-features-hub-expansion-not-wired.md` - tạo - ghi bug feature mới chưa nối route/hub.
- `docs/issues/features-hub-widget-test-stale/001-issue-features-hub-widget-test-stale.md` - tạo - ghi bug widget test Features Hub stale.
- `docs/issues/auth-guards-disabled/001-issue-auth-guards-disabled.md` - tạo - ghi bug route guard bị tắt.
- `docs/issues/new-care-pages-session-only-state/001-issue-new-care-pages-session-only-state.md` - tạo - ghi bug state cục bộ của page mới.
- `docs/issues/release-format-dry-run-fails-new-pages/001-issue-release-format-dry-run-fails-new-pages.md` - tạo - ghi bug format dry-run fail.
- `docs/issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md` - tạo - ghi bug analyze đỏ.
- `docs/issues/release-test-suite-fails/001-issue-release-test-suite-fails.md` - tạo - ghi bug test suite đỏ.
- `docs/worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md` - tạo - ghi nhận phiên audit.

## Tài liệu liên quan
- [AI Chat crash khi dotenv chưa được khởi tạo](../../issues/ai-chat-dotenv-uninitialized/001-issue-ai-chat-dotenv-uninitialized.md)
- [AI Chat giữ lịch sử không giới hạn làm tăng token và độ trễ](../../issues/ai-chat-unbounded-context-tokens/001-issue-ai-chat-unbounded-context-tokens.md)
- [AI service log raw prompt, raw response và hồ sơ sức khỏe](../../issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md)
- [Onboarding log toàn bộ snapshot hồ sơ sức khỏe sau khi lưu](../../issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md)
- [Features Hub expansion tạo page mới nhưng chưa hiển thị và chưa có route](../../issues/features-hub-expansion-not-wired/001-issue-features-hub-expansion-not-wired.md)
- [Features Hub widget test tìm AI Coach không còn tồn tại](../../issues/features-hub-widget-test-stale/001-issue-features-hub-widget-test-stale.md)
- [Dashboard và AI Chat đang tắt auth guard](../../issues/auth-guards-disabled/001-issue-auth-guards-disabled.md)
- [Các page chăm sóc mới hiển thị tương tác nhưng không lưu dữ liệu thật](../../issues/new-care-pages-session-only-state/001-issue-new-care-pages-session-only-state.md)
- [Dart format dry-run fail ở 6 page mới](../../issues/release-format-dry-run-fails-new-pages/001-issue-release-format-dry-run-fails-new-pages.md)
- [Flutter analyze đang fail với 290 issue](../../issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md)
- [Flutter test đang fail 3 case trước release 1.0](../../issues/release-test-suite-fails/001-issue-release-test-suite-fails.md)

## Commands
- `dart format --output=none --set-exit-if-changed .`: FAIL - 6 page mới cần format; không ghi file.
- `flutter analyze`: FAIL - 290 issues found.
- `flutter test`: FAIL - 3 test case fail.
- `rg ...`: PASS - dùng để tìm route, logging, AI, UI/perf pattern và feature mới.

## Lỗi/Rủi ro
- Đã fix: không sửa code theo yêu cầu, chỉ ghi docs bug.
- Chưa fix: toàn bộ issue trong `docs/issues` vẫn mở.
- Cần kiểm tra tiếp: responsive thực tế bằng emulator/device và Android APK build nếu muốn audit trước khi phát hành lên store.
