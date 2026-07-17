# DD — Thông báo đồng hành từ Nabi

| Attribute | Value |
|---|---|
| Module Code | `NABI_COMPANION_NOTIFICATIONS` |
| BD Module | M30 |
| Version | v1.0 |
| Status | Approved - implementation contract |
| Owner | Product Owner / Tech Lead |
| Created / Updated | 2026-07-17 |
| Source BD | `docs/BD/notification_Nabi/BD_thong_bao_nut_noi_Nabi.md` (`BD-NABI-NOTIFICATION-001`) |
| Accepted plan | User-provided implementation plan, 2026-07-17 |

## Purpose

M30 điều phối thông báo contextual, milestone, subscription, retention, reward,
report, care và profile qua nút nổi Nabi. Module sở hữu catalog 20 mã, eligibility,
tần suất, overlay, local OS delivery, CTA, trạng thái theo người dùng và analytics;
M09 tiếp tục sở hữu schedule reminder và complete/skip action.

## Documents

- [Overall](./Overall.md)
- [Notification Catalog](./Notification_Catalog.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import and File Mapping](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Change History](./history/CHANGELOG.md)

## Accepted decisions

- VIP 30 ngày = `Plus/monthly`; VIP năm = `Plus/yearly`; Free Chat = 3/ngày.
- Guest giữ kế hoạch đầu 7 ngày; authenticated Free tối đa 3 ngày/request và 3 request/tháng.
- FamilyPlus chỉ nhận care/reward/profile, không nhận upsell Plus.
- Local OS notification + in-app; không thêm FCM/APNs; không TTS.
- Reward/invite dùng Điểm chăm sóc; Sale Points không thay đổi.
- Analytics remote cần explicit opt-in, pseudonymous, raw event retention 90 ngày.

## Dependencies

M01/M05 profile/auth, M02 schedule generation, M03 dashboard/schedule, M06 membership/quota,
M07 AI Chat, M08 rewards, M09 native notification primitives, M13 payment, M15/M16 Admin,
M18 reporting và M19 audit/privacy.

## Approval status

| Role | Status | Evidence |
|---|---|---|
| BA/PO | Approved | User requested implementation of the attached decision-complete plan, 2026-07-17 |
| Tech Lead | Approved for source implementation | Architecture and data contracts below |
| QA | Pending production acceptance | Supabase sandbox and Android/iOS device smoke required |

