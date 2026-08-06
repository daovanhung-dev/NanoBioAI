# Coding Plan — Nabi Kinetic Aura

## 1. Scope and invariants

### Scope

Refactor toàn bộ presentation/theme/navigation/feedback theo design trong `.codex/design`.

### Invariants

- Không thay đổi business logic, schema, repository contract, trusted access hoặc quota.
- Không tạo production mock data.
- Không phát success trước persistence/RPC thành công.
- Presentation không gọi DAO/API.
- Notification/outbox/provider invalidation behavior phải giữ nguyên.
- User/Admin surface selection trong unified app không đổi.

## 2. Pre-coding gates

1. Xác nhận design documents.
2. Khôi phục/cung cấp physical sound assets hoặc chấp nhận triển khai haptic-only trước.
3. Chọn audio dependency sau license/platform/size review; bọc sau adapter.
4. Chốt visual prototype cho 16 interaction đại diện.
5. Chụp baseline screenshots/device matrix.
6. Khóa public token/primitive naming để tránh lớp thứ ba.

## 3. Wave 1 — Foundation and feedback

### Files

- `lib/core/theme/foundation/*`
- `lib/core/theme/tokens/*`
- `lib/core/theme/app_*`
- `lib/core/theme/primitives/*`
- New `lib/core/feedback/*`
- New/updated component tests.

### Tasks

1. Consolidate duration/curve/scale/distance/spring tokens.
2. Resolve duplicate `AppTextStyles` and token symbols.
3. Map `AppColors/AppSpacing/AppRadius/AppDuration` to canonical tokens.
4. Implement `AppMotionScope` and reduced-motion resolver.
5. Implement `AppFeedbackService`, haptic adapter, sound adapter/no-op/fake.
6. Upgrade Button/Card/Chip/Input/State primitives.
7. Expand design-system demo into motion lab.

### Validation

- Token uniqueness static tests.
- Primitive widget tests.
- Reduced motion, semantics, text scale.
- No direct audio dependency outside adapter.

## 4. Wave 2 — App shell and route motion

### Files

- `lib/app/bio_ai_app.dart`
- `lib/app/app_surface_controller.dart`
- `lib/app_versions/*/app/*`
- `lib/app_versions/*/router/*`
- `lib/features/nabi/presentation/widgets/nabi_app_shell.dart`

### Tasks

1. Install one Experience/Feedback/Motion scope.
2. Create route-motion registry.
3. Apply push/back symmetry and auth redirect no-flash.
4. Standardize modal/bottom-sheet helpers.
5. Add route transition tests.

## 5. Wave 3 — Splash and onboarding

- Refactor `splash_page.dart` to one timeline orchestrator.
- Migrate onboarding shell, chips, text field and all 9 steps.
- Stable keys/directional transitions/back preservation.
- Nabi onboarding priority and plan-ready feedback.
- Sound limited to welcome/plan-ready; success after plan persistence.

## 6. Wave 4 — Dashboard and navigation

- Refactor `menu_page.dart` navigation indicator/body fade-through.
- Split dashboard orchestration from sections.
- Migrate score, stats, goals, timeline, insights and states.
- Delta-only animation; preserve scroll and provider refresh behavior.

## 7. Wave 5 — Meal, nutrition, schedule and proof

- Split `meal_plan_page.dart` and `lifestyle_schedule_page.dart` by components.
- Implement entity identity, shared recipe/proof transitions.
- Replace-in-place meal animation and macro tween.
- Timeline complete/skip/proof feedback after transaction.
- Reschedule notification/sync signals without duplicate celebration.

## 8. Wave 6 — AI Chat, Voice AI and Nabi

- Migrate message insert/typing/composer/error state.
- Implement voice orb state machine.
- Centralize haptic/sound cues.
- Consolidate Nabi global/V1 owner, renderer and route mapping.
- Add lifecycle/cooldown/cache/reduced motion tests.

## 9. Wave 7 — Health tracking and care surfaces

- Body metrics, water, sleep/stress shells, weekly summary, goals, health score, advanced tracking.
- Tactile metric controls and chart/ring delta motion.
- Care/feature hub/planned states.
- Shared AI generation loading surface.

## 10. Wave 8 — Auth, profile and settings

- Split `auth_pages.dart`, `profile_page.dart`, `settings_page.dart`.
- Focus/validation/submit transitions.
- Add motion/haptic/sound/Nabi settings.
- Auth gate no-flash and sync/consent state transitions.

## 11. Wave 9 — V2/V3/Membership/FamilyPlus

- Locked/pending/active/revoked states.
- Payment request vs trusted approval feedback.
- Family member insert/remove and subject switch privacy transition.
- Wellness rewards ledger-confirmed animation.

## 12. Wave 10 — Sale and Admin

- Split `sale_shell_page.dart` and `admin_shell_page.dart`.
- Compact motion primitives, table row highlight, filter/dialog continuity.
- Admin sound default off, no ambient Nabi.
- Mutation feedback only after RPC result.

## 13. Wave 11 — Cleanup and certification

1. Remove direct `HapticFeedback`/audio calls outside adapter.
2. Remove raw duration/color from feature UI or record reviewed exception.
3. Remove duplicate/deprecated motion APIs.
4. Add static architecture policies.
5. Run targeted format/analyze/test per wave.
6. Run broad architecture tests.
7. Build debug APK.
8. Real-device visual/motion/audio/accessibility matrix.
9. Update screenshots, worklog and design matrix statuses.

## 14. Commit boundaries

Mỗi wave tối thiểu tách thành:

1. Foundation/API.
2. Component/page migration.
3. Tests/docs/cleanup.

Không trộn Supabase/schema/business changes với UI motion refactor.

## 15. Risk controls

| Risk | Control |
|---|---|
| Jank/asset memory | Performance tier, visibility pause, profile evidence |
| Success before commit | Feedback emitted from confirmed state transition |
| Animation replay | Stable keys + previous value comparison |
| Duplicate Nabi | One owner/orchestrator test |
| Sound spam | Policy/cooldown/dedup/event ID |
| Accessibility regression | Reduce motion/text scale/semantics tests |
| Scope explosion | File matrix + wave status + no business refactor |
| Missing audio assets | Block sound wave or use no-op adapter until assets exist |

## 16. Completion evidence

- Matrix 100% `Verified` for in-scope files.
- Static policy PASS.
- Targeted tests PASS.
- Architecture tests PASS.
- Debug APK build PASS.
- Device visual/motion/audio/reduce-motion evidence.
- No unresolved P0/P1 introduced by refactor.
