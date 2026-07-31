---
finding_id: FP-20260728-002
title: M30 Nabi notification catalog and controller are not integrated into the unified app runtime
severity: P1
status: OPEN
category: Logic / business flow / UI integration
campaign: full-project-2026-07-28
run_id: FP-20260728-NBI-RUNTIME-AUDIT
command_id: CMD-20260728-NBI-RUNTIME-001
---

# M30 Nabi notification runtime is not reachable

## Scope

All 20 catalog notification IDs and the four cross-behaviour cases are affected:
NBI-001 through NBI-024. This spans Free, Plus, Family, Wellness, Sale, Guest
and Admin-content cohorts because none can enter the M30 notification runtime.

## Reproduction / evidence steps

1. Start from the approved unified entry point, `lib/main.dart`.
2. Inspect its bootstrap and the reachable app shell using the targeted commands
   recorded in `technical/NBI-M30-runtime-audit.md`.
3. Compare those references with the catalog, controller, engine and M30
   presentation shell under `lib/features/nabi/`.
4. Observe that the controller provider has no caller outside its declaration,
   `NabiAppShell` has no caller outside its own presentation files, and the
   defaults for navigation/native delivery are no-ops.

## Expected

For each eligible business state, the relevant M30 notification must be
evaluated and, when allowed by priority/suppression/cooldown, rendered as the
Nabi bubble/overlay; CTA must navigate safely, OS delivery must be actionable
where applicable, and analytics/retry behaviour must be observable as specified
by the Nabi BD.

## Actual

The unified runtime starts the older `NotificationBootstrap`, but contains no
M30 Nabi import or bootstrap. It does not subscribe business events to
`NabiNotificationController.evaluate`, does not mount `NabiAppShell`, and its
default M30 navigation/native-delivery adapters cannot perform work. Local
analytics `drainPending` returns zero and no authenticated adapter is wired.
The legacy V1 floating mascot is a different component and cannot demonstrate
any M30 trigger, CTA, suppression, retry or analytics requirement.

## Impact

The intended proactive Nabi experience is absent for every persona. Required
notifications cannot surface, priority/cooldown cannot govern a surface, CTA
and deep-link handling cannot complete, and notification analytics cannot be
collected through the intended flow. Acceptance evidence for the 24 cases
cannot be captured on a real device without changing the product, so the cases
are recorded as FAIL rather than fabricated PASS/BLOCKED evidence.

## Probable cause

The M30 domain/application/presentation layer appears to have been added as
isolated code but has not been composed into the production startup, router/app
shell, business-event source, platform delivery gateway, navigation gateway or
authenticated analytics adapter.

## Required resolution direction

Wire the M30 controller into the unified runtime with authenticated business
snapshots, install the M30 shell once in the active application shell, provide
real navigation/native-delivery/analytics adapters, then re-run the 24 cases on
the physical device. The exact package/entitlement wording should be aligned to
Product Flow M06 separately; it does not remove the integration requirement.

## References

- Technical evidence: `technical/NBI-M30-runtime-audit.md`
- Unified bootstrap: `lib/main.dart:31-52,115-124`
- Controller/no-op adapters: `lib/features/nabi/application/notifications/nabi_notification_controller.dart:80-326`
- M30 shell: `lib/features/nabi/presentation/widgets/nabi_app_shell.dart:9-26`
- Analytics drain: `lib/features/nabi/data/notifications/nabi_notification_local_repositories.dart:267-272`
- Legacy non-M30 overlay: `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart:314-317`
- Linked cases: NBI-001 .. NBI-024
