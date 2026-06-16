# Local Reminder Notifications - Task Checklist

Ngay tao: 2026-06-16

## Muc tieu

Chia nho task local reminder notifications de cac phien Codex sau co the lam tung phan nho, tranh bi ngat do model capacity. Feature can:

- Schedule local notifications cho meal plan va daily health tasks da duoc AI sinh sau onboarding.
- Moi notification co 2 action: `Da lam` va `Bo qua`.
- Luu moi action vao SQLite `notifications`.
- Neu `Da lam`, cap nhat ban ghi nguon:
  - `meal_plans.is_completed = 1`
  - `daily_health_tasks.current_value = target_value`, `is_completed = 1`

## Tinh trang hien tai

Da lam mot phan:

- Them dependencies trong `pubspec.yaml` va `pubspec.lock`:
  - `flutter_local_notifications: 19.5.0`
  - `timezone: 0.10.1`
  - `flutter_timezone: 5.1.0`
- Ly do version:
  - May hien dung Flutter `3.35.6` / Dart `3.9.2`.
  - `timezone 0.11.0` yeu cau Dart `^3.10.0`, nen dung `0.10.1`.
  - `flutter_local_notifications 22.0.1` yeu cau Flutter moi hon, nen dung `19.5.0`.
- DB da bat dau nang len v4:
  - `DatabaseVersion.currentVersion = 4`
  - `notifications` table them cot: `source_type`, `source_id`, `scheduled_at`, `notification_id`, `action_status`, `responded_at`, `payload`, `updated_at`
  - `MigrationManager` da co `_migrateToV4`
- `NotificationModel` da duoc mo rong day du field moi.
- `NotificationsDao` da co insert/update/query pending/delete pending co ban.
- `MealPlansDao` da co `getById`.
- `DailyHealthTasksDao` da co `getAll` va `getById`.
- Da tao helper files trong `lib/services/notifications/`:
  - `notification_constants.dart`
  - `notification_id_generator.dart`
  - `notification_payload.dart`
  - `reminder_defaults.dart`
  - `reminder_notification_scheduler.dart`
- Chunk `DB tests only` da hoan tat:
  - `MigrationManager.runMigrations` da chi chay migration khi `oldVersion < targetVersion <= newVersion`.
  - Them `test/core/storage/localdb/notification_model_test.dart`.
  - Them `test/core/storage/localdb/notifications_dao_test.dart`.
  - Mo rong `test/core/storage/localdb/migration_manager_test.dart` voi case v4 idempotent.
  - Da chay pass:
    - `flutter test test/core/storage/localdb/migration_manager_test.dart`
    - `flutter test test/core/storage/localdb/notification_model_test.dart`
    - `flutter test test/core/storage/localdb/notifications_dao_test.dart`
    - `flutter test test/core/storage/localdb`

Can luu y:

- `flutter pub add` bi exit code 1 do Windows chua bat Developer Mode/symlink support, nhung dependency va generated plugin registrants da bi cap nhat.
- `git status` dang co 3 file docs root bi delete, khong lien quan truc tiep task notification:
  - `AI_CHAT_QUICK_START.md`
  - `FEATURE_AI_CHAT_SUMMARY.md`
  - `bioai_readme_project_structure.md`
- Khong doc/copy noi dung `.env`.

## Checklist nho de tiep tuc

### 0. Pre-flight va lam sach pham vi

- [x] Chay `git status --short`.
- [ ] Xac nhan 3 deleted docs root co phai user muon xoa khong.
- [x] Neu khong lien quan, khong sua/khong revert cac file docs do.
- [x] Kiem tra `pubspec.yaml` co dung 3 dependency notification/timezone.
- [ ] Ghi chu trong final neu build/pub get bi chan boi Windows Developer Mode.

### 1. Hoan thien DB layer va tests

- [x] Tao/update tests cho `NotificationModel.fromMap/toMap`.
- [x] Tao tests cho `NotificationsDao`:
  - [x] insert + getAll
  - [x] getByNotificationId
  - [x] getPendingBySources
  - [x] deletePendingBySources
  - [x] updateActionStatus
- [x] Cap nhat `migration_manager_test.dart` them case v4:
  - [x] tao bang notifications kieu v3 cu
  - [x] chay migration len v4 2 lan
  - [x] expect cac cot moi chi xuat hien 1 lan
  - [x] expect indexes khong gay loi khi lap lai
- [x] Chay targeted tests cho DB/model neu co the.

### 2. Tao native notification bootstrap

- [ ] Tao `lib/services/notifications/notification_bootstrap.dart`.
- [ ] Implement `ReminderNotificationScheduler` bang `flutter_local_notifications`.
- [ ] Init timezone:
  - [ ] `tz.initializeTimeZones()`
  - [ ] lay timezone bang `FlutterTimezone.getLocalTimezone()`
  - [ ] fallback `Asia/Ho_Chi_Minh`
  - [ ] `tz.setLocalLocation(...)`
- [ ] Init plugin:
  - [ ] Android icon mac dinh dung resource co san, vi du `ic_launcher`
  - [ ] iOS `DarwinInitializationSettings` khong auto request permission luc app boot
  - [ ] Darwin category id = `bioai_reminder_actions`
  - [ ] action id = `done`, `skipped`
- [ ] Permission:
  - [ ] Android: request `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`
  - [ ] iOS: request alert/badge/sound qua `IOSFlutterLocalNotificationsPlugin.requestPermissions`
  - [ ] non-mobile/test fallback return `true`
- [ ] Schedule:
  - [ ] dung `zonedSchedule`
  - [ ] `AndroidScheduleMode.inexactAllowWhileIdle`
  - [ ] `NotificationDetails` co Android action buttons va Darwin category
- [ ] Callback:
  - [ ] foreground callback goi action handler
  - [ ] background callback top-level co `@pragma('vm:entry-point')`

### 3. Tao action handler

- [ ] Tao `lib/services/notifications/notification_action_handler.dart`.
- [ ] Parse `NotificationResponse.payload` bang `NotificationPayload.fromJsonString`.
- [ ] Neu action id la `done`:
  - [ ] update notification `action_status = done`, `responded_at`, `is_read = 1`
  - [ ] neu source `meal`, update `meal_plans.is_completed = 1`
  - [ ] neu source `daily_task`, load task by id, set `current_value = target_value`, `is_completed = 1`, `updated_at = now`
- [ ] Neu action id la `skipped`:
  - [ ] update notification `action_status = skipped`, `responded_at`, `is_read = 1`
  - [ ] khong update meal/task completed
- [ ] Neu payload loi hoac source khong ton tai:
  - [ ] khong crash isolate
  - [ ] log bang `AppLogger` hoac `debugPrint`
- [ ] Tao tests:
  - [ ] done meal
  - [ ] done daily_task
  - [ ] skipped khong mark completed
  - [ ] invalid payload khong crash

### 4. Tao reminder schedule service

- [ ] Tao `lib/services/notifications/reminder_schedule_service.dart`.
- [ ] Doc data tu SQLite:
  - [ ] `MealPlansDao.getAll()`
  - [ ] `DailyHealthTasksDao.getAll()`
- [ ] Mapping gio mac dinh bang `ReminderDefaults`:
  - [ ] meal `breakfast` -> `07:00`
  - [ ] meal `lunch` -> `12:00`
  - [ ] meal `dinner` -> `18:30`
  - [ ] daily `water` -> `09:00`
  - [ ] daily `body` -> `17:30`
  - [ ] daily `mind` -> `21:00`
  - [ ] daily `brain` -> `20:00`
- [ ] Chi schedule item co `scheduled_at` o tuong lai.
- [ ] Truoc khi schedule lai:
  - [ ] query pending notifications theo source ids
  - [ ] cancel native notification ids cu
  - [ ] delete pending rows cu
- [ ] Tao notification row id deterministic:
  - [ ] `reminder_${sourceType}_${sourceId}_${scheduledAt}`
  - [ ] notification id = FNV-1a 31-bit tu row id
- [ ] Neu permission denied:
  - [ ] khong throw len onboarding
  - [ ] insert notification rows voi `action_status = permission_denied`
- [ ] Neu schedule tung item loi:
  - [ ] insert/update row voi `action_status = schedule_failed`
  - [ ] tiep tuc cac item khac
- [ ] Tao fake scheduler tests:
  - [ ] payload encode dung
  - [ ] notification id on dinh
  - [ ] schedule dung so luong item tuong lai
  - [ ] permission denied khong throw

### 5. Noi vao app boot va onboarding

- [ ] Trong `main.dart`, sau `Supabase.initialize`, goi `NotificationBootstrap.initialize()`.
- [ ] Trong onboarding completion callback:
  - [ ] giu thu tu hien co:
    - generate 21 meal records
    - seed 28 daily health tasks
    - schedule reminders
  - [ ] wrap schedule reminders bang try/catch de khong lam fail onboarding neu permission/scheduler loi
- [ ] Dam bao khong pha invariant:
  - [ ] meal + daily task generation van fail onboarding neu thieu du lieu bat buoc
  - [ ] notification schedule failure khong fail onboarding

### 6. Platform setup

- [ ] Android `android/app/build.gradle.kts`:
  - [ ] `multiDexEnabled = true`
  - [ ] `isCoreLibraryDesugaringEnabled = true`
  - [ ] add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
- [ ] Android `AndroidManifest.xml`:
  - [ ] giu `POST_NOTIFICATIONS`
  - [ ] them `RECEIVE_BOOT_COMPLETED`
  - [ ] them receivers/actions theo README plugin 19.5.0 cho scheduled notifications va actions
- [ ] iOS `AppDelegate.swift`:
  - [ ] import `flutter_local_notifications`
  - [ ] set `FlutterLocalNotificationsPlugin.setPluginRegistrantCallback`
  - [ ] set `UNUserNotificationCenter.current().delegate = self` neu iOS 10+
- [ ] Kiem tra generated registrants bi `flutter pub add` sua la hop ly.

### 7. Verification nho sau moi chunk

- [x] `dart format` chi tren file minh sua trong chunk DB tests.
- [x] `flutter test test/core/storage/localdb/migration_manager_test.dart`
- [x] test notification model/dao moi.
- [ ] test notification action/scheduler moi.
- [ ] `flutter test test/features/daily_health_tracking/data/daily_health_dao_test.dart`
- [ ] `flutter test test/features/meal_plan/data/meal_plan_model_test.dart`
- [ ] `flutter test test/architecture_preservation_property_test.dart`
- [ ] `flutter analyze` neu Windows Developer Mode/symlink da duoc bat.

## Goi y chia phien Codex

Lam theo tung phien nho:

1. `DB tests only`: da hoan tat tests cho model/DAO/migration, khong dung native plugin.
2. `Action handler only`: implement va test action handler voi SQLite FFI.
3. `Scheduler service only`: implement reminder schedule service voi fake scheduler.
4. `Native bootstrap only`: implement plugin init/permission/schedule wrapper va platform config.
5. `Onboarding integration only`: hook vao `main.dart`, chay preservation tests.

Moi phien nen dung checkpoint:

- Bat dau: `git status --short`
- Ket thuc: liet ke file da sua + tests da chay + blocker neu co
