# sleep-safety-provider-webhook

Provider callback endpoint for M31. The provider must send `x-sleep-safety-token` matching `SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET` and a payload containing provider `id` and `status`.

Terminal `failed`/`no_answer` callbacks continue the contact cascade without requiring the sleeping user's device to be online: voice failure falls back to SMS for the same verified contact, then the next verified priority is tried. Successful/submitted states only update dispatch evidence.
