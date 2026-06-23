Commit de xuat: fix(dashboard): phan biet zero score va missing score input

# Fixbug - Health score zero inputs

## Summary

- Bug: v1 dashboard dung `dailyScore == 0` de hien thi trang thai chua du du lieu.
- Impact: Ngay co lich that su nhung chua hoan thanh task/meal nao bi hien thi nhu chua co input score.
- Scope: v1 dashboard daily care score va v2 health scoring placeholder; khong implement cong thuc v2 official vi DD Q-05 van open.

## Root Cause

- `DashboardDailyMetrics.dailyScore` co the bang `0` trong hai truong hop khac nhau:
  - Khong co task/meal/water/sleep/nutrition input de tinh score.
  - Co input that nhung tien do hien tai bang 0%.
- Score panel chi kiem tra `score == 0`, nen hai truong hop bi tron voi nhau.

## Fix

- Them `DashboardDailyMetrics.hasDailyScoreInputs` de tach input presence khoi score value.
- Score panel chi hien `--` khi `hasDailyScoreInputs == false`.
- Neu co input that va score bang `0`, UI hien `0` cung copy Nabinhe nhang.
- `V2HealthScoringFeature` ghi ro v1 local daily care score khong phai cong thuc v2 official.

## Evidence

- `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart`:
  - no score inputs -> `dailyScore == 0`, `hasDailyScoreInputs == false`.
  - today task/meal inputs with zero progress -> `dailyScore == 0`, `hasDailyScoreInputs == true`.
- `test/features/dashboard/domain/dashboard_companion_service_test.dart`:
  - empty metrics giu missing-data copy.
  - zero score with inputs dung supportive copy.

## Validation

- `flutter test test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart test/features/dashboard/domain/dashboard_companion_service_test.dart`: PASS.
- `flutter analyze`: PASS.
- `flutter test`: PASS - 309 tests pass.

## Remaining

- V2 official health scoring formula, weights, skip/miss handling, and UI policy remain blocked by DD Q-05.
- Free quota, membership entitlement, FamilyPlus, and Sale/referral remain planned/blocked by DD decisions and Supabase verification.
