# DD-AUTH-FR-04 - Xác thực email

**BD nguồn:** AUTH-FR-04  
**Dependencies:** `04_FEATURE_REGISTRATION.md`, `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md`, `14_FLUTTER_LAYER_CONTRACTS.md`

## 1. Mục tiêu

Khi Confirm Email bật, account chỉ được xem là usable sau khi người dùng mở link verification và Auth xác nhận email. Profile baseline vẫn có thể đã được trigger tạo, nhưng AuthGate phải chặn Dashboard khi email chưa confirmed.

## 2. Cấu hình Supabase cần có

- Confirm email enabled theo environment policy.
- Redirect URL/deep link được khai báo allow-list tại Supabase Auth.
- Mobile app xử lý inbound auth deep link và refresh session/state sau redirect.
- Email template không lộ dữ liệu sức khỏe hoặc secret.

## 3. Flow

```text
Registration success
→ VerificationRequired screen
→ user opens email link
→ Supabase Auth validates token
→ deep link returns to app
→ app refreshes current user/session
→ email_confirmed_at exists?
  ├─ no: keep VerificationRequired
  └─ yes: AuthGate decides Onboarding/Dashboard
```

## 4. UI contract

Verification screen phải có: email masked or displayed safely, instruction, resend button with cooldown, “đổi email/đăng nhập lại” route hợp lý, retry state sau deep link.

Không hiển thị raw token, provider exception, server stack trace hoặc thông tin user khác.

## 5. Resend behavior

- Chỉ gọi resend khi cooldown hết.
- Nếu rate-limited, hiện thông điệp thân thiện, không cho auto retry loop.
- Không reset `onboarding_status` chỉ vì resend verification.

## 6. Route guard

Priority logic:

1. Không có session → Welcome/Login.
2. Có session nhưng email chưa confirmed (và policy requires confirm) → Verify Email.
3. Email confirmed + onboarding pending → Onboarding.
4. Email confirmed + completed → Dashboard.

## 7. Acceptance

TC-AUTH-08 đến TC-AUTH-10.
