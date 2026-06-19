# Playbook - Dashboard / Health Score

## Muc tieu

Dashboard phai phan anh du lieu that tu SQLite: ho so, BMI, tracking logs, meal plan, daily tasks, lifestyle schedule, notifications, AI insights/recommendations.

## Doc truoc

- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- Neu can: `lib/features/meal_plan/`, `lib/services/notifications/`
- Tests: `test/features/dashboard/`, `test/features/daily_health_tracking/`, `test/features/lifestyle_schedule/`

## Luong dung

```text
SQLite/data layer
-> dashboard providers
-> repository/datasource
-> calculator/mapper
-> page/widgets
```

File hien tai can de y:

- `lib/features/dashboard/providers/dashboard_provider.dart`
- `lib/features/dashboard/providers/dashboard_dynamic_provider.dart`
- `lib/features/dashboard/data/datasources/dashboard_local_datasource.dart`
- `lib/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart`
- `lib/features/dashboard/domain/services/dashboard_health_calculator.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`

## Quy tac

- Khong dung mock/fake/sample data trong production dashboard.
- UI khong query SQLite truc tiep.
- Score/progress/timeline phai tinh tu du lieu that; thieu data thi hien empty state.
- Neu user complete/skip task, dashboard phai refresh tu DB.
- User-facing copy khong noi `database`, `table`, `query`, `log`, `exception`.
- Tranh `dynamic` trong UI neu co entity typed san.

## Tim nhanh

```bash
rg "dashboardProvider|dashboardDynamicProvider|DashboardHealthCalculator|timeline|dailyScore" lib/features/dashboard test/features/dashboard
rg "mock|fake|sample|dummy" lib/features/dashboard
rg "HealthTrackingLogsDao|DailyHealthTasksDao|LifestyleScheduleItemsDao|MealPlansDao|NotificationsDao" lib test
```

## Test nen chay

- `flutter test test/features/dashboard`
- Neu cham tracking/schedule: `flutter test test/features/daily_health_tracking test/features/lifestyle_schedule`
- Quick check neu thay doi logic dung chung.
