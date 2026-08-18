# M04 Change Log — 2026-08-18

## Added

- Read-only `BodyMetricsHealthSnapshot`.
- Historical 7d/30d tracking/nutrition/schedule aggregation.
- 60 deterministic metric registry.
- Trend calculator and group-based data quality/freshness engine.
- Trusted Free/Plus/FamilyPlus access reader.
- 5-stage Free/Guest and 15-stage Paid Nabi analysis pipeline.
- Typed stage validation and partial-failure behavior.
- Read-only health dashboard UI and 7d/30d trend visualization.
- Targeted unit tests for metrics, trends, AI safety, pipeline count and current subject scoping.

## Changed

- Body Metrics no longer treats storage recency as identity.
- Body Metrics no longer lets the user edit profile data inline.
- AI is no longer the numeric source of truth.
- Feature Hub copy changes from `Chỉ số cơ thể` to `Sức khỏe của bạn`; route remains unchanged.

## Not changed

- SQLite schema/version.
- `/body-metrics` route.
- Advanced Health clinical classification rules.
