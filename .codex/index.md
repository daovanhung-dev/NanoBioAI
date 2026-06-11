# .codex/index.md — BioAI Context Index

## Dự án là gì
**BioAI** — Flutter app theo dõi sức khỏe cá nhân, AI-powered meal planning, offline-first.  
Stack: Flutter + Riverpod 3 + GoRouter + SQLite + Supabase Auth + Gemini AI.

---

## Thứ tự đọc đề xuất cho AI

### Đọc nhanh (5 file đầu tiên)
1. **`project_overview.md`** — dự án làm gì, phạm vi, trạng thái
2. **`architecture.md`** — kiến trúc tổng thể, layers, stack, data flow
3. **`modules.md`** — danh sách modules, trạng thái, dependency graph
4. **`workflows.md`** — 6 luồng nghiệp vụ chính (startup, onboarding, login, AI gen, etc.)
5. **`data_model.md`** — 14 bảng SQLite, Dart entities, SharedPreferences

### Đọc khi cần làm việc cụ thể
6. **`features.md`** — chi tiết từng feature: input/output/điều kiện
7. **`business_rules.md`** — validation, logic không nên phá vỡ
8. **`api_reference.md`** — Supabase Auth API + Gemini AI API + GoRouter routes
9. **`repository_structure.md`** — cây thư mục, vai trò từng file/folder
10. **`coding_standards.md`** — naming, patterns, SQLite conventions

### Đọc khi mở rộng hoặc debug
11. **`security.md`** — auth guards, API keys, điểm cảnh báo
12. **`dependencies.md`** — packages, vai trò, ảnh hưởng kiến trúc
13. **`decisions.md`** — 9 quyết định kỹ thuật quan trọng với bằng chứng
14. **`environment_setup.md`** — cách chạy, biến env, build commands
15. **`testing.md`** — test coverage (hiện tại: 0%)
16. **`deployment.md`** — trạng thái deployment (chưa có CI/CD)
17. **`glossary.md`** — từ điển thuật ngữ domain + technical
18. **`changelog.md`** — lịch sử thay đổi, pending issues

---

## Điều hướng nhanh theo task

| Task | Đọc file |
|---|---|
| Hiểu tổng quan dự án | `project_overview.md`, `architecture.md` |
| Sửa onboarding | `features.md` → Onboarding, `business_rules.md`, `data_model.md` |
| Sửa auth/login | `features.md` → Auth, `api_reference.md`, `security.md` |
| Sửa AI meal plan | `workflows.md` → Flow 4, `api_reference.md` → Gemini |
| Thêm feature mới | `modules.md`, `coding_standards.md`, `repository_structure.md` |
| Debug routing | `api_reference.md` → Routes, `security.md` → Route Guards |
| Sửa SQLite schema | `data_model.md`, `repository_structure.md` → localdb |
| Hiểu dependencies | `dependencies.md` |

---

## Điểm cảnh báo quan trọng
- ⚠️ `.env` không có trong `.gitignore` — credentials bị commit
- ⚠️ Dashboard `authGuard` đang bị comment out
- ⚠️ `SplashNotifier.initialize()` chưa implement auth check thực
- ⚠️ `AppPrefs.setOnboardingCompleted(true)` chưa rõ được gọi ở đâu sau save onboarding
- ⚠️ `LoginController` dùng legacy `StateNotifier` (chưa migrate sang gen3)
- ⚠️ Test coverage = 0%
