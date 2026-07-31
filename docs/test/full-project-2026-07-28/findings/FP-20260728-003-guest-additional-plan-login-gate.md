# FP-20260728-003 — Guest renewal control blocks the mandatory login escalation

## Classification

- Severity: High / P1 business-rule and conversion-path defect
- Type: business logic, authorization journey, UX
- Status: Open; this campaign did not change product code
- Persona scope: any local Guest after consuming its one initial journey while the current journey remains locked
- Related case: [PF-003](../cases/PF-003.md)

## Environment

- Physical Android 11 (API 30), `220333QPG`, package `com.example.nano_app`
- Unified entry point `lib/main.dart`; source revision `9e81b08b9ae2aab4e1c263f99b044002059b4bb0` with a pre-existing dirty worktree
- Fresh local Guest sequence: app data was cleared before PF-002; no backend fixture or account was modified

## Reproduction

1. Start as a Guest and complete onboarding to create the one allowed initial journey.
2. Return to the Dashboard while the created journey still has more than one day remaining.
3. Attempt the visible journey-renewal surface and its chevron.

## Expected versus actual

- Expected: Product Flow M02 / AC-02 requires a Guest who has used the initial creation to be directed to login before another journey can be created. The rule says the product must not merely hide the route.
- Actual: the UI displays the remaining-day message and locks the renewal control. Touching the card/chevron does not navigate to login or expose an escalation action.

## Evidence and impact

- [Redacted device screenshot](../assets/PF-003-fail.png) preserves the locked control and the remaining-day message.
- In the current implementation, `dashboard_page.dart` disables the control when `isLocked`; the Guest-initial-plan exception has a login-oriented message only after the generation use case is reached. This is a triage clue, not a root-cause conclusion.
- Impact: the configured one-time Guest limit is enforced by an unavailable UI path rather than the required login conversion/authorization experience. A Guest cannot understand or execute the prescribed next step.

## Suggested resolution direction

Product and engineering should decide how the schedule-horizon guard and Guest limit compose. The UI should retain an accessible, actionable “sign in to create another journey” path for a Guest who has consumed the initial creation, while preserving the rule that no second Guest AI journey is created. Validate the same behavior at route/use-case level after the UI change.
