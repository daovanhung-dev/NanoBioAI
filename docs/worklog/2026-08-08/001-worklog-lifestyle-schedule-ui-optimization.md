# Worklog — Tối ưu UI Lịch trình cá nhân

## Metadata

- Ngày: 2026-08-08
- Workflow: `coding`
- Domain chính: UI / Theme / NabiCopy
- Domain liên quan: Lifestyle Schedule / Timeline
- Module: M03 `DASHBOARD_SCHEDULE`
- Base repository: `daovanhung-dev/NanoBioAI`
- Base branch: `main`
- Source baseline đã đối chiếu: commit `1a54318b7291de013d59ef5fd99af5bfc8c461a4`

## Phạm vi

Refactor Presentation của `lifestyle_schedule` theo NanoBio Calm Expressive Health, không thay business logic, persistence, access, quota, reward, notification hoặc cloud sync.

### Invariants giữ nguyên

- `lifestyleScheduleControllerProvider` vẫn là entrypoint state/action của page.
- `toggleItem()` vẫn xử lý completion window, camera proof, reward begin/finalize/undo và local commit.
- `refresh()`, `selectDate()`, `focusItem()` và `reconcilePendingRewards()` không đổi.
- Deep-link focus vẫn scroll tới item.
- Pull-to-refresh vẫn gọi controller hiện tại.
- `ScheduleProofPreviewSection` và gallery/proof restore giữ nguyên workflow.

## Thay đổi UI

1. Bổ sung AppBar rõ ràng với title `Lịch trình cá nhân` và action tùy chỉnh nhịp sinh hoạt.
2. Loại bỏ composition cũ kiểu decorative background/orb/glass hero khỏi page mới.
3. Tách UI thành các widget độc lập:
   - `ScheduleDayHeader`
   - `ScheduleDateSelector`
   - `ScheduleProgressSummary`
   - `ScheduleEncouragementBanner` / `ScheduleActionErrorBanner`
   - `ScheduleTimeline`
   - `ScheduleItemCard`
   - `SchedulePageFrame` / loading / error state
4. Đưa date selector lên trước summary để thao tác đổi ngày nhanh hơn.
5. Nén progress thành một summary duy nhất; bỏ lặp 3 metric card `Hoàn thành/Còn lại/Tổng mục`.
6. Timeline trở thành nội dung trung tâm, giữ thứ tự thời gian và phân biệt rõ `waiting/open/locked/completed`.
7. Task card ưu tiên `time -> title -> status -> action`; category chuyển thành supporting icon/label thay vì pill ngang hàng status.
8. Chỉ item `open` được nhấn primary mạnh; completed dùng mint nhẹ; locked giảm emphasis.
9. Adaptive layout: compact một cột; từ 760px tách overview và timeline thành hai vùng.
10. Date selection dùng semantic selection feedback; completion success vẫn chỉ do controller phát sau authoritative local commit.
11. Bổ sung focused widget tests cho header, progress summary và date selector.

## Verification evidence

### Đã thực hiện trong môi trường hiện tại

- Đối chiếu source runtime/controller/entity/design tokens trực tiếp từ GitHub `main`.
- Static architecture scan trên patch: không có import `core/storage/localdb`, datasource, DAO hoặc Supabase trong Presentation mới.
- Decorative-effects scan: page/widgets mới không dùng `BackdropFilter`, `ImageFilter`, `LinearGradient`, custom `BoxShadow` hay `_SoftOrb`.
- Lexical delimiter scan cho toàn bộ Dart patch: `{}`, `[]`, `()` cân bằng và string/comment state đóng đúng.

### Chưa thể chạy

Môi trường hiện tại không có `dart`/`flutter`, và `git clone` bị chặn DNS (`Could not resolve host: github.com`). Vì vậy chưa claim:

- `dart format`
- `flutter analyze`
- `flutter test`
- full repo quick check

Các lệnh cần chạy sau khi áp patch vào checkout thật:

```powershell
dart format lib/app_versions/v1/features/lifestyle_schedule/presentation test/features/lifestyle_schedule/presentation
flutter analyze lib/app_versions/v1/features/lifestyle_schedule test/features/lifestyle_schedule
flutter test test/features/lifestyle_schedule
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
git diff --check
```

## Self-review

- Output quality: refactor bám source hiện tại và design canonical; giảm cạnh tranh thị giác, đưa timeline thành trung tâm.
- Completion: hoàn thành source patch + focused tests; không thay controller/domain/data.
- Verification strength: API contract được đối chiếu từ GitHub; syntax chỉ static/lexical do thiếu Flutter SDK.
- Token efficiency: đọc đúng source/controller/entity/theme liên quan, không quét broad `lib/**`.
- Next-session optimization: sau khi patch được áp vào checkout có Flutter SDK, ưu tiên format/analyze/test targeted trước; chỉ sửa compile/lint nếu có, không mở rộng business scope.

## History refresh

Chưa chạy `.codex/tools/update_worklog_learning.ps1` vì không có full checkout cục bộ. Sau khi áp patch, chạy refresh script nếu worklog này được giữ trong repository.
