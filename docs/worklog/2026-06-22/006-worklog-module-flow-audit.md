Commit de xuat: docs(worklog): ghi nhan phien audit module flow

# Worklog - Audit module va flow san pham

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 12:08
- Ket thuc: 12:10
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: docs-context / audit checklist
- Module chinh: DB local, Supabase draft, `lib/app_versions/v1`, `lib/app_versions/v2`, `lib/app_versions/v3`, `lib/sale_referral`
- Yeu cau goc: Doc DB va `lib`, xac dinh module nao da lap trinh, module nao chua lam, module nao dang sai flow du an; dac biet chu y Onboarding va Auth vi dang sai luong; tao checklist trong worklog phuc vu phien sau.
- Gioi han: Khong sua runtime code. Khong tao issue docs hoac todo docs trong phien nay.

## Da lam

- Tao worklog audit module/flow theo BD Product Flow Membership Sale.
- Tong hop lai trang thai da lap trinh, chua lam/scaffold, va sai flow theo bang duoi.
- Ghi checklist uu tien P0/P1/P2 de phien sau co the bat dau sua luong ma khong phai doc lai toan bo `lib`.

## Module da lap trinh

| Nhom | Trang thai | Bang chung |
| --- | --- | --- |
| v1 onboarding local save | Da co luong UI/controller/repository/local datasource, luu local profile va pending guest id | `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`, `lib/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart`, `lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart` |
| v1 splash routing | Da co route decision theo auth session va local onboarding flag | `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart`, `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` |
| v1 dashboard / meal / lifestyle / daily tracking | Da co feature code, providers, repositories/datasources va UI chinh | `lib/app_versions/v1/features/dashboard/`, `lib/app_versions/v1/features/meal_plan/`, `lib/app_versions/v1/features/lifestyle_schedule/`, `lib/app_versions/v1/features/daily_health_tracking/` |
| v1 notification | Da co bootstrap, startup scheduler va reminder scheduling | `lib/app_versions/v1/services/notifications/` |
| v1 settings/profile | Da co settings/account UI va local/remote datasource co ban | `lib/app_versions/v1/features/settings/`, `lib/app_versions/v1/features/profile/` |
| v1 AI chat | Da co UI/service, nhung can xep lai theo quota Free v2 | `lib/app_versions/v1/features/ai_chat/`, `lib/app_versions/v1/services/ai/ai_chat_service.dart` |
| v2 auth Supabase | Da co auth pages, controller, repository, remote datasource, route state resolver va AuthGate | `lib/app_versions/v2/features/auth/`, `lib/app_versions/v2/router/v2_router.dart` |
| v2 cloud sync | Da co sync pending guest data len authenticated user va pull cloud snapshot ve local | `lib/app_versions/v2/features/cloud_sync/` |
| v2 account security co ban | Da co service/provider va contract tests | `lib/services/supabase/auth/account_security_service.dart`, `lib/services/supabase/auth/account_security_provider.dart`, `test/app_versions/v2/features/auth/account_security_contract_test.dart` |
| DB local SQLite | Da co SQLite v8 voi users, health profile, goals, conditions, lifestyle, meal plans, daily tasks, schedule items, notifications, tracking logs, catalog | `lib/core/storage/localdb/database_version.dart`, `lib/core/storage/localdb/database_service.dart`, `lib/core/storage/localdb/tables/`, `lib/core/storage/localdb/migrations/migration_manager.dart` |

## Module chua lam hoac moi scaffold

| Module | Trang thai hien tai | Can lam tiep |
| --- | --- | --- |
| `membership_entitlement` | Folder ton tai nhung chua co implementation/entitlement resolver | Can dung Supabase/trusted backend de tao effective access cho Free/Plus/FamilyPlus va Sale axis rieng. |
| `usage_quota` | File planned only, chua co quota AI chat 3/day | Can guard quota truoc khi goi AI chat service cho Free. |
| `personal_schedule_quota` | File planned only, chua co quota tao lich 3/month | Can tach first-generation guest va additional-generation authenticated/quota. |
| `health_scoring` | File planned only | Can v2 health score tu lich su hoan thanh lich trinh, khong nham voi dashboard score local hien tai. |
| v3 Plus/FamilyPlus | `app/`, `router/`, `features/` moi la shell/placeholder | Chua co premium AI, family onboarding, family members, family schedule, advanced tracking that su. |
| `sale_referral` | Moi la placeholder features | Chua co sale dashboard, referral code, payment events, commission records that su. |
| Supabase membership/quota/family/sale | SQL va docs dang la draft | Chua verify sandbox/staging; chua the coi la production-ready cho membership, quota, FamilyPlus, Sale/referral, payment, commission. |

## Module sai flow du an

| Uu tien | Module/flow | Sai lech so voi BD | Bang chung | Huong xu ly sau |
| --- | --- | --- | --- | --- |
| P0 | Onboarding guest first plan | Guest hoan tat onboarding nhung callback trong `main.dart` bo qua sinh plan neu chua co Supabase user. BD yeu cau Guest duoc sinh lich ca nhan lan dau sau onboarding. | `lib/main.dart` override `onboardingCompletionCallbackProvider` return sớm khi `currentSupabaseUserIdOrNull() == null`. | Cho phep first-generation guest dung local user id/pending guest id; chi auth-gate cho generation tiep theo. |
| P0 | Generated plan service | `GeneratedPlanService.generateNextPlan()` bat buoc authenticated user, trai flow Guest initial schedule. | `lib/app_versions/v1/services/ai/generated_plan_service.dart` goi `requireAuthenticatedGeneratedPlanUser(currentUserId())`. | Tach policy: initial guest generation vs authenticated additional generation. |
| P0 | Onboarding completed flag | `AppPrefs.setOnboardingCompleted(true)` van chay du plan bi skip do auth required, co the dua Guest vao app ma khong co lich ca nhan dau tien. | `onboarding_controller.dart` catch `DashboardGenerationAuthRequiredException`, sau do van set completed flag. | Chi mark completed khi da tao lich dau tien hoac co fallback/decision ro rang duoc chap nhan. |
| P0 | Auth/onboarding sync | AuthGate dua vao `users.onboarding_status`; can kiem lai voi pending guest data de khong ep onboarding lai hoac lam mat flow guest-first. | `auth_gate_page.dart`, `auth_route_state_resolver.dart`, `authenticated_user_data_sync_repository_impl.dart`. | Test guest local data -> sign in/sign up -> cloud sync -> route ready; khong lap onboarding sai. |
| P1 | Guest/V1 route gate | Allowlist Guest/V1 chua tap trung; co route ngoai V1 co the mo bang deep-link, vi du `community`. | `v1_router.dart` chi guard AI chat/nutrition/profile; `community` khong guard. | Tao centralized allowlist gate cho route va controller/use-case, khong chi an UI. |
| P1 | Free quota | AI chat va tao lich them da auth-gate nhung chua co quota Free 3/day va 3/month. | `usage_quota.dart` va `personal_schedule_quota.dart` dang `status = 'planned'`; `dashboard_controller.dart` chi check auth. | Implement quota service/repository tu Supabase/RPC/trusted backend truoc khi goi AI. |
| P1 | Membership entitlement | App con doc `users.subscription_tier` read-model, chua dung entitlement tu `membership_subscriptions`/`plan_entitlements` va Sale axis rieng. | `supabase_auth_remote_datasource.dart` select `subscription_tier`; `docs/supabase/README.md` noi field nay chi la read-model. | Dung effective access tu Supabase/trusted backend va route/use-case gate. |
| P2 | Sale/FamilyPlus | Moi placeholder, chua duoc coi la implemented cho BD flow. | `lib/app_versions/v3/README.md`, `lib/sale_referral/README.md`, planned feature files. | Giu planned cho toi khi DD open decisions va Supabase verification duoc chot. |

### Cap nhat trang thai sau phien fix runtime

| Uu tien | Module/flow | Trang thai sau fix | Bang chung moi | Con lai |
| --- | --- | --- | --- | --- |
| P0 | Onboarding guest first plan | Da sua + test pass: entrypoint khong return som khi guest va goi initial guest plan sau onboarding. | `lib/main.dart`, `lib/main_v2.dart`, `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`. | Manual QA voi AI key hop le tren emulator/thiet bi. |
| P0 | Generated plan service | Da sua + test pass: them `generateInitialGuestPlan()` cho guest; `generateNextPlan()` van authenticated-only cho generation tiep theo. | `lib/app_versions/v1/services/ai/generated_plan_service.dart`, `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`. | Khi P1 quota Ready, chi wire quota vao additional generation/authenticated flow. |
| P0 | Onboarding completed flag | Da sua + test pass: chi set completed khi callback tra `generatedInitialPlan`; skip/fail khong dua guest vao app. | `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`, `lib/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart`, `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`. | Manual QA copy loi Nami khi AI/plan generation fail. |
| P0 | Auth/onboarding sync | Da kiem chung + test pass: pending guest data push len auth user, cloud snapshot completed resolve `authenticatedReady`. | `test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart`, `test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`. | Can Supabase sandbox smoke de dong NB-RISK-001. |
| P1 | Guest/V1 route gate | Da sua route layer + test pass: centralized guest allowlist chan `community`, `ai-chat`, `nutrition`, `profile`, `/v2`. | `lib/app_versions/v1/router/v1_route_guards.dart`, `lib/app_versions/v1/router/v1_router.dart`, `lib/app_versions/v2/router/v2_router.dart`, `test/app_versions/v1/router/v1_route_guards_test.dart`. | Use-case/controller gate con phu thuoc entitlement/quota P1. |
| P1 | v2 health scoring / dashboard score | Da sua + test pass: v1 dashboard phan biet "chua co input score" voi "co input that nhung score = 0"; v2 official health_scoring van planned do Q-05. | `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart`, `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`, `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart`, `test/features/dashboard/domain/dashboard_companion_service_test.dart`. | Cong thuc v2 health scoring van Draft cho toi khi Q-05 duoc chot. |
| P1 | Free quota | Blocked/Planned: chua implement production quota vi can Supabase/RPC/trusted backend va DD Q-03/Q-04. | `docs/DD/product_flow/06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md` van Draft; `usage_quota.dart`, `personal_schedule_quota.dart` van planned. | Implement sau khi backend contract va Supabase verification Ready. |
| P1 | Membership entitlement | Blocked/Planned: chua implement effective access production vi DD Q-06 va Supabase verification chua dong. | `docs/DD/product_flow/05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md` van Draft; `supabase_auth_remote_datasource.dart` van doc read-model `subscription_tier`. | Dung Supabase/trusted effective access khi Ready. |
| P2 | Sale/FamilyPlus | Planned: placeholder duoc giu nguyen, chua coi la implemented cho BD flow. | `lib/app_versions/v3/README.md`, `lib/sale_referral/README.md`. | Chi implement khi DD open decisions va Supabase verification duoc chot. |

## Checklist uu tien cho phien sau

- [x] P0 - Sua Guest onboarding sinh lich ca nhan lan dau khong can login.
- [x] P0 - Tach first-generation guest khoi additional-generation authenticated/quota.
- [x] P0 - Doi test dang bao ve unauthenticated generation block theo BD moi.
- [x] P0 - Khong set onboarding completed neu lich ca nhan dau tien chua tao hoac chua co fallback duoc chap nhan.
- [x] P0 - Kiem chung guest local data -> auth cloud sync khong ep onboarding sai.
- [x] P1 - Tao centralized Guest/V1 allowlist gate cho route; controller/use-case gate con phu thuoc entitlement/quota P1.
- [ ] P1 - Implement membership entitlement tu Supabase/trusted backend.
- [ ] P1 - Implement quota Free cho AI chat va schedule generation.
- [x] P1 - Lam ro dashboard score hien tai khac v2 health_scoring BD.
- [ ] P2 - Giu v3/FamilyPlus/Sale o trang thai planned cho toi khi DD/open decisions va Supabase verification xong.

## File code/docs da sua

- `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md` - tao - worklog audit module/flow va checklist cho phien sau.
- `.codex/history/WORKLOG_INDEX.md` - cap nhat tu dong - them worklog moi vao index.
- `.codex/history/LEARNED_SKILLS.md` - cap nhat tu dong - hoc them tu worklog audit module/flow.
- `.codex/task-skills/README.md` - cap nhat tu dong - dong bo so lieu task-skill.
- `.codex/task-skills/*.md` - cap nhat tu dong neu refresh script thay doi noi dung generated tu corpus worklog.

## Tai lieu lien quan

- `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/OPEN_RISKS.md`
- `docs/supabase/README.md`

## Commands

- `Get-ChildItem docs/worklog/2026-06-22 -File`: PASS - xac dinh so thu tu worklog tiep theo la `006`.
- `rg`/focused file reads trong phien lap plan truoc: PASS - doi chieu DB, `lib`, route, auth, onboarding, quota, scaffold.
- `git diff --check`: PASS - chay sau khi tao docs; chi co warning line-ending san co trong worktree.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - chay sau khi tao worklog.
- Flutter analyze/test: SKIPPED - docs/worklog-only, khong sua runtime code.

## Loi/Rui ro

- Da fix: Da co worklog/checklist tap trung de phien sau khong bi mat context ve module chua lam va sai flow.
- Chua fix: Chua sua runtime code cho Onboarding/Auth/quota/entitlement.
- Can kiem tra tiep:
  - NB-RISK-001: Supabase sandbox/staging verification pending.
  - NB-RISK-002: Product flow DD open decisions Q-01..Q-10.
  - Kiem chung thuc te luong Guest onboarding -> first plan -> notifications -> dashboard.

## Ty le hoan thanh

- Hoan thanh: Tao worklog audit/checklist theo dung yeu cau, neu validation pass.
- Dang do: Runtime fixes cho P0/P1/P2 checklist.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - noi dung tach ro module da lam, chua lam, sai flow va checklist uu tien co bang chung file.
- Muc do hoan thanh task: Hoan thanh pham vi docs/worklog-only; khong sua code theo dung yeu cau.
- Bang chung kiem chung: File worklog moi, `git diff --check`, va refresh `.codex/history` sau khi tao worklog.
- Diem ton token/chua toi uu: Da tiet kiem bang cach dung context/read pack va ket qua audit da co tu plan truoc; khong doc lai raw `lib` rong.
- Cach toi uu cho phien sau: Bat dau tu worklog nay, sau do doc domain `onboarding.md`, `access-membership-referral.md`, `ai-service.md`, va file P0 lien quan truoc khi sua code.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md` neu sua flow sai; `.codex/task-skills/coding.md` neu implement quota/entitlement moi.
