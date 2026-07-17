# Function List — NABI_COMPANION_NOTIFICATIONS

## Registry

| ID | Function | Layer | Input → output | Side effect |
|---|---|---|---|---|
| `...-FN01` | `refreshDefinitions` | Use case | actor/app version → active definitions | cache update |
| `...-FN02` | `evaluateEligibility` | Pure policy | definition + snapshots + history + UI context → decision | none |
| `...-FN03` | `claimHighestPriority` | Use case/repository | eligible candidates → occurrence | atomic local/remote claim |
| `...-FN04` | `composeNabiPresentation` | Provider | visual + notification state → presentation | none |
| `...-FN05` | `deliverOccurrence` | Use case/adapter | occurrence + lifecycle/preferences → channel result | bubble/native schedule |
| `...-FN06` | `recordInteraction` | Use case | occurrence + action → state | local state + event outbox |
| `...-FN07` | `resolveDestination` | Gateway | allowlisted destination + actor → navigation result | navigation/return intent |
| `...-FN08` | `invalidateForAccessChange` | Use case | trusted access/payment event → cancelled/converted | cancel native + clear queue |
| `...-FN09` | `drainAnalyticsOutbox` | Job/repository | opted-in pending events → acknowledgement | RPC batch/retry/expiry |

## Core contracts

`evaluateEligibility` is deterministic and clock-injected. It validates audience,
effective window, dynamic values, trigger snapshot, terminal state, session/day/rolling
caps, cooldown, quiet hours and UI suppression. It returns a typed blocked reason;
it never writes or navigates.

`claimHighestPriority` sorts by BR01, writes an occurrence keyed by actor + notification
+ source event + content version, and returns an existing claim on idempotent replay.

`deliverOccurrence` presents only one current bubble. Local native delivery uses a stable
M30 integer ID, generic safe body, occurrence/config version/action key payload and no
health/question content. Foreground deduplicates the same occurrence.

`recordInteraction` enforces the state machine. `deferred` sets `nextEligibleAt +24h`;
network action failure remains retryable; background callback only stores the event.

`resolveDestination` accepts only registered action keys and typed params. It revalidates
auth/access at open time and uses dashboard/membership fallback for invalid resources.

## Error contract

| Code | Behavior |
|---|---|
| `config_invalid` | fail closed, retain last valid cache, safe metric |
| `not_eligible` / `suppressed` | no presentation or native schedule |
| `claim_conflict` | reuse winning occurrence, no duplicate event |
| `offline` | keep local state/outbox and allow retry |
| `destination_invalid` | safe fallback and `nabi_notification_failed` |
| `permission_denied` | in-app remains; native attempt is terminal until preference changes |

