# V1-22 — Health Check-in

- Classification: `active-route` — `V1RoutePaths.healthCheckIn`
- Group: `07_health_tracking`
- Source: `lib/app_versions/v1/features/health_check_in/presentation/pages/health_check_in_page.dart`
- Entry: Nabi prompt / health reminders / direct route.
- Primary job: record the user's current feeling and explicitly confirmed condition updates.
- Presentation order: short check-in prompt → feeling choice → condition updates → optional note → save action.
- States: loading, retryable load error, ready, no conditions, validation, saving and saved/error feedback. Do not imply diagnosis.
- Design: Blue Wellness for primary action; green only for positive health state. Use semantic roles, 48 dp targets, bounded content width, keyboard-safe scrolling and text-scale-safe labels.
- Guardrails: retain controller calls, actor-key initialization, fields, persistence and route behavior. Never submit on selection or show unconfirmed health status.
- Verification: current-source mapping refreshed 2026-10-06; render/device certification pending.
