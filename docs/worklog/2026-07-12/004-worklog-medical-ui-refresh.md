Commit de xuat: docs(worklog): ghi nhan phien medical-ui-refresh

# Worklog - Medical UI Refresh toàn dự án

## Thoi gian

- Ngay: 2026-07-12
- Bat dau: 11:00
- Ket thuc: 12:30
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding/test/docs
- Module chinh: UI/UX dùng chung cho V1, V2, V3, Sale và Admin
- Yeu cau goc: tối ưu toàn bộ giao diện theo UI y tế hiện đại, chuyên nghiệp và nâng tầm trải nghiệm.

## Da lam

- Đọc `AGENTS.md`, context `.codex`, workflow coding, domain UI Nabi và checklist DD.
- Thiết kế lại palette, typography, radius, shadow, gradient và ThemeData Material 3.
- Tạo app-level experience wrapper và medical UI primitives dùng chung.
- Wiring wrapper vào bốn app surface và thay raw page scaffold trên toàn bộ view production.
- Nâng cấp Auth V2 responsive, Dashboard, Features Hub, Settings, V2/V3 Home, empty/coming-soon states.
- Giữ nguyên toàn bộ business logic Auth, sync, membership, Sale và Admin.
- Bổ sung contract test, feature doc và test doc.

## File code/docs da sua

- `lib/core/theme/*` - sửa/tạo - hệ thống thiết kế y tế thống nhất.
- `lib/app_versions/**/app/*.dart` - sửa - wiring `AppExperience.builder`.
- `lib/app_versions/**/presentation/**/*.dart` - sửa - áp dụng shell và view mới.
- `lib/sale_referral/presentation/pages/*.dart` - sửa - đồng nhất shell Sale.
- `lib/shared/widgets/loading_gen_ai.dart` - sửa - dùng shell chung nhưng giữ animation riêng.
- `test/core/theme/medical_design_system_contract_test.dart` - tạo - bảo vệ contract UI toàn dự án.
- `test/features/features_hub/features_hub_page_test.dart` - sửa - đồng bộ copy mới.
- `docs/features/medical-ui-refresh/001-feature-medical-ui-refresh.md` - tạo.
- `docs/test/medical-ui-refresh/001-test-medical-ui-refresh.md` - tạo.

## Tai lieu lien quan

- `.codex/domains/ui-nami.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `rg`/Python source contracts: PASS - kiểm tra wiring, raw Scaffold, import và token.
- Python delimiter/static checks: PASS cho phạm vi sửa; một parser chuỗi đơn giản báo false-positive ở file legacy và đã được kiểm tra thủ công.
- `flutter analyze`: SKIPPED - không có Flutter SDK.
- `flutter test`: SKIPPED - không có Flutter SDK.
- `dart format`: SKIPPED - không có Dart SDK.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED - không có PowerShell.

## Loi/Rui ro

- Da fix: shell không đồng nhất, màu sắc cũ thiên trang trí, raw Scaffold phân tán, form auth thiếu responsive desktop, placeholder view không thống nhất.
- Chua fix: chưa có golden screenshot và real-device accessibility smoke.
- Can kiem tra tiep: compile/analyze/test bằng Flutter 3.35.6; text scale; TalkBack/VoiceOver; tablet/desktop.

## Ty le hoan thanh

- Hoan thanh: 95% phần code và static contract của UI refresh.
- Dang do: 5% kiểm chứng runtime/visual trên SDK và thiết bị thật.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay đổi tập trung ở token/primitive nên phủ toàn dự án mà không can thiệp nghiệp vụ.
- Muc do hoan thanh task: hoàn thành code redesign toàn view, còn runtime acceptance.
- Bang chung kiem chung: source contract, diff toàn dự án, raw Scaffold scan, ZIP integrity.
- Diem ton token/chua toi uu: số lượng page lớn nên chưa thực hiện golden cho từng route.
- Cach toi uu cho phien sau: chạy screenshot matrix tự động theo 360/600/1024 px và sửa theo ảnh thay vì đọc toàn bộ file.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
