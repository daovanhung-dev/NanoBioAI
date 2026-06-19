# Playbook - Lifestyle Schedule / Timeline

## Muc tieu

Tao va quan ly lich trinh ca nhan tu meal, exercise, hydration, sleep; status cap nhat duoc tu app va notification.

## Doc truoc

- `lib/features/lifestyle_schedule/`
- `lib/services/notifications/` neu lien quan reminder/action.
- Meal/daily task DAO/service neu schedule lay nguon tu do.
- Tests: `test/features/lifestyle_schedule/`, `test/services/notifications/`

## Luong dung

```text
Generate meal/exercise/tasks
-> build schedule items
-> save SQLite
-> schedule notifications
-> complete/skip
-> update SQLite
-> dashboard refresh
```

## Quy tac

- Schedule item phai co ngay/gio ro rang.
- Source type ro: `meal`, `exercise`, `hydration`, `sleep`, `custom`.
- Status flow: `pending -> completed` hoac `pending -> skipped`.
- Notification id nen dua tren schedule item id hoac mapping on dinh.
- Refresh/tai tao lich phai tranh tao item trung ngay/gio/source.
- Timeline sap xep theo thoi gian va khong bia data.

## Tim nhanh

```bash
rg "lifestyleSchedule|lifestyle_schedule|schedule_items|TimelineBuilder|pending|completed|skipped|hydrate|sleep" lib/features lib/services test
```

## Test nen chay

- `flutter test test/features/lifestyle_schedule`
- Timeline builder tao dung item/ngay.
- Complete/skip cap nhat DB.
- Query pending items dung thu tu.
