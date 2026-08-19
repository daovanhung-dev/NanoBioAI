# DUPLICATED UI / COMPONENT REPORT

Baseline: `30587ab9b04d95aa621e5412502aafd0d0ca4827`

## Confirmed duplication / drift

### 1. Meal replacement sheets — should merge
- `meal_plan_page.dart` contains a private replacement sheet.
- `presentation/widgets/meal_replacement_picker.dart` contains a reusable picker used from Today Tasks.
- Same user job, different loading/error/selection UI → style/behavior drift risk. Recommended: one shared picker with parameterized copy/callback.

### 2. Daily Health Tracking route aliases Lifestyle Schedule — canonicalize
- `/health-tracking` renders `LifestyleSchedulePage` directly.
- `/lifestyle-schedule` also renders `LifestyleSchedulePage`.
- Recommended: one canonical product route; legacy alias should redirect rather than expose duplicate feature identity.

### 3. Nabi context mapping duplicates `/menu` for two tabs
- Features Hub and Settings both use the same Nabi route key. This is presentation-context duplication, not visual duplication, and can preserve stale assistant context.

### 4. V3 standalone route definitions duplicate V1/V2 routes
- Login, Payments and Lifestyle Schedule are recreated in `v3_router.dart`. Prefer canonical route factories.

### 5. Design token migration residue
- Runtime has moved to Nabi Blue Wellness, while multiple onboarding/source aliases still use names such as `NabiPalette.greenPrimary/greenDeep` and older screen specs mention Green Wellness. Compatibility aliases may be intentional, but they increase semantic drift and make future audits harder.

## Intentional duplication that should NOT be removed automatically

- Nabi V1 assets remain in Git as source-only rollback material; current `pubspec.yaml` explicitly bundles Nabi V2 for release. This is intentional rollback duplication, not an asset bug by itself.
- Admin sections share `AdminWorkspacePage`/`admin_workspace_sections.dart`; this is desired composition, not screen duplication.
- V1 auth entry pages intentionally hand off to V2 auth; this wrapper can be simplified as a UX improvement but is not code duplication requiring deletion.

## Shared components that are working as intended
- `MedicalPageScaffold`, `MedicalSurfaceCard`, `AppStateSwitcher` centralize medical shell/state behavior.
- Onboarding uses `OnboardingStepShell`, choice grids, picker fields and Nabi experience primitives consistently.
- Admin workspace centralizes sidebar/drawer/toolbar/work queue rather than copying section layouts.