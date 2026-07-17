# M30 diagrams

```text
Business event -> snapshot gateways -> eligibility policy -> atomic claim
              -> in-app bubble OR local OS schedule -> interaction/outbox
              -> optional Supabase analytics/state sync
```

```text
eligible -> queued -> presented -> collapsed/opened
         -> deferred/actioned -> converted
         -> expired/cancelled/failed
```

M09 and M30 share bootstrap/navigation primitives but keep distinct payload kind,
channel, integer ID namespace, state and business handlers.

