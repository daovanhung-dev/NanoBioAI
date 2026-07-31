# NBI M30 runtime-integration audit

- Campaign: `full-project-2026-07-28`
- Run ID: `FP-20260728-NBI-RUNTIME-AUDIT`
- Command ID: `CMD-20260728-NBI-RUNTIME-001`
- Source revision: `9e81b08b9ae2aab4e1c263f99b044002059b4bb0`
- Entry point inspected: `lib/main.dart`
- Evidence type: source/runtime integration audit; this is not a simulated notification and does not claim a device screenshot.

## Method

The audit used targeted, read-only source searches and reads. It did not inject a
business event, change a fixture, call a notification API, or use a hidden test
route. The relevant commands were:

```text
rg -l --glob '*.dart' 'nabiNotificationControllerProvider' lib
rg -l --glob '*.dart' 'NabiNotificationEngine' lib
rg -l --glob '*.dart' 'NabiAppShell' lib
rg -l --glob '*.dart' 'NabiAssistantOverlay' lib
rg -n 'features/nabi|Nabi' lib/main.dart
rg -n "id: 'NBI-" lib/features/nabi/domain/notifications/nabi_notification_catalog.dart
```

## Observed evidence

1. The catalog declares all 20 planned IDs in
   `lib/features/nabi/domain/notifications/nabi_notification_catalog.dart:23-256`.
   The ID count from the targeted search was 20.
2. The unified entry point calls `runApp(... BioAIApp())` at
   `lib/main.dart:31-52` and starts only the legacy
   `NotificationBootstrap` lifecycle at `lib/main.dart:115-124`. The targeted
   `features/nabi|Nabi` search in `lib/main.dart` returned zero matches.
3. `nabiNotificationControllerProvider` occurs only in its declaration file,
   `lib/features/nabi/application/notifications/nabi_notification_controller.dart:83`.
   The engine is defined only in its own file and this controller file. No app
   shell, route, bootstrap, or business-event subscription starts `evaluate`.
4. The presentation shell is self-contained: `NabiAppShell` only stacks
   `NabiAssistantOverlay` over its child at
   `lib/features/nabi/presentation/widgets/nabi_app_shell.dart:9-26`; targeted
   searches found no use outside the two M30 presentation-widget files.
5. The controller's default navigation and native-delivery dependencies are
   `_NoopNabiNavigationGateway` and `_NoopNabiNativeDeliveryGateway` at
   `lib/features/nabi/application/notifications/nabi_notification_controller.dart:310-326`.
   Navigation therefore returns `false` and native schedule/cancel perform no
   action.
6. The bundled local analytics repository returns `0` from `drainPending` at
   `lib/features/nabi/data/notifications/nabi_notification_local_repositories.dart:267-272`.
   The comment itself states that a remote authenticated adapter is opt-in;
   none is wired by the unified runtime.
7. A different, legacy mascot exists in the running application:
   `NabiFloatingOverlay` is mounted from V1 dashboard/menu pages at
   `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart:314-317`
   and `.../menu_page.dart:157-161`. It is not `NabiAppShell` or the M30
   notification controller and is not evidence that an M30 notification was
   triggered.

## Result

The repository contains a catalog and isolated M30 engine/controller code, but
the unified application neither subscribes business state to the controller nor
mounts the M30 presentation shell. Its default CTA, native-delivery and remote
analytics paths are no-ops. Consequently no notification ID can be truthfully
triggered, rendered, delivered, deep-linked, retried, or remotely observed from
`lib/main.dart`.

This is an implementation/integration failure for NBI-001 through NBI-024, not
a Draft-only Advanced Health gap. No device PNG is supplied because there is no
M30 surface to capture without fabricating a result. The separately visible V1
mascot must not be substituted for M30 evidence.

## Terminology handling

For annual/package scenarios, Product Flow M06 remains the entitlement/quota
oracle. Older Nabi wording such as VIP/annual is a documentation terminology
gap only; it does not cause the failures above and does not make a missing M30
runtime integration acceptable.
