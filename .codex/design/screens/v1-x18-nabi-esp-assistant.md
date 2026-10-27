# V1-X18 — Nabi - Siêu trợ lý AI kết nối ESP

> Classification: **release-gated placeholder** · Group: `03_dashboard_health` · Platform: Android entry only.

## Purpose

Show the proposed local-AI-to-OSTB experience and explain its prerequisites. This preview remains intentionally inactive until technical, QA, and privacy reviews are recorded.

## Entry and access

- Entry: Feature Hub → collapsed “Sắp ra mắt” → “Nabi - Siêu trợ lý AI”.
- The tile is shown on Android only; iOS does not show an active entry.
- Guest, Free, Plus, and FamilyPlus may open the preview. No sign-in or quota applies to the proposed ESP feature; this does not change AI Voice access.
- Route: `/nabi-esp-assistant`.

## Current state

- Clearly states that review is pending and hotspot, Bluetooth, and audio are not active.
- Shows planned local AI, private LAN connection, and one-time USB firmware preparation.
- The “Kết nối Nabi” button is visibly disabled; permissions, device scan, server, model load, microphone, audio, or secret is not activated.
- Back navigation returns to the previous Feature Hub state.

## Visual and accessibility contract

- Use Blue Wellness semantic colors and standard theme spacing/radius; no local palette.
- Use a scrollable single-column information card that fits 320 dp width and increased text scale.
- Status is conveyed in copy, not color alone. Screen-reader order follows heading, review state, three prerequisites, and next-step summary.
- No decorative looping motion or audio cue.

## Future acceptance

- After reviews, the tile may move from planned preview to the approved runtime-backed section only after the actual connection route is implemented and Android/ESP evidence exists.
- Until then, preserve the exactly 19 active runtime-backed Feature Hub shortcuts.
