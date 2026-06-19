Commit de xuat: docs(dd): them index module design document

# DD Module Index

Bang nay tom tat module DD hien co, noi code lien quan va khoang cach can de y khi coding.

| ID | Module | Code lien quan | Trang thai hien tai | Can de y khi coding |
| --- | --- | --- | --- | --- |
| 01 | Profile Assessment | `lib/features/onboarding/`, `lib/features/profile/`, `lib/features/settings/`, `lib/core/storage/localdb/` | Da co onboarding/profile luu-doc SQLite | Bao ve flow onboarding -> profile/goals/habits/conditions/allergies/treatments/survey answers |
| 02 | Personalized MealPlan 30 Days | `lib/services/ai/`, `lib/features/meal_plan/` | Code hien nghieng ve 7 ngay, DD cu noi 30 ngay | Khi doi prompt/parser/storage phai noi ro 7 ngay hay 30 ngay |
| 03 | MealPlan Storage | `lib/features/meal_plan/`, `lib/core/storage/localdb/daos/` | Da co `meal_plans` va DAO chinh | Chua co cycle/history model rieng |
| 04 | Cycle Refresh After 30 Days | onboarding + meal plan + schedule | Chua co model cycle rieng | Neu lam can schema/DAO/migration va rule het chu ky |
| 05 | Daily Health Tracking | `lib/features/daily_health_tracking/`, `lib/core/storage/localdb/` | Co table/log model mot phan, DAO con thieu | Can validate range, upsert theo ngay, dashboard integration |
| 06 | Weekly Summary Scoring | `lib/features/dashboard/`, `lib/features/daily_health_tracking/`, notification | Chua co weekly summary model rieng | Can rule tinh diem, lich thu 6 21:00, notification/test |
| 07 | Health Assistant QA | `lib/features/ai_chat/`, `lib/services/ai/` | Co chat message model; history chu yeu in-memory | Can tranh loi dotenv/API key, can guard medical advice va fallback |
| 08 | Zalo Special Care Group | chua ro module code | Chua co model/entity/table | Can xac dinh MVP va external link policy truoc khi code |
| 09 | Health Knowledge Base | chua ro module code | Chua co model/entity/table | Can content model/category/source/review policy |

## Flow San Pham Can Giu

```text
Onboarding complete
-> save profile/goals/habits/conditions/allergies/treatments/survey answers to SQLite
-> generate meal plan + exercise/daily health tasks by AI or fallback
-> normalize Vietnamese user-facing text
-> save meal/task/schedule data to SQLite
-> build lifestyle schedule: meals + exercise + hydration + sleep
-> schedule local notifications with complete/skip actions
-> user action updates SQLite
-> dashboard reads SQLite and recalculates score/progress/timeline
```

## Legacy DD Source

Tai lieu cu trong `DD_Module/**` van co gia tri nhu product intent, nhung hien:

- bi loi encoding o nhieu file;
- mo ta kha tong quat, chua du data contract;
- chua map day du sang code hien tai;
- co sai lech lon ve meal plan 30 ngay so voi flow 7 ngay trong code.

Khi can code, dung bang index nay + `.codex/PROJECT_MAP.md` de mo source lien quan truoc, roi moi quay lai legacy DD neu can xem y tuong san pham.

