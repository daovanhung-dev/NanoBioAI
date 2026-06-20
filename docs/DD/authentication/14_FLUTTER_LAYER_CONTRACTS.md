# DD-AUTH-CTR-001 - Kiến trúc Flutter và hợp đồng lớp

**Architecture rule:** `Presentation -> Provider/Controller -> Repository -> Datasource -> Supabase Auth/PostgreSQL`.

## 1. Suggested file boundaries

```text
lib/features/auth/
├── presentation/
│   ├── pages/
│   │   ├── welcome_page.dart
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── verify_email_page.dart
│   │   ├── forgot_password_page.dart
│   │   └── reset_password_page.dart
│   ├── controllers/auth_controller.dart
│   └── providers/auth_providers.dart
├── domain/
│   ├── entities/auth_user_entity.dart
│   ├── entities/auth_route_state.dart
│   └── repositories/auth_repository.dart
└── data/
    ├── datasources/supabase_auth_remote_datasource.dart
    ├── models/auth_user_model.dart
    └── repositories/supabase_auth_repository.dart

lib/core/router/auth_gate.dart
lib/features/profile/...                         # update profile/onboarding values
lib/features/cloud_sync/...                      # cloud health datasource/repository
```

Actual paths can follow project convention, but responsibilities must not cross layers.

## 2. Repository contract

```dart
abstract interface class AuthRepository {
  Stream<AuthRouteState> watchAuthRouteState();

  Future<RegistrationResult> signUpWithEmail(RegisterCommand command);
  Future<void> signInWithEmail(LoginCommand command);
  Future<void> resendEmailConfirmation(String email);
  Future<void> sendPasswordRecovery(String email);
  Future<void> updatePassword(UpdatePasswordCommand command);
  Future<void> signOut();
  Future<void> requestAccountDeletion();
}
```

`watchAuthRouteState()` is the single route-state source: it maps Auth session + email confirmation + `public.users.onboarding_status` to the states declared in `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md`.

## 3. Commands and result entities

- `RegisterCommand`: email, password, fullName?, phone?, acceptedTerms.
- `LoginCommand`: email, password.
- `UpdatePasswordCommand`: newPassword, confirmPassword.
- `RegistrationResult`: `verificationRequired` or `sessionReady`, without exposing token/password.
- `AuthRouteState`: unauthenticated, verifyEmail, onboardingRequired, ready, profileBootstrapUnavailable, failure.

## 4. Datasource responsibilities

| Datasource method | Allowed remote API | Notes |
|---|---|---|
| `signUp` | `supabase.auth.signUp` | sends display metadata only |
| `signIn` | `supabase.auth.signInWithPassword` | no direct profile insert |
| `getCurrentProfile` | `from('users').select()` | select row matching current auth user; RLS is authority |
| `touchLastLogin` | `from('users').update()` | best effort, not route-blocking |
| `updateProfile` | `users`, `health_profiles`, `lifestyle_habits` update | never insert base rows |
| `resetPassword` / `updatePassword` | Auth SDK | no public DB password field |
| `deleteAccount` | Edge Function invocation | no service role in app |

## 5. Auth controller rules

- Controller owns form state, loading, error mapping and route intent.
- Controller never imports `supabase_flutter` directly unless project architecture explicitly wraps it; use repository.
- Provider scope/cache must be disposed/reset on logout and auth user changes.
- UI strings use Nami tone; raw technical terms such as RLS/trigger/database are not shown to end users.

## 6. Router guard rule

Only AuthGate decides top-level route. Feature pages may request re-evaluation after an operation but must not bypass the status contract using direct `context.go('/dashboard')` after registration/onboarding without confirmed state.
