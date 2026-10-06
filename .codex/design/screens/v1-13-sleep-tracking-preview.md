# V1-13 — Sleep Tracking and Safety

> Baseline: `daovanhung-dev/NanoBioAI` @ `d126e8ad0c482e3eacc373f35b37f339dd37a8cb`  
> Classification: **active-route with auth and access gate** · Group: `07_health_tracking` · Archetype: `health-tracking`

## 01. Purpose
Cho phép tài khoản đã được cấp quyền chủ động bật giám sát âm thanh cục bộ, quản lý người liên hệ an toàn và xem các trạng thái sau phiên ngủ.

## 02. Source evidence
- Source: `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- Current route evidence: `V1RoutePaths.sleepTracking` is registered with `V1RouteGuards.authGuard` and renders `SleepSafetyAccessGate(child: SleepTrackingPage())`.
- This spec preserves runtime/business boundaries; it is a UI/UX implementation contract, not new product logic.

## 03. Route / entry
`V1RoutePaths.sleepTracking` → auth guard → `SleepSafetyAccessGate` → sleep tracking and M31 safety sub-surfaces.

## 04. Access model
Respect existing guards, membership, guest/auth, admin/sale state and trusted-backend decisions. UI must never infer access from color, local cache or optimistic state.

## 05. Primary user
The current user/persona already permitted by the route or invocation context. Admin and Sale surfaces use role-specific density and copy; health surfaces remain consumer-friendly.

## 06. User job
Biết tính năng đang ở trạng thái nào, bắt đầu hoặc dừng giám sát có chủ đích, cấu hình lịch/người liên hệ và xem lịch sử/phân tích khi đã có phiên phù hợp.

## 07. Success outcome
Người dùng hiểu quyền truy cập, trạng thái micro/giám sát, hành động kế tiếp và giới hạn an toàn; ứng dụng chỉ bắt đầu nghe sau thao tác chủ động và không lưu bản ghi âm.

## 08. Information hierarchy
Use the order **context → most important state/data → next action → supporting detail → history/help**. Do not place equal visual weight on every card.

## 09. Page anatomy
Sleep view, access gate, safety history, trusted contacts, safety schedule and sound-level setup.

## 10. Material 3 Expressive archetype
Use expressive typography, shape and motion to clarify hierarchy—not to decorate every surface. One visual focal point per viewport is the default.

## 11. Color
- Semantic tokens only from `lib/core/theme/`.
- Blue Wellness primary `#285CC5` directs action/navigation; health green `#16845C` marks positive health status; use semantic light/dark roles and avoid simulated sleep data.
- Error/warning/success must carry icon/text, never color alone.

## 12. Typography
- Roboto 400/500/600/700 is the deterministic family; use a strong, short display/heading for the current task.
- Body copy stays compact and Vietnamese-first.
- Numeric health/business values use tabular/scannable treatment; labels remain readable at increased text scale.

## 13. Shape
Use M3 expressive shape contrast: input/control 14 dp, card 20 dp and sheet 28 dp are the Blue Wellness defaults; pills are reserved for status/chips.

## 14. Spacing
Base rhythm 4/8 with practical tokens: 8, 12, 16, 20, 24, 32. Maintain at least 16 px compact side padding and avoid stacking decorative gaps.

## 15. Elevation & depth
Prefer tonal containment + border + short shadow. Glass/blur is allowed only for transient navigation/control layers and must degrade cleanly when transparency is reduced.

## 16. Core components
Cards, section headers, semantic icons, state containers and buttons come from canonical theme/primitives. Feature-local styling must not introduce a parallel design system.

## 17. Primary action
Khi được mở khóa: bắt đầu giám sát thủ công hoặc dừng phiên đang hoạt động. Ở gate: chỉ hiển thị CTA đăng nhập/nâng cấp/thử lại khi luồng đó đã có thật.

## 18. Secondary actions
Keep secondary actions visually quieter and spatially grouped with the content they affect. Overflow/menu is preferred over a row of equally weighted buttons.

## 19. Navigation & back
Preserve current GoRouter/Navigator behavior. Push/back transitions must be symmetric; system back must return to the previous valid state without discarding unsaved input silently.

## 20. Loading state
Giữ app bar và nội dung ổn định khi tải lựa chọn, liên hệ hoặc lịch sử; trạng thái kiểm tra quyền dùng mô tả rõ đang xác nhận điều gì.

## 21. Empty state
Nêu rõ chưa có phiên, lịch sử hoặc liên hệ và hành động thật kế tiếp. Không tạo dữ liệu ngủ mẫu hay khẳng định sức khỏe từ dữ liệu rỗng.

## 22. Error state
Use Nabi-safe Vietnamese on consumer surfaces and operational Vietnamese on Admin. Provide retry only when retry is meaningful; no stack trace, parser, table, query, exception or log terminology.

## 23. Ready state
Đưa trạng thái giám sát và nút bắt đầu/dừng lên trước; cấu hình độ nhạy, lịch, liên hệ và lịch sử theo thứ tự tác vụ.

## 24. Disabled / locked / coming-soon
Phân biệt đang tải quyền, lỗi cần thử lại, cần đăng nhập, cần gói Plus/FamilyPlus, rollout đang tạm dừng và tính năng sẵn sàng. Không gộp các gate thành một nhãn “sắp ra mắt”.

## 25. Motion
Static/fade only; no celebratory loop. Reduced Motion must collapse movement to opacity/static state changes while preserving causality and hierarchy.

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

Current inventory refresh: route is active behind auth, membership and rollout checks; previous "coming-soon" label was stale. M31 child surfaces are included in the source audit. Device/render evidence is pending.
