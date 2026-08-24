Commit de xuat: docs(worklog): ghi nhan fix nut tao lich AI

# Worklog - Personal Schedule AI Regeneration Button

## Thoi gian

- Ngay: 2026-08-24
- Bat dau: 00:07
- Ket thuc: trong phien hien tai
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: Lifestyle Schedule / Personal Schedule AI
- Yeu cau goc: thêm nút gửi yêu cầu AI tạo mới lịch trình cá nhân và chỉ cho
  phép bấm khi lịch hiện tại còn đúng một ngày.

## Da lam

- Xác nhận root cause là thiếu CTA tại `LifestyleSchedulePage`.
- Xác nhận pipeline tạo lịch mới đã tồn tại trong
  `DashboardController.generateAdditionalPlan()` và `GeneratedPlanService`.
- Expose `ScheduleHorizon` qua Riverpod provider dùng `ScheduleHorizonReader`.
- Thêm card CTA vào Lịch trình cá nhân.
- Khóa nút khi `remainingDays >= 2`; enable khi `remainingDays < 2` (0 hoặc 1 ngày).
- Thêm guard submit lần hai tại page.
- Khóa double tap trong lúc generation.
- Tái sử dụng auth/quota/preferences/error/upgrade flow hiện có.
- Invalidate horizon sau refresh/app resume/generation thành công.
- Thêm widget regression tests cho trạng thái enable/disable/loading.

## File code/docs da sua

- `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` - sửa - nối CTA với generation flow hiện có.
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_regeneration_card.dart` - tạo - card CTA và rule enable.
- `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart` - sửa - expose schedule horizon qua provider.
- `test/features/lifestyle_schedule/presentation/schedule_regeneration_card_test.dart` - tạo - regression widget tests.
- `docs/fixbug/personal-schedule-ai-regeneration-button/001-fixbug-personal-schedule-ai-regeneration-button.md` - tạo - mô tả bugfix.
- `docs/worklog/2026-08-24/001-worklog-personal-schedule-ai-regeneration-button.md` - tạo - worklog phiên.

## Tai lieu lien quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/lifestyle-schedule.md`
- `.codex/DOCS_WORKFLOW.md`
- `lib/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_horizon.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/data/datasources/schedule_horizon_local_datasource.dart`

## Commands

- Static grep `remainingDays < 2`: PASS - rule UI có ở CTA.
- Static grep submit guard `horizon == null || horizon.remainingDays >= 2`: PASS.
- Static check không có `DatabaseService|sqflite|DAO|Dao` trong page: PASS.
- `dart format`: SKIPPED - môi trường thực thi không có `dart`.
- `flutter analyze`: SKIPPED - môi trường thực thi không có `flutter`.
- `flutter test`: SKIPPED - môi trường thực thi không có `flutter`.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED - phiên chỉ có sparse delivery tree, không có toàn bộ worklog corpus/runtime PowerShell để regenerate an toàn.

## Loi/Rui ro

- Da fix: thiếu entry point tạo lịch mới trong Lịch trình cá nhân.
- Chua fix: không có lỗi ngoài phạm vi được sửa.
- Can kiem tra tiep: chạy targeted Flutter tests và device UAT trong checkout đầy đủ của repository.

## Ty le hoan thanh

- Hoan thanh: code + regression test source + docs theo phạm vi bugfix.
- Dang do: runtime verification trên Flutter/device do toolchain không có trong môi trường này.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay đổi nhỏ, tái sử dụng pipeline generation hiện có và không duplicate quota/AI logic.
- Muc do hoan thanh task: hoàn tất source change; runtime verification còn UNVERIFIED.
- Bang chung kiem chung: source baseline GitHub, horizon datasource/test hiện có, static guards trong delivery tree.
- Diem ton token/chua toi uu: GitHub code search index không trả kết quả nên phải dùng focused fetch theo path.
- Cach toi uu cho phien sau: chạy trong checkout đầy đủ có Flutter SDK để format/analyze/test và refresh generated history ngay trong cùng phiên.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
