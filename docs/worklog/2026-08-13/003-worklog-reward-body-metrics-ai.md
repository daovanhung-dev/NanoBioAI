Commit de xuat: docs(worklog): ghi nhan phien reward proof va Body Metrics AI

# Worklog - Reward proof + personalized Body Metrics AI

## Thoi gian

- Ngay: 2026-08-13
- Bat dau: 10:37
- Ket thuc: 11:12
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M03 Dashboard/Schedule reward delta; M04 Basic Health Calculator scoped AI interpretation
- Yeu cau goc:
  - Chụp ảnh minh chứng hoàn thành nhiệm vụ phải nhận Điểm chăm sóc, không còn nhánh chụp ảnh nhưng không có điểm.
  - `Feature Hub -> Chỉ số cơ thể` dùng dữ liệu cơ thể thật của người dùng và AI để diễn giải tình trạng hiện tại/xu hướng sau 30 ngày nếu duy trì thực đơn, lịch chăm sóc của app.

## Da lam

- Trace live `main` và xác định hai UI surface cùng có complete-without-reward escape hatch: Lifestyle Schedule và Today Tasks.
- Loại bỏ `requiresNoRewardConfirmation` và `allowWithoutReward` khỏi production path.
- Chuyển reward flow sang fail-closed trước camera: bắt buộc `beginCompletion` thành công; sau ảnh, upload/finalize hoặc pending reconciliation.
- Bổ sung client check `pointsDelta > 0` và giữ idempotency keys hiện hữu để retry an toàn.
- Xác định `wellness_rewards_rollout` seed đang false và RPC fail-closed khi flag false; giữ nguyên default-off release guardrail, cập nhật proof reconciliation source và thêm migration activation opt-in cho môi trường hiện hữu sau acceptance.
- Bổ sung proof upload reconciliation grace cho attempt được mở đúng completion window.
- Tạo Body Metrics datasource/repository/provider đọc local profile, latest tracking, lifestyle, meal plan và schedule.
- Ưu tiên tracking weight mới hơn profile; chỉ tính meal-day có đủ tối thiểu ba bữa.
- Giữ M04 calculator deterministic làm nguồn số liệu chuẩn; thêm 30-day projection policy chỉ phân loại xu hướng năng lượng.
- Thêm Gemini Body Metrics AI service với model fallback, timeout, JSON schema validation, no-new-number policy và medical-claim rejection.
- Refactor Body Metrics UI: profile prefill, current metrics, 30-day scenario, AI interpretation và disclaimer.
- Thêm disclosure ngay trước hành động AI: chỉ số wellness tổng hợp/bối cảnh kế hoạch được gửi để diễn giải; không gửi ảnh proof hoặc nhật ký thô.
- Cập nhật widget regression M04 để dùng ProviderScope/overrides; thêm focused data/projection/AI/reward/Supabase contract tests.
- Tạo DD delta M04, fixbug doc, installer overlay, application guide và validation evidence.

## File code/docs da sua

- `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart` - thay thế - reward-before-camera + pending reconcile.
- `lib/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_timeline.dart` - thay thế - bỏ dialog chụp ảnh không nhận điểm.
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart` - thay thế - bỏ complete-without-reward path.
- `lib/app_versions/v1/features/body_metrics/**` - sửa/tạo - personalized data flow, deterministic projection, AI service, providers, UI.
- `test/app_versions/v1/features/body_metrics/body_metrics_page_test.dart` - thay thế - regression widget cho ProviderScope/prefill/AI UI.
- `test/features/body_metrics/**` - tạo - datasource/projection/AI tests.
- `test/features/lifestyle_schedule/presentation/reward_camera_contract_test.dart` - tạo - reward invariant contract.
- `test/contracts/wellness_rewards_rollout_contract_test.dart` - tạo - rebuild/activation contract.
- `docs/supabase/16-wellness-rewards.sql` - installer edit - proof reconciliation rule; rollout seed vẫn false.
- `docs/supabase/config.sql` - installer edit - đồng bộ rebuild contract.
- `docs/supabase/27-wellness-rewards-runtime-fix.sql` - tạo - activation migration cho existing environment.
- `docs/DD/basic_health_calculators/AI_30_DAY_DELTA.md` - tạo - scoped M04 contract.
- `docs/DD/basic_health_calculators/Overall.md` - installer append - link implementation delta.
- `docs/checklist/checklist_complete_DD.md` - installer append - implementation evidence.
- `docs/checklist/checklist_task_coding.md` - installer append - completed/backlog tasks.
- `docs/fixbug/reward-proof-body-metrics-ai/001-fixbug-reward-proof-body-metrics-ai.md` - tạo.

## Tai lieu lien quan

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/lifestyle-schedule.md`
- `.codex/domains/ai-service.md`
- `docs/DD/basic_health_calculators/Overall.md`
- `docs/supabase/16-wellness-rewards.sql`

## Commands

- `python -m py_compile tools/apply_patch.py`: PASS - installer Python syntax hợp lệ.
- custom Dart lexical delimiter scan: PASS - toàn bộ Dart files trong patch cân bằng delimiter sau khi bỏ strings/comments.
- static reward invariant scan: PASS - production overlay không còn `requiresNoRewardConfirmation`, `allowWithoutReward` hay copy 0-point cũ.
- static architecture scan: PASS - Body Metrics presentation không import local DB/datasource trực tiếp.
- synthetic installer apply x2: PASS - overlay/appends/text replacements idempotent trên checkout tương thích giả lập.
- `dart format ...`: SKIPPED - runtime hiện tại không có Dart SDK.
- `flutter analyze ...`: SKIPPED - runtime hiện tại không có Flutter SDK.
- `flutter test ...`: SKIPPED - runtime hiện tại không có Flutter SDK.
- Supabase sandbox apply/RLS/device camera smoke: SKIPPED - runtime không có verified target project/credentials/device.
- GitHub branch/write: FAIL/BLOCKED - GitHub App trả HTTP 403; remote `main` không bị sửa.

## Loi/Rui ro

- Da fix:
  - Luồng UI cố ý cho phép hoàn thành bằng ảnh nhưng không nhận điểm.
  - Reward feature flag rebuild mặc định false.
  - Existing environment cần explicit active rollout version sau acceptance; source migration có sẵn nhưng không tự deploy/activate.
  - Body Metrics chỉ nhập tay và không dùng dữ liệu profile/plan/AI.
- Chua fix:
  - Chưa có runtime evidence từ Flutter analyzer/test vì SDK không có trong execution environment.
  - Chưa deploy SQL vào Supabase sandbox/production.
  - Chưa real-device smoke camera + reconnect.
- Can kiem tra tiep:
  - Apply patch vào checkout thật rồi chạy targeted format/analyze/test.
  - Apply `16-wellness-rewards.sql` + `27-wellness-rewards-runtime-fix.sql` trên sandbox và xác minh `points_delta = 10` đúng một lần.
  - Kiểm tra private bucket `schedule-completion-proofs`, reconnect sau capture và undo idempotency.

## Ty le hoan thanh

- Hoan thanh: source patch + tests + DD/fixbug/worklog + installer = 100% theo phạm vi code tạo được trong runtime này.
- Dang do: runtime/sandbox/device acceptance evidence trước production.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - reward authority vẫn ở server, AI không được phép thay metric deterministic hoặc chẩn đoán.
- Muc do hoan thanh task: source implementation hoàn tất; deployment/Flutter gates bị chặn bởi environment.
- Bang chung kiem chung: static invariants, lexical scan, installer idempotency; không giả claim analyzer/test.
- Diem ton token/chua toi uu: cần đọc thêm live SQL và Today Tasks vì cùng bug tồn tại ở nhiều surface; đây là mở rộng cần thiết để tránh fix nửa luồng.
- Cach toi uu cho phien sau: chạy patch trên checkout có Flutter SDK trước, chỉ mở thêm source khi targeted analyzer/test chỉ ra cross-domain impact.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
