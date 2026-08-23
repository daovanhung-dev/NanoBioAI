# Contributing to NanoBioAI

Tài liệu này áp dụng cho source hiện tại tại baseline `25018e8`. Hãy đọc
`AGENTS.md` và router `.codex/` trước khi sửa code hoặc tài liệu.

## Yêu cầu môi trường

- Flutter SDK có Dart thỏa constraint `^3.9.2` trong `pubspec.yaml`.
- Git.
- PowerShell cho các script canonical của dự án.
- Android/iOS toolchain phù hợp nếu cần build hoặc device verification.

Không commit `.env`, API key, service-role key, session token, health PII hoặc
payload backend nhạy cảm.

## Setup

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
```

`lib/main.dart` là entrypoint duy nhất. Chạy app bằng:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1
```

Guest mode không bắt buộc Supabase. Auth, sync, membership, quota, payment,
FamilyPlus, Sale và Admin cần cấu hình backend hợp lệ.

## Chọn workflow trước khi sửa

1. Đọc `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md` và
   `.codex/history/LEARNED_SKILLS.md`.
2. Chọn đúng một workflow trong `.codex/workflows/`.
3. Đọc `.codex/task-skills/README.md` và task-skill tương ứng.
4. Đọc một domain trong `.codex/domains/` khi task chạm product/runtime.
5. Dùng source reachable và executable contracts làm source of truth.

Không dùng delivery manifest/worklog lịch sử làm mô tả trạng thái hiện tại.

## Kiến trúc

Giữ dependency flow:

```text
Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API
```

- Presentation không truy cập SQLite, Supabase hoặc external API trực tiếp.
- Membership, quota, FamilyPlus, Sale, payment và Admin permission phải lấy từ
  trusted backend.
- Không thêm mock/sample data vào production path.
- Không đổi public API/schema/RPC ngoài phạm vi task đã được yêu cầu.
- User-facing copy dùng tiếng Việt và không lộ thuật ngữ/kỹ thuật nội bộ.

## Branch và commit

Dùng branch có mục đích rõ ràng, ví dụ:

```text
feature/<slug>
fix/<slug>
docs/<slug>
refactor/<slug>
```

Commit message nên theo dạng:

```text
feat(scope): mô tả ngắn
fix(scope): mô tả ngắn
docs(scope): mô tả ngắn
test(scope): mô tả ngắn
refactor(scope): mô tả ngắn
```

Không gộp refactor ngoài phạm vi vào cùng patch chức năng.

## Validation

Chạy kiểm tra theo đúng file/module đã chạm trước:

```powershell
dart format <dart-paths>
dart format --set-exit-if-changed <dart-paths>
flutter analyze <paths>
flutter test <paths>
```

Docs/context-only:

```powershell
python tools/validate_docs_source_truth.py
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
git diff --check
```

Runtime quick/full check khi scope yêu cầu:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

Không ghi `PASS` cho Flutter/device/Supabase sandbox nếu command chưa chạy.
Ghi `UNVERIFIED` cùng lý do môi trường.

## Tài liệu và worklog

Làm theo `.codex/DOCS_WORKFLOW.md`:

- Ghi worklog cho thay đổi đáng kể.
- Cập nhật feature/fixbug/test/issue/todo/DD khi workflow yêu cầu.
- Giữ kết quả lịch sử nguyên trạng; thêm marker superseded thay vì viết lại
  evidence cũ.
- Sau khi tạo/cập nhật worklog, chạy history refresh theo hướng dẫn của workflow.

## Pull request checklist

- [ ] Scope khớp yêu cầu và không đổi runtime ngoài ý muốn.
- [ ] Public interface/schema/RPC change được nêu rõ.
- [ ] Test/validator đúng phạm vi đã chạy và có kết quả.
- [ ] Runtime chưa kiểm chứng được ghi `UNVERIFIED`.
- [ ] Không có secret, PII hoặc raw backend/AI payload trong diff.
- [ ] Docs hiện hành khớp source; docs lịch sử có lifecycle rõ ràng.
- [ ] `git diff --check` PASS.
