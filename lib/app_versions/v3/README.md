# V3 App Version

Lifecycle: `Current`. Baseline: `25018e8`.

V3 là lớp Plus/FamilyPlus trong user router hợp nhất. V3 hiện có cả runtime
partial lẫn planned marker; không được mô tả toàn bộ folder là “đã triển khai”
hoặc toàn bộ là “placeholder”.

## Trạng thái

- `home`: `Placeholder`; route `/v3` hiển thị catalog “Sắp có”.
- `advanced_tracking` (M10): `Partial`; có paid access gate, SQLite repository,
  hydration roadmap, provider và route `/v3/advanced-tracking`.
- `familyplus` (M11): `Partial`; có trusted entitlement, Supabase repository,
  group/member context UI và route `/v3/familyplus`.
- `premium_ai`, `goal_roadmap`, `advanced_health_tracking`,
  `family_onboarding`, `family_members`, `family_schedule`: `Source-only`
  planned markers, không có route/consumer riêng.

M20-M29 không phải runtime implementation trong V3; chúng là coming-soon
catalog dưới `lib/shared/health_features/` với access UI ở V2.

## Guardrails

- Paid access phải đến từ effective access/trusted backend, không từ route,
  local flags hoặc hidden UI state.
- FamilyPlus cross-subject access phải dùng trusted family context và
  `SubjectAccessContext`.
- Không import lower-version presentation/controller chỉ để tái sử dụng logic.
- Route tồn tại không tự chứng minh paid access hoặc capability hoàn chỉnh.

Verification: static source only; Flutter/device/Supabase sandbox là
`UNVERIFIED` nếu không có command evidence riêng.
