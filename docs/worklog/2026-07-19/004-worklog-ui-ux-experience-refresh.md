Commit de xuat: docs(worklog): ghi nhan phien ui-ux-experience-refresh

# Worklog - UI/UX Experience Refresh toàn dự án

## Thoi gian

- Ngay: 2026-07-19
- Bat dau: không có timestamp tự động chính xác khi nhận task
- Ket thuc: 17:36
- Timezone: Asia/Saigon (UTC+07:00)

## Pham vi

- Loai task: coding/docs/static-validation
- Module chinh: UI/Theme/NabiCopy xuyên V1, V2, V3, Admin và Sale
- Workflow: `coding`
- Task-skill: `.codex/task-skills/coding.md`
- Domain: `.codex/domains/ui-nami.md`
- Yeu cau goc: đồng bộ style toàn bộ view, nâng UI/UX và hiệu ứng, compact layout, rút gọn Onboarding, giữ nguyên logic/cấu trúc và hỗ trợ hardware Back.

## Da lam

- Đọc `nano_context.md`, project overview, canonical `AGENTS.md`, workflow, task-skill và UI domain.
- Chốt style `Clinical Calm × Nabi Friendly` theo plan đã được người dùng xác nhận.
- Tạo motion primitive dùng chung: page transition, view reveal/stagger và press-scale feedback.
- Compact spacing/radius/component density ở ThemeData để phủ toàn bộ app surface.
- Nâng `MedicalPageScaffold`, `MedicalScrollPage`, `MedicalSurfaceCard`, primitive button/card và onboarding buttons.
- Bổ sung tap-outside để đóng bàn phím trong `AppExperience`.
- Chuyển các navigation action mở view chi tiết sang stack-preserving navigation.
- Bổ sung hardware Back từng bước cho Onboarding.
- Bổ sung direct-route fallback: Auth phụ về Login, Onboarding về `/start`, Admin section về Dashboard.
- Rút gọn copy của onboarding entry và 9 bước, giữ consent/validation/medical warning.
- Tạo feature doc, test report và manifest bàn giao.

## File code/docs da sua

- `lib/core/theme/app_motion.dart` - tạo - motion primitive và reduced-motion behavior.
- `lib/core/theme/app_theme.dart` - sửa - theme/component density và page transition.
- `lib/core/theme/app_spacing.dart` - sửa - compact spacing scale.
- `lib/core/theme/app_radius.dart` - sửa - radius scale cân đối hơn.
- `lib/core/theme/app_experience.dart` - sửa - tap-outside keyboard dismissal.
- `lib/core/theme/medical_ui.dart` - sửa - shared page/scroll/card motion.
- `lib/core/theme/primitives/button.dart` - sửa - tactile press feedback.
- `lib/core/theme/primitives/card.dart` - sửa - tactile press feedback.
- `lib/core/theme/theme.dart` - sửa - export motion API.
- `lib/app_versions/v1/features/onboarding/presentation/**` - sửa - copy, layout, animation, Back flow.
- `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` - sửa - stack-preserving navigation.
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` - sửa - stack-preserving detail/auth navigation.
- `lib/app_versions/v2/features/**/presentation/**` - sửa chọn lọc - back stack và visual surface.
- `lib/app_versions/v3/features/**/presentation/**` - sửa chọn lọc - back stack và visual surface.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - sửa - section history.
- `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart` - sửa - AI Chat giữ view nguồn trong history.
- `lib/sale_referral/presentation/pages/sale_participation_page.dart` - sửa - auth/sale route stack.
- `docs/features/ui-ux-experience-refresh/001-feature-ui-ux-experience-refresh.md` - tạo.
- `docs/test/ui-ux-experience-refresh/001-test-ui-ux-experience-refresh.md` - tạo.
- `docs/test/ui-ux-experience-refresh/static-validation-output.txt` - tạo - kết quả kiểm tra tĩnh có thể đối chiếu.
- `UI_UX_REFRESH_MANIFEST.md` - tạo.

## Tai lieu lien quan

- `nano_context.md`
- `01_project_overview.md`
- `05_agent_operating_contract.md`
- `.codex/AGENTS.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ui-nami.md`
- `docs/features/medical-ui-refresh/001-feature-medical-ui-refresh.md`

## Commands

- Changed-file hash/diff inventory: PASS - 34 Dart file thay đổi.
- Python delimiter lexical check: PASS.
- Package/relative import resolution: PASS.
- View/theme scope guard: PASS.
- Navigation source audit bằng `rg`: PASS tĩnh; root/redirect `go` được giữ có chủ đích.
- Onboarding literal metrics: PASS - giảm 501 từ, tương đương 22,6% trong presentation scope.
- `dart format`: SKIPPED - không có Dart SDK trong môi trường.
- `flutter analyze`: SKIPPED - không có Flutter SDK trong môi trường.
- `flutter test`: SKIPPED - không có Flutter SDK trong môi trường.
- `flutter build apk --debug`: SKIPPED - không có Flutter/Android toolchain.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED - không có PowerShell.

## Loi/Rui ro

- Da fix: style/density phân mảnh ở shared theme; thiếu transition thống nhất; thiếu press feedback dùng chung; detail navigation làm mất history; onboarding chặn Back và có copy dài.
- Chua fix: không phát hiện bug nghiệp vụ vì task không cho phép đổi logic; không sửa baseline ngoài phạm vi UI.
- Can kiem tra tiep: Dart format/analyze, targeted tests, APK build, screenshot matrix, TalkBack, text scale, reduce motion và hardware Back trên điện thoại thật.

## Ty le hoan thanh

- Hoan thanh: code UI/UX, navigation presentation, docs và static validation.
- Dang do: runtime compile/test/build và visual acceptance trên thiết bị thật do môi trường không có Flutter/Dart/device.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt ở cấp source architecture - thay đổi tập trung vào token/primitive nên phủ rộng mà không chạm nghiệp vụ.
- Muc do hoan thanh task: hoàn thành phần có thể thực thi trong artifact; runtime evidence chưa thể xác minh.
- Bang chung kiem chung: changed-file inventory, delimiter/import/scope checks, navigation audit và copy metrics.
- Diem ton token/chua toi uu: repository lớn; đọc từng view không hiệu quả bằng sửa shared primitive rồi audit ngoại lệ.
- Cach toi uu cho phien sau: chạy route screenshot matrix và hardware-back automation trên một APK/commit khóa, chỉ sửa theo bằng chứng hình ảnh.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
