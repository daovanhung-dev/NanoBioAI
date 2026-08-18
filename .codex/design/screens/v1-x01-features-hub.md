# V1-X01 — Features Hub

> Baseline: `daovanhung-dev/NanoBioAI` @ `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`  
> Classification: **source-sub-surface** · Group: `03_dashboard_health` · Archetype: `feature-grid`
> Compact-density decision: **2026-08-18 — 3-column active shortcut grid, 15 runtime destinations, future sections collapsed by default.**

## 01. Purpose
Tập hợp các chức năng chăm sóc theo nhóm để người dùng mở nhanh nhiều công cụ thật đang có trong runtime, đồng thời không để các mục chưa hoàn thiện chiếm phần lớn viewport.

## 02. Source evidence
- Source: `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
- Evidence baseline: commit `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`.
- This spec preserves runtime/business boundaries; it is a UI/UX implementation contract, not new product logic.
- Active shortcut destinations must already exist in the current route registry; this surface does not create placeholder routes to make the grid look complete.

## 03. Route / entry
`MainNavigationPage tab: Tiện ích`

## 04. Access model
Respect existing guards, membership, guest/auth, admin/sale state and trusted-backend decisions. UI must never infer access from color, local cache or optimistic state. A shortcut may point at a guarded route; the existing router remains the authority for allowed/auth-required behavior.

## 05. Primary user
The current user/persona already permitted by the route or invocation context. Admin and Sale surfaces use role-specific density and copy; health surfaces remain consumer-friendly.

## 06. User job
Nhìn thấy nhiều lựa chọn chăm sóc hữu ích ngay trong viewport đầu, nhận biết nhanh từng công cụ bằng icon + nhãn, và mở đúng route mà không phải cuộn qua các card quá lớn.

## 07. Success outcome
The user can identify the current state, the next safe action, and the result of that action without needing internal implementation knowledge. On compact devices, active care shortcuts are materially denser than the legacy full-width card list while remaining tappable and scannable.

## 08. Information hierarchy
Use the order **context → active care shortcuts → collapsed future/advanced groups → supporting detail**. Do not place equal visual weight on unfinished modules and runtime-ready tools.

## 09. Page anatomy
Calm medical hierarchy with one compact expressive hero, one compact active-care section header, a dense active shortcut grid, then progressively disclosed future and advanced sections.

## 10. Material 3 Expressive archetype
Use expressive typography, shape and motion to clarify hierarchy—not to decorate every surface. One visual focal point per viewport is the default. Active shortcuts use tonal cards and semantic icons rather than independent arrow buttons.

## 11. Color
- Semantic tokens only from `lib/core/theme/`.
- Blue Wellness primary `#2F6FED` owns brand/navigation hierarchy; green remains a supporting wellness/success accent.
- Pastel tonal surfaces may distinguish categories, but state/access must never rely on color alone.
- Error/warning/success must carry icon/text, never color alone.

## 12. Typography
- Roboto 400/500/600/700 is the deterministic family.
- Active compact tiles use short Vietnamese labels, maximum two visual lines.
- Descriptive subtitles remain available through semantics even when hidden from the compact tile face.
- Numeric health/business values use tabular/scannable treatment where relevant; labels remain readable at increased text scale.

## 13. Shape
Use M3 expressive shape contrast: input/control 14 dp, compact shortcut card approximately 16 dp, standard detail card 20 dp and sheet 28 dp. Pills are reserved for status/count chips.

## 14. Spacing
Base rhythm 4/8 with practical tokens: 4, 8, 12, 16, 20, 24, 32. Maintain 16 px compact side padding. Active compact grid uses 8 px gaps on compact devices and avoids decorative vertical gaps inside each tile.

## 15. Elevation & depth
Prefer tonal containment + border + short shadow. Compact shortcuts use the lightest supported card shadow; future/advanced detail cards may retain standard card depth after expansion.

## 16. Core components
Cards, section headers, semantic icons, state containers and buttons come from canonical theme/primitives. Feature-local styling must not introduce a parallel design system.

## 17. Primary action
The entire active shortcut tile is the tap target. Do not add a second 48 dp arrow button inside the same tile.

## 18. Secondary actions
Future and advanced groups are secondary to active care. Keep them collapsed by default and expose their contents through one clear section toggle each.

## 19. Navigation & back
Preserve current GoRouter/Navigator behavior. Active shortcuts call their existing route constants. Existing auth/access guards remain authoritative; system back must return to the previous valid state.

## 20. Loading state
Use skeleton/progress only for regions actually loading. This surface is primarily static navigation composition; do not invent loading placeholders when destinations are already known locally.

## 21. Empty state
Never populate production UI with mock/sample health or financial data. If a destination has no real data, its destination page owns that empty state rather than the Feature Hub fabricating preview values.

## 22. Error state
Use Nabi-safe Vietnamese on consumer surfaces. Provide retry only when retry is meaningful; no stack trace, parser, table, query, exception or log terminology.

## 23. Ready state
Ready content should be glanceable in the first viewport. The active section contains **15 runtime-backed shortcuts** in priority order. Compact tiles show icon + short title; detail copy remains semantic/supporting information rather than occupying the tile face.

## 24. Disabled / locked / coming-soon
- `Giấc ngủ`, `Cảm xúc & stress`, and `Cộng đồng chăm sóc` remain explicitly coming-soon/preview surfaces and live under a collapsed **Sắp ra mắt** group.
- M20–M29 remain development/advanced catalog items and live under a collapsed **Theo dõi chuyên sâu** group.
- Expanding a group does not upgrade its implementation status.

## 25. Motion
Use short causal expansion/collapse motion through opacity/size/arrow rotation. Respect `MediaQuery.disableAnimations`; Reduce Motion collapses these transitions to immediate/static state changes. Generic shortcut taps do not add decorative animation loops.

## 26. Haptic & sound
Generic navigation and expansion taps do not require sound. Do not bypass `AppFeedbackService` for future semantic feedback.

## 27. Nabi behavior
Nabi is contextual companion, not a permanent obstruction. Hide/reposition around dense controls; do not cover shortcut tiles. Copy is gentle, concise and non-judgmental.

## 28. Accessibility
- The whole shortcut tile is a semantic button and comfortably exceeds the 48 dp minimum tap size.
- Compact visual face may omit subtitle, but semantic label keeps `title + subtitle`.
- Titles use maximum two lines with ellipsis rather than overflow.
- Grid extent adapts upward for increased text scale.
- Contrast must survive dark/high-contrast modes.
- State is communicated by text/icon/shape as well as color.
- Collapsible groups announce group name, count and current expanded/collapsed state through semantics.
- Respect `MediaQuery.disableAnimations`, Reduce Motion/Transparency and screen-reader semantics.

## 29. Responsive / adaptive
- **Compact `<720 px`: 3 active shortcut columns.** Expected tile width is approximately 90–110 dp on common 320–390 dp devices, with ~104 dp base height and extra height at increased text scale.
- **Medium `720–1079 px`: 4 active shortcut columns.**
- **Expanded `>=1080 px`: 6 active shortcut columns.**
- Future/advanced groups remain collapsed by default. After expansion, their descriptive cards use 1 column on compact, 2 on medium and 3 on expanded widths.
- This 3-column compact rule is an explicit product-density exception for Features Hub and supersedes the legacy single-column line in the older baseline spec.

## 30. Data & trust guardrails
Presentation uses only existing route constants and catalog data. No DAO/API calls are introduced. Membership, quota, payment success, Sale/Admin authority and financial state remain trusted-backend/router responsibilities.

## 31. Implementation handoff
- Keep the hero smaller than the legacy version so the active grid begins earlier in the viewport.
- Use stable ids/keys for active shortcuts so widget tests can assert actual grid geometry.
- Preserve advanced module keys such as `advanced-health-feature-M20` for route/access regression coverage.
- Keep future/advanced child widgets unmounted while collapsed so unfinished content does not affect first-viewport density.
- Validate 320, 360, 390 and 1200 px widths plus increased text scale.
- Preserve current route behavior; this task is presentation density, not access/business refactoring.

## 32. Acceptance criteria
- [ ] Active section renders exactly 15 approved runtime-backed shortcuts.
- [ ] Compact width renders the first three active shortcuts on the same row and the fourth on the next row.
- [ ] Hero and active section header are materially more compact than the legacy layout.
- [ ] Active compact cards do not show the legacy standalone 48×48 arrow button.
- [ ] `Sắp ra mắt` is collapsed by default and expands to the three preview destinations on demand.
- [ ] `Theo dõi chuyên sâu` is collapsed by default and expands to M20–M29 on demand.
- [ ] Existing Free/Plus and `Đang phát triển` badges remain present after advanced expansion.
- [ ] Existing GoRouter/auth/access behavior is unchanged.
- [ ] No overflow at 320/360/390 px and increased text scale.
- [ ] Reduced-motion behavior is usable.
- [ ] User-facing copy is Vietnamese and contains no internal technical terms.
- [ ] Source/route classification remains accurate at implementation time.


## 33. Task-specific compact density override

For the approved Feature Hub density task, compact behavior intentionally overrides the historical single-column baseline:

- Active tools: 3-column compact grid on mobile.
- Planned tools: collapsed by default; when expanded, 3-column compact grid on mobile.
- Advanced M20-M29: collapsed by default; when expanded, 2-column compact grid on mobile to preserve long Vietnamese titles and access badges.
- Planned/advanced descriptions remain available through semantics but are not rendered as multi-line body copy inside compact tiles.
- Advanced tiles retain visible `Miễn phí`/`Plus` and `Đang phát triển` states.
- No route, auth, entitlement, persistence, or module readiness semantics change.
