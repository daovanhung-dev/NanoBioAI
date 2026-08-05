# Kế hoạch refactor toàn bộ UI — NaBi Green Wellness

> **Trạng thái:** Hoàn tất khảo sát, checklist và kế hoạch. **Chưa chỉnh sửa source runtime.** Chỉ bắt đầu coding sau khi người dùng xác nhận kế hoạch này.

## 1. Mục tiêu và phạm vi

Chuẩn hóa toàn bộ giao diện NanoBio/NamiAI theo `.codex/Design_NaBi_Green_Wellness.md`, bao phủ Core Theme, App Shell, V1, V2, V3, Global Nabi, Admin, Sale/Referral, shared components và widget/theme tests. Refactor phải giữ nguyên nghiệp vụ, API, data model, navigation, Riverpod state, quota, permission, consent, payment và persistence contract.

Phạm vi đã quét: **580** Dart source trong `lib/`, **154** Dart test trong `test/`; checklist chứa **202** source UI-facing/adjacent và **23** test UI/theme.

## 2. Tóm tắt Design System bắt buộc

### 2.1 Màu sắc và bề mặt

- Consumer wellness dùng xanh làm chủ đạo: `#14A36F`; deep `#075E45`; bright `#42D392`; soft `#DDF6E9`; mint `#EAF9F1`; page `#F6FBF8`; surface trắng.
- Text: primary `#12352A`, secondary `#60766E`, muted `#8A9B94`; border `#D9E9E1`; focus `#68D9A5`.
- Accent chỉ hỗ trợ: energy yellow `#FFC857`, calm blue `#58B9E8`, care coral `#FF7D75`, personal purple `#8B7CF6`.
- Status giữ semantic độc lập, không dùng màu đơn độc để biểu đạt selected/error/completed.
- Gradient chỉ dùng cho hero, CTA chính, celebration hoặc một featured surface; tối đa một dominant gradient above-the-fold.

### 2.2 Typography, spacing và shape

- Giữ Roboto/system và semantic text styles. Hero 28–34; screen title 24–28; section 18–20; body 14–16; label 12–14; CTA 15–17.
- Mobile page padding 16; section rhythm 20–24; card padding 16–20; minimum interactive target 48 dp.
- Radius: input/control 12–14; selection 18–20; standard card 20; hero 24–28; sheet top 28; chip/pill capsule.
- Không cố định height quanh text động; title/body mặc định tối đa hai dòng khi phù hợp.

### 2.3 Motion, state và accessibility

- Press 110–160 ms; selection 180–240 ms; entrance 240–360 ms; wizard 320–420 ms; progress 350–550 ms; Nabi 450–900 ms.
- Mọi motion phải có reduced-motion fallback; dispose controller; không chạy nhiều painter/animation nặng đồng thời.
- Async UI phải có loading, ready, empty, error, working/disabled, success; lỗi được sanitize bằng tiếng Việt.
- SafeArea, keyboard-safe CTA, responsive 320–390 px, text scale lớn, Semantics/Tooltip, contrast và 48 dp là gate bắt buộc.

### 2.4 Component contracts

- Chuẩn hóa `AppButton`, `AppCard`, `AppChip`, `AppInput`, `AppBadge`, `SectionHeader`, `EmptyState`, `LoadingState`, `ErrorState`.
- Existing pages ưu tiên `theme.dart`; primitive-first boundary dùng `design_system.dart`. Không import hai barrel không định danh trong cùng widget.
- Global Nabi phải dùng hệ thống expression/route hiện có; không tạo mascot độc lập trong feature.

### 2.5 Dark mode và Admin/Sale

- App hiện chỉ wire light theme. Phạm vi này chuẩn hóa dark-capable tokens/components nhưng không tự bật global dark mode nếu chưa có product decision và test đầy đủ.
- Admin và Sale không bị ép thành consumer green 65–75%. Chúng dùng cùng foundation/tokens nhưng giữ mật độ, trạng thái quyền, tài chính, audit và trusted-state semantics riêng.

## 3. Kết quả khảo sát hiện trạng

| Hạng mục | Kết quả |
|---|---:|
| Core theme/design files | 37 |
| Page/Screen | 46 |
| Widget/Component | 54 |
| Router/Navigation | 12 |
| Presentation controller/state | 14 |
| Import compatibility theme | 80 |
| Import 3-layer design system | 3 |
| File import cả hai barrel | 0 |
| Ứng viên raw color ngoài core theme | 334 |
| Ứng viên raw spacing ngoài core theme | 127 |
| Ứng viên raw radius ngoài core theme | 97 |
| Ứng viên raw duration ngoài core theme | 87 |
| File UI ứng viên không có inbound import | 32 |
| Ứng viên presentation import storage/datasource | 8 |
| Ứng viên render raw error | 8 |

Các số literal/import là kết quả regex/static scan để định vị; từng trường hợp phải được đọc thủ công trước khi sửa. `AppColors` hiện vẫn blue/clinical-first, trong khi onboarding đã có palette Green Wellness feature-local. Vì task là toàn dự án, core-theme migration được coi là một thay đổi coherent được phê duyệt, sau đó onboarding local palette sẽ được hợp nhất thay vì nhân đôi.

### 3.1 Hotspot rủi ro cao

| File | LOC | Rủi ro chính |
|---|---:|---|
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` | 3875 | file rất lớn, 7 raw color, route/state regression, permission/audit |
| `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | 2242 | file rất lớn, 19 raw color, nhiều layout literal, route/state regression, data/action dense |
| `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | 1899 | file rất lớn, 24 raw color, nhiều layout literal, route/state regression, data/action dense |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` | 1876 | file rất lớn, route/state regression |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | 1745 | file rất lớn, 6 raw color, route/state regression |
| `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | 1385 | 14 raw color, nhiều layout literal, route/state regression |
| `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | 1244 | 8 raw color, route/state regression |
| `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | 1201 | 11 raw color, route/state regression |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart` | 1083 | 11 raw color, nhiều layout literal, consent/step state |
| `lib/sale_referral/presentation/pages/sale_shell_page.dart` | 1082 | route/state regression |
| `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart` | 1023 | 6 raw color |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` | 926 | 42 raw color, nhiều layout literal, consent/step state |
| `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | 912 | 11 raw color, route/state regression |
| `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart` | 905 | 7 raw color, route/state regression |
| `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` | 865 | 8 raw color, route/state regression |

### 3.2 Trùng lặp và legacy cần quyết định

- `AppSpacing`, `AppRadius`, `AppDuration` tồn tại ở cả `lib/core/theme/` và `lib/core/constants/app/`; legacy constants phải được kiểm tra usage trước khi deprecate.
- `AppTextStyles` tồn tại ở compatibility layer và token component layer; không trộn barrel.
- `SectionHeader` tồn tại ở dashboard và design primitive; cần chọn canonical component và migrate an toàn.
- `NabiRouteObserver` có global và V1 compatibility implementation; giữ adapter/version boundary, không hợp nhất mù.
- Các file zero-inbound chỉ được xóa khi route/barrel/reflection/test chứng minh không còn dùng; mặc định giữ nguyên và đánh dấu N/A/legacy.

## 4. Kiến trúc UI mục tiêu

```text
AppTheme / semantic tokens
  → primitives & shared components
    → app shell / navigation / Nabi overlay
      → feature pages/widgets
        → existing Provider/Controller contracts
```

### 4.1 Cấu trúc đề xuất

- `lib/core/theme/`: một source of truth cho palette, typography, spacing, radius, shadow, gradient, motion, Material component themes.
- `theme.dart`: compatibility barrel cho phần lớn existing pages.
- `design_system.dart`: primitive-first barrel; không thay thế hàng loạt nếu gây symbol conflict.
- `lib/shared/widgets/` hoặc primitive layer: component dùng chung thực sự; không copy-paste style vào feature.
- Feature presentation giữ layout đặc thù nhưng chỉ dùng semantic tokens và shared primitives.
- Admin/Sale dùng semantic profile riêng trên cùng foundation; không hard-code trusted status bằng màu/copy tùy ý.

### 4.2 Nguyên tắc coding

- Không thay logic nghiệp vụ, repository, datasource, schema, API hoặc route contract trong UI refactor.
- Presentation không được thêm direct DAO/API access. Existing direct-import candidates phải được xác minh và không mở rộng.
- Không xóa code cũ chỉ vì không có inbound import tĩnh.
- Không đổi text pháp lý, disclaimer, consent hoặc trusted payment/access wording nếu không có DD căn cứ.
- Mỗi batch nhỏ, format/analyze/test targeted trước khi mở rộng.
- Checklist cập nhật ngay sau mỗi file; `[x] Đã coding` và `[x] Đã kiểm tra` là hai gate khác nhau.

## 5. Kế hoạch thực thi theo giai đoạn

| Giai đoạn | Phạm vi chính | Phụ thuộc | Điều kiện hoàn thành |
|---:|---|---|---|
| 0 | Baseline và khóa hợp đồng | Checklist hiện tại, route/state contracts | Không sửa code; baseline tests/commands và blocker được ghi. |
| 1 | Core Theme và design tokens | GĐ0 | Palette/type/spacing/radius/shadow/motion/Material themes thống nhất; theme tests đạt. |
| 2 | Primitives và shared components | GĐ1 | Button/input/card/chip/badge/state components đủ variant/a11y; tests đạt. |
| 3 | App Shell, navigation và Global Nabi | GĐ1–2 | Theme wiring, transition, overlay, bottom nav không che CTA; route regressions đạt. |
| 4 | Splash, onboarding và auth handoff | GĐ1–3 | Green Wellness flow, consent/state giữ nguyên; narrow/text-scale/widget tests đạt. |
| 5 | Dashboard, tracking, schedule, meal plan, AI | GĐ1–3 | Core daily surfaces đồng nhất, real-data actions giữ nguyên; targeted tests đạt. |
| 6 | Profile, settings, nutrition và care modules | GĐ1–3 | Secondary V1 surfaces không còn visual drift; dev-only UI tách rõ. |
| 7 | V2/V3 authenticated/paid surfaces | GĐ1–3 | Auth/score/payment/family/advanced tracking giữ access/trusted-state semantics. |
| 8 | Admin và Sale/Referral | GĐ1–3 | Foundation thống nhất nhưng operational/financial semantics không bị consumer hóa. |
| 9 | State matrix, responsive, accessibility, reduced motion | GĐ4–8 | Mỗi screen có state/a11y/responsive evidence; không overflow. |
| 10 | Widget/theme/architecture tests | GĐ1–9 | 23 test checklist được cập nhật/chạy; architecture boundaries pass. |
| 11 | Full validation và visual QA | GĐ10 | Analyze/test/build + device size/text-scale/state matrix có kết quả thật. |
| 12 | Docs, checklist, report và ZIP | GĐ11 | Checklist final, report, worklog, file list, blockers, ZIP source đã sửa. |

## 6. Chi tiết từng giai đoạn

### Giai đoạn 0 — Baseline và khóa hợp đồng

**File/nhóm:** `AGENTS.md`, `.codex/*`, routes, app shells, checklist hiện tại, targeted tests.

**Công việc:** ghi baseline git/file hash; xác định Flutter/Dart availability; chạy các test hiện có khả dụng; chụp/ghi UI baseline nếu có device; đánh dấu file legacy và direct-import candidates; không sửa source.

**Rủi ro:** archive không có `.git`; môi trường hiện tại chưa thấy `flutter`, `dart`, `powershell` trong PATH. Coding vẫn có thể thực hiện nhưng validation cuối phải chạy ở môi trường Flutter hoặc được báo blocker rõ.

**Kiểm tra:** route inventory, import graph, baseline analyzer/test output, assets/font config.

### Giai đoạn 1 — Core Theme và design tokens

**File chính:** toàn bộ `lib/core/theme/` (37 file), đặc biệt `app_colors.dart`, `app_theme.dart`, `app_gradients.dart`, `app_shadows.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`, `app_motion.dart`, `app_duration.dart`, foundation/tokens và barrels.

**Công việc:** migrate semantic palette; giữ status colors; cập nhật gradients/shadows; chuẩn type/spacing/radius; Material component themes cho app bar, navigation, input, button, dialog, sheet, snackbar, tooltip, progress; dark-capable mapping; loại drift giữa compatibility và 3-layer bằng adapter có chủ đích.

**Không làm:** bật global dark mode hoặc xóa legacy API ngay nếu call sites chưa migrate.

**Kiểm tra:** core theme tests, contrast review, symbol conflict, no mixed barrels.

### Giai đoạn 2 — Primitives và shared components

**File chính:** `lib/core/theme/primitives/**`, `lib/shared/widgets/**`, dashboard `SectionHeader`, shared loading/AI state widgets.

**Công việc:** chuẩn variant, loading/disabled/selected/error, 48 dp, semantics, focus, keyboard, reduced motion; chọn canonical `SectionHeader`; tránh nested cards và duplicate component.

**Kiểm tra:** primitive widget tests, golden/snapshot nếu hạ tầng có, text scale và disabled/focus states.

### Giai đoạn 3 — App Shell, navigation và Global Nabi

**File chính:** `lib/app/**`, `lib/main.dart` wiring-only, `lib/app_versions/*/app/**`, routers/transitions, `lib/features/nabi/**`, V1 Nabi compatibility, `ai_chat_fab.dart`, `menu_page.dart`.

**Công việc:** áp theme toàn app; chuẩn surface/background/nav; giữ unified role routing; transition token; overlay safe area/keyboard/bottom-nav; reduced motion; chỉ một Nabi focal point.

**Kiểm tra:** app-shell tests, route/back/state retention, user/admin surface switching, overlay không che CTA.

### Giai đoạn 4 — Splash, onboarding và auth handoff

**File chính:** `lib/app_versions/v1/features/splash/**`, `onboarding/presentation/**` (21 file), V1 auth entry, V2 auth pages/gate.

**Công việc:** hợp nhất feature-local green palette vào semantic core; mỗi step một task/CTA; progress capsule; selection cards/sheets; concise copy; keyboard-safe CTA; consent riêng; directional transition; sanitize errors; preserve state/controller methods.

**Kiểm tra:** onboarding entry/completion tests, auth smoke, back navigation, duplicate submit, large text, reduced motion, invalid-field scroll.

### Giai đoạn 5 — Daily core surfaces

**File chính:** dashboard (31 file), daily health tracking, lifestyle schedule, meal plan, AI chat/voice, daily routine, shared AI loading.

**Công việc:** migrate hero/data hierarchy; green dominance không che status; real-data loading/empty/error; completion actions chỉ qua controller; meal detail/replacement UI giữ existing logic; chat composer/typing/quota state; voice lifecycle visual state.

**Kiểm tra:** dashboard/meal/schedule/chat widget and contract tests, no production mock, no duplicate write, no raw AI error.

### Giai đoạn 6 — Secondary V1 surfaces

**File chính:** profile, settings, nutrition, body metrics, features hub, community, sleep/stress/water, personal goals, quick/gentle care, weekly summary, other/dev viewer.

**Công việc:** chuẩn cards/forms/empty states/copy; responsive grids; tách dev-only database viewer khỏi consumer patterns; giữ medical disclaimer; xác minh direct storage import candidates thay vì mở rộng kiến trúc sai.

**Kiểm tra:** feature widget tests, guest/auth reactivity, calculator disclaimer, narrow screen.

### Giai đoạn 7 — V2/V3

**File chính:** V2 auth/home/health score/cloud-sync states/health modules/payments/wellness rewards; V3 home/familyplus/advanced tracking/app shell.

**Công việc:** trusted-state UI cho auth/sync/score/payment/access; không tạo zero/mock data; paid/family state chỉ theo provider; Green Wellness consumer treatment có kiểm soát.

**Kiểm tra:** auth/health score/payment/family/advanced tracking tests và route/access boundary tests.

### Giai đoạn 8 — Admin và Sale/Referral

**File chính:** Admin login/shell/controllers/widgets/router (10 file), Sale participation/shell (2 visual file + adjacent contracts).

**Công việc:** dùng foundation, type, spacing, focus, state components; giữ density, tables, permission denied, audit, financial warning, trusted server state; không biến toàn bộ console thành gradient consumer UI.

**Kiểm tra:** admin permission/payment review tests; Sale shell tests; desktop/tablet/mobile breakpoints; keyboard/focus.

### Giai đoạn 9 — Cross-cutting QA pass

Rà từng checklist row cho loading/ready/empty/error/working/success, disabled/selected, semantics, tooltips, 48 dp, text scale, SafeArea, keyboard, 320–390 px, 600+ px, reduced motion và contrast. Mọi raw literal còn lại phải có lý do kỹ thuật (painter geometry, asset dimension, protocol constant) hoặc chuyển thành token.

### Giai đoạn 10–12 — Tests, validation và bàn giao

Cập nhật/bổ sung test; chạy targeted rồi full; build APK; kiểm tra trực quan; cập nhật checklist hai bước; lập report tổng kết và worklog; đóng gói toàn bộ project đã sửa thành `.zip`.

## 7. Validation ladder

```bash
# Mỗi batch
dart format <touched paths>
flutter analyze <touched source/test paths>
flutter test <matching tests>

# Boundary/full
flutter test test/architecture_version_boundary_test.dart
flutter test test/architecture_preservation_property_test.dart
flutter test test/core/theme
flutter test
flutter analyze
flutter build apk --debug
```

Nếu dùng Windows project tooling, chạy thêm `.codex/tool/codex_quick_check.ps1`, `.codex/tool/codex_check.ps1 -BuildApk`, `tools/run_v2.ps1 -ValidateOnly`. Không tuyên bố PASS khi command chưa chạy hoặc môi trường thiếu SDK.

## 8. Ma trận kiểm tra trực quan

| Trục | Giá trị tối thiểu |
|---|---|
| Width | 320/360, 390–430, 600+, desktop Admin |
| Text scale | 1.0, 1.3, 1.6–2.0 tùy khả năng |
| State | loading, ready, empty, error, disabled/working, selected, success |
| Input | keyboard mở/đóng, validation, focus, autofill nếu có |
| Motion | mặc định và `disableAnimations=true` |
| Navigation | forward/back/deep link/auth handoff/role switch |
| Overlay | Nabi/FAB/sheet không che CTA, nav hoặc keyboard |

## 9. Rủi ro và giả định

1. **Khối lượng lớn:** 202 source rows, nhiều file >1.000 LOC. Phải chia batch; không nên mass-replace.
2. **Theme blast radius:** đổi `AppColors.primary` tác động toàn app. Core theme phải hoàn tất và test trước feature migration.
3. **Admin/Sale boundary:** Design System yêu cầu foundation chung nhưng không consumer recolor; đây là quyết định áp dụng mặc định.
4. **Legacy/zero inbound:** static graph không chứng minh dead code; không xóa nếu chưa có route/barrel/test evidence.
5. **Dark mode:** chỉ chuẩn token capability, chưa bật global mode.
6. **Business copy:** giữ consent/disclaimer/payment/access text nếu không có DD quyết định khác.
7. **Architecture candidates:** một số presentation file import storage/datasource; refactor UI không tự ý đổi nghiệp vụ, nhưng phải ghi issue hoặc sửa boundary nếu chính call path gây cản trở và có test.
8. **Validation environment:** môi trường hiện tại không có Flutter/Dart/PowerShell trong PATH; cuối task cần môi trường phù hợp hoặc ghi blocker minh bạch.
9. **Visual evidence:** không đánh dấu kiểm tra chỉ dựa trên static scan; cần run/screenshot hoặc widget test tương ứng.
10. **Assets:** giữ asset Nabi hiện có; không tạo mascot/ảnh thương hiệu mới trong refactor này.

## 10. Tiêu chí nghiệm thu cuối

- Checklist từng file được cập nhật, không có dòng visual bỏ trống.
- Core theme và primitives dùng semantic Green Wellness tokens.
- Consumer UI đồng nhất; Admin/Sale đồng nhất foundation nhưng đúng operational semantics.
- Không còn raw style không có lý do; component trùng lặp được hợp nhất hoặc ghi lý do giữ.
- Navigation, state, consent, quota, payment, permission, sync và data actions không regression.
- Targeted/full analyze/test/build có kết quả thật hoặc blocker chi tiết.
- Visual matrix và accessibility/reduced-motion có bằng chứng.
- Báo cáo final đủ số file phát hiện/sửa/N/A/blocker, component mới/tái sử dụng, lỗi đã xử lý/còn lại.
- Project hoàn tất được nén `.zip` và gửi lại.

## 11. Gate xác nhận

Kế hoạch này là gate trước coding. Sau khi người dùng xác nhận, thực thi bắt đầu từ **Giai đoạn 0 → 1**, không sửa feature pages trước khi core theme/primitives ổn định.

## 12. Trạng thái thực thi sau phê duyệt

| Giai đoạn | Trạng thái | Kết quả |
|---|---|---|
| 0. Khóa baseline và hợp đồng | Hoàn tất tĩnh | Đã đọc AGENTS/workflow/domain, xác nhận không chạm nghiệp vụ và SQLite runtime v17. |
| 1. Core Theme và design tokens | Hoàn tất coding | Canonical Green Wellness palette, typography, spacing, radius, shadow, gradient, motion và component theme đã được chuẩn hóa. |
| 2. Shared primitives | Hoàn tất coding | Button, card, chip, badge, loading, empty và error state được nâng cấp về semantics, 48dp target và reduced motion. |
| 3. App Shell/navigation/global Nabi | Hoàn tất coding tĩnh | Visual tokens được áp dụng; route/state/action contracts được giữ nguyên. |
| 4–9. V1/V2/V3/Admin/Sale | Hoàn tất coding tĩnh | 90 source sửa trực tiếp; 62 source review không cần patch cục bộ; 50 source regression-only. |
| 10. Responsive/accessibility/state matrix | Hoàn tất ở cấp code/static | Token, semantics và state primitives đã chuẩn hóa; device visual matrix còn bị chặn. |
| 11. Tests và validation | Hoàn tất một phần | Static validation PASS; Flutter analyze/test/build/visual chưa chạy do thiếu SDK và 57 asset paths. |
| 12. Báo cáo/đóng gói | Hoàn tất | Checklist, manifest, validation report, completion report và worklog đã được tạo; project được đóng gói sanitized ZIP. |

Chi tiết bằng chứng nằm tại:

- `docs/ui/NABI_GREEN_WELLNESS_UI_CHECKLIST.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_CHANGED_FILES.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_VALIDATION_REPORT.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_COMPLETION_REPORT.md`
