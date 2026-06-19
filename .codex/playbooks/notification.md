# Playbook - Notification / Reminder

## Muc tieu

Thong bao theo lifestyle schedule, co action Da lam/Bo qua, va action cap nhat SQLite an toan.

## Doc truoc

- `lib/services/notifications/`
- `lib/features/lifestyle_schedule/`
- DAOs lien quan notifications, meal plans, daily health tasks, lifestyle schedule items.
- Tests: `test/services/notifications/`, `test/features/lifestyle_schedule/`

## File can de y

- `notification_bootstrap.dart`
- `notification_payload.dart`
- `notification_id_generator.dart`
- `reminder_notification_scheduler.dart`
- `reminder_schedule_service.dart`
- `notification_action_handler.dart`
- `notification_lifecycle_refresher.dart`
- `notification_startup_scheduler.dart`

## Quy tac

- Init timezone truoc khi schedule.
- Notification id phai on dinh, tranh trung ngoai y muon.
- Payload co type/id/version neu can; invalid payload khong crash.
- Background action khong phu thuoc `BuildContext`.
- Complete/skip phai update DB qua service/DAO abstraction.
- Neu doi Android/native config, chay build APK debug neu moi truong cho phep.
- Khong goi plugin notification that trong unit test; test mapper/payload/id/service logic.

## Tim nhanh

```bash
rg "Notification|notification|payload|timezone|reminder|complete|skip|AndroidNotificationAction|background" lib/services/notifications lib/features test
```

## Test nen chay

- `flutter test test/services/notifications`
- Payload round-trip va invalid payload.
- ID generator on dinh.
- Complete/skip update dung source.
- Build APK debug neu doi native/manifest.
