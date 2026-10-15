# DD — M22 / Lịch dùng thuốc

| Thuộc tính | Giá trị |
|---|---|
| Module Code | M22 `MEDICATION_ADHERENCE` |
| Version | v1.0.1 — approved local reminder slice |
| Lifecycle | Current |
| DD decision | Approved for M22-F01/F02 only; other adherence behavior remains Draft |
| Implementation | Partial — approved F01/F02 source implemented on top of baseline `598daf04` |
| Verification | Affected Dart analysis and coordinator tests passed; SQLite FFI/device verification pending |
| Source BD | `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md`, M22 and 2026-10-15 addendum |
| Decision authority | Explicit user implementation instruction, 2026-10-15 |
| Created / updated | 2026-10-15 / 2026-10-15 |

## Phạm vi

DD này chốt phần Guest nhập tên thuốc và giờ nhắc lặp hằng ngày trong onboarding,
lưu trên thiết bị hiện tại, và quản lý lịch trong Cài đặt thông báo. Không bao
gồm liều dùng, trạng thái đã uống/bỏ qua, tư vấn, AI, FamilyPlus hoặc cloud sync.
Approved chỉ áp dụng cho lát cắt này, không phê duyệt toàn bộ M22.

Sau khi hoàn tất onboarding, người dùng thêm/xóa lịch nhắc, đổi tên thuốc và
chỉnh giờ trong `Cài đặt > Quản lý thông báo > Nhắc uống thuốc`.

## Tài liệu

- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)

## Traceability

| Nguồn | DD |
|---|---|
| Advanced Health BD §M22; addendum 2026-10-15 | M22-F01 onboarding; M22-F02 quản lý và M22-BR01..BR10; M22-AC11..AC12 |
| User-confirmed scope decisions 2026-10-15 | Guest cục bộ, lặp hằng ngày, nội dung thông báo chung, thêm/đổi tên/xóa lịch trong Settings, chuyển cục bộ khi merge Guest |

## Open scope

- Phần adherence, event history, liều/dạng thuốc, FamilyPlus và đồng bộ nhiều thiết bị vẫn Draft; cần DD/approval riêng.
- DD approval records the explicit user-approved product scope. Không khẳng định đã có reviewer Tech Lead/QA độc lập.

