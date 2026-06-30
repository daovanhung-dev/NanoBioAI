# Design.md — NanoBio / NamiAI UI Engineering Context

> **Purpose:** This is the UI implementation context for an Agent that must design, refactor, or fix Flutter interfaces in this repository without breaking product flows, version boundaries, data architecture, or the Nabi persona.
>
> **Use with:** root `AGENTS.md` and the selected `.codex` workflow/domain. This document concentrates all UI-relevant knowledge discovered in the current project snapshot; it does **not** replace BD/DD when a change affects a business rule, data contract, permission, quota, payment, referral, notification, or consent.

## 0. Audit scope and reliability

- Snapshot audited: `nano_app.zip` supplied for this task.
- Full file traversal: **4,396 files**, **495,535,349 bytes**; every file was byte-read and checksummed during audit.
- Text/source inventory: **3,770 text files**, **419 Dart files under `lib/`**, **73 Dart tests**, **115 UI/widget-oriented Dart files**, **75 context files under `.codex` / `.agents`**, and **129 app assets**.
- Human-authored code, docs, configuration, DD/BD, routes, theme, providers, controllers, presentation pages/widgets and tests were structurally indexed. Compiled objects, Gradle/Xcode/CMake caches, package artifacts and binary assets were byte-audited plus file-name/metadata indexed; they are not a source of UI logic.
- This document is an **as-of-snapshot** design map. Before editing a feature, confirm the target file and provider contract with `rg` because the repository contains multiple versioned surfaces and some legacy paths.

## 1. Mandatory Agent read order for UI work

1. Read `AGENTS.md`, then `.codex/AGENTS.md` and `.codex/PROJECT_MAP.md`.
2. Choose exactly one workflow (normally `.codex/workflows/coding.md`, `bugfix.md`, or `docs-context.md`) and read the matching file in `.codex/task-skills/`.
3. Read `.codex/domains/ui-nami.md` **and** the feature domain when UI touches behaviour: `onboarding.md`, `dashboard.md`, `ai-service.md`, `health-tracking.md`, `lifestyle-schedule.md`, or `access-membership-referral.md`.
4. Read the target module DD: `docs/DD/<module>/Overall.md`, `Views.md`, `Function_List.md`, and `Import_File.md` before changing user-visible behavior.
5. Read the nearest page, its controller/provider, domain entity, repository/datasource and targeted widget tests. Do not copy a UI pattern from another version unless version-boundary rules allow it.
6. Implement only in the selected surface. Validate formatting/analyze/tests for the changed area, then update project docs/worklog only when the user requests the project workflow artifacts.

**UI task routing:**

| UI scope | Primary source root | Primary domain/context |
|---|---|---|
| V1 guest/basic wellness UI | `lib/app_versions/v1/` | `ui-nami.md` + feature domain |
| V2 authenticated/free UI | `lib/app_versions/v2/` | `access-membership-referral.md` |
| V3 Plus / FamilyPlus | `lib/app_versions/v3/` | `access-membership-referral.md` + related DD |
| Admin operations | `lib/app_versions/admin/` | `docs/DD/admin_dashboard`, `admin_operations` |
| Sale/referral | `lib/sale_referral/` | `docs/DD/referral_direct`, `sale_points` |
| Global Nabi | `lib/features/nabi/` and `lib/app_versions/v1/features/nabi/` | `docs/features/11_NABI_GLOBAL_ASSISTANT.md` |
| Shared theme/primitives | `lib/core/theme/` | `.codex/domains/ui-nami.md` |

## 2. Product model and app surfaces

NanoBio / NamiAI is a Vietnamese health and lifestyle assistant. It is offline-first at the local data level, uses SQLite for core app data, Supabase for identity/cloud synchronization, Gemini-based services for plan/chat behavior, and Riverpod for state.

### 2.1 Product surfaces

| Surface | Intended access | UI responsibility | Primary entry / root |
|---|---|---|---|
| **V1** | Guest/basic baseline | onboarding, initial personal plan, local health widgets, schedules, dashboard | `lib/app_versions/v1/` |
| **V2** | Authenticated free | login/register/recovery, user sync, account-gated functions, health score | `lib/app_versions/v2/` |
| **V3** | Planned Plus / FamilyPlus | premium/family feature scaffolds | `lib/app_versions/v3/` |
| **Admin** | Internal authorized operations | dashboard, users, payments, sales, reconciliation, plans, reports, audit/config | `lib/app_versions/admin/` |
| **Sale/Referral** | Independent product axis | enrollment, customer visibility, point ledger, conversion/payout-related UX | `lib/sale_referral/` |
| **Global Nabi** | Cross-screen companion | visual state, assistant bubble/overlay, route-aware expression | `lib/features/nabi/` |

### 2.2 Entrypoints and shell behavior

- `lib/main.dart` and `lib/main_v2.dart` both initialize environment, Supabase, local-to-cloud write-through dispatching and notification scheduling, then run `BioAIV2App` inside `ProviderScope`. V2 routing still begins at V1 splash to preserve onboarding/handoff flow.
- `lib/main_admin.dart` initializes environment/Supabase and runs `BioAIAdminApp`.
- Every app currently applies `AppTheme.lightTheme`. Treat dark-mode support as token/component capability, not as a globally wired `themeMode` guarantee.
- The V1 dashboard can be hosted standalone or in `MainNavigationPage`; `showStandaloneChatButton` prevents duplicate floating chat entry.

### 2.3 Navigation map


| Surface | Constant | Route |
|---|---|---|
| V1 | `V1RoutePaths.splash` | `'/'` |
| V1 | `V1RoutePaths.login` | `'/login'` |
| V1 | `V1RoutePaths.register` | `'/register'` |
| V1 | `V1RoutePaths.forgotPassword` | `'/forgot-password'` |
| V1 | `V1RoutePaths.onboarding` | `'/onboarding'` |
| V1 | `V1RoutePaths.onboardingEntry` | `'/start'` |
| V1 | `V1RoutePaths.dashboard` | `'/dashboard'` |
| V1 | `V1RoutePaths.healthTracking` | `'/health-tracking'` |
| V1 | `V1RoutePaths.lifestyleSchedule` | `'/lifestyle-schedule'` |
| V1 | `V1RoutePaths.nutrition` | `'/nutrition'` |
| V1 | `V1RoutePaths.sleepTracking` | `'/sleep-tracking'` |
| V1 | `V1RoutePaths.stressTracking` | `'/stress-tracking'` |
| V1 | `V1RoutePaths.menu` | `'/menu'` |
| V1 | `V1RoutePaths.mealPlan` | `'/meal-plan'` |
| V1 | `V1RoutePaths.aiChat` | `'/ai-chat'` |
| V1 | `V1RoutePaths.aiAnalysis` | `'/ai-analysis'` |
| V1 | `V1RoutePaths.foodScanner` | `'/food-scanner'` |
| V1 | `V1RoutePaths.goals` | `'/goals'` |
| V1 | `V1RoutePaths.profile` | `'/profile'` |
| V1 | `V1RoutePaths.settings` | `'/settings'` |
| V1 | `V1RoutePaths.community` | `'/community'` |
| V1 | `V1RoutePaths.admin` | `'/admin'` |
| V2 | `V2RoutePaths.home` | `'/v2'` |
| V2 | `V2RoutePaths.healthScore` | `'/v2/health-score'` |
| V2 | `V2RoutePaths.sale` | `'/v2/sale'` |
| V2 | `V2RoutePaths.authGate` | `AuthRoutePaths.authGate` |
| V2 | `V2RoutePaths.login` | `AuthRoutePaths.login` |
| V2 | `V2RoutePaths.register` | `AuthRoutePaths.register` |
| V2 | `V2RoutePaths.verifyEmail` | `AuthRoutePaths.verifyEmail` |
| V2 | `V2RoutePaths.forgotPassword` | `AuthRoutePaths.forgotPassword` |
| V2 | `V2RoutePaths.resetPassword` | `AuthRoutePaths.resetPassword` |
| V2 | `V2RoutePaths.authCallback` | `AuthRoutePaths.authCallback` |
| V3 | `V3RoutePaths.home` | `'/v3'` |
| Admin | `AdminRoutePaths.root` | `'/admin'` |
| Admin | `AdminRoutePaths.login` | `'/admin/login'` |
| Admin | `AdminRoutePaths.dashboard` | `'/admin/dashboard'` |
| Admin | `AdminRoutePaths.users` | `'/admin/users'` |
| Admin | `AdminRoutePaths.payments` | `'/admin/payments'` |
| Admin | `AdminRoutePaths.sales` | `'/admin/sales'` |
| Admin | `AdminRoutePaths.saleConversions` | `'/admin/sale-conversions'` |
| Admin | `AdminRoutePaths.reconciliation` | `'/admin/reconciliation'` |
| Admin | `AdminRoutePaths.plans` | `'/admin/plans'` |
| Admin | `AdminRoutePaths.reports` | `'/admin/reports'` |
| Admin | `AdminRoutePaths.audit` | `'/admin/audit'` |
| Admin | `AdminRoutePaths.config` | `'/admin/config'` |


## 3. Architecture, ownership and hard boundaries

### 3.1 Required data direction

```text
Presentation (page/widget)
  → Provider / Controller (Riverpod)
  → Domain repository contract
  → Repository implementation
  → Datasource (SQLite / Supabase / service)
  → DAO / API
```

- Presentation must **not** call DAO, raw SQL, Supabase RPC, direct Gemini, or another feature’s datasource directly.
- Build UI from real provider state. Do not introduce mock/sample data that is presented as a user’s actual health, plan, score, quota, payment, or referral result.
- Keep the `AsyncValue`/loading/error/empty/ready contract complete. Do not expose raw errors, stack traces, tables, database names, SQL, API payloads, secrets or logs in end-user UI.
- Prefer immutable `State` models and narrow action methods; use `ref.watch(...)` for render state and `ref.read(...notifier)` for an action.

### 3.2 Version-boundary invariants enforced by tests

1. `lib/core` never imports `app_versions/*` or `sale_referral`.
2. V1 does not depend on V2, V3, Admin or Sale.
3. V2/V3 features must not import lower-version presentation/controller code; share contracts/services instead.
4. V2/V3 do not depend on later tiers, Admin or Sale.
5. Admin does not import user-version presentation/controllers or Sale.
6. Sale/Referral is independent, not a V1/V2/V3 child.
7. Known UI bridges are intentionally narrow: V1 settings can hand off to Sale participation; Sale participation can use the V2 auth route.

### 3.3 Placement rules for new UI

| Change type | Put it here | Do not put it here |
|---|---|---|
| Feature-specific page | `lib/app_versions/<surface>/features/<feature>/presentation/pages/` | `core/`, arbitrary `shared/` |
| Feature-specific reusable widget | same feature’s `presentation/widgets/` | global shared until ≥2 unrelated consumers exist |
| Presentation state/action | feature `presentation/controllers/` + `providers/` | page `setState` for persistent/domain data |
| Cross-surface generic visual primitive | `lib/core/theme/primitives/` | a single feature’s page |
| Global Nabi rendering | `lib/features/nabi/` or V1 Nabi bridge only | duplicated custom FAB/character in every page |
| Design tokens/theme extension | `lib/core/theme/` | hard-coded style in a page |
| Data/behavior change | domain/data layers and DD-guided APIs | a widget callback that bypasses layer flow |

### 3.4 Riverpod and UI state style

- V1 uses `Notifier`, `AsyncNotifier`, `ConsumerWidget` and `ConsumerStatefulWidget` depending on behavior/animation ownership.
- Local visual-only state is allowed in a `StatefulWidget` (tab selection, animation controller, temporary expansion, a non-persisted draft). Domain writes must use the existing controller/provider.
- Always dispose `AnimationController`, `TextEditingController`, `FocusNode`, and `ScrollController` owned by a state object.
- Use `mounted` before UI effects after awaited actions; show generic Vietnamese `SnackBar` feedback, not raw errors.
- Invalidate / reload the providers that own a changed read model. The dashboard controller already centralizes cross-feature invalidation after timeline, mood, water or weight writes.

## 4. UI persona and visual language

### 4.1 Nabi tone

- User-facing language is Vietnamese, warm, calm, concrete and non-judgmental.
- Nabi is a companion, not a clinician. Use gentle invitations such as “Mình cùng xem nhé”, “Bạn có thể thử lại sau một chút nhé”; do not shame, diagnose, overpromise or claim certainty.
- Health data UI must distinguish a wellness suggestion from medical diagnosis. Preserve consent/disclaimer flow, especially onboarding and health calculations.
- Use the current product label consistently **within the touched screen**. The repository contains both `Nabi` and `Nami` legacy text/identifiers; do not do broad branding renames as part of a UI task.

### 4.2 Core visual grammar

| Element | Existing direction |
|---|---|
| Brand | blue `#3B82F6`, cyan `#06B6D4`, purple `#8B5CF6`; healthcare/wellness rather than clinical sterile UI |
| Surface | pale slate/blue background, white cards, thin soft borders, restrained elevation |
| Emphasis | blue/cyan/purple gradients on hero, AI and premium/supporting surfaces; colored soft panels for success/warning/error/info |
| Shape | medium inputs/buttons (`12`), cards (`16`), larger hero containers (`24`), full pill badges/chips |
| Type | Roboto-based system; strong hierarchy through `AppTextStyles`/`AppTypography` rather than arbitrary sizes |
| Icons | rounded Material icons, `AppIcons` for common semantics; avoid emoji as an icon substitute outside data/options that already use emoji |
| Motion | short and purposeful: entrance fade/slide/scale, selected control transitions, progress pulses, loading/typing; never block use or overload a health screen |
| Nabi | use image/expression/overlay components; do not construct a second visual mascot ad hoc |

### 4.3 Layout and responsive rules observed in source

- Mobile-first: page padding normally `AppSpacing.md` (16), section rhythm `AppSpacing.lg` (24), card padding 16–24.
- Use `SafeArea`; use a scrollable body when content can exceed height. `CustomScrollView`/slivers are common for rich long pages; `SingleChildScrollView` for short forms; embedded `GridView` must be `shrinkWrap: true` + non-scrollable.
- Prevent overflows with `Expanded`, `Flexible`, `ConstrainedBox`, `Wrap`, `maxLines`, `TextOverflow.ellipsis` and responsive grids.
- Existing breakpoints are feature-specific: 420–560 content widths for compact screens/forms, profile grid 620, admin internal 720, sale grid 760, desktop admin around 960, large care grid 900. Reuse the nearest feature’s breakpoint rather than inventing a global behavior in an isolated page.
- Admin is responsive desktop-first (sidebar/drawer/content max width); user surfaces are touch-first with 48dp minimum interactive targets.
- The floating chat control reserves bottom navigation space and is draggable. Never overlay a CTA, system navigation or keyboard with it.

## 5. Theme and Design System — canonical usage

### 5.1 Which import to use

```dart
// Existing V1/V2/V3/Admin pages normally use this compatibility barrel:
import 'package:nano_app/core/theme/theme.dart';

// New primitive-first work may use this Layer 3 design-system barrel:
import 'package:nano_app/core/theme/design_system.dart';
```

There are **two coexisting layers**:

1. **Compatibility theme (`theme.dart`)** — `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppDecoration`, `AppGradients`, `AppShadows`, `AppDuration`, `AppAnimations`, `AppIcons`, `AppTypography`. Existing high-fidelity pages use it heavily.
2. **Three-layer design system (`design_system.dart`)** — foundation → semantic tokens → primitives. It is correct for new reusable primitives and some newer components.

**Decision rule:** imitate the nearest maintained page/component. In an existing V1 page, stay on the compatibility layer unless you are deliberately migrating the entire local component boundary. Do not mix both token families arbitrarily inside one compact widget. Never hard-code a color/spacing/radius where a project token exists.

### 5.2 Compatibility theme file map

| File | Ownership / use |
|---|---|
| `lib/core/theme/theme.dart` | public compatibility barrel; preferred import for current feature pages |
| `app_theme.dart` | `AppTheme.lightTheme` Material theme configuration |
| `app_colors.dart` | brand, semantic, surface, text, border, overlay, icon colors |
| `app_spacing.dart` | 4/8-based spacing scale, semantic spacing, responsive helpers |
| `app_radius.dart` | visual radii and safe clamp helper |
| `app_text_styles.dart` | display/heading/body/label/button/input semantic styles + color helpers |
| `app_typography.dart` | font weights, fixed text-size helpers and readability helpers |
| `app_gradients.dart` | branded/semantic/health/AI/hero/glass gradients + helpers |
| `app_shadows.dart` | elevation, colored and dark-mode shadow recipes + helpers |
| `app_decoration.dart` | complete `BoxDecoration` factories (card/input/button/glass/sheet/etc.) |
| `app_duration.dart` | motion-duration constants |
| `app_animations.dart` | transition/widget/animation helper factories |
| `app_icons.dart` | semantic rounded Material icon catalog and state mappers |

### 5.3 Color tokens — use semantic intention, not raw literals

`AppColors` defines the following stable groups:

| Need | Use |
|---|---|
| Main CTA / active state | `primary`, `primaryDark`, `primaryLight`, `primarySoft` |
| AI / supporting accent | `secondary`, `secondaryDark`, `secondaryLight`, `secondarySoft`, `tertiary` |
| Outcome/status | `success`/`successSoft`, `warning`/`warningSoft`, `error`/`errorSoft`, `info`/`infoSoft` |
| Page/surface | `background`, `scaffold`, `surface`, `surfaceElevated`, `card`, `cardAlt`, `inputBackground`, `modalBackground` |
| Text hierarchy | `textPrimary`, `textSecondary`, `textMuted`, `textHint`, `textDisabled`, `textInverse` |
| Border / separator | `border`, `borderLight`, `divider`, `outline` |
| Interaction overlays | `hover`, `pressed`, `focused`, `selected`, `disabled`, `overlay`, `scrim` |
| Dark equivalents | `dark*` variants only inside a verified dark-aware component |
| Legacy aliases | `backgroundColor`, `surfaceColor`, `cardColor`, `scaffoldBackground`, etc.; use only to preserve old code, not for new public API |

`AppColors.primaryGradient`, `blueGradient`, `premiumGradient`, and `successGradient` exist for short legacy use. For named visual roles prefer `AppGradients`.

### 5.4 Spacing, radius and type

| API | Values / functions | How to use |
|---|---|---|
| `AppSpacing` | base `xxs=2`, `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48`, `xxxl=64`, `xxxxl=96` | `const SizedBox(height: AppSpacing.lg)`, `EdgeInsets.all(AppSpacing.md)` |
| `AppSpacing` semantic | `pagePadding`, `sectionSpacing`, `cardPadding`, `itemSpacing`, `iconTextSpacing`, button/input/list/dialog/sheet values, minimum targets | choose semantic name when layout intent is clear |
| `AppSpacing.scale(value)` | currently returns value | compatibility hook; do not rely on it for adaptive layout |
| `AppSpacing.adaptive(...)` | picks a value based on device/context parameters | use only where a nearby page already uses it |
| `AppSpacing.responsive(...)` | responsive spacing helper | use for a single adjustable dimension, not as replacement for `LayoutBuilder` |
| `AppSpacing.spaceBetween(count, itemSize)` | calculates inter-item spacing | only for deliberate evenly distributed items |
| `AppRadius` | `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `circular=9999`; semantic `button`, `card`, `input`, `dialog`, `bottomSheet`, `avatar`, `pill`, `fab` | `BorderRadius.circular(AppRadius.card)` |
| `AppRadius.clamp(value, min, max)` | prevents invalid radius | use for input-derived or dynamic radius only |
| `AppTextStyles` | display/heading/body/label/button/caption/helper/chip/input/appBar/section styles | start from a semantic style then `copyWith(color:, fontWeight:, height:)` |
| `AppTextStyles.custom(...)` | builds an explicit style from named inputs | use only when no semantic role fits |
| `AppTextStyles.primary/secondary/muted/inverse/success/warning/error/brand(style)` | applies canonical text color to an existing style | preserve visual type then change only semantic color |
| `AppTypography` | weights `regular`, `medium`, `semiBold`, `bold`; scale helpers | favor `AppTextStyles` first; use `AppTypography` for controlled weight/response/readability |
| `AppTypography.style/responsive/adaptive` | custom/responsive type builders | use for reusable custom component, not every page text |
| `AppTypography.display/heading/body/label/button/input/captionStyle/overline` | named style factories requiring color | use inside a local reusable widget where `AppTextStyles` is not enough |
| `AppTypography.elderlyFriendly/readable/italic/underline/strike` | transforms a `TextStyle` | apply intentionally for accessibility or text semantics |

### 5.5 Gradient, shadow and decoration factory reference

| API | Available functions / presets | Recommended use |
|---|---|---|
| `AppGradients` | `primary`, `primaryReverse`, `primarySoft`, `premium`, `premiumDark`, `surface`, `surfaceAlt`, `darkSurface`, `darkSurfaceElevated`, `success`, `warning`, `danger`, `info`, `health`, `energy`, `sleep`, `meditation`, `ai`, `futuristic`, `hero`, `dashboard`, `onboarding`, `glass`, `glassDark` | use a named semantic gradient for hero/AI/status panels; avoid gradients on every card |
| `AppGradients.custom(colors, begin, end, stops, tileMode)` | creates a named one-off `LinearGradient` | use only after checking no existing preset fits |
| `AppGradients.opacity(color, opacityStart, opacityEnd, begin, end)` | makes a softened same-color gradient | useful for a low-noise background wash |
| `AppGradients.adaptive(darkMode, light, dark)` | chooses light/dark gradient | only when the screen is actually dark-aware |
| `AppShadows` | base `xs`→`xl`; semantic `card`, `cardRaised`, `dialog`, `bottomSheet`, `button`, `fab`, `floating`, `focus`; colored status shadows; `glass`, `soft`, dark presets | cards normally use `card`/`cardRaised`; keep elevation subtle |
| `AppShadows.custom(color, blurRadius, spreadRadius, offset)` | one `BoxShadow` list | reserve for a reusable visual special case |
| `AppShadows.opacity(color, opacity, blurRadius, spreadRadius, offset)` | color-alpha shadow | preferred for colored glow or custom accent |
| `AppShadows.elevation(level, darkMode, color)` | maps level to shadow recipe | use when component exposes elevation as a param |
| `AppShadows.surface(elevated, darkMode)` | returns surface shadow or none | suitable for reusable surface components |
| `AppDecoration.base(...)` | raw composition factory | use only inside a decoration helper |
| `AppDecoration.card/elevatedCard/premiumCard` | card surfaces | primary choice for reusable card implementations |
| `AppDecoration.container/input/focusedInput/errorInput` | generic and form-field surfaces | maintain input state hierarchy |
| `AppDecoration.button/outlinedButton` | decoration-only button surfaces | use only when Material `ButtonStyle` / `AppButton` cannot satisfy UI |
| `AppDecoration.gradient/primaryGradient/premiumGradient` | gradient container recipes | hero/CTA/featured section, not routine data cards |
| `AppDecoration.glass/glassDark` | glassmorphism factory | onboarding/hero overlays only; ensure text contrast |
| `AppDecoration.dialog/bottomSheet/circle/outlined` | special container shapes | use for their named purpose |
| `AppDecoration.radius(value)`, `border(color,width)`, `adaptive(...)` | low-level helpers | use in reusable widgets to avoid duplicates |

### 5.6 Motion and animation API reference

| API | Function / value | Use |
|---|---|---|
| `AppDuration` | `instant`, `xFast`, `fast`, `normal`, `slow`, `xSlow` | base duration selection |
| `AppDuration` components | `tap`, `hover`, `press`, `focus`, `button`, `card`, `input`, `switcher`, `checkbox`, `progress`, `pageTransition`, `modalTransition`, `bottomSheet`, `dialog`, `navigation`, `shimmer`, `loading`, `skeleton`, `pulse`, `stagger` | select the named behavioral duration rather than a raw millisecond literal |
| `AppAnimations` curves | `standardCurve`, `emphasizedCurve`, `decelerateCurve`, `accelerateCurve`, `bounceCurve`, `smoothCurve` | use for a predictable animation feel |
| `fade`, `slide`, `scale`, `rotate`, `size` | wraps matching Flutter transition | for an existing `Animation<T>` and a lightweight single effect |
| `fadeScale`, `fadeSlide` | combined entrance transitions | default entrance for cards/page sections |
| `animatedOpacity`, `animatedScale`, `animatedContainer` | implicit animation wrappers | selected/pressed/visible visual state |
| `switcher` | `AnimatedSwitcher` with project fade-scale transition | swap loading/content or small state panels |
| `stagger(index, base)` | derives stagger delay | repeating list entrance only; keep count modest |
| `pageTransition`, `modalTransition`, `bottomSheetTransition`, `floating` | project-specific composite transitions | full page/modal/sheet/hero entry |
| `transition` | generic wrapper | use only if it clarifies a reusable API |
| `curved`, `slideOffset`, `scaleTween` | builds derived animations | use inside stateful animation owners |

### 5.7 Icons

`AppIcons` wraps rounded Material icons by product meaning (`health`, `sleep`, `nutrition`, `water`, `fitness`, `aiChat`, `settings`, `success`, `warning`, `error`, etc.). Use `AppIcons.icon(icon, size:, color:)` for a direct `Icon`; use `AppIcons.byHealthState(state)` and `AppIcons.byStatus(status)` only for data-driven visual mapping. Never show a raw backend status string to a user.

### 5.8 New 3-layer design-system primitives

| Component | Variants | Contract |
|---|---|---|
| `AppButton` | `primary`, `secondary`, `text`, `icon`, `outlined` | `variant`, `onPressed`, optional `child`, `icon`, `loading`; `onPressed: null` is disabled |
| `AppCard` | `defaultCard`, `elevated`, `outlined` | `variant`, required `child`, optional `onTap`, `padding` |
| `AppChip` | `selectable`, `filter`, `action` | `label`, `selected`, `onTap`, optional `onDeleted`, `icon` |
| `AppInput` | `textField`, `dropdown`, `search` | `controller`, label/hint/error, onChanged/onSubmitted, enabled, obscure, keyboard, maxLines, prefix/suffix |
| `AppBadge` | `status`, `count`, `dot`; status `success`, `warning`, `error`, `info`, `neutral` | choose the variant, then pass correct label/count/status |
| `SectionHeader` | — | title, optional subtitle and action label/callback |
| `EmptyState` | — | required icon/title/description, optional action |
| `LoadingState` | `spinner`, `skeleton`, `shimmer` | current non-spinner variants are placeholder visual modes; validate desired behavior |
| `ErrorState` | — | message + optional retry with `retryLabel` |

New primitive code should normally import `design_system.dart` and use `AppColorTokens`, `AppSpacingTokens`, `AppRadiusTokens`, `AppShadowTokens`, `AppMotionTokens`, and its `AppTextStyles`. This `AppTextStyles` has the same symbol name as the compatibility file; never import both barrels unqualified in one file.

## 6. Feature UI contracts and action APIs

### 6.1 Onboarding

- Feature root: `lib/app_versions/v1/features/onboarding/`.
- Main UI: `OnboardingEntryPage` → `OnboardingPage` → welcome/basic info/goals/conditions/lifestyle/extras/consent/review/result step widgets.
- Input design: use choice cards/chips/pickers before free text; `OnboardingTextField` only where a value genuinely requires input. Keep choices compact and readable.
- `OnboardingController` action contract: `nextStep`, `previousStep`, `goToStep`, all `update*` setters, `toggleGoal`, `toggleCondition`, `toggleHabit`, `setAgreed`, and `saveOnboarding`.
- Consent is a required separate step; UI cannot silently mark agreement. Completion persists onboarding state, marks local onboarding complete and invokes the configured completion callback/plan handoff.
- Do not log sensitive onboarding values to user UI or documentation.

### 6.2 Dashboard and daily companion

- Primary page: `DashboardPage` uses `dashboardProvider`, `dashboardDynamicProvider`, and `dashboardControllerProvider`.
- It renders loading/error/data with `AsyncValue.when`, has pull-to-refresh, entry/score/pulse animations, summary/score/metrics/insights/timeline/goals/lifestyle sections and optional `DraggableAIChatButton`.
- `DashboardController` UI action API: `generateAdditionalPlan`, `completeTimelineItem`, `saveDailyCheckIn`, `addWater`, `setWater`, `saveWeight` (plus legacy `genMealByWeeksToDB`). Actions invalidate dashboard-dependent read models.
- Timeline completion is guarded by feature/domain rules; do not add a local completion illusion that bypasses controller behavior. “Để lát nữa” remains UI-only where persistence has no skip schema.
- Dashboard displays real SQLite-derived data; production mock data is forbidden.

### 6.3 Daily health tracking

- `DailyHealthTrackingPage` consumes `dailyHealthTrackingProvider` and `DailyHealthTrackingController`.
- Controller actions: `refresh`, `toggleTask`, `addWater`, `addSteps`, `dismissEncouragement`.
- UI includes header/score, encouragement, category grid, task cards, quick action controls and explicit loading/error UI. Preserve task semantics and quick-update constraints.

### 6.4 Lifestyle schedule and meal plan

- `LifestyleSchedulePage` follows controller state; action API is `refresh`, `selectDate`, `toggleItem`, `dismissEncouragement`. It represents date-based schedule items and completion state.
- `MealPlanPage` consumes `MealPlanController`, which exposes `refreshMealPlans`. Content is weekly/day-oriented, responsive and constrained with its local responsive helper.
- New schedule/meal UI must not reach SQLite directly; preserve date/timezone, quota and AI-generated-plan behavior.

### 6.5 AI chat

- `AIChatScreen` provides ChatGPT-like header, message list, assistant/user bubbles, suggestions grid, composer, send button, typing indicator and empty state.
- `AIChatController` action API: `sendMessage`, `clearChat`, `dismissError`; it loads history internally.
- Render ongoing response/typing state; prevent duplicate sends while sending. Do not expose provider/AI exception objects, raw prompts, raw payloads or internal tokens.

### 6.6 Profile and settings

- `ProfilePage` is a responsive personal health summary; grid columns adapt at local breakpoint. Editing and account operations must enter their provider/service contract.
- `SettingsView` uses settings provider actions `setDarkMode`, `setPushEnabled`, `clearCache`; account security and sale/referral entry are present. Its display must never reveal local database/debug details except in explicit developer-only routes.
- `DevDatabaseViewerPage` is an internal/developer screen; it is not a pattern for end-user copy or routine navigation.

### 6.7 V2 authentication and V2 health score

- Auth UI root: `AuthGatePage` plus `V2LoginPage`, `V2RegisterPage`, `V2VerifyEmailPage`, `V2ForgotPasswordPage`, `V2ResetPasswordPage`, `V2AuthCallbackPage` in `auth_pages.dart`.
- `AuthController` action API: `refresh`, `signUpWithEmail`, `signInWithEmail`, `resendEmailConfirmation`, `sendPasswordRecovery`, `updatePassword`, `recoverSessionFromUri`, `signOut`, `requestAccountDeletion`.
- Never make a UI-side claim that account/cloud synchronization succeeded until controller state confirms it. Use status/support states for auth-required/empty/failure situations.
- `HealthScoreHabitsPage` is V2 authenticated health-score UI; render its view model statuses (`authRequired`, `empty`, `ready`, `failure`) rather than inventing zero-valued data.

### 6.8 Nabi global assistant

- Global implementation: `lib/features/nabi/` (`NabiContextNotifier`, route observer/mapper, `NabiAppShell`, `NabiAssistantOverlay`, `NabiCharacter`).
- V1 compatibility rendering: `lib/app_versions/v1/features/nabi/` and `lib/app_versions/v1/shared/widgets/ai_chat_fab.dart`.
- `NabiContextNotifier` updates: `setRoute`, `setChatTyping`, `setChatAnswerReady`, `notifyTaskCompleted`, `notifyTaskSkipped`, `clearTransientState`, `setOnboardingStep`, `completeOnboarding`, `setDailyProgress`, `setStreak`.
- Nabi has route/action/state-specific expressions. Feed it meaningful UI events through its context contract; do not place independent hard-coded `Image.asset` mascots in pages.

### 6.9 Admin and Sale

- Admin `AdminShellPage` is a large responsive operating console. It owns nav/sidebar/drawer, permission-aware sections, filtering, forms, lists, mutation feedback and loading/denied/error states. `AdminController` actions: `signInWithEmail`, `signOut`, `selectSection`, `search`, `refresh`, `runMutation`.
- Sale `SaleShellPage` covers overview, direct customers, points ledger, conversion tools/history; `SaleParticipationPage` manages enrollment/terms/status. Financial, commission, payment, referral and conversion UI are **not** authoritative—show trusted server/RPC state only.

## 7. Page construction patterns

### 7.1 Stateful feature page with Riverpod and motion

```dart
class ExamplePage extends ConsumerStatefulWidget {
  const ExamplePage({super.key});

  @override
  ConsumerState<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends ConsumerState<ExamplePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exampleProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.when(
          loading: () => const LoadingState(
            variant: LoadingVariant.spinner,
            message: 'Nabi đang chuẩn bị cho bạn nhé.',
          ),
          error: (_, __) => ErrorState(
            message: 'Nabi chưa thể mở mục này lúc này.',
            onRetry: () => ref.invalidate(exampleProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.read(exampleControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _entryController,
                        curve: AppAnimations.decelerateCurve,
                      ),
                      child: _ExampleContent(data: data),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 7.2 Stateless card / selector pattern

```dart
class _ExampleMetricCard extends StatelessWidget {
  const _ExampleMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.card(
        border: AppDecoration.border(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          )),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}
```

### 7.3 Required UI state checklist

For every async screen/action decide and implement:

- **Initial/loading:** skeleton/spinner or a designed page state; never a blank white page.
- **Ready:** real provider data with null/empty-safe rendering.
- **Empty:** specific gentle explanation + action if one is valid.
- **Error:** sanitized Vietnamese message + retry or return action; no internal details.
- **Working CTA:** disable/relabel action and prevent duplicate submission.
- **Success:** visible confirmation, provider refresh/invalidation where needed, then navigate only after state is durable.
- **Accessibility:** 48dp targets, readable contrast, labels/tooltips for icon-only controls, no color-only status meaning, text can wrap/scroll.

## 8. UI safety and business constraints

1. Do not portray a plan, score, notification, membership, payment, Sale commission, conversion or referral outcome as confirmed unless its controller/trusted data source confirms it.
2. V1 guest flow, V2 account flow, V3 paid/family flow and Admin/Sale must remain visually and architecturally separate.
3. A user can complete onboarding locally; plan generation/next-plan behavior must obey session/quota/guest one-time guards already implemented in service/controller layers.
4. Do not make medical claims or diagnosis. Keep all existing disclaimers and consent controls.
5. The local UI may render convenience actions, but financial/quota/entitlement decisions cannot trust cache/client-only state.
6. Never reveal secrets, raw server payloads, profile health PII in logs/docs, database schema/debug names or exception text to the user.
7. Do not remove `SafeArea`, scrolling, keyboard-safe padding, responsive constraints or `mounted` checks when restyling a page.
8. Do not perform wide automated formatting/refactors merely to change one view. Existing unrelated formatting/analyzer issues are recorded in project docs; scope validation to the change.

## 9. UI implementation checklist

### Before code

- [ ] Identify app surface/version and feature DD.
- [ ] Read the nearest page/widget plus controller/provider/domain entity.
- [ ] Search for the existing route, callback and state contract with `rg`.
- [ ] Decide whether the change is visual-only or alters data/permission/business behavior.
- [ ] Reuse the local theme family and existing reusable widget before adding a new abstraction.

### During code

- [ ] Keep `Presentation → Provider/Controller → Repository → Datasource → DAO/API`.
- [ ] Use project tokens and `const` where valid.
- [ ] Implement all states and disable repeated writes.
- [ ] Keep Vietnamese Nabi copy, safeguards and consent visible where needed.
- [ ] Preserve version boundaries and global Nabi integration.
- [ ] Use responsive constraints and touch target rules.

### After code

- [ ] Run `dart format` on changed Dart files (or record a tool blocker).
- [ ] Run targeted `flutter test` for feature/widget behavior and architecture constraints where appropriate.
- [ ] Run targeted `flutter analyze` if environment supports it; do not claim a global pass if unrelated legacy failures remain.
- [ ] Verify route reachability, back navigation, keyboard behavior, loading/error/empty/disabled states and a narrow/wide layout.
- [ ] Update worklog/DD/checklist only if user task includes project documentation workflow.

## 10. Current design cautions / known implementation context

- The app contains a polished high-animation onboarding/splash/dashboard path and several lightweight care pages. Preserve visual consistency but do not pretend session-only care-page interactions are persisted until their feature has a data contract.
- `design_system.dart` documents a clean semantic-token + primitive direction; most complex existing feature pages still use `theme.dart` compatibility APIs. Gradual component-boundary migration is safer than a page-wide token rewrite.
- The root entrypoint selects `BioAIV2App`, but V2’s router begins at V1 splash. A visual change around splash/onboarding/auth must test the entire handoff.
- V3 mostly consists of planned feature scaffolds; do not copy V1 presentation/controllers into V3.
- Admin and Sale UI may be visually richer/wider but need stronger permission, audit and trusted-data behavior than consumer health UI.
- This archive includes build/cache artifacts and historical docs. Treat source files and current DD/checklists as authority; do not edit generated/cache directories.

## 11. Curated source tree

```text
nano_app/
├── AGENTS.md                         # bridge to .codex context
├── Design.md                         # this UI context map
├── pubspec.yaml                      # Flutter/Dart dependencies and asset declarations
├── assets/                           # Nabi images/config + icons/illustrations/audio/etc.
├── docs/
│   ├── BD/project_flow/              # product flow
│   ├── DD/                           # module design documents M01–M19
│   ├── checklist/                    # development/DD/coding progress
│   ├── features/, fixbug/, issues/, todo/, test/, worklog/
│   └── supabase/                     # schema / RLS / sync context
├── .codex/                           # mandatory agent workflows/domains/skills/history
├── .agents/                          # discovery bridges to .codex skills
├── lib/
│   ├── app_versions/
│   │   ├── v1/                       # guest/basic app and primary wellness UI
│   │   ├── v2/                       # authenticated/free app
│   │   ├── v3/                       # Plus/FamilyPlus planned surface
│   │   └── admin/                    # internal admin app surface
│   ├── core/                         # constants, theme, local storage, network, utils
│   ├── features/nabi/                # global Nabi implementation
│   ├── sale_referral/                # independent sale/referral product axis
│   ├── services/                     # Supabase, biometric, image picker integrations
│   ├── shared/widgets/               # cross-feature reusable widgets
│   ├── main.dart
│   ├── main_v2.dart
│   └── main_admin.dart
├── test/                             # unit, architecture and widget tests
└── android/ ios/ linux/ macos/ web/ windows/  # platform wrappers
```

## Appendix A — all UI/widget source inventory

This is the exact UI-facing Dart inventory captured in the audit. A “widget” marker means the file declares a widget/stateful widget or is under a presentation/shared component path; use the path rather than names alone as the source of truth.

| Path | LOC | Main declarations | Role / notes |
|---|---:|---|---|

| `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` | 244 | `AdminPanelState`, `AdminController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` | 375 | `AdminLoginPage`, `_AdminLoginPageState`, `_LoginIntroPanel`, `_LoginFeatureChip`, `_LoginFormCard` | Responsive admin sign-in screen. |
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` | 2640 | `AdminShellPage`, `_AdminShellPageState`, `_LoadingScaffold`, `_AdminStateScaffold`, `_AdminSideBar`, `_AdminDrawer`, `_AdminBrand`, `_DrawerBrand`, `_AdminNavButton` | Responsive admin dashboard, management views, lists, filters and actions. |
| `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` | 99 | `AIChatState`, `AIChatController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | 1101 | `AIChatScreen`, `_AIChatScreenState`, `_ChatHeaderTitle`, `_MessageList`, `_MessageRow`, `_AssistantMessage`, `_UserMessageBubble`, `_MessageTime`, `_ChatGptEmptyState` | ChatGPT-like health conversation with prompt suggestions and composer. |
| `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | 81 | `V1AuthEntryIntent`, `V1AuthEntryPage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` | 86 | `BodyMetricsPage`, `_MetricRow` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/community/presentation/pages/community_page.dart` | 66 | `CommunityPage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_controller.dart` | 89 | `DailyHealthTrackingController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_state.dart` | 32 | `DailyHealthTrackingState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` | 574 | `DailyHealthTrackingPage`, `_TrackingHeader`, `_ScoreCard`, `_EncouragementBanner`, `_CategoryGrid`, `_TaskCard`, `_QuickActionButton`, `_TrackingLoading`, `_TrackingError` | Daily mission/health task board with score and quick actions. |
| `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` | 184 | `DashboardController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/enums/insight_type.dart` | 2 | `InsightType` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/mappers/dashboard_health_status_mapper.dart` | 77 | `DashboardHealthStatusMapper` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | 2012 | `DashboardPage`, `_DashboardPageState`, `_DashboardContent`, `_HeroPanel`, `_GeneratePlanCta`, `_PlanRenewalBanner`, `_HeroPill`, `_HealthScorePanel`, `_ScoreRing` | Daily home dashboard, dynamic health data, completion actions, floating AI entry. |
| `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` | 556 | `MainNavigationPage`, `_MainNavigationPageState`, `_AnimatedNavItem`, `_AnimatedBackground`, `_AmbientOrb`, `_NavItemData` | Main bottom-navigation shell that hosts Dashboard / care hub / profile areas. |
| `lib/app_versions/v1/features/dashboard/presentation/utils/dashboard_helpers.dart` | 43 | — | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/common/section_header.dart` | 53 | `SectionHeader` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart` | 799 | `DashboardDailySummaryCard`, `DashboardSlowDayBanner`, `DashboardNextActionSection`, `DashboardDailyCheckInCard`, `DashboardPlanStatusCard`, `DashboardSelfCareStreakCard`, `DashboardHealthScoreBreakdownSheet`, `DashboardWaterUpdateSheet`, `_DashboardWaterUpdateSheetState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chip.dart` | 41 | `GoalChip` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chips_grid.dart` | 32 | `GoalChipsGrid` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_data.dart` | 23 | `GoalData` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_row.dart` | 92 | `GoalProgressRow` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_section.dart` | 36 | `GoalProgressSection` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/health_status/health_metrics_overview_section.dart` | 362 | `HealthMetricsOverviewSection`, `_ScoreBadge`, `_MetricGrid`, `_MetricTile`, `_InsightList` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/hero/header_stat_pill.dart` | 47 | `HeaderStatPill` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/ai_insight_section.dart` | 45 | `AiInsightSection` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_card.dart` | 139 | `InsightCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_data.dart` | 19 | `InsightData` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/conditions_card.dart` | 71 | `ConditionsCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/lifestyle_metric_card.dart` | 67 | `LifestyleMetricCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_metric_row.dart` | 41 | `ScoreMetricRow` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_ring_painter.dart` | 67 | `ScoreRingPainter` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_error.dart` | 49 | `DashboardError` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_loading.dart` | 50 | `DashboardLoading` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/skeleton_box.dart` | 60 | `SkeletonBox`, `_SkeletonBoxState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_card.dart` | 80 | `StatCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_item.dart` | 23 | `StatItem` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/daily_timeline.dart` | 37 | `DailyTimeline` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_event.dart` | 19 | `TimelineEvent` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_row.dart` | 86 | `TimelineRow` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | 432 | `FeaturesHubPage`, `_HeaderSection`, `_NamiCareCard`, `_FeatureTile`, `_SoftBackground`, `_GlowOrb`, `_FeatureAction` | Care feature directory/grid with feature routes. |
| `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart` | 496 | `NamiCareScaffold`, `NamiCareSurfaceCard`, `NamiCareSectionTitle`, `NamiCareInfoTile`, `NamiCareActionChip`, `NamiCareEmptyState`, `_NamiCareHeader`, `_NamiCareBackground`, `_GlowOrb` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` | 171 | `GentleCareModePage`, `_GentleCareModePageState`, `_CareMood`, `_CareSuggestion` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart` | 85 | `LifestyleScheduleController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_state.dart` | 51 | `LifestyleScheduleState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` | 1562 | `LifestyleSchedulePage`, `_ScheduleContent`, `_SchedulePageFrame`, `_DecorativeBackground`, `_SoftOrb`, `_NamiHero`, `_NamiAvatar`, `_NamiMessage`, `_HeroPill` | Date-oriented lifestyle timeline with complete-toggle actions. |
| `lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart` | 29 | `MealPlanController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | 1655 | `MealPlanPage`, `_MealPlanPageState`, `_MealPlanHeader`, `_DecorativeCircle`, `_DateChipSelector`, `_DateChip`, `_DaySummaryBanner`, `_AnimatedMealCard`, `_MealPlanCard` | Weekly meals and per-day view sourced through MealPlan provider. |
| `lib/app_versions/v1/features/nabi/presentation/nabi_page_mixin.dart` | 77 | `NabiPageMixin`, `NabiRefExtension` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/nabi/presentation/nabi_route_observer.dart` | 58 | `NabiRouteObserver` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart` | 1023 | `_NabiAnimProfile`, `NabiCharacterWidget`, `_NabiCharacterWidgetState`, `_NabiAura`, `_NabiImage`, `_NabiFallbackIcon`, `_NabiParticles`, `_ParticlesPainter`, `_NabiShine` | V1 character renderer and image/expression state mapping. |
| `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart` | 288 | `NabiFloatingOverlay`, `_NabiFloatingOverlayState`, `_NabiLabel` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | 867 | `NutritionPage`, `_NutritionLoadingState`, `_Header`, `_NamiNoteCard`, `_SummaryGrid`, `_Metric`, `_MetricCard`, `_MealPlanSection`, `_NutritionLogSection` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart` | 488 | — | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` | 621 | `OnboardingState`, `OnboardingController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` | 1335 | `OnboardingEntryPage`, `_OnboardingEntryPageState`, `_EntryContent`, `_EntryLayout`, `_EntryAtmosphere`, `_EntryAtmospherePainter`, `_EntryTopBar`, `_LaunchPill`, `_EntryHero` | High-impact welcome / onboarding entry with animated atmosphere. |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | 81 | `OnboardingPage` | Wizard host; selects the current onboarding step. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart` | 1018 | `BasicInfoStep`, `_BasicInfoLayout`, `_ProfileProgressBanner`, `_ProgressRing`, `_SectionCard`, `_RequiredBadge`, `_AdaptivePair`, `_BirthYearField`, `_FieldLabel` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart` | 619 | `ConditionsStep`, `_ConditionsLayout`, `_SelectionOverviewBanner`, `_HealthStatusOrb`, `_PremiumConditionsCard`, `_SelectedCountBadge`, `_ChoiceGuidance`, `_OtherNoteHint`, `_MedicalBoundaryInfoCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` | 900 | `ConsentStep`, `_ConsentStepState`, `_ConsentHero`, `_ConsentHeroBubble`, `_ConsentHeroLabel`, `_ConsentHeroStatus`, `_ConsentTrustOrbit`, `_ConsentOrbitBadge`, `_ConsentStatusNotice` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` | 968 | `ExtrasStep`, `_ExtrasStepState`, `_ExtrasHero`, `_HeroBubble`, `_HeroLabel`, `_HeroProgressChip`, `_CareOrbit`, `_OrbitItem`, `_PrivacyNotice` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart` | 813 | `GoalsStep`, `_GoalsLayout`, `_GoalProgressBanner`, `_GoalCounterOrb`, `_GoalSelectionCard`, `_GoalCardHeader`, `_GoalCountBadge`, `_SelectionStatus`, `_OtherGoalCard` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/health_chip.dart` | 138 | `HealthChip` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` | 785 | `LifestyleStep`, `_LifestyleStepState`, `_LifestyleHero`, `_AmbientBubble`, `_HeroLabel`, `_HeroSelectionStatus`, `_LifestyleOrbit`, `_OrbitIcon`, `_PremiumSurface` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` | 731 | `NabiPalette`, `NabiAmbientBackground`, `_NabiAmbientBackgroundState`, `_NabiAmbientPainter`, `NabiGlassPanel`, `NabiMoodPill`, `NabiCompanionAvatar`, `_NabiCompanionAvatarState`, `_NabiFacePainter` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_chip.dart` | 138 | `OnboardingChip` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart` | 635 | `OnboardingSectionCard`, `OnboardingChoiceGrid`, `OnboardingChoiceTile`, `_OnboardingChoiceTileState`, `OnboardingChoicePickerField`, `OnboardingInlineInfo`, `OnboardingLabelValue`, `_CountBadge` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart` | 559 | `OnboardingStepShell`, `_OnboardingBody`, `_Content`, `_TopBar`, `_TopBarLabel`, `_StepBadge`, `_BackButton`, `_BottomAction`, `_OnboardingLayout` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_text_field.dart` | 266 | `OnboardingTextField`, `_OnboardingTextFieldState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart` | 127 | `ResultStep` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` | 1520 | `ReviewStep`, `_ReviewStepState`, `_ReviewHero`, `_HeroBubble`, `_HeroEyebrow`, `_HeroProgressChip`, `_ReviewOrbit`, `_OrbitBadge`, `_ReadinessNotice` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` | 994 | `WelcomeStep`, `_WelcomeStepState`, `_PremiumWelcomeHero`, `_HeroEyebrow`, `_HealthOrbit`, `_OrbitBadge`, `_AmbientHeroPainter`, `_OrbitPainter`, `_SignalRow` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` | 865 | `HealthInsightsView`, `_Header`, `_SummaryCard`, `_InfoChip`, `_TodayOverview`, `_OverviewCard`, `_HealthScoreCard`, `_InsightSection`, `_RecommendationSection` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart` | 114 | `PersonalGoalsPage`, `_PersonalGoalsPageState`, `_GoalOption` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` | 693 | `ProfilePage`, `_EditProfileSheet`, `_EditProfileSheetState`, `_ProfileField`, `_ProfileHeader`, `_MetricGrid`, `_Metric`, `_MetricCard`, `_InfoSection` | Profile summary, body metrics, health information and edit routes. |
| `lib/app_versions/v1/features/profile/presentation/profile_screen.dart` | 13 | `ProfileScreen` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart` | 100 | `QuickCarePage`, `_QuickCareAction` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart` | 905 | `DevDatabaseViewerPage`, `_DevDatabaseViewerPageState`, `_DatabaseSnapshot`, `_DatabaseTableSnapshot`, `_DatabaseColumnSnapshot`, `_DatabaseSummaryCard`, `_SummaryPill`, `_SearchField`, `_TableSelector` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | 1022 | `SettingsView`, `_ChangePasswordSheet`, `_ChangePasswordSheetState`, `_SaleSettingsEntry`, `_ReferralCodeSettingsEntry`, `_ReferralCodeSheet`, `_ReferralCodeSheetState`, `_Header`, `_ProfileCard` | Settings, account security, theme/push, cache and Sale/referral handoff. |
| `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` | 66 | `SleepTrackingPage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | 1452 | `_BootStage`, `_BootStagePresentation`, `SplashPage`, `_SplashPageState`, `_SplashLayout`, `_SplashAtmosphere`, `_SplashAtmospherePainter`, `_SplashTopBar`, `_LaunchStatusPill` | Boot experience, readiness timeline, route hand-off. |
| `lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart` | 66 | `StressTrackingPage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart` | 118 | `WaterTrackingPage`, `_WaterTrackingPageState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart` | 93 | `WeeklySummaryPage`, `_SummaryItem` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v1/shared/widgets/ai_chat_fab.dart` | 493 | `AIChatFAB`, `_AIChatFABState`, `DraggableAIChatButton`, `_DraggableAIChatButtonState`, `_NamiChatBubble`, `_NamiStatusDot`, `_NamiOrbitPainter` | Legacy shared draggable animated AI/Nabi chat FAB. |
| `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` | 136 | `AuthController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` | 149 | `AuthGatePage`, `_AuthLoading`, `_AuthSupportState` | Authentication / hydration gate that decides which V2 state to render. |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | 717 | `V2LoginPage`, `_V2LoginPageState`, `V2RegisterPage`, `_V2RegisterPageState`, `V2VerifyEmailPage`, `_V2VerifyEmailPageState`, `V2ForgotPasswordPage`, `_V2ForgotPasswordPageState`, `V2ResetPasswordPage` | Email/password auth flow and password recovery screens. |
| `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | 346 | `HealthScoreHabitsPage`, `_HealthScoreLoading`, `_HealthScoreReady`, `_ScoreHeader`, `_SectionCard`, `_BreakdownRow`, `_HabitProgressRow`, `_ProgressRow`, `_EmptyInline` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` | 62 | `V2HomePage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart` | 81 | `V3HomePage` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/core/theme/design_system_demo_page.dart` | 667 | `DesignSystemDemoPage`, `_DesignSystemDemoPageState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/core/theme/primitives/badge.dart` | 270 | `BadgeVariant`, `BadgeStatus`, `AppBadge` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/button.dart` | 350 | `ButtonVariant`, `AppButton` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/card.dart` | 204 | `CardVariant`, `AppCard` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/chip.dart` | 214 | `ChipVariant`, `AppChip` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/input.dart` | 272 | `InputVariant`, `AppInput` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/section_header.dart` | 145 | `SectionHeader` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/states/empty_state.dart` | 136 | `EmptyState` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/states/error_state.dart` | 128 | `ErrorState` | Design-system primitive; check variant/constructor contract before using. |
| `lib/core/theme/primitives/states/loading_state.dart` | 157 | `LoadingVariant`, `LoadingState` | Design-system primitive; check variant/constructor contract before using. |
| `lib/features/nabi/application/nabi_controller.dart` | 68 | `NabiController` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/application/nabi_expression_resolver.dart` | 227 | `NabiExpressionResolver`, `NabiResolvedPresentation` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/application/nabi_state.dart` | 47 | `NabiState` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/domain/entities/nabi_expression.dart` | 62 | `NabiEmotion`, `NabiContext`, `NabiEvent` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/nabi.dart` | 10 | — | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/presentation/navigation/nabi_route_mapper.dart` | 44 | `NabiRouteMapper` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/presentation/navigation/nabi_route_observer.dart` | 48 | `NabiRouteObserver` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/presentation/widgets/nabi_app_shell.dart` | 30 | `NabiAppShell` | Presentation/shared/theme UI component. Read this file together with its nearest page/controller/provider before reuse. |
| `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart` | 307 | `NabiOverlayConfig`, `NabiAssistantOverlay`, `_NabiAssistantOverlayState`, `_NabiFloatingControl`, `_NabiSpeechBubble` | Shared global animated Nabi overlay with draggable assistant affordance. |
| `lib/features/nabi/presentation/widgets/nabi_character.dart` | 594 | `NabiCharacter`, `_NabiCharacterState`, `_NabiCharacterPainter` | Custom-painted global Nabi character with expression model. |
| `lib/sale_referral/presentation/pages/sale_participation_page.dart` | 304 | `SaleParticipationPage`, `_SaleParticipationPageState`, `_BuildTermsBody`, `_StatusNotice` | Sale enrollment / terms / status screen. |
| `lib/sale_referral/presentation/pages/sale_shell_page.dart` | 1066 | `SaleShellPage`, `_SaleShellPageState`, `_SalePayoutProfileGate`, `_SalePayoutProfileGateState`, `_OverviewTab`, `_DirectCustomersTab`, `_PointLedgerTab`, `_ConversionToolsTab`, `_ConversionToolsTabState` | Sale dashboard with customer, point, conversion and history tabs. |
| `lib/shared/widgets/loading_gen_ai.dart` | 519 | `AIGeneratingPage`, `_AIGeneratingPageState`, `_ThoughtEntry` | Full-page AI generation loading experience / thought steps. |


## Appendix B — full library source index

All Dart source files under `lib/` are listed below so an Agent can locate the exact owner before searching. Declarations are intentionally abbreviated; inspect the file before changing a public contract.

| File | LOC | First declarations |
|---|---:|---|

| `lib/app_versions/admin/app/bio_ai_admin_app.dart` | 18 | `BioAIAdminApp` |
| `lib/app_versions/admin/core/admin_logger.dart` | 227 | `AdminLogger` |
| `lib/app_versions/admin/features/admin_panel/admin_panel.dart` | 4 | — |
| `lib/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart` | 207 | `AdminSupabaseDatasource` |
| `lib/app_versions/admin/features/admin_panel/data/repositories/admin_repository_impl.dart` | 61 | `AdminRepositoryImpl` |
| `lib/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart` | 297 | `AdminRoleCode`, `AdminPanelSection`, `AdminPermissions`, `AdminTimeDefaults`, `AdminSession`, `AdminDashboardMetric` |
| `lib/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart` | 29 | `AdminRepository` |
| `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` | 244 | `AdminPanelState`, `AdminController` |
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` | 375 | `AdminLoginPage`, `_AdminLoginPageState`, `_LoginIntroPanel`, `_LoginFeatureChip`, `_LoginFormCard` |
| `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` | 2640 | `AdminShellPage`, `_AdminShellPageState`, `_LoadingScaffold`, `_AdminStateScaffold`, `_AdminSideBar`, `_AdminDrawer` |
| `lib/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart` | 17 | — |
| `lib/app_versions/admin/features/admin_panel/providers/admin_providers.dart` | 10 | — |
| `lib/app_versions/admin/router/admin_route_paths.dart` | 15 | `AdminRoutePaths` |
| `lib/app_versions/admin/router/admin_router.dart` | 92 | — |
| `lib/app_versions/v1/app/bio_ai_v1_app.dart` | 20 | `BioAIV1App` |
| `lib/app_versions/v1/features/ai_chat/ai_chat.dart` | 5 | — |
| `lib/app_versions/v1/features/ai_chat/data/models/chat_message_model.dart` | 44 | `ChatMessageModel` |
| `lib/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart` | 54 | `MessageRole`, `ChatMessageEntity` |
| `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart` | 10 | `AIChatRepository` |
| `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart` | 54 | `AIChatRepositoryImpl` |
| `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` | 99 | `AIChatState`, `AIChatController` |
| `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | 1101 | `AIChatScreen`, `_AIChatScreenState`, `_ChatHeaderTitle`, `_MessageList`, `_MessageRow`, `_AssistantMessage` |
| `lib/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart` | 10 | — |
| `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | 81 | `V1AuthEntryIntent`, `V1AuthEntryPage` |
| `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` | 86 | `BodyMetricsPage`, `_MetricRow` |
| `lib/app_versions/v1/features/community/presentation/pages/community_page.dart` | 66 | `CommunityPage` |
| `lib/app_versions/v1/features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart` | 84 | `DailyHealthTasksDao` |
| `lib/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart` | 413 | `DailyHealthTrackingLocalDatasource` |
| `lib/app_versions/v1/features/daily_health_tracking/data/models/daily_health_ai_task_normalizer.dart` | 128 | `DailyHealthAiTaskNormalizer` |
| `lib/app_versions/v1/features/daily_health_tracking/data/models/daily_health_task_model.dart` | 189 | `DailyHealthTaskModel` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart` | 22 | `DailyHealthProfileEntity` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_summary_entity.dart` | 44 | `DailyHealthSummaryEntity` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_task_entity.dart` | 84 | `DailyHealthTaskEntity` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/repositories/daily_health_tracking_repository.dart` | 28 | `DailyHealthTrackingRepository` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/repositories/daily_health_tracking_repository_impl.dart` | 74 | `DailyHealthTrackingRepositoryImpl` |
| `lib/app_versions/v1/features/daily_health_tracking/domain/services/daily_health_task_generator.dart` | 338 | `DailyHealthTaskGenerator` |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_controller.dart` | 89 | `DailyHealthTrackingController` |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_state.dart` | 32 | `DailyHealthTrackingState` |
| `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` | 574 | `DailyHealthTrackingPage`, `_TrackingHeader`, `_ScoreCard`, `_EncouragementBanner`, `_CategoryGrid`, `_TaskCard` |
| `lib/app_versions/v1/features/daily_health_tracking/providers/daily_health_tracking_provider.dart` | 26 | — |
| `lib/app_versions/v1/features/dashboard/dashboard.dart` | 2 | — |
| `lib/app_versions/v1/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart` | 1192 | `DashboardDynamicLocalDatasource`, `_DashboardScheduleItem` |
| `lib/app_versions/v1/features/dashboard/data/datasources/dashboard_local_datasource.dart` | 213 | `DashboardLocalDatasource` |
| `lib/app_versions/v1/features/dashboard/data/models/dashboard_health_data_model.dart` | 96 | `DashboardHealthDataModel` |
| `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart` | 335 | `DashboardDynamicEntity`, `DashboardPlanStatus`, `DashboardSelfCareStreak`, `DashboardSelfCareDay`, `DashboardDailyMetrics`, `DashboardMealItem` |
| `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart` | 83 | `DashboardEntity` |
| `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_health_input.dart` | 84 | `DashboardHealthInput` |
| `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_health_status.dart` | 60 | `DashboardRiskLevel`, `DashboardMetricStatus`, `DashboardHealthInsight`, `DashboardHealthStatus` |
| `lib/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart` | 10 | `DashboardRepository` |
| `lib/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository_impl.dart` | 22 | `DashboardRepositoryImpl` |
| `lib/app_versions/v1/features/dashboard/domain/services/dashboard_companion_service.dart` | 251 | `DashboardMoodCodes`, `DashboardScoreBreakdownItem`, `DashboardCompanionService` |
| `lib/app_versions/v1/features/dashboard/domain/services/dashboard_health_calculator.dart` | 567 | `DashboardHealthCalculator`, `_WeightedScore` |
| `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` | 184 | `DashboardController` |
| `lib/app_versions/v1/features/dashboard/presentation/enums/insight_type.dart` | 2 | `InsightType` |
| `lib/app_versions/v1/features/dashboard/presentation/mappers/dashboard_health_status_mapper.dart` | 77 | `DashboardHealthStatusMapper` |
| `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | 2012 | `DashboardPage`, `_DashboardPageState`, `_DashboardContent`, `_HeroPanel`, `_GeneratePlanCta`, `_PlanRenewalBanner` |
| `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` | 556 | `MainNavigationPage`, `_MainNavigationPageState`, `_AnimatedNavItem`, `_AnimatedBackground`, `_AmbientOrb`, `_NavItemData` |
| `lib/app_versions/v1/features/dashboard/presentation/utils/dashboard_helpers.dart` | 43 | — |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/common/section_header.dart` | 53 | `SectionHeader` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart` | 799 | `DashboardDailySummaryCard`, `DashboardSlowDayBanner`, `DashboardNextActionSection`, `DashboardDailyCheckInCard`, `DashboardPlanStatusCard`, `DashboardSelfCareStreakCard` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chip.dart` | 41 | `GoalChip` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chips_grid.dart` | 32 | `GoalChipsGrid` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_data.dart` | 23 | `GoalData` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_row.dart` | 92 | `GoalProgressRow` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_section.dart` | 36 | `GoalProgressSection` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/health_status/health_metrics_overview_section.dart` | 362 | `HealthMetricsOverviewSection`, `_ScoreBadge`, `_MetricGrid`, `_MetricTile`, `_InsightList` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/hero/header_stat_pill.dart` | 47 | `HeaderStatPill` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/ai_insight_section.dart` | 45 | `AiInsightSection` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_card.dart` | 139 | `InsightCard` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_data.dart` | 19 | `InsightData` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/conditions_card.dart` | 71 | `ConditionsCard` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/lifestyle_metric_card.dart` | 67 | `LifestyleMetricCard` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_metric_row.dart` | 41 | `ScoreMetricRow` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_ring_painter.dart` | 67 | `ScoreRingPainter` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_error.dart` | 49 | `DashboardError` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_loading.dart` | 50 | `DashboardLoading` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/states/skeleton_box.dart` | 60 | `SkeletonBox`, `_SkeletonBoxState` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_card.dart` | 80 | `StatCard` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_item.dart` | 23 | `StatItem` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/daily_timeline.dart` | 37 | `DailyTimeline` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_event.dart` | 19 | `TimelineEvent` |
| `lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_row.dart` | 86 | `TimelineRow` |
| `lib/app_versions/v1/features/dashboard/providers/dashboard_dynamic_provider.dart` | 21 | — |
| `lib/app_versions/v1/features/dashboard/providers/dashboard_health_status_provider.dart` | 29 | — |
| `lib/app_versions/v1/features/dashboard/providers/dashboard_provider.dart` | 32 | — |
| `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | 432 | `FeaturesHubPage`, `_HeaderSection`, `_NamiCareCard`, `_FeatureTile`, `_SoftBackground`, `_GlowOrb` |
| `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart` | 496 | `NamiCareScaffold`, `NamiCareSurfaceCard`, `NamiCareSectionTitle`, `NamiCareInfoTile`, `NamiCareActionChip`, `NamiCareEmptyState` |
| `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` | 171 | `GentleCareModePage`, `_GentleCareModePageState`, `_CareMood`, `_CareSuggestion` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/daos/lifestyle_schedule_items_dao.dart` | 116 | `LifestyleScheduleItemsDao` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart` | 303 | `LifestyleScheduleLocalDatasource` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/models/exercise_task_model.dart` | 60 | `ExerciseTaskModel` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart` | 327 | `ExerciseTasksAiNormalizer`, `ExerciseTaskSlot` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_item_model.dart` | 241 | `LifestyleScheduleItemModel` |
| `lib/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart` | 239 | `LifestyleScheduleTimelineBuilder` |
| `lib/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart` | 141 | `LifestyleScheduleSourceTypes`, `LifestyleScheduleCategories`, `LifestyleScheduleItemEntity` |
| `lib/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_summary_entity.dart` | 51 | `LifestyleScheduleSummaryEntity` |
| `lib/app_versions/v1/features/lifestyle_schedule/domain/repositories/lifestyle_schedule_repository.dart` | 16 | `LifestyleScheduleRepository` |
| `lib/app_versions/v1/features/lifestyle_schedule/domain/repositories/lifestyle_schedule_repository_impl.dart` | 34 | `LifestyleScheduleRepositoryImpl` |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart` | 85 | `LifestyleScheduleController` |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_state.dart` | 51 | `LifestyleScheduleState` |
| `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` | 1562 | `LifestyleSchedulePage`, `_ScheduleContent`, `_SchedulePageFrame`, `_DecorativeBackground`, `_SoftOrb`, `_NamiHero` |
| `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart` | 25 | — |
| `lib/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart` | 196 | `MealPlansDao` |
| `lib/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart` | 30 | `MealPlanLocalDatasource` |
| `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart` | 354 | `MealPlanAiNormalizer`, `MealPlanSlot` |
| `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart` | 315 | `MealPlanModel` |
| `lib/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart` | 92 | `MealPlanEntity` |
| `lib/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository.dart` | 9 | `MealPlanRepository` |
| `lib/app_versions/v1/features/meal_plan/domain/repositories/meal_plan_repository_impl.dart` | 20 | `MealPlanRepositoryImpl` |
| `lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart` | 29 | `MealPlanController` |
| `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | 1655 | `MealPlanPage`, `_MealPlanPageState`, `_MealPlanHeader`, `_DecorativeCircle`, `_DateChipSelector`, `_DateChip` |
| `lib/app_versions/v1/features/meal_plan/providers/meal_plan_provider.dart` | 24 | — |
| `lib/app_versions/v1/features/nabi/domain/nabi_asset_resolver.dart` | 144 | — |
| `lib/app_versions/v1/features/nabi/domain/nabi_context.dart` | 143 | `NabiContext` |
| `lib/app_versions/v1/features/nabi/domain/nabi_state_resolver.dart` | 138 | — |
| `lib/app_versions/v1/features/nabi/domain/nabi_visual_state.dart` | 266 | `NabiVisualState` |
| `lib/app_versions/v1/features/nabi/nabi.dart` | 16 | — |
| `lib/app_versions/v1/features/nabi/presentation/nabi_page_mixin.dart` | 77 | `NabiPageMixin`, `NabiRefExtension` |
| `lib/app_versions/v1/features/nabi/presentation/nabi_route_observer.dart` | 58 | `NabiRouteObserver` |
| `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart` | 1023 | `_NabiAnimProfile`, `NabiCharacterWidget`, `_NabiCharacterWidgetState`, `_NabiAura`, `_NabiImage`, `_NabiFallbackIcon` |
| `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart` | 288 | `NabiFloatingOverlay`, `_NabiFloatingOverlayState`, `_NabiLabel` |
| `lib/app_versions/v1/features/nabi/providers/nabi_provider.dart` | 108 | `NabiContextNotifier` |
| `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | 867 | `NutritionPage`, `_NutritionLoadingState`, `_Header`, `_NamiNoteCard`, `_SummaryGrid`, `_Metric` |
| `lib/app_versions/v1/features/nutrition/providers/nutrition_provider.dart` | 115 | `NutritionSummary` |
| `lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart` | 563 | `OnboardingLocalDatasource` |
| `lib/app_versions/v1/features/onboarding/data/models/onboarding_model.dart` | 60 | `OnboardingModel` |
| `lib/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart` | 73 | `OnboardingEntity` |
| `lib/app_versions/v1/features/onboarding/domain/repositories/ai_repository.dart` | 4 | `AIRepository` |
| `lib/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository.dart` | 8 | `OnboardingRepository` |
| `lib/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart` | 68 | `OnboardingRepositoryImpl` |
| `lib/app_versions/v1/features/onboarding/onboarding.dart` | 3 | — |
| `lib/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart` | 488 | — |
| `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` | 621 | `OnboardingState`, `OnboardingController` |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` | 1335 | `OnboardingEntryPage`, `_OnboardingEntryPageState`, `_EntryContent`, `_EntryLayout`, `_EntryAtmosphere`, `_EntryAtmospherePainter` |
| `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | 81 | `OnboardingPage` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart` | 1018 | `BasicInfoStep`, `_BasicInfoLayout`, `_ProfileProgressBanner`, `_ProgressRing`, `_SectionCard`, `_RequiredBadge` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart` | 619 | `ConditionsStep`, `_ConditionsLayout`, `_SelectionOverviewBanner`, `_HealthStatusOrb`, `_PremiumConditionsCard`, `_SelectedCountBadge` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` | 900 | `ConsentStep`, `_ConsentStepState`, `_ConsentHero`, `_ConsentHeroBubble`, `_ConsentHeroLabel`, `_ConsentHeroStatus` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` | 968 | `ExtrasStep`, `_ExtrasStepState`, `_ExtrasHero`, `_HeroBubble`, `_HeroLabel`, `_HeroProgressChip` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart` | 813 | `GoalsStep`, `_GoalsLayout`, `_GoalProgressBanner`, `_GoalCounterOrb`, `_GoalSelectionCard`, `_GoalCardHeader` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/health_chip.dart` | 138 | `HealthChip` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` | 785 | `LifestyleStep`, `_LifestyleStepState`, `_LifestyleHero`, `_AmbientBubble`, `_HeroLabel`, `_HeroSelectionStatus` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` | 731 | `NabiPalette`, `NabiAmbientBackground`, `_NabiAmbientBackgroundState`, `_NabiAmbientPainter`, `NabiGlassPanel`, `NabiMoodPill` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_chip.dart` | 138 | `OnboardingChip` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart` | 635 | `OnboardingSectionCard`, `OnboardingChoiceGrid`, `OnboardingChoiceTile`, `_OnboardingChoiceTileState`, `OnboardingChoicePickerField`, `OnboardingInlineInfo` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart` | 559 | `OnboardingStepShell`, `_OnboardingBody`, `_Content`, `_TopBar`, `_TopBarLabel`, `_StepBadge` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_text_field.dart` | 266 | `OnboardingTextField`, `_OnboardingTextFieldState` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart` | 127 | `ResultStep` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` | 1520 | `ReviewStep`, `_ReviewStepState`, `_ReviewHero`, `_HeroBubble`, `_HeroEyebrow`, `_HeroProgressChip` |
| `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` | 994 | `WelcomeStep`, `_WelcomeStepState`, `_PremiumWelcomeHero`, `_HeroEyebrow`, `_HealthOrbit`, `_OrbitBadge` |
| `lib/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart` | 32 | `OnboardingInitialPlanException`, `OnboardingCompletionResult` |
| `lib/app_versions/v1/features/onboarding/providers/onboarding_provider.dart` | 54 | — |
| `lib/app_versions/v1/features/onboarding/providers/repository_providers.dart` | 16 | — |
| `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` | 865 | `HealthInsightsView`, `_Header`, `_SummaryCard`, `_InfoChip`, `_TodayOverview`, `_OverviewCard` |
| `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart` | 114 | `PersonalGoalsPage`, `_PersonalGoalsPageState`, `_GoalOption` |
| `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` | 693 | `ProfilePage`, `_EditProfileSheet`, `_EditProfileSheetState`, `_ProfileField`, `_ProfileHeader`, `_MetricGrid` |
| `lib/app_versions/v1/features/profile/presentation/profile_screen.dart` | 13 | `ProfileScreen` |
| `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart` | 100 | `QuickCarePage`, `_QuickCareAction` |
| `lib/app_versions/v1/features/settings/data/datasources/settings_local_datasource.dart` | 388 | `SettingsLocalDatasource` |
| `lib/app_versions/v1/features/settings/data/datasources/settings_remote_datasource.dart` | 53 | `SettingsRemoteDatasource` |
| `lib/app_versions/v1/features/settings/data/models/settings_preferences_model.dart` | 167 | `SettingsPreferencesModel` |
| `lib/app_versions/v1/features/settings/data/models/user_profile_model.dart` | 140 | `UserProfileModel` |
| `lib/app_versions/v1/features/settings/domain/entities/settings_preferences_entity.dart` | 142 | `SettingsPreferencesEntity` |
| `lib/app_versions/v1/features/settings/domain/entities/user_profile_entity.dart` | 135 | `UserProfileEntity` |
| `lib/app_versions/v1/features/settings/domain/repositories/settings_repository.dart` | 266 | `SettingsRepository` |
| `lib/app_versions/v1/features/settings/domain/validators/settings_validator.dart` | 103 | `SettingsValidator` |
| `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart` | 905 | `DevDatabaseViewerPage`, `_DevDatabaseViewerPageState`, `_DatabaseSnapshot`, `_DatabaseTableSnapshot`, `_DatabaseColumnSnapshot`, `_DatabaseSummaryCard` |
| `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | 1022 | `SettingsView`, `_ChangePasswordSheet`, `_ChangePasswordSheetState`, `_SaleSettingsEntry`, `_ReferralCodeSettingsEntry`, `_ReferralCodeSheet` |
| `lib/app_versions/v1/features/settings/providers/settings_provider.dart` | 107 | `SettingsPreferencesController` |
| `lib/app_versions/v1/features/settings/utils/profile_validator.dart` | 159 | `ProfileValidator` |
| `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` | 66 | `SleepTrackingPage` |
| `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart` | 19 | `SplashRouteTarget`, `SplashRouteDecision` |
| `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | 1452 | `_BootStage`, `_BootStagePresentation`, `SplashPage`, `_SplashPageState`, `_SplashLayout`, `_SplashAtmosphere` |
| `lib/app_versions/v1/features/splash/providers/splash_provider.dart` | 18 | `SplashNotifier` |
| `lib/app_versions/v1/features/splash/providers/splash_state.dart` | 2 | `SplashStatus` |
| `lib/app_versions/v1/features/splash/splash.dart` | 2 | — |
| `lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart` | 66 | `StressTrackingPage` |
| `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart` | 118 | `WaterTrackingPage`, `_WaterTrackingPageState` |
| `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart` | 93 | `WeeklySummaryPage`, `_SummaryItem` |
| `lib/app_versions/v1/router/router.dart` | 4 | — |
| `lib/app_versions/v1/router/transitions.dart` | 18 | `AppTransitions` |
| `lib/app_versions/v1/router/v1_navigation_service.dart` | 48 | `V1AppNavigator` |
| `lib/app_versions/v1/router/v1_route_guards.dart` | 65 | `V1RouteGuards` |
| `lib/app_versions/v1/router/v1_route_paths.dart` | 34 | `V1RoutePaths` |
| `lib/app_versions/v1/router/v1_router.dart` | 146 | — |
| `lib/app_versions/v1/services/ai/ai_chat_service.dart` | 659 | `AIChatService`, `AIChatModelCandidates`, `AIChatRetryPolicy`, `_AIChatModelEntry`, `_AIChatValidationResult` |
| `lib/app_versions/v1/services/ai/ai_exceptions.dart` | 34 | `AIOverloadedException` |
| `lib/app_versions/v1/services/ai/ai_json_parser.dart` | 30 | `AIJsonParser` |
| `lib/app_versions/v1/services/ai/ai_json_prompt_builder.dart` | 21 | `AIJsonPromptBuilder` |
| `lib/app_versions/v1/services/ai/ai_service.dart` | 1191 | `AIConnectionCheckResult`, `AIService`, `AIModelCandidates`, `AIRetryPolicy`, `_AIModelEntry`, `_AIChunk` |
| `lib/app_versions/v1/services/ai/ai_trace_logger.dart` | 200 | `AITraceLogger` |
| `lib/app_versions/v1/services/ai/ai_vietnamese_text_validator.dart` | 55 | `AIVietnameseTextValidator` |
| `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` | 316 | `GeneratedPlanActorModes`, `GeneratedPlanRequestStatuses`, `PersonalScheduleAiRequestRecord`, `PersonalScheduleAiRequestStore`, `LocalPersonalScheduleAiRequestStore` |
| `lib/app_versions/v1/services/ai/generated_plan_service.dart` | 373 | `DashboardGenerationAuthRequiredException`, `GuestInitialPlanAlreadyUsedException`, `GeneratedPlanResult`, `GeneratedPlanService` |
| `lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart` | 165 | `PersonalScheduleQuotaDecision`, `PersonalScheduleQuotaExceededException`, `PersonalScheduleQuotaUnavailableException`, `PersonalScheduleQuotaGateway`, `TrustedBackendPersonalScheduleQuotaGateway` |
| `lib/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart` | 82 | `ExerciseTasksPrompt` |
| `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` | 89 | `MealPlanPrompt` |
| `lib/app_versions/v1/services/notifications/notification_action_handler.dart` | 234 | `NotificationActionHandler` |
| `lib/app_versions/v1/services/notifications/notification_bootstrap.dart` | 128 | `NotificationBootstrap` |
| `lib/app_versions/v1/services/notifications/notification_constants.dart` | 23 | `NotificationActionIds`, `NotificationChannels`, `ReminderSourceTypes`, `NotificationTypes` |
| `lib/app_versions/v1/services/notifications/notification_id_generator.dart` | 12 | — |
| `lib/app_versions/v1/services/notifications/notification_lifecycle_refresher.dart` | 75 | `NotificationLifecycleRefresher` |
| `lib/app_versions/v1/services/notifications/notification_payload.dart` | 51 | `NotificationPayload` |
| `lib/app_versions/v1/services/notifications/notification_startup_scheduler.dart` | 34 | `NotificationStartupScheduler` |
| `lib/app_versions/v1/services/notifications/reminder_defaults.dart` | 66 | `ReminderDefaults` |
| `lib/app_versions/v1/services/notifications/reminder_notification_scheduler.dart` | 280 | `ReminderNotificationScheduler`, `LocalReminderNotificationScheduler` |
| `lib/app_versions/v1/services/notifications/reminder_schedule_service.dart` | 264 | `ReminderScheduleService`, `_ReminderCandidate` |
| `lib/app_versions/v1/shared/widgets/ai_chat_fab.dart` | 493 | `AIChatFAB`, `_AIChatFABState`, `DraggableAIChatButton`, `_DraggableAIChatButtonState`, `_NamiChatBubble`, `_NamiStatusDot` |
| `lib/app_versions/v2/app/bio_ai_v2_app.dart` | 18 | `BioAIV2App` |
| `lib/app_versions/v2/features/auth/auth.dart` | 12 | — |
| `lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart` | 123 | `SupabaseAuthRemoteDatasource` |
| `lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart` | 277 | `SupabaseAuthRepository` |
| `lib/app_versions/v2/features/auth/domain/entities/auth_commands.dart` | 37 | `RegisterCommand`, `LoginCommand`, `UpdatePasswordCommand`, `RegistrationResult` |
| `lib/app_versions/v2/features/auth/domain/entities/auth_failure.dart` | 23 | `AuthFailureCode`, `AuthFailure` |
| `lib/app_versions/v2/features/auth/domain/entities/auth_profile.dart` | 39 | `AuthSessionSnapshot`, `AuthProfile` |
| `lib/app_versions/v2/features/auth/domain/entities/auth_route_state.dart` | 77 | `AuthRouteStatus`, `AuthRouteState` |
| `lib/app_versions/v2/features/auth/domain/repositories/auth_repository.dart` | 25 | `AuthRepository` |
| `lib/app_versions/v2/features/auth/domain/services/auth_route_state_resolver.dart` | 55 | `AuthRouteStateResolver` |
| `lib/app_versions/v2/features/auth/domain/services/auth_validators.dart` | 44 | `AuthValidators` |
| `lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart` | 136 | `AuthController` |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` | 149 | `AuthGatePage`, `_AuthLoading`, `_AuthSupportState` |
| `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | 717 | `V2LoginPage`, `_V2LoginPageState`, `V2RegisterPage`, `_V2RegisterPageState`, `V2VerifyEmailPage`, `_V2VerifyEmailPageState` |
| `lib/app_versions/v2/features/auth/providers/auth_dependencies.dart` | 29 | — |
| `lib/app_versions/v2/features/auth/providers/auth_providers.dart` | 11 | — |
| `lib/app_versions/v2/features/cloud_sync/cloud_sync.dart` | 4 | — |
| `lib/app_versions/v2/features/cloud_sync/data/datasources/sqlite_user_data_sync_local_datasource.dart` | 198 | `SqliteUserDataSyncLocalDatasource` |
| `lib/app_versions/v2/features/cloud_sync/data/datasources/supabase_user_data_sync_remote_datasource.dart` | 247 | `SupabaseUserDataSyncRemoteDatasource` |
| `lib/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_datasource_contracts.dart` | 25 | — |
| `lib/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_tables.dart` | 436 | `UserDataSyncTables` |
| `lib/app_versions/v2/features/cloud_sync/data/repositories/authenticated_user_data_sync_repository_impl.dart` | 135 | `AuthenticatedUserDataSyncRepositoryImpl` |
| `lib/app_versions/v2/features/cloud_sync/domain/entities/cloud_sync_result.dart` | 35 | `AuthSyncReason`, `CloudSyncResult` |
| `lib/app_versions/v2/features/cloud_sync/domain/entities/user_data_snapshot.dart` | 16 | `UserDataSnapshot` |
| `lib/app_versions/v2/features/cloud_sync/domain/repositories/authenticated_user_data_sync_repository.dart` | 6 | — |
| `lib/app_versions/v2/features/cloud_sync/providers/cloud_sync_providers.dart` | 25 | — |
| `lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn01.dart` | 34 | `HealthScoreHabitsFn01` |
| `lib/app_versions/v2/features/health_scoring/application/health_score_habits_fn02.dart` | 34 | `HealthScoreHabitsFn02` |
| `lib/app_versions/v2/features/health_scoring/data/datasources/sqlite_health_score_habits_local_datasource.dart` | 224 | `SqliteHealthScoreHabitsLocalDatasource` |
| `lib/app_versions/v2/features/health_scoring/data/repositories/local_health_score_habits_repository.dart` | 19 | `LocalHealthScoreHabitsRepository` |
| `lib/app_versions/v2/features/health_scoring/domain/entities/health_score_habits_models.dart` | 216 | `HealthScorePeriod`, `HealthScoreDateKey`, `CalculateHealthScoreCommand`, `LoadHabitProgressCommand`, `HealthScoreCompletionGroup`, `HealthScoreCompletionEntry` |
| `lib/app_versions/v2/features/health_scoring/domain/repositories/health_score_habits_repository.dart` | 10 | `HealthScoreHabitsRepository` |
| `lib/app_versions/v2/features/health_scoring/domain/services/health_score_habits_calculator.dart` | 247 | `HealthScoreHabitsCalculator` |
| `lib/app_versions/v2/features/health_scoring/health_scoring.dart` | 29 | `V2HealthScoringFeature` |
| `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | 346 | `HealthScoreHabitsPage`, `_HealthScoreLoading`, `_HealthScoreReady`, `_ScoreHeader`, `_SectionCard`, `_BreakdownRow` |
| `lib/app_versions/v2/features/health_scoring/providers/health_score_habits_providers.dart` | 115 | `HealthScoreHabitsViewStatus`, `HealthScoreHabitsViewModel` |
| `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` | 62 | `V2HomePage` |
| `lib/app_versions/v2/features/personal_schedule_quota/personal_schedule_quota.dart` | 17 | `V2PersonalScheduleQuotaFeature` |
| `lib/app_versions/v2/features/usage_quota/usage_quota.dart` | 17 | `V2UsageQuotaFeature` |
| `lib/app_versions/v2/router/v2_route_paths.dart` | 15 | `V2RoutePaths` |
| `lib/app_versions/v2/router/v2_router.dart` | 70 | — |
| `lib/app_versions/v3/app/bio_ai_v3_app.dart` | 18 | `BioAIV3App` |
| `lib/app_versions/v3/features/advanced_health_tracking/advanced_health_tracking.dart` | 17 | `V3AdvancedHealthTrackingFeature` |
| `lib/app_versions/v3/features/family_members/family_members.dart` | 17 | `V3FamilyMembersFeature` |
| `lib/app_versions/v3/features/family_onboarding/family_onboarding.dart` | 17 | `V3FamilyOnboardingFeature` |
| `lib/app_versions/v3/features/family_schedule/family_schedule.dart` | 17 | `V3FamilyScheduleFeature` |
| `lib/app_versions/v3/features/goal_roadmap/goal_roadmap.dart` | 17 | `V3GoalRoadmapFeature` |
| `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart` | 81 | `V3HomePage` |
| `lib/app_versions/v3/features/premium_ai/premium_ai.dart` | 17 | `V3PremiumAiFeature` |
| `lib/app_versions/v3/router/v3_route_paths.dart` | 4 | `V3RoutePaths` |
| `lib/app_versions/v3/router/v3_router.dart` | 18 | — |
| `lib/core/constants/api/supabase_constants.dart` | 6 | `SupabaseConstants` |
| `lib/core/constants/app/app_assets.dart` | 5 | `AppAssets` |
| `lib/core/constants/app/app_constants.dart` | 5 | `AppConstants` |
| `lib/core/constants/app/app_duration.dart` | 5 | `AppDuration` |
| `lib/core/constants/app/app_radius.dart` | 6 | `AppRadius` |
| `lib/core/constants/app/app_spacing.dart` | 8 | `AppSpacing` |
| `lib/core/constants/app/app_strings.dart` | 6 | `AppStrings` |
| `lib/core/constants/constant.dart` | 2 | — |
| `lib/core/constants/enums/gender_enum.dart` | 2 | `GenderEnum` |
| `lib/core/constants/health/bmi_constants.dart` | 6 | `BMIConstants` |
| `lib/core/constants/health/nutrition_constants.dart` | 5 | `NutritionConstants` |
| `lib/core/constants/network/endpoint_constants.dart` | 5 | `EndpointConstants` |
| `lib/core/constants/onboarding_constants.dart` | 498 | `OnboardingChoiceOption` |
| `lib/core/constants/routes/auth_route_paths.dart` | 10 | `AuthRoutePaths` |
| `lib/core/constants/storage/storage_keys.dart` | 6 | `StorageKeys` |
| `lib/core/constants/validation/regex_constants.dart` | 5 | `RegexConstants` |
| `lib/core/core.dart` | 2 | — |
| `lib/core/interfaces/health_data_interface.dart` | 25 | `HealthDataInterface` |
| `lib/core/membership/membership_display_info.dart` | 79 | `MembershipDisplayInfo` |
| `lib/core/network/dio_provider.dart` | 18 | — |
| `lib/core/storage/localdb/app_prefs.dart` | 59 | `AppPrefs` |
| `lib/core/storage/localdb/daos/ai_catalog_dao.dart` | 94 | `AiCatalogDao` |
| `lib/core/storage/localdb/daos/ai_insights_dao.dart` | 89 | `AiInsightsDao` |
| `lib/core/storage/localdb/daos/ai_recommendations_dao.dart` | 89 | `AiRecommendationsDao` |
| `lib/core/storage/localdb/daos/food_allergies_dao.dart` | 89 | `FoodAllergiesDao` |
| `lib/core/storage/localdb/daos/health_conditions_dao.dart` | 89 | `HealthConditionsDao` |
| `lib/core/storage/localdb/daos/health_goals_dao.dart` | 99 | `HealthGoalsDao` |
| `lib/core/storage/localdb/daos/health_profiles_dao.dart` | 89 | `HealthProfilesDao` |
| `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart` | 137 | `HealthTrackingLogsDao` |
| `lib/core/storage/localdb/daos/lifestyle_habits_dao.dart` | 89 | `LifestyleHabitsDao` |
| `lib/core/storage/localdb/daos/medical_treatments_dao.dart` | 89 | `MedicalTreatmentsDao` |
| `lib/core/storage/localdb/daos/notifications_dao.dart` | 197 | `NotificationsDao` |
| `lib/core/storage/localdb/daos/nutrition_logs_dao.dart` | 116 | `NutritionLogsDao` |
| `lib/core/storage/localdb/daos/survey_answers_dao.dart` | 104 | `SurveyAnswersDao` |
| `lib/core/storage/localdb/daos/users_dao.dart` | 91 | `UsersDao` |
| `lib/core/storage/localdb/database_constants.dart` | 9 | `DatabaseConstants` |
| `lib/core/storage/localdb/database_service.dart` | 154 | `DatabaseService` |
| `lib/core/storage/localdb/database_version.dart` | 4 | `DatabaseVersion` |
| `lib/core/storage/localdb/datasources/ai_catalog_local_datasource.dart` | 19 | `AiCatalogLocalDatasource` |
| `lib/core/storage/localdb/migrations/migration_manager.dart` | 302 | `MigrationManager` |
| `lib/core/storage/localdb/migrations/migration_v1.dart` | 4 | — |
| `lib/core/storage/localdb/models/ai_catalog_models.dart` | 259 | `AiCatalogBundle`, `MealCatalogItemModel`, `ExerciseCatalogItemModel`, `ScheduleTaskCatalogItemModel` |
| `lib/core/storage/localdb/models/ai_insight_model.dart` | 75 | `AIInsightModel` |
| `lib/core/storage/localdb/models/ai_recommendation_model.dart` | 89 | `AIRecommendationModel` |
| `lib/core/storage/localdb/models/food_allergy_model.dart` | 63 | `FoodAllergyModel` |
| `lib/core/storage/localdb/models/health_condition_model.dart` | 76 | `HealthConditionModel` |
| `lib/core/storage/localdb/models/health_goal_model.dart` | 77 | `HealthGoalModel` |
| `lib/core/storage/localdb/models/health_profile_model.dart` | 100 | `HealthProfileModel` |
| `lib/core/storage/localdb/models/health_tracking_log_model.dart` | 134 | `HealthTrackingLogModel` |
| `lib/core/storage/localdb/models/lifestyle_habit_model.dart` | 131 | `LifestyleHabitModel` |
| `lib/core/storage/localdb/models/medical_treatment_model.dart` | 69 | `MedicalTreatmentModel` |
| `lib/core/storage/localdb/models/notification_model.dart` | 137 | `NotificationModel`, `NotificationActionStatuses` |
| `lib/core/storage/localdb/models/nutrition_log_model.dart` | 101 | `NutritionLogModel` |
| `lib/core/storage/localdb/models/survey_answer_model.dart` | 63 | `SurveyAnswerModel` |
| `lib/core/storage/localdb/models/user_model.dart` | 100 | `UserModel` |
| `lib/core/storage/localdb/seeders/ai_catalog_seed_data.dart` | 922 | `AiCatalogSeedData` |
| `lib/core/storage/localdb/seeders/ai_catalog_seeder.dart` | 16 | `AiCatalogSeeder` |
| `lib/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart` | 23 | `LocalUserDataSyncDispatcher` |
| `lib/core/storage/localdb/sync/sync_outbox_schema.dart` | 225 | `SyncOutboxSchema` |
| `lib/core/storage/localdb/sync/sync_runtime_state.dart` | 26 | `SyncRuntimeState` |
| `lib/core/storage/localdb/tables/ai_insights_table.dart` | 21 | `AIInsightsTable` |
| `lib/core/storage/localdb/tables/ai_recommendations_table.dart` | 23 | `AIRecommendationsTable` |
| `lib/core/storage/localdb/tables/daily_health_tasks_table.dart` | 29 | `DailyHealthTasksTable` |
| `lib/core/storage/localdb/tables/exercise_catalog_table.dart` | 27 | `ExerciseCatalogTable` |
| `lib/core/storage/localdb/tables/food_allergies_table.dart` | 17 | `FoodAllergiesTable` |
| `lib/core/storage/localdb/tables/health_conditions_table.dart` | 18 | `HealthConditionsTable` |
| `lib/core/storage/localdb/tables/health_goals_table.dart` | 18 | `HealthGoalsTable` |
| `lib/core/storage/localdb/tables/health_profiles_table.dart` | 22 | `HealthProfilesTable` |
| `lib/core/storage/localdb/tables/health_tracking_logs_table.dart` | 30 | `HealthTrackingLogsTable` |
| `lib/core/storage/localdb/tables/lifestyle_habits_table.dart` | 30 | `LifestyleHabitsTable` |
| `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart` | 41 | `LifestyleScheduleItemsTable` |
| `lib/core/storage/localdb/tables/meal_catalog_table.dart` | 28 | `MealCatalogTable` |
| `lib/core/storage/localdb/tables/meal_plans_table.dart` | 50 | `MealPlansTable` |
| `lib/core/storage/localdb/tables/medical_treatments_table.dart` | 18 | `MedicalTreatmentsTable` |
| `lib/core/storage/localdb/tables/notifications_table.dart` | 31 | `NotificationsTable` |
| `lib/core/storage/localdb/tables/nutrition_logs_table.dart` | 24 | `NutritionLogsTable` |
| `lib/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart` | 31 | `PersonalScheduleAiRequestsTable` |
| `lib/core/storage/localdb/tables/schedule_task_catalog_table.dart` | 27 | `ScheduleTaskCatalogTable` |
| `lib/core/storage/localdb/tables/survey_answers_table.dart` | 19 | `SurveyAnswersTable` |
| `lib/core/storage/localdb/tables/users_table.dart` | 24 | `UsersTable` |
| `lib/core/theme/app_animations.dart` | 286 | `AppAnimations` |
| `lib/core/theme/app_colors.dart` | 202 | `AppColors` |
| `lib/core/theme/app_decoration.dart` | 310 | `AppDecoration` |
| `lib/core/theme/app_duration.dart` | 120 | `AppDuration` |
| `lib/core/theme/app_gradients.dart` | 254 | `AppGradients` |
| `lib/core/theme/app_icons.dart` | 286 | `AppIcons` |
| `lib/core/theme/app_radius.dart` | 63 | `AppRadius` |
| `lib/core/theme/app_shadows.dart` | 264 | `AppShadows` |
| `lib/core/theme/app_spacing.dart` | 135 | `AppSpacing` |
| `lib/core/theme/app_text_styles.dart` | 299 | `AppTextStyles` |
| `lib/core/theme/app_theme.dart` | 315 | `AppTheme` |
| `lib/core/theme/app_typography.dart` | 256 | `AppTypography` |
| `lib/core/theme/design_system.dart` | 130 | — |
| `lib/core/theme/design_system_demo_page.dart` | 667 | `DesignSystemDemoPage`, `_DesignSystemDemoPageState` |
| `lib/core/theme/foundation/colors.dart` | 174 | `ColorFoundation`, `GradientFoundation` |
| `lib/core/theme/foundation/motion.dart` | 91 | `MotionFoundation` |
| `lib/core/theme/foundation/radius.dart` | 43 | `RadiusFoundation` |
| `lib/core/theme/foundation/shadows.dart` | 121 | `ShadowFoundation` |
| `lib/core/theme/foundation/spacing.dart` | 83 | `SpacingFoundation` |
| `lib/core/theme/foundation/typography.dart` | 64 | `TypographyFoundation` |
| `lib/core/theme/primitives/badge.dart` | 270 | `BadgeVariant`, `BadgeStatus`, `AppBadge` |
| `lib/core/theme/primitives/button.dart` | 350 | `ButtonVariant`, `AppButton` |
| `lib/core/theme/primitives/card.dart` | 204 | `CardVariant`, `AppCard` |
| `lib/core/theme/primitives/chip.dart` | 214 | `ChipVariant`, `AppChip` |
| `lib/core/theme/primitives/input.dart` | 272 | `InputVariant`, `AppInput` |
| `lib/core/theme/primitives/section_header.dart` | 145 | `SectionHeader` |
| `lib/core/theme/primitives/states/empty_state.dart` | 136 | `EmptyState` |
| `lib/core/theme/primitives/states/error_state.dart` | 128 | `ErrorState` |
| `lib/core/theme/primitives/states/loading_state.dart` | 157 | `LoadingVariant`, `LoadingState` |
| `lib/core/theme/theme.dart` | 13 | — |
| `lib/core/theme/tokens/color_tokens.dart` | 162 | `AppColorTokens` |
| `lib/core/theme/tokens/component_tokens.dart` | 327 | `AppRadiusTokens`, `AppShadowTokens`, `AppMotionTokens`, `AppTextStyles` |
| `lib/core/theme/tokens/spacing_tokens.dart` | 183 | `AppSpacingTokens` |
| `lib/core/utils/logger/app_logger.dart` | 141 | `AppLogger` |
| `lib/core/utils/password_validator.dart` | 94 | `PasswordValidator` |
| `lib/features/nabi/application/nabi_controller.dart` | 68 | `NabiController` |
| `lib/features/nabi/application/nabi_expression_resolver.dart` | 227 | `NabiExpressionResolver`, `NabiResolvedPresentation` |
| `lib/features/nabi/application/nabi_state.dart` | 47 | `NabiState` |
| `lib/features/nabi/domain/entities/nabi_expression.dart` | 62 | `NabiEmotion`, `NabiContext`, `NabiEvent` |
| `lib/features/nabi/nabi.dart` | 10 | — |
| `lib/features/nabi/presentation/navigation/nabi_route_mapper.dart` | 44 | `NabiRouteMapper` |
| `lib/features/nabi/presentation/navigation/nabi_route_observer.dart` | 48 | `NabiRouteObserver` |
| `lib/features/nabi/presentation/widgets/nabi_app_shell.dart` | 30 | `NabiAppShell` |
| `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart` | 307 | `NabiOverlayConfig`, `NabiAssistantOverlay`, `_NabiAssistantOverlayState`, `_NabiFloatingControl`, `_NabiSpeechBubble` |
| `lib/features/nabi/presentation/widgets/nabi_character.dart` | 594 | `NabiCharacter`, `_NabiCharacterState`, `_NabiCharacterPainter` |
| `lib/main.dart` | 60 | — |
| `lib/main_admin.dart` | 20 | — |
| `lib/main_v2.dart` | 60 | — |
| `lib/sale_referral/data/datasources/sale_remote_datasource.dart` | 34 | `SaleRemoteDatasource` |
| `lib/sale_referral/data/datasources/supabase_sale_remote_datasource.dart` | 114 | `SupabaseSaleRemoteDatasource` |
| `lib/sale_referral/data/device/sale_device_hash_store.dart` | 32 | `SaleDeviceHashStore` |
| `lib/sale_referral/data/repositories/sale_repository_impl.dart` | 116 | `SaleRepositoryImpl` |
| `lib/sale_referral/domain/entities/sale_models.dart` | 367 | `SaleStatus`, `SaleState`, `SalePayoutProfile`, `SalePayoutProfileCommand`, `SaleDashboard`, `SaleDirectCustomer` |
| `lib/sale_referral/domain/repositories/sale_repository.dart` | 34 | `SaleRepository` |
| `lib/sale_referral/domain/services/sale_commission_calculator.dart` | 39 | `SaleCommissionCalculator`, `SaleCommissionEstimate` |
| `lib/sale_referral/domain/services/sale_conversion_policy_service.dart` | 22 | `SaleConversionPolicyService` |
| `lib/sale_referral/domain/services/sale_referral_code_validator.dart` | 19 | `SaleReferralCodeValidator` |
| `lib/sale_referral/features/commission/commission.dart` | 17 | `SaleCommissionFeature` |
| `lib/sale_referral/features/payment_events/payment_events.dart` | 17 | `SalePaymentEventsFeature` |
| `lib/sale_referral/features/referral_code/referral_code.dart` | 17 | `ReferralCodeFeature` |
| `lib/sale_referral/features/sale_dashboard/sale_dashboard.dart` | 17 | `SaleDashboardFeature` |
| `lib/sale_referral/presentation/pages/sale_participation_page.dart` | 304 | `SaleParticipationPage`, `_SaleParticipationPageState`, `_BuildTermsBody`, `_StatusNotice` |
| `lib/sale_referral/presentation/pages/sale_shell_page.dart` | 1066 | `SaleShellPage`, `_SaleShellPageState`, `_SalePayoutProfileGate`, `_SalePayoutProfileGateState`, `_OverviewTab`, `_DirectCustomersTab` |
| `lib/sale_referral/providers/sale_providers.dart` | 78 | — |
| `lib/services/biometric/biometric.dart` | 3 | — |
| `lib/services/biometric/biometric_service.dart` | 143 | `BiometricException`, `BiometricService` |
| `lib/services/image_picker/image_picker.dart` | 9 | — |
| `lib/services/image_picker/image_picker_provider.dart` | 9 | — |
| `lib/services/image_picker/image_picker_service.dart` | 156 | `ImagePickerService` |
| `lib/services/supabase/auth/account_security_provider.dart` | 43 | `AccountSecurityController` |
| `lib/services/supabase/auth/account_security_service.dart` | 61 | `AccountSecurityService` |
| `lib/services/supabase/auth/auth_profile_service.dart` | 30 | `AuthProfileService` |
| `lib/services/supabase/auth/current_auth_user.dart` | 10 | — |
| `lib/services/supabase/auth_service.dart` | 38 | `AuthService` |
| `lib/services/supabase/cloud_sync/user_data_sync_outbox.dart` | 494 | `SyncOutboxMutation`, `UserDataSyncOutbox` |
| `lib/services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart` | 99 | `UserDataSyncOutboxRefresher` |
| `lib/services/supabase/sale/sale_participation_service.dart` | 74 | `SaleParticipationService` |
| `lib/services/supabase/sale/sale_terms.dart` | 67 | `SaleTerms`, `SaleTermsSection` |
| `lib/services/supabase/supabase_service.dart` | 6 | `SupabaseService` |
| `lib/shared/widgets/loading_gen_ai.dart` | 519 | `AIGeneratingPage`, `_AIGeneratingPageState`, `_ThoughtEntry` |


## Appendix C — test source index

Use the narrowest test that owns the page/contract. Architecture tests are especially important when moving code across app surfaces.

| Test | LOC | First declarations |
|---|---:|---|

| `test/app_versions/admin/admin_controller_test.dart` | 193 | `_FakeAdminRepository` |
| `test/app_versions/admin/admin_models_test.dart` | 298 | — |
| `test/app_versions/v1/features/dashboard/dashboard_generated_plan_contract_test.dart` | 17 | — |
| `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` | 248 | `_FakeOnboardingRepository` |
| `test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart` | 50 | — |
| `test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart` | 270 | — |
| `test/app_versions/v1/features/splash/splash_route_decision_test.dart` | 34 | — |
| `test/app_versions/v1/router/v1_route_guards_test.dart` | 50 | — |
| `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` | 797 | `_RecordingDashboardRepository`, `_RecordingDailyHealthDatasource`, `_RecordingRequestStore`, `_RecordingQuotaGateway`, `_RecordingScheduleDatasource` |
| `test/app_versions/v2/features/auth/account_security_contract_test.dart` | 49 | — |
| `test/app_versions/v2/features/auth/auth_flow_contract_test.dart` | 103 | — |
| `test/app_versions/v2/features/auth/auth_pages_smoke_test.dart` | 27 | — |
| `test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart` | 106 | — |
| `test/app_versions/v2/features/auth/auth_validators_test.dart` | 28 | — |
| `test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart` | 244 | `_FakeRemoteDatasource`, `_FakeLocalDatasource` |
| `test/app_versions/v2/features/cloud_sync/cloud_sync_contract_test.dart` | 44 | — |
| `test/app_versions/v2/features/health_scoring/data/sqlite_health_score_habits_local_datasource_test.dart` | 237 | — |
| `test/app_versions/v2/features/health_scoring/domain/health_score_habits_calculator_test.dart` | 169 | — |
| `test/app_versions/v2/features/health_scoring/presentation/health_score_habits_page_test.dart` | 96 | `_FakeHealthScoreHabitsRepository` |
| `test/app_versions/v2/features/health_scoring/providers/health_score_habits_providers_test.dart` | 83 | `_FakeHealthScoreHabitsRepository` |
| `test/architecture_preservation_property_test.dart` | 726 | — |
| `test/architecture_version_boundary_test.dart` | 219 | — |
| `test/architecture_violation_exploration_test.dart` | 372 | — |
| `test/core/storage/localdb/ai_catalog_seed_data_test.dart` | 76 | — |
| `test/core/storage/localdb/migration_manager_test.dart` | 411 | — |
| `test/core/storage/localdb/notification_model_test.dart` | 89 | — |
| `test/core/storage/localdb/notifications_dao_test.dart` | 168 | — |
| `test/core/storage/localdb/sync/local_user_data_sync_dispatcher_test.dart` | 22 | — |
| `test/core/storage/localdb/user_model_test.dart` | 20 | — |
| `test/core/theme/foundation/gradient_test.dart` | 153 | — |
| `test/core/theme/foundation/motion_test.dart` | 55 | — |
| `test/core/theme/primitives/button_test.dart` | 337 | — |
| `test/docs/supabase_admin_contract_test.dart` | 297 | — |
| `test/docs/supabase_config_contract_test.dart` | 223 | — |
| `test/docs/supabase_dev_seed_membership_test.dart` | 24 | — |
| `test/features/daily_health_tracking/data/daily_health_ai_task_normalizer_test.dart` | 86 | — |
| `test/features/daily_health_tracking/data/daily_health_dao_test.dart` | 135 | — |
| `test/features/daily_health_tracking/data/daily_health_task_model_test.dart` | 62 | — |
| `test/features/daily_health_tracking/data/daily_health_tracking_local_datasource_write_test.dart` | 129 | — |
| `test/features/daily_health_tracking/domain/daily_health_task_generator_test.dart` | 89 | — |
| `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart` | 387 | — |
| `test/features/dashboard/data/dashboard_local_datasource_test.dart` | 63 | — |
| `test/features/dashboard/domain/dashboard_companion_service_test.dart` | 144 | — |
| `test/features/features_hub/features_hub_page_test.dart` | 14 | — |
| `test/features/lifestyle_schedule/data/exercise_tasks_ai_normalizer_test.dart` | 137 | — |
| `test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart` | 314 | — |
| `test/features/lifestyle_schedule/data/lifestyle_schedule_dao_test.dart` | 122 | — |
| `test/features/lifestyle_schedule/data/lifestyle_schedule_item_model_test.dart` | 39 | — |
| `test/features/lifestyle_schedule/data/lifestyle_schedule_timeline_builder_test.dart` | 153 | — |
| `test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart` | 129 | — |
| `test/features/meal_plan/data/meal_plan_completion_test.dart` | 59 | — |
| `test/features/meal_plan/data/meal_plan_model_test.dart` | 72 | — |
| `test/features/nabi/application/nabi_controller_test.dart` | 49 | — |
| `test/features/nabi/application/nabi_expression_resolver_test.dart` | 19 | — |
| `test/features/settings/data/datasources/settings_local_datasource_test.dart` | 369 | — |
| `test/features/settings/domain/validators/profile_validator_test.dart` | 49 | — |
| `test/features/settings/domain/validators/settings_validator_test.dart` | 231 | — |
| `test/features/settings/profile_update_contract_test.dart` | 44 | — |
| `test/features/settings/user_scoped_cache_contract_test.dart` | 23 | — |
| `test/sale_referral/data/sale_repository_impl_test.dart` | 202 | `_FakeSaleRemoteDatasource` |
| `test/sale_referral/domain/sale_models_test.dart` | 59 | — |
| `test/sale_referral/domain/services/sale_commission_calculator_test.dart` | 26 | — |
| `test/sale_referral/presentation/sale_shell_page_test.dart` | 327 | `_FakeSaleRepository` |
| `test/services/ai/ai_service_test.dart` | 948 | `_FakeHealthData` |
| `test/services/biometric/biometric_service_test.dart` | 60 | — |
| `test/services/image_picker_service_test.dart` | 76 | — |
| `test/services/notifications/android_notification_manifest_test.dart` | 55 | — |
| `test/services/notifications/notification_action_handler_test.dart` | 290 | — |
| `test/services/notifications/notification_lifecycle_refresher_test.dart` | 80 | — |
| `test/services/notifications/notification_startup_scheduler_test.dart` | 44 | — |
| `test/services/notifications/reminder_schedule_service_test.dart` | 301 | `FakeReminderNotificationScheduler`, `ScheduledReminder` |
| `test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart` | 113 | — |
| `test/widget_test.dart` | 242 | — |


## Appendix D — DD documented view inventory

DD modules document future/current required views. A documented view is not proof that an equivalent Flutter page has already been wired; inspect implementation and checklist progress before claiming it exists.

| DD module | View ID / title | Source |
|---|---|---|

| `admin_dashboard` | ADMIN_DASHBOARD-V01 — Admin dashboard | `docs/DD/admin_dashboard/Views.md` |
| `admin_dashboard` | ADMIN_DASHBOARD-V02 — Admin dashboard drilldown | `docs/DD/admin_dashboard/Views.md` |
| `admin_operations` | ADMIN_OPS-V01 — Admin management views | `docs/DD/admin_operations/Views.md` |
| `admin_operations` | ADMIN_OPS-V02 — Finance admin queue | `docs/DD/admin_operations/Views.md` |
| `advanced_tracking_goals` | ADVANCED_TRACKING_GOALS-V01 — Advanced goal setup | `docs/DD/advanced_tracking_goals/Views.md` |
| `advanced_tracking_goals` | ADVANCED_TRACKING_GOALS-V02 — Goal roadmap | `docs/DD/advanced_tracking_goals/Views.md` |
| `ai_chat` | AI_CHAT-V01 — AI Chat screen | `docs/DD/ai_chat/Views.md` |
| `ai_chat` | AI_CHAT-V02 — AI Chat composer | `docs/DD/ai_chat/Views.md` |
| `audit_security` | AUDIT_SECURITY-V01 — Audit log view | `docs/DD/audit_security/Views.md` |
| `audit_security` | AUDIT_SECURITY-V02 — Security and support console | `docs/DD/audit_security/Views.md` |
| `auth_profile_sync` | AUTH_PROFILE_SYNC-V01 — Auth entry | `docs/DD/auth_profile_sync/Views.md` |
| `auth_profile_sync` | AUTH_PROFILE_SYNC-V02 — Sync confirmation | `docs/DD/auth_profile_sync/Views.md` |
| `basic_health_calculators` | BASIC_HEALTH_CALC-V01 — Basic calculator | `docs/DD/basic_health_calculators/Views.md` |
| `basic_health_calculators` | BASIC_HEALTH_CALC-V02 — Formula config view | `docs/DD/basic_health_calculators/Views.md` |
| `dashboard_schedule` | DASHBOARD_SCHEDULE-V01 — Schedule dashboard | `docs/DD/dashboard_schedule/Views.md` |
| `dashboard_schedule` | DASHBOARD_SCHEDULE-V02 — Plan item action | `docs/DD/dashboard_schedule/Views.md` |
| `familyplus` | FAMILYPLUS-V01 — Family management | `docs/DD/familyplus/Views.md` |
| `familyplus` | FAMILYPLUS-V02 — Family member context | `docs/DD/familyplus/Views.md` |
| `health_score_habits` | HEALTH_SCORE_HABITS-V01 — Health score summary | `docs/DD/health_score_habits/Views.md` |
| `health_score_habits` | HEALTH_SCORE_HABITS-V02 — Habit progress view | `docs/DD/health_score_habits/Views.md` |
| `membership_quota` | MEMBERSHIP_QUOTA-V01 — Access state provider | `docs/DD/membership_quota/Views.md` |
| `membership_quota` | MEMBERSHIP_QUOTA-V02 — Quota gate messaging | `docs/DD/membership_quota/Views.md` |
| `onboarding_profile` | ONBOARDING_PROFILE-V01 — Onboarding flow | `docs/DD/onboarding_profile/Views.md` |
| `onboarding_profile` | ONBOARDING_PROFILE-V02 — Onboarding review | `docs/DD/onboarding_profile/Views.md` |
| `payment_membership` | PAYMENT_MEMBERSHIP-V01 — Payment checkout | `docs/DD/payment_membership/Views.md` |
| `payment_membership` | PAYMENT_MEMBERSHIP-V02 — Payment approval queue | `docs/DD/payment_membership/Views.md` |
| `personal_schedule_ai` | PERSONAL_SCHEDULE_AI-V01 — Initial schedule generation | `docs/DD/personal_schedule_ai/Views.md` |
| `personal_schedule_ai` | PERSONAL_SCHEDULE_AI-V02 — Regenerate schedule | `docs/DD/personal_schedule_ai/Views.md` |
| `reconciliation` | RECONCILIATION-V01 — Reconciliation run view | `docs/DD/reconciliation/Views.md` |
| `reconciliation` | RECONCILIATION-V02 — Discrepancy detail | `docs/DD/reconciliation/Views.md` |
| `referral_direct` | REFERRAL_DIRECT-V01 — Sale registration | `docs/DD/referral_direct/Views.md` |
| `referral_direct` | REFERRAL_DIRECT-V02 — Referral code entry | `docs/DD/referral_direct/Views.md` |
| `reporting` | REPORTING-V01 — Report builder | `docs/DD/reporting/Views.md` |
| `reporting` | REPORTING-V02 — Report export dialog | `docs/DD/reporting/Views.md` |
| `sale_points` | SALE_POINTS-V01 — Sale point history | `docs/DD/sale_points/Views.md` |
| `sale_points` | SALE_POINTS-V02 — Sale wallet and conversion queue | `docs/DD/sale_points/Views.md` |
| `schedule_notifications` | SCHEDULE_NOTIFICATIONS-V01 — Notification settings | `docs/DD/schedule_notifications/Views.md` |
| `schedule_notifications` | SCHEDULE_NOTIFICATIONS-V02 — Notification action result | `docs/DD/schedule_notifications/Views.md` |


## Appendix E — Agent context files indexed

These are the repository context files that govern workflows. Read only the selected files in the mandated order during normal work; this appendix makes them discoverable.

| Context file | Headings / purpose |
|---|---|

| `.agents/skills/create-dd-from-bd/SKILL.md` | Create DD From BD Bridge |
| `.agents/skills/create-dd-from-bd/agents/openai.yaml` | Bridge/configuration |
| `.agents/skills/nanobio-project-agent/SKILL.md` | NanoBio Project Agent Bridge |
| `.agents/skills/nanobio-project-agent/agents/openai.yaml` | Bridge/configuration |
| `.codex/AGENTS.md` | AGENTS - NanoBio / BioAI · Snapshot · Required Read Pack · Workflow Router · Task Skill Router · Domain Router |
| `.codex/CHECKLIST.md` | CODEX CHECKLIST · Before Work · During Work · After Work |
| `.codex/DOCS_WORKFLOW.md` | DOCS_WORKFLOW - Worklog And Project Docs · Required Docs · Numbering · Worklog Location · Worklog Template · Worklog - <ten phien> |
| `.codex/ISSUE_TODO_WORKFLOW.md` | ISSUE_TODO_WORKFLOW - Issue And Todo Modes · Modes · Issue Docs · Todo Docs · Fix Issue Flow |
| `.codex/MAP_TREE.md` | MAP_TREE - NanoBio / BioAI · Default Context Roots · .codex Layout · Canonical Workflows · Domain Contexts · Generated Memory |
| `.codex/PROJECT_MAP.md` | PROJECT_MAP - NanoBio / BioAI · Source Roots · Workflow Routing · Domain Routing · Critical Files · Search Commands |
| `.codex/README.md` | .codex - NanoBio / BioAI · Cach Doc Mac Dinh · Cau Truc · Snapshot · History Learning |
| `.codex/domains/README.md` | Domain Registry |
| `.codex/domains/access-membership-referral.md` | Domain - Access / Membership / Referral Sale · Source · Access Map · Rules · Search |
| `.codex/domains/ai-service.md` | Domain - AI Service / Meal / Exercise / Chat · Source · Rules · Search |
| `.codex/domains/dashboard.md` | Domain - Dashboard / Health Score · Source · Rules · Search |
| `.codex/domains/health-tracking.md` | Domain - Daily Health Tracking · Source · Rules · Search |
| `.codex/domains/lifestyle-schedule.md` | Domain - Lifestyle Schedule / Timeline · Source · Rules · Search |
| `.codex/domains/notification.md` | Domain - Notification / Reminder · Source · Rules · Search |
| `.codex/domains/onboarding.md` | Domain - Onboarding · Source · Rules · Search |
| `.codex/domains/sqlite.md` | Domain - SQLite / DAO / Migration · Source · Rules · Search |
| `.codex/domains/ui-nami.md` | Domain - UI / Theme / NabiCopy · Source · Rules · Search |
| `.codex/history/HISTORY_REFRESH.md` | History Refresh |
| `.codex/history/LEARNED_SKILLS.md` | Learned Skills · Canonical Work Types Seen · Frequent Modules · Reusable Project Skills · Command And Test Patterns · Post-Session Self Optimization |
| `.codex/history/OPEN_RISKS.md` | Open Risks · NB-RISK-001 Supabase sandbox/staging verification pending · NB-RISK-002 Product flow DD open decisions Q-01..Q-10 |
| `.codex/history/RISK_HISTORY.md` | Risk History · Extracted Lines |
| `.codex/history/SESSION_QUALITY_REVIEW.md` | Session Quality Review · Required Self-Review Questions · Worklog Section · Tu danh gia va toi uu phien sau |
| `.codex/history/WORKLOG_INDEX.md` | Worklog Index · Entries |
| `.codex/playbooks/access_membership_referral.md` | Alias - Access / Membership / Referral |
| `.codex/playbooks/ai_service.md` | Alias - AI Service |
| `.codex/playbooks/dashboard.md` | Alias - Dashboard |
| `.codex/playbooks/dd_creation.md` | Alias - DD Creation |
| `.codex/playbooks/health_tracking.md` | Alias - Daily Health Tracking |
| `.codex/playbooks/lifestyle_schedule.md` | Alias - Lifestyle Schedule |
| `.codex/playbooks/notification.md` | Alias - Notification |
| `.codex/playbooks/onboarding.md` | Alias - Onboarding |
| `.codex/playbooks/sqlite.md` | Alias - SQLite |
| `.codex/playbooks/ui_nami.md` | Alias - UI Nami |
| `.codex/skills/create-dd-from-bd/SKILL.md` | Create DD From BD · When To Use · Required Context · Output Contract · DD Rules · Completion |
| `.codex/skills/create-dd-from-bd/agents/openai.yaml` | Bridge/configuration |
| `.codex/skills/create-dd-from-bd/references/dd-module-from-bd.md` | DD Module From BD Reference · Input Extraction · Folder And File Responsibilities · Traceability Pattern · Quality Gate |
| `.codex/skills/nanobio-project-agent/SKILL.md` | NanoBio Project Agent · Quick Start · Workflow Selection · Domain Selection · History Learning |
| `.codex/skills/nanobio-project-agent/agents/openai.yaml` | Bridge/configuration |
| `.codex/skills/nanobio-project-agent/references/context-router.md` | Context Router · Default Read Pack · Request To Workflow · Expansion Rule |
| `.codex/skills/nanobio-project-agent/references/domain-map.md` | Domain Map |
| `.codex/skills/nanobio-project-agent/references/worklog-learning.md` | Worklog Learning · Read Rule · Refresh Rule · Self-Optimization Rule |
| `.codex/task-skills/LEGACY_TASK_KEY_MAP.md` | Legacy Task Key Map |
| `.codex/task-skills/README.md` | Task Skills |
| `.codex/task-skills/bugfix.md` | Task Skill - Direct bugfix · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/coding.md` | Task Skill - Coding · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/create-issues.md` | Task Skill - Create issue docs · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/create-todo.md` | Task Skill - Create todo docs · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/docs-context.md` | Task Skill - Context and docs update · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/docs-dd.md` | Task Skill - Design docs · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/find-issues.md` | Task Skill - Review and find issues · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/fix-issues.md` | Task Skill - Fix documented issue · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/nabi-character/SKILL.md` | Nabi Character Task Skill · Read first · Contract · Working sequence |
| `.codex/task-skills/refactor-scaffold.md` | Task Skill - Scaffold refactor · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/supabase-schema.md` | Task Skill - Supabase schema and RLS · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/task-skills/test.md` | Task Skill - Test and verification · When To Read · Common Modules · Work Pattern · Token Optimization · Source Worklogs |
| `.codex/workRule/develop.md` | Alias - Develop / Coding |
| `.codex/workRule/fix.md` | Alias - Fix Issues |
| `.codex/workRule/test.md` | Alias - Test |
| `.codex/workflows/README.md` | Workflow Registry · Common Session Rules |
| `.codex/workflows/bugfix.md` | Workflow - Bugfix · Required Context · Rules · Completion |
| `.codex/workflows/coding.md` | Workflow - Coding · Required Context · DD Progress Gate · Rules · Completion |
| `.codex/workflows/context-read.md` | Workflow - Context Read · Read Order · Do Not Read By Default |
| `.codex/workflows/create-issues.md` | Workflow - Create Issues · Required Context · Rules · Completion |
| `.codex/workflows/create-todo.md` | Workflow - Create Todo · Required Context · Rules · Completion |
| `.codex/workflows/docs-context.md` | Workflow - Docs Context · Required Context · Rules · Completion |
| `.codex/workflows/docs-dd.md` | Workflow - Docs DD · Required Context · Rules · Completion |
| `.codex/workflows/find-issues.md` | Workflow - Find Issues · Required Context · Rules · Completion |
| `.codex/workflows/fix-issues.md` | Workflow - Fix Issues · Read Order · Rules · Completion |
| `.codex/workflows/refactor-scaffold.md` | Workflow - Refactor Scaffold · Required Context · Rules · Completion |
| `.codex/workflows/supabase-schema.md` | Workflow - Supabase Schema · Required Context · Rules · Completion |
| `.codex/workflows/test.md` | Workflow - Test · Required Context · Rules · Commands · Completion |


## Appendix F - asset map

Snapshot 2026-06-30. Use declared assets only after checking `pubspec.yaml` and the feature asset/documentation contract. Nabi assets are organized by interaction context; do not relocate/rename them without updating asset config and consumers.

| Asset group | Files | Examples |
|---|---:|---|

| `assets/config/nabi` | 5 | `nabi_asset_manifest.json`, `nabi_character_config.json`, `nabi_expression_map.json`, `nabi_motion_library.json`, `nabi_state_matrix.yaml` |
| `assets/icons` | 2 | `Logo.jpg`, `logo.png` |
| `assets/icons/custom` | 1 | `.gitkeep` |
| `assets/icons/filled` | 1 | `.gitkeep` |
| `assets/icons/health` | 1 | `.gitkeep` |
| `assets/icons/nutrition` | 1 | `.gitkeep` |
| `assets/icons/outlined` | 1 | `.gitkeep` |
| `assets/images/nabi` | 1 | `README.md` |
| `assets/images/nabi/chat` | 10 | `nabi_chat_answer_ready.png`, `nabi_chat_clarify.png`, `nabi_chat_greet.png`, `nabi_chat_typing.png` |
| `assets/images/nabi/core` | 8 | `nabi_analyze.png`, `nabi_idle_happy.png`, `nabi_listen.png`, `nabi_wave.png` |
| `assets/images/nabi/daily` | 14 | `nabi_breakfast.png`, `nabi_drink_water.png`, `nabi_exercise.png`, `nabi_sleep.png` |
| `assets/images/nabi/engagement` | 10 | `nabi_away_1day.png`, `nabi_daily_user.png`, `nabi_new_user.png`, `nabi_welcome_back.png` |
| `assets/images/nabi/future` | 10 | `nabi_family_plan.png`, `nabi_premium_unlocked.png`, `nabi_referral_success.png`, `nabi_sales_reward.png` |
| `assets/images/nabi/onboarding` | 9 | `nabi_ai_generating_plan.png`, `nabi_onboarding_intro.png`, `nabi_onboarding_review.png`, `nabi_plan_ready.png` |
| `assets/images/nabi/progress` | 12 | `nabi_day_complete.png`, `nabi_milestone_badge.png`, `nabi_task_complete.png`, `nabi_thank_you.png` |
| `assets/images/nabi/system` | 11 | `nabi_access_locked.png`, `nabi_loading.png`, `nabi_offline.png`, `nabi_sync_success.png` |


---

### Final instruction to an implementation Agent

For a UI request: identify **surface → feature → page → provider/controller → DD → nearest theme family**; then make the smallest coherent change that preserves data direction, route behavior, accessibility, Vietnamese Nabi tone and version boundaries. When uncertain, search the source contract rather than introducing a new UI convention.

