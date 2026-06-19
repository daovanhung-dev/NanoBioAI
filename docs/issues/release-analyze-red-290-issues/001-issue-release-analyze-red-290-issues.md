Commit đề xuất: docs(issue): ghi nhận lỗi flutter analyze fail trước release

# Flutter analyze đang fail với 290 issue

## Tóm tắt
- `flutter analyze` exit code 1 với `290 issues found`.
- Phần lớn là lint/deprecation, nhưng vẫn làm release check đỏ.

## Mức độ ảnh hưởng
- Severity: medium
- Ảnh hưởng user: gián tiếp, vì một số warning che khuất lỗi release thật.
- Ảnh hưởng dev/build/test: không thể coi nhánh hiện tại là release-clean.

## Cách tái hiện
1. Chạy `flutter analyze`.
2. Command exit code 1.
3. Output kết thúc bằng `290 issues found`.

## Đã xác nhận
- Warning đáng chú ý:
  - `lib/services/ai/ai_chat_service.dart:100:33` unnecessary non-null assertion.
  - `lib/features/ai_chat/presentation/pages/ai_chat_screen.dart:19:23` unused field `_maxContentWidth`.
  - Nhiều helper `_readInt`, `_readDouble`, `_readBool` không dùng trong localdb models.
  - Rất nhiều `withOpacity` deprecated trên UI.
- Một số issue nằm trong test imports không dùng.

## Giả thuyết
- Lint debt tồn tại lâu và tăng thêm sau các feature mới.

## Workaround
- Triage nhanh theo nhóm: warning có khả năng gây bug trước, style/deprecation sau.

## Hướng fix đề xuất
- Chốt policy release: analyze phải pass hoặc có baseline rõ.
- Sửa warning có impact trước: AI service, unused production fields, imports sai.
- Sau đó xử lý deprecated UI API theo batch có test.

## Files/log liên quan
- `lib/services/ai/ai_chat_service.dart`
- `lib/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- `lib/core/storage/localdb/models/*`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
