# Import File — NABI_COMPANION_NOTIFICATIONS

## Dependency rules

`Presentation → Provider/Controller → Use case → Repository → Datasource/DAO/API`.
Domain/application code must not import Flutter widgets, sqflite, Supabase client or
`BuildContext`. Remote config cannot provide executable rules or raw deep links.

## Planned file map

| Path | Layer/responsibility | May import | Must not import |
|---|---|---|---|
| `lib/features/nabi/domain/notifications/` | typed entities/policies | Dart core/domain | Flutter/DB/network |
| `lib/features/nabi/application/notifications/` | evaluation, claim, delivery orchestration | domain/repository contracts | widgets/DAO/client |
| `lib/features/nabi/data/notifications/` | repositories, SQLite/Supabase mapping | datasource/DAO/client | presentation |
| `lib/features/nabi/presentation/` | overlay/controllers/providers | application/domain/theme | DAO/raw clients |
| `lib/app_versions/v1/services/notifications/` | shared native bootstrap/envelope dispatch | M30 gateway contracts | M30 business policy |
| `lib/app_versions/v2/features/membership_entitlement/` | trusted billing period/access snapshot | membership datasource | M30 presentation |
| `docs/supabase/config.sql` | rebuildable schema/RLS/RPC/seed | PostgreSQL | secrets/production data |

## Public contracts

- `NabiBusinessEvent`, `NabiNotificationDefinition`, `NabiNotificationOccurrence`
- `NabiNotificationDestination`, `NabiUiContext`, `NabiEligibilityDecision`
- `NabiNotificationConfigRepository`, `NabiNotificationStateRepository`
- `NabiNotificationAnalyticsRepository`, `NabiNativeDeliveryGateway`
- `NabiNavigationGateway`, `NabiBusinessEventBus`

## Existing integrations

- Reuse `flutter_local_notifications 19.5.0`, timezone initialization, notification
  navigation coordinator and safe background bootstrap from M09.
- Reuse shared Nabi animation assets and consolidate v1 consumers through compatibility exports.
- Use dedicated M30 RPC/outbox; do not add M30 state to the generic user snapshot replacement.
- Supabase remains source of truth for membership/payment/reward/invite; local data is cache/offline state.

## Validation map

- `test/features/nabi/notifications/`: engine/catalog/repository/controller/widget.
- `test/core/storage/localdb/`: fresh DB and v14→v15 migration.
- `test/services/notifications/`: envelope routing/M09 regression.
- `test/docs/`: Supabase config/RLS/RPC contracts.

