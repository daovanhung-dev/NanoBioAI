# Dashboard Refactor TODO

## Dashboard Architecture Refactor

### Refactor Goal

Tách `dashboard_page.dart` thành các component nhỏ hơn để:

* Giảm responsibility của page
* Tăng reusability
* Dễ maintain
* Dễ scale feature
* Chuẩn clean architecture

---

## Tasks

### Structure Refactor

* [ ] Tạo folder `widgets/`
* [ ] Tạo folder `charts/`
* [ ] Tạo folder `models/`

---

### Extract Widgets

* [ ] Tách `_HeaderSection`
* [ ] Tách `_HeroHealthCard`
* [ ] Tách `_MetricGrid`
* [ ] Tách `_MetricCard`
* [ ] Tách `_SectionCard`
* [ ] Tách `_InfoChip`
* [ ] Tách `_ScoreRing`
* [ ] Tách `_AiSuggestions`
* [ ] Tách `_QuickActions`
* [ ] Tách `_ActionTile`
* [ ] Tách `_TodayPlan`
* [ ] Tách `_TimelineTile`
* [ ] Tách `_Highlights`

---

### Chart Refactor

* [ ] Tách `_MiniTrendChart`
* [ ] Tách `_TrendChartPainter`
* [ ] Tạo reusable chart system

---

### Model Refactor

* [ ] Tách `_MetricData`
* [ ] Tách `_ActionData`
* [ ] Chuẩn hóa dashboard models

---

### Architecture Improvements

* [ ] Giảm nested widget depth
* [ ] Tách UI khỏi data structure
* [ ] Chuẩn hóa reusable cards
* [ ] Chuẩn hóa dashboard sections
* [ ] Chuẩn bị Riverpod integration
* [ ] Chuẩn bị realtime update architecture

---

## Planned Structure

```txt id="0r6s1w"
dashboard/
├── presentation/
│   ├── pages/
│   │   └── dashboard_page.dart
│   │
│   ├── widgets/
│   ├── charts/
│   └── models/
```

---

## Priority

High

---

## Status

Pending

---

## Notes

Dashboard hiện tại đã ổn định về UI nên ưu tiên hoàn thiện flow trước.

Refactor sẽ thực hiện sau khi:

* feature flow ổn định
* state management hoàn thiện
* dashboard data thật được integrate
