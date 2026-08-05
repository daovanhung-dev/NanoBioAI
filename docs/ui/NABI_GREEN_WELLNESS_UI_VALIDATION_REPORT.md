# Báo cáo kiểm tra — NaBi Green Wellness UI

## 1. Kết luận kiểm tra hiện tại

| Nhóm kiểm tra | Kết quả | Bằng chứng / giới hạn |
|---|---|---|
| Static import target + duplicate import | PASS | Kiểm tra 735 Dart files; không phát hiện import package/relative bị thiếu hoặc import trùng. |
| Dart lexical/delimiter balance | PASS | Scanner xử lý comment, raw/multiline string và interpolation; 0 blocking findings. |
| Opaque raw color trong feature UI | PASS | 0 ứng viên bị cấm ngoài core theme. |
| Named Material color trong feature UI | PASS | 0 ứng viên bị cấm, ngoại trừ `transparent` được cho phép trong primitive. |
| Numeric border radius trong feature UI | PASS | 0 ứng viên; đã dùng semantic radius token. |
| Raw Scaffold ngoài approved shell | PASS | Chỉ còn `medical_ui.dart` và `design_system_demo_page.dart`, đúng vai trò foundation/demo. |
| Unsafe const-expression scan | PASS | 0 trường hợp `Theme.of`, `withValues` hoặc biểu thức runtime trong const context được phát hiện. |
| Pubspec asset existence | BLOCKED | **57 đường dẫn asset cấu hình bị thiếu** vì archive nguồn không chứa root `assets/`. |
| `dart format` | NOT RUN | Không có executable `dart` trong môi trường. |
| `flutter analyze` | NOT RUN | Không có executable `flutter`; asset tree cũng chưa đầy đủ. |
| Flutter tests | NOT RUN | Không có Flutter SDK và asset tree. |
| Build APK / device smoke | NOT RUN | Không có Flutter/Android execution environment. |
| Visual QA / screenshot matrix | NOT RUN | Không thể render ứng dụng từ archive thiếu assets và môi trường không có SDK/device. |

## 2. Static validator

Tool tái lập: `tools/validate_nabi_green_wellness.py`.

```text
NaBi Green Wellness static validation
- Dart files checked: 735
- Blocking static findings: 0
- Missing configured asset paths: 57
WARN  [MISSING_ASSET_PATH] assets
WARN  [MISSING_ASSET_PATH] assets/data
WARN  [MISSING_ASSET_PATH] assets/images
WARN  [MISSING_ASSET_PATH] assets/images/nabi
WARN  [MISSING_ASSET_PATH] assets/images/nabi/chat
WARN  [MISSING_ASSET_PATH] assets/images/nabi/core
WARN  [MISSING_ASSET_PATH] assets/images/nabi/daily
WARN  [MISSING_ASSET_PATH] assets/images/nabi/engagement
WARN  [MISSING_ASSET_PATH] assets/images/nabi/future
WARN  [MISSING_ASSET_PATH] assets/images/nabi/onboarding
WARN  [MISSING_ASSET_PATH] assets/images/nabi/progress
WARN  [MISSING_ASSET_PATH] assets/images/nabi/system
WARN  [MISSING_ASSET_PATH] assets/icons
WARN  [MISSING_ASSET_PATH] assets/icons/custom
WARN  [MISSING_ASSET_PATH] assets/icons/filled
WARN  [MISSING_ASSET_PATH] assets/icons/health
WARN  [MISSING_ASSET_PATH] assets/icons/nutrition
WARN  [MISSING_ASSET_PATH] assets/icons/outlined
WARN  [MISSING_ASSET_PATH] assets/config
WARN  [MISSING_ASSET_PATH] assets/config/nabi
WARN  [MISSING_ASSET_PATH] assets/nabi
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/01_static_expressions
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/01_core/NABI_ANIM_001_happy_idle_breathing
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/01_core/NABI_ANIM_002_happy_wave_right
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/01_core/NABI_ANIM_003_happy_jump_pop
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/01_core/NABI_ANIM_004_happy_heart_send
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/01_core/NABI_ANIM_005_success_confetti_dance
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_006_sad_sigh_slow
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_007_sad_look_down
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_008_pout_cheek_turn
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_009_pout_cross_arm
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_010_angry_small_stomp
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_011_angry_warning_shake
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_012_cry_big_tears
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_013_cry_rub_eye
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/02_emotion/NABI_ANIM_014_sleepy_yawn
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_015_sleepy_reminder_nod
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_016_thinking_bubble
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_017_talking_soft
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_018_listening_ear_bounce
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_019_nod_yes
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/03_daily/NABI_ANIM_020_shake_no
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/04_system/NABI_ANIM_021_loading_leaf_spin
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/04_system/NABI_ANIM_022_error_dizzy
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_023_meal_scan_food
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_024_exercise_cheer
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_025_profile_greeting
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_026_membership_vip_sparkle
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_027_critical_alert_guard
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_028_empty_state_peek
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_029_onboarding_welcome
WARN  [MISSING_ASSET_PATH] assets/nabi/01_character/02_30fps_frames/05_views/NABI_ANIM_030_dashboard_morning
WARN  [MISSING_ASSET_PATH] assets/nabi/02_spritesheets
WARN  [MISSING_ASSET_PATH] assets/nabi/03_effects
WARN  [MISSING_ASSET_PATH] assets/nabi/04_audio/sfx
WARN  [MISSING_ASSET_PATH] assets/nabi/06_manifest
```

## 3. Các kiểm tra contract được bổ sung

- `test/core/theme/foundation/gradient_test.dart`: cập nhật expectation theo canonical Green Wellness palette.
- `test/core/theme/green_wellness_contract_test.dart`: kiểm tra mã màu nền tảng, typography/geometry, semantics và touch target của chip, loading variants thực và lệnh cấm raw color/radius ở feature UI.
- `tools/validate_nabi_green_wellness.py`: cho phép kiểm tra lại import, lexical balance, raw style policy và asset presence mà không cần Flutter SDK.

## 4. Lệnh bắt buộc phải chạy tại máy có SDK và assets

```powershell
flutter pub get
dart format <toàn bộ Dart file trong NABI_GREEN_WELLNESS_UI_CHANGED_FILES.md>
flutter analyze <các source/test đã đổi>
flutter test test/core/theme/foundation/gradient_test.dart
flutter test test/core/theme/green_wellness_contract_test.dart
flutter test test/core/theme test/widget_test.dart
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
flutter build apk --debug
```

## 5. Visual matrix chưa được đóng

- Thiết bị nhỏ, trung bình và lớn.
- Text scale mặc định và lớn.
- Light mode; dark-capable token inspection nếu dark mode được bật sau này.
- Có dữ liệu, empty, loading, error, selected, disabled và keyboard-open.
- Onboarding, auth, dashboard, AI, meal plan, profile/settings, V2/V3, Admin và Sale/Referral.

**Trạng thái nghiệm thu:** static migration đạt; runtime/visual acceptance còn mở và không được tuyên bố PASS trong môi trường hiện tại.
