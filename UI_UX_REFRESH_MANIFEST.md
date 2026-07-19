# UI/UX Refresh Manifest

- Ngày: `2026-07-19`
- Style: `Clinical Calm × Nabi Friendly`
- Workflow: `coding`
- Domain: `UI / Theme / NabiCopy`
- Dart files thay đổi: `34`
- Business logic/data/schema/router catalog thay đổi: `0`
- Runtime validation: `SKIPPED` vì môi trường không có Flutter/Dart SDK

## Phạm vi triển khai

- Theme/density/motion dùng chung cho V1, V2, V3, Admin và Sale.
- Back-navigation ở presentation giữ history stack và có fallback cho route trực tiếp.
- Onboarding entry và 9 bước được rút gọn copy, compact layout và hỗ trợ hardware Back từng bước.
- Shared button/card/page primitives có tactile motion và reduced-motion fallback.

## Dart files thay đổi

| File | + | - | SHA-256 |
|---|---:|---:|---|
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` | 90 | 80 | `2ccfc37cc70ffda100e20e5b0d0bf95550d1ab12a977d3e1d61d14a78d43130c` |
| `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | 1 | 1 | `234098abe04304bd290a8f9eae5032cc046c8544a5d189dc4607e7cee9d0b95b` |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` | 9 | 9 | `d38298c1bf24d640c9e776d349e999ccfa6acd0de2949c24f5ae19e545eea96f` |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | 11 | 3 | `5a41959177d5e1860994d581dab6a402f5b66be5b4b8e47934b29d8399ea7dc0` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart` | 8 | 8 | `5a5004c586482058eceec3d67725a11006fb7d8186ea2acb5f9e0c7e50f6f1bf` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart` | 7 | 7 | `6704bbf84e8c1d7ec04625badd69834046da4b2507a2436647e64371dc5b7eea` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` | 9 | 9 | `1f62b1f0b8cf43fa2252356ec695308c79613a4ab3c02c0077800d4483c5f580` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart` | 3 | 3 | `37f72bedb565b1c785e25a3ea98d7e037a0bf0a346fd1aec958f88737290ced1` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` | 10 | 10 | `af0ef16482af37069bd4c93296214f0e38f9e010e6c359d30c285a609e03e945` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart` | 9 | 9 | `cd813b1c02c54f372ef93846c125330123136b13726579857bbff35f6e91da10` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` | 6 | 6 | `23d5779a9c3ea8459921fbccd347964150ca6b1558a8a81b770674b5323695f9` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` | 88 | 80 | `be5d60ae9e7b815bd536fcf1790e3d051a1020d59e5972a04d266248a4d6bd1a` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart` | 9 | 9 | `627d07b00bd8daae26c5ab4490405d1af840a2240ee78509aac4fead2378f442` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` | 13 | 13 | `6fdce54297fca29efa30d9496a7e928154de104f6641e93a474cc652fd9d9099` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` | 8 | 8 | `b3012b04313935ff9a1186d71333f655bc1cd800f89c004c3a65602bf76b7115` |
| `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | 3 | 3 | `143ab716919279d639cf16ef40058626bc9b7e8e2743e82569d3e870a1105e5d` |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | 108 | 85 | `75cf7a38f02ac1550c149cdc6234d562554b920593680cd690de2a1307ec477e` |
| `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart` | 1 | 1 | `d2a7487d0a2b312aa7169d368e11d5c47d3e2fdf0bc02614ecbe4d15e24ddf6b` |
| `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | 1 | 1 | `e765fd6d7f8695397b9c23ffd1b0cc96ff07e0567a93c79e543664c5c0c3492c` |
| `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` | 3 | 3 | `d7656f6c7a65f50431f569725422e23a620df18f62c3e531624dd351e17b44d5` |
| `lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart` | 1 | 1 | `01adb3dcfe9aa754b3333d10012469055912f4b6f2d2888edb5c7bc202c106a4` |
| `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart` | 1 | 1 | `950e82195d590bc4b56eeb05b74d2718e3402aedeb1a696b921dedfc1e4dc486` |
| `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart` | 1 | 1 | `b4ce5cf9fa02ab970f63de62a55d5194544876e204c2eccb7a8d1efb777c6338` |
| `lib/core/theme/app_experience.dart` | 13 | 3 | `04bdaf19f3cfbd8fdd4256a9bfc1a1cc6ed1b50f6f7d4f4b53731ed50be88dc2` |
| `lib/core/theme/app_motion.dart` | 166 | 0 | `ecab4f527daab965f8cd4b57dd1787775c07e1fddb44261056a416a20cd7cdae` |
| `lib/core/theme/app_radius.dart` | 5 | 5 | `fb5db5663f2637b85024e6a39d6b8f4c22392213422039fea14806d2ea540293` |
| `lib/core/theme/app_spacing.dart` | 7 | 7 | `9295476aa49f2cdcb44ccc7df50d039b65968b7bf124690b9b94d2a9b6d9ae7a` |
| `lib/core/theme/app_theme.dart` | 23 | 17 | `feb3dd6d8f0e3609c497a26e91a324aa5f5662c795713ed2adc5671eb7fc4581` |
| `lib/core/theme/medical_ui.dart` | 20 | 4 | `e42cd5b0efb78373ba0d2d0089fec6dfa36beeca3372710df4f173ce828d638c` |
| `lib/core/theme/primitives/button.dart` | 10 | 7 | `21898511bb52cb060b951aacf4953ddcbb07297e8713ba05a19566c6d6f8da7b` |
| `lib/core/theme/primitives/card.dart` | 19 | 15 | `6bb739ac97f98ca444cb756b95390b01d392ed72f5a910b20b076d89f01ca2ac` |
| `lib/core/theme/theme.dart` | 1 | 0 | `40112d1a01f675eee2a32bb744b281618f4ee4cd631339c4496065c1bb7f188b` |
| `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart` | 1 | 1 | `684375a70260a099b6bfcc999b5b0c0487f3e5e9394ccbafbe46a7e64f9f1286` |
| `lib/sale_referral/presentation/pages/sale_participation_page.dart` | 2 | 2 | `c5968cee5f3ed017a0934d462c769cdcae963ff931c88f1cc2e8043a71a51405` |

## Tài liệu tạo mới

- `docs/features/ui-ux-experience-refresh/001-feature-ui-ux-experience-refresh.md` — SHA-256 `b67ed3a325e17a82f00c50f5c7c6f26de7612782d58da7e03e0744bd057b8ce9`
- `docs/test/ui-ux-experience-refresh/001-test-ui-ux-experience-refresh.md` — SHA-256 `8030978f4966626f24217067e08098bcc992e0217a6d6f9377a9d8f833801598`
- `docs/test/ui-ux-experience-refresh/static-validation-output.txt` — SHA-256 `fc0e5a8c941399d1d6f3a33ab5e09f3115db5b61f4020e7b0475bcadaaed17d4`
- `docs/worklog/2026-07-19/004-worklog-ui-ux-experience-refresh.md` — SHA-256 `df25f6b737bbb25fb6bc463ac068ea61e3b972d3b976bbd8588fbf47c3eb48d2`

## Static validation

- Dart delimiter lexical scan: **PASS**.
- `package:nano_app` import resolution: **PASS**.
- Relative import resolution: **PASS**.
- Scope guard chỉ `presentation`/`core/theme`: **PASS**.
- GoRouter import contract: **PASS**.
- 5 app surface dùng `AppExperience.builder`: **PASS**.
- Onboarding/Auth/Admin direct-route Back fallback: **PASS tĩnh**.
- Onboarding string-literal words: `2.218 → 1.717`, giảm `501` từ (`22,6%`).

## Không đóng gói

- `.env` và `assets/config/auth.env`
- `.dart_tool/`, `build/`, `.temp/`
- `android/.gradle/`, `android/.kotlin/`, `android/local.properties`
- `**/flutter/ephemeral/`, `**/.plugin_symlinks/`
- `sources/` (Android SDK source local, không phải source ứng dụng)
- `__pycache__/`, `*.pyc`, Flutter log files
- `.idea/workspace.xml`, `*.iml`, `.flutter-plugins-dependencies`

## Validation cần chạy trên máy Flutter

1. `dart format` trên toàn bộ file Dart trong bảng.
2. `flutter analyze` theo phạm vi file/module đã chạm.
3. Targeted onboarding/auth/theme/navigation tests.
4. `flutter build apk --debug`.
5. Real-device route/back/screenshot matrix trên APK cuối.
