# Biometric Service

Lifecycle: `Current source note`. Implementation: `Source-only` at baseline
`25018e8`.

`BiometricService` wraps `local_auth` and exposes:

- `isAvailable()` — checks `canCheckBiometrics` and device support.
- `authenticate(reason)` — biometric-only authentication with sticky auth.
- `getAvailableBiometrics()` — returns the enrolled biometric types reported
  by the plugin.

Platform permissions/descriptions exist in AndroidManifest and iOS Info.plist.
However, no source outside `lib/services/biometric/` constructs or calls
`BiometricService` at this baseline. It is therefore not an active login or
Settings capability and must not be documented as one.

## Error contract

`BiometricException` carries a safe message and optional platform error code.
Known `local_auth` states such as not available, not enrolled, missing
passcode, locked out and permanently locked out are mapped explicitly. User
cancellation/authentication failure may return `false`.

## Activation requirements

Before changing status to `Implemented`:

1. Add a reachable provider/controller consumer.
2. Define whether the biometric protects local UI only or participates in auth.
3. Keep Supabase session/identity as the trusted account source.
4. Add unit/widget tests and real-device Android/iOS verification.

Device behavior is `UNVERIFIED` by static inspection.
