# Dashboard Refactor Note

## Module

Dashboard

## Problem

File `dashboard_page.dart` hiện đang quá lớn và chứa gần như toàn bộ UI dashboard trong cùng một file. 

Hiện tại file đang bao gồm:

* Dashboard layout chính
* Header section
* Hero health card
* Metric grid
* Quick actions
* AI suggestions
* Timeline plan
* Highlight section
* Reusable cards
* Custom chart widget
* Custom painter
* Internal models
* Action buttons
* Multiple private widgets

Tổng số widget/component nội bộ trong file:

* `_HeaderSection`
* `_HeroHealthCard`
* `_MetricGrid`
* `_MainColumn`
* `_SideColumn`
* `_SectionCard`
* `_MetricCard`
* `_InfoChip`
* `_ScoreRing`
* `_MiniTrendChart`
* `_AiSuggestions`
* `_QuickActions`
* `_TodayPlan`
* `_Highlights`
* `_ActionTile`
* `_ActionIconButton`
* `_TimelineTile`
* `_TrendChartPainter`

Điều này khiến file trở nên quá tải responsibility.

---

## Technical Problems

### 1. Quá nhiều UI components trong một file

Toàn bộ dashboard đang được build trong duy nhất một file lớn.

Điều này gây:

* File rất dài
* Scroll khó đọc
* Dev khó tìm widget
* Maintain khó

---

### 2. Widget tree quá sâu

Dashboard chứa nhiều nested widget:

* GridView
* LayoutBuilder
* Column
* Row
* Stack
* CustomPaint

khiến:

* Widget tree khó debug
* Build method khó theo dõi
* Performance optimization khó thực hiện

---

### 3. Business sections chưa được modular hóa

Các section lớn như:

* Health score
* AI suggestions
* Quick actions
* Today plan
* Trend chart

đều đang nằm trực tiếp trong file page thay vì component riêng.

Điều này làm:

* Không reusable
* Không scalable
* Khó mở rộng feature

---

### 4. CustomPainter nằm chung với UI

`_TrendChartPainter` hiện đang nằm trực tiếp trong file dashboard.

Vấn đề:

* Painter logic không nên nằm trong page
* Khó tái sử dụng chart
* Sau này khó scale chart system

---

### 5. Internal models nằm sai responsibility

Các model:

* `_MetricData`
* `_ActionData`

đang nằm trực tiếp trong UI file.

Điều này gây:

* UI bị trộn data structure
* Khó scale state management
* Khó convert sang entity/model thật sau này

---

### 6. Khó teamwork

Khi nhiều dev cùng sửa dashboard:

* Dễ merge conflict
* Dễ override code nhau
* Review PR khó

---

## Current Impact

### Maintainability

Dashboard ngày càng khó maintain khi thêm feature mới.

### Scalability

Khó mở rộng:

* AI dashboard
* realtime widgets
* charts
* analytics
* wearable sync

### Reusability

Không reuse được:

* cards
* metric item
* chart section
* quick action item

### Clean Architecture

Hiện tại UI layer đang ôm quá nhiều responsibility.

---

## Planned Refactor Structure

```txt id="u1yz7v"
dashboard/
├── presentation/
│   ├── pages/
│   │   └── dashboard_page.dart
│   │
│   ├── widgets/
│   │   ├── dashboard_header.dart
│   │   ├── hero_health_card.dart
│   │   ├── metric_grid.dart
│   │   ├── metric_card.dart
│   │   ├── section_card.dart
│   │   ├── ai_suggestions.dart
│   │   ├── quick_actions.dart
│   │   ├── action_tile.dart
│   │   ├── today_plan.dart
│   │   ├── timeline_tile.dart
│   │   ├── highlights.dart
│   │   ├── score_ring.dart
│   │   └── info_chip.dart
│   │
│   ├── charts/
│   │   ├── mini_trend_chart.dart
│   │   └── trend_chart_painter.dart
│   │
│   └── models/
│       ├── metric_data.dart
│       └── action_data.dart
```

---

## Planned Improvements

* Tách widget theo responsibility
* Reusable dashboard components
* Separate chart system
* Cleaner architecture
* Easier testing
* Easier Riverpod integration
* Easier realtime updates
* Easier AI widget expansion

---

## Priority

High

---

## Status

Pending

---

## Notes

Hiện tại dashboard đã hoạt động ổn định về UI nên ưu tiên hoàn thiện feature flow trước.
Refactor component sẽ thực hiện sau khi các module chính hoàn thiện hơn.
