# BD Amendment — M31 response deadline and call handoff

> **Project:** NanoBio / NamiAI  
> **Document ID:** BD-NANOBIO-SLEEP-SAFETY-001  
> **Module:** M31 `SLEEP_SAFETY_MONITORING`  
> **Version:** 1.3  
> **Updated:** 2026-10-06  
> **Inherits:** `BD_NanoBio_Sleep_Safety_M31_v1.2.md`

## 1. Approved behavior delta

- This amendment supersedes the M31-BR06/07, M31-AC06, and Q-M31-04 timing
  decisions from v1.2 only; all other inherited M31 requirements remain active.
- Keep the alert open for 15 seconds. If the user has not responded by then,
  start the existing automatic voice/SMS escalation flow.
- Remove the former +30-second reminder. An explicit `OK` or `Need help`
  response cancels the no-response timer.
- `Need help` continues to use the highest-priority active phone-enabled
  contact locally and never invokes server dispatch.
- After Android accepts `ACTION_CALL` or `ACTION_DIAL`, or iOS accepts `tel:`,
  stop the alert tone and clear its notification without stopping the monitoring
  session. If the operating system rejects the handoff, keep the sound and
  alert active so the user can retry.
- A successful handoff records only that the operating system accepted the
  request; it does not confirm that the call connected or was answered.

## 2. Compatibility and safety boundary

- The change affects local response timers and phone handoff behavior only.
- Voice/SMS routing, contact priority, server contracts, persistence schema,
  permissions, call confirmation behavior, and iOS system confirmation remain
  unchanged.
- No automatic call to emergency services is introduced.
