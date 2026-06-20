# DD-AUTH-TEST-001 - Test, acceptance và traceability

## 1. Test matrix

| ID | Requirement | Scenario | Expected result |
|---|---|---|---|
| TC-AUTH-01 | FR-01 | valid sign-up with confirm email off | Auth user + 3 baseline rows; route onboarding |
| TC-AUTH-02 | FR-01/02 | valid sign-up with confirm email on | baseline rows exist; route verify email |
| TC-AUTH-03 | FR-01 | invalid local input | no network request; field errors |
| TC-AUTH-04 | FR-01 | duplicate email | safe provider error mapping; no data duplication |
| TC-AUTH-05 | FR-02 | trigger failure simulation | no orphan Auth user/profile partial state |
| TC-AUTH-06 | FR-02 | retry/idempotent bootstrap | exactly one health + habits row |
| TC-AUTH-07 | FR-03 | create user via Dashboard | same baseline profile result |
| TC-AUTH-08 | FR-04 | unverified user signs in | verification route, no Dashboard |
| TC-AUTH-09 | FR-04 | verification deep link returns | AuthGate refreshes and routes onboarding/dashboard |
| TC-AUTH-10 | FR-04 | resend cooldown/rate limit | button state and friendly error correct |
| TC-AUTH-11 | FR-05 | valid login + completed profile | Dashboard |
| TC-AUTH-12 | FR-05 | valid login + pending onboarding | Onboarding resume |
| TC-AUTH-13 | FR-05 | invalid credentials | generic error, no account enumeration |
| TC-AUTH-14 | FR-06 | app restart with valid session | AuthGate restores correct route |
| TC-AUTH-15 | FR-06 | session expired | login route and scoped cache cleared |
| TC-AUTH-16 | FR-06/12 | missing public profile | support/retry state; no client insert |
| TC-AUTH-17 | FR-06 | last_login update fails | route still works |
| TC-AUTH-18 | FR-07 | start onboarding | status becomes `in_progress` |
| TC-AUTH-19 | FR-07 | partial save then restart | resume pending state |
| TC-AUTH-20 | FR-07 | final valid save | status completed + timestamp + Dashboard |
| TC-AUTH-21 | FR-07 | invalid final form | status remains pending |
| TC-AUTH-22 | FR-07 | unselected optional data | no blank collection records |
| TC-AUTH-23 | FR-07 | user A attempts user B data | RLS denies operation |
| TC-AUTH-24 | FR-08 | update health profile | existing row updated, not inserted |
| TC-AUTH-25 | FR-08 | update email/password through public table | impossible; use Auth flow |
| TC-AUTH-26 | FR-08 | stale/missing session during update | safe failure + route reevaluation |
| TC-AUTH-27 | FR-09 | send recovery for valid format | generic email-sent state |
| TC-AUTH-28 | FR-09 | recovery deep link | reset password screen accepts flow |
| TC-AUTH-29 | FR-09 | mismatched new passwords | no API request |
| TC-AUTH-30 | FR-09 | password success | no public password data written |
| TC-AUTH-31 | FR-10 | sign out | auth/session + user-scoped cache removed, cloud data stays |
| TC-AUTH-32 | FR-11 | delete request without valid JWT | rejected server-side |
| TC-AUTH-33 | FR-11 | confirmed account deletion | auth user and all personal rows cascade delete |
| TC-AUTH-34 | FR-11 | client calls privileged Admin API | impossible/no key exposed |
| TC-AUTH-35 | FR-12 | backfill old users | all old Auth accounts get base rows only |

## 2. RLS smoke test two-account

1. Create User A and User B.
2. Sign in A; create or update A profile/log data.
3. Attempt query/update/delete by B using A's ID via client request.
4. Expect zero returned/affected rows or policy denial.
5. Verify catalogs can be read by both authenticated users but cannot be written by either client.

## 3. Definition of Done

- [ ] All test cases relevant to changed feature pass.
- [ ] SQL integrity query shows no baseline profile gaps.
- [ ] RLS two-user smoke test passes.
- [ ] No credentials/service-role tokens appear in source, logs or artifacts.
- [ ] Worklog, feature/fixbug/test documents created according to project workflow.
- [ ] `flutter analyze` and targeted tests pass in project environment.

## 4. Traceability

Every code PR/commit should mention affected DD ID and test IDs, for example: `feat(auth): implement DD-AUTH-FR-01 (TC-AUTH-01..04)`.
