# M09 Web Push Implementation Delta — 2026-11-14

## Scope

Adds browser delivery for the existing schedule/reminder categories. Native
Android/iOS notification scheduling and actions remain unchanged. The web
client stores its reminder IDs, category and schedule locally; the backend
stores the browser push endpoint, push keys, timezone and matching schedule
metadata. It receives no reminder title/body or health details.

## Contract

| Operation | Contract |
|---|---|
| `GET /api/v1/web-push/config` | Returns enabled state and public VAPID key only. |
| `POST /api/v1/web-push/subscriptions` | Guest creates a subscription; response includes an opaque capability. Endpoint host is restricted to known push services. |
| `PUT /api/v1/web-push/subscriptions/{id}/reminders` | Capability-protected replacement of timezone and minimal reminder metadata. |
| `DELETE /api/v1/web-push/subscriptions/{id}` | Capability-protected unsubscribe; related reminders are removed. |

The client keeps the capability in browser preferences. The server persists
only its SHA-256 digest. Push messages always use generic copy and open the app
root; event-specific names and content stay out of the push payload. The
`sleep_safety` category opens `/sleep-tracking?source=scheduled_reminder` and
never starts monitoring; the user must explicitly start a session.

## Delivery and operations

- Alembic migration `0008_web_push` creates subscription/reminder tables and
  due indexes.
- `nanobio-web-push.timer` starts the worker every minute. The worker sends
  due one-shot and daily reminders using VAPID and disables expired endpoints.
- Runtime setup must provide `WEB_PUSH_VAPID_PUBLIC_KEY`,
  `WEB_PUSH_VAPID_PRIVATE_KEY`, and `WEB_PUSH_VAPID_SUBJECT`, apply the
  migration, and install/enable the worker and timer.
- Web Push requires HTTPS and a browser that supports service workers and Push.
  iPhone users must install the web app to the Home Screen for supported push.
- Browser permission, actual delivery, click-through, iOS installation and
  server deployment acceptance are pending; no production configuration was
  changed in this delta.
