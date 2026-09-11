Commit de xuat: docs(worklog): ghi nhan debug signup Auth V2 tren thiet bi that

# Worklog - Debug va sua signup Auth V2 tren Android that

## Thoi gian

- Ngay: 2026-09-11
- Bat dau: 11:51
- Ket thuc: 12:16
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix va runtime acceptance
- Module chinh: Auth V2, Supabase signup atomic, Android device run
- Yeu cau goc: chay app tren may that, tao tai khoan thu, tim nguyen nhan loi tao tai khoan va fix.

## Da lam

- Nap context NanoBio theo workflow bugfix va domain access/membership/referral.
- Xac minh Flutter SDK day du, Android device that, Supabase CLI linked project va runtime config ma khong in secret.
- Build/cai APK debug; khi streaming install bi Android tu choi, dung fallback `adb install -r --no-streaming` thanh cong.
- Tai hien sach luong dang nhap -> tao tai khoan voi du lieu hop le; request thanh cong va route toi verify email.
- Phan loai loi nhap email ban dau do Gboard Telex bien doi chuoi, khong phai backend/signup bug.
- Sua guard `_loading` trong register page de chan callback lap truoc frame rebuild.
- Them regression coverage cho controller single-flight signup.
- Kiem tra read-only Supabase sau signup va logcat app da loc thong tin nhay cam.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` - sua - chan submit dang ky lap.
- `test/app_versions/v2/features/auth/auth_controller_login_race_test.dart` - sua - regression cho signup single-flight.
- `docs/fixbug/auth-signup-real-device/001-fixbug-auth-signup-real-device.md` - tao - ghi nhan root cause, fix va evidence.
- `docs/worklog/2026-09-11/001-worklog-auth-signup-real-device.md` - tao - ghi nhan phien thuc thi.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `docs/supabase/01_build_system.sql` - chi doc contract, khong chay rebuild remote.

## Commands

- `powershell tools/prepare_dart_defines.ps1`: PASS - tao runtime defines, khong in secret.
- `flutter build apk --debug -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS.
- `adb install -r --no-streaming build/app/outputs/flutter-apk/app-debug.apk`: PASS.
- `dart format --set-exit-if-changed` file lien quan: PASS.
- `flutter analyze` source/test auth lien quan: PASS.
- Focused auth/config/error-translator/Supabase contract tests: PASS `42/42`.
- `flutter test test/app_versions/v2/features/auth/auth_pages_smoke_test.dart`: FAIL baseline 2 test do Flutter `ListTile` assertion; khong phai signup runtime.
- Supabase read-only post-signup query: PASS - recent auth/profile/health counts dong bo, trigger count `1`.
- Logcat loc theo PID app: PASS - khong co fatal/unhandled exception.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL baseline - thieu `docs/audit/source_truth_manifest.json` va mot so backticked path cu trong generated history/task-skill; khong phat sinh tu patch signup.

## Loi/Rui ro

- Da fix: cua so submit lap o register page duoc chan; controller single-flight co regression test.
- Chua fix: chua co inbox de xac nhan email va test tiep dang nhap/onboarding sau confirmation.
- Can kiem tra tiep: baseline ListTile assertion va auth-stream timeout neu muon dong bo full test suite rieng.
- Rate-limit tam thoi xuat hien trong phien debug; da dung retry de khong lam nhiem backend.

## Ty le hoan thanh

- Hoan thanh: build, cai/chay may that, signup success, remote read-only verification, fix guard, regression tests, docs.
- Dang do: email confirmation va dang nhap sau confirmation chua xac minh do khong co inbox truy cap duoc.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - da tach ro loi nhap lieu Telex, loi runtime va baseline test; khong ghi secret vao log/worklog.
- Muc do hoan thanh task: hoan thanh phan signup runtime va fix regression; email confirmation end-to-end con phu thuoc inbox.
- Bang chung kiem chung: device route toi verify email, APK sau patch, focused suite `42/42`, remote count read-only va logcat PID-filtered.
- Diem ton token/chua toi uu: ADB input theo ky tu cham do Gboard Telex; lan sau nen dung input method English hoac automation co clipboard an toan.
- Cach toi uu cho phien sau: preflight device keyboard/input method truoc khi nhap form, chup evidence chi khi state thay doi.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
