Commit de xuat: fix(test): dong bo release gate tests voi source hien tai

# Fixbug - Google Play final pass

## Kết luận

Đã thực thi plan Google Play Final Pass trên HEAD hiện tại
`a1ef0ed11b935d16dcdf801300ded3c6979363bb`. File plan mà yêu cầu nêu ra
(`docs/tasks/PLAN_GPT_LUNA_GOOGLE_PLAY_PUBLISH_NANOBIOAI.md`) không tồn tại;
phiên này dùng plan Final Pass gần nhất:
`docs/tasks/NanoBioAI_Google_Play_Final_PASS_Execution_Plan_GPT-5.6-Luna_2026-08-29.md`.

Kết quả là `IMPLEMENTATION_COMPLETE / RELEASE_VERIFICATION_BLOCKED_EXTERNAL`.
Các test contract liên quan release đã được đồng bộ với source hiện tại và pass;
AAB release build pass. Chưa thể kết luận production GO vì full suite còn fail,
và các cổng Play Console, thiết bị Android, public legal URL, Supabase sandbox
và tài khoản mua thử không có trong môi trường này.

## Thay đổi trong phạm vi

- Đồng bộ constructor test Food Scan với API hiện tại (`pickerService`).
- Đồng bộ AI Chat screen test với UI hiện tại dùng `Icons.auto_awesome_rounded`,
  thay cho asset mascot đã bị loại khỏi màn hình.
- Xóa import `sqflite` không được dùng trong generated-plan auth test.
- Làm matcher Supabase rebuild README chịu được line-wrap và khác biệt hoa/thường,
  không nới lỏng nội dung contract cần kiểm tra.
- Cập nhật [release evidence matrix](../../release/google_play/RELEASE_EVIDENCE_MATRIX.md)
  và [release README](../../release/google_play/README.md) bằng artifact/run mới.

Không thay đổi production Dart/Kotlin, schema/RLS, Edge Function deployment,
membership grant rule, signing material, credential hay Play Console state.

## Kiểm chứng local

Evidence root của run:
`/tmp/nanobio-release-validation/20260831T210948Z-a1ef0ed`

- `flutter pub get`: PASS.
- `flutter analyze`: PASS, `No issues found!`.
- Deno handler tests: PASS — `nabi-ai-generate` 10/10, `report-ai-content`
  4/4, `delete-account` 5/5, `google-play-verify-purchase` 4/4,
  `food-scan-analyze` 11/11.
- Release-focused Flutter contracts: PASS cho Billing, purchase verification,
  account deletion, AI reporting, Sleep Safety, Food Scan, notifications,
  Supabase rebuild và secret isolation.
- Full Flutter suite dùng alias test-only cho `libsqlite3.so.0`: `1144 PASS /
  79 FAIL`; command timeout sau 600 giây trong teardown, kèm lỗi
  `Cannot close sink while adding stream`. Các failure còn lại gồm legacy/admin
  route và UI expectation ngoài release-focused set; vì vậy full-suite gate là
  `NO-GO`, không bị che bằng skip.
- `flutter build appbundle --release`: PASS.
- AAB: `build/app/outputs/bundle/release/app-release.aab`, SHA-256
  `dbcf473c27d27ab36fe5dd130170dbba287609538cf4ec32866c41b992eb22ee`,
  128,427,356 bytes, package `com.nanobioai.app`, version `1.0.0`, versionCode
  `1`, target/compile SDK `36`.
- Native ELF static check: all extracted `LOAD` alignments are `0x4000` or
  `0x10000`; this is not a 16 KB device/install test.
- Secret/permission scan: no tracked provider key marker, private-key value,
  broad photo/media permission or local endpoint in the checked Android/lib
  source; arm64 artifact strings contain no Gemini key marker/provider URL.
- `supabase functions list`: remote functions are ACTIVE; `supabase status` bị
  chặn vì máy không có Docker/Podman, nên chưa có local/sandbox DB runtime proof.

## External gates còn mở

- Google Play internal-track purchase với tester account và cả bốn sản phẩm.
- Play App Signing/app upload identity và install/update trên track thật.
- Data Safety, Health Apps và foreground-service declarations trong Play Console.
- Public HTTPS Privacy Policy/account deletion URL với legal owner/contact/retention
  data thật; repo hiện chỉ có draft/placeholder.
- Android device acceptance cho foreground microphone, notification/alarm và 16 KB.
- Supabase local/sandbox rebuild, RLS two-session isolation, replay/idempotency,
  deletion E2E và authorized AI/Food Scan runtime.

## Handoff

Handoff source-only được tạo sau khi hoàn tất matrix:
`docs/release/google_play/NanoBioAI_GOOGLE_PLAY_FINAL_PASS_SOURCE_READY_20260901.zip`.
Archive đã được list, kiểm tra path traversal/duplicate path, `unzip -t` và
giải nén thử thành công. Archive chỉ chứa source/docs/test và các file context
do execution sửa/tạo; không chứa worklog runtime, AAB, cache, key, credential,
log nhạy cảm hoặc plan người dùng.

## Tự đánh giá

- Chất lượng: tốt — evidence tách rõ source/local artifact và external gate;
  không dùng static inspection để claim Play/runtime PASS.
- Mức độ hoàn thành: partial — code/test/docs local đã hoàn tất; release verify
  bị block bởi quyền truy cập và full-suite regressions.
- Điểm cần tiếp tục: sửa hoặc phân loại dứt điểm 79 full-suite failures, sau đó
  chạy device/Play Console/Supabase sandbox matrix với dữ liệu test được cấp.
- Task-skill: `.codex/task-skills/fix-issues.md`.
