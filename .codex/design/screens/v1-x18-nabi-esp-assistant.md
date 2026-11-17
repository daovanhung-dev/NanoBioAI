# V1-X18 — Nabi - Siêu trợ lý AI kết nối ESP

> Classification: **Android debug pilot, release-gated** · Group: `08_features_care` · Platform: Android.

## Purpose

Configure an OSTB 3ST on the user's home Wi-Fi, then manage the linked device and its data-sharing consent. The route remains visible through Feature Hub → “Sắp ra mắt”; setup actions run only in Android debug until technical, QA, and privacy reviews are recorded.

## Entry and access

- Entry: Feature Hub → collapsed “Sắp ra mắt” → “Nabi - Siêu trợ lý AI”.
- The tile is shown on Android only; iOS does not show an active entry.
- The page can be opened while signed out; linking or managing a device requires a signed-in account. No chat quota applies because the ESP sends voice directly to the server.
- Route: `/nabi-esp-assistant`.

## Current state

- Requires a successful app login while the phone has Internet before the user joins the ESP's WPA2 `Nabi-xxxx` AP. Home Wi-Fi setup then uses the local AP only and does not require mobile data.
- The app stores the login credential encrypted in SQLite with its key in Android Keystore until logout. It sends home Wi-Fi and account credentials over HTTP on the WPA2 AP. ESP stores the account credential in NVS and authenticates to the backend over HTTPS; PostgreSQL keeps the existing Argon2 hash only.
- Android debug pilot enables setup; release builds keep setup and device-management actions locked. Voice/audio remains an ESP↔server flow after setup.
- Back navigation returns to the previous Feature Hub state.

## Visual and accessibility contract

- Use Blue Wellness semantic colors and standard theme spacing/radius; no local palette.
- Use a scrollable single-column information card that fits 320 dp width and increased text scale.
- Status is conveyed in copy, not color alone. Screen-reader order follows heading, review state, three prerequisites, and next-step summary.
- No decorative looping motion or audio cue.

## Future acceptance

- Before release, complete device firmware installation and acceptance, phone-to-AP setup, voice round trip, consent/revocation checks, and Tech/QA/Privacy sign-off.
