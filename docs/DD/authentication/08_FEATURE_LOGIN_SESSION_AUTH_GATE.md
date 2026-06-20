# DD-AUTH-FR-05/06 - Đăng nhập, khôi phục session và AuthGate

**BD nguồn:** AUTH-FR-05, AUTH-FR-06  
**Dependencies:** `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`, `07_FEATURE_EMAIL_VERIFICATION.md`, `14_FLUTTER_LAYER_CONTRACTS.md`

## 1. Mục tiêu

Đăng nhập bằng email/password, khôi phục session khi mở app và điều hướng duy nhất qua AuthGate dựa trên session, email verification và `onboarding_status`.

## 2. Login command

```dart
Future<AuthSessionResult> signInWithEmail({
  required String email,
  required String password,
});
```

Không nhận/cached `userId` từ form hoặc local storage tùy ý. UUID hợp lệ phải đến từ `supabase.auth.currentUser`/session.

## 3. AuthGate decision algorithm

```text
1. Subscribe/read auth session state.
2. session == null → Welcome/Login.
3. user == null → Welcome/Login.
4. If confirm-email policy requires and user.emailConfirmedAt == null → VerifyEmail.
5. Query public.users where id = currentUser.id using RLS.
6. Profile absent → ProfileBootstrapUnavailable state; do not client-insert.
7. onboarding_status in {not_started, in_progress} → resume Onboarding.
8. onboarding_status == completed → Dashboard.
9. Any unknown status → safe failure state and report monitoring event.
```

## 4. State model

| State | Meaning | Route/UI |
|---|---|---|
| `initializing` | restoring persisted session | splash/loading |
| `unauthenticated` | no valid session | welcome/login |
| `emailVerificationRequired` | session but email not confirmed | verify email |
| `onboardingRequired` | base profile exists but status pending | onboarding |
| `authenticatedReady` | session + confirmed + completed | dashboard |
| `profileBootstrapUnavailable` | unexpected missing base rows | friendly temporary support state |
| `failure` | auth/query connectivity failure | retry screen |

## 5. Login post-actions

- On successful sign-in, update `public.users.last_login_at = now()` only after AuthGate has a valid current user.
- Do not use last-login write as a condition for routing. A harmless update failure must not block access where profile is valid.
- Load only minimal `public.users` fields needed for route; defer dashboard queries until route is resolved.

## 6. Security and error response

- Credential failure: one neutral message; no user enumeration.
- Session expired/revoked: clear local state and route login.
- RLS denial for profile read: treat as data/config error, not as “user has no profile”; report observability event without sensitive payload.
- Never trust an old locally stored `onboarding_status` for final route.

## 7. Acceptance

TC-AUTH-11 đến TC-AUTH-17.
