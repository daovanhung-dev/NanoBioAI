Commit de xuat: feat(ui): trien khai Nabi Kinetic Aura motion va feedback foundation

# Worklog - Coding Nabi Kinetic Aura toàn bộ ứng dụng

## Thời gian

- Ngày: 2026-08-05
- Bắt đầu: 20:36
- Kết thúc: 21:45
- Timezone: Asia/Saigon (UTC+07:00)

## Phạm vi

- Loại task: coding / test-contract / docs-context
- Workflow: `.codex/workflows/coding.md`
- Task skill: `.codex/task-skills/coding.md`
- Domain chính: UI/theme/Nabi copy
- Domain phụ có bằng chứng cross-domain: Dashboard, Onboarding, AI/Voice, Schedule/Notification, Access/Membership/Sale/Admin.
- Yêu cầu gốc: triển khai coding theo Nabi Kinetic Aura design, đồng bộ chuyển cảnh widget, micro-interaction, màu sắc, haptic và âm thanh nhỏ trên toàn ứng dụng.

## Invariants đã giữ

- Không thay đổi business logic, SQLite schema/migration, Supabase schema/RLS/RPC, quota hoặc access policy.
- Không thêm production mock data.
- Presentation vẫn đi qua provider/controller/repository hiện có.
- Không phát success trước khi local persistence, repository command hoặc trusted controller/RPC trả thành công trong các flow đã migrate.
- Pending/locked/revoked/payment-awaiting-review không dùng success feedback.
- User/Admin unified app selection không đổi.

## Đã làm

### Foundation motion

- Tạo `AppMotionPolicy` và `AppMotionScope` dùng chung toàn app.
- Hợp nhất duration/curve/scale/distance semantic trong motion foundation.
- Thêm performance tier `economical`, `balanced`, `rich`.
- Thêm shared `AppStateSwitcher`, `AppDirectionalSwitcher`, `AppPressScale` và page transition builder.
- Đưa page transition vào `AppTheme` cho Android, iOS, macOS, Windows, Linux và Fuchsia.
- Dừng/giảm ambient loop ở Splash, Nabi, AI FAB và Admin khi Reduce Motion/economical tier được bật.

### Feedback/haptic/sound

- Tạo `AppFeedbackService`, semantic feedback type, policy, haptic adapter và sound adapter.
- Cô lập toàn bộ `HapticFeedback` và `SystemSound` sau adapter.
- Thêm cooldown/dedup để tránh rung/âm thanh spam.
- Generic tap mặc định không phát sound; sound subtle dành cho state có ý nghĩa.
- Dùng system-sound fallback vì snapshot không có physical Nabi SFX và chưa có asset-audio dependency.

### Preference và accessibility

- Lưu Reduce Motion, haptic, sound level và performance tier bằng SharedPreferences.
- Kết hợp preference với `MediaQuery.disableAnimations`; system Reduce Motion luôn ưu tiên.
- Thêm control tương ứng trong Settings.
- Áp dụng experience builder cho unified app, V1, V2, V3 và Admin surfaces.

### Shared component

- Nâng cấp button, card, chip, input, badge, section header và state primitives.
- Nâng cấp Medical page/card primitives để view chưa sửa trực tiếp vẫn nhận shared motion/theme.
- Loading/empty/error chuyển state ổn định; button loading giữ layout và chống feedback trùng.

### Flow trực tiếp đã migrate

- Splash và onboarding.
- Dashboard, menu, overview, companion, skeleton.
- Meal Plan, đổi món, Nutrition và nutrition profile.
- Lifestyle Schedule, proof capture/gallery và Hero cleanup.
- AI Chat, Voice AI, AI FAB.
- Nabi global/V1 overlay, mascot, vector/frame animation.
- Body metrics, water, personal goals, daily routine, health score, advanced tracking.
- Auth V1/V2, auth gate, register/verify/recovery/reset/callback.
- Profile và Settings.
- Membership payment, Wellness Rewards, FamilyPlus.
- Sale participation/Sale shell.
- Admin login/Admin shell/Admin access gate.

## Quy mô thay đổi

- 84 file Dart changed/new so với `nano_app(8).zip`.
- 72 file Dart hiện hữu được sửa.
- 12 file Dart mới.
- 71/183 file trong design inventory được migrate trực tiếp.
- 71 view-like file khác nhận global theme/route/shared primitive foundation.
- 41 support/controller/router contract được giữ nguyên hoặc chỉ nhận behavior từ caller.
- 49 file runtime tham chiếu feedback semantic.
- 48 file runtime tham chiếu Kinetic Aura motion primitives/policy.

## Test và tooling đã thêm

- `test/core/theme/foundation/motion_test.dart`
- `test/core/feedback/app_feedback_service_test.dart`
- `test/core/theme/app_experience_preferences_test.dart`
- `test/core/theme/kinetic_aura_contract_test.dart`
- `tools/validate_kinetic_aura.py`
- `.codex/design/inventory/coding_touched_files.txt`
- `.codex/design/inventory/coding_implementation_status.csv`

## Tài liệu đã thêm/cập nhật

- `.codex/design/21_CODING_IMPLEMENTATION_STATUS.md`
- `.codex/design/README.md`
- `.codex/design/15_CODING_PLAN.md`
- `.codex/history/OPEN_RISKS.md`
- `.codex/history/WORKLOG_INDEX.md`
- Worklog này.

## Commands và bằng chứng

- `python tools/validate_kinetic_aura.py`: PASS.
  - 594 Dart package imports checked.
  - 75 Kinetic structural files detected.
  - 84 changed/structural Dart files delimiter-checked.
  - Package và relative imports resolved.
  - Direct haptic/sound calls isolated behind adapters.
- Original ZIP comparison: 72 existing Dart files changed + 12 Dart files added.
- `rg 'HapticFeedback\.' lib`: chỉ còn `app_haptic_adapter.dart`.
- `rg 'SystemSound\.' lib`: chỉ còn `app_sound_adapter.dart`.
- Custom file-status generation: 183/183 design inventory rows classified.
- `python -m py_compile tools/validate_kinetic_aura.py`: PASS.

## Validation không chạy được

- `dart format`: SKIPPED - sandbox không có Dart executable; thử tải SDK nhưng direct network bị chặn.
- `flutter analyze`: SKIPPED - sandbox không có Flutter SDK.
- `flutter test`: SKIPPED - sandbox không có Flutter SDK; test source đã thêm nhưng chưa chạy.
- Debug APK/device test: SKIPPED - không có Flutter/native device toolchain.
- PowerShell integrity/history refresh: SKIPPED - sandbox không có PowerShell.
- `git diff --check`: SKIPPED - snapshot không có `.git`.

## Lỗi/rủi ro

### Đã xử lý

- Haptic calls phân tán trong presentation/controller.
- Thiếu feedback semantic và cooldown.
- Thiếu Reduce Motion/performance-tier toàn app.
- Route motion không thống nhất đa nền tảng.
- Nabi/ambient animation vẫn tick khi giảm chuyển động.
- Duplicate Hero trong proof gallery.
- Success feedback của các action tin cậy bị phát trước kết quả ở một số luồng UI.

### Còn mở

- Chưa có compile/analyzer/test/build evidence.
- Chưa có physical Nabi SFX; hiện dùng system cue abstraction.
- Chưa có real-device visual/performance/audio/accessibility matrix.
- Raw color/duration còn tồn tại ở legacy custom UI và service timeout; không thay cơ học ngoài scope để tránh regression.
- Chưa chạy history refresh script do thiếu PowerShell.

## Tỷ lệ hoàn thành

- Foundation/motion/feedback/shared primitives: hoàn thành theo coding scope.
- Active high-value User/V2/V3/Sale/Admin flows: đã migrate trực tiếp.
- Toàn bộ app nhận global theme/page transition/reduce-motion foundation.
- Cleanup/release certification Wave 11: partial, chờ Flutter SDK và device evidence.
- Release-certified: chưa.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt ở mức kiến trúc và static source; feedback/motion có một canonical boundary và không thay đổi data/access contracts.
- Mức độ hoàn thành task: coding foundation và các flow chính hoàn thành; Flutter/device certification và custom physical SFX chưa hoàn thành.
- Bằng chứng kiểm chứng: portable validator PASS, 84 changed/new Dart files được structural-check, 183/183 inventory status, platform feedback boundary PASS.
- Điểm tốn token/chưa tối ưu: Admin/Sale/legacy page rất lớn; nên tiếp tục tách theo component chỉ khi analyzer/device baseline sẵn sàng, không mở lại toàn corpus.
- Cách tối ưu cho phiên sau: dùng `.codex/design/21_CODING_IMPLEMENTATION_STATUS.md` và CSV status để chọn đúng file còn foundation-only; chạy targeted formatter/analyzer/test trước visual QA.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`
