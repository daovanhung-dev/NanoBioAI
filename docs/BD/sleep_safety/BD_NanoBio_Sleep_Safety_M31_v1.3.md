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
  call the highest-priority active contact who opted into phone calls, using
  the device phone app. The local timeout route does not depend on a server
  runtime flag.
- Remove the former +30-second reminder. An explicit `OK` or `Need help`
  response cancels the no-response timer.
- `Need help` continues to use the highest-priority active phone-enabled
  contact locally and never invokes server dispatch.
- On Android, use `ACTION_CALL` when `CALL_PHONE` is granted; otherwise, or if
  direct calling fails, open the prefilled dialer. On iOS, open `tel:` and let
  the operating system request confirmation when required.
- If no eligible contact exists or phone-app handoff fails, keep the alert
  active and guide the user to respond or call manually. Do not dispatch to the
  backend or enqueue a backend retry.
- After Android accepts `ACTION_CALL` or `ACTION_DIAL`, or iOS accepts `tel:`,
  stop the alert tone and clear its notification without stopping the monitoring
  session. If the operating system rejects the handoff, keep the sound and
  alert active so the user can retry.
- A successful handoff records only that the operating system accepted the
  request; it does not confirm that the call connected or was answered.

## 2. Compatibility and safety boundary

- The timeout change affects local response and phone handoff behavior; it no
  longer invokes the existing voice/SMS dispatch contract.
- Backend APIs, contact priority, persistence schema, the existing
  `escalation_status` enum, permissions, and iOS system confirmation remain
  unchanged. No new API or schema value is introduced.
- No automatic call to emergency services is introduced.
