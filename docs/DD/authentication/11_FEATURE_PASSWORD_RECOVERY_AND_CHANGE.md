# DD-AUTH-FR-09 - Quên mật khẩu và đổi mật khẩu

**BD nguồn:** AUTH-FR-09  
**Dependencies:** `14_FLUTTER_LAYER_CONTRACTS.md`

## 1. Quên mật khẩu

### Input

Email; app validates basic format then calls Supabase password recovery API with approved deep-link redirect.

### Flow

```text
Forgot Password page
→ submit email
→ Supabase sends recovery link subject to rate limit
→ user opens deep link
→ app receives recovery session/event
→ Reset Password page
→ new password + confirm
→ Supabase Auth update password
→ success → login/AuthGate
```

### Security rules

- Response must be generic enough not to enumerate registered emails.
- Recovery token is controlled by Auth; never persist it in `public` tables, app logs or analytics.
- Deep link must be allow-listed.
- New password is never placed in controller state longer than needed and never persisted.

## 2. Đổi mật khẩu khi đã đăng nhập

- Require valid authenticated session.
- Product may require recent login/re-authentication before sensitive update.
- Call Supabase Auth password update API.
- On provider/session requirement error, guide user through sign-in/recovery; do not handle with custom database write.

## 3. UI states

`idle`, `submitting`, `emailSent`, `recoverySessionReady`, `passwordUpdated`, `rateLimited`, `failure`.

## 4. Acceptance

TC-AUTH-27 đến TC-AUTH-30.
