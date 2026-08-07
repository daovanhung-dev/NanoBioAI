# V2-13 — V2 Home

> Baseline: `daovanhung-dev/NanoBioAI` @ `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`  
> Classification: **active-route** · Group: `06_v2_v3_access` · Archetype: `member-home`

## 01. Purpose
Trang member Free định hướng module có quyền truy cập và các hành động tiếp theo.

## 02. Source evidence
- Source: `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart`
- Evidence baseline: commit `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`.
- This spec preserves runtime/business boundaries; it is a UI/UX implementation contract, not new product logic.

## 03. Route / entry
`V2RoutePaths.home`

## 04. Access model
Respect existing guards, membership, guest/auth, admin/sale state and trusted-backend decisions. UI must never infer access from color, local cache or optimistic state.

## 05. Primary user
The current user/persona already permitted by the route or invocation context. Admin and Sale surfaces use role-specific density and copy; health surfaces remain consumer-friendly.

## 06. User job
Trang member Free định hướng module có quyền truy cập và các hành động tiếp theo.

## 07. Success outcome
The user can identify the current state, the next safe action, and the result of that action without needing internal implementation knowledge.

## 08. Information hierarchy
Use the order **context → most important state/data → next action → supporting detail → history/help**. Do not place equal visual weight on every card.

## 09. Page anatomy
Calm medical card hierarchy with one expressive focal element.

## 10. Material 3 Expressive archetype
Use expressive typography, shape and motion to clarify hierarchy—not to decorate every surface. One visual focal point per viewport is the default.

## 11. Color
- Semantic tokens only from `lib/core/theme/`.
- Primary blue for action/navigation; cyan/mint for informational/wellness semantics; violet only for AI/premium emphasis when relevant.
- Error/warning/success must carry icon/text, never color alone.

## 12. Typography
- Strong, short display/heading for the current task.
- Body copy stays compact and Vietnamese-first.
- Numeric health/business values use tabular/scannable treatment; labels remain readable at increased text scale.

## 13. Shape
Use M3 expressive shape contrast: large hero/summary containers may be softer; data rows/forms use calmer radii; pills are reserved for status/chips rather than every container.

## 14. Spacing
Base rhythm 4/8 with practical tokens: 8, 12, 16, 20, 24, 32. Maintain at least 16 px compact side padding and avoid stacking decorative gaps.

## 15. Elevation & depth
Prefer tonal containment + border + short shadow. Glass/blur is allowed only for transient navigation/control layers and must degrade cleanly when transparency is reduced.

## 16. Core components
Cards, section headers, semantic icons, state containers and buttons come from canonical theme/primitives. Feature-local styling must not introduce a parallel design system.

## 17. Primary action
Primary task visually dominant; secondary actions grouped.

## 18. Secondary actions
Keep secondary actions visually quieter and spatially grouped with the content they affect. Overflow/menu is preferred over a row of equally weighted buttons.

## 19. Navigation & back
Preserve current GoRouter/Navigator behavior. Push/back transitions must be symmetric; system back must return to the previous valid state without discarding unsaved input silently.

## 20. Loading state
Use skeleton/progress only for regions actually loading. Preserve stable page chrome where possible; do not blank a usable page for additive/background refresh.

## 21. Empty state
Explain **what is empty, why that is normal, and the next real action**. Never populate production UI with mock/sample health or financial data.

## 22. Error state
Use Nabi-safe Vietnamese on consumer surfaces and operational Vietnamese on Admin. Provide retry only when retry is meaningful; no stack trace, parser, table, query, exception or log terminology.

## 23. Ready state
Ready content should be glanceable in the first viewport, with detail progressively disclosed. Avoid dense prose above the first actionable information.

## 24. Disabled / locked / coming-soon
Development/locked state must state what is available now and what is not.

## 25. Motion
Fade-through / subtle shape morph 180–260 ms. Reduced Motion must collapse movement to opacity/static state changes while preserving causality and hierarchy.

## 26. Haptic & sound
Use `AppFeedbackService` at interaction boundaries. Generic taps do not need sound. Admin defaults to sound Off; health milestones may use subtle success feedback only after confirmed state change.

## 27. Nabi behavior
Nabi is contextual companion, not a permanent obstruction. Hide/reposition around dense controls; do not cover tap targets. Admin has no ambient Nabi. Copy is gentle, concise and non-judgmental.

## 28. Accessibility
- Touch targets ≥ 48 dp where practical.
- Support text scale without clipping/overflow.
- Contrast must survive dark/high-contrast modes.
- State is communicated by text/icon/shape as well as color.
- Respect `MediaQuery.disableAnimations`, Reduce Motion/Transparency and screen-reader semantics.

## 29. Responsive / adaptive
Compact: single column, sticky/local CTA only when safe. Medium: 2-column cards/forms where relationship is clear. Expanded/Admin: bounded content width or data workspace; do not merely stretch mobile cards across desktop.

## 30. Data & trust guardrails
Presentation reads through existing provider/controller boundaries. No DAO/API calls from UI. Membership, quota, payment success, Sale/Admin authority and financial state come from trusted backend contracts, not visual assumptions.

## 31. Implementation handoff
- Start with tokens/primitives before page-level decoration.
- Preserve current provider/controller calls and keys unless a separate runtime task approves change.
- Implement state parity first, then expressive motion, then polish.
- Validate narrow screen, large text, dark mode and reduced motion for this surface.

## 32. Acceptance criteria
- [ ] Visual hierarchy matches this spec and group rules.
- [ ] Loading/empty/error/ready/disabled state coverage is explicit.
- [ ] No business/access/persistence behavior changed by styling.
- [ ] No overflow at compact width and increased text scale.
- [ ] Reduced-motion behavior is usable.
- [ ] User-facing copy is Vietnamese and contains no internal technical terms.
- [ ] Feedback fires only after the corresponding semantic event.
- [ ] Source/route classification remains accurate at implementation time.
