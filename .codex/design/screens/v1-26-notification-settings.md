# V1-26 — Notification Settings

- Classification: `active-route` — `V1RoutePaths.notificationSettings`
- Group: `09_auth_profile_settings`
- Source: `lib/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart`
- Primary job: understand and change reminder preferences with clear system-permission status.
- Presentation order: current permission state → reminder categories → timing/details → save or system-settings action.
- States: loading, error/retry, denied permission, unavailable permission, enabled/disabled preferences, saving, success and failure.
- Design: bounded 640 dp content, concise explanatory copy, state icon plus text, aligned controls and separators; no ambiguous full-card tap targets around nested controls.
- Guardrails: preserve provider calls, permission requests, preference defaults and save behavior; do not request OS permission merely by opening the screen.
- Verification: focused widget/theme checks passed; Xiaomi interactive/device proof pending to avoid changing local preferences.
