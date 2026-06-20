# AGENTS - NanoBio / BioAI

File luat chinh cho Codex. Muc tieu: sua dung loi goc, giu flow san pham, kiem chung that, va tiet kiem token.

## Project Snapshot

- App: NanoBio / NamiAI - tro ly suc khoe AI bang Flutter.
- UI persona: Nami - am ap, nhe nhang, quan tam, khong phan xet.
- Kien truc: feature-first + Clean Architecture theo huong hien co cua repo.
- Stack hien tai: Flutter/Dart SDK `^3.9.2`, Riverpod `3.3.1`, GoRouter `17.2.3`, sqflite `2.4.2`, Supabase `2.12.4`, Gemini SDK `0.4.7`, local notifications `19.5.0`.
- SQLite version hien tai: `DatabaseVersion.currentVersion = 8`.
- Nguon version chinh xac: `pubspec.yaml` va `lib/core/storage/localdb/database_version.dart`; khong doan.

## Read Order

1. Doc file nay.
2. Doc `.codex/PROJECT_MAP.md` de chon dung module/source.
3. Neu sap code, review, test, hoac sua docs: doc `.codex/DOCS_WORKFLOW.md`.
4. Neu task la tim bug, tao issue, tao todo, hoac fix issue: doc `.codex/ISSUE_TODO_WORKFLOW.md`.
5. Doc dung 1 playbook lien quan truc tiep:
   - Dashboard/health score/task: `.codex/playbooks/dashboard.md`
   - Onboarding: `.codex/playbooks/onboarding.md`
   - AI/meal/exercise/parser/chat: `.codex/playbooks/ai_service.md`
   - Notification/reminder/action: `.codex/playbooks/notification.md`
   - SQLite/DAO/migration: `.codex/playbooks/sqlite.md`
   - UI/theme/copywriting: `.codex/playbooks/ui_nami.md`
   - Daily health tracking: `.codex/playbooks/health_tracking.md`
   - Lifestyle schedule/timeline: `.codex/playbooks/lifestyle_schedule.md`
6. Dung `rg` de tim usage truoc khi mo rong pham vi hoac doi public API/provider/route/schema.
7. Yêu cầu đọc workRule để hiểu cách làm việc, chỉ đọc file tương ứng với loại task hiện tại(develop: tạo chức năng mới, test: kiểm thử chức năng đã coding, fix: fix các issues).

Khong doc toan bo repo khi task nam trong mot feature. Neu user yeu cau doc toan du an, lam inventory truoc, sau do doc sau cac hotspot can cho task.

## Context Strategy

- Structure scan: dung `rg --files`, `Get-ChildItem`, `pubspec.yaml`, `analysis_options.yaml`, route/config, feature/test folders.
- Targeted deep read: doc file user nhac, import truc tiep, provider/controller/repository/datasource usage, test gan nhat.
- Exhaustive read: chi doc noi dung moi file text khi user yeu cau ro; van bo qua build/cache/generated/binary/secrets.
- Dung lai khi da co: mode, module, trieu chung/muc tieu, file can sua, usage anh huong, cach kiem chung.

## Task Mode Separation

Moi phien chi chon 1 mode chinh: `coding`, `test`, `find-issues`, `create-issues`, `create-todo`, hoac `fix-issues`.

- `coding`: lap trinh dung yeu cau; khong tim bug lan, khong fix issue ngoai scope.
- `test`: chay test/analyze/build va ghi ket qua; khong sua code khi fail.
- `find-issues`: review/tim bug/rui ro va ghi `docs/issues` neu co; khong sua code, khong tao todo.
- `create-issues`: chuyen findings/bug thanh issue; khong sua code, khong tao todo.
- `create-todo`: doc issue da co va tao `docs/todo`; khong sua code, khong test.
- `fix-issues`: doc issue + todo lien quan va sua nho nhat de dong issue.

Chi doc `docs/DD/**` khi user yeu cau ro lap trinh theo DD, tao feature theo DD, hoac doc DD. Neu code mau thuan DD, bao ro `code hien tai` vs `DD tam nhin`, khong tu nang scope.

## Architecture Rules

Luong phu thuoc muc tieu:

```text
Presentation -> Provider/Controller -> Repository -> Datasource -> DAO/API
```

Giu cac luat sau:

- UI chi goi Provider/Controller, khong query DB/API truc tiep.
- Presentation khong import DAO, datasource, SQLite model, hoac `core/storage/localdb`.
- Provider/Controller khong goi DAO/API truc tiep neu da co Repository.
- Repository impl goi datasource; datasource goi DAO/service.
- Domain entity/service nen la Dart thuan, khong phu thuoc Flutter/sqflite/http.
- Repo hien co co mot so `RepositoryImpl` dat trong `domain/repositories`; di theo pattern hien tai neu task khong yeu cau refactor kien truc.
- Khong them mock/fake/sample data vao production de che loi.
- Khong hard-code secret/API key, khong sua `.env` that neu khong duoc yeu cau ro.
- Tranh `dynamic`, `!`, `as` neu chua chung minh an toan.
- Khong refactor lan sang module khac khi khong can cho loi goc.

## Critical Product Flow

Luong loi can giu dung:

```text
Onboarding complete
-> save profile/goals/habits/conditions/allergies/treatments/survey answers to SQLite
-> generate meal plan + exercise/daily health tasks by AI or fallback
-> normalize Vietnamese user-facing text
-> save meal/task/schedule data to SQLite
-> build lifestyle schedule: meals + exercise + hydration + sleep
-> schedule local notifications with complete/skip actions
-> user action updates SQLite
-> dashboard reads SQLite and recalculates score/progress/timeline
```

Dashboard production phai doc data that tu data layer/SQLite. Empty state duoc phep, bia so lieu thi khong.

## UI & Copy

- Text user-facing phai la tieng Viet co dau.
- Giong Nami: diu dang, tu nhien, khong phan xet, khong gay cam giac bi cham diem.
- Khong de user thay thuat ngu noi bo: database, table, query, parser, exception, stack trace, log.
- Error/loading/empty state phai ro rang va de chiu.
- Uu tien token trong `lib/core/theme/`: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppDecoration`, `AppGradients`, `AppShadows`, `AppDuration`.

## Work Process

Discover:

- Xac dinh mode, module chinh va playbook duy nhat can doc.
- Mo file dang loi/duoc yeu cau, import truc tiep, usage bang `rg`, test lien quan.
- Dung khi da du nguyen nhan goc hoac pham vi thay doi nho nhat.

Patch:

- Sua nho nhat de giai quyet dung yeu cau.
- Giu public API/provider/route/callback neu chua kiem usage.
- Neu doi schema: version + migration + table + model + DAO + onCreate.
- Neu doi logic rui ro: them/cap nhat test phu hop.
- Neu code/docs/review/test: cap nhat worklog theo `.codex/DOCS_WORKFLOW.md`.
- Neu tim bug/tao issue/tao todo/fix issue: lam theo `.codex/ISSUE_TODO_WORKFLOW.md` va khong tron mode.

Validate:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

Tuong duong:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Full check khi doi Android/native/notification/build:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

Neu command khong chay duoc do moi truong, bao ro blocker. Khong bia ket qua test.

## Definition of Done

Task chi xong khi:

- Dung loi goc hoac dung yeu cau chuc nang.
- Khong pha flow onboarding -> schedule -> notification -> dashboard.
- Khong tao architecture violation moi.
- Format/analyze/test da chay, hoac co ly do skip ro rang.
- User-facing copy dung tieng Viet co dau va dung giong Nami.
- Worklog/docs can thiet da cap nhat theo `.codex/DOCS_WORKFLOW.md`.
- Bao cao cuoi neu file da sua, docs da tao/cap nhat, command da chay, ket qua, rui ro con lai.
