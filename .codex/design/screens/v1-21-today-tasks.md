# V1-21 - Today Tasks

> Working-tree evidence: 2026-08-08
> Classification: **active-route** - Group: `03_dashboard_health` - Archetype: `daily-task-list`

## 01. Purpose
Give the user one glanceable view of today's real Lifestyle Schedule tasks, their completion windows and the next valid action.

## 02. Source evidence
- Page: `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`
- States: `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_tasks_states.dart`
- Task interaction: `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`
- Source of truth: existing Lifestyle Schedule provider/controller and meal replacement controller.

## 03. Route / entry
`V1RoutePaths.todayTasks` (`/today-tasks`), exposed from the Features Hub.

## 04. Access model
Preserve the current V1 route guard and local/member data boundaries. Styling must not broaden access, membership or reward eligibility.

## 05. Primary user
A NanoBio user who already has zero or more real schedule items for the current local day.

## 06. User job
See what is open, upcoming, completed or locked; complete/undo a valid task; replace an eligible meal; inspect details; refresh.

## 07. Success outcome
The user understands current progress and can perform only the actions permitted by the task window and trusted controller result.

## 08. Information hierarchy
Date and daily context -> completed/total progress -> open tasks -> upcoming -> completed -> locked -> details.

## 09. Page anatomy
Stable app bar, Green Wellness hero, progress card, status-grouped task cards and a modal detail sheet.

## 10. Material 3 archetype
Use a single expressive daily-progress focal point. Task rows remain stable, scannable and keyed by task identity.

## 11. Color
- Green Wellness primary `#006A46`; accent `#14A36F`; background `#F5FAF7`; text `#12352A`; mint `#EAF9F1`.
- Open, upcoming, completed and locked states also carry icon and copy; color is never the only signal.
- Read context-aware semantic roles so dark mode preserves the same meaning.

## 12. Typography
Roboto 400/500/600/700. Keep the task title and time range readable at text scale 1.6; use tabular/scannable treatment for progress values.

## 13. Shape
Input/control radius 14 where applicable, cards 20 and the detail sheet 28. Status pills remain pill-shaped.

## 14. Spacing
Compact page gutter 16 with a 4/8 rhythm. Wrap task actions instead of compressing labels.

## 15. Elevation and depth
Prefer tonal cards and semantic borders. The currently open task may receive modest elevation; locked/complete states must stay readable.

## 16. Core components
`MedicalPageScaffold`, `MedicalPageHero`, `MedicalSurfaceCard`, `MedicalStatusPill`, semantic buttons, progress and state containers.

## 17. Primary action
`Hoan thanh` or `Hoan tac` is enabled only when the existing completion window permits it. Loading replaces the icon without changing layout.

## 18. Secondary actions
`Thay mon` appears only for a linked, incomplete meal. `Chi tiet` opens the task sheet. Refresh remains available when the provider is not already loading.

## 19. Navigation and back
Preserve GoRouter behavior. Closing the detail/confirmation sheet returns to the same scroll and task context.

## 20. Loading state
Keep app chrome stable and show bounded skeleton/progress content for the schedule region.

## 21. Empty state
Explain that no tasks are scheduled for today and provide only a real next action. Never populate sample tasks.

## 22. Error state
Use gentle Vietnamese copy and a meaningful retry bound to the existing refresh action. Do not expose implementation terminology.

## 23. Ready state
Group real tasks by open, waiting, completed and locked status calculated for the current local day.

## 24. Disabled / locked / pending
Disabled completion explains the time-window constraint. Pending reward sync is distinct from completion failure; no reward or success is claimed before the controller result.

## 25. Motion
Use stable keys, short fade-through/status transitions and no whole-page replay on same-data refresh. Reduced Motion keeps only short opacity/state changes.

## 26. Haptic and sound
Emit semantic feedback only after the existing controller reports the result. Generic taps remain silent and user settings override decorative feedback.

## 27. Nabi behavior
Nabi copy is concise, supportive and non-judgmental. It does not diagnose, promise rewards or cover task actions.

## 28. Accessibility
48 dp targets, semantic task/status/time labels, logical focus order, screen-reader announcements for committed changes, contrast in light/dark and no color-only status.

## 29. Responsive / adaptive
Single column at 320/360/390/412 widths; constrain content around 780 dp on larger layouts. Buttons wrap at large text and the sheet respects safe areas/keyboard.

## 30. Data and trust guardrails
Presentation continues through the existing providers/controllers. Completion proof, reward sync and meal replacement behavior are unchanged. No DAO/API call, sample health data or optimistic reward claim is introduced.

## 31. Implementation handoff
Match the relevant Stitch daily-task composition where classified, but use runtime task values and this source state model. Validate light/dark, offline refresh, empty/error and completion-window boundaries.

## 32. Acceptance criteria
- [ ] `/today-tasks` resolves to `TodayTasksPage` under the current guard.
- [ ] Loading, empty, error and all four ready groups have evidence.
- [ ] Complete/undo, no-reward confirmation, meal replacement and retry preserve existing controller behavior.
- [ ] No sample task, reward or health value is rendered.
- [ ] No overflow at 320 dp or text scale 1.6.
- [ ] Light/dark contrast, semantics, focus and reduced motion are verified.
- [ ] Success feedback occurs only after a confirmed result.
