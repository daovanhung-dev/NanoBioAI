Commit de xuat: feat(onboarding): polish Nabi onboarding completion flow

# Worklog - Chỉnh onboarding Nabi theo NABI-01–08

## Thời gian

- Ngày: 2026-11-13
- Bắt đầu: trước 10:34, tiếp nối từ lượt trước trong cùng phiên
- Kết thúc: 10:39
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding/test/docs
- Module chính: M01 `ONBOARDING_PROFILE` — UI/UX onboarding v1
- Yêu cầu gốc: triển khai kế hoạch đã duyệt cho NABI-01–08, giữ nguyên dữ liệu, điều kiện bắt buộc, privacy consent và logic lưu hiện tại.

## Đã làm

- Rút gọn copy trên 9 bước, đổi heading mở đầu thành câu hỏi phù hợp và thu nhỏ minh họa ở nơi chiếm chỗ thao tác.
- Bước 5/9 vẫn lưu ba trường ngủ, vận động, nước uống; chỉ đổi copy/bố cục.
- Bước 7/9 bỏ heading nội dung, vẫn giữ tiến độ, nút quay lại, Nabi và xác nhận khung giờ.
- Thêm route nội bộ tới `ResultStep` chỉ sau khi completion được xác nhận. Nội dung phụ lấy từ `savedLog` hiện có; lỗi và món chờ duyệt tiếp tục ở luồng hiện tại. CTA và system back từ màn hoàn tất đều mở Menu.
- Tạo test cho thành công, lỗi, chờ duyệt, route thiếu dữ liệu, CTA và system back; mở rộng layout/navigation tests cho đủ 9 bước, giữ data khi quay lại/tiếp tục, text scale lớn, bàn phím và màn hẹp.
- Chỉnh editor khung giờ phụ để dùng bố cục dọc ở viewport hẹp, tránh lỗi `ListTile` khi chữ lớn.
- Cập nhật design registry/spec, task NABI và hai checklist M01. NABI-01–08 đã được đánh dấu hoàn tất; mục ảnh Android giữ trạng thái chưa xác minh.
- Không đổi public API, schema, API backend hoặc quy tắc lưu dữ liệu.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/` — rút gọn copy/bố cục các bước Welcome, Basic Info, Goals, Conditions, Lifestyle, Extras, Daily Routine, Consent, Review và Result.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` — rút gọn thông điệp hoàn tất, giữ ý nghĩa trạng thái.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_result_page.dart` — thêm completion page và hành vi quay lại Menu.
- `lib/app_versions/v1/features/onboarding/onboarding.dart` — export completion page.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` — điều hướng sang completion page sau lưu thành công và xử lý loading/error/pending approval.
- `lib/app_versions/v1/features/daily_routine/presentation/widgets/daily_routine_preferences_editor.dart` — layout responsive cho hàng chọn giờ trên màn hẹp.
- `lib/app_versions/v1/router/v1_route_paths.dart`, `v1_route_guards.dart`, `v1_router.dart` — đăng ký success route trong router và guest allowlist.
- `test/widget_test.dart`, `test/app_versions/v1/features/onboarding/onboarding_result_flow_widget_test.dart`, `test/app_versions/v1/router/v1_route_guards_test.dart` — kiểm tra điều hướng, lưu, layout và route guards.
- `.codex/design/screens/onb-11-result-step.md`, `.codex/design/groups/02_onboarding_auth.md`, `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`, `.codex/design/13_SCREEN_REGISTRY.md` — cập nhật ResultStep thành internal route.
- `docs/tasks/NABI_ONBOARDING_FIX_TASKS.md`, `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` — cập nhật trạng thái và bằng chứng.
- `docs/worklog/2026-11-13/001-worklog-nabi-onboarding-fix.md` — ghi lại phạm vi, kiểm tra và tự đánh giá.

## Tài liệu liên quan

- `docs/tasks/NABI_ONBOARDING_FIX_TASKS.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/onboarding-profile.md`
- `.codex/design/screens/onb-11-result-step.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `dart format --set-exit-if-changed <20 Dart files đã sửa>`: PASS — 20 files, không còn thay đổi format.
- `flutter analyze <20 source/test files đã sửa>`: PASS — No issues found.
- `flutter test test/widget_test.dart test/app_versions/v1/features/onboarding/onboarding_result_flow_widget_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart test/app_versions/v1/router/v1_route_guards_test.dart`: PASS — toàn bộ test trong 5 files đạt; widget suite bao gồm 320×640, scale 1.3, keyboard inset và 390×844.
- `python3 iot/tools/generate_nabi_esp_contract.py`: PASS — tạo output Dart bị thiếu để router test compile; contract JSON không đổi, output `.g.dart` bị ignore theo quy ước repo.
- `python3 iot/tools/generate_nabi_esp_contract.py --check`: PASS — contract outputs đồng bộ.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: SKIPPED — host không có `powershell`/`pwsh`; sẽ dùng Python history refresh sau worklog.
- Android screenshots/device smoke: SKIPPED — `flutter devices` chỉ có Linux target; không ghi nhận ảnh nghiệm thu.

## Lỗi/Rủi ro

- Đã fix: overflow ở nhãn onboarding trên màn hẹp; hàng chọn giờ phụ chuyển sang bố cục dọc dưới 360 px; review status card xếp trạng thái xuống dòng ở card hẹp.
- Chưa fix: không có lỗi chức năng trong scope đã kiểm tra.
- Cần kiểm tra tiếp: chụp ảnh/visual smoke trên Android; Supabase sandbox, consent/audit production evidence vẫn ngoài phạm vi.
- Lưu ý môi trường: router test ban đầu không compile do output `nabi_esp_contract.g.dart` bị thiếu và nằm trong pattern ignore; đã chạy generator chuẩn để kiểm tra rồi xác nhận contract outputs đồng bộ.

## Tỷ lệ hoàn thành

- Hoàn thành: NABI-01–08; các luồng UI/widget và route guards đã xác minh trên Flutter Linux.
- Đang dở: Android screenshot/device smoke chưa xác minh do thiếu thiết bị Android.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — nội dung và layout vẫn giữ nguyên dữ liệu/consent; completion route chỉ chạy sau lưu thành công; lỗi và chờ duyệt không chúc mừng sớm.
- Mức độ hoàn thành task: hoàn thành phạm vi code NABI-01–08; ảnh Android và device acceptance còn chưa xác minh.
- Bằng chứng kiểm chứng: targeted analyzer pass, 5 test files pass, format check pass, contract generator check pass, diff check pass.
- Điểm tốn token/chưa tối ưu: layout test cần một vòng chẩn đoán RenderFlex trước khi xác định nhãn consent và readiness card; router test cần sinh output contract đang bị ignore.
- Cách tối ưu cho phiên sau: trước khi chạy route-level Flutter tests, kiểm tra các output generator được ignore; giữ layout checks trên 320/390 px và text scale lớn.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
