# Stitch Green Wellness UI Acceptance Checklist

Unchecked means no acceptance claim. Evidence must identify the surface, state, viewport, theme and command or review record.

## Source and coverage

- [ ] All 76 Stitch `screen.png`/`code.html` pairs are classified as page, component, state or placeholder.
- [ ] Every Stitch pair has an owner, runtime route/invocation, state mapping and QA evidence link.
- [ ] PNG governs layout and HTML governs typography/token intent; Approved DD/runtime governs business.
- [ ] Repository registry count and route classifications match the working tree.
- [ ] `/today-tasks` has its own active-route spec and state evidence.
- [ ] No placeholder or alias is described as an implemented business capability.

## Foundation

- [ ] Primary `#006A46`, accent `#14A36F`, CTA `#0F8E62 -> #32C789`, background `#F5FAF7`, text `#12352A` and mint `#EAF9F1` resolve through semantic roles.
- [ ] Page gutter 16 and input/card/sheet radii 14/20/28 are mapped through tokens.
- [ ] Roboto 400/500/600/700 is bundled and deterministic.
- [ ] `AppSemanticColors` and `ColorScheme` provide light/dark parity; new UI does not depend on static light colors.
- [ ] Dark scheme is a frozen M3 fidelity result from seed `#006A46` and passes contrast review.
- [ ] Compatibility Blue aliases have an explicit removal gate after cutover.
- [ ] Admin retains its independent workspace palette.

## Assets

- [ ] Every imported Stitch URL records HTML hash, URL hash, MIME, dimensions, content hash, duplicate and license status.
- [ ] Unverified-license assets are reference/golden-only and are not bundled into a production surface.
- [ ] No hotlink, WebView, embedded HTML or Tailwind runtime is used.
- [ ] Avatar, QR, health, financial and transaction content comes from approved local/runtime sources, never Stitch samples.

## State and behavior

- [ ] Loading, empty, error, ready, locked, pending, offline and meaningful retry states are covered where applicable.
- [ ] Auth, entitlement, quota, payment, FamilyPlus, Sale and Admin authority remain trusted-runtime decisions.
- [ ] No mock/sample production data is added.
- [ ] Success feedback occurs only after authoritative commit.
- [ ] Duplicate submit, reconnect and retry behavior are idempotent where applicable.
- [ ] Unapproved DD/module/platform capability fails closed to manual fallback or honest placeholder.

## Visual and adaptive

- [ ] Light and dark golden evidence exists at 390 x 884 for every accepted surface.
- [ ] Adaptive checks pass at widths 320, 360, 412 and 600+ without overflow.
- [ ] Text scale 1.0, 1.3 and 1.6 remains usable.
- [ ] Page hierarchy follows the matched Stitch reference without copying sample data.
- [ ] Safe area, keyboard, sheet and back-stack behavior are verified.

## Accessibility and motion

- [ ] Screen-reader semantics, focus order and keyboard operation are verified.
- [ ] Interactive targets are at least 48 dp where applicable.
- [ ] Contrast passes in light/dark and state is not color-only.
- [ ] Reduce Motion collapses translation, scale and loops while preserving causal state changes.
- [ ] Sound and haptic settings override decorative feedback.

## Validation and release gates

- [ ] Touched Dart passes format check.
- [ ] Targeted `flutter analyze` and `flutter test` pass.
- [ ] Architecture and integration screenshot suites pass.
- [ ] Debug APK builds.
- [ ] Supabase sandbox/RLS matrix passes for affected trusted flows.
- [ ] Android and iOS real-device acceptance is recorded.
- [ ] Clinical/privacy approval, store permission review, asset license review and escrow key ceremony are recorded where applicable.
- [ ] `stitchGreenUi` cutover and rollback evidence is recorded.

No production-ready or 76/76 claim is valid until every applicable checkbox has evidence.
