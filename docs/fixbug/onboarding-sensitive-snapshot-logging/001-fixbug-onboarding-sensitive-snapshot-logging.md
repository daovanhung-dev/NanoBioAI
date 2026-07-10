Commit de xuat: fix(onboarding): chan log snapshot nhay cam

# Fixbug - Onboarding sensitive snapshot logging

## Tom tat

- Issue/todo cu ghi nhan rui ro onboarding log raw snapshot ho so suc khoe/PII
  sau khi save.
- Source hien tai khong con block query va in raw SQLite snapshot, nhung
  `AppLogger` van bat co dinh trong moi build.
- Fix nay dong contract bang release logging gate va them regression test o
  datasource that de ngan tai xuat log raw PII/snapshot.

## Cach sua

- Doi `AppLogger` sang `kDebugMode`, nen release build khong phat debug logs.
- Them test `OnboardingLocalDatasource` capture `debugPrint` khi save entity co
  email, phone, ten, allergy/treatment/note/concern nhay cam va assert log
  khong chua raw PII, `ONBOARDING SAVED TO SQLITE`, `snapshot`, `User ID`.
- Giu test controller hien co khong log raw onboarding PII.

## Kiem chung

- `flutter test test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS.
- `dart analyze lib/core/utils/logger/app_logger.dart lib/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS.
- `rg "ONBOARDING SAVED TO SQLITE|User ID|debugPrint\\(|jsonEncode|jsonEncode\\(|snapshot" ...`: source-only khong thay raw snapshot log; `jsonEncode(model.habits)` con lai la du lieu luu DB, khong phai logging.

## Gioi han

- `AppLogger.error` van co the in error object/stack trong debug/test build.
  Cac flow tiep theo can tiep tuc thay raw error bang safe error name khi error
  co kha nang chua PII.
