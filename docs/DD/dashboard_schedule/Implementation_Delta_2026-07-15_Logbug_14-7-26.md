# Implementation Delta 2026-07-15 — Logbug 14-7-26

| Thuộc tính | Giá trị |
|---|---|
| Module | M03 / `DASHBOARD_SCHEDULE` |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp ngày 2026-07-15 |
| Ảnh hưởng | Dashboard CTA, timeline, completion/proof/undo |

## Quyết định bổ sung

| ID | Quyết định |
|---|---|
| DASHBOARD_SCHEDULE-DELTA-BR01 | Dashboard dùng cùng `ScheduleHorizonReader` với service. CTA tạo lịch disabled khi còn ít nhất hai ngày; dữ liệu ngày lỗi khóa an toàn. |
| DASHBOARD_SCHEDULE-DELTA-BR02 | Cửa sổ hoàn thành/hoàn tác là inclusive `[start, start + 30 phút]`; trước start hoặc sau deadline đều khóa. Mốc đúng `+30:00` được chấp nhận. |
| DASHBOARD_SCHEDULE-DELTA-BR03 | Completion online bắt buộc camera proof. Controller kiểm tra cửa sổ cả trước và sau camera; nếu camera vượt deadline thì xóa proof tạm và không finalize. |
| DASHBOARD_SCHEDULE-DELTA-ADR01 | Clock được inject để test và UI đặt timer tại cả start/deadline. Ngày/giờ invalid hiển thị lỗi dữ liệu và không cho thao tác. |

## View và evidence

- Item hoàn tất vẫn hiển thị kết quả, nhưng sau cửa sổ không được sửa/undo. Trang lịch có entry chỉnh hồ sơ nhịp sinh hoạt cho lần sinh tiếp theo.
- Runtime: dashboard datasource/page, window policy/provider/controller/page và local datasource.
- Test: exact deadline, after-deadline, malformed time, proof flow và schedule horizon.
- Server contract: proof upload timestamp được chấp nhận đến hết `window_end`; điểm chỉ available sau mốc này.
