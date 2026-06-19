# Playbook - Daily Health Tracking

## Muc tieu

Ghi nhan chi so hang ngay an toan, khong trung sai du lieu, va dashboard doc duoc de tinh score/progress.

## Doc truoc

- `lib/features/daily_health_tracking/`
- Health tracking logs/tasks table/model/DAO.
- `.codex/playbooks/dashboard.md` neu thay doi score/progress.
- Tests: `test/features/daily_health_tracking/`

## Quy tac

- Validate range cho weight, sleep, water, steps, stress.
- Khong tao duplicate log cho cung metric + date neu nghiep vu yeu cau moi ngay mot ban ghi.
- Timestamp/date format phai nhat quan va timezone-aware.
- Dashboard khong bia tracking data; phai doc logs/tasks that.
- Error user-facing dung giong Nami, khong lo stack trace.

## Tim nhanh

```bash
rg "dailyHealthTracking|health_tracking|tracking_logs|weight|sleep|water|steps|stress|DailyHealthTasksDao|HealthTrackingLogsDao" lib/features lib/core/storage/localdb test
```

## Test nen chay

- `flutter test test/features/daily_health_tracking`
- Insert/update theo ngay.
- Validate min/max.
- Dashboard regression neu score/progress doi.
