# Fixbug — Voice chỉ dành cho Plus, không trừ lượt

## Vấn đề

Luồng voice trước đó tái sử dụng quota `ai_chat_message` và yêu cầu consent
lưu cục bộ. Điều này không đúng yêu cầu sản phẩm mới: người dùng Plus cần vào
voice và nói ngay, không bị giới hạn lượt nội bộ; tài khoản Free không được
nhận Gemini token.

## Cách sửa

- Edge Function xác thực caller bằng JWT, đọc quyền server-derived từ
  `effective_user_access`, và chỉ mint token cho `plus`/`family_plus`.
- Bỏ check/commit quota, session id và mapping quota khỏi toàn bộ voice path.
- Giữ Gemini ephemeral token ở backend để không lộ API key và không cho Free
  mint token trực tiếp.
- Giao diện chỉ tạo `AiVoicePage` sau khi quyền Plus đã xác thực. Nếu quyền
  thay đổi đúng lúc bắt đầu, `403` được map thành thông báo nâng cấp Plus.
- Bỏ consent SharedPreferences/dialog; vẫn yêu cầu người dùng chạm **Bắt đầu**
  trước khi micro được mở.

## Bằng chứng

- Deno format/check/lint pass và 9 Deno Edge tests pass: JWT, Free 403, Plus
  mint, không request-id/quota, lỗi membership/provider redaction, AuthToken
  constraints và không lộ secret.
- Dart format, targeted Flutter analyze (0 issue) và 24 Flutter tests cho
  access gate/controller/protocol/gateway đều pass.

## Điều kiện nghiệm thu

Deploy Function và Edge secret, sau đó dùng tài khoản Plus/FamilyPlus active
trên Android thật để kiểm tra bắt đầu, audio hai chiều, chen lời, pause/resume,
Stop, background và reconnect. Project hiện vẫn trả 404 cho function chưa
deploy, nên chưa thể coi là voice hoạt động thật. APK mới đã được cài trên
Xiaomi: trang Plus-only và bỏ consent hiển thị đúng, nhưng chạm Bắt đầu vẫn
dừng tại lỗi server chưa sẵn sàng vì Function 404.
