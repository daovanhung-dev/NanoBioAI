Commit de xuat: docs(worklog): ghi nhan phien build-apk-theme-parity

# Worklog - Dong bo giao dien APK release voi flutter run

## Thoi gian

- Ngay: 2026-08-11
- Bat dau: 23:38:34
- Ket thuc: 23:55:46
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: Core theme / Green Wellness release presentation
- Yeu cau goc: `flutter build apk` phai cho giao dien Green giong `flutter run`.

## Da lam

- Xac nhan hai lenh cung target `lib/main.dart` va khong co flavor/package Android rieng; khac biet la debug so voi release.
- Doi Green Wellness thanh mac dinh compile-time cho moi build mode; Blue chi con la rollback tường minh qua `STITCH_GREEN_UI_ENABLED=false`.
- Cap nhat regression test cho palette mac dinh Green va rollback Blue.
- Dong bo feature doc, release checklist va design coding plan; giu ro cac acceptance/production-readiness gate khac chua dat.
- Build APK release bang dung lenh `flutter build apk`, cai len Android va smoke man hinh onboarding Green Wellness.

## File code/docs da sua

- `lib/core/theme/app_theme_flags.dart` - sua default presentation flag thanh Green o moi build mode.
- `test/core/theme/theme_cutover_flag_test.dart` - sua contract default/rollback va palette compile-time.
- `docs/features/stitch-green-wellness/001-feature-stitch-green-wellness.md` - cap nhat chinh sach cutover.
- `docs/checklist/checklist_task_coding.md` - cap nhat checklist release palette parity.
- `.codex/design/15_CODING_PLAN.md` - lam ro Green mac dinh khong dong nghia cutover hoan tat.
- `docs/fixbug/build-apk-theme-parity/001-fixbug-build-apk-theme-parity.md` - ghi nhan root cause va cach sua.
- `docs/worklog/2026-08-11/001-worklog-build-apk-theme-parity.md` - ghi nhan phien nay.

## Tai lieu lien quan

- `docs/features/stitch-green-wellness/001-feature-stitch-green-wellness.md`
- `docs/checklist/checklist_task_coding.md`
- `.codex/design/15_CODING_PLAN.md`

## Commands

- `dart format --set-exit-if-changed lib/core/theme/app_theme_flags.dart test/core/theme/theme_cutover_flag_test.dart`: PASS.
- `flutter analyze lib/core/theme/app_theme_flags.dart test/core/theme/theme_cutover_flag_test.dart`: PASS.
- `flutter test test/core/theme/theme_cutover_flag_test.dart`: PASS, 2 tests.
- `flutter test --dart-define=STITCH_GREEN_UI_ENABLED=false test/core/theme/theme_cutover_flag_test.dart`: PASS, 2 tests.
- `flutter build apk`: PASS, release artifact `build/app/outputs/flutter-apk/app-release.apk` (166.5 MB).
- `flutter install -d 12b304f9 --release --use-application-binary=build/app/outputs/flutter-apk/app-release.apk`: PASS; Flutter replaced the prior installed instance.
- Android release smoke: PASS; onboarding rendered Green Wellness palette.
- `flutter build apk --dart-define=STITCH_GREEN_UI_ENABLED=false`: PASS; rollback artifact hash khac voi APK Green, sau do APK Green da duoc khoi phuc lam artifact mac dinh.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check`: PASS.

## Loi/Rui ro

- Da fix: release APK mac dinh Blue khac giao dien `flutter run`.
- Chua fix: release khong duoc ky la production-ready chi dua tren thay doi palette; visual/accessibility, privacy, license, Supabase va cac acceptance gate khac van mo.
- Can kiem tra tiep: chay ma tran visual 76 surface va release acceptance da duoc ghi trong checklist.

## Ty le hoan thanh

- Hoan thanh: dong bo Green/Blue palette giua `flutter run` va `flutter build apk`, co regression test, build va Android smoke evidence.
- Dang do: cac gate release rong hon khong thuoc pham vi yeu cau nay.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - root cause duoc xac nhan bang build mode, compile-time flag va APK release tren thiet bi that.
- Muc do hoan thanh task: hoan thanh pham vi da chot.
- Bang chung kiem chung: analyzer, hai cau hinh test, hai build APK va Android smoke.
- Diem ton token/chua toi uu: dieu tra Android runtime config can tach khoi palette de tranh mo rong sang Auth/AI ngoai pham vi.
- Cach toi uu cho phien sau: dung cu luon `flutter build apk` va regression test theme truoc khi mo rong visual acceptance.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
