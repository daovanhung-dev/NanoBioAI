# Professional Observability & Bug Logging

Date: 2026-08-24
Work type: coding / cross-cutting observability

## Objective

Replace the fragmented terminal logging behavior with one privacy-safe structured logging pipeline that can surface actionable evidence while running the Flutter application. The implementation covers framework and uncaught errors, Riverpod failures, navigation breadcrumbs, HTTP request/response/error timing, Supabase transport/auth operations, SQLite lifecycle/migration/integrity failures, and Gemini AI HTTP/trace activity.

## Implementation

- Rebuilt `AppLogger` as the single application logging facade with structured level, category, scope, operation, correlation id, duration, metadata, error type, and sanitized stack trace fields.
- Added centralized privacy redaction for secrets, authentication material, PII, health data, prompts/payloads/responses, URLs, and oversized values.
- Added a terminal sink as the only production output boundary.
- Added `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and root-zone capture.
- Added a Riverpod `ProviderObserver` for provider failures.
- Added a legacy `print` / `debugPrint` bridge so remaining legacy output is routed through the structured pipeline during migration.
- Added reusable Dio request/response/error instrumentation with correlation ids and timings.
- Attached Dio logging to both the core network provider and Gemini's internal Dio paths, including SSE streaming requests.
- Added an `http.BaseClient` wrapper for Supabase transport instrumentation and disabled Supabase's duplicate debug logger.
- Added SQLite open/configure/create/upgrade/integrity/delete/close tracing while preserving the existing schema and migration behavior.
- Added privacy-safe Supabase Auth operation tracing.
- Routed `AITraceLogger` through the central logger while preserving allowlisted AI metadata and stack traces.
- Added V2 and Admin navigation observers plus redirect reason breadcrumbs.
- Added tests for privacy/redaction, global Flutter error capture, Dio logging, Gemini private-Dio logging, and a repository architecture guard against raw production logging.

## Data / contract impact

- No SQLite schema change.
- No Supabase schema, RLS, RPC, seed, payment, membership, or access-rule change.
- No business-flow change intended.
- No third-party crash analytics service added.
- Added direct `http` dependency because the Supabase transport logger directly imports `package:http`.

## Validation performed in this environment

- Verified the delivery tree contains only task-related new/modified project files.
- Scanned task production files for direct `print`, `debugPrint`, and `developer.log`; only the intentionally whitelisted terminal sink contains the final `developer.log` output call.
- Verified Gemini's private request and streaming Dio paths are attached to the shared interceptor.
- Checked project YAML parseability and basic Dart delimiter/string balance with local static scripts.
- Checked for merge-conflict markers and patch artifacts.

## Environment limits

The execution container for this delivery does not provide `flutter` or `dart`, so `dart format`, `flutter analyze`, and `flutter test` could not be executed here. The included architecture test is designed to scan the complete real checkout when the ZIP is applied to the repository; the delivery working tree itself intentionally contains only new/modified files rather than a full repository checkout.
