# AGENTS — NanoBio / BioAI

Đây là file luật chính. Mục tiêu: Codex hiểu đúng dự án, sửa đúng phạm vi, test đúng quy trình, tiết kiệm token tối đa.

## 1. Project identity

- App: NanoBio / BioAI.
- Stack: Flutter, Dart, Riverpod, GoRouter, SQLite/sqflite, Supabase, AI service, local notifications.
- Architecture: Clean Architecture + feature-first.
- UI persona: Nami — trợ lý sức khỏe tiếng Việt có dấu, nhẹ nhàng, ân cần, không phán xét.

## 2. Read order bắt buộc

Luôn đọc theo thứ tự:

1. `.codex/AGENTS.md`.
2. `.codex/PROJECT_MAP.md`.
3. Chỉ đọc playbook liên quan trực tiếp:
   - Dashboard/health score -> `.codex/playbooks/dashboard.md`
   - Onboarding -> `.codex/playbooks/onboarding.md`
   - AI/meal/exercise/parser -> `.codex/playbooks/ai_service.md`
   - Notification/reminder/action -> `.codex/playbooks/notification.md`
   - SQLite/DAO/migration -> `.codex/playbooks/sqlite.md`
   - UI/theme/copywriting -> `.codex/playbooks/ui.md`

Không đọc toàn bộ project nếu task chỉ liên quan một module.

## 3. Luồng kiến trúc phải giữ

```text
UI/Page/Widget -> Riverpod Controller/Provider -> Repository -> Datasource -> DAO/SQLite hoặc Service
```

Quy tắc cứng:

- UI không query SQLite trực tiếp.
- Presentation không bypass repository/datasource/DAO nếu lớp đó đã tồn tại.
- Không thêm mock/fake data vào production để che lỗi.
- Không gọi Gemini/OpenAI/Supabase/network thật trong unit/widget test.
- Không sửa `.env` thật, không hard-code key.
- Đổi schema thì cập nhật đủ table/model/DAO/migration/onCreate và tăng database version.
- Không đổi route/provider public API nếu chưa kiểm tra usage bằng `rg`.
- Text tiếng Việt hiển thị cho user phải có dấu.

## 4. Luồng nghiệp vụ lõi

Sau onboarding thành công:

1. Lưu hồ sơ sức khỏe vào SQLite.
2. Tạo meal plan và exercise/lifestyle tasks bằng AI hoặc local catalog.
3. Lưu `meal_plans`, `lifestyle_schedule_items`, `daily_health_tasks`.
4. Dashboard tính điểm/trạng thái từ dữ liệu SQLite thật.
5. Notification đặt lịch theo nhiệm vụ cá nhân.
6. User hoàn thành/bỏ qua task thì trạng thái được lưu DB và dashboard cập nhật.

## 5. Quy trình làm việc bắt buộc

Trước khi sửa:

1. Xác định task thuộc module nào.
2. Đọc `.codex/PROJECT_MAP.md` để biết vùng source cần xem.
3. Dùng `rg` tìm file liên quan, không mở tràn lan.
4. Lập plan ngắn 3–5 ý.

Khi sửa:

- Sửa nhỏ nhất đủ đúng lỗi gốc.
- Không refactor lan rộng nếu task không yêu cầu.
- Không tạo code chết/comment bỏ code.
- Ưu tiên type rõ ràng; không dùng `dynamic`/`!` bừa bãi.

Sau khi sửa:

- Chạy quick check.
- Nếu sửa Android/native/notification/build config, chạy full check thêm build APK.

## 6. Commands

Windows quick:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

Windows full:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -FixFormat -BuildApk
```

Git Bash/WSL/macOS/Linux quick:

```bash
bash .codex/tool/codex_quick_check.sh
```

Git Bash/WSL/macOS/Linux full:

```bash
bash .codex/tool/codex_check.sh --fix-format --build-apk
```

## 7. Report format

Cuối task phải báo cáo:

```text
Đã làm:
- ...

File đã sửa:
- ...

Test/command đã chạy:
- flutter pub get: PASS/FAIL/SKIPPED
- dart format --set-exit-if-changed .: PASS/FAIL/SKIPPED
- flutter analyze: PASS/FAIL/SKIPPED
- flutter test: PASS/FAIL/SKIPPED
- flutter build apk --debug: PASS/FAIL/SKIPPED

Ghi chú/rủi ro còn lại:
- ...
```
