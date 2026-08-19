Commit de xuat: fix(ui): khac phuc 36 issue UI UX tu full audit

# Fixbug - UI/UX Full Audit

## Baseline

- Repository: `daovanhung-dev/NanoBioAI`
- Baseline commit: `30587ab9b04d95aa621e5412502aafd0d0ca4827`
- Audit source: `docs/audit/FLUTTER_UI_UX_FULL_AUDIT.md`
- Scope: UI/UX, interaction, state consistency, navigation, accessibility, performance and presentation architecture.
- Supabase schema/RLS/RPC: **khong thay doi**.

## Muc tieu

Khac phuc 36 issue da duoc xac nhan/potential trong full UI/UX audit ma khong them du lieu suc khoe mau, khong thay doi membership/Sale authority va khong de Presentation goi truc tiep Supabase.

## Ket qua theo issue

| ID | Trang thai | Thay doi chinh |
|---|---|---|
| BUG-UI-001 | FIXED | Quick Care co chon bai, bat dau, dem gio, dung/hoan thanh va feedback local. |
| BUG-UI-002 | FIXED | Weekly Summary doc du lieu Lifestyle Schedule that cua tuan hien tai; co loading/error/empty/refresh. |
| BUG-UI-003 | FIXED | Today Tasks dat timer theo time-boundary va refresh khi app resume. |
| BUG-UI-004 | FIXED | Profile/user scoped invalidation bao gom Body Metrics context/controller. |
| BUG-UI-005 | FIXED | Gentle Care khong con tuyen bo da tu dong thay doi lich khi chua co persistence contract. |
| BUG-UI-006 | FIXED | Sale Participation giu error state rieng, khong bien loi trusted backend thanh `SaleState.none`. |
| BUG-UI-007 | FIXED | Auth Gate single-flight cho merge/use-cloud/sign-out va khoa CTA trong mutation. |
| BUG-UI-008 | FIXED | Auth controller single-flight cho sign-up/sign-in, chan keyboard/button duplicate submit. |
| BUG-UI-009 | FIXED | FamilyPlus create group co single-flight + stable idempotency key trong mot user intent. |
| BUG-UI-010 | FIXED | Advanced Tracking create goal co mutation busy guard rieng. |
| BUG-UI-011 | FIXED | Settings pull-refresh phan biet full success/partial failure/total failure, giu noi dung cu. |
| BUG-UI-012 | FIXED | AI Chat System UI icon brightness bam theo Theme brightness. |
| BUG-UI-013 | FIXED | AI Chat chi auto-scroll khi user dang gan bottom/tu gui; neu dang doc cu thi hien `Tin nhan moi`. |
| BUG-UI-014 | FIXED | Meal Plan co back affordance ro rang va `maybePop`. |
| BUG-UI-015 | FIXED | Meal Plan dung mot `showMealReplacementPicker` canonical; bo private sheet trung. |
| BUG-UI-016 | FIXED | `/health-tracking` render Daily Health UI that, khong alias Lifestyle Schedule. |
| BUG-UI-017 | FIXED | Copy consumer duoc doi sang ngon ngu nguoi dung; bo cac tu implementation da audit. |
| BUG-UI-018 | FIXED | Proof image memoize file-resolution future theo proof thay vi tao Future moi trong build. |
| BUG-UI-019 | FIXED | Proof thumbnail decode theo kich thuoc render x DPR; viewer moi dung anh full. |
| BUG-UI-020 | FIXED | Features Hub tinh so cot theo width + text scale thay vi co dinh 3 cot. |
| BUG-UI-021 | FIXED | Nutrition metric dung adaptive Wrap thay grid co childAspectRatio co dinh. |
| BUG-UI-022 | FIXED | Meal date selector co min touch target va chieu cao adaptive theo text scale. |
| BUG-UI-023 | FIXED | Nabi context tach rieng Dashboard/Features/Health Insights/Settings. |
| BUG-UI-024 | FIXED | Admin confirmation dialog gioi han max-height theo viewport/keyboard va scroll duoc. |
| BUG-UI-025 | FIXED | Upload proof Admin duoc tach Presentation -> Provider -> Repository -> Datasource -> Supabase Storage. |
| BUG-UI-026 | FIXED | Health Module access dung push-stack cho login/payment de giu return intent. |
| BUG-UI-027 | FIXED | Health Score stale-while-refresh; refresh fail giu data cu va warning. |
| BUG-UI-028 | FIXED | Dashboard periodic refresh chi chay khi Dashboard tab dang active; resume cung co visibility gate. |
| BUG-UI-029 | FIXED | ResultStep bo default `healthScore = 82`; score nullable/no-score state. |
| BUG-UI-030 | FIXED | Splash prefs read failure thanh recoverable error + retry, khong fail-open vao onboarding. |
| BUG-UI-031 | FIXED | Settings/Cua ban duoc them vao design surface registry va screen spec. |
| BUG-UI-032 | FIXED | Consumer naming tren cac surface audit chinh dung `Nabi`/`Nabi Care`; bo `Nami Care` o display title va `NaBi` tren Voice/onboarding surface da sua. |
| BUG-UI-033 | FIXED | Admin drawer/sidebar touch target toi thieu 48dp. |
| BUG-UI-034 | FIXED | V1/V2/V3 dung chung route factories cho Lifestyle Schedule/Login/Payment. |
| BUG-UI-035 | FIXED | Onboarding logging roi khoi build path, chuyen sang provider transition listener. |
| BUG-UI-036 | FIXED | AI Voice dung `push` sang Chat de Back quay ve Voice. |

## Kien truc moi/duoc chinh lai

### Shared route factories

`lib/app/router/shared_route_factories.dart` la nguon builder chung cho nhung route truoc day bi copy giua V1/V2/V3.

### Admin payout proof upload

```text
AdminWorkspacePage
  -> adminPayoutProofRepositoryProvider
  -> AdminPayoutProofRepository
  -> AdminPayoutProofRemoteDatasource
  -> Supabase Storage
```

Presentation chi chon file/nhan user intent; trusted remote call nam o datasource.

### Main navigation visibility

`mainNavigationIndexProvider` la state nhe de Dashboard biet khi nao no dang hien trong shell. Timer refresh khong con invalidate du lieu trong luc user o tab khac.

## Regression guards

Tao `test/ui_ux_audit/ui_ux_audit_regression_test.dart` de khoa cac invariant de tai phat:

- active Quick Care co interaction;
- Weekly Summary doc state that;
- time-boundary Today Tasks;
- Body Metrics invalidation;
- single-flight auth/FamilyPlus/Advanced Tracking;
- Sale trusted error;
- AI Chat theme/reading position;
- single Meal Replacement picker;
- Daily Health khong alias;
- Admin presentation khong import/call Supabase;
- route factories dung chung;
- fake health score khong quay lai;
- touch target >=48dp;
- AI Voice dung push.

## Validation da thuc hien trong moi truong hien tai

- Source invariant scan: **40/40 PASS**.
- Dart lexical delimiter/string/comment balance tren overlay: **PASS, 0 error**.
- Forbidden pattern scan:
  - `healthScore = 82`: khong con.
  - private `_MealReplacementSheet`: khong con.
  - `context.go(V1RoutePaths.aiChat)`: khong con.
  - Supabase Storage trong Admin presentation: khong con; chi con trong datasource.
  - Admin `minHeight: 42/44`: khong con.
- `TODO/FIXME/HACK` trong Dart da thay doi: khong co.

## Validation bi chan boi moi truong

Container hien tai khong co `dart` va `flutter` executable, nen chua the chay:

- `dart format --set-exit-if-changed ...`
- `flutter analyze ...`
- `flutter test test/ui_ux_audit/ui_ux_audit_regression_test.dart`
- `.codex/tool/codex_quick_check.ps1`
- `.codex/tool/codex_check.ps1 -BuildApk`

Day la blocker cua moi truong thuc thi, khong duoc ghi nhan nham thanh PASS.

GitHub connector doc duoc repo nhung thao tac tao branch bi tu choi `403`, vi vay source duoc ban giao thanh overlay ZIP giu nguyen repo-relative paths, khong claim da push len GitHub.

## Rui ro con lai

- Can chay Flutter analyzer/widget tests/native build tren may co Flutter SDK truoc release.
- Naming regression test hien khoa cac consumer surface co risk cao; neu sau nay them copy moi, nen tiep tuc dung canonical `Nabi`.
