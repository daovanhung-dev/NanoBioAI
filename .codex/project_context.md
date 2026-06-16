# Project Context

## Ban chat san pham

BioAI la ung dung Flutter theo doi suc khoe ca nhan, tap trung vao:

- Onboarding ho so suc khoe ban dau.
- Dashboard tong quan BMI, lifestyle, muc tieu, insight.
- AI meal planning dua tren ho so suc khoe.
- AI chat assistant ve dinh duong, giac ngu, stress va loi song.
- Offline-first storage bang SQLite, cloud dependency toi thieu.

Ten package Flutter: `nano_app`. Ten san pham hien tren UI/docs: `BioAI`.

## Tech stack

- Flutter SDK/Dart: `sdk: ^3.9.2`.
- State management: `flutter_riverpod: ^3.3.1`.
- Navigation: `go_router: ^17.2.3`.
- Local storage: `sqflite`, `shared_preferences`, `path`, `path_provider`.
- Backend auth: `supabase_flutter`.
- AI: `google_generative_ai`, mot so `dio` provider cu con ton tai.
- Device services: `local_auth`, `image_picker`, `permission_handler`.
- Testing: `flutter_test`, `mockito`, `build_runner`.

## Entry point

`lib/main.dart`:

- `WidgetsFlutterBinding.ensureInitialized()`.
- Load `.env` bang `flutter_dotenv`.
- Khoi tao Supabase bang `SUPABASE_URL` va `SUPABASE_ANON_KEY`.
- `runApp(const ProviderScope(child: BioAIApp()))`.

`lib/app/app.dart`:

- Render `MaterialApp.router`.
- Theme hien chi dung `AppTheme.lightTheme`.
- Router: `appRouter` tu `lib/core/router/app_router.dart`.

## Cau truc lon

```txt
lib/
├── app/
├── core/
│   ├── constants/
│   ├── interfaces/
│   ├── network/
│   ├── router/
│   ├── storage/localdb/
│   ├── theme/
│   └── utils/
├── features/
│   ├── ai_chat/
│   ├── auth/
│   ├── community/
│   ├── dashboard/
│   ├── meal_plan/
│   ├── nutrition/
│   ├── onboarding/
│   ├── other/
│   ├── profile/
│   ├── settings/
│   ├── sleep_tracking/
│   ├── splash/
│   └── stress_tracking/
├── services/
│   ├── ai/
│   ├── biometric/
│   ├── image_picker/
│   └── supabase/
└── shared/widgets/
```

## Product docs vs code hien tai

Co 2 muc tieu dang song song:

- Code/README hien tai: AI sinh meal plan 7 ngay, bat dau tu ngay mai.
- `docs/DD/DD_Module`: product vision noi den thuc don ca nhan hoa 30 ngay va refresh chu ky sau 30 ngay.

Khi lam feature meal plan can hoi/kiem tra pham vi: tiep tuc 7 ngay nhu code hay nang len 30 ngay theo DD docs.

## Trang thai `.codex` truoc khi tao bo nay

Tai thoi diem tao context, `.codex` dang rong. Cac file IDE dang mo nhu `SECURITY.md`, `REFACTOR_PROGRESS.md`, `.codex/api_reference.md` khong ton tai trong workspace; `api_reference.md` duoc tao moi trong bo context nay.

## Cac docs nguon da doc

- `README.md`
- `bioai_readme_project_structure.md`
- `AI_CHAT_QUICK_START.md`
- `FEATURE_AI_CHAT_SUMMARY.md`
- `docs/issues/bug_architecture.md`
- `docs/todo/ui_todo_dashboard.md`
- `docs/todo/login_ui_refactor_todo.md`
- `docs/DD/DD_Module/**`
- `test/PRESERVATION_BASELINE_OBSERVATIONS.md`
- `test/ARCHITECTURE_VIOLATIONS_COUNTEREXAMPLES.md`

## Quy tac an toan

- Khong commit `.env`, database local, API key, cert/signing file.
- `.env.example` chi la template.
- Khi viet docs/API context, khong copy secret tu `.env`.
