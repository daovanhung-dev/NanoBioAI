Commit đề xuất: docs(test): xác minh đăng ký và đăng nhập thành viên bằng SĐT

# Kiểm thử - Tạo tài khoản và đăng nhập bằng số điện thoại

## Phạm vi

- M05 `AUTH_PROFILE_SYNC`.
- Đăng ký thành viên bằng SĐT và mật khẩu, sau đó đăng nhập bằng cùng SĐT.
- Không bật Supabase Phone Auth/SMS; Admin tiếp tục dùng email.

## Kết quả

- Flutter focused suite: PASS, 44/44 test.
- Production API smoke trước đó của project `rnwohifdnylqfofkydfl`: PASS khi tạo tài khoản qua `member-phone-signup` rồi đăng nhập Supabase Auth.
- Android 11 smoke bổ sung: PASS qua `SupabaseAuthRemoteDatasource` của app. Tạo tài khoản bằng SĐT/mật khẩu, đăng xuất, đăng nhập lại bằng cùng SĐT/mật khẩu và xác nhận Auth user ID không đổi.
- Source nối `V2RegisterPage` → `v2AuthControllerProvider.signUpWithPhone` → repository → datasource; đăng nhập nối `V2LoginPage` → `signInWithPhone` → cùng datasource. Datasource chuẩn hóa SĐT, gọi signup Edge Function và đăng nhập bằng alias.
- Widget tests đã chạy xác nhận form đăng ký/đăng nhập render và chấp nhận thông tin hợp lệ. Live smoke gọi datasource thật trên Android; chưa tự động nhập/chạm nút trong UI.
- Hai tài khoản smoke tổng hợp đã được tạo trên production qua các lượt kiểm thử. Số/mật khẩu lượt Android chỉ ở bộ nhớ, không được in hoặc ghi vào file; các tài khoản không bị xóa sau test.
- Snapshot production sau lượt smoke đầu ghi nhận bảy Auth identity cũ chưa chuyển sang alias. Trạng thái này chưa được query lại sau smoke Android.
- App chính được khởi chạy lại sau khi bỏ entrypoint smoke tạm. Chrome Dashboard có tab Auth Providers nhưng debugger không attach; chưa có bằng chứng thao tác Admin Web.

## Lệnh và bằng chứng

- `flutter test test/app_versions/v2/features/auth test/services/supabase/auth test/docs/supabase_member_phone_auth_contract_test.dart`: PASS, 44 tests.
- `flutter run --no-pub --dart-define-from-file=.dart_tool/nanobio_defines.json -d 12b304f9 -t tools/live_member_phone_auth_smoke.dart`: PASS, in `LIVE_MEMBER_PHONE_AUTH=PASS`; entrypoint thử nghiệm đã xóa sau khi chạy.
- `flutter analyze tools/live_member_phone_auth_smoke.dart`: PASS trước khi xóa harness.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_v2.ps1 -DeviceId 12b304f9`: build/install/chạy lại app chính thành công.
- `mcp__dart_mcp_server__widget_inspector(get_widget_tree)`: PASS, trả về cây widget có `V2RegisterPage`.
- `mcp__dart_mcp_server__get_runtime_errors`: PASS, không có runtime error.
- `git diff --check`: PASS. `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL vì manifest source truth bị thiếu và có stale path từ history/task-skill cũ ngoài phạm vi.
- Production signup/login smoke: tham chiếu `docs/worklog/2026-10-14/004-worklog-member-phone-simple-reset-production-smoke.md`.

## Giới hạn

- Chưa xác minh thao tác chạm/gửi form trực tiếp trên UI Android và chưa kiểm thử reset mật khẩu từ Admin Web.
- Bảy tài khoản Auth cũ cần được rà soát/chuyển đổi trước khi các tài khoản đó đăng nhập bằng SĐT.
