Commit de xuat: feat(auth): mo loi dang nhap cho Guest va build authenticated

# Mở quyền đăng nhập cho người dùng

## Phạm vi

- Module: M05 `AUTH_PROFILE_SYNC`.
- Giữ nguyên v1 Guest, v2 authenticated và cơ chế đồng bộ có xác nhận.
- Không đưa `.env` đầy đủ hoặc khóa bí mật vào Flutter assets; chỉ đóng gói public Supabase client config đã whitelist.

## Thay đổi runtime

- Người dùng đang ở chế độ khách nhìn thấy thẻ **Đăng nhập để giữ hành trình lâu dài** trong Cài đặt.
- Có hai thao tác độc lập: **Đăng nhập** và **Tạo tài khoản mới**.
- Mục **Dữ liệu của bạn** của Guest điều hướng tới đăng nhập thay vì bị vô hiệu hóa.
- Các thao tác chỉ dành cho tài khoản như đổi mật khẩu, đăng xuất và xóa tài khoản không còn hiển thị cho Guest.
- Trạng thái tài khoản trong Cài đặt theo dõi auth event qua Riverpod để cập nhật sau đăng nhập/đăng xuất.

## Thay đổi build

- Thêm `tools/build_authenticated.ps1` để kiểm tra `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AUTH_EMAIL_REDIRECT_URL` và truyền `.env` bằng `--dart-define-from-file`.
- Bổ sung `assets/config/auth.env` chỉ chứa public Supabase client config để cả lệnh Flutter trực tiếp cũng có thể đăng nhập.
- Script build vẫn được giữ để kiểm tra và ghi đè cấu hình local theo môi trường.
- README hướng dẫn cả cách build trực tiếp và cách build có validate.

## Giới hạn kiểm chứng

- Môi trường thực thi hiện tại không có Flutter/Dart/PowerShell nên chưa chạy format, analyze, widget test hoặc build APK.
- Đã thực hiện kiểm tra tĩnh cấu trúc Dart, đường dẫn import, khóa cấu hình và contract script.
