Commit de xuat: fix(m31): dong bo contact va dispatch giam sat giac ngu

# Worklog - M31 contact và dispatch giám sát giấc ngủ

## Thời gian

- Ngày: 2026-09-14
- Kết thúc ghi nhận: 21:52
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: Sửa bug runtime Flutter/native/Supabase integration và nghiệm thu Android máy thật.
- Module chính: M31 giám sát giấc ngủ, contact khẩn cấp, verification và emergency dispatch.
- Yêu cầu gốc: contact vừa lưu phải hiện bền vững; dispatch không bị native acknowledgement chặn; phải có retry/idempotency, trạng thái UI kết thúc rõ ràng và native alert được dismiss sau accepted.

## Đã làm

- Controller nhận `SafetyContact` từ RPC, merge ngay vào state, cache SQLite và chống stale refresh bằng generation guard.
- Validate tên, mối quan hệ, số điện thoại E.164/đầu số Việt Nam, priority và OTP; tự chọn priority còn trống; chuyển lỗi RPC/Edge thành thông báo tiếng Việt.
- Repository bắt buộc đồng bộ session rồi event lên Supabase trước dispatch; retry sync một lần và không gọi Edge Function khi sync thất bại.
- Native acknowledgement là best-effort; provider dispatch retry hai lần với cùng idempotency key; accepted/failed đều thoát spinner, failed có thể thử lại.
- Thêm `dismissAlert` cho Android/iOS sau khi server accepted.
- Giữ nguyên RPC/schema, contact verified, Plus/FamilyPlus, voice -> SMS fallback, server boundary và không gọi 115.
- Bổ sung regression tests cho contact/cache/priority/native failure/retry/idempotency/sync order và native crash contract.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart`
- `lib/app_versions/v1/features/sleep_tracking/data/repositories/sleep_safety_repository_impl.dart`
- `lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart`
- `lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_local_datasource.dart`
- `lib/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart`
- `lib/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart`
- `lib/core/storage/localdb/daos/sleep_safety_dao.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart`
- `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt`
- `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt`
- `ios/Runner/AppDelegate.swift`
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart`
- `test/app_versions/v1/features/sleep_tracking/data/sleep_safety_repository_impl_test.dart`
- `test/app_versions/v1/features/sleep_tracking/sleep_safety_start_crash_contract_test.dart`
- `docs/fixbug/sleep-safety-contact-dispatch/001-fixbug-sleep-safety-contact-dispatch.md`

## Commands và bằng chứng

- Flutter SDK khôi phục theo `android/local.properties`: `/home/daovanhung/development/Flutter/flutter`, Flutter 3.47.1, Dart 3.13.1.
- `flutter pub get`: PASS.
- `dart format` trên đúng tập file M31: PASS, không còn file cần format.
- `flutter analyze`: PASS, `No issues found!`.
- Flutter focused suite: PASS 15/15.
- Deno verification/dispatch tests: PASS 4/4.
- `flutter build apk --debug -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS.
- `adb -s 12b304f9 install -r --no-streaming build/app/outputs/flutter-apk/app-debug.apk`: PASS.
- `adb -s 12b304f9 shell monkey -p com.nanobioai.app 1`: PASS; PID sau launch `28269`; logcat không có `FATAL EXCEPTION` hoặc `AndroidRuntime`.
- Đã điều hướng tới tile Giám sát giấc ngủ trên máy thật; route yêu cầu đăng nhập. Không có credential/OTP test được cung cấp nên chưa chạy được các bước add contact, verification, dispatch và native dismiss end-to-end.
- `supabase functions list`: PASS; verification, dispatch và webhook đều `ACTIVE` trên remote project.
- `supabase status`: BLOCKED vì máy kiểm thử không có Docker/Podman cho local runtime.
- Provider voice/SMS: `UNVERIFIED/BLOCKED`; thiếu `SLEEP_SAFETY_PROVIDER_BASE_URL` và `SLEEP_SAFETY_PROVIDER_TOKEN`, nên không có bằng chứng provider nhận cuộc gọi/SMS thực tế.

## Lỗi/Rủi ro

- Đã fix ở code: contact bị refresh stale ghi đè; lỗi native chặn cloud dispatch; session/event chưa sync; provider retry thiếu idempotency; spinner vô hạn; thiếu native dismiss.
- Chưa thể nghiệm thu thực tế: cần tài khoản test/OTP hợp lệ và cấu hình provider secret trên Supabase runtime.
- Không claim provider accepted, voice/SMS thực tế hoặc native dismiss end-to-end khi chưa có dispatch accepted thật.

## Tỷ lệ hoàn thành

- Hoàn thành: implementation, regression tests, Deno tests, analyze, format, Android APK build/install/launch và crash smoke trên máy thật.
- `UNVERIFIED/BLOCKED`: nghiệm thu feature end-to-end trên máy thật và provider voice/SMS do thiếu credential/OTP và provider secret.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt trong phạm vi có thể kiểm chứng; code path và test regression đã bao phủ các nguyên nhân gốc, nhưng chưa đủ bằng chứng provider/runtime thật để kết luận production-ready.
- Mức độ hoàn thành task: chưa hoàn tất nghiệm thu bắt buộc; implementation/build/device launch hoàn tất, feature acceptance còn blocked.
- Bằng chứng kiểm chứng: Flutter analyze PASS, focused Flutter 15/15, Deno 4/4, APK installed/launched trên serial `12b304f9`, logcat không crash; contact/dispatch thực tế chưa chạy vì login/provider.
- Điểm tốn token/chưa tối ưu: cần phục hồi Flutter SDK và build native khá lâu; lần sau nên chuẩn bị sẵn SDK/cache và tài khoản test/provider sandbox trước khi bắt đầu.
- Cách tối ưu cho phiên sau: cung cấp test account/OTP, cấu hình provider sandbox secrets, chạy checklist 1-7 trên cùng serial, lưu evidence provider request id và kiểm tra duplicate theo idempotency key.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
