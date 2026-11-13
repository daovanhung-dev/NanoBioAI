# Worklog — Flutter web parity foundation

**Date:** 2026-11-14  
**Task:** Implement the approved phone-first Flutter Web/PWA parity plan.  
**Scope:** Consumer app, shared active V1/V2/V3 flows, M09 Web Push backend, M13 web checkout, M31 browser foreground monitoring.

## Changes

- Kept consumer routes as the web entry point. Direct `/admin` now opens a
  configured HTTPS Admin Web destination, leaving the Admin app on its
  separately hosted surface.
- Added browser SQLite through IndexedDB, a single-tab Web Lock, generated
  SQLite worker/WASM files, and PWA metadata.
- Added guest Web Push subscription and reminder APIs, capability hashing,
  endpoint validation, minimal reminder metadata, generic push copy, a worker
  timer/service, and a M31 scheduled arming reminder route. Runtime VAPID values
  are examples only; no live secret or production deployment was changed.
- Added the web membership transfer screen using server-owned VietQR details,
  confirmation and pending-review refresh. Native Google Play behavior remains
  selected outside web.
- Routed onboarding and AI voice input to local Whisper WebAssembly in a worker
  on secure cross-origin isolated pages. Captured audio remains in browser
  memory; touch/text fallback remains available when the local runtime cannot
  start.
- Added browser Sleep Safety audio feature extraction using the existing
  controller/session flow. The web monitor stops when the user leaves its screen
  or the page is hidden/paused, shows an explicit disclosure, and requires a user tap before opening
  `tel:`. It cannot provide native all-night/background monitoring.
- Updated module DD notes, the coding checklist, and this worklog with the
  platform-specific behavior and remaining acceptance work.

## Verification

- Targeted `flutter analyze` on 27 changed Flutter source files: PASS.
- `flutter build web --release --no-pub --no-wasm-dry-run
  --output-dir=/tmp/nanobio-web-release-final3`: PASS (release build completed;
  includes app, SQLite worker/WASM, PWA headers and Web Push worker).
- Final targeted `flutter analyze` on the reminder coordinator and local voice
  gateway: PASS after fixing the browser build type error and voice fallback copy.
- Backend Web Push Ruff checks, Ruff format check, and `mypy src/nanobio_backend`:
  PASS.
- Earlier in this implementation, the focused Web Push pytest suite passed
  (4 tests), and Alembic migration `0008_web_push` upgraded a temporary SQLite
  database to head. The final worker deep-link adjustment was followed by
  static checks, not a rerun of pytest.
- Browser UI, microphone, local model download, push delivery, installed iOS PWA,
  payment bank-app handoff, and Android/iOS native acceptance were not exercised.

## Remaining deployment and acceptance work

- Configure VAPID public/private keys and subject, apply migration `0008_web_push`,
  install/enable the systemd worker and timer, and verify push delivery and click
  navigation on desktop Chrome, Android Chrome, and installed iOS Safari PWA.
- Configure the production static host to return COOP/COEP headers for local
  Whisper WebAssembly. Hosts that do not honor `web/_headers` must set the same
  response headers in their own server configuration.
- Verify Chrome Android, desktop Chrome and latest iOS Safari/PWA for responsive
  routes, IndexedDB reopen, permissions and local voice fallback, foreground
  Sleep Safety stop, payment state refresh, and notifications.
- Web Sleep Safety remains foreground-only by design; loss of page foreground
  ends the session. This limitation is shown in the user-facing screen.
- The repository's referenced `backend/project/INDEX.md` and Web Push module
  note are absent in this checkout; API/schema/operations detail is recorded in
  the canonical M09 implementation delta and this worklog.

## Self-review

- No Admin surface was merged into the consumer app and no planned/placeholder
  module was added.
- Push messages contain generic copy and a safe route; names, health details,
  titles and message bodies are not sent to the push service.
- Browser voice uses local Whisper for audio input; the backend receives only
  the recognized text through the existing voice turn path.
- Source/build evidence does not establish 100% runtime parity or production
  readiness. Browser/device, backend deployment, VAPID and bank acceptance are
  outstanding.
