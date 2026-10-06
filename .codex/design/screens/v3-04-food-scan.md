# V3-04 — Food Scan

- Classification: `active-route` — `V3RoutePaths.foodScan`
- Group: `10_v2_v3_membership`
- Source: `lib/app_versions/v3/features/food_scan/presentation/pages/food_scan_page.dart`
- Primary job: scan or select a food image, review the resulting nutrition estimate and explicitly accept any proposed update.
- Presentation order: access/consent status → capture or image selection → processing → review → explicit user action.
- States: access loading/locked/error, consent required, camera/gallery permission, processing, no result, ready estimate, retryable failure and history access.
- Design: make estimates visibly provisional until reviewed; maintain privacy and camera affordance clarity; fit compact screens and large text.
- Guardrails: preserve consent, access, provider, image lifecycle, AI and confirmation boundaries. Never imply medical diagnosis or silently save a generated estimate.
- Verification: route added to current-source inventory 2026-10-06; render/device certification pending.
