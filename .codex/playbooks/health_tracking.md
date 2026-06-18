# Playbook — Daily Health Tracking

## Mục tiêu

Theo dõi sức khỏe hàng ngày (BMI, cân nặng, giấc ngủ, stress, nước uống, bước chân) và lưu vào DB để tính progress.

## Luồng đúng

```text
User input tracking data → Validate → Save to health_tracking_logs 
→ Calculate score/progress → Update dashboard
```

## Khi sửa Health Tracking

Đọc vùng liên quan:

- `lib/features/daily_health_tracking/`
- `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart`
- `lib/core/storage/localdb/tables/health_tracking_logs_table.dart`
- `lib/core/storage/localdb/models/health_tracking_log_model.dart`

Kiểm tra bằng `rg`:

```bash
rg "health_tracking|tracking_logs|log_entry" lib test
rg "trackWeight|trackSleep|trackStress|trackWater|trackSteps" lib
```

## Quy tắc

- Tracking log phải có timestamp chính xác (timezone-aware).
- Không cho phép duplicate entry cho cùng metric + date.
- Validate input range:
  - Weight: 20-300 kg
  - Height: 50-250 cm
  - Sleep: 0-24 hours
  - Water: 0-10000 ml
  - Steps: 0-100000
  - Stress level: 1-10
- Progress calculation phải từ DB thật, không mock.
- Chart/graph hiển thị trend theo time range (7/30/90 days).

## Data model

```dart
class HealthTrackingLogModel {
  final String id;
  final String userId;
  final String metricType; // 'weight', 'sleep', 'water', 'steps', 'stress'
  final double value;
  final String? note;
  final String timestamp; // ISO8601
  final String createdAt;
}
```

## Metric types

| Type | Unit | Range | Frequency |
|------|------|-------|-----------|
| weight | kg | 20-300 | Daily/Weekly |
| height | cm | 50-250 | Monthly |
| sleep | hours | 0-24 | Daily |
| water | ml | 0-10000 | Multiple/day |
| steps | count | 0-100000 | Daily |
| stress | level | 1-10 | Daily |

## Test nên có

- Insert log → read back correct values
- Duplicate prevention (same metric + date)
- Range validation
- Trend calculation (7/30/90 days)
- Chart data formatting
- Empty state handling

## Common issues

- ❌ Timezone không đúng → log bị ghi sai ngày
- ❌ Duplicate logs → multiple entries cho cùng metric + date
- ❌ Invalid range → user nhập 500kg weight
- ❌ Chart calculation sai → trend không đúng

## Integration với Dashboard

Dashboard phải query tracking logs để:
- Hiển thị latest weight/BMI
- Show progress chart
- Calculate completion rate
- Display health score

```dart
// ✅ CORRECT
final logs = await dao.getLogsByDateRange(startDate, endDate);
final progress = calculateProgress(logs);

// ❌ WRONG
final mockProgress = 75.0; // Don't use mock data!
```
